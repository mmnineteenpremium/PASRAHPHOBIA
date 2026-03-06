local Controller = {}
Controller.__index = Controller
local Services = require(script.Parent.Parent.Core.Services)
local PURCHASE_EVENT_NAME = "PurchaseEvent"

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
    local purchaseRemote = remoteFolder:FindFirstChild(PURCHASE_EVENT_NAME)
    if purchaseRemote and purchaseRemote:IsA("RemoteEvent") then
        return purchaseRemote
    end
    return nil
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._security = resolveSecurityService(self._deps)
    self._purchaseRemote = nil
    self._purchaseRemoteConnection = nil
    self._handlersRegistered = false
    self._subscriptions = {}
    return self
end

function Controller:Init()
    self._purchaseRemote = resolvePurchaseRemote()
end

function Controller:RegisterEventHandlers()
    if self._handlersRegistered then
        return
    end

    if self._eventBus then
        self:_subscribe("ShopPurchaseRequested", function(payload)
            self:OnShopPurchaseRequested(payload)
        end)
        self:_subscribe("CurrencyEarned", function(payload)
            self._service:OnCurrencyEarned(payload)
        end)
    end
    self:_connectPurchaseRemote()
    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    if not self._handlersRegistered then
        return
    end

    if self._eventBus then
        for _, sub in ipairs(self._subscriptions) do
            self._eventBus:Unsubscribe(sub.eventName, sub.callback)
        end
    end
    table.clear(self._subscriptions)
    self:_disconnectPurchaseRemote()
    self._handlersRegistered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:_connectPurchaseRemote()
    if self._purchaseRemoteConnection then
        return
    end
    if not self._purchaseRemote then
        self._purchaseRemote = resolvePurchaseRemote()
    end
    if not self._purchaseRemote then
        return
    end
    self._purchaseRemoteConnection = self._purchaseRemote.OnServerEvent:Connect(function(player, payload)
        self:OnRemotePurchaseRequested(player, payload)
    end)
end

function Controller:_disconnectPurchaseRemote()
    if self._purchaseRemoteConnection then
        self._purchaseRemoteConnection:Disconnect()
        self._purchaseRemoteConnection = nil
    end
end

function Controller:_isValidPurchasePayload(payload)
    if type(payload) ~= "table" then
        return false
    end
    return type(payload.itemId) == "string" and payload.itemId ~= ""
end

function Controller:OnShopPurchaseRequested(payload)
    local player = payload and payload.player
    local itemId = payload and payload.itemId
    if not player or type(itemId) ~= "string" or itemId == "" then
        return
    end

    local ok, err, purchasePayload = self._service:ProcessPurchase(player, itemId)

    if ok and self._eventBus then
        self._eventBus:Publish("ShopPurchaseSucceeded", {
            player = player,
            userId = purchasePayload and purchasePayload.userId or player.UserId,
            itemId = itemId,
            itemType = purchasePayload and purchasePayload.itemType,
            source = payload and payload.source,
        })
        return
    end

    if self._eventBus then
        self._eventBus:Publish("ShopPurchaseFailed", {
            player = player,
            userId = player.UserId,
            itemId = itemId,
            error = err,
            source = payload and payload.source,
        })
    end
end

function Controller:OnRemotePurchaseRequested(player, payload)
    if not player then
        return
    end

    if not self:_isValidPurchasePayload(payload) then
        if self._purchaseRemote then
            self._purchaseRemote:FireClient(player, {
                success = false,
                error = "invalid_payload",
            })
        end
        return
    end

    if self._security and type(self._security.ValidateRemoteRequest) == "function" then
        local requestOk = self._security:ValidateRemoteRequest(player, PURCHASE_EVENT_NAME, payload, {
            system = "ShopSystem",
        })
        if not requestOk then
            if self._purchaseRemote then
                self._purchaseRemote:FireClient(player, {
                    success = false,
                    error = "blocked_by_security",
                    itemId = payload.itemId,
                })
            end
            return
        end
    end

    local ok, err, result = self._service:ProcessPurchase(player, payload.itemId)
    if self._purchaseRemote then
        self._purchaseRemote:FireClient(player, {
            success = ok,
            error = err,
            itemId = payload.itemId,
            itemType = result and result.itemType,
            price = result and result.price,
        })
    end
end

return Controller
