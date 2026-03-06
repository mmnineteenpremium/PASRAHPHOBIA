local State = {}
State.__index = State

local DEFAULT_STATE = {
	activeEvents = {},
	eventCooldowns = {},
	eventHistory = {},
	activeMatchId = nil,
	currentPhase = "Lobby",
	lastSanity = 100,
	lastAggression = 0,
	lastDirectorIntensity = 0,
}

local function cloneTable(source)
	local out = {}
	for key, value in pairs(source) do
		out[key] = value
	end
	return out
end

function State.new(seed)
	local self = setmetatable({}, State)
	self._data = cloneTable(DEFAULT_STATE)
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
	self._data.activeEvents = {}
	self._data.eventCooldowns = {}
	self._data.eventHistory = {}
	self._data.activeMatchId = matchId
	self._data.currentPhase = "Investigation"
	self._data.lastSanity = 100
	self._data.lastAggression = 0
	self._data.lastDirectorIntensity = 0
end

function State:Clear()
	self._data = cloneTable(DEFAULT_STATE)
end

return State
