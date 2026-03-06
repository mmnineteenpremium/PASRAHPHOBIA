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
	self:_subscribe("EvidenceCollected", function(payload)
		self:OnEvidenceCollected(payload)
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

function Controller:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	self._service:SpawnGhost(matchId, {
		roomIds = payload.roomIds or payload.rooms,
		roomGraph = payload.roomGraph,
		roomSpawnRules = payload.roomSpawnRules,
		ghostType = payload.ghostType,
		ghostTypeData = payload.ghostTypeData,
		personality = payload.personality,
		personalityType = payload.personalityType,
		evidenceSet = payload.evidenceSet,
		initialAggression = payload.initialAggression,
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
	self._service:TickGhost(matchId, snapshot, payload.dt, payload.now)
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
end

function Controller:OnEvidenceCollected(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	self._service:TickGhost(matchId, {
		playerUsingToolNearGhostRoom = payload.toolNearGhostRoom == true or payload.nearGhostRoom == true,
		investigationToolUsedNearGhostRoom = payload.toolNearGhostRoom == true,
	}, payload.dt, payload.now)
end

return Controller

