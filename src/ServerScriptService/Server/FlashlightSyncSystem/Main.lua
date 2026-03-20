local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local FlashlightSyncSystem = {}
FlashlightSyncSystem.__index = FlashlightSyncSystem

function FlashlightSyncSystem.new(deps)
    local self = setmetatable({}, FlashlightSyncSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function FlashlightSyncSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function FlashlightSyncSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function FlashlightSyncSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return FlashlightSyncSystem
