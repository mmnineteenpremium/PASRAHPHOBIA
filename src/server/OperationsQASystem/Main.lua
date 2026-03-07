local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local OperationsQASystem = {}
OperationsQASystem.__index = OperationsQASystem

function OperationsQASystem.new(deps)
    local self = setmetatable({}, OperationsQASystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.OperationsQAState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function OperationsQASystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function OperationsQASystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function OperationsQASystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return OperationsQASystem
