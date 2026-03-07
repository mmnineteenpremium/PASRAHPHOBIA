local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local RuntimeIntegritySystem = {}
RuntimeIntegritySystem.__index = RuntimeIntegritySystem

function RuntimeIntegritySystem.new(deps)
    local self = setmetatable({}, RuntimeIntegritySystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function RuntimeIntegritySystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function RuntimeIntegritySystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function RuntimeIntegritySystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return RuntimeIntegritySystem
