local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ContractConfigSystem = {}
ContractConfigSystem.__index = ContractConfigSystem

function ContractConfigSystem.new(deps)
    local self = setmetatable({}, ContractConfigSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ContractConfigSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ContractConfigSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function ContractConfigSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function ContractConfigSystem:GetContractConfigs()
    return self.Service:GetContractConfigs()
end

function ContractConfigSystem:GetContractConfig(contractId)
    return self.Service:GetContractConfig(contractId)
end

return ContractConfigSystem
