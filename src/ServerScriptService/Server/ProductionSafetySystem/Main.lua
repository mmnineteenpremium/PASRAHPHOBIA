local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ProductionSafetySystem = {}
ProductionSafetySystem.__index = ProductionSafetySystem

function ProductionSafetySystem.new(deps)
    local self = setmetatable({}, ProductionSafetySystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ProductionSafetySystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ProductionSafetySystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ProductionSafetySystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return ProductionSafetySystem
