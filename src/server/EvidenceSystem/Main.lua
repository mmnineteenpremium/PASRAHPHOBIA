local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local EvidenceSystem = {}
EvidenceSystem.__index = EvidenceSystem

function EvidenceSystem.new(deps)
    local self = setmetatable({}, EvidenceSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function EvidenceSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function EvidenceSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function EvidenceSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function EvidenceSystem:Shutdown()
    self:Stop()
end

return EvidenceSystem
