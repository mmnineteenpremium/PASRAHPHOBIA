local Players = game:GetService("Players")
local Services = require(script.Parent.Parent.Core.Services)
local GhostHuntController = require(script.Parent.Parent.GhostSystem.GhostHuntController)

local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    SanityThreshold = 45,
    AggressionThreshold = 75,
    EscalationStages = {
        Aggressive = true,
        Hunting = true,
    },
    BaseDurationSeconds = 34,
    MinDurationSeconds = 24,
    MaxDurationSeconds = 65,
    CooldownSeconds = 30,
    PendingTimeoutSeconds = 3,
    InitialHuntGraceSeconds = 45,
}

-- removed: huntCooldown is now per-match via state

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

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function normalize01(value, fallback)
    if type(value) ~= "number" then
        return fallback
    end
    if value > 1 then
        value = value / 100
    end
    return clamp(value, 0, 1)
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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        FearSystem = Services.Get(self._deps, "FearSystem"),
        AggressionSystem = Services.Get(self._deps, "AggressionSystem"),
        SanitySystem = Services.Get(self._deps, "SanitySystem"),
    }
    self._ghostHuntController = GhostHuntController
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.HuntSystemConfig)
    return self
end

function Service:Init()
    self._state:Set("activeMatchId", self._state:Get("activeMatchId"))
    self._state:Set("huntActiveByMatchId", self._state:Get("huntActiveByMatchId") or {})
    self._state:Set("huntContextByMatchId", self._state:Get("huntContextByMatchId") or {})
    self._state:Set("huntCooldownUntilByMatchId", self._state:Get("huntCooldownUntilByMatchId") or {})
    self._state:Set("huntPendingByMatchId", self._state:Get("huntPendingByMatchId") or {})
    self._state:Set("huntTokenByMatchId", self._state:Get("huntTokenByMatchId") or {})
    self._state:Set("lastMetricsByMatchId", self._state:Get("lastMetricsByMatchId") or {})
    self._state:Set("matchStates", self._state:Get("matchStates") or {})
end

function Service:Start()
end

function Service:Stop()
    self._state:Clear()
end

function Service:_getAverageSanity(match)
    local sanity = nil
    local fearSystem = self._dependencies.FearSystem
    if type(fearSystem) == "table" then
        if type(fearSystem.GetAverageSanity) == "function" then
            sanity = fearSystem:GetAverageSanity(match)
        elseif type(fearSystem.Service) == "table" and type(fearSystem.Service.GetAverageSanity) == "function" then
            sanity = fearSystem.Service:GetAverageSanity(match)
        end
    end

    if sanity == nil then
        local sanitySystem = self._dependencies.SanitySystem
        local matchId = match and (match.matchId or match.id)
        if type(sanitySystem) == "table" and type(sanitySystem.GetAverageTeamSanity) == "function" then
            sanity = sanitySystem:GetAverageTeamSanity(matchId)
        elseif type(sanitySystem) == "table" and type(sanitySystem.Service) == "table" and type(sanitySystem.Service.GetAverageTeamSanity) == "function" then
            sanity = sanitySystem.Service:GetAverageTeamSanity(matchId)
        end
    end

    return normalize01(sanity, 1)
end

function Service:_getGhostAggression(match)
    local aggression = nil
    local aggressionSystem = self._dependencies.AggressionSystem
    if type(aggressionSystem) == "table" then
        if type(aggressionSystem.GetGhostAggression) == "function" then
            aggression = aggressionSystem:GetGhostAggression(match)
        elseif type(aggressionSystem.Service) == "table" and type(aggressionSystem.Service.GetGhostAggression) == "function" then
            aggression = aggressionSystem.Service:GetGhostAggression(match)
        elseif type(aggressionSystem.GetAggressionLevel) == "function" then
            local result = aggressionSystem:GetAggressionLevel(match and (match.matchId or match.id))
            aggression = type(result) == "table" and result.aggression or result
        elseif type(aggressionSystem.Service) == "table" and type(aggressionSystem.Service.GetAggressionLevel) == "function" then
            local result = aggressionSystem.Service:GetAggressionLevel(match and (match.matchId or match.id))
            aggression = type(result) == "table" and result.aggression or result
        end
    end

    return normalize01(aggression, 0)
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

