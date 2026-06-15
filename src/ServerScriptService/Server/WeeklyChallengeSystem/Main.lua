local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)
local Services = require(script.Parent.Parent.Core.Services)

local WeeklyChallengeSystem = {}
WeeklyChallengeSystem.__index = WeeklyChallengeSystem

function WeeklyChallengeSystem.new(deps)
    local self = setmetatable({}, WeeklyChallengeSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.WeeklyChallengeState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function WeeklyChallengeSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function WeeklyChallengeSystem:Start()
    self.Controller:Start()
    self.Service:Start()
    local dailyEngagementSystem = Services.Get(self._deps, "DailyEngagementSystem")
    if type(dailyEngagementSystem) == "table" and type(dailyEngagementSystem.RefreshAllQuestRuntime) == "function" then
        dailyEngagementSystem:RefreshAllQuestRuntime()
    end
end

function WeeklyChallengeSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function WeeklyChallengeSystem:GetWeeklyChallenges(playerOrUserId)
    return self.Service:GetWeeklyChallenges(playerOrUserId)
end

function WeeklyChallengeSystem:GetWeeklyChallengeSnapshot(playerOrUserId)
    return self.Service:GetWeeklyChallengeSnapshot(playerOrUserId)
end

return WeeklyChallengeSystem
