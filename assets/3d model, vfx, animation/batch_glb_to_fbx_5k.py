import json
import math
import os
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
MAX_TRIS = 5_000
DECIMATE_TARGET = 4_600


PROMPT_TASKS = {
    "royal_free_tier_5": {"asset": "cap", "rig": "no", "rig_type": "Static accessory/mesh", "animation": "no", "vfx": "Optional glow kecil"},
    "royal_premium_tier_5": {"asset": "cap", "rig": "no", "rig_type": "Static accessory/mesh", "animation": "no", "vfx": "Ya, aura crown"},
    "royal_free_tier_10": {"asset": "frame", "rig": "no", "rig_type": "UI/static model optional", "animation": "no", "vfx": "Optional UI shimmer"},
    "royal_premium_tier_10": {"asset": "compass amulet", "rig": "no", "rig_type": "Static mesh", "animation": "Optional idle spin", "vfx": "Ya"},
    "royal_free_tier_15": {"asset": "amulet badge", "rig": "no", "rig_type": "Static mesh", "animation": "no", "vfx": "Optional"},
    "royal_premium_tier_15": {"asset": "ghost orb pet", "rig": "yes", "rig_type": "Custom armature bones", "animation": "Ya, idle/follow/float", "vfx": "Ya"},
    "royal_free_tier_20": {"asset": "emote icon", "rig": "no model", "rig_type": "R15 untuk emote animation", "animation": "Ya", "vfx": "Optional"},
    "royal_premium_tier_20": {"asset": "staff", "rig": "no", "rig_type": "Static mesh", "animation": "Optional glow pulse", "vfx": "Ya"},
    "royal_free_tier_25": {"asset": "mask", "rig": "no", "rig_type": "Static accessory/mesh", "animation": "no", "vfx": "Optional"},
    "royal_premium_tier_25": {"asset": "lantern", "rig": "no", "rig_type": "Static mesh", "animation": "Optional flame flicker", "vfx": "Ya"},
    "royal_free_tier_30": {"asset": "title card", "rig": "no", "rig_type": "UI only/static", "animation": "no", "vfx": "UI VFX optional"},
    "royal_premium_tier_30": {"asset": "outfit upper", "rig": "yes", "rig_type": "R15 kalau humanoid wearable/preview", "animation": "Optional equip pose", "vfx": "Optional"},
    "royal_free_tier_35": {"asset": "badge", "rig": "no", "rig_type": "Static mesh/UI", "animation": "no", "vfx": "Optional"},
    "royal_premium_tier_35": {"asset": "mini kuntilanak pet", "rig": "yes", "rig_type": "Custom armature bones", "animation": "Ya, idle/follow/hover", "vfx": "Ya"},
    "royal_free_tier_40": {"asset": "camera skin", "rig": "no", "rig_type": "Static tool mesh", "animation": "Optional use animation via tool", "vfx": "Ya"},
    "royal_premium_tier_40": {"asset": "spirit wings", "rig": "yes", "rig_type": "Custom bones, bukan R15", "animation": "Ya, wing flap/idle", "vfx": "Ya"},
    "royal_free_tier_45": {"asset": "jimat amulet", "rig": "no", "rig_type": "Static mesh", "animation": "no", "vfx": "Optional"},
    "royal_premium_tier_45": {"asset": "wewe pet", "rig": "yes", "rig_type": "Custom armature bones", "animation": "Ya, idle/follow/hover", "vfx": "Ya"},
    "royal_free_tier_50": {"asset": "Barong mask", "rig": "no", "rig_type": "Static accessory/mesh", "animation": "Optional inspect", "vfx": "Ya"},
    "royal_premium_tier_50": {"asset": "elite outfit", "rig": "yes", "rig_type": "R15 kalau humanoid outfit/mannequin", "animation": "Optional pose/equip", "vfx": "Ya"},
    "royal_free_tier_55": {"asset": "survivor badge", "rig": "no", "rig_type": "Static mesh/UI", "animation": "no", "vfx": "Optional"},
    "royal_premium_tier_55": {"asset": "spirit crown", "rig": "no", "rig_type": "Static accessory/mesh", "animation": "Optional hover/spin", "vfx": "Ya"},
    "outfit_sang_ahli_season_exclusive": {"asset": "outfit", "rig": "yes", "rig_type": "R15 kalau humanoid outfit/mannequin", "animation": "Ya kalau jadi preview character", "vfx": "Ya"},
}

