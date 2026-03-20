# --------------------------------------------------------------
#  WEWE GOMBEL – Ghost generator with LOD0 / LOD1 / LOD2
#  (c) 2026, your-name / PASRAH project
# --------------------------------------------------------------

import bpy
import bmesh
from mathutils import Vector, Matrix, Euler
from math import radians

# ------------------------------------------------------------------
# 1?? Helper utilities
# ------------------------------------------------------------------

def clear_scene():
    """
    Remove *all* objects, meshes, materials etc.
    Works both in UI and background mode.
    """
    # Delete objects
    for obj in bpy.data.objects:
        bpy.data.objects.remove(obj, do_unlink=True)
    # Delete orphan data-blocks
    for block in bpy.data.meshes:
        bpy.data.meshes.remove(block, do_unlink=True)
    for block in bpy.data.materials:
        bpy.data.materials.remove(block, do_unlink=True)

def make_material(name, rgba):
    """
    Creates a Principled BSDF material with the given base colour.
    Returns the material datablock.
    """
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf is None:  # fallback – create one if the default was renamed
        bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs["Base Color"].default_value = rgba
    # Slight subsurface for that “ghostly” glow (optional)
    bsdf.inputs["Subsurface"].default_value = 0.05
    bsdf.inputs["Subsurface Color"].default_value = (rgba[0]*1.2,
                                                     rgba[1]*1.2,
                                                     rgba[2]*1.2, 1.0)
    return mat

def set_origin_to_bottom(obj):
    """
    Moves the mesh data so that the lowest Z-coordinate is at Z=0,
    then sets the object origin to (0,0,0) – i.e. right at the feet.
    This works for any mesh orientation.
    """
    # Ensure mesh data is up-to-date (apply any transforms first)
    bpy.context.view_layer.update()

    # Find the minimum Z in *object* space
    min_z = min((obj.matrix_world @ Vector(v)).z for v in obj.bound_box)

    # Translate the mesh *data* so that the bottom aligns with Z=0
    # (we move the vertices in local space; location stays unchanged)
    mesh = obj.data
    translation = Matrix.Translation((0, 0, -min_z))
    mesh.transform(translation)

    # Now the object origin is already at world Z=0 – just apply
    obj.location.z = 0.0
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

def smooth_object(obj):
    """
    Enables smooth shading and auto-smooth (useful for LOD0).
    """
    # Smooth shading
    for poly in obj.data.polygons:
        poly.use_smooth = True
    # Auto-smooth (if you want a 30° threshold, change the angle)
    obj.data.use_auto_smooth = True
    obj.data.auto_smooth_angle = radians(30.0)

# ------------------------------------------------------------------
# 2?? Core ghost geometry functions
# ------------------------------------------------------------------

def create_lod0(parent_collection, skin_mat):
    """
    Detailed ghost – a torso-cube + head-sphere + four limbs.
    Returns the resulting Object.
    """
    # Create a new empty mesh that we will fill with BMesh
    mesh = bpy.data.meshes.new("WeweGombel_LOD0_Mesh")
    obj  = bpy.data.objects.new("PASRAH_GHOST_WEWEGOMBEL_LOD0", mesh)
    parent_collection.objects.link(obj)

    bm = bmesh.new()

    # ---------- Torso (scaled cube) ----------
    bmesh.ops.create_cube(bm,
                          size=1.0,
                          matrix=Matrix.Translation((0, 0, 1.2)) @
                                 Matrix.Scale(0.25, 4, (1, 0, 0)) @
                                 Matrix.Scale(0.15, 4, (0, 1, 0)) @
                                 Matrix.Scale(0.6, 4, (0, 0, 1)))

    # ---------- Head (UV sphere) ----------
    bmesh.ops.create_uvsphere(bm,
                              u_segments=24,
                              v_segments=12,
                              diameter=0.4,
                              matrix=Matrix.Translation((0, 0, 1.8)))

    # ---------- Arms (cylinders) ----------
    arm_mat = Matrix.Rotation(radians(90), 4, 'X')
    for side in (-1, 1):
        arm_loc = Vector((0.35 * side, 0, 1.1))
        bmesh.ops.create_cone(bm,
                              cap_ends=True,
                              cap_tris=False,
                              segments=16,
                              radius1=0.07,
                              radius2=0.07,
                              depth=0.8,
                              matrix=Matrix.Translation(arm_loc) @ arm_mat)

    # ---------- Legs (cylinders) ----------
    leg_mat = Matrix.Rotation(radians(90), 4, 'X')
    for side in (-1, 1):
        leg_loc = Vector((0.1 * side, 0, 0.5))
        bmesh.ops.create_cone(bm,
                              cap_ends=True,
                              cap_tris=False,
                              segments=16,
                              radius1=0.09,
                              radius2=0.09,
                              depth=1.0,
                              matrix=Matrix.Translation(leg_loc) @ leg_mat)

    # Finish up
    bm.to_mesh(mesh)
    bm.free()

    # Assign material
    obj.data.materials.append(skin_mat)

    # Origin ? feet and smooth shading
    set_origin_to_bottom(obj)
    smooth_object(obj)

    # Custom LOD-distance property (you can drive this from a driver later)
    obj["lod_distance_0"] = 0.0   # visible from 0 m up to LOD 1 switch distance
    obj["lod_distance_1"] = 15.0  # after 15 m switch to LOD 1
    obj["lod_distance_2"] = 30.0  # after 30 m switch to LOD 2

    return obj


