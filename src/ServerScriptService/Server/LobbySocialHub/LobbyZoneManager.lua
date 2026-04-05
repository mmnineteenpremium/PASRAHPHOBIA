local LobbyLocator = require(script.Parent.Parent.Core.LobbyLocator)

local LobbyZoneManager = {}
LobbyZoneManager.__index = LobbyZoneManager

local SUPPORTED_ZONES = {
    "SpawnPlaza",
    "FlexZone",
    "ShopZone",
    "TrainingZone",
    "LeaderboardZone",
    "DailyRewardZone",
    "MatchmakingZone",
    "PartyZone",
}

local LOBBY_ZONE_CANDIDATES = {
    SpawnPlaza = { "Room_MainHubPlaza", "Interact_MainHubPlaza", "Prop_MainHubPlaza", "PlayerSpawn_1" },
    MatchmakingZone = {
        "Room_NorthEvidenceBuilding",
        "Interact_NorthEvidenceBuilding",
        "Door_NorthEvidenceBuilding",
        "Prop_NorthEvidenceBuilding",
    },
    ShopZone = { "Room_EastShopBuilding", "Interact_EastShopBuilding", "Door_EastShopBuilding", "Prop_EastShopBuilding" },
    PartyZone = { "Room_WestPartyZone", "Interact_WestPartyZone", "Door_WestPartyZone", "Prop_WestPartyZone" },
    DailyRewardZone = {
        "Room_SouthSocialGarden",
        "Interact_SouthSocialGarden",
        "Door_SouthSocialGarden",
        "Prop_SouthSocialGarden",
    },
    FlexZone = {
        "Room_SouthEastFlexZone",
        "Interact_SouthEastFlexZone",
        "Door_SouthEastFlexZone",
        "Prop_SouthEastFlexZone",
    },
}

local function resolvePlayersService(deps)
    local players = deps.Players
    if players then
        return players
    end
    return game:GetService("Players")
end

local function resolveZonesFolder(deps, config)
    if config and typeof(config.ZonesFolder) == "Instance" then
        return config.ZonesFolder
    end
    if deps.LobbyZonesFolder and typeof(deps.LobbyZonesFolder) == "Instance" then
        return deps.LobbyZonesFolder
    end

    local workspaceZones = workspace:FindFirstChild("LobbyZones")
    if workspaceZones and workspaceZones:IsA("Folder") then
        return workspaceZones
    end
    return nil
end

function LobbyZoneManager.new(deps, config)
    local self = setmetatable({}, LobbyZoneManager)
    self._deps = deps or {}
    self._config = config or {}
    self._playersService = resolvePlayersService(self._deps)
    self._zonesFolder = resolveZonesFolder(self._deps, self._config)
    self._zoneParts = {}
    self._connections = {}
    self._recentTouches = {}
    self._cooldown = self._config.TouchDebounceSeconds or 0.75
    self._onZoneEntered = nil
    return self
end

function LobbyZoneManager:SetZoneEnteredCallback(callback)
    self._onZoneEntered = callback
end

function LobbyZoneManager:Init()
    table.clear(self._zoneParts)
    if self._zonesFolder then
        for _, zoneName in ipairs(SUPPORTED_ZONES) do
            local zonePart = self._zonesFolder:FindFirstChild(zoneName)
            if zonePart and zonePart:IsA("BasePart") then
                self._zoneParts[zoneName] = zonePart
            end
        end
    end

    if next(self._zoneParts) ~= nil then
        return
    end

    local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
    if not lobbyRoot then
        return
    end

    for _, zoneName in ipairs(SUPPORTED_ZONES) do
        local candidates = LOBBY_ZONE_CANDIDATES[zoneName] or {}
        for _, candidateName in ipairs(candidates) do
            local candidate = lobbyRoot:FindFirstChild(candidateName, true)
            if candidate and candidate:IsA("BasePart") then
                self._zoneParts[zoneName] = candidate
                break
            end
        end
    end
end

function LobbyZoneManager:Start()
    for zoneName, zonePart in pairs(self._zoneParts) do
        local connection = zonePart.Touched:Connect(function(hitPart)
            self:_onTouched(zoneName, hitPart)
        end)
        table.insert(self._connections, connection)
    end
end

function LobbyZoneManager:Stop()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    table.clear(self._recentTouches)
end

function LobbyZoneManager:GetZoneParts()
    local snapshot = {}
    for zoneName, zonePart in pairs(self._zoneParts) do
        snapshot[zoneName] = zonePart
    end
    return snapshot
end

function LobbyZoneManager:_buildTouchKey(player, zoneName)
    return tostring(player.UserId) .. ":" .. zoneName
end

function LobbyZoneManager:_isTouchOnCooldown(player, zoneName)
    local key = self:_buildTouchKey(player, zoneName)
    local now = os.clock()
    local previous = self._recentTouches[key]
    if previous and (now - previous) < self._cooldown then
        return true
    end
    self._recentTouches[key] = now
    return false
end

function LobbyZoneManager:_playerFromHit(hitPart)
    if typeof(hitPart) ~= "Instance" then
        return nil
    end
    local model = hitPart.Parent
    if not model then
        return nil
    end
    return self._playersService:GetPlayerFromCharacter(model)
end

function LobbyZoneManager:_onTouched(zoneName, hitPart)
    local player = self:_playerFromHit(hitPart)
    if not player then
        return
    end
    if self:_isTouchOnCooldown(player, zoneName) then
        return
    end
    if self._onZoneEntered then
        self._onZoneEntered(player, zoneName)
    end
end

function LobbyZoneManager:SimulatePlayerEnteredZone(player, zoneName)
    if self._onZoneEntered then
        self._onZoneEntered(player, zoneName)
    end
end

return LobbyZoneManager
