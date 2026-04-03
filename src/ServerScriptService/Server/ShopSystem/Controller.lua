local Services = require(script.Parent.Parent.Core.Services)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

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
    self._marketplaceConnections = {}
    self._marketplaceItemsByKey = {}
    self._lastRequestAtByUserId = {}
    return self
end

function Controller:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._security = resolveSecurityService(self._deps)
    self._purchaseRemote = resolvePurchaseRemote()
    self:_rebuildMarketplaceItemIndex()
end

function Controller:Init()
    -- Event subscriptions happen in Start.
end

function Controller:Start()
    self:RegisterEventHandlers()
    self:_connectPurchaseRemote()
    self:_connectMarketplaceSignals()
    self:_syncCurrentPlayerEntitlements()
end

function Controller:Stop()
    self:_disconnectMarketplaceSignals()
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

function Controller:_rebuildMarketplaceItemIndex()
    self._marketplaceItemsByKey = {}
    if not self._service or type(self._service.GetCatalog) ~= "function" then
        return
    end

    for itemId, item in pairs(self._service:GetCatalog()) do
        if type(item) == "table" and self._service:IsMarketplacePurchase(item) then
            local key = string.format("%s:%s", tostring(item.marketplaceType), tostring(item.marketplaceId))
            self._marketplaceItemsByKey[key] = itemId
        end
    end
end

function Controller:_getMarketplaceItemId(marketplaceType, marketplaceId)
    return self._marketplaceItemsByKey[string.format("%s:%s", tostring(marketplaceType), tostring(marketplaceId))]
end

function Controller:_processedReceipts()
    return self._state:Get("processedReceiptIds") or {}
end

function Controller:_markReceiptProcessed(receiptId)
    local processed = self:_processedReceipts()
    processed[tostring(receiptId)] = true
    self._state:Set("processedReceiptIds", processed)
end

function Controller:_isReceiptProcessed(receiptId)
    return self:_processedReceipts()[tostring(receiptId)] == true
end

function Controller:_trackMarketplacePrompt(player, itemId, item)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local activeTransactions = self._state:Get("activeTransactions") or {}
    activeTransactions[userId] = {
        itemId = itemId,
        marketplaceType = item.marketplaceType,
        marketplaceId = item.marketplaceId,
        startedAt = os.clock(),
    }
    self._state:Set("activeTransactions", activeTransactions)
end

function Controller:_clearMarketplacePrompt(player)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local activeTransactions = self._state:Get("activeTransactions") or {}
    activeTransactions[userId] = nil
    self._state:Set("activeTransactions", activeTransactions)
end

function Controller:_findTrackedMarketplacePrompt(player, marketplaceType, marketplaceId)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local activeTransactions = self._state:Get("activeTransactions") or {}
    local pending = activeTransactions[userId]
    if type(pending) ~= "table" then
        return nil
    end
    if pending.marketplaceType ~= marketplaceType then
        return nil
    end
    if tonumber(pending.marketplaceId) ~= tonumber(marketplaceId) then
        return nil
    end
    return pending
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

function Controller:_connectMarketplaceSignals()
    if #self._marketplaceConnections > 0 then
        return
    end

    table.insert(self._marketplaceConnections, MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchaseSuccess)
        self:_onGamePassPurchaseFinished(player, gamePassId, purchaseSuccess)
    end))

    MarketplaceService.ProcessReceipt = function(receiptInfo)
        return self:_processReceipt(receiptInfo)
    end

    table.insert(self._marketplaceConnections, Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            self:_syncOwnedGamePassesForPlayer(player)
        end)
    end))
end

function Controller:_disconnectMarketplaceSignals()
    for _, connection in ipairs(self._marketplaceConnections) do
        connection:Disconnect()
    end
    table.clear(self._marketplaceConnections)
end

function Controller:_syncCurrentPlayerEntitlements()
    for _, player in ipairs(Players:GetPlayers()) do
        task.defer(function()
            self:_syncOwnedGamePassesForPlayer(player)
        end)
    end
end

