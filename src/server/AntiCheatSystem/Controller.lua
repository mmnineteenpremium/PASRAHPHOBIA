local Controller = {}
Controller.__index = Controller

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
	return self
end

function Controller:Init()
	-- Event wiring only.
end

function Controller:RegisterEventHandlers()
	if not self._eventBus then
		return
	end
	self:_subscribe("RemoteEventReceived", function(payload)
		self:OnRemoteEventReceived(payload)
	end)
	self:_subscribe("PlayerMovementReport", function(payload)
		self:OnPlayerMovementReport(payload)
	end)
	self:_subscribe("RewardClaimRequested", function(payload)
		self:OnRewardClaimRequested(payload)
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

function Controller:OnRemoteEventReceived(payload)
	local player = payload and payload.player
	local remoteName = payload and payload.remoteName
	if player and remoteName then
		self._service:ValidateRemoteCall(player, remoteName, payload.payload, payload.context)
	end
end

function Controller:OnPlayerMovementReport(payload)
	local player = payload and payload.player
	if player then
		self._service:CheckMovement(player, payload)
	end
end

function Controller:OnRewardClaimRequested(payload)
	local player = payload and payload.player
	if player then
		self._service:CheckDuplicateReward(player, payload.requestId, payload)
	end
end

return Controller
