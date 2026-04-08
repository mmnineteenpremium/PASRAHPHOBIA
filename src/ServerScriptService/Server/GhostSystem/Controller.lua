local Controller = {}
Controller.__index = Controller

local GhostInteractionGateway = require(script.Parent.GhostInteractionGateway)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GHOST_TRACE_ATTRIBUTE = "PasrahGhostTrace"

local INVESTIGATION_PHASES = {
	Investigation = true,
	InvestigationPhase = true,
	Hunt = true,
	HuntPhase = true,
}

local function resolveEventBus(deps)
	local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus"))
		or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus"))
		or (deps and deps.EventBus or nil)
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Subscribe) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then
		return eventBus.Service
	end
	return nil
end

local function resolveMatchSystem(deps)
	local matchSystem = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("MatchSystem"))
		or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("MatchSystem"))
		or (deps and deps.MatchSystem or nil)
	if type(matchSystem) ~= "table" then
		return nil
	end
	if type(matchSystem.GetLiveMatch) == "function" then
		return matchSystem
	end
	if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
		return matchSystem.Service
	end
	return nil
end

local function coerceVector3(value)
	if typeof(value) == "Vector3" then
		return value
	end
	if type(value) == "table" then
		local x = tonumber(value.x or value.X)
		local y = tonumber(value.y or value.Y)
		local z = tonumber(value.z or value.Z)
		if x and y and z then
			return Vector3.new(x, y, z)
		end
	end
	return nil
end

local function resolveSharedGameDataModule(moduleName)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	if not shared then
		return nil
	end
	local gameData = shared:FindFirstChild("GameData")
	if not gameData then
		return nil
	end
	local moduleScript = gameData:FindFirstChild(moduleName)
	if moduleScript and moduleScript:IsA("ModuleScript") then
		return moduleScript
	end
	return nil
end

local function safeRequireModule(moduleScript)
	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

local function resolveGhostTargetBounds(ghostType)
	if type(ghostType) ~= "string" or ghostType == "" then
		return nil
	end
	local tuning = safeRequireModule(resolveSharedGameDataModule("GhostVisualTuning"))
	local ghosts = type(tuning) == "table" and tuning.ghosts or nil
	local config = type(ghosts) == "table" and ghosts[ghostType] or nil
	if type(config) ~= "table" then
		return nil
	end
	return coerceVector3(config.targetBounds) or coerceVector3(config.meshSize)
end

local function resolveStudioGhostSessionState(ghostState, runtimeState)
	local runtimeToken = type(runtimeState) == "string" and runtimeState or nil
	local stateToken = type(ghostState) == "table" and tostring(ghostState.state or "") or nil
	if runtimeToken and runtimeToken ~= "" and type(ghostState) == "table" and ghostState.huntActive == true then
		return runtimeToken
	end
	if stateToken and stateToken ~= "" then
		return stateToken
	end
	if runtimeToken and runtimeToken ~= "" then
		return runtimeToken
	end
	return nil
end

local function resolveMatchRemote()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		return nil
	end
	local remote = remoteFolder:FindFirstChild("MatchEvent")
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

local function shouldTraceGhost()
	return RunService:IsStudio() and ReplicatedStorage:GetAttribute(GHOST_TRACE_ATTRIBUTE) == true
end

local function traceGhost(message, payload)
	if not shouldTraceGhost() then
		return
	end

	local parts = {}
	for key, value in pairs(payload or {}) do
		table.insert(parts, string.format("%s=%s", tostring(key), tostring(value)))
	end
	table.sort(parts)
	if #parts > 0 then
		warn(string.format("[GHOST TRACE] %s [%s]", tostring(message), table.concat(parts, ", ")))
	else
		warn(string.format("[GHOST TRACE] %s", tostring(message)))
	end
end

local function setGhostTraceState(stage, details)
	if not shouldTraceGhost() then
		return
	end
	ReplicatedStorage:SetAttribute("PasrahGhostTraceStage", stage)
	ReplicatedStorage:SetAttribute("PasrahGhostTraceDetails", details)
end

