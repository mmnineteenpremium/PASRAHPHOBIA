local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)
    self._data = {
        rankTable = {
            { tier = "Bayi", minLevel = 1, divisions = 3, starsPerDivision = 3 },
            { tier = "Balita", minLevel = 5, divisions = 3, starsPerDivision = 3 },
            { tier = "Anak-Anak", minLevel = 10, divisions = 3, starsPerDivision = 3 },
            { tier = "Remaja", minLevel = 20, divisions = 3, starsPerDivision = 4 },
            { tier = "Dewasa", minLevel = 30, divisions = 3, starsPerDivision = 4 },
            { tier = "Profesional", minLevel = 40, divisions = 3, starsPerDivision = 5 },
            { tier = "Detektive", minLevel = 50, divisions = 3, starsPerDivision = 5 },
            { tier = "Sang Ahli", minLevel = 60, divisions = 0, starsPerDivision = 0 },
        },
        rankByUserId = {},
        recentRankUpdates = {},
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
