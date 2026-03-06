local State = {}
State.__index = State

local DEFAULT_STATE = {
    registeredObjects = {},
    objectStates = {},
    interactionCooldowns = {},
    activeMatchId = nil,
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
	self._data.registeredObjects = {}
	self._data.objectStates = {}
	self._data.interactionCooldowns = {}
	self._data.activeMatchId = matchId
end

function State:Clear()
	self._data = cloneTable(DEFAULT_STATE)
end

return State
