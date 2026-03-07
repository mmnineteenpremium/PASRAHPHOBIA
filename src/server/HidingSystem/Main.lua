local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local HidingSystem = {}
HidingSystem.__index = HidingSystem

function HidingSystem.new(deps)
    local self = setmetatable({}, HidingSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function HidingSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function HidingSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function HidingSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return HidingSystem