def create_lod1(parent_collection, skin_mat):
    """
    Simplified ghost – just a tall, scaled cube.
    Returns the resulting Object.
    """
    # Direct mesh creation – no BMesh required for a simple cube
    mesh = bpy.data.meshes.new("WeweGombel_LOD1_Mesh")
    obj  = bpy.data.objects.new("PASRAH_GHOST_WEWEGOMBEL_LOD1", mesh)
    parent_collection.objects.link(obj)

    # Create a cube primitive (size = 1) and then scale it.
    verts = [(-0.5, -0.5, -0.5),
             ( 0.5, -0.5, -0.5),
             ( 0.5,  0.5, -0.5),
             (-0.5,  0.5, -0.5),
             (-0.5, -0.5,  0.5),
             ( 0.5, -0.5,  0.5),
             ( 0.5,  0.5,  0.5),
             (-0.5,  0.5,  0.5)]

    # Apply the same scale as the detailed torso (x=0.25, y=0.15, z=1.2)
    scale = Matrix.Scale(0.25, 4, (1, 0, 0)) @ \
            Matrix.Scale(0.15, 4, (0, 1, 0)) @ \
            Matrix.Scale(1.2, 4, (0, 0, 1))

    transformed_verts = [scale @ Vector(v) + Vector((0, 0, 1.2)) for v in verts]

    faces = [(0, 1, 2, 3),
             (4, 5, 6, 7),
             (0, 1, 5, 4),
             (1, 2, 6, 5),
             (2, 3, 7, 6),
             (3, 0, 4, 7)]

    mesh.from_pydata(transformed_verts, [], faces)
    mesh.update()

    obj.data.materials.append(skin_mat)

    set_origin_to_bottom(obj)
    smooth_object(obj)  # optional – keeps shading consistent with LOD0

    obj["lod_distance_0"] = 0.0
    obj["lod_distance_1"] = 15.0
    obj["lod_distance_2"] = 30.0

    return obj


