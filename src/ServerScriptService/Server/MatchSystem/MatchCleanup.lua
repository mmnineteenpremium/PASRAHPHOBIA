--[[
    MATCH CLEANUP MODULE
    Handles proper cleanup when match ends:
    1. Teleport all players to lobby
    2. Destroy match folder from Workspace
    3. Clean up all match resources

    CRITICAL: This fixes the spawn issue where old match folders stay in Workspace
]]

local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local LobbyLocator = require(script.Parent.Parent.Core.LobbyLocator)

local MatchCleanup = {}

-- Configuration
local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 3, 0)
local LOBBY_SPAWN_MAX_DELTA_XZ = 350
local LOBBY_MIN_Y = -50
local LOBBY_MAX_SPAWN_Y = 15
local LOBBY_VISUAL_SPAWN_OFFSETS = {
	Vector3.new(-8, 0, 18),
	Vector3.new(8, 0, 18),
	Vector3.new(-8, 0, 30),
	Vector3.new(8, 0, 30),
}

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

local function isValidLobbySpawnPart(lobbyRoot, spawnPart)
	if not (spawnPart and spawnPart:IsA("BasePart")) then
		return false
	end

	if spawnPart.Position.Y < LOBBY_MIN_Y then
		return false
	end

	if spawnPart.Position.Y > LOBBY_MAX_SPAWN_Y then
		return false
	end

	if lobbyRoot and spawnPart:IsDescendantOf(lobbyRoot) then
		return true
	end

	if lobbyRoot then
		local pivot = lobbyRoot:GetPivot().Position
		local delta = spawnPart.Position - pivot
		if math.abs(delta.X) > LOBBY_SPAWN_MAX_DELTA_XZ or math.abs(delta.Z) > LOBBY_SPAWN_MAX_DELTA_XZ then
			return false
		end
		if spawnPart.Position.Y < LOBBY_MIN_Y then
			return false
		end
	end

	return true
end

local function sortSpawnParts(spawnParts)
	table.sort(spawnParts, function(a, b)
		return a.Name < b.Name
	end)
	return spawnParts
end

local function buildUprightPartCFrame(part, offset)
	if not (part and part:IsA("BasePart")) then
		return nil
	end

	local position = part.Position + (offset or Vector3.zero)
	local flatLook = Vector3.new(part.CFrame.LookVector.X, 0, part.CFrame.LookVector.Z)
	if flatLook.Magnitude <= 1e-4 then
		flatLook = Vector3.new(0, 0, -1)
	else
		flatLook = flatLook.Unit
	end

	return CFrame.lookAt(position, position + flatLook, Vector3.yAxis)
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

	return nil
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

local function resolveLobbySpawnParts()
	local lobby = resolveLobbyRoot()
	if lobby then
		local lobbySpawn = lobby:FindFirstChild("LobbySpawn", true)
		if isValidLobbySpawnPart(lobby, lobbySpawn) then
			return { lobbySpawn }
		end

		local spawnFolder = lobby:FindFirstChild("SpawnPoints", true)
		local spawnParts = sortSpawnParts(collectSpawnParts(spawnFolder))
		local validSpawnParts = {}
		for _, spawnPart in ipairs(spawnParts) do
			if isValidLobbySpawnPart(lobby, spawnPart) then
				table.insert(validSpawnParts, spawnPart)
			end
		end
		if #validSpawnParts > 0 then
			return validSpawnParts
		end

		local spawnLocation = lobby:FindFirstChildWhichIsA("SpawnLocation", true)
		if isValidLobbySpawnPart(lobby, spawnLocation) then
			return { spawnLocation }
		end
	end

	local directSpawn = workspace:FindFirstChild("LobbySpawn")
	if isValidLobbySpawnPart(lobby, directSpawn) then
		return { directSpawn }
	end

	if not lobby then
		return nil, "lobby_missing"
	end

	return nil, "spawn_missing"
end

