local InvestigationState = {}
InvestigationState.__index = InvestigationState

function InvestigationState.new()
    local self = setmetatable({}, InvestigationState)
    return self
end

function InvestigationState:CreateMatchState(matchId, now)
    return {
        matchId = matchId,
        createdAt = now or os.clock(),
        ghostType = nil,
        discoveredEvidence = {},
        discoveredByEvidence = {},
        discoveriesByUserId = {},
        possibleGhostTypes = {},
        guessesByUserId = {},
        latestGuessByUserId = {},
        validated = false,
    }
end

function InvestigationState:EnsureMatch(matchMap, matchId, now)
    matchMap[matchId] = matchMap[matchId] or self:CreateMatchState(matchId, now)
    return matchMap[matchId]
end

return InvestigationState