local function setStudioGhostPlayerSnapshot(players, matchId, match, ghostState)
	if not RunService:IsStudio() or type(players) ~= "table" then
		return
	end

	local ghostModel = type(match) == "table" and match.ghost or nil
	local meshPart = ghostModel and ghostModel:FindFirstChildWhichIsA("MeshPart", true) or nil
	local modelPath = typeof(ghostModel) == "Instance" and ghostModel:GetFullName() or nil
	local modelName = typeof(ghostModel) == "Instance" and ghostModel.Name or nil
	local ghostType = type(match) == "table" and tostring(match.ghostType or "") or nil
	local visualTemplateName = typeof(ghostModel) == "Instance" and ghostModel:GetAttribute("VisualTemplateName") or nil
	local runtimeState = typeof(ghostModel) == "Instance" and ghostModel:GetAttribute("RuntimeGhostState") or nil
	local ghostPosition = (ghostModel and ghostModel:IsA("Model")) and tostring(ghostModel:GetPivot().Position) or nil
	local meshSize = (meshPart and meshPart:IsA("MeshPart")) and tostring(meshPart.Size) or nil
	local ghostExtents = nil
	local ghostScale = nil
	if ghostModel and ghostModel:IsA("Model") then
		local okExtents, extents = pcall(function()
			return ghostModel:GetExtentsSize()
		end)
		if okExtents and typeof(extents) == "Vector3" then
			ghostExtents = tostring(extents)
		end
		local okScale, scale = pcall(function()
			return ghostModel:GetScale()
		end)
		if okScale and type(scale) == "number" then
			ghostScale = scale
		end
	end
	local targetBounds = resolveGhostTargetBounds(ghostType)

	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			player:SetAttribute("PasrahGhostMatchId", type(matchId) == "string" and matchId or tostring(matchId or ""))
			player:SetAttribute("PasrahGhostType", ghostType ~= "" and ghostType or nil)
			player:SetAttribute("PasrahGhostModelName", modelName)
			player:SetAttribute("PasrahGhostModelPath", modelPath)
			player:SetAttribute("PasrahGhostVisualTemplate", visualTemplateName)
			player:SetAttribute("PasrahGhostRuntimeState", runtimeState)
			player:SetAttribute("PasrahGhostMeshSize", meshSize)
			player:SetAttribute("PasrahGhostPosition", ghostPosition)
			player:SetAttribute("PasrahGhostHasModel", typeof(ghostModel) == "Instance")
			player:SetAttribute("PasrahGhostPlaceholder", typeof(ghostModel) == "Instance" and ghostModel:GetAttribute("PlaceholderVisual") == true or false)
			player:SetAttribute("PasrahGhostSessionState", resolveStudioGhostSessionState(ghostState, runtimeState))
			player:SetAttribute("PasrahGhostCurrentRoomId", type(ghostState) == "table" and ghostState.currentRoomId or nil)
			player:SetAttribute("PasrahGhostHuntActive", type(ghostState) == "table" and ghostState.huntActive == true or false)
			player:SetAttribute("PasrahGhostTargetBounds", typeof(targetBounds) == "Vector3" and tostring(targetBounds) or nil)
			player:SetAttribute("PasrahGhostExtents", ghostExtents)
			player:SetAttribute("PasrahGhostScale", ghostScale)
		end
	end
end

function Controller.new(state, service, deps)
	local self = setmetatable({}, Controller)
	self._state = state
	self._service = service
	self._deps = deps or {}
	self._subscriptions = {}
	self._eventBus = resolveEventBus(self._deps)
	self._matchSystem = resolveMatchSystem(self._deps)
	self._matchRemote = resolveMatchRemote()
	self._handlersRegistered = false
	self._gateway = nil
	self._lastAggressionByMatch = {}
	return self
end

function Controller:Init()
	self._gateway = GhostInteractionGateway.new(self._service, self._deps)
end

