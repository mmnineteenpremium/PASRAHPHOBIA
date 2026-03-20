local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local LiveContentOpsSystem = {}
LiveContentOpsSystem.__index = LiveContentOpsSystem

function LiveContentOpsSystem.new(deps)
    local self = setmetatable({}, LiveContentOpsSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.LiveContentOpsState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function LiveContentOpsSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function LiveContentOpsSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function LiveContentOpsSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return LiveContentOpsSystem
