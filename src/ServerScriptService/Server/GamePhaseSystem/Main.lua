local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local GamePhaseSystem = {}
GamePhaseSystem.__index = GamePhaseSystem

function GamePhaseSystem.new(deps)
    local self = setmetatable({}, GamePhaseSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function GamePhaseSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function GamePhaseSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function GamePhaseSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function GamePhaseSystem:Shutdown()
    self:Stop()
end

return GamePhaseSystem
