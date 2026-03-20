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
    self._players = game:GetService("Players")
    self._spectatorRemote = nil
    return self
end

local function ensureRemoteFolder(replicatedStorage)
    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    if remoteFolder and remoteFolder:IsA("Folder") then
        return remoteFolder
    end
    if remoteFolder then
        remoteFolder:Destroy()
    end
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = replicatedStorage
    return remoteFolder
end

function Controller:_resolveSpectatorRemote()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remoteFolder = ensureRemoteFolder(replicatedStorage)
    local remote = remoteFolder:FindFirstChild("SpectatorEvidence")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    if remote then
        remote:Destroy()
    end
    remote = Instance.new("RemoteEvent")
    remote.Name = "SpectatorEvidence"
    remote.Parent = remoteFolder
    return remote
end

function Controller:Init()
    self._spectatorRemote = self:_resolveSpectatorRemote()
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    self:_subscribe("MatchStarted", function(payload)
        self:OnMatchStarted(payload)
    end)
    self:_subscribe("PlayerKilled", function(payload)
        self:OnPlayerKilled(payload)
    end)
    self:_subscribe("GhostRoamed", function(payload)
        self:OnGhostRoamed(payload)
    end)
    self:_subscribe("GhostInteraction", function(payload)
        self:OnGhostInteraction(payload)
    end)
    self:_subscribe("HuntStarted", function(payload)
        self:OnHuntStarted(payload)
    end)
    self:_subscribe("HuntEnded", function(payload)
        self:OnHuntEnded(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
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

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:StartMatch(matchId, payload)
end

function Controller:OnPlayerDied(payload)
    local matchId = payload and payload.matchId
    local player = payload and payload.player
    if not matchId or not player then
        return
    end
    self._service:EnterSpectator(player, matchId, payload)
end

function Controller:OnPlayerKilled(payload)
    local matchId = payload and payload.matchId
    local player = payload and payload.player
    if not matchId or not player then
        return
    end

    self._service:EnterSpectator(player, matchId, payload)

    self._service:ProcessGhostActivity(matchId, {
        activityType = "player_killed",
        player = player,
        now = payload.now,
        room = payload.room,
    })
end

function Controller:OnGhostRoamed(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessGhostActivity(matchId, {
        activityType = "ghost_roamed",
        room = payload.room,
        now = payload.now,
    })
end


function Controller:OnEvidenceCollected(payload)
    local matchId = payload and payload.matchId
    if not matchId or not self._spectatorRemote then
        return
    end
    local spectators = self._service:GetSpectators(matchId)
    for _, spectator in pairs(spectators) do
        local distortion = self._service:DistortEvidence(payload)
        local target = spectator.player
        if typeof(target) == "Instance" and target:IsA("Player") then
            self._spectatorRemote:FireClient(target, distortion and distortion.payload or nil)
        end
    end
end

function Controller:OnGhostInteraction(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessGhostActivity(matchId, {
        activityType = "ghost_interaction",
        room = payload.room,
        interactionType = payload.interactionType,
        now = payload.now,
    })
end

function Controller:OnHuntStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessGhostActivity(matchId, {
        activityType = "hunt_started",
        now = payload.now,
    })
end

function Controller:OnHuntEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessGhostActivity(matchId, {
        activityType = "hunt_ended",
        now = payload.now,
    })
end

function Controller:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:ClearSpectators(matchId)
end

return Controller

