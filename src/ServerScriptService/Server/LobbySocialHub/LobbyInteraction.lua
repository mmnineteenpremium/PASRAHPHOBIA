local LobbyInteraction = {}
LobbyInteraction.__index = LobbyInteraction

local DEFAULT_INTERACTIONS_BY_ZONE = {
    FlexZone = { "EmoteSpot", "ShowcaseProp", "SeatCluster" },
    ShopZone = { "ShopDoor", "CounterProp", "AmbientRadio" },
    TrainingZone = { "TrainingDoor", "PracticeProp", "SeatBench" },
    LeaderboardZone = { "LeaderboardPanel", "AmbientProp" },
    DailyRewardZone = { "RewardKiosk", "AmbientRadio" },
    MatchmakingZone = { "QueueTerminal", "QueueDoor" },
    PartyZone = { "PartyBoard", "PartyDoor", "SeatCluster" },
    SpawnPlaza = { "SpawnArch", "PlazaRadio" },
}

function LobbyInteraction.new(deps, config)
    local self = setmetatable({}, LobbyInteraction)
    self._deps = deps or {}
    self._config = config or {}
    self._interactionsByZone = {}
    return self
end

function LobbyInteraction:Init()
    local source = self._config.InteractionsByZone or DEFAULT_INTERACTIONS_BY_ZONE
    for zoneName, interactions in pairs(source) do
        self._interactionsByZone[zoneName] = interactions
    end
end

function LobbyInteraction:Start()
    -- Runtime is event-driven.
end

function LobbyInteraction:Stop()
    -- Runtime is event-driven.
end

function LobbyInteraction:HandleZoneEntry(player, zoneName)
    local interactions = self._interactionsByZone[zoneName]
    if not interactions then
        return nil
    end
    return {
        player = player,
        zoneName = zoneName,
        interactions = interactions,
    }
end

return LobbyInteraction
