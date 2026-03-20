local Controller = {}
Controller.__index = Controller
local GhostInteractionGateway = require(script.Parent.GhostInteractionGateway)

local function resolveEventBus(deps)
	local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

function Controller.new(state, service, deps)
	local self = setmetatable({}, Controller)
	self._state = state
	self._service = service
	self._deps = deps or {}
	self._subscriptions = {}
	self._eventBus = resolveEventBus(self._deps)
	self._handlersRegistered = false
	self._gateway = nil
	self._lastAggressionByMatch = {}
	return self
end

function Controller:Init()
	-- Prepare controller-level wiring here.
	self._gateway = GhostInteractionGateway.new(self._service, self._deps)
end

function Controller:RegisterEventHandlers()
	if self._gateway then
		self._gateway:Start()
	end
	if not self._eventBus then
		return
	end
	if self._handlersRegistered then
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
	self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
	if self._gateway then
		self._gateway:Stop()
	end
	if not self._eventBus then
		return
	end
	if not self._handlersRegistered then
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

	self._service:InitGhost(matchId, {
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
		difficultyProfile = payload.difficultyProfile,
	})
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:DespawnGhost(matchId)
end

function Controller:OnPhaseStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	local phaseName = payload.phaseName
	if phaseName and phaseName ~= "Investigation" and phaseName ~= "Hunt" then
		return
	end

	local snapshot = payload.snapshot or {}
	local session = self._service:TickGhost(matchId, snapshot, payload.dt, payload.now)
	self:_maybePublishAggressionThreshold(matchId, session)
end

function Controller:OnHuntTriggered(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:StartHunt(matchId, payload.snapshot, payload.now)
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
end

function Controller:OnForceHunt(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:StartHunt(matchId, payload.snapshot, payload.now)
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
end

function Controller:OnHuntEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:TransitionGhostState(matchId, "Cooldown", payload and payload.now)
end

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

return Controller

