local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)
local Services = require(script.Parent.Parent.Core.Services)

local StoryMissionSystem = {}
StoryMissionSystem.__index = StoryMissionSystem

function StoryMissionSystem.new(deps)
    local self = setmetatable({}, StoryMissionSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.StoryMissionState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function StoryMissionSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function StoryMissionSystem:Start()
    self.Controller:Start()
    self.Service:Start()
    local dailyEngagementSystem = Services.Get(self._deps, "DailyEngagementSystem")
    if type(dailyEngagementSystem) == "table" and type(dailyEngagementSystem.RefreshAllQuestRuntime) == "function" then
        dailyEngagementSystem:RefreshAllQuestRuntime()
    end
end

function StoryMissionSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function StoryMissionSystem:GetStoryMissions(playerOrUserId)
    return self.Service:GetStoryMissions(playerOrUserId)
end

function StoryMissionSystem:GetStorySnapshot(playerOrUserId)
    return self.Service:GetStorySnapshot(playerOrUserId)
end

return StoryMissionSystem
