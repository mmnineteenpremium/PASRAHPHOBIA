import math
from pathlib import Path
from random import Random

import bpy
import mathutils


RARITY_DATA = {
    "R1": {
        "tier_name": "B-ajah",
        "color": (0.70, 0.70, 0.73, 1.0),
        "screen_strength": 2.1,
        "aura_strength": 0.55,
        "spark_count": 3,
    },
    "R2": {
        "tier_name": "B-Lebih",
        "color": (0.30, 0.92, 0.42, 1.0),
        "screen_strength": 2.4,
        "aura_strength": 0.68,
        "spark_count": 4,
    },
    "R3": {
        "tier_name": "Lumayan",
        "color": (0.26, 0.66, 1.00, 1.0),
        "screen_strength": 2.6,
        "aura_strength": 0.78,
        "spark_count": 5,
    },
    "R4": {
        "tier_name": "Langka",
        "color": (0.72, 0.42, 1.00, 1.0),
        "screen_strength": 2.8,
        "aura_strength": 0.92,
        "spark_count": 6,
    },
    "R5": {
        "tier_name": "Gagah",
        "color": (1.00, 0.78, 0.31, 1.0),  # gold/amber ~ RGB 255/200/80
        "screen_strength": 3.2,
        "aura_strength": 1.10,
        "spark_count": 8,
    },
}


def look_at(obj, target):
    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def clear_previous_helpers():
    helper_prefixes = (
        "SHOP_",
        "Badge_",
        "Card_",
        "Spark_",
        "Aura_",
    )
    remove = [obj for obj in bpy.data.objects if obj.name.startswith(helper_prefixes)]
    for obj in remove:
        bpy.data.objects.remove(obj, do_unlink=True)

    remove_mats = [mat for mat in bpy.data.materials if mat.name.startswith(helper_prefixes)]
    for mat in remove_mats:
        bpy.data.materials.remove(mat, do_unlink=True)


def setup_render():
    scene = bpy.context.scene
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"


def setup_camera_and_lights():
    scene = bpy.context.scene
    for cam in [o for o in bpy.data.objects if o.type == "CAMERA"]:
        bpy.data.objects.remove(cam, do_unlink=True)
    for light in [o for o in bpy.data.objects if o.type == "LIGHT"]:
        bpy.data.objects.remove(light, do_unlink=True)

    bpy.ops.object.camera_add(location=(0.18, -0.26, 0.15))
    cam = bpy.context.object
    cam.name = "SHOP_Camera"
    cam.data.lens = 78
    look_at(cam, mathutils.Vector((0.0, 0.04, 0.03)))
    scene.camera = cam

    bpy.ops.object.light_add(type="AREA", location=(0.33, -0.15, 0.24))
    key = bpy.context.object
    key.name = "SHOP_KeyLight"
    key.data.energy = 310.0
    key.data.size = 0.22
    key.data.color = (1.0, 0.96, 0.90)

    bpy.ops.object.light_add(type="AREA", location=(-0.25, -0.22, 0.16))
    fill = bpy.context.object
    fill.name = "SHOP_FillLight"
    fill.data.energy = 145.0
    fill.data.size = 0.26
    fill.data.color = (0.72, 0.79, 0.95)

    bpy.ops.object.light_add(type="SPOT", location=(0.0, 0.27, 0.24))
    rim = bpy.context.object
    rim.name = "SHOP_RimLight"
    rim.data.energy = 170.0
    rim.data.spot_size = math.radians(48.0)
    rim.data.spot_blend = 0.5
    rim.data.color = (0.66, 0.76, 0.98)
    look_at(rim, mathutils.Vector((0.0, 0.04, 0.03)))

    return cam


