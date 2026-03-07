local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local PlayerDeathSystem = {}
PlayerDeathSystem.__index = PlayerDeathSystem

function PlayerDeathSystem.new(deps)
    local self = setmetatable({}, PlayerDeathSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function PlayerDeathSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function PlayerDeathSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function PlayerDeathSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return PlayerDeathSystem
