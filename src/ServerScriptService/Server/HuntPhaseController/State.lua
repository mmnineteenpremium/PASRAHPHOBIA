local State = {}
State.__index = State

local DEFAULT_STATE = {
    huntPhase = "Idle",
    phaseTimer = 0,
    activeMatchId = nil,
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

function State.new()
    local self = setmetatable({}, State)
    self._data = deepCopy(DEFAULT_STATE)
    return self
end

function State:Get(key)
    return self._data[key]
end

function State:Set(key, value)
    self._data[key] = value
end

function State:Clear()
    self._data = deepCopy(DEFAULT_STATE)
end

return State
