import math
from pathlib import Path
from random import Random

import bpy
import bmesh
import mathutils


def ensure_dirs(base_dir: Path):
    tex_dir = base_dir / "Textures"
    tex_dir.mkdir(parents=True, exist_ok=True)
    return tex_dir


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"


def select_only(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def add_bevel_modifier(obj, width=0.0018, segments=2):
    mod = obj.modifiers.new(name="Bevel", type="BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(30.0)
    select_only(obj)
    bpy.ops.object.modifier_apply(modifier=mod.name)


def create_body_parts():
    main_objs = []
    screen_objs = []

    body_len = 0.148
    body_width = 0.078
    body_height = 0.032

    bpy.ops.mesh.primitive_cube_add(location=(0.0, 0.035, 0.026))
    body = bpy.context.object
    body.name = "MEDOK_Body"
    body.scale = (body_width * 0.5, body_len * 0.5, body_height * 0.5)
    bpy.ops.object.transform_apply(scale=True)
    add_bevel_modifier(body, width=0.0022, segments=2)
    main_objs.append(body)

    bpy.ops.mesh.primitive_cube_add(location=(0.0, 0.0, 0.0))
    grip = bpy.context.object
    grip.name = "MEDOK_Grip"
    grip.scale = (0.022, 0.034, 0.029)
    bpy.ops.object.transform_apply(scale=True)
    add_bevel_modifier(grip, width=0.0016, segments=2)
    main_objs.append(grip)

    bpy.ops.mesh.primitive_cube_add(location=(0.0, 0.046, 0.043))
    screen_panel = bpy.context.object
    screen_panel.name = "MEDOK_ScreenPanel"
    screen_panel.scale = (0.026, 0.021, 0.0018)
    bpy.ops.object.transform_apply(scale=True)
    add_bevel_modifier(screen_panel, width=0.0006, segments=1)
    screen_objs.append(screen_panel)

    button_positions = [(-0.017, 0.004, 0.0435), (0.017, 0.004, 0.0435)]
    for idx, pos in enumerate(button_positions, start=1):
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16,
            radius=0.009,
            depth=0.0052,
            location=pos,
        )
        button = bpy.context.object
        button.name = f"MEDOK_Button_{idx}"
        main_objs.append(button)

    bar_x = [-0.0158, -0.0079, 0.0, 0.0079, 0.0158]
    for idx, x in enumerate(bar_x, start=1):
        bpy.ops.mesh.primitive_cube_add(location=(x, 0.052, 0.0454))
        bar = bpy.context.object
        bar.name = f"MEDOK_LEDBar_{idx}"
        bar.scale = (0.0028, 0.0060, 0.0007)
        bpy.ops.object.transform_apply(scale=True)
        screen_objs.append(bar)

    bpy.ops.object.text_add(location=(-0.0175, 0.0375, 0.0452))
    txt = bpy.context.object
    txt.name = "MEDOK_LabelText"
    txt.data.body = "MEDOK"
    txt.data.size = 0.0062
    txt.data.extrude = 0.0007
    txt.data.bevel_depth = 0.0
    txt.data.resolution_u = 1
    txt.rotation_euler = (0.0, 0.0, 0.0)
    bpy.ops.object.convert(target="MESH")
    txt = bpy.context.object
    txt.name = "MEDOK_LabelMesh"
    screen_objs.append(txt)

    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12,
        radius=0.0035,
        depth=0.013,
        location=(0.0, 0.113, 0.045),
    )
    antenna = bpy.context.object
    antenna.name = "MEDOK_Antenna"
    main_objs.append(antenna)

    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=10,
        ring_count=6,
        radius=0.0047,
        location=(0.0, 0.113, 0.053),
    )
    probe_tip = bpy.context.object
    probe_tip.name = "MEDOK_ProbeTip"
    main_objs.append(probe_tip)

    return main_objs, screen_objs


