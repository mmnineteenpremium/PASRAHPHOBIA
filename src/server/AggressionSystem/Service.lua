local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    MinAggression = 0,
    MaxAggression = 100,
    DefaultAggression = 5,
    Thresholds = {
        Restless = 25,
        Angry = 50,
        HuntReady = 75,
        HuntTrigger = 90,
    },
    HuntProbabilityBase = 0.08,
    HuntProbabilityCap = 0.95,
}

local function resolveEventBus(deps)
    local eventBus = deps.EventBus
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

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function mergeConfig(base, override)
    local merged = {}
    for key, value in pairs(base) do
        if type(value) == "table" then
            merged[key] = mergeConfig(value, {})
        else
            merged[key] = value
        end
    end
    for key, value in pairs(override or {}) do
        if type(value) == "table" and type(merged[key]) == "table" then
            merged[key] = mergeConfig(merged[key], value)
        else
            merged[key] = value
        end
    end
    return merged
end

local function classifyAggression(level, thresholds)
    if level >= thresholds.HuntTrigger then
        return "hunt-trigger"
    end
    if level >= thresholds.HuntReady then
        return "hunt-ready"
    end
    if level >= thresholds.Angry then
        return "angry"
    end
    if level >= thresholds.Restless then
        return "restless"
    end
    return "calm"
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.AggressionConfig or {})
    return self
end

function Service:Init()
    self._state:Set("matches", {})
end

function Service:Start()
    -- Event-driven only.
end

function Service:Stop()
    self._state:Set("matches", {})
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_matches()
    return self._state:Get("matches") or {}
end

function Service:_setMatches(matches)
    self._state:Set("matches", matches)
end

function Service:_getOrCreateMatch(matchId)
    local matches = self:_matches()
    local session = matches[matchId]
    if session then
        return session
    end

    session = {
        matchId = matchId,
        aggression = self._config.DefaultAggression,
        level = classifyAggression(self._config.DefaultAggression, self._config.Thresholds),
        huntProbability = self._config.HuntProbabilityBase,
        investigationTime = 0,
        interactionCount = 0,
    }
    matches[matchId] = session
    self:_setMatches(matches)
    return session
end

function Service:StartMatch(matchId, payload)
    if not matchId then
        return nil, "invalid_match"
    end
    local session = self:_getOrCreateMatch(matchId)
    session.startedAt = payload and payload.now or os.clock()
    return session
end

function Service:EndMatch(matchId)
    local matches = self:_matches()
    matches[matchId] = nil
    self:_setMatches(matches)
end

function Service:IncreaseAggression(...)
    local matchId, amount, reason, metadata = ...
    if not matchId then
        return nil, "invalid_match"
    end

    local session = self:_getOrCreateMatch(matchId)
    local delta = math.max(0, tonumber(amount) or 0)
    if delta <= 0 then
        return session.aggression, nil
    end

    local previousAggression = session.aggression
    local previousLevel = session.level
    session.aggression = clamp(previousAggression + delta, self._config.MinAggression, self._config.MaxAggression)
    session.level = classifyAggression(session.aggression, self._config.Thresholds)

    self:_publish("AggressionIncreased", {
        matchId = matchId,
        amount = session.aggression - previousAggression,
        previousAggression = previousAggression,
        aggression = session.aggression,
        level = session.level,
        reason = reason or "unspecified",
        metadata = metadata,
    })

    if session.level ~= previousLevel then
        self:_publish("AggressionLevelChanged", {
            matchId = matchId,
            previousLevel = previousLevel,
            currentLevel = session.level,
            aggression = session.aggression,
        })
    end

    if session.aggression >= self._config.Thresholds.HuntReady then
        self:_publish("AggressionCritical", {
            matchId = matchId,
            aggression = session.aggression,
            level = session.level,
            reason = reason or "threshold",
        })
    end

    return session.aggression
end

function Service:GetAggressionLevel(...)
    local matchId = ...
    if not matchId then
        return nil
    end
    local session = self:_getOrCreateMatch(matchId)
    return {
        aggression = session.aggression,
        level = session.level,
        huntProbability = session.huntProbability,
    }
end

function Service:CheckHuntTrigger(...)
    local matchId, payload = ...
    if not matchId then
        return nil, "invalid_match"
    end

    local session = self:_getOrCreateMatch(matchId)
    local averageSanity = payload and payload.averageSanity
    local sanityFactor = 0
    if type(averageSanity) == "number" then
        sanityFactor = clamp((100 - averageSanity) / 100, 0, 1) * 0.25
    end

    local aggressionFactor = clamp(session.aggression / self._config.MaxAggression, 0, 1)
    local probability = self._config.HuntProbabilityBase
        + (aggressionFactor * (self._config.HuntProbabilityCap - self._config.HuntProbabilityBase))
        + sanityFactor
    probability = clamp(probability, 0, self._config.HuntProbabilityCap)
    session.huntProbability = probability

    self:_publish("HuntProbabilityIncreased", {
        matchId = matchId,
        aggression = session.aggression,
        level = session.level,
        probability = probability,
        averageSanity = averageSanity,
    })

    return probability >= 0.85, probability
end

function Service:RecordInvestigationTime(matchId, dt)
    local session = self:_getOrCreateMatch(matchId)
    session.investigationTime = (session.investigationTime or 0) + math.max(0, tonumber(dt) or 0)
    if session.investigationTime >= 60 then
        session.investigationTime = 0
        self:IncreaseAggression(matchId, 2.0, "long_investigation_time")
    end
end

function Service:RecordLongSilence(matchId, seconds)
    local silence = math.max(0, tonumber(seconds) or 0)
    if silence < 20 then
        return
    end
    self:IncreaseAggression(matchId, 1.2, "long_silence", {
        silenceSeconds = silence,
    })
end

return Service

