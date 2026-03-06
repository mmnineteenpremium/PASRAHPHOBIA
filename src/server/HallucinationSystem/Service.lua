local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local HALLUCINATION_TYPES = {
    "FakeGhostAppearance",
    "ShadowFigure",
    "FalseFootsteps",
    "FakeEvidence",
}

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

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    self._rng = Random.new()
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        SanitySystem = Services.Get(self._deps, "SanitySystem"),
        HorrorDirector = Services.Get(self._deps, "HorrorDirector"),
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        MapEventSystem = Services.Get(self._deps, "MapEventSystem"),
    }
end

function Service:Init()
    self._state:Set("activeHallucinations", self._state:Get("activeHallucinations") or {})
    self._state:Set("hallucinationHistory", self._state:Get("hallucinationHistory") or {})
    self._state:Set("cooldownUntil", self._state:Get("cooldownUntil") or {})
end

function Service:Start()
    -- Event-driven service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_isOnCooldown(userId)
    local cooldownUntil = self._state:Get("cooldownUntil") or {}
    return (cooldownUntil[userId] or 0) > os.clock()
end

function Service:_setCooldown(userId, seconds)
    local cooldownUntil = self._state:Get("cooldownUntil") or {}
    cooldownUntil[userId] = os.clock() + (seconds or 12)
    self._state:Set("cooldownUntil", cooldownUntil)
end

function Service:TriggerHallucination(userId, matchId, fearLevel)
    if self:_isOnCooldown(userId) then
        return false, "cooldown"
    end

    local hallucinationType = HALLUCINATION_TYPES[self._rng:NextInteger(1, #HALLUCINATION_TYPES)]
    local duration = self._rng:NextNumber(3.0, 7.5)

    local active = self._state:Get("activeHallucinations") or {}
    active[userId] = {
        type = hallucinationType,
        startedAt = os.clock(),
        duration = duration,
        matchId = matchId,
        fearLevel = fearLevel,
    }
    self._state:Set("activeHallucinations", active)

    local history = self._state:Get("hallucinationHistory") or {}
    history[userId] = history[userId] or {}
    table.insert(history[userId], {
        type = hallucinationType,
        at = os.time(),
        duration = duration,
        matchId = matchId,
    })
    self._state:Set("hallucinationHistory", history)

    self:_publish("HallucinationTriggered", {
        userId = userId,
        matchId = matchId,
        hallucinationType = hallucinationType,
        duration = duration,
        fearLevel = fearLevel,
        disclaimer = "Hallucination does not reveal true ghost identity",
    })

    self:_setCooldown(userId, 12)

    task.delay(duration, function()
        local activeNow = self._state:Get("activeHallucinations") or {}
        local current = activeNow[userId]
        if current and current.type == hallucinationType then
            activeNow[userId] = nil
            self._state:Set("activeHallucinations", activeNow)
            self:_publish("HallucinationEnded", {
                userId = userId,
                matchId = matchId,
                hallucinationType = hallucinationType,
            })
        end
    end)

    return true
end

function Service:OnFearThresholdTriggered(payload)
    if type(payload) ~= "table" then
        return
    end
    local userId = toUserId(payload.player or payload.userId)
    if not userId then
        return
    end
    if payload.threshold ~= "HIGH" then
        return
    end

    self:TriggerHallucination(userId, payload.matchId, payload.fearLevel)
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local active = self._state:Get("activeHallucinations") or {}
    for userId, entry in pairs(active) do
        if matchId == nil or entry.matchId == matchId then
            active[userId] = nil
            self:_publish("HallucinationEnded", {
                userId = userId,
                matchId = matchId,
                hallucinationType = entry.type,
            })
        end
    end
    self._state:Set("activeHallucinations", active)
end

return Service