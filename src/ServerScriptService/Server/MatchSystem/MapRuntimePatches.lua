local MapRuntimePatches = {}
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AbandonedPalaceMapScaffold = require(script.Parent.AbandonedPalaceMapScaffold)
local EmptyBuildingMapScaffold = require(script.Parent.EmptyBuildingMapScaffold)
local HauntedHouseMapScaffold = require(script.Parent.HauntedHouseMapScaffold)
local StudioMMNineteenMapScaffold = require(script.Parent.StudioMMNineteenMapScaffold)

local FLOOR_PATCH_ATTR = "SecondFloorRuntimePatched"
local INTERACTION_PATCH_ATTR = "InteractionPointsRuntimePatched"
local DOOR_PATCH_ATTR = "DoorTraversalRuntimePatched"
local SAFE_ZONE_PATCH_ATTR = "SafeZoneRuntimePatched"
local MATERIAL_PATCH_ATTR = "MapMaterialRuntimePatched"
local TRAVERSAL_GUIDE_PATCH_ATTR = "TraversalGuideRuntimePatched"
local LOGIC_VOLUME_PATCH_ATTR = "LogicVolumesRuntimeHidden"
local PREPARATION_STAGING_PATCH_ATTR = "PreparationStagingRuntimePatched"
local BOUNDARY_PATCH_ATTR = "RuntimeBoundaryPatched"
local PREPARATION_STAGING_FOLDER_NAME = "PreparationStagingRuntime"
local PREPARATION_STAGING_DEBUG_ATTR = "PreparationStagingRuntimeDebug"
local PREPARATION_LANE_STATE_ATTR = "PreparationEntryLaneState"
local PREPARATION_BREACH_MOVED_ATTR = "PreparationBreachMoved"
local DOOR_MODE_ATTR = "DoorTraversalMode"
local DOOR_POLICY_ATTR = "DoorTraversalPolicy"
local DOOR_OPEN_SOUND_ATTR = "DoorOpenSoundId"
local DOOR_CLOSE_SOUND_ATTR = "DoorCloseSoundId"
local DEFAULT_DOOR_POLICY = "HybridRadiusPrompt"
local DEFAULT_DOOR_OPEN_SOUND_ID = "rbxassetid://83005562781593"
local DEFAULT_DOOR_CLOSE_SOUND_ID = "rbxassetid://78764817933410"
local MIN_SEGMENT_SIZE = 0.25
local PREPARATION_TWEEN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PREPARATION_FAST_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
local USE_LEGACY_SPAWN_OVERRIDES = false
local USE_LEGACY_SYNTHETIC_STAGING = false
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

local SPAWN_POINT_OVERRIDES = {
	hauntedhouse = {
		PlayerSpawn_1 = {
			position = Vector3.new(-19.2, 50.5, -26.5),
		},
		PlayerSpawn_2 = {
			position = Vector3.new(-22.1, 50.5, -28.2),
		},
		PlayerSpawn_3 = {
			position = Vector3.new(-25.0, 50.5, -28.2),
		},
		PlayerSpawn_4 = {
			position = Vector3.new(-27.9, 50.5, -26.5),
		},
	},
	studiommnineteen = {
		PlayerSpawn_1 = {
			position = Vector3.new(-20.8, 10.2, -22.8),
		},
		PlayerSpawn_2 = {
			position = Vector3.new(-18.4, 10.2, -24.1),
		},
		PlayerSpawn_3 = {
			position = Vector3.new(-16.0, 10.2, -25.3),
		},
		PlayerSpawn_4 = {
			position = Vector3.new(-13.6, 10.2, -26.5),
		},
	},
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
		lightBrightnessScale = 0.88,
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
		lightBrightnessScale = 0.9,
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
		lightBrightnessScale = 0.92,
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
		lightBrightnessScale = 0.96,
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
		floodReadyBrightness = 3.2,
		floodArmedBrightness = 3.8,
		floodBreachBrightness = 4.3,
		lampReadyColor = Color3.fromRGB(255, 214, 170),
		lampArmedColor = Color3.fromRGB(184, 214, 255),
		lampBreachColor = Color3.fromRGB(190, 255, 236),
		lampReadyBrightness = 1.8,
		lampArmedBrightness = 2.1,
		lampBreachBrightness = 2.45,
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
		floodReadyBrightness = 3.6,
		floodArmedBrightness = 4.0,
		floodBreachBrightness = 4.5,
		lampReadyColor = Color3.fromRGB(255, 198, 150),
		lampArmedColor = Color3.fromRGB(188, 214, 255),
		lampBreachColor = Color3.fromRGB(198, 255, 234),
		lampReadyBrightness = 1.95,
		lampArmedBrightness = 2.2,
		lampBreachBrightness = 2.55,
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
		entryOpenBody = "Buka pintu depan lalu mulai investigasi.",
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

local PREPARATION_TOOL_STATIONS = {
	{ name = "ToolStation_EMF", title = "EMF", subtitle = "Medok sweep", color = Color3.fromRGB(132, 186, 255) },
	{ name = "ToolStation_UV", title = "UV CAM", subtitle = "To'un trace", color = Color3.fromRGB(214, 146, 255) },
	{ name = "ToolStation_THERMO", title = "THERMO", subtitle = "Freeze check", color = Color3.fromRGB(142, 214, 198) },
	{ name = "ToolStation_BOX", title = "BOX", subtitle = "Voice bait", color = Color3.fromRGB(255, 196, 118) },
	{ name = "ToolStation_WRITING", title = "WRITING", subtitle = "Book proof", color = Color3.fromRGB(150, 189, 255) },
	{ name = "ToolStation_SENSOR", title = "SENSOR", subtitle = "Movement read", color = Color3.fromRGB(255, 130, 130) },
}

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
		billboard = Instance.new("BillboardGui")
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
		panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = panel

		local stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = palette.accent
		stroke.Transparency = 0.2
		stroke.Thickness = 1.2
		stroke.Parent = panel

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.BorderSizePixel = 0
		title.Position = UDim2.new(0, 14, 0, 5)
		title.Size = UDim2.new(1, -28, 0, 16)
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = palette.title
		title.TextSize = 12
		title.TextWrapped = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = panel

		local subtitle = Instance.new("TextLabel")
		subtitle.Name = "Subtitle"
		subtitle.BackgroundTransparency = 1
		subtitle.BorderSizePixel = 0
		subtitle.Position = UDim2.new(0, 14, 0, 20)
		subtitle.Size = UDim2.new(1, -28, 0, 14)
		subtitle.Font = Enum.Font.GothamMedium
		subtitle.Text = guideSubtitle
		subtitle.TextColor3 = palette.subtitle
		subtitle.TextSize = 10
		subtitle.TextWrapped = true
		subtitle.TextXAlignment = Enum.TextXAlignment.Left
		subtitle.Parent = panel
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

local function createGuideTextLabel(name, font, textSize, textColor, text, height, position)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Position = position
	label.Size = UDim2.new(1, -18, 0, height)
	label.Font = font
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = textSize
	label.TextStrokeTransparency = 0.82
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	return label
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
		surface = Instance.new("SurfaceGui")
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
		panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.Parent = surface

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 18)
		corner.Parent = panel

		local stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Transparency = 0.14
		stroke.Thickness = 2
		stroke.Parent = panel

		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.AnchorPoint = Vector2.new(0, 0.5)
		accent.BorderSizePixel = 0
		accent.Position = UDim2.new(0, 18, 0.5, 0)
		accent.Size = UDim2.fromOffset(6, 180)
		accent.Parent = panel

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(1, 0)
		accentCorner.Parent = accent

		createGuideTextLabel(
			"Title",
			Enum.Font.GothamBold,
			28,
			Color3.fromRGB(242, 246, 252),
			titleText or "",
			38,
			UDim2.new(0, 38, 0, 26)
		).Parent = panel

		createGuideTextLabel(
			"Subtitle",
			Enum.Font.GothamMedium,
			18,
			Color3.fromRGB(188, 204, 236),
			subtitleText or "",
			28,
			UDim2.new(0, 38, 0, 66)
		).Parent = panel

		local body = createGuideTextLabel(
			"Body",
			Enum.Font.GothamMedium,
			16,
			Color3.fromRGB(220, 228, 238),
			"",
			260,
			UDim2.new(0, 38, 0, 116)
		)
		body.Size = UDim2.new(1, -66, 1, -138)
		body.TextWrapped = true
		body.Parent = panel
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
		toolsSubtitle = "Default field kit briefing",
		toolsLines = toolLines,
	}
