local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local MatchmakingQualitySystem = {}
MatchmakingQualitySystem.__index = MatchmakingQualitySystem

function MatchmakingQualitySystem.new(deps)
    local self = setmetatable({}, MatchmakingQualitySystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.MatchmakingQualityState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function MatchmakingQualitySystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function MatchmakingQualitySystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function MatchmakingQualitySystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return MatchmakingQualitySystem
