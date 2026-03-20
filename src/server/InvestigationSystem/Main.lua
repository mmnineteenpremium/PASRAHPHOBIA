local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local InvestigationSystem = {}
InvestigationSystem.__index = InvestigationSystem

function InvestigationSystem.new(deps)
    local self = setmetatable({}, InvestigationSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function InvestigationSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function InvestigationSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function InvestigationSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return InvestigationSystem
