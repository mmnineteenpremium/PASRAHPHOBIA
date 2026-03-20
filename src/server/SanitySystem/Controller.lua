local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
	local eventBus = deps.EventBus
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
	return self
end

function Controller:Init()
	-- Prepare controller-level wiring here.
end

function Controller:RegisterEventHandlers()
	if not self._eventBus then
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
	self:_subscribe("GhostInteraction", function(payload)
		self:OnGhostInteraction(payload)
	end)
	self:_subscribe("GhostRoamed", function(payload)
		self:OnGhostRoamed(payload)
	end)
	self:_subscribe("GhostManifest", function(payload)
		self:OnGhostManifest(payload)
	end)
	self:_subscribe("HuntStarted", function(payload)
		self:OnHuntStarted(payload)
	end)
	self:_subscribe("HuntEnded", function(payload)
		self:OnHuntEnded(payload)
	end)
	self:_subscribe("EnvironmentalEvent", function(payload)
		self:OnEnvironmentalEvent(payload)
	end)
	self:_subscribe("EnvironmentEventTriggered", function(payload)
		self:OnEnvironmentalEvent(payload)
	end)
	self:_subscribe("GhostEventTriggered", function(payload)
		self:OnGhostEventTriggered(payload)
	end)
	self:_subscribe("HuntTriggered", function(payload)
		self:OnDirectorHuntTriggered(payload)
	end)
	self:_subscribe("DirectorTriggeredHunt", function(payload)
		self:OnDirectorHuntTriggered(payload)
	end)
end

function Controller:UnregisterEventHandlers()
	if not self._eventBus then
		return
	end
	for _, subscription in ipairs(self._subscriptions) do
		self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
	end
	table.clear(self._subscriptions)
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
	self._service:StartMatch(matchId, payload)
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:EndMatch(matchId)
end

function Controller:OnPhaseStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	local phaseName = payload.phaseName
	if phaseName ~= "Investigation" and phaseName ~= "InvestigationPhase" and phaseName ~= "Hunt" and phaseName ~= "HuntPhase" then
		return
	end
	self._service:ApplySnapshotDrain(matchId, payload.snapshot or {}, payload.now)
end

function Controller:OnGhostInteraction(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	if payload.interactionType == "Manifest" then
		self._service:OnGhostManifest(matchId, {
			players = payload.players or {},
		})
	end
end

function Controller:OnGhostRoamed(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:SetGhostRoom(matchId, payload.room)
end

function Controller:OnGhostManifest(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:OnGhostManifest(matchId, payload)
end

function Controller:OnHuntStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:OnHuntStarted(matchId, payload)
end

function Controller:OnHuntEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:OnHuntEnded(matchId)
end

function Controller:OnEnvironmentalEvent(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:OnEnvironmentalEvent(matchId, payload)
end

function Controller:OnGhostEventTriggered(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:OnGhostEventTriggered(matchId, payload)
end

function Controller:OnDirectorHuntTriggered(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:OnDirectorTriggeredHunt(matchId, payload)
end

return Controller

