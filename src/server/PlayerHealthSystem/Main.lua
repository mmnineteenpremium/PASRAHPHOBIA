local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local PlayerHealthSystem = {}
PlayerHealthSystem.__index = PlayerHealthSystem

function PlayerHealthSystem.new(deps)
    local self = setmetatable({}, PlayerHealthSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function PlayerHealthSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function PlayerHealthSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function PlayerHealthSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return PlayerHealthSystem