function Service:_setMap(key, mapValue)
    self._state:Set(key, mapValue)
end

function Service:_getMatchStates()
    return self._state:Get("matchStates") or {}
end

function Service:_setMatchStates(states)
    self._state:Set("matchStates", states)
end

function Service:_getMatchState(matchId)
    local states = self:_getMatchStates()
    local state = states[matchId]
    if not state then
        state = {
            huntActive = false,
            huntCooldown = false,
            startedAt = nil,
        }
        states[matchId] = state
        self:_setMatchStates(states)
    end
    return state
end

function Service:_clearMatchState(matchId)
    local states = self:_getMatchStates()
    states[matchId] = nil
    self:_setMatchStates(states)
end

function Service:_applyHuntEffects(matchId)
    self:_publish("HuntEffectDoorLock", { matchId = matchId })
    self:_publish("HuntEffectLighting", { matchId = matchId })
    self:_publish("HuntEffectToolJam", { matchId = matchId })
end

function Service:TryStartHunt(matchId)
    if type(matchId) ~= "string" then
        return false, "invalid_match"
    end
    local allowed, rejectReason = self:_canRequestHunt(matchId, false)
    if not allowed then
        return false, rejectReason
    end
    local state = self:_getMatchState(matchId)
    if state.huntCooldown or state.huntActive then
        return false, "hunt_unavailable"
    end
    state.huntActive = true
    state.huntCooldown = true

    self:_publish("HuntStarted", {
        matchId = matchId,
        reason = "validated_legacy_try_start",
        source = "HuntSystem",
    })
    self:_applyHuntEffects(matchId)

    local duration = math.random(20, 40)
    task.delay(duration, function()
        self:EndHunt(matchId)
    end)
end

function Service:EndHunt(matchId)
    if type(matchId) ~= "string" then
        return
    end
    local state = self:_getMatchState(matchId)
    state.huntActive = false
    self:_publish("HuntEnded", { matchId = matchId })

    local cooldownDuration = math.random(25, 45)
    task.delay(cooldownDuration, function()
        local states = self:_getMatchStates()
        local current = states[matchId]
        if current then
            current.huntCooldown = false
        end
    end)
end

function Service:_setMetric(matchId, values)
    if type(matchId) ~= "string" then
        return
    end
    local metricsByMatch = self:_getMap("lastMetricsByMatchId")
    local current = metricsByMatch[matchId] or {
        averageSanity = 100,
        aggression = 0,
        escalationStage = "Calm",
    }

    if type(values.averageSanity) == "number" then
        current.averageSanity = clamp(values.averageSanity, 0, 100)
    end
    if type(values.aggression) == "number" then
        current.aggression = clamp(values.aggression, 0, 100)
    end
    if type(values.escalationStage) == "string" and values.escalationStage ~= "" then
        current.escalationStage = values.escalationStage
    end

    current.updatedAt = os.clock()
    metricsByMatch[matchId] = current
    self:_setMap("lastMetricsByMatchId", metricsByMatch)
end

function Service:_getMetric(matchId)
    local metricsByMatch = self:_getMap("lastMetricsByMatchId")
    return metricsByMatch[matchId] or {
        averageSanity = 100,
        aggression = 0,
        escalationStage = "Calm",
    }
end

function Service:_isEscalationEligible(stageName)
    if type(stageName) ~= "string" then
        return false
    end
    return self._config.EscalationStages[stageName] == true
end

