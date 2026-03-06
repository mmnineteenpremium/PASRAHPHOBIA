local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Subscribe) == "function" and type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" then
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
    -- Reserved for future lobby-wide orchestration.
end

function Controller:Start()
    if not self._eventBus then
        return
    end

    local callback = function(payload)
        self._state:Set("lastLobbyZoneEntry", payload)
    end

    self._eventBus:Subscribe("PlayerEnteredZone", callback)
    table.insert(self._subscriptions, {
        eventName = "PlayerEnteredZone",
        callback = callback,
    })
end

function Controller:Stop()
    if not self._eventBus then
        return
    end

    for _, subscription in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
    end
    table.clear(self._subscriptions)
end

return Controller