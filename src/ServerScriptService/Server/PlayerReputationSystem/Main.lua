local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local PlayerReputationSystem = {}
PlayerReputationSystem.__index = PlayerReputationSystem

function PlayerReputationSystem.new(deps)
    local self = setmetatable({}, PlayerReputationSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.PlayerReputationState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function PlayerReputationSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function PlayerReputationSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function PlayerReputationSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function PlayerReputationSystem:GetReputation(playerOrUserId)
    return self.Service:GetReputation(playerOrUserId)
end

return PlayerReputationSystem
