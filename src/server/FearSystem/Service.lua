local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    MinFear = 0,
    MaxFear = 100,
    UpdateIntervalSeconds = 1.0,
    EmitDeltaThreshold = 0.5,
    BaseDecayPerSecond = 1.5,
    SanityWeight = 26,
    TensionWeight = 18,
    DisturbanceWeight = 14,
    GhostPressureWeight = 22,
    HuntBonus = 20,
}

local function resolveEventBus(deps)
    local eventBus = deps and deps.EventBus
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
        merged[key] = value
    end
    for key, value in pairs(override or {}) do
        merged[key] = value
    end
    return merged
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.FearConfig)
    self._loopToken = 0
    self._loopThread = nil
    self._loopRunning = false
    return self
end

function Service:Init()
    self._state:Set("matches", {})
    self._state:Set("globalFearLevel", 0)
end

function Service:Start()
    self:_startUpdateLoop()
end

function Service:Stop()
    self:_stopUpdateLoop()
    self._state:Set("matches", {})
    self._state:Set("globalFearLevel", 0)
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

function Service:_getOrCreateMatch(matchId, now)
    local matches = self:_matches()
    local match = matches[matchId]
    if match then
        return match
    end

    local currentTime = now or os.clock()
    match = {
        matchId = matchId,
        fearLevel = 0,
        lastEmittedFearLevel = 0,
        averageSanity = 100,
        directorTension = 0,
        disturbance = 0,
        ghostPressure = 0,
        huntActive = false,
        lastUpdatedAt = currentTime,
        pending = false,
    }
    matches[matchId] = match
    self:_setMatches(matches)
    return match
end

function Service:StartMatch(matchId, payload)
    if not matchId then
        return nil
    end
    return self:_getOrCreateMatch(matchId, payload and payload.now)
end

function Service:EndMatch(matchId)
    local matches = self:_matches()
    matches[matchId] = nil
    self:_setMatches(matches)
    self:_recomputeGlobalFear(os.clock())
end

function Service:_markPending(matchId)
    local match = self:_getOrCreateMatch(matchId, os.clock())
    match.pending = true
end

function Service:OnSanityChanged(matchId, payload)
    local match = self:_getOrCreateMatch(matchId, payload and payload.now)
    local sanity = payload and (payload.averageSanity or payload.newSanity)
    if type(sanity) == "number" then
        match.averageSanity = clamp(sanity, 0, 100)
    end
    self:_markPending(matchId)
end

function Service:OnDirectorTensionChanged(matchId, payload)
    local match = self:_getOrCreateMatch(matchId, payload and payload.now)
    local tension = payload and payload.tension
    if type(tension) == "number" then
        match.directorTension = clamp(tension, 0, 100)
    end
    self:_markPending(matchId)
end

function Service:OnGhostInteraction(matchId, payload)
    local match = self:_getOrCreateMatch(matchId, payload and payload.now)
    local intensity = payload and payload.intensity
    if type(intensity) ~= "number" then
        intensity = 1
    end
    match.ghostPressure = clamp(intensity / 3, 0, 1)
    match.disturbance = clamp(math.max(match.disturbance, intensity / 3), 0, 1)
    self:_markPending(matchId)
end

function Service:OnDirectorEvent(matchId, payload)
    local match = self:_getOrCreateMatch(matchId, payload and payload.now)
    local eventType = payload and payload.eventType
    if eventType == "Hunt" or eventType == "Manifestation" then
        match.disturbance = clamp(match.disturbance + 0.3, 0, 1)
    else
        match.disturbance = clamp(match.disturbance + 0.15, 0, 1)
    end
    self:_markPending(matchId)
end

function Service:OnHuntStarted(matchId)
    local match = self:_getOrCreateMatch(matchId, os.clock())
    match.huntActive = true
    self:_markPending(matchId)
end

function Service:OnHuntEnded(matchId)
    local match = self:_getOrCreateMatch(matchId, os.clock())
    match.huntActive = false
    match.ghostPressure = clamp(match.ghostPressure * 0.5, 0, 1)
    self:_markPending(matchId)
end

function Service:_evaluateMatch(match, now)
    local dt = math.max(0.1, now - (match.lastUpdatedAt or now))
    match.lastUpdatedAt = now

    local sanityFactor = 1 - (match.averageSanity / 100)
    local tensionFactor = match.directorTension / 100
    local gainPerSecond = (sanityFactor * self._config.SanityWeight)
        + (tensionFactor * self._config.TensionWeight)
        + (match.disturbance * self._config.DisturbanceWeight)
        + (match.ghostPressure * self._config.GhostPressureWeight)

    if match.huntActive then
        gainPerSecond += self._config.HuntBonus
    end

    local oldFear = match.fearLevel
    local nextFear = oldFear + ((gainPerSecond - self._config.BaseDecayPerSecond) * dt)
    match.fearLevel = clamp(nextFear, self._config.MinFear, self._config.MaxFear)

    match.disturbance = clamp(match.disturbance - (0.35 * dt), 0, 1)
    match.ghostPressure = clamp(match.ghostPressure - (0.45 * dt), 0, 1)
    match.pending = false

    local delta = math.abs(match.fearLevel - (match.lastEmittedFearLevel or 0))
    if delta >= self._config.EmitDeltaThreshold then
        match.lastEmittedFearLevel = match.fearLevel
        self:_publish("FearLevelChanged", {
            matchId = match.matchId,
            fearLevel = match.fearLevel,
            oldFearLevel = oldFear,
            averageSanity = match.averageSanity,
            directorTension = match.directorTension,
            huntActive = match.huntActive,
            now = now,
        })
    end
end

function Service:_recomputeGlobalFear(now)
    local matches = self:_matches()
    local total = 0
    local count = 0
    for _, match in pairs(matches) do
        total += (match.fearLevel or 0)
        count += 1
    end
    local newGlobal = count > 0 and (total / count) or 0
    local currentGlobal = self._state:Get("globalFearLevel") or 0
    if math.abs(newGlobal - currentGlobal) >= self._config.EmitDeltaThreshold then
        self._state:Set("globalFearLevel", newGlobal)
        self:_publish("FearLevelChanged", {
            matchId = nil,
            fearLevel = newGlobal,
            oldFearLevel = currentGlobal,
            global = true,
            now = now,
        })
    end
end

function Service:_flush(now)
    local matches = self:_matches()
    local changed = false
    for _, match in pairs(matches) do
        if match.pending then
            self:_evaluateMatch(match, now)
            changed = true
        end
    end
    if changed then
        self:_recomputeGlobalFear(now)
    end
end

function Service:_startUpdateLoop()
    if self._loopRunning then
        return
    end
    self._loopRunning = true
    self._loopToken += 1
    local token = self._loopToken
    self._loopThread = task.spawn(function()
        while self._loopRunning and token == self._loopToken do
            self:_flush(os.clock())
            task.wait(self._config.UpdateIntervalSeconds)
        end
    end)
end

function Service:_stopUpdateLoop()
    self._loopRunning = false
    self._loopToken += 1
    if self._loopThread then
        task.cancel(self._loopThread)
        self._loopThread = nil
    end
end

function Service:GetFearLevel(matchId)
    local match = self:_matches()[matchId]
    return match and match.fearLevel or 0
end

function Service:GetGlobalFearLevel()
    return self._state:Get("globalFearLevel") or 0
end

return Service