def create_background(cam):
    bpy.ops.mesh.primitive_plane_add(size=2.0, location=(0.0, 0.0, 0.0))
    bg = bpy.context.object
    bg.name = "SHOP_Background"
    bg.parent = cam
    bg.location = (0.0, 0.0, -1.1)
    bg.scale = (1.75, 1.75, 1.0)

    mat = bpy.data.materials.new("SHOP_BG_Mat")
    mat.use_nodes = True
    n = mat.node_tree.nodes
    l = mat.node_tree.links
    n.clear()

    out = n.new("ShaderNodeOutputMaterial")
    out.location = (460, 120)
    emis = n.new("ShaderNodeEmission")
    emis.location = (260, 120)
    coord = n.new("ShaderNodeTexCoord")
    coord.location = (-430, 80)
    sep = n.new("ShaderNodeSeparateXYZ")
    sep.location = (-230, 80)
    ramp = n.new("ShaderNodeValToRGB")
    ramp.location = (-20, 80)
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.01, 0.01, 0.02, 1.0)
    ramp.color_ramp.elements[1].position = 1.0
    ramp.color_ramp.elements[1].color = (0.05, 0.09, 0.19, 1.0)
    emis.inputs["Strength"].default_value = 1.0

    l.new(coord.outputs["Generated"], sep.inputs["Vector"])
    l.new(sep.outputs["Y"], ramp.inputs["Fac"])
    l.new(ramp.outputs["Color"], emis.inputs["Color"])
    l.new(emis.outputs["Emission"], out.inputs["Surface"])

    bg.data.materials.clear()
    bg.data.materials.append(mat)


def create_shadow_plane():
    bpy.ops.mesh.primitive_plane_add(size=0.44, location=(0.0, 0.04, -0.0006))
    plane = bpy.context.object
    plane.name = "SHOP_ShadowPlane"

    mat = bpy.data.materials.new("SHOP_Shadow_Mat")
    mat.use_nodes = True
    n = mat.node_tree.nodes
    n.clear()
    out = n.new("ShaderNodeOutputMaterial")
    out.location = (320, 0)
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (90, 0)
    bsdf.inputs["Base Color"].default_value = (0.03, 0.04, 0.06, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.93
    bsdf.inputs["Specular IOR Level"].default_value = 0.15
    mat.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    plane.data.materials.clear()
    plane.data.materials.append(mat)


def orient_tool():
    tool = bpy.data.objects.get("Tool_MEDOK_Mesh")
    if tool is None:
        raise RuntimeError("Tool_MEDOK_Mesh not found in Tool_MEDOK.blend")

    tool.location = (0.0, 0.03, 0.0)
    tool.rotation_mode = "XYZ"
    tool.rotation_euler = mathutils.Euler((math.radians(8.0), math.radians(-5.0), math.radians(-22.0)), "XYZ")
    return tool


def get_material(name):
    mat = bpy.data.materials.get(name)
    if mat is None:
        raise RuntimeError(f"Material not found: {name}")
    return mat


def find_emission_node(mat):
    for node in mat.node_tree.nodes:
        if node.type == "EMISSION":
            return node
    raise RuntimeError(f"No Emission node in material {mat.name}")


def create_aura_shell(tool):
    aura = tool.copy()
    aura.data = tool.data.copy()
    aura.name = "Aura_Shell"
    aura.scale = (1.025, 1.025, 1.025)
    bpy.context.collection.objects.link(aura)

    aura_mat = bpy.data.materials.new("Aura_Mat")
    aura_mat.use_nodes = True
    aura_mat.blend_method = "BLEND"
    if hasattr(aura_mat, "shadow_method"):
        aura_mat.shadow_method = "NONE"
    n = aura_mat.node_tree.nodes
    l = aura_mat.node_tree.links
    n.clear()

    out = n.new("ShaderNodeOutputMaterial")
    out.location = (550, 160)
    mix = n.new("ShaderNodeMixShader")
    mix.location = (370, 160)
    transp = n.new("ShaderNodeBsdfTransparent")
    transp.location = (150, 250)
    emis = n.new("ShaderNodeEmission")
    emis.location = (150, 80)
    emis.inputs["Strength"].default_value = 0.9
    layer = n.new("ShaderNodeLayerWeight")
    layer.location = (-60, 170)
    ramp = n.new("ShaderNodeValToRGB")
    ramp.location = (110, 350)
    ramp.color_ramp.elements[0].position = 0.35
    ramp.color_ramp.elements[0].color = (0.0, 0.0, 0.0, 1.0)
    ramp.color_ramp.elements[1].position = 0.96
    ramp.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)

    l.new(layer.outputs["Facing"], ramp.inputs["Fac"])
    l.new(ramp.outputs["Color"], mix.inputs["Fac"])
    l.new(transp.outputs["BSDF"], mix.inputs[1])
    l.new(emis.outputs["Emission"], mix.inputs[2])
    l.new(mix.outputs["Shader"], out.inputs["Surface"])

    aura.data.materials.clear()
    aura.data.materials.append(aura_mat)

    return aura, aura_mat, emis


