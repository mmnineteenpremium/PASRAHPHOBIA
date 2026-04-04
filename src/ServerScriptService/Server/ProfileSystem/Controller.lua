local Controller = {}
Controller.__index = Controller

local Players = game:GetService("Players")

local bindToCloseRegistered = false

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
    self._players = self._deps.Players or Players
    self._connections = {}
    return self
end

function Controller:Init()
    -- Prepare controller-level wiring here.
end

function Controller:RegisterEventHandlers()
    if self._players then
        table.insert(self._connections, self._players.PlayerAdded:Connect(function(player)
            self._service:OnPlayerAdded(player)
        end))
        table.insert(self._connections, self._players.PlayerRemoving:Connect(function(player)
            self._service:OnPlayerRemoving(player)
        end))
        for _, player in ipairs(self._players:GetPlayers()) do
            self._service:OnPlayerAdded(player)
        end
    end

    if not self._eventBus then
        if not bindToCloseRegistered then
            bindToCloseRegistered = true
            game:BindToClose(function()
                if not self._players then
                    return
                end
                for _, player in ipairs(self._players:GetPlayers()) do
                    self._service:OnPlayerRemoving(player)
                end
            end)
        end
        return
    end

    self:_subscribe("PlayerEnteredLobby", function(payload)
        self:OnPlayerEnteredLobby(payload)
    end)
    self:_subscribe("RankUpdated", function(payload)
        self:OnRankUpdated(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
    end)

    if not bindToCloseRegistered then
        bindToCloseRegistered = true
        game:BindToClose(function()
            if not self._players then
                return
            end
            for _, player in ipairs(self._players:GetPlayers()) do
                self._service:OnPlayerRemoving(player)
            end
        end)
    end
end

function Controller:UnregisterEventHandlers()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

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

function Controller:OnPlayerEnteredLobby(payload)
    local player = payload and payload.player
    if not player then
        return
    end
    self._service:OnPlayerEnteredLobby(player)
end

function Controller:OnRankUpdated(payload)
    self._service:OnRankUpdated(payload)
end

function Controller:OnMatchEnded(payload)
    self._service:OnMatchEnded(payload)
end

return Controller

