local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        activeContracts = initial and initial.activeContracts or {},
        rewardHistory = initial and initial.rewardHistory or {},
		lastMatchResults = initial and initial.lastMatchResults or nil,
		difficultyMultipliers = initial and initial.difficultyMultipliers or {
			Easy = 0.85,
			Normal = 1.0,
			Hard = 1.2,
			Nightmare = 1.5,
			Mudah = 1.0,
			Lumayan = 1.2,
			Angker = 1.45,
			["Uji Nyali"] = 1.7,
		},
        baseContractReward = initial and initial.baseContractReward or 250,
        surviveBonus = initial and initial.surviveBonus or 100,
        contractBonus = initial and initial.contractBonus or 150,
        performanceScale = initial and initial.performanceScale or 2,
    }
    return self
end

function State:Get(key)
    return self._data[key]
end

function State:Set(key, value)
    self._data[key] = value
end

function State:Clear()
    table.clear(self._data)
end

return State