end

local function updatePreparationToolsBoard(boardPart, selectedTool)
	local lines = {
		"Field kit issued for first sweep.",
		"EMF • UV CAM • THERMO",
		"BOX • WRITING • SENSOR",
		"Support kit: GARAM • SALIB • DUPA",
	}
	local subtitle = "Default field kit briefing"
	if type(selectedTool) == "string" and selectedTool ~= "" then
		subtitle = string.format("%s ready for first sweep", selectedTool)
		table.insert(lines, 1, string.format("Focus awal: %s", selectedTool))
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

local function updatePreparationToolStationState(toolPart, prompt, toolData, selectedTool, breachOpen, statePad)
	if not (toolPart and toolPart:IsA("BasePart") and type(toolData) == "table") then
		return
	end

	local isSelected = type(selectedTool) == "string" and selectedTool == toolData.title
	local accentColor = toolData.color or Color3.fromRGB(132, 186, 255)
	local highlightColor = accentColor:Lerp(Color3.new(1, 1, 1), 0.18)
	local idleColor = accentColor:Lerp(Color3.fromRGB(46, 52, 64), 0.18)

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
		stateSubtitle = "Focus active • use first"
		stateBody = "Gunakan tool ini untuk sweep pertama sebelum ganti jalur evidence."
		padColor = accentColor
		padTransparency = 0.12
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
		highlight = Instance.new("Highlight")
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
		stateLight = Instance.new("PointLight")
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
		emitter = Instance.new("ParticleEmitter")
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
	local floodReadyBrightness = type(profile) == "table" and tonumber(profile.floodReadyBrightness) or 3.2
	local floodArmedBrightness = type(profile) == "table" and tonumber(profile.floodArmedBrightness) or 3.8
	local floodBreachBrightness = type(profile) == "table" and tonumber(profile.floodBreachBrightness) or 4.3
	local lampReadyColor = type(profile) == "table" and profile.lampReadyColor or Color3.fromRGB(255, 214, 170)
	local lampArmedColor = type(profile) == "table" and profile.lampArmedColor or Color3.fromRGB(184, 214, 255)
	local lampBreachColor = type(profile) == "table" and profile.lampBreachColor or Color3.fromRGB(190, 255, 236)
	local lampReadyBrightness = type(profile) == "table" and tonumber(profile.lampReadyBrightness) or 1.8
	local lampArmedBrightness = type(profile) == "table" and tonumber(profile.lampArmedBrightness) or 2.1
	local lampBreachBrightness = type(profile) == "table" and tonumber(profile.lampBreachBrightness) or 2.45

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
		light = Instance.new("PointLight")
		light.Name = "Light"
		light.Parent = beaconPart
	end
	light.Color = color
	light.Brightness = breachOpen and 1.8 or 1.25
	light.Range = 16
	light.Shadows = false
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
		glowLight = Instance.new("PointLight")
		glowLight.Name = "Light"
		glowLight.Parent = marqueeGlow
	end
	glowLight.Range = 18
	glowLight.Brightness = 1.1
	glowLight.Color = readyAccent
	glowLight.Shadows = false

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
				lanternLight = Instance.new("PointLight")
				lanternLight.Name = "Light"
				lanternLight.Parent = porchLantern
			end
			lanternLight.Range = 14
			lanternLight.Brightness = 1.2
			lanternLight.Color = Color3.fromRGB(255, 214, 170)
			lanternLight.Shadows = false

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
				flameLight = Instance.new("PointLight")
				flameLight.Name = "Light"
				flameLight.Parent = brazierFlame
			end
			flameLight.Range = 18
			flameLight.Brightness = 1.7
			flameLight.Color = readyAccent
			flameLight.Shadows = false

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
			relicLight = Instance.new("PointLight")
			relicLight.Name = "Light"
			relicLight.Parent = relicCore
		end
		relicLight.Range = 16
		relicLight.Brightness = 1.35
		relicLight.Color = readyAccent
		relicLight.Shadows = false
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
				worklight = Instance.new("SpotLight")
				worklight.Name = "Light"
				worklight.Parent = worklightHead
			end
			worklight.Angle = 72
			worklight.Brightness = 2.2
			worklight.Range = 28
			worklight.Color = Color3.fromRGB(224, 232, 255)
			worklight.Face = Enum.NormalId.Front
			worklight.Shadows = false
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
				scannerLight = Instance.new("PointLight")
				scannerLight.Name = "Light"
				scannerLight.Parent = scannerGlow
			end
			scannerLight.Range = 14
			scannerLight.Brightness = 1.4
			scannerLight.Color = Color3.fromRGB(114, 182, 255)
			scannerLight.Shadows = false
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
		highlight = Instance.new("Highlight")
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
		labelGui = Instance.new("BillboardGui")
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
		panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.Parent = labelGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = panel

		local stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = palette.accent
		stroke.Transparency = 0.12
		stroke.Thickness = 1.4
		stroke.Parent = panel

		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.AnchorPoint = Vector2.new(0, 0.5)
		accent.BackgroundColor3 = palette.accent
		accent.BorderSizePixel = 0
		accent.Position = UDim2.new(0, 10, 0.5, 0)
		accent.Size = UDim2.fromOffset(3, 28)
		accent.Parent = panel

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(1, 0)
		accentCorner.Parent = accent

		createGuideTextLabel(
			"Title",
			Enum.Font.GothamBold,
			13,
			palette.title,
			"AKSES LANTAI 2",
			18,
			UDim2.new(0, 20, 0, 6)
		).Parent = panel

		createGuideTextLabel(
			"Subtitle",
			Enum.Font.GothamMedium,
			11,
			palette.subtitle,
			"Naik lewat tangga pusat",
			16,
			UDim2.new(0, 20, 0, 23)
		).Parent = panel
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

