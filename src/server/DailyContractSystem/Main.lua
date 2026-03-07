local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local DailyContractSystem = {}
DailyContractSystem.__index = DailyContractSystem

function DailyContractSystem.new(deps)
    local self = setmetatable({}, DailyContractSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.DailyContractState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function DailyContractSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function DailyContractSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function DailyContractSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function DailyContractSystem:GetDailyContracts(playerOrUserId)
    return self.Service:GetDailyContracts(playerOrUserId)
end

return DailyContractSystem
