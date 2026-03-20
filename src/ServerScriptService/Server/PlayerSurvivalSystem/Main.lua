local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local PlayerSurvivalSystem = {}
PlayerSurvivalSystem.__index = PlayerSurvivalSystem

function PlayerSurvivalSystem.new(deps)
    local self = setmetatable({}, PlayerSurvivalSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function PlayerSurvivalSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function PlayerSurvivalSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function PlayerSurvivalSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return PlayerSurvivalSystem
