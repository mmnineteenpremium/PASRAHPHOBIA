local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GhostAnimationPipeline = {}
GhostAnimationPipeline.__index = GhostAnimationPipeline

local EVENT_TO_ANIMATION = {
	GhostSpawned = "GhostIdle",
	GhostManifest = "GhostManifest",
	HuntStarted = "GhostHunt",
	HuntEnded = "GhostIdle",
	GhostAttack = "GhostAttack",
	GhostJumpscare = "GhostJumpscare",
	MatchStarted = "GhostIdle",
}

function GhostAnimationPipeline:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._tracks = {}
	self._activeTrack = nil
	self._activeAnimationName = nil
	self:_loadAnimationAssets()
end

function GhostAnimationPipeline:Start()
	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end
end

function GhostAnimationPipeline:_loadAnimationAssets()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local animationsFolder = assets
		and assets:FindFirstChild("Animations")
		and assets.Animations:FindFirstChild("Ghosts")

	self._assets = animationsFolder
	if not animationsFolder then
		return
	end

	for _, instance in ipairs(animationsFolder:GetChildren()) do
		if instance:IsA("Animation") then
			self._tracks[instance.Name] = {
				animation = instance,
				looped = self:_readLoopFlag(instance),
			}
		end
	end
end

function GhostAnimationPipeline:_readLoopFlag(animation)
	local flag = animation:FindFirstChild("Looped")
	return flag and flag:IsA("BoolValue") and flag.Value == true
end

function GhostAnimationPipeline:_findAnimator()
	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("AnimationController") then
			local animator = instance:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = instance
			end
			return animator
		end
	end

	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("Humanoid") then
			local animator = instance:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = instance
			end
			return animator
		end
	end

	return nil
end

function GhostAnimationPipeline:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	local animationName = EVENT_TO_ANIMATION[eventName]
	if not animationName then
		return
	end

	self:Play(animationName)
end

function GhostAnimationPipeline:Play(animationName)
	if self._activeAnimationName == animationName then
		return
	end

	local entry = self._tracks[animationName]
	if not entry then
		return
	end

	local animator = self:_findAnimator()
	if not animator then
		return
	end

	if self._activeTrack then
		self._activeTrack:Stop(0.15)
		self._activeTrack = nil
	end

	local track = animator:LoadAnimation(entry.animation)
	track.Looped = entry.looped
	track:Play(0.15)

	self._activeTrack = track
	self._activeAnimationName = animationName
end

function GhostAnimationPipeline:GetState()
	return {
		activeAnimation = self._activeAnimationName,
		assetCount = (self._assets and #self._assets:GetChildren()) or 0,
	}
end

return setmetatable({}, GhostAnimationPipeline)
