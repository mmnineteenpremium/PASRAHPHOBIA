local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local Integrations = {}
Integrations.__index = Integrations

function Integrations.new(deps)
    local self = setmetatable({}, Integrations)
    self._deps = deps or {}
    self.State = State.new(self._deps.IntegrationState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function Integrations:Init()
    self.Service:Init()
    self.Controller:Init()
end

function Integrations:Start()
    self.Service:Start()
end

function Integrations:Stop()
    self.Service:Stop()
end

return Integrations
