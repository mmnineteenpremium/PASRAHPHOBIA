local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ModerationOperationsSystem = {}
ModerationOperationsSystem.__index = ModerationOperationsSystem

function ModerationOperationsSystem.new(deps)
    local self = setmetatable({}, ModerationOperationsSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.ModerationOperationsState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ModerationOperationsSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ModerationOperationsSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function ModerationOperationsSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return ModerationOperationsSystem
