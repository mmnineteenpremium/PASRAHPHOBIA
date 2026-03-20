local LobbyPlayerManager = {}
LobbyPlayerManager.__index = LobbyPlayerManager

local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 3, 0)
local EXPECTED_SPAWN_COUNT = 4
local SPAWN_OFFSETS = {
    Vector3.new(-10, 0, -10),
    Vector3.new(10, 0, -10),
    Vector3.new(-10, 0, 10),
    Vector3.new(10, 0, 10),
}

local function resolvePlayersService(deps)
    local players = deps.Players
    if players then
        return players
    end
    return game:GetService("Players")
end

local function collectSpawnParts(root, out)
    out = out or {}
    if not root then
        return out
    end

    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(out, child)
        elseif child:IsA("Folder") or child:IsA("Model") then
            collectSpawnParts(child, out)
        end
    end

    return out
end

local function resolveLobbyRoot()
    local workspaceLobby = workspace:FindFirstChild(LOBBY_NAME)
    if workspaceLobby then
        return workspaceLobby
    end

    local mapsFolder = workspace:FindFirstChild("Maps")
    if mapsFolder then
        local mapsLobby = mapsFolder:FindFirstChild(LOBBY_NAME)
        if mapsLobby then
            return mapsLobby
        end
    end

    local currentMap = workspace:FindFirstChild("CurrentMap")
    if currentMap and currentMap.Name == LOBBY_NAME then
        return currentMap
    end

    return nil
end

local function getSpawnFolder(lobbyRoot)
    if not lobbyRoot then
        return nil
    end
    local folder = lobbyRoot:FindFirstChild("SpawnPoints")
    if folder and folder:IsA("Folder") then
        return folder
    end
    return nil
end

local function sortSpawnParts(spawnParts)
    table.sort(spawnParts, function(a, b)
        return a.Name < b.Name
    end)
    return spawnParts
end

local function raycastSpawnY(lobbyRoot, targetXZ, fallbackY)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { lobbyRoot }

    local origin = Vector3.new(targetXZ.X, fallbackY + 120, targetXZ.Z)
    local result = workspace:Raycast(origin, Vector3.new(0, -240, 0), params)
    if result then
        return result.Position.Y
    end

    local globalResult = workspace:Raycast(origin, Vector3.new(0, -400, 0))
    if globalResult then
        return globalResult.Position.Y
    end

    return fallbackY
end

