local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local MatchSystem = {}
MatchSystem.__index = MatchSystem

function MatchSystem.new(deps)
    local self = setmetatable({}, MatchSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function MatchSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function MatchSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function MatchSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function MatchSystem:Shutdown()
    self:Stop()
end

function MatchSystem:GetMatch(matchId)
    return self.Service:GetMatch(matchId)
end

function MatchSystem:GetLiveMatch(matchId)
    return self.Service:GetLiveMatch(matchId)
end

return MatchSystem
