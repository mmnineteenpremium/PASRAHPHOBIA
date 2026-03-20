local MatchTeleport = {}
MatchTeleport.__index = MatchTeleport

local function getActiveMatchesFolder()
	local workspace = game:GetService("Workspace")
	local folder = workspace:FindFirstChild("ActiveMatches")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ActiveMatches"
		folder.Parent = workspace
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

		local spawnFolder = mapClone:FindFirstChild("SpawnPoints", true)
		local spawnPoints = spawnFolder and spawnFolder:GetChildren() or {}

		for index, player in ipairs(players) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				local character = player.Character
				local root = getCharacterRoot(character)
				local spawn = spawnPoints[index] or spawnPoints[#spawnPoints]
				if root and spawn and spawn:IsA("BasePart") then
					root.CFrame = spawn.CFrame
				elseif root and spawn and spawn:IsA("Model") and spawn.PrimaryPart then
					root.CFrame = spawn.PrimaryPart.CFrame
				end
				player:SetAttribute("InMatch", true)
				if match and (match.matchId or match.id) then
					player:SetAttribute("MatchId", tostring(match.matchId or match.id))
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
