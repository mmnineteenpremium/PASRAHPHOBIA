local Service = {}
Service.__index = Service

local DEFAULT_PHASE_DURATIONS = {
    PreparationPhase = 15,
    InvestigationPhase = 180,
    HuntPhase = 45,
    EndgamePhase = 15,
}

local LEGACY_TO_PHASE = {
    Preparation = "PreparationPhase",
    Investigation = "InvestigationPhase",
    Hunt = "HuntPhase",
    Endgame = "EndgamePhase",
}

local NEXT_PHASE_BY_NAME = {
    PreparationPhase = "InvestigationPhase",
    InvestigationPhase = "HuntPhase",
    HuntPhase = "EndgamePhase",
}

local function normalizePhase(phaseName)
    return LEGACY_TO_PHASE[phaseName] or phaseName
end

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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    local config = self._deps.GamePhaseConfig or self._deps.GamePhaseSystemConfig or {}
    self._phaseDurations = config.phaseDurations or DEFAULT_PHASE_DURATIONS
    return self
end

function Service:Init()
    self._state:Set("currentPhaseByMatchId", {})
    self._state:Set("phaseTimerTokenByMatchId", {})
    self._state:Set("phaseStartedAtByMatchId", {})
    self._state:Set("activeMatches", {})
end

function Service:Start()
    -- Start runtime tasks or loops here.
end

function Service:Stop()
    self:_cancelAllTimers()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if not self._eventBus then
        return
    end
    self._eventBus:Publish(eventName, payload)
end

function Service:_phases()
    return self._state:Get("currentPhaseByMatchId") or {}
end

function Service:_setPhases(phases)
    self._state:Set("currentPhaseByMatchId", phases)
end

function Service:_tokens()
    return self._state:Get("phaseTimerTokenByMatchId") or {}
end

function Service:_setTokens(tokens)
    self._state:Set("phaseTimerTokenByMatchId", tokens)
end

function Service:_startedAtByMatchId()
    return self._state:Get("phaseStartedAtByMatchId") or {}
end

function Service:_setStartedAtByMatchId(startedAtByMatchId)
    self._state:Set("phaseStartedAtByMatchId", startedAtByMatchId)
end

function Service:_activeMatches()
    return self._state:Get("activeMatches") or {}
end

function Service:_setActiveMatches(activeMatches)
    self._state:Set("activeMatches", activeMatches)
end

function Service:_newTimerToken(matchId)
    local tokens = self:_tokens()
    local token = (tokens[matchId] or 0) + 1
    tokens[matchId] = token
    self:_setTokens(tokens)
    return token
end

function Service:_isTimerTokenCurrent(matchId, token)
    local tokens = self:_tokens()
    return tokens[matchId] == token
end

function Service:_cancelTimers(matchId)
    local tokens = self:_tokens()
    tokens[matchId] = nil
    self:_setTokens(tokens)
end

function Service:_cancelAllTimers()
    self:_setTokens({})
end

function Service:_schedulePhaseTimeout(matchId, phaseName)
    local durationSeconds = self._phaseDurations[phaseName]
    if type(durationSeconds) ~= "number" or durationSeconds < 0 then
        return
    end

    local token = self:_newTimerToken(matchId)
    task.delay(durationSeconds, function()
        if not self:_isTimerTokenCurrent(matchId, token) then
            return
        end
        self:_onPhaseTimerElapsed(matchId, phaseName)
    end)
end

function Service:_onPhaseTimerElapsed(matchId, phaseName)
    if phaseName == "EndgamePhase" then
        self:_publish("MatchPhaseTransitionRequested", {
            matchId = matchId,
            endMatch = true,
            reason = "endgame_timer_elapsed",
        })
        return
    end

    local nextPhase = NEXT_PHASE_BY_NAME[phaseName]
    if not nextPhase then
        return
    end
    self:RequestTransition(matchId, nextPhase, "phase_timer_elapsed")
end

function Service:MarkMatchStarted(matchId, payload)
    if not matchId then
        return false, "invalid_arguments"
    end

    local activeMatches = self:_activeMatches()
    activeMatches[matchId] = {
        startedAt = payload and payload.at or os.clock(),
    }
    self:_setActiveMatches(activeMatches)
    return true
end

function Service:StartPhase(matchId, phaseName, payload)
    if not matchId or not phaseName then
        return nil, "invalid_arguments"
    end

    local normalizedPhase = normalizePhase(phaseName)
    local phases = self:_phases()
    phases[matchId] = normalizedPhase
    self:_setPhases(phases)

    local startedAtByMatchId = self:_startedAtByMatchId()
    startedAtByMatchId[matchId] = payload and payload.at or os.clock()
    self:_setStartedAtByMatchId(startedAtByMatchId)

    self:_cancelTimers(matchId)
    self:_schedulePhaseTimeout(matchId, normalizedPhase)

    self:_publish("GamePhaseChanged", {
        matchId = matchId,
        phase = normalizedPhase,
        phaseName = normalizedPhase,
    })

    return normalizedPhase
end

function Service:GetCurrentPhase(matchId)
    local phases = self:_phases()
    return phases[matchId]
end

function Service:TransitionPhase(matchId, phaseName)
    return self:StartPhase(matchId, phaseName)
end

function Service:RequestTransition(matchId, nextPhase, reason)
    if not matchId or not nextPhase then
        return false, "invalid_arguments"
    end

    local normalizedPhase = normalizePhase(nextPhase)
    self:_publish("MatchPhaseTransitionRequested", {
        matchId = matchId,
        nextPhase = normalizedPhase,
        reason = reason,
    })

    return true
end

function Service:ClearMatch(matchId)
    if not matchId then
        return
    end

    self:_cancelTimers(matchId)

    local phases = self:_phases()
    phases[matchId] = nil
    self:_setPhases(phases)

    local startedAtByMatchId = self:_startedAtByMatchId()
    startedAtByMatchId[matchId] = nil
    self:_setStartedAtByMatchId(startedAtByMatchId)

    local activeMatches = self:_activeMatches()
    activeMatches[matchId] = nil
    self:_setActiveMatches(activeMatches)
end

return Service

