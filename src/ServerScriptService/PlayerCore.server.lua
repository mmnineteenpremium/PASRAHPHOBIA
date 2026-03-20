local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 3, 0)

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

local function spawnPlayerToLobby(player, character, source)
	if player:GetAttribute("InMatch") == true then
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

	local spawnParts = resolveLobbySpawnParts()
	if #spawnParts == 0 then
		warn(string.format("[PlayerCore] [%s] Lobby spawn unresolved for %s", tostring(source), player.Name))
		return
	end

	local index = (player.UserId % #spawnParts) + 1
	local spawnPart = spawnParts[index]
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = spawnPart.CFrame + LOBBY_SPAWN_OFFSET
	player:SetAttribute("InLobby", true)
	print(string.format("[PlayerCore] [%s] Fallback spawned %s at %s", tostring(source), player.Name, tostring(spawnPart.Position)))
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
