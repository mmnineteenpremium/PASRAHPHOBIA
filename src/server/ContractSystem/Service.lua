local ContractService = require(script.Parent.ContractService)

local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._contractService = ContractService.new(self._state, self._deps)
    return self
end

function Service:Init()
    self._contractService:Init()
end

function Service:Start()
    self._contractService:Start()
end

function Service:Stop()
    self._contractService:Stop()
end

function Service:GenerateBoard(lobbyId, count, payload)
    return self._contractService:GenerateBoard(lobbyId, count, payload)
end

function Service:GetBoardContracts(lobbyId)
    return self._contractService:GetBoardContracts(lobbyId)
end

function Service:SelectContract(partyId, contractId, selector)
    return self._contractService:SelectContract(partyId, contractId, selector)
end

function Service:BindMatchFromParties(matchId, partyIds)
    return self._contractService:BindMatchFromParties(matchId, partyIds)
end

function Service:StartMatchSession(matchId, payload)
    return self._contractService:StartMatchSession(matchId, payload)
end

function Service:EndMatchSession(matchId, payload)
    return self._contractService:EndMatchSession(matchId, payload)
end

function Service:ProcessSignal(matchId, signalType, payload)
    return self._contractService:ProcessSignal(matchId, signalType, payload)
end

function Service:SetGhostRoom(matchId, roomId)
    self._contractService:SetGhostRoom(matchId, roomId)
end

return Service
