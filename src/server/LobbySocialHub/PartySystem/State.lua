local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        status = "idle",
        partyByLeaderUserId = {},
    }

    for key, value in pairs(initial or {}) do
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

return State