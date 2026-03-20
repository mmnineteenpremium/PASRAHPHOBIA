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
    -- Subscriptions are established in Start.
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

    self:_subscribe("XPGranted", function(payload)
        local userId = payload and payload.userId
        local amount = payload and payload.amount
        if not userId or not amount then
            return
        end
        self._service:AddXP(userId, amount)
    end)

    self:_subscribe("MatchEnded", function(payload)
        if type(payload) ~= "table" then
            return
        end
        local reward = payload.rewardPayload or payload.rewards or payload.reward or {}
        local multiplier = tonumber(reward.difficultyMultiplier) or 1
        local xp = tonumber(reward.xp) or 0
        local total = xp * multiplier
        if type(payload.players) == "table" then
            for _, player in ipairs(payload.players) do
                local userId = player and player.UserId or player
                if userId then
                    self._service:AddXP(userId, total)
                end
            end
        end
    end)

    self:_subscribe("PlayerJoined", function(payload)
        local userId = payload and (payload.userId or payload.playerId or (payload.player and payload.player.UserId))
        local saved = payload and payload.savedData
        if not userId then
            return
        end
        self._service:InitSession(userId, saved)
    end)

    self:_subscribe("PlayerLeaving", function(payload)
        local userId = payload and (payload.userId or payload.playerId or (payload.player and payload.player.UserId))
        if not userId then
            return
        end
        self._service:SaveSession(userId)
    end)

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus or not self._registered then
        return
    end

    for _, subscription in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
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
