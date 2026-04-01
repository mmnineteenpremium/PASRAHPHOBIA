local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)
local DeathEventBridge = require(script.Parent.DeathEventBridge)

local DeathStateSystem = {}
DeathStateSystem.__index = DeathStateSystem

function DeathStateSystem.new(deps)
    local self = setmetatable({}, DeathStateSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    self._deathEventBridgeStarted = false
    return self
end

function DeathStateSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function DeathStateSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
    if not self._deathEventBridgeStarted then
        DeathEventBridge.Start(self.Service)
        self._deathEventBridgeStarted = true
    end
end

function DeathStateSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return DeathStateSystem
