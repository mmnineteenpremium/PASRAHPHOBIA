local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local EvidenceJournalSystem = {}
EvidenceJournalSystem.__index = EvidenceJournalSystem

function EvidenceJournalSystem.new(deps)
    local self = setmetatable({}, EvidenceJournalSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function EvidenceJournalSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function EvidenceJournalSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function EvidenceJournalSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return EvidenceJournalSystem
