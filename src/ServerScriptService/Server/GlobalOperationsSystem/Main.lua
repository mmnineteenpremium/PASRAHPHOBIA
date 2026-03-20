local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local GlobalOperationsSystem = {}
GlobalOperationsSystem.__index = GlobalOperationsSystem

function GlobalOperationsSystem.new(deps)
    local self = setmetatable({}, GlobalOperationsSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.GlobalOperationsState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function GlobalOperationsSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function GlobalOperationsSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function GlobalOperationsSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function GlobalOperationsSystem:EvaluateReleaseReadiness()
    return self.Service:EvaluateReleaseReadiness()
end

return GlobalOperationsSystem
