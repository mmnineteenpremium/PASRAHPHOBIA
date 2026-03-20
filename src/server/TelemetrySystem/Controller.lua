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
	-- Wiring only.
end

function Controller:RegisterEventHandlers()
	if not self._eventBus then
		return
	end
	self:_subscribe("MatchStarted", function(payload)
		self._service:OnMatchStarted(payload)
	end)
	self:_subscribe("GhostSpawned", function(payload)
		self._service:OnGhostSpawned(payload)
	end)
	self:_subscribe("EvidenceCollected", function(payload)
		self._service:OnEvidenceCollected(payload)
	end)
	self:_subscribe("PlayerKilled", function(payload)
		self._service:OnPlayerKilled(payload)
	end)
	self:_subscribe("RewardsGranted", function(payload)
		self._service:OnRewardsGranted(payload)
	end)
	self:_subscribe("MatchEnded", function(payload)
		self._service:OnMatchEnded(payload)
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

return Controller
