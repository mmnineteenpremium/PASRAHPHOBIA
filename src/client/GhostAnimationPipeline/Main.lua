local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GhostAnimationPipeline = {}
GhostAnimationPipeline.__index = GhostAnimationPipeline

local EVENT_TO_ANIMATION = {
	GhostSpawned = "GhostIdle",
	GhostManifest = "GhostManifest",
	GhostManifestEnd = "GhostCooldown",
	GhostRoamed = "GhostRoam",
	HuntStarted = "GhostHunt",
	HuntEnded = "GhostCooldown",
	GhostAttack = "GhostAttack",
	GhostJumpscare = "GhostJumpscare",
	JumpscareTriggered = "GhostJumpscare",
	MatchStarted = "GhostIdle",
}

local ANIMATION_FALLBACKS = {
	GhostRoam = { "GhostIdle" },
	GhostCooldown = { "GhostIdle" },
}

local STATE_TO_ANIMATION = {
	Idle = "GhostIdle",
	Roaming = "GhostRoam",
	Manifest = "GhostManifest",
	Manifestation = "GhostManifest",
	Hunt = "GhostHunt",
	Hunting = "GhostHunt",
	Cooldown = "GhostCooldown",
	Retreat = "GhostCooldown",
}

local VARIANT_SUFFIXES = {
	"Aggressive",
	"Angry",
}

local ANIMATOR_RETRY_ATTEMPTS = 20
local ANIMATOR_RETRY_DELAY_SECONDS = 0.15
local ANIMATION_WATCHDOG_INTERVAL_SECONDS = 0.5

local function normalizeGhostType(value)
	if type(value) ~= "string" then
		return nil
	end
	local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return nil
	end
	return trimmed
end

local function resolveBaseGhostType(ghostType)
	local normalized = normalizeGhostType(ghostType)
	if not normalized then
		return nil
	end

	for _, suffix in ipairs(VARIANT_SUFFIXES) do
		if #normalized > #suffix and normalized:sub(-#suffix) == suffix then
			return normalized:sub(1, #normalized - #suffix)
		end
	end

	return normalized
end

local function stampAnimationDebug(trackKey, ghostType, animationName, assetId, errorText)
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end
	localPlayer:SetAttribute("PasrahGhostAnimationTrackKey", type(trackKey) == "string" and trackKey ~= "" and trackKey or nil)
	localPlayer:SetAttribute("PasrahGhostAnimationGhostType", type(ghostType) == "string" and ghostType ~= "" and ghostType or nil)
	localPlayer:SetAttribute("PasrahGhostAnimationName", type(animationName) == "string" and animationName ~= "" and animationName or nil)
	localPlayer:SetAttribute("PasrahGhostAnimationAssetId", type(assetId) == "string" and assetId ~= "" and assetId or nil)
	localPlayer:SetAttribute("PasrahGhostAnimationLastError", type(errorText) == "string" and errorText ~= "" and errorText or nil)
	localPlayer:SetAttribute("PasrahGhostAnimationStamp", os.clock())
end

local function normalizeSearchToken(value)
	local normalized = normalizeGhostType(value)
	if not normalized then
		return nil
	end
	return normalized:gsub("^Ghost[%s_%-]+", ""):gsub("[%s_%-_%.]+", ""):lower()
end

local function getAnimatorFromRig(rig)
	if typeof(rig) ~= "Instance" then
		return nil
	end

	local controller = rig:FindFirstChildWhichIsA("AnimationController", true)
	if controller then
		local animator = controller:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = controller
		end
		return animator
	end

	local humanoid = rig:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	local fallbackController = Instance.new("AnimationController")
	fallbackController.Name = "GhostAnimationController"
	fallbackController.Parent = rig

	local animator = Instance.new("Animator")
	animator.Parent = fallbackController
	return animator
end

local function modelMatchesGhostType(model, ghostType)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false
	end

	local targetToken = normalizeSearchToken(ghostType)
	if not targetToken then
		return false
	end

	for _, candidate in ipairs({
		model:GetAttribute("GhostType"),
		model:GetAttribute("VisualGhostType"),
		model:GetAttribute("VisualTemplateName"),
		model.Name,
	}) do
		local token = normalizeSearchToken(candidate)
		if token == targetToken then
			return true
		end
	end

	local baseGhostType = resolveBaseGhostType(ghostType)
	local baseToken = normalizeSearchToken(baseGhostType)
	if baseToken and baseToken ~= targetToken then
		for _, candidate in ipairs({
			model:GetAttribute("GhostType"),
			model:GetAttribute("VisualGhostType"),
			model:GetAttribute("VisualTemplateName"),
			model.Name,
		}) do
			local token = normalizeSearchToken(candidate)
			if token == baseToken then
				return true
			end
		end
	end

	return false
end

function GhostAnimationPipeline:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._tracks = {}
	self._tracksByGhost = {}
	self._activeTrack = nil
	self._activeAnimator = nil
	self._activeAnimationName = nil
	self._activeTrackKey = nil
	self._activeGhostType = nil
	self._pendingRetryToken = 0
	self._lastRequestedAnimationName = nil
	self._lastRequestedGhostType = nil
	self._watchdogStarted = false
	self._refreshScheduled = false
	self:_loadAnimationAssets()
end

function GhostAnimationPipeline:_scheduleAnimatorRetry(animationName, ghostType, attempt)
	local retryAttempt = tonumber(attempt) or 0
	if retryAttempt >= ANIMATOR_RETRY_ATTEMPTS then
		return
	end

	self._pendingRetryToken = (self._pendingRetryToken or 0) + 1
	local token = self._pendingRetryToken
	task.delay(ANIMATOR_RETRY_DELAY_SECONDS, function()
		if self._pendingRetryToken ~= token then
			return
		end
		self:Play(animationName, ghostType, retryAttempt + 1)
	end)
end

function GhostAnimationPipeline:_scheduleAnimationRefresh()
	if self._refreshScheduled then
		return
	end

	self._refreshScheduled = true
	task.defer(function()
		self._refreshScheduled = false
		local animationName, ghostType = self:_resolveCurrentAnimationRequest()
		if ghostType then
			self._activeGhostType = ghostType
		end

		if animationName then
			self._lastRequestedAnimationName = animationName
			self._lastRequestedGhostType = ghostType
			self:Play(animationName, ghostType)
		end
	end)
end

function GhostAnimationPipeline:Start()
	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		for _, attributeName in ipairs({
			"InMatch",
			"PasrahMatchPhase",
			"PasrahGhostHuntActive",
			"PasrahGhostRenderManifesting",
			"PasrahGhostRuntimeState",
			"PasrahGhostSessionState",
			"PasrahGhostType",
		}) do
			table.insert(self._connections, localPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
				self:_onPlayerGhostAttributesChanged()
			end))
		end
		self:_scheduleAnimationRefresh()
	end
	self:_startAnimationWatchdog()
