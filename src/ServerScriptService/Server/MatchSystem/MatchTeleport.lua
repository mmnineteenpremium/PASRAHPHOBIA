local MatchTeleport = {}
MatchTeleport.__index = MatchTeleport

local Workspace = game:GetService("Workspace")

local SAFE_MIN_SPAWN_Y = 5
local FLOOR_CHECK_DISTANCE = 50
local FLOOR_RAY_START_OFFSET = 10
local FLOOR_CLEARANCE = 4
local SPAWN_WAIT_TIMEOUT = 5
local SPAWN_WAIT_STEP = 0.1

local function getActiveMatchesFolder()
	local folder = Workspace:FindFirstChild("ActiveMatches")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ActiveMatches"
		folder.Parent = Workspace
	end
	return folder
end

local function getMatchContainer(match)
	local activeMatches = getActiveMatchesFolder()
	if type(match) ~= "table" then
		return activeMatches
	end

	local matchId = match.matchId or match.id
	if not matchId then
		return activeMatches
	end

	local expectedName = "Match_" .. tostring(matchId)
	local container = match.container
	if typeof(container) ~= "Instance" or not container:IsA("Folder") or container.Parent ~= activeMatches or container.Name ~= expectedName then
		container = activeMatches:FindFirstChild(expectedName)
	end

	if not container then
		container = Instance.new("Folder")
		container.Name = expectedName
		container.Parent = activeMatches
	end

	match.container = container
	return container
end

local function normalizeMapName(value)
	if type(value) ~= "string" then
		return nil, nil
	end
	local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return nil, nil
	end
	local token = trimmed:gsub("[%s_%-%.]+", ""):lower()
	return trimmed, token
end

local function resolveMapsFolder()
	local serverStorage = game:GetService("ServerStorage")
	local mapsFolder = serverStorage:FindFirstChild("Maps")
	if not mapsFolder then
		-- Rojo can sync this folder a moment after server scripts start in Studio.
		mapsFolder = serverStorage:WaitForChild("Maps", 10)
	end

	if mapsFolder and mapsFolder:IsA("Folder") and #mapsFolder:GetChildren() == 0 then
		local deadline = os.clock() + 3
		while #mapsFolder:GetChildren() == 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end

	return mapsFolder
end

local function findMapTemplateInFolder(mapsFolder, normalizedName, normalizedToken)
	if not mapsFolder then
		return nil, nil
	end

	local directMatch = mapsFolder:FindFirstChild(normalizedName)
	if directMatch then
		return directMatch, directMatch.Name
	end

	for _, child in ipairs(mapsFolder:GetChildren()) do
		local _, childToken = normalizeMapName(child.Name)
		if childToken and childToken == normalizedToken then
			return child, child.Name
		end

		-- Support maps wrapped in a folder where the root map model is one level deeper.
		if child:IsA("Folder") then
			local nestedDirect = child:FindFirstChild(normalizedName)
			if nestedDirect then
				return nestedDirect, nestedDirect.Name
			end

			for _, nested in ipairs(child:GetChildren()) do
				local _, nestedToken = normalizeMapName(nested.Name)
				if nestedToken and nestedToken == normalizedToken then
					return nested, nested.Name
				end
			end
		end
	end

	return nil, nil
end

local function resolveMapTemplate(mapName)
	local normalizedName, normalizedToken = normalizeMapName(mapName)
	if not normalizedName then
		return nil, nil, nil, nil
	end

	local mapsFolder = resolveMapsFolder()
	local mapTemplate, resolvedTemplateName = findMapTemplateInFolder(mapsFolder, normalizedName, normalizedToken)
	if mapTemplate then
		return mapTemplate, "ServerStorage.Maps", resolvedTemplateName, mapsFolder
	end

	if mapsFolder then
		return nil, "ServerStorage.Maps", normalizedName, mapsFolder
	end

	return nil, "ServerStorage.Maps", normalizedName, nil
end

local function computeMatchOffset(container)
	local index = 1
	if container and container.Parent then
		index = #container.Parent:GetChildren() + 1
	end
	local spacing = 3000
	return Vector3.new(index * spacing, 0, 0)
end

local function applyWorldOffset(instance, offset)
	local targetCFrame = CFrame.new(offset)

	if instance:IsA("Model") then
		if instance:FindFirstChildWhichIsA("BasePart", true) then
			instance:PivotTo(targetCFrame)
			return true
		end
		return false
	end

	if instance:IsA("BasePart") then
		instance.CFrame = targetCFrame
		return true
	end

	local nestedModel = instance:FindFirstChildWhichIsA("Model", true)
	if nestedModel and nestedModel:FindFirstChildWhichIsA("BasePart", true) then
		nestedModel:PivotTo(targetCFrame)
		return true
	end

	local nestedPart = instance:FindFirstChildWhichIsA("BasePart", true)
	if nestedPart then
		nestedPart.CFrame = targetCFrame
		return true
	end

	return false
