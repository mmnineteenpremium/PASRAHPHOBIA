local MapRuntimePatches = {}

local FLOOR_PATCH_ATTR = "SecondFloorRuntimePatched"
local INTERACTION_PATCH_ATTR = "InteractionPointsRuntimePatched"
local DOOR_PATCH_ATTR = "DoorTraversalRuntimePatched"
local SAFE_ZONE_PATCH_ATTR = "SafeZoneRuntimePatched"
local MATERIAL_PATCH_ATTR = "MapMaterialRuntimePatched"
local TRAVERSAL_GUIDE_PATCH_ATTR = "TraversalGuideRuntimePatched"
local LOGIC_VOLUME_PATCH_ATTR = "LogicVolumesRuntimeHidden"
local PREPARATION_STAGING_PATCH_ATTR = "PreparationStagingRuntimePatched"
local PREPARATION_STAGING_FOLDER_NAME = "PreparationStagingRuntime"
local DOOR_MODE_ATTR = "DoorTraversalMode"
local DOOR_POLICY_ATTR = "DoorTraversalPolicy"
local DOOR_OPEN_SOUND_ATTR = "DoorOpenSoundId"
local DOOR_CLOSE_SOUND_ATTR = "DoorCloseSoundId"
local DEFAULT_DOOR_POLICY = "HybridRadiusPrompt"
local DEFAULT_DOOR_OPEN_SOUND_ID = "rbxassetid://139204195403262"
local DEFAULT_DOOR_CLOSE_SOUND_ID = "rbxassetid://83336813491039"
local MIN_SEGMENT_SIZE = 0.25
local STAIR_MARGIN = 0.75
local INTERACTION_HEIGHT_OFFSET = 1.5
local TRAVERSAL_GUIDE_FOLDER_NAME = "TraversalGuideRuntime"
local TRAVERSAL_GUIDE_HIGHLIGHT_NAME = "Highlight"
local TRAVERSAL_GUIDE_BILLBOARD_NAME = "Billboard"
local INTERACTION_GUIDE_FOLDER_NAME = "InteractionGuideRuntime"
local INTERACTION_GUIDE_BILLBOARD_NAME = "Billboard"
local PLAYER_FACING_GUIDE_VISUALS_ENABLED = false
local LOGIC_VOLUME_VISUAL_TRANSPARENCY = 1
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
		SafeZone_1 = {
			roomName = "Room_LivingRoom",
			offset = Vector3.new(9.5, 3.5, -9),
		},
		SafeZone_2 = {
			roomName = "Room_LivingRoom",
			offset = Vector3.new(-6, 3.5, 7),
		},
	},
	abandonedpalace = {
		SafeZone_1 = Vector3.new(-63.2, 4, 32.4),
	},
	emptybuilding = {
		SafeZone_1 = Vector3.new(778, 4, -10),
		SafeZone_2 = Vector3.new(824, 4, -20),
	},
	studiommnineteen = {
		SafeZone_1 = Vector3.new(369.4, 4, 18.2),
	},
}

