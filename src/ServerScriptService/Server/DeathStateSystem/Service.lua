local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")
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
function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    return self
end
function Service:Init()
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
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
function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        self._state:Set("activeMatchId", payload and payload.matchId)
        if type(payload) == "table" and type(payload.players) == "table" then
            for _, player in ipairs(payload.players) do
                applySpawnProtection(player, TELEPORT_DEATH_GRACE_SECONDS)
            end
        end
    elseif eventName == "MatchEnded" then self._state:Set("activeMatchId", nil) end
    if eventName == "MatchStarted" then
        self._state:Set("deathStateByPlayer", {})
        self._state:Set("lastDeathEventAtByPlayer", {})
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
            self:_publish("DeathStateChanged", { userId = userId, player = payload.player, state = "RespawnRequested", matchId = matchId })
        end
    end
end
return Service

