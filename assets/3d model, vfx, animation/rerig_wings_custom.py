from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
NAME = "royal_premium_tier_40"
MAX_TRIS = 5_000
DECIMATE_TARGET = 4_600


def clear():
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def meshes():
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def bounds():
    pts = []
    for obj in meshes():
        pts.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    return (
        Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))),
        Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts))),
    )


def remove_rigs():
    for obj in list(bpy.context.scene.objects):
        if obj.type == "ARMATURE":
            bpy.data.objects.remove(obj, do_unlink=True)
    for obj in meshes():
        for mod in list(obj.modifiers):
            if mod.type == "ARMATURE":
                obj.modifiers.remove(mod)
        for group in list(obj.vertex_groups):
            obj.vertex_groups.remove(group)


def tri_count():
    total = 0
    for obj in meshes():
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    return total


def decimate_to_limit():
    current = tri_count()
    for i in range(10):
        if current <= MAX_TRIS:
            break
        ratio = max(0.02, min(1.0, DECIMATE_TARGET / float(current) * 0.94))
        for obj in meshes():
            bpy.ops.object.select_all(action="DESELECT")
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            mod = obj.modifiers.new(name=f"CODX_Wing_Decimate_{i + 1}", type="DECIMATE")
            mod.ratio = ratio
            mod.use_collapse_triangulate = True
            try:
                bpy.ops.object.modifier_apply(modifier=mod.name)
            except Exception:
                obj.modifiers.remove(mod)
            obj.select_set(False)
        current = tri_count()


def create_wing_rig():
    min_v, max_v = bounds()
    c = (min_v + max_v) * 0.5
    h = max(max_v.z - min_v.z, 0.1)
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm = bpy.context.object
    arm.name = f"{NAME}_Wing_Armature"
    arm.data.name = f"{NAME}_Wing_Rig"
    root = arm.data.edit_bones[0]
    root.name = "Root"
    root.head = (c.x, c.y, c.z - h * 0.1)
    root.tail = (c.x, c.y, c.z + h * 0.1)
    root.use_deform = False

    def add(name, head, tail, parent=root):
        b = arm.data.edit_bones.new(name)
        b.head = head
        b.tail = tail
        b.parent = parent
        b.use_connect = False
        return b

    l1 = add("sayap_kiri", (c.x, c.y, c.z + h * 0.1), (min_v.x, c.y, c.z + h * 0.15))
    r1 = add("sayap_kanan", (c.x, c.y, c.z + h * 0.1), (max_v.x, c.y, c.z + h * 0.15))
    add("sayap_kiri_tip", (min_v.x, c.y, c.z + h * 0.15), (min_v.x, c.y, max_v.z), l1)
    add("sayap_kanan_tip", (max_v.x, c.y, c.z + h * 0.15), (max_v.x, c.y, max_v.z), r1)
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def assign_weights(arm):
    deform = [b for b in arm.data.bones if b.use_deform]
    for obj in meshes():
        groups = {b.name: obj.vertex_groups.new(name=b.name) for b in deform}
        inv = obj.matrix_world.inverted()
        centers = {
            b.name: inv @ (arm.matrix_world @ ((b.head_local + b.tail_local) * 0.5))
            for b in deform
        }
        for v in obj.data.vertices:
            ranked = sorted(centers.items(), key=lambda item: (v.co - item[1]).length)[:2]
            weights = [(name, 1.0 / (((v.co - pos).length + 0.0001) ** 2)) for name, pos in ranked]
            total = sum(w for _, w in weights)
            for name, w in weights:
                groups[name].add([v.index], w / total, "ADD")
        mod = obj.modifiers.new("Armature", "ARMATURE")
        mod.object = arm


def export():
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes() + [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]:
        obj.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=str(ROOT / f"{NAME}.fbx"),
        use_selection=True,
        object_types={"MESH", "ARMATURE"},
        path_mode="COPY",
        embed_textures=True,
        add_leaf_bones=False,
        bake_anim=False,
        apply_scale_options="FBX_SCALE_UNITS",
    )


clear()
bpy.ops.import_scene.fbx(filepath=str(ROOT / f"{NAME}.fbx"))
remove_rigs()
decimate_to_limit()
armature = create_wing_rig()
assign_weights(armature)
export()
print("rerigged custom wing bones for", NAME, "triangles", tri_count())
