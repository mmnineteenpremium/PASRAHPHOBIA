import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
TARGETS = [
    "outfit_sang_ahli_season_exclusive",
    "royal_premium_tier_30",
    "royal_premium_tier_50",
]
MAX_TRIS = 5_000
DECIMATE_TARGET = 4_600

R15_DEFORM_BONES = [
    "LowerTorso",
    "UpperTorso",
    "Head",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
]


def clear_scene():
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for collection in (
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.armatures,
        bpy.data.actions,
    ):
        for item in list(collection):
            if item.users == 0:
                collection.remove(item)


def meshes():
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def armatures():
    return [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]


def tri_count():
    total = 0
    for obj in meshes():
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    return total


def apply_mesh_transforms():
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
    for obj in meshes():
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        try:
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        except Exception:
            pass
        obj.select_set(False)


def dissolve_planar_detail():
    for obj in meshes():
        bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        try:
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.mesh.dissolve_limited(angle_limit=math.radians(2.0), use_dissolve_boundaries=False)
        except Exception:
            pass
        finally:
            bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
        obj.select_set(False)


def decimate_to_limit():
    before = tri_count()
    if before > MAX_TRIS:
        dissolve_planar_detail()
    current = tri_count()
    if current <= MAX_TRIS:
        return before, current
    for i in range(10):
        ratio = max(0.02, min(1.0, DECIMATE_TARGET / float(current) * 0.94))
        for obj in meshes():
            bpy.ops.object.select_all(action="DESELECT")
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            mod = obj.modifiers.new(name=f"CODX_R15_Decimate_{i+1}", type="DECIMATE")
            mod.ratio = ratio
            mod.use_collapse_triangulate = True
            try:
                bpy.ops.object.modifier_apply(modifier=mod.name)
            except Exception:
                obj.modifiers.remove(mod)
            obj.select_set(False)
        current = tri_count()
        if current <= MAX_TRIS:
            break
    return before, current


def scene_bounds():
    objs = meshes()
    points = []
    for obj in objs:
        points.extend([obj.matrix_world @ Vector(corner) for corner in obj.bound_box])
    if not points:
        return Vector((-1, -0.2, 0)), Vector((1, 0.2, 2))
    return (
        Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points))),
        Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points))),
    )


