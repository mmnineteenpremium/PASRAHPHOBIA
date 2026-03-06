local EvidenceRandomizer = {}
EvidenceRandomizer.__index = EvidenceRandomizer

local DEFAULT_CONFIG = {
    MinSpawnIntervalSeconds = 2.0,
    BaseDelayChance = 0.2,
    MinDelaySeconds = 0.4,
    MaxDelaySeconds = 2.2,
    BaseFakeChance = 0.04,
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

function EvidenceRandomizer.new(deps)
    local self = setmetatable({}, EvidenceRandomizer)
    self._deps = deps or {}
    self._rng = self._deps.Random or Random.new()
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.EvidenceRandomizerConfig)
    self._matches = {}
    return self
end

function EvidenceRandomizer:Reset()
    self._matches = {}
end

function EvidenceRandomizer:_getMatch(matchId)
    return self._matches[matchId]
end

function EvidenceRandomizer:_ensureMatch(matchId)
    local state = self._matches[matchId]
    if state then
        return state
    end
    state = {
        nextAllowedAt = 0,
        tension = 0,
        personality = {
            name = "Unknown",
            eventFrequency = 1.0,
            fakeEvidenceChance = 0.0,
        },
        spectatorFakeBias = 0.0,
    }
    self._matches[matchId] = state
    return state
end

function EvidenceRandomizer:StartMatch(matchId)
    self:_ensureMatch(matchId)
end

function EvidenceRandomizer:EndMatch(matchId)
    self._matches[matchId] = nil
end

function EvidenceRandomizer:UpdateTension(matchId, tension)
    local state = self:_getMatch(matchId)
    if not state then
        return
    end
    if type(tension) == "number" then
        state.tension = clamp(tension, 0, 100)
    end
end

function EvidenceRandomizer:UpdateGhostPersonality(matchId, personality)
    local state = self:_getMatch(matchId)
    if not state then
        return
    end
    if type(personality) ~= "table" then
        return
    end
    state.personality = {
        name = personality.name or personality.personality or "Unknown",
        eventFrequency = clamp(tonumber(personality.eventFrequency) or 1.0, 0.3, 2.0),
        fakeEvidenceChance = clamp(tonumber(personality.fakeEvidenceChance) or 0.0, 0, 0.95),
    }
end

function EvidenceRandomizer:OnSpectatorVisionUpdated(matchId, payload)
    local state = self:_getMatch(matchId)
    if not state then
        return
    end
    local outcome = payload and payload.vision and payload.vision.outcome
    local bias = state.spectatorFakeBias or 0
    if outcome == "fake" or outcome == "uncertain" then
        bias = clamp(bias + 0.1, 0, 0.35)
    else
        bias = clamp(bias - 0.04, 0, 0.35)
    end
    state.spectatorFakeBias = bias
end

function EvidenceRandomizer:_computeDelayChance(state)
    local tensionFactor = (state.tension or 0) / 100
    local personalityFreq = state.personality and state.personality.eventFrequency or 1.0
    local chance = self._config.BaseDelayChance + (tensionFactor * 0.2) + ((personalityFreq - 1.0) * 0.08)
    return clamp(chance, 0.05, 0.8)
end

function EvidenceRandomizer:_computeFakeChance(state)
    local tensionFactor = (state.tension or 0) / 100
    local personalityFake = state.personality and state.personality.fakeEvidenceChance or 0
    local spectatorBias = state.spectatorFakeBias or 0
    local chance = self._config.BaseFakeChance + personalityFake + (tensionFactor * 0.08) + spectatorBias
    return clamp(chance, 0.01, 0.95)
end

function EvidenceRandomizer:Spawn(matchId, payload, spawnFn, publishFn)
    local state = self:_ensureMatch(matchId)
    local now = payload and payload.now or os.clock()

    if now < (state.nextAllowedAt or 0) then
        return nil, "throttled"
    end
    state.nextAllowedAt = now + self._config.MinSpawnIntervalSeconds

    local fakeChance = self:_computeFakeChance(state)
    if self._rng:NextNumber() <= fakeChance then
        local fakePayload = {
            matchId = matchId,
            evidenceType = payload and payload.evidenceType or "FakeEvidence",
            roomId = payload and payload.roomId,
            source = "EvidenceRandomizer",
            now = now,
            isFake = true,
        }
        if publishFn then
            publishFn("GhostFakeEvidenceSpawned", fakePayload)
            publishFn("EvidenceSpawned", {
                matchId = matchId,
                evidenceType = fakePayload.evidenceType,
                location = fakePayload.roomId,
                trigger = payload and payload.trigger or "randomizer_fake",
                source = "EvidenceRandomizer",
                isFake = true,
            })
        end
        return fakePayload, "fake_spawned"
    end

    local delayChance = self:_computeDelayChance(state)
    if self._rng:NextNumber() <= delayChance then
        local delaySec = self._rng:NextNumber(self._config.MinDelaySeconds, self._config.MaxDelaySeconds)
        if publishFn then
            publishFn("EvidenceSpawnDelayed", {
                matchId = matchId,
                delaySec = delaySec,
                source = "EvidenceRandomizer",
                now = now,
            })
        end
        task.delay(delaySec, function()
            if not self:_getMatch(matchId) then
                return
            end
            local delayedPayload = {}
            for key, value in pairs(payload or {}) do
                delayedPayload[key] = value
            end
            delayedPayload.now = os.clock()
            if spawnFn then
                spawnFn(delayedPayload)
            end
        end)
        return nil, "delayed"
    end

    return spawnFn and spawnFn(payload or {}) or nil
end

return EvidenceRandomizer
