local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local MatchRewards = {}
MatchRewards.__index = MatchRewards

function MatchRewards.new(deps)
    local self = setmetatable({}, MatchRewards)
    self._deps = deps or {}
    self.State = State.new(self._deps.MatchRewardState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function MatchRewards:Init()
    self.Service:Init()
    self.Controller:RegisterEventHandlers()
end

function MatchRewards:Start()
    self.Service:Start()
end

function MatchRewards:Stop()
    self.Controller:UnregisterEventHandlers()
end

return MatchRewards
