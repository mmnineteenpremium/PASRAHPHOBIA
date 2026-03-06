local Controller = {}
Controller.__index = Controller

local Services = require(script.Parent.Parent.Core.Services)

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

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._subscriptions = {}
    self._handlersRegistered = false
    return self
end

function Controller:Init()
    -- Runtime event bindings are registered in Start.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._handlersRegistered then
        return
    end
    self:_subscribe("LevelUp", function(data)
        self:OnLevelUp(data)
    end)
    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus or not self._handlersRegistered then
        return
    end
    for _, sub in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(sub.eventName, sub.callback)
    end
    table.clear(self._subscriptions)
    self._handlersRegistered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:OnLevelUp(data)
    local playerOrUserId = data and (data.player or data.userId)
    if not playerOrUserId then
        return
    end
    self._service:EvaluateRank(playerOrUserId, data.levelAfter or data.level)
end

return Controller
