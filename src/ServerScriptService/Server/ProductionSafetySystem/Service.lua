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

local function getAllServices(registry)
    if type(registry) ~= "table" then
        return {}
    end
    if type(registry.GetServicesByName) == "function" then
        return registry:GetServicesByName()
    end
    if type(registry.GetAll) == "function" then
        return registry:GetAll()
    end
    return {}
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._services = Services.GetRegistry(self._deps)
    return self
end

function Service:Init()
    self._state:Set("safetyTriggered", false)
    self._state:Set("lastViolation", nil)
    self._state:Set("activeMatchId", nil)
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

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        self._state:Set("activeMatchId", payload and payload.matchId)
    elseif eventName == "MatchEnded" then
        self._state:Set("activeMatchId", nil)
    elseif eventName == "EngineStart" then
        if not self._eventBus or not self._services then
            self._state:Set("safetyTriggered", true)
            self._state:Set("lastViolation", "startup_dependencies_missing")
            self:_publish("ProductionSafetyTriggered", {
                reason = "startup_dependencies_missing",
                timestamp = os.clock(),
            })
        end
    elseif eventName == "SystemErrorDetected" then
        self._state:Set("safetyTriggered", true)
        self._state:Set("lastViolation", "runtime_system_error")
        self:_publish("ProductionSafetyTriggered", {
            reason = "runtime_system_error",
            details = payload,
            timestamp = os.clock(),
        })
    end
end

return Service