function Service:_canRequestHunt(matchId, force)
    if type(matchId) ~= "string" then
        return false, "invalid_match"
    end

    local activeByMatch = self:_getMap("huntActiveByMatchId")
    if activeByMatch[matchId] == true then
        return false, "hunt_already_active"
    end

    local pendingByMatch = self:_getMap("huntPendingByMatchId")
    if pendingByMatch[matchId] == true then
        return false, "hunt_request_pending"
    end

    local cooldownUntilByMatch = self:_getMap("huntCooldownUntilByMatchId")
    local cooldownUntil = cooldownUntilByMatch[matchId] or 0
    if os.clock() < cooldownUntil then
        return false, "hunt_cooldown_active"
    end

    if force == true then
        return true
    end

    local state = self:_getMatchState(matchId)
    local graceSeconds = tonumber(self._config.InitialHuntGraceSeconds) or 0
    local startedAt = tonumber(state.startedAt) or 0
    if graceSeconds > 0 and startedAt > 0 and (os.clock() - startedAt) < graceSeconds then
        return false, "initial_hunt_grace"
    end

    local metric = self:_getMetric(matchId)
    local sanityOk = (metric.averageSanity or 100) <= self._config.SanityThreshold
    local aggressionOk = (metric.aggression or 0) >= self._config.AggressionThreshold
    local escalationOk = self:_isEscalationEligible(metric.escalationStage)
    if sanityOk and aggressionOk and escalationOk then
        return true
    end

    return false, "conditions_not_met"
end

function Service:_setPending(matchId, pending)
    local pendingByMatch = self:_getMap("huntPendingByMatchId")
    pendingByMatch[matchId] = pending == true
    self:_setMap("huntPendingByMatchId", pendingByMatch)
end

function Service:_bumpToken(matchId)
    local tokenByMatch = self:_getMap("huntTokenByMatchId")
    tokenByMatch[matchId] = (tokenByMatch[matchId] or 0) + 1
    self:_setMap("huntTokenByMatchId", tokenByMatch)
    return tokenByMatch[matchId]
end

function Service:_currentToken(matchId)
    return (self:_getMap("huntTokenByMatchId")[matchId] or 0)
end

function Service:_requestHunt(matchId, reason, force, payload)
    local t0 = tick()
    local allowed, rejectReason = self:_canRequestHunt(matchId, force)
    if not allowed then
        local elapsed = tick() - t0
        if elapsed > 0.1 then
            warn("[PERF] HuntSystem._requestHunt exceeded 100ms: " .. elapsed)
        end
        return false, rejectReason
    end

    self:_setPending(matchId, true)
    local requestToken = self:_bumpToken(matchId)
    local metric = self:_getMetric(matchId)
    local now = os.clock()

    local requestPayload = {
        matchId = matchId,
        reason = reason or "hunt_conditions_met",
        source = "HuntSystem",
        averageSanity = metric.averageSanity,
        aggression = metric.aggression,
        escalationStage = metric.escalationStage,
        now = now,
        snapshot = payload and payload.snapshot,
        force = force == true,
    }

    self:_publish("GhostHuntTriggerRequested", requestPayload)
    self:_publish("HuntTriggered", requestPayload)

    task.delay(self._config.PendingTimeoutSeconds, function()
        if self:_currentToken(matchId) ~= requestToken then
            return
        end
        local pendingByMatch = self:_getMap("huntPendingByMatchId")
        if pendingByMatch[matchId] == true then
            pendingByMatch[matchId] = false
            self:_setMap("huntPendingByMatchId", pendingByMatch)
        end
    end)

    local elapsed = tick() - t0
    if elapsed > 0.1 then
        warn("[PERF] HuntSystem._requestHunt exceeded 100ms: " .. elapsed)
    end
    return true
end