def create_lod2(parent_collection):
    """
    Ultra-low-poly ghost – a single plane that works as a billboard.
    The plane is oriented on the Y-axis (facing +Y).  To make it truly
    a “billboard”, you will have to rotate it per-frame in your engine
    (or use a simple driver that points the plane at the camera).
    """
    mesh = bpy.data.meshes.new("WeweGombel_LOD2_Mesh")
    obj  = bpy.data.objects.new("PASRAH_GHOST_WEWEGOMBEL_LOD2", mesh)
    parent_collection.objects.link(obj)

    # Each vertex is placed so the plane stands on the ground (Y-up)
    verts = [(-0.5, 0, 0),   # lower-left
             ( 0.5, 0, 0),   # lower-right
             ( 0.5, 0, 2),   # upper-right
             (-0.5, 0, 2)]   # upper-left

    # Scale the plane to roughly the same width/height as the LOD0 ghost
    scale = Matrix.Scale(0.5, 4, (1, 0, 0)) @ Matrix.Scale(2.0, 4, (0, 0, 1))
    verts = [scale @ Vector(v) for v in verts]

    faces = [(0, 1, 2, 3)]

    mesh.from_pydata(verts, [], faces)
    mesh.update()

    # ---- OPTIONAL: give the plane a transparent “ghost” material ----
    mat = bpy.data.materials.new(name="Ghost_Billboard")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    # Remove default Principled BSDF, replace with Transparent BSDF + Emission (glow)
    for n in nodes:
        nodes.remove(n)

    output = nodes.new(type='ShaderNodeOutputMaterial')
    mix = nodes.new(type='ShaderNodeMixShader')
    transp = nodes.new(type='ShaderNodeBsdfTransparent')
    emis = nodes.new(type='ShaderNodeEmission')
    tex_image = nodes.new(type='ShaderNodeTexImage')
    tex_image.interpolation = 'Closest'

    # Load a placeholder texture (make sure you have a texture called "wewe_gombel.png" in //textures/)
    # If you don’t have one, just leave the node disconnected – the plane will be fully transparent.
    # img = bpy.data.images.load(filepath=bpy.path.abspath("//textures/wewe_gombel.png"))
    # tex_image.image = img

    # Tone-down the emission – you can drive the strength with a driver later
    emis.inputs["Color"].default_value = (0.8, 0.9, 1.0, 0.7)
    emis.inputs["Strength"].default_value = 2.5

    # Connect nodes
    links.new(tex_image.outputs["Color"], emis.inputs["Color"])
    links.new(transp.outputs[0], mix.inputs[1])
    links.new(emis.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], output.inputs["Surface"])

    # Force the material to be transparent in the viewport/render
    mat.blend_method = 'BLEND'
    mat.shadow_method = 'NONE'

    obj.data.materials.append(mat)

    set_origin_to_bottom(obj)

    # LOD distance values – identical to the other objects for consistency
    obj["lod_distance_0"] = 0.0
    obj["lod_distance_1"] = 15.0
    obj["lod_distance_2"] = 30.0

    return obj

# ------------------------------------------------------------------
# 3?? Main driver – run everything
# ------------------------------------------------------------------

def generate_wewe_gombel():
    """
    Entry point – clears the scene, creates a collection, then builds
    LOD 0, 1, 2.  Returns a tuple (lod0, lod1, lod2) for further tweaking.
    """
    # 1?? Clear everything (safe for background mode)
    clear_scene()

    # 2?? Create a dedicated collection (helps later visibility toggling)
    coll = bpy.data.collections.new("PASRAH_GHOSTS")
    bpy.context.scene.collection.children.link(coll)

    # 3?? Shared material for LOD0&1 (dark skin tone)
    skin_mat = make_material("SkinMat", (0.25, 0.20, 0.20, 1.0))

    # 4?? Build the three LOD objects
    lod0 = create_lod0(coll, skin_mat)
    lod1 = create_lod1(coll, skin_mat)
    lod2 = create_lod2(coll)

    # 5?? (Optional) Parent LOD-levels together – useful for moving the whole ghost.
    #    We'll keep LOD0 as the “master” and make the others children.
    lod1.parent = lod0
    lod2.parent = lod0

    # 6?? Set a nice scene camera for a quick preview (optional)
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    coll.objects.link(cam)
    cam.location = (5, -8, 4)
    cam.rotation_euler = Euler((radians(60), 0, radians(45)), 'XYZ')
    bpy.context.scene.camera = cam

    # 7?? Return objects for any downstream script
    return lod0, lod1, lod2

# ------------------------------------------------------------------
# Run the generator when the script is executed
# ------------------------------------------------------------------
if __name__ == "__main__":
    lod0_obj, lod1_obj, lod2_obj = generate_wewe_gombel()
    print("? Wewe Gombel ghost generated:")
    print(f"    • LOD0 ? {lod0_obj.name}")
    print(f"    • LOD1 ? {lod1_obj.name}")
    print(f"    • LOD2 ? {lod2_obj.name}")

