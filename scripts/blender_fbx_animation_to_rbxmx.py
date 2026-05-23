import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

import bpy
from mathutils import Matrix


ROBLOX_SCHEMA = "http://www.roblox.com/roblox.xsd"
SY = Matrix(
    (
        (1.0, 0.0, 0.0, 0.0),
        (0.0, -1.0, 0.0, 0.0),
        (0.0, 0.0, 1.0, 0.0),
        (0.0, 0.0, 0.0, 1.0),
    )
)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for collection in (
        bpy.data.actions,
        bpy.data.armatures,
        bpy.data.meshes,
        bpy.data.objects,
    ):
        for item in list(collection):
            collection.remove(item)


def import_fbx(path):
    clear_scene()
    bpy.ops.import_scene.fbx(filepath=path)


def get_single_armature():
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    if len(armatures) != 1:
        raise RuntimeError(f"Expected exactly one armature, found {len(armatures)}")
    return armatures[0]


def get_mesh_name(armature):
    children = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj.parent == armature]
    if children:
        return sorted(children, key=lambda obj: obj.name)[0].name
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        return "node_0"
    return sorted(meshes, key=lambda obj: obj.name)[0].name


def get_single_action():
    actions = list(bpy.data.actions)
    if len(actions) != 1:
        raise RuntimeError(f"Expected exactly one action, found {len(actions)}")
    return actions[0]


def safe_referent(seed):
    safe = re.sub(r"[^A-Za-z0-9]", "", seed).upper()[:24]
    return f"RBX{safe:0<29}"[:32]


def add_text(parent, tag, name, value):
    child = ET.SubElement(parent, tag, {"name": name})
    child.text = str(value)
    return child


def add_empty(parent, tag, name):
    child = ET.SubElement(parent, tag, {"name": name})
    child.text = ""
    return child


def add_common_instance_props(parent, name):
    add_empty(parent, "BinaryString", "AttributesSerialize")
    add_text(parent, "SecurityCapabilities", "Capabilities", "0")
    add_text(parent, "bool", "DefinesCapabilities", "false")
    add_text(parent, "string", "Name", name)
    add_text(parent, "int64", "SourceAssetId", "-1")
    add_empty(parent, "BinaryString", "Tags")


def add_cframe(parent, matrix):
    cf = ET.SubElement(parent, "CoordinateFrame", {"name": "CFrame"})
    values = {
        "X": matrix[0][3],
        "Y": matrix[1][3],
        "Z": matrix[2][3],
        "R00": matrix[0][0],
        "R01": matrix[0][1],
        "R02": matrix[0][2],
        "R10": matrix[1][0],
        "R11": matrix[1][1],
        "R12": matrix[1][2],
        "R20": matrix[2][0],
        "R21": matrix[2][1],
        "R22": matrix[2][2],
    }
    for key, value in values.items():
        element = ET.SubElement(cf, key)
        element.text = format_float(value)


def format_float(value):
    value = float(value)
    if abs(value) < 1e-12:
        value = 0.0
    return f"{value:.9g}"


def pose_matrix_from_blender(matrix):
    return SY @ matrix @ SY


def rotation_y_180():
    return Matrix(
        (
            (-1.0, 0.0, 0.0, 0.0),
            (0.0, 1.0, 0.0, 0.0),
            (0.0, 0.0, -1.0, 0.0),
            (0.0, 0.0, 0.0, 1.0),
        )
    )


def identity():
    return Matrix.Identity(4)


def add_pose(parent, name, matrix, referent_seed):
    item = ET.SubElement(parent, "Item", {"class": "Pose", "referent": safe_referent(referent_seed)})
    props = ET.SubElement(item, "Properties")
    add_cframe(props, matrix)
    add_text(props, "token", "EasingDirection", "0")
    add_text(props, "token", "EasingStyle", "0")
    add_text(props, "float", "Weight", "1")
    add_common_instance_props(props, name)
    return item


def add_bone_pose_tree(parent, armature, bone, frame_index):
    pose_bone = armature.pose.bones.get(bone.name)
    if pose_bone is None:
        raise RuntimeError(f"Pose bone not found: {bone.name}")
    item = add_pose(parent, bone.name, pose_matrix_from_blender(pose_bone.matrix_basis.copy()), f"{frame_index}-{bone.name}")
    for child in bone.children:
        add_bone_pose_tree(item, armature, child, frame_index)


def add_keyframe(parent, time_value, frame_index, armature, mesh_name, source_stem):
    item = ET.SubElement(parent, "Item", {"class": "Keyframe", "referent": safe_referent(f"keyframe-{frame_index}")})
    props = ET.SubElement(item, "Properties")
    add_text(props, "float", "Time", format_float(time_value))
    add_common_instance_props(props, "Keyframe")

    mesh_pose = add_pose(item, mesh_name, identity(), f"{frame_index}-{mesh_name}")
    root_bones = [bone for bone in armature.data.bones if bone.parent is None]
    for bone in root_bones:
        add_bone_pose_tree(mesh_pose, armature, bone, frame_index)

    add_pose(item, source_stem, rotation_y_180(), f"{frame_index}-{source_stem}")
    add_pose(item, armature.name, identity(), f"{frame_index}-{armature.name}")


