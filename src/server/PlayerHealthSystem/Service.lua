local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    BaseHealth = 100,
    DefaultAttackDamage = 50,
    MinAttackDamage = 20,
    MaxAttackDamage = 100,
    ProximityExposureThreshold = 3,
    ProximityExposureStep = 1,
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

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.PlayerHealthConfig)
    return self
end

function Service:Init()
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
    self._state:Set("activeMatchId", self._state:Get("activeMatchId"))
    self._state:Set("playerHealthByMatchId", self._state:Get("playerHealthByMatchId") or {})
    self._state:Set("proximityExposureByMatchId", self._state:Get("proximityExposureByMatchId") or {})
    self._state:Set("deadPlayersByMatchId", self._state:Get("deadPlayersByMatchId") or {})
    self._state:Set("huntActiveByMatchId", self._state:Get("huntActiveByMatchId") or {})
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

function Service:_getMap(key)
    return self._state:Get(key) or {}
end

function Service:_setMap(key, value)
    self._state:Set(key, value)
end

function Service:_ensurePlayerHealth(matchId, userId)
    local healthByMatch = self:_getMap("playerHealthByMatchId")
    healthByMatch[matchId] = healthByMatch[matchId] or {}
    if type(healthByMatch[matchId][userId]) ~= "number" then
        healthByMatch[matchId][userId] = self._config.BaseHealth
    end
    self:_setMap("playerHealthByMatchId", healthByMatch)
    return healthByMatch[matchId][userId]
end

function Service:_setPlayerHealth(matchId, userId, value)
    local healthByMatch = self:_getMap("playerHealthByMatchId")
    healthByMatch[matchId] = healthByMatch[matchId] or {}
    healthByMatch[matchId][userId] = value
    self:_setMap("playerHealthByMatchId", healthByMatch)
end

function Service:_setDead(matchId, userId)
    local deadByMatch = self:_getMap("deadPlayersByMatchId")
    deadByMatch[matchId] = deadByMatch[matchId] or {}
    deadByMatch[matchId][userId] = true
    self:_setMap("deadPlayersByMatchId", deadByMatch)
end

function Service:_isDead(matchId, userId)
    local deadByMatch = self:_getMap("deadPlayersByMatchId")
    return deadByMatch[matchId] and deadByMatch[matchId][userId] == true
end

function Service:_setExposure(matchId, userId, value)
    local exposureByMatch = self:_getMap("proximityExposureByMatchId")
    exposureByMatch[matchId] = exposureByMatch[matchId] or {}
    exposureByMatch[matchId][userId] = value
    self:_setMap("proximityExposureByMatchId", exposureByMatch)
end

function Service:_getExposure(matchId, userId)
    local exposureByMatch = self:_getMap("proximityExposureByMatchId")
    exposureByMatch[matchId] = exposureByMatch[matchId] or {}
    return exposureByMatch[matchId][userId] or 0
end

function Service:_setHuntActive(matchId, isActive)
    local huntActive = self:_getMap("huntActiveByMatchId")
    huntActive[matchId] = isActive == true
    self:_setMap("huntActiveByMatchId", huntActive)
end

function Service:_isHuntActive(matchId)
    local huntActive = self:_getMap("huntActiveByMatchId")
    return huntActive[matchId] == true
end

function Service:_registerMatchPlayers(payload)
    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    local players = payload and payload.players
    if type(players) ~= "table" then
        return
    end

    for _, player in ipairs(players) do
        local userId = toUserId(player)
        if userId then
            self:_ensurePlayerHealth(matchId, userId)
            self:_setExposure(matchId, userId, 0)
        end
    end
end

function Service:_killPlayer(matchId, userId, player, reason, payload)
    if self:_isDead(matchId, userId) then
        return
    end
    self:_setPlayerHealth(matchId, userId, 0)
    self:_setDead(matchId, userId)
    self:_setExposure(matchId, userId, 0)

    self:_publish("PlayerHealthChanged", {
        matchId = matchId,
        userId = userId,
        player = player,
        health = 0,
        reason = reason,
    })
    self:_publish("PlayerDied", {
        matchId = matchId,
        userId = userId,
        player = player,
        reason = reason,
        source = "PlayerHealthSystem",
        context = payload,
    })
