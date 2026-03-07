local MatchService = require(script.Parent.MatchService)

local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._matchService = MatchService.new(self._state, self._deps)
    return self
end

function Service:Init()
    self._matchService:Init()
end

function Service:Start()
    self._matchService:Start()
end

function Service:Stop()
    self._matchService:Stop()
end

function Service:JoinQueue(player, payload)
    return self._matchService:JoinQueue(player, payload)
end

function Service:LeaveQueue(player)
    return self._matchService:LeaveQueue(player)
end

function Service:TryCreateMatchFromQueue(payload)
    return self._matchService:TryCreateMatchFromQueue(payload)
end

function Service:CreateMatch(payload)
    return self._matchService:CreateMatch(payload)
end

function Service:StartMatch(matchId)
    return self._matchService:StartMatch(matchId)
end

function Service:AdvanceMatchPhase(matchId, nextPhase)
    return self._matchService:AdvanceMatchPhase(matchId, nextPhase)
end

function Service:EndMatch(matchId, results)
    return self._matchService:EndMatch(matchId, results)
end

function Service:MarkPlayerDeath(matchId, userId, reason, payload)
    return self._matchService:MarkPlayerDeath(matchId, userId, reason, payload)
end

function Service:MarkPlayerExtracted(matchId, userId, payload)
    return self._matchService:MarkPlayerExtracted(matchId, userId, payload)
end

function Service:GetMatch(matchId)
    return self._matchService:GetMatch(matchId)
end

function Service:SetContractForParty(partyId, contractId)
    self._matchService:SetContractForParty(partyId, contractId)
end

return Service

