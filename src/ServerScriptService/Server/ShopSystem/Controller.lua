local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local PURCHASE_REMOTE_NAME = "PurchaseEvent"
local PURCHASE_REQUEST_COOLDOWN_SECONDS = 0.35

local VALID_ACTIONS = {
    PurchaseItem = true,
    RequestPurchase = true,
    BuyItem = true,
}

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

local function resolveSecurityService(deps)
    local security = Services.Get(deps, "SecuritySystem")
    if type(security) ~= "table" then
        return nil
    end
    if type(security.ValidateRemoteRequest) == "function" then
        return security
    end
    if type(security.Service) == "table" and type(security.Service.ValidateRemoteRequest) == "function" then
        return security.Service
    end
    return nil
end

local function resolveSocialCommerceService(deps)
    local socialCommerce = Services.Get(deps, "SocialCommerceSystem")
    if type(socialCommerce) ~= "table" then
        return nil
    end
    if type(socialCommerce.ProcessGiftPurchase) == "function" then
        return socialCommerce
    end
    if type(socialCommerce.Service) == "table" and type(socialCommerce.Service.ProcessGiftPurchase) == "function" then
        return socialCommerce.Service
    end
    return nil
end

local function toUserId(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
end

local function resolvePurchaseRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end

    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end

    local remote = remoteFolder:FindFirstChild(PURCHASE_REMOTE_NAME)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

local function resolveItemIdFromRequest(request)
    if type(request) ~= "table" then
        return nil
    end

    local raw = request.itemId
    if type(raw) ~= "string" and type(request.payload) == "table" then
        raw = request.payload.itemId or request.payload.productId
    end
    if type(raw) ~= "string" or raw == "" then
        return nil
    end
    return raw
end

local function resolveGiftRecipientUserId(request)
    if type(request) ~= "table" then
        return nil
    end

    local raw = request.recipientUserId
    if raw == nil and type(request.payload) == "table" then
        raw = request.payload.recipientUserId or request.payload.targetUserId
    end

    if raw == nil then
        return nil
    end

    local recipientUserId = tonumber(raw)
    if not recipientUserId or recipientUserId <= 0 then
        return nil
    end
    return recipientUserId
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = nil
    self._security = nil
    self._subscriptions = {}
    self._registered = false
    self._purchaseRemote = nil
    self._remoteConnection = nil
    self._lastRequestAtByUserId = {}
    return self
end

function Controller:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._security = resolveSecurityService(self._deps)
    self._purchaseRemote = resolvePurchaseRemote()
end

function Controller:Init()
    -- Event subscriptions happen in Start.
end

function Controller:Start()
    self:RegisterEventHandlers()
    self:_connectPurchaseRemote()
end

function Controller:Stop()
    self:_disconnectPurchaseRemote()
    self:UnregisterEventHandlers()
    table.clear(self._lastRequestAtByUserId)
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._registered then
        return
    end

    self:_subscribe("PlayerPurchaseRequest", function(payload)
        self:OnPlayerPurchaseRequest(payload)
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

function Controller:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Controller:_connectPurchaseRemote()
    if self._remoteConnection then
        return
    end
    if not self._purchaseRemote then
        self._purchaseRemote = resolvePurchaseRemote()
    end
    if not self._purchaseRemote then
        return
    end

    self._remoteConnection = self._purchaseRemote.OnServerEvent:Connect(function(player, request)
        self:OnPurchaseRemoteRequest(player, request)
    end)
end

function Controller:_disconnectPurchaseRemote()
    if self._remoteConnection then
        self._remoteConnection:Disconnect()
        self._remoteConnection = nil
    end
end

function Controller:_sendPurchaseResponse(player, payload)
    if not player or not self._purchaseRemote then
        return
    end
    self._purchaseRemote:FireClient(player, payload)
end

function Controller:_validateRemoteRequest(player, request)
    if type(request) ~= "table" then
        return false, "invalid_request"
    end

    self:_publish("RemoteEventReceived", {
        player = player,
        remoteName = PURCHASE_REMOTE_NAME,
        payload = request,
        context = {
            system = "ShopSystem",
        },
    })

    if not self._security then
        return true
    end

    local ok, reason = self._security:ValidateRemoteRequest(player, PURCHASE_REMOTE_NAME, request, {
        system = "ShopSystem",
    })
    if not ok then
        return false, reason or "blocked_by_security"
    end
    return true
end

function Controller:_validateCooldown(player)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local now = os.clock()
    local last = self._lastRequestAtByUserId[userId] or 0
    if (now - last) < PURCHASE_REQUEST_COOLDOWN_SECONDS then
        return false, "purchase_cooldown"
    end
    self._lastRequestAtByUserId[userId] = now
    return true
end

function Controller:OnPurchaseRemoteRequest(player, request)
    local requestId = type(request) == "table" and request.requestId or nil
    local validRequest, requestErr = self:_validateRemoteRequest(player, request)
    if not validRequest then
        self:_sendPurchaseResponse(player, {
            eventName = "PurchaseProcessed",
            requestId = requestId,
            success = false,
            reason = requestErr,
        })
        return
    end

    local action = request.action
    if type(action) ~= "string" or not VALID_ACTIONS[action] then
        self:_sendPurchaseResponse(player, {
            eventName = "PurchaseProcessed",
            requestId = requestId,
            success = false,
            reason = "unsupported_action",
        })
        return
    end

    local cooldownOk, cooldownErr = self:_validateCooldown(player)
    if not cooldownOk then
        self:_sendPurchaseResponse(player, {
            eventName = "PurchaseProcessed",
            requestId = requestId,
            success = false,
            reason = cooldownErr,
        })
        return
    end

    local itemId = resolveItemIdFromRequest(request)
    if not itemId then
        self:_sendPurchaseResponse(player, {
            eventName = "PurchaseProcessed",
            requestId = requestId,
            success = false,
            reason = "invalid_item_id",
        })
        return
    end

    local recipientUserId = resolveGiftRecipientUserId(request)
    if recipientUserId and recipientUserId ~= toUserId(player) then
        local socialCommerce = resolveSocialCommerceService(self._deps)
        if not socialCommerce then
            self:_sendPurchaseResponse(player, {
                eventName = "PurchaseProcessed",
                requestId = requestId,
                success = false,
                reason = "gift_system_unavailable",
                itemId = itemId,
                recipientUserId = recipientUserId,
            })
            return
        end

        local ok, reason = socialCommerce:ProcessGiftPurchase({
            player = player,
            fromPlayer = player,
            recipientUserId = recipientUserId,
            itemId = itemId,
        })
        self:_sendPurchaseResponse(player, {
            eventName = "PurchaseProcessed",
            requestId = requestId,
            success = ok == true,
            reason = reason,
            itemId = itemId,
            recipientUserId = recipientUserId,
        })
        return
    end

    self:_publish("PurchaseRequestReceived", {
        player = player,
        itemId = itemId,
        source = "PurchaseEvent",
    })
    local ok, reason = self._service:ProcessPurchase(player, itemId)
    self:_sendPurchaseResponse(player, {
        eventName = "PurchaseProcessed",
        requestId = requestId,
        success = ok == true,
        reason = reason,
        itemId = itemId,
    })
end

function Controller:OnPlayerPurchaseRequest(payload)
    if type(payload) ~= "table" then
        return
    end
    local player = payload.player
    local itemId = payload.itemId
    if not player or type(itemId) ~= "string" or itemId == "" then
        return
    end
    local recipientUserId = tonumber(payload.recipientUserId)
    if recipientUserId and recipientUserId > 0 and recipientUserId ~= toUserId(player) then
        local socialCommerce = resolveSocialCommerceService(self._deps)
        if socialCommerce then
            socialCommerce:ProcessGiftPurchase({
                player = player,
                fromPlayer = player,
                recipientUserId = recipientUserId,
                itemId = itemId,
            })
        end
        return
    end
    self._service:ProcessPurchase(player, itemId)
end

return Controller
