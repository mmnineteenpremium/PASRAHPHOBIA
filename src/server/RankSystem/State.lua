local State = {}
State.__index = State

local DEFAULT_STATE = {
    playerRank = {},
    playerStars = {},
    rankTable = {
        "Bayi III",
        "Bayi II",
        "Bayi I",
        "Balita III",
        "Balita II",
        "Balita I",
        "Anak-Anak III",
        "Anak-Anak II",
        "Anak-Anak I",
        "Remaja III",
        "Remaja II",
        "Remaja I",
        "Dewasa III",
        "Dewasa II",
        "Dewasa I",
        "Profesional III",
        "Profesional II",
        "Profesional I",
        "Detektive III",
        "Detektive II",
        "Detektive I",
        "Sang Ahli",
    },
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nested in pairs(value) do
        copy[key] = deepCopy(nested)
    end
    return copy
end

function State.new(seed)
    local self = setmetatable({}, State)
    self._data = deepCopy(DEFAULT_STATE)

    if type(seed) == "table" then
        for key, value in pairs(seed) do
            self._data[key] = value
        end
    end

    return self
end

function State:Get(key)
    return self._data[key]
end

function State:Set(key, value)
    self._data[key] = value
end

function State:Clear()
    self._data = deepCopy(DEFAULT_STATE)
end

return State