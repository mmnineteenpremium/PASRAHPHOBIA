local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = deps and deps.EventBus
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
    -- Event subscriptions are registered in Start.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    self:_subscribe("PlayerRewardGranted", function(payload)
        self:OnPlayerRewardGranted(payload)
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

function Controller:OnPlayerRewardGranted(payload)
    self._service:OnPlayerRewardGranted(payload)
end

return Controller
