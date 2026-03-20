local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local EscalationTimerSystem = {}
EscalationTimerSystem.__index = EscalationTimerSystem

function EscalationTimerSystem.new(deps)
    local self = setmetatable({}, EscalationTimerSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function EscalationTimerSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function EscalationTimerSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function EscalationTimerSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return EscalationTimerSystem
