local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local HorrorDirector = {}
HorrorDirector.__index = HorrorDirector

function HorrorDirector.new(deps)
    local self = setmetatable({}, HorrorDirector)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function HorrorDirector:Init()
    self.Service:Init()
    self.Controller:Init()
end

function HorrorDirector:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function HorrorDirector:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function HorrorDirector:EvaluateTension(matchId, snapshot, now)
    return self.Service:EvaluateTension(matchId, snapshot, now)
end

function HorrorDirector:ScheduleEvent(matchId, reason, now)
    return self.Service:ScheduleEvent(matchId, reason, now)
end

function HorrorDirector:AdjustHuntProbability(matchId)
    return self.Service:AdjustHuntProbability(matchId)
end

return HorrorDirector
