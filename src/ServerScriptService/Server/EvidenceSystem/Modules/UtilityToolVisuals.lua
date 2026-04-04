local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TOOL_CONTAINER_NAME = "InvestigationTools"

local UtilityToolVisuals = {}
UtilityToolVisuals.__index = UtilityToolVisuals

local function getToolsFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	return models and models:FindFirstChild("Tools") or nil
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

	local expectedName = "Match_" .. tostring(matchId)
	local matchFolder = activeMatches:FindFirstChild(expectedName)
	if not matchFolder and createIfMissing ~= false then
		matchFolder = Instance.new("Folder")
		matchFolder.Name = expectedName
		matchFolder.Parent = activeMatches
	end
	return matchFolder
end

local function ensureToolsContainer(matchId)
	local matchFolder = resolveMatchFolder(matchId, true)
	if not matchFolder then
		return nil
	end

	local container = matchFolder:FindFirstChild(TOOL_CONTAINER_NAME)
	if not container then
		container = Instance.new("Folder")
		container.Name = TOOL_CONTAINER_NAME
		container.Parent = matchFolder
	end
	return container
end

local function setPlacementPhysics(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
end

local function createPart(parent, name, size, position, material, color, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Size = size
	part.Position = position
	part.Material = material
	part.Color = color
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function setPartColor(model, partName, color, transparency, material)
	local part = model and model:FindFirstChild(partName, true)
	if part and part:IsA("BasePart") then
		if color then
			part.Color = color
		end
		if transparency ~= nil then
			part.Transparency = transparency
		end
		if material then
			part.Material = material
		end
	end
	return part
end

local function buildFallbackModel(toolType)
	local model = Instance.new("Model")
	model.Name = toolType

	if toolType == "Garam" then
		createPart(model, "PileMain", Vector3.new(1.8, 0.14, 1.2), Vector3.new(0, 0.05, 0), Enum.Material.Sand, Color3.fromRGB(245, 245, 238))
		createPart(model, "PileAccent", Vector3.new(0.88, 0.1, 0.52), Vector3.new(0.28, 0.09, 0.08), Enum.Material.Sand, Color3.fromRGB(250, 250, 244))
		createPart(model, "PileAccent2", Vector3.new(0.46, 0.08, 0.34), Vector3.new(-0.42, 0.08, 0.18), Enum.Material.Sand, Color3.fromRGB(252, 252, 246))
		createPart(model, "Satchel", Vector3.new(0.42, 0.28, 0.2), Vector3.new(-0.74, 0.14, 0.32), Enum.Material.Fabric, Color3.fromRGB(148, 126, 92))
		createPart(model, "Seal", Vector3.new(0.08, 0.08, 0.18), Vector3.new(-0.58, 0.2, 0.32), Enum.Material.Metal, Color3.fromRGB(188, 170, 128))
		createPart(model, "SaltGlow", Vector3.new(1.52, 0.03, 0.94), Vector3.new(0.04, 0.02, 0.02), Enum.Material.Neon, Color3.fromRGB(224, 236, 255), 0.9)
		createPart(model, "TrackLeft", Vector3.new(0.22, 0.04, 0.58), Vector3.new(-0.34, 0.02, -0.44), Enum.Material.Slate, Color3.fromRGB(64, 64, 64), 1)
		createPart(model, "TrackRight", Vector3.new(0.22, 0.04, 0.58), Vector3.new(0.32, 0.02, -0.18), Enum.Material.Slate, Color3.fromRGB(64, 64, 64), 1)
	elseif toolType == "Salib" then
		createPart(model, "Stem", Vector3.new(0.26, 2.1, 0.2), Vector3.new(0, 1.05, 0), Enum.Material.Wood, Color3.fromRGB(92, 64, 42))
		createPart(model, "Crossbar", Vector3.new(1.28, 0.24, 0.2), Vector3.new(0, 1.46, 0), Enum.Material.Wood, Color3.fromRGB(100, 72, 48))
		createPart(model, "Base", Vector3.new(0.72, 0.24, 0.72), Vector3.new(0, 0.12, 0), Enum.Material.Slate, Color3.fromRGB(38, 38, 42))
		createPart(model, "HaloBack", Vector3.new(1.48, 1.48, 0.08), Vector3.new(0, 1.46, 0.02), Enum.Material.Neon, Color3.fromRGB(255, 226, 130), 0.78)
		createPart(model, "GroundAura", Vector3.new(1.46, 0.04, 1.46), Vector3.new(0, 0.02, 0), Enum.Material.Neon, Color3.fromRGB(255, 220, 126), 0.82)
		createPart(model, "Charge1", Vector3.new(0.18, 0.18, 0.18), Vector3.new(-0.36, 1.86, 0), Enum.Material.Neon, Color3.fromRGB(255, 211, 94))
		createPart(model, "Charge2", Vector3.new(0.18, 0.18, 0.18), Vector3.new(0, 1.98, 0), Enum.Material.Neon, Color3.fromRGB(255, 211, 94))
		createPart(model, "Charge3", Vector3.new(0.18, 0.18, 0.18), Vector3.new(0.36, 1.86, 0), Enum.Material.Neon, Color3.fromRGB(255, 211, 94))
	elseif toolType == "Dupa" then
		createPart(model, "Stick", Vector3.new(1.5, 0.12, 0.18), Vector3.new(0, 0.08, 0), Enum.Material.Wood, Color3.fromRGB(78, 56, 42))
		createPart(model, "Binding", Vector3.new(0.12, 0.16, 0.22), Vector3.new(-0.34, 0.09, 0), Enum.Material.Fabric, Color3.fromRGB(146, 120, 86))
		createPart(model, "AshBed", Vector3.new(0.44, 0.04, 0.28), Vector3.new(0.12, 0.03, 0), Enum.Material.Slate, Color3.fromRGB(76, 72, 66))
		createPart(model, "CharmWrap", Vector3.new(0.14, 0.18, 0.24), Vector3.new(0.08, 0.11, 0), Enum.Material.Fabric, Color3.fromRGB(124, 76, 54))
		createPart(model, "Ember", Vector3.new(0.12, 0.12, 0.12), Vector3.new(0.76, 0.1, 0), Enum.Material.Neon, Color3.fromRGB(255, 124, 56))
		createPart(model, "RepelAura", Vector3.new(0.94, 0.06, 0.94), Vector3.new(0.42, 0.03, 0), Enum.Material.Neon, Color3.fromRGB(106, 186, 196), 0.92)
		createPart(model, "Smoke1", Vector3.new(0.22, 0.24, 0.22), Vector3.new(0.78, 0.44, 0), Enum.Material.Neon, Color3.fromRGB(172, 178, 186), 0.5)
		createPart(model, "Smoke2", Vector3.new(0.28, 0.26, 0.28), Vector3.new(0.63, 0.68, 0.08), Enum.Material.Neon, Color3.fromRGB(176, 184, 192), 0.62)
		createPart(model, "Smoke3", Vector3.new(0.34, 0.28, 0.34), Vector3.new(0.9, 0.9, -0.06), Enum.Material.Neon, Color3.fromRGB(186, 192, 198), 0.7)
		createPart(model, "Smoke4", Vector3.new(0.26, 0.24, 0.26), Vector3.new(0.52, 0.86, 0.12), Enum.Material.Neon, Color3.fromRGB(178, 186, 192), 0.76)
		createPart(model, "Smoke5", Vector3.new(0.22, 0.2, 0.22), Vector3.new(1.04, 1.08, -0.04), Enum.Material.Neon, Color3.fromRGB(190, 196, 200), 0.82)
	else
		createPart(model, "Core", Vector3.new(1, 1, 1), Vector3.new(), Enum.Material.SmoothPlastic, Color3.fromRGB(200, 200, 200))
	end

	return model
end

function UtilityToolVisuals.new()
	local self = setmetatable({}, UtilityToolVisuals)
	self._placementsByMatch = {}
	return self
end

function UtilityToolVisuals:_getPlacementMap(matchId)
	local placementMap = self._placementsByMatch[matchId]
	if type(placementMap) ~= "table" then
		placementMap = {}
		self._placementsByMatch[matchId] = placementMap
	end
	return placementMap
end

function UtilityToolVisuals:_getPlacement(matchId, placementId)
	local placementMap = self._placementsByMatch[matchId]
	if type(placementMap) ~= "table" then
		return nil
	end
	return placementMap[placementId]
end

function UtilityToolVisuals:StartMatch(matchId)
	self:ClearMatch(matchId)
	ensureToolsContainer(matchId)
end

function UtilityToolVisuals:PlaceTool(matchId, toolType, placementId, worldCFrame)
	if not matchId or not toolType or not placementId then
		return nil
	end

	local toolsFolder = getToolsFolder()
	local template = toolsFolder and toolsFolder:FindFirstChild(toolType)

	local container = ensureToolsContainer(matchId)
	if not container then
		return nil
	end

	local model = nil
	if template and template:IsA("Model") then
		model = template:Clone()
	else
		model = buildFallbackModel(toolType)
	end
	if not model then
		return nil
	end
	model.Name = string.format("%s_%s", toolType, tostring(placementId))
	setPlacementPhysics(model)
	model.Parent = container

	if typeof(worldCFrame) == "CFrame" then
		pcall(function()
			model:PivotTo(worldCFrame)
		end)
	end

	self:_getPlacementMap(matchId)[placementId] = {
		model = model,
		toolType = toolType,
	}

	if toolType == "Salib" then
		self:UpdateCrucifixCharges(matchId, placementId, 3)
	end

	return model
end

function UtilityToolVisuals:MarkSaltTriggered(matchId, placementId)
	local placement = self:_getPlacement(matchId, placementId)
	local model = placement and placement.model
	if not (model and model.Parent) then
		return false
	end

	for _, trackName in ipairs({ "TrackLeft", "TrackRight" }) do
		local track = model:FindFirstChild(trackName, true)
		if track and track:IsA("BasePart") then
			track.Transparency = 0.12
			track.Color = Color3.fromRGB(74, 74, 74)
			track.Material = Enum.Material.Slate
		end
	end

	local pileAccent = model:FindFirstChild("PileAccent", true)
	if pileAccent and pileAccent:IsA("BasePart") then
		pileAccent.Color = Color3.fromRGB(248, 248, 242)
	end
	setPartColor(model, "SaltGlow", Color3.fromRGB(208, 220, 255), 0.32, Enum.Material.Neon)
	setPartColor(model, "Satchel", Color3.fromRGB(112, 92, 68), nil, nil)
	setPartColor(model, "Seal", Color3.fromRGB(222, 206, 160), 0.05, Enum.Material.Metal)

	return true
end

function UtilityToolVisuals:UpdateCrucifixCharges(matchId, placementId, chargesRemaining)
	local placement = self:_getPlacement(matchId, placementId)
	local model = placement and placement.model
	if not (model and model.Parent) then
		return false
	end

	local remaining = math.max(0, math.floor(tonumber(chargesRemaining) or 0))
	for chargeIndex = 1, 3 do
		local chargePart = model:FindFirstChild("Charge" .. tostring(chargeIndex), true)
		if chargePart and chargePart:IsA("BasePart") then
			local active = chargeIndex <= remaining
			chargePart.Transparency = active and 0.08 or 0.84
			chargePart.Color = active and Color3.fromRGB(255, 211, 94) or Color3.fromRGB(82, 82, 82)
			chargePart.Material = active and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end

	local auraTransparency = 0.9
	local auraColor = Color3.fromRGB(126, 108, 84)
	if remaining >= 3 then
		auraTransparency = 0.48
		auraColor = Color3.fromRGB(255, 226, 132)
	elseif remaining == 2 then
		auraTransparency = 0.62
		auraColor = Color3.fromRGB(240, 194, 112)
	elseif remaining == 1 then
		auraTransparency = 0.76
		auraColor = Color3.fromRGB(214, 154, 88)
	end
	setPartColor(model, "HaloBack", auraColor, auraTransparency, Enum.Material.Neon)
	setPartColor(model, "GroundAura", auraColor, math.min(0.9, auraTransparency + 0.06), Enum.Material.Neon)

	return true
end

function UtilityToolVisuals:ActivateSmudge(matchId, placementId, huntRepelled)
	local placement = self:_getPlacement(matchId, placementId)
	local model = placement and placement.model
	if not (model and model.Parent) then
		return false
	end

	local auraColor = huntRepelled and Color3.fromRGB(112, 214, 224) or Color3.fromRGB(198, 170, 118)
	local emberColor = huntRepelled and Color3.fromRGB(120, 234, 242) or Color3.fromRGB(255, 148, 84)
	setPartColor(model, "Ember", emberColor, 0.02, Enum.Material.Neon)
	setPartColor(model, "RepelAura", auraColor, huntRepelled and 0.34 or 0.48, Enum.Material.Neon)
	for smokeIndex = 1, 5 do
		local transparency = 0.44 + ((smokeIndex - 1) * 0.08)
		if huntRepelled then
			transparency -= 0.08
		end
		setPartColor(
			model,
			"Smoke" .. tostring(smokeIndex),
			huntRepelled and Color3.fromRGB(188, 236, 240) or Color3.fromRGB(204, 196, 184),
			math.clamp(transparency, 0.18, 0.88),
			Enum.Material.Neon
		)
	end

	return true
end

function UtilityToolVisuals:DestroyTool(matchId, placementId)
	local placementMap = self._placementsByMatch[matchId]
	local placement = type(placementMap) == "table" and placementMap[placementId] or nil
	if not placement then
		return false
	end

	placementMap[placementId] = nil
	local model = placement.model
	if model and model.Parent then
		model:Destroy()
	end
	return true
end

function UtilityToolVisuals:ClearMatch(matchId)
	local placementMap = self._placementsByMatch[matchId]
	if type(placementMap) == "table" then
		for placementId in pairs(placementMap) do
			self:DestroyTool(matchId, placementId)
		end
	end
	self._placementsByMatch[matchId] = nil

	local matchFolder = resolveMatchFolder(matchId, false)
	local container = matchFolder and matchFolder:FindFirstChild(TOOL_CONTAINER_NAME)
	if container then
		container:Destroy()
	end
end

function UtilityToolVisuals:ClearAll()
	for matchId in pairs(self._placementsByMatch) do
		self:ClearMatch(matchId)
	end
end

return UtilityToolVisuals