-- Teleport all players in match back to lobby
function MatchCleanup.TeleportPlayersToLobby(matchId)
	local activeMatches = workspace:FindFirstChild("ActiveMatches")
	local matchFolder = activeMatches and activeMatches:FindFirstChild("Match_" .. tostring(matchId)) or nil
	if not activeMatches then
		warn("[MatchCleanup] ActiveMatches folder not found")
	end
	if not matchFolder then
		warn("[MatchCleanup] Match folder not found:", matchId)
	end

	local lobbySpawns, spawnReason = resolveLobbySpawnParts()
	local lobbyRoot = resolveLobbyRoot()
	if not lobbySpawns or #lobbySpawns == 0 then
		warn(string.format("[MatchCleanup] Lobby spawn unresolved (%s). Players will be flagged out-of-match only.", tostring(spawnReason)))
	end

	local teleportCount = 0
	local teleportedPlayers = {}

	-- Teleport all players
	for _, player in ipairs(Players:GetPlayers()) do
		local playerMatchId = player:GetAttribute("MatchId")
		local inMatch = player:GetAttribute("InMatch") == true
		local sameMatch = playerMatchId == nil or tostring(playerMatchId) == tostring(matchId)
		if not (inMatch and sameMatch) then
			continue
		end

		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and lobbySpawns and #lobbySpawns > 0 then
				local spawnIndex = (math.abs(player.UserId) % #lobbySpawns) + 1
				local lobbySpawn = lobbySpawns[spawnIndex]
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
				local spawnCFrame = nil
				local visualSpawnPosition = resolveLobbyVisualSpawnPosition(lobbyRoot, lobbySpawn)
				local lookTarget = resolveLobbyLookTarget(lobbyRoot)
				if typeof(visualSpawnPosition) == "Vector3" then
					local position = visualSpawnPosition + LOBBY_SPAWN_OFFSET
					local flatLook = typeof(lookTarget) == "Vector3"
						and Vector3.new(lookTarget.X - position.X, 0, lookTarget.Z - position.Z)
						or Vector3.zero
					if flatLook.Magnitude <= 1e-4 then
						flatLook = Vector3.new(lobbySpawn.CFrame.LookVector.X, 0, lobbySpawn.CFrame.LookVector.Z)
					end
					if flatLook.Magnitude <= 1e-4 then
						flatLook = Vector3.new(0, 0, -1)
					else
						flatLook = flatLook.Unit
					end
					spawnCFrame = CFrame.new(position, position + flatLook)
				else
					spawnCFrame = buildUprightPartCFrame(lobbySpawn, LOBBY_SPAWN_OFFSET)
				end
				hrp.CFrame = spawnCFrame or (lobbySpawn.CFrame + LOBBY_SPAWN_OFFSET)
				teleportCount = teleportCount + 1
			end
		end

		player:SetAttribute("InMatch", false)
		player:SetAttribute("MatchId", nil)
		table.insert(teleportedPlayers, player)
	end

	return teleportedPlayers, teleportCount
end

-- Destroy match folder and all contents
function MatchCleanup.DestroyMatchFolder(matchId)
	local activeMatches = workspace:FindFirstChild("ActiveMatches")
	if not activeMatches then
		warn("[MatchCleanup] ActiveMatches folder not found")
		return false
	end

	local matchFolder = activeMatches:FindFirstChild("Match_" .. tostring(matchId))
	if not matchFolder then
		warn("[MatchCleanup] Match folder not found:", matchId)
		return false
	end

	-- Destroy entire match folder (including map, evidence, ghosts, etc.)
	matchFolder:Destroy()

	return true
end

-- Full cleanup sequence (call this when match ends)
function MatchCleanup.CleanupMatch(matchId)
	-- Step 1: Teleport players FIRST (before destroying map)
	local teleportedPlayers, teleportedCount = MatchCleanup.TeleportPlayersToLobby(matchId)

	-- Step 2: Wait a moment for teleport to complete
	task.wait(0.5)

	-- Step 3: Destroy match folder
	local destroyed = MatchCleanup.DestroyMatchFolder(matchId)

	if destroyed then
		return {
			destroyed = destroyed,
			teleportedCount = teleportedCount or 0,
			teleportedPlayers = teleportedPlayers or {},
		}
	end

	warn("[MatchCleanup] Match cleanup FAILED:", matchId)
	return {
		destroyed = destroyed,
		teleportedCount = teleportedCount or 0,
		teleportedPlayers = teleportedPlayers or {},
	}
end

return MatchCleanup