end

function Service:_handleGhostInteraction(payload)
    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" or not self:_isHuntActive(matchId) then
        return
    end

    local player = payload and payload.player
    local userId = toUserId(player) or toUserId(payload and payload.userId)
    if not userId or self:_isDead(matchId, userId) then
        return
    end

    local action = payload and (payload.action or payload.interactionType)
    if type(action) ~= "string" then
        return
    end

    self:_ensurePlayerHealth(matchId, userId)

    if action == "Attack" or action == "GhostAttack" then
        local damage = tonumber(payload and payload.damage) or self._config.DefaultAttackDamage
        damage = clamp(damage, self._config.MinAttackDamage, self._config.MaxAttackDamage)
        local currentHealth = self:_ensurePlayerHealth(matchId, userId)
        local nextHealth = math.max(0, currentHealth - damage)
        self:_setPlayerHealth(matchId, userId, nextHealth)

        self:_publish("PlayerHealthChanged", {
            matchId = matchId,
            userId = userId,
            player = player,
            health = nextHealth,
            reason = "ghost_attack",
            damage = damage,
        })

        if nextHealth <= 0 then
            self:_killPlayer(matchId, userId, player, "ghost_attack", payload)
        end
        return
    end

    if action == "GhostNear" or action == "ProximityPressure" or action == "GhostProximity" then
        local step = tonumber(payload and payload.exposureStep) or self._config.ProximityExposureStep
        local exposure = self:_getExposure(matchId, userId) + math.max(0.1, step)
        self:_setExposure(matchId, userId, exposure)

        if exposure >= self._config.ProximityExposureThreshold then
            self:_killPlayer(matchId, userId, player, "failed_escape_proximity", payload)
        end
        return
    end

    if action == "EscapedGhost" then
        self:_setExposure(matchId, userId, 0)
    end
end

function Service:_clearMatchData(matchId)
    local keys = {
        "playerHealthByMatchId",
        "proximityExposureByMatchId",
        "deadPlayersByMatchId",
        "huntActiveByMatchId",
    }
    for _, key in ipairs(keys) do
        local mapValue = self:_getMap(key)
        mapValue[matchId] = nil
        self:_setMap(key, mapValue)
    end
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        self._state:Set("activeMatchId", matchId)
        self:_setHuntActive(matchId, false)
        self:_registerMatchPlayers(payload)
        return
    end

    if eventName == "MatchEnded" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        self:_clearMatchData(matchId)
        if self._state:Get("activeMatchId") == matchId then
            self._state:Set("activeMatchId", nil)
        end
        return
    end

    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    if eventName == "HuntStarted" then
        self:_setHuntActive(matchId, true)
        return
    end

    if eventName == "HuntEnded" then
        self:_setHuntActive(matchId, false)
        local exposureByMatch = self:_getMap("proximityExposureByMatchId")
        exposureByMatch[matchId] = {}
        self:_setMap("proximityExposureByMatchId", exposureByMatch)
        return
    end

    if eventName == "PlayerEscapedHunt" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            self:_setExposure(matchId, userId, 0)
        end
        return
    end

    if eventName == "GhostInteraction" then
        self:_handleGhostInteraction(payload)
        return
    end

    if eventName == "PlayerDisconnected" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if not userId then
            return
        end

        local mapKeys = {
            "playerHealthByMatchId",
            "proximityExposureByMatchId",
            "deadPlayersByMatchId",
        }
        for _, key in ipairs(mapKeys) do
            local mapValue = self:_getMap(key)
            if type(mapValue[matchId]) == "table" then
                mapValue[matchId][userId] = nil
                self:_setMap(key, mapValue)
            end
        end
    end
end

return Service
