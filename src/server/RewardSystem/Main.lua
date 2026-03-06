local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local RewardSystem = {}
RewardSystem.__index = RewardSystem

function RewardSystem.new(deps)
    local self = setmetatable({}, RewardSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.RewardState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function RewardSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function RewardSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function RewardSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return RewardSystem
