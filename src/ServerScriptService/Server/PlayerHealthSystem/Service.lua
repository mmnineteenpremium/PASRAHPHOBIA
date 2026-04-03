local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")

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
local HUNT_PRESSURE_TICK_INTERVAL = 0.35
local HUNT_DISTANCE_KILL = 8
local HUNT_DISTANCE_CLOSE = 16
local HUNT_DISTANCE_TRACK = 28
local HUNT_DISTANCE_WARN = 48

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
    self._running = false
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
    self._state:Set("hiddenPlayersByMatchId", self._state:Get("hiddenPlayersByMatchId") or {})
end

function Service:Start()
    if self._running then
        return
    end
    self._running = true
    task.spawn(function()
        local lastTickAt = os.clock()
        while self._running do
            local now = os.clock()
            local dt = now - lastTickAt
            lastTickAt = now
            self:_tickHuntPressure(dt)
            task.wait(HUNT_PRESSURE_TICK_INTERVAL)
        end
    end)
end

function Service:Stop()
    self._running = false
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

function Service:_setHidden(matchId, userId, isHidden)
    local hiddenByMatch = self:_getMap("hiddenPlayersByMatchId")
    hiddenByMatch[matchId] = hiddenByMatch[matchId] or {}
    hiddenByMatch[matchId][userId] = isHidden == true
    self:_setMap("hiddenPlayersByMatchId", hiddenByMatch)
end

function Service:_isHidden(matchId, userId)
    local hiddenByMatch = self:_getMap("hiddenPlayersByMatchId")
    return hiddenByMatch[matchId] and hiddenByMatch[matchId][userId] == true
end

local function getLiveMatch(matchSystem, matchId)
    if type(matchSystem) ~= "table" or type(matchId) ~= "string" or matchId == "" then
        return nil
    end
    if type(matchSystem.GetLiveMatch) == "function" then
        return matchSystem:GetLiveMatch(matchId)
    end
    if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
        return matchSystem.Service:GetLiveMatch(matchId)
    end
    return nil
end

local function getCharacterRoot(player)
    local character = typeof(player) == "Instance" and player:IsA("Player") and player.Character or nil
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local function resolveGhostPosition(liveMatch)
    if type(liveMatch) ~= "table" then
        return nil
    end

    local container = liveMatch.container
    if typeof(container) ~= "Instance" then
        return nil
    end

    for _, child in ipairs(container:GetChildren()) do
        if child.Name:match("^Ghost_") or child.Name:match("^GhostPlaceholder_") then
            if child:IsA("BasePart") then
                return child.Position
            end
            if child:IsA("Model") then
                local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart", true) or child:FindFirstChildWhichIsA("BasePart", true)
                if root and root:IsA("BasePart") then
                    return root.Position
                end
                local ok, pivot = pcall(function()
                    return child:GetPivot()
                end)
                if ok then
                    return pivot.Position
                end
            end
        end
    end

    return nil
end

function Service:_setThreatAttributes(player, distance, threatState)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    player:SetAttribute("PasrahHuntThreatState", threatState)
    if type(distance) == "number" and distance < math.huge then
        player:SetAttribute("PasrahHuntThreatDistance", math.floor(distance + 0.5))
    else
        player:SetAttribute("PasrahHuntThreatDistance", nil)
    end
end

function Service:_tickHuntPressure(dt)
    local huntActiveByMatch = self:_getMap("huntActiveByMatchId")
    for matchId, isActive in pairs(huntActiveByMatch) do
        if isActive == true then
            local liveMatch = getLiveMatch(self._dependencies.MatchSystem, matchId)
            local ghostPosition = resolveGhostPosition(liveMatch)
            local playersByUserId = liveMatch and liveMatch.playersByUserId or nil
            if type(playersByUserId) == "table" then
                for userId, playerState in pairs(playersByUserId) do
                    local player = playerState and playerState.player or Players:GetPlayerByUserId(tonumber(userId) or 0)
                    if playerState and playerState.alive ~= false and not self:_isDead(matchId, userId) then
                        self:_ensurePlayerHealth(matchId, userId)

                        if self:_isHidden(matchId, userId) then
                            local exposure = math.max(0, self:_getExposure(matchId, userId) - math.max(0.5, dt * 2.1))
                            self:_setExposure(matchId, userId, exposure)
                            self:_setThreatAttributes(player, nil, "Sheltered")
                        else
                            local root = getCharacterRoot(player)
                            local distance = math.huge
                            if root and ghostPosition then
                                distance = (root.Position - ghostPosition).Magnitude
                            end

                            local threatState = "Clear"
                            local exposureGain = 0
                            if distance <= HUNT_DISTANCE_KILL then
                                threatState = "Critical"
                                exposureGain = math.max(0.85, dt * 2.8)
                            elseif distance <= HUNT_DISTANCE_CLOSE then
                                threatState = "Close"
                                exposureGain = math.max(0.45, dt * 1.75)
                            elseif distance <= HUNT_DISTANCE_TRACK then
                                threatState = "Tracked"
                                exposureGain = math.max(0.22, dt * 0.95)
                            elseif distance <= HUNT_DISTANCE_WARN then
                                threatState = "Warn"
                                exposureGain = math.max(0.1, dt * 0.45)
                            end

                            local exposure = self:_getExposure(matchId, userId)
                            if exposureGain > 0 then
                                exposure = exposure + exposureGain
                                self:_setExposure(matchId, userId, exposure)
                            else
                                exposure = math.max(0, exposure - math.max(0.05, dt * 0.35))
                                self:_setExposure(matchId, userId, exposure)
                            end

                            self:_setThreatAttributes(player, distance, threatState)
                            if exposure >= self._config.ProximityExposureThreshold then
                                self:_killPlayer(matchId, userId, player, "failed_escape_hunt", {
                                    matchId = matchId,
                                    action = "HuntPressure",
                                    interactionType = "HuntPressure",
                                    distance = distance,
                                    exposure = exposure,
                                })
                            end
                        end
                    else
                        self:_setThreatAttributes(player, nil, "Clear")
                    end
                end
            end
        end
    end
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

    if action == "HuntPressure" then
        local step = tonumber(payload and payload.exposureStep) or 0.85
        local exposure = self:_getExposure(matchId, userId) + math.max(0.15, step)
        self:_setExposure(matchId, userId, exposure)

        if exposure >= self._config.ProximityExposureThreshold then
            self:_killPlayer(matchId, userId, player, "failed_escape_hunt", payload)
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
        "hiddenPlayersByMatchId",
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
        for _, player in ipairs(payload and payload.players or {}) do
            if typeof(player) == "Instance" and player:IsA("Player") then
                player:SetAttribute("PasrahHuntThreatState", "Clear")
                player:SetAttribute("PasrahHuntThreatDistance", nil)
            end
        end
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

    if eventName == "PlayerHid" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            self:_setHidden(matchId, userId, true)
            self:_setExposure(matchId, userId, 0)
        end
        return
    end

    if eventName == "PlayerRevealed" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            self:_setHidden(matchId, userId, false)
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

        local player = payload and payload.player
        self:_setThreatAttributes(player, nil, "Clear")
    end
end

return Service