function Service:_startHuntFromGhost(payload)
    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    local metric = self:_getMetric(matchId)
    local sanityFactor = clamp((100 - (metric.averageSanity or 100)) / 100, 0, 1)
    local aggressionFactor = clamp((metric.aggression or 0) / 100, 0, 1)
    local escalationBonus = self:_isEscalationEligible(metric.escalationStage) and 0.2 or 0
    local intensity = clamp((sanityFactor * 0.5) + (aggressionFactor * 0.4) + escalationBonus, 0.35, 1)
    local duration = clamp(
        self._config.BaseDurationSeconds + math.floor(intensity * 24),
        self._config.MinDurationSeconds,
        self._config.MaxDurationSeconds
    )
    local speedMultiplier = clamp(1.15 + (intensity * 0.85), 1.15, 2)

    local activeByMatch = self:_getMap("huntActiveByMatchId")
    activeByMatch[matchId] = true
    self:_setMap("huntActiveByMatchId", activeByMatch)
    self:_setPending(matchId, false)
    self:_bumpToken(matchId)

    local contextByMatch = self:_getMap("huntContextByMatchId")
    contextByMatch[matchId] = {
        startedAt = os.clock(),
        expectedEndAt = os.clock() + duration,
        duration = duration,
        intensity = intensity,
        speedMultiplier = speedMultiplier,
        reason = payload and payload.reason or "ghost_system_hunt_start",
    }
    self:_setMap("huntContextByMatchId", contextByMatch)

    local eventPayload = {
        matchId = matchId,
        duration = duration,
        intensity = intensity,
        speedMultiplier = speedMultiplier,
        reason = contextByMatch[matchId].reason,
        source = payload and payload.source or "GhostSystem",
    }

    self:_publish("GhostHuntStarted", eventPayload)
    self:_publish("ExitDoorsLocked", {
        matchId = matchId,
        locked = true,
        source = "HuntSystem",
    })
    self:_publish("HuntDoorLockChanged", {
        matchId = matchId,
        locked = true,
        source = "HuntSystem",
    })
    self:_publish("HuntLightingStateChanged", {
        matchId = matchId,
        mode = "flicker_shutdown",
        source = "HuntSystem",
    })
    self:_publish("ToolMalfunctionStateChanged", {
        matchId = matchId,
        active = true,
        severity = intensity,
        source = "HuntSystem",
    })
    self:_publish("GhostPursuitStateChanged", {
        matchId = matchId,
        active = true,
        speedMultiplier = speedMultiplier,
        source = "HuntSystem",
    })
end

function Service:_endHuntFromGhost(payload)
    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    local activeByMatch = self:_getMap("huntActiveByMatchId")
    activeByMatch[matchId] = false
    self:_setMap("huntActiveByMatchId", activeByMatch)
    self:_setPending(matchId, false)
    self:_bumpToken(matchId)

    local cooldownByMatch = self:_getMap("huntCooldownUntilByMatchId")
    cooldownByMatch[matchId] = os.clock() + self._config.CooldownSeconds
    self:_setMap("huntCooldownUntilByMatchId", cooldownByMatch)

    local contextByMatch = self:_getMap("huntContextByMatchId")
    local context = contextByMatch[matchId]
    contextByMatch[matchId] = nil
    self:_setMap("huntContextByMatchId", contextByMatch)

    local eventPayload = {
        matchId = matchId,
        reason = payload and payload.reason or "ghost_system_hunt_end",
        source = payload and payload.source or "GhostSystem",
        intensity = context and context.intensity or nil,
        speedMultiplier = context and context.speedMultiplier or nil,
    }

    self:_publish("GhostHuntEnded", eventPayload)
    self:_publish("ExitDoorsLocked", {
        matchId = matchId,
        locked = false,
        source = "HuntSystem",
    })
    self:_publish("HuntDoorLockChanged", {
        matchId = matchId,
        locked = false,
        source = "HuntSystem",
    })
    self:_publish("HuntLightingStateChanged", {
        matchId = matchId,
        mode = "restore",
        source = "HuntSystem",
    })
    self:_publish("ToolMalfunctionStateChanged", {
        matchId = matchId,
        active = false,
        severity = 0,
        source = "HuntSystem",
    })
    self:_publish("GhostPursuitStateChanged", {
        matchId = matchId,
        active = false,
        speedMultiplier = 1,
        source = "HuntSystem",
    })
end

