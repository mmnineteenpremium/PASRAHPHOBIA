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
    self._state:Set("missingServices", {})
    self._state:Set("invalidServiceNames", {})
    self._state:Set("circularRiskDetected", false)
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
    elseif eventName == "EngineStart" or eventName == "SystemRegistered" then
        local required = {
            "EventBus",
            "ConfigLoader",
            "MatchSystem",
            "GhostSystem",
            "EvidenceSystem",
            "InvestigationSystem",
        }
        local missing = {}
        for _, name in ipairs(required) do
            if Services.Get(self._deps, name) == nil then
                table.insert(missing, name)
            end
        end

        local invalid = {}
        for name, _ in pairs(getAllServices(self._services)) do
            if type(name) ~= "string" or name == "" then
                table.insert(invalid, tostring(name))
            end
        end

        local circularRisk = false
        local graph = self._deps.DependencyGraph
        if type(graph) == "table" then
            for source, targets in pairs(graph) do
                if type(targets) == "table" and targets[source] == true then
                    circularRisk = true
                    break
                end
            end
        end

        self._state:Set("missingServices", missing)
        self._state:Set("invalidServiceNames", invalid)
        self._state:Set("circularRiskDetected", circularRisk)

        if #missing == 0 and #invalid == 0 and not circularRisk then
            self:_publish("DependencyVerified", { timestamp = os.clock() })
        else
            self:_publish("DependencyErrorDetected", {
                missingServices = missing,
                invalidServiceNames = invalid,
                circularRiskDetected = circularRisk,
                timestamp = os.clock(),
            })
        end
    end
end

return Service
