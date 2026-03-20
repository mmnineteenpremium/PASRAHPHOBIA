local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ContractSystem = {}
ContractSystem.__index = ContractSystem

function ContractSystem.new(deps)
    local self = setmetatable({}, ContractSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ContractSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ContractSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ContractSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function ContractSystem:GetBoardContracts(lobbyId)
    return self.Service:GetBoardContracts(lobbyId)
end

function ContractSystem:SelectContract(partyId, contractId, selector)
    return self.Service:SelectContract(partyId, contractId, selector)
end

return ContractSystem
