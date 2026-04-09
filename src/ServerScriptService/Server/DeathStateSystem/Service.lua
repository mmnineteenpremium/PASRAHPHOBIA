local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Service = {}
Service.__index = Service
local TELEPORT_DEATH_GRACE_SECONDS = 3
local PLAYER_DIED_DEBOUNCE_SECONDS = 1
local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then return nil end
    if type(eventBus.Publish) == "function" then return eventBus end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then return eventBus.Service end
    return nil
end
local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then return playerOrUserId end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then return playerOrUserId.UserId end
    return nil
end
local function resolvePlayerFromPayload(payload)
    if type(payload) ~= "table" then
        return nil
    end
    local player = payload.player
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player
    end
    local userId = toUserId(payload.userId)
    if type(userId) == "number" then
        return Players:GetPlayerByUserId(userId)
    end
    return nil
end
local function isProtectedInMatch(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false
    end
    local protectUntil = player:GetAttribute("SpawnProtectedUntil")
    if type(protectUntil) == "number" and protectUntil > os.clock() then
        return true
    end
    return player:GetAttribute("SpawnProtected") == true
end
local function applySpawnProtection(player, duration)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end
    local seconds = tonumber(duration) or TELEPORT_DEATH_GRACE_SECONDS
    local protectUntil = os.clock() + seconds
    player:SetAttribute("SpawnProtected", true)
    player:SetAttribute("SpawnProtectedUntil", protectUntil)
    task.delay(seconds, function()
        if not player.Parent then
            return
        end
        local currentUntil = player:GetAttribute("SpawnProtectedUntil")
        if type(currentUntil) == "number" and currentUntil > os.clock() then
            return
        end
        player:SetAttribute("SpawnProtected", nil)
        player:SetAttribute("SpawnProtectedUntil", nil)
    end)
end
local function resolveMatchSystem(deps)
    local matchSystem = Services.Get(deps, "MatchSystem")
    if type(matchSystem) ~= "table" then
        return nil
    end
    if type(matchSystem.GetLiveMatch) == "function" then
        return matchSystem
    end
    if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
        return matchSystem.Service
    end
    return nil
end
local function resolveMatchRemote()
    local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end
    local remote = remoteFolder:FindFirstChild("MatchEvent")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end
local function resolveLiveMatch(matchSystem, matchId)
    if type(matchSystem) ~= "table" or type(matchSystem.GetLiveMatch) ~= "function" or type(matchId) ~= "string" then
        return nil
    end
    local ok, result = pcall(function()
        return matchSystem:GetLiveMatch(matchId)
    end)
    if ok and type(result) == "table" then
        return result
    end
    return nil
end
local function resolveMatchPlayers(match)
    local players = {}
    for _, player in ipairs(type(match) == "table" and match.players or {}) do
        if typeof(player) == "Instance" and player:IsA("Player") then
            table.insert(players, player)
        end
    end
    if #players > 0 then
        return players
    end
    for _, playerState in pairs(type(match) == "table" and match.playersByUserId or {}) do
        local player = type(playerState) == "table" and playerState.player or nil
        if typeof(player) == "Instance" and player:IsA("Player") then
            table.insert(players, player)
        end
    end
    return players
end
local function chooseSpectatorTargetPlayer(match, deadUserId)
    local fallbackPlayer = nil
    for userId, playerState in pairs(type(match) == "table" and match.playersByUserId or {}) do
        local numericUserId = tonumber(userId)
        local player = type(playerState) == "table" and playerState.player or nil
        if numericUserId and numericUserId ~= deadUserId and typeof(player) == "Instance" and player:IsA("Player") then
            if fallbackPlayer == nil then
                fallbackPlayer = player
            end
            if playerState.alive ~= false then
                return player
            end
        end
    end
    return fallbackPlayer
end
local function stampDeathRuntime(target, payload)
    if typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end
    target:SetAttribute("PasrahDeathOwner", "DeathStateSystem")
    target:SetAttribute("PasrahDeathMatchId", type(payload.matchId) == "string" and payload.matchId or nil)
    target:SetAttribute("PasrahDeathState", type(payload.state) == "string" and payload.state or nil)
    target:SetAttribute("PasrahDeathReason", type(payload.reason) == "string" and payload.reason or nil)
    target:SetAttribute("PasrahDeathLastEvent", type(payload.lastEvent) == "string" and payload.lastEvent or nil)
    target:SetAttribute("PasrahDeathSpectatorTargetUserId", tonumber(payload.targetUserId))
    target:SetAttribute("PasrahDeathSpectatorTargetName", type(payload.targetName) == "string" and payload.targetName or nil)
    target:SetAttribute("PasrahDeathAt", type(payload.deathAt) == "number" and payload.deathAt or nil)
    target:SetAttribute("PasrahDeathActive", payload.active == true)
end
local function clearDeathRuntime(target)
    if typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end
    target:SetAttribute("PasrahDeathOwner", nil)
    target:SetAttribute("PasrahDeathMatchId", nil)
    target:SetAttribute("PasrahDeathState", nil)
    target:SetAttribute("PasrahDeathReason", nil)
    target:SetAttribute("PasrahDeathLastEvent", nil)
    target:SetAttribute("PasrahDeathSpectatorTargetUserId", nil)
    target:SetAttribute("PasrahDeathSpectatorTargetName", nil)
    target:SetAttribute("PasrahDeathAt", nil)
    target:SetAttribute("PasrahDeathActive", nil)
end
function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    self._matchRemote = resolveMatchRemote()
    return self
end
function Service:Init()
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
        MatchSystem = resolveMatchSystem(self._deps),
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
    }
    self._deps.SpectatorModeSystem = Services.Get(self._deps, "SpectatorModeSystem")
