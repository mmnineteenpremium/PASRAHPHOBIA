local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local SystemIntegrationController = {}
SystemIntegrationController.__index = SystemIntegrationController

function SystemIntegrationController.new(deps)
    local self = setmetatable({}, SystemIntegrationController)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SystemIntegrationController:Init()
    self.Service:Init()
    self.Controller:Init()
end

function SystemIntegrationController:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function SystemIntegrationController:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return SystemIntegrationController
