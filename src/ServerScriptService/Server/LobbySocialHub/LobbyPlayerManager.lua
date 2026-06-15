local LobbyPlayerManager = {}
LobbyPlayerManager.__index = LobbyPlayerManager

local LobbyLocator = require(script.Parent.Parent.Core.LobbyLocator)
local CollectionService = game:GetService("CollectionService")

local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 13, 0)
local LOBBY_SPAWN_PART_HEIGHT_FROM_FLOOR = 3.5
local LOBBY_SPAWN_PROTECTION_SECONDS = 3
local LOBBY_SPAWN_RETRY_DELAY_SECONDS = 0.35
local LOBBY_CHARACTER_RELOAD_COOLDOWN_SECONDS = 1.25
local EXPECTED_SPAWN_COUNT = 4
local SPAWN_CLEARANCE_HEIGHT = 6
local SAFE_SPAWN_RAYCAST_DEPTH = 64
local SAFE_SPAWN_SHIFT_X = 5
local MAX_COLLIDABLE_RAYCAST_PASSES = 12
local SPAWN_MARKER_MIN_Y = -50
local SPAWN_MARKER_MAX_REFERENCE_DELTA_XZ = 300
local CAMPFIRE_SAFE_RADIUS_ATTRIBUTE = "PasrahLobbyCampfireSafeRadius"
local CAMPFIRE_CENTER_CANDIDATE_NAMES = {
    "CampfireCenter",
    "CampfireFireCore",
    "CampfirePit",
}
local LOBBY_FLOOR_REFERENCE_CANDIDATE_NAMES = {
    "Floor_1_Main",
    "DirectoryPad",
    "GardenBayFloor",
    "ShopBayFloor",
    "FlexBayFloor",
    "PartyBayFloor",
    "NorthBayFloor",
}
local DEFAULT_CAMPFIRE_SAFE_RADIUS = 12
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

local function stabilizeSpawnPart(spawnPart)
    if not (spawnPart and spawnPart:IsA("BasePart")) then
        return false
    end

    local changed = false
    if spawnPart.Anchored ~= true then
        spawnPart.Anchored = true
        changed = true
    end
    if spawnPart.CanCollide ~= false then
        spawnPart.CanCollide = false
        changed = true
    end
    if spawnPart:IsA("SpawnLocation") then
        if spawnPart.Enabled ~= true then
            spawnPart.Enabled = true
            changed = true
        end
        if spawnPart.Neutral ~= true then
            spawnPart.Neutral = true
            changed = true
        end
        if spawnPart.Duration ~= 0 then
            spawnPart.Duration = 0
            changed = true
        end
        if spawnPart.AllowTeamChangeOnTouch ~= false then
            spawnPart.AllowTeamChangeOnTouch = false
            changed = true
        end
    end
    if spawnPart.AssemblyLinearVelocity.Magnitude > 1e-3 then
        spawnPart.AssemblyLinearVelocity = Vector3.zero
        changed = true
    end
    if spawnPart.AssemblyAngularVelocity.Magnitude > 1e-3 then
        spawnPart.AssemblyAngularVelocity = Vector3.zero
        changed = true
    end

    return changed
end

