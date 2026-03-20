local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._subscriptions = {}
    self._eventBus = resolveEventBus(self._deps)
    return self
end

function Controller:Init()
    -- Prepare controller-level wiring here.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
    end)
    self:_subscribe("ResultsCalculated", function(payload)
        self:OnResultsCalculated(payload)
    end)
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus then
        return
    end

    for _, subscription in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
    end
    table.clear(self._subscriptions)
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:OnMatchEnded(payload)
    self._service:ApplyMatchResults(payload)
end

function Controller:OnResultsCalculated(payload)
    self._service:ApplyMatchResults(payload)
end

return Controller

