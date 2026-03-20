local State = {}
State.__index = State

local DEFAULT_STATE = {
    enabled = true,
    activeMatchId = nil,
    currentStage = "Calm",
    baseIntervalSeconds = 36,
    minIntervalSeconds = 12,
    eventTypes = {},
    running = false,
    loopToken = 0,
    nextEventAt = 0,
    eventHistory = {},
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

function State:AppendEvent(entry)
    local history = self._data.eventHistory or {}
    table.insert(history, entry)
    if #history > 80 then
        table.remove(history, 1)
    end
    self._data.eventHistory = history
end

function State:ResetForMatch(matchId)
    self._data.activeMatchId = matchId
    self._data.currentStage = "Calm"
    self._data.nextEventAt = os.clock()
    self._data.eventHistory = {}
end

function State:Clear()
    self._data = deepCopy(DEFAULT_STATE)
end

return State
