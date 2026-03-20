local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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
    }
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