def build_xml(armature, mesh_name, source_stem, action, fps):
    root = ET.Element(
        "roblox",
        {
            "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
            "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
            "xsi:noNamespaceSchemaLocation": ROBLOX_SCHEMA,
            "version": "4",
        },
    )
    meta = ET.SubElement(root, "Meta", {"name": "ExplicitAutoJoints"})
    meta.text = "true"
    ext_null = ET.SubElement(root, "External")
    ext_null.text = "null"
    ext_nil = ET.SubElement(root, "External")
    ext_nil.text = "nil"

    kfs = ET.SubElement(root, "Item", {"class": "KeyframeSequence", "referent": safe_referent("keyframe-sequence")})
    props = ET.SubElement(kfs, "Properties")
    add_text(props, "float", "AuthoredHipHeight", "2")
    add_text(props, "BinaryString", "GuidBinaryString", "AAAAAAAAAAAAAAAAAAAAAA==")
    add_text(props, "bool", "Loop", "true")
    add_text(props, "token", "Priority", "2")
    add_common_instance_props(props, f"{source_stem}_Scene")

    start = int(round(action.frame_range[0]))
    end = int(round(action.frame_range[1]))
    for output_index, frame in enumerate(range(start, end + 1)):
        bpy.context.scene.frame_set(frame)
        time_value = output_index / fps
        add_keyframe(kfs, time_value, output_index, armature, mesh_name, source_stem)

    return root, start, end


def write_xml(root, output_path):
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    tree = ET.ElementTree(root)
    tree.write(output_path, encoding="utf-8", xml_declaration=False, short_empty_elements=False)


def convert(input_path, output_path, name=None, fps=30.0):
    import_fbx(input_path)
    armature = get_single_armature()
    action = get_single_action()
    armature.animation_data_create()
    armature.animation_data.action = action
    mesh_name = get_mesh_name(armature)
    source_stem = name or Path(input_path).stem
    root, start, end = build_xml(armature, mesh_name, source_stem, action, fps)
    write_xml(root, output_path)
    return {
        "input": input_path,
        "output": output_path,
        "name": source_stem,
        "armature": armature.name,
        "mesh": mesh_name,
        "action": action.name,
        "frameStart": start,
        "frameEnd": end,
        "keyframes": end - start + 1,
        "fps": fps,
        "boneCount": len(armature.data.bones),
    }


def convert_plan(plan_path, output_root, fps=30.0, only_missing=False, keys=None):
    with open(plan_path, "r", encoding="utf-8-sig") as handle:
        plan = json.load(handle)
    if isinstance(plan, dict):
        plan = [plan]

    selected_keys = set(keys or [])
    rows = []
    for item in plan:
        key = item.get("key") or ""
        if selected_keys and key not in selected_keys:
            continue

        source_path = item.get("sourceFbxPath") or item.get("sourceFbx")
        if not source_path:
            rows.append({"key": key, "status": "error", "error": "missing sourceFbxPath/sourceFbx"})
            continue
        if not os.path.isabs(source_path):
            source_path = os.path.abspath(source_path)

        output_path = item.get("filePath")
        if not output_path:
            output_path = os.path.join(output_root, item["file"])
        if not os.path.isabs(output_path):
            output_path = os.path.abspath(output_path)

        if only_missing and os.path.exists(output_path):
            rows.append({"key": key, "status": "skipped_existing", "output": output_path})
            continue

        try:
            row = convert(source_path, output_path, Path(source_path).stem, fps)
            row["key"] = key
            row["status"] = "converted"
            rows.append(row)
        except Exception as exc:
            rows.append(
                {
                    "key": key,
                    "input": source_path,
                    "output": output_path,
                    "status": "error",
                    "error": str(exc),
                }
            )

    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default=None)
    parser.add_argument("--output", default=None)
    parser.add_argument("--plan", default=None)
    parser.add_argument("--output-root", default=None)
    parser.add_argument("--name", default=None)
    parser.add_argument("--fps", type=float, default=30.0)
    parser.add_argument("--report", default=None)
    parser.add_argument("--only-missing", action="store_true")
    parser.add_argument("--key", action="append", default=[])
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])

    if args.plan:
        if not args.output_root:
            raise RuntimeError("--output-root is required with --plan")
        result = convert_plan(args.plan, args.output_root, args.fps, args.only_missing, args.key)
        errors = [row for row in result if row.get("status") == "error"]
        text = json.dumps(result, indent=2)
        if args.report:
            os.makedirs(os.path.dirname(args.report), exist_ok=True)
            with open(args.report, "w", encoding="utf-8") as handle:
                handle.write(text)
                handle.write("\n")
        counts = {}
        for row in result:
            counts[row.get("status", "unknown")] = counts.get(row.get("status", "unknown"), 0) + 1
        print(json.dumps({"items": len(result), "counts": counts, "report": args.report}, indent=2))
        if errors:
            raise RuntimeError(f"{len(errors)} conversion item(s) failed")
        return

    if not args.input or not args.output:
        raise RuntimeError("--input and --output are required for single-file conversion")

    result = convert(args.input, args.output, args.name, args.fps)
    text = json.dumps(result, indent=2)
    if args.report:
        os.makedirs(os.path.dirname(args.report), exist_ok=True)
        with open(args.report, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.write("\n")
    print(text)


if __name__ == "__main__":
    main()
