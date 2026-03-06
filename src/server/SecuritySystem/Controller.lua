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
    self._eventBus = resolveEventBus(self._deps)
    self._subscriptions = {}
    return self
end

function Controller:Init()
    -- Runtime event subscriptions only.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    self:_subscribe("RemoteEventReceived", function(payload)
        self._service:OnRemoteEventReceived(payload)
    end)
    self:_subscribe("CurrencyTransactionRequested", function(payload)
        self._service:OnCurrencyTransactionRequested(payload)
    end)
    self:_subscribe("InventoryUpdateRequested", function(payload)
        self._service:OnInventoryUpdateRequested(payload)
    end)
    self:_subscribe("MatchEventRequested", function(payload)
        self._service:OnMatchEventRequested(payload)
    end)
    self:_subscribe("MatchStarted", function(payload)
        self._service:OnMatchStarted(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self._service:OnMatchEnded(payload)
    end)
    self:_subscribe("CurrencyChanged", function(payload)
        self._service:OnCurrencyChanged(payload)
    end)
    self:_subscribe("InventoryUpdated", function(payload)
        self._service:OnInventoryUpdated(payload)
    end)
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus then
        return
    end
    for _, sub in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(sub.eventName, sub.callback)
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

return Controller
