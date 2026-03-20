local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local DynamicInvestigationEventSystem = {}
DynamicInvestigationEventSystem.__index = DynamicInvestigationEventSystem

function DynamicInvestigationEventSystem.new(deps)
    local self = setmetatable({}, DynamicInvestigationEventSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.DynamicInvestigationEventState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function DynamicInvestigationEventSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function DynamicInvestigationEventSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function DynamicInvestigationEventSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return DynamicInvestigationEventSystem
