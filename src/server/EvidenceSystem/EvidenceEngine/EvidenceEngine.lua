local CoreEvidenceEngine = require(script.Parent.Parent.Modules.EvidenceEngine)

local EvidenceEngine = {}
EvidenceEngine.__index = EvidenceEngine

function EvidenceEngine.new(deps)
    local self = setmetatable({}, EvidenceEngine)
    self._core = CoreEvidenceEngine.new(deps)
    return self
end

function EvidenceEngine:StartMatch(matchId, payload)
    return self._core:StartMatch(matchId, payload)
end

function EvidenceEngine:EndMatch(matchId)
    return self._core:EndMatch(matchId)
end

function EvidenceEngine:TrySpawnEvidence(matchId, payload, context)
    return self._core:TrySpawnEvidence(matchId, payload, context)
end

function EvidenceEngine:TryCollectEvidence(matchId, player, payload, context)
    return self._core:TryCollectEvidence(matchId, player, payload, context)
end

return EvidenceEngine
