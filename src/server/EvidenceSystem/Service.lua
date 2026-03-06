local EvidenceService = require(script.Parent.Modules.EvidenceService)

local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._evidenceService = EvidenceService.new(self._state, self._deps)
    return self
end

function Service:Init()
    self._evidenceService:Init()
end

function Service:Start()
    self._evidenceService:Start()
end

function Service:Stop()
    self._evidenceService:Stop()
end

function Service:StartMatch(matchId, payload)
    return self._evidenceService:StartMatch(matchId, payload)
end

function Service:EndMatch(matchId)
    self._evidenceService:EndMatch(matchId)
end

function Service:SetGhostProfile(matchId, payload)
    return self._evidenceService:SetGhostProfile(matchId, payload)
end

function Service:SpawnEvidence(matchId, payload)
    return self._evidenceService:SpawnEvidence(matchId, payload)
end

function Service:ProcessToolUse(player, matchId, payload)
    return self._evidenceService:ProcessToolUse(player, matchId, payload)
end

function Service:CollectEvidence(player, matchId, payload)
    return self._evidenceService:CollectEvidence(player, matchId, payload)
end

function Service:ValidateJournalGuess(player, matchId, payload)
    return self._evidenceService:ValidateJournalGuess(player, matchId, payload)
end

function Service:GetCollectedEvidence(matchId)
    return self._evidenceService:GetCollectedEvidence(matchId)
end

function Service:GetPossibleGhosts(matchId)
    return self._evidenceService:GetPossibleGhosts(matchId)
end

function Service:UpdateDirectorTension(matchId, tension)
    self._evidenceService:UpdateDirectorTension(matchId, tension)
end

function Service:UpdateGhostPersonality(matchId, personality)
    self._evidenceService:UpdateGhostPersonality(matchId, personality)
end

function Service:UpdateSpectatorVision(matchId, payload)
    self._evidenceService:UpdateSpectatorVision(matchId, payload)
end

return Service

