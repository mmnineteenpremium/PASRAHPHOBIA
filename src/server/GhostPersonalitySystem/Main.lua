local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local GhostPersonalitySystem = {}
GhostPersonalitySystem.__index = GhostPersonalitySystem

function GhostPersonalitySystem.new(deps)
    local self = setmetatable({}, GhostPersonalitySystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function GhostPersonalitySystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function GhostPersonalitySystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function GhostPersonalitySystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return GhostPersonalitySystem