end

function GhostAnimationPipeline:_resolveCurrentAnimationRequest()
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return nil, nil
	end

	local matchPhase = normalizeGhostType(localPlayer:GetAttribute("PasrahMatchPhase"))
	if matchPhase == "Result" or matchPhase == "End" then
		return nil, nil
	end
	if localPlayer:GetAttribute("InMatch") == false then
		return nil, nil
	end

	local ghostType = self:_resolveGhostTypeFromPlayerAttributes(localPlayer) or self._activeGhostType
	local animationName = nil
	if localPlayer:GetAttribute("PasrahGhostHuntActive") == true then
		animationName = "GhostHunt"
	elseif localPlayer:GetAttribute("PasrahGhostRenderManifesting") == true then
		animationName = "GhostManifest"
	else
		local stateName = normalizeGhostType(localPlayer:GetAttribute("PasrahGhostRuntimeState"))
			or normalizeGhostType(localPlayer:GetAttribute("PasrahGhostSessionState"))
		animationName = STATE_TO_ANIMATION[stateName]
	end

	return animationName or self._lastRequestedAnimationName, ghostType or self._lastRequestedGhostType
end

function GhostAnimationPipeline:_ensureActiveAnimation()
	local animationName, ghostType = self:_resolveCurrentAnimationRequest()
	if not animationName then
		return
	end

	local entry, trackKey, resolvedAnimationName = self:_resolveTrack(animationName, ghostType)
	if not entry then
		return
	end

	local animator = self._activeAnimator
	if animator and (not animator.Parent or not animator.Parent:IsDescendantOf(Workspace)) then
		animator = nil
	end
	if animator then
		local activeGhostType = normalizeGhostType(self._activeGhostType)
		local requestedGhostType = normalizeGhostType(ghostType)
		if requestedGhostType and activeGhostType and activeGhostType ~= requestedGhostType then
			animator = nil
		end
	end
	if not animator then
		animator = self:_findAnimator(ghostType)
	end
	if not animator then
		self:Play(animationName, ghostType)
		return
	end

	if self._activeTrackKey == trackKey and self._activeTrack and self._activeTrack.IsPlaying and self._activeTrack.Animation == entry.animation and self._activeAnimator == animator then
		return
	end

	if self._activeTrack and self._activeTrack.IsPlaying and self._activeTrack.Animation == entry.animation then
		self._activeAnimator = animator
		self._activeAnimationName = resolvedAnimationName
		self._activeTrackKey = trackKey
		self._activeGhostType = ghostType
		self._lastPlayError = nil
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.IsPlaying and track.Animation == entry.animation then
			self._activeTrack = track
			self._activeAnimator = animator
			self._activeAnimationName = resolvedAnimationName
			self._activeTrackKey = trackKey
			self._activeGhostType = ghostType
			self._lastPlayError = nil
			return
		end
	end

	self:Play(animationName, ghostType)