function Controller:_syncOwnedGamePassesForPlayer(player)
    if not player or not self._service or type(self._service.GetCatalog) ~= "function" then
        return
    end

    for itemId, item in pairs(self._service:GetCatalog()) do
        if type(item) == "table" and item.marketplaceType == "GamePass" and tonumber(item.marketplaceId) and tonumber(item.marketplaceId) > 0 then
            local ok, ownsPass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, item.marketplaceId)
            end)
            if ok and ownsPass == true then
                self._service:GrantMarketplacePurchase(player, itemId, {
                    source = "GamePassOwnershipSync",
                    marketplaceId = item.marketplaceId,
                })
            end
        end
    end
end

function Controller:_onGamePassPurchaseFinished(player, gamePassId, purchaseSuccess)
    local marketplaceId = tonumber(gamePassId)
    local tracked = self:_findTrackedMarketplacePrompt(player, "GamePass", marketplaceId)
    local itemId = self:_getMarketplaceItemId("GamePass", marketplaceId) or (tracked and tracked.itemId or nil)
    self:_clearMarketplacePrompt(player)

    if not itemId then
        return
    end

    if purchaseSuccess ~= true then
        self:_sendPurchaseResponse(player, {
            eventName = "PurchaseProcessed",
            success = false,
            reason = "purchase_cancelled",
            itemId = itemId,
        })
        return
    end

    local ok, reason = self._service:GrantMarketplacePurchase(player, itemId, {
        source = "GamePassPurchaseFinished",
        marketplaceId = marketplaceId,
    })
    self:_sendPurchaseResponse(player, {
        eventName = "PurchaseProcessed",
        success = ok == true,
        reason = reason,
        itemId = itemId,
    })
end

function Controller:_processReceipt(receiptInfo)
    local purchaseId = receiptInfo and receiptInfo.PurchaseId
    if not purchaseId then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    if self:_isReceiptProcessed(purchaseId) then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    local marketplaceId = receiptInfo and tonumber(receiptInfo.ProductId)
    local itemId = self:_getMarketplaceItemId("DeveloperProduct", marketplaceId)
    if not itemId then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local player = receiptInfo and Players:GetPlayerByUserId(receiptInfo.PlayerId) or nil
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local ok, reason = self._service:GrantMarketplacePurchase(player, itemId, {
        source = "ProcessReceipt",
        receiptId = tostring(purchaseId),
        marketplaceId = marketplaceId,
    })
    if ok ~= true then
        self:_sendPurchaseResponse(player, {
            eventName = "PurchaseProcessed",
            success = false,
            reason = reason or "receipt_grant_failed",
            itemId = itemId,
        })
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    self:_markReceiptProcessed(purchaseId)
    self:_clearMarketplacePrompt(player)
    self:_sendPurchaseResponse(player, {
        eventName = "PurchaseProcessed",
        success = true,
        reason = "receipt_granted",
        itemId = itemId,
    })
    return Enum.ProductPurchaseDecision.PurchaseGranted
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
        local purchaseIntentOk, purchaseIntentErr, purchaseIntent = self._service:ResolvePurchaseIntent(player, itemId)
        if not purchaseIntentOk then
            self:_sendPurchaseResponse(player, {
                eventName = "PurchaseProcessed",
                requestId = requestId,
                success = false,
                reason = purchaseIntentErr,
                itemId = itemId,
                recipientUserId = recipientUserId,
            })
            return
        end
        if purchaseIntent.flow == "Marketplace" then
            self:_sendPurchaseResponse(player, {
                eventName = "PurchaseProcessed",
                requestId = requestId,
                success = false,
                reason = "gift_not_supported_for_marketplace",
                itemId = itemId,
                recipientUserId = recipientUserId,
            })
            return
        end

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

    local intentOk, intentErr, intent = self._service:ResolvePurchaseIntent(player, itemId)
    if not intentOk then
        self:_sendPurchaseResponse(player, {
            eventName = "PurchaseProcessed",
            requestId = requestId,
            success = false,
            reason = intentErr,
            itemId = itemId,
        })
        return
    end

    if intent.flow == "Marketplace" then
        self:_trackMarketplacePrompt(player, itemId, intent.item)
        self:_sendPurchaseResponse(player, {
            eventName = "PurchasePromptRequested",
            requestId = requestId,
            success = true,
            itemId = itemId,
            purchaseType = intent.marketplaceType,
            productId = intent.marketplaceId,
            currency = intent.purchaseCurrency,
        })
        return
    end

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
