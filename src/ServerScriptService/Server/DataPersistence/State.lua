local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        playerData = initial and initial.playerData or {},
        economyData = initial and initial.economyData or {},
        inventoryData = initial and initial.inventoryData or {},
        rankData = initial and initial.rankData or {},
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