function Controller:RegisterEventHandlers()
	if self._gateway then
		self._gateway:Start()
	end
	if not self._eventBus or self._handlersRegistered then
		return
	end

	self:_subscribe("MatchStarted", function(payload)
		self:OnMatchStarted(payload)
	end)
	self:_subscribe("MatchEnded", function(payload)
		self:OnMatchEnded(payload)
	end)
	self:_subscribe("PhaseStarted", function(payload)
		self:OnPhaseStarted(payload)
	end)
	self:_subscribe("HuntTriggered", function(payload)
		self:OnHuntTriggered(payload)
	end)
	self:_subscribe("TensionHigh", function(payload)
		self:OnTensionHigh(payload)
	end)
	self:_subscribe("ForceManifest", function(payload)
		self:OnForceManifest(payload)
	end)
	self:_subscribe("ForceHunt", function(payload)
		self:OnForceHunt(payload)
	end)
	self:_subscribe("SanityCritical", function(payload)
		self:OnSanityCritical(payload)
	end)
	self:_subscribe("AggressionThreshold", function(payload)
		self:OnAggressionThreshold(payload)
	end)
	self:_subscribe("HuntStarted", function(payload)
		self:OnHuntStarted(payload)
	end)
	self:_subscribe("HuntEnded", function(payload)
		self:OnHuntEnded(payload)
	end)
	self:_subscribe("EvidenceCollected", function(payload)
		self:OnEvidenceCollected(payload)
	end)
	self:_subscribe("EscalationStageChanged", function(payload)
		self:OnEscalationStageChanged(payload)
	end)
	self:_subscribe("GhostManifest", function(payload)
		self:OnGhostManifest(payload)
	end)
	self:_subscribe("GhostManifestEnd", function(payload)
		self:OnGhostManifestEnd(payload)
	end)

	self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
	if self._gateway then
		self._gateway:Stop()
	end
	if not self._eventBus or not self._handlersRegistered then
		return
	end

	for _, subscription in ipairs(self._subscriptions) do
		self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
	end
	table.clear(self._subscriptions)
	self._handlersRegistered = false
end

function Controller:_subscribe(eventName, callback)
	self._eventBus:Subscribe(eventName, callback)
	table.insert(self._subscriptions, {
		eventName = eventName,
		callback = callback,
	})
end

function Controller:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Controller:_forwardMatchEvent(eventName, payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	local matchSystem = self._matchSystem or resolveMatchSystem(self._deps)
	local remote = self._matchRemote or resolveMatchRemote()
	if not matchSystem or not remote then
		return
	end

	self._matchSystem = matchSystem
	self._matchRemote = remote

	local match = matchSystem:GetLiveMatch(matchId)
	local players = type(match) == "table" and match.players or nil
	if type(players) ~= "table" then
		return
	end

	local clientPayload = {}
	for key, value in pairs(payload or {}) do
		clientPayload[key] = value
	end
	clientPayload.eventName = eventName
	clientPayload.source = clientPayload.source or "GhostSystem"

	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			remote:FireClient(player, clientPayload)
		end
	end
end

function Controller:_maybePublishAggressionThreshold(matchId, session)
	if not self._eventBus or not matchId or not session then
		return
	end
	local threshold = tonumber(session.difficultyProfile and session.difficultyProfile.HuntFrequency)
	if not threshold then
		return
	end
	local current = tonumber(session.aggression) or 0
	local previous = self._lastAggressionByMatch[matchId] or 0
	self._lastAggressionByMatch[matchId] = current
	if previous < threshold and current >= threshold then
		self._eventBus:Publish("AggressionThreshold", {
			matchId = matchId,
			aggression = current,
		})
	end
end

function Controller:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	setGhostTraceState("OnMatchStarted", string.format("match=%s;payloadGhostType=%s", tostring(matchId), tostring(payload and payload.ghostType)))
	traceGhost("OnMatchStarted", {
		matchId = matchId,
		payloadGhostType = payload and payload.ghostType or nil,
	})

	local ok, _, err = pcall(function()
		return self._service:InitGhost(matchId, {
			roomIds = payload.roomIds or payload.rooms,
			roomGraph = payload.roomGraph,
			roomSpawnRules = payload.roomSpawnRules,
			ghostType = payload.ghostType,
			ghostTypeData = payload.ghostTypeData,
			personality = payload.personality,
			personalityType = payload.personalityType,
			evidenceSet = payload.evidenceSet,
			initialAggression = payload.initialAggression,
			difficulty = payload.difficulty,
			mode = payload.mode or payload.gameMode,
			gameMode = payload.gameMode or payload.mode,
			difficultyProfile = payload.difficultyProfile,
			favoriteRoomId = payload.favoriteRoomId,
			now = payload.now,
		})
	end)
	if not ok then
		err = tostring(_)
	end
	setGhostTraceState("InitGhostResult", string.format("match=%s;error=%s", tostring(matchId), tostring(err)))
	traceGhost("InitGhostResult", {
		matchId = matchId,
		error = err or "nil",
	})

	local liveMatch = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or payload and payload.players, matchId, liveMatch, self._service:GetGhostState(matchId))

	if err then
		self:_publish("MatchPhaseTransitionRequested", {
			matchId = matchId,
			endMatch = true,
			reason = "ghost_spawn_failed",
			missionFailed = true,
			source = "GhostSystem",
		})
	end
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:DespawnGhost(matchId)
	self._lastAggressionByMatch[matchId] = nil