def generate_textures(tex_dir: Path):
    size = 512
    rnd = Random(77)

    def make_albedo():
        px = []
        for y in range(size):
            v = y / (size - 1)
            for x in range(size):
                u = x / (size - 1)
                grain = 0.03 * math.sin((u * 52.0) + (v * 40.0))
                smudge = -0.02 * abs(math.sin((u + v) * 8.0))
                noise = rnd.uniform(-0.015, 0.015)
                base = max(0.11, min(0.34, 0.22 + grain + smudge + noise))
                r = base * 0.96
                g = base * 0.98
                b = base
                px.extend((r, g, b, 1.0))
        return px

    def make_roughness():
        px = []
        for y in range(size):
            v = y / (size - 1)
            for x in range(size):
                u = x / (size - 1)
                tiny = 0.06 * math.sin((u * 67.0) - (v * 48.0))
                rough = max(0.62, min(0.95, 0.81 + tiny))
                px.extend((rough, rough, rough, 1.0))
        return px

    def make_normal():
        px = []
        for _ in range(size * size):
            px.extend((0.5, 0.5, 1.0, 1.0))
        return px

    albedo = bpy.data.images.new("Tool_MEDOK_Albedo", width=size, height=size, alpha=False)
    albedo.pixels = make_albedo()
    albedo.filepath_raw = str(tex_dir / "Tool_MEDOK_Albedo.png")
    albedo.file_format = "PNG"
    albedo.save()

    rough = bpy.data.images.new("Tool_MEDOK_Roughness", width=size, height=size, alpha=False)
    rough.pixels = make_roughness()
    rough.filepath_raw = str(tex_dir / "Tool_MEDOK_Roughness.png")
    rough.file_format = "PNG"
    rough.save()

    normal = bpy.data.images.new("Tool_MEDOK_Normal", width=size, height=size, alpha=False)
    normal.pixels = make_normal()
    normal.filepath_raw = str(tex_dir / "Tool_MEDOK_Normal.png")
    normal.file_format = "PNG"
    normal.save()

    return albedo, rough, normal


def build_materials(albedo, rough, normal):
    main_mat = bpy.data.materials.new(name="MEDOK_Main")
    main_mat.use_nodes = True
    n = main_mat.node_tree.nodes
    l = main_mat.node_tree.links
    n.clear()

    out = n.new("ShaderNodeOutputMaterial")
    out.location = (600, 160)

    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (320, 160)
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.28

    t_albedo = n.new("ShaderNodeTexImage")
    t_albedo.location = (20, 260)
    t_albedo.image = albedo

    t_rough = n.new("ShaderNodeTexImage")
    t_rough.location = (20, 80)
    t_rough.image = rough
    t_rough.image.colorspace_settings.name = "Non-Color"

    t_normal = n.new("ShaderNodeTexImage")
    t_normal.location = (20, -90)
    t_normal.image = normal
    t_normal.image.colorspace_settings.name = "Non-Color"

    nmap = n.new("ShaderNodeNormalMap")
    nmap.location = (190, -90)
    nmap.inputs["Strength"].default_value = 0.22

    l.new(t_albedo.outputs["Color"], bsdf.inputs["Base Color"])
    l.new(t_rough.outputs["Color"], bsdf.inputs["Roughness"])
    l.new(t_normal.outputs["Color"], nmap.inputs["Color"])
    l.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    l.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    screen_mat = bpy.data.materials.new(name="MEDOK_Screen")
    screen_mat.use_nodes = True
    sn = screen_mat.node_tree.nodes
    sl = screen_mat.node_tree.links
    sn.clear()

    sout = sn.new("ShaderNodeOutputMaterial")
    sout.location = (500, 120)

    emis = sn.new("ShaderNodeEmission")
    emis.location = (230, 120)
    emis.inputs["Color"].default_value = (0.22, 1.0, 0.38, 1.0)
    emis.inputs["Strength"].default_value = 2.8

    gloss = sn.new("ShaderNodeBsdfGlossy")
    gloss.location = (230, -40)
    gloss.inputs["Color"].default_value = (0.02, 0.05, 0.02, 1.0)
    gloss.inputs["Roughness"].default_value = 0.18

    mix = sn.new("ShaderNodeMixShader")
    mix.location = (360, 110)

    fac = sn.new("ShaderNodeValue")
    fac.location = (100, 220)
    fac.outputs[0].default_value = 0.78

    sl.new(fac.outputs[0], mix.inputs["Fac"])
    sl.new(emis.outputs["Emission"], mix.inputs[1])
    sl.new(gloss.outputs["BSDF"], mix.inputs[2])
    sl.new(mix.outputs["Shader"], sout.inputs["Surface"])

    return main_mat, screen_mat


