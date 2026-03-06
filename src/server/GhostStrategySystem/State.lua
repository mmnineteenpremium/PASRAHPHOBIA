local State = {}
State.__index = State

local DEFAULT_STATE = {
    activeMatchId = nil,
    activeStrategies = {},
    strategyHistory = {},
    strategyDefinitions = {
        Ambush = {
            huntBias = 1.2,
            interactionBias = 0.8,
            routePrediction = true,
        },
        Stalk = {
            huntBias = 1.0,
            interactionBias = 1.0,
            routePrediction = true,
        },
        TerritoryDefense = {
            huntBias = 1.15,
            interactionBias = 0.9,
            roomStickiness = 1.4,
        },
        ChaosInteraction = {
            huntBias = 0.9,
            interactionBias = 1.5,
            roomStickiness = 0.8,
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
    self._data.activeStrategies = {}
end

function State:Clear()
    self._data = deepCopy(DEFAULT_STATE)
end

return State
