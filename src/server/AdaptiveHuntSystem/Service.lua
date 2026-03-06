local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function appendHistory(history, entry)
    table.insert(history, entry)
    if #history > 250 then
        table.remove(history, 1)
    end
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    self._rng = self._deps.Random or Random.new()
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        AggressionSystem = Services.Get(self._deps, "AggressionSystem"),
        SanitySystem = Services.Get(self._deps, "SanitySystem"),
        HorrorDirector = Services.Get(self._deps, "HorrorDirector"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        GhostPersonalitySystem = Services.Get(self._deps, "GhostPersonalitySystem"),
    }
end

function Service:Init()
    self._state:Set("huntIntensity", self._state:Get("huntIntensity") or {})
    self._state:Set("huntCooldowns", self._state:Get("huntCooldowns") or {})
    self._state:Set("huntHistory", self._state:Get("huntHistory") or {})
end

function Service:Start()
    -- Event-driven system.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_calculateIntensity(context)
    local averageSanity = clamp(tonumber(context.averageSanity) or 100, 0, 100)
    local aggression = clamp(tonumber(context.aggression) or 0, 0, 100)
    local playerNoise = clamp(tonumber(context.playerNoise) or 0, 0, 100)

    local personalityMultiplier = tonumber(context.personalityHuntMultiplier) or 1
    local base = ((100 - averageSanity) * 0.45) + (aggression * 0.40) + (playerNoise * 0.15)
    return clamp(base * personalityMultiplier, 0, 100)
end

function Service:_calculateDuration(intensity)
    return clamp(20 + (intensity * 0.25), 18, 50)
end

function Service:_calculateCooldown(intensity)
    return clamp(65 - (intensity * 0.4), 20, 75)
end

function Service:_canTriggerHunt(matchId)
    local cooldowns = self._state:Get("huntCooldowns") or {}
    return (cooldowns[matchId] or 0) <= os.clock()
end

function Service:TriggerAdaptiveHunt(matchId, ghostId, context)
    if type(matchId) ~= "string" or matchId == "" then
        return nil, "invalid_match_id"
    end
    if not self:_canTriggerHunt(matchId) then
        return nil, "hunt_cooldown_active"
    end

    context = context or {}
    local intensity = self:_calculateIntensity(context)
    local duration = self:_calculateDuration(intensity)
    local cooldownSeconds = self:_calculateCooldown(intensity)

    local huntIntensity = self._state:Get("huntIntensity") or {}
    local previousIntensity = huntIntensity[matchId] or 0
    huntIntensity[matchId] = intensity
    self._state:Set("huntIntensity", huntIntensity)

    local cooldowns = self._state:Get("huntCooldowns") or {}
    cooldowns[matchId] = os.clock() + cooldownSeconds
    self._state:Set("huntCooldowns", cooldowns)

    local history = self._state:Get("huntHistory") or {}
    appendHistory(history, {
        at = os.time(),
        matchId = matchId,
        ghostId = ghostId,
        intensity = intensity,
        duration = duration,
        cooldownSeconds = cooldownSeconds,
    })
    self._state:Set("huntHistory", history)

    local payload = {
        matchId = matchId,
        ghostId = ghostId,
        intensity = intensity,
        duration = duration,
        cooldownSeconds = cooldownSeconds,
        previousIntensity = previousIntensity,
        context = context,
    }

    self:_publish("AdaptiveHuntTriggered", payload)
    self:_publish("HuntIntensityChanged", payload)

    return payload
end

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._state:ResetForMatch(matchId)
end

function Service:OnHuntTriggered(payload)
    if type(payload) ~= "table" then
        return
    end
    local matchId = payload.matchId or self._state:Get("activeMatchId")
    local ghostId = payload.ghostId
    if type(matchId) ~= "string" then
        return
    end

    self:TriggerAdaptiveHunt(matchId, ghostId, {
        averageSanity = payload.averageSanity,
        aggression = payload.aggression,
        playerNoise = payload.playerNoise,
        personalityHuntMultiplier = payload.personalityHuntMultiplier,
    })
end

function Service:OnPlayerNoiseDetected(payload)
    if type(payload) ~= "table" then
        return
    end
    local matchId = payload.matchId or self._state:Get("activeMatchId")
    if type(matchId) ~= "string" then
        return
    end

    local huntIntensity = self._state:Get("huntIntensity") or {}
    local current = huntIntensity[matchId] or 0
    local noise = clamp(tonumber(payload.noiseLevel) or 0, 0, 100)
    local nextIntensity = clamp(current + (noise * 0.08), 0, 100)
    huntIntensity[matchId] = nextIntensity
    self._state:Set("huntIntensity", huntIntensity)
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatch = self._state:Get("activeMatchId")
    if activeMatch and matchId and activeMatch ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("huntIntensity", {})
    self._state:Set("huntCooldowns", {})
end

return Service
