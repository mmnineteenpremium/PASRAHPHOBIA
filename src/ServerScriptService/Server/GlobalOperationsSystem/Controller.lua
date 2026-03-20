local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Subscribe) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then
        return eventBus.Service
    end
    return nil
end

local function resolveRunService(deps)
    return deps and deps.RunService or game:GetService("RunService")
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = nil
    self._runService = resolveRunService(self._deps)
    self._subscriptions = {}
    self._connections = {}
    self._registered = false
    self._accumulator = 0
    return self
end

function Controller:Init()
    self._eventBus = resolveEventBus(self._deps)
end

function Controller:Start()
    self:RegisterEventHandlers()
end

function Controller:Stop()
    self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
    if self._registered then
        return
    end

    if self._eventBus then
        self:_subscribe("TelemetryEventRecorded", function(payload)
            self._service:OnTelemetryEventRecorded(payload)
        end)
        self:_subscribe("MatchStarted", function(payload)
            self._service:OnMatchStarted(payload)
        end)
        self:_subscribe("MatchEnded", function(payload)
            self._service:OnMatchEnded(payload)
        end)
        self:_subscribe("ServerHealthWarning", function(payload)
            self._service:OnServerHealthWarning(payload)
        end)
        self:_subscribe("GlobalReleaseReadinessRequested", function()
            self._service:OnGlobalReleaseReadinessRequested()
        end)
        self:_subscribe("GlobalOperationsConfigReloadRequested", function()
            self._service:ReloadConfig()
        end)
    end

    if self._runService then
        table.insert(self._connections, self._runService.Heartbeat:Connect(function(delta)
            self._accumulator += delta
            if self._accumulator >= 5 then
                self._accumulator = 0
                self._service:OnHeartbeatTick()
            end
        end))
    end

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._registered then
        return
    end

    if self._eventBus then
        for _, sub in ipairs(self._subscriptions) do
            self._eventBus:Unsubscribe(sub.eventName, sub.callback)
        end
    end

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end

    table.clear(self._subscriptions)
    table.clear(self._connections)
    self._registered = false
    self._accumulator = 0
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

return Controller
