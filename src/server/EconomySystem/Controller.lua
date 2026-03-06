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

local function resolveRewardSystem(deps)
    local services = deps and (deps.Services or deps.ServiceRegistry)
    if type(services) ~= "table" then
        return nil
    end
    local get = services.Get or services.GetService
    if type(get) ~= "function" then
        return nil
    end
    local reward = get(services, "RewardSystem")
    if type(reward) ~= "table" then
        return nil
    end
    if type(reward.HandleMatchEnded) == "function" then
        return reward
    end
    if type(reward.Service) == "table" and type(reward.Service.HandleMatchEnded) == "function" then
        return reward.Service
    end
    return nil
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._playersService = resolvePlayersService(self._deps)
    self._eventBus = resolveEventBus(self._deps)
    self._rewardSystem = resolveRewardSystem(self._deps)
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
    if self._eventBus then
        self:_subscribe("MatchEnded", function(payload)
            self:OnMatchEnded(payload)
        end)
        self:_subscribe("MissionCompleted", function(payload)
            self:OnMissionCompleted(payload)
        end)
        self:_subscribe("EvidenceDiscovered", function(payload)
            self:OnEvidenceDiscovered(payload)
        end)
    end

    if not self._playersService then
        self._handlersRegistered = true
        return
    end

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
    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    if not self._handlersRegistered then
        return
    end
    if self._eventBus then
        for _, sub in ipairs(self._subscriptions) do
            self._eventBus:Unsubscribe(sub.eventName, sub.callback)
        end
    end
    table.clear(self._subscriptions)

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    self._handlersRegistered = false
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

function Controller:OnMatchEnded(payload)
    if self._rewardSystem and type(self._rewardSystem.HandleMatchEnded) == "function" then
        self._rewardSystem:HandleMatchEnded(payload)
        return
    end
    self._service:GrantMatchRewardsFromMatch(payload)
end

function Controller:OnMissionCompleted(payload)
    local player = payload and (payload.player or payload.userId)
    if not player then
        return
    end
    if self._rewardSystem and type(self._rewardSystem.HandleMissionCompleted) == "function" then
        self._rewardSystem:HandleMissionCompleted(payload)
        return
    end
    self._service:GrantMissionCompleted(player)
end

function Controller:OnEvidenceDiscovered(payload)
    local player = payload and (payload.player or payload.userId)
    if not player then
        return
    end
    -- Lightweight direct reward for evidence confirmations when central RewardSystem does not map this event.
    local ok, _, granted = self._service:AddCurrency(player, "MM", 25, "evidence_discovered")
    if ok and self._eventBus and (granted or 0) > 0 then
        self._eventBus:Publish("PlayerRewardGranted", {
            player = payload and payload.player,
            userId = payload and payload.userId,
            currency = "MM",
            amount = granted,
            reason = "evidence_discovered",
            context = payload,
        })
    end
end

return Controller
