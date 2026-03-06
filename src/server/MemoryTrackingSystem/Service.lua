local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local EVENT_NAMES = {
    "MemoryUsageUpdated",
    "MemoryLeakSuspected",
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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    self._running = false
    self._loopToken = 0
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
        EventBus = Services.Get(self._deps, "EventBus"),
        ServiceRegistry = Services.Get(self._deps, "ServiceRegistry"),
    }
end

function Service:Init()
    self._state:Set("memoryStats", self._state:Get("memoryStats") or {})
    self._state:Set("objectCounts", self._state:Get("objectCounts") or {})
end

function Service:Start()
    self._running = true
    self._loopToken += 1
    local token = self._loopToken
    task.spawn(function()
        while self._running and token == self._loopToken do
            local first = EVENT_NAMES[1]
            if first then
                self:_publish(first, {
                    sourceEvent = "Tick",
                    snapshot = self._state:Get("eventCounters"),
                    at = os.time(),
                })
            end
            task.wait(5)
        end
    end)
end

function Service:Stop()
    self._running = false
    self._loopToken += 1
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:HandleEvent(eventName, payload)
    local counters = self._state:Get("eventCounters") or {}
    counters[eventName] = (counters[eventName] or 0) + 1
    self._state:Set("eventCounters", counters)

    local bucket = self._state:Get("memoryStats") or {}
    table.insert(bucket, {
        eventName = eventName,
        payload = payload,
        at = os.time(),
    })
    if #bucket > 200 then
        table.remove(bucket, 1)
    end
    self._state:Set("memoryStats", bucket)

    local first = EVENT_NAMES[1]
    local second = EVENT_NAMES[2]

    if eventName == "SystemErrorDetected" and first then
        self:_publish(first, {
            sourceEvent = eventName,
            payload = payload,
            counters = counters,
        })
    elseif second and counters[eventName] >= 25 then
        self:_publish(second, {
            sourceEvent = eventName,
            count = counters[eventName],
        })
    elseif first and (eventName == "MatchStarted" or eventName == "MatchEnded") then
        self:_publish(first, {
            sourceEvent = eventName,
            payload = payload,
        })
    end
end

return Service