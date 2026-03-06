local Personalities = require(script.Parent.Personalities.init)
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    UpdateIntervalSeconds = 2.0,
    MinEventCooldownSeconds = 6.0,
    MaxEventCooldownSeconds = 18.0,
}

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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
    local system = Services.Get(deps, "AggressionSystem")
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

local function resolveEvidenceService(deps)
    local system = Services.Get(deps, "EvidenceSystem")
    if type(system) ~= "table" then
        return nil
    end
    if type(system.SpawnEvidence) == "function" then
        return system
    end
    if type(system.Service) == "table" and type(system.Service.SpawnEvidence) == "function" then
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
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.GhostPersonalityConfig)
    self._eventBus = resolveEventBus(self._deps)
    self._aggression = resolveAggressionService(self._deps)
    self._evidence = resolveEvidenceService(self._deps)
    self._rng = self._deps.Random or Random.new()
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

function Service:_personalityNames()
    local out = {}
    for name in pairs(Personalities) do
        table.insert(out, name)
    end
    table.sort(out)
    return out
end

function Service:_resolvePersonality(personalityName)
    if type(personalityName) == "string" and Personalities[personalityName] then
        return Personalities[personalityName]
    end
    local names = self:_personalityNames()
    if #names == 0 then
        return {
            name = "Unknown",
            huntThreshold = 80,
            eventFrequency = 0.5,
            fakeEvidenceChance = 0.0,
        }
    end
    local pick = names[self._rng:NextInteger(1, #names)]
    return Personalities[pick]
end

function Service:_getOrCreateMatch(matchId, now)
    local matches = self:_matches()
    local session = matches[matchId]
    if session then
        return session
    end

    session = {
        matchId = matchId,
        personality = nil,
        tension = 0,
        huntActive = false,
        lastEventAt = now or os.clock(),
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
    local personality = self:_resolvePersonality(payload and payload.personalityType)
    session.personality = personality
    self:_publish("GhostPersonalityAssigned", {
        matchId = matchId,
        personality = personality.name,
        huntThreshold = personality.huntThreshold,
        eventFrequency = personality.eventFrequency,
        fakeEvidenceChance = personality.fakeEvidenceChance,
    })
    return session
end

function Service:OnGhostSpawned(matchId, payload)
    local session = self:_getOrCreateMatch(matchId, payload and payload.now)
    local personalityName = payload and (payload.personalityType or (payload.personality and payload.personality.type))
    local personality = self:_resolvePersonality(personalityName)
    session.personality = personality
    session.pending = true
    self:_publish("GhostPersonalityAssigned", {
        matchId = matchId,
        personality = personality.name,
        huntThreshold = personality.huntThreshold,
        eventFrequency = personality.eventFrequency,
        fakeEvidenceChance = personality.fakeEvidenceChance,
    })
end

function Service:EndMatch(matchId)
    local matches = self:_matches()
    matches[matchId] = nil
    self:_setMatches(matches)
end

function Service:OnDirectorTensionChanged(matchId, payload)
    local session = self:_getOrCreateMatch(matchId, payload and payload.now)
    local tension = payload and payload.tension
    if type(tension) == "number" then
        session.tension = clamp(tension, 0, 100)
    end
    session.pending = true
end

function Service:OnEvidenceCollected(matchId)
    local session = self:_getOrCreateMatch(matchId, os.clock())
    session.pending = true
end

function Service:OnHuntStarted(matchId)
    local session = self:_getOrCreateMatch(matchId, os.clock())
    session.huntActive = true
end

function Service:OnHuntEnded(matchId)
    local session = self:_getOrCreateMatch(matchId, os.clock())
    session.huntActive = false
end

function Service:_eventCooldown(personality)
    local frequency = clamp(personality.eventFrequency or 1, 0.2, 2.0)
    local base = 12 / frequency
    return clamp(base, self._config.MinEventCooldownSeconds, self._config.MaxEventCooldownSeconds)
end

function Service:_raiseAggression(matchId, amount, reason, metadata)
    if self._aggression and type(self._aggression.IncreaseAggression) == "function" then
        self._aggression:IncreaseAggression(matchId, amount, reason, metadata)
    else
        self:_publish("IncreaseAggression", {
            matchId = matchId,
            amount = amount,
            reason = reason,
            metadata = metadata,
            source = "GhostPersonalitySystem",
        })
    end
end

function Service:_triggerPersonalityEvent(session, now)
    local personality = session.personality
    if not personality then
        return
    end

    local matchId = session.matchId
    local fakeRoll = self._rng:NextNumber()
    local shouldFakeEvidence = fakeRoll <= (personality.fakeEvidenceChance or 0)

    if personality.name == "Demon" then
        if session.tension >= personality.huntThreshold and not session.huntActive then
            self:_publish("ForceHunt", {
                matchId = matchId,
                reason = "personality_demon_hunt",
                now = now,
            })
        else
            self:_publish("ForceManifest", {
                matchId = matchId,
                reason = "personality_demon_pressure",
                duration = 6,
                now = now,
            })
        end
        self:_raiseAggression(matchId, 1.8, "personality_demon", {
            tension = session.tension,
        })
    elseif personality.name == "Shade" then
        self:_publish("DirectorEventTriggered", {
            matchId = matchId,
            eventType = "ShadePresence",
            reason = "personality_shade",
            tension = session.tension,
        })
        if session.tension >= personality.huntThreshold then
            self:_raiseAggression(matchId, 0.7, "personality_shade_threshold", {
                tension = session.tension,
            })
        end
    elseif personality.name == "Poltergeist" then
        self:_publish("EnvironmentEventTriggered", {
            matchId = matchId,
            eventType = "ObjectMovement",
            reason = "personality_poltergeist",
            now = now,
        })
        self:_publish("GhostInteraction", {
            matchId = matchId,
            interactionType = "PoltergeistBurst",
            intensity = 2,
            now = now,
        })
        self:_raiseAggression(matchId, 1.0, "personality_poltergeist", nil)
    elseif personality.name == "Trickster" then
        if shouldFakeEvidence then
            self:_publish("GhostFakeEvidenceSpawned", {
                matchId = matchId,
                evidenceType = "FakeEvidence",
                reason = "personality_trickster",
                now = now,
            })
        elseif self._evidence and type(self._evidence.SpawnEvidence) == "function" then
            self._evidence:SpawnEvidence(matchId, {
                source = "personality_trickster",
                trigger = "personality",
                activity = 2,
                now = now,
            })
        else
            self:_publish("EvidenceSpawned", {
                matchId = matchId,
                source = "personality_trickster",
                now = now,
            })
        end
        self:_publish("DirectorEventTriggered", {
            matchId = matchId,
            eventType = "TricksterDeception",
            reason = "personality_trickster",
            tension = session.tension,
        })
    end

    self:_publish("GhostPersonalityEventTriggered", {
        matchId = matchId,
        personality = personality.name,
        tension = session.tension,
        now = now,
    })
end

function Service:_evaluateSession(session, now)
    if not session.personality then
        session.personality = self:_resolvePersonality(nil)
    end

    local cooldown = self:_eventCooldown(session.personality)
    if (now - (session.lastEventAt or 0)) < cooldown then
        session.pending = false
        return
    end

    local frequencyChance = clamp((session.personality.eventFrequency or 1) * 0.22, 0.05, 0.85)
    if self._rng:NextNumber() > frequencyChance then
        session.pending = false
        return
    end

    self:_triggerPersonalityEvent(session, now)
    session.lastEventAt = now
    session.pending = false
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