local function patchSpawnPoints(mapId, mapClone)
	if not USE_LEGACY_SPAWN_OVERRIDES then
		return false
	end

	local token = resolveMapOverrideToken(mapId, mapClone)
	if token and SPAWN_POINT_OVERRIDES[token] == nil then
		token = resolveMapOverrideToken(nil, mapClone)
	end
	local overrides = token and SPAWN_POINT_OVERRIDES[token]
	if not mapClone or not overrides then
		return false
	end

	local spawnFolder = mapClone:FindFirstChild("SpawnPoints", true)
	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	if not spawnFolder then
		return false
	end

	local patchedAny = false
	for spawnName, overrideValue in pairs(overrides) do
		local spawnPart = spawnFolder:FindFirstChild(spawnName)
		if spawnPart and spawnPart:IsA("BasePart") then
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

			if typeof(targetPosition) == "Vector3" and (spawnPart.Position - targetPosition).Magnitude > 0.05 then
				spawnPart.CFrame = CFrame.new(targetPosition)
				patchedAny = true
			end
		end
	end

	return patchedAny
end

local function patchPreparationStaging(mapId, mapClone, matchContext)
	if not mapClone or mapClone:GetAttribute(PREPARATION_STAGING_PATCH_ATTR) == true then
		return false
	end

	if not USE_LEGACY_SYNTHETIC_STAGING then
		-- Keep a marker folder for world-preparation UI detection, but do not generate synthetic geometry.
		local markerFolder = mapClone:FindFirstChild(PREPARATION_STAGING_FOLDER_NAME)
		if not markerFolder then
			markerFolder = Instance.new("Folder")
			markerFolder.Name = PREPARATION_STAGING_FOLDER_NAME
			markerFolder.Parent = mapClone
		end
		for _, child in ipairs(markerFolder:GetChildren()) do
			child:Destroy()
		end
		markerFolder:SetAttribute("NativeStagingSourceOfTruth", true)

		local token = resolveMapOverrideToken(mapId, mapClone)
		if token and PREPARATION_STAGING_PROFILES[token] == nil then
			token = resolveMapOverrideToken(nil, mapClone)
		end
		local profile = token and PREPARATION_STAGING_PROFILES[token] or nil
		local didReanchor = false
		local roomsFolder = mapClone:FindFirstChild("Rooms", true)
		local doorsFolder = mapClone:FindFirstChild("Doors", true)
		local spawnFolder = mapClone:FindFirstChild("SpawnPoints", true)
		local safeZonesFolder = mapClone:FindFirstChild("SafeZones", true)

		if profile and roomsFolder and doorsFolder and spawnFolder then
			local anchorRoom = roomsFolder:FindFirstChild(profile.anchorRoomName, true)
			local anchorDoor = doorsFolder:FindFirstChild(profile.anchorDoorName, true)
			if anchorRoom and anchorRoom:IsA("BasePart") and anchorDoor and anchorDoor:IsA("BasePart") then
				local outward = flattenDirection(anchorDoor.Position - anchorRoom.Position)
				if outward then
					local right = Vector3.new(-outward.Z, 0, outward.X)
					local spawnCenter = anchorDoor.Position + (outward * 8.5) + Vector3.new(0, 0.5, 0)
					local spawnOne = spawnFolder:FindFirstChild("PlayerSpawn_1")
					local needsSpawnReanchor = not (spawnOne and spawnOne:IsA("BasePart"))
						or (spawnOne.Position - spawnCenter).Magnitude > 24

					if needsSpawnReanchor then
						local spawnOffsets = { -5.4, -1.8, 1.8, 5.4 }
						for index = 1, 4 do
							local spawnPart = ensurePart(spawnFolder, "PlayerSpawn_" .. tostring(index))
							local spawnPosition = spawnCenter + (right * spawnOffsets[index])
							configurePart(
								spawnPart,
								{
									Size = Vector3.new(1, 1, 1),
									CFrame = CFrame.lookAt(spawnPosition, spawnPosition - outward, Vector3.yAxis),
									Transparency = 1,
									CanCollide = false,
									CanTouch = false,
									CanQuery = false,
									Color = Color3.fromRGB(255, 255, 255),
								}
							)
						end
						didReanchor = true
					end

					if safeZonesFolder then
						local safeOne = safeZonesFolder:FindFirstChild("SafeZone_1")
						local safeCenter = spawnCenter + (outward * 1.8)
						local needsSafeReanchor = not (safeOne and safeOne:IsA("BasePart"))
							or (safeOne.Position - safeCenter).Magnitude > 28
						if needsSafeReanchor then
							local safeOffsets = { -3.2, 3.2 }
							for index = 1, 2 do
								local safePart = ensurePart(safeZonesFolder, "SafeZone_" .. tostring(index))
								local safePosition = safeCenter + (right * safeOffsets[index])
								configurePart(
									safePart,
									{
										Size = Vector3.new(4, 7, 4),
										CFrame = CFrame.lookAt(safePosition, safePosition - outward, Vector3.yAxis),
										Transparency = 1,
										CanCollide = false,
										CanTouch = false,
										CanQuery = true,
										Color = Color3.fromRGB(255, 255, 255),
									}
								)
							end
							didReanchor = true
						end
					end
				end
			end
		end

		mapClone:SetAttribute(
			PREPARATION_STAGING_DEBUG_ATTR,
			didReanchor and "native_map_reanchored" or "native_map_authoritative"
		)
		mapClone:SetAttribute(PREPARATION_STAGING_PATCH_ATTR, true)
		if type(matchContext) == "table" then
			matchContext.preparationWorldBoard = true
		end
		return true
	end

	local function setPreparationDebug(stage)
		if mapClone then
			mapClone:SetAttribute(PREPARATION_STAGING_DEBUG_ATTR, tostring(stage or ""))
		end
	end

	local token = resolveMapOverrideToken(mapId, mapClone)
	if token and PREPARATION_STAGING_PROFILES[token] == nil then
		token = resolveMapOverrideToken(nil, mapClone)
	end
	local profile = token and PREPARATION_STAGING_PROFILES[token] or nil
	if not profile then
		setPreparationDebug("profile_missing")
		return false
	end

	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	local spawnFolder = mapClone:FindFirstChild("SpawnPoints", true)
	if not (roomsFolder and doorsFolder and spawnFolder) then
		setPreparationDebug("folder_missing")
		return false
	end

	local anchorRoom = roomsFolder:FindFirstChild(profile.anchorRoomName, true)
	local anchorDoor = doorsFolder:FindFirstChild(profile.anchorDoorName, true)
	if not (anchorRoom and anchorRoom:IsA("BasePart") and anchorDoor and anchorDoor:IsA("BasePart")) then
		setPreparationDebug(string.format(
			"anchor_missing|token=%s|room=%s|door=%s",
			tostring(token),
			tostring(anchorRoom and anchorRoom:GetFullName() or "nil"),
			tostring(anchorDoor and anchorDoor:GetFullName() or "nil")
		))
		return false
	end

	local outward = flattenDirection(anchorDoor.Position - anchorRoom.Position)
	if not outward then
		setPreparationDebug("outward_missing")
		return false
	end
	local ok, result = xpcall(function()
		setPreparationDebug("start|" .. tostring(token))
		local right = Vector3.new(-outward.Z, 0, outward.X)
		local stageDistance = tonumber(profile.stagingDistance) or 18
		local platformWidth = tonumber(profile.platformWidth) or 28
		local platformDepth = tonumber(profile.platformDepth) or 18
		local boardData = buildPreparationBoardContent(mapId, matchContext)
		local baseY = anchorRoom.Position.Y
		local platformCenter = Vector3.new(
			anchorDoor.Position.X,
			baseY - 0.28,
			anchorDoor.Position.Z
		) + (outward * stageDistance)
		local existingBounds = collectMapXZBounds(mapClone, mapClone:FindFirstChild(PREPARATION_STAGING_FOLDER_NAME))
		if existingBounds then
			local shellPadding = (platformDepth * 0.5) + 12
			if math.abs(outward.X) >= math.abs(outward.Z) then
				local targetX = outward.X >= 0
					and (existingBounds.maxX + shellPadding)
					or (existingBounds.minX - shellPadding)
				platformCenter = Vector3.new(targetX, platformCenter.Y, anchorDoor.Position.Z)
			else
				local targetZ = outward.Z >= 0
					and (existingBounds.maxZ + shellPadding)
					or (existingBounds.minZ - shellPadding)
				platformCenter = Vector3.new(anchorDoor.Position.X, platformCenter.Y, targetZ)
			end
		end

		local existingFolder = mapClone:FindFirstChild(PREPARATION_STAGING_FOLDER_NAME)
		if existingFolder then
			existingFolder:Destroy()
		end
		local folder = ensureFolder(mapClone, PREPARATION_STAGING_FOLDER_NAME)
		if not folder then
			setPreparationDebug("folder_create_failed")
			return false
		end
		setPreparationDebug("folder_ready")

		local platformCFrame = CFrame.lookAt(platformCenter, platformCenter - outward, Vector3.yAxis)
		configurePart(
			ensurePart(folder, "PreparationPlatform"),
			{
				Size = Vector3.new(platformWidth, 0.32, platformDepth),
				CFrame = platformCFrame,
				Material = type(profile) == "table" and profile.platformMaterial or Enum.Material.Concrete,
				Color = type(profile) == "table" and profile.platformColor or Color3.fromRGB(64, 66, 74),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)

		local runnerLength = math.max(10, (platformCenter - anchorDoor.Position).Magnitude - 2)
		local runnerCenter = Vector3.new(
			(platformCenter.X + anchorDoor.Position.X) * 0.5,
			baseY - 0.32,
			(platformCenter.Z + anchorDoor.Position.Z) * 0.5
		)
		configurePart(
			ensurePart(folder, "PreparationRunner"),
			{
				Size = Vector3.new(math.max(8, platformWidth * 0.44), 0.18, runnerLength),
				CFrame = CFrame.lookAt(runnerCenter, runnerCenter - outward, Vector3.yAxis),
				Material = type(profile) == "table" and profile.runnerMaterial or Enum.Material.Slate,
				Color = Color3.fromRGB(88, 92, 102),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)

	configurePart(
		ensurePart(folder, "PreparationForecourt"),
		{
			Size = Vector3.new(platformWidth + 16, 0.16, platformDepth + 14),
			CFrame = CFrame.lookAt(platformCenter + (outward * 2.8) + Vector3.new(0, -0.12, 0), platformCenter - outward, Vector3.yAxis),
			Material = type(profile) == "table" and profile.forecourtMaterial or Enum.Material.Asphalt,
			Color = type(profile) == "table" and profile.forecourtColor or Color3.fromRGB(52, 56, 64),
			CanCollide = true,
			CanTouch = false,
			CanQuery = true,
		}
	)

	local fenceHeight = 4.2
	local fenceBack = ensurePart(folder, "PreparationFence_Back")
	configurePart(
		fenceBack,
		{
			Size = Vector3.new(platformWidth + 14, fenceHeight, 0.22),
				CFrame = CFrame.lookAt(platformCenter + (outward * ((platformDepth * 0.5) + 6.8)) + Vector3.new(0, 2.1, 0), platformCenter - outward, Vector3.yAxis),
				Material = type(profile) == "table" and (profile.frameMaterial or Enum.Material.Metal) or Enum.Material.Metal,
				Color = type(profile) == "table" and (profile.frameColor or Color3.fromRGB(98, 104, 114)) or Color3.fromRGB(98, 104, 114),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
	)
	for index, side in ipairs({ -1, 1 }) do
		local fenceSide = ensurePart(folder, "PreparationFence_Side_" .. tostring(index))
		configurePart(
			fenceSide,
			{
				Size = Vector3.new(0.22, fenceHeight, platformDepth + 10),
				CFrame = CFrame.lookAt(
					platformCenter + (right * side * ((platformWidth * 0.5) + 6.8)) + Vector3.new(0, 2.1, 0),
					platformCenter - outward,
					Vector3.yAxis
				),
				Material = type(profile) == "table" and (profile.frameMaterial or Enum.Material.Metal) or Enum.Material.Metal,
				Color = type(profile) == "table" and (profile.frameColor or Color3.fromRGB(98, 104, 114)) or Color3.fromRGB(98, 104, 114),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
	end

	for index, side in ipairs({ -1, 1 }) do
		local barrier = ensurePart(folder, "PreparationBarrier_" .. tostring(index))
		configurePart(
			barrier,
			{
				Size = Vector3.new(3.8, 1.1, 0.9),
				CFrame = CFrame.lookAt(
					platformCenter + (right * side * ((platformWidth * 0.5) - 3.8)) + (outward * 6.8) + Vector3.new(0, 0.58, 0),
					platformCenter - outward,
					Vector3.yAxis
				),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(244, 180, 88),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
	end

	configurePart(
		ensurePart(folder, "PreparationCanopy"),
			{
				Size = Vector3.new(platformWidth - 2, 0.24, 5.2),
				CFrame = CFrame.lookAt(platformCenter + Vector3.new(0, 6.2, 0), platformCenter - outward, Vector3.yAxis),
				Material = type(profile) == "table" and (profile.canopyMaterial or Enum.Material.Metal) or Enum.Material.Metal,
				Color = type(profile) == "table" and (profile.canopyColor or Color3.fromRGB(46, 50, 58)) or Color3.fromRGB(46, 50, 58),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
	)

	for index, side in ipairs({ -1, 1 }) do
		local tripod = ensurePart(folder, "PreparationFloodlightTripod_" .. tostring(index))
		local tripodPos = platformCenter + (right * side * ((platformWidth * 0.5) + 2.6)) + (outward * -1.8) + Vector3.new(0, 1.9, 0)
		configurePart(
			tripod,
			{
				Size = Vector3.new(0.34, 3.8, 0.34),
				CFrame = CFrame.new(tripodPos),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(82, 88, 98),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)

		local lightBar = ensurePart(folder, "PreparationFloodlightBar_" .. tostring(index))
		configurePart(
			lightBar,
			{
				Size = Vector3.new(2.8, 0.28, 0.28),
				CFrame = CFrame.lookAt(tripodPos + Vector3.new(0, 1.88, 0), tripodPos - outward, Vector3.yAxis),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(90, 96, 106),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)

		local flood = ensurePart(folder, "PreparationFloodlight_" .. tostring(index))
		configurePart(
			flood,
			{
				Size = Vector3.new(1.8, 0.34, 0.72),
				CFrame = CFrame.lookAt(tripodPos + Vector3.new(0, 1.88, 0), tripodPos - outward, Vector3.yAxis),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(214, 228, 255),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)

		local spot = flood:FindFirstChild("Light")
		if not (spot and spot:IsA("SpotLight")) then
			if spot then
				spot:Destroy()
			end
			spot = Instance.new("SpotLight")
			spot.Name = "Light"
			spot.Parent = flood
		end
		spot.Angle = 82
		spot.Brightness = 3.2
		spot.Color = Color3.fromRGB(214, 228, 255)
		spot.Range = 40
		spot.Face = Enum.NormalId.Front
		spot.Shadows = false
	end

	for index, side in ipairs({ -1, 1 }) do
		local post = ensurePart(folder, "PreparationPost_" .. tostring(index))
		local postPosition = platformCenter + (right * side * ((platformWidth * 0.5) - 1.8)) + (outward * -3.2) + Vector3.new(0, 2.9, 0)
		configurePart(
			post,
			{
				Size = Vector3.new(0.42, 5.8, 0.42),
				CFrame = CFrame.new(postPosition),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(74, 78, 86),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)

		local lamp = ensurePart(folder, "PreparationLamp_" .. tostring(index))
		configurePart(
			lamp,
			{
				Size = Vector3.new(0.9, 0.22, 0.9),
				CFrame = CFrame.new(postPosition + Vector3.new(0, 2.56, 0)),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 214, 170),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
			}
		)

		local light = lamp:FindFirstChild("Light")
		if not (light and light:IsA("PointLight")) then
			if light then
				light:Destroy()
			end
			light = Instance.new("PointLight")
			light.Name = "Light"
			light.Parent = lamp
		end
		light.Range = 20
		light.Brightness = 1.8
		light.Color = Color3.fromRGB(255, 214, 170)
		light.Shadows = false
	end

	local contractBoard = ensurePart(folder, "PreparationContractBoard")
	configurePart(
		contractBoard,
			{
				Size = Vector3.new(5.2, 4.6, 0.32),
				CFrame = CFrame.lookAt(platformCenter + (outward * -1.6) + Vector3.new(0, 3.2, 0), platformCenter + outward, Vector3.yAxis),
				Material = type(profile) == "table" and (profile.boardMaterial or Enum.Material.Metal) or Enum.Material.Metal,
				Color = type(profile) == "table" and (profile.boardColor or Color3.fromRGB(34, 40, 52)) or Color3.fromRGB(34, 40, 52),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
	)
	ensureBoardSurface(
		contractBoard,
		"FrontSurface",
		Enum.NormalId.Front,
		boardData.contractTitle,
		boardData.contractSubtitle,
		boardData.contractLines,
		Color3.fromRGB(214, 160, 104)
	)

	local contractDesk = ensurePart(folder, "PreparationContractDesk")
	configurePart(
		contractDesk,
			{
				Size = Vector3.new(6.4, 1.2, 2.2),
				CFrame = CFrame.lookAt(platformCenter + (outward * 1.2) + Vector3.new(0, 0.64, 0), platformCenter - outward, Vector3.yAxis),
				Material = type(profile) == "table" and (profile.deskMaterial or Enum.Material.WoodPlanks) or Enum.Material.WoodPlanks,
				Color = type(profile) == "table" and (profile.deskColor or Color3.fromRGB(82, 62, 48)) or Color3.fromRGB(82, 62, 48),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
	)
	ensureBoardSurface(
		contractBoard,
		"BackSurface",
		Enum.NormalId.Back,
		boardData.contractTitle,
		boardData.contractSubtitle,
		boardData.contractLines,
		Color3.fromRGB(214, 160, 104)
	)

	local objectiveBoard = ensurePart(folder, "PreparationObjectiveBoard")
	configurePart(
		objectiveBoard,
			{
				Size = Vector3.new(5.8, 4.8, 0.32),
				CFrame = CFrame.lookAt(platformCenter + (right * -8.2) + (outward * -0.4) + Vector3.new(0, 3.3, 0), platformCenter + outward, Vector3.yAxis),
				Material = type(profile) == "table" and (profile.boardMaterial or Enum.Material.Metal) or Enum.Material.Metal,
				Color = type(profile) == "table" and (profile.boardColor or Color3.fromRGB(26, 34, 48)) or Color3.fromRGB(26, 34, 48),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
	)
	updatePreparationObjectiveBoard(objectiveBoard, boardData, nil, false)

	local toolsBoard = ensurePart(folder, "PreparationToolsBoard")
	configurePart(
		toolsBoard,
			{
				Size = Vector3.new(5.8, 4.8, 0.32),
				CFrame = CFrame.lookAt(platformCenter + (right * 8.2) + (outward * -0.4) + Vector3.new(0, 3.3, 0), platformCenter + outward, Vector3.yAxis),
				Material = type(profile) == "table" and (profile.boardMaterial or Enum.Material.Metal) or Enum.Material.Metal,
				Color = type(profile) == "table" and (profile.boardColor or Color3.fromRGB(26, 34, 48)) or Color3.fromRGB(26, 34, 48),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
	)
	updatePreparationToolsBoard(toolsBoard, nil)

	local rackBase = ensurePart(folder, "PreparationToolRack")
	configurePart(
		rackBase,
			{
				Size = Vector3.new(12.8, 1.1, 1.8),
				CFrame = CFrame.lookAt(platformCenter + (right * 8.2) + (outward * 4.2) + Vector3.new(0, 0.6, 0), platformCenter + outward, Vector3.yAxis),
				Material = type(profile) == "table" and (profile.rackMaterial or Enum.Material.SmoothPlastic) or Enum.Material.SmoothPlastic,
				Color = type(profile) == "table" and (profile.rackColor or Color3.fromRGB(58, 66, 82)) or Color3.fromRGB(58, 66, 82),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
	)

	local equipmentCases = {}
	for index, side in ipairs({ -1, 1, 0 }) do
		local case = ensurePart(folder, "PreparationEquipmentCase_" .. tostring(index))
		local offsetX = side == 0 and 0 or side * 6.2
		local offsetZ = side == 0 and -4.2 or 1.8
		configurePart(
			case,
			{
				Size = side == 0 and Vector3.new(2.8, 1.1, 1.8) or Vector3.new(2.2, 1.0, 1.6),
				CFrame = CFrame.lookAt(
					platformCenter + (right * offsetX) + (outward * offsetZ) + Vector3.new(0, 0.56, 0),
					platformCenter - outward,
					Vector3.yAxis
				),
				Material = type(profile) == "table" and (profile.rackMaterial or Enum.Material.Metal) or Enum.Material.Metal,
				Color = type(profile) == "table" and (profile.caseColor or (side == 0 and Color3.fromRGB(58, 64, 76) or Color3.fromRGB(74, 78, 86))) or (side == 0 and Color3.fromRGB(58, 64, 76) or Color3.fromRGB(74, 78, 86)),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
		equipmentCases[side] = case
	end
	if equipmentCases[-1] then
		syncRuntimeAssetModel(
			folder,
			"PreparationSupportTool_Garam",
			"Tools",
			"Garam",
			equipmentCases[-1].CFrame * CFrame.new(0, equipmentCases[-1].Size.Y * 0.5 + 0.12, 0.08) * CFrame.Angles(0, math.rad(18), 0),
			{
				scale = 0.98,
				castShadow = false,
			}
		)
	end
	if equipmentCases[1] then
		syncRuntimeAssetModel(
			folder,
			"PreparationSupportTool_Dupa",
			"Tools",
			"Dupa",
			equipmentCases[1].CFrame * CFrame.new(0, equipmentCases[1].Size.Y * 0.5 + 0.1, -0.06) * CFrame.Angles(0, math.rad(-24), math.rad(8)),
			{
				scale = 1.0,
				castShadow = false,
			}
		)
	end
	if equipmentCases[0] then
		syncRuntimeAssetModel(
			folder,
			"PreparationSupportTool_Salib",
			"Tools",
			"Salib",
			equipmentCases[0].CFrame * CFrame.new(0, equipmentCases[0].Size.Y * 0.5 + 1.02, 0.04) * CFrame.Angles(0, math.rad(180), 0),
			{
				scale = 0.82,
				castShadow = false,
			}
		)
	end

		buildPreparationStageDecor(folder, profile, platformCenter, runnerCenter, right, outward)
		setPreparationDebug("decor_ready")

	local entrySign = ensurePart(folder, "PreparationEntrySign")
	configurePart(
		entrySign,
		{
			Size = Vector3.new(4.6, 2.2, 0.24),
			CFrame = CFrame.lookAt(runnerCenter + (outward * -0.8) + Vector3.new(0, 2.6, 0), runnerCenter - outward, Vector3.yAxis),
			Material = type(profile) == "table" and (profile.boardMaterial or Enum.Material.Metal) or Enum.Material.Metal,
			Color = type(profile) == "table" and (profile.boardColor or Color3.fromRGB(28, 34, 44)) or Color3.fromRGB(28, 34, 44),
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)
	updatePreparationEntrySign(entrySign, nil, false, profile)

	local entryBeacon = ensurePart(folder, "PreparationEntryBeacon")
	configurePart(
		entryBeacon,
		{
			Size = Vector3.new(0.48, 0.48, 0.48),
			CFrame = CFrame.new(entrySign.Position + Vector3.new(0, 1.9, 0)),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(214, 160, 104),
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)
	updatePreparationEntryBeacon(entryBeacon, nil, false, profile)
	updatePreparationEntryLane(folder, nil, false, profile)

	local breachPrompt
	local studioManifestPrompt
	local toolStations = {}
	local function resolvePreparationSelectedTool()
		if type(matchContext) ~= "table" then
			return nil
		end

		for _, participant in ipairs(matchContext.players or {}) do
			if typeof(participant) == "Instance" and participant:IsA("Player") then
				local focusTool = participant:GetAttribute("PreparationFocusTool")
				if type(focusTool) == "string" and focusTool ~= "" then
					return focusTool
				end
			end
		end

		return nil
	end

	local function resolvePreparationBreachOpen()
		if type(matchContext) == "table" then
			local phaseToken = tostring(matchContext.phase or "")
			if phaseToken ~= "" and phaseToken ~= "PreparationPhase" then
				return true
			end
		end

		if type(matchContext) == "table" then
			for _, participant in ipairs(matchContext.players or {}) do
				if typeof(participant) == "Instance" and participant:IsA("Player") then
					local lifecyclePhase = tostring(participant:GetAttribute("MatchLifecyclePhase") or "")
					if lifecyclePhase ~= "" and lifecyclePhase ~= "PreparationPhase" then
						return true
					end
				end
			end
		end

		return false
	end

	local function syncPreparationEntryState()
		local selectedTool = resolvePreparationSelectedTool()
		local breachOpen = resolvePreparationBreachOpen()
		updatePreparationToolsBoard(toolsBoard, selectedTool)
		for _, station in ipairs(toolStations) do
			updatePreparationToolStationState(station.part, station.prompt, station.tool, selectedTool, breachOpen, station.pad)
		end
		updatePreparationObjectiveBoard(objectiveBoard, boardData, selectedTool, breachOpen)
		updatePreparationEntrySign(entrySign, selectedTool, breachOpen, profile)
		updatePreparationEntryBeacon(entryBeacon, selectedTool, breachOpen, profile)
		updatePreparationEntryLane(folder, selectedTool, breachOpen, profile)
		if breachOpen and folder:GetAttribute(PREPARATION_BREACH_MOVED_ATTR) ~= true then
			movePlayersToPreparationBreachTargets(folder, matchContext, outward)
		end
		if breachOpen and breachPrompt and breachPrompt.Parent then
			breachPrompt:Destroy()
		end
		if studioManifestPrompt then
			studioManifestPrompt.Enabled = breachOpen == true
		end
	end

	breachPrompt = ensurePrompt(entrySign, "BreachPrompt", "Mulai Breach", "Main Entry")
	if breachPrompt and breachPrompt:GetAttribute("PreparationConnected") ~= true then
		breachPrompt:SetAttribute("PreparationConnected", true)
		breachPrompt.Triggered:Connect(function(player)
			if typeof(player) ~= "Instance" or not player:IsA("Player") then
				return
			end
			if type(matchContext) == "table" and type(matchContext.requestAdvancePhase) == "function" then
				local payload = matchContext.requestAdvancePhase(player, "InvestigationPhase")
				if payload ~= nil then
					syncPreparationEntryState()
				end
			end
		end)
	end
	if (token == "hauntedhouse" or token == "studiommnineteen" or token == "emptybuilding" or token == "abandonedpalace") and breachPrompt then
		breachPrompt.Enabled = false
	end

	if RunService:IsStudio() then
		studioManifestPrompt = ensurePrompt(entrySign, "StudioManifestPrompt", "Paksa Manifest", "Studio Ghost Probe")
		if studioManifestPrompt then
			studioManifestPrompt.MaxActivationDistance = 14
			studioManifestPrompt.Enabled = false
			if studioManifestPrompt:GetAttribute("PreparationConnected") ~= true then
				studioManifestPrompt:SetAttribute("PreparationConnected", true)
				studioManifestPrompt.Triggered:Connect(function(player)
					if typeof(player) ~= "Instance" or not player:IsA("Player") then
						return
					end
					if type(matchContext) == "table" and type(matchContext.requestForceManifest) == "function" then
						local payload = matchContext.requestForceManifest(player)
						if payload ~= nil then
							syncPreparationEntryState()
						end
					end
				end)
			end
		end
	end

	local rackCenter = rackBase.Position + Vector3.new(0, 1.02, 0)
	for index, tool in ipairs(PREPARATION_TOOL_STATIONS) do
		local offset = (index - ((#PREPARATION_TOOL_STATIONS + 1) * 0.5)) * 2.18
		local toolPart = ensurePart(folder, tool.name)
		local toolPosition = rackCenter + (right * offset)
		configurePart(
			toolPart,
			{
				Size = Vector3.new(1.2, 1.0, 1.2),
				CFrame = CFrame.lookAt(toolPosition, toolPosition + outward, Vector3.yAxis),
				Material = Enum.Material.SmoothPlastic,
				Color = tool.color,
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
		local statePad = ensurePart(folder, tool.name .. "_Pad")
		configurePart(
			statePad,
			{
				Size = Vector3.new(1.6, 0.06, 1.6),
				CFrame = CFrame.lookAt(toolPosition + Vector3.new(0, -0.48, 0), toolPosition + outward, Vector3.yAxis),
				Material = Enum.Material.Neon,
				Color = tool.color:Lerp(Color3.fromRGB(28, 34, 44), 0.62),
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
				Transparency = 0.3,
			}
		)

		ensureBoardSurface(
			toolPart,
			"FrontSurface",
			Enum.NormalId.Front,
			tool.title,
			tool.subtitle,
			"",
			tool.color
		)
		ensureBoardSurface(
			toolPart,
			"BackSurface",
			Enum.NormalId.Back,
			tool.title,
			tool.subtitle,
			"",
			tool.color
		)

		local prompt = ensurePrompt(toolPart, "Prompt", "Pilih Fokus Tool", tool.title)
		if prompt and prompt:GetAttribute("PreparationConnected") ~= true then
			prompt:SetAttribute("PreparationConnected", true)
			prompt.Triggered:Connect(function(player)
				if typeof(player) == "Instance" and player:IsA("Player") then
					player:SetAttribute("PreparationFocusTool", tool.title)
					syncPreparationEntryState()
				end
			end)
		end
		table.insert(toolStations, {
			part = toolPart,
			prompt = prompt,
			tool = tool,
			pad = statePad,
		})
	end

	if type(matchContext) == "table" then
		for _, participant in ipairs(matchContext.players or {}) do
			if typeof(participant) == "Instance" and participant:IsA("Player") then
				participant:GetAttributeChangedSignal("MatchLifecyclePhase"):Connect(syncPreparationEntryState)
				participant:GetAttributeChangedSignal("PreparationFocusTool"):Connect(syncPreparationEntryState)
			end
		end
	end
		syncPreparationEntryState()

		local spawnOffsets = { -5.4, -1.8, 1.8, 5.4 }
		local breachOffsets = { -4.2, -1.4, 1.4, 4.2 }
		local spawnY = anchorDoor.Position.Y + 0.5
		for index = 1, 4 do
			local spawnPart = ensurePart(spawnFolder, "PlayerSpawn_" .. tostring(index))
			local spawnPosition = Vector3.new(
				platformCenter.X,
				spawnY,
				platformCenter.Z
			) + (outward * 5.8) + (right * spawnOffsets[index])
			configurePart(
				spawnPart,
				{
					Size = Vector3.new(1, 1, 1),
					CFrame = CFrame.lookAt(spawnPosition, spawnPosition - outward, Vector3.yAxis),
					Transparency = 1,
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
					Color = Color3.fromRGB(255, 255, 255),
				}
			)

			local breachTarget = ensurePart(folder, "PreparationBreachTarget_" .. tostring(index))
			local breachPosition = Vector3.new(
				anchorDoor.Position.X,
				spawnY,
				anchorDoor.Position.Z
			) - (outward * 4.8) + (right * breachOffsets[index])
			configurePart(
				breachTarget,
				{
					Size = Vector3.new(1, 1, 1),
					CFrame = CFrame.lookAt(breachPosition, breachPosition - outward, Vector3.yAxis),
					Transparency = 1,
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
					Color = Color3.fromRGB(255, 255, 255),
				}
			)
		end

		mapClone:SetAttribute(PREPARATION_STAGING_PATCH_ATTR, true)
		setPreparationDebug("complete")
		if type(matchContext) == "table" then
			matchContext.preparationWorldBoard = true
		end
		return true
	end, debug.traceback)

	if not ok then
		setPreparationDebug("error|" .. tostring(result))
		return false
	end
	return result == true
end

local function patchMapMaterials(mapId, mapClone)
	if not mapClone or mapClone:GetAttribute(MATERIAL_PATCH_ATTR) == true then
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
			if string.find(nameToken, "floor", 1, true) then
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
	end
	return patchedAny
end

local function collectMapBounds(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return nil
	end

	local minV
	local maxV
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Parent ~= nil then
			local half = descendant.Size * 0.5
			local mn = descendant.Position - half
			local mx = descendant.Position + half
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

local function patchRuntimeBoundary(mapClone)
	if not mapClone or mapClone:GetAttribute(BOUNDARY_PATCH_ATTR) == true then
		return false
	end

	local bounds = collectMapBounds(mapClone)
	if not bounds then
		return false
	end

	local minV = bounds.min
	local maxV = bounds.max
	local margin = 26
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

local function patchHauntedHouseScaffold(mapId, mapClone)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token ~= "hauntedhouse" or mapClone == nil then
		return false
	end
	return HauntedHouseMapScaffold.Build(mapClone) == true
end

local function patchStudioMMNineteenScaffold(mapId, mapClone)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token ~= "studiommnineteen" or mapClone == nil then
		return false
	end
	return StudioMMNineteenMapScaffold.Build(mapClone) == true
end

local function patchAbandonedPalaceScaffold(mapId, mapClone)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token ~= "abandonedpalace" or mapClone == nil then
		return false
	end
	return AbandonedPalaceMapScaffold.Build(mapClone) == true
end

local function patchEmptyBuildingScaffold(mapId, mapClone)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token ~= "emptybuilding" or mapClone == nil then
		return false
	end
	return EmptyBuildingMapScaffold.Build(mapClone) == true
end

function MapRuntimePatches.Apply(mapId, mapClone, matchContext)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token == nil or mapClone == nil then
		return false
	end

	local didPatch = false
	didPatch = patchHauntedHouseScaffold(mapId, mapClone) or didPatch
	didPatch = patchStudioMMNineteenScaffold(mapId, mapClone) or didPatch
	didPatch = patchAbandonedPalaceScaffold(mapId, mapClone) or didPatch
	didPatch = patchEmptyBuildingScaffold(mapId, mapClone) or didPatch
	didPatch = patchSecondFloor(mapClone) or didPatch
	didPatch = patchLogicVolumes(mapClone) or didPatch
	didPatch = patchMapMaterials(mapId, mapClone) or didPatch
	didPatch = patchDoorTraversal(mapClone) or didPatch
	didPatch = patchInteractionPoints(mapId, mapClone) or didPatch
	didPatch = patchSafeZones(mapId, mapClone) or didPatch
	didPatch = patchSpawnPoints(mapId, mapClone) or didPatch
	didPatch = patchPreparationStaging(mapId, mapClone, matchContext) or didPatch
	didPatch = patchRuntimeBoundary(mapClone) or didPatch
	didPatch = patchTraversalGuides(mapClone) or didPatch
	return didPatch
end

return MapRuntimePatches
