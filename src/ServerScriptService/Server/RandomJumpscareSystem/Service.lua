local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    LoopIntervalSeconds = 3,
    MinCooldownSeconds = 20,
    MaxPerWindow = 4,
    WindowSeconds = 120,
    AtmosphericMinInterval = 25,
    AtmosphericMaxInterval = 55,
    RandomAtmosphericChance = 0.22,
    LongInvestigationThresholdSeconds = 300,
}

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
    local out = {}
    for key, value in pairs(base) do
        out[key] = value
    end
    for key, value in pairs(override or {}) do
        out[key] = value
    end
    return out
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

local function isInvestigationPhase(payload)
    local phaseName = payload and (payload.phaseName or payload.phase)
    if type(phaseName) ~= "string" then
        return false
    end
    return phaseName == "Investigation" or phaseName == "InvestigationPhase"
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._rng = self._deps.Random or Random.new()
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.RandomJumpscareConfig)
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._state:Set("matches", {})
end

function Service:Start()
    self:_startLoop()
end

function Service:Stop()
    self:_stopLoop()
    self._state:Clear()
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

function Service:_nextAtmosphericAt(now)
    local minDelay = self._config.AtmosphericMinInterval
    local maxDelay = math.max(minDelay, self._config.AtmosphericMaxInterval)
    return now + self._rng:NextNumber(minDelay, maxDelay)
end

function Service:_registerMatch(matchId, now)
    local matches = self:_matches()
    matches[matchId] = {
        matchId = matchId,
        startedAt = now,
        lastJumpscareAt = 0,
        recentTriggers = {},
        nextAtmosphericAt = self:_nextAtmosphericAt(now),
    }
    self:_setMatches(matches)
end

function Service:_removeMatch(matchId)
    local matches = self:_matches()
    matches[matchId] = nil
    self:_setMatches(matches)
end

function Service:_cleanupTriggerWindow(session, now)
    local keepFrom = now - self._config.WindowSeconds
    local kept = {}
    for _, entry in ipairs(session.recentTriggers or {}) do
        if entry >= keepFrom then
            table.insert(kept, entry)
        end
    end
    session.recentTriggers = kept
end

function Service:_canTrigger(session, now)
    if (now - (session.lastJumpscareAt or 0)) < self._config.MinCooldownSeconds then
        return false
    end

    self:_cleanupTriggerWindow(session, now)
    if #(session.recentTriggers or {}) >= self._config.MaxPerWindow then
        return false
    end

    return true
end

function Service:_chooseEffects()
    local roll = self._rng:NextNumber()
    if roll < 0.34 then
        return {
            ghostFlash = true,
            audioSpike = true,
            cameraShake = true,
            environmentalDisturbance = false,
            profile = "GhostFlash",
        }
    elseif roll < 0.67 then
        return {
            ghostFlash = false,
            audioSpike = true,
            cameraShake = true,
            environmentalDisturbance = true,
            profile = "AudioDistortion",
        }
    end

    return {
        ghostFlash = true,
        audioSpike = false,
        cameraShake = true,
        environmentalDisturbance = true,
        profile = "EnvironmentalShock",
    }
end

function Service:_tryTrigger(matchId, triggerType, chance, payload)
    local matches = self:_matches()
    local session = matches[matchId]
    if not session then
        return false
    end

    local now = payload and payload.now or os.clock()
    if not self:_canTrigger(session, now) then
        return false
    end

    local clampedChance = clamp(chance or 0, 0, 1)
    if self._rng:NextNumber() > clampedChance then
        return false
    end

    local effects = self:_chooseEffects()
    session.lastJumpscareAt = now
    table.insert(session.recentTriggers, now)

    self:_publish("JumpscareTriggered", {
        matchId = matchId,
        triggerType = triggerType,
        chance = clampedChance,
        ghostFlash = effects.ghostFlash,
        audioSpike = effects.audioSpike,
        cameraShake = effects.cameraShake,
        environmentalDisturbance = effects.environmentalDisturbance,
        effectProfile = effects.profile,
        source = "RandomJumpscareSystem",
        now = now,
    })

    return true
end

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    local now = payload and payload.now or os.clock()
    self:_registerMatch(matchId, now)
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self:_removeMatch(matchId)
end

function Service:OnGhostInteraction(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    local intensity = tonumber(payload.intensity) or 1
    local proximity = tonumber(payload.ghostProximity or payload.distanceToGhost)
    local chance = 0.14 + clamp((intensity - 1) * 0.08, 0, 0.24)
    if type(proximity) == "number" and proximity <= 16 then
        chance += 0.14
    end

    self:_tryTrigger(matchId, "GhostProximity", chance, payload)
end

function Service:OnGhostStateChanged(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    if payload.currentState == "Manifest" then
        self:_tryTrigger(matchId, "GhostManifest", 0.46, payload)
    elseif payload.currentState == "Hunt" then
        self:_tryTrigger(matchId, "HuntPressure", 0.28, payload)
    end
end

function Service:OnPlayerSanityChanged(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    local sanity = tonumber(payload.newSanity)
    if not sanity then
        return
    end

    if sanity <= 25 then
        self:_tryTrigger(matchId, "DarknessExposure", 0.34, payload)
    elseif sanity <= 40 then
        self:_tryTrigger(matchId, "DarknessExposure", 0.2, payload)
    end
end

function Service:OnPhaseStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId or not isInvestigationPhase(payload) then
        return
    end

    local session = self:_matches()[matchId]
    if not session then
        return
    end

    local now = payload and payload.now or os.clock()
    local elapsed = now - (session.startedAt or now)
    if elapsed < self._config.LongInvestigationThresholdSeconds then
        return
    end

    self:_tryTrigger(matchId, "LongInvestigation", 0.24, payload)
end

function Service:_atmosphericTick(now)
    for matchId, session in pairs(self:_matches()) do
        if now >= (session.nextAtmosphericAt or 0) then
            self:_tryTrigger(matchId, "RandomAtmospheric", self._config.RandomAtmosphericChance, {
                matchId = matchId,
                now = now,
            })
            session.nextAtmosphericAt = self:_nextAtmosphericAt(now)
        end
    end
end

function Service:_tick()
    self:_atmosphericTick(os.clock())
end

function Service:_startLoop()
    if self._state:Get("running") == true then
        return
    end

    self._state:Set("running", true)
    local loopToken = (self._state:Get("loopToken") or 0) + 1
    self._state:Set("loopToken", loopToken)

    task.spawn(function()
        while self._state:Get("running") == true and self._state:Get("loopToken") == loopToken do
            self:_tick()
            task.wait(self._config.LoopIntervalSeconds)
        end
    end)
end

function Service:_stopLoop()
    self._state:Set("running", false)
    self._state:Set("loopToken", (self._state:Get("loopToken") or 0) + 1)
end

return Service
