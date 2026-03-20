local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local HuntPhaseController = {}
HuntPhaseController.__index = HuntPhaseController

function HuntPhaseController.new(deps)
    local self = setmetatable({}, HuntPhaseController)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function HuntPhaseController:Init()
    self.Service:Init()
    self.Controller:Init()
end

function HuntPhaseController:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function HuntPhaseController:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return HuntPhaseController
