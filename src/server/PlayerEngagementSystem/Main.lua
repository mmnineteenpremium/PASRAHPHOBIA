local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local PlayerEngagementSystem = {}
PlayerEngagementSystem.__index = PlayerEngagementSystem

function PlayerEngagementSystem.new(deps)
    local self = setmetatable({}, PlayerEngagementSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.PlayerEngagementState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function PlayerEngagementSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function PlayerEngagementSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function PlayerEngagementSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return PlayerEngagementSystem
