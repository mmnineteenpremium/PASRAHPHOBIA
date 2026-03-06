local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ProgressionSystem = {}
ProgressionSystem.__index = ProgressionSystem

function ProgressionSystem.new(deps)
    local self = setmetatable({}, ProgressionSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.ProgressionState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ProgressionSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ProgressionSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ProgressionSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return ProgressionSystem
