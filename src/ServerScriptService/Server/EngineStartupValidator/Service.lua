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
    self._state:Set("lastValidation", nil)
    self._state:Set("startupErrors", {})
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
        local errors = {}
        if not self._services then
            table.insert(errors, "service_registry_unavailable")
        end
        if not self._eventBus then
            table.insert(errors, "event_bus_unavailable")
        end

        local bootstrap = Services.Get(self._deps, "Bootstrap")
        local systemFactory = self._deps.SystemFactory
        if type(bootstrap) ~= "table" then
            table.insert(errors, "bootstrap_unavailable")
        end
        if type(systemFactory) ~= "table" then
            table.insert(errors, "system_factory_unavailable")
        end

        self._state:Set("startupErrors", errors)
        self._state:Set("lastValidation", os.clock())
        if #errors == 0 then
            self:_publish("EngineStartupValidated", { timestamp = os.clock() })
        else
            self:_publish("StartupErrorDetected", { errors = errors, timestamp = os.clock() })
        end
    end
end

return Service
