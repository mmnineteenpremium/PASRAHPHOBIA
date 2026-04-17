local Layout = require(script.Parent.EmptyBuildingRuntimeLayout)

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

local function ensureModel(parent, name)
	local model = parent:FindFirstChild(name)
	if model and model:IsA("Model") then
		return model
	end
	if model then
		model:Destroy()
	end
	model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
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

local function configureVisiblePart(part, cframe, size, material, color)
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = true
	part.Transparency = 0
	part.Material = material or Enum.Material.Concrete
	part.Color = color or Color3.fromRGB(96, 98, 104)
	part.Size = size
	part.CFrame = cframe
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

local function clearNativeSpawnLocations(mapClone)
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("SpawnLocation") then
			descendant:Destroy()
		end
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

local function buildStairFlight(parent, name, startPos, riseDir, forwardDir)
	local model = ensureModel(parent, name)
	local normalizedForward = forwardDir.Unit
	local normalizedRise = riseDir.Unit
	local tread = 2.0
	local rise = 1.0
	local steps = 12
	for index = 1, steps do
		local step = ensurePart(model, "Step_" .. tostring(index))
		local offsetForward = normalizedForward * ((index - 1) * tread)
		local offsetRise = normalizedRise * ((index - 1) * rise)
		local pos = startPos + offsetForward + offsetRise
		configureVisiblePart(
			step,
			CFrame.lookAt(pos, pos + normalizedForward, Vector3.yAxis),
			Vector3.new(6, 1, tread),
			Enum.Material.Metal,
			Color3.fromRGB(86, 90, 98)
		)
	end
end

local function buildLadder(parent, name, basePos)
	local model = ensureModel(parent, name)
	local leftRail = ensurePart(model, "LeftRail")
	configureVisiblePart(
		leftRail,
		CFrame.new(basePos + Vector3.new(-1.2, 6.5, 0)),
		Vector3.new(0.35, 13, 0.35),
		Enum.Material.Metal,
		Color3.fromRGB(120, 124, 132)
	)
	local rightRail = ensurePart(model, "RightRail")
	configureVisiblePart(
		rightRail,
		CFrame.new(basePos + Vector3.new(1.2, 6.5, 0)),
		Vector3.new(0.35, 13, 0.35),
		Enum.Material.Metal,
		Color3.fromRGB(120, 124, 132)
	)
	for rung = 1, 8 do
		local step = ensurePart(model, "Rung_" .. tostring(rung))
		configureVisiblePart(
			step,
			CFrame.new(basePos + Vector3.new(0, 1 + (rung * 1.35), 0)),
			Vector3.new(2.7, 0.2, 0.35),
			Enum.Material.Metal,
			Color3.fromRGB(136, 140, 148)
		)
	end
end

local function buildFillerProps(parent)
	local model = ensureModel(parent, "FillerProps")
	local filler = {
		{ "LobbySofa", Vector3.new(812, 1, -27), Vector3.new(5.5, 2.2, 2.4), Enum.Material.Fabric, Color3.fromRGB(72, 76, 88) },
		{ "LobbyShelf", Vector3.new(786, 2, -10), Vector3.new(1.8, 4, 6.2), Enum.Material.Metal, Color3.fromRGB(84, 88, 96) },
		{ "StorageRackA", Vector3.new(826, 2.2, -16), Vector3.new(2.0, 4.4, 7.0), Enum.Material.Metal, Color3.fromRGB(86, 90, 98) },
		{ "StorageRackB", Vector3.new(834, 2.2, -24), Vector3.new(2.0, 4.4, 7.0), Enum.Material.Metal, Color3.fromRGB(86, 90, 98) },
		{ "ServerRackA", Vector3.new(770, 14.2, -26), Vector3.new(2.2, 4.4, 2.2), Enum.Material.Metal, Color3.fromRGB(36, 42, 52) },
		{ "ServerRackB", Vector3.new(780, 14.2, -34), Vector3.new(2.2, 4.4, 2.2), Enum.Material.Metal, Color3.fromRGB(36, 42, 52) },
		{ "MeetingTable", Vector3.new(820, 13.8, -26), Vector3.new(8.0, 1.1, 3.6), Enum.Material.WoodPlanks, Color3.fromRGB(88, 74, 62) },
	}
	for _, def in ipairs(filler) do
		local part = ensurePart(model, def[1])
		configureVisiblePart(
			part,
			CFrame.new(def[2]),
			def[3],
			def[4],
			def[5]
		)
	end
end

local function buildStructuralDecor(mapClone)
	local decor = ensureFolder(mapClone, "RuntimeDecor")
	buildStairFlight(
		decor,
		"NorthStairs",
		Vector3.new(803, 1.0, -53.0),
		Vector3.new(0, 1, 0),
		Vector3.new(0, 0, 1)
	)
	buildStairFlight(
		decor,
		"SouthStairs",
		Vector3.new(797, 1.0, 53.0),
		Vector3.new(0, 1, 0),
		Vector3.new(0, 0, -1)
	)
	buildLadder(decor, "ServiceLadder", Vector3.new(810, 1.0, 6.0))
	buildFillerProps(decor)
end

function Scaffold.Build(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return false
	end
	clearNativeSpawnLocations(mapClone)
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
	buildStructuralDecor(mapClone)
	return true
end

return Scaffold
