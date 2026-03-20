local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        rankByUserId = initial and initial.rankByUserId or {},
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
