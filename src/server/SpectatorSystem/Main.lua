local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local SpectatorSystem = {}
SpectatorSystem.__index = SpectatorSystem

function SpectatorSystem.new(deps)
    local self = setmetatable({}, SpectatorSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SpectatorSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function SpectatorSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function SpectatorSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return SpectatorSystem