function Service:_onMatchStarted(payload)
    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    self._state:Set("activeMatchId", matchId)
    local state = self:_getMatchState(matchId)
    state.startedAt = os.clock()
    state.huntActive = false
    state.huntCooldown = false
    self:_setMetric(matchId, {
        averageSanity = 100,
        aggression = 0,
        escalationStage = "Calm",
    })

    local activeByMatch = self:_getMap("huntActiveByMatchId")
    activeByMatch[matchId] = false
    self:_setMap("huntActiveByMatchId", activeByMatch)
    self:_setPending(matchId, false)
end

function Service:_onMatchEnded(payload)
    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    local keys = {
        "huntActiveByMatchId",
        "huntContextByMatchId",
        "huntCooldownUntilByMatchId",
        "huntPendingByMatchId",
        "huntTokenByMatchId",
        "lastMetricsByMatchId",
    }
    for _, key in ipairs(keys) do
        local mapValue = self:_getMap(key)
        mapValue[matchId] = nil
        self:_setMap(key, mapValue)
    end

    if self._state:Get("activeMatchId") == matchId then
        self._state:Set("activeMatchId", nil)
    end
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        self:_onMatchStarted(payload)
        return
    end
    if eventName == "MatchEnded" then
        self:_onMatchEnded(payload)
        return
    end

    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    if eventName == "TeamSanityLow" then
        self:_setMetric(matchId, {
            averageSanity = tonumber(payload and payload.averageSanity),
        })
        self:_requestHunt(matchId, "low_team_sanity", false, payload)
        return
    end

    if eventName == "PlayerSanityChanged" then
        self:_setMetric(matchId, {
            averageSanity = tonumber(payload and (payload.averageSanity or payload.newSanity or payload.sanity)),
        })
        self:_requestHunt(matchId, "player_sanity_drop", false, payload)
        return
    end

    if eventName == "AggressionIncreased" or eventName == "AggressionLevelChanged" or eventName == "AggressionCritical" then
        self:_setMetric(matchId, {
            aggression = tonumber(payload and payload.aggression),
        })
        self:_requestHunt(matchId, "aggression_threshold", false, payload)
        return
    end

    if eventName == "EscalationStageChanged" then
        self:_setMetric(matchId, {
            escalationStage = payload and payload.currentStage,
        })
        if payload and payload.forceHunt == true then
            self:_requestHunt(matchId, "escalation_force_hunt", true, payload)
        else
            self:_requestHunt(matchId, "escalation_high", false, payload)
        end
        return
    end

    if eventName == "ForceHunt" then
        self:_requestHunt(matchId, "forced_hunt", true, payload)
        return
    end

    if eventName == "HuntStarted" then
        self:_startHuntFromGhost(payload)
        return
    end

    if eventName == "HuntEnded" then
        self:_endHuntFromGhost(payload)
    end
end

function Service:StartMatch(matchId, matchData)
    self:_onMatchStarted({
        matchId = matchId,
        data = matchData,
    })
    if type(matchId) == "string" then
        self:_getMatchState(matchId)
    end
end

function Service:EndMatch(matchId)
    self:_onMatchEnded({
        matchId = matchId,
    })
    if type(matchId) == "string" then
        self:_clearMatchState(matchId)
    end
end

function Service:OnAggressionUpdate(matchId, value)
    if type(matchId) ~= "string" then
        return
    end
    self:_setMetric(matchId, {
        aggression = tonumber(value),
    })
    self:_requestHunt(matchId, "aggression_threshold", false, {
        matchId = matchId,
        aggression = value,
    })
end

function Service:OnSanityCritical(matchId, playerId)
    if type(matchId) ~= "string" then
        return
    end
    self:_setMetric(matchId, {
        averageSanity = 10,
    })
    self:_requestHunt(matchId, "sanity_critical", false, {
        matchId = matchId,
        playerId = playerId,
        averageSanity = 10,
    })
end

function Service:OnHuntEnded(matchId)
    if type(matchId) ~= "string" then
        return
    end
    self:EndHunt(matchId)
end

return Service



