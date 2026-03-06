local State = {}
State.__index = State

local DEFAULT = {
    rewardPerPercent = 10,
    winMultiplier = 1.2,
    loseMultiplier = 0.8,
}

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {}
    for key, value in pairs(DEFAULT) do
        self._data[key] = value
    end
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