end

local function getCharacterRoot(character)
	if not character then
		return nil
	end
	if character.PrimaryPart then
		return character.PrimaryPart
	end
	return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
end

local function extractSpawnCFrame(spawnNode)
	if not spawnNode then
		return nil
	end
	if spawnNode:IsA("BasePart") then
		return spawnNode.CFrame
	end
	if spawnNode:IsA("Model") then
		if spawnNode.PrimaryPart then
			return spawnNode.PrimaryPart.CFrame
		end
		local ok, pivot = pcall(function()
			return spawnNode:GetPivot()
		end)
		if ok then
			return pivot
		end
	end
	return nil
end

local function getSpawnCandidates(mapClone)
	local spawnFolder = mapClone and mapClone:FindFirstChild("SpawnPoints", true)
	if not spawnFolder then
		return {}
	end

	local candidates = {}
	for _, child in ipairs(spawnFolder:GetChildren()) do
		if child:IsA("BasePart") or child:IsA("Model") then
			table.insert(candidates, child)
		end
	end
	return candidates
end

local function waitForSpawnCandidates(mapClone)
	local deadline = os.clock() + SPAWN_WAIT_TIMEOUT
	repeat
		if mapClone and mapClone:IsDescendantOf(Workspace) then
			local candidates = getSpawnCandidates(mapClone)
			if #candidates > 0 then
				return candidates
			end
		end
		task.wait(SPAWN_WAIT_STEP)
	until os.clock() >= deadline

	return getSpawnCandidates(mapClone)
end

local function buildSafeSpawnCFrame(mapClone, rawCFrame)
	if not rawCFrame then
		return nil, "missing_spawn_cframe"
	end

	local rawPosition = rawCFrame.Position
	if rawPosition.Y < 0 then
		return nil, "spawn_below_zero_y"
	end

	local correctedPosition = Vector3.new(
		rawPosition.X,
		math.max(rawPosition.Y, SAFE_MIN_SPAWN_Y),
		rawPosition.Z
	)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { mapClone }
	rayParams.IgnoreWater = true

	local rayOrigin = correctedPosition + Vector3.new(0, FLOOR_RAY_START_OFFSET, 0)
	local rayDirection = Vector3.new(0, -(FLOOR_RAY_START_OFFSET + FLOOR_CHECK_DISTANCE), 0)
	local floorHit = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if not floorHit then
		return nil, "no_floor_within_50"
	end

	local floorY = floorHit.Position.Y
	local finalPosition = Vector3.new(
		correctedPosition.X,
		math.max(floorY + FLOOR_CLEARANCE, SAFE_MIN_SPAWN_Y),
		correctedPosition.Z
	)

	local rotation = rawCFrame - rawPosition
	return CFrame.new(finalPosition) * rotation, nil
end

