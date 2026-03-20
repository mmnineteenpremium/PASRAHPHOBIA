local LobbyPlayerManager = require(script.Parent.LobbyPlayerManager)
local LobbyZoneManager = require(script.Parent.LobbyZoneManager)
local LobbyInteraction = require(script.Parent.LobbyInteraction)
local PartySystem = require(script.Parent.PartySystem)
local LobbyPopulationController = require(script.Parent.LobbyPopulationController)

local LobbyService = {}
LobbyService.__index = LobbyService

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

function LobbyService.new(state, deps)
    local self = setmetatable({}, LobbyService)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)

    self._playerManager = LobbyPlayerManager.new(self._deps, self._deps.LobbyPlayerManagerConfig)
    self._zoneManager = LobbyZoneManager.new(self._deps, self._deps.LobbyZoneManagerConfig)
    self._interaction = LobbyInteraction.new(self._deps, self._deps.LobbyInteractionConfig)
    self._partySystem = PartySystem.new(self._deps, self._deps.PartySystemConfig)
    self._population = LobbyPopulationController.new(self._state, self._deps, self._deps.LobbyPopulationConfig)
    return self
end

function LobbyService:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function LobbyService:_refreshPopulation()
    local playerCount = self._playerManager:GetLobbyPlayerCount()
    self._population:OnLobbyPlayerCountChanged(playerCount)
end

function LobbyService:Init()
    self._state:Set("lobbyStatus", "initialized")
    self._playerManager:Init()
    self._zoneManager:Init()
    self._interaction:Init()
    self._partySystem:Init()
    self._population:Init()

    self._zoneManager:SetZoneEnteredCallback(function(player, zoneName)
        self:OnPlayerEnteredZone(player, zoneName)
    end)
    self._partySystem:SetCallbacks({
        onPlayerJoinedParty = function(player, party)
            self:_publish("PlayerJoinedParty", {
                player = player,
                partyId = party.partyId,
                leader = party.leader,
                members = party.members,
            })
        end,
    })
end

function LobbyService:Start()
    self._state:Set("lobbyStatus", "running")
    self._playerManager:Start()
    self._zoneManager:Start()
    self._interaction:Start()
    self._partySystem:Start()
    self._population:Start()
end

function LobbyService:Stop()
    self._state:Set("lobbyStatus", "stopped")
    self._zoneManager:Stop()
    self._interaction:Stop()
    self._partySystem:Stop()
    self._playerManager:Stop()
    self._population:Stop()
end

function LobbyService:RegisterPlayer(player)
    local alreadyInLobby = self._playerManager:IsInLobby(player)
    local ok, reason = self._playerManager:RegisterPlayer(player)
    if not ok then
        return false, reason
    end
    if alreadyInLobby then
        return true
    end

    self:_publish("PlayerEnteredLobby", {
        player = player,
    })
    self:_refreshPopulation()
    return true
end

function LobbyService:RemovePlayer(player)
    if not self._playerManager:IsInLobby(player) then
        return true
    end

    local ok, reason = self._playerManager:RemovePlayer(player)
    if not ok then
        return false, reason
    end

    self._partySystem:LeaveParty(player)
    self:_refreshPopulation()
    return true
end

function LobbyService:GetLobbyPlayers()
    return self._playerManager:GetLobbyPlayers()
end

function LobbyService:CreateParty(player)
    return self._partySystem:CreateParty(player)
end

function LobbyService:InvitePlayer(partyId, player)
    return self._partySystem:InvitePlayer(partyId, player)
end

function LobbyService:DisbandParty(partyId)
    return self._partySystem:DisbandParty(partyId)
end

function LobbyService:PrepareGroupMatchmaking(player)
    return self._partySystem:PrepareGroupMatchmaking(player)
end

function LobbyService:StartMatchmaking(player, payload)
    local matchmakingPackage, reason = self._partySystem:PrepareGroupMatchmaking(player)
    if not matchmakingPackage then
        return false, reason
    end

    self:_publish("MatchmakingStarted", {
        partyId = matchmakingPackage.partyId,
        leader = matchmakingPackage.leader,
        players = matchmakingPackage.players,
        queueType = matchmakingPackage.queueType,
        mapId = payload and payload.mapId or nil,
        difficulty = payload and payload.difficulty or nil,
        mode = payload and (payload.mode or payload.gameMode) or "Classic",
        gameMode = payload and (payload.gameMode or payload.mode) or "Classic",
        averageMMR = payload and payload.averageMMR or nil,
        playerMMRs = payload and payload.playerMMRs or nil,
        rankedDifficulty = payload and payload.rankedDifficulty or nil,
    })
    return true
end

function LobbyService:OnPlayerEnteredZone(player, zoneName)
    if not self._playerManager:IsInLobby(player) then
        return
    end

    self._interaction:HandleZoneEntry(player, zoneName)

    if zoneName == "MatchmakingZone" then
        self:_publish("PlayerEnteredMatchmaking", {
            player = player,
        })
        self:StartMatchmaking(player)
    end
end

function LobbyService:HandlePlayerTeleported(payload)
    local player = payload and payload.player
    local mapId = payload and payload.mapId
    if not player then
        return
    end

    if mapId == "Lobby" then
        self:RegisterPlayer(player)
    else
        self:RemovePlayer(player)
    end
end

function LobbyService:ApplyCosmetic(player, cosmeticId, category)
    self:_publish("LobbyCosmeticApplied", {
        player = player,
        cosmeticId = cosmeticId,
        category = category,
    })
    return true
end

return LobbyService
