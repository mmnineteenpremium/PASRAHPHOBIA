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
    -- Rank events are bound at runtime.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    self:_subscribe("ExperienceGranted", function(payload)
        self._service:OnExperienceGranted(payload)
    end)
    self:_subscribe("LevelUp", function(payload)
        self._service:OnLevelUp(payload)
    end)
    self:_subscribe("RankUp", function(payload)
        self._service:OnRankUp(payload)
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