SPECIAL_RIG_TASKS = {
    "outfit_sang_ahli_season_exclusive",
    "royal_premium_tier_30",
    "royal_premium_tier_40",
    "royal_premium_tier_50",
}


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for datablock_collection in (
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.armatures,
        bpy.data.actions,
    ):
        for block in list(datablock_collection):
            if block.users == 0:
                datablock_collection.remove(block)


def mesh_objects():
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def armature_objects():
    return [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]


def triangle_count():
    count = 0
    for obj in mesh_objects():
        mesh = obj.data
        mesh.calc_loop_triangles()
        count += len(mesh.loop_triangles)
    return count


def apply_transforms():
    for obj in mesh_objects():
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        try:
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        except Exception:
            pass
        obj.select_set(False)


def dissolve_planar_detail():
    for obj in mesh_objects():
        bpy.ops.object.mode_set(mode="OBJECT")
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        try:
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.mesh.dissolve_limited(angle_limit=math.radians(3.0), use_dissolve_boundaries=False)
        except Exception:
            pass
        finally:
            try:
                bpy.ops.object.mode_set(mode="OBJECT")
            except Exception:
                pass
        obj.select_set(False)


def reduce_to_5k():
    before = triangle_count()
    if before > MAX_TRIS:
        dissolve_planar_detail()
        before = triangle_count()
    if before <= MAX_TRIS:
        return before, before

    ratio = max(0.02, min(1.0, DECIMATE_TARGET / float(before) * 0.96))
    for obj in mesh_objects():
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        modifier = obj.modifiers.new(name="CODX_Decimate_5k", type="DECIMATE")
        modifier.ratio = ratio
        modifier.use_collapse_triangulate = True
        try:
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        except Exception:
            obj.modifiers.remove(modifier)
        obj.select_set(False)

    after = triangle_count()
    passes = 0
    while after > MAX_TRIS and passes < 10:
        ratio = max(0.02, DECIMATE_TARGET / float(after) * 0.92)
        for obj in mesh_objects():
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            modifier = obj.modifiers.new(name=f"CODX_Decimate_5k_pass_{passes + 1}", type="DECIMATE")
            modifier.ratio = ratio
            modifier.use_collapse_triangulate = True
            try:
                bpy.ops.object.modifier_apply(modifier=modifier.name)
            except Exception:
                obj.modifiers.remove(modifier)
            obj.select_set(False)
        after = triangle_count()
        passes += 1
    if after > MAX_TRIS:
        dissolve_planar_detail()
        after = triangle_count()
    return before, after


def scene_bounds():
    objs = mesh_objects()
    if not objs:
        return Vector((0, 0, 0)), Vector((1, 1, 1))
    points = []
    for obj in objs:
        points.extend([obj.matrix_world @ Vector(corner) for corner in obj.bound_box])
    min_v = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    max_v = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return min_v, max_v


