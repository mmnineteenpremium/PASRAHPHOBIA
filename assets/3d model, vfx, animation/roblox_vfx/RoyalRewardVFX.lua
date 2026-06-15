-- Royal reward VFX presets generated for Roblox Studio.
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
