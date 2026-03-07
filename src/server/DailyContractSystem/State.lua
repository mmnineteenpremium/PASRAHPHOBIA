local State = {}
State.__index = State

local DEFAULT_STATE = {
    templates = {},
    activeContractCount = 4,
    resetSeconds = 86400,
    playerContracts = {},
    playerCycleStart = {},
    matchPlayers = {},
    playersByUserId = {},
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

function State:Clear()
    self._data = deepCopy(DEFAULT_STATE)
end

return State
