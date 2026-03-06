local State = {}
State.__index = State

local DEFAULT_STATE = {
    currentTension = 0,
    lastEventTime = 0,
    eventCooldown = 6,
    directorMode = "CALM",
    activeMatchId = nil,
    loopToken = 0,
    running = false,
    lastMatchResults = nil,
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
    self._data.currentTension = 0
    self._data.lastEventTime = os.clock()
    self._data.directorMode = "CALM"
    self._data.activeMatchId = matchId
    self._data.lastMatchResults = nil
end

function State:Clear()
    local loopToken = self._data.loopToken or 0
    self._data = cloneTable(DEFAULT_STATE)
    self._data.loopToken = loopToken
end

return State
