local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local EvidenceConfigSystem = {}
EvidenceConfigSystem.__index = EvidenceConfigSystem

function EvidenceConfigSystem.new(deps)
    local self = setmetatable({}, EvidenceConfigSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function EvidenceConfigSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function EvidenceConfigSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function EvidenceConfigSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function EvidenceConfigSystem:GetEvidenceDefinitions()
    return self.Service:GetEvidenceDefinitions()
end

function EvidenceConfigSystem:GetEvidenceDefinition(evidenceId)
    return self.Service:GetEvidenceDefinition(evidenceId)
end

return EvidenceConfigSystem
