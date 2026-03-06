local Behaviors = require(script.Parent.Behaviors.init)

local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    UpdateIntervalSeconds = 1.5,
    MinDecisionCooldownSeconds = 4.0,
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

local function resolveAggressionService(deps)
    local system = deps and deps.AggressionSystem
    if type(system) ~= "table" then
        return nil
    end
    if type(system.IncreaseAggression) == "function" then
        return system
    end
    if type(system.Service) == "table" and type(system.Service.IncreaseAggression) == "function" then
        return system.Service
    end
    return nil
end

local function resolveGhostService(deps)
    local system = deps and deps.GhostSystem
    if type(system) ~= "table" then
        return nil
    end
    if type(system.ApplyDirectorEvent) == "function" then
        return system
    end
    if type(system.Service) == "table" and type(system.Service.ApplyDirectorEvent) == "function" then
        return system.Service
    end
    return nil
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
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.GhostDirectorConfig)
    self._eventBus = resolveEventBus(self._deps)
    self._aggression = resolveAggressionService(self._deps)
    self._ghost = resolveGhostService(self._deps)
    self._loopToken = 0
    self._loopRunning = false
    self._loopThread = nil
    return self
end

function Service:Init()
    self._state:Set("matches", {})
end

function Service:Start()
    self:_startLoop()
end

function Service:Stop()
    self:_stopLoop()
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

function Service:_getOrCreateMatch(matchId, now)
    local matches = self:_matches()
    local session = matches[matchId]
    if session then
        return session
    end

    session = {
        matchId = matchId,
        fearLevel = 0,
        averageSanity = 100,
        tension = 0,
        aggression = 0,
        huntActive = false,
        currentBehavior = nil,
        lastDecisionAt = now or os.clock(),
        pending = false,
    }
    matches[matchId] = session
    self:_setMatches(matches)
    return session
end

function Service:StartMatch(matchId, payload)
    if not matchId then
        return nil
    end
    local session = self:_getOrCreateMatch(matchId, payload and payload.now)
    session.pending = true
    return session
end

function Service:EndMatch(matchId)
    local matches = self:_matches()
    matches[matchId] = nil
    self:_setMatches(matches)
end

function Service:OnFearLevelChanged(matchId, payload)
    local session = self:_getOrCreateMatch(matchId, payload and payload.now)
    if type(payload and payload.fearLevel) == "number" then
        session.fearLevel = payload.fearLevel
    end
    session.pending = true
end

function Service:OnSanityChanged(matchId, payload)
    local session = self:_getOrCreateMatch(matchId, payload and payload.now)
    local sanity = payload and (payload.averageSanity or payload.newSanity)
    if type(sanity) == "number" then
        session.averageSanity = sanity
    end
    session.pending = true
end

function Service:OnDirectorTensionChanged(matchId, payload)
    local session = self:_getOrCreateMatch(matchId, payload and payload.now)
    if type(payload and payload.tension) == "number" then
        session.tension = payload.tension
    end
    session.pending = true
end

function Service:OnAggressionIncreased(matchId, payload)
    local session = self:_getOrCreateMatch(matchId, payload and payload.now)
    if type(payload and payload.aggression) == "number" then
        session.aggression = payload.aggression
    end
    session.pending = true
end

function Service:OnHuntStarted(matchId)
    local session = self:_getOrCreateMatch(matchId, os.clock())
    session.huntActive = true
end

function Service:OnHuntEnded(matchId)
    local session = self:_getOrCreateMatch(matchId, os.clock())
    session.huntActive = false
    session.pending = true
end

function Service:_applyAction(session, action, now)
    local matchId = session.matchId
    if action.type == "force_roam" then
        self:_publish("ForceRoam", action.payload)
        if self._ghost and type(self._ghost.ApplyDirectorEvent) == "function" then
            self._ghost:ApplyDirectorEvent(matchId, "TensionHigh", {
                now = now,
                duration = action.payload.duration or 6,
                aggressionBoost = 2,
            })
        end
    elseif action.type == "force_manifest" then
        self:_publish("ForceManifest", action.payload)
        if self._ghost and type(self._ghost.ApplyDirectorEvent) == "function" then
            self._ghost:ApplyDirectorEvent(matchId, "ForceManifest", action.payload)
        end
    elseif action.type == "force_hunt" then
        self:_publish("ForceHunt", action.payload)
    elseif action.type == "increase_aggression" then
        if self._aggression and type(self._aggression.IncreaseAggression) == "function" then
            self._aggression:IncreaseAggression(matchId, action.payload.amount, action.payload.reason, {
                source = "GhostDirector",
            })
        else
            self:_publish("IncreaseAggression", action.payload)
        end
    end

    self:_publish("GhostDirectorActionIssued", {
        matchId = matchId,
        actionType = action.type,
        behavior = session.currentBehavior,
        now = now,
    })
end

function Service:_selectBehavior(session)
    local context = {
        matchId = session.matchId,
        fearLevel = session.fearLevel,
        averageSanity = session.averageSanity,
        tension = session.tension,
        aggression = session.aggression,
        huntActive = session.huntActive,
    }

    local bestBehavior = nil
    local bestScore = 0
    for _, behavior in ipairs(Behaviors) do
        local score = 0
        if type(behavior.Score) == "function" then
            score = behavior.Score(context) or 0
        end
        if score > bestScore then
            bestScore = score
            bestBehavior = behavior
        end
    end

    if not bestBehavior then
        return nil, context
    end
    return bestBehavior, context
end

function Service:_evaluateSession(session, now)
    if (now - (session.lastDecisionAt or 0)) < self._config.MinDecisionCooldownSeconds then
        session.pending = false
        return
    end

    if self._aggression and type(self._aggression.GetAggressionLevel) == "function" then
        local info = self._aggression:GetAggressionLevel(session.matchId)
        if type(info) == "table" and type(info.aggression) == "number" then
            session.aggression = info.aggression
        end
    end

    local behavior, context = self:_selectBehavior(session)
    session.pending = false
    if not behavior then
        return
    end

    local previous = session.currentBehavior
    session.currentBehavior = behavior.Name or "UnknownBehavior"
    session.lastDecisionAt = now

    if previous ~= session.currentBehavior then
        self:_publish("GhostDirectorBehaviorSelected", {
            matchId = session.matchId,
            behavior = session.currentBehavior,
            previousBehavior = previous,
            scoreContext = {
                fearLevel = context.fearLevel,
                averageSanity = context.averageSanity,
                tension = context.tension,
                aggression = context.aggression,
            },
            now = now,
        })
    end

    if type(behavior.BuildActions) == "function" then
        for _, action in ipairs(behavior.BuildActions(context, now) or {}) do
            self:_applyAction(session, action, now)
        end
    end
end

function Service:_flush(now)
    local matches = self:_matches()
    for _, session in pairs(matches) do
        if session.pending then
            self:_evaluateSession(session, now)
        end
    end
end

function Service:_startLoop()
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

function Service:_stopLoop()
    self._loopRunning = false
    self._loopToken += 1
    if self._loopThread then
        task.cancel(self._loopThread)
        self._loopThread = nil
    end
end

return Service