def create_r15_armature(name):
    min_v, max_v = scene_bounds()
    center = (min_v + max_v) * 0.5
    size = max_v - min_v
    height = max(size.z, 0.1)
    width = max(size.x, 0.1)
    depth = max(size.y, 0.1)

    z = {
        "foot": min_v.z + height * 0.02,
        "knee": min_v.z + height * 0.26,
        "hip": min_v.z + height * 0.47,
        "waist": min_v.z + height * 0.58,
        "chest": min_v.z + height * 0.75,
        "neck": min_v.z + height * 0.84,
        "head": max_v.z,
    }
    x = {
        "center": center.x,
        "hip_l": center.x - width * 0.16,
        "hip_r": center.x + width * 0.16,
        "shoulder_l": center.x - width * 0.33,
        "shoulder_r": center.x + width * 0.33,
        "elbow_l": center.x - width * 0.48,
        "elbow_r": center.x + width * 0.48,
        "hand_l": min_v.x,
        "hand_r": max_v.x,
    }
    y = center.y - depth * 0.02

    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm = bpy.context.object
    arm.name = f"{name}_R15_Armature"
    arm.data.name = f"{name}_R15_Rig"
    arm.show_in_front = True

    root = arm.data.edit_bones[0]
    root.name = "Root"
    root.head = (x["center"], y, min_v.z)
    root.tail = (x["center"], y, z["hip"])
    root.use_deform = False

    def bone(bone_name, head, tail, parent, connect=False, deform=True):
        b = arm.data.edit_bones.new(bone_name)
        b.head = head
        b.tail = tail
        b.parent = parent
        b.use_connect = connect
        b.use_deform = deform
        return b

    lower = bone("LowerTorso", (x["center"], y, z["hip"]), (x["center"], y, z["waist"]), root)
    upper = bone("UpperTorso", (x["center"], y, z["waist"]), (x["center"], y, z["neck"]), lower, True)
    bone("Head", (x["center"], y, z["neck"]), (x["center"], y, z["head"]), upper, True)

    lua = bone("LeftUpperArm", (x["shoulder_l"], y, z["chest"]), (x["elbow_l"], y, z["waist"]), upper)
    lla = bone("LeftLowerArm", (x["elbow_l"], y, z["waist"]), (x["hand_l"], y, z["hip"]), lua, True)
    bone("LeftHand", (x["hand_l"], y, z["hip"]), (x["hand_l"], y, z["hip"] - height * 0.10), lla, True)
    rua = bone("RightUpperArm", (x["shoulder_r"], y, z["chest"]), (x["elbow_r"], y, z["waist"]), upper)
    rla = bone("RightLowerArm", (x["elbow_r"], y, z["waist"]), (x["hand_r"], y, z["hip"]), rua, True)
    bone("RightHand", (x["hand_r"], y, z["hip"]), (x["hand_r"], y, z["hip"] - height * 0.10), rla, True)

    lul = bone("LeftUpperLeg", (x["hip_l"], y, z["hip"]), (x["hip_l"], y, z["knee"]), lower)
    lll = bone("LeftLowerLeg", (x["hip_l"], y, z["knee"]), (x["hip_l"], y, z["foot"]), lul, True)
    bone("LeftFoot", (x["hip_l"], y, z["foot"]), (x["hip_l"], y - depth * 0.35, z["foot"]), lll, True)
    rul = bone("RightUpperLeg", (x["hip_r"], y, z["hip"]), (x["hip_r"], y, z["knee"]), lower)
    rll = bone("RightLowerLeg", (x["hip_r"], y, z["knee"]), (x["hip_r"], y, z["foot"]), rul, True)
    bone("RightFoot", (x["hip_r"], y, z["foot"]), (x["hip_r"], y - depth * 0.35, z["foot"]), rll, True)

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def remove_existing_rigs_and_weights():
    for arm in armatures():
        bpy.data.objects.remove(arm, do_unlink=True)
    for obj in meshes():
        for mod in list(obj.modifiers):
            if mod.type == "ARMATURE":
                obj.modifiers.remove(mod)
        for group in list(obj.vertex_groups):
            obj.vertex_groups.remove(group)


def bind_auto_weights(arm):
    mesh_objs = meshes()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in mesh_objs:
        obj.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    try:
        bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    except Exception:
        pass
    clean_weights(arm)
    max_inf, _ = max_vertex_influences()
    if max_inf == 0:
        assign_spatial_r15_weights(arm)
        clean_weights(arm)


def distance_to_segment(point, a, b):
    ab = b - a
    denom = ab.length_squared
    if denom <= 0.000001:
        return (point - a).length
    t = max(0.0, min(1.0, (point - a).dot(ab) / denom))
    nearest = a + ab * t
    return (point - nearest).length


def assign_spatial_r15_weights(arm):
    bones = [b for b in arm.data.bones if b.use_deform and b.name in R15_DEFORM_BONES]
    for obj in meshes():
        for group in list(obj.vertex_groups):
            obj.vertex_groups.remove(group)
        groups = {bone.name: obj.vertex_groups.new(name=bone.name) for bone in bones}
        inv = obj.matrix_world.inverted()
        bone_segments = {
            bone.name: (
                inv @ (arm.matrix_world @ bone.head_local),
                inv @ (arm.matrix_world @ bone.tail_local),
            )
            for bone in bones
        }
        for vert in obj.data.vertices:
            distances = []
            for bone_name, (head, tail) in bone_segments.items():
                dist = distance_to_segment(vert.co, head, tail)
                distances.append((bone_name, dist))
            closest = sorted(distances, key=lambda item: item[1])[:4]
            weights = []
            for bone_name, dist in closest:
                weights.append((bone_name, 1.0 / ((dist + 0.0001) ** 2)))
            total = sum(weight for _, weight in weights) or 1.0
            for bone_name, weight in weights:
                groups[bone_name].add([vert.index], weight / total, "ADD")
        mod = obj.modifiers.new(name="Armature", type="ARMATURE")
        mod.object = arm


