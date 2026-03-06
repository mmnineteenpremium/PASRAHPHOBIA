local ContractGenerator = {}
ContractGenerator.__index = ContractGenerator

function ContractGenerator.new(deps)
    local self = setmetatable({}, ContractGenerator)
    self._deps = deps or {}
    self._rng = self._deps.Random or Random.new()
    self._contractTypes = self._deps.ContractTypes or {
        Investigation = "Investigation",
    }
    self._objectiveTypes = self._deps.ContractObjectiveTypes or {
        IdentifyGhost = "IdentifyGhost",
        CollectEvidence = "CollectEvidence",
        SurviveHunt = "SurviveHunt",
    }
    self._rewardDefaults = self._deps.ContractRewardTypes or {
        MM = 1000,
        EXP = 250,
    }
    return self
end

function ContractGenerator:Generate(payload)
    local contractType = self._contractTypes.Investigation
    local objectives = {
        self._objectiveTypes.IdentifyGhost,
        self._objectiveTypes.CollectEvidence,
        self._objectiveTypes.SurviveHunt,
    }

    return {
        contractType = contractType,
        mapId = payload and payload.mapId or "AbandonedPalace",
        ghostType = payload and payload.ghostType or "UnknownGhost",
        difficulty = payload and payload.difficulty or "Normal",
        objectives = objectives,
        reward = {
            MM = self._rewardDefaults.MM,
            EXP = self._rewardDefaults.EXP,
        },
    }
end

return ContractGenerator
