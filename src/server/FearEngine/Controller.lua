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
	-- Controller wiring only.
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
	self:_subscribe("SanityChanged", function(payload)
		self:OnSanityChanged(payload)
	end)
	self:_subscribe("EnvironmentEventTriggered", function(payload)
		self:OnEnvironmentEventTriggered(payload)
	end)
	self:_subscribe("GhostInteraction", function(payload)
		self:OnGhostInteraction(payload)
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
	if matchId then
		self._service:StartMatch(matchId)
	end
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:EndMatch(matchId)
	end
end

function Controller:OnSanityChanged(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:OnSanityChanged(matchId, payload)
	end
end

function Controller:OnEnvironmentEventTriggered(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:OnEnvironmentEvent(matchId, payload)
	end
end

function Controller:OnGhostInteraction(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:OnGhostInteraction(matchId, payload)
	end
end

function Controller:OnHuntStarted(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:OnHuntStarted(matchId, payload)
	end
end

function Controller:OnHuntEnded(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:OnHuntEnded(matchId, payload)
	end
end

function Controller:OnPhaseStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local snapshot = payload.snapshot or {}
	self._service:Evaluate(matchId, {
		dt = payload.dt,
		averageSanity = snapshot.averageSanity,
		ghostProximity = snapshot.ghostProximity or 0,
		darknessLevel = snapshot.darknessLevel or 0,
		environmentDisturbances = snapshot.disturbanceLevel or 0,
	}, payload.now, "phase_tick")
end

return Controller
