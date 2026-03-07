local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local SpectatorCameraSystem = {}
SpectatorCameraSystem.__index = SpectatorCameraSystem

function SpectatorCameraSystem.new(deps)
    local self = setmetatable({}, SpectatorCameraSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SpectatorCameraSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function SpectatorCameraSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function SpectatorCameraSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return SpectatorCameraSystem
