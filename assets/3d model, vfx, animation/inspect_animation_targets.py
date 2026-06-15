import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parent
TARGETS = [
    "royal_premium_tier_15.fbx",
    "royal_premium_tier_35.fbx",
    "royal_premium_tier_40.fbx",
    "royal_premium_tier_45.fbx",
    "royal_premium_tier_10.fbx",
    "royal_premium_tier_20.fbx",
    "royal_premium_tier_25.fbx",
    "royal_premium_tier_55.fbx",
]


def clear():
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


result = []
for target in TARGETS:
    clear()
    bpy.ops.import_scene.fbx(filepath=str(ROOT / target))
    result.append(
        {
            "file": target,
            "meshes": [obj.name for obj in bpy.context.scene.objects if obj.type == "MESH"],
            "armatures": [
                {"name": obj.name, "bones": [bone.name for bone in obj.data.bones]}
                for obj in bpy.context.scene.objects
                if obj.type == "ARMATURE"
            ],
        }
    )
print(json.dumps(result, indent=2))
