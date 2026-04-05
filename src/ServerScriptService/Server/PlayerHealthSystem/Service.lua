local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    BaseHealth = 100,
    DefaultAttackDamage = 50,
    MinAttackDamage = 20,
    MaxAttackDamage = 100,
    ProximityExposureThreshold = 4.5,
    ProximityExposureStep = 1,
    HuntStartGraceSeconds = 6.0,
    MaxHuntPressureTickDelta = 0.5,
    HuntPressureBurstStep = 0.35,
    HuntPressureBurstDuringGraceStep = 0.15,
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

local function normalizeUserKey(userId)
    local numericUserId = tonumber(userId)
    if numericUserId then
        return tostring(numericUserId)
    end
    if userId == nil then
        return nil
    end
    return tostring(userId)
end

local function setStudioRuntimeAttribute(name, value)
    if not RunService:IsStudio() then
        return
    end
    ReplicatedStorage:SetAttribute(name, value)
end

local function setStudioProbe(name, value)
    if not RunService:IsStudio() then
        return
    end
    ReplicatedStorage:SetAttribute(name, value)
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
    self._state:Set("huntStartedAtByMatchId", self._state:Get("huntStartedAtByMatchId") or {})
    self._state:Set("hiddenPlayersByMatchId", self._state:Get("hiddenPlayersByMatchId") or {})
end

function Service:Start()
    setStudioRuntimeAttribute("PasrahHuntPressureReady", true)
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
    setStudioRuntimeAttribute("PasrahHuntPressureReady", nil)
    setStudioRuntimeAttribute("PasrahHuntPressureActiveMatchId", nil)
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
    local userKey = normalizeUserKey(userId)
    if userKey == nil then
        return self._config.BaseHealth
    end
    local healthByMatch = self:_getMap("playerHealthByMatchId")
    healthByMatch[matchId] = healthByMatch[matchId] or {}
    if type(healthByMatch[matchId][userKey]) ~= "number" then
        healthByMatch[matchId][userKey] = self._config.BaseHealth
    end
    self:_setMap("playerHealthByMatchId", healthByMatch)
    return healthByMatch[matchId][userKey]
end

function Service:_setPlayerHealth(matchId, userId, value)
    local userKey = normalizeUserKey(userId)
    if userKey == nil then
        return
    end
    local healthByMatch = self:_getMap("playerHealthByMatchId")
    healthByMatch[matchId] = healthByMatch[matchId] or {}
    healthByMatch[matchId][userKey] = value
    self:_setMap("playerHealthByMatchId", healthByMatch)
end

function Service:_setDead(matchId, userId)
    local userKey = normalizeUserKey(userId)
    if userKey == nil then
        return
    end
    local deadByMatch = self:_getMap("deadPlayersByMatchId")
    deadByMatch[matchId] = deadByMatch[matchId] or {}
    deadByMatch[matchId][userKey] = true
    self:_setMap("deadPlayersByMatchId", deadByMatch)
end

function Service:_isDead(matchId, userId)
    local userKey = normalizeUserKey(userId)
    if userKey == nil then
        return false
    end
    local deadByMatch = self:_getMap("deadPlayersByMatchId")
    return deadByMatch[matchId] and deadByMatch[matchId][userKey] == true
end

function Service:_setExposure(matchId, userId, value)
    local userKey = normalizeUserKey(userId)
    if userKey == nil then
        return
    end
    local exposureByMatch = self:_getMap("proximityExposureByMatchId")
    exposureByMatch[matchId] = exposureByMatch[matchId] or {}
    exposureByMatch[matchId][userKey] = value
    self:_setMap("proximityExposureByMatchId", exposureByMatch)
end

function Service:_getExposure(matchId, userId)
    local userKey = normalizeUserKey(userId)
    if userKey == nil then
        return 0
    end
    local exposureByMatch = self:_getMap("proximityExposureByMatchId")
    exposureByMatch[matchId] = exposureByMatch[matchId] or {}
    return exposureByMatch[matchId][userKey] or 0
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

function Service:_setHuntStartedAt(matchId, startedAt)
    local huntStartedAt = self:_getMap("huntStartedAtByMatchId")
    huntStartedAt[matchId] = startedAt
    self:_setMap("huntStartedAtByMatchId", huntStartedAt)
end

function Service:_getHuntStartedAt(matchId)
    local huntStartedAt = self:_getMap("huntStartedAtByMatchId")
    return huntStartedAt[matchId]
end

function Service:_getHuntGraceRemaining(matchId, now)
    local startedAt = self:_getHuntStartedAt(matchId)
    if type(startedAt) ~= "number" then
        return 0
    end
    return math.max(0, (self._config.HuntStartGraceSeconds or 0) - ((now or os.clock()) - startedAt))
