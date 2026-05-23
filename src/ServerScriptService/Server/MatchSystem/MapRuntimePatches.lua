local MapRuntimePatches = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FLOOR_PATCH_ATTR = "SecondFloorRuntimePatched"
local INTERACTION_PATCH_ATTR = "InteractionPointsRuntimePatched"
local DOOR_PATCH_ATTR = "DoorTraversalRuntimePatched"
local SAFE_ZONE_PATCH_ATTR = "SafeZoneRuntimePatched"
local MATERIAL_PATCH_ATTR = "MapMaterialRuntimePatched"
local MATERIAL_PATCH_VERSION_ATTR = "MapMaterialRuntimePatchVersion"
local MATERIAL_PATCH_VERSION = 3
local TRAVERSAL_GUIDE_PATCH_ATTR = "TraversalGuideRuntimePatched"
local PLAYABLE_FLOOR_PATCH_ATTR = "RuntimePlayableFloorPatched"
local LOGIC_VOLUME_PATCH_ATTR = "LogicVolumesRuntimeHidden"
local LEGACY_ASSET_SCRIPTS_DISABLED_ATTR = "LegacyAssetScriptsDisabled"
local PREPARATION_STAGING_PATCH_ATTR = "PreparationStagingRuntimePatched"
local BOUNDARY_PATCH_ATTR = "RuntimeBoundaryPatched"
local PREPARATION_STAGING_FOLDER_NAME = "PreparationStagingRuntime"
local PREPARATION_STAGING_DEBUG_ATTR = "PreparationStagingRuntimeDebug"
local PREPARATION_LANE_STATE_ATTR = "PreparationEntryLaneState"
local PREPARATION_BREACH_MOVED_ATTR = "PreparationBreachMoved"
local ABANDONED_PALACE_ALIGNMENT_PATCH_ATTR = "AbandonedPalaceAuthoringAlignmentPatched"
local DOOR_MODE_ATTR = "DoorTraversalMode"
local DOOR_POLICY_ATTR = "DoorTraversalPolicy"
local DOOR_OPEN_SOUND_ATTR = "DoorOpenSoundId"
local DOOR_CLOSE_SOUND_ATTR = "DoorCloseSoundId"
local DEFAULT_DOOR_POLICY = "HybridRadiusPrompt"
local DEFAULT_DOOR_OPEN_SOUND_ID = "rbxassetid://119680795545028"
local DEFAULT_DOOR_CLOSE_SOUND_ID = "rbxassetid://79226838058023"
local MIN_SEGMENT_SIZE = 0.25
local PREPARATION_TWEEN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PREPARATION_FAST_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PREPARATION_TOOL_PROXIMITY_RADIUS = 3.25
local PREPARATION_TOOL_AUTOSELECT_DELAY = 2.5
local PREPARATION_STAGING_ROOM_ESCAPE_STEP = 8
local PREPARATION_STAGING_ROOM_ESCAPE_MAX_STEPS = 8
local PREPARATION_FORCE_MAINFLOOR_STAGING = true
local PREPARATION_MAINFLOOR_STAGE_DISTANCE = 8.5
local PREPARATION_MAINFLOOR_ESCAPE_MAX_STEPS = 0
local PREPARATION_HIDE_SYNTHETIC_FLOOR = true
local STAIR_MARGIN = 0.75
local INTERACTION_HEIGHT_OFFSET = 1.5
local TRAVERSAL_GUIDE_FOLDER_NAME = "TraversalGuideRuntime"
local TRAVERSAL_GUIDE_HIGHLIGHT_NAME = "Highlight"
local TRAVERSAL_GUIDE_BILLBOARD_NAME = "Billboard"
local INTERACTION_GUIDE_FOLDER_NAME = "InteractionGuideRuntime"
local INTERACTION_GUIDE_BILLBOARD_NAME = "Billboard"
local PLAYER_FACING_GUIDE_VISUALS_ENABLED = false
local LOGIC_VOLUME_VISUAL_TRANSPARENCY = 1
-- Canonical source-of-truth maps now author spawn/safezone/staging directly in the map asset.
-- Keep runtime overrides disabled unless explicitly re-enabled for legacy maps.
local USE_LEGACY_SAFEZONE_OVERRIDES = false
local STRICT_AUTHORED_MAP_RUNTIME = true
local MAINFLOOR_PATCH_ATTR = "RuntimeMainfloorPatched"
local LOGIC_VOLUME_FOLDER_NAMES = {
	"Rooms",
	"SafeZones",
	"InteractionPoints",
	"NavigationNodes",
	"EvidenceSpawnNodes",
	"EvidenceSpawns",
	"SpawnPoints",
}
local INTERACTION_POSITION_OVERRIDES = {
}
local INTERACTION_DOOR_OVERRIDES = {
	hauntedhouse = {
		Interact_Bedroom1 = {
			doorName = "Door_Bedroom1",
			insideOffset = 5,
		},
		Interact_Kitchen = {
			doorName = "Door_Kitchen",
			insideOffset = 5,
		},
	},
	emptybuilding = {
		Interact_WorkspaceOpen = {
			doorName = "Door_WorkspaceOpen",
			insideOffset = 6,
		},
		Interact_OfficeB = {
			doorName = "Door_OfficeB",
			insideOffset = 5,
		},
		Interact_Bathroom1 = {
			doorName = "Door_Bathroom1",
			insideOffset = 4,
		},
	},
}
local SAFE_ZONE_POSITION_OVERRIDES = {
	hauntedhouse = {
		SafeZone_1 = Vector3.new(-30.5, 50.5, -25.0),
		SafeZone_2 = Vector3.new(-16.5, 50.5, -25.0),
	},
	abandonedpalace = {
		SafeZone_1 = Vector3.new(-63.2, 4, 32.4),
	},
	emptybuilding = {
		SafeZone_1 = Vector3.new(778, 4, -10),
		SafeZone_2 = Vector3.new(824, 4, -20),
	},
	studiommnineteen = {
		SafeZone_1 = Vector3.new(-19.0, 10.2, -20.5),
		SafeZone_2 = Vector3.new(-15.8, 10.2, -22.3),
	},
}
local PRIMARY_ENTRY_DOOR_BY_TOKEN = {
	hauntedhouse = "Door_FrontEntry",
	studiommnineteen = "Door_FrontEntry",
	emptybuilding = "Door_Lobby",
	abandonedpalace = "Door_GrandHall",
}
local MAINFLOOR_REQUIRED_TOKENS = {
	studiommnineteen = true,
	emptybuilding = true,
	abandonedpalace = true,
}
local PLAYABLE_FLOOR_REQUIRED_TOKENS = {
	abandonedpalace = true,
	emptybuilding = true,
	studiommnineteen = true,
}

local MAP_MATERIAL_POLISH = {
	hauntedhouse = {
		floorMaterial = Enum.Material.WoodPlanks,
		floorColor = Color3.fromRGB(58, 46, 38),
		wallMaterial = Enum.Material.WoodPlanks,
		wallColor = Color3.fromRGB(74, 58, 48),
		doorMaterial = Enum.Material.Wood,
		doorColor = Color3.fromRGB(88, 60, 40),
		windowMaterial = Enum.Material.Glass,
		windowColor = Color3.fromRGB(164, 178, 194),
		windowTransparency = 0.42,
		windowReflectance = 0.03,
		lightColor = Color3.fromRGB(255, 214, 170),
		lightBrightnessScale = 0.36,
		foliageMaterial = Enum.Material.LeafyGrass,
		foliageColor = Color3.fromRGB(18, 25, 20),
		trunkMaterial = Enum.Material.Wood,
		trunkColor = Color3.fromRGB(38, 28, 20),
		soilMaterial = Enum.Material.Ground,
		soilColor = Color3.fromRGB(28, 23, 18),
	},
	emptybuilding = {
		floorMaterial = Enum.Material.Concrete,
		floorColor = Color3.fromRGB(58, 60, 66),
		wallMaterial = Enum.Material.Concrete,
		wallColor = Color3.fromRGB(78, 82, 90),
		doorMaterial = Enum.Material.Metal,
		doorColor = Color3.fromRGB(78, 82, 88),
		windowMaterial = Enum.Material.Glass,
		windowColor = Color3.fromRGB(170, 186, 202),
		windowTransparency = 0.4,
		windowReflectance = 0.02,
		lightColor = Color3.fromRGB(214, 226, 255),
		lightBrightnessScale = 0.42,
		foliageMaterial = Enum.Material.LeafyGrass,
		foliageColor = Color3.fromRGB(22, 28, 26),
		trunkMaterial = Enum.Material.Wood,
		trunkColor = Color3.fromRGB(40, 32, 26),
		soilMaterial = Enum.Material.Ground,
		soilColor = Color3.fromRGB(34, 34, 32),
	},
	abandonedpalace = {
		floorMaterial = Enum.Material.Slate,
		floorColor = Color3.fromRGB(54, 50, 58),
		wallMaterial = Enum.Material.Marble,
		wallColor = Color3.fromRGB(96, 86, 80),
		doorMaterial = Enum.Material.Wood,
		doorColor = Color3.fromRGB(102, 76, 58),
		windowMaterial = Enum.Material.Glass,
		windowColor = Color3.fromRGB(182, 174, 168),
		windowTransparency = 0.36,
		windowReflectance = 0.04,
		lightColor = Color3.fromRGB(255, 208, 164),
		lightBrightnessScale = 0.38,
		foliageMaterial = Enum.Material.LeafyGrass,
		foliageColor = Color3.fromRGB(24, 22, 20),
		trunkMaterial = Enum.Material.Wood,
		trunkColor = Color3.fromRGB(44, 32, 24),
		soilMaterial = Enum.Material.Ground,
		soilColor = Color3.fromRGB(32, 26, 22),
	},
	studiommnineteen = {
		floorMaterial = Enum.Material.Concrete,
		floorColor = Color3.fromRGB(68, 72, 80),
		wallMaterial = Enum.Material.SmoothPlastic,
		wallColor = Color3.fromRGB(86, 92, 104),
		doorMaterial = Enum.Material.Metal,
		doorColor = Color3.fromRGB(92, 98, 108),
		windowMaterial = Enum.Material.Glass,
		windowColor = Color3.fromRGB(176, 192, 208),
		windowTransparency = 0.34,
		windowReflectance = 0.03,
		lightColor = Color3.fromRGB(228, 234, 255),
		lightBrightnessScale = 0.4,
		foliageMaterial = Enum.Material.LeafyGrass,
		foliageColor = Color3.fromRGB(20, 26, 28),
		trunkMaterial = Enum.Material.Wood,
		trunkColor = Color3.fromRGB(38, 30, 24),
		soilMaterial = Enum.Material.Ground,
		soilColor = Color3.fromRGB(30, 32, 34),
	},
}

local PREPARATION_STAGING_PROFILES = {
	hauntedhouse = {
		anchorRoomName = "Room_Foyer",
		anchorDoorName = "Door_FrontEntry",
		platformWidth = 28,
		platformDepth = 18,
		stagingDistance = 18,
		siteLabel = "CONTRACT BAY",
		siteSubtitle = "Room • Contract • Tools",
		contractExtraLine = "Hold porch staging before entering the house.",
		entryTitle = "MAIN ENTRY",
		entryReadyBody = "Review board lalu breach dari porch utama.",
		entryArmedBodyTemplate = "Aktifkan breach untuk sweep awal dengan %s.",
		entryOpenBody = "Masuk ke foyer rumah dan sweep area inti.",
		propStyle = "house",
		platformMaterial = Enum.Material.WoodPlanks,
		platformColor = Color3.fromRGB(76, 60, 46),
		runnerMaterial = Enum.Material.WoodPlanks,
		forecourtMaterial = Enum.Material.Asphalt,
		forecourtColor = Color3.fromRGB(48, 50, 58),
		canopyMaterial = Enum.Material.WoodPlanks,
		canopyColor = Color3.fromRGB(58, 46, 38),
		frameMaterial = Enum.Material.Wood,
		frameColor = Color3.fromRGB(92, 72, 58),
		boardMaterial = Enum.Material.WoodPlanks,
		boardColor = Color3.fromRGB(40, 32, 28),
		deskMaterial = Enum.Material.WoodPlanks,
		deskColor = Color3.fromRGB(92, 66, 48),
		rackMaterial = Enum.Material.SmoothPlastic,
		rackColor = Color3.fromRGB(54, 60, 72),
		caseColor = Color3.fromRGB(78, 72, 66),
		readyAccent = Color3.fromRGB(214, 160, 104),
		armedAccent = Color3.fromRGB(132, 186, 255),
		breachAccent = Color3.fromRGB(142, 214, 198),
		runnerReadyColor = Color3.fromRGB(98, 84, 70),
		runnerArmedColor = Color3.fromRGB(72, 104, 146),
		runnerBreachColor = Color3.fromRGB(72, 138, 122),
		floodReadyColor = Color3.fromRGB(214, 228, 255),
		floodArmedColor = Color3.fromRGB(178, 214, 255),
		floodBreachColor = Color3.fromRGB(174, 255, 236),
		floodReadyBrightness = 1.25,
		floodArmedBrightness = 1.45,
		floodBreachBrightness = 1.7,
		lampReadyColor = Color3.fromRGB(255, 214, 170),
		lampArmedColor = Color3.fromRGB(184, 214, 255),
		lampBreachColor = Color3.fromRGB(190, 255, 236),
		lampReadyBrightness = 0.65,
		lampArmedBrightness = 0.78,
		lampBreachBrightness = 0.9,
	},
	abandonedpalace = {
		anchorRoomName = "Room_GrandHall",
		anchorDoorName = "Door_GrandHall",
		platformWidth = 30,
		platformDepth = 18,
		stagingDistance = 20,
		siteLabel = "PALACE GATE",
		siteSubtitle = "Ward • Briefing • Breach",
		contractExtraLine = "Ward the palace threshold before entry.",
		entryTitle = "PALACE ENTRY",
		entryReadyBody = "Review board lalu breach dari gerbang istana.",
		entryArmedBodyTemplate = "Aktifkan breach untuk sweep awal dengan %s.",
		entryOpenBody = "Masuk ke grand hall dan sweep sayap utama.",
		propStyle = "palace",
		platformMaterial = Enum.Material.Marble,
		platformColor = Color3.fromRGB(112, 98, 90),
		runnerMaterial = Enum.Material.Fabric,
		forecourtMaterial = Enum.Material.Slate,
		forecourtColor = Color3.fromRGB(58, 52, 58),
		canopyMaterial = Enum.Material.Marble,
		canopyColor = Color3.fromRGB(118, 108, 102),
		frameMaterial = Enum.Material.Marble,
		frameColor = Color3.fromRGB(146, 136, 128),
		boardMaterial = Enum.Material.Metal,
		boardColor = Color3.fromRGB(52, 42, 38),
		deskMaterial = Enum.Material.Marble,
		deskColor = Color3.fromRGB(118, 106, 98),
		rackMaterial = Enum.Material.Metal,
		rackColor = Color3.fromRGB(86, 76, 70),
		caseColor = Color3.fromRGB(90, 82, 78),
		readyAccent = Color3.fromRGB(232, 176, 126),
		armedAccent = Color3.fromRGB(144, 182, 255),
		breachAccent = Color3.fromRGB(170, 236, 214),
		runnerReadyColor = Color3.fromRGB(108, 48, 48),
		runnerArmedColor = Color3.fromRGB(84, 98, 148),
		runnerBreachColor = Color3.fromRGB(72, 142, 126),
		floodReadyColor = Color3.fromRGB(255, 224, 190),
		floodArmedColor = Color3.fromRGB(188, 218, 255),
		floodBreachColor = Color3.fromRGB(182, 255, 236),
		floodReadyBrightness = 1.35,
		floodArmedBrightness = 1.55,
		floodBreachBrightness = 1.8,
		lampReadyColor = Color3.fromRGB(255, 198, 150),
		lampArmedColor = Color3.fromRGB(188, 214, 255),
		lampBreachColor = Color3.fromRGB(198, 255, 234),
		lampReadyBrightness = 0.7,
		lampArmedBrightness = 0.82,
		lampBreachBrightness = 0.95,
	},
	emptybuilding = {
		anchorRoomName = "Room_Lobby",
		anchorDoorName = "Door_Lobby",
		platformWidth = 26,
		platformDepth = 16,
		stagingDistance = 16,
		siteLabel = "OPERATIONS ENTRY",
		siteSubtitle = "Check • Brief • Breach",
		entryTitle = "MAIN ENTRY",
		entryReadyBody = "Review board lalu breach dari akses utama.",
		entryArmedBodyTemplate = "Aktifkan breach untuk sweep awal dengan %s.",
		entryOpenBody = "Masuk ke bangunan dan mulai sweep awal.",
		propStyle = "facility",
		propVariant = "industrial",
	},
	studiommnineteen = {
		anchorRoomName = "Room_LivingRoom",
		anchorDoorName = "Door_FrontEntry",
		platformWidth = 26,
		platformDepth = 16,
		stagingDistance = 16,
		siteLabel = "FRONT GATE",
		siteSubtitle = "Plan • Tools • Entry",
		entryTitle = "FRONT ENTRY",
		entryReadyBody = "Review board lalu breach dari pintu depan.",
		entryArmedBodyTemplate = "Aktifkan breach untuk sweep awal dengan %s.",
		entryOpenBody = "Masuk ke pintu depan dan mulai investigasi.",
		propStyle = "facility",
		propVariant = "residential",
	},
}

local PREPARATION_OBJECTIVE_TEMPLATE = {
	primary = {
		"Identify ghost type",
		"Capture 3 evidence",
	},
	optional = {
		"Survive hunt",
		"Witness ghost event",
		"Use the right tool",
	},
}

local PREPARATION_MAX_LOADOUT_TOOLS = 3
local PREPARATION_LOADOUT_ATTR_PREFIX = "PasrahLoadoutTool"
local PREPARATION_LOADOUT_COUNT_ATTR = "PasrahLoadoutToolCount"
local PREPARATION_DEFAULT_PRIMARY_TOOL = "Flashlight"

local PREPARATION_TOOL_STATIONS = {
	{
		name = "ToolStation_FLASHLIGHT",
		title = "FLASH",
		toolType = "Flashlight",
		subtitle = "Main light",
		color = Color3.fromRGB(172, 154, 96),
		modelName = "Flashlight",
		modelLift = 0.62,
		modelYaw = 90,
	},
	{
		name = "ToolStation_EMF",
		title = "EMF",
		toolType = "JejakEnergi",
		subtitle = "Medok sweep",
		color = Color3.fromRGB(132, 186, 255),
		modelName = "JejakEnergi",
		modelLift = 0.63,
		modelYaw = 90,
	},
	{
		name = "ToolStation_UV",
		title = "UV CAM",
		toolType = "BolaArwah",
		subtitle = "To'un trace",
		color = Color3.fromRGB(214, 146, 255),
		modelName = "BolaArwah",
		modelLift = 0.64,
		modelYaw = 90,
	},
	{
		name = "ToolStation_THERMO",
		title = "THERMO",
		toolType = "SuhuMembeku",
		subtitle = "Freeze check",
		color = Color3.fromRGB(142, 214, 198),
		modelName = "SuhuMembeku",
		modelLift = 0.63,
		modelYaw = 90,
	},
	{
		name = "ToolStation_BOX",
		title = "BOX",
		toolType = "KotakArwah",
		subtitle = "Voice bait",
		color = Color3.fromRGB(255, 196, 118),
		modelName = "KotakArwah",
		modelLift = 0.62,
		modelYaw = 90,
	},
	{
		name = "ToolStation_WRITING",
		title = "WRITING",
		toolType = "BukuTerkutuk",
		subtitle = "Book proof",
		color = Color3.fromRGB(150, 189, 255),
		modelName = "BukuTerkutuk",
		modelLift = 0.6,
		modelYaw = 90,
	},
	{
		name = "ToolStation_SENSOR",
		title = "SENSOR",
		toolType = "GerakanGaib",
		subtitle = "Movement read",
		color = Color3.fromRGB(255, 130, 130),
		modelName = "GerakanGaib",
		modelLift = 0.63,
		modelYaw = 90,
	},
	{
		name = "ToolStation_GARAM",
		title = "GARAM",
		toolType = "Garam",
		subtitle = "Salt trap",
		color = Color3.fromRGB(180, 166, 110),
		modelName = "Garam",
		modelLift = 0.58,
		modelYaw = 90,
	},
	{
		name = "ToolStation_SALIB",
		title = "SALIB",
		toolType = "Salib",
		subtitle = "Hunt block",
		color = Color3.fromRGB(160, 118, 76),
		modelName = "Salib",
		modelLift = 0.6,
		modelYaw = 90,
	},
	{
		name = "ToolStation_DUPA",
		title = "DUPA",
		toolType = "Dupa",
		subtitle = "Repel cloud",
		color = Color3.fromRGB(180, 102, 72),
		modelName = "Dupa",
		modelLift = 0.6,
		modelYaw = 90,
	},
	{
		name = "ToolStation_PIL",
		title = "SANITY",
		toolType = "PilSanity",
		subtitle = "Recover sanity",
		color = Color3.fromRGB(126, 196, 154),
		modelName = "PilSanity",
		modelLift = 0.56,
		modelYaw = 90,
	},
}

local function disableLegacyAssetScripts(mapId, mapClone)
	if typeof(mapClone) ~= "Instance" then
		return false
	end
	if mapClone:GetAttribute(LEGACY_ASSET_SCRIPTS_DISABLED_ATTR) == true then
		return false
	end

	local normalizedMapId = tostring(mapId or ""):gsub("[%s_%-]+", ""):lower()
	local disablesImportedScripts = {
		hauntedhouse = true,
		abandonedpalace = true,
		emptybuilding = true,
		studiommnineteen = true,
	}
	if disablesImportedScripts[normalizedMapId] ~= true then
		return false
	end

	local disabledCount = 0
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			descendant.Disabled = true
			descendant:SetAttribute("PasrahDisabledLegacyMapScript", true)
			disabledCount += 1
		end
	end

	mapClone:SetAttribute(LEGACY_ASSET_SCRIPTS_DISABLED_ATTR, true)
	mapClone:SetAttribute("LegacyAssetScriptsDisabledCount", disabledCount)
	return disabledCount > 0
end

function MapRuntimePatches.DisableLegacyAssetScripts(mapId, mapClone)
	return disableLegacyAssetScripts(mapId, mapClone)
end

