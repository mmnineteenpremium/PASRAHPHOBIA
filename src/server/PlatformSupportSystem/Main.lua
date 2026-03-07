local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local PlatformSupportSystem = {}
PlatformSupportSystem.__index = PlatformSupportSystem

function PlatformSupportSystem.new(deps)
    local self = setmetatable({}, PlatformSupportSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.PlatformSupportState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function PlatformSupportSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function PlatformSupportSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function PlatformSupportSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return PlatformSupportSystem
