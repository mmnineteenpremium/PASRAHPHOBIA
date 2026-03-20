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
    self._state:Set("bootstrapStarted", false)
    self._state:Set("bootstrapCompleted", false)
    self._state:Set("startupOrderValidated", false)
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
        self._state:Set("bootstrapStarted", true)
        local hasEventBus = Services.Get(self._deps, "EventBus") ~= nil
        local hasMatch = Services.Get(self._deps, "MatchSystem") ~= nil
        local hasGhost = Services.Get(self._deps, "GhostSystem") ~= nil
        local hasInvestigation = Services.Get(self._deps, "InvestigationSystem") ~= nil

        local valid = hasEventBus and hasMatch and hasGhost and hasInvestigation
        self._state:Set("startupOrderValidated", valid)

        if valid then
            self:_publish("EngineStartupValidated", {
                sourceSystem = "FinalEngineBootstrap",
                timestamp = os.clock(),
            })
        else
            self:_publish("StartupErrorDetected", {
                sourceSystem = "FinalEngineBootstrap",
                reason = "startup_order_validation_failed",
                timestamp = os.clock(),
            })
        end

        self._state:Set("bootstrapCompleted", true)
    end
end

return Service
