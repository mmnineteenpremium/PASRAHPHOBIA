local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service
local Players = game:GetService("Players")

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end
local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
        return eventBus.Service
    end
    return nil
end

local function resolveGameDataModule(moduleName)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
    if not shared then
        return nil
    end
    local gameData = shared:FindFirstChild("GameData")
    if not gameData then
        return nil
    end
    return gameData:FindFirstChild(moduleName)
end

local function getByPath(root, path)
    local node = root
    for _, segment in ipairs(path or {}) do
        if typeof(node) ~= "Instance" then
            return nil
        end
        node = node:FindFirstChild(segment)
        if not node then
            return nil
        end
    end
    return node
end

local function resolveCatalogModule()
    local pathOptions = {
        { "shared", "DataTypes", "ShopCatalog" },
        { "Shared", "DataTypes", "ShopCatalog" },
    }

    local cursor = script
    while cursor do
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(cursor, path)
            if moduleScript then
                return moduleScript
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(replicatedStorage, path)
            if moduleScript then
                return moduleScript
            end
        end
    end

    return nil
end

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function safeCall(target, methodName, ...)
    if type(target) ~= "table" then
        return nil
    end
    local method = target[methodName]
    if type(method) ~= "function" then
        return nil
    end
    local ok, a, b, c = pcall(method, target, ...)
    if not ok then
        return nil
    end
    return a, b, c
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        InventorySystem = Services.Get(self._deps, "InventorySystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
    }
    self._state:Set("shopCatalog", self:LoadShopCatalog())
    self:ReloadConfig()
end

function Service:Start()
end

function Service:Stop()
    self._state:Clear()
end

function Service:ReloadConfig()
    local cfg = safeRequire(resolveGameDataModule("GlobalOperationsConfig")) or {}
    self._state:Set("config", cfg.Commerce or {})
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:LoadShopCatalog()
    local loadedCatalog = safeRequire(resolveCatalogModule())
    if type(loadedCatalog) ~= "table" then
        return {}
    end

    local normalized = {}
    for _, item in pairs(loadedCatalog) do
        if type(item) == "table" and type(item.id) == "string" and item.id ~= "" then
            normalized[item.id] = deepCopy(item)
        end
    end
    return normalized
end

function Service:_getCatalogItem(itemId)
    local catalog = self._state:Get("shopCatalog") or {}
    return type(itemId) == "string" and catalog[itemId] or nil
end

function Service:_getInventoryService()
    local inventory = self._dependencies.InventorySystem
    if type(inventory) == "table" and type(inventory.Service) == "table" then
        return inventory.Service
    end
    return inventory
end

function Service:_getEconomyService()
    local economy = self._dependencies.EconomySystem
    if type(economy) == "table" and type(economy.Service) == "table" then
        return economy.Service
    end
    return economy
end

function Service:_getPersistenceService()
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) == "table" and type(persistence.Service) == "table" then
        return persistence.Service
    end
    return persistence
end