local INTERACTION_GUIDE_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldMarkers", "InteractionGuideBillboardTemplate" }
local TRAVERSAL_GUIDE_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldMarkers", "TraversalGuideBillboardTemplate" }
local MAP_BOARD_SURFACE_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldSurfaces", "MapBoardSurfaceTemplate" }
local WORLD_HIGHLIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldHighlightTemplate" }
local WORLD_POINT_LIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldPointLightTemplate" }
local WORLD_SPOT_LIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldSpotLightTemplate" }
local WORLD_PARTICLE_EMITTER_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldParticleEmitterTemplate" }

local function resolveChildPath(root, path)
	local node = root
	for _, segment in ipairs(path) do
		if typeof(node) ~= "Instance" then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local function cloneGuideBillboardTemplate(path, name)
	local template = resolveChildPath(ReplicatedStorage, path)
	if template and template:IsA("BillboardGui") then
		local clone = template:Clone()
		clone.Name = name
		return clone
	end
	return nil
end

local function cloneGuideSurfaceTemplate(path, name)
	local template = resolveChildPath(ReplicatedStorage, path)
	if template and template:IsA("SurfaceGui") then
		local clone = template:Clone()
		clone.Name = name
		return clone
	end
	return nil
end

local function cloneWorldEffectTemplate(path, name, className)
	local template = resolveChildPath(ReplicatedStorage, path)
	if template and template:IsA(className) then
		local clone = template:Clone()
		clone.Name = name
		return clone
	end
	return nil
end

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-%.]+", ""):lower()
end

