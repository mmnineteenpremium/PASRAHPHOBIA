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

local function resolvePlayers(deps)
    return deps and deps.Players or game:GetService("Players")
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = nil
    self._players = resolvePlayers(self._deps)
    self._subscriptions = {}
    self._connections = {}
    self._registered = false
    return self
end

function Controller:Init()
    self._eventBus = resolveEventBus(self._deps)
end

function Controller:Start()
    self:RegisterEventHandlers()
end

function Controller:Stop()
    self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
    if self._registered then
        return
    end

    if self._eventBus then
        self:_subscribe("MatchEnded", function(payload)
            self._service:OnMatchEnded(payload)
        end)
        self:_subscribe("GhostIdentified", function(payload)
            self._service:OnGhostIdentified(payload)
        end)
        self:_subscribe("ContentRegistered", function(payload)
            self._service:OnContentRegistered(payload)
        end)
        self:_subscribe("PlayerProfileShowcaseRequested", function(payload)
            self._service:OnProfileShowcaseRequested(payload)
        end)
        self:_subscribe("PlayerEngagementConfigReloadRequested", function()
            self._service:ReloadConfig()
        end)
    end

    if self._players then
        table.insert(self._connections, self._players.PlayerAdded:Connect(function(player)
            self._service:OnPlayerAdded({ player = player })
        end))
        for _, player in ipairs(self._players:GetPlayers()) do
            self._service:OnPlayerAdded({ player = player })
        end
    end

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._registered then
        return
    end

    if self._eventBus then
        for _, sub in ipairs(self._subscriptions) do
            self._eventBus:Unsubscribe(sub.eventName, sub.callback)
        end
    end

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end

    table.clear(self._subscriptions)
    table.clear(self._connections)
    self._registered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, { eventName = eventName, callback = callback })
end

return Controller
