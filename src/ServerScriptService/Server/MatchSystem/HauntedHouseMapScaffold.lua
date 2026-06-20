local Layout = require(script.Parent.HauntedHouseRuntimeLayout)

local Scaffold = {}

local DEFAULT_PROXY_SIZE = Vector3.new(2.5, 7, 2.5)

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function ensurePart(parent, name)
	local part = parent:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part
	end
	if part then
		part:Destroy()
	end
	part = Instance.new("Part")
	part.Name = name
	part.Parent = parent
	return part
end

local function configureProxyPart(part, position, size)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = false
	part.Transparency = 1
	part.Material = Enum.Material.ForceField
	part.Size = size or DEFAULT_PROXY_SIZE
	part.CFrame = CFrame.new(position)
	return part
end

local function stampTargetQuery(part, definition)
	if not (part and definition) then
		return
	end
	part:SetAttribute("PasrahRuntimeRoomId", definition.roomId)
	part:SetAttribute("PasrahTargetRootName", definition.targetRootName)
	part:SetAttribute("PasrahTargetName", definition.targetName)
	part:SetAttribute("PasrahTargetMode", definition.mode)
	if typeof(definition.expectedPosition) == "Vector3" then
		part:SetAttribute("PasrahTargetPosition", tostring(definition.expectedPosition))
	end
	if definition.advanceFromPreparation == true then
		part:SetAttribute("PasrahPreparationAdvanceDoor", true)
		part:SetAttribute("DoorTraversalPolicy", "PromptManual")
	end
end

local function buildRooms(mapClone)
	local roomsFolder = ensureFolder(mapClone, "Rooms")
	for _, room in ipairs(Layout.rooms) do
		local part = ensurePart(roomsFolder, "Room_" .. room.roomId)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = true
		part.CastShadow = false
		part.Transparency = 1
		part.Size = room.size
		part.CFrame = CFrame.new(room.center)
		part:SetAttribute("RoomId", room.roomId)
		part:SetAttribute("Floor", room.floor)
		part:SetAttribute("PasrahRoomId", room.roomId)
		part:SetAttribute("PasrahRoomFloor", room.floor)
	end
	return roomsFolder
end

local function buildInteractionPoints(mapClone)
	local folder = ensureFolder(mapClone, "InteractionPoints")
	for _, room in ipairs(Layout.rooms) do
		local part = ensurePart(folder, "Interact_" .. room.roomId)
		configureProxyPart(part, room.center + Vector3.new(0, 1.5, 0), Vector3.new(1, 1, 1))
		part:SetAttribute("PasrahRuntimeRoomId", room.roomId)
	end
	return folder
end

local function buildSpawnPoints(mapClone)
	local folder = ensureFolder(mapClone, "SpawnPoints")
	for _, spawn in ipairs(Layout.spawnPoints) do
		local existing = folder:FindFirstChild(spawn.name)
		if existing and existing:IsA("BasePart") then
			existing.Anchored = true
			existing.CanCollide = false
			existing.CanTouch = false
			existing.CanQuery = true
			existing.CastShadow = false
			existing.Transparency = 1
			existing.Size = Vector3.new(1, 1, 1)
		else
			local part = ensurePart(folder, spawn.name)
			configureProxyPart(part, spawn.position, Vector3.new(1, 1, 1))
		end
	end
	return folder
end

local function buildSafeZones(mapClone)
	local folder = ensureFolder(mapClone, "SafeZones")
	for _, safeZone in ipairs(Layout.safeZones) do
		local existing = folder:FindFirstChild(safeZone.name)
		if existing and existing:IsA("BasePart") then
			existing.Anchored = true
			existing.CanCollide = false
			existing.CanTouch = false
			existing.CanQuery = true
			existing.CastShadow = false
			existing.Transparency = 1
			existing.Size = Vector3.new(4, 7, 4)
		else
			local part = ensurePart(folder, safeZone.name)
			configureProxyPart(part, safeZone.position, Vector3.new(4, 7, 4))
		end
	end
	return folder
end

local function buildGhostSpawns(mapClone)
	local folder = ensureFolder(mapClone, "GhostSpawns")
	for _, spawn in ipairs(Layout.ghostSpawns) do
		local part = ensurePart(folder, spawn.name)
		configureProxyPart(part, spawn.position, Vector3.new(3, 7, 3))
		part:SetAttribute("GhostSpawn", true)
		part:SetAttribute("PasrahRuntimeRoomId", spawn.roomId)
	end
	for _, child in ipairs(folder:GetChildren()) do
		local expected = false
		for _, spawn in ipairs(Layout.ghostSpawns) do
			if child.Name == spawn.name then
				expected = true
				break
			end
		end
		if child:IsA("BasePart") and not expected then
			child:Destroy()
		end
	end
	return folder
end

local function buildEvidenceNodes(mapClone)
	local folder = ensureFolder(mapClone, "EvidenceSpawnNodes")
	for _, node in ipairs(Layout.evidenceNodes) do
		local part = ensurePart(folder, node.name)
		configureProxyPart(part, node.position, Vector3.new(1, 1, 1))
		part:SetAttribute("PasrahRuntimeRoomId", node.roomId)
	end
	return folder
end

local function buildDoorProxies(mapClone)
	local folder = ensureFolder(mapClone, "Doors")
	for _, door in ipairs(Layout.doors) do
		local part = ensurePart(folder, door.objectId)
		configureProxyPart(part, door.proxyPosition, DEFAULT_PROXY_SIZE)
		part:SetAttribute("DoorLabel", door.label)
		stampTargetQuery(part, door)
	end
	return folder
end

local function buildRuntimeObjectFolder(mapClone, folderName, definitions)
	local folder = ensureFolder(mapClone, folderName)
	for _, definition in ipairs(definitions) do
		local part = ensurePart(folder, definition.objectId)
		configureProxyPart(part, definition.proxyPosition, Vector3.new(1.8, 2.4, 1.8))
		stampTargetQuery(part, definition)
		if definition.generated then
			part:SetAttribute("PasrahGeneratedKind", definition.generated.kind)
			part:SetAttribute("PasrahGeneratedPosition", tostring(definition.generated.position))
		end
	end
	return folder
end

function Scaffold.Build(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return false
	end
	buildRooms(mapClone)
	buildInteractionPoints(mapClone)
	buildSpawnPoints(mapClone)
	buildSafeZones(mapClone)
	buildGhostSpawns(mapClone)
	buildEvidenceNodes(mapClone)
	buildDoorProxies(mapClone)
	buildRuntimeObjectFolder(mapClone, "Lights", Layout.lights)
	buildRuntimeObjectFolder(mapClone, "Props", Layout.props)
	buildRuntimeObjectFolder(mapClone, "Electronics", Layout.electronics)
	buildRuntimeObjectFolder(mapClone, "Windows", Layout.windows)
	return true
end

return Scaffold
