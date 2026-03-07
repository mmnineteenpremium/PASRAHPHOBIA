local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local JournalSystem = {}
JournalSystem.__index = JournalSystem

function JournalSystem.new(deps)
    local self = setmetatable({}, JournalSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function JournalSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function JournalSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function JournalSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return JournalSystem
