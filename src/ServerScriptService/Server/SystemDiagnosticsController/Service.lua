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
    self._state:Set("eventTraffic", 0)
    self._state:Set("runtimeWarnings", 0)
    self._state:Set("snapshots", {})
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
    local traffic = (self._state:Get("eventTraffic") or 0) + 1
    self._state:Set("eventTraffic", traffic)

    if eventName == "MatchStarted" then
        self._state:Set("activeMatchId", payload and payload.matchId)
    elseif eventName == "MatchEnded" then
        self._state:Set("activeMatchId", nil)
    elseif eventName == "SystemErrorDetected" then
        self._state:Set("runtimeWarnings", (self._state:Get("runtimeWarnings") or 0) + 1)
    elseif eventName == "EngineStart" then
        local snapshot = {
            at = os.clock(),
            systemLoad = 0,
            eventTraffic = self._state:Get("eventTraffic") or 0,
            runtimeWarnings = self._state:Get("runtimeWarnings") or 0,
            totalServices = 0,
        }
        local count = 0
        for _, _ in pairs(getAllServices(self._services)) do
            count += 1
        end
        snapshot.totalServices = count

        local snapshots = self._state:Get("snapshots") or {}
        table.insert(snapshots, snapshot)
        self._state:Set("snapshots", snapshots)
        self:_publish("DiagnosticsSnapshotCreated", snapshot)
    end
end

return Service