local function stabilizeLobbyPhysics(lobbyRoot)
    if not lobbyRoot then
        return 0
    end

    local stabilized = 0
    for _, descendant in ipairs(lobbyRoot:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Anchored ~= true then
            descendant.Anchored = true
            stabilized += 1
        end
    end
    return stabilized
end

local function applyLobbySpawnState(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    local matchId = player:GetAttribute("MatchId")
    local lifecyclePhase = player:GetAttribute("MatchLifecyclePhase")
    local hasMatchContext = (type(matchId) == "string" and matchId ~= "")
        or (type(lifecyclePhase) == "string" and lifecyclePhase ~= "")
    if hasMatchContext then
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

local function resolveLobbyFloorReferencePart(lobbyRoot)
    if not lobbyRoot then
        return nil
    end

    for _, name in ipairs(LOBBY_FLOOR_REFERENCE_CANDIDATE_NAMES) do
        local candidate = lobbyRoot:FindFirstChild(name, true)
        if candidate and candidate:IsA("BasePart") then
            return candidate
        end
    end

    local bestPart = nil
    local bestArea = 0
    for _, descendant in ipairs(lobbyRoot:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local lowerName = descendant.Name:lower()
            if lowerName:find("floor", 1, true) or lowerName:find("pad", 1, true) then
                local area = descendant.Size.X * descendant.Size.Z
                if area > bestArea then
                    bestArea = area
                    bestPart = descendant
                end
            end
        end
    end

    return bestPart
end

local function resolvePrimaryFloorTopY(lobbyRoot)
    local floorPart = resolveLobbyFloorReferencePart(lobbyRoot)
    if floorPart then
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

    local floorPart = resolveLobbyFloorReferencePart(lobbyRoot)
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
    -- LobbySocialHub owns lobby-facing spawn composition. Keep marker-relative
    -- placement disabled here so the authoritative marker stays the single source.
    return nil
end

local function resolveCampfireCenter(lobbyRoot)
    if not lobbyRoot then
        return nil
    end

    for _, name in ipairs(CAMPFIRE_CENTER_CANDIDATE_NAMES) do
        local part = lobbyRoot:FindFirstChild(name, true)
        if part and part:IsA("BasePart") then
            return part.Position
        end
    end

    return resolveLobbyReferencePosition(lobbyRoot)
end

local function resolveCampfireSafeRadius()
    local fromWorkspace = tonumber(workspace:GetAttribute(CAMPFIRE_SAFE_RADIUS_ATTRIBUTE))
    if fromWorkspace and fromWorkspace > 1 then
        return fromWorkspace
    end
    return DEFAULT_CAMPFIRE_SAFE_RADIUS
end

local function isInsideCampfireSafetyRadius(lobbyRoot, position)
    if typeof(position) ~= "Vector3" then
        return false
    end

    local center = resolveCampfireCenter(lobbyRoot)
    if typeof(center) ~= "Vector3" then
        return false
    end

    return (position - center).Magnitude < resolveCampfireSafeRadius()
end

local function projectOutsideCampfireRadius(lobbyRoot, position, fallbackDirection)
    if typeof(position) ~= "Vector3" then
        return position
    end

    local center = resolveCampfireCenter(lobbyRoot)
    if typeof(center) ~= "Vector3" then
        return position
    end

    local safeRadius = resolveCampfireSafeRadius()
    local offset = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
    local direction = offset
    if direction.Magnitude <= 1e-4 then
        direction = fallbackDirection or Vector3.new(1, 0, 0)
    end
    direction = Vector3.new(direction.X, 0, direction.Z)
    if direction.Magnitude <= 1e-4 then
        direction = Vector3.new(1, 0, 0)
    else
        direction = direction.Unit
    end

    if offset.Magnitude < safeRadius then
        return Vector3.new(
            center.X + (direction.X * safeRadius),
            position.Y,
            center.Z + (direction.Z * safeRadius)
        )
    end

    return position
end

local function raycastFirstCollidable(origin, direction, excludeInstances)
    local filter = {}
    for _, instance in ipairs(excludeInstances or {}) do
        if typeof(instance) == "Instance" then
            table.insert(filter, instance)
        end
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    for _ = 1, MAX_COLLIDABLE_RAYCAST_PASSES do
        params.FilterDescendantsInstances = filter
        local result = workspace:Raycast(origin, direction, params)
        if not result then
            return nil
        end

        local hit = result.Instance
        if hit and hit:IsA("BasePart") and hit.CanCollide then
            return result
        end
        if typeof(hit) ~= "Instance" then
            return nil
        end
        table.insert(filter, hit)
    end

    return nil
end

local function hasOverheadClearance(position, excludeInstances, clearanceNeeded)
    local clearance = tonumber(clearanceNeeded) or SPAWN_CLEARANCE_HEIGHT
    return raycastFirstCollidable(position, Vector3.new(0, clearance, 0), excludeInstances) == nil
end

local function buildFlatLookVector(position, lookTarget, fallbackPart)
    local flatLook = typeof(lookTarget) == "Vector3"
        and Vector3.new(lookTarget.X - position.X, 0, lookTarget.Z - position.Z)
        or Vector3.zero
    if flatLook.Magnitude <= 1e-4 and fallbackPart and fallbackPart:IsA("BasePart") then
        flatLook = Vector3.new(fallbackPart.CFrame.LookVector.X, 0, fallbackPart.CFrame.LookVector.Z)
    end
    if flatLook.Magnitude <= 1e-4 then
        return Vector3.new(0, 0, -1)
    end
    return flatLook.Unit
end

local function buildSafeSpawnPosition(lobbyRoot, markerPart, excludeInstances, positionX, positionZ)
    local origin = Vector3.new(positionX, markerPart.Position.Y + math.max(markerPart.Size.Y, 2), positionZ)
    local floorResult = raycastFirstCollidable(origin, Vector3.new(0, -SAFE_SPAWN_RAYCAST_DEPTH, 0), excludeInstances)
    local floorY = resolvePrimaryFloorTopY(lobbyRoot)
    if floorResult then
        floorY = floorResult.Position.Y
    end
    local primaryFloorTopY = resolvePrimaryFloorTopY(lobbyRoot)
    if primaryFloorTopY and (not floorY or floorY < primaryFloorTopY) then
        floorY = primaryFloorTopY
    end
    if floorY == nil then
        floorY = markerPart.Position.Y
    end
    return Vector3.new(positionX, floorY + LOBBY_SPAWN_OFFSET.Y, positionZ), floorResult ~= nil
end

local function getSafeSpawnCFrame(lobbyRoot, markerPart, lookTarget, character)
    if not (markerPart and markerPart:IsA("BasePart")) then
        return nil
    end

    local excludeInstances = { markerPart }
    if typeof(character) == "Instance" then
        table.insert(excludeInstances, character)
    end

    local safePosition, hitFloor = buildSafeSpawnPosition(
        lobbyRoot,
        markerPart,
        excludeInstances,
        markerPart.Position.X,
        markerPart.Position.Z
    )
    if not hitFloor then
        warn(string.format(
            "[LobbyPlayerManager] Safe spawn raycast missed floor for %s. Using marker height fallback.",
            markerPart.Name
        ))
    end

    if not hasOverheadClearance(safePosition, excludeInstances, SPAWN_CLEARANCE_HEIGHT) then
        local shiftedPosition = buildSafeSpawnPosition(
            lobbyRoot,
            markerPart,
            excludeInstances,
            markerPart.Position.X + SAFE_SPAWN_SHIFT_X,
            markerPart.Position.Z
        )
        safePosition = shiftedPosition
        warn(string.format(
            "[LobbyPlayerManager] Overhead obstruction at %s. Shifting spawn to X+%d.",
            markerPart.Name,
            SAFE_SPAWN_SHIFT_X
        ))
    end

    local flatLook = buildFlatLookVector(safePosition, lookTarget, markerPart)
    return CFrame.lookAt(safePosition, safePosition + flatLook, Vector3.yAxis)
end

local function raycastSpawnY(lobbyRoot, targetXZ, fallbackY)
    local floorTopY = resolvePrimaryFloorTopY(lobbyRoot)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.IgnoreWater = true
    params.FilterDescendantsInstances = { lobbyRoot }

    local origin = Vector3.new(targetXZ.X, fallbackY + 120, targetXZ.Z)
    local result = workspace:Raycast(origin, Vector3.new(0, -240, 0), params)
    if result then
        return result.Position.Y
    end

    if floorTopY then
        return floorTopY
    end

    local globalResult = workspace:Raycast(origin, Vector3.new(0, -400, 0))
    if globalResult then
        return globalResult.Position.Y
    end

    return fallbackY
end

local function isHealthySpawnCandidate(lobbyRoot, spawnPart)
    if not (spawnPart and spawnPart:IsA("BasePart")) then
        return false, "non_basepart"
    end

    if spawnPart.Position.Y < SPAWN_MARKER_MIN_Y then
        return false, "spawn_out_of_lobby_bounds"
    end

    local referencePosition = resolveLobbyReferencePosition(lobbyRoot)
    if referencePosition then
        local delta = spawnPart.Position - referencePosition
        if math.abs(delta.X) > SPAWN_MARKER_MAX_REFERENCE_DELTA_XZ
            or math.abs(delta.Z) > SPAWN_MARKER_MAX_REFERENCE_DELTA_XZ
        then
            return false, "spawn_out_of_lobby_bounds"
        end
    end

    local floorTopY = resolvePrimaryFloorTopY(lobbyRoot)
    if floorTopY then
        local heightAboveFloor = spawnPart.Position.Y - floorTopY
        if heightAboveFloor < 1 or heightAboveFloor > 6 then
            return false, "spawn_height_invalid"
        end
    end

    if isInsideCampfireSafetyRadius(lobbyRoot, spawnPart.Position) then
        return false, "spawn_in_campfire_zone"
    end

    return true, nil
end

local function spawnPartsAreHealthy(lobbyRoot, spawnParts)
	if #spawnParts < EXPECTED_SPAWN_COUNT then
		return false, string.format("spawn_count_%d", #spawnParts)
	end

    local spawnLocationCount = 0
    local floorTopY = resolvePrimaryFloorTopY(lobbyRoot)
    for _, spawnPart in ipairs(spawnParts) do
        if spawnPart:IsA("SpawnLocation") then
            spawnLocationCount += 1
        end
        local healthy, reason = isHealthySpawnCandidate(lobbyRoot, spawnPart)
        if not healthy then
            return false, reason
        end

        local spawnY = (floorTopY or spawnPart.Position.Y) + LOBBY_SPAWN_OFFSET.Y
        local clearanceOrigin = Vector3.new(spawnPart.Position.X, spawnY, spawnPart.Position.Z)
        if not hasOverheadClearance(clearanceOrigin, { spawnPart }, SPAWN_CLEARANCE_HEIGHT) then
            return false, "spawn_overhead_blocked"
        end
    end
    if spawnLocationCount < EXPECTED_SPAWN_COUNT then
        return false, string.format("spawn_locations_%d", spawnLocationCount)
    end

	return true, nil
end

local function collectTaggedSpawnParts(lobbyRoot)
	if not lobbyRoot then
		return nil
	end

	local taggedSpawnParts = {}
	for _, candidate in ipairs(CollectionService:GetTagged("PasrahLobbySpawnPoint")) do
		if candidate and candidate:IsA("SpawnLocation") and candidate:IsDescendantOf(lobbyRoot) and isHealthySpawnCandidate(lobbyRoot, candidate) then
			table.insert(taggedSpawnParts, candidate)
		end
	end

	if #taggedSpawnParts >= EXPECTED_SPAWN_COUNT then
		return sortSpawnParts(taggedSpawnParts)
	end

	return nil
end

local function collectWorkspaceLobbySpawnParts(lobbyRoot)
	local workspaceSpawn = workspace:FindFirstChild("LobbySpawn")
	if workspaceSpawn and workspaceSpawn:IsA("BasePart") and isHealthySpawnCandidate(lobbyRoot, workspaceSpawn) then
		return { workspaceSpawn }
	end

	return nil
end

local function collectSpawnFolderSpawnParts(lobbyRoot)
	if not lobbyRoot then
		return nil
	end

	local spawnFolder = lobbyRoot:FindFirstChild("SpawnPoints", true)
	local spawnParts = collectSpawnParts(spawnFolder)
	local safeSpawnParts = {}
	for _, candidate in ipairs(spawnParts) do
		if string.match(candidate.Name, "^PlayerSpawn_%d+$") and isHealthySpawnCandidate(lobbyRoot, candidate) then
			table.insert(safeSpawnParts, candidate)
		end
	end

	if #safeSpawnParts > 0 then
		return sortSpawnParts(safeSpawnParts)
	end

	return nil
end

local function collectDirectSpawnParts(lobbyRoot)
	if not lobbyRoot then
		return nil
	end

	local directSpawnParts = {}
	for index = 1, EXPECTED_SPAWN_COUNT do
		local candidate = lobbyRoot:FindFirstChild(string.format("PlayerSpawn_%d", index))
		if candidate and candidate:IsA("BasePart") and isHealthySpawnCandidate(lobbyRoot, candidate) then
			table.insert(directSpawnParts, candidate)
		end
	end

	if #directSpawnParts > 0 then
		return sortSpawnParts(directSpawnParts)
	end

	return nil
end

local function resolveLobbySpawnPartsForResolver(lobbyRoot)
	local taggedSpawnParts = collectTaggedSpawnParts(lobbyRoot)
	if taggedSpawnParts then
		return taggedSpawnParts, "tagged_spawn_points"
	end

	local workspaceSpawnParts = collectWorkspaceLobbySpawnParts(lobbyRoot)
	if workspaceSpawnParts then
		return workspaceSpawnParts, "workspace_lobby_spawn"
	end

	local spawnFolderParts = collectSpawnFolderSpawnParts(lobbyRoot)
	if spawnFolderParts then
		return spawnFolderParts, "spawn_points_folder"
	end

	local directSpawnParts = collectDirectSpawnParts(lobbyRoot)
	if directSpawnParts then
		return directSpawnParts, "direct_player_spawns"
	end

	return nil, "spawn_missing"
end

local function resolveSpawnPart(deps, config, player)
	local lobbyRoot = resolveLobbyRoot()
	if config and typeof(config.SpawnPart) == "Instance" then
		local healthy = isHealthySpawnCandidate(lobbyRoot, config.SpawnPart)
		if healthy then
			return config.SpawnPart
		end
	end
	if deps.LobbySpawnPart and typeof(deps.LobbySpawnPart) == "Instance" then
		local healthy = isHealthySpawnCandidate(lobbyRoot, deps.LobbySpawnPart)
		if healthy then
			return deps.LobbySpawnPart
		end
	end

	local resolverSpawnParts = resolveLobbySpawnPartsForResolver(lobbyRoot)
	if resolverSpawnParts then
		local index = 1
		if typeof(player) == "Instance" and player:IsA("Player") then
			index = (player.UserId % #resolverSpawnParts) + 1
		end
		return resolverSpawnParts[index]
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
    self._spawnRetryByUserId = {}
    self._characterReloadAtByUserId = {}
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
    table.clear(self._spawnRetryByUserId)
    table.clear(self._characterReloadAtByUserId)
end

function LobbyPlayerManager:_hasActiveMatchContext(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false
    end

    local matchId = player:GetAttribute("MatchId")
    local lifecyclePhase = player:GetAttribute("MatchLifecyclePhase")
    return (type(matchId) == "string" and matchId ~= "")
        or (type(lifecyclePhase) == "string" and lifecyclePhase ~= "")
        or player:GetAttribute("InMatch") == true
end

function LobbyPlayerManager:_requestCharacterReload(player, reason)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or not player.Parent then
        return false
    end
    if self:_hasActiveMatchContext(player) then
        return false
    end

    local userId = player.UserId
    local now = os.clock()
    local lastReloadAt = self._characterReloadAtByUserId[userId]
    if type(lastReloadAt) == "number" and (now - lastReloadAt) < LOBBY_CHARACTER_RELOAD_COOLDOWN_SECONDS then
        return false
    end

    self._characterReloadAtByUserId[userId] = now
    applyLobbySpawnState(player)
    task.defer(function()
        if player.Parent and not self:_hasActiveMatchContext(player) then
            local ok, err = pcall(function()
                player:LoadCharacter()
            end)
            if ok then
                print(string.format("[LobbyPlayerManager] Reloaded lobby character for %s (%s).", player.Name, tostring(reason)))
            else
                warn(string.format("[LobbyPlayerManager] Failed to reload lobby character for %s (%s): %s", player.Name, tostring(reason), tostring(err)))
            end
        end
    end)
    return true
end

function LobbyPlayerManager:_scheduleSpawnRetry(player, character, reason)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or not player.Parent then
        return false
    end
    if self:_hasActiveMatchContext(player) then
        return false
    end

    local userId = player.UserId
    if self._spawnRetryByUserId[userId] then
        return false
    end

    self._spawnRetryByUserId[userId] = true
    task.delay(LOBBY_SPAWN_RETRY_DELAY_SECONDS, function()
        self._spawnRetryByUserId[userId] = nil
        if player.Parent and not self:_hasActiveMatchContext(player) then
            self:_spawnPlayer(player, character or player.Character)
        end
    end)
    warn(string.format("[LobbyPlayerManager] Scheduled lobby spawn retry for %s (%s).", player.Name, tostring(reason)))
    return true
end

function LobbyPlayerManager:_scanAndSyncLobbySpawns(reason)
    local lobbyRoot = resolveLobbyRoot()
    if not lobbyRoot then
        warn(string.format("[LobbyPlayerManager] [%s] Lobby root not found for spawn scan", tostring(reason)))
        return nil
    end

    local stabilizedPhysicsCount = stabilizeLobbyPhysics(lobbyRoot)
    if stabilizedPhysicsCount > 0 then
        print(string.format(
            "[LobbyPlayerManager] [%s] Stabilized %d unanchored lobby part(s).",
            tostring(reason),
            stabilizedPhysicsCount
        ))
    end

    local spawnParts, spawnSource = resolveLobbySpawnPartsForResolver(lobbyRoot)
    if not spawnParts then
        spawnParts = {}
    end
    local stabilizedCount = 0
    for _, spawnPart in ipairs(spawnParts) do
        if stabilizeSpawnPart(spawnPart) then
            stabilizedCount += 1
        end
    end
    if stabilizedCount > 0 then
        print(string.format(
            "[LobbyPlayerManager] [%s] Stabilized %d lobby spawn marker(s).",
            tostring(reason),
            stabilizedCount
        ))
    end

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

    if lobbyRoot:GetAttribute("PasrahLobbyAllowSpawnRebuild") ~= true then
        warn(string.format("[LobbyPlayerManager] [%s] SpawnPoints rebuild skipped because PasrahLobbyAllowSpawnRebuild is not enabled.", tostring(reason)))
        return nil
    end

    local referencePosition = resolveLobbyReferencePosition(lobbyRoot)

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
        target = projectOutsideCampfireRadius(lobbyRoot, target, Vector3.new(offset.X, 0, offset.Z))
        local floorY = raycastSpawnY(lobbyRoot, target, referencePosition.Y)

        local part = Instance.new("SpawnLocation")
        part.Name = string.format("PlayerSpawn_%d", index)
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Transparency = 1
        part.Enabled = true
        part.Neutral = true
        part.Duration = 0
        part.AllowTeamChangeOnTouch = false
        part.Size = Vector3.new(2, 1, 2)
        part.Position = Vector3.new(target.X, floorY + LOBBY_SPAWN_PART_HEIGHT_FROM_FLOOR, target.Z)
        part:SetAttribute("PasrahAuthoredLobbySpawn", true)
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
    local activeMatchId = player:GetAttribute("MatchId")
    local activeLifecyclePhase = player:GetAttribute("MatchLifecyclePhase")
    local hasActiveMatchContext = (type(activeMatchId) == "string" and activeMatchId ~= "")
        or (type(activeLifecyclePhase) == "string" and activeLifecyclePhase ~= "")
    if hasActiveMatchContext then
        return
    end
    if player:GetAttribute("InMatch") == true then
        local matchId = player:GetAttribute("MatchId")
        local lifecyclePhase = player:GetAttribute("MatchLifecyclePhase")
        local hasAuthoritativeMatchContext = (type(matchId) == "string" and matchId ~= "")
            or (type(lifecyclePhase) == "string" and lifecyclePhase ~= "")
        if hasAuthoritativeMatchContext then
            return
        end
        -- Stale match flags can persist after interrupted Studio playtest loops.
        -- Clear them so LobbySocialHub regains spawn authority.
        player:SetAttribute("InMatch", nil)
        player:SetAttribute("MatchId", nil)
        player:SetAttribute("MatchLifecyclePhase", nil)
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
        local humanoid = resolvedCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            self:_requestCharacterReload(player, "dead_before_lobby_spawn")
        else
            self:_scheduleSpawnRetry(player, resolvedCharacter, "missing_root")
        end
        return
    end

    local humanoid = resolvedCharacter:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        self:_requestCharacterReload(player, "dead_before_lobby_spawn")
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
        self:_scheduleSpawnRetry(player, resolvedCharacter, "missing_spawn")
        return
    end
    stabilizeSpawnPart(spawnPart)
    self._warnedMissingSpawn = false

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    local lobbyRoot = resolveLobbyRoot()
    local lookTarget = resolveLobbyLookTarget(lobbyRoot)
    local visualSpawnPosition = resolveLobbyVisualSpawnPosition(lobbyRoot, spawnPart)
    local spawnCFrame = nil
    if typeof(visualSpawnPosition) == "Vector3" then
        local position = visualSpawnPosition + LOBBY_SPAWN_OFFSET
        local flatLook = buildFlatLookVector(position, lookTarget, spawnPart)
        spawnCFrame = CFrame.lookAt(position, position + flatLook, Vector3.yAxis)
    else
        spawnCFrame = getSafeSpawnCFrame(lobbyRoot, spawnPart, lookTarget, resolvedCharacter)
            or buildUprightPartCFrame(spawnPart, LOBBY_SPAWN_OFFSET, lookTarget)
    end
    root.CFrame = spawnCFrame or (spawnPart.CFrame + LOBBY_SPAWN_OFFSET)
    applyLobbySpawnState(player)
    print(string.format("[LobbyPlayerManager] Spawned %s at %s", player.Name, tostring(spawnPart.Position)))
end

function LobbyPlayerManager:RegisterPlayer(player)
    print("[DEBUG-MGR-1] LobbyPlayerManager:RegisterPlayer CALLED for: " .. (player and player.Name or "nil"))
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        print("[DEBUG-MGR-2] LobbyPlayerManager:RegisterPlayer INVALID player")
        return false, "invalid_player"
    end

    local userId = player.UserId
    local matchId = player:GetAttribute("MatchId")
    local lifecyclePhase = player:GetAttribute("MatchLifecyclePhase")
    local hasActiveMatchContext = (type(matchId) == "string" and matchId ~= "")
        or (type(lifecyclePhase) == "string" and lifecyclePhase ~= "")
    if hasActiveMatchContext then
        self._players[userId] = nil
        local existingConnection = self._connectionsByUserId[userId]
        if existingConnection then
            existingConnection:Disconnect()
            self._connectionsByUserId[userId] = nil
        end
        player:SetAttribute("InLobby", nil)
        return true, "player_in_match"
    end

    if self._players[userId] then
        print("[DEBUG-MGR-3] LobbyPlayerManager:RegisterPlayer already registered, skipping")
        return true
    end

    self._players[userId] = player
    applyLobbySpawnState(player)

    self._connectionsByUserId[userId] = player.CharacterAdded:Connect(function(character)
        task.defer(function()
            self:_spawnPlayer(player, character)
        end)
    end)

    if player.Character then
        print("[DEBUG-MGR-4] LobbyPlayerManager:RegisterPlayer has character, calling _spawnPlayer now")
        self:_spawnPlayer(player, player.Character)
    else
        print("[DEBUG-MGR-5] LobbyPlayerManager:RegisterPlayer NO character, requesting reload")
        self:_requestCharacterReload(player, "missing_character")
    end
    print("[DEBUG-MGR-6] LobbyPlayerManager:RegisterPlayer COMPLETE for: " .. player.Name)
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
    self._spawnRetryByUserId[userId] = nil
    self._characterReloadAtByUserId[userId] = nil

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