local function titleCaseToken(token)
	local raw = tostring(token or ""):gsub("(%d+)", " %1"):gsub("[_%-.]+", " ")
	raw = raw:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if raw == "" then
		return "-"
	end
	local words = {}
	for word in raw:gmatch("%S+") do
		words[#words + 1] = string.upper(word:sub(1, 1)) .. string.lower(word:sub(2))
	end
	return table.concat(words, " ")
end

local function resolveMapOverrideToken(mapId, mapClone)
	local primaryToken = normalizeToken(mapId)
	if primaryToken then
		return primaryToken
	end
	if typeof(mapClone) == "Instance" then
		return normalizeToken(mapClone.Name)
	end
	return nil
end

local function hasNamedAncestor(instance, ancestorToken)
	if typeof(instance) ~= "Instance" then
		return false
	end
	local targetToken = normalizeToken(ancestorToken)
	if not targetToken then
		return false
	end
	local current = instance.Parent
	while current do
		if normalizeToken(current.Name) == targetToken then
			return true
		end
		current = current.Parent
	end
	return false
end

local function flattenDirection(vector)
	if typeof(vector) ~= "Vector3" then
		return nil
	end

	local flattened = Vector3.new(vector.X, 0, vector.Z)
	if flattened.Magnitude <= 1e-4 then
		return nil
	end
	return flattened.Unit
end

local function resolveDoorAnchoredInteractionPosition(room, door, insideOffset)
	if not (room and room:IsA("BasePart") and door and door:IsA("BasePart")) then
		return nil
	end

	local directionToRoom = flattenDirection(room.Position - door.Position)
	if not directionToRoom then
		return nil
	end

	local resolvedOffset = tonumber(insideOffset)
	if resolvedOffset == nil then
		local minRoomSpan = math.min(room.Size.X, room.Size.Z)
		resolvedOffset = math.clamp(minRoomSpan * 0.3, 3, 6)
	end

	return Vector3.new(
		door.Position.X,
		room.Position.Y + INTERACTION_HEIGHT_OFFSET,
		door.Position.Z
	) + (directionToRoom * resolvedOffset)
end

local function findNearestRoomLabel(roomsFolder, worldPosition)
	if not (typeof(roomsFolder) == "Instance" and typeof(worldPosition) == "Vector3") then
		return nil
	end

	local bestLabel = nil
	local bestDistance = math.huge
	for _, room in ipairs(roomsFolder:GetChildren()) do
		if room:IsA("BasePart") then
			local roomLabel = titleCaseToken(room.Name:gsub("^Room_", ""))
			local distance = (Vector3.new(room.Position.X, 0, room.Position.Z) - Vector3.new(worldPosition.X, 0, worldPosition.Z)).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				bestLabel = roomLabel
			end
		end
	end

	return bestLabel
end

local function resolveInteractionGuideSubtitle(roomLabel)
	local token = tostring(roomLabel or ""):lower()
	if token:find("closet", 1, true) or token:find("locker", 1, true) then
		return "Refuge route"
	end
	if token:find("basement", 1, true) or token:find("attic", 1, true) or token:find("stair", 1, true) then
		return "Transisi vertikal"
	end
	if token:find("bathroom", 1, true) or token:find("bedroom", 1, true) then
		return "Sweep evidence"
	end
	if token:find("kitchen", 1, true) or token:find("living", 1, true) or token:find("dining", 1, true) then
		return "Area investigasi"
	end
	return "Anchor ruang"
end

local function getTraversalGuidePalette()
	return {
		accent = Color3.fromRGB(142, 168, 236),
		outline = Color3.fromRGB(206, 220, 255),
		title = Color3.fromRGB(242, 246, 252),
		subtitle = Color3.fromRGB(188, 204, 236),
	}
end

local function getInteractionGuidePalette(subtitle)
	if subtitle == "Refuge route" then
		return {
			accent = Color3.fromRGB(132, 186, 154),
			title = Color3.fromRGB(244, 250, 246),
			subtitle = Color3.fromRGB(184, 222, 196),
		}
	end
	if subtitle == "Transisi vertikal" then
		return {
			accent = Color3.fromRGB(142, 168, 236),
			title = Color3.fromRGB(242, 246, 252),
			subtitle = Color3.fromRGB(188, 204, 236),
		}
	end
	if subtitle == "Sweep evidence" then
		return {
			accent = Color3.fromRGB(214, 160, 104),
			title = Color3.fromRGB(250, 246, 238),
			subtitle = Color3.fromRGB(228, 196, 154),
		}
	end
	if subtitle == "Area investigasi" then
		return {
			accent = Color3.fromRGB(110, 188, 172),
			title = Color3.fromRGB(240, 250, 248),
			subtitle = Color3.fromRGB(180, 224, 216),
		}
	end
	return {
		accent = Color3.fromRGB(158, 190, 222),
		title = Color3.fromRGB(238, 244, 250),
		subtitle = Color3.fromRGB(176, 198, 218),
	}
end

local function ensureInteractionPointPart(folder, interactionName, targetPosition)
	if typeof(folder) ~= "Instance" or not folder:IsA("Folder") or typeof(targetPosition) ~= "Vector3" then
		return nil
	end

	local interactionPoint = folder:FindFirstChild(interactionName)
	if interactionPoint and interactionPoint:IsA("BasePart") then
		return interactionPoint
	end
	if interactionPoint then
		interactionPoint:Destroy()
	end

	interactionPoint = Instance.new("Part")
	interactionPoint.Name = interactionName
	interactionPoint.Anchored = true
	interactionPoint.CanCollide = false
	interactionPoint.CanTouch = false
	interactionPoint.CanQuery = false
	interactionPoint.Transparency = 1
	interactionPoint.Size = Vector3.new(1, 1, 1)
	interactionPoint.CFrame = CFrame.new(targetPosition)
	interactionPoint.Parent = folder
	return interactionPoint
end

local function sanitizeLogicVolumePart(part)
	if not (part and part:IsA("BasePart")) then
		return false
	end

	local changed = false
	if part.Transparency ~= LOGIC_VOLUME_VISUAL_TRANSPARENCY then
		part.Transparency = LOGIC_VOLUME_VISUAL_TRANSPARENCY
		changed = true
	end
	if part.CanCollide then
		part.CanCollide = false
		changed = true
	end
	if part.CanTouch then
		part.CanTouch = false
		changed = true
	end
	if part.CanQuery ~= true then
		part.CanQuery = true
		changed = true
	end
	if part.CastShadow then
		part.CastShadow = false
		changed = true
	end
	return changed
end

local function patchLogicVolumes(mapClone)
	if not mapClone or mapClone:GetAttribute(LOGIC_VOLUME_PATCH_ATTR) == true then
		return false
	end

	local patchedAny = false
	for _, folderName in ipairs(LOGIC_VOLUME_FOLDER_NAMES) do
		local folder = mapClone:FindFirstChild(folderName, true)
		if folder then
			for _, descendant in ipairs(folder:GetDescendants()) do
				if descendant:IsA("BasePart") then
					patchedAny = sanitizeLogicVolumePart(descendant) or patchedAny
				end
			end
		end
	end

	if patchedAny then
		mapClone:SetAttribute(LOGIC_VOLUME_PATCH_ATTR, true)
	end
	return patchedAny
end

local function ensureInteractionGuide(interactionPoint, roomLabel)
	if not (interactionPoint and interactionPoint:IsA("BasePart") and interactionPoint.Parent ~= nil) then
		return nil
	end
	if PLAYER_FACING_GUIDE_VISUALS_ENABLED ~= true then
		local existingFolder = interactionPoint:FindFirstChild(INTERACTION_GUIDE_FOLDER_NAME)
		if existingFolder then
			existingFolder:Destroy()
		end
		return nil
	end
	local guideSubtitle = resolveInteractionGuideSubtitle(roomLabel)
	local palette = getInteractionGuidePalette(guideSubtitle)

	local folder = interactionPoint:FindFirstChild(INTERACTION_GUIDE_FOLDER_NAME)
	if not (folder and folder:IsA("Folder")) then
		if folder then
			folder:Destroy()
		end
		folder = Instance.new("Folder")
		folder.Name = INTERACTION_GUIDE_FOLDER_NAME
		folder.Parent = interactionPoint
	end

	local billboard = folder:FindFirstChild(INTERACTION_GUIDE_BILLBOARD_NAME)
	if not (billboard and billboard:IsA("BillboardGui")) then
		if billboard then
			billboard:Destroy()
		end
		billboard = cloneGuideBillboardTemplate(INTERACTION_GUIDE_TEMPLATE_PATH, INTERACTION_GUIDE_BILLBOARD_NAME)
		if not billboard then
			warn("[MapRuntimePatches] Missing authored visual template: WorldMarkers.InteractionGuideBillboardTemplate")
			return nil
		end
		billboard.Name = INTERACTION_GUIDE_BILLBOARD_NAME
		billboard.Parent = folder
	end
	billboard.Active = false
	billboard.Adornee = interactionPoint
	billboard.AlwaysOnTop = true
	billboard.Brightness = 2
	billboard.ClipsDescendants = false
	billboard.Enabled = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 85
	billboard.ResetOnSpawn = false
	billboard.Size = UDim2.fromOffset(186, 42)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)

	local panel = billboard:FindFirstChild("Panel")
	if not (panel and panel:IsA("Frame")) then
		if panel then
			panel:Destroy()
		end
		warn("[MapRuntimePatches] InteractionGuideBillboardTemplate missing required child: Panel")
		return nil
	end

	panel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
	panel.BackgroundTransparency = 0.16
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromScale(1, 1)

	local title = panel:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = roomLabel
		title.TextColor3 = palette.title
	end
	local subtitle = panel:FindFirstChild("Subtitle")
	if subtitle and subtitle:IsA("TextLabel") then
		subtitle.Text = guideSubtitle
		subtitle.TextColor3 = palette.subtitle
	end
	local stroke = panel:FindFirstChild("Stroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = palette.accent
	end

	return folder
end

local function getXZBounds(part)
	local halfSize = part.Size * 0.5
	return {
		minX = part.Position.X - halfSize.X,
		maxX = part.Position.X + halfSize.X,
		minZ = part.Position.Z - halfSize.Z,
		maxZ = part.Position.Z + halfSize.Z,
	}
end

local function collectMapXZBounds(mapClone, ignoredFolder)
	if not mapClone then
		return nil
	end

	local bounds = nil
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart") and (not ignoredFolder or not descendant:IsDescendantOf(ignoredFolder)) then
			local partBounds = getXZBounds(descendant)
			if not bounds then
				bounds = {
					minX = partBounds.minX,
					maxX = partBounds.maxX,
					minZ = partBounds.minZ,
					maxZ = partBounds.maxZ,
				}
			else
				bounds.minX = math.min(bounds.minX, partBounds.minX)
				bounds.maxX = math.max(bounds.maxX, partBounds.maxX)
				bounds.minZ = math.min(bounds.minZ, partBounds.minZ)
				bounds.maxZ = math.max(bounds.maxZ, partBounds.maxZ)
			end
		end
	end

	return bounds
end

local function hasArea(bounds)
	return bounds
		and (bounds.maxX - bounds.minX) > MIN_SEGMENT_SIZE
		and (bounds.maxZ - bounds.minZ) > MIN_SEGMENT_SIZE
end

local function intersectsXZ(a, b)
	if not a or not b then
		return false
	end
	return a.maxX > b.minX
		and a.minX < b.maxX
		and a.maxZ > b.minZ
		and a.minZ < b.maxZ
end

local function createFloorSegment(source, parent, name, bounds)
	if not hasArea(bounds) then
		return nil
	end

	local segment = source:Clone()
	segment.Name = name
	segment.Size = Vector3.new(bounds.maxX - bounds.minX, source.Size.Y, bounds.maxZ - bounds.minZ)
	segment.Position = Vector3.new(
		(bounds.minX + bounds.maxX) * 0.5,
		source.Position.Y,
		(bounds.minZ + bounds.maxZ) * 0.5
	)
	segment.Parent = parent
	return segment
end

local function ensureFolder(parent, name)
	if typeof(parent) ~= "Instance" then
		return nil
	end

	local folder = parent:FindFirstChild(name)
	if not (folder and folder:IsA("Folder")) then
		if folder then
			folder:Destroy()
		end
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function ensurePart(parent, name)
	if typeof(parent) ~= "Instance" then
		return nil
	end

	local part = parent:FindFirstChild(name)
	if not (part and part:IsA("BasePart")) then
		if part then
			part:Destroy()
		end
		part = Instance.new("Part")
		part.Name = name
		part.Parent = parent
	end

	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = true
	return part
end

local function configurePart(part, properties)
	if not (part and part:IsA("BasePart")) or type(properties) ~= "table" then
		return part
	end

	for key, value in pairs(properties) do
		part[key] = value
	end
	return part
end

local function configureAccentDrivenPart(part, properties, idleTransparency, focusTransparency, breachTransparency)
	part = configurePart(part, properties)
	if part and part:IsA("BasePart") then
		part:SetAttribute("PreparationAccentDriven", true)
		part:SetAttribute("PreparationAccentIdleTransparency", tonumber(idleTransparency) or 0.18)
		part:SetAttribute("PreparationAccentFocusTransparency", tonumber(focusTransparency) or 0.1)
		part:SetAttribute("PreparationAccentBreachTransparency", tonumber(breachTransparency) or 0.04)
	end
	return part
end

local function resolveReplicatedAssetModelTemplate(categoryName, modelName)
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local assets = replicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local categoryFolder = models and models:FindFirstChild(tostring(categoryName or ""))
	local template = categoryFolder and categoryFolder:FindFirstChild(tostring(modelName or ""))
	if template and template:IsA("Model") then
		return template
	end
	return nil
end

local toolVisualConfigCache = nil

local function safeRequireModule(moduleScript)
	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok then
		return result
	end
	return nil
end

local function coerceConfigVector3(value)
	if typeof(value) == "Vector3" then
		return value
	end
	if type(value) ~= "table" then
		return nil
	end
	local x = tonumber(value.x or value.X or value[1])
	local y = tonumber(value.y or value.Y or value[2])
	local z = tonumber(value.z or value.Z or value[3])
	if x and y and z then
		return Vector3.new(x, y, z)
	end
	return nil
end

local function resolveToolTargetBounds(toolType)
	if type(toolType) ~= "string" or toolType == "" then
		return nil
	end

	if toolVisualConfigCache == nil then
		local replicatedStorage = game:GetService("ReplicatedStorage")
		local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
		local gameData = shared and shared:FindFirstChild("GameData")
		local moduleScript = gameData and gameData:FindFirstChild("ToolVisualConfig")
		local configModule = safeRequireModule(moduleScript)
		local tools = type(configModule) == "table" and type(configModule.tools) == "table" and configModule.tools or false
		toolVisualConfigCache = tools
	end

	if toolVisualConfigCache == false then
		return nil
	end

	local config = toolVisualConfigCache[toolType]
	if type(config) ~= "table" then
		return nil
	end
	return coerceConfigVector3(config.targetBounds)
end

local function clampRuntimeModelBounds(model, targetBounds)
	if not (model and model:IsA("Model")) or typeof(targetBounds) ~= "Vector3" then
		return false
	end

	local okExtents, extents = pcall(function()
		return model:GetExtentsSize()
	end)
	if not okExtents or typeof(extents) ~= "Vector3" then
		return false
	end

	if extents.X <= 0 or extents.Y <= 0 or extents.Z <= 0 then
		return false
	end

	local factor = math.min(
		targetBounds.X / extents.X,
		targetBounds.Y / extents.Y,
		targetBounds.Z / extents.Z
	)
	if factor <= 0 then
		return false
	end
	if factor >= 0.98 and factor <= 1.02 then
		return true
	end

	local currentScale = 1
	local okScale, scale = pcall(function()
		return model:GetScale()
	end)
	if okScale and type(scale) == "number" and scale > 0 then
		currentScale = scale
	end

	local nextScale = math.max(0.01, currentScale * factor)
	local okApply = pcall(function()
		model:ScaleTo(nextScale)
	end)
	return okApply
end

local function configureRuntimeModel(model, options)
	if not (model and model:IsA("Model")) then
		return model
	end

	local desiredCollision = type(options) == "table" and options.canCollide == true or false
	local desiredQuery = type(options) == "table" and options.canQuery == true or false
	local desiredShadow = type(options) == "table" and options.castShadow == true or false
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = desiredCollision
			descendant.CanTouch = false
			descendant.CanQuery = desiredQuery
			descendant.CastShadow = desiredShadow
		end
	end
	return model
end

local function syncRuntimeAssetModel(parent, runtimeName, categoryName, modelName, targetCFrame, options)
	if typeof(parent) ~= "Instance" then
		return nil
	end

	local template = resolveReplicatedAssetModelTemplate(categoryName, modelName)
	local existing = parent:FindFirstChild(runtimeName)
	if not (template and template:IsA("Model")) then
		if existing then
			existing:Destroy()
		end
		return nil
	end

	local sourceToken = string.format("%s/%s", tostring(categoryName or ""), tostring(modelName or ""))
	local model = existing
	if not (model and model:IsA("Model") and model:GetAttribute("PasrahAssetSourceToken") == sourceToken) then
		if model then
			model:Destroy()
		end
		model = template:Clone()
		model.Name = runtimeName
		model:SetAttribute("PasrahAssetSourceToken", sourceToken)
		model.Parent = parent
	end

	configureRuntimeModel(model, options)
	if type(options) == "table" and type(options.scale) == "number" and options.scale > 0 then
		pcall(function()
			model:ScaleTo(options.scale)
		end)
	end
	local targetBounds = type(options) == "table" and coerceConfigVector3(options.targetBounds) or nil
	if targetBounds == nil and tostring(categoryName or "") == "Tools" then
		targetBounds = resolveToolTargetBounds(tostring(modelName or ""))
	end
	if targetBounds then
		clampRuntimeModelBounds(model, targetBounds)
	end
	if typeof(targetCFrame) == "CFrame" then
		pcall(function()
			model:PivotTo(targetCFrame)
		end)
	end
	return model
end

local function ensureBoardSurface(part, surfaceName, face, titleText, subtitleText, bodyLines, accentColor)
	if not (part and part:IsA("BasePart")) then
		return nil
	end

	local surface = part:FindFirstChild(surfaceName)
	if not (surface and surface:IsA("SurfaceGui")) then
		if surface then
			surface:Destroy()
		end
		surface = cloneGuideSurfaceTemplate(MAP_BOARD_SURFACE_TEMPLATE_PATH, surfaceName)
		if not surface then
			warn("[MapRuntimePatches] Missing authored visual template: WorldSurfaces.MapBoardSurfaceTemplate")
			return nil
		end
		surface.Name = surfaceName
		surface.Parent = part
	end

	surface.Adornee = part
	surface.Face = face
	surface.ResetOnSpawn = false
	surface.AlwaysOnTop = false
	surface.LightInfluence = 1
	surface.Brightness = 1
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.CanvasSize = Vector2.new(720, 420)

	local panel = surface:FindFirstChild("Panel")
	if not (panel and panel:IsA("Frame")) then
		if panel then
			panel:Destroy()
		end
		warn("[MapRuntimePatches] MapBoardSurfaceTemplate missing required child: Panel")
		return nil
	end

	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0

	local accent = panel:FindFirstChild("Accent")
	if accent and accent:IsA("Frame") then
		accent.BackgroundColor3 = accentColor or Color3.fromRGB(142, 168, 236)
	end

	local stroke = panel:FindFirstChild("Stroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = accentColor or Color3.fromRGB(142, 168, 236)
	end

	local title = panel:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = titleText or ""
	end

	local subtitle = panel:FindFirstChild("Subtitle")
	if subtitle and subtitle:IsA("TextLabel") then
		subtitle.Text = subtitleText or ""
	end

	local body = panel:FindFirstChild("Body")
	if body and body:IsA("TextLabel") then
		body.Text = type(bodyLines) == "table" and table.concat(bodyLines, "\n") or tostring(bodyLines or "")
	end

	return surface
end

local function ensurePrompt(parent, name, actionText, objectText)
	if typeof(parent) ~= "Instance" then
		return nil
	end

	local prompt = parent:FindFirstChild(name)
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		if prompt then
			prompt:Destroy()
		end
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = name
		prompt.Parent = parent
	end

	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Style = Enum.ProximityPromptStyle.Default
	return prompt
end

local function formatMapLabel(mapId)
	local token = tostring(mapId or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if token == "" then
		return "Unknown Site"
	end
	token = token:gsub("(%l)(%u)", "%1 %2")
	return titleCaseToken(token)
end

local function buildPreparationBoardContent(mapId, matchContext)
	local token = resolveMapOverrideToken((type(matchContext) == "table" and (matchContext.mapId or matchContext.map)) or mapId)
	local profile = token and PREPARATION_STAGING_PROFILES[token] or nil
	local mapLabel = formatMapLabel((type(matchContext) == "table" and (matchContext.mapId or matchContext.map)) or mapId)
	local modeLabel = titleCaseToken(type(matchContext) == "table" and (matchContext.mode or matchContext.gameMode) or "Classic")
	local difficultyLabel = titleCaseToken(type(matchContext) == "table" and matchContext.difficulty or "Mudah")
	local difficultyProfile = type(matchContext) == "table" and type(matchContext.difficultyProfile) == "table" and matchContext.difficultyProfile or nil
	local evidenceCount = difficultyProfile and tonumber(difficultyProfile.EvidenceCount) or nil
	local evidenceTarget = evidenceCount and string.format("Capture %d evidence", evidenceCount) or PREPARATION_OBJECTIVE_TEMPLATE.primary[2]

	local contractLines = {
		string.format("Map: %s", mapLabel),
		string.format("Mode: %s", modeLabel),
		string.format("Difficulty: %s", difficultyLabel),
		"Spawn di staging luar sebelum masuk.",
		"Review board, pilih tool awal, lalu breach dari pintu utama.",
	}
	if type(profile) == "table" and type(profile.contractExtraLine) == "string" and profile.contractExtraLine ~= "" then
		table.insert(contractLines, profile.contractExtraLine)
	end

	local objectiveLines = {
		"PRIMARY",
		"- " .. PREPARATION_OBJECTIVE_TEMPLATE.primary[1],
		"- " .. evidenceTarget,
		"",
		"OPTIONAL",
		"- " .. PREPARATION_OBJECTIVE_TEMPLATE.optional[1],
		"- " .. PREPARATION_OBJECTIVE_TEMPLATE.optional[2],
		"- " .. PREPARATION_OBJECTIVE_TEMPLATE.optional[3],
	}

	local toolLines = {
		"Field kit issued for first sweep.",
		"EMF • UV CAM • THERMO",
		"BOX • WRITING • SENSOR",
		"Support kit: GARAM • SALIB • DUPA",
		"Gunakan rack kanan untuk review urutan tool awal.",
	}

	return {
		contractTitle = "CONTRACT",
		contractSubtitle = string.format("%s • %s • %s", mapLabel, modeLabel, difficultyLabel),
		contractLines = contractLines,
		objectiveTitle = "OBJECTIVES",
		objectiveSubtitle = "Primary + optional briefing",
		objectiveLines = objectiveLines,
		toolsTitle = "TOOLS",
		toolsSubtitle = "Staging loadout briefing",
		toolsLines = toolLines,
	}
end

local function findPreparationToolDataByType(toolType)
	if type(toolType) ~= "string" or toolType == "" then
		return nil
	end
	for _, toolData in ipairs(PREPARATION_TOOL_STATIONS) do
		if toolData.toolType == toolType or toolData.title == toolType or toolData.name == toolType then
			return toolData
		end
	end
	if toolType == PREPARATION_DEFAULT_PRIMARY_TOOL then
		return {
			title = "FLASH",
			toolType = PREPARATION_DEFAULT_PRIMARY_TOOL,
		}
	end
	return nil
end

local function getPreparationToolLabel(toolType)
	local toolData = findPreparationToolDataByType(toolType)
	return toolData and tostring(toolData.title or toolType) or tostring(toolType or "")
end

local function clonePreparationLoadoutList(source)
	local loadout = {}
	local seen = {}
	if type(source) == "table" then
		for _, toolType in ipairs(source) do
			if type(toolType) == "string"
				and toolType ~= ""
				and not seen[toolType]
				and findPreparationToolDataByType(toolType)
				and #loadout < PREPARATION_MAX_LOADOUT_TOOLS then
				table.insert(loadout, toolType)
				seen[toolType] = true
			end
		end
	end
	return loadout
end

local function readPreparationLoadoutFromPlayer(player)
	local loadout = {}
	if not (typeof(player) == "Instance" and player:IsA("Player")) then
		return loadout
	end
	for slot = 1, PREPARATION_MAX_LOADOUT_TOOLS do
		local toolType = player:GetAttribute(PREPARATION_LOADOUT_ATTR_PREFIX .. tostring(slot))
		if type(toolType) == "string" and toolType ~= "" then
			table.insert(loadout, toolType)
		end
	end
	return clonePreparationLoadoutList(loadout)
end

local function writePreparationLoadoutToPlayer(player, loadout)
	if not (typeof(player) == "Instance" and player:IsA("Player")) then
		return
	end
	local normalized = clonePreparationLoadoutList(loadout)
	player:SetAttribute(PREPARATION_LOADOUT_COUNT_ATTR, #normalized)
	for slot = 1, PREPARATION_MAX_LOADOUT_TOOLS do
		player:SetAttribute(PREPARATION_LOADOUT_ATTR_PREFIX .. tostring(slot), normalized[slot])
	end
end

local function getPreparationLoadoutLabels(loadout)
	local labels = {}
	for _, toolType in ipairs(clonePreparationLoadoutList(loadout)) do
		table.insert(labels, getPreparationToolLabel(toolType))
	end
	return labels
end

local function getPreparationLoadoutLabelText(loadout)
	local labels = getPreparationLoadoutLabels(loadout)
	if #labels == 0 then
		return ""
	end
	return table.concat(labels, " / ")
end

local function resolvePreparationLoadout(matchContext)
	local loadout = {}
	if type(matchContext) == "table" then
		loadout = clonePreparationLoadoutList(matchContext.selectedPreparationTools)
		if #loadout == 0 and type(matchContext.selectedPreparationTool) == "string" and matchContext.selectedPreparationTool ~= "" then
			loadout = clonePreparationLoadoutList({ PREPARATION_DEFAULT_PRIMARY_TOOL, matchContext.selectedPreparationTool })
		end
		for _, player in ipairs(matchContext.players or {}) do
			if #loadout >= PREPARATION_MAX_LOADOUT_TOOLS then
				break
			end
			for _, toolType in ipairs(readPreparationLoadoutFromPlayer(player)) do
				if #loadout >= PREPARATION_MAX_LOADOUT_TOOLS then
					break
				end
				local exists = false
				for _, existing in ipairs(loadout) do
					if existing == toolType then
						exists = true
						break
					end
				end
				if not exists then
					table.insert(loadout, toolType)
				end
			end
		end
	end
	return clonePreparationLoadoutList(loadout)
end

local function buildPreparationLoadoutAfterSelection(currentLoadout, selectedTool)
	local loadout = clonePreparationLoadoutList(currentLoadout)
	local seen = {}
	for _, toolType in ipairs(loadout) do
		seen[toolType] = true
	end
	if not seen[PREPARATION_DEFAULT_PRIMARY_TOOL] then
		table.insert(loadout, 1, PREPARATION_DEFAULT_PRIMARY_TOOL)
		seen[PREPARATION_DEFAULT_PRIMARY_TOOL] = true
	end
	if type(selectedTool) == "string" and selectedTool ~= "" and not seen[selectedTool] then
		if #loadout < PREPARATION_MAX_LOADOUT_TOOLS then
			table.insert(loadout, selectedTool)
		else
			loadout[PREPARATION_MAX_LOADOUT_TOOLS] = selectedTool
		end
	end
	return clonePreparationLoadoutList(loadout)
end

local function updatePreparationToolsBoard(boardPart, selectedTool)
	local selectedLoadout = type(selectedTool) == "table" and clonePreparationLoadoutList(selectedTool) or nil
	local selectedLabel = selectedLoadout and getPreparationLoadoutLabelText(selectedLoadout) or selectedTool
	local lines = {
		"Loadout maksimal 3 tool.",
		"FLASH otomatis ikut saat tool dipilih.",
		"Slot 1-3 dipakai untuk switch tool.",
		"Masuk hanya setelah loadout siap.",
	}
	local subtitle = "Pilih 1-2 tool tambahan"
	if type(selectedLabel) == "string" and selectedLabel ~= "" then
		subtitle = string.format("Loadout: %s", selectedLabel)
		table.insert(lines, 1, string.format("%d/%d slot siap", selectedLoadout and #selectedLoadout or 1, PREPARATION_MAX_LOADOUT_TOOLS))
	end

	ensureBoardSurface(
		boardPart,
		"FrontSurface",
		Enum.NormalId.Front,
		"TOOLS",
		subtitle,
		lines,
		Color3.fromRGB(132, 186, 255)
	)
	ensureBoardSurface(
		boardPart,
		"BackSurface",
		Enum.NormalId.Back,
		"TOOLS",
		subtitle,
		lines,
		Color3.fromRGB(132, 186, 255)
	)
end

local function updatePreparationToolStationState(toolPart, prompt, toolData, selectedTool, breachOpen, statePad, loadoutLookup, loadoutCount)
	if not (toolPart and toolPart:IsA("BasePart") and type(toolData) == "table") then
		return
	end

	local selectedToken = type(selectedTool) == "string" and selectedTool or ""
	local isSelected = (type(loadoutLookup) == "table" and loadoutLookup[toolData.toolType] == true)
		or (selectedToken ~= "" and (selectedToken == toolData.title or selectedToken == toolData.toolType))
	local accentColor = toolData.color or Color3.fromRGB(132, 186, 255)
	local highlightColor = accentColor:Lerp(Color3.new(1, 1, 1), 0.18)
	local idleColor = accentColor:Lerp(Color3.fromRGB(46, 52, 64), 0.18)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = isSelected and "Aktifkan Tool" or "Ambil Tool"
		prompt.ObjectText = string.format("%s  %d/%d", tostring(toolData.title or toolData.toolType), tonumber(loadoutCount) or 0, PREPARATION_MAX_LOADOUT_TOOLS)
	end

	toolPart.Material = isSelected and Enum.Material.Neon or Enum.Material.SmoothPlastic
	toolPart.Color = isSelected and highlightColor or idleColor
	toolPart.Reflectance = isSelected and 0.04 or 0

	local stateSubtitle = toolData.subtitle or ""
	local stateBody = ""
	local padColor = accentColor:Lerp(Color3.fromRGB(28, 34, 44), 0.62)
	local padTransparency = 0.3
	if breachOpen then
		stateSubtitle = isSelected and "Focus active • breach live" or "Rack locked • breach live"
		stateBody = isSelected and "Masuk dan buka sweep awal dengan tool ini." or "Ubah fokus hanya tersedia saat staging luar."
		if isSelected then
			padColor = accentColor:Lerp(Color3.fromRGB(220, 250, 240), 0.22)
			padTransparency = 0.08
		else
			padTransparency = 0.4
		end
	elseif isSelected then
		stateSubtitle = string.format("Loadout aktif • %d/%d", tonumber(loadoutCount) or 1, PREPARATION_MAX_LOADOUT_TOOLS)
		stateBody = "Tool ini terbawa. Klik tool lain untuk isi slot berikutnya atau ganti slot terakhir."
		padColor = accentColor
		padTransparency = 0.12
	elseif tonumber(loadoutCount) and tonumber(loadoutCount) >= PREPARATION_MAX_LOADOUT_TOOLS then
		stateSubtitle = "Slot penuh"
		stateBody = "Memilih ini akan mengganti slot terakhir."
	else
		stateSubtitle = string.format("Ambil tool • %d/%d", tonumber(loadoutCount) or 0, PREPARATION_MAX_LOADOUT_TOOLS)
		stateBody = "Pilih untuk masuk loadout staging."
	end

	ensureBoardSurface(
		toolPart,
		"FrontSurface",
		Enum.NormalId.Front,
		toolData.title,
		stateSubtitle,
		stateBody,
		accentColor
	)
	ensureBoardSurface(
		toolPart,
		"BackSurface",
		Enum.NormalId.Back,
		toolData.title,
		stateSubtitle,
		stateBody,
		accentColor
	)

	local highlight = toolPart:FindFirstChild("StateHighlight")
	if not (highlight and highlight:IsA("Highlight")) then
		if highlight then
			highlight:Destroy()
		end
		highlight = cloneWorldEffectTemplate(WORLD_HIGHLIGHT_TEMPLATE_PATH, "StateHighlight", "Highlight")
		if not highlight then
			warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldHighlightTemplate")
			return
		end
		highlight.Name = "StateHighlight"
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee = toolPart
		highlight.Parent = toolPart
	end
	highlight.Enabled = isSelected
	highlight.FillColor = accentColor
	highlight.OutlineColor = highlightColor
	highlight.FillTransparency = 0.68
	highlight.OutlineTransparency = 0.08

	local stateLight = toolPart:FindFirstChild("StateLight")
	if not (stateLight and stateLight:IsA("PointLight")) then
		if stateLight then
			stateLight:Destroy()
		end
		stateLight = cloneWorldEffectTemplate(WORLD_POINT_LIGHT_TEMPLATE_PATH, "StateLight", "PointLight")
		if not stateLight then
			warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
			return
		end
		stateLight.Name = "StateLight"
		stateLight.Parent = toolPart
	end
	stateLight.Color = accentColor
	stateLight.Brightness = isSelected and 1.8 or 0
	stateLight.Range = isSelected and 11 or 0
	stateLight.Enabled = isSelected

	if statePad and statePad:IsA("BasePart") then
		statePad.Color = padColor
		statePad.Transparency = padTransparency
	end

	if prompt and prompt:IsA("ProximityPrompt") then
		if breachOpen then
			prompt.Enabled = false
			prompt.ActionText = "Breach Live"
		elseif isSelected then
			prompt.Enabled = true
			prompt.ActionText = "Tool Aktif"
		else
			prompt.Enabled = true
			prompt.ActionText = "Pilih Fokus Tool"
		end
	end
end

local function updatePreparationObjectiveBoard(boardPart, boardData, selectedTool, breachOpen)
	local lines = {}
	for _, line in ipairs(boardData.objectiveLines or {}) do
		table.insert(lines, line)
	end

	table.insert(lines, "")
	table.insert(lines, "STATUS")
	if type(selectedTool) == "string" and selectedTool ~= "" then
		table.insert(lines, "- Focus awal: " .. selectedTool)
	else
		table.insert(lines, "- Focus awal: pilih tool dari rack")
	end
	table.insert(lines, breachOpen and "- Breach: OPEN" or "- Breach: READY")

	local subtitle = breachOpen and "Primary + breach active" or "Primary + optional briefing"
	if not breachOpen and type(selectedTool) == "string" and selectedTool ~= "" then
		subtitle = string.format("Focus: %s • breach ready", selectedTool)
	end

	ensureBoardSurface(
		boardPart,
		"FrontSurface",
		Enum.NormalId.Front,
		boardData.objectiveTitle,
		subtitle,
		lines,
		Color3.fromRGB(142, 168, 236)
	)
	ensureBoardSurface(
		boardPart,
		"BackSurface",
		Enum.NormalId.Back,
		boardData.objectiveTitle,
		subtitle,
		lines,
		Color3.fromRGB(142, 168, 236)
	)
end

local function tweenPreparationProperties(instance, tweenInfo, properties)
	if typeof(instance) ~= "Instance" then
		return
	end

	local ok, tween = pcall(function()
		return TweenService:Create(instance, tweenInfo or PREPARATION_TWEEN_INFO, properties)
	end)
	if ok and tween then
		tween:Play()
		return
	end

	for propertyName, value in pairs(properties) do
		pcall(function()
			instance[propertyName] = value
		end)
	end
end

local function ensurePreparationBurstEmitter(part, name, baseColor)
	if not (typeof(part) == "Instance" and part:IsA("BasePart")) then
		return nil
	end

	local emitter = part:FindFirstChild(name)
	if emitter and not emitter:IsA("ParticleEmitter") then
		emitter:Destroy()
		emitter = nil
	end
	if not emitter then
		emitter = cloneWorldEffectTemplate(WORLD_PARTICLE_EMITTER_TEMPLATE_PATH, name, "ParticleEmitter")
		if not emitter then
			warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldParticleEmitterTemplate")
			return nil
		end
		emitter.Name = name
		emitter.Parent = part
	end

	emitter.Enabled = false
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.28, 0.45)
	emitter.Speed = NumberRange.new(6, 12)
	emitter.Rotation = NumberRange.new(-180, 180)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.SpreadAngle = Vector2.new(65, 65)
	emitter.LightEmission = 0.72
	emitter.LightInfluence = 0
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(0.4, 0.14),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	local color = baseColor or Color3.fromRGB(255, 255, 255)
	emitter.Color = ColorSequence.new(
		color:Lerp(Color3.fromRGB(255, 255, 255), 0.2),
		color:Lerp(Color3.fromRGB(20, 24, 28), 0.1)
	)
	return emitter
end

local function resolvePreparationTheme(profile, selectedTool, breachOpen)
	local readyAccent = type(profile) == "table" and profile.readyAccent or Color3.fromRGB(214, 160, 104)
	local armedAccent = type(profile) == "table" and profile.armedAccent or Color3.fromRGB(132, 186, 255)
	local breachAccent = type(profile) == "table" and profile.breachAccent or Color3.fromRGB(142, 214, 198)
	local runnerReadyColor = type(profile) == "table" and profile.runnerReadyColor or Color3.fromRGB(98, 84, 70)
	local runnerArmedColor = type(profile) == "table" and profile.runnerArmedColor or Color3.fromRGB(72, 104, 146)
	local runnerBreachColor = type(profile) == "table" and profile.runnerBreachColor or Color3.fromRGB(72, 138, 122)
	local floodReadyColor = type(profile) == "table" and profile.floodReadyColor or Color3.fromRGB(214, 228, 255)
	local floodArmedColor = type(profile) == "table" and profile.floodArmedColor or Color3.fromRGB(178, 214, 255)
	local floodBreachColor = type(profile) == "table" and profile.floodBreachColor or Color3.fromRGB(174, 255, 236)
	local floodReadyBrightness = type(profile) == "table" and tonumber(profile.floodReadyBrightness) or 1.25
	local floodArmedBrightness = type(profile) == "table" and tonumber(profile.floodArmedBrightness) or 1.45
	local floodBreachBrightness = type(profile) == "table" and tonumber(profile.floodBreachBrightness) or 1.7
	local lampReadyColor = type(profile) == "table" and profile.lampReadyColor or Color3.fromRGB(255, 214, 170)
	local lampArmedColor = type(profile) == "table" and profile.lampArmedColor or Color3.fromRGB(184, 214, 255)
	local lampBreachColor = type(profile) == "table" and profile.lampBreachColor or Color3.fromRGB(190, 255, 236)
	local lampReadyBrightness = type(profile) == "table" and tonumber(profile.lampReadyBrightness) or 0.65
	local lampArmedBrightness = type(profile) == "table" and tonumber(profile.lampArmedBrightness) or 0.78
	local lampBreachBrightness = type(profile) == "table" and tonumber(profile.lampBreachBrightness) or 0.9

	if breachOpen then
		return {
			accent = breachAccent,
			runnerColor = runnerBreachColor,
			floodColor = floodBreachColor,
			floodBrightness = floodBreachBrightness,
			lampColor = lampBreachColor,
			lampBrightness = lampBreachBrightness,
		}
	end
	if type(selectedTool) == "string" and selectedTool ~= "" then
		return {
			accent = armedAccent,
			runnerColor = runnerArmedColor,
			floodColor = floodArmedColor,
			floodBrightness = floodArmedBrightness,
			lampColor = lampArmedColor,
			lampBrightness = lampArmedBrightness,
		}
	end
	return {
		accent = readyAccent,
		runnerColor = runnerReadyColor,
		floodColor = floodReadyColor,
		floodBrightness = floodReadyBrightness,
		lampColor = lampReadyColor,
		lampBrightness = lampReadyBrightness,
	}
end

local function resolvePreparationLaneState(selectedTool, breachOpen)
	if breachOpen then
		return "breach"
	end
	if type(selectedTool) == "string" and selectedTool ~= "" then
		return "armed"
	end
	return "ready"
end

local function updatePreparationEntryBeacon(beaconPart, selectedTool, breachOpen, profile)
	if not (typeof(beaconPart) == "Instance" and beaconPart:IsA("BasePart")) then
		return
	end

	local theme = resolvePreparationTheme(profile, selectedTool, breachOpen)
	local color = theme.accent

	beaconPart.Color = color
	local light = beaconPart:FindFirstChild("Light")
	if not (light and light:IsA("PointLight")) then
		if light then
			light:Destroy()
		end
		light = cloneWorldEffectTemplate(WORLD_POINT_LIGHT_TEMPLATE_PATH, "Light", "PointLight")
		if light then
			light.Name = "Light"
			light.Parent = beaconPart
		else
			warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
		end
	end
	if light then
		light.Color = color
		light.Brightness = breachOpen and 1.8 or 1.25
		light.Range = 16
		light.Shadows = false
	end
end

local function updatePreparationEntryLane(folder, selectedTool, breachOpen, profile)
	if typeof(folder) ~= "Instance" then
		return
	end

	local laneState = resolvePreparationLaneState(selectedTool, breachOpen)
	local previousLaneState = tostring(folder:GetAttribute(PREPARATION_LANE_STATE_ATTR) or "")
	local stateChanged = previousLaneState ~= laneState
	local theme = resolvePreparationTheme(profile, selectedTool, breachOpen)
	local accent = theme.accent
	local runnerColor = theme.runnerColor
	local floodColor = theme.floodColor
	local floodBrightness = theme.floodBrightness
	local lampColor = theme.lampColor
	local lampBrightness = theme.lampBrightness

	local runner = folder:FindFirstChild("PreparationRunner")
	if runner and runner:IsA("BasePart") then
		if stateChanged then
			tweenPreparationProperties(runner, PREPARATION_TWEEN_INFO, {
				Color = runnerColor,
			})
		else
			runner.Color = runnerColor
		end
		runner.Material = type(profile) == "table" and profile.runnerMaterial or runner.Material
	end

	for index = 1, 2 do
		local flood = folder:FindFirstChild("PreparationFloodlight_" .. tostring(index))
		if flood and flood:IsA("BasePart") then
			if stateChanged then
				tweenPreparationProperties(flood, PREPARATION_TWEEN_INFO, {
					Color = floodColor,
				})
			else
				flood.Color = floodColor
			end
			local spot = flood:FindFirstChild("Light")
			if spot and spot:IsA("SpotLight") then
				if stateChanged then
					tweenPreparationProperties(spot, PREPARATION_TWEEN_INFO, {
						Brightness = floodBrightness,
					})
				else
					spot.Brightness = floodBrightness
				end
				spot.Color = floodColor
			end
		end

		local lamp = folder:FindFirstChild("PreparationLamp_" .. tostring(index))
		if lamp and lamp:IsA("BasePart") then
			if stateChanged then
				tweenPreparationProperties(lamp, PREPARATION_TWEEN_INFO, {
					Color = lampColor,
				})
			else
				lamp.Color = lampColor
			end
			local light = lamp:FindFirstChild("Light")
			if light and light:IsA("PointLight") then
				if stateChanged then
					tweenPreparationProperties(light, PREPARATION_TWEEN_INFO, {
						Brightness = lampBrightness,
					})
				else
					light.Brightness = lampBrightness
				end
				light.Color = lampColor
			end
		end
	end

	local entryAccent = folder:FindFirstChild("PreparationEntryAccent")
	if entryAccent and entryAccent:IsA("BasePart") then
		if stateChanged then
			tweenPreparationProperties(entryAccent, PREPARATION_FAST_TWEEN_INFO, {
				Color = accent,
			})
		else
			entryAccent.Color = accent
		end
	end

	local marqueeAccent = folder:FindFirstChild("PreparationSiteMarqueeAccent")
	if marqueeAccent and marqueeAccent:IsA("BasePart") then
		if stateChanged then
			tweenPreparationProperties(marqueeAccent, PREPARATION_FAST_TWEEN_INFO, {
				Color = accent,
			})
		else
			marqueeAccent.Color = accent
		end
	end

	local marqueeGlow = folder:FindFirstChild("PreparationSiteMarqueeGlow")
	if marqueeGlow and marqueeGlow:IsA("BasePart") then
		if stateChanged then
			tweenPreparationProperties(marqueeGlow, PREPARATION_FAST_TWEEN_INFO, {
				Color = accent,
			})
		else
			marqueeGlow.Color = accent
		end
		local glowLight = marqueeGlow:FindFirstChild("Light")
		if glowLight and glowLight:IsA("PointLight") then
			glowLight.Color = accent
			if stateChanged then
				tweenPreparationProperties(glowLight, PREPARATION_FAST_TWEEN_INFO, {
					Brightness = breachOpen and 1.8 or 1.1,
				})
			else
				glowLight.Brightness = breachOpen and 1.8 or 1.1
			end
		end
	end

	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("PreparationAccentDriven") == true then
			local idleTransparency = tonumber(descendant:GetAttribute("PreparationAccentIdleTransparency")) or descendant.Transparency
			local focusTransparency = tonumber(descendant:GetAttribute("PreparationAccentFocusTransparency")) or idleTransparency
			local breachTransparency = tonumber(descendant:GetAttribute("PreparationAccentBreachTransparency")) or focusTransparency
			local targetTransparency = breachOpen and breachTransparency or ((type(selectedTool) == "string" and selectedTool ~= "") and focusTransparency or idleTransparency)
			if stateChanged then
				tweenPreparationProperties(descendant, PREPARATION_FAST_TWEEN_INFO, {
					Color = accent,
					Transparency = targetTransparency,
				})
			else
				descendant.Color = accent
				descendant.Transparency = targetTransparency
			end
		end
	end

	local entrySign = folder:FindFirstChild("PreparationEntrySign")
	local gateLeft = folder:FindFirstChild("PreparationGateLeft")
	local gateRight = folder:FindFirstChild("PreparationGateRight")
	local gateSeal = folder:FindFirstChild("PreparationGateSeal")
	local gateHeader = folder:FindFirstChild("PreparationGateHeader")
	local gateThreshold = folder:FindFirstChild("PreparationGateThreshold")
	local gateJambLeft = folder:FindFirstChild("PreparationGateJambLeft")
	local gateJambRight = folder:FindFirstChild("PreparationGateJambRight")
	if entrySign and entrySign:IsA("BasePart") and gateLeft and gateLeft:IsA("BasePart") and gateRight and gateRight:IsA("BasePart") then
		local right = entrySign.CFrame.RightVector
		local look = entrySign.CFrame.LookVector
		local gateCenter = entrySign.Position + look * -0.14 + Vector3.new(0, -0.42, 0)
		local closedSpan = math.max(0.86, (entrySign.Size.X * 0.18))
		local openSpan = math.max(closedSpan + 2.6, (entrySign.Size.X * 0.58))
		local span = breachOpen and openSpan or closedSpan
		local gateColor = accent:Lerp(Color3.fromRGB(20, 24, 30), 0.34)
		local leftPos = gateCenter - right * span
		local rightPos = gateCenter + right * span
		local gateLeftCFrame = CFrame.lookAt(leftPos, leftPos + look, Vector3.yAxis)
		local gateRightCFrame = CFrame.lookAt(rightPos, rightPos + look, Vector3.yAxis)
		if stateChanged then
			tweenPreparationProperties(gateLeft, PREPARATION_TWEEN_INFO, {
				CFrame = gateLeftCFrame,
				Color = gateColor,
				Transparency = breachOpen and 0.16 or 0,
			})
			tweenPreparationProperties(gateRight, PREPARATION_TWEEN_INFO, {
				CFrame = gateRightCFrame,
				Color = gateColor,
				Transparency = breachOpen and 0.16 or 0,
			})
		else
			gateLeft.CFrame = gateLeftCFrame
			gateRight.CFrame = gateRightCFrame
			gateLeft.Color = gateColor
			gateRight.Color = gateColor
			gateLeft.Transparency = breachOpen and 0.16 or 0
			gateRight.Transparency = breachOpen and 0.16 or 0
		end
		gateLeft.CanCollide = not breachOpen
		gateRight.CanCollide = not breachOpen
		gateLeft.CanQuery = not breachOpen
		gateRight.CanQuery = not breachOpen
		if gateSeal and gateSeal:IsA("BasePart") then
			if stateChanged then
				tweenPreparationProperties(gateSeal, PREPARATION_TWEEN_INFO, {
					Color = accent,
					Transparency = breachOpen and 0.9 or 0.08,
				})
			else
				gateSeal.Color = accent
				gateSeal.Transparency = breachOpen and 0.9 or 0.08
			end
			if stateChanged and laneState == "breach" then
				local sealEmitter = ensurePreparationBurstEmitter(gateSeal, "BreachBurst", accent)
				if sealEmitter then
					sealEmitter:Emit(24)
				end
			end
		end
		for _, framePart in ipairs({ gateHeader, gateThreshold, gateJambLeft, gateJambRight }) do
			if framePart and framePart:IsA("BasePart") then
				local frameColor = accent:Lerp(Color3.fromRGB(28, 34, 44), 0.46)
				if stateChanged then
					tweenPreparationProperties(framePart, PREPARATION_FAST_TWEEN_INFO, {
						Color = frameColor,
						Transparency = breachOpen and 0.03 or 0,
					})
				else
					framePart.Color = frameColor
					framePart.Transparency = breachOpen and 0.03 or 0
				end
			end
		end
	end

	for index = 1, 2 do
		local brazierFlame = folder:FindFirstChild("PreparationBrazierFlame_" .. tostring(index))
		if brazierFlame and brazierFlame:IsA("BasePart") then
			local flameColor = accent:Lerp(Color3.fromRGB(255, 214, 166), 0.28)
			if stateChanged then
				tweenPreparationProperties(brazierFlame, PREPARATION_FAST_TWEEN_INFO, {
					Color = flameColor,
				})
			else
				brazierFlame.Color = flameColor
			end
			if stateChanged and laneState == "breach" then
				local flameEmitter = ensurePreparationBurstEmitter(brazierFlame, "BreachPulse", flameColor)
				if flameEmitter then
					flameEmitter:Emit(10)
				end
			end
		end
	end

	if stateChanged and laneState ~= "ready" and marqueeGlow and marqueeGlow:IsA("BasePart") then
		local marqueeEmitter = ensurePreparationBurstEmitter(marqueeGlow, "StateBurst", accent)
		if marqueeEmitter then
			marqueeEmitter:Emit(laneState == "breach" and 18 or 10)
		end
	end

	folder:SetAttribute(PREPARATION_LANE_STATE_ATTR, laneState)
end

local function updatePreparationEntrySign(entrySign, selectedTool, breachOpen, profile)
	if typeof(entrySign) ~= "Instance" then
		return
	end

	local theme = resolvePreparationTheme(profile, selectedTool, breachOpen)
	local title = type(profile) == "table" and tostring(profile.entryTitle or "MAIN ENTRY") or "MAIN ENTRY"
	local subtitle = "Breach setelah review board"
	local body = type(profile) == "table" and tostring(profile.entryReadyBody or "Ikuti runner ke pintu utama.") or "Ikuti runner ke pintu utama."
	local accent = theme.accent

	if type(selectedTool) == "string" and selectedTool ~= "" then
		subtitle = string.format("%s ready • breach armed", selectedTool)
		local template = type(profile) == "table" and tostring(profile.entryArmedBodyTemplate or "Aktifkan breach untuk sweep awal dengan %s.") or "Aktifkan breach untuk sweep awal dengan %s."
		body = string.format(template, selectedTool)
	end

	if breachOpen then
		title = "BREACH OPEN"
		subtitle = "Investigation live"
		body = type(profile) == "table" and tostring(profile.entryOpenBody or "Gate utama terbuka. Masuk ke area utama sekarang.") or "Gate utama terbuka. Masuk ke area utama sekarang."
	end

	ensureBoardSurface(
		entrySign,
		"FrontSurface",
		Enum.NormalId.Front,
		title,
		subtitle,
		body,
		accent
	)
	ensureBoardSurface(
		entrySign,
		"BackSurface",
		Enum.NormalId.Back,
		title,
		subtitle,
		body,
		accent
	)
end

local function resolvePreparationToolModelTemplate(toolData)
	if type(toolData) ~= "table" then
		return nil
	end
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	local modelsFolder = assetsFolder and assetsFolder:FindFirstChild("Models")
	local toolsFolder = modelsFolder and modelsFolder:FindFirstChild("Tools")
	if not toolsFolder then
		return nil
	end
	local modelName = type(toolData.modelName) == "string" and toolData.modelName or toolData.toolType
	local template = modelName and toolsFolder:FindFirstChild(modelName)
	if not template and type(toolData.toolType) == "string" then
		template = toolsFolder:FindFirstChild(toolData.toolType)
	end
	return template and template:IsA("Model") and template or nil
end

local function ensurePreparationToolDisplay(toolPart, toolData)
	if not (toolPart and toolPart:IsA("BasePart") and type(toolData) == "table") then
		return nil
	end

	local display = toolPart:FindFirstChild("PreparationToolDisplay")
	local template = resolvePreparationToolModelTemplate(toolData)
	if not template then
		if display then
			display:Destroy()
		end
		return nil
	end
	if not (display and display:IsA("Model") and display:GetAttribute("PasrahToolType") == toolData.toolType) then
		if display then
			display:Destroy()
		end
		display = template:Clone()
		display.Name = "PreparationToolDisplay"
		display:SetAttribute("PasrahToolType", toolData.toolType)
		display:SetAttribute("PasrahPreparationDisplay", true)
		display.Parent = toolPart
	end

	for _, descendant in ipairs(display:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	if display:GetAttribute("PasrahToolDisplayScaled") ~= true then
		local okSize, size = pcall(function()
			return display:GetExtentsSize()
		end)
		if okSize and typeof(size) == "Vector3" then
			local maxDim = math.max(size.X, size.Y, size.Z)
			local targetDim = math.max(0.18, math.min(toolPart.Size.X * 0.74, toolPart.Size.Z * 0.74, 1.25))
			if maxDim > 0.001 then
				local scaleFactor = math.clamp(targetDim / maxDim, 0.08, 4)
				pcall(function()
					display:ScaleTo(scaleFactor)
				end)
			end
		end
		display:SetAttribute("PasrahToolDisplayScaled", true)
	end

	local lift = tonumber(toolData.modelLift) or 0.62
	local yaw = math.rad(tonumber(toolData.modelYaw) or 0)
	local pivot = toolPart.CFrame
		* CFrame.new(0, (toolPart.Size.Y * 0.5) + lift, 0)
		* CFrame.Angles(0, yaw, 0)
	pcall(function()
		display:PivotTo(pivot)
	end)
	return display
end

local function isPreparationMatchPlayer(player, matchContext)
	if not (typeof(player) == "Instance" and player:IsA("Player")) then
		return false
	end
	if type(matchContext) ~= "table" then
		return tostring(player:GetAttribute("MatchLifecyclePhase") or "") == "PreparationPhase"
	end
	local expectedMatchId = tostring(matchContext.matchId or matchContext.id or "")
	local playerMatchId = tostring(player:GetAttribute("MatchId") or "")
	if expectedMatchId ~= "" and playerMatchId ~= "" and playerMatchId ~= expectedMatchId then
		return false
	end
	for _, matchPlayer in ipairs(matchContext.players or {}) do
		if matchPlayer == player then
			return true
		end
	end
	return tostring(player:GetAttribute("MatchLifecyclePhase") or "") == "PreparationPhase"
end

local function resolveSelectedPreparationTool(matchContext)
	local loadout = resolvePreparationLoadout(matchContext)
	local selectedTool = type(matchContext) == "table" and tostring(matchContext.selectedPreparationTool or "") or ""
	local selectedLabel = type(matchContext) == "table" and tostring(matchContext.selectedPreparationToolLabel or "") or ""
	if selectedTool ~= "" then
		local toolData = findPreparationToolDataByType(selectedTool)
		return selectedTool, selectedLabel ~= "" and selectedLabel or (toolData and toolData.title or selectedTool)
	end
	if #loadout > 0 then
		local fallbackTool = loadout[#loadout] or loadout[1]
		return fallbackTool, getPreparationToolLabel(fallbackTool)
	end

	if type(matchContext) == "table" then
		for _, player in ipairs(matchContext.players or {}) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				local source = tostring(player:GetAttribute("PreparationFocusToolSource") or "")
				local focusTool = tostring(player:GetAttribute("PreparationFocusTool") or "")
				if source == "WorldToolStation" and focusTool ~= "" then
					local toolData = findPreparationToolDataByType(focusTool)
					return focusTool, tostring(player:GetAttribute("PreparationFocusToolLabel") or (toolData and toolData.title) or focusTool)
				end
			end
		end
	end
	return "", ""
end

local function updatePreparationGateBlocker(blocker, selectedTool, selectedLabel, breachOpen)
	if not (blocker and blocker:IsA("BasePart")) then
		return
	end
	local selectedLoadout = type(selectedTool) == "table" and clonePreparationLoadoutList(selectedTool) or nil
	local unlocked = selectedLoadout and #selectedLoadout > 0 or (type(selectedTool) == "string" and selectedTool ~= "")
	local loadoutText = selectedLoadout and getPreparationLoadoutLabelText(selectedLoadout) or tostring(selectedLabel or selectedTool or "")
	blocker.CanCollide = not unlocked
	blocker.CanTouch = false
	blocker.CanQuery = true
	blocker.Transparency = unlocked and 0.86 or 0.35
	blocker.Color = unlocked and Color3.fromRGB(96, 178, 146) or Color3.fromRGB(170, 108, 92)
	blocker:SetAttribute("PasrahPreparationGateLocked", not unlocked)
	blocker:SetAttribute("PasrahPreparationSelectedTool", unlocked and (selectedLoadout and selectedLoadout[1] or selectedTool) or nil)
	blocker:SetAttribute("PasrahPreparationSelectedToolLabel", unlocked and loadoutText or nil)

	local title = unlocked and "TOOLS SIAP" or "SILAHKAN PILIH TOOLS"
	local subtitle = unlocked and string.format("%s terbawa", loadoutText) or "Ambil tool dari meja"
	local body = unlocked
		and (breachOpen and "Pintu sudah terbuka. Masuk untuk investigasi." or "Buka pintu depan untuk mulai investigasi.")
		or "Pilih loadout staging. Flashlight masuk otomatis, total maksimal 3 tool."
	ensureBoardSurface(
		blocker,
		"GateLabel",
		Enum.NormalId.Front,
		title,
		subtitle,
		body,
		unlocked and Color3.fromRGB(142, 214, 198) or Color3.fromRGB(240, 156, 120)
	)
end

local function applyPreparationToolSelectionState(preparationFolder, matchContext, breachOpen)
	if typeof(preparationFolder) ~= "Instance" then
		return false
	end
	local loadout = resolvePreparationLoadout(matchContext)
	local loadoutLookup = {}
	for _, toolType in ipairs(loadout) do
		loadoutLookup[toolType] = true
	end
	local selectedTool, selectedLabel = resolveSelectedPreparationTool(matchContext)
	local hasSelection = #loadout > 0 or selectedTool ~= ""
	local loadoutText = getPreparationLoadoutLabelText(loadout)
	preparationFolder:SetAttribute("SelectedPreparationTool", hasSelection and selectedTool or nil)
	preparationFolder:SetAttribute("SelectedPreparationToolLabel", hasSelection and (loadoutText ~= "" and loadoutText or selectedLabel) or nil)
	preparationFolder:SetAttribute("SelectedPreparationLoadout", hasSelection and loadoutText or nil)
	preparationFolder:SetAttribute("SelectedPreparationLoadoutCount", #loadout)
	preparationFolder:SetAttribute("PreparationEntryLaneState", breachOpen and "breach" or (hasSelection and "armed" or "ready"))

	for _, toolData in ipairs(PREPARATION_TOOL_STATIONS) do
		local toolPart = preparationFolder:FindFirstChild(toolData.name, true)
		if toolPart and toolPart:IsA("BasePart") then
			toolPart:SetAttribute("PasrahPreparationToolType", toolData.toolType)
			toolPart:SetAttribute("PasrahPreparationToolLabel", toolData.title)
			local prompt = ensurePrompt(toolPart, "Prompt", "Pilih Fokus Tool", toolData.title)
			ensurePreparationToolDisplay(toolPart, toolData)
			local statePad = preparationFolder:FindFirstChild(toolData.name .. "_Pad", true)
			updatePreparationToolStationState(toolPart, prompt, toolData, selectedTool, breachOpen == true, statePad, loadoutLookup, #loadout)
		end
	end

	local toolsBoard = preparationFolder:FindFirstChild("PreparationToolsBoard", true)
		or preparationFolder:FindFirstChild("PreparationToolsTable", true)
	if toolsBoard and toolsBoard:IsA("BasePart") then
		updatePreparationToolsBoard(toolsBoard, loadout)
	end
	local objectiveBoard = preparationFolder:FindFirstChild("PreparationObjectiveBoard", true)
	if objectiveBoard and objectiveBoard:IsA("BasePart") then
		updatePreparationObjectiveBoard(objectiveBoard, buildPreparationBoardContent(nil, matchContext or {}), selectedLabel ~= "" and selectedLabel or nil, breachOpen == true)
	end
	local entrySign = preparationFolder:FindFirstChild("PreparationEntrySign", true)
	if entrySign then
		updatePreparationEntrySign(entrySign, selectedLabel ~= "" and selectedLabel or nil, breachOpen == true, nil)
	end
	updatePreparationEntryLane(preparationFolder, selectedLabel ~= "" and selectedLabel or selectedTool, breachOpen == true, nil)
	updatePreparationGateBlocker(
		preparationFolder:FindFirstChild("PreparationToolGateBlocker", true),
		loadout,
		loadoutText ~= "" and loadoutText or selectedLabel ~= "" and selectedLabel or selectedTool,
		breachOpen == true
	)
	return true
end

local function bindPreparationToolStations(preparationFolder, matchContext)
	if typeof(preparationFolder) ~= "Instance" then
		return false
	end

	if type(matchContext) == "table" and type(matchContext._preparationToolPromptConnections) ~= "table" then
		matchContext._preparationToolPromptConnections = {}
	end
	if type(matchContext) == "table" and matchContext._preparationLoadoutInitialized ~= true then
		matchContext._preparationLoadoutInitialized = true
		matchContext.selectedPreparationTools = clonePreparationLoadoutList(matchContext.selectedPreparationTools)
		for _, player in ipairs(matchContext.players or {}) do
			if typeof(player) == "Instance" and player:IsA("Player") and #matchContext.selectedPreparationTools == 0 then
				writePreparationLoadoutToPlayer(player, {})
				player:SetAttribute("PreparationFocusTool", nil)
				player:SetAttribute("PreparationFocusToolLabel", nil)
				player:SetAttribute("PreparationFocusToolSource", nil)
				player:SetAttribute("PasrahPreparationToolSelected", nil)
				player:SetAttribute("PasrahEquippedToolType", nil)
			end
		end
	end

	for _, toolData in ipairs(PREPARATION_TOOL_STATIONS) do
		local toolPart = preparationFolder:FindFirstChild(toolData.name, true)
		if not (toolPart and toolPart:IsA("BasePart")) then
			continue
		end
		local prompt = ensurePrompt(toolPart, "Prompt", "Pilih Fokus Tool", toolData.title)
		ensurePreparationToolDisplay(toolPart, toolData)
		if prompt and prompt:GetAttribute("PasrahPreparationToolPromptBound") ~= true then
			prompt:SetAttribute("PasrahPreparationToolPromptBound", true)
			local connection = prompt.Triggered:Connect(function(player)
				if not isPreparationMatchPlayer(player, matchContext) then
					return
				end
				if type(matchContext) == "table" and tostring(matchContext.phase or "") ~= "PreparationPhase" then
					return
				end

				local currentLoadout = type(matchContext) == "table"
					and clonePreparationLoadoutList(matchContext.selectedPreparationTools)
					or {}
				if #currentLoadout == 0 then
					currentLoadout = readPreparationLoadoutFromPlayer(player)
				end
				local nextLoadout = buildPreparationLoadoutAfterSelection(currentLoadout, toolData.toolType)
				writePreparationLoadoutToPlayer(player, nextLoadout)
				player:SetAttribute("PreparationFocusTool", toolData.toolType)
				player:SetAttribute("PreparationFocusToolLabel", toolData.title)
				player:SetAttribute("PreparationFocusToolSource", "WorldToolStation")
				player:SetAttribute("PasrahPreparationToolSelected", true)
				player:SetAttribute("PasrahEquippedToolType", toolData.toolType)
				player:SetAttribute("PasrahToolUseStamp", os.clock())
				if type(matchContext) == "table" then
					matchContext.selectedPreparationTool = toolData.toolType
					matchContext.selectedPreparationToolLabel = toolData.title
					matchContext.selectedPreparationTools = nextLoadout
					matchContext.selectedPreparationToolLabels = getPreparationLoadoutLabels(nextLoadout)
				end
				applyPreparationToolSelectionState(preparationFolder, matchContext, false)
			end)
			if type(matchContext) == "table" and type(matchContext._preparationToolPromptConnections) == "table" then
				table.insert(matchContext._preparationToolPromptConnections, connection)
			end
		end
	end

	return applyPreparationToolSelectionState(preparationFolder, matchContext, false)
end

local function movePlayersToPreparationBreachTargets(folder, matchContext, outward)
	if typeof(folder) ~= "Instance" or type(matchContext) ~= "table" then
		return false
	end

	local players = matchContext.players
	if type(players) ~= "table" or #players == 0 then
		return false
	end

	local targets = {}
	for index = 1, 4 do
		local target = folder:FindFirstChild("PreparationBreachTarget_" .. tostring(index))
		if target and target:IsA("BasePart") then
			table.insert(targets, target)
		end
	end
	if #targets == 0 then
		return false
	end

	local movedAny = false
	for index, participant in ipairs(players) do
		if typeof(participant) == "Instance" and participant:IsA("Player") then
			local character = participant.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if rootPart and rootPart:IsA("BasePart") then
				local target = targets[math.min(index, #targets)]
				local targetPosition = target.Position
				character:PivotTo(CFrame.lookAt(targetPosition, targetPosition - outward, Vector3.yAxis))
				movedAny = true
			end
		end
	end

	if movedAny then
		folder:SetAttribute(PREPARATION_BREACH_MOVED_ATTR, true)
	end
	return movedAny
end

local function buildPreparationStageDecor(folder, profile, platformCenter, runnerCenter, right, outward)
	if typeof(folder) ~= "Instance" then
		return
	end

	local frameMaterial = type(profile) == "table" and profile.frameMaterial or Enum.Material.Metal
	local frameColor = type(profile) == "table" and profile.frameColor or Color3.fromRGB(76, 80, 88)
	local boardMaterial = type(profile) == "table" and profile.boardMaterial or Enum.Material.Metal
	local boardColor = type(profile) == "table" and profile.boardColor or Color3.fromRGB(34, 40, 52)
	local readyAccent = type(profile) == "table" and profile.readyAccent or Color3.fromRGB(214, 160, 104)
	local siteLabel = type(profile) == "table" and tostring(profile.siteLabel or "OUTSIDE STAGING") or "OUTSIDE STAGING"
	local siteSubtitle = type(profile) == "table" and tostring(profile.siteSubtitle or "Briefing • Tools • Breach") or "Briefing • Tools • Breach"

	local marquee = ensurePart(folder, "PreparationSiteMarquee")
	configurePart(
		marquee,
		{
			Size = Vector3.new(11.8, 2.9, 0.3),
			CFrame = CFrame.lookAt(platformCenter + (outward * 3.8) + Vector3.new(0, 5.2, 0), platformCenter - outward, Vector3.yAxis),
			Material = boardMaterial,
			Color = boardColor,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)
	ensureBoardSurface(marquee, "FrontSurface", Enum.NormalId.Front, siteLabel, siteSubtitle, "", readyAccent)
	ensureBoardSurface(marquee, "BackSurface", Enum.NormalId.Back, siteLabel, siteSubtitle, "", readyAccent)

	local marqueeAccent = ensurePart(folder, "PreparationSiteMarqueeAccent")
	configurePart(
		marqueeAccent,
		{
			Size = Vector3.new(11.2, 0.18, 0.14),
			CFrame = CFrame.lookAt(marquee.Position + Vector3.new(0, -1.32, -0.08), marquee.Position + marquee.CFrame.LookVector, Vector3.yAxis),
			Material = Enum.Material.Neon,
			Color = readyAccent,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)

	local marqueeGlow = ensurePart(folder, "PreparationSiteMarqueeGlow")
	configurePart(
		marqueeGlow,
		{
			Size = Vector3.new(1.6, 0.2, 0.16),
			CFrame = CFrame.new(marquee.Position + Vector3.new(0, 0, -0.2)),
			Material = Enum.Material.Neon,
			Color = readyAccent,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Transparency = 0.14,
		}
	)
	local glowLight = marqueeGlow:FindFirstChild("Light")
	if not (glowLight and glowLight:IsA("PointLight")) then
		if glowLight then
			glowLight:Destroy()
		end
		glowLight = cloneWorldEffectTemplate(WORLD_POINT_LIGHT_TEMPLATE_PATH, "Light", "PointLight")
		if glowLight then
			glowLight.Name = "Light"
			glowLight.Parent = marqueeGlow
		else
			warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
		end
	end
	if glowLight then
		glowLight.Range = 18
		glowLight.Brightness = 1.1
		glowLight.Color = readyAccent
		glowLight.Shadows = false
	end

	local crest = ensurePart(folder, "PreparationSiteCrest")
	configureAccentDrivenPart(
		crest,
		{
			Size = Vector3.new(1.4, 1.4, 0.12),
			CFrame = CFrame.lookAt(marquee.Position + Vector3.new(0, 0.04, -0.1), marquee.Position + marquee.CFrame.LookVector, Vector3.yAxis),
			Material = Enum.Material.Neon,
			Color = readyAccent,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Transparency = 0.12,
			Shape = Enum.PartType.Ball,
		},
		0.12,
		0.08,
		0.02
	)

	local runnerInset = ensurePart(folder, "PreparationRunnerInset")
	configureAccentDrivenPart(
		runnerInset,
		{
			Size = Vector3.new(3.6, 0.05, 12.4),
			CFrame = CFrame.lookAt(runnerCenter + Vector3.new(0, -0.06, 0), runnerCenter - outward, Vector3.yAxis),
			Material = Enum.Material.Neon,
			Color = readyAccent,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Transparency = 0.28,
		},
		0.28,
		0.14,
		0.08
	)

	local canopyTrim = ensurePart(folder, "PreparationCanopyTrim")
	configureAccentDrivenPart(
		canopyTrim,
		{
			Size = Vector3.new(10.2, 0.14, 0.22),
			CFrame = CFrame.lookAt(platformCenter + Vector3.new(0, 6.06, 2.48), platformCenter - outward, Vector3.yAxis),
			Material = Enum.Material.Neon,
			Color = readyAccent,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Transparency = 0.16,
		},
		0.16,
		0.1,
		0.04
	)

	for _, trimData in ipairs({
		{ name = "PreparationPlatformTrim_Front", size = Vector3.new(12.6, 0.12, 0.18), offset = outward * -8.1 + Vector3.new(0, 0.02, 0) },
		{ name = "PreparationPlatformTrim_Back", size = Vector3.new(12.6, 0.12, 0.18), offset = outward * 8.1 + Vector3.new(0, 0.02, 0) },
		{ name = "PreparationPlatformTrim_Left", size = Vector3.new(0.18, 0.12, 9.4), offset = right * -12.9 + Vector3.new(0, 0.02, 0) },
		{ name = "PreparationPlatformTrim_Right", size = Vector3.new(0.18, 0.12, 9.4), offset = right * 12.9 + Vector3.new(0, 0.02, 0) },
	}) do
		local trim = ensurePart(folder, trimData.name)
		configureAccentDrivenPart(
			trim,
			{
				Size = trimData.size,
				CFrame = CFrame.lookAt(platformCenter + trimData.offset, platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Neon,
				Color = readyAccent,
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
				Transparency = 0.18,
			},
			0.18,
			0.12,
			0.06
		)
	end

	local entryAccent = ensurePart(folder, "PreparationEntryAccent")
	configurePart(
		entryAccent,
		{
			Size = Vector3.new(4.1, 0.16, 0.14),
			CFrame = CFrame.lookAt(runnerCenter + (outward * -0.68) + Vector3.new(0, 1.18, 0), runnerCenter - outward, Vector3.yAxis),
			Material = Enum.Material.Neon,
			Color = readyAccent,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)

	local gateTrack = ensurePart(folder, "PreparationGateTrack")
	configurePart(
		gateTrack,
		{
			Size = Vector3.new(7.2, 0.18, 0.26),
			CFrame = CFrame.lookAt(runnerCenter + (outward * -0.72) + Vector3.new(0, 1.92, 0), runnerCenter - outward, Vector3.yAxis),
			Material = frameMaterial,
			Color = frameColor,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)
	local gateHeader = ensurePart(folder, "PreparationGateHeader")
	configurePart(
		gateHeader,
		{
			Size = Vector3.new(7.8, 0.28, 0.32),
			CFrame = CFrame.lookAt(runnerCenter + (outward * -0.78) + Vector3.new(0, 2.86, 0), runnerCenter - outward, Vector3.yAxis),
			Material = frameMaterial,
			Color = frameColor,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)
	local gateThreshold = ensurePart(folder, "PreparationGateThreshold")
	configurePart(
		gateThreshold,
		{
			Size = Vector3.new(7.4, 0.12, 0.34),
			CFrame = CFrame.lookAt(runnerCenter + (outward * -0.74) + Vector3.new(0, -0.08, 0), runnerCenter - outward, Vector3.yAxis),
			Material = frameMaterial,
			Color = frameColor,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)
	for _, side in ipairs({ -1, 1 }) do
		local gateJamb = ensurePart(folder, "PreparationGateJamb" .. (side < 0 and "Left" or "Right"))
		configurePart(
			gateJamb,
			{
				Size = Vector3.new(0.28, 3.24, 0.28),
				CFrame = CFrame.lookAt(runnerCenter + (right * side * 2.16) + (outward * -0.76) + Vector3.new(0, 1.34, 0), runnerCenter - outward, Vector3.yAxis),
				Material = frameMaterial,
				Color = frameColor,
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)
		gateJamb:SetAttribute("PreparationAccentIdleTransparency", 0)
		gateJamb:SetAttribute("PreparationAccentFocusTransparency", 0)
		gateJamb:SetAttribute("PreparationAccentBreachTransparency", 0.03)
	end
	for index, side in ipairs({ -1, 1 }) do
		local gateLeaf = ensurePart(folder, "PreparationGate" .. (side < 0 and "Left" or "Right"))
		configurePart(
			gateLeaf,
			{
				Size = Vector3.new(2.0, 3.0, 0.22),
				CFrame = CFrame.lookAt(runnerCenter + (right * side * 0.96) + (outward * -0.84) + Vector3.new(0, 1.24, 0), runnerCenter - outward, Vector3.yAxis),
				Material = frameMaterial,
				Color = frameColor,
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
	end
	local gateSeal = ensurePart(folder, "PreparationGateSeal")
	configurePart(
		gateSeal,
		{
			Size = Vector3.new(0.34, 2.84, 0.1),
			CFrame = CFrame.lookAt(runnerCenter + (outward * -0.78) + Vector3.new(0, 1.24, 0), runnerCenter - outward, Vector3.yAxis),
			Material = Enum.Material.Neon,
			Color = readyAccent,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Transparency = 0.08,
		}
	)

	local propStyle = type(profile) == "table" and profile.propStyle or nil
	if propStyle == "house" then
		local gateArch = ensurePart(folder, "PreparationGateArch")
		configurePart(
			gateArch,
			{
				Size = Vector3.new(9.6, 0.44, 1.2),
				CFrame = CFrame.lookAt(platformCenter + (outward * 5.4) + Vector3.new(0, 3.86, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromRGB(92, 74, 58),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)
		for index, side in ipairs({ -1, 1 }) do
			local porchPost = ensurePart(folder, "PreparationPorchPost_" .. tostring(index))
			configurePart(
				porchPost,
				{
					Size = Vector3.new(0.48, 4.2, 0.48),
					CFrame = CFrame.new(platformCenter + (right * side * 4.8) + (outward * -1.4) + Vector3.new(0, 2.1, 0)),
					Material = frameMaterial,
					Color = frameColor,
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local crate = ensurePart(folder, "PreparationSupplyCrate_" .. tostring(index))
			configurePart(
				crate,
				{
					Size = Vector3.new(2.4, 1.3, 1.8),
					CFrame = CFrame.lookAt(platformCenter + (right * side * 7.1) + (outward * 2.7) + Vector3.new(0, 0.66, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.WoodPlanks,
					Color = Color3.fromRGB(94, 72, 54),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
		end
		local noticeStand = ensurePart(folder, "PreparationNoticeStand")
		configurePart(
			noticeStand,
			{
				Size = Vector3.new(2.2, 2.8, 0.22),
				CFrame = CFrame.lookAt(platformCenter + (right * -10.2) + (outward * 1.2) + Vector3.new(0, 1.5, 0), platformCenter - outward, Vector3.yAxis),
				Material = boardMaterial,
				Color = boardColor,
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
		ensureBoardSurface(noticeStand, "FrontSurface", Enum.NormalId.Front, "STAGING", "Porch hold", { "Room • Contract • Tools", "Breach after review" }, readyAccent)
		local gearBench = ensurePart(folder, "PreparationGearBench")
		configurePart(
			gearBench,
			{
				Size = Vector3.new(3.8, 0.94, 1.6),
				CFrame = CFrame.lookAt(platformCenter + (right * 10.2) + (outward * 1.4) + Vector3.new(0, 0.48, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromRGB(98, 76, 58),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
		for index, side in ipairs({ -1, 1 }) do
			local rail = ensurePart(folder, "PreparationFenceRail_" .. tostring(index))
			configurePart(
				rail,
				{
					Size = Vector3.new(0.28, 1.6, 4.2),
					CFrame = CFrame.lookAt(platformCenter + (right * side * 11.8) + (outward * 4.8) + Vector3.new(0, 0.82, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.WoodPlanks,
					Color = Color3.fromRGB(86, 68, 54),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local porchLantern = ensurePart(folder, "PreparationPorchLantern_" .. tostring(index))
			configurePart(
				porchLantern,
				{
					Size = Vector3.new(0.42, 0.42, 0.42),
					CFrame = CFrame.new(platformCenter + (right * side * 5.1) + (outward * -1.3) + Vector3.new(0, 4.46, 0)),
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(255, 214, 170),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local lanternLight = porchLantern:FindFirstChild("Light")
			if not (lanternLight and lanternLight:IsA("PointLight")) then
				if lanternLight then
					lanternLight:Destroy()
				end
				lanternLight = cloneWorldEffectTemplate(WORLD_POINT_LIGHT_TEMPLATE_PATH, "Light", "PointLight")
				if lanternLight then
					lanternLight.Name = "Light"
					lanternLight.Parent = porchLantern
				else
					warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
				end
			end
			if lanternLight then
				lanternLight.Range = 14
				lanternLight.Brightness = 1.2
				lanternLight.Color = Color3.fromRGB(255, 214, 170)
				lanternLight.Shadows = false
			end

			local hedge = ensurePart(folder, "PreparationHedge_" .. tostring(index))
			configurePart(
				hedge,
				{
					Size = Vector3.new(2.6, 1.6, 4.6),
					CFrame = CFrame.lookAt(platformCenter + (right * side * 12.4) + (outward * 4.1) + Vector3.new(0, 0.82, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Grass,
					Color = Color3.fromRGB(72, 106, 68),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
		end
		local mailbox = ensurePart(folder, "PreparationMailbox")
		configurePart(
			mailbox,
			{
				Size = Vector3.new(0.8, 1.8, 0.8),
				CFrame = CFrame.lookAt(platformCenter + (right * -12.2) + (outward * 2.9) + Vector3.new(0, 0.92, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(82, 90, 108),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
		for index, side in ipairs({ -1, 1 }) do
			local facadeWall = ensurePart(folder, "PreparationHouseFacadeWall_" .. tostring(index))
			configurePart(
				facadeWall,
				{
					Size = Vector3.new(3.6, 4.8, 0.42),
					CFrame = CFrame.lookAt(platformCenter + (right * side * 6.4) + (outward * 0.4) + Vector3.new(0, 2.4, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.WoodPlanks,
					Color = Color3.fromRGB(92, 78, 70),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local window = ensurePart(folder, "PreparationHouseWindow_" .. tostring(index))
			configurePart(
				window,
				{
					Size = Vector3.new(1.5, 1.5, 0.1),
					CFrame = CFrame.lookAt(facadeWall.Position + Vector3.new(0, 0.24, -0.2), facadeWall.Position + facadeWall.CFrame.LookVector, Vector3.yAxis),
					Material = Enum.Material.Glass,
					Color = Color3.fromRGB(176, 208, 236),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
					Transparency = 0.22,
				}
			)
		end
		local roofCap = ensurePart(folder, "PreparationHouseRoofCap")
		configurePart(
			roofCap,
			{
				Size = Vector3.new(13.2, 0.36, 4.6),
				CFrame = CFrame.lookAt(platformCenter + (outward * 0.5) + Vector3.new(0, 5.06, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Slate,
				Color = Color3.fromRGB(66, 70, 84),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)
		local porchLintel = ensurePart(folder, "PreparationHousePorchLintel")
		configureAccentDrivenPart(
			porchLintel,
			{
				Size = Vector3.new(9.8, 0.18, 0.18),
				CFrame = CFrame.lookAt(platformCenter + (outward * 0.18) + Vector3.new(0, 3.12, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Neon,
				Color = readyAccent,
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
				Transparency = 0.16,
			},
			0.16,
			0.08,
			0.03
		)
	elseif propStyle == "palace" then
		local stairDais = ensurePart(folder, "PreparationStairDais")
		configurePart(
			stairDais,
			{
				Size = Vector3.new(10.8, 0.42, 3.2),
				CFrame = CFrame.lookAt(platformCenter + (outward * 5.4) + Vector3.new(0, 0.08, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Marble,
				Color = Color3.fromRGB(138, 126, 116),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
		local carpet = ensurePart(folder, "PreparationCarpet")
		configurePart(
			carpet,
			{
				Size = Vector3.new(8.2, 0.08, 17.6),
				CFrame = CFrame.lookAt(runnerCenter + (outward * 2.6) + Vector3.new(0, -0.18, 0), runnerCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Fabric,
				Color = Color3.fromRGB(112, 38, 42),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)
		for index, side in ipairs({ -1, 1 }) do
			local pillar = ensurePart(folder, "PreparationPillar_" .. tostring(index))
			configurePart(
				pillar,
				{
					Size = Vector3.new(1.1, 5.6, 1.1),
					CFrame = CFrame.new(platformCenter + (right * side * 8.6) + (outward * -0.9) + Vector3.new(0, 2.8, 0)),
					Material = Enum.Material.Marble,
					Color = Color3.fromRGB(144, 132, 124),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local brazierBase = ensurePart(folder, "PreparationBrazierBase_" .. tostring(index))
			configurePart(
				brazierBase,
				{
					Size = Vector3.new(1.6, 1.1, 1.6),
					CFrame = CFrame.new(platformCenter + (right * side * 10.8) + (outward * 0.9) + Vector3.new(0, 0.56, 0)),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(96, 78, 64),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local brazierFlame = ensurePart(folder, "PreparationBrazierFlame_" .. tostring(index))
			configurePart(
				brazierFlame,
				{
					Size = Vector3.new(0.72, 0.72, 0.72),
					CFrame = CFrame.new(brazierBase.Position + Vector3.new(0, 1.06, 0)),
					Material = Enum.Material.Neon,
					Color = readyAccent,
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local flameLight = brazierFlame:FindFirstChild("Light")
			if not (flameLight and flameLight:IsA("PointLight")) then
				if flameLight then
					flameLight:Destroy()
				end
				flameLight = cloneWorldEffectTemplate(WORLD_POINT_LIGHT_TEMPLATE_PATH, "Light", "PointLight")
				if flameLight then
					flameLight.Name = "Light"
					flameLight.Parent = brazierFlame
				else
					warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
				end
			end
			if flameLight then
				flameLight.Range = 18
				flameLight.Brightness = 1.7
				flameLight.Color = readyAccent
				flameLight.Shadows = false
			end

			local banner = ensurePart(folder, "PreparationBanner_" .. tostring(index))
			configurePart(
				banner,
				{
					Size = Vector3.new(1.4, 3.8, 0.12),
					CFrame = CFrame.lookAt(platformCenter + (right * side * 6.4) + (outward * -2.4) + Vector3.new(0, 3.4, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Fabric,
					Color = Color3.fromRGB(96, 36, 40),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)

			local urn = ensurePart(folder, "PreparationUrn_" .. tostring(index))
			configurePart(
				urn,
				{
					Size = Vector3.new(1.3, 1.9, 1.3),
					CFrame = CFrame.new(platformCenter + (right * side * 12.2) + (outward * 1.8) + Vector3.new(0, 0.96, 0)),
					Material = Enum.Material.Marble,
					Color = Color3.fromRGB(132, 120, 110),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
		end
		local archLintel = ensurePart(folder, "PreparationArchLintel")
		configurePart(
			archLintel,
			{
				Size = Vector3.new(10.6, 0.9, 0.42),
				CFrame = CFrame.lookAt(platformCenter + (outward * -1.1) + Vector3.new(0, 5.4, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Marble,
				Color = Color3.fromRGB(150, 138, 128),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
		local relicPlinth = ensurePart(folder, "PreparationRelicPlinth")
		configurePart(
			relicPlinth,
			{
				Size = Vector3.new(2.4, 1.2, 2.4),
				CFrame = CFrame.lookAt(platformCenter + (outward * 4.4) + Vector3.new(0, 0.62, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Marble,
				Color = Color3.fromRGB(136, 122, 112),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
		local relicCore = ensurePart(folder, "PreparationRelicCore")
		configurePart(
			relicCore,
			{
				Size = Vector3.new(0.82, 0.82, 0.82),
				CFrame = CFrame.new(relicPlinth.Position + Vector3.new(0, 1.12, 0)),
				Material = Enum.Material.Neon,
				Color = readyAccent,
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)
		local relicLight = relicCore:FindFirstChild("Light")
		if not (relicLight and relicLight:IsA("PointLight")) then
			if relicLight then
				relicLight:Destroy()
			end
			relicLight = cloneWorldEffectTemplate(WORLD_POINT_LIGHT_TEMPLATE_PATH, "Light", "PointLight")
			if relicLight then
				relicLight.Name = "Light"
				relicLight.Parent = relicCore
			else
				warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
			end
		end
		if relicLight then
			relicLight.Range = 16
			relicLight.Brightness = 1.35
			relicLight.Color = readyAccent
			relicLight.Shadows = false
		end
		local sealMosaic = ensurePart(folder, "PreparationSealMosaic")
		configurePart(
			sealMosaic,
			{
				Size = Vector3.new(4.4, 0.05, 4.4),
				CFrame = CFrame.lookAt(platformCenter + (outward * 2.0) + Vector3.new(0, -0.11, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Slate,
				Color = Color3.fromRGB(92, 46, 48),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)
		local porticoRoof = ensurePart(folder, "PreparationPalacePorticoRoof")
		configurePart(
			porticoRoof,
			{
				Size = Vector3.new(12.8, 0.42, 4.8),
				CFrame = CFrame.lookAt(platformCenter + (outward * 0.36) + Vector3.new(0, 5.54, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Marble,
				Color = Color3.fromRGB(148, 138, 128),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)
		for index, side in ipairs({ -1, 1 }) do
			local screen = ensurePart(folder, "PreparationPalaceScreen_" .. tostring(index))
			configurePart(
				screen,
				{
					Size = Vector3.new(2.4, 4.6, 0.24),
					CFrame = CFrame.lookAt(platformCenter + (right * side * 6.8) + (outward * 0.9) + Vector3.new(0, 2.32, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Marble,
					Color = Color3.fromRGB(142, 130, 120),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
		end
		local cornice = ensurePart(folder, "PreparationPalaceCornice")
		configureAccentDrivenPart(
			cornice,
			{
				Size = Vector3.new(11.4, 0.2, 0.16),
				CFrame = CFrame.lookAt(platformCenter + (outward * 0.22) + Vector3.new(0, 4.78, 0), platformCenter - outward, Vector3.yAxis),
				Material = Enum.Material.Neon,
				Color = readyAccent,
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
				Transparency = 0.16,
			},
			0.16,
			0.08,
			0.03
		)
	else
		local propVariant = type(profile) == "table" and tostring(profile.propVariant or "facility") or "facility"
		for index, side in ipairs({ -1, 1 }) do
			local bollard = ensurePart(folder, "PreparationMarker_" .. tostring(index))
			configurePart(
				bollard,
				{
					Size = Vector3.new(0.8, 1.8, 0.8),
					CFrame = CFrame.new(platformCenter + (right * side * 8.2) + (outward * 2.2) + Vector3.new(0, 0.9, 0)),
					Material = Enum.Material.Metal,
					Color = frameColor,
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
		end

		if propVariant == "industrial" then
			local trussFrame = ensurePart(folder, "PreparationTrussFrame")
			configurePart(
				trussFrame,
				{
					Size = Vector3.new(10.4, 0.34, 0.34),
					CFrame = CFrame.lookAt(platformCenter + (outward * 5.2) + Vector3.new(0, 4.1, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(94, 100, 112),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local crate = ensurePart(folder, "PreparationOpsCrate")
			configurePart(
				crate,
				{
					Size = Vector3.new(2.8, 1.4, 1.8),
					CFrame = CFrame.lookAt(platformCenter + (right * -7.2) + (outward * 3.1) + Vector3.new(0, 0.72, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.DiamondPlate,
					Color = Color3.fromRGB(88, 94, 104),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local monitor = ensurePart(folder, "PreparationPortableMonitor")
			configurePart(
				monitor,
				{
					Size = Vector3.new(2.4, 1.8, 0.22),
					CFrame = CFrame.lookAt(platformCenter + (right * 7.2) + (outward * 1.6) + Vector3.new(0, 1.38, 0), platformCenter - outward, Vector3.yAxis),
					Material = boardMaterial,
					Color = boardColor,
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			ensureBoardSurface(
				monitor,
				"FrontSurface",
				Enum.NormalId.Front,
				"SITE FEED",
				"Ops lane",
				{ "Check • Brief • Breach", "Prep power before entry" },
				readyAccent
			)
			for index, side in ipairs({ -1, 1 }) do
				local cone = ensurePart(folder, "PreparationSafetyCone_" .. tostring(index))
				configurePart(
					cone,
					{
						Size = Vector3.new(0.9, 1.2, 0.9),
						CFrame = CFrame.new(platformCenter + (right * side * 4.1) + (outward * 4.8) + Vector3.new(0, 0.62, 0)),
						Material = Enum.Material.Neon,
						Color = Color3.fromRGB(255, 170, 82),
						CanCollide = true,
						CanTouch = false,
						CanQuery = true,
					}
				)
			end
			local spool = ensurePart(folder, "PreparationCableSpool")
			configurePart(
				spool,
				{
					Size = Vector3.new(1.9, 1.4, 1.9),
					CFrame = CFrame.lookAt(platformCenter + (right * -9.2) + (outward * 2.8) + Vector3.new(0, 0.72, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.WoodPlanks,
					Color = Color3.fromRGB(102, 88, 72),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local worklightStand = ensurePart(folder, "PreparationWorklightStand")
			configurePart(
				worklightStand,
				{
					Size = Vector3.new(0.32, 3.4, 0.32),
					CFrame = CFrame.new(platformCenter + (right * 9.6) + (outward * 3.6) + Vector3.new(0, 1.72, 0)),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(84, 90, 102),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local worklightHead = ensurePart(folder, "PreparationWorklightHead")
			configurePart(
				worklightHead,
				{
					Size = Vector3.new(1.4, 0.34, 0.7),
					CFrame = CFrame.lookAt(worklightStand.Position + Vector3.new(0, 1.66, 0), platformCenter, Vector3.yAxis),
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(224, 232, 255),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local worklight = worklightHead:FindFirstChild("Light")
			if not (worklight and worklight:IsA("SpotLight")) then
				if worklight then
					worklight:Destroy()
				end
				worklight = cloneWorldEffectTemplate(WORLD_SPOT_LIGHT_TEMPLATE_PATH, "Light", "SpotLight")
				if worklight then
					worklight.Name = "Light"
					worklight.Parent = worklightHead
				else
					warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldSpotLightTemplate")
				end
			end
			if worklight then
				worklight.Angle = 72
				worklight.Brightness = 2.2
				worklight.Range = 28
				worklight.Color = Color3.fromRGB(224, 232, 255)
				worklight.Face = Enum.NormalId.Front
				worklight.Shadows = false
			end
			local hazardRail = ensurePart(folder, "PreparationHazardRail")
			configurePart(
				hazardRail,
				{
					Size = Vector3.new(6.2, 0.24, 0.24),
					CFrame = CFrame.lookAt(platformCenter + (outward * 5.9) + Vector3.new(0, 1.22, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(255, 178, 80),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local hangarWall = ensurePart(folder, "PreparationIndustrialWall")
			configurePart(
				hangarWall,
				{
					Size = Vector3.new(12.8, 4.8, 0.24),
					CFrame = CFrame.lookAt(platformCenter + (outward * 0.8) + Vector3.new(0, 2.4, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.CorrodedMetal,
					Color = Color3.fromRGB(88, 94, 102),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local hangarRoof = ensurePart(folder, "PreparationIndustrialRoof")
			configurePart(
				hangarRoof,
				{
					Size = Vector3.new(13.4, 0.28, 4.6),
					CFrame = CFrame.lookAt(platformCenter + (outward * 0.42) + Vector3.new(0, 5.12, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(78, 84, 96),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local catwalkStrip = ensurePart(folder, "PreparationIndustrialCatwalkStrip")
			configureAccentDrivenPart(
				catwalkStrip,
				{
					Size = Vector3.new(10.2, 0.18, 0.18),
					CFrame = CFrame.lookAt(platformCenter + (outward * 0.16) + Vector3.new(0, 3.88, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Neon,
					Color = readyAccent,
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
					Transparency = 0.18,
				},
				0.18,
				0.1,
				0.04
			)
			local generator = ensurePart(folder, "PreparationGenerator")
			configurePart(
				generator,
				{
					Size = Vector3.new(2.6, 1.8, 1.8),
					CFrame = CFrame.lookAt(platformCenter + (right * 10.2) + (outward * 2.4) + Vector3.new(0, 0.92, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.DiamondPlate,
					Color = Color3.fromRGB(98, 104, 118),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local drumStack = ensurePart(folder, "PreparationDrumStack")
			configurePart(
				drumStack,
				{
					Size = Vector3.new(1.8, 2.1, 1.8),
					CFrame = CFrame.lookAt(platformCenter + (right * -10.6) + (outward * 4.0) + Vector3.new(0, 1.06, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(72, 86, 106),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
		elseif propVariant == "control" then
			local securityArch = ensurePart(folder, "PreparationSecurityArch")
			configurePart(
				securityArch,
				{
					Size = Vector3.new(9.8, 0.3, 0.42),
					CFrame = CFrame.lookAt(platformCenter + (outward * 5.0) + Vector3.new(0, 4.2, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(72, 82, 104),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local console = ensurePart(folder, "PreparationOpsConsole")
			configurePart(
				console,
				{
					Size = Vector3.new(4.2, 1.4, 1.8),
					CFrame = CFrame.lookAt(platformCenter + (right * -6.8) + (outward * 2.6) + Vector3.new(0, 0.72, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(72, 82, 100),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local rack = ensurePart(folder, "PreparationServerRack")
			configurePart(
				rack,
				{
					Size = Vector3.new(1.8, 3.8, 1.8),
					CFrame = CFrame.lookAt(platformCenter + (right * 7.4) + (outward * 2.2) + Vector3.new(0, 1.92, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(48, 56, 70),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local display = ensurePart(folder, "PreparationSignalDisplay")
			configurePart(
				display,
				{
					Size = Vector3.new(2.8, 1.8, 0.2),
					CFrame = CFrame.lookAt(platformCenter + (right * -6.8) + (outward * 0.8) + Vector3.new(0, 1.8, 0), platformCenter - outward, Vector3.yAxis),
					Material = boardMaterial,
					Color = boardColor,
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			ensureBoardSurface(
				display,
				"FrontSurface",
				Enum.NormalId.Front,
				"SIGNAL GRID",
				"Control lane",
				{ "Plan • Tools • Entry", "Sync board before breach" },
				readyAccent
			)
			local scannerPedestal = ensurePart(folder, "PreparationAccessScanner")
			configurePart(
				scannerPedestal,
				{
					Size = Vector3.new(1.2, 2.8, 1.2),
					CFrame = CFrame.lookAt(platformCenter + (right * 9.2) + (outward * 3.2) + Vector3.new(0, 1.42, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(62, 72, 94),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local scannerGlow = ensurePart(folder, "PreparationScannerGlow")
			configurePart(
				scannerGlow,
				{
					Size = Vector3.new(0.88, 0.88, 0.18),
					CFrame = CFrame.lookAt(scannerPedestal.Position + Vector3.new(0, 0.84, -0.5), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(114, 182, 255),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local scannerLight = scannerGlow:FindFirstChild("Light")
			if not (scannerLight and scannerLight:IsA("PointLight")) then
				if scannerLight then
					scannerLight:Destroy()
				end
				scannerLight = cloneWorldEffectTemplate(WORLD_POINT_LIGHT_TEMPLATE_PATH, "Light", "PointLight")
				if scannerLight then
					scannerLight.Name = "Light"
					scannerLight.Parent = scannerGlow
				else
					warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
				end
			end
			if scannerLight then
				scannerLight.Range = 14
				scannerLight.Brightness = 1.4
				scannerLight.Color = Color3.fromRGB(114, 182, 255)
				scannerLight.Shadows = false
			end
			for index, side in ipairs({ -1, 1 }) do
				local dataColumn = ensurePart(folder, "PreparationDataColumn_" .. tostring(index))
				configurePart(
					dataColumn,
					{
						Size = Vector3.new(1.1, 3.8, 1.1),
						CFrame = CFrame.new(platformCenter + (right * side * 11.2) + (outward * 2.6) + Vector3.new(0, 1.92, 0)),
						Material = Enum.Material.Metal,
						Color = Color3.fromRGB(58, 68, 92),
						CanCollide = true,
						CanTouch = false,
						CanQuery = true,
					}
				)
			end
			local dataPedestal = ensurePart(folder, "PreparationDataPedestal")
			configurePart(
				dataPedestal,
				{
					Size = Vector3.new(1.9, 1.18, 1.9),
					CFrame = CFrame.lookAt(platformCenter + (right * -9.4) + (outward * 2.4) + Vector3.new(0, 0.6, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(54, 62, 80),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local conduitStrip = ensurePart(folder, "PreparationConduitStrip")
			configurePart(
				conduitStrip,
				{
					Size = Vector3.new(7.2, 0.18, 0.32),
					CFrame = CFrame.lookAt(platformCenter + (outward * 5.4) + Vector3.new(0, 0.12, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(88, 146, 228),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local guideStrip = ensurePart(folder, "PreparationGuideStrip")
			configurePart(
				guideStrip,
				{
					Size = Vector3.new(7.2, 0.08, 0.6),
					CFrame = CFrame.lookAt(platformCenter + (outward * 4.1) + Vector3.new(0, -0.12, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(108, 176, 255),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local controlVestibule = ensurePart(folder, "PreparationControlVestibule")
			configurePart(
				controlVestibule,
				{
					Size = Vector3.new(12.4, 4.8, 0.22),
					CFrame = CFrame.lookAt(platformCenter + (outward * 0.76) + Vector3.new(0, 2.4, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(62, 72, 92),
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
				}
			)
			local controlRoof = ensurePart(folder, "PreparationControlRoof")
			configurePart(
				controlRoof,
				{
					Size = Vector3.new(13.2, 0.28, 4.2),
					CFrame = CFrame.lookAt(platformCenter + (outward * 0.44) + Vector3.new(0, 5.02, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(56, 66, 84),
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
				}
			)
			local controlPulseBar = ensurePart(folder, "PreparationControlPulseBar")
			configureAccentDrivenPart(
				controlPulseBar,
				{
					Size = Vector3.new(9.4, 0.18, 0.18),
					CFrame = CFrame.lookAt(platformCenter + (outward * 0.14) + Vector3.new(0, 3.86, 0), platformCenter - outward, Vector3.yAxis),
					Material = Enum.Material.Neon,
					Color = readyAccent,
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
					Transparency = 0.18,
				},
				0.18,
				0.1,
				0.04
			)
		end
	end
end

local function collectStairBounds(mapClone)
	local bounds = nil

	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local includePart = descendant.Name == "CentralStaircase" or string.match(descendant.Name, "^StairStep_") ~= nil
			if includePart then
				local partBounds = getXZBounds(descendant)
				if bounds == nil then
					bounds = partBounds
				else
					bounds.minX = math.min(bounds.minX, partBounds.minX)
					bounds.maxX = math.max(bounds.maxX, partBounds.maxX)
					bounds.minZ = math.min(bounds.minZ, partBounds.minZ)
					bounds.maxZ = math.max(bounds.maxZ, partBounds.maxZ)
				end
			end
		end
	end

	if bounds == nil then
		return nil
	end

	return {
		minX = bounds.minX - STAIR_MARGIN,
		maxX = bounds.maxX + STAIR_MARGIN,
		minZ = bounds.minZ - STAIR_MARGIN,
		maxZ = bounds.maxZ + STAIR_MARGIN,
	}
end

local function carveFloorAroundStairs(floorPart, stairBounds)
	if not floorPart or not floorPart:IsA("BasePart") or not hasArea(stairBounds) then
		return false
	end

	local floorBounds = getXZBounds(floorPart)
	if not intersectsXZ(floorBounds, stairBounds) then
		return false
	end

	local cutBounds = {
		minX = math.max(floorBounds.minX, stairBounds.minX),
		maxX = math.min(floorBounds.maxX, stairBounds.maxX),
		minZ = math.max(floorBounds.minZ, stairBounds.minZ),
		maxZ = math.min(floorBounds.maxZ, stairBounds.maxZ),
	}
	if not hasArea(cutBounds) then
		return false
	end

	local fragments = {
		{
			name = floorPart.Name .. "_North",
			bounds = {
				minX = floorBounds.minX,
				maxX = floorBounds.maxX,
				minZ = floorBounds.minZ,
				maxZ = cutBounds.minZ,
			},
		},
		{
			name = floorPart.Name .. "_South",
			bounds = {
				minX = floorBounds.minX,
				maxX = floorBounds.maxX,
				minZ = cutBounds.maxZ,
				maxZ = floorBounds.maxZ,
			},
		},
		{
			name = floorPart.Name .. "_West",
			bounds = {
				minX = floorBounds.minX,
				maxX = cutBounds.minX,
				minZ = cutBounds.minZ,
				maxZ = cutBounds.maxZ,
			},
		},
		{
			name = floorPart.Name .. "_East",
			bounds = {
				minX = cutBounds.maxX,
				maxX = floorBounds.maxX,
				minZ = cutBounds.minZ,
				maxZ = cutBounds.maxZ,
			},
		},
	}

	local parent = floorPart.Parent
	floorPart:Destroy()
	if not parent then
		return true
	end

	for _, fragment in ipairs(fragments) do
		if hasArea(fragment.bounds) then
			createFloorSegment(floorPart, parent, fragment.name, fragment.bounds)
		end
	end
	return true
end

local function patchSecondFloor(mapClone)
	if not mapClone or mapClone:GetAttribute(FLOOR_PATCH_ATTR) == true then
		return false
	end

	local removedDuplicateFloor = false
	local segmentedFloors = {}
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "Floor_2_Main" then
			removedDuplicateFloor = true
			descendant:Destroy()
		elseif descendant:IsA("BasePart") and string.match(descendant.Name, "^Floor_2_") ~= nil then
			table.insert(segmentedFloors, descendant)
		end
	end

	local stairBounds = collectStairBounds(mapClone)
	local carvedAnyFloor = false
	if stairBounds ~= nil then
		for _, floorPart in ipairs(segmentedFloors) do
			if floorPart.Parent ~= nil then
				local carved = carveFloorAroundStairs(floorPart, stairBounds)
				carvedAnyFloor = carvedAnyFloor or carved
			end
		end
	end

	local didPatch = removedDuplicateFloor or carvedAnyFloor
	if didPatch then
		mapClone:SetAttribute(FLOOR_PATCH_ATTR, true)
	end
	return didPatch
end

local function ensureTraversalGuide(part)
	if not (part and part:IsA("BasePart") and part.Parent ~= nil) then
		return nil
	end
	if PLAYER_FACING_GUIDE_VISUALS_ENABLED ~= true then
		local existingFolder = part:FindFirstChild(TRAVERSAL_GUIDE_FOLDER_NAME)
		if existingFolder then
			existingFolder:Destroy()
		end
		return nil
	end
	local palette = getTraversalGuidePalette()
	part:SetAttribute("TraversalGuideLabel", "AKSES LANTAI 2")
	part:SetAttribute("TraversalGuideSubtitle", "Transisi vertikal")

	local folder = part:FindFirstChild(TRAVERSAL_GUIDE_FOLDER_NAME)
	if not (folder and folder:IsA("Folder")) then
		if folder then
			folder:Destroy()
		end
		folder = Instance.new("Folder")
		folder.Name = TRAVERSAL_GUIDE_FOLDER_NAME
		folder.Parent = part
	end

	local highlight = folder:FindFirstChild(TRAVERSAL_GUIDE_HIGHLIGHT_NAME)
	if not (highlight and highlight:IsA("Highlight")) then
		if highlight then
			highlight:Destroy()
		end
		highlight = cloneWorldEffectTemplate(WORLD_HIGHLIGHT_TEMPLATE_PATH, TRAVERSAL_GUIDE_HIGHLIGHT_NAME, "Highlight")
		if not highlight then
			warn("[MapRuntimePatches] Missing authored visual template: WorldEffects.WorldHighlightTemplate")
			return nil
		end
		highlight.Name = TRAVERSAL_GUIDE_HIGHLIGHT_NAME
		highlight.Parent = folder
	end
	highlight.Adornee = part
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = palette.accent
	highlight.FillTransparency = 0.9
	highlight.OutlineColor = palette.outline
	highlight.OutlineTransparency = 0.1
	highlight.Enabled = true

	local labelGui = folder:FindFirstChild(TRAVERSAL_GUIDE_BILLBOARD_NAME)
	if not (labelGui and labelGui:IsA("BillboardGui")) then
		if labelGui then
			labelGui:Destroy()
		end
		labelGui = cloneGuideBillboardTemplate(TRAVERSAL_GUIDE_TEMPLATE_PATH, TRAVERSAL_GUIDE_BILLBOARD_NAME)
		if not labelGui then
			warn("[MapRuntimePatches] Missing authored visual template: WorldMarkers.TraversalGuideBillboardTemplate")
			return nil
		end
		labelGui.Name = TRAVERSAL_GUIDE_BILLBOARD_NAME
		labelGui.Parent = folder
	end
	labelGui.Active = false
	labelGui.Adornee = part
	labelGui.AlwaysOnTop = true
	labelGui.Brightness = 2
	labelGui.ClipsDescendants = false
	labelGui.Enabled = true
	labelGui.LightInfluence = 0
	labelGui.MaxDistance = 120
	labelGui.ResetOnSpawn = false
	labelGui.Size = UDim2.fromOffset(210, 54)
	labelGui.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y * 0.5 + 2.8, 0)

	local panel = labelGui:FindFirstChild("Panel")
	if not (panel and panel:IsA("Frame")) then
		if panel then
			panel:Destroy()
		end
		warn("[MapRuntimePatches] TraversalGuideBillboardTemplate missing required child: Panel")
		return nil
	end

	panel.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
	panel.BackgroundTransparency = 0.14
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromScale(1, 1)
	local title = panel:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.TextColor3 = palette.title
	end
	local subtitle = panel:FindFirstChild("Subtitle")
	if subtitle and subtitle:IsA("TextLabel") then
		subtitle.TextColor3 = palette.subtitle
	end
	local stroke = panel:FindFirstChild("Stroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = palette.accent
	end
	local accent = panel:FindFirstChild("Accent")
	if accent and accent:IsA("Frame") then
		accent.BackgroundColor3 = palette.accent
	end
	return folder
end

local function patchTraversalGuides(mapClone)
	if not mapClone or mapClone:GetAttribute(TRAVERSAL_GUIDE_PATCH_ATTR) == true then
		return false
	end

	local patchedAny = false
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "CentralStaircase" then
			ensureTraversalGuide(descendant)
			patchedAny = true
		end
	end

	if patchedAny then
		mapClone:SetAttribute(TRAVERSAL_GUIDE_PATCH_ATTR, true)
	end
	return patchedAny
end

local function patchInteractionPoints(mapId, mapClone)
	if not mapClone or mapClone:GetAttribute(INTERACTION_PATCH_ATTR) == true then
		return false
	end

	local mapToken = resolveMapOverrideToken(mapId, mapClone)
	if mapToken and INTERACTION_POSITION_OVERRIDES[mapToken] == nil then
		mapToken = resolveMapOverrideToken(nil, mapClone)
	end
	local interactionOverrides = mapToken and INTERACTION_POSITION_OVERRIDES[mapToken] or nil
	local interactionDoorOverrides = mapToken and INTERACTION_DOOR_OVERRIDES[mapToken] or nil

	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	local interactionPointsFolder = mapClone:FindFirstChild("InteractionPoints", true)
	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	if not roomsFolder or not interactionPointsFolder then
		return false
	end

	local roomsByToken = {}
	for _, room in ipairs(roomsFolder:GetChildren()) do
		if room:IsA("BasePart") then
			local token = normalizeToken(room.Name:gsub("^Room_", ""))
			if token then
				roomsByToken[token] = room
			end
		end
	end

	local movedAny = false
	local guidedAny = false
	local existingInteractionsByToken = {}
	for _, interactionPoint in ipairs(interactionPointsFolder:GetChildren()) do
		if interactionPoint:IsA("BasePart") then
			local token = normalizeToken(interactionPoint.Name:gsub("^Interact_", ""))
			if token then
				existingInteractionsByToken[token] = interactionPoint
			end
			local room = token and roomsByToken[token] or nil
			if room then
				local roomLabel = titleCaseToken(room.Name:gsub("^Room_", ""))
				local targetPosition = room.Position + Vector3.new(0, INTERACTION_HEIGHT_OFFSET, 0)
				local doorOverride = interactionDoorOverrides and interactionDoorOverrides[interactionPoint.Name]
				if type(doorOverride) == "table" and doorsFolder then
					local door = doorsFolder:FindFirstChild(doorOverride.doorName)
					local anchoredTarget = resolveDoorAnchoredInteractionPosition(room, door, doorOverride.insideOffset)
					if anchoredTarget then
						targetPosition = anchoredTarget
					end
				elseif doorsFolder then
					local exactDoor = doorsFolder:FindFirstChild("Door_" .. room.Name:gsub("^Room_", ""))
					local anchoredTarget = resolveDoorAnchoredInteractionPosition(room, exactDoor, nil)
					if anchoredTarget then
						targetPosition = anchoredTarget
					end
				end
				local explicitOverride = interactionOverrides and interactionOverrides[interactionPoint.Name]
				if typeof(explicitOverride) == "Vector3" then
					targetPosition = explicitOverride
				end
				interactionPoint:SetAttribute("InteractionGuideLabel", roomLabel)
				ensureInteractionGuide(interactionPoint, roomLabel)
				guidedAny = true
				if (interactionPoint.Position - targetPosition).Magnitude > 0.5 then
					interactionPoint.CFrame = CFrame.new(targetPosition)
					movedAny = true
				end
			end
		end
	end

	for token, room in pairs(roomsByToken) do
		if existingInteractionsByToken[token] == nil then
			local interactionName = "Interact_" .. tostring(room.Name:gsub("^Room_", ""))
			local roomLabel = titleCaseToken(room.Name:gsub("^Room_", ""))
			local targetPosition = room.Position + Vector3.new(0, INTERACTION_HEIGHT_OFFSET, 0)
			if doorsFolder then
				local exactDoor = doorsFolder:FindFirstChild("Door_" .. room.Name:gsub("^Room_", ""))
				local anchoredTarget = resolveDoorAnchoredInteractionPosition(room, exactDoor, nil)
				if anchoredTarget then
					targetPosition = anchoredTarget
				end
			end
			local syntheticPoint = ensureInteractionPointPart(interactionPointsFolder, interactionName, targetPosition)
			if syntheticPoint then
				syntheticPoint:SetAttribute("SyntheticInteractionPoint", true)
				syntheticPoint:SetAttribute("InteractionGuideLabel", roomLabel)
				ensureInteractionGuide(syntheticPoint, roomLabel)
				movedAny = true
				guidedAny = true
			end
		end
	end

	if movedAny or guidedAny then
		mapClone:SetAttribute(INTERACTION_PATCH_ATTR, true)
	end
	return movedAny or guidedAny
end

local function ensureDoorPathModifier(part)
	local existing = part:FindFirstChild("DoorPathModifier")
	if existing and existing:IsA("PathfindingModifier") then
		existing.Label = "Doorway"
		existing.PassThrough = true
		return existing
	end

	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("PathfindingModifier") then
			child.Name = "DoorPathModifier"
			child.Label = "Doorway"
			child.PassThrough = true
			return child
		end
	end

	local ok, modifier = pcall(Instance.new, "PathfindingModifier")
	if not ok or not modifier then
		return nil
	end
	modifier.Name = "DoorPathModifier"
	modifier.Label = "Doorway"
	modifier.PassThrough = true
	modifier.Parent = part
	return modifier
end

local function patchDoorTraversal(mapClone)
	if not mapClone or mapClone:GetAttribute(DOOR_PATCH_ATTR) == true then
		return false
	end

	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	if not doorsFolder then
		return false
	end

	-- MatchTeleport clones every playable map for both Classic and Ranked, so this fallback stays mode-agnostic.
	local patchedAny = false
	for _, descendant in ipairs(doorsFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name:match("^Door_") and not descendant.Name:match("_Frame") then
			descendant.Anchored = true
			descendant.CanCollide = true
			descendant.CanTouch = true
			descendant.CanQuery = true
			descendant:SetAttribute("DoorLocked", false)
			descendant:SetAttribute("DoorIsOpen", false)
			if type(descendant:GetAttribute(DOOR_POLICY_ATTR)) ~= "string" or descendant:GetAttribute(DOOR_POLICY_ATTR) == "" then
				descendant:SetAttribute(DOOR_POLICY_ATTR, DEFAULT_DOOR_POLICY)
			end
			descendant:SetAttribute(DOOR_OPEN_SOUND_ATTR, DEFAULT_DOOR_OPEN_SOUND_ID)
			descendant:SetAttribute(DOOR_CLOSE_SOUND_ATTR, DEFAULT_DOOR_CLOSE_SOUND_ID)
			ensureDoorPathModifier(descendant)
			patchedAny = true
		end
	end

	if patchedAny then
		mapClone:SetAttribute(DOOR_PATCH_ATTR, true)
		mapClone:SetAttribute(DOOR_MODE_ATTR, DEFAULT_DOOR_POLICY)
	end
	return patchedAny
end

local function patchSafeZones(mapId, mapClone)
	if not USE_LEGACY_SAFEZONE_OVERRIDES then
		return false
	end

	local token = resolveMapOverrideToken(mapId, mapClone)
	if token and SAFE_ZONE_POSITION_OVERRIDES[token] == nil then
		token = resolveMapOverrideToken(nil, mapClone)
	end
	local overrides = token and SAFE_ZONE_POSITION_OVERRIDES[token]
	if not mapClone or not overrides or mapClone:GetAttribute(SAFE_ZONE_PATCH_ATTR) == true then
		return false
	end

	local safeZonesFolder = mapClone:FindFirstChild("SafeZones", true)
	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	if not safeZonesFolder then
		return false
	end

	local patchedAny = false
	for zoneName, overrideValue in pairs(overrides) do
		local targetPosition = nil
		if typeof(overrideValue) == "Vector3" then
			targetPosition = overrideValue
		elseif type(overrideValue) == "table" then
			local roomName = type(overrideValue.roomName) == "string" and overrideValue.roomName or nil
			local roomPart = roomName and roomsFolder and roomsFolder:FindFirstChild(roomName)
			local offset = typeof(overrideValue.offset) == "Vector3" and overrideValue.offset or nil
			if roomPart and roomPart:IsA("BasePart") and offset then
				targetPosition = roomPart.Position + offset
			elseif typeof(overrideValue.position) == "Vector3" then
				targetPosition = overrideValue.position
			end
		end

		if typeof(targetPosition) ~= "Vector3" then
			continue
		end

		local zone = safeZonesFolder:FindFirstChild(zoneName)
		if zone and zone:IsA("BasePart") then
			if (zone.Position - targetPosition).Magnitude > 0.05 then
				zone.CFrame = CFrame.new(targetPosition)
				patchedAny = true
			end
			zone.Anchored = true
			zone.CanCollide = false
			zone.CanTouch = false
			zone.CanQuery = true

			local roomLabel = findNearestRoomLabel(roomsFolder, zone.Position)
			local routeLabel = roomLabel and ("Anchor aman: " .. roomLabel) or "Diam di sini saat hunt"
			zone:SetAttribute("SafeZoneLabel", "SAFE ZONE")
			zone:SetAttribute("SafeZoneSubtitle", routeLabel)
			zone:SetAttribute("SafeZoneRoomLabel", roomLabel)
			zone:SetAttribute("RefugeRouteLabel", roomLabel or zoneName)
			patchedAny = true
		end
	end

	if patchedAny then
		mapClone:SetAttribute(SAFE_ZONE_PATCH_ATTR, true)
	end
	return patchedAny
end

local function findAuthoredPreparationRuntimeFolder(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return nil
	end
	local runtimeFolder = mapClone:FindFirstChild("Runtime")
	local preparationFolder = runtimeFolder and runtimeFolder:FindFirstChild(PREPARATION_STAGING_FOLDER_NAME)
	if preparationFolder and preparationFolder:IsA("Folder") then
		return preparationFolder
	end

	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("Folder") and descendant.Name == "Runtime" then
			local nestedPreparation = descendant:FindFirstChild(PREPARATION_STAGING_FOLDER_NAME)
			if nestedPreparation and nestedPreparation:IsA("Folder") then
				return nestedPreparation
			end
		end
	end
	return nil
end

local function collectAuthoredPreparationSpawns(preparationFolder)
	if typeof(preparationFolder) ~= "Instance" then
		return {}
	end
	local spawnArea = preparationFolder:FindFirstChild("PreparationSpawnArea", true)
	if not spawnArea then
		return {}
	end

	local spawns = {}
	for _, child in ipairs(spawnArea:GetDescendants()) do
		if child:IsA("BasePart") then
			spawns[#spawns + 1] = child
		end
	end
	table.sort(spawns, function(a, b)
		return tostring(a.Name) < tostring(b.Name)
	end)
	return spawns
end

local function ensureSafeZonesFromAuthoredPreparation(mapClone, preparationFolder)
	local authoredSpawns = collectAuthoredPreparationSpawns(preparationFolder)
	if #authoredSpawns == 0 then
		return false
	end

	local positions = {}
	for _, authoredSpawn in ipairs(authoredSpawns) do
		positions[#positions + 1] = authoredSpawn.Position
	end

	local safeZonesFolder = ensureFolder(mapClone, "SafeZones")
	local center = Vector3.zero
	local leftMost = positions[1]
	local rightMost = positions[#positions]
	for _, position in ipairs(positions) do
		center += position
		if position.X + position.Z < leftMost.X + leftMost.Z then
			leftMost = position
		end
		if position.X + position.Z > rightMost.X + rightMost.Z then
			rightMost = position
		end
	end
	center /= #positions
	local lateral = flattenDirection(rightMost - leftMost) or Vector3.xAxis
	local forward = Vector3.zAxis
	local blocker = preparationFolder:FindFirstChild("PreparationToolGateBlocker", true)
	if blocker and blocker:IsA("BasePart") then
		forward = flattenDirection(blocker.Position - center) or forward
	end
	local safeCenter = center + (forward * 2)
	for index, side in ipairs({ -1, 1 }) do
		local safePart = ensurePart(safeZonesFolder, "SafeZone_" .. tostring(index))
		local safePosition = safeCenter + (lateral * side * 3.5)
		configurePart(
			safePart,
			{
				Anchored = true,
				CanCollide = false,
				CanTouch = false,
				CanQuery = true,
				Transparency = 1,
				CastShadow = false,
				Size = Vector3.new(4, 7, 4),
				CFrame = CFrame.lookAt(safePosition, safePosition + forward, Vector3.yAxis),
				Color = Color3.fromRGB(255, 255, 255),
			}
		)
	end

	return true
end

local function hasAuthoredOutdoorRuntime(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return false
	end
	if findAuthoredPreparationRuntimeFolder(mapClone) then
		return true
	end
	local runtimeFolder = mapClone:FindFirstChild("Runtime", true)
	if not runtimeFolder then
		return false
	end
	local outdoorFolder = runtimeFolder:FindFirstChild("OutdoorBaseplateRuntime")
	if outdoorFolder and outdoorFolder:IsA("Folder") then
		return true
	end
	local boundaryFolder = runtimeFolder:FindFirstChild("MapBoundaryRuntime")
	if boundaryFolder and boundaryFolder:IsA("Folder") then
		return true
	end
	return false
end

local function hasAnyBasePart(folder)
	if typeof(folder) ~= "Instance" then
		return false
	end
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return true
		end
	end
	return false
end

local function resolveAuthoredRuntimeBoundaryFolder(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return nil
	end

	local runtimeFolder = mapClone:FindFirstChild("Runtime", true)
	local candidates = {}
	local seen = {}
	local function pushCandidate(folder)
		if typeof(folder) ~= "Instance" or not folder:IsA("Folder") then
			return
		end
		if seen[folder] then
			return
		end
		seen[folder] = true
		table.insert(candidates, folder)
	end

	pushCandidate(runtimeFolder and runtimeFolder:FindFirstChild("MapBoundaryRuntime"))
	pushCandidate(runtimeFolder and runtimeFolder:FindFirstChild("RuntimeBoundary"))
	pushCandidate(mapClone:FindFirstChild("RuntimeBoundary", true))

	if runtimeFolder then
		for _, descendant in ipairs(runtimeFolder:GetDescendants()) do
			if descendant:IsA("Folder") and string.find(string.lower(descendant.Name), "boundary", 1, true) then
				pushCandidate(descendant)
			end
		end
	end

	for _, folder in ipairs(candidates) do
		if hasAnyBasePart(folder) then
			return folder
		end
	end
	return nil
end

local function resolvePreparationAuthoringRoot(mapClone, preparationFolder)
	if typeof(mapClone) ~= "Instance" or typeof(preparationFolder) ~= "Instance" then
		return preparationFolder
	end
	local cursor = preparationFolder
	local directChild = preparationFolder
	while cursor and cursor.Parent and cursor.Parent ~= mapClone do
		cursor = cursor.Parent
		directChild = cursor
	end
	return directChild
end

local function applyVectorOffsetRecursive(node, delta)
	if typeof(node) ~= "Instance" or typeof(delta) ~= "Vector3" or delta.Magnitude <= 1e-4 then
		return false
	end
	if node:IsA("Model") then
		local ok, pivot = pcall(function()
			return node:GetPivot()
		end)
		if ok then
			node:PivotTo(pivot + delta)
			return true
		end
	elseif node:IsA("BasePart") then
		node.CFrame = node.CFrame + delta
		return true
	end

	local movedAny = false
	for _, child in ipairs(node:GetChildren()) do
		if applyVectorOffsetRecursive(child, delta) then
			movedAny = true
		end
	end
	return movedAny
end

local function isInsideRoomVolume(roomsFolder, worldPosition)
	if typeof(roomsFolder) ~= "Instance" or typeof(worldPosition) ~= "Vector3" then
		return false, nil
	end

	for _, room in ipairs(roomsFolder:GetDescendants()) do
		if room:IsA("BasePart") and string.find(room.Name, "Room_", 1, true) == 1 then
			local localPosition = room.CFrame:PointToObjectSpace(worldPosition)
			local half = room.Size * 0.5
			local verticalTolerance = math.max(half.Y, 8)
			if math.abs(localPosition.X) <= half.X
				and math.abs(localPosition.Y) <= verticalTolerance
				and math.abs(localPosition.Z) <= half.Z then
				return true, room
			end
		end
	end

	return false, nil
end

local function resolvePreparationStagingPlacement(anchorDoor, baseY, outward, stageDistance, roomsFolder, maxEscapeSteps)
	if not (anchorDoor and anchorDoor:IsA("BasePart") and typeof(outward) == "Vector3") then
		return nil, nil, nil, nil
	end

	local resolvedEscapeSteps = math.max(
		0,
		math.floor(tonumber(maxEscapeSteps) or PREPARATION_STAGING_ROOM_ESCAPE_MAX_STEPS)
	)

	local baseCenter = Vector3.new(
		anchorDoor.Position.X,
		baseY - 0.28,
		anchorDoor.Position.Z
	)
	local spawnOffsets = { -5.4, -1.8, 1.8, 5.4 }
	local spawnY = anchorDoor.Position.Y + 0.5

	local function probeDirection(direction)
		local right = Vector3.new(-direction.Z, 0, direction.X)
		local blockedRoomName = nil
		for step = 0, resolvedEscapeSteps do
			local distance = stageDistance + (step * PREPARATION_STAGING_ROOM_ESCAPE_STEP)
			local center = baseCenter + (direction * distance)
			local blocked = false
			for _, offset in ipairs(spawnOffsets) do
				local spawnPosition = Vector3.new(center.X, spawnY, center.Z) + (direction * 5.8) + (right * offset)
				local insideRoom, room = isInsideRoomVolume(roomsFolder, spawnPosition)
				if insideRoom then
					blocked = true
					blockedRoomName = room and room.Name or blockedRoomName
					break
				end
			end
			if not blocked then
				return {
					center = center,
					outward = direction,
					steps = step,
				}
			end
		end
		return nil, blockedRoomName
	end

	if typeof(roomsFolder) ~= "Instance" then
		return baseCenter + (outward * stageDistance), outward, 0, nil
	end

	local positive, positiveBlockedRoom = probeDirection(outward)
	local negative, negativeBlockedRoom = probeDirection(-outward)
	if positive and negative then
		if negative.steps < positive.steps then
			return negative.center, negative.outward, negative.steps, nil
		end
		return positive.center, positive.outward, positive.steps, nil
	end
	if positive then
		return positive.center, positive.outward, positive.steps, nil
	end
	if negative then
		return negative.center, negative.outward, negative.steps, nil
	end

	return baseCenter + (outward * stageDistance), outward, nil, (positiveBlockedRoom or negativeBlockedRoom)
end

local function estimateAbandonedPalaceVisualFloorY(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return nil
	end

	local bestBottomY = nil
	local bestFootprint = 0
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart")
			and descendant.Anchored
			and descendant.CanCollide
			and descendant.Position.Y > 20
			and not hasNamedAncestor(descendant, "Rooms")
			and not hasNamedAncestor(descendant, "SpawnPoints")
			and not hasNamedAncestor(descendant, "SafeZones")
			and not hasNamedAncestor(descendant, "GhostSpawns")
			and not hasNamedAncestor(descendant, "EvidenceSpawnNodes")
			and not hasNamedAncestor(descendant, "InteractionPoints")
			and not hasNamedAncestor(descendant, "Doors")
			and not hasNamedAncestor(descendant, PREPARATION_STAGING_FOLDER_NAME) then
			local footprint = math.max(descendant.Size.X, 0) * math.max(descendant.Size.Z, 0)
			if footprint >= 90 and footprint > bestFootprint then
				bestFootprint = footprint
				bestBottomY = descendant.Position.Y - (descendant.Size.Y * 0.5)
			end
		end
	end

	return bestBottomY
end

local function moveNamedFolderByDelta(mapClone, folderName, delta)
	if typeof(mapClone) ~= "Instance" or typeof(delta) ~= "Vector3" or delta.Magnitude <= 0.01 then
		return false
	end

	local folder = mapClone:FindFirstChild(folderName, true)
	if not (folder and folder:IsA("Folder")) then
		return false
	end
	return applyVectorOffsetRecursive(folder, delta)
end

local function ensureAbandonedPalacePreparationSpawns(mapClone, visualFloorY)
	local runtimeFolder = mapClone and mapClone:FindFirstChild("Runtime", true)
	local preparationFolder = runtimeFolder and runtimeFolder:FindFirstChild(PREPARATION_STAGING_FOLDER_NAME, true)
	if not (preparationFolder and preparationFolder:IsA("Folder")) then
		return false
	end

	local spawnArea = preparationFolder:FindFirstChild("PreparationSpawnArea", true)
	if not (spawnArea and spawnArea:IsA("Folder")) then
		spawnArea = Instance.new("Folder")
		spawnArea.Name = "PreparationSpawnArea"
		spawnArea.Parent = preparationFolder
	end

	local gateBlocker = preparationFolder:FindFirstChild("PreparationToolGateBlocker", true)
	local anchor = gateBlocker and gateBlocker:IsA("BasePart") and gateBlocker
		or preparationFolder:FindFirstChild("PreparationToolsTable", true)
	if anchor and anchor:IsA("Model") then
		anchor = anchor:FindFirstChild("Top", true)
	end
	if not (anchor and anchor:IsA("BasePart")) then
		return false
	end

	local baseY = tonumber(visualFloorY) or (anchor.Position.Y - 1.5)
	local center = Vector3.new(anchor.Position.X, baseY + 3.8, anchor.Position.Z + 3.5)
	local offsets = {
		Vector3.new(-4.8, 0, -2.6),
		Vector3.new(-1.6, 0, -2.6),
		Vector3.new(1.6, 0, -2.6),
		Vector3.new(4.8, 0, -2.6),
	}

	local floor = ensurePart(preparationFolder, "PreparationSpawnFloor")
	configurePart(floor, {
		Anchored = true,
		CanCollide = true,
		CanTouch = false,
		CanQuery = true,
		CastShadow = false,
		Transparency = 1,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(52, 46, 54),
		Size = Vector3.new(18, 0.75, 14),
		CFrame = CFrame.new(center.X, baseY + 0.2, center.Z),
	})
	floor:SetAttribute("PasrahRuntimePreparationFloor", true)

	for index, offset in ipairs(offsets) do
		local spawnPart = ensurePart(spawnArea, "PreparationSpawn_" .. tostring(index))
		configurePart(spawnPart, {
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
			CanQuery = true,
			CastShadow = false,
			Transparency = 1,
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(2.8, 1, 2.8),
			CFrame = CFrame.new(center + offset),
		})
		spawnPart:SetAttribute("PasrahPreparationSpawn", true)
		spawnPart:SetAttribute("PasrahRuntimeAlignedSpawn", true)
	end

	preparationFolder:SetAttribute("PasrahRuntimeSpawnAlignment", "AbandonedPalaceVisualFloor")
	return true
end

local function patchAbandonedPalaceAuthoringAlignment(mapId, mapClone)
	if typeof(mapClone) ~= "Instance" or mapClone:GetAttribute(ABANDONED_PALACE_ALIGNMENT_PATCH_ATTR) == true then
		return false
	end
	local token = resolveMapOverrideToken(mapId, mapClone) or resolveMapOverrideToken(nil, mapClone)
	if token ~= "abandonedpalace" then
		return false
	end

	local visualFloorY = estimateAbandonedPalaceVisualFloorY(mapClone)
	if not visualFloorY then
		return false
	end

	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	local firstRoom = roomsFolder and roomsFolder:FindFirstChildWhichIsA("BasePart", true)
	local roomFloorY = firstRoom and (firstRoom.Position.Y - (firstRoom.Size.Y * 0.5)) or 0
	local deltaY = visualFloorY - roomFloorY
	if math.abs(deltaY) < 15 then
		return false
	end
	local delta = Vector3.new(0, deltaY, 0)

	local movedAny = false
	for _, folderName in ipairs({
		"Rooms",
		"SpawnPoints",
		"SafeZones",
		"GhostSpawns",
		"EvidenceSpawnNodes",
		"InteractionPoints",
		"Doors",
		"RuntimeDecor",
		"OutdoorBaseplateRuntime",
	}) do
		movedAny = moveNamedFolderByDelta(mapClone, folderName, delta) or movedAny
	end

	local spawnsAligned = ensureAbandonedPalacePreparationSpawns(mapClone, visualFloorY)
	if movedAny or spawnsAligned then
		mapClone:SetAttribute(ABANDONED_PALACE_ALIGNMENT_PATCH_ATTR, true)
		mapClone:SetAttribute("AbandonedPalaceVisualFloorY", visualFloorY)
		mapClone:SetAttribute("AbandonedPalaceLogicDeltaY", deltaY)
	end
	return movedAny or spawnsAligned
end

local function patchDistantPreparationEntryAlignment(mapId, mapClone)
	if typeof(mapClone) ~= "Instance" or mapClone:GetAttribute("DistantPreparationEntryAlignmentPatched") == true then
		return false
	end
	local token = resolveMapOverrideToken(mapId, mapClone) or resolveMapOverrideToken(nil, mapClone)
	if token ~= "emptybuilding" then
		return false
	end

	local runtimeFolder = mapClone:FindFirstChild("Runtime", true)
	local preparationFolder = runtimeFolder and runtimeFolder:FindFirstChild(PREPARATION_STAGING_FOLDER_NAME, true)
	if not (preparationFolder and preparationFolder:IsA("Folder")) then
		return false
	end

	local gateBlocker = preparationFolder:FindFirstChild("PreparationToolGateBlocker", true)
	local anchor = gateBlocker and gateBlocker:IsA("BasePart") and gateBlocker
		or preparationFolder:FindFirstChild("PreparationToolsTable", true)
	if anchor and anchor:IsA("Model") then
		anchor = anchor:FindFirstChild("Top", true)
	end
	if not (anchor and anchor:IsA("BasePart")) then
		return false
	end

	local entryDoorName = PRIMARY_ENTRY_DOOR_BY_TOKEN[token]
	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	local entryDoor = doorsFolder and doorsFolder:FindFirstChild(entryDoorName, true)
	if not (entryDoor and entryDoor:IsA("BasePart")) then
		return false
	end

	local xzDistance = (Vector3.new(entryDoor.Position.X, 0, entryDoor.Position.Z)
		- Vector3.new(anchor.Position.X, 0, anchor.Position.Z)).Magnitude
	if xzDistance < 100 then
		return false
	end

	local anchorFloorY = anchor.Position.Y - (anchor.Size.Y * 0.5)
	local targetDoorPosition = Vector3.new(anchor.Position.X, anchorFloorY + (entryDoor.Size.Y * 0.5), anchor.Position.Z)
	local delta = targetDoorPosition - entryDoor.Position

	local movedAny = false
	for _, folderName in ipairs({
		"Rooms",
		"SpawnPoints",
		"SafeZones",
		"GhostSpawns",
		"EvidenceSpawnNodes",
		"InteractionPoints",
		"Doors",
		"RuntimeDecor",
	}) do
		movedAny = moveNamedFolderByDelta(mapClone, folderName, delta) or movedAny
	end

	local spawnsAligned = ensureAbandonedPalacePreparationSpawns(mapClone, anchorFloorY)
	if movedAny or spawnsAligned then
		mapClone:SetAttribute("DistantPreparationEntryAlignmentPatched", true)
		mapClone:SetAttribute("DistantPreparationEntryAlignmentDelta", tostring(delta))
	end
	return movedAny or spawnsAligned
end

local function patchPreparationStaging(mapId, mapClone, matchContext)
	if not mapClone or mapClone:GetAttribute(PREPARATION_STAGING_PATCH_ATTR) == true then
		return false
	end

	local authoredPreparationFolder = findAuthoredPreparationRuntimeFolder(mapClone)
	if not authoredPreparationFolder then
		mapClone:SetAttribute(PREPARATION_STAGING_DEBUG_ATTR, "strict_missing_authored_preparation_runtime")
		return false
	end
	local spawnArea = authoredPreparationFolder:FindFirstChild("PreparationSpawnArea", true)
	if not spawnArea then
		mapClone:SetAttribute(PREPARATION_STAGING_DEBUG_ATTR, "strict_missing_preparation_spawn_area")
		return false
	end
	local authoredSpawns = collectAuthoredPreparationSpawns(authoredPreparationFolder)
	if #authoredSpawns == 0 then
		mapClone:SetAttribute(PREPARATION_STAGING_DEBUG_ATTR, "strict_missing_preparation_spawns")
		return false
	end

	for _, authoredSpawn in ipairs(authoredSpawns) do
		authoredSpawn:SetAttribute("PasrahPreparationSpawn", true)
	end

	local legacySpawnFolder = mapClone:FindFirstChild("SpawnPoints", true)
	if legacySpawnFolder then
		legacySpawnFolder:Destroy()
	end

	local safeZonesFolder = mapClone:FindFirstChild("SafeZones", true)
	if not hasAnyBasePart(safeZonesFolder) then
		ensureSafeZonesFromAuthoredPreparation(mapClone, authoredPreparationFolder)
	end

	local strictToken = resolveMapOverrideToken(mapId, mapClone) or resolveMapOverrideToken(nil, mapClone)
	local expectedEntryDoor = strictToken and PRIMARY_ENTRY_DOOR_BY_TOKEN[strictToken] or nil
	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	local entryDoor = expectedEntryDoor and doorsFolder and doorsFolder:FindFirstChild(expectedEntryDoor, true) or nil
	if entryDoor and entryDoor:IsA("BasePart") then
		entryDoor:SetAttribute("PasrahPreparationAdvanceDoor", true)
		mapClone:SetAttribute("PreparationAdvanceDoorSource", "Authored")
	elseif expectedEntryDoor then
		mapClone:SetAttribute("PreparationAdvanceDoorSource", "Missing")
		mapClone:SetAttribute(PREPARATION_STAGING_DEBUG_ATTR, "strict_missing_preparation_advance_door")
		return false
	else
		mapClone:SetAttribute("PreparationAdvanceDoorSource", "Unspecified")
	end

	local boundaryFolder = resolveAuthoredRuntimeBoundaryFolder(mapClone)
	if boundaryFolder then
		mapClone:SetAttribute("RuntimeBoundarySource", "Authored")
	else
		mapClone:SetAttribute("RuntimeBoundarySource", "Missing")
		mapClone:SetAttribute(PREPARATION_STAGING_DEBUG_ATTR, "strict_missing_runtime_boundary")
		return false
	end

	authoredPreparationFolder:SetAttribute("NativeStagingSourceOfTruth", true)
	mapClone:SetAttribute(PREPARATION_STAGING_DEBUG_ATTR, "strict_native_runtime_authoritative")
	mapClone:SetAttribute(PREPARATION_STAGING_PATCH_ATTR, true)
	if type(matchContext) == "table" then
		matchContext.preparationWorldBoard = true
	end
	bindPreparationToolStations(authoredPreparationFolder, matchContext)
	return true
end

local function patchMapMaterials(mapId, mapClone)
	if not mapClone then
		return false
	end
	if mapClone:GetAttribute(MATERIAL_PATCH_ATTR) == true
		and mapClone:GetAttribute(MATERIAL_PATCH_VERSION_ATTR) == MATERIAL_PATCH_VERSION then
		return false
	end

	local token = resolveMapOverrideToken(mapId, mapClone)
	if token and MAP_MATERIAL_POLISH[token] == nil then
		token = resolveMapOverrideToken(nil, mapClone)
	end
	local profile = token and MAP_MATERIAL_POLISH[token] or nil
	if not profile then
		return false
	end

	local patchedAny = false
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local nameToken = normalizeToken(descendant.Name) or ""
			if string.find(nameToken, "leaf", 1, true)
				or string.find(nameToken, "leaves", 1, true)
				or string.find(nameToken, "foliage", 1, true)
				or string.find(nameToken, "bush", 1, true) then
				descendant.Material = profile.foliageMaterial or descendant.Material
				descendant.Color = profile.foliageColor or descendant.Color
				descendant.Reflectance = 0
				patchedAny = true
			elseif string.find(nameToken, "trunk", 1, true)
				or (string.find(nameToken, "tree", 1, true) and hasNamedAncestor(descendant, "BoundaryTrees")) then
				descendant.Material = profile.trunkMaterial or descendant.Material
				descendant.Color = profile.trunkColor or descendant.Color
				descendant.Reflectance = 0
				patchedAny = true
			elseif string.find(nameToken, "soil", 1, true)
				or (string.find(nameToken, "ground", 1, true) and hasNamedAncestor(descendant, "BoundaryTrees")) then
				descendant.Material = profile.soilMaterial or descendant.Material
				descendant.Color = profile.soilColor or descendant.Color
				descendant.Reflectance = 0
				patchedAny = true
			elseif string.find(nameToken, "floor", 1, true) then
				descendant.Material = profile.floorMaterial or descendant.Material
				descendant.Color = profile.floorColor or descendant.Color
				patchedAny = true
			elseif string.find(nameToken, "wall", 1, true) or string.find(nameToken, "ceiling", 1, true) then
				descendant.Material = profile.wallMaterial or descendant.Material
				descendant.Color = profile.wallColor or descendant.Color
				patchedAny = true
			elseif string.find(nameToken, "door", 1, true) or hasNamedAncestor(descendant, "Doors") then
				descendant.Material = profile.doorMaterial or descendant.Material
				descendant.Color = profile.doorColor or descendant.Color
				patchedAny = true
			elseif string.find(nameToken, "window", 1, true) or hasNamedAncestor(descendant, "Windows") then
				descendant.Material = profile.windowMaterial or descendant.Material
				descendant.Color = profile.windowColor or descendant.Color
				descendant.Transparency = profile.windowTransparency or descendant.Transparency
				descendant.Reflectance = profile.windowReflectance or descendant.Reflectance
				patchedAny = true
			end
		elseif descendant:IsA("PointLight") or descendant:IsA("SurfaceLight") or descendant:IsA("SpotLight") then
			descendant.Color = profile.lightColor or descendant.Color
			descendant.Brightness = math.max(0.05, descendant.Brightness * (profile.lightBrightnessScale or 1))
			patchedAny = true
		end
	end

	if patchedAny then
		mapClone:SetAttribute(MATERIAL_PATCH_ATTR, true)
		mapClone:SetAttribute(MATERIAL_PATCH_VERSION_ATTR, MATERIAL_PATCH_VERSION)
	end
	return patchedAny
end

local function collectMapBounds(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return nil
	end

	local minV
	local maxV
	local function absorbPart(part)
		local half = part.Size * 0.5
		local mn = part.Position - half
		local mx = part.Position + half
		if not minV then
			minV = mn
			maxV = mx
		else
			minV = Vector3.new(
				math.min(minV.X, mn.X),
				math.min(minV.Y, mn.Y),
				math.min(minV.Z, mn.Z)
			)
			maxV = Vector3.new(
				math.max(maxV.X, mx.X),
				math.max(maxV.Y, mx.Y),
				math.max(maxV.Z, mx.Z)
			)
		end
	end

	-- Prefer authored playable folders to avoid outlier parts that bloat boundary size.
	local preferredFolders = {
		"PreparationStaging",
		"PreparationStagingRuntime",
		"RuntimeMainfloor",
		"Rooms",
		"Doors",
		"SpawnPoints",
		"SafeZones",
		"GhostSpawns",
		"EvidenceSpawnNodes",
		"InteractionPoints",
	}
	for _, folderName in ipairs(preferredFolders) do
		local folder = mapClone:FindFirstChild(folderName, true)
		if folder then
			for _, descendant in ipairs(folder:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant.Parent ~= nil then
					absorbPart(descendant)
				end
			end
		end
	end

	-- Fallback when preferred folders are missing.
	if not minV or not maxV then
		for _, descendant in ipairs(mapClone:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Parent ~= nil then
				absorbPart(descendant)
			end
		end
	end

	if not minV or not maxV then
		return nil
	end

	return {
		min = minV,
		max = maxV,
	}
end

local function resolvePrimaryDoorForRuntime(token, mapClone)
	if typeof(mapClone) ~= "Instance" then
		return nil
	end

	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	if not doorsFolder then
		return nil
	end

	local explicitName = token and PRIMARY_ENTRY_DOOR_BY_TOKEN[token] or nil
	if type(explicitName) == "string" and explicitName ~= "" then
		local door = doorsFolder:FindFirstChild(explicitName)
		if door and door:IsA("BasePart") then
			return door
		end
	end

	for _, door in ipairs(doorsFolder:GetChildren()) do
		if door:IsA("BasePart") and door:GetAttribute("PasrahPreparationAdvanceDoor") == true then
			return door
		end
	end
	for _, door in ipairs(doorsFolder:GetChildren()) do
		if door:IsA("BasePart") and string.find(string.lower(door.Name), "front", 1, true) then
			return door
		end
	end
	for _, door in ipairs(doorsFolder:GetChildren()) do
		if door:IsA("BasePart") and string.find(string.lower(door.Name), "lobby", 1, true) then
			return door
		end
	end
	return nil
end

local function patchRuntimeMainfloor(mapId, mapClone)
	if not mapClone or mapClone:GetAttribute(MAINFLOOR_PATCH_ATTR) == true then
		return false
	end
	if STRICT_AUTHORED_MAP_RUNTIME then
		if hasAuthoredOutdoorRuntime(mapClone) then
			mapClone:SetAttribute(MAINFLOOR_PATCH_ATTR, true)
		end
		return false
	end
	if hasAuthoredOutdoorRuntime(mapClone) then
		mapClone:SetAttribute(MAINFLOOR_PATCH_ATTR, true)
		return false
	end

	local token = resolveMapOverrideToken(mapId, mapClone)
	if not token or MAINFLOOR_REQUIRED_TOKENS[token] ~= true then
		return false
	end

	local bounds = collectMapBounds(mapClone)
	if not bounds then
		return false
	end

	local minV = bounds.min
	local maxV = bounds.max
	local spanX = math.clamp((maxV.X - minV.X) + 22, 28, 420)
	local spanZ = math.clamp((maxV.Z - minV.Z) + 22, 28, 420)
	local centerX = (minV.X + maxV.X) * 0.5
	local centerZ = (minV.Z + maxV.Z) * 0.5
	local floorY = minV.Y - 0.8

	local folder = ensureFolder(mapClone, "RuntimeMainfloor")
	if not folder then
		return false
	end

	local pad = ensurePart(folder, "MainfloorPad")
	configurePart(
		pad,
		{
			Anchored = true,
			CanCollide = true,
			CanTouch = false,
			CanQuery = true,
			Transparency = 0,
			CastShadow = true,
			Material = Enum.Material.Concrete,
			Color = Color3.fromRGB(74, 76, 84),
			Size = Vector3.new(spanX, 1.2, spanZ),
			CFrame = CFrame.new(centerX, floorY, centerZ),
		}
	)

	mapClone:SetAttribute(MAINFLOOR_PATCH_ATTR, true)
	return true
end

local function patchPlayableFloorColliders(mapId, mapClone)
	if not mapClone or mapClone:GetAttribute(PLAYABLE_FLOOR_PATCH_ATTR) == true then
		return false
	end
	local token = resolveMapOverrideToken(mapId, mapClone) or resolveMapOverrideToken(nil, mapClone)
	if not token or PLAYABLE_FLOOR_REQUIRED_TOKENS[token] ~= true then
		return false
	end

	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	if not roomsFolder then
		return false
	end

	local floorFolder = ensureFolder(mapClone, "RuntimePlayableColliders")
	if not floorFolder then
		return false
	end
	floorFolder:SetAttribute("PasrahRuntimeGenerated", true)
	floorFolder:SetAttribute("RuntimePurpose", "GameplayFloor")

	local patchedAny = false
	local baseFloorCFrame = nil
	for _, room in ipairs(roomsFolder:GetChildren()) do
		if room:IsA("BasePart") and string.find(room.Name, "Room_", 1, true) == 1 then
			baseFloorCFrame = baseFloorCFrame or room.CFrame
			local roomId = room.Name:gsub("^Room_", "")
			local floor = ensurePart(floorFolder, "Floor_" .. roomId)
			configurePart(
				floor,
				{
					Anchored = true,
					CanCollide = true,
					CanTouch = false,
					CanQuery = true,
					Transparency = 1,
					CastShadow = false,
					Material = Enum.Material.SmoothPlastic,
					Color = Color3.fromRGB(58, 52, 58),
					Size = Vector3.new(math.max(room.Size.X, 4), 0.75, math.max(room.Size.Z, 4)),
					CFrame = room.CFrame,
				}
			)
			floor:SetAttribute("PasrahRuntimePlayableFloor", true)
			floor:SetAttribute("RoomId", roomId)
			patchedAny = true
		end
	end

	local function addGameplayPad(part, prefix, size)
		if not (part and part:IsA("BasePart")) or typeof(baseFloorCFrame) ~= "CFrame" then
			return
		end
		local pad = ensurePart(floorFolder, prefix .. "_" .. part.Name)
		local _, yaw, _ = part.CFrame:ToOrientation()
		configurePart(
			pad,
			{
				Anchored = true,
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
				Transparency = 1,
				CastShadow = false,
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(58, 52, 58),
				Size = size,
				CFrame = CFrame.new(part.Position.X, baseFloorCFrame.Position.Y, part.Position.Z) * CFrame.Angles(0, yaw, 0),
			}
		)
		pad:SetAttribute("PasrahRuntimePlayableFloor", true)
		pad:SetAttribute("RuntimeFloorSource", part:GetFullName())
		patchedAny = true
	end

	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	if doorsFolder then
		for _, door in ipairs(doorsFolder:GetChildren()) do
			if door:IsA("BasePart") and string.find(door.Name, "Door_", 1, true) == 1 then
				addGameplayPad(door, "DoorPad", Vector3.new(18, 0.75, 24))
			end
		end
	end

	if patchedAny then
		mapClone:SetAttribute(PLAYABLE_FLOOR_PATCH_ATTR, true)
	end
	return patchedAny
end

local function patchRuntimeBoundary(mapClone)
	if not mapClone or mapClone:GetAttribute(BOUNDARY_PATCH_ATTR) == true then
		return false
	end
	if STRICT_AUTHORED_MAP_RUNTIME then
		if hasAuthoredOutdoorRuntime(mapClone) then
			mapClone:SetAttribute(BOUNDARY_PATCH_ATTR, true)
		end
		return false
	end
	if hasAuthoredOutdoorRuntime(mapClone) then
		mapClone:SetAttribute(BOUNDARY_PATCH_ATTR, true)
		return false
	end

	local bounds = collectMapBounds(mapClone)
	if not bounds then
		return false
	end

	local minV = bounds.min
	local maxV = bounds.max
	local margin = 8
	local wallThickness = 6
	local wallBottom = minV.Y - 4
	local wallTop = maxV.Y + 28
	local wallHeight = math.max(36, wallTop - wallBottom)
	local wallMidY = wallBottom + (wallHeight * 0.5)

	local minX = minV.X - margin
	local maxX = maxV.X + margin
	local minZ = minV.Z - margin
	local maxZ = maxV.Z + margin
	local spanX = maxX - minX
	local spanZ = maxZ - minZ
	local centerX = (minX + maxX) * 0.5
	local centerZ = (minZ + maxZ) * 0.5

	local folder = ensureFolder(mapClone, "RuntimeBoundary")
	if not folder then
		return false
	end

	local function configureBoundary(part, size, cframe)
		configurePart(
			part,
			{
				Anchored = true,
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
				Transparency = 1,
				CastShadow = false,
				Material = Enum.Material.ForceField,
				Size = size,
				CFrame = cframe,
			}
		)
	end

	configureBoundary(
		ensurePart(folder, "Boundary_North"),
		Vector3.new(spanX, wallHeight, wallThickness),
		CFrame.new(centerX, wallMidY, minZ)
	)
	configureBoundary(
		ensurePart(folder, "Boundary_South"),
		Vector3.new(spanX, wallHeight, wallThickness),
		CFrame.new(centerX, wallMidY, maxZ)
	)
	configureBoundary(
		ensurePart(folder, "Boundary_West"),
		Vector3.new(wallThickness, wallHeight, spanZ),
		CFrame.new(minX, wallMidY, centerZ)
	)
	configureBoundary(
		ensurePart(folder, "Boundary_East"),
		Vector3.new(wallThickness, wallHeight, spanZ),
		CFrame.new(maxX, wallMidY, centerZ)
	)

	mapClone:SetAttribute(BOUNDARY_PATCH_ATTR, true)
	return true
end

local function removeDeprecatedPreparationStaging(mapClone, matchContext)
	if typeof(mapClone) ~= "Instance" then
		return false
	end

	local removedAny = false
	local deprecatedFolders = {}
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("Folder") then
			local isDeprecatedLegacy = descendant.Name == "PreparationStaging"
			local isSyntheticRuntime = descendant.Name == PREPARATION_STAGING_FOLDER_NAME
				and not (descendant.Parent ~= nil and descendant.Parent.Name == "Runtime")
			if isDeprecatedLegacy or isSyntheticRuntime then
				deprecatedFolders[#deprecatedFolders + 1] = descendant
			end
		end
	end
	for _, folder in ipairs(deprecatedFolders) do
		if folder.Parent ~= nil then
			folder:Destroy()
			removedAny = true
		end
	end

	if mapClone:GetAttribute(PREPARATION_STAGING_PATCH_ATTR) ~= nil then
		mapClone:SetAttribute(PREPARATION_STAGING_PATCH_ATTR, nil)
		removedAny = true
	end
	if mapClone:GetAttribute(PREPARATION_STAGING_DEBUG_ATTR) ~= nil then
		mapClone:SetAttribute(PREPARATION_STAGING_DEBUG_ATTR, nil)
		removedAny = true
	end

	if type(matchContext) == "table" then
		matchContext.preparationWorldBoard = false
	end

	return removedAny
end

function MapRuntimePatches.Apply(mapId, mapClone, matchContext)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token == nil or mapClone == nil then
		return false
	end

	local didPatch = false
	didPatch = disableLegacyAssetScripts(mapId, mapClone) or didPatch
	didPatch = removeDeprecatedPreparationStaging(mapClone, matchContext) or didPatch
	didPatch = patchSecondFloor(mapClone) or didPatch
	didPatch = patchLogicVolumes(mapClone) or didPatch
	didPatch = patchMapMaterials(mapId, mapClone) or didPatch
	didPatch = patchDoorTraversal(mapClone) or didPatch
	didPatch = patchInteractionPoints(mapId, mapClone) or didPatch
	didPatch = patchSafeZones(mapId, mapClone) or didPatch
	didPatch = patchAbandonedPalaceAuthoringAlignment(mapId, mapClone) or didPatch
	didPatch = patchDistantPreparationEntryAlignment(mapId, mapClone) or didPatch
	didPatch = patchPlayableFloorColliders(mapId, mapClone) or didPatch
	didPatch = patchPreparationStaging(mapId, mapClone, matchContext) or didPatch
	didPatch = patchTraversalGuides(mapClone) or didPatch
	return didPatch
end

return MapRuntimePatches
