local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
        return eventBus.Service
    end
    return nil
end

local function resolveUserId(payload)
    if type(payload.userId) == "number" then
        return payload.userId
    end
    if type(payload.playerId) == "number" then
        return payload.playerId
    end
    local player = payload.player
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        LobbySocialHub = Services.Get(self._deps, "LobbySocialHub"),
        TeleportService = Services.Get(self._deps, "TeleportService"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
    }
end

function Service:Init()
    self._state:Set("recoverableSessions", self._state:Get("recoverableSessions") or {})
    self._state:Set("recoveredPlayers", self._state:Get("recoveredPlayers") or {})
end

function Service:Start()
    -- Event-driven.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:CreateRecoverableSession(userId, payload)
    if type(userId) ~= "number" then
        return false
    end

    local recoverableSessions = self._state:Get("recoverableSessions") or {}
    recoverableSessions[userId] = {
        userId = userId,
        matchId = payload.matchId,
        disconnectedAt = os.time(),
        investigationState = payload.investigationState,
        inventorySnapshot = payload.inventorySnapshot,
    }
    self._state:Set("recoverableSessions", recoverableSessions)

    self:_publish("SessionRecoveryStarted", {
        userId = userId,
        matchId = payload.matchId,
    })
    return true
end

function Service:RecoverSession(userId)
    local recoverableSessions = self._state:Get("recoverableSessions") or {}
    local session = recoverableSessions[userId]
    if type(session) ~= "table" then
        return false, "session_not_found"
    end

    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) == "table" then
        local target = persistence.Service or persistence
        if type(target.LoadInventory) == "function" then
            pcall(function()
                target:LoadInventory(userId)
            end)
        end
        if type(target.LoadProfile) == "function" then
            pcall(function()
                target:LoadProfile(userId)
            end)
        end
    end

    local recoveredPlayers = self._state:Get("recoveredPlayers") or {}
    recoveredPlayers[userId] = {
        recoveredAt = os.time(),
        matchId = session.matchId,
    }
    self._state:Set("recoveredPlayers", recoveredPlayers)

    recoverableSessions[userId] = nil
    self._state:Set("recoverableSessions", recoverableSessions)

    self:_publish("SessionRecovered", {
        userId = userId,
        matchId = session.matchId,
        investigationState = session.investigationState,
    })
    return true
end

function Service:OnPlayerDisconnected(payload)
    payload = payload or {}
    local userId = resolveUserId(payload)
    if not userId then
        return
    end

    self:CreateRecoverableSession(userId, {
        matchId = payload.matchId,
        investigationState = payload.investigationState,
        inventorySnapshot = payload.inventorySnapshot,
    })
end

function Service:OnPlayerJoinedLobby(payload)
    payload = payload or {}
    local userId = resolveUserId(payload)
    if not userId then
        return
    end
    self:RecoverSession(userId)
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if type(matchId) ~= "string" then
        return
    end

    local recoverableSessions = self._state:Get("recoverableSessions") or {}
    for userId, session in pairs(recoverableSessions) do
        if session.matchId == matchId then
            recoverableSessions[userId] = nil
        end
    end
    self._state:Set("recoverableSessions", recoverableSessions)
end

return Service
