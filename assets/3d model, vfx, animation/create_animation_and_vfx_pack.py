import json
import math
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parent
ANIM_DIR = ROOT / "animations_fbx"
VFX_DIR = ROOT / "roblox_vfx"
ANIM_DIR.mkdir(exist_ok=True)
VFX_DIR.mkdir(exist_ok=True)


def clear():
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.ops.object.mode_set.poll() else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def import_fbx(name):
    clear()
    bpy.ops.import_scene.fbx(filepath=str(ROOT / f"{name}.fbx"))
    bpy.context.scene.frame_start = 1
    for obj in bpy.context.scene.objects:
        obj.animation_data_clear()
        if obj.type == "ARMATURE":
            for pb in obj.pose.bones:
                pb.rotation_mode = "XYZ"
                pb.location = (0, 0, 0)
                pb.rotation_euler = (0, 0, 0)
                pb.scale = (1, 1, 1)
    return list(bpy.context.scene.objects)


def meshes():
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def armature():
    return next((obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"), None)


def key_obj(obj, frame, loc=None, rot=None, scale=None):
    bpy.context.scene.frame_set(frame)
    if loc is not None:
        obj.location = loc
        obj.keyframe_insert("location", frame=frame)
    if rot is not None:
        obj.rotation_euler = rot
        obj.keyframe_insert("rotation_euler", frame=frame)
    if scale is not None:
        obj.scale = scale
        obj.keyframe_insert("scale", frame=frame)


def key_bone(arm, bone_name, frame, loc=None, rot=None, scale=None):
    if not arm or bone_name not in arm.pose.bones:
        return False
    bpy.context.view_layer.objects.active = arm
    bpy.context.scene.frame_set(frame)
    pb = arm.pose.bones[bone_name]
    pb.rotation_mode = "XYZ"
    if loc is not None:
        pb.location = loc
        pb.keyframe_insert("location", frame=frame)
    if rot is not None:
        pb.rotation_euler = rot
        pb.keyframe_insert("rotation_euler", frame=frame)
    if scale is not None:
        pb.scale = scale
        pb.keyframe_insert("scale", frame=frame)
    return True


def export_clip(asset, clip, end_frame):
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = end_frame
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type in {"MESH", "ARMATURE"}:
            obj.select_set(True)
    active = armature() or (meshes()[0] if meshes() else None)
    if active:
        bpy.context.view_layer.objects.active = active
    out_path = ANIM_DIR / f"{asset}__{clip}.fbx"
    bpy.ops.export_scene.fbx(
        filepath=str(out_path),
        use_selection=True,
        object_types={"MESH", "ARMATURE"},
        path_mode="COPY",
        embed_textures=True,
        add_leaf_bones=False,
        bake_anim=True,
        bake_anim_use_all_bones=True,
        bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=False,
        bake_anim_force_startend_keying=True,
        bake_anim_step=1,
        bake_anim_simplify_factor=0.0,
        apply_scale_options="FBX_SCALE_UNITS",
    )
    return str(out_path.relative_to(ROOT))


def create_pet_clip(asset, clip):
    import_fbx(asset)
    arm = armature()
    if clip == "idle_float":
        end = 60
        key_bone(arm, "float_anchor", 1, loc=(0, 0, 0))
        key_bone(arm, "spine", 1, rot=(0, 0, 0))
        key_bone(arm, "head_or_orb", 1, scale=(1, 1, 1))
        key_bone(arm, "float_anchor", 30, loc=(0, 0, 0.12))
        key_bone(arm, "spine", 30, rot=(math.radians(3), 0, math.radians(4)))
        key_bone(arm, "head_or_orb", 30, scale=(1.035, 1.035, 1.035))
        key_bone(arm, "float_anchor", end, loc=(0, 0, 0))
        key_bone(arm, "spine", end, rot=(0, 0, 0))
        key_bone(arm, "head_or_orb", end, scale=(1, 1, 1))
    elif clip == "follow_float":
        end = 42
        for frame, y, z, rx in [(1, 0, 0, 0), (14, -0.07, 0.09, -5), (28, 0.07, 0.02, 5), (end, 0, 0, 0)]:
            key_bone(arm, "float_anchor", frame, loc=(0, y, z))
            key_bone(arm, "spine", frame, rot=(math.radians(rx), 0, 0))
    elif clip == "hover_loop":
        end = 72
        for frame, rz, z in [(1, 0, 0), (18, 5, 0.08), (36, 0, 0.12), (54, -5, 0.08), (end, 0, 0)]:
            key_bone(arm, "float_anchor", frame, loc=(0, 0, z))
            key_bone(arm, "head_or_orb", frame, rot=(0, 0, math.radians(rz)))
    else:
        end = 36
        for frame, z, s in [(1, 0, 1), (9, 0.16, 1.08), (18, -0.03, 0.96), (27, 0.08, 1.04), (end, 0, 1)]:
            key_bone(arm, "float_anchor", frame, loc=(0, 0, z))
            key_bone(arm, "head_or_orb", frame, scale=(s, s, s))
    return export_clip(asset, clip, end)


def create_wing_clip(asset, clip):
    import_fbx(asset)
    arm = armature()
    if clip == "wing_flap_idle":
        end = 40
        keys = [(1, 0), (10, 18), (20, -10), (30, 14), (end, 0)]
    else:
        end = 24
        keys = [(1, 0), (6, 28), (12, -18), (18, 22), (end, 0)]
    for frame, angle in keys:
        key_bone(arm, "sayap_kiri", frame, rot=(0, math.radians(angle), math.radians(-angle * 0.4)))
        key_bone(arm, "sayap_kanan", frame, rot=(0, math.radians(-angle), math.radians(angle * 0.4)))
        key_bone(arm, "sayap_kiri_tip", frame, rot=(0, math.radians(angle * 0.5), 0))
        key_bone(arm, "sayap_kanan_tip", frame, rot=(0, math.radians(-angle * 0.5), 0))
    return export_clip(asset, clip, end)


def create_static_clip(asset, clip):
    import_fbx(asset)
    objs = meshes()
    if not objs:
        return None
    obj = objs[0]
    if clip in {"idle_spin", "hover_spin"}:
        end = 72
        key_obj(obj, 1, rot=(0, 0, 0), loc=(0, 0, 0))
        key_obj(obj, 36, rot=(0, 0, math.radians(180)), loc=(0, 0, 0.08 if clip == "hover_spin" else 0))
        key_obj(obj, end, rot=(0, 0, math.radians(360)), loc=(0, 0, 0))
    elif clip == "glow_pulse":
        end = 60
        key_obj(obj, 1, scale=(1, 1, 1))
        key_obj(obj, 30, scale=(1.04, 1.04, 1.04))
        key_obj(obj, end, scale=(1, 1, 1))
    elif clip == "flame_flicker":
        end = 48
        for frame, sx, z in [(1, 1, 0), (8, 1.03, 0.03), (16, 0.97, -0.01), (24, 1.05, 0.04), (36, 0.99, 0.01), (end, 1, 0)]:
            key_obj(obj, frame, loc=(0, 0, z), scale=(sx, sx, sx))
    elif clip == "inspect":
        end = 48
        key_obj(obj, 1, rot=(0, 0, 0), scale=(1, 1, 1))
        key_obj(obj, 24, rot=(math.radians(8), 0, math.radians(22)), scale=(1.04, 1.04, 1.04))
        key_obj(obj, end, rot=(0, 0, 0), scale=(1, 1, 1))
    elif clip == "tool_use":
        end = 30
        key_obj(obj, 1, rot=(0, 0, 0))
        key_obj(obj, 10, rot=(math.radians(-8), 0, math.radians(-10)))
        key_obj(obj, 20, rot=(math.radians(10), 0, math.radians(8)))
        key_obj(obj, end, rot=(0, 0, 0))
    else:
        end = 36
        key_obj(obj, 1, rot=(0, 0, 0), loc=(0, 0, 0))
        key_obj(obj, 18, rot=(math.radians(4), 0, 0), loc=(0, 0, 0.04))
        key_obj(obj, end, rot=(0, 0, 0), loc=(0, 0, 0))
    return export_clip(asset, clip, end)


def create_r15_pose_clip(asset, clip):
    import_fbx(asset)
    arm = armature()
    end = 36
    for frame, angle, z in [(1, 0, 0), (18, 6, 0.03), (end, 0, 0)]:
        key_bone(arm, "UpperTorso", frame, rot=(math.radians(angle * 0.4), 0, 0))
        key_bone(arm, "LeftUpperArm", frame, rot=(math.radians(-angle), 0, math.radians(-angle * 0.4)))
        key_bone(arm, "RightUpperArm", frame, rot=(math.radians(-angle), 0, math.radians(angle * 0.4)))
        key_bone(arm, "LowerTorso", frame, loc=(0, 0, z))
    return export_clip(asset, clip, end)


def write_vfx_module():
    module = r'''-- Royal reward VFX presets generated for Roblox Studio.
-- Put this ModuleScript in ReplicatedStorage, then call:
-- local VFX = require(ReplicatedStorage.RoyalRewardVFX)
-- VFX.apply(model, "royal_premium_tier_15")

local RoyalRewardVFX = {}

local PRESETS = {
	royal_free_tier_5 = {color = Color3.fromRGB(150, 220, 255), light = 0.6, particles = 8, aura = "soft"},
	royal_premium_tier_5 = {color = Color3.fromRGB(255, 215, 96), light = 1.8, particles = 18, aura = "crown"},
	royal_free_tier_10 = {color = Color3.fromRGB(120, 180, 255), light = 0.4, particles = 6, aura = "ui_shimmer"},
	royal_premium_tier_10 = {color = Color3.fromRGB(80, 220, 255), light = 1.2, particles = 14, aura = "compass_spin"},
	royal_free_tier_15 = {color = Color3.fromRGB(180, 255, 220), light = 0.5, particles = 8, aura = "soft"},
	royal_premium_tier_15 = {color = Color3.fromRGB(130, 230, 255), light = 2.2, particles = 28, aura = "ghost_pet"},
	royal_free_tier_20 = {color = Color3.fromRGB(170, 170, 255), light = 0.4, particles = 6, aura = "emote"},
	royal_premium_tier_20 = {color = Color3.fromRGB(90, 180, 255), light = 1.8, particles = 20, aura = "staff_pulse"},
	royal_free_tier_25 = {color = Color3.fromRGB(190, 230, 255), light = 0.4, particles = 8, aura = "soft"},
	royal_premium_tier_25 = {color = Color3.fromRGB(255, 145, 56), light = 2.0, particles = 24, aura = "lantern_flame"},
	royal_free_tier_30 = {color = Color3.fromRGB(130, 180, 255), light = 0.2, particles = 5, aura = "ui"},
	royal_premium_tier_30 = {color = Color3.fromRGB(190, 120, 255), light = 0.8, particles = 10, aura = "equip"},
	royal_free_tier_35 = {color = Color3.fromRGB(220, 240, 255), light = 0.4, particles = 8, aura = "badge"},
	royal_premium_tier_35 = {color = Color3.fromRGB(210, 245, 255), light = 2.0, particles = 28, aura = "spirit_pet"},
	royal_free_tier_40 = {color = Color3.fromRGB(80, 200, 255), light = 0.7, particles = 10, aura = "camera"},
	royal_premium_tier_40 = {color = Color3.fromRGB(120, 140, 255), light = 1.6, particles = 22, aura = "spirit_wings"},
	royal_free_tier_45 = {color = Color3.fromRGB(200, 230, 255), light = 0.4, particles = 8, aura = "soft"},
	royal_premium_tier_45 = {color = Color3.fromRGB(180, 220, 255), light = 2.0, particles = 26, aura = "wewe_pet"},
	royal_free_tier_50 = {color = Color3.fromRGB(255, 80, 80), light = 1.2, particles = 16, aura = "barong"},
	royal_premium_tier_50 = {color = Color3.fromRGB(255, 230, 150), light = 1.0, particles = 14, aura = "elite"},
	royal_free_tier_55 = {color = Color3.fromRGB(170, 230, 255), light = 0.4, particles = 8, aura = "badge"},
	royal_premium_tier_55 = {color = Color3.fromRGB(190, 160, 255), light = 1.7, particles = 22, aura = "spirit_crown"},
	outfit_sang_ahli_season_exclusive = {color = Color3.fromRGB(255, 245, 190), light = 1.4, particles = 18, aura = "exclusive"},
}

local function findAdornee(model)
	if model:IsA("BasePart") then
		return model
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function ensureAttachment(part)
	local attachment = part:FindFirstChild("RoyalRewardVFXAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "RoyalRewardVFXAttachment"
		attachment.Parent = part
	end
	return attachment
end

function RoyalRewardVFX.clear(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant.Name == "RoyalRewardVFX" or descendant.Name == "RoyalRewardVFXAttachment" then
			descendant:Destroy()
		end
	end
end

function RoyalRewardVFX.apply(model, assetKey)
	local preset = PRESETS[assetKey]
	assert(preset, ("Unknown RoyalRewardVFX preset: %s"):format(tostring(assetKey)))
	local part = findAdornee(model)
	if not part then
		return nil
	end

	RoyalRewardVFX.clear(model)
	local attachment = ensureAttachment(part)

	local light = Instance.new("PointLight")
	light.Name = "RoyalRewardVFX"
	light.Color = preset.color
	light.Brightness = preset.light
	light.Range = math.clamp(8 + preset.light * 5, 8, 18)
	light.Shadows = false
	light.Parent = part

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "RoyalRewardVFX"
	particles.Color = ColorSequence.new(preset.color)
	particles.LightEmission = 0.75
	particles.LightInfluence = 0
	particles.Rate = preset.particles
	particles.Lifetime = NumberRange.new(0.7, 1.4)
	particles.Speed = NumberRange.new(0.15, 0.65)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-40, 40)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.10),
		NumberSequenceKeypoint.new(0.4, 0.20),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.75, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Parent = attachment

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RoyalRewardVFX"
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(80, 80)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 0.5, 0)
	billboard.Parent = part

	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(1, 1)
	glow.BackgroundColor3 = preset.color
	glow.BackgroundTransparency = 0.72
	glow.BorderSizePixel = 0
	glow.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = glow

	return {
		attachment = attachment,
		light = light,
		particles = particles,
		billboard = billboard,
		preset = preset,
	}
end

function RoyalRewardVFX.presets()
	return PRESETS
end

return RoyalRewardVFX
'''
    path = VFX_DIR / "RoyalRewardVFX.lua"
    path.write_text(module, encoding="utf-8")
    return str(path.relative_to(ROOT))


def write_animation_manifest(records):
    manifest = {
        "notes": [
            "FBX animation clips are source/import files. Upload/import them in Roblox Studio Animation Editor or 3D Importer to get animation asset IDs.",
            "Runtime follow movement for pets should be scripted in Roblox; these clips provide looped idle/follow/hover/interact motion for the rig itself.",
            "VFX are Roblox runtime presets in roblox_vfx/RoyalRewardVFX.lua because FBX does not carry ParticleEmitter, PointLight, or BillboardGui instances.",
        ],
        "clips": records,
    }
    path = ROOT / "animation_vfx_manifest.json"
    path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return str(path.relative_to(ROOT))


def main():
    records = []
    for asset in ["royal_premium_tier_15", "royal_premium_tier_35", "royal_premium_tier_45"]:
        for clip in ["idle_float", "follow_float", "hover_loop", "interact_pulse"]:
            records.append({"asset": asset, "clip": clip, "file": create_pet_clip(asset, clip), "looped": clip != "interact_pulse"})

    for clip in ["wing_flap_idle", "wing_flap_fast"]:
        records.append({"asset": "royal_premium_tier_40", "clip": clip, "file": create_wing_clip("royal_premium_tier_40", clip), "looped": True})

    static_clips = {
        "royal_premium_tier_10": ["idle_spin"],
        "royal_premium_tier_20": ["glow_pulse"],
        "royal_premium_tier_25": ["flame_flicker"],
        "royal_premium_tier_55": ["hover_spin"],
        "royal_free_tier_50": ["inspect"],
        "royal_free_tier_40": ["tool_use"],
    }
    for asset, clips in static_clips.items():
        for clip in clips:
            records.append({"asset": asset, "clip": clip, "file": create_static_clip(asset, clip), "looped": clip not in {"inspect", "tool_use"}})

    for asset in ["outfit_sang_ahli_season_exclusive", "royal_premium_tier_30", "royal_premium_tier_50"]:
        records.append({"asset": asset, "clip": "equip_pose", "file": create_r15_pose_clip(asset, "equip_pose"), "looped": False})

    vfx_file = write_vfx_module()
    manifest_file = write_animation_manifest(records)
    print(json.dumps({"clips": len(records), "manifest": manifest_file, "vfx_module": vfx_file}, indent=2))


if __name__ == "__main__":
    main()
