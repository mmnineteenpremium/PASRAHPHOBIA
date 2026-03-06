local LobbyPlayerManager = {}
LobbyPlayerManager.__index = LobbyPlayerManager

local function resolvePlayersService(deps)
    local players = deps.Players
    if players then
        return players
    end
    return game:GetService("Players")
end

local function resolveSpawnPart(deps, config)
    if config and typeof(config.SpawnPart) == "Instance" then
        return config.SpawnPart
    end
    if deps.LobbySpawnPart and typeof(deps.LobbySpawnPart) == "Instance" then
        return deps.LobbySpawnPart
    end

    local workspaceSpawn = workspace:FindFirstChild("LobbySpawn")
    if workspaceSpawn and workspaceSpawn:IsA("BasePart") then
        return workspaceSpawn
    end
    return nil
end

function LobbyPlayerManager.new(deps, config)
    local self = setmetatable({}, LobbyPlayerManager)
    self._deps = deps or {}
    self._config = config or {}
    self._players = {}
    self._connectionsByUserId = {}
    self._playersService = resolvePlayersService(self._deps)
    self._spawnPart = resolveSpawnPart(self._deps, self._config)
    return self
end

function LobbyPlayerManager:Init()
    -- Runtime is event-driven.
end

function LobbyPlayerManager:Start()
    -- Runtime is event-driven.
end

function LobbyPlayerManager:Stop()
    for _, connection in pairs(self._connectionsByUserId) do
        connection:Disconnect()
    end
    table.clear(self._connectionsByUserId)
    table.clear(self._players)
end

function LobbyPlayerManager:_spawnPlayer(player)
    if not self._spawnPart then
        return
    end
    local character = player.Character
    if not character then
        return
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end
    root.CFrame = self._spawnPart.CFrame + Vector3.new(0, 3, 0)
end

function LobbyPlayerManager:RegisterPlayer(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "invalid_player"
    end

    local userId = player.UserId
    if self._players[userId] then
        return true
    end

    self._players[userId] = player
    player:SetAttribute("InLobby", true)

    self._connectionsByUserId[userId] = player.CharacterAdded:Connect(function()
        self:_spawnPlayer(player)
    end)

    self:_spawnPlayer(player)
    return true
end

function LobbyPlayerManager:RemovePlayer(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "invalid_player"
    end

    local userId = player.UserId
    self._players[userId] = nil

    local connection = self._connectionsByUserId[userId]
    if connection then
        connection:Disconnect()
        self._connectionsByUserId[userId] = nil
    end

    player:SetAttribute("InLobby", nil)
    return true
end

function LobbyPlayerManager:GetLobbyPlayers()
    local players = {}
    for _, player in pairs(self._players) do
        table.insert(players, player)
    end
    return players
end

function LobbyPlayerManager:GetLobbyPlayerCount()
    local count = 0
    for _ in pairs(self._players) do
        count += 1
    end
    return count
end

function LobbyPlayerManager:IsInLobby(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false
    end
    return self._players[player.UserId] ~= nil
end

return LobbyPlayerManager
