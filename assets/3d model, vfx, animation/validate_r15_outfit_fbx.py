import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parent
TARGETS = [
    "outfit_sang_ahli_season_exclusive.fbx",
    "royal_premium_tier_30.fbx",
    "royal_premium_tier_50.fbx",
]
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


def max_vertex_influences():
    max_inf = 0
    weighted_vertices = 0
    root_weighted = False
    for obj in meshes():
        index_to_name = {g.index: g.name for g in obj.vertex_groups}
        for vert in obj.data.vertices:
            active = [g for g in vert.groups if g.weight > 0.001]
            if active:
                weighted_vertices += 1
            max_inf = max(max_inf, len(active))
            for group in active:
                if index_to_name.get(group.group) in {"Root", "HumanoidRootNode"}:
                    root_weighted = True
    return max_inf, weighted_vertices, root_weighted


def validate(path):
    clear_scene()
    bpy.ops.import_scene.fbx(filepath=str(path))
    bones = []
    for arm in armatures():
        bones.extend([bone.name for bone in arm.data.bones])
    max_inf, weighted_vertices, root_weighted = max_vertex_influences()
    return {
        "fbx": path.name,
        "triangles": tri_count(),
        "armature_count": len(armatures()),
        "mesh_count": len(meshes()),
        "bones": bones,
        "all_r15_deform_bones_present": all(bone in bones for bone in R15_DEFORM_BONES),
        "has_root": "Root" in bones,
        "max_vertex_influences": max_inf,
        "weighted_vertices": weighted_vertices,
        "root_or_humanoidrootnode_weighted": root_weighted,
    }


def main():
    results = [validate(ROOT / name) for name in TARGETS]
    out = ROOT / "r15_outfit_fbx_validation_report_5k.json"
    out.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
