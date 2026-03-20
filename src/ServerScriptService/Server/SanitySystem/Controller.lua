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

    self:_subscribe("MatchStarted", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:StartMatch(matchId, payload and payload.players or {}, payload and payload.difficultyProfile)
    end)

    self:_subscribe("MatchEnded", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:EndMatch(matchId)
    end)

    self:_subscribe("HuntStarted", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:OnHuntStarted(matchId, payload)
    end)

    self:_subscribe("HuntEnded", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:OnHuntEnded(matchId)
    end)

    self:_subscribe("GhostManifested", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:ApplySnapshotDrain(matchId, 5)
    end)

    self:_subscribe("GhostRoaming", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:OnGhostEvent(matchId, "Roaming")
    end)

    self:_subscribe("PlayerDied", function(payload)
        local matchId = payload and payload.matchId
        local playerId = payload and (payload.userId or payload.playerId)
        if not matchId or not playerId then
            return
        end
        self._service:RemovePlayer(matchId, playerId)
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

function Controller:Shutdown()
    self:UnregisterEventHandlers()
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

return Controller
