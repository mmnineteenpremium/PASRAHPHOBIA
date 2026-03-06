local State = {}
State.__index = State

local DEFAULT_DATA = {
    zones = {
        "SpawnPlaza",
        "FlexZone",
        "MatchmakingZone",
        "PartyZone",
        "ShopZone",
        "LeaderboardZone",
        "TrainingZone",
        "DailyRewardZone",
    },
    buildings = {
        "MatchmakingHall",
        "FlexGallery",
        "ShopBuilding",
        "LeaderboardBuilding",
        "TrainingBuilding",
        "DailyRewardBuilding",
    },
    supportedInteractions = {
        "TeamFormation",
        "PartyInvites",
        "ProfileInspection",
        "CosmeticFlex",
        "ShopInteraction",
        "TrainingTools",
    },
    integrations = {
        "MatchSystem",
        "ProfileSystem",
        "EconomySystem",
        "PartySystem",
    },
    eventNames = {
        "PlayerEnteredLobby",
        "PlayerEnteredZone",
        "PlayerJoinedParty",
        "PlayerLeftParty",
        "MatchmakingStarted",
    },
}

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {}

    for key, value in pairs(DEFAULT_DATA) do
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