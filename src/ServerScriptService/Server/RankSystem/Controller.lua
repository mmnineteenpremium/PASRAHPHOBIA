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

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
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
    -- Event subscriptions are registered in Start.
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

    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
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

function Controller:OnMatchEnded(payload)
    if type(payload) ~= "table" then
        return
    end

    local matchMode = payload.mode or payload.matchMode or payload.gameMode
    local results = payload.results or {}

    for _, entry in ipairs(results.playerResults or {}) do
        local userId = entry.userId or toUserId(entry.player)
        local won = entry.won or entry.didWin or entry.winner
        if userId ~= nil and won ~= nil then
            self._service:ProcessMatchResult(userId, won == true, matchMode)
        end
    end

    for userId, entry in pairs(results.byUserId or {}) do
        if type(entry) == "table" then
            local resolvedId = entry.userId or tonumber(userId) or userId
            local won = entry.won or entry.didWin or entry.winner
            if resolvedId ~= nil and won ~= nil then
                self._service:ProcessMatchResult(resolvedId, won == true, matchMode)
            end
        end
    end

    if type(payload.players) == "table" and results.playerResults == nil then
        local won = payload.winner or payload.didWin or payload.won
        if won ~= nil then
            for _, player in ipairs(payload.players) do
                local userId = toUserId(player)
                if userId then
                    self._service:ProcessMatchResult(userId, won == true, matchMode)
                end
            end
        end
    end
end

return Controller
