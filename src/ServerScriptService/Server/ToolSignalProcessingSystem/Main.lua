local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ToolSignalProcessingSystem = {}
ToolSignalProcessingSystem.__index = ToolSignalProcessingSystem

function ToolSignalProcessingSystem.new(deps)
    local self = setmetatable({}, ToolSignalProcessingSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ToolSignalProcessingSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ToolSignalProcessingSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ToolSignalProcessingSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return ToolSignalProcessingSystem
