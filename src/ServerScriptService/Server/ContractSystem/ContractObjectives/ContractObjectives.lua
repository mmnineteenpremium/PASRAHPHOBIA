local ContractObjectives = {}
ContractObjectives.__index = ContractObjectives

function ContractObjectives.new(deps)
    local self = setmetatable({}, ContractObjectives)
    self._deps = deps or {}
    self._objectiveTypes = self._deps.ContractObjectiveTypes or {
        IdentifyGhost = "IdentifyGhost",
        CollectEvidence = "CollectEvidence",
        SurviveHunt = "SurviveHunt",
    }
    return self
end

function ContractObjectives:CreateObjectiveStates(objectives)
    local states = {}
    for _, objectiveType in ipairs(objectives or {}) do
        table.insert(states, {
            objectiveType = objectiveType,
            completed = false,
            progress = 0,
            target = 1,
        })
    end
    return states
end

function ContractObjectives:ValidateCompletion(state, signalType)
    if not state then
        return false
    end

    if state.objectiveType == self._objectiveTypes.IdentifyGhost and signalType == "GhostIdentified" then
        state.completed = true
    elseif state.objectiveType == self._objectiveTypes.CollectEvidence and signalType == "EvidenceDetected" then
        state.completed = true
    elseif state.objectiveType == self._objectiveTypes.SurviveHunt and signalType == "HuntEnded" then
        state.completed = true
    end

    return state.completed == true
end

return ContractObjectives
