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
	-- Event wiring only.
end

function Controller:RegisterEventHandlers()
	if not self._eventBus then
		return
	end
	self:_subscribe("PhaseStarted", function(payload)
		self._service:OnPhaseTick(payload)
	end)
	self:_subscribe("GhostStateChanged", function()
		self._service:AddGhostLoad(2)
	end)
	self:_subscribe("HuntStarted", function()
		self._service:AddGhostLoad(8)
	end)
	self:_subscribe("HuntEnded", function()
		self._service:AddGhostLoad(-4)
	end)
	self:_subscribe("EnvironmentEventTriggered", function()
		self._service:AddEventSystemLoad(3)
	end)
	self:_subscribe("MapEventStarted", function()
		self._service:AddEventSystemLoad(2)
	end)
	self:_subscribe("MapEventEnded", function()
		self._service:AddEventSystemLoad(-1)
	end)
	self:_subscribe("RemoteEventReceived", function()
		self._service:CountNetworkEvent(1)
	end)
	self:_subscribe("PlayerViolationDetected", function()
		self._service:CountNetworkEvent(1)
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
