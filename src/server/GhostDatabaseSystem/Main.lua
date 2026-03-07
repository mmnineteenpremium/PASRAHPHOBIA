local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local GhostDatabaseSystem = {}
GhostDatabaseSystem.__index = GhostDatabaseSystem

function GhostDatabaseSystem.new(deps)
    local self = setmetatable({}, GhostDatabaseSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function GhostDatabaseSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function GhostDatabaseSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function GhostDatabaseSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function GhostDatabaseSystem:GetGhostDatabase()
    return self.Service:GetGhostDatabase()
end

function GhostDatabaseSystem:GetGhostDefinition(ghostId)
    return self.Service:GetGhostDefinition(ghostId)
end

return GhostDatabaseSystem
