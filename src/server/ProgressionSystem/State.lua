local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        xpTable = initial and initial.xpTable or {},
        recentLevelUps = initial and initial.recentLevelUps or {},
        playerProgress = initial and initial.playerProgress or {},
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
