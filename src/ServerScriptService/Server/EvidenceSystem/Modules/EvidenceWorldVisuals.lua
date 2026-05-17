local Workspace = game:GetService("Workspace")

local EvidenceWorldVisuals = {}
EvidenceWorldVisuals.__index = EvidenceWorldVisuals

local FOLDER_NAME = "EvidenceVisuals"
local VISUAL_ATTRIBUTE = "PasrahEvidenceVisual"

local EVIDENCE_CONFIG = {
	MEDOK = {
		color = Color3.fromRGB(92, 222, 255),
		title = "EMF 5",
		subtitle = "MEDOK spike",
	},
	Suhu = {
		color = Color3.fromRGB(128, 214, 255),
		title = "COLD SPOT",
		subtitle = "freezing trace",
	},
	BukuTerkutuk = {
		color = Color3.fromRGB(176, 94, 214),
		title = "WRITING",
		subtitle = "cursed book mark",
	},
	["To'un"] = {
		color = Color3.fromRGB(142, 236, 255),
		title = "UV MARK",
		subtitle = "handprint anomaly",
	},
	Suara = {
		color = Color3.fromRGB(184, 148, 255),
		title = "VOICE",
		subtitle = "spirit response",
	},
	Pengganggu = {
		color = Color3.fromRGB(146, 255, 188),
		title = "MOTION",
		subtitle = "disturbance trace",
	},
}

local function sanitizeName(value)
	local token = tostring(value or "Unknown"):gsub("[^%w_]+", "_")
	if token == "" then
		return "Unknown"
	end
	return token
end

local function ensureActiveMatchesFolder()
	local folder = Workspace:FindFirstChild("ActiveMatches")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ActiveMatches"
		folder.Parent = Workspace
	end
	return folder
end

local function resolveMatchFolder(matchId, createIfMissing)
	local activeMatches = createIfMissing ~= false and ensureActiveMatchesFolder() or Workspace:FindFirstChild("ActiveMatches")
	if not activeMatches then
		return nil
	end
	local name = "Match_" .. tostring(matchId)
	local folder = activeMatches:FindFirstChild(name)
	if not folder and createIfMissing ~= false then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = activeMatches
	end
	return folder
end

local function resolveMapModel(matchFolder)
	if typeof(matchFolder) ~= "Instance" then
		return nil
	end
	for _, child in ipairs(matchFolder:GetChildren()) do
		if (child:IsA("Model") or child:IsA("Folder"))
			and child.Name ~= FOLDER_NAME
			and child.Name ~= "InvestigationTools"
			and not child.Name:match("^Ghost_")
			and not child.Name:match("^GhostPlaceholder_") then
			return child
		end
	end
	return nil
end

local function partRoomMatches(part, roomId)
	if not (part and part:IsA("BasePart")) then
		return false
	end
	local wanted = tostring(roomId or "")
	if wanted == "" then
		return true
	end
	if part.Name == wanted then
		return true
	end
	for _, attributeName in ipairs({ "RoomId", "PasrahRoomId", "SafeZoneRoomLabel", "RoomName" }) do
		if tostring(part:GetAttribute(attributeName) or "") == wanted then
			return true
		end
	end
	return false
end

local function findRoomAnchor(mapModel, roomId)
	if typeof(mapModel) ~= "Instance" then
		return nil
	end
	for _, folderName in ipairs({ "EvidenceSpawnNodes", "EvidenceSpawns", "Rooms", "InteractionPoints" }) do
		local folder = mapModel:FindFirstChild(folderName, true)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("BasePart") and partRoomMatches(child, roomId) then
					return child.CFrame
				end
			end
		end
	end
	return nil
end

local function resolvePlayerCFrame(player)
	if not (typeof(player) == "Instance" and player:IsA("Player")) then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.CFrame * CFrame.new(0, 0, -3)
	end
	return nil
end

