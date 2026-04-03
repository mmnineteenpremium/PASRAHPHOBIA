local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controller = {}
Controller.__index = Controller

local SANITY_REMOTE_NAME = "SanityEvent"

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
    self._sanityRemote = nil
    return self
end

function Controller:Init()
    self._sanityRemote = self:_resolveSanityRemote()
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    self:_subscribe("MatchStarted", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:StartMatch(matchId, payload and payload.players or {}, payload and payload.difficultyProfile)
        self:_sendInitialSanity(matchId, payload and payload.players or {})
    end)

    self:_subscribe("MatchEnded", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:EndMatch(matchId)
    end)

    self:_subscribe("HuntStarted", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:OnHuntStarted(matchId, payload)
    end)

    self:_subscribe("HuntEnded", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:OnHuntEnded(matchId)
    end)

    self:_subscribe("GhostManifested", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:ApplySnapshotDrain(matchId, 5)
    end)

    self:_subscribe("GhostRoaming", function(payload)
        local matchId = payload and payload.matchId
        if not matchId then
            return
        end
        self._service:OnGhostEvent(matchId, "Roaming")
    end)

    self:_subscribe("PlayerDied", function(payload)
        local matchId = payload and payload.matchId
        local playerId = payload and (payload.userId or payload.playerId)
        if not matchId or not playerId then
            return
        end
        self._service:RemovePlayer(matchId, playerId)
    end)

    self:_subscribe("SanityChanged", function(payload)
        self:_sendSanityUpdate(payload)
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

function Controller:Shutdown()
    self:UnregisterEventHandlers()
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:_resolveSanityRemote()
    local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end
    local remote = remoteFolder:FindFirstChild(SANITY_REMOTE_NAME)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

function Controller:_resolvePlayer(playerOrUserId)
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId
    end
    if type(playerOrUserId) == "number" then
        local ok, player = pcall(function()
            return Players:GetPlayerByUserId(playerOrUserId)
        end)
        if ok then
            return player
        end
    end
    return nil
end

function Controller:_sendSanityUpdate(payload)
    if not self._sanityRemote or type(payload) ~= "table" then
        return
    end
    local player = self:_resolvePlayer(payload.player or payload.userId)
    if not player then
        return
    end
    self._sanityRemote:FireClient(player, {
        matchId = payload.matchId,
        userId = payload.userId or player.UserId,
        newSanity = payload.newSanity,
        oldSanity = payload.oldSanity,
        sanity = payload.newSanity,
        sanityBand = payload.sanityBand,
        reason = payload.reason,
        source = "SanitySystem",
    })
end

function Controller:_sendInitialSanity(matchId, players)
    if not self._sanityRemote then
        return
    end
    for _, entry in ipairs(players or {}) do
        local player = self:_resolvePlayer(entry)
        if player then
            self._sanityRemote:FireClient(player, {
                matchId = matchId,
                userId = player.UserId,
                newSanity = self._service:GetSanity(player, matchId),
                sanity = self._service:GetSanity(player, matchId),
                sanityBand = "Stable",
                reason = "match_started",
                source = "SanitySystem",
            })
        end
    end
end

return Controller