def simplify_ui_title_card():
    objs = mesh_objects()
    if not objs:
        return False
    min_v, max_v = scene_bounds()
    center = (min_v + max_v) * 0.5
    dims = max_v - min_v
    material = None
    largest = max(objs, key=lambda obj: len(obj.data.polygons))
    if largest.data.materials:
        material = largest.data.materials[0]

    axes = sorted([(dims.x, "x"), (dims.y, "y"), (dims.z, "z")], reverse=True)
    a1, a2 = axes[0][1], axes[1][1]

    def point(v1, v2):
        values = {"x": center.x, "y": center.y, "z": center.z}
        values[a1] = v1
        values[a2] = v2
        return (values["x"], values["y"], values["z"])

    ranges = {
        "x": (min_v.x, max_v.x),
        "y": (min_v.y, max_v.y),
        "z": (min_v.z, max_v.z),
    }
    lo1, hi1 = ranges[a1]
    lo2, hi2 = ranges[a2]
    verts = [point(lo1, lo2), point(hi1, lo2), point(hi1, hi2), point(lo1, hi2)]
    mesh = bpy.data.meshes.new("royal_free_tier_30_title_card_mesh")
    mesh.from_pydata(verts, [], [(0, 1, 2, 3)])
    mesh.update()
    uv_layer = mesh.uv_layers.new(name="UVMap")
    for loop, uv in zip(uv_layer.data, [(0, 0), (1, 0), (1, 1), (0, 1)]):
        loop.uv = uv
    plane = bpy.data.objects.new("royal_free_tier_30_title_card_plane", mesh)
    bpy.context.collection.objects.link(plane)
    if material:
        plane.data.materials.append(material)
    for obj in objs:
        bpy.data.objects.remove(obj, do_unlink=True)
    return True


def make_basic_armature(task_key, task):
    if armature_objects() or task.get("rig") != "yes":
        return None

    min_v, max_v = scene_bounds()
    center = (min_v + max_v) * 0.5
    height = max(0.1, max_v.z - min_v.z)
    width = max(0.1, max_v.x - min_v.x)
    depth = max(0.1, max_v.y - min_v.y)

    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm = bpy.context.object
    arm.name = f"{task_key}_Armature"
    arm.data.name = f"{task_key}_Rig"
    arm.show_in_front = True

    root = arm.data.edit_bones[0]
    root.name = "Root"
    root.head = (center.x, center.y, min_v.z)
    root.tail = (center.x, center.y, min_v.z + height * 0.25)

    def add_bone(name, head, tail, parent=root):
        bone = arm.data.edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        bone.parent = parent
        bone.use_connect = False
        return bone

    rig_type = task.get("rig_type", "").lower()
    if "r15" in rig_type:
        lower = add_bone("LowerTorso", (center.x, center.y, min_v.z + height * 0.32), (center.x, center.y, min_v.z + height * 0.50))
        upper = add_bone("UpperTorso", (center.x, center.y, min_v.z + height * 0.50), (center.x, center.y, min_v.z + height * 0.72), lower)
        add_bone("Head", (center.x, center.y, min_v.z + height * 0.72), (center.x, center.y, max_v.z), upper)
        add_bone("LeftUpperArm", (center.x, center.y, min_v.z + height * 0.66), (min_v.x, center.y, min_v.z + height * 0.54), upper)
        add_bone("RightUpperArm", (center.x, center.y, min_v.z + height * 0.66), (max_v.x, center.y, min_v.z + height * 0.54), upper)
        add_bone("LeftUpperLeg", (center.x - width * 0.14, center.y, min_v.z + height * 0.32), (center.x - width * 0.18, center.y, min_v.z), lower)
        add_bone("RightUpperLeg", (center.x + width * 0.14, center.y, min_v.z + height * 0.32), (center.x + width * 0.18, center.y, min_v.z), lower)
    elif "wing" in task.get("asset", "") or "sayap" in task.get("asset", ""):
        add_bone("sayap_kiri", (center.x, center.y, center.z), (min_v.x, center.y, center.z + height * 0.1))
        add_bone("sayap_kanan", (center.x, center.y, center.z), (max_v.x, center.y, center.z + height * 0.1))
    else:
        spine = add_bone("spine", (center.x, center.y, min_v.z + height * 0.2), (center.x, center.y, min_v.z + height * 0.68))
        add_bone("head_or_orb", (center.x, center.y, min_v.z + height * 0.68), (center.x, center.y, max_v.z), spine)
        add_bone("float_anchor", (center.x, center.y - depth * 0.25, center.z), (center.x, center.y - depth * 0.25, center.z + height * 0.2), root)

    bpy.ops.object.mode_set(mode="OBJECT")
    weight_meshes_to_armature(arm)
    return arm.name