local function spawnPartsAreHealthy(lobbyRoot, spawnParts)
    if #spawnParts < EXPECTED_SPAWN_COUNT then
        return false, string.format("spawn_count_%d", #spawnParts)
    end

    local pivot = lobbyRoot:GetPivot().Position
    for _, spawnPart in ipairs(spawnParts) do
        if not spawnPart:IsA("BasePart") then
            return false, "non_basepart"
        end
        local delta = spawnPart.Position - pivot
        if math.abs(delta.X) > 300 or math.abs(delta.Z) > 300 or spawnPart.Position.Y < -50 then
            return false, "spawn_out_of_lobby_bounds"
        end
    end

    return true, nil
end

local function resolveSpawnPart(deps, config, player)
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

    local lobbyRoot = resolveLobbyRoot()
    if lobbyRoot then
        local lobbySpawn = lobbyRoot:FindFirstChild("LobbySpawn", true)
        if lobbySpawn and lobbySpawn:IsA("BasePart") then
            return lobbySpawn
        end

        local spawnLocation = lobbyRoot:FindFirstChildWhichIsA("SpawnLocation", true)
        if spawnLocation then
            return spawnLocation
        end

        local spawnFolder = lobbyRoot:FindFirstChild("SpawnPoints", true)
        local spawnParts = collectSpawnParts(spawnFolder)
        if #spawnParts > 0 then
            table.sort(spawnParts, function(a, b)
                return a.Name < b.Name
            end)

            local index = 1
            if typeof(player) == "Instance" and player:IsA("Player") then
                index = (player.UserId % #spawnParts) + 1
            end
            return spawnParts[index]
        end
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
    self._spawnPart = resolveSpawnPart(self._deps, self._config, nil)
    self._warnedMissingSpawn = false
    return self
end

function LobbyPlayerManager:Init()
    self:_scanAndSyncLobbySpawns("Init")
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

function LobbyPlayerManager:_scanAndSyncLobbySpawns(reason)
    local lobbyRoot = resolveLobbyRoot()
    if not lobbyRoot then
        warn(string.format("[LobbyPlayerManager] [%s] Lobby root not found for spawn scan", tostring(reason)))
        return nil
    end

    local spawnFolder = getSpawnFolder(lobbyRoot)
    local spawnParts = sortSpawnParts(collectSpawnParts(spawnFolder))
    local healthy, healthReason = spawnPartsAreHealthy(lobbyRoot, spawnParts)
    local forceRebuild = workspace:GetAttribute("ForceLobbySpawnRebuild") == true
    if forceRebuild then
        healthy = false
        healthReason = "forced_rebuild"
        workspace:SetAttribute("ForceLobbySpawnRebuild", false)
    end

    if healthy then
        local names = {}
        for _, spawnPart in ipairs(spawnParts) do
            table.insert(names, string.format("%s@(%.1f,%.1f,%.1f)", spawnPart.Name, spawnPart.Position.X, spawnPart.Position.Y, spawnPart.Position.Z))
        end
        print(string.format("[LobbyPlayerManager] [%s] Spawn scan OK: %s", tostring(reason), table.concat(names, ", ")))
        return spawnParts
    end

    warn(string.format("[LobbyPlayerManager] [%s] Spawn scan unhealthy (%s). Rebuilding SpawnPoints.", tostring(reason), tostring(healthReason)))

    if spawnFolder then
        spawnFolder:Destroy()
    end

    spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "SpawnPoints"
    spawnFolder.Parent = lobbyRoot

    local pivot = lobbyRoot:GetPivot().Position
    for index, offset in ipairs(SPAWN_OFFSETS) do
        local target = pivot + Vector3.new(offset.X, 0, offset.Z)
        local floorY = raycastSpawnY(lobbyRoot, target, pivot.Y)

        local part = Instance.new("Part")
        part.Name = string.format("PlayerSpawn_%d", index)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(2, 1, 2)
        part.Position = Vector3.new(target.X, floorY + 1, target.Z)
        part.Parent = spawnFolder
    end

    local rebuiltParts = sortSpawnParts(collectSpawnParts(spawnFolder))
    local rebuiltNames = {}
    for _, spawnPart in ipairs(rebuiltParts) do
        table.insert(rebuiltNames, string.format("%s@(%.1f,%.1f,%.1f)", spawnPart.Name, spawnPart.Position.X, spawnPart.Position.Y, spawnPart.Position.Z))
    end
    print(string.format("[LobbyPlayerManager] [%s] SpawnPoints rebuilt: %s", tostring(reason), table.concat(rebuiltNames, ", ")))

    return rebuiltParts
end

function LobbyPlayerManager:_spawnPlayer(player, character)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end
    if player:GetAttribute("InMatch") == true then
        return
    end

    local resolvedCharacter = character or player.Character
    if not resolvedCharacter then
        return
    end

    local root = resolvedCharacter:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        root = resolvedCharacter:WaitForChild("HumanoidRootPart", 5)
    end
    if not root or not root:IsA("BasePart") then
        return
    end

    if workspace:GetAttribute("ForceLobbySpawnRebuild") == true then
        self:_scanAndSyncLobbySpawns("SpawnForceCheck")
    end

    local spawnPart = resolveSpawnPart(self._deps, self._config, player)
    self._spawnPart = spawnPart or self._spawnPart
    if not spawnPart then
        self:_scanAndSyncLobbySpawns("SpawnMissing")
        spawnPart = resolveSpawnPart(self._deps, self._config, player)
        self._spawnPart = spawnPart or self._spawnPart
    end
    if not spawnPart then
        if not self._warnedMissingSpawn then
            self._warnedMissingSpawn = true
            warn("[LobbyPlayerManager] Lobby spawn not found. Expected LobbySpawn or LobbySocialHub/SpawnPoints.")
        end
        return
    end
    self._warnedMissingSpawn = false

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = spawnPart.CFrame + LOBBY_SPAWN_OFFSET
    print(string.format("[LobbyPlayerManager] Spawned %s at %s", player.Name, tostring(spawnPart.Position)))
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

    self._connectionsByUserId[userId] = player.CharacterAdded:Connect(function(character)
        task.defer(function()
            self:_spawnPlayer(player, character)
        end)
    end)

    self:_spawnPlayer(player, player.Character)
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
