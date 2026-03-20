local GhostAbilityPipeline = {}
GhostAbilityPipeline.__index = GhostAbilityPipeline

function GhostAbilityPipeline.new(deps)
    local self = setmetatable({}, GhostAbilityPipeline)
    self._deps = deps or {}
    return self
end

function GhostAbilityPipeline:InitSession(session)
    session.abilityRuntime = session.abilityRuntime or {
        lastAbilityAt = 0,
    }
end

function GhostAbilityPipeline:Tick(session, snapshot, now)
    -- Skeleton orchestration; concrete behavior lives in GhostAbilityEngine.
    return {
        matchId = session and session.matchId,
        now = now,
        snapshot = snapshot,
    }
end

return GhostAbilityPipeline
