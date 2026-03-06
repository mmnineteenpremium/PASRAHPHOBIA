local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        rankTable = initial and initial.rankTable or {
            { level = 1, rank = "Rookie" },
            { level = 5, rank = "Investigator" },
            { level = 10, rank = "Specialist" },
            { level = 20, rank = "Paranormal Expert" },
            { level = 35, rank = "Night Hunter" },
            { level = 50, rank = "Elite Hunter" },
        },
        recentRankUpdates = initial and initial.recentRankUpdates or {},
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