function Service:_persistInventory(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    local inventory = self:_getInventoryService()
    local persistence = self:_getPersistenceService()
    if type(inventory) ~= "table" or type(inventory.GetSnapshotForPersistence) ~= "function" then
        return
    end
    if type(persistence) ~= "table" or type(persistence.SaveInventory) ~= "function" then
        return
    end

    local snapshot = safeCall(inventory, "GetSnapshotForPersistence", player)
    if type(snapshot) ~= "table" then
        return
    end

    pcall(function()
        persistence:SaveInventory(player.UserId, snapshot)
    end)
end

function Service:HandleMarketplacePurchase(payload)
    local cfg = self._state:Get("config") or {}
    if cfg.MarketplaceEnabled == false then
        return false, "marketplace_disabled"
    end

    local player = payload and payload.player
    local userId = toUserId(player or payload and payload.userId)
    local cosmeticId = payload and payload.cosmeticId
    local price = math.max(0, math.floor(tonumber(payload and payload.price) or 0))

    if not userId or type(cosmeticId) ~= "string" or price <= 0 then
        return false, "invalid_purchase_payload"
    end

    local economy = self._dependencies.EconomySystem
    local inventory = self._dependencies.InventorySystem

    local spent = safeCall(economy, "SpendCurrency", player or userId, "MM", price, "CosmeticMarketplace")
    if spent ~= true then
        spent = safeCall(economy, "SpendCurrency", player or userId, price, "CosmeticMarketplace")
    end
    if spent ~= true then
        return false, "insufficient_funds"
    end

    safeCall(inventory, "AddCosmeticOwnership", player or userId, cosmeticId)
    if type(inventory) == "table" and type(inventory.Service) == "table" then
        safeCall(inventory.Service, "AddCosmeticOwnership", player or userId, cosmeticId)
    end

    self:_publish("CosmeticMarketplacePurchaseCompleted", {
        userId = userId,
        cosmeticId = cosmeticId,
        price = price,
        currency = "MM",
    })

    return true
end

function Service:ProcessGiftPurchase(payload)
    local cfg = self._state:Get("config") or {}
    if cfg.GiftingEnabled == false then
        return false, "gifting_disabled"
    end

    local senderPlayer = payload and (payload.player or payload.fromPlayer)
    local senderUserId = toUserId(senderPlayer or payload and payload.fromUserId)
    local recipientUserId = toUserId(payload and (payload.recipientPlayer or payload.recipientUserId or payload.targetUserId))
    local itemId = payload and payload.itemId

    if not senderUserId or not recipientUserId or senderUserId == recipientUserId then
        return false, "invalid_gift_users"
    end
    if type(itemId) ~= "string" or itemId == "" then
        return false, "invalid_item_id"
    end

    local item = self:_getCatalogItem(itemId)
    if type(item) ~= "table" then
        return false, "item_not_found"
    end
    if item.category ~= "Cosmetic" then
        return false, "gift_requires_cosmetic"
    end

    local recipientPlayer = payload and payload.recipientPlayer
    if (typeof(recipientPlayer) ~= "Instance" or not recipientPlayer:IsA("Player")) and recipientUserId then
        recipientPlayer = Players:GetPlayerByUserId(recipientUserId)
    end
    if typeof(recipientPlayer) ~= "Instance" or not recipientPlayer:IsA("Player") then
        return false, "recipient_offline"
    end

    local inventory = self:_getInventoryService()
    if type(inventory) ~= "table" then
        return false, "inventory_unavailable"
    end

    local alreadyOwned = safeCall(inventory, "OwnsCosmetic", recipientPlayer, itemId)
    if alreadyOwned == true then
        return false, "recipient_already_owns_item"
    end

    local economy = self:_getEconomyService()
    if type(economy) ~= "table" then
        return false, "economy_unavailable"
    end

    local currency = type(item.currency) == "string" and item.currency or "MM"
    local spendOk, spendErr = safeCall(economy, "SpendCurrency", senderPlayer or senderUserId, currency, tonumber(item.price) or 0, "GiftPurchase")
    if spendOk ~= true then
        return false, spendErr or "gift_payment_failed"
    end

    local granted = nil
    if type(inventory.GrantItem) == "function" then
        granted = safeCall(inventory, "GrantItem", recipientPlayer, itemId, item)
    end
    if granted ~= true then
        granted = safeCall(inventory, "AddCosmeticOwnership", recipientPlayer, itemId)
    end
    if granted ~= true then
        safeCall(economy, "AddCurrency", senderPlayer or senderUserId, currency, tonumber(item.price) or 0, "GiftPurchaseRefund")
        return false, "gift_grant_failed"
    end

    self:_persistInventory(recipientPlayer)

    self:_publish("GiftPurchaseCompleted", {
        fromUserId = senderUserId,
        toUserId = recipientPlayer.UserId,
        itemId = itemId,
        price = tonumber(item.price) or 0,
        currency = currency,
    })

    return true
end

function Service:_nextTradeId()
    local nextId = self._state:Get("nextTradeId") or 1
    self._state:Set("nextTradeId", nextId + 1)
    return string.format("trade_%06d", nextId)
end

function Service:RequestTrade(payload)
    local cfg = self._state:Get("config") or {}
    if cfg.TradingEnabled == false then
        return false, "trading_disabled"
    end

    local fromUserId = toUserId(payload and (payload.fromPlayer or payload.fromUserId))
    local toUserIdValue = toUserId(payload and (payload.toPlayer or payload.toUserId))
    local offeredCosmeticId = payload and payload.offeredCosmeticId
    local requestedCosmeticId = payload and payload.requestedCosmeticId

    if not fromUserId or not toUserIdValue or fromUserId == toUserIdValue then
        return false, "invalid_trade_users"
    end

    local inventory = self._dependencies.InventorySystem
    local fromOwns = safeCall(inventory, "OwnsCosmetic", fromUserId, offeredCosmeticId)
    local toOwns = safeCall(inventory, "OwnsCosmetic", toUserIdValue, requestedCosmeticId)

    if fromOwns ~= true or toOwns ~= true then
        return false, "ownership_validation_failed"
    end

    local tradeId = self:_nextTradeId()
    local pending = self._state:Get("pendingTrades") or {}
    pending[tradeId] = {
        tradeId = tradeId,
        fromUserId = fromUserId,
        toUserId = toUserIdValue,
        offeredCosmeticId = offeredCosmeticId,
        requestedCosmeticId = requestedCosmeticId,
        createdAt = os.time(),
        expiresAt = os.time() + math.max(30, math.floor(tonumber(cfg.TradeTimeoutSeconds) or 120)),
        status = "Pending",
    }
    self._state:Set("pendingTrades", pending)

    self:_publish("TradeRequested", pending[tradeId])
    return true, nil, deepCopy(pending[tradeId])
end

function Service:AcceptTrade(payload)
    local tradeId = payload and payload.tradeId
    local accepterUserId = toUserId(payload and (payload.userId or payload.player))
    if type(tradeId) ~= "string" or not accepterUserId then
        return false, "invalid_accept_payload"
    end

    local pending = self._state:Get("pendingTrades") or {}
    local trade = pending[tradeId]
    if type(trade) ~= "table" or trade.status ~= "Pending" then
        return false, "trade_not_pending"
    end

    if trade.toUserId ~= accepterUserId then
        return false, "not_trade_recipient"
    end

    if os.time() > (trade.expiresAt or 0) then
        trade.status = "Expired"
        pending[tradeId] = trade
        self._state:Set("pendingTrades", pending)
        return false, "trade_expired"
    end

    local cfg = self._state:Get("config") or {}
    local fee = math.max(0, math.floor(tonumber(cfg.TradeFeeAmount) or 0))
    local economy = self._dependencies.EconomySystem

    if fee > 0 then
        local paidFrom = safeCall(economy, "SpendCurrency", trade.fromUserId, "MM", fee, "TradingFee")
        local paidTo = safeCall(economy, "SpendCurrency", trade.toUserId, "MM", fee, "TradingFee")
        if paidFrom ~= true or paidTo ~= true then
            return false, "trade_fee_failed"
        end
    end

    trade.status = "Completed"
    trade.completedAt = os.time()
    pending[tradeId] = trade
    self._state:Set("pendingTrades", pending)

    -- Inventory transfer event is explicit and server-authoritative; InventorySystem can process debit/credit in dedicated handlers.
    self:_publish("CosmeticTradeTransferRequested", {
        tradeId = tradeId,
        fromUserId = trade.fromUserId,
        toUserId = trade.toUserId,
        offeredCosmeticId = trade.offeredCosmeticId,
        requestedCosmeticId = trade.requestedCosmeticId,
    })

    self:_publish("TradeCompleted", deepCopy(trade))
    return true
end

function Service:OnMatchEnded(payload)
    local stats = self._state:Get("globalStats") or {}

    local results = payload and payload.results or {}
    local outcome = results.playerOutcome or {}

    for key, entry in pairs(outcome) do
        local userId = tonumber(key) or entry.userId
        if userId then
            stats.investigationsCompleted[userId] = (stats.investigationsCompleted[userId] or 0) + 1

            if entry.extracted == true then
                stats.survivalStreak[userId] = (stats.survivalStreak[userId] or 0) + 1
            else
                stats.survivalStreak[userId] = 0
            end

            if type(results.timeToIdentifyGhostSeconds) == "number" then
                local existing = stats.fastestIdentifySeconds[userId]
                if existing == nil or results.timeToIdentifyGhostSeconds < existing then
                    stats.fastestIdentifySeconds[userId] = results.timeToIdentifyGhostSeconds
                end
            end
        end
    end

    self._state:Set("globalStats", stats)

    self:_publish("GlobalLeaderboardStatsUpdated", {
        investigationsCompleted = stats.investigationsCompleted,
        survivalStreak = stats.survivalStreak,
        fastestIdentifySeconds = stats.fastestIdentifySeconds,
    })
end

return Service
