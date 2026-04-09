local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")

local Controller = {}
Controller.__index = Controller

local ROYAL_PASS_REMOTE_NAME = "RoyalPassEvent"

local function resolveRoyalPassRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end

    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end

    local remote = remoteFolder:FindFirstChild(ROYAL_PASS_REMOTE_NAME)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

local function resolvePlayerFromPayload(payload)
    if type(payload) ~= "table" then
        return nil
    end
    if typeof(payload.player) == "Instance" and payload.player:IsA("Player") then
        return payload.player
    end

    local userId = tonumber(payload.userId)
    if not userId or userId <= 0 then
        return nil
    end

    local ok, player = pcall(function()
        return Players:GetPlayerByUserId(userId)
    end)
    if ok then
        return player
    end
    return nil
end

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
    self._royalPassRemote = nil
    self._playerAddedConnection = nil
    return self
end

function Controller:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._royalPassRemote = resolveRoyalPassRemote()
end

function Controller:Init()
    -- Subscriptions are registered in Start.
end

function Controller:Start()
    self:RegisterEventHandlers()
    self:_connectPlayerSignals()
    self:_syncExistingPlayers()
end

function Controller:Stop()
    self:_disconnectPlayerSignals()
    self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._registered then
        return
    end

    self:_subscribe("MatchEnded", function(payload)
        self._service:OnMatchEnded(payload)
    end)

    self:_subscribe("MissionCompleted", function(payload)
        self._service:OnMissionCompleted(payload)
    end)

    self:_subscribe("XPGranted", function(payload)
        self._service:OnXPGranted(payload)
    end)

    self:_subscribe("RoyalPassXPGranted", function(payload)
        self:OnRoyalPassXPGranted(payload)
    end)

    self:_subscribe("RoyalPassTierUnlocked", function(payload)
        self:OnRoyalPassTierUnlocked(payload)
    end)

    self:_subscribe("RoyalPassPremiumOwnershipChanged", function(payload)
        self:OnRoyalPassPremiumOwnershipChanged(payload)
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

function Controller:_connectPlayerSignals()
    if self._playerAddedConnection then
        return
    end

    self._playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:_scheduleSnapshotPush(player, "PlayerAdded")
    end)
end

function Controller:_disconnectPlayerSignals()
    if self._playerAddedConnection then
        self._playerAddedConnection:Disconnect()
        self._playerAddedConnection = nil
    end
end

function Controller:_scheduleSnapshotPush(player, reason)
    if not player then
        return
    end

    for _, delaySeconds in ipairs({ 1, 4 }) do
        task.delay(delaySeconds, function()
            if player.Parent == Players then
                self:_sendSnapshot(player, "RoyalPassSnapshot", {
                    reason = reason,
                })
            end
        end)
    end
end

function Controller:_syncExistingPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        self:_scheduleSnapshotPush(player, "InitialSync")
    end
end

function Controller:_sendPayload(player, payload)
    if not player then
        return
    end
    if not self._royalPassRemote then
        self._royalPassRemote = resolveRoyalPassRemote()
    end
    if not self._royalPassRemote then
        return
    end
    self._royalPassRemote:FireClient(player, payload)
end

function Controller:_sendSnapshot(player, eventName, extraPayload)
    local snapshotBuilder = type(self._service) == "table" and type(self._service._buildPlayerSnapshot) == "function"
        and self._service._buildPlayerSnapshot
        or type(self._service) == "table" and type(self._service.GetPlayerSnapshot) == "function"
        and self._service.GetPlayerSnapshot
        or nil
    if type(snapshotBuilder) ~= "function" then
        return
    end

    local snapshot = snapshotBuilder(self._service, player)
    if not snapshot then
        return
    end

    local payload = {
        eventName = eventName or "RoyalPassSnapshot",
        snapshot = snapshot,
    }

    if type(extraPayload) == "table" then
        for key, value in pairs(extraPayload) do
            payload[key] = value
        end
    end

    self:_sendPayload(player, payload)
end

function Controller:OnRoyalPassXPGranted(payload)
    local player = resolvePlayerFromPayload(payload)
    if not player then
        return
    end

    self:_sendSnapshot(player, "RoyalPassProgress", {
        amount = math.max(0, math.floor(tonumber(payload.amount) or 0)),
        source = payload.source,
        totalXP = math.max(0, math.floor(tonumber(payload.totalXP) or 0)),
    })
end

function Controller:OnRoyalPassTierUnlocked(payload)
    local player = resolvePlayerFromPayload(payload)
    if not player then
        return
    end

    self:_sendSnapshot(player, "RoyalPassTierUnlocked", {
        tier = math.max(1, math.floor(tonumber(payload.tier) or 1)),
        seasonId = payload.seasonId,
    })
end

function Controller:OnRoyalPassPremiumOwnershipChanged(payload)
    local player = resolvePlayerFromPayload(payload)
    if not player then
        return
    end

    self:_sendSnapshot(player, "RoyalPassPremiumUpdated", {
        ownsPremium = payload.ownsPremium == true,
        seasonId = payload.seasonId,
    })
end

return Controller
