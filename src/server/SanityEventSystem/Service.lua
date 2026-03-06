local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local SANITY_EVENT_TYPES = {
    "LightFlicker",
    "DoorSlam",
    "ShadowMovement",
    "SuddenSilence",
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

local function safeCall(target, methodName, ...)
    if type(target) ~= "table" then
        return nil
    end
    local fn = target[methodName]
    if type(fn) ~= "function" then
        return nil
    end
    local ok, result = pcall(fn, target, ...)
    if not ok then
        return nil
    end
    return result
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
    self._state:Set("activeSanityEvents", self._state:Get("activeSanityEvents") or {})
    self._state:Set("eventCooldowns", self._state:Get("eventCooldowns") or {})
    self._state:Set("lastSanityByUser", self._state:Get("lastSanityByUser") or {})
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
    local eventCooldowns = self._state:Get("eventCooldowns") or {}
    return (eventCooldowns[userId] or 0) > os.clock()
end

function Service:_setCooldown(userId, seconds)
    local eventCooldowns = self._state:Get("eventCooldowns") or {}
    eventCooldowns[userId] = os.clock() + (seconds or 8)
    self._state:Set("eventCooldowns", eventCooldowns)
end

function Service:TriggerSanityEvent(userId, matchId, sanity)
    if self:_isOnCooldown(userId) then
        return false, "cooldown"
    end

    local eventType = SANITY_EVENT_TYPES[self._rng:NextInteger(1, #SANITY_EVENT_TYPES)]
    local duration = self._rng:NextNumber(2.0, 5.0)
    local intensity = math.max(0.2, math.min(1.0, (100 - (tonumber(sanity) or 100)) / 100))

    local activeEvents = self._state:Get("activeSanityEvents") or {}
    activeEvents[userId] = {
        eventType = eventType,
        startedAt = os.clock(),
        duration = duration,
        matchId = matchId,
        intensity = intensity,
    }
    self._state:Set("activeSanityEvents", activeEvents)

    local mapEventSystem = self._dependencies.MapEventSystem
    safeCall(mapEventSystem, "TriggerEvent", {
        eventType = eventType,
        intensity = intensity,
        matchId = matchId,
        source = "SanityEventSystem",
    })
    if type(mapEventSystem) == "table" and type(mapEventSystem.Service) == "table" then
        safeCall(mapEventSystem.Service, "TriggerEvent", {
            eventType = eventType,
            intensity = intensity,
            matchId = matchId,
            source = "SanityEventSystem",
        })
    end

    self:_publish("SanityEventTriggered", {
        userId = userId,
        matchId = matchId,
        eventType = eventType,
        intensity = intensity,
        sanity = sanity,
    })

    self:_setCooldown(userId, 8)

    task.delay(duration, function()
        local activeNow = self._state:Get("activeSanityEvents") or {}
        local current = activeNow[userId]
        if current and current.eventType == eventType then
            activeNow[userId] = nil
            self._state:Set("activeSanityEvents", activeNow)
            self:_publish("SanityEventResolved", {
                userId = userId,
                matchId = matchId,
                eventType = eventType,
            })
        end
    end)

    return true
end

function Service:OnPlayerSanityChanged(payload)
    if type(payload) ~= "table" then
        return
    end
    local userId = toUserId(payload.player or payload.userId)
    if not userId then
        return
    end

    local sanity = tonumber(payload.newSanity) or tonumber(payload.sanity) or 100
    local lastSanity = self._state:Get("lastSanityByUser") or {}
    local previous = lastSanity[userId]
    lastSanity[userId] = sanity
    self._state:Set("lastSanityByUser", lastSanity)

    local shouldTrigger = false
    if sanity <= 25 then
        shouldTrigger = true
    elseif previous and previous > 50 and sanity <= 50 then
        shouldTrigger = true
    end

    if shouldTrigger then
        self:TriggerSanityEvent(userId, payload.matchId, sanity)
    end
end

function Service:OnParanormalEvent(payload)
    if type(payload) ~= "table" then
        return
    end
    local userId = toUserId(payload.player or payload.userId)
    if userId then
        local sanity = (self._state:Get("lastSanityByUser") or {})[userId] or 100
        if sanity <= 45 then
            self:TriggerSanityEvent(userId, payload.matchId, sanity)
        end
    end
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local active = self._state:Get("activeSanityEvents") or {}
    for userId, eventData in pairs(active) do
        if matchId == nil or eventData.matchId == matchId then
            active[userId] = nil
            self:_publish("SanityEventResolved", {
                userId = userId,
                matchId = matchId,
                eventType = eventData.eventType,
            })
        end
    end
    self._state:Set("activeSanityEvents", active)
end

return Service