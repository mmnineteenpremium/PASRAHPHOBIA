local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local AggressionSystem = {}
AggressionSystem.__index = AggressionSystem

function AggressionSystem.new(deps)
    local self = setmetatable({}, AggressionSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function AggressionSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function AggressionSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function AggressionSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function AggressionSystem:IncreaseAggression(matchId, amount, reason, metadata)
    return self.Service:IncreaseAggression(matchId, amount, reason, metadata)
end

function AggressionSystem:GetAggressionLevel(matchId)
    return self.Service:GetAggressionLevel(matchId)
end

function AggressionSystem:CheckHuntTrigger(matchId, payload)
    return self.Service:CheckHuntTrigger(matchId, payload)
end

return AggressionSystem
