local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")

local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    DefaultInventoryDrop = { "Flashlight" },
}

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

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for key, nested in pairs(value) do
        out[key] = deepCopy(nested)
    end
    return out
end

local function mergeConfig(base, override)
    local out = deepCopy(base)
    for key, value in pairs(override or {}) do
        if type(value) == "table" and type(out[key]) == "table" then
            for nestedKey, nestedValue in pairs(value) do
                out[key][nestedKey] = nestedValue
            end
        else
            out[key] = value
        end
    end
    return out
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

local function cloneArray(source)
    local out = {}
    for index, value in ipairs(source or {}) do
        out[index] = value
    end
    return out
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.PlayerDeathConfig)
    return self
end

function Service:Init()
    self._dependencies = {
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
    self._state:Set("activeMatchId", self._state:Get("activeMatchId"))
    self._state:Set("deathLog", self._state:Get("deathLog") or {})
    self._state:Set("droppedInventory", self._state:Get("droppedInventory") or {})
    self._state:Set("processedDeathsByMatchId", self._state:Get("processedDeathsByMatchId") or {})
end

function Service:Start()
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_matchId(payload)
    return payload and payload.matchId or self._state:Get("activeMatchId")
end

function Service:_markProcessed(matchId, userId)
    local processed = self._state:Get("processedDeathsByMatchId") or {}
    processed[matchId] = processed[matchId] or {}
    if processed[matchId][userId] == true then
        return true
    end
    processed[matchId][userId] = true
    self._state:Set("processedDeathsByMatchId", processed)
    return false
end

function Service:_registerDeath(matchId, userId, payload)
    local deathLog = self._state:Get("deathLog") or {}
    table.insert(deathLog, {
        matchId = matchId,
        userId = userId,
        reason = payload and payload.reason or "unknown",
        at = os.clock(),
    })
    self._state:Set("deathLog", deathLog)

    local droppedInventory = self._state:Get("droppedInventory") or {}
    droppedInventory[userId] = cloneArray(payload and payload.inventoryDrop or self._config.DefaultInventoryDrop)
    self._state:Set("droppedInventory", droppedInventory)
    return droppedInventory[userId]
end

function Service:_emitDeathFlow(matchId, userId, payload, droppedItems)
    local player = payload and payload.player
    if not player and type(userId) == "number" then
        player = Players:GetPlayerByUserId(userId)
    end
    local reason = payload and payload.reason or "unknown"

    self:_publish("PlayerDeathProcessed", {
        matchId = matchId,
        userId = userId,
        player = player,
        reason = reason,
        droppedItems = droppedItems,
        source = "PlayerDeathSystem",
    })

    self:_publish("PlayerCameraDistortionRequested", {
        matchId = matchId,
        userId = userId,
        player = player,
        preset = "death",
        source = "PlayerDeathSystem",
    })
    self:_publish("PlayerDeathAnimationRequested", {
        matchId = matchId,
        userId = userId,
        player = player,
        animation = "death_fade",
        source = "PlayerDeathSystem",
    })

    self:_publish("PlayerKilled", {
        matchId = matchId,
        userId = userId,
        player = player,
        reason = reason,
        source = "PlayerDeathSystem",
    })
    self:_publish("PlayerRemovedFromActiveGameplay", {
        matchId = matchId,
        userId = userId,
        player = player,
        reason = reason,
        source = "PlayerDeathSystem",
    })
    self:_publish("SpectatorTransitionRequested", {
        matchId = matchId,
        userId = userId,
        player = player,
        reason = reason,
        source = "PlayerDeathSystem",
    })
    self:_publish("MatchPlayerEliminated", {
        matchId = matchId,
        userId = userId,
        player = player,
        reason = reason,
        source = "PlayerDeathSystem",
    })
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end

        self._state:Set("activeMatchId", matchId)
        self._state:Set("deathLog", {})
        self._state:Set("droppedInventory", {})

        local processed = self._state:Get("processedDeathsByMatchId") or {}
        processed[matchId] = {}
        self._state:Set("processedDeathsByMatchId", processed)
        return
    end

    if eventName == "MatchEnded" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end

        local processed = self._state:Get("processedDeathsByMatchId") or {}
        processed[matchId] = nil
        self._state:Set("processedDeathsByMatchId", processed)

        if self._state:Get("activeMatchId") == matchId then
            self._state:Set("activeMatchId", nil)
        end
        return
    end

    if eventName ~= "PlayerDied" then
        return
    end

    local matchId = self:_matchId(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if type(matchId) ~= "string" or not userId then
        return
    end

    if self:_markProcessed(matchId, userId) then
        return
    end

    local droppedItems = self:_registerDeath(matchId, userId, payload)
    self:_emitDeathFlow(matchId, userId, payload, droppedItems)
end

return Service
