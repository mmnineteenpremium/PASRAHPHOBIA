import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parent
ANIM_DIR = ROOT / "animations_fbx"


def clear_scene():
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def triangle_count():
    count = 0
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            obj.data.calc_loop_triangles()
            count += len(obj.data.loop_triangles)
    return count


def main():
    results = []
    for path in sorted(ANIM_DIR.glob("*.fbx")):
        clear_scene()
        bpy.ops.import_scene.fbx(filepath=str(path))
        results.append(
            {
                "fbx": str(path.relative_to(ROOT)),
                "triangles": triangle_count(),
                "armatures": len([obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]),
                "meshes": len([obj for obj in bpy.context.scene.objects if obj.type == "MESH"]),
            }
        )
    out = ROOT / "animation_fbx_validation_report.json"
    out.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
