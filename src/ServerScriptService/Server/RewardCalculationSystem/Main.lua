local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local RewardCalculationSystem = {}
RewardCalculationSystem.__index = RewardCalculationSystem

function RewardCalculationSystem.new(deps)
    local self = setmetatable({}, RewardCalculationSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function RewardCalculationSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function RewardCalculationSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function RewardCalculationSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return RewardCalculationSystem
