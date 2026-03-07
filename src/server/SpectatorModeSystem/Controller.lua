local Services = require(script.Parent.Parent.Core.Services)
local Controller = {}
Controller.__index = Controller
local SUBSCRIPTIONS = {
    "MatchStarted",
    "MatchEnded",
    "PlayerDied",
    "PlayerDisconnected",
}
local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then return nil end
    if type(eventBus.Subscribe) == "function" then return eventBus end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then return eventBus.Service end
    return nil
end
function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._subscriptions = {}
    self._registered = false
    return self
end
function Controller:Init() end
function Controller:RegisterEventHandlers()
    if not self._eventBus or self._registered then return end
    for _, eventName in ipairs(SUBSCRIPTIONS) do
        self:_subscribe(eventName, function(payload) self._service:HandleEvent(eventName, payload) end)
    end
    self._registered = true
end
function Controller:UnregisterEventHandlers()
    if not self._eventBus or not self._registered then return end
    for _, subscription in ipairs(self._subscriptions) do self._eventBus:Unsubscribe(subscription.eventName, subscription.callback) end
    table.clear(self._subscriptions)
    self._registered = false
end
function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, { eventName = eventName, callback = callback })
end
return Controller