end
function Service:Start() end
function Service:Stop() self._state:Clear() end
function Service:_publish(eventName, payload)
    if self._eventBus then self._eventBus:Publish(eventName, payload) end
end
function Service:_fireMatchEventToPlayers(players, payloadBuilder)
    local remote = self._matchRemote
    if not remote then
        remote = resolveMatchRemote()
        self._matchRemote = remote
    end
    if not remote then
        return
    end
    for _, player in ipairs(players or {}) do
        if typeof(player) == "Instance" and player:IsA("Player") then
            local payload = type(payloadBuilder) == "function" and payloadBuilder(player) or payloadBuilder
            if type(payload) == "table" then
                remote:FireClient(player, payload)
            end
        end
    end
end
function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        self._state:Set("activeMatchId", payload and payload.matchId)
        if type(payload) == "table" and type(payload.players) == "table" then
            for _, player in ipairs(payload.players) do
                applySpawnProtection(player, TELEPORT_DEATH_GRACE_SECONDS)
                clearDeathRuntime(player)
            end
        end
    elseif eventName == "MatchEnded" then self._state:Set("activeMatchId", nil) end
    if eventName == "MatchStarted" then
        self._state:Set("deathStateByPlayer", {})
        self._state:Set("lastDeathEventAtByPlayer", {})
    elseif eventName == "MatchEnded" then
        if type(payload) == "table" and type(payload.players) == "table" then
            for _, player in ipairs(payload.players) do
                clearDeathRuntime(player)
            end
        end
    elseif eventName == "PlayerDied" then
        local matchId = payload and payload.matchId or self._state:Get("activeMatchId")
        if type(matchId) ~= "string" then
            return
        end
        local resolvedPlayer = resolvePlayerFromPayload(payload)
        if isProtectedInMatch(resolvedPlayer) then
            return
        end
        local userId = toUserId(payload and (resolvedPlayer or payload.userId))
        if not userId then
            return
        end
        local states = self._state:Get("deathStateByPlayer") or {}
        if states[userId] == "Dead" then
            return
        end
        local lastDeathEventAtByPlayer = self._state:Get("lastDeathEventAtByPlayer") or {}
        local now = os.clock()
        local lastAt = lastDeathEventAtByPlayer[userId]
        if type(lastAt) == "number" and (now - lastAt) < PLAYER_DIED_DEBOUNCE_SECONDS then
            return
        end
        lastDeathEventAtByPlayer[userId] = now
        self._state:Set("lastDeathEventAtByPlayer", lastDeathEventAtByPlayer)
        local spectatorSystem = self._deps.SpectatorModeSystem
        if spectatorSystem and spectatorSystem.Service then
            spectatorSystem.Service:HandleEvent("PlayerDied", {
                matchId = matchId,
                userId = userId,
                player = resolvedPlayer or payload.player,
                reason = payload and payload.reason,
            })
        end
        local liveMatch = resolveLiveMatch(self._dependencies.MatchSystem, matchId)
        local targetPlayer = chooseSpectatorTargetPlayer(liveMatch, userId)
        stampDeathRuntime(resolvedPlayer or payload.player, {
            matchId = matchId,
            state = "Dead",
            reason = payload and payload.reason or "unknown",
            lastEvent = "PlayerKilled",
            targetUserId = targetPlayer and targetPlayer.UserId or nil,
            targetName = targetPlayer and targetPlayer.Name or nil,
            deathAt = now,
            active = true,
        })
        self:_fireMatchEventToPlayers(resolveMatchPlayers(liveMatch), function(recipient)
            return {
                eventName = "PlayerKilled",
                matchId = matchId,
                userId = userId,
                player = resolvedPlayer or payload.player,
                reason = payload and payload.reason or "unknown",
                source = "DeathStateSystem",
                localPlayerKilled = recipient.UserId == userId,
                targetPlayer = targetPlayer,
                targetUserId = targetPlayer and targetPlayer.UserId or nil,
            }
        end)
        states[userId] = "Dead"
        self._state:Set("deathStateByPlayer", states)
        self:_publish("DeathStateChanged", { userId = userId, player = resolvedPlayer or payload.player, state = "Dead", matchId = matchId })
    elseif eventName == "PlayerRespawnRequested" then
        local matchId = payload and payload.matchId or self._state:Get("activeMatchId")
        if type(matchId) ~= "string" then
            return
        end
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local states = self._state:Get("deathStateByPlayer") or {}
            states[userId] = "RespawnRequested"
            self._state:Set("deathStateByPlayer", states)
            clearDeathRuntime(payload and payload.player or Players:GetPlayerByUserId(userId))
            self:_publish("DeathStateChanged", { userId = userId, player = payload.player, state = "RespawnRequested", matchId = matchId })
        end
    end
end
return Service

