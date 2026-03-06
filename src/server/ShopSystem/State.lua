local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        catalog = initial and initial.catalog or {
            ghost_scanner_skin = {
                price = 1000,
                type = "cosmetic",
            },
        },
        purchaseHistory = initial and initial.purchaseHistory or {},
        cooldowns = initial and initial.cooldowns or {},
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