end

function Service:_setHidden(matchId, userId, isHidden)
    local userKey = normalizeUserKey(userId)
    if userKey == nil then
        return
    end
    local hiddenByMatch = self:_getMap("hiddenPlayersByMatchId")
    hiddenByMatch[matchId] = hiddenByMatch[matchId] or {}
    hiddenByMatch[matchId][userKey] = isHidden == true
    self:_setMap("hiddenPlayersByMatchId", hiddenByMatch)
end

function Service:_isHidden(matchId, userId)
    local userKey = normalizeUserKey(userId)
    if userKey == nil then
        return false
    end
    local hiddenByMatch = self:_getMap("hiddenPlayersByMatchId")
    return hiddenByMatch[matchId] and hiddenByMatch[matchId][userKey] == true
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

    local directGhost = liveMatch.ghost
    if typeof(directGhost) == "Instance" then
        if directGhost:IsA("BasePart") then
            return directGhost.Position
        end
        if directGhost:IsA("Model") then
            local directRoot = directGhost.PrimaryPart or directGhost:FindFirstChild("HumanoidRootPart", true) or directGhost:FindFirstChildWhichIsA("BasePart", true)
            if directRoot and directRoot:IsA("BasePart") then
                return directRoot.Position
            end
            local ok, pivot = pcall(function()
                return directGhost:GetPivot()
            end)
            if ok and typeof(pivot) == "CFrame" then
                return pivot.Position
            end
        end
    end

    local container = liveMatch.container
    if typeof(container) ~= "Instance" then
        local activeMatches = workspace:FindFirstChild("ActiveMatches")
        local matchId = liveMatch.matchId or liveMatch.id
        container = activeMatches and matchId and activeMatches:FindFirstChild("Match_" .. tostring(matchId)) or nil
    end
    if typeof(container) ~= "Instance" then
        return nil
    end

    for _, child in ipairs(container:GetDescendants()) do
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

function Service:_setExposureAttribute(player, exposure)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end
    if type(exposure) == "number" and exposure > 0 then
        player:SetAttribute("PasrahHuntExposure", math.floor(exposure * 100 + 0.5) / 100)
    else
        player:SetAttribute("PasrahHuntExposure", nil)
    end
end

