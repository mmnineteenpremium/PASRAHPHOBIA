local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local SeasonalEventSystem = {}
SeasonalEventSystem.__index = SeasonalEventSystem

function SeasonalEventSystem.new(deps)
    local self = setmetatable({}, SeasonalEventSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.SeasonalEventState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SeasonalEventSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function SeasonalEventSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function SeasonalEventSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function SeasonalEventSystem:GetActiveEvent()
    return self.Service:GetActiveEvent()
end

function SeasonalEventSystem:GetEventMapPool()
    return self.Service:GetEventMapPool()
end

return SeasonalEventSystem