end

function GhostAnimationPipeline:_startAnimationWatchdog()
	if self._watchdogStarted then
		return
	end
	self._watchdogStarted = true
	task.spawn(function()
		while self._watchdogStarted do
			task.wait(ANIMATION_WATCHDOG_INTERVAL_SECONDS)
			self:_ensureActiveAnimation()
		end
	end)
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
			self._tracks[instance.Name] = self:_buildTrackEntry(instance)
		elseif instance:IsA("Folder") then
			local ghostTracks = {}
			for _, child in ipairs(instance:GetChildren()) do
				if child:IsA("Animation") then
					ghostTracks[child.Name] = self:_buildTrackEntry(child)
				end
			end
			if next(ghostTracks) ~= nil then
				self._tracksByGhost[instance.Name] = ghostTracks
			end
		end
	end
end

function GhostAnimationPipeline:_buildTrackEntry(animation)
	return {
		animation = animation,
		looped = self:_readLoopFlag(animation),
	}
end

function GhostAnimationPipeline:_readLoopFlag(animation)
	local flag = animation:FindFirstChild("Looped")
	return flag and flag:IsA("BoolValue") and flag.Value == true
end

function GhostAnimationPipeline:_resolveGhostTypeFromPayload(payload)
	local ghostType = normalizeGhostType(payload and (payload.visualGhostType or payload.ghostType or payload.actualGhostType))
	if ghostType then
		return ghostType
	end

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		return normalizeGhostType(localPlayer:GetAttribute("PasrahGhostType"))
	end

	return nil
end

