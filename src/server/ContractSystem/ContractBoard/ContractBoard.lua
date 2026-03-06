local ContractBoard = {}
ContractBoard.__index = ContractBoard

function ContractBoard.new()
    local self = setmetatable({}, ContractBoard)
    self._boardByLobby = {}
    return self
end

function ContractBoard:SetContracts(lobbyId, contracts)
    self._boardByLobby[lobbyId or "lobby_main"] = contracts or {}
end

function ContractBoard:GetContracts(lobbyId)
    return self._boardByLobby[lobbyId or "lobby_main"] or {}
end

function ContractBoard:SelectContract(lobbyId, contractId)
    for _, contract in ipairs(self:GetContracts(lobbyId)) do
        if contract.contractId == contractId then
            return contract
        end
    end
    return nil
end

return ContractBoard
