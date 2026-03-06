local LobbyService = require(script.Parent.LobbyService)

local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._lobbyService = LobbyService.new(self._state, self._deps)
    return self
end

function Service:Init()
    self._lobbyService:Init()
end

function Service:Start()
    self._lobbyService:Start()
end

function Service:Stop()
    self._lobbyService:Stop()
end

function Service:RegisterPlayer(player)
    return self._lobbyService:RegisterPlayer(player)
end

function Service:RemovePlayer(player)
    return self._lobbyService:RemovePlayer(player)
end

function Service:GetLobbyPlayers()
    return self._lobbyService:GetLobbyPlayers()
end

function Service:CreateParty(player)
    return self._lobbyService:CreateParty(player)
end

function Service:InvitePlayer(partyId, player)
    return self._lobbyService:InvitePlayer(partyId, player)
end

function Service:DisbandParty(partyId)
    return self._lobbyService:DisbandParty(partyId)
end

function Service:PrepareGroupMatchmaking(player)
    return self._lobbyService:PrepareGroupMatchmaking(player)
end

function Service:OnPlayerEnteredZone(player, zoneName)
    self._lobbyService:OnPlayerEnteredZone(player, zoneName)
end

function Service:HandlePlayerTeleported(payload)
    self._lobbyService:HandlePlayerTeleported(payload)
end

function Service:ApplyCosmetic(player, cosmeticId, category)
    return self._lobbyService:ApplyCosmetic(player, cosmeticId, category)
end

return Service

