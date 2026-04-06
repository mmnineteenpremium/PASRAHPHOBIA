local LobbyPlayerManager = {}
LobbyPlayerManager.__index = LobbyPlayerManager

local LobbyLocator = require(script.Parent.Parent.Core.LobbyLocator)

local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 3, 0)
local LOBBY_SPAWN_PART_HEIGHT_FROM_FLOOR = 3.5
local LOBBY_SPAWN_PROTECTION_SECONDS = 3
local EXPECTED_SPAWN_COUNT = 4
local SPAWN_OFFSETS = {
    Vector3.new(-10, 0, -10),
    Vector3.new(10, 0, -10),
    Vector3.new(-10, 0, 10),
    Vector3.new(10, 0, 10),
}
local LOBBY_VISUAL_SPAWN_OFFSETS = {
    Vector3.new(-4, 0, 26),
    Vector3.new(4, 0, 26),
    Vector3.new(-4, 0, 34),
    Vector3.new(4, 0, 34),
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
    return LobbyLocator.ResolveRoot(LOBBY_NAME, workspace)
end

local function getSpawnFolder(lobbyRoot)
    if not lobbyRoot then
        return nil
    end

    local folder = lobbyRoot:FindFirstChild("SpawnPoints", true)
    if folder and (folder:IsA("Folder") or folder:IsA("Model")) then
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

local function applyLobbySpawnState(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    local protectUntil = os.clock() + LOBBY_SPAWN_PROTECTION_SECONDS
    player:SetAttribute("InLobby", true)
    player:SetAttribute("InMatch", nil)
    player:SetAttribute("MatchId", nil)
    player:SetAttribute("SpawnProtected", true)
    player:SetAttribute("SpawnProtectedUntil", protectUntil)

    task.delay(LOBBY_SPAWN_PROTECTION_SECONDS, function()
        if not player.Parent then
            return
        end
        local currentUntil = player:GetAttribute("SpawnProtectedUntil")
        if type(currentUntil) == "number" and currentUntil > os.clock() then
            return
        end
        player:SetAttribute("SpawnProtected", nil)
        player:SetAttribute("SpawnProtectedUntil", nil)
    end)
end

local function resolvePrimaryFloorTopY(lobbyRoot)
    if not lobbyRoot then
        return nil
    end

    local floorPart = lobbyRoot:FindFirstChild("Floor_1_Main", true)
    if not (floorPart and floorPart:IsA("BasePart")) then
        for _, descendant in ipairs(lobbyRoot:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant.Name:match("^Floor") then
                floorPart = descendant
                break
            end
        end
    end

    if floorPart and floorPart:IsA("BasePart") then
        return floorPart.Position.Y + (floorPart.Size.Y * 0.5)
    end

    return nil
end

local function resolveLobbyReferencePosition(lobbyRoot)
    if not lobbyRoot then
        return nil
    end

    local boundaryReference = lobbyRoot:FindFirstChild("BoundaryReference", true)
    if boundaryReference and boundaryReference:IsA("BasePart") then
        return boundaryReference.Position
    end

    local floorPart = lobbyRoot:FindFirstChild("Floor_1_Main", true)
    if floorPart and floorPart:IsA("BasePart") then
        return floorPart.Position
    end

    if lobbyRoot:IsA("Model") then
        local ok, pivot = pcall(function()
            return lobbyRoot:GetPivot().Position
        end)
        if ok and typeof(pivot) == "Vector3" then
            return pivot
        end
    end

    local firstPart = lobbyRoot:FindFirstChildWhichIsA("BasePart", true)
    if firstPart then
        return firstPart.Position
    end

    return nil
end

local function resolveLobbyLookTarget(lobbyRoot)
    if not lobbyRoot then
        return nil
    end

    local matchmakingDoor = lobbyRoot:FindFirstChild("Door_NorthEvidenceBuilding", true)
    if matchmakingDoor and matchmakingDoor:IsA("BasePart") then
        return matchmakingDoor.Position
    end

    local matchmakingInteract = lobbyRoot:FindFirstChild("Interact_NorthEvidenceBuilding", true)
    if matchmakingInteract and matchmakingInteract:IsA("BasePart") then
        return matchmakingInteract.Position
    end

    local mainHubRoom = lobbyRoot:FindFirstChild("Room_MainHubPlaza", true)
    if mainHubRoom and mainHubRoom:IsA("BasePart") then
        return mainHubRoom.Position
    end

    local mainHubProp = lobbyRoot:FindFirstChild("Prop_MainHubPlaza", true)
    if mainHubProp and mainHubProp:IsA("BasePart") then
        return mainHubProp.Position
    end

    return resolveLobbyReferencePosition(lobbyRoot)
end

local function resolveLobbyVisualSpawnPosition(lobbyRoot, spawnPart)
    if not (lobbyRoot and spawnPart and spawnPart:IsA("BasePart")) then
        return nil
    end

    local matchmakingDoor = lobbyRoot:FindFirstChild("Door_NorthEvidenceBuilding", true)
    if not (matchmakingDoor and matchmakingDoor:IsA("BasePart")) then
        return nil
    end

    local spawnIndex = tonumber(string.match(spawnPart.Name, "PlayerSpawn_(%d+)")) or 1
    local offset = LOBBY_VISUAL_SPAWN_OFFSETS[((spawnIndex - 1) % #LOBBY_VISUAL_SPAWN_OFFSETS) + 1]
    local targetXZ = matchmakingDoor.Position + Vector3.new(offset.X, 0, offset.Z)
    return Vector3.new(targetXZ.X, spawnPart.Position.Y, targetXZ.Z)
end

local function raycastSpawnY(lobbyRoot, targetXZ, fallbackY)
    local floorTopY = resolvePrimaryFloorTopY(lobbyRoot)
    if floorTopY then
        return floorTopY
    end

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

    local referencePosition = resolveLobbyReferencePosition(lobbyRoot)
    local floorTopY = resolvePrimaryFloorTopY(lobbyRoot)
    for _, spawnPart in ipairs(spawnParts) do
        if not spawnPart:IsA("BasePart") then
            return false, "non_basepart"
        end

        if spawnPart.Position.Y < -50 then
            return false, "spawn_out_of_lobby_bounds"
        end

        if referencePosition then
            local delta = spawnPart.Position - referencePosition
            if math.abs(delta.X) > 300 or math.abs(delta.Z) > 300 then
                return false, "spawn_out_of_lobby_bounds"
            end
        end

        if floorTopY then
            local heightAboveFloor = spawnPart.Position.Y - floorTopY
            if heightAboveFloor < 1 or heightAboveFloor > 6 then
                return false, "spawn_height_invalid"
            end
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

local function buildUprightPartCFrame(part, offset, lookTarget)
    if not (part and part:IsA("BasePart")) then
        return nil
    end

    local position = part.Position + (offset or Vector3.zero)
    local flatLook
    if typeof(lookTarget) == "Vector3" then
        flatLook = Vector3.new(lookTarget.X - position.X, 0, lookTarget.Z - position.Z)
    end
    if not flatLook or flatLook.Magnitude <= 1e-4 then
        flatLook = Vector3.new(part.CFrame.LookVector.X, 0, part.CFrame.LookVector.Z)
    end
    if flatLook.Magnitude <= 1e-4 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end

    return CFrame.lookAt(position, position + flatLook, Vector3.yAxis)
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

    local referencePosition = resolveLobbyReferencePosition(lobbyRoot)
    if not referencePosition then
        warn(string.format("[LobbyPlayerManager] [%s] Missing lobby reference position for SpawnPoints rebuild", tostring(reason)))
        return nil
    end

    for index, offset in ipairs(SPAWN_OFFSETS) do
        local target = referencePosition + Vector3.new(offset.X, 0, offset.Z)
        local floorY = raycastSpawnY(lobbyRoot, target, referencePosition.Y)

        local part = Instance.new("Part")
        part.Name = string.format("PlayerSpawn_%d", index)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(2, 1, 2)
        part.Position = Vector3.new(target.X, floorY + LOBBY_SPAWN_PART_HEIGHT_FROM_FLOOR, target.Z)
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
    local lobbyRoot = resolveLobbyRoot()
    local lookTarget = resolveLobbyLookTarget(lobbyRoot)
    local visualSpawnPosition = resolveLobbyVisualSpawnPosition(lobbyRoot, spawnPart)
    local spawnCFrame = nil
    if typeof(visualSpawnPosition) == "Vector3" then
        local position = visualSpawnPosition + LOBBY_SPAWN_OFFSET
        local flatLook = typeof(lookTarget) == "Vector3"
            and Vector3.new(lookTarget.X - position.X, 0, lookTarget.Z - position.Z)
            or Vector3.zero
        if flatLook.Magnitude <= 1e-4 then
            flatLook = Vector3.new(spawnPart.CFrame.LookVector.X, 0, spawnPart.CFrame.LookVector.Z)
        end
        if flatLook.Magnitude <= 1e-4 then
            flatLook = Vector3.new(0, 0, -1)
        else
            flatLook = flatLook.Unit
        end
        spawnCFrame = CFrame.new(position, position + flatLook)
    else
        spawnCFrame = buildUprightPartCFrame(spawnPart, LOBBY_SPAWN_OFFSET, lookTarget)
    end
    root.CFrame = spawnCFrame or (spawnPart.CFrame + LOBBY_SPAWN_OFFSET)
    applyLobbySpawnState(player)
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
    applyLobbySpawnState(player)

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
