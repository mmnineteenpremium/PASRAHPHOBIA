local State = {}
State.__index = State

local DEFAULT_STATE = {
	activeModifiers = {},
	modifierHistory = {},
	modifierDefinitions = {
		Territorial = {
			roamingMultiplier = 0.5,
			interactionMultiplier = 0.9,
			huntChanceNearRoomMultiplier = 1.5,
			evidenceDistortionMultiplier = 1.0,
			aggressionMultiplier = 1.1,
		},
		Trickster = {
			roamingMultiplier = 1.1,
			interactionMultiplier = 1.5,
			huntChanceNearRoomMultiplier = 1.0,
			evidenceDistortionMultiplier = 1.3,
			aggressionMultiplier = 1.05,
		},
		Watcher = {
			roamingMultiplier = 0.9,
			interactionMultiplier = 1.1,
			huntChanceNearRoomMultiplier = 0.8,
			evidenceDistortionMultiplier = 1.0,
			aggressionMultiplier = 0.9,
		},
		Silent = {
			roamingMultiplier = 1.0,
			interactionMultiplier = 0.8,
			huntChanceNearRoomMultiplier = 1.0,
			evidenceDistortionMultiplier = 1.1,
			aggressionMultiplier = 1.0,
		},
		Aggressive = {
			roamingMultiplier = 1.2,
			interactionMultiplier = 1.2,
			huntChanceNearRoomMultiplier = 1.4,
			evidenceDistortionMultiplier = 0.9,
			aggressionMultiplier = 1.35,
		},
		Shy = {
			roamingMultiplier = 0.8,
			interactionMultiplier = 0.75,
			huntChanceNearRoomMultiplier = 0.7,
			evidenceDistortionMultiplier = 1.0,
			aggressionMultiplier = 0.8,
		},
	},
	activeMatchId = nil,
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, nestedValue in pairs(value) do
		out[key] = deepCopy(nestedValue)
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

function State:ResetForMatch(matchId)
	self._data.activeModifiers = {}
	self._data.activeMatchId = matchId
end

function State:Clear()
	self._data = deepCopy(DEFAULT_STATE)
end

return State