local SPAWN_POINT_OVERRIDES = {
	hauntedhouse = {
		PlayerSpawn_1 = {
			position = Vector3.new(1178, 4, 4),
		},
		PlayerSpawn_2 = {
			position = Vector3.new(1174, 4, 8),
		},
		PlayerSpawn_3 = {
			position = Vector3.new(1166, 4, -4),
		},
		PlayerSpawn_4 = {
			position = Vector3.new(1166, 4, -8),
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
		anchorRoomName = "Room_LivingRoom",
		anchorDoorName = "Door_LivingRoom",
		platformWidth = 28,
		platformDepth = 18,
		stagingDistance = 18,
	},
	abandonedpalace = {
		anchorRoomName = "Room_GrandHall",
		anchorDoorName = "Door_GrandHall",
		platformWidth = 30,
		platformDepth = 18,
		stagingDistance = 20,
	},
	emptybuilding = {
		anchorRoomName = "Room_Lobby",
		anchorDoorName = "Door_Lobby",
		platformWidth = 26,
		platformDepth = 16,
		stagingDistance = 16,
	},
	studiommnineteen = {
		anchorRoomName = "Room_ControlRoom",
		anchorDoorName = "Door_ControlRoom",
		platformWidth = 26,
		platformDepth = 16,
		stagingDistance = 16,
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

local function updatePreparationEntryBeacon(beaconPart, selectedTool, breachOpen)
	if not (typeof(beaconPart) == "Instance" and beaconPart:IsA("BasePart")) then
		return
	end

	local color = Color3.fromRGB(214, 160, 104)
	if type(selectedTool) == "string" and selectedTool ~= "" then
		color = Color3.fromRGB(132, 186, 255)
	end
	if breachOpen then
		color = Color3.fromRGB(142, 214, 198)
	end

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

local function updatePreparationEntryLane(folder, selectedTool, breachOpen)
	if typeof(folder) ~= "Instance" then
		return
	end

	local accent = Color3.fromRGB(214, 160, 104)
	local runnerColor = Color3.fromRGB(98, 84, 70)
	local floodColor = Color3.fromRGB(214, 228, 255)
	local floodBrightness = 3.2
	local lampColor = Color3.fromRGB(255, 214, 170)
	local lampBrightness = 1.8

	if type(selectedTool) == "string" and selectedTool ~= "" then
		accent = Color3.fromRGB(132, 186, 255)
		runnerColor = Color3.fromRGB(72, 104, 146)
		floodColor = Color3.fromRGB(178, 214, 255)
		floodBrightness = 3.8
		lampColor = Color3.fromRGB(184, 214, 255)
		lampBrightness = 2.1
	end

	if breachOpen then
		accent = Color3.fromRGB(142, 214, 198)
		runnerColor = Color3.fromRGB(72, 138, 122)
		floodColor = Color3.fromRGB(174, 255, 236)
		floodBrightness = 4.3
		lampColor = Color3.fromRGB(190, 255, 236)
		lampBrightness = 2.45
	end

	local runner = folder:FindFirstChild("PreparationRunner")
	if runner and runner:IsA("BasePart") then
		runner.Color = runnerColor
	end

	for index = 1, 2 do
		local flood = folder:FindFirstChild("PreparationFloodlight_" .. tostring(index))
		if flood and flood:IsA("BasePart") then
			flood.Color = floodColor
			local spot = flood:FindFirstChild("Light")
			if spot and spot:IsA("SpotLight") then
				spot.Color = floodColor
				spot.Brightness = floodBrightness
			end
		end

		local lamp = folder:FindFirstChild("PreparationLamp_" .. tostring(index))
		if lamp and lamp:IsA("BasePart") then
			lamp.Color = lampColor
			local light = lamp:FindFirstChild("Light")
			if light and light:IsA("PointLight") then
				light.Color = lampColor
				light.Brightness = lampBrightness
			end
		end
	end

	local entryAccent = folder:FindFirstChild("PreparationEntryAccent")
	if entryAccent and entryAccent:IsA("BasePart") then
		entryAccent.Color = accent
	end
end

local function updatePreparationEntrySign(entrySign, selectedTool, breachOpen)
	if typeof(entrySign) ~= "Instance" then
		return
	end

	local title = "MAIN ENTRY"
	local subtitle = "Breach setelah review board"
	local body = "Ikuti runner ke pintu utama."
	local accent = Color3.fromRGB(214, 160, 104)

	if type(selectedTool) == "string" and selectedTool ~= "" then
		subtitle = string.format("%s ready • breach armed", selectedTool)
		body = string.format("Aktifkan breach untuk sweep awal dengan %s.", selectedTool)
		accent = Color3.fromRGB(132, 186, 255)
	end

	if breachOpen then
		title = "BREACH OPEN"
		subtitle = "Investigation live"
		body = "Masuk ke area utama sekarang."
		accent = Color3.fromRGB(142, 214, 198)
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
			descendant:SetAttribute(DOOR_POLICY_ATTR, DEFAULT_DOOR_POLICY)
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

	local token = resolveMapOverrideToken(mapId, mapClone)
	if token and PREPARATION_STAGING_PROFILES[token] == nil then
		token = resolveMapOverrideToken(nil, mapClone)
	end
	local profile = token and PREPARATION_STAGING_PROFILES[token] or nil
	if not profile then
		return false
	end

	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	local spawnFolder = mapClone:FindFirstChild("SpawnPoints", true)
	if not (roomsFolder and doorsFolder and spawnFolder) then
		return false
	end

	local anchorRoom = roomsFolder:FindFirstChild(profile.anchorRoomName)
	local anchorDoor = doorsFolder:FindFirstChild(profile.anchorDoorName)
	if not (anchorRoom and anchorRoom:IsA("BasePart") and anchorDoor and anchorDoor:IsA("BasePart")) then
		return false
	end

	local outward = flattenDirection(anchorDoor.Position - anchorRoom.Position)
	if not outward then
		return false
	end
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
		return false
	end

	local platformCFrame = CFrame.lookAt(platformCenter, platformCenter - outward, Vector3.yAxis)
	configurePart(
		ensurePart(folder, "PreparationPlatform"),
		{
			Size = Vector3.new(platformWidth, 0.32, platformDepth),
			CFrame = platformCFrame,
			Material = Enum.Material.Concrete,
			Color = Color3.fromRGB(64, 66, 74),
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
			Material = Enum.Material.Slate,
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
			Material = Enum.Material.Asphalt,
			Color = Color3.fromRGB(52, 56, 64),
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
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(98, 104, 114),
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
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(98, 104, 114),
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
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(46, 50, 58),
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
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(34, 40, 52),
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
			Material = Enum.Material.WoodPlanks,
			Color = Color3.fromRGB(82, 62, 48),
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
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(26, 34, 48),
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
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(26, 34, 48),
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
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(58, 66, 82),
			CanCollide = true,
			CanTouch = false,
			CanQuery = true,
		}
	)

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
				Material = Enum.Material.Metal,
				Color = side == 0 and Color3.fromRGB(58, 64, 76) or Color3.fromRGB(74, 78, 86),
				CanCollide = true,
				CanTouch = false,
				CanQuery = true,
			}
		)
	end

	local entrySign = ensurePart(folder, "PreparationEntrySign")
	configurePart(
		entrySign,
		{
			Size = Vector3.new(4.6, 2.2, 0.24),
			CFrame = CFrame.lookAt(runnerCenter + (outward * -0.8) + Vector3.new(0, 2.6, 0), runnerCenter - outward, Vector3.yAxis),
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(28, 34, 44),
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	)
	updatePreparationEntrySign(entrySign, nil, false)

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
	updatePreparationEntryBeacon(entryBeacon, nil, false)
	updatePreparationEntryLane(folder, nil, false)

	local breachPrompt
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
		updatePreparationObjectiveBoard(objectiveBoard, boardData, selectedTool, breachOpen)
		updatePreparationEntrySign(entrySign, selectedTool, breachOpen)
		updatePreparationEntryBeacon(entryBeacon, selectedTool, breachOpen)
		updatePreparationEntryLane(folder, selectedTool, breachOpen)
		if breachOpen and breachPrompt and breachPrompt.Parent then
			breachPrompt:Destroy()
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
					updatePreparationToolsBoard(toolsBoard, tool.title)
					syncPreparationEntryState()
				end
			end)
		end
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
	end

	mapClone:SetAttribute(PREPARATION_STAGING_PATCH_ATTR, true)
	if type(matchContext) == "table" then
		matchContext.preparationWorldBoard = true
	end
	return true
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

function MapRuntimePatches.Apply(mapId, mapClone, matchContext)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token == nil or mapClone == nil then
		return false
	end

	local didPatch = false
	didPatch = patchSecondFloor(mapClone) or didPatch
	didPatch = patchLogicVolumes(mapClone) or didPatch
	didPatch = patchMapMaterials(mapId, mapClone) or didPatch
	didPatch = patchDoorTraversal(mapClone) or didPatch
	didPatch = patchInteractionPoints(mapId, mapClone) or didPatch
	didPatch = patchSafeZones(mapId, mapClone) or didPatch
	didPatch = patchSpawnPoints(mapId, mapClone) or didPatch
	didPatch = patchPreparationStaging(mapId, mapClone, matchContext) or didPatch
	didPatch = patchTraversalGuides(mapClone) or didPatch
	return didPatch
end

return MapRuntimePatches
