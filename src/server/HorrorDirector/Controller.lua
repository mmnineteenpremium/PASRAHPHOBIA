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
	self._handlersRegistered = false
	return self
end

function Controller:Init()
	-- Prepare controller-level wiring here.
end

function Controller:RegisterEventHandlers()
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
	self:_subscribe("GhostSpawned", function(payload)
		self:OnGhostSpawned(payload)
	end)
	self:_subscribe("EvidenceCollected", function(payload)
		self:OnEvidenceCollected(payload)
	end)
	self:_subscribe("PlayerSanityChanged", function(payload)
		self:OnPlayerSanityChanged(payload)
	end)
	self:_subscribe("GhostStateChanged", function(payload)
		self:OnGhostStateChanged(payload)
	end)
	self:_subscribe("HuntStarted", function(payload)
		self:OnHuntStarted(payload)
	end)
	self:_subscribe("HuntEnded", function(payload)
		self:OnHuntEnded(payload)
	end)
	self:_subscribe("PhaseStarted", function(payload)
		self:OnPhaseStarted(payload)
	end)
	self:_subscribe("PlayerStateSnapshot", function(payload)
		self:OnPlayerStateSnapshot(payload)
	end)
	self:_subscribe("PlayerStateUpdated", function(payload)
		self:OnPlayerStateSnapshot(payload)
	end)
	self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
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

	self._service:StartMatch(matchId, payload)
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:EndMatch(matchId)
end

function Controller:OnGhostSpawned(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:SetGhostRoom(matchId, payload.favoriteRoomId)
end

function Controller:OnEvidenceCollected(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:RecordEvidenceCollected(matchId, payload)
end

function Controller:OnPlayerSanityChanged(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:RecordPlayerSanityChanged(matchId, payload)
end

function Controller:OnGhostStateChanged(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:RecordGhostStateChanged(matchId, payload)
end

function Controller:OnHuntStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:RecordHuntStarted(matchId)
end

function Controller:OnHuntEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:RecordHuntEnded(matchId)
end

function Controller:OnPhaseStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	local snapshot = payload.snapshot or {}
	snapshot.phaseName = payload.phaseName
	snapshot.dt = payload.dt
	snapshot.now = payload.now
	self._service:EvaluateTension(matchId, snapshot, payload.now)
end

function Controller:OnPlayerStateSnapshot(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local snapshot = payload.snapshot or payload
	self._service:RecordPlayerStateSnapshot(matchId, snapshot, payload and payload.now)
end

return Controller

