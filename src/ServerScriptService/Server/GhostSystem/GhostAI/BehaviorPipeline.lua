local GhostTypeProvider = require(script.Parent.GhostTypeProvider)

local GhostBehaviorPipeline = {}
GhostBehaviorPipeline.__index = GhostBehaviorPipeline

function GhostBehaviorPipeline.new(deps)
    local self = setmetatable({}, GhostBehaviorPipeline)
    self._deps = deps or {}
    self._ghostTypes = GhostTypeProvider.new(self._deps):ResolveGhostTypes()
    return self
end

function GhostBehaviorPipeline:BootstrapSession(session)
    session.pipeline = session.pipeline or {
        spawned = true,
        favoriteRoomSelected = session.favoriteRoomId ~= nil,
    }
end

function GhostBehaviorPipeline:GetDefaultStateOrder()
    return {
        "GhostSpawn",
        "SelectFavoriteRoom",
        "IdleState",
        "RoamingState",
        "InteractionState",
        "HuntState",
    }
end

function GhostBehaviorPipeline:Tick(session, snapshot, now)
    -- Skeleton hook for orchestration-only behavior pipeline.
    return {
        matchId = session and session.matchId,
        now = now,
        stateOrder = self:GetDefaultStateOrder(),
        snapshot = snapshot,
    }
end

return GhostBehaviorPipeline
