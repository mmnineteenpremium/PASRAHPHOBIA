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

local MatchCleanup = {}

-- Configuration
local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 3, 0)
local LOBBY_SPAWN_MAX_DELTA_XZ = 350
local LOBBY_MIN_Y = -50

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
	local direct = workspace:FindFirstChild(LOBBY_NAME)
	if direct then
		return direct
	end

	local mapsFolder = workspace:FindFirstChild("Maps")
	if mapsFolder then
		local nested = mapsFolder:FindFirstChild(LOBBY_NAME)
		if nested then
			return nested
		end
	end

	local currentMap = workspace:FindFirstChild("CurrentMap")
	if currentMap and currentMap.Name == LOBBY_NAME then
		return currentMap
	end

	return nil
end

local function isValidLobbySpawnPart(lobbyRoot, spawnPart)
	if not (spawnPart and spawnPart:IsA("BasePart")) then
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

local function resolveLobbySpawnPart()
	local lobby = resolveLobbyRoot()
	if lobby then
		local lobbySpawn = lobby:FindFirstChild("LobbySpawn", true)
		if isValidLobbySpawnPart(lobby, lobbySpawn) then
			return lobbySpawn
		end

		local spawnFolder = lobby:FindFirstChild("SpawnPoints", true)
		local spawnParts = collectSpawnParts(spawnFolder)
		table.sort(spawnParts, function(a, b)
			return a.Name < b.Name
		end)
		for _, spawnPart in ipairs(spawnParts) do
			if isValidLobbySpawnPart(lobby, spawnPart) then
				return spawnPart
			end
		end

		local spawnLocation = lobby:FindFirstChildWhichIsA("SpawnLocation", true)
		if isValidLobbySpawnPart(lobby, spawnLocation) then
			return spawnLocation
		end
	end

	local directSpawn = workspace:FindFirstChild("LobbySpawn")
	if isValidLobbySpawnPart(lobby, directSpawn) then
		return directSpawn
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

	local lobbySpawn, spawnReason = resolveLobbySpawnPart()
	if not lobbySpawn then
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
			if hrp and lobbySpawn then
				hrp.CFrame = lobbySpawn.CFrame + LOBBY_SPAWN_OFFSET
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