def assign_materials(main_objs, screen_objs, main_mat, screen_mat):
    for obj in main_objs:
        obj.data.materials.clear()
        obj.data.materials.append(main_mat)

    for obj in screen_objs:
        obj.data.materials.clear()
        obj.data.materials.append(screen_mat)


def join_mesh(main_objs, screen_objs):
    all_objs = main_objs + screen_objs
    bpy.ops.object.select_all(action="DESELECT")
    for obj in all_objs:
        obj.select_set(True)
    grip = next((obj for obj in main_objs if obj.name == "MEDOK_Grip"), main_objs[0])
    bpy.context.view_layer.objects.active = grip
    bpy.ops.object.join()
    mesh = bpy.context.object
    mesh.name = "Tool_MEDOK_Mesh"

    select_only(mesh)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.shade_smooth()
    return mesh


def cleanup_geometry(mesh):
    select_only(mesh)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode="OBJECT")


def smart_uv(mesh):
    select_only(mesh)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.02, area_weight=0.4)
    bpy.ops.object.mode_set(mode="OBJECT")


def count_triangles(mesh):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    eval_obj = mesh.evaluated_get(depsgraph)
    eval_mesh = eval_obj.to_mesh()
    tri_count = len(eval_mesh.loop_triangles)
    eval_obj.to_mesh_clear()
    return tri_count


def export_assets(base_dir: Path, mesh):
    blend_path = base_dir / "Tool_MEDOK.blend"
    fbx_path = base_dir / "Tool_MEDOK.fbx"

    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))

    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh

    bpy.ops.export_scene.fbx(
        filepath=str(fbx_path),
        use_selection=True,
        object_types={"MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="Y",
        axis_up="Z",
        add_leaf_bones=False,
        bake_anim=False,
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
    )


def write_report(base_dir: Path, tri_count: int):
    report_path = base_dir / "Tool_MEDOK_Report.txt"
    report_path.write_text(
        "\n".join(
            [
                "Tool MEDOK build summary",
                f"Triangles: {tri_count}",
                "Materials: MEDOK_Main + MEDOK_Screen",
                "Pivot target: center grip at object origin",
                "Export axis: Forward Y, Up Z",
                "Texture set: Albedo + Roughness + Normal(optional)",
            ]
        ),
        encoding="utf-8",
    )


def main():
    base_dir = Path(__file__).resolve().parent
    tex_dir = ensure_dirs(base_dir)

    reset_scene()
    main_objs, screen_objs = create_body_parts()
    albedo, rough, normal = generate_textures(tex_dir)
    main_mat, screen_mat = build_materials(albedo, rough, normal)
    assign_materials(main_objs, screen_objs, main_mat, screen_mat)

    mesh = join_mesh(main_objs, screen_objs)
    cleanup_geometry(mesh)
    smart_uv(mesh)

    tri_count = count_triangles(mesh)
    export_assets(base_dir, mesh)
    write_report(base_dir, tri_count)

    print("Tool MEDOK build complete.")
    print(f"Triangles: {tri_count}")
    print(f"Assets exported to: {base_dir}")


if __name__ == "__main__":
    main()
