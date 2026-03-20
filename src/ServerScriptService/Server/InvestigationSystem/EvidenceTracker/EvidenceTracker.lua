local EvidenceTracker = {}
EvidenceTracker.__index = EvidenceTracker

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

function EvidenceTracker.new()
    local self = setmetatable({}, EvidenceTracker)
    return self
end

function EvidenceTracker:Record(matchState, playerOrUserId, evidenceType, now)
    if type(matchState) ~= "table" or type(evidenceType) ~= "string" then
        return false
    end
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false
    end

    local alreadyFound = matchState.discoveredEvidence[evidenceType] == true
    matchState.discoveredEvidence[evidenceType] = true

    matchState.discoveredByEvidence[evidenceType] = matchState.discoveredByEvidence[evidenceType] or {}
    matchState.discoveredByEvidence[evidenceType][userId] = now or os.clock()

    matchState.discoveriesByUserId[userId] = matchState.discoveriesByUserId[userId] or {}
    matchState.discoveriesByUserId[userId][evidenceType] = now or os.clock()

    return not alreadyFound
end

function EvidenceTracker:GetEvidenceList(matchState)
    local out = {}
    for evidenceType in pairs((matchState and matchState.discoveredEvidence) or {}) do
        table.insert(out, evidenceType)
    end
    table.sort(out)
    return out
end

function EvidenceTracker:GetDiscoverers(matchState, evidenceType)
    local out = {}
    local discoverers = matchState and matchState.discoveredByEvidence and matchState.discoveredByEvidence[evidenceType] or {}
    for userId in pairs(discoverers or {}) do
        table.insert(out, userId)
    end
    table.sort(out)
    return out
end

return EvidenceTracker