local function resolveSafeSpawnCFrame(mapClone, spawnCandidates, preferredIndex)
	local orderedCandidates = {}
	local preferred = spawnCandidates[preferredIndex] or spawnCandidates[#spawnCandidates]
	if preferred then
		table.insert(orderedCandidates, preferred)
	end

	local explicitSpawn = mapClone and mapClone:FindFirstChild("SpawnLocation", true)
	if explicitSpawn and explicitSpawn:IsA("BasePart") then
		table.insert(orderedCandidates, explicitSpawn)
	end

	for _, candidate in ipairs(spawnCandidates) do
		if candidate ~= preferred then
			table.insert(orderedCandidates, candidate)
		end
	end

	if mapClone and mapClone:IsA("Model") then
		table.insert(orderedCandidates, mapClone)
	end

	for _, candidate in ipairs(orderedCandidates) do
		local candidateCFrame = extractSpawnCFrame(candidate)
		local safeCFrame, reason = buildSafeSpawnCFrame(mapClone, candidateCFrame)
		if safeCFrame then
			return safeCFrame, candidate
		end
		if reason == "spawn_below_zero_y" then
			warn("[MatchTeleport] Invalid spawn Y<0 for candidate:", candidate:GetFullName())
		end
	end

	return nil, nil
end

local function resolveTeleportService(deps)
	local service = deps.TeleportService
	if type(service) == "table" then
		return service
	end
	return nil
end

function MatchTeleport.new(deps, config)
	local self = setmetatable({}, MatchTeleport)
	self._deps = deps or {}
	self._config = config or {}
	self._teleportService = resolveTeleportService(self._deps)
	return self
end

function MatchTeleport:_teleport(player, placeId, options)
	if self._teleportService and type(self._teleportService.TeleportAsync) == "function" then
		local ok, err = pcall(function()
			self._teleportService:TeleportAsync(placeId, { player }, options)
		end)
		if not ok then
			return false, err
		end
	end
	return true
end

function MatchTeleport:TeleportPlayers(matchOrPlayers, mapName)
	local match = nil
	local players = nil
	local resolvedMapName = mapName
	local resolvedPlaceId = nil

	if type(matchOrPlayers) == "table" and matchOrPlayers.players then
		match = matchOrPlayers
		players = match.players or {}
		resolvedMapName = match.map or match.mapId or resolvedMapName
		resolvedPlaceId = match.mapReference or (self._config and self._config.MatchPlaceId)
	else
		players = matchOrPlayers or {}
	end

	local teleported = {}
	local mapTemplate, mapSource, resolvedTemplateName, mapsFolder = resolveMapTemplate(resolvedMapName)
	if mapTemplate then
		print("[MatchTeleport] Using map template:", resolvedTemplateName, "from", mapSource or "unknown")
		local mapClone = mapTemplate:Clone()
		local container = getMatchContainer(match)
		mapClone.Parent = container
		local offset = computeMatchOffset(container)
		if not applyWorldOffset(mapClone, offset) then
			warn("[MatchTeleport] Unable to apply map offset (no pivotable part):", mapClone:GetFullName())
		end

		local spawnPoints = waitForSpawnCandidates(mapClone)
		if #spawnPoints == 0 then
			warn("[MatchTeleport] SpawnPoints missing/empty after map load:", mapClone:GetFullName())
		end

		for index, player in ipairs(players) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				local character = player.Character
				local root = getCharacterRoot(character)
				local safeSpawnCFrame, usedSpawn = resolveSafeSpawnCFrame(mapClone, spawnPoints, index)
				if not safeSpawnCFrame then
					warn("[MatchTeleport] HARD FAIL SAFE SPAWN TRIGGERED")
					local fallbackPart = mapClone:FindFirstChildWhichIsA("BasePart", true)
					if fallbackPart then
						safeSpawnCFrame = fallbackPart.CFrame + Vector3.new(0, 6, 0)
					else
						warn("[MatchTeleport] NO VALID SPAWN, SKIP PLAYER")
						continue
					end
				end

				if not root then
					local playerName = player and player.Name or "Unknown"
					warn(string.format("[MatchTeleport] Skip teleport for %s (invalid root).", playerName))
					continue
				end

				player:SetAttribute("SpawnProtected", true)
				player:SetAttribute("SpawnProtectedUntil", os.clock() + 3)
				root.CFrame = safeSpawnCFrame
				player:SetAttribute("InMatch", true)
				if match and (match.matchId or match.id) then
					player:SetAttribute("MatchId", tostring(match.matchId or match.id))
				end
				if usedSpawn then
					print(string.format("[MatchTeleport] Spawned %s at %s via %s", player.Name, tostring(safeSpawnCFrame.Position), usedSpawn.Name))
				end
				table.insert(teleported, player)
			end
		end

		print("[MatchTeleport] Teleported players to map", resolvedTemplateName or resolvedMapName)
		return teleported
	end

	local sourceLabel = mapSource or "ServerStorage.Maps"
	warn(string.format("[MatchTeleport] Map template not found in %s: %s", sourceLabel, tostring(resolvedMapName)))
	if not mapsFolder then
		warn("[MatchTeleport] No maps folder found in ServerStorage. Check Rojo sync for src/ServerStorage/Maps.")
	end
	if mapsFolder then
		local availableNames = {}
		for _, child in ipairs(mapsFolder:GetChildren()) do
			table.insert(availableNames, child.Name)
		end
		table.sort(availableNames)
		warn("[MatchTeleport] Available maps:", table.concat(availableNames, ", "))
	end

	if resolvedPlaceId then
		for _, player in ipairs(players or {}) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				local ok = self:_teleport(player, resolvedPlaceId, nil)
				if ok then
					table.insert(teleported, player)
				end
			end
		end
	end

	return teleported
end

function MatchTeleport:ReturnPlayersToLobby(match)
	local teleported = {}
	local lobbyPlaceId = self._config.LobbyPlaceId

	for _, player in ipairs(match.players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			local ok = true
			if lobbyPlaceId then
				ok = self:_teleport(player, lobbyPlaceId, nil)
			end
			if ok then
				player:SetAttribute("InMatch", false)
				player:SetAttribute("MatchId", nil)
				table.insert(teleported, player)
			end
		end
	end

	return teleported
end

return MatchTeleport