def create_sparks(tool):
    spark_mat = bpy.data.materials.new("Spark_Mat")
    spark_mat.use_nodes = True
    n = spark_mat.node_tree.nodes
    l = spark_mat.node_tree.links
    n.clear()

    out = n.new("ShaderNodeOutputMaterial")
    out.location = (360, 120)
    emis = n.new("ShaderNodeEmission")
    emis.location = (120, 120)
    emis.inputs["Strength"].default_value = 3.0
    l.new(emis.outputs["Emission"], out.inputs["Surface"])

    rnd = Random(2026)
    sparks = []
    for i in range(12):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=rnd.uniform(0.0013, 0.0028))
        s = bpy.context.object
        s.name = f"Spark_{i:02d}"
        s.parent = tool
        s.location = (
            rnd.uniform(-0.027, 0.027),
            rnd.uniform(0.030, 0.073),
            rnd.uniform(0.035, 0.060),
        )
        s.data.materials.clear()
        s.data.materials.append(spark_mat)
        sparks.append(s)

    return sparks, spark_mat, emis


def create_overlay(cam):
    badge_mat = bpy.data.materials.new("Badge_Mat")
    badge_mat.use_nodes = True
    bn = badge_mat.node_tree.nodes
    bl = badge_mat.node_tree.links
    bn.clear()
    bout = bn.new("ShaderNodeOutputMaterial")
    bout.location = (380, 120)
    bemis = bn.new("ShaderNodeEmission")
    bemis.location = (130, 120)
    bemis.inputs["Strength"].default_value = 1.6
    bl.new(bemis.outputs["Emission"], bout.inputs["Surface"])

    text_mat = bpy.data.materials.new("Card_Text_Mat")
    text_mat.use_nodes = True
    tn = text_mat.node_tree.nodes
    tl = text_mat.node_tree.links
    tn.clear()
    tout = tn.new("ShaderNodeOutputMaterial")
    tout.location = (360, 120)
    temis = tn.new("ShaderNodeEmission")
    temis.location = (120, 120)
    temis.inputs["Color"].default_value = (0.96, 0.97, 0.99, 1.0)
    temis.inputs["Strength"].default_value = 1.2
    tl.new(temis.outputs["Emission"], tout.inputs["Surface"])

    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.0, 0.0, 0.0))
    badge = bpy.context.object
    badge.name = "Badge_BG"
    badge.parent = cam
    badge.location = (-0.16, 0.15, -0.52)
    badge.scale = (0.09, 0.032, 1.0)
    badge.data.materials.clear()
    badge.data.materials.append(badge_mat)

    bpy.ops.object.text_add(location=(0.0, 0.0, 0.0))
    rarity_text = bpy.context.object
    rarity_text.name = "Card_RarityText"
    rarity_text.parent = cam
    rarity_text.location = (-0.205, 0.138, -0.515)
    rarity_text.data.body = "R1"
    rarity_text.data.size = 0.036
    rarity_text.data.extrude = 0.001
    rarity_text.data.align_x = "LEFT"
    rarity_text.data.align_y = "CENTER"
    rarity_text.data.materials.clear()
    rarity_text.data.materials.append(text_mat)

    bpy.ops.object.text_add(location=(0.0, 0.0, 0.0))
    label_text = bpy.context.object
    label_text.name = "Card_MEDOKText"
    label_text.parent = cam
    label_text.location = (-0.23, -0.20, -0.51)
    label_text.data.body = "MEDOK"
    label_text.data.size = 0.031
    label_text.data.extrude = 0.001
    label_text.data.align_x = "LEFT"
    label_text.data.align_y = "CENTER"
    label_text.data.materials.clear()
    label_text.data.materials.append(text_mat)

    return badge_mat, bemis, rarity_text


