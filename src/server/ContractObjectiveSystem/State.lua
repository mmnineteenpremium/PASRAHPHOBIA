local State = {}
State.__index = State

local DEFAULT_STATE = {
	activeObjectives = {},
	completedObjectives = {},
	objectiveProgress = {},
	contractType = nil,
	activeMatchId = nil,
	objectiveTemplates = {
		Investigation = {
			primary = {
				{ id = "IdentifyGhost", type = "Primary", target = 1 },
				{ id = "CaptureEvidence", type = "Primary", target = 3 },
			},
			optional = {
				{ id = "SurviveHunt", type = "Optional", target = 1 },
				{ id = "WitnessGhostEvent", type = "Optional", target = 1 },
				{ id = "UseSpecificTool", type = "Optional", target = 1 },
			},
		},
		Exorcism = {
			primary = {
				{ id = "IdentifyGhost", type = "Primary", target = 1 },
				{ id = "SurviveHunt", type = "Primary", target = 1 },
			},
			optional = {
				{ id = "CaptureEvidence", type = "Optional", target = 2 },
				{ id = "CompleteInvestigation", type = "Optional", target = 1 },
			},
		},
		EvidenceCollection = {
			primary = {
				{ id = "CaptureEvidence", type = "Primary", target = 5 },
				{ id = "CompleteInvestigation", type = "Primary", target = 1 },
			},
			optional = {
				{ id = "IdentifyGhost", type = "Optional", target = 1 },
				{ id = "WitnessGhostEvent", type = "Optional", target = 1 },
			},
		},
	},
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, nested in pairs(value) do
		out[key] = deepCopy(nested)
	end
	return out
end

function State.new(seed)
	local self = setmetatable({}, State)
	self._data = deepCopy(DEFAULT_STATE)
	for key, value in pairs(seed or {}) do
		self._data[key] = value
	end
	return self
end

function State:Get(key)
	return self._data[key]
end

function State:Set(key, value)
	self._data[key] = value
end

function State:ResetForMatch(matchId, contractType)
	self._data.activeObjectives = {}
	self._data.completedObjectives = {}
	self._data.objectiveProgress = {}
	self._data.activeMatchId = matchId
	self._data.contractType = contractType
end

function State:Clear()
	self._data = deepCopy(DEFAULT_STATE)
end

return State
