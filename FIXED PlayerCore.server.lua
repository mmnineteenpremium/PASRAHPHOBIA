local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 3, 0)
local FIXED_SAFE_LOBBY_POSITION = Vector3.new(1600, 15, 0)
local SPAWN_PROTECTION_SECONDS = 3

local function isPlayerInMatchState(player)
	return player:GetAttribute("InMatch") == true or player:GetAttribute("MatchId") ~= nil
end

local function isPlayerInLobbyState(player)
	return player:GetAttribute("InLobby") == true
end

local function setSpawnProtection(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end

	local protectUntil = os.clock() + SPAWN_PROTECTION_SECONDS
	player:SetAttribute("SpawnProtected", true)
	player:SetAttribute("SpawnProtectedUntil", protectUntil)

	task.delay(SPAWN_PROTECTION_SECONDS, function()
		if not player.Parent then
			return
		end
		local currentUntil = player:GetAttribute("SpawnProtectedUntil")
		if type(currentUntil) == "number" and currentUntil > os.clock() then
			return
		end
		player:SetAttribute("SpawnProtected", nil)
		player:SetAttribute("SpawnProtectedUntil", nil)
		print("[PlayerCore] 🛡️ Protection expired for", player.Name)
	end)
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
	local direct = Workspace:FindFirstChild(LOBBY_NAME)
	if direct then
		return direct
	end

	local mapsFolder = Workspace:FindFirstChild("Maps")
	if mapsFolder then
		local nested = mapsFolder:FindFirstChild(LOBBY_NAME)
		if nested then
			return nested
		end
	end

	local currentMap = Workspace:FindFirstChild("CurrentMap")
	if currentMap and currentMap.Name == LOBBY_NAME then
		return currentMap
	end

	return nil
end

local function resolveLobbySpawnParts()
	local lobbyRoot = resolveLobbyRoot()
	if not lobbyRoot then
		return {}
	end

	local lobbySpawn = lobbyRoot:FindFirstChild("LobbySpawn", true)
	if lobbySpawn and lobbySpawn:IsA("BasePart") then
		return { lobbySpawn }
	end

	local spawnFolder = lobbyRoot:FindFirstChild("SpawnPoints", true)
	local spawnParts = collectSpawnParts(spawnFolder, {})
	table.sort(spawnParts, function(a, b)
		return a.Name < b.Name
	end)
	if #spawnParts > 0 then
		return spawnParts
	end

	local spawnLocation = lobbyRoot:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		return { spawnLocation }
	end

	return {}
end

local function resolveSafeLobbySpawnCFrame()
	local lobbySpawn = Workspace:FindFirstChild("LobbySpawn", true)
	if lobbySpawn and lobbySpawn:IsA("BasePart") then
		return CFrame.new(lobbySpawn.Position + LOBBY_SPAWN_OFFSET), lobbySpawn.Position
	end

	return CFrame.new(FIXED_SAFE_LOBBY_POSITION), FIXED_SAFE_LOBBY_POSITION
end

local function spawnPlayerToLobby(player, character, source)
	-- ✅ CHANGED: If in match, protect and return early
	if isPlayerInMatchState(player) then
		setSpawnProtection(player)
		return
	end

	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		root = character and character:WaitForChild("HumanoidRootPart", 5)
	end
	if not root or not root:IsA("BasePart") then
		warn(string.format("[PlayerCore] [%s] Missing HumanoidRootPart for %s", tostring(source), player.Name))
		return
	end

	-- ✅ REMOVED: Gate check that was blocking new players
	-- OLD CODE: if not isPlayerInLobbyState(player) then return end
	
	-- ✅ CHANGED: Always spawn to lobby (for new join or returning from match)
	
	local spawnCFrame, spawnPosition = resolveSafeLobbySpawnCFrame()
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = spawnCFrame
	
	-- ✅ CHANGED: Set lobby state BEFORE protection (correct order)
	player:SetAttribute("InLobby", true)
	player:SetAttribute("InMatch", nil)   -- ✅ ADD: Clear match state
	player:SetAttribute("MatchId", nil)   -- ✅ ADD: Clear match ID
	
	-- ✅ CHANGED: ALWAYS set spawn protection for lobby
	setSpawnProtection(player)
	
	print(string.format("[PlayerCore] [%s] ✅ Spawned %s at %s with protection", tostring(source), player.Name, tostring(spawnPosition)))
end

local function onPlayerAdded(player)
    print("[PlayerCore] Player joined:", player.Name)
    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            spawnPlayerToLobby(player, character, "CharacterAdded")
        end)
    end)

    if player.Character then
        task.defer(function()
            spawnPlayerToLobby(player, player.Character, "OnPlayerAdded")
        end)
    end
end

local function onPlayerRemoving(player)
    print("[PlayerCore] Player leaving:", player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