end

function Controller:OnPhaseStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	local phaseName = payload and (payload.phaseName or payload.lifecyclePhase or payload.phase)
	if not INVESTIGATION_PHASES[phaseName] then
		return
	end

	local session = self._service:TickGhost(matchId, payload.snapshot or {}, payload.dt, payload.now)
	self:_maybePublishAggressionThreshold(matchId, session)
	local liveMatch = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

function Controller:OnHuntTriggered(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:StartHunt(matchId, payload.snapshot, payload.now)
	local liveMatch = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

function Controller:OnTensionHigh(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:ApplyDirectorEvent(matchId, "TensionHigh", payload)
end

function Controller:OnForceManifest(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:ApplyDirectorEvent(matchId, "ForceManifest", payload)
	self._service:ForceManifest(matchId, payload.now)
	self._service:TickGhost(matchId, payload.snapshot or {}, payload.dt, payload.now)
	local liveMatch = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

function Controller:OnForceHunt(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:ForceHunt(matchId, payload.snapshot, payload.now)
	local liveMatch = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

function Controller:OnSanityCritical(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:OnSanityCritical(matchId)
end

function Controller:OnAggressionThreshold(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:OnAggressionThreshold(matchId)
end

function Controller:OnHuntStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:TransitionGhostState(matchId, "Hunting", payload and payload.now)
	local liveMatch = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

function Controller:OnHuntEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:TransitionGhostState(matchId, "Cooldown", payload and payload.now)
	local liveMatch = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

function Controller:OnEvidenceCollected(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	local session = self._service:TickGhost(matchId, {
		playerUsingToolNearGhostRoom = payload.toolNearGhostRoom == true or payload.nearGhostRoom == true,
		investigationToolUsedNearGhostRoom = payload.toolNearGhostRoom == true,
	}, payload.dt, payload.now)
	self:_maybePublishAggressionThreshold(matchId, session)
	local liveMatch = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

function Controller:OnEscalationStageChanged(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	local stage = payload.currentStage
	local now = payload and payload.now
	local aggressionBoost = tonumber(payload and payload.aggressionBoost) or 0
	local duration = tonumber(payload and payload.stageDuration) or 0

	if stage == "Tension" or stage == "Aggressive" or stage == "Hunting" then
		self._service:ApplyDirectorEvent(matchId, "TensionHigh", {
			now = now,
			duration = math.max(8, math.floor(duration * 0.35)),
			aggressionBoost = aggressionBoost,
		})
	end

	if stage == "Aggressive" then
		self._service:ApplyDirectorEvent(matchId, "ForceManifest", {
			now = now,
			duration = 8,
		})
		self._service:TickGhost(matchId, payload.snapshot or {}, payload.dt, now)
	elseif stage == "Hunting" then
		self._service:StartHunt(matchId, payload.snapshot, now)
	end
end

function Controller:OnGhostManifest(payload)
	self:_forwardMatchEvent("GhostManifest", payload)
	local matchId = payload and payload.matchId
	local liveMatch = matchId and self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

function Controller:OnGhostManifestEnd(payload)
	self:_forwardMatchEvent("GhostManifestEnd", payload)
	local matchId = payload and payload.matchId
	local liveMatch = matchId and self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	setStudioGhostPlayerSnapshot(type(liveMatch) == "table" and liveMatch.players or nil, matchId, liveMatch, self._service:GetGhostState(matchId))
end

return Controller