def apply_rarity_visual(
    tier_code,
    tier,
    screen_emission_node,
    aura_emission_node,
    spark_emission_node,
    sparks,
    badge_emission_node,
    rarity_text,
):
    color = tier["color"]

    screen_emission_node.inputs["Color"].default_value = color
    screen_emission_node.inputs["Strength"].default_value = tier["screen_strength"]

    aura_emission_node.inputs["Color"].default_value = color
    aura_emission_node.inputs["Strength"].default_value = tier["aura_strength"]

    spark_emission_node.inputs["Color"].default_value = color
    spark_emission_node.inputs["Strength"].default_value = 2.8 if tier_code != "R5" else 3.5

    badge_emission_node.inputs["Color"].default_value = color
    badge_emission_node.inputs["Strength"].default_value = 1.6 if tier_code != "R5" else 2.1

    rarity_text.data.body = f"{tier_code}  {tier['tier_name']}"

    for idx, s in enumerate(sparks):
        s.hide_render = idx >= tier["spark_count"]


def render_cards(
    base_dir: Path,
    screen_emission_node,
    aura_emission_node,
    spark_emission_node,
    sparks,
    badge_emission_node,
    rarity_text,
):
    scene = bpy.context.scene
    for tier_code, tier in RARITY_DATA.items():
        apply_rarity_visual(
            tier_code=tier_code,
            tier=tier,
            screen_emission_node=screen_emission_node,
            aura_emission_node=aura_emission_node,
            spark_emission_node=spark_emission_node,
            sparks=sparks,
            badge_emission_node=badge_emission_node,
            rarity_text=rarity_text,
        )
        scene.render.filepath = str(base_dir / f"Shop_MEDOK_{tier_code}.png")
        bpy.ops.render.render(write_still=True)


def main():
    base_dir = Path(__file__).resolve().parent
    blend_path = base_dir / "Tool_MEDOK.blend"
    if not blend_path.exists():
        raise FileNotFoundError(f"Missing required file: {blend_path}")

    bpy.ops.wm.open_mainfile(filepath=str(blend_path))

    clear_previous_helpers()
    setup_render()
    cam = setup_camera_and_lights()
    create_background(cam)
    create_shadow_plane()
    tool = orient_tool()

    screen_mat = get_material("MEDOK_Screen")
    screen_emission = find_emission_node(screen_mat)

    _, _, aura_emission = create_aura_shell(tool)
    sparks, _, spark_emission = create_sparks(tool)
    _, badge_emission, rarity_text = create_overlay(cam)

    render_cards(
        base_dir=base_dir,
        screen_emission_node=screen_emission,
        aura_emission_node=aura_emission,
        spark_emission_node=spark_emission,
        sparks=sparks,
        badge_emission_node=badge_emission,
        rarity_text=rarity_text,
    )
    print("Shop cards rendered:")
    for tier_code in RARITY_DATA:
        print(str(base_dir / f"Shop_MEDOK_{tier_code}.png"))


if __name__ == "__main__":
    main()
