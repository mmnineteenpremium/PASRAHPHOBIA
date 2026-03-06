local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local DailyCheckIn = {}
DailyCheckIn.__index = DailyCheckIn

function DailyCheckIn.new(deps)
    local self = setmetatable({}, DailyCheckIn)
    self._deps = deps or {}
    self.State = State.new(self._deps.DailyCheckInState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function DailyCheckIn:Init()
    self.Service:Init()
    self.Controller:Init()
end

function DailyCheckIn:Start()
    self.Service:Start()
end

function DailyCheckIn:Stop()
    self.Service:Stop()
end

return DailyCheckIn
