local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local DailyMissions = {}
DailyMissions.__index = DailyMissions

function DailyMissions.new(deps)
    local self = setmetatable({}, DailyMissions)
    self._deps = deps or {}
    self.State = State.new(self._deps.DailyMissionState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function DailyMissions:Init()
    self.Service:Init()
    self.Controller:Init()
end

function DailyMissions:Start()
    self.Service:Start()
end

function DailyMissions:Stop()
    self.Service:Stop()
end

return DailyMissions
