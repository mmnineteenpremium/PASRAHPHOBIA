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
    self._handlersRegistered = false
    return self
end

function Controller:Init()
    -- Event-driven wiring only.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._handlersRegistered then
        return
    end

    self:_subscribe("MatchStarted", function(payload)
        self:OnMatchStarted(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
    end)
    self:_subscribe("FearLevelChanged", function(payload)
        self:OnFearLevelChanged(payload)
    end)
    self:_subscribe("SanityChanged", function(payload)
        self:OnSanityChanged(payload)
    end)
    self:_subscribe("PlayerSanityChanged", function(payload)
        self:OnSanityChanged(payload)
    end)
    self:_subscribe("DirectorTensionChanged", function(payload)
        self:OnDirectorTensionChanged(payload)
    end)
    self:_subscribe("AggressionIncreased", function(payload)
        self:OnAggressionIncreased(payload)
    end)
    self:_subscribe("HuntStarted", function(payload)
        self:OnHuntStarted(payload)
    end)
    self:_subscribe("HuntEnded", function(payload)
        self:OnHuntEnded(payload)
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

function Controller:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if matchId then
        self._service:StartMatch(matchId, payload)
    end
end

function Controller:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if matchId then
        self._service:EndMatch(matchId)
    end
end

function Controller:OnFearLevelChanged(payload)
    if payload and payload.global == true then
        return
    end
    local matchId = payload and payload.matchId
    if matchId then
        self._service:OnFearLevelChanged(matchId, payload)
    end
end

function Controller:OnSanityChanged(payload)
    local matchId = payload and payload.matchId
    if matchId then
        self._service:OnSanityChanged(matchId, payload)
    end
end

function Controller:OnDirectorTensionChanged(payload)
    local matchId = payload and payload.matchId
    if matchId then
        self._service:OnDirectorTensionChanged(matchId, payload)
    end
end

function Controller:OnAggressionIncreased(payload)
    local matchId = payload and payload.matchId
    if matchId then
        self._service:OnAggressionIncreased(matchId, payload)
    end
end

function Controller:OnHuntStarted(payload)
    local matchId = payload and payload.matchId
    if matchId then
        self._service:OnHuntStarted(matchId)
    end
end

function Controller:OnHuntEnded(payload)
    local matchId = payload and payload.matchId
    if matchId then
        self._service:OnHuntEnded(matchId)
    end
end

return Controller
