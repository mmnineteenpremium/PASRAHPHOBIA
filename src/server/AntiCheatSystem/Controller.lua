local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
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
	self._eventBus = nil
	self._registered = false
	return self
end

function Controller:Create()
	self._eventBus = resolveEventBus(self._deps)
end

function Controller:Init()
	-- Event wiring only.
end

function Controller:Start()
	self:RegisterEventHandlers()
end

function Controller:Stop()
	self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
	if not self._eventBus or self._registered then
		return
	end
	self:_subscribe("RemoteEventReceived", function(payload)
		self:OnRemoteEventReceived(payload)
	end)
	self:_subscribe("RemoteEventTriggered", function(payload)
		self:OnRemoteEventReceived(payload)
	end)
	self:_subscribe("PlayerMovementReport", function(payload)
		self:OnPlayerMovementReport(payload)
	end)
	self:_subscribe("RewardClaimRequested", function(payload)
		self:OnRewardClaimRequested(payload)
	end)
	self:_subscribe("PlayerJoinedLobby", function(payload)
		self:OnPlayerJoinedLobby(payload)
	end)
	self:_subscribe("PlayerDisconnected", function(payload)
		self:OnPlayerDisconnected(payload)
	end)
	self._registered = true
end

function Controller:UnregisterEventHandlers()
	if not self._eventBus or not self._registered then
		return
	end
	for _, subscription in ipairs(self._subscriptions) do
		self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
	end
	table.clear(self._subscriptions)
	self._registered = false
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
	if player and payload then
		self._service:ValidateInteraction(player, payload.context or payload.payload)
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

function Controller:OnPlayerJoinedLobby(payload)
	local player = payload and payload.player
	if player then
		self._service:CheckMovement(player, {
			position = payload.position,
			now = payload.now or os.clock(),
		})
	end
end

function Controller:OnPlayerDisconnected(payload)
	local player = payload and payload.player
	if player then
		self._service:GetPlayerViolations(player)
	end
end

return Controller
