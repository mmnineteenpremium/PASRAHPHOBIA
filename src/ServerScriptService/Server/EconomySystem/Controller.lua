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
    self._eventBus = resolveEventBus(self._deps)
    self._players = self._deps.Players or Players
    self._connections = {}
    self._subscriptions = {}
    self._handlersRegistered = false
    return self
end

function Controller:Init()
    -- Placeholder for future controller wiring.
end

function Controller:RegisterEventHandlers()
    if self._handlersRegistered then
        return
    end
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
    if self._eventBus then
        self:_subscribe("DailyMissionCompleted", function(payload)
            self:OnDailyMissionCompleted(payload)
        end)
        self:_subscribe("DailyCheckinClaimed", function(payload)
            self:OnDailyCheckinClaimed(payload)
        end)
    end
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
    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    if not self._handlersRegistered then
        return
    end
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    if self._eventBus then
        for _, sub in ipairs(self._subscriptions) do
            self._eventBus:Unsubscribe(sub.eventName, sub.callback)
        end
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

function Controller:OnDailyMissionCompleted(payload)
    local userId = payload and (payload.userId or toUserId(payload.player))
    if not userId then
        return
    end
    local reward = payload and (payload.reward or payload) or {}
    self._service:GrantMissionReward(userId, reward)
end

function Controller:OnDailyCheckinClaimed(payload)
    local userId = payload and (payload.userId or toUserId(payload.player))
    local reward = payload and (payload.reward or payload.checkinReward or payload.amount) or 0
    if not userId then
        return
    end
    self._service:AddCurrency(userId, "MM", reward, "DailyCheckIn")
end

return Controller
