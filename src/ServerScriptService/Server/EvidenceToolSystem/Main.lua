local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local EvidenceToolSystem = {}
EvidenceToolSystem.__index = EvidenceToolSystem

function EvidenceToolSystem.new(deps)
    local self = setmetatable({}, EvidenceToolSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function EvidenceToolSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function EvidenceToolSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function EvidenceToolSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return EvidenceToolSystem