def clean_weights(arm):
    allowed = set(R15_DEFORM_BONES)
    for obj in meshes():
        for group in list(obj.vertex_groups):
            if group.name not in allowed:
                obj.vertex_groups.remove(group)
        arm_mod = next((m for m in obj.modifiers if m.type == "ARMATURE"), None)
        if arm_mod is None:
            arm_mod = obj.modifiers.new(name="Armature", type="ARMATURE")
        arm_mod.object = arm
        limit = obj.modifiers.new(name="CODX_Limit_4_Influences", type="WEIGHTED_NORMAL")
        obj.modifiers.remove(limit)
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        try:
            bpy.ops.object.vertex_group_limit_total(limit=4)
            bpy.ops.object.vertex_group_clean(group_select_mode="ALL", limit=0.001)
            bpy.ops.object.vertex_group_normalize_all(lock_active=False)
        except Exception:
            pass
        obj.select_set(False)


def max_vertex_influences():
    max_inf = 0
    root_weighted = False
    for obj in meshes():
        index_to_name = {g.index: g.name for g in obj.vertex_groups}
        for v in obj.data.vertices:
            active = [g for g in v.groups if g.weight > 0.001]
            max_inf = max(max_inf, len(active))
            for g in active:
                if index_to_name.get(g.group) in {"Root", "HumanoidRootNode"}:
                    root_weighted = True
    return max_inf, root_weighted


def pack_images():
    for image in bpy.data.images:
        if image.source == "FILE" and not image.packed_file:
            try:
                image.pack()
            except Exception:
                pass


def export_fbx(path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes() + armatures():
        obj.select_set(True)
    if armatures():
        bpy.context.view_layer.objects.active = armatures()[0]
    bpy.ops.export_scene.fbx(
        filepath=str(path),
        use_selection=True,
        object_types={"MESH", "ARMATURE"},
        path_mode="COPY",
        embed_textures=True,
        add_leaf_bones=False,
        bake_anim=False,
        apply_scale_options="FBX_SCALE_UNITS",
    )


def process(name):
    clear_scene()
    source = ROOT / f"{name}.fbx"
    bpy.ops.import_scene.fbx(filepath=str(source))
    apply_mesh_transforms()
    remove_existing_rigs_and_weights()
    tris_before, tris_after = decimate_to_limit()
    arm = create_r15_armature(name)
    bind_auto_weights(arm)
    pack_images()
    bpy.context.scene["rig_type"] = "Roblox R15-style deform skeleton"
    bpy.context.scene["bone_influence_limit"] = 4
    bpy.context.scene["root_weighted"] = False
    export_fbx(ROOT / f"{name}.fbx")
    max_inf, root_weighted = max_vertex_influences()
    return {
        "asset": name,
        "fbx": f"{name}.fbx",
        "triangles_before": tris_before,
        "triangles_after": tri_count(),
        "bones": [b.name for b in arm.data.bones],
        "required_r15_deform_bones_present": all(b in arm.data.bones for b in R15_DEFORM_BONES),
        "max_vertex_influences": max_inf,
        "root_or_humanoidrootnode_weighted": root_weighted,
        "export_path_mode": "COPY",
        "embed_textures": True,
    }


def main():
    reports = [process(name) for name in TARGETS]
    report_path = ROOT / "r15_outfit_rerig_report_5k.json"
    report_path.write_text(json.dumps(reports, indent=2), encoding="utf-8")
    print(json.dumps(reports, indent=2))


if __name__ == "__main__":
    main()