function GhostAnimationPipeline:_resolveGhostTypeFromPlayerAttributes(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end

	for _, attributeName in ipairs({
		"PasrahGhostType",
		"PasrahGhostVisualTemplate",
		"PasrahGhostModelName",
	}) do
		local ghostType = normalizeGhostType(player:GetAttribute(attributeName))
		if ghostType then
			return ghostType:gsub("^Ghost[%s_%-]+", "")
		end
	end

	return nil
end

function GhostAnimationPipeline:_onPlayerGhostAttributesChanged()
	self:_scheduleAnimationRefresh()
end

function GhostAnimationPipeline:_resolveTrack(animationName, ghostType)
	local searchNames = { animationName }
	for _, fallbackName in ipairs(ANIMATION_FALLBACKS[animationName] or {}) do
		table.insert(searchNames, fallbackName)
	end

	local ghostSearch = {}
	local normalizedGhostType = normalizeGhostType(ghostType)
	if normalizedGhostType then
		table.insert(ghostSearch, normalizedGhostType)
		local baseGhostType = resolveBaseGhostType(normalizedGhostType)
		if baseGhostType and baseGhostType ~= normalizedGhostType then
			table.insert(ghostSearch, baseGhostType)
		end
	end

	for _, ghostKey in ipairs(ghostSearch) do
		local ghostTracks = self._tracksByGhost[ghostKey]
		if ghostTracks then
			for _, candidateName in ipairs(searchNames) do
				local entry = ghostTracks[candidateName]
				if entry then
					return entry, ghostKey .. ":" .. candidateName, candidateName
				end
			end
		end
	end
	if normalizedGhostType then
		return nil, nil, nil
	end

	for _, candidateName in ipairs(searchNames) do
		local entry = self._tracks[candidateName]
		if entry then
			return entry, "global:" .. candidateName, candidateName
		end
	end

	return nil, nil, nil
end

function GhostAnimationPipeline:_findAnimator(ghostType)
	local normalizedGhostType = normalizeGhostType(ghostType)
	local descendants = Workspace:GetDescendants()
	for _, instance in ipairs(descendants) do
		if normalizedGhostType and instance:IsA("Model") and modelMatchesGhostType(instance, normalizedGhostType) then
			local animator = getAnimatorFromRig(instance)
			if animator then
				return animator
			end
		end
	end

	if normalizedGhostType then
		return nil
	end

	for _, instance in ipairs(descendants) do
		if instance:IsA("Model") then
			local isGhostModel = instance:GetAttribute("GhostType") ~= nil
				or instance:GetAttribute("VisualGhostType") ~= nil
				or instance:GetAttribute("VisualTemplateName") ~= nil
				or instance.Name:match("^Ghost[_%-]") ~= nil
			if isGhostModel then
				local animator = getAnimatorFromRig(instance)
				if animator then
					return animator
				end
			end
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

	local ghostType = self:_resolveGhostTypeFromPayload(payload)
	if ghostType then
		self._activeGhostType = ghostType
	end

	self._lastRequestedAnimationName = animationName
	self._lastRequestedGhostType = ghostType
	self:Play(animationName, ghostType)
end

function GhostAnimationPipeline:Play(animationName, ghostType, retryAttempt)
	local resolvedGhostType = ghostType or self._activeGhostType
	if animationName then
		self._lastRequestedAnimationName = animationName
	end
	if resolvedGhostType then
		self._lastRequestedGhostType = resolvedGhostType
	end
	local entry, trackKey, resolvedAnimationName = self:_resolveTrack(animationName, resolvedGhostType)
	if not entry then
		self:_loadAnimationAssets()
		entry, trackKey, resolvedAnimationName = self:_resolveTrack(animationName, resolvedGhostType)
	end
	if not entry then
		self._lastPlayError = "missing_track:" .. tostring(resolvedGhostType or "global") .. ":" .. tostring(animationName)
		stampAnimationDebug(nil, resolvedGhostType, animationName, nil, self._lastPlayError)
		return
	end

	local animator = self._activeAnimator
	if animator and (not animator.Parent or not animator.Parent:IsDescendantOf(Workspace)) then
		animator = nil
	end
	if animator then
		local activeGhostType = normalizeGhostType(self._activeGhostType)
		local requestedGhostType = normalizeGhostType(resolvedGhostType)
		if requestedGhostType and activeGhostType and activeGhostType ~= requestedGhostType then
			animator = nil
		end
	end
	if not animator then
		animator = self:_findAnimator(resolvedGhostType)
	end
	if not animator then
		self._lastPlayError = "missing_ghost_animator:" .. tostring(resolvedGhostType or "unknown")
		stampAnimationDebug(trackKey, resolvedGhostType, resolvedAnimationName or animationName, entry.animation.AnimationId, self._lastPlayError)
		self:_scheduleAnimatorRetry(animationName, resolvedGhostType, retryAttempt)
		return
	end

	self._pendingRetryToken = (self._pendingRetryToken or 0) + 1

	if self._activeTrackKey == trackKey and self._activeAnimator == animator and self._activeTrack and self._activeTrack.IsPlaying then
		stampAnimationDebug(trackKey, resolvedGhostType, resolvedAnimationName or animationName, entry.animation.AnimationId, nil)
		return
	end

	if self._activeTrack then
		self._activeTrack:Stop(0.15)
		self._activeTrack = nil
	end

	local loaded, trackOrError = pcall(function()
		return animator:LoadAnimation(entry.animation)
	end)
	if not loaded or not trackOrError then
		self._lastPlayError = "load_failed:" .. tostring(trackOrError)
		stampAnimationDebug(trackKey, resolvedGhostType, resolvedAnimationName or animationName, entry.animation.AnimationId, self._lastPlayError)
		return
	end

	local track = trackOrError
	track.Looped = entry.looped
	track:Play(0.15)

	self._activeTrack = track
	self._activeAnimator = animator
	self._activeAnimationName = resolvedAnimationName
	self._activeTrackKey = trackKey
	self._activeGhostType = resolvedGhostType
	self._lastPlayError = nil
	stampAnimationDebug(trackKey, resolvedGhostType, resolvedAnimationName or animationName, entry.animation.AnimationId, nil)
end

function GhostAnimationPipeline:GetState()
	local globalCount = 0
	for _ in pairs(self._tracks or {}) do
		globalCount += 1
	end

	local perGhostCount = 0
	for _, ghostTracks in pairs(self._tracksByGhost or {}) do
		for _ in pairs(ghostTracks) do
			perGhostCount += 1
		end
	end

	return {
		activeAnimation = self._activeAnimationName,
		activeAnimatorPath = self._activeAnimator and self._activeAnimator:GetFullName() or nil,
		activeGhostType = self._activeGhostType,
		activeTrackAnimationId = self._activeTrack and self._activeTrack.Animation and self._activeTrack.Animation.AnimationId or nil,
		activeTrackPlaying = self._activeTrack and self._activeTrack.IsPlaying or false,
		assetCount = (self._assets and #self._assets:GetChildren()) or 0,
		globalTrackCount = globalCount,
		lastPlayError = self._lastPlayError,
		perGhostTrackCount = perGhostCount,
	}
end

return setmetatable({}, GhostAnimationPipeline)