def weight_meshes_to_armature(arm):
    bones = [bone for bone in arm.data.bones if bone.name != "Root"] or list(arm.data.bones)
    if not bones:
        return
    for obj in mesh_objects():
        for group in obj.vertex_groups:
            obj.vertex_groups.remove(group)
        groups = {bone.name: obj.vertex_groups.new(name=bone.name) for bone in bones}
        inv = obj.matrix_world.inverted()
        bone_points = {
            bone.name: inv @ (arm.matrix_world @ ((bone.head_local + bone.tail_local) * 0.5))
            for bone in bones
        }
        for vert in obj.data.vertices:
            closest = min(bone_points.items(), key=lambda item: (vert.co - item[1]).length)[0]
            groups[closest].add([vert.index], 1.0, "REPLACE")
        mod = obj.modifiers.new(name="Armature", type="ARMATURE")
        mod.object = arm


def add_prompt_metadata(source_name, task, tris_before, tris_after, rig_created):
    bpy.context.scene["prompt_task"] = json.dumps(task, ensure_ascii=False)
    bpy.context.scene["source_glb"] = source_name
    bpy.context.scene["triangles_before"] = tris_before
    bpy.context.scene["triangles_after"] = tris_after
    bpy.context.scene["max_triangles_target"] = MAX_TRIS
    if rig_created:
        bpy.context.scene["created_placeholder_rig"] = rig_created


def pack_images():
    for image in bpy.data.images:
        if image.source == "FILE" and not image.packed_file:
            try:
                image.pack()
            except Exception:
                pass


def export_fbx(out_path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in mesh_objects() + armature_objects():
        obj.select_set(True)
    if mesh_objects():
        bpy.context.view_layer.objects.active = mesh_objects()[0]
    bpy.ops.export_scene.fbx(
        filepath=str(out_path),
        use_selection=True,
        path_mode="COPY",
        embed_textures=True,
        add_leaf_bones=False,
        bake_anim=False,
        apply_scale_options="FBX_SCALE_UNITS",
        object_types={"MESH", "ARMATURE"},
    )


def task_key_for(path):
    return path.stem.strip()


def process_file(source_path):
    clear_scene()
    bpy.ops.import_scene.fbx(filepath=str(source_path))
    apply_transforms()
    key = task_key_for(source_path)
    task = PROMPT_TASKS.get(key, {"asset": key, "rig": "unknown", "rig_type": "Unknown", "animation": "Unknown", "vfx": "Unknown"})
    if key in SPECIAL_RIG_TASKS:
        return None
    if key == "royal_free_tier_30":
        simplify_ui_title_card()
    tris_before, tris_after = reduce_to_5k()
    rig_created = make_basic_armature(key, task)
    pack_images()
    add_prompt_metadata(source_path.name, task, tris_before, tris_after, rig_created)
    out_path = source_path.with_suffix(".fbx")
    export_fbx(out_path)
    return {
        "source": source_path.name,
        "fbx": out_path.name,
        "triangles_before": tris_before,
        "triangles_after": triangle_count(),
        "rig_task": task.get("rig"),
        "rig_type": task.get("rig_type"),
        "rig_created": rig_created,
        "animation_task": task.get("animation"),
        "vfx_task": task.get("vfx"),
    }


def main():
    reports = []
    for source_path in sorted(ROOT.glob("*.fbx")):
        key = task_key_for(source_path)
        task = PROMPT_TASKS.get(key)
        if task is None or key in SPECIAL_RIG_TASKS:
            continue
        reports.append(process_file(source_path))
    report_path = ROOT / "fbx_5k_export_report.json"
    report_path.write_text(json.dumps(reports, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(reports, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
