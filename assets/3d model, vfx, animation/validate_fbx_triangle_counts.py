import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parent


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def triangle_count():
    count = 0
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        obj.data.calc_loop_triangles()
        count += len(obj.data.loop_triangles)
    return count


def main():
    results = []
    for fbx in sorted(ROOT.glob("*.fbx")):
        clear_scene()
        bpy.ops.import_scene.fbx(filepath=str(fbx))
        results.append({"fbx": fbx.name, "triangles": triangle_count()})
    out = ROOT / "fbx_5k_validation_report.json"
    out.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
