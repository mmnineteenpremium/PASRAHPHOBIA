local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        availableCosmetics = initial and initial.availableCosmetics or {},
        availableItems = initial and initial.availableItems or {},
        purchasesByUserId = {},
    }
    return self
end

function State:Get(key)
    return self._data[key]
end

function State:Set(key, value)
    self._data[key] = value
end

return State
