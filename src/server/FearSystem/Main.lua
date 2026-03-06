local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local FearSystem = {}
FearSystem.__index = FearSystem

function FearSystem.new(deps)
    local self = setmetatable({}, FearSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function FearSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function FearSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function FearSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function FearSystem:GetFearLevel(matchId)
    return self.Service:GetFearLevel(matchId)
end

function FearSystem:GetGlobalFearLevel()
    return self.Service:GetGlobalFearLevel()
end

return FearSystem
