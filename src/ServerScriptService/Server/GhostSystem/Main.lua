local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local GhostSystem = {}
GhostSystem.__index = GhostSystem

function GhostSystem.new(deps)
    local self = setmetatable({}, GhostSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function GhostSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function GhostSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function GhostSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function GhostSystem:Shutdown()
    self:Stop()
end

function GhostSystem:SpawnGhost(match, payload)
    return self.Service:SpawnGhost(match, payload)
end

function GhostSystem:InitializeMatch(match)
    return self.Service:InitializeMatch(match)
end

function GhostSystem:StartHunt(match, snapshot, now)
    return self.Service:StartHunt(match, snapshot, now)
end

function GhostSystem:TriggerHunt(match, snapshot, now)
    return self.Service:TriggerHunt(match, snapshot, now)
end

function GhostSystem:ForceHunt(match, snapshot, now)
    return self.Service:ForceHunt(match, snapshot, now)
end

function GhostSystem:EndHunt(match, now)
    return self.Service:EndHunt(match, now)
end

function GhostSystem:GetGhostState(match)
    return self.Service:GetGhostState(match)
end

return GhostSystem
