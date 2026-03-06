local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = deps.EventBus
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

    self:_subscribe("MatchStarted", function(payload)
        self:OnMatchStarted(payload)
    end)
    self:_subscribe("PlayerKilled", function(payload)
        self:OnPlayerKilled(payload)
    end)
    self:_subscribe("GhostRoamed", function(payload)
        self:OnGhostRoamed(payload)
    end)
    self:_subscribe("GhostInteraction", function(payload)
        self:OnGhostInteraction(payload)
    end)
    self:_subscribe("HuntStarted", function(payload)
        self:OnHuntStarted(payload)
    end)
    self:_subscribe("HuntEnded", function(payload)
        self:OnHuntEnded(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
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

function Controller:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:StartMatch(matchId, payload)
end

function Controller:OnPlayerKilled(payload)
    local matchId = payload and payload.matchId
    local player = payload and payload.player
    if not matchId or not player then
        return
    end

    self._service:EnterSpectator(player, matchId, payload)

    self._service:ProcessGhostActivity(matchId, {
        activityType = "player_killed",
        player = player,
        now = payload.now,
        room = payload.room,
    })
end

function Controller:OnGhostRoamed(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessGhostActivity(matchId, {
        activityType = "ghost_roamed",
        room = payload.room,
        now = payload.now,
    })
end

function Controller:OnGhostInteraction(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessGhostActivity(matchId, {
        activityType = "ghost_interaction",
        room = payload.room,
        interactionType = payload.interactionType,
        now = payload.now,
    })
end

function Controller:OnHuntStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessGhostActivity(matchId, {
        activityType = "hunt_started",
        now = payload.now,
    })
end

function Controller:OnHuntEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessGhostActivity(matchId, {
        activityType = "hunt_ended",
        now = payload.now,
    })
end

function Controller:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:EndMatch(matchId)
end

return Controller

