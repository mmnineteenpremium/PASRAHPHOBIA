-- Runtime helpers for Royal reward models, animation playback, pet follow, and VFX.
-- Put this ModuleScript in ReplicatedStorage with RoyalRewardVFX.lua.
-- Fill ANIMATION_IDS after importing/uploading the FBX clips from animations_fbx.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoyalRewardVFX = require(ReplicatedStorage:WaitForChild("RoyalRewardVFX"))

local RoyalRewardRuntime = {}

local ANIMATION_IDS = {
	royal_premium_tier_15 = {
		idle_float = 0,
		follow_float = 0,
		hover_loop = 0,
		interact_pulse = 0,
	},
	royal_premium_tier_35 = {
		idle_float = 0,
		follow_float = 0,
		hover_loop = 0,
		interact_pulse = 0,
	},
	royal_premium_tier_45 = {
		idle_float = 0,
		follow_float = 0,
		hover_loop = 0,
		interact_pulse = 0,
	},
	royal_premium_tier_40 = {
		wing_flap_idle = 0,
		wing_flap_fast = 0,
	},
	outfit_sang_ahli_season_exclusive = {
		equip_pose = 0,
	},
	royal_premium_tier_30 = {
		equip_pose = 0,
	},
	royal_premium_tier_50 = {
		equip_pose = 0,
	},
}

local activeTracks = setmetatable({}, {__mode = "k"})
local activeFollowConnections = setmetatable({}, {__mode = "k"})

local function getModelPart(model)
	if model:IsA("BasePart") then
		return model
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function getAnimator(model)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	if not controller then
		controller = Instance.new("AnimationController")
		controller.Name = "RoyalRewardAnimationController"
		controller.Parent = model
	end
	local animator = controller:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end
	return animator
end

function RoyalRewardRuntime.setAnimationId(assetKey, clipName, animationId)
	ANIMATION_IDS[assetKey] = ANIMATION_IDS[assetKey] or {}
	ANIMATION_IDS[assetKey][clipName] = animationId
end

function RoyalRewardRuntime.stop(model, fadeTime)
	local tracks = activeTracks[model]
	if not tracks then
		return
	end
	for _, track in pairs(tracks) do
		track:Stop(fadeTime or 0.12)
	end
	activeTracks[model] = nil
end

function RoyalRewardRuntime.play(model, assetKey, clipName, options)
	options = options or {}
	local clips = ANIMATION_IDS[assetKey]
	local id = clips and clips[clipName]
	if not id or id == 0 then
		warn(("Missing animation id for %s.%s"):format(tostring(assetKey), tostring(clipName)))
		return nil
	end

	local animator = getAnimator(model)
	local animation = Instance.new("Animation")
	animation.AnimationId = ("rbxassetid://%d"):format(id)

	local track = animator:LoadAnimation(animation)
	track.Looped = options.looped == true
	track.Priority = options.priority or Enum.AnimationPriority.Idle
	track:Play(options.fadeTime or 0.12, options.weight or 1, options.speed or 1)

	activeTracks[model] = activeTracks[model] or {}
	activeTracks[model][clipName] = track
	return track
end

function RoyalRewardRuntime.applyVFX(model, assetKey)
	return RoyalRewardVFX.apply(model, assetKey)
end

function RoyalRewardRuntime.startPetFollow(petModel, character, options)
	options = options or {}
	local petPart = getModelPart(petModel)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not petPart or not root then
		return nil
	end

	if activeFollowConnections[petModel] then
		activeFollowConnections[petModel]:Disconnect()
	end

	local offset = options.offset or Vector3.new(2.5, 2.2, 3.0)
	local stiffness = options.stiffness or 8
	local bobHeight = options.bobHeight or 0.35
	local bobSpeed = options.bobSpeed or 2.3
	local lookAtCharacter = options.lookAtCharacter ~= false
	local t = 0

	local connection = RunService.Heartbeat:Connect(function(dt)
		if not petModel.Parent or not character.Parent or not root.Parent then
			connection:Disconnect()
			activeFollowConnections[petModel] = nil
			return
		end

		t += dt
		local desired = root.CFrame:PointToWorldSpace(offset)
		desired += Vector3.new(0, math.sin(t * math.pi * bobSpeed) * bobHeight, 0)
		local alpha = 1 - math.exp(-stiffness * dt)
		local current = petPart.CFrame
		local targetCFrame
		if lookAtCharacter then
			targetCFrame = CFrame.lookAt(current.Position:Lerp(desired, alpha), root.Position)
		else
			targetCFrame = current:Lerp(CFrame.new(desired), alpha)
		end
		petModel:PivotTo(targetCFrame)
	end)

	activeFollowConnections[petModel] = connection
	return connection
end

function RoyalRewardRuntime.stopPetFollow(petModel)
	local connection = activeFollowConnections[petModel]
	if connection then
		connection:Disconnect()
	end
	activeFollowConnections[petModel] = nil
end

function RoyalRewardRuntime.animationMap()
	return ANIMATION_IDS
end

return RoyalRewardRuntime
