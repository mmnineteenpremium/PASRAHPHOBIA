local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

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

local function playerIdFromPayload(payload)
    if type(payload.playerId) == "number" then
        return payload.playerId
    end
    if type(payload.userId) == "number" then
        return payload.userId
    end
    local player = payload.player
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
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
    -- Subscriptions are registered in Start.
end

function Controller:Start()
    self:RegisterEventHandlers()
end

function Controller:Stop()
    self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._registered then
        return
    end

    self:_subscribe("PlayerJoinedLobby", function(payload)
        local playerId = playerIdFromPayload(payload or {})
        if playerId then
            self._service:JoinQueue(playerId, payload)
        end
    end)

    self:_subscribe("PartyCreated", function(payload)
        local partyId = payload and payload.partyId
        local members = payload and payload.members
        if partyId and type(members) == "table" then
            self._service:JoinPartyQueue(partyId, members, payload)
        end
    end)

    self:_subscribe("PlayerDisconnected", function(payload)
        local playerId = playerIdFromPayload(payload or {})
        if playerId then
            self._service:LeaveQueue(playerId)
        end
    end)

    self:_subscribe("MatchStarted", function(payload)
        local players = payload and payload.players
        if type(players) == "table" then
            for _, userId in ipairs(players) do
                if type(userId) == "number" then
                    self._service:LeaveQueue(userId)
                end
            end
        end
    end)

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus or not self._registered then
        return
    end
    for _, sub in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(sub.eventName, sub.callback)
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

return Controller
