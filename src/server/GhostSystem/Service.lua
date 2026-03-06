local GhostService = require(script.Parent.GhostService)

local Service = {}
Service.__index = Service

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._ghostService = GhostService.new(self._state, self._deps)
	return self
end

function Service:Init()
	self._ghostService:Init()
end

function Service:Start()
	self._ghostService:Start()
end

function Service:Stop()
	self._ghostService:Stop()
end

function Service:SpawnGhost(matchId, payload)
	return self._ghostService:SpawnGhost(matchId, payload)
end

function Service:TickGhost(matchId, snapshot, dt, now)
	return self._ghostService:TickGhost(matchId, snapshot, dt, now)
end

function Service:StartHunt(matchId, snapshot, now)
	return self._ghostService:StartHunt(matchId, snapshot, now)
end

function Service:EndHunt(matchId, now)
	return self._ghostService:EndHunt(matchId, now)
end

function Service:GetGhostState(matchId)
	return self._ghostService:GetGhostState(matchId)
end

function Service:DespawnGhost(matchId)
	self._ghostService:DespawnGhost(matchId)
end

function Service:ApplyDirectorEvent(matchId, eventName, payload)
	return self._ghostService:ApplyDirectorEvent(matchId, eventName, payload)
end

function Service:ForceManifest(matchId, now)
	return self._ghostService:ForceManifest(matchId, now)
end

return Service