local function raycastToFloor(baseCFrame, matchFolder)
	if typeof(baseCFrame) ~= "CFrame" then
		return nil
	end
	local origin = baseCFrame.Position + Vector3.new(0, 8, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = typeof(matchFolder) == "Instance" and { matchFolder } or {}
	params.IgnoreWater = true
	local result = Workspace:Raycast(origin, Vector3.new(0, -32, 0), params)
	if result then
		local look = baseCFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude <= 0.01 then
			flatLook = Vector3.new(0, 0, -1)
		end
		return CFrame.lookAt(result.Position + Vector3.new(0, 0.06, 0), result.Position + flatLook.Unit)
	end
	return baseCFrame
end

local function resolveAnchorCFrame(matchFolder, mapModel, player, requestPayload)
	local requestedPosition = type(requestPayload) == "table" and requestPayload.playerPosition or nil
	if typeof(requestedPosition) == "Vector3" then
		return raycastToFloor(CFrame.new(requestedPosition), matchFolder)
	end

	local playerCFrame = resolvePlayerCFrame(player)
	if playerCFrame then
		return raycastToFloor(playerCFrame, matchFolder)
	end

	local roomId = type(requestPayload) == "table" and (requestPayload.roomId or requestPayload.location or requestPayload.room) or nil
	local roomCFrame = findRoomAnchor(mapModel, roomId)
	if roomCFrame then
		return raycastToFloor(roomCFrame, matchFolder)
	end

	if typeof(mapModel) == "Instance" then
		local ok, pivot = pcall(function()
			return mapModel:GetPivot()
		end)
		if ok and typeof(pivot) == "CFrame" then
			return raycastToFloor(pivot, matchFolder)
		end
	end
	return CFrame.new(0, 4, 0)
end

local function ensureContainer(matchId)
	local matchFolder = resolveMatchFolder(matchId, true)
	if not matchFolder then
		return nil, nil, nil
	end
	local folder = matchFolder:FindFirstChild(FOLDER_NAME)
	if folder and not folder:IsA("Folder") then
		folder:Destroy()
		folder = nil
	end
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = matchFolder
	end
	return folder, matchFolder, resolveMapModel(matchFolder)
end

local function stampPart(part, evidenceType)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = false
	part.Massless = true
	part:SetAttribute(VISUAL_ATTRIBUTE, true)
	part:SetAttribute("PasrahEvidenceType", tostring(evidenceType or ""))
end

local function createPart(model, evidenceType, name, size, offsetCFrame, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CFrame = model:GetPivot() * offsetCFrame
	stampPart(part, evidenceType)
	part.Parent = model
	return part
end

local function addLight(part, color, brightness, range)
	if not (part and part:IsA("BasePart")) then
		return nil
	end
	local light = Instance.new("PointLight")
	light.Name = "EvidenceGlow"
	light.Color = color
	light.Brightness = brightness or 1.2
	light.Range = range or 8
	light.Shadows = false
	light.Parent = part
	return light
end

local function addBillboard(part, title, subtitle, color)
	if not (part and part:IsA("BasePart")) then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EvidenceLabel"
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(150, 46)
	gui.StudsOffset = Vector3.new(0, 1.8, 0)
	gui.Parent = part

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromScale(1, 1)
	panel.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.18
	stroke.Color = color
	stroke.Parent = panel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextColor3 = color:Lerp(Color3.fromRGB(255, 255, 255), 0.25)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Size = UDim2.new(1, -8, 0, 22)
	titleLabel.Position = UDim2.fromOffset(4, 3)
	titleLabel.Text = tostring(title or "EVIDENCE")
	titleLabel.Parent = panel

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.TextSize = 10
	subtitleLabel.TextColor3 = Color3.fromRGB(198, 210, 222)
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	subtitleLabel.Size = UDim2.new(1, -8, 0, 16)
	subtitleLabel.Position = UDim2.fromOffset(4, 25)
	subtitleLabel.Text = tostring(subtitle or "")
	subtitleLabel.Parent = panel
	return gui
end

local function buildMedok(model, evidenceType, config)
	local base = createPart(model, evidenceType, "EMFCore", Vector3.new(0.42, 0.18, 0.42), CFrame.new(0, 0.16, 0), config.color, Enum.Material.Neon, 0.12)
	addLight(base, config.color, 1.8, 9)
	for index = 1, 5 do
		local height = 0.18 + (index * 0.08)
		local color = index >= 4 and Color3.fromRGB(255, 92, 92) or config.color
		createPart(model, evidenceType, "EMFBar" .. tostring(index), Vector3.new(0.07, height, 0.07), CFrame.new(-0.24 + index * 0.12, 0.18 + height * 0.5, -0.28), color, Enum.Material.Neon, 0.06)
	end
	return base
end

local function buildColdSpot(model, evidenceType, config)
	local core = createPart(model, evidenceType, "ColdCore", Vector3.new(0.7, 0.08, 0.7), CFrame.new(0, 0.08, 0), config.color, Enum.Material.Glass, 0.42)
	addLight(core, config.color, 1.1, 7)
	for index = 1, 6 do
		local x = math.cos(index) * 0.38
		local z = math.sin(index) * 0.38
		createPart(model, evidenceType, "FrostMote" .. tostring(index), Vector3.new(0.12, 0.12, 0.12), CFrame.new(x, 0.34 + (index % 3) * 0.16, z), config.color, Enum.Material.Neon, 0.34 + (index * 0.04))
	end
	return core
end

local function buildBookWriting(model, evidenceType, config)
	local cover = createPart(model, evidenceType, "BookCover", Vector3.new(1.35, 0.08, 0.9), CFrame.new(0, 0.08, 0), Color3.fromRGB(58, 38, 36), Enum.Material.Fabric, 0)
	createPart(model, evidenceType, "LeftPage", Vector3.new(0.58, 0.04, 0.78), CFrame.new(-0.31, 0.16, 0), Color3.fromRGB(228, 218, 196), Enum.Material.SmoothPlastic, 0)
	createPart(model, evidenceType, "RightPage", Vector3.new(0.58, 0.04, 0.78), CFrame.new(0.31, 0.16, 0), Color3.fromRGB(230, 220, 198), Enum.Material.SmoothPlastic, 0)
	for index = 1, 6 do
		local x = index <= 3 and -0.42 or 0.16
		local z = -0.24 + ((index - 1) % 3) * 0.18
		createPart(model, evidenceType, "WritingStroke" .. tostring(index), Vector3.new(0.34, 0.025, 0.035), CFrame.new(x, 0.195, z) * CFrame.Angles(0, math.rad(index % 2 == 0 and 9 or -11), 0), config.color, Enum.Material.Neon, 0.08)
	end
	addLight(cover, config.color, 1.2, 7)
	return cover
end

local function buildUvMark(model, evidenceType, config)
	local palm = createPart(model, evidenceType, "UVHandprintPalm", Vector3.new(0.42, 0.08, 0.48), CFrame.new(0, 1.32, -0.32), config.color, Enum.Material.Neon, 0.12)
	for index = 1, 5 do
		local x = -0.24 + (index - 1) * 0.12
		local height = index == 3 and 0.56 or 0.46
		createPart(model, evidenceType, "UVFinger" .. tostring(index), Vector3.new(0.07, 0.06, height), CFrame.new(x, 1.72, -0.34) * CFrame.Angles(math.rad(90), 0, math.rad((index - 3) * 6)), config.color:Lerp(Color3.fromRGB(190, 120, 255), 0.28), Enum.Material.Neon, 0.1)
	end
	local plate = createPart(model, evidenceType, "UVScanPlate", Vector3.new(0.95, 0.04, 1.15), CFrame.new(0, 1.36, -0.36) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(56, 70, 84), Enum.Material.Glass, 0.76)
	addLight(palm, config.color, 1.8, 9)
	return plate
end

local function buildVoiceMark(model, evidenceType, config)
	local core = createPart(model, evidenceType, "VoiceCore", Vector3.new(0.28, 0.28, 0.28), CFrame.new(0, 0.6, 0), config.color, Enum.Material.Neon, 0.08)
	for index = 1, 3 do
		createPart(model, evidenceType, "VoiceWave" .. tostring(index), Vector3.new(0.06, 0.5 + index * 0.22, 0.06), CFrame.new(index * 0.2, 0.62, 0), config.color, Enum.Material.Neon, 0.18 + index * 0.12)
		createPart(model, evidenceType, "VoiceWaveL" .. tostring(index), Vector3.new(0.06, 0.5 + index * 0.22, 0.06), CFrame.new(-index * 0.2, 0.62, 0), config.color, Enum.Material.Neon, 0.18 + index * 0.12)
	end
	addLight(core, config.color, 1.3, 8)
	return core
end

local function buildMotionMark(model, evidenceType, config)
	local core = createPart(model, evidenceType, "MotionTripod", Vector3.new(0.22, 0.5, 0.22), CFrame.new(0, 0.34, 0), Color3.fromRGB(42, 52, 44), Enum.Material.Metal, 0.02)
	for index = 1, 4 do
		local angle = math.rad((index - 1) * 90)
		createPart(model, evidenceType, "MotionBeam" .. tostring(index), Vector3.new(0.08, 0.08, 1.2), CFrame.new(math.cos(angle) * 0.42, 0.7, math.sin(angle) * 0.42) * CFrame.Angles(0, angle, 0), config.color, Enum.Material.Neon, 0.62)
	end
	addLight(core, config.color, 1.1, 7)
	return core
end

local BUILDERS = {
	MEDOK = buildMedok,
	Suhu = buildColdSpot,
	BukuTerkutuk = buildBookWriting,
	["To'un"] = buildUvMark,
	Suara = buildVoiceMark,
	Pengganggu = buildMotionMark,
}

function EvidenceWorldVisuals.new()
	local self = setmetatable({}, EvidenceWorldVisuals)
	self._visualsByMatch = {}
	return self
end

function EvidenceWorldVisuals:StartMatch(matchId)
	self:ClearMatch(matchId)
	ensureContainer(matchId)
end

function EvidenceWorldVisuals:PlaceEvidence(matchId, evidenceType, player, requestPayload)
	if not matchId or type(evidenceType) ~= "string" or evidenceType == "" then
		return nil
	end
	local config = EVIDENCE_CONFIG[evidenceType]
	local builder = BUILDERS[evidenceType]
	if not (config and builder) then
		return nil
	end
	local container, matchFolder, mapModel = ensureContainer(matchId)
	if not container then
		return nil
	end

	local visualName = "Evidence_" .. sanitizeName(evidenceType)
	local existing = container:FindFirstChild(visualName)
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = visualName
	model:SetAttribute(VISUAL_ATTRIBUTE, true)
	model:SetAttribute("PasrahEvidenceType", evidenceType)
	model:SetAttribute("PasrahEvidenceToolType", type(requestPayload) == "table" and tostring(requestPayload.toolType or "") or nil)
	model:SetAttribute("PasrahEvidenceRoomId", type(requestPayload) == "table" and tostring(requestPayload.roomId or "") or nil)
	model:SetAttribute("PasrahEvidenceVisualKind", config.title)
	model.Parent = container

	local anchorCFrame = resolveAnchorCFrame(matchFolder, mapModel, player, requestPayload)
	pcall(function()
		model:PivotTo(anchorCFrame)
	end)
	local rootPart = builder(model, evidenceType, config)
	model.PrimaryPart = rootPart
	if rootPart then
		addBillboard(rootPart, config.title, config.subtitle, config.color)
	end

	self._visualsByMatch[matchId] = self._visualsByMatch[matchId] or {}
	self._visualsByMatch[matchId][evidenceType] = model
	return {
		model = model,
		position = rootPart and rootPart.Position or anchorCFrame.Position,
		kind = config.title,
	}
end

function EvidenceWorldVisuals:ClearMatch(matchId)
	local matchVisuals = self._visualsByMatch[matchId]
	if type(matchVisuals) == "table" then
		for _, model in pairs(matchVisuals) do
			if typeof(model) == "Instance" and model.Parent then
				model:Destroy()
			end
		end
	end
	self._visualsByMatch[matchId] = nil

	local matchFolder = resolveMatchFolder(matchId, false)
	local container = matchFolder and matchFolder:FindFirstChild(FOLDER_NAME)
	if container then
		container:Destroy()
	end
end

function EvidenceWorldVisuals:ClearAll()
	for matchId in pairs(self._visualsByMatch) do
		self:ClearMatch(matchId)
	end
	local activeMatches = Workspace:FindFirstChild("ActiveMatches")
	if activeMatches then
		for _, matchFolder in ipairs(activeMatches:GetChildren()) do
			local container = matchFolder:FindFirstChild(FOLDER_NAME)
			if container then
				container:Destroy()
			end
		end
	end
end

return EvidenceWorldVisuals