function Service:_tickHuntPressure(dt)
    local now = os.clock()
    local effectiveDt = math.min(math.max(dt or 0, 0), self._config.MaxHuntPressureTickDelta or HUNT_PRESSURE_TICK_INTERVAL)
    setStudioProbe("PasrahHuntPressureLastTickAt", math.floor(now * 100 + 0.5) / 100)
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
                            self:_setExposureAttribute(player, exposure)
                            self:_setThreatAttributes(player, nil, "Sheltered")
                        else
                            local root = getCharacterRoot(player)
                            local distance = math.huge
                            if root and ghostPosition then
                                distance = (root.Position - ghostPosition).Magnitude
                            end
                            local huntGraceRemaining = self:_getHuntGraceRemaining(matchId, now)
                            player:SetAttribute("PasrahHuntGraceRemaining", huntGraceRemaining > 0 and math.floor(huntGraceRemaining * 10 + 0.5) / 10 or nil)

                            local threatState = "Clear"
                            local exposureGain = 0
                            if distance <= HUNT_DISTANCE_KILL then
                                threatState = "Critical"
                                exposureGain = math.max(0.55, effectiveDt * 1.8)
                            elseif distance <= HUNT_DISTANCE_CLOSE then
                                threatState = "Close"
                                exposureGain = math.max(0.28, effectiveDt * 1.1)
                            elseif distance <= HUNT_DISTANCE_TRACK then
                                threatState = "Tracked"
                                exposureGain = math.max(0.14, effectiveDt * 0.6)
                            elseif distance <= HUNT_DISTANCE_WARN then
                                threatState = "Warn"
                                exposureGain = math.max(0.06, effectiveDt * 0.3)
                            end

                            local exposure = self:_getExposure(matchId, userId)
                            local lethalExposure = self._config.ProximityExposureThreshold or 4.5
                            if huntGraceRemaining > 0 then
                                exposure = math.max(0, exposure - math.max(0.08, effectiveDt * 0.45))
                                exposure = math.min(exposure, math.max(0, lethalExposure - 0.25))
                                self:_setExposure(matchId, userId, exposure)
                            elseif exposureGain > 0 then
                                exposure = exposure + exposureGain
                                self:_setExposure(matchId, userId, exposure)
                            else
                                exposure = math.max(0, exposure - math.max(0.05, effectiveDt * 0.35))
                                self:_setExposure(matchId, userId, exposure)
                            end

                            self:_setExposureAttribute(player, exposure)
                            setStudioProbe("PasrahHuntPressureLastExposure", math.floor(exposure * 100 + 0.5) / 100)
                            setStudioProbe("PasrahHuntPressureLastThreatState", threatState)
                            setStudioProbe(
                                "PasrahHuntDebugLastTick",
                                string.format(
                                    "match=%s threat=%s distance=%.2f exposure=%.2f grace=%.2f dt=%.2f",
                                    tostring(matchId),
                                    tostring(threatState),
                                    tonumber(distance) or -1,
                                    tonumber(exposure) or -1,
                                    tonumber(huntGraceRemaining) or -1,
                                    tonumber(effectiveDt) or -1
                                )
                            )
                            self:_setThreatAttributes(player, distance, threatState)
                            if huntGraceRemaining <= 0 and exposure >= lethalExposure then
                                setStudioProbe(
                                    "PasrahHuntKillCause",
                                    string.format(
                                        "tick match=%s threat=%s distance=%.2f exposure=%.2f grace=%.2f dt=%.2f",
                                        tostring(matchId),
                                        tostring(threatState),
                                        tonumber(distance) or -1,
                                        tonumber(exposure) or -1,
                                        tonumber(huntGraceRemaining) or -1,
                                        tonumber(effectiveDt) or -1
                                    )
                                )
                                setStudioProbe("PasrahHuntKillStage", string.format("attempt:%s:%.2f", tostring(matchId), exposure))
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
                        self:_setExposureAttribute(player, nil)
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
    setStudioProbe("PasrahHuntKillStage", string.format("entered:%s:%s", tostring(matchId), tostring(reason)))
    self:_setPlayerHealth(matchId, userId, 0)
    self:_setDead(matchId, userId)
    self:_setExposure(matchId, userId, 0)
    self:_setExposureAttribute(player, nil)
    setStudioProbe("PasrahHuntKillStage", string.format("dead_marked:%s:%s", tostring(matchId), tostring(reason)))

    self:_publish("PlayerHealthChanged", {
        matchId = matchId,
        userId = userId,
        player = player,
        health = 0,
        reason = reason,
    })
    setStudioProbe("PasrahHuntKillStage", string.format("health_published:%s:%s", tostring(matchId), tostring(reason)))
    self:_publish("PlayerDied", {
        matchId = matchId,
        userId = userId,
        player = player,
        reason = reason,
        source = "PlayerHealthSystem",
        context = payload,
    })
    setStudioProbe("PasrahHuntKillStage", string.format("death_published:%s:%s", tostring(matchId), tostring(reason)))
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
        local graceRemaining = self:_getHuntGraceRemaining(matchId)
        local lethalExposure = self._config.ProximityExposureThreshold or 4.5
        local step = tonumber(payload and payload.exposureStep) or self._config.ProximityExposureStep
        local exposure = self:_getExposure(matchId, userId) + math.max(0.1, step)
        if graceRemaining > 0 then
            exposure = math.min(exposure, math.max(0, lethalExposure - 0.25))
        end
        self:_setExposure(matchId, userId, exposure)
        setStudioProbe(
            "PasrahHuntDebugLastInteraction",
            string.format(
                "action=%s match=%s exposure=%.2f grace=%.2f step=%.2f",
                tostring(action),
                tostring(matchId),
                tonumber(exposure) or -1,
                tonumber(graceRemaining) or -1,
                tonumber(step) or -1
            )
        )

        if graceRemaining <= 0 and exposure >= lethalExposure then
            setStudioProbe(
                "PasrahHuntKillCause",
                string.format(
                    "interaction action=%s match=%s exposure=%.2f grace=%.2f step=%.2f",
                    tostring(action),
                    tostring(matchId),
                    tonumber(exposure) or -1,
                    tonumber(graceRemaining) or -1,
                    tonumber(step) or -1
                )
            )
            self:_killPlayer(matchId, userId, player, "failed_escape_proximity", payload)
        end
        return
    end

    if action == "HuntPressure" then
        local graceRemaining = self:_getHuntGraceRemaining(matchId)
        local lethalExposure = self._config.ProximityExposureThreshold or 4.5
        local step = tonumber(payload and payload.exposureStep)
        if graceRemaining > 0 then
            step = step or self._config.HuntPressureBurstDuringGraceStep or 0.15
        else
            step = step or self._config.HuntPressureBurstStep or 0.35
        end
        local exposure = self:_getExposure(matchId, userId) + math.max(0.15, step)
        if graceRemaining > 0 then
            exposure = math.min(exposure, math.max(0, lethalExposure - 0.25))
        end
        self:_setExposure(matchId, userId, exposure)
        setStudioProbe(
            "PasrahHuntDebugLastInteraction",
            string.format(
                "action=%s match=%s exposure=%.2f grace=%.2f step=%.2f",
                tostring(action),
                tostring(matchId),
                tonumber(exposure) or -1,
                tonumber(graceRemaining) or -1,
                tonumber(step) or -1
            )
        )

        if graceRemaining <= 0 and exposure >= lethalExposure then
            setStudioProbe(
                "PasrahHuntKillCause",
                string.format(
                    "interaction action=%s match=%s exposure=%.2f grace=%.2f step=%.2f",
                    tostring(action),
                    tostring(matchId),
                    tonumber(exposure) or -1,
                    tonumber(graceRemaining) or -1,
                    tonumber(step) or -1
                )
            )
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
        "huntStartedAtByMatchId",
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
        setStudioRuntimeAttribute("PasrahHuntPressureActiveMatchId", matchId)
        self:_setHuntActive(matchId, false)
        self:_registerMatchPlayers(payload)
        setStudioProbe("PasrahHuntPressureLastExposure", nil)
        setStudioProbe("PasrahHuntPressureLastThreatState", nil)
        setStudioProbe("PasrahHuntKillStage", nil)
        for _, player in ipairs(payload and payload.players or {}) do
            if typeof(player) == "Instance" and player:IsA("Player") then
                player:SetAttribute("PasrahHuntThreatState", "Clear")
                player:SetAttribute("PasrahHuntThreatDistance", nil)
                player:SetAttribute("PasrahHuntGraceRemaining", nil)
                player:SetAttribute("PasrahHuntExposure", nil)
            end
        end
        return
    end

    if eventName == "MatchEnded" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        local clearedPlayers = {}
        for _, player in ipairs(payload and payload.players or {}) do
            if typeof(player) == "Instance" and player:IsA("Player") then
                clearedPlayers[player] = true
                player:SetAttribute("PasrahHuntThreatState", "Clear")
                player:SetAttribute("PasrahHuntThreatDistance", nil)
                player:SetAttribute("PasrahHuntGraceRemaining", nil)
                player:SetAttribute("PasrahHuntExposure", nil)
            end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if not clearedPlayers[player] and player:GetAttribute("MatchId") == matchId then
                player:SetAttribute("PasrahHuntThreatState", "Clear")
                player:SetAttribute("PasrahHuntThreatDistance", nil)
                player:SetAttribute("PasrahHuntGraceRemaining", nil)
                player:SetAttribute("PasrahHuntExposure", nil)
            end
        end
        self:_clearMatchData(matchId)
        if self._state:Get("activeMatchId") == matchId then
            self._state:Set("activeMatchId", nil)
        end
        setStudioProbe("PasrahHuntPressureLastExposure", nil)
        setStudioProbe("PasrahHuntPressureLastThreatState", nil)
        setStudioProbe("PasrahHuntKillStage", nil)
        setStudioRuntimeAttribute("PasrahHuntPressureActiveMatchId", nil)
        return
    end

    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    if eventName == "HuntStarted" then
        self:_setHuntActive(matchId, true)
        self:_setHuntStartedAt(matchId, os.clock())
        setStudioProbe("PasrahHuntKillStage", nil)
        local liveMatch = getLiveMatch(self._dependencies.MatchSystem, matchId)
        local playersByUserId = liveMatch and liveMatch.playersByUserId or nil
        if type(playersByUserId) == "table" then
            for _, playerState in pairs(playersByUserId) do
                local player = playerState and playerState.player
                if typeof(player) == "Instance" and player:IsA("Player") and playerState.alive ~= false then
                    player:SetAttribute("PasrahHuntThreatState", "Warn")
                    player:SetAttribute("PasrahHuntThreatDistance", nil)
                    player:SetAttribute("PasrahHuntGraceRemaining", math.floor((self._config.HuntStartGraceSeconds or 0) * 10 + 0.5) / 10)
                    player:SetAttribute("PasrahHuntExposure", nil)
                end
            end
        end
        return
    end

    if eventName == "HuntEnded" then
        self:_setHuntActive(matchId, false)
        self:_setHuntStartedAt(matchId, nil)
        local exposureByMatch = self:_getMap("proximityExposureByMatchId")
        exposureByMatch[matchId] = {}
        self:_setMap("proximityExposureByMatchId", exposureByMatch)
        local players = Players:GetPlayers()
        for _, player in ipairs(players) do
            if player:GetAttribute("MatchId") == matchId then
                player:SetAttribute("PasrahHuntGraceRemaining", nil)
                player:SetAttribute("PasrahHuntExposure", nil)
                self:_setThreatAttributes(player, nil, "Clear")
            end
        end
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
        if typeof(player) == "Instance" and player:IsA("Player") then
            player:SetAttribute("PasrahHuntExposure", nil)
        end
        self:_setThreatAttributes(player, nil, "Clear")
    end
end

return Service
