local State = {}
State.__index = State

local DEFAULT_STATE = {
    activeMatchId = nil,
    ghostTraits = {},
    traitHistory = {},
    traitDefinitions = {
        Aggressive = {
            roamingMultiplier = 1.0,
            interactionMultiplier = 1.1,
            huntAggressionMultiplier = 1.35,
            manifestationMultiplier = 1.2,
        },
        Passive = {
            roamingMultiplier = 1.15,
            interactionMultiplier = 0.9,
            huntAggressionMultiplier = 0.75,
            manifestationMultiplier = 0.8,
        },
        Trickster = {
            roamingMultiplier = 1.1,
            interactionMultiplier = 1.4,
            huntAggressionMultiplier = 1.0,
            manifestationMultiplier = 1.3,
        },
        Deceptive = {
            roamingMultiplier = 1.05,
            interactionMultiplier = 1.3,
            huntAggressionMultiplier = 1.05,
            manifestationMultiplier = 1.35,
        },
        Watcher = {
            roamingMultiplier = 0.9,
            interactionMultiplier = 1.2,
            huntAggressionMultiplier = 0.85,
            manifestationMultiplier = 1.35,
        },
        Territorial = {
            roamingMultiplier = 0.65,
            interactionMultiplier = 1.05,
            huntAggressionMultiplier = 1.25,
            manifestationMultiplier = 1.0,
        },
        Stalker = {
            roamingMultiplier = 1.2,
            interactionMultiplier = 1.0,
            huntAggressionMultiplier = 1.15,
            manifestationMultiplier = 1.1,
        },
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

function State:ResetForMatch(matchId)
    self._data.activeMatchId = matchId
    self._data.ghostTraits = {}
end

function State:Clear()
    self._data = deepCopy(DEFAULT_STATE)
end

return State
