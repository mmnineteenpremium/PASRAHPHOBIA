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

function GhostSystem:SpawnGhost(matchId, payload)
    return self.Service:SpawnGhost(matchId, payload)
end

function GhostSystem:StartHunt(matchId, snapshot, now)
    return self.Service:StartHunt(matchId, snapshot, now)
end

function GhostSystem:EndHunt(matchId, now)
    return self.Service:EndHunt(matchId, now)
end

function GhostSystem:GetGhostState(matchId)
    return self.Service:GetGhostState(matchId)
end

return GhostSystem
