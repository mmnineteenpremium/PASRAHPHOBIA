local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local REQUIRED_SUBSCRIPTIONS = {
    "MatchStarted",
    "EvidenceCollected",
    "PlayerSanityChanged",
    "GhostInteraction",
    "HuntTriggered",
    "MatchEnded",
}

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
    self._eventBus = nil
    self._subscriptions = {}
    self._registered = false
    return self
end

function Controller:Create()
    self._eventBus = resolveEventBus(self._deps)
end

function Controller:Init()
    -- Event hooks are registered in Start.
end

function Controller:Start()
    self:RegisterEventHandlers()
end

function Controller:Stop()
    self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
    if self._registered or not self._eventBus then
        return
    end

    self:_subscribe("MatchStarted", function(payload)
        self._service:OnMatchStarted(payload)
    end)
    self:_subscribe("EvidenceCollected", function(payload)
        self._service:OnEvidenceCollected(payload)
    end)
    self:_subscribe("PlayerSanityChanged", function(payload)
        self._service:OnPlayerSanityChanged(payload)
    end)
    self:_subscribe("GhostInteraction", function(payload)
        self._service:OnGhostInteraction(payload)
    end)
    self:_subscribe("HuntTriggered", function(payload)
        self._service:OnHuntTriggered(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self._service:OnMatchEnded(payload)
    end)

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._registered or not self._eventBus then
        return
    end

    for _, entry in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(entry.eventName, entry.callback)
    end
    table.clear(self._subscriptions)
    self._registered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:GetSubscriptions()
    return REQUIRED_SUBSCRIPTIONS
end

return Controller

