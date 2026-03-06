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

local function resolvePlayersService(deps)
    if deps.Players then
        return deps.Players
    end
    return game:GetService("Players")
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._subscriptions = {}
    self._connections = {}
    self._eventBus = resolveEventBus(self._deps)
    self._playersService = resolvePlayersService(self._deps)
    return self
end

function Controller:Init()
    -- Prepare controller-level wiring here.
end

function Controller:RegisterEventHandlers()
    if self._eventBus then
        self:_subscribe("PlayerTeleported", function(payload)
            self:OnPlayerTeleported(payload)
        end)
    end

    if self._playersService then
        table.insert(self._connections, self._playersService.PlayerAdded:Connect(function(player)
            self:OnPlayerAdded({
                player = player,
            })
        end))

        table.insert(self._connections, self._playersService.PlayerRemoving:Connect(function(player)
            self:OnPlayerRemoving({
                player = player,
            })
        end))

        for _, player in ipairs(self._playersService:GetPlayers()) do
            self:OnPlayerAdded({
                player = player,
            })
        end
    end
end

function Controller:UnregisterEventHandlers()
    if self._eventBus then
        for _, subscription in ipairs(self._subscriptions) do
            self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
        end
        table.clear(self._subscriptions)
    end

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:OnPlayerAdded(payload)
    local player = payload and payload.player
    if not player then
        return
    end
    self._service:RegisterPlayer(player)
end

function Controller:OnPlayerRemoving(payload)
    local player = payload and payload.player
    if not player then
        return
    end
    self._service:RemovePlayer(player)
end

function Controller:OnPartyUpdated(payload)
    -- Reserved for future party board synchronization.
end

function Controller:OnPlayerTeleported(payload)
    self._service:HandlePlayerTeleported(payload)
end

return Controller

