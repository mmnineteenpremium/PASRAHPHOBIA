local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)
    self._data = {}
    return self
end

function State:Set(key, value)
    self._data[key] = value
end

function State:Get(key)
    return self._data[key]
end

return State
