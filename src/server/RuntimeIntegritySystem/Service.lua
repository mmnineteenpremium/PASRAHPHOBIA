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
    self._state:Set("lastHeartbeatAt", os.clock())
    self._state:Set("warningCount", 0)
    self._state:Set("maxAllowedDelay", 5)
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
        self._state:Set("lastHeartbeatAt", os.clock())
    elseif eventName == "SystemErrorDetected" then
        local count = (self._state:Get("warningCount") or 0) + 1
        self._state:Set("warningCount", count)
        self:_publish("RuntimeIntegrityWarning", {
            reason = "system_error_detected",
            warningCount = count,
            timestamp = os.clock(),
        })
    elseif eventName == "SystemRegistered" then
        local now = os.clock()
        local last = self._state:Get("lastHeartbeatAt") or now
        local delay = now - last
        self._state:Set("lastHeartbeatAt", now)
        if delay > (self._state:Get("maxAllowedDelay") or 5) then
            local count = (self._state:Get("warningCount") or 0) + 1
            self._state:Set("warningCount", count)
            self:_publish("RuntimeIntegrityWarning", {
                reason = "event_processing_delay",
                delay = delay,
                warningCount = count,
                timestamp = now,
            })
        end
    end
end

return Service
