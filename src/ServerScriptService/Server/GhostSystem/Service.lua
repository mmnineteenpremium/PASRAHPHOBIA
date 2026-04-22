local GhostService = require(script.Parent.GhostService)
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local GHOST_TRACE_ATTRIBUTE = "PasrahGhostTrace"
local GHOST_FORCE_VISUAL_STATE_ATTRIBUTE = "PasrahForceGhostVisualState"

local DEFAULT_GHOST_TYPES = {
	"Pocong",
	"Kuntilanak",
	"Genderuwo",
	"Tuyul",
	"Leak",
	"Banaspati",
	"Jerangkong",
	"WeweGombel",
	"Palasik",
	"SilumanUlar",
	"SundelBolong",
	"HantuTanah",
}

local DEFAULT_GHOST_TEMPLATE_VISUAL_OFFSETS = {}

local DEFAULT_GHOST_TEMPLATE_ROOT_SIZES = {}

local DEFAULT_GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES = {}

local DEFAULT_GHOST_TEMPLATE_TARGET_BOUNDS = {
	Kuntilanak = Vector3.new(3.5, 4.8, 1.8),
	KuntilanakAggressive = Vector3.new(2.2, 5.4, 1.8),
	Genderuwo = Vector3.new(3.4, 5.8, 2.6),
	Leak = Vector3.new(2.0, 4.8, 2.35),
}

local DEFAULT_GHOST_TEMPLATE_MAX_HOVER_HEIGHT = {
	Kuntilanak = 0.05,
	KuntilanakAggressive = 0.05,
}

local DEFAULT_GHOST_TEMPLATE_GROUNDED = {
	Pocong = true,
	Genderuwo = true,
	Leak = true,
}

local DEFAULT_GHOST_TEMPLATE_MESH_PART_NAMES = {}

local DEFAULT_GHOST_TEMPLATE_CAST_SHADOW = {}

local GHOST_TEMPLATE_VISUAL_OFFSETS = {}
local GHOST_TEMPLATE_ROOT_SIZES = {}
local GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES = {}
local GHOST_TEMPLATE_TARGET_BOUNDS = {}
local GHOST_TEMPLATE_MAX_HOVER_HEIGHT = {}
local GHOST_TEMPLATE_GROUNDED = {}
local GHOST_TEMPLATE_MESH_PART_NAMES = {}
local GHOST_TEMPLATE_CAST_SHADOW = {}
local GHOST_TEMPLATE_INVENTORY_MODEL_ASSET_IDS = {}

local GHOST_VISUAL_MOVE_SPEED_BY_STATE = {
	Idle = 1.75,
	Roaming = 3.6,
	Manifestation = 4.4,
	Hunting = 7.8,
	Cooldown = 2.1,
}

local GHOST_VISUAL_TRANSPARENCY_BY_STATE = {
	Idle = 0.75,
	Roaming = 0.35,
	Manifestation = 0.0,
	Hunting = 0.05,
	Cooldown = 0.55,
}

local GHOST_VISUAL_MOTION_BY_STATE = {
	Idle = {
		bobAmplitude = 0.015,
		bobFrequency = 1.2,
		swayAmplitude = 0.02,
		swayFrequency = 0.7,
		pitchDegrees = 0.8,
		rollDegrees = 1.6,
		yawDegrees = 2.5,
	},
	Roaming = {
		bobAmplitude = 0.03,
		bobFrequency = 1.8,
		swayAmplitude = 0.045,
		swayFrequency = 1.2,
		pitchDegrees = 1.8,
		rollDegrees = 2.6,
		yawDegrees = 4,
	},
	Manifestation = {
		bobAmplitude = 0.055,
		bobFrequency = 1.35,
		swayAmplitude = 0.035,
		swayFrequency = 0.9,
		pitchDegrees = 3.6,
		rollDegrees = 5,
		yawDegrees = 6,
	},
	Hunting = {
		bobAmplitude = 0.028,
		bobFrequency = 3.6,
		swayAmplitude = 0.02,
		swayFrequency = 2.2,
		pitchDegrees = 5.2,
		rollDegrees = 1.8,
		yawDegrees = 0,
		forwardLunge = 0.1,
	},
	Cooldown = {
		bobAmplitude = 0.018,
		bobFrequency = 1.1,
		swayAmplitude = 0.018,
		swayFrequency = 0.65,
		pitchDegrees = 1.2,
		rollDegrees = 1.4,
		yawDegrees = 2,
	},
}

local STUDIO_GHOST_PREVIEW_FOLDER_NAME = "StudioGhostPreviewGallery"
local STUDIO_GHOST_PREVIEW_ENABLED_ATTRIBUTE = "PasrahStudioLobbyGhostPreview"
local STUDIO_GHOST_PREVIEW_ORDER = {
	Pocong = 1,
	Kuntilanak = 2,
	KuntilanakAggressive = 3,
	Genderuwo = 4,
	Leak = 5,
}

local GHOST_AGGRESSIVE_VISUAL_THRESHOLD = 65
local GHOST_AGGRESSIVE_SUFFIXES = {
	"Aggressive",
	"Agressive",
	"Angry",
}

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return nil
	end
	return trimmed:gsub("[%s_%-_%.]+", ""):lower()
end

local function trimGhostName(value)
	if type(value) ~= "string" then
		return nil
	end
	local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return nil
	end
	return trimmed
end

local function splitGhostTypeVariant(ghostType)
	local trimmed = trimGhostName(ghostType)
	if not trimmed then
		return nil, nil
	end

	for _, suffix in ipairs(GHOST_AGGRESSIVE_SUFFIXES) do
		local directToken = suffix .. "$"
		if trimmed:match(directToken) then
			local baseName = trimGhostName(trimmed:gsub(directToken, ""))
			if baseName then
				return baseName, suffix
			end
		end

		local delimitedToken = "[%s_%-]+" .. suffix .. "$"
		if trimmed:match(delimitedToken) then
			local baseName = trimGhostName(trimmed:gsub(delimitedToken, ""))
			if baseName then
				return baseName, suffix
			end
		end
	end

	return trimmed, nil
end

local function resolveGhostBaseType(ghostType)
	local baseName = select(1, splitGhostTypeVariant(ghostType))
	baseName = baseName or ghostType
	if type(baseName) == "string" then
		baseName = baseName:gsub("^Ghost[%s_%-]+", "")
	end
	return baseName
end

local function isAggressiveGhostTypeName(ghostType)
	local _, suffix = splitGhostTypeVariant(ghostType)
	return suffix ~= nil
end

local function resolveGhostTemplateConfigValue(configMap, ghostType)
	if type(configMap) ~= "table" then
		return nil
	end
	if configMap[ghostType] ~= nil then
		return configMap[ghostType]
	end

	local baseGhostType = resolveGhostBaseType(ghostType)
	if baseGhostType ~= ghostType and configMap[baseGhostType] ~= nil then
		return configMap[baseGhostType]
	end

	local baseToken = normalizeToken(baseGhostType)
	if not baseToken then
		return nil
	end
	for key, value in pairs(configMap) do
		if normalizeToken(key) == baseToken then
			return value
		end
	end
	return nil
end

local function resolveGhostVisualTypeName(ghostModel)
	if typeof(ghostModel) ~= "Instance" then
		return nil
	end

	for _, candidate in ipairs({
		ghostModel:GetAttribute("VisualGhostType"),
		ghostModel:GetAttribute("GhostType"),
		ghostModel:GetAttribute("VisualTemplateName"),
		ghostModel.Name,
	}) do
		if type(candidate) == "string" and candidate ~= "" then
			return candidate
		end
	end

	return nil
end

local function normalizeGhostVisualState(stateName)
	if type(stateName) ~= "string" then
		return nil
	end

	local trimmed = stateName:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return nil
	end

	if trimmed == "Manifest" or trimmed == "Manifestation" then
		return "Manifestation"
	end
	if trimmed == "Hunt" or trimmed == "Hunting" then
		return "Hunting"
	end
	if trimmed == "Retreat" or trimmed == "Cooldown" then
		return "Cooldown"
	end
	if trimmed == "Idle" or trimmed == "Roaming" then
		return trimmed
	end
	return nil
end

local function resolveGhostVisualStateName(ghostState)
	local actualStateName = ghostState and ghostState.state or nil
	local normalizedActualStateName = normalizeGhostVisualState(actualStateName)
	local overrideStateName = nil
	if RunService:IsStudio() then
		overrideStateName = normalizeGhostVisualState(ReplicatedStorage:GetAttribute(GHOST_FORCE_VISUAL_STATE_ATTRIBUTE))
	end

	local stateName = overrideStateName or normalizedActualStateName or actualStateName
	if not overrideStateName and ghostState and ghostState.huntActive == true then
		stateName = "Hunting"
	end

	return stateName, normalizedActualStateName or actualStateName, overrideStateName
end

local function shouldHideGhostControlPart(part)
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return false
	end

	local token = normalizeToken(part.Name)
	return token == "humanoidrootpart"
		or token == "rootpart"
		or token == "root"
		or token == "primarypart"
end

local function createGhostRigPart(model, name, size, offset, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.CFrame = offset
	part.Parent = model
	return part
end

local function createGhostHumanoid(model)
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "GhostHumanoid"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model
	return humanoid
end

local function createVisibleGhostPlaceholder(spawnCFrame, ghostType)
	local ghostModel = Instance.new("Model")
	ghostModel.Name = string.format("GhostPlaceholder_%s", tostring(ghostType or "Unknown"))
	ghostModel:SetAttribute("GhostType", ghostType)
	ghostModel:SetAttribute("PlaceholderVisual", true)
	ghostModel:SetAttribute("PasrahGhostInventoryModelAssetId", nil)

	local root = createGhostRigPart(ghostModel, "HumanoidRootPart", Vector3.new(2, 2, 1), spawnCFrame, Color3.fromRGB(80, 86, 96))
	root.Transparency = 1

	local torso = createGhostRigPart(ghostModel, "Torso", Vector3.new(2, 2, 1), spawnCFrame * CFrame.new(0, 0, 0), Color3.fromRGB(168, 176, 188))
	local head = createGhostRigPart(ghostModel, "Head", Vector3.new(2, 1, 1), spawnCFrame * CFrame.new(0, 1.5, 0), Color3.fromRGB(214, 220, 228))
	local leftArm = createGhostRigPart(ghostModel, "Left Arm", Vector3.new(1, 2, 1), spawnCFrame * CFrame.new(-1.5, 0, 0), Color3.fromRGB(160, 168, 182))
	local rightArm = createGhostRigPart(ghostModel, "Right Arm", Vector3.new(1, 2, 1), spawnCFrame * CFrame.new(1.5, 0, 0), Color3.fromRGB(160, 168, 182))
	local leftLeg = createGhostRigPart(ghostModel, "Left Leg", Vector3.new(1, 2, 1), spawnCFrame * CFrame.new(-0.5, -2, 0), Color3.fromRGB(124, 132, 148))
	local rightLeg = createGhostRigPart(ghostModel, "Right Leg", Vector3.new(1, 2, 1), spawnCFrame * CFrame.new(0.5, -2, 0), Color3.fromRGB(124, 132, 148))

	for _, limb in ipairs({ torso, head, leftArm, rightArm, leftLeg, rightLeg }) do
		limb.CastShadow = false
	end

	createGhostHumanoid(ghostModel)
	ghostModel.PrimaryPart = root
	return ghostModel
end

local GHOST_RETRY_COUNT = 3
local GHOST_RETRY_WAIT = 0.05
local GHOST_VISUAL_SYNC_INTERVAL = 0.1

local function safeRequire(moduleScript)
	if not moduleScript then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok then
		return result
	end
	return nil
end

local function resolveGhostVisualProfileFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("GhostVisualProfiles") or nil
end

local function resolveGhostVisualProfile(ghostType)
	if type(ghostType) ~= "string" or ghostType == "" then
		return nil
	end
	local folder = resolveGhostVisualProfileFolder()
	if not folder then
		return nil
	end
	local moduleScript = folder:FindFirstChild(ghostType)
	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return nil
	end
	local profile = safeRequire(moduleScript)
	if type(profile) ~= "table" then
		return nil
	end
	return profile
end

local function coerceProfileVector3(value)
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

local function buildGhostTemplateCandidateNames(ghostType, profile)
	local seen = {}
	local candidates = {}

	local function addCandidate(name)
		if type(name) ~= "string" or name == "" or seen[name] then
			return
		end
		seen[name] = true
		table.insert(candidates, name)
	end

	addCandidate(ghostType)
	addCandidate("Ghost_" .. tostring(ghostType))

	local modelName = type(profile) == "table" and profile.modelName or nil
	addCandidate(modelName)
	if type(modelName) == "string" and string.sub(modelName, 1, 6) == "Ghost_" then
		addCandidate(string.sub(modelName, 7))
	end

	return candidates
end

local function buildAggressiveGhostTemplateCandidateNames(ghostType)
	local baseGhostType = resolveGhostBaseType(ghostType)
	local seen = {}
	local candidates = {}

	local function addCandidate(name)
		if type(name) ~= "string" or name == "" or seen[name] then
			return
		end
		seen[name] = true
		table.insert(candidates, name)
	end

	for _, suffix in ipairs(GHOST_AGGRESSIVE_SUFFIXES) do
		addCandidate(baseGhostType .. suffix)
		addCandidate(baseGhostType .. "_" .. suffix)
		addCandidate(baseGhostType .. "-" .. suffix)
		addCandidate("Ghost_" .. baseGhostType .. suffix)
		addCandidate("Ghost_" .. baseGhostType .. "_" .. suffix)
		addCandidate("Ghost_" .. baseGhostType .. "-" .. suffix)
	end

	return candidates
end

local function shouldUseAggressiveGhostVisualType(ghostType, ghostState, options)
	if isAggressiveGhostTypeName(ghostType) then
		return true
	end

	local context = type(options) == "table" and options or {}
	local state = type(ghostState) == "table" and ghostState or {}
	local stateRaw = trimGhostName(state.state)
	local stateName = stateRaw
	if stateRaw == "Hunt" then
		stateName = "Hunting"
	elseif stateRaw == "Manifest" then
		stateName = "Manifestation"
	elseif stateRaw == "Retreat" then
		stateName = "Cooldown"
	end
	local aggression = tonumber(state.aggression)
	if type(aggression) ~= "number" then
		aggression = tonumber(context.initialAggression)
	end
	local personalityType = type(state.personality) == "table" and tostring(state.personality.type or "") or ""
	if personalityType == "" then
		personalityType = tostring(context.personalityType or "")
	end

	if state.huntActive == true then
		return true
	end
	if stateName == "Hunting" then
		return true
	end
	if type(aggression) == "number" and aggression >= GHOST_AGGRESSIVE_VISUAL_THRESHOLD then
		return true
	end
	if personalityType == "Aggressive" and type(aggression) == "number" and aggression >= 55 then
		return true
	end

	return false
end

local function resolveGhostTemplatesFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	local models = assets:FindFirstChild("Models")
	if not models then
		return nil
	end
	return models:FindFirstChild("Ghosts")
end

local function resolveGhostModelTemplate(ghostType, options)
	if type(ghostType) ~= "string" or ghostType == "" then
		return nil
	end
	local ghosts = resolveGhostTemplatesFolder()
	if not ghosts then
		return nil
	end

	local context = type(options) == "table" and options or {}
	local baseGhostType = resolveGhostBaseType(ghostType)
	local profile = resolveGhostVisualProfile(ghostType) or resolveGhostVisualProfile(baseGhostType)
	local preferredCandidates = {}
	local seen = {}

	local function appendCandidates(candidates)
		for _, candidateName in ipairs(candidates or {}) do
			if type(candidateName) == "string" and candidateName ~= "" and not seen[candidateName] then
				seen[candidateName] = true
				table.insert(preferredCandidates, candidateName)
			end
		end
	end

	if shouldUseAggressiveGhostVisualType(ghostType, context.ghostState, context) then
		appendCandidates(buildAggressiveGhostTemplateCandidateNames(ghostType))
	end
	appendCandidates(buildGhostTemplateCandidateNames(ghostType, profile))
	if baseGhostType ~= ghostType then
		appendCandidates(buildGhostTemplateCandidateNames(baseGhostType, resolveGhostVisualProfile(baseGhostType)))
	end

	for _, candidateName in ipairs(preferredCandidates) do
		local candidate = ghosts:FindFirstChild(candidateName)
		if candidate and candidate:IsA("Model") then
			return candidate, candidateName
		end
	end

	return nil
end

local function resolveForcedStudioGhostType()
	if not RunService:IsStudio() then
		return nil
	end
	local ghostType = ReplicatedStorage:GetAttribute("PasrahForceGhostType")
	if type(ghostType) ~= "string" or ghostType == "" then
		return nil
	end
	return ghostType
end

local function shouldTraceGhost()
	return RunService:IsStudio() and ReplicatedStorage:GetAttribute(GHOST_TRACE_ATTRIBUTE) == true
end

local function traceGhost(message, payload)
	if not shouldTraceGhost() then
		return
	end

	local parts = {}
	for key, value in pairs(payload or {}) do
		table.insert(parts, string.format("%s=%s", tostring(key), tostring(value)))
	end
	table.sort(parts)
	if #parts > 0 then
		warn(string.format("[GHOST TRACE] %s [%s]", tostring(message), table.concat(parts, ", ")))
	else
		warn(string.format("[GHOST TRACE] %s", tostring(message)))
	end
end

local function setGhostTraceState(stage, details)
	if not shouldTraceGhost() then
		return
	end
	ReplicatedStorage:SetAttribute("PasrahGhostTraceStage", stage)
	ReplicatedStorage:SetAttribute("PasrahGhostTraceDetails", details)
end

local function clampGhostTemplateScale(ghostModel, ghostType)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return
	end

	local targetBounds = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_TARGET_BOUNDS, ghostType) or Vector3.new(2.8, 5.6, 2.4)
	local ok, _, currentBounds = pcall(function()
		return ghostModel:GetBoundingBox()
	end)
	if not ok or typeof(currentBounds) ~= "Vector3" then
		return
	end

	local currentX = math.max(currentBounds.X, 0.001)
	local currentY = math.max(currentBounds.Y, 0.001)
	local currentZ = math.max(currentBounds.Z, 0.001)
	local factor = math.min(targetBounds.X / currentX, targetBounds.Y / currentY, targetBounds.Z / currentZ)
	if factor >= 0.98 and factor <= 1.02 then
		return
	end

	local currentScale = 1
	local okScale, value = pcall(function()
		return ghostModel:GetScale()
	end)
	if okScale and type(value) == "number" and value > 0 then
		currentScale = value
	end

	pcall(function()
		ghostModel:ScaleTo(currentScale * factor)
	end)
end

local function createGhostFromTemplate(spawnCFrame, ghostType, options)
	local context = type(options) == "table" and options or {}
	local template = context.forcedTemplate
	local resolvedVisualGhostType = nil
	if typeof(template) ~= "Instance" then
		template, resolvedVisualGhostType = resolveGhostModelTemplate(ghostType, context)
	end
	if typeof(template) ~= "Instance" or not template:IsA("Model") then
		return nil
	end

	local logicalGhostType = context.logicalGhostType or ghostType
	local visualGhostType = resolvedVisualGhostType or template.Name or ghostType
	local preferredRootSize = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_ROOT_SIZES, visualGhostType)
	local preferredCastShadow = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_CAST_SHADOW, visualGhostType)
	local inventoryModelAssetId = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_INVENTORY_MODEL_ASSET_IDS, visualGhostType)

	local ghostModel = template:Clone()
	ghostModel.Name = string.format("Ghost_%s", tostring(logicalGhostType or "Unknown"))
	ghostModel:SetAttribute("GhostType", logicalGhostType)
	ghostModel:SetAttribute("VisualGhostType", visualGhostType)
	ghostModel:SetAttribute("PlaceholderVisual", false)
	ghostModel:SetAttribute("VisualTemplateName", template.Name)
	ghostModel:SetAttribute("PasrahGhostInventoryModelAssetId", inventoryModelAssetId)

	for _, descendant in ipairs(ghostModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Anchored = true
			if shouldHideGhostControlPart(descendant) then
				descendant.Transparency = 1
				descendant.CastShadow = false
			elseif type(preferredCastShadow) == "boolean" then
				descendant.CastShadow = preferredCastShadow
			end
		end
	end

	clampGhostTemplateScale(ghostModel, visualGhostType)

	local root = ghostModel:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		if typeof(preferredRootSize) == "Vector3" then
			root.Size = preferredRootSize
		else
			root.Size = Vector3.new(2, 2, 1)
		end
		root.Transparency = 1
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
		root.Anchored = true
		ghostModel.PrimaryPart = root
		ghostModel:SetPrimaryPartCFrame(spawnCFrame)
	else
		local firstPart = ghostModel:FindFirstChildWhichIsA("BasePart", true)
		if firstPart then
			ghostModel.PrimaryPart = firstPart
			ghostModel:PivotTo(spawnCFrame)
		end
	end

	if ghostModel.PrimaryPart then
		local visualOffset = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_VISUAL_OFFSETS, visualGhostType)
		local visualMesh = nil
		local preferredMeshPartName = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_MESH_PART_NAMES, visualGhostType)
		if type(preferredMeshPartName) == "string" and preferredMeshPartName ~= "" then
			local candidate = ghostModel:FindFirstChild(preferredMeshPartName, true)
			if candidate and candidate:IsA("MeshPart") then
				visualMesh = candidate
			end
		end
		if not visualMesh then
			visualMesh = ghostModel:FindFirstChildWhichIsA("MeshPart", true)
		end
		if visualMesh then
			local forcedSize = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES, visualGhostType)
			if typeof(forcedSize) == "Vector3" then
				visualMesh.Size = forcedSize
			end
			if typeof(visualOffset) == "Vector3" then
				visualMesh.CFrame = ghostModel.PrimaryPart.CFrame * CFrame.new(visualOffset)
			end
		end
	end

	if not ghostModel:FindFirstChildOfClass("Humanoid") then
		createGhostHumanoid(ghostModel)
	end
	return ghostModel
end

local function tryParentGhostModel(ghostModel, container)
	if typeof(ghostModel) ~= "Instance" or typeof(container) ~= "Instance" then
		return false, "invalid_parent_target"
	end
	local ok, err = pcall(function()
		ghostModel.Parent = container
	end)
	if ok then
		return true
	end
	return false, tostring(err)
end

local function resolveSharedGameDataModule(moduleName)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	if not shared then
		return nil
	end
	local gameData = shared:FindFirstChild("GameData")
	if not gameData then
		return nil
	end
	return gameData:FindFirstChild(moduleName)
end

local function copyGhostVisualVectorMap(source)
	local out = {}
	for ghostType, vector in pairs(source or {}) do
		if type(ghostType) == "string" and typeof(vector) == "Vector3" then
			out[ghostType] = vector
		end
	end
	return out
end

local function copyGhostVisualNumberMap(source)
	local out = {}
	for ghostType, value in pairs(source or {}) do
		if type(ghostType) == "string" and type(value) == "number" then
			out[ghostType] = value
		end
	end
	return out
end

local function copyGhostVisualBooleanMap(source)
	local out = {}
	for ghostType, value in pairs(source or {}) do
		if type(ghostType) == "string" and type(value) == "boolean" then
			out[ghostType] = value
		end
	end
	return out
end

local function copyGhostVisualStringMap(source)
	local out = {}
	for ghostType, value in pairs(source or {}) do
		if type(ghostType) == "string" and type(value) == "string" and value ~= "" then
			out[ghostType] = value
		end
	end
	return out
end

local function loadGhostVisualTuning()
	local offsets = copyGhostVisualVectorMap(DEFAULT_GHOST_TEMPLATE_VISUAL_OFFSETS)
	local rootSizes = copyGhostVisualVectorMap(DEFAULT_GHOST_TEMPLATE_ROOT_SIZES)
	local meshSizes = copyGhostVisualVectorMap(DEFAULT_GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES)
	local bounds = copyGhostVisualVectorMap(DEFAULT_GHOST_TEMPLATE_TARGET_BOUNDS)
	local maxHoverHeights = copyGhostVisualNumberMap(DEFAULT_GHOST_TEMPLATE_MAX_HOVER_HEIGHT)
	local grounded = copyGhostVisualBooleanMap(DEFAULT_GHOST_TEMPLATE_GROUNDED)
	local meshPartNames = copyGhostVisualStringMap(DEFAULT_GHOST_TEMPLATE_MESH_PART_NAMES)
	local castShadow = copyGhostVisualBooleanMap(DEFAULT_GHOST_TEMPLATE_CAST_SHADOW)
	local inventoryModelAssetIds = copyGhostVisualStringMap({})
	local tuning = safeRequire(resolveSharedGameDataModule("GhostVisualTuning"))
	local ghosts = type(tuning) == "table" and tuning.ghosts or nil
	if type(ghosts) ~= "table" then
		ghosts = {}
	end

	for ghostType, config in pairs(ghosts) do
		if type(ghostType) == "string" and type(config) == "table" then
			if typeof(config.meshOffset) == "Vector3" then
				offsets[ghostType] = config.meshOffset
			end
			if typeof(config.meshSize) == "Vector3" then
				meshSizes[ghostType] = config.meshSize
			end
			if typeof(config.targetBounds) == "Vector3" then
				bounds[ghostType] = config.targetBounds
			end
			if type(config.maxHoverHeight) == "number" then
				maxHoverHeights[ghostType] = math.max(0, config.maxHoverHeight)
			end
			if type(config.grounded) == "boolean" then
				grounded[ghostType] = config.grounded
			end
			if type(config.inventoryModelAssetId) == "string" and config.inventoryModelAssetId ~= "" then
				inventoryModelAssetIds[ghostType] = config.inventoryModelAssetId
			end
		end
	end

	local profilesFolder = resolveGhostVisualProfileFolder()
	if profilesFolder then
		for _, child in ipairs(profilesFolder:GetChildren()) do
			if child:IsA("ModuleScript") then
				local profile = safeRequire(child)
				if type(profile) == "table" then
					local ghostType = child.Name
					local visualOffset = coerceProfileVector3(profile.visualOffset)
					if visualOffset then
						offsets[ghostType] = visualOffset
					end

					local meshSize = coerceProfileVector3(profile.size)
					if meshSize and meshSizes[ghostType] == nil then
						meshSizes[ghostType] = meshSize
					end

					local rootSize = coerceProfileVector3(profile.rootSize)
					if rootSize then
						rootSizes[ghostType] = rootSize
					end

					local targetBounds = coerceProfileVector3(profile.targetBounds) or meshSize
					if targetBounds then
						bounds[ghostType] = targetBounds
					end

					if type(profile.maxHoverHeight) == "number" then
						maxHoverHeights[ghostType] = math.max(0, profile.maxHoverHeight)
					end
					if type(profile.grounded) == "boolean" then
						grounded[ghostType] = profile.grounded
					end
					if type(profile.meshPartName) == "string" and profile.meshPartName ~= "" then
						meshPartNames[ghostType] = profile.meshPartName
					end
					if type(profile.castShadow) == "boolean" then
						castShadow[ghostType] = profile.castShadow
					end
				end
			end
		end
	end

	return offsets, meshSizes, bounds, maxHoverHeights, grounded, rootSizes, meshPartNames, castShadow, inventoryModelAssetIds
end

GHOST_TEMPLATE_VISUAL_OFFSETS,
	GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES,
	GHOST_TEMPLATE_TARGET_BOUNDS,
	GHOST_TEMPLATE_MAX_HOVER_HEIGHT,
	GHOST_TEMPLATE_GROUNDED,
	GHOST_TEMPLATE_ROOT_SIZES,
	GHOST_TEMPLATE_MESH_PART_NAMES,
	GHOST_TEMPLATE_CAST_SHADOW,
	GHOST_TEMPLATE_INVENTORY_MODEL_ASSET_IDS = loadGhostVisualTuning()

local function loadMapDatabase()
	local database = safeRequire(resolveSharedGameDataModule("MapConfig"))
	if type(database) == "table" then
		return database
	end
	return {}
end

local function loadGhostDatabase()
	local database = safeRequire(resolveSharedGameDataModule("GhostDatabase"))
	if type(database) == "table" then
		return database
	end
	return {}
end

local function resolveInvestigationToolService(deps)
	local evidenceSystem = Services.Get(deps, "EvidenceSystem")
	if type(evidenceSystem) ~= "table" then
		return nil
	end
	if type(evidenceSystem.TryConsumeHuntProtection) == "function" then
		return evidenceSystem
	end
	if type(evidenceSystem.Service) == "table" and type(evidenceSystem.Service.TryConsumeHuntProtection) == "function" then
		return evidenceSystem.Service
	end
	return nil
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, nested in pairs(value) do
		out[key] = deepCopy(nested)
	end
	return out
end

local function resolveMatchId(matchOrId)
	if type(matchOrId) == "string" then
		return matchOrId
	end
	if type(matchOrId) == "table" then
		return matchOrId.matchId or matchOrId.id
	end
	return nil
end

local function collectSpawnParts(root)
	local parts = {}
	if not root then
		return parts
	end
	for _, child in ipairs(root:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	return parts
end

local function resolveStudioLobbyPreviewRoot()
	local maps = Workspace:FindFirstChild("Maps")
	if not maps then
		return nil
	end

	local lobbyContainer = maps:FindFirstChild("LobbySocialHub")
	if not lobbyContainer then
		return nil
	end

	local nested = lobbyContainer:FindFirstChild("LobbySocialHub")
	if nested and nested:IsA("Model") then
		return nested
	end

	if lobbyContainer:IsA("Model") or lobbyContainer:IsA("Folder") then
		return lobbyContainer
	end

	return nil
end

local function resolveStudioLobbyPreviewSpawnParts()
	local lobbyRoot = resolveStudioLobbyPreviewRoot()
	if not lobbyRoot then
		return nil, {}
	end

	local spawnFolder = lobbyRoot:FindFirstChild("SpawnPoints", true)
	local spawnParts = collectSpawnParts(spawnFolder)
	table.sort(spawnParts, function(left, right)
		return left.Name < right.Name
	end)
	return lobbyRoot, spawnParts
end

local function resolveStudioLobbyPreviewGhostTypes()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local ghosts = models and models:FindFirstChild("Ghosts")
	if not ghosts then
		return {}
	end

	local ghostTypes = {}
	for _, child in ipairs(ghosts:GetChildren()) do
		if child:IsA("Model") then
			table.insert(ghostTypes, child.Name)
		end
	end

	table.sort(ghostTypes, function(left, right)
		local leftOrder = STUDIO_GHOST_PREVIEW_ORDER[left] or 1000
		local rightOrder = STUDIO_GHOST_PREVIEW_ORDER[right] or 1000
		if leftOrder == rightOrder then
			return left < right
		end
		return leftOrder < rightOrder
	end)

	return ghostTypes
end

local function resolveStudioLobbyPreviewCenter(spawnParts)
	if #spawnParts == 0 then
		return nil
	end

	local sum = Vector3.zero
	for _, part in ipairs(spawnParts) do
		sum += part.Position
	end
	return sum / #spawnParts
end

local function resolveStudioLobbyPreviewFloorY(spawnParts)
	if #spawnParts == 0 then
		return nil
	end

	local sum = 0
	for _, part in ipairs(spawnParts) do
		sum += part.Position.Y + (part.Size.Y * 0.5)
	end
	return sum / #spawnParts
end

local function attachStudioGhostPreviewLabel(model, ghostType)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.PrimaryPart then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PreviewLabel"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 100
	billboard.Size = UDim2.fromOffset(180, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	billboard.Adornee = model.PrimaryPart
	billboard.Parent = model.PrimaryPart

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	label.BorderSizePixel = 0
	label.Text = tostring(ghostType)
	label.TextColor3 = Color3.fromRGB(237, 240, 244)
	label.TextStrokeTransparency = 0.6
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = billboard
end

local function resolveGhostGroundPosition(match, targetAnchor)
	if type(match) ~= "table" or typeof(match.ghost) ~= "Instance" then
		return nil
	end

	local targetPosition = nil
	local targetGroundY = nil
	if typeof(targetAnchor) == "Instance" and targetAnchor:IsA("BasePart") then
		targetPosition = targetAnchor.Position
		targetGroundY = targetAnchor.Position.Y + (targetAnchor.Size.Y * 0.5)
	elseif typeof(targetAnchor) == "Vector3" then
		targetPosition = targetAnchor
	else
		return nil
	end

	local ghostPivot = match.ghost:GetPivot()
	local ok, ghostBoundsCFrame, ghostBoundsSize = pcall(function()
		return match.ghost:GetBoundingBox()
	end)
	if not ok or typeof(ghostBoundsCFrame) ~= "CFrame" or typeof(ghostBoundsSize) ~= "Vector3" then
		return targetPosition
	end

	local pivotToBoundsOffset = ghostBoundsCFrame.Position - ghostPivot.Position
	local groundY = targetGroundY
	if groundY == nil then
		groundY = targetPosition.Y
	end
	local boundsCenterY = groundY + (ghostBoundsSize.Y * 0.5) + 0.04
	local boundsCenter = Vector3.new(targetPosition.X, boundsCenterY, targetPosition.Z)
	local resolvedPivot = boundsCenter - pivotToBoundsOffset
	return resolvedPivot
end

local function resolvePlayerRootPart(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end

	local character = player.Character
	if typeof(character) ~= "Instance" then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return character.PrimaryPart
end

local function collectMatchSafeZoneParts(match)
	if type(match) ~= "table" then
		return nil
	end
	local container = match.container
	if not (typeof(container) == "Instance" and container:IsA("Folder")) then
		return nil
	end
	local safeZonesFolder = container:FindFirstChild("SafeZones", true)
	if not safeZonesFolder then
		return nil
	end
	local safeZoneParts = {}
	for _, descendant in ipairs(safeZonesFolder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(safeZoneParts, descendant)
		end
	end
	if #safeZoneParts == 0 then
		return nil
	end
	return safeZoneParts
end

local function isPositionInsidePartBounds(position, part)
	if typeof(position) ~= "Vector3" or not (typeof(part) == "Instance" and part:IsA("BasePart")) then
		return false
	end
	local localPosition = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size * 0.5
	return math.abs(localPosition.X) <= halfSize.X
		and math.abs(localPosition.Y) <= halfSize.Y
		and math.abs(localPosition.Z) <= halfSize.Z
end

local function isRootInsideSafeZone(rootPart, safeZoneParts)
	if not (rootPart and rootPart:IsA("BasePart")) then
		return false
	end
	if type(safeZoneParts) ~= "table" or #safeZoneParts == 0 then
		return false
	end
	local position = rootPart.Position
	for _, safeZonePart in ipairs(safeZoneParts) do
		if isPositionInsidePartBounds(position, safeZonePart) then
			return true
		end
	end
	return false
end

local function isPositionInsideSafeZones(position, safeZoneParts)
	if typeof(position) ~= "Vector3" then
		return false
	end
	if type(safeZoneParts) ~= "table" or #safeZoneParts == 0 then
		return false
	end
	for _, safeZonePart in ipairs(safeZoneParts) do
		if isPositionInsidePartBounds(position, safeZonePart) then
			return true
		end
	end
	return false
end

local function keepGhostOutsideSafeZones(match, currentPosition, desiredPosition)
	if typeof(desiredPosition) ~= "Vector3" then
		return desiredPosition
	end

	local safeZoneParts = collectMatchSafeZoneParts(match)
	if type(safeZoneParts) ~= "table" or #safeZoneParts == 0 then
		return desiredPosition
	end

	if not isPositionInsideSafeZones(desiredPosition, safeZoneParts) then
		return desiredPosition
	end

	if typeof(currentPosition) == "Vector3" and not isPositionInsideSafeZones(currentPosition, safeZoneParts) then
		return currentPosition
	end

	if typeof(currentPosition) == "Vector3" then
		return currentPosition
	end

	return desiredPosition
end

local function resolveHuntTargetPlayer(match, ghostState)
	local safeZoneParts = collectMatchSafeZoneParts(match)
	local preferredUserId = type(ghostState) == "table" and tonumber(ghostState.huntTargetUserId) or nil
	if preferredUserId then
		local preferredPlayer = Players:GetPlayerByUserId(preferredUserId)
		local preferredRoot = resolvePlayerRootPart(preferredPlayer)
		if preferredRoot and preferredRoot:IsA("BasePart") and not isRootInsideSafeZone(preferredRoot, safeZoneParts) then
			return preferredPlayer, preferredRoot, preferredUserId
		end
	end

	if type(match) ~= "table" then
		return nil, nil, nil
	end

	local bestPlayer = nil
	local bestRoot = nil
	local bestUserId = nil
	local bestDistance = math.huge
	local ghostPosition = nil
	if typeof(match.ghost) == "Instance" then
		local ok, pivot = pcall(function()
			return match.ghost:GetPivot()
		end)
		if ok and typeof(pivot) == "CFrame" then
			ghostPosition = pivot.Position
		end
	end

	for userId, playerState in pairs(match.playersByUserId or {}) do
		if type(playerState) == "table" and playerState.alive ~= false then
			local candidatePlayer = playerState.player or Players:GetPlayerByUserId(tonumber(userId) or 0)
			local candidateRoot = resolvePlayerRootPart(candidatePlayer)
			if candidateRoot and candidateRoot:IsA("BasePart") and not isRootInsideSafeZone(candidateRoot, safeZoneParts) then
				local distance = ghostPosition and (candidateRoot.Position - ghostPosition).Magnitude or 0
				if not bestRoot or distance < bestDistance then
					bestPlayer = candidatePlayer
					bestRoot = candidateRoot
					bestUserId = tonumber(userId) or (candidatePlayer and candidatePlayer.UserId) or nil
					bestDistance = distance
				end
			end
		end
	end

	return bestPlayer, bestRoot, bestUserId
end

local function resolveGhostFocusPosition(match, ghostState)
	local _, root = resolveHuntTargetPlayer(match, ghostState)
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function resolveGhostChasePosition(match, ghostState)
	if type(ghostState) ~= "table" or ghostState.huntActive ~= true then
		return nil, nil
	end

	local player, root, userId = resolveHuntTargetPlayer(match, ghostState)
	if not (root and root:IsA("BasePart")) then
		return nil, nil
	end

	local ignoreInstances = {}
	if typeof(player) == "Instance" and player:IsA("Player") and typeof(player.Character) == "Instance" then
		table.insert(ignoreInstances, player.Character)
	end
	if type(match) == "table" and typeof(match.ghost) == "Instance" then
		table.insert(ignoreInstances, match.ghost)
	end

	local groundY = root.Position.Y - ((root.Size.Y * 0.5) + 1)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = ignoreInstances
	raycastParams.IgnoreWater = true
	local rayResult = Workspace:Raycast(
		root.Position + Vector3.new(0, 6, 0),
		Vector3.new(0, -24, 0),
		raycastParams
	)
	if rayResult then
		groundY = rayResult.Position.Y
	end

	return Vector3.new(root.Position.X, groundY, root.Position.Z), userId
end

local function flattenLookVector(vector)
	if typeof(vector) ~= "Vector3" then
		return Vector3.zAxis
	end

	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.001 then
		return Vector3.zAxis
	end
	return flat.Unit
end

local function moveTowardsVector3(currentPosition, targetPosition, maxStep)
	if typeof(currentPosition) ~= "Vector3" then
		return targetPosition
	end
	if typeof(targetPosition) ~= "Vector3" then
		return currentPosition
	end

	local delta = targetPosition - currentPosition
	local distance = delta.Magnitude
	if distance <= 0.001 or maxStep <= 0 then
		return targetPosition
	end
	if distance <= maxStep then
		return targetPosition
	end
	return currentPosition + (delta.Unit * maxStep)
end

local function resolveGhostBottomOffset(ghostModel)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return nil
	end

	local pivot = ghostModel:GetPivot()
	local ok, boundsCFrame, boundsSize = pcall(function()
		return ghostModel:GetBoundingBox()
	end)
	if not ok or typeof(boundsCFrame) ~= "CFrame" or typeof(boundsSize) ~= "Vector3" then
		return nil
	end

	local bottomY = boundsCFrame.Position.Y - (boundsSize.Y * 0.5)
	return pivot.Position.Y - bottomY
end

local function resolveGhostFloorY(match, ghostModel, position)
	if typeof(position) ~= "Vector3" then
		return nil
	end

	local ignoreInstances = {}
	if type(match) == "table" and typeof(match.container) == "Instance" then
		for _, playerState in pairs(match.playersByUserId or {}) do
			local player = type(playerState) == "table" and playerState.player or nil
			if typeof(player) == "Instance" and player:IsA("Player") and typeof(player.Character) == "Instance" then
				table.insert(ignoreInstances, player.Character)
			end
		end
	end
	if typeof(ghostModel) == "Instance" then
		table.insert(ignoreInstances, ghostModel)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = ignoreInstances
	raycastParams.IgnoreWater = true
	local rayResult = Workspace:Raycast(
		Vector3.new(position.X, position.Y + 2, position.Z),
		Vector3.new(0, -20, 0),
		raycastParams
	)
	if rayResult then
		return rayResult.Position.Y
	end

	return nil
end

local function resetGhostVisualMotion(match, targetPosition, roomId)
	if type(match) ~= "table" then
		return
	end

	match.ghostVisualCurrentPosition = targetPosition
	match.ghostVisualTargetPosition = targetPosition
	match.ghostVisualCurrentRoomId = roomId
	match.ghostVisualTargetRoomId = roomId
	match.ghostVisualLastSyncAt = Workspace:GetServerTimeNow()
end

local function cloneMotionProfile(baseMotion)
	local clone = {}
	for key, value in pairs(baseMotion or {}) do
		clone[key] = value
	end
	return clone
end

local function resolveGhostMotionProfile(ghostModel, stateName)
	local motion = cloneMotionProfile(GHOST_VISUAL_MOTION_BY_STATE[stateName] or GHOST_VISUAL_MOTION_BY_STATE.Roaming)
	local ghostTypeName = resolveGhostVisualTypeName(ghostModel)
	local ghostTypeToken = normalizeToken(ghostTypeName)

	if ghostTypeName and resolveGhostTemplateConfigValue(GHOST_TEMPLATE_GROUNDED, ghostTypeName) == true then
		motion.bobAmplitude = 0
	end

	if ghostTypeToken == "pocong" then
		if stateName == "Idle" then
			motion.bobAmplitude = 0
			motion.bobFrequency = 1.6
			motion.swayAmplitude = 0.012
			motion.pitchDegrees = 1.6
			motion.rollDegrees = 0.5
			motion.yawDegrees = 1.25
			motion.motionStyle = nil
			motion.hopSharpness = 1.4
		elseif stateName == "Roaming" then
			motion.bobAmplitude = 0
			motion.bobFrequency = 2.85
			motion.swayAmplitude = 0.014
			motion.pitchDegrees = 7.5
			motion.rollDegrees = 0.75
			motion.yawDegrees = 1.2
			motion.motionStyle = nil
			motion.hopSharpness = 1.85
			motion.forwardLunge = 0.025
		elseif stateName == "Manifestation" then
			motion.bobAmplitude = 0
			motion.bobFrequency = 2.2
			motion.swayAmplitude = 0.01
			motion.pitchDegrees = 5
			motion.rollDegrees = 0.4
			motion.yawDegrees = 1
			motion.motionStyle = nil
			motion.hopSharpness = 1.65
		elseif stateName == "Hunting" then
			motion.bobAmplitude = 0
			motion.bobFrequency = 4.8
			motion.swayAmplitude = 0.012
			motion.pitchDegrees = 9.5
			motion.rollDegrees = 0.9
			motion.yawDegrees = 0.4
			motion.motionStyle = nil
			motion.hopSharpness = 2.15
			motion.forwardLunge = 0.085
		elseif stateName == "Cooldown" then
			motion.bobAmplitude = 0
			motion.bobFrequency = 1.45
			motion.swayAmplitude = 0.01
			motion.pitchDegrees = 2.5
			motion.rollDegrees = 0.45
			motion.yawDegrees = 1
			motion.motionStyle = nil
			motion.hopSharpness = 1.3
		end
	end

	return motion
end

local function computeGhostVisualCFrame(match, ghostModel, targetPosition, ghostState, stateName, seedValue)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") or typeof(targetPosition) ~= "Vector3" then
		return nil
	end

	local motion = resolveGhostMotionProfile(ghostModel, stateName)
	local ghostTypeName = resolveGhostVisualTypeName(ghostModel)
	local currentPivot = ghostModel:GetPivot()
	local focusPosition = resolveGhostFocusPosition(match, ghostState)
	local lookVector = flattenLookVector(currentPivot.LookVector)
	local travelVector = targetPosition - currentPivot.Position
	local travelDirection = flattenLookVector(travelVector)
	local remainingDistance = tonumber(ghostModel:GetAttribute("VisualTargetDistance")) or 0
	if typeof(focusPosition) == "Vector3" then
		lookVector = flattenLookVector(focusPosition - targetPosition)
	elseif travelVector.Magnitude > 0.02 then
		lookVector = travelDirection
	end

	local rightVector = Vector3.new(-lookVector.Z, 0, lookVector.X)
	if rightVector.Magnitude < 0.001 then
		rightVector = Vector3.xAxis
	end
	rightVector = rightVector.Unit

	local serverTime = Workspace:GetServerTimeNow()
	local phaseOffset = (tonumber(seedValue) or 0) * 0.037
	local bobPhase = (serverTime + phaseOffset) * (motion.bobFrequency or 1)
	local swayPhase = (serverTime + phaseOffset + 0.6) * (motion.swayFrequency or 1)
	local yawPhase = (serverTime + phaseOffset + 1.3) * 0.8
	local movementAlpha = math.clamp(math.max(travelVector.Magnitude * 10, remainingDistance * 0.35), 0, 1)
	local bobWave = math.abs(math.sin(bobPhase))
	if motion.motionStyle == "pocong_hop" then
		bobWave = math.max(0, math.sin(bobPhase))
		bobWave = bobWave ^ (motion.hopSharpness or 1.6)
	end
	local bobAmplitude = (motion.bobAmplitude or 0) * math.max(0.3, movementAlpha)
	local swayAmplitude = (motion.swayAmplitude or 0) * math.max(0.25, movementAlpha)
	local bobOffset = bobWave * bobAmplitude
	local maxHoverHeight = ghostTypeName and resolveGhostTemplateConfigValue(GHOST_TEMPLATE_MAX_HOVER_HEIGHT, ghostTypeName) or 0.05
	if ghostTypeName and resolveGhostTemplateConfigValue(GHOST_TEMPLATE_GROUNDED, ghostTypeName) == true then
		bobOffset = 0
	else
		bobOffset = math.clamp(bobOffset, 0, math.max(0, maxHoverHeight or 0.05))
	end
	local swayOffset = math.sin(swayPhase) * swayAmplitude
	local forwardOffset = 0
	if motion.forwardLunge then
		forwardOffset = bobWave * motion.forwardLunge * math.max(0.35, movementAlpha)
	end

	local position = targetPosition
		+ Vector3.new(0, bobOffset, 0)
		+ (rightVector * swayOffset)
		+ (lookVector * forwardOffset)

	local floorY = resolveGhostFloorY(match, ghostModel, position)
	local bottomOffset = resolveGhostBottomOffset(ghostModel)
	if type(floorY) == "number" and type(bottomOffset) == "number" then
		local desiredHover = (ghostTypeName and resolveGhostTemplateConfigValue(GHOST_TEMPLATE_GROUNDED, ghostTypeName) == true) and 0 or bobOffset
		position = Vector3.new(position.X, floorY + desiredHover + bottomOffset, position.Z)
	end

	local pitch = math.rad((math.sin(bobPhase) * (motion.pitchDegrees or 0)) * math.max(0.35, movementAlpha))
	local roll = math.rad((math.sin(swayPhase) * (motion.rollDegrees or 0)) * math.max(0.3, movementAlpha))
	local yaw = math.rad((math.sin(yawPhase) * (motion.yawDegrees or 0)) * math.max(0.25, movementAlpha))

	return CFrame.lookAt(position, position + lookVector, Vector3.yAxis) * CFrame.Angles(pitch, yaw, roll)
end

local function findNamedBasePart(root, ...)
	if typeof(root) ~= "Instance" then
		return nil
	end

	local tokens = {}
	for _, value in ipairs({ ... }) do
		local token = normalizeToken(value)
		if token then
			tokens[token] = true
		end
	end

	if next(tokens) == nil then
		return nil
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local token = normalizeToken(descendant.Name)
			if token and tokens[token] then
				return descendant
			end
		end
	end

	return nil
end

local function resolveSpawnPart(container)
	if not container then
		return nil
	end
	local direct = container:FindFirstChild("GhostSpawn") or container:FindFirstChild("GhostSpawns")
	if direct then
		local parts = collectSpawnParts(direct)
		if #parts > 0 then
			return parts[1]
		end
	end
	local fallbackFolder = container:FindFirstChild("SpawnPoints") or container:FindFirstChild("GhostSpawnPoints")
	if fallbackFolder then
		local parts = collectSpawnParts(fallbackFolder)
		if #parts > 0 then
			return parts[1]
		end
	end
	local parts = collectSpawnParts(container)
	if #parts > 0 then
		return parts[1]
	end
	return nil
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

local function resolveMatchContainer(match)
	if type(match) ~= "table" then
		return nil
	end
	local matchId = match.matchId or match.id
	if not matchId then
		return nil
	end
	local activeMatches = ensureActiveMatchesFolder()
	local expectedName = "Match_" .. tostring(matchId)
	local container = match.container
	if container and (not container:IsA("Folder") or container.Parent ~= activeMatches or container.Name ~= expectedName) then
		container = nil
	end
	if not container then
		container = activeMatches:FindFirstChild(expectedName)
	end
	if not container then
		container = Instance.new("Folder")
		container.Name = expectedName
		container.Parent = activeMatches
	end
	match.container = container
	return container, activeMatches
end

local function ensureGhostPlacement(match)
	if not (match and match.ghost) then
		return false
	end
	local container = match.container
	if not container then
		container = resolveMatchContainer(match)
	end
	if not container then
		return false
	end
	if match.ghost.Parent ~= container then
		local parentOk = tryParentGhostModel(match.ghost, container)
		if not parentOk then
			return false
		end
	end
	return true
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._ghostService = GhostService.new(self._state, self._deps)
	self._investigationToolService = resolveInvestigationToolService(self._deps)
	self._matchSystem = Services.Get(self._deps, "MatchSystem")
	self._mapDatabase = loadMapDatabase()
	self._ghostDatabase = loadGhostDatabase()
	self._studioGhostPreviewFolder = nil
	self._visualSyncConnection = nil
	self._visualSyncAccumulator = 0
	return self
end

function Service:Init()
	self._ghostService:Init()
end

function Service:_destroyStudioLobbyGhostPreview()
	if self._studioGhostPreviewFolder and self._studioGhostPreviewFolder.Parent then
		self._studioGhostPreviewFolder:Destroy()
	end
	self._studioGhostPreviewFolder = nil
end

function Service:_ensureStudioLobbyGhostPreview()
	if not RunService:IsStudio() then
		return
	end
	if ReplicatedStorage:GetAttribute(STUDIO_GHOST_PREVIEW_ENABLED_ATTRIBUTE) ~= true then
		self:_destroyStudioLobbyGhostPreview()
		return
	end

	local lobbyRoot, spawnParts = resolveStudioLobbyPreviewSpawnParts()
	if not lobbyRoot or #spawnParts == 0 then
		return
	end

	local ghostTypes = resolveStudioLobbyPreviewGhostTypes()
	if #ghostTypes == 0 then
		return
	end

	self:_destroyStudioLobbyGhostPreview()

	local folder = Instance.new("Folder")
	folder.Name = STUDIO_GHOST_PREVIEW_FOLDER_NAME
	folder.Parent = lobbyRoot
	self._studioGhostPreviewFolder = folder

	local spawnCenter = resolveStudioLobbyPreviewCenter(spawnParts)
	local previewFloorY = resolveStudioLobbyPreviewFloorY(spawnParts)
	if typeof(spawnCenter) ~= "Vector3" or type(previewFloorY) ~= "number" then
		return
	end

	local origin = Vector3.new(spawnCenter.X, previewFloorY, spawnCenter.Z)
	local columns = math.min(3, #ghostTypes)
	local rowCount = math.ceil(#ghostTypes / columns)
	local lookTarget = origin + Vector3.new(0, 2.5, 0)

	for index, ghostType in ipairs(ghostTypes) do
		local row = math.floor((index - 1) / columns)
		local column = (index - 1) % columns
		local ghostsRemaining = #ghostTypes - (row * columns)
		local itemsInRow = math.min(columns, ghostsRemaining)
		local offsetX = (row - ((rowCount - 1) * 0.5)) * 10
		local offsetZ = (column - ((itemsInRow - 1) * 0.5)) * 10
		local previewPosition = origin + Vector3.new(offsetX, 0, offsetZ)
		local previewCFrame = CFrame.lookAt(previewPosition, lookTarget)
		local ghostModel = createGhostFromTemplate(previewCFrame, ghostType)
		if not ghostModel then
			ghostModel = createVisibleGhostPlaceholder(previewCFrame, ghostType)
		end

		ghostModel.Name = string.format("Preview_%s", tostring(ghostType))
		ghostModel:SetAttribute("StudioGhostPreview", true)
		ghostModel.Parent = folder
		if ghostModel.PrimaryPart then
			local groundedPosition = resolveGhostGroundPosition({ ghost = ghostModel }, previewPosition) or previewPosition
			ghostModel:PivotTo(CFrame.lookAt(groundedPosition, lookTarget))
		end
		self:_applyGhostVisualState({ ghost = ghostModel }, { state = "Manifestation" })
		attachStudioGhostPreviewLabel(ghostModel, ghostType)
	end
end

function Service:Start()
	self._ghostService:Start()
	self:_ensureStudioLobbyGhostPreview()
	if self._visualSyncConnection then
		self._visualSyncConnection:Disconnect()
	end
	self._visualSyncAccumulator = 0
	self._visualSyncConnection = RunService.Heartbeat:Connect(function(deltaTime)
		self._visualSyncAccumulator += deltaTime
		if self._visualSyncAccumulator < GHOST_VISUAL_SYNC_INTERVAL then
			return
		end

		self._visualSyncAccumulator = 0
		local sessions = self._state:Get("sessions") or {}
		for matchId in pairs(sessions) do
			self:_syncGhostVisualByMatch(matchId)
		end
	end)
end

function Service:Stop()
	self:_destroyStudioLobbyGhostPreview()
	if self._visualSyncConnection then
		self._visualSyncConnection:Disconnect()
		self._visualSyncConnection = nil
	end
	self._visualSyncAccumulator = 0
	self._ghostService:Stop()
end

function Service:_getMatchSystem()
	if self._matchSystem then
		return self._matchSystem
	end
	self._matchSystem = Services.Get(self._deps, "MatchSystem")
	return self._matchSystem
end

function Service:_resolveLiveMatch(matchOrId)
	local matchId = resolveMatchId(matchOrId)
	local matchData = type(matchOrId) == "table" and matchOrId or nil
	if not matchId then
		return nil, nil
	end

	if type(matchData) == "table" and matchData.playersByUserId and matchData.history then
		return matchData, matchId
	end

	local matchSystem = self:_getMatchSystem()
	if not matchSystem then
		return matchData, matchId
	end

	if type(matchSystem.GetLiveMatch) == "function" then
		return matchSystem:GetLiveMatch(matchId) or matchData, matchId
	end
	if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
		return matchSystem.Service:GetLiveMatch(matchId) or matchData, matchId
	end

	return matchData, matchId
end

function Service:_getMapDefinition(mapId)
	if type(mapId) ~= "string" or mapId == "" then
		return nil
	end
	local direct = self._mapDatabase[mapId]
	if type(direct) == "table" then
		return direct
	end
	local token = string.lower(mapId:gsub("[%s_%-%.]+", ""))
	for key, value in pairs(self._mapDatabase) do
		if string.lower(tostring(key):gsub("[%s_%-%.]+", "")) == token and type(value) == "table" then
			return value
		end
	end
	return nil
end

function Service:_buildGhostPayload(match, payload)
	local incoming = type(payload) == "table" and payload or {}
	local mapDefinition = self:_getMapDefinition(match and (match.mapId or match.map) or incoming.mapId)
	local ghostType = incoming.ghostType or (match and match.ghostType) or "Pocong"
	local ghostTypeData = incoming.ghostTypeData or self._ghostDatabase[ghostType]

	local roomIds = incoming.roomIds
		or (match and match.roomIds)
		or (mapDefinition and mapDefinition.rooms)
		or (mapDefinition and mapDefinition.ghostRoomCandidates)
		or {}

	return {
		roomIds = deepCopy(roomIds),
		roomGraph = incoming.roomGraph,
		roomSpawnRules = incoming.roomSpawnRules,
		ghostType = ghostType,
		ghostTypeData = ghostTypeData,
		personality = incoming.personality,
		personalityType = incoming.personalityType,
		evidenceSet = incoming.evidenceSet,
		initialAggression = incoming.initialAggression,
		difficulty = incoming.difficulty or (match and match.difficulty),
		mode = incoming.mode or incoming.gameMode or (match and (match.mode or match.gameMode)),
		gameMode = incoming.gameMode or incoming.mode or (match and (match.gameMode or match.mode)),
		difficultyProfile = deepCopy(incoming.difficultyProfile or (match and match.difficultyProfile) or {}),
		favoriteRoomId = incoming.favoriteRoomId,
		now = incoming.now,
	}
end

function Service:_resolveRoomAnchor(match, roomId)
	if type(match) ~= "table" or type(roomId) ~= "string" or roomId == "" then
		return nil
	end

	local container = match.container
	if typeof(container) ~= "Instance" then
		return nil
	end

	local roomsRoot = container:FindFirstChild("Rooms", true) or container
	return findNamedBasePart(roomsRoot, roomId, "Room_" .. roomId)
		or findNamedBasePart(container, roomId, "Room_" .. roomId)
end

function Service:_applyGhostVisualState(match, ghostState)
	if type(match) ~= "table" or typeof(match.ghost) ~= "Instance" then
		return
	end

	local stateName, actualStateName, overrideStateName = resolveGhostVisualStateName(ghostState)
	local transparency = GHOST_VISUAL_TRANSPARENCY_BY_STATE[stateName] or 0.35

	match.ghost:SetAttribute("RuntimeGhostState", tostring(stateName or "Unknown"))
	match.ghost:SetAttribute("RuntimeGhostStateActual", tostring(actualStateName or "Unknown"))
	if overrideStateName then
		match.ghost:SetAttribute("RuntimeGhostStateOverride", overrideStateName)
	else
		match.ghost:SetAttribute("RuntimeGhostStateOverride", nil)
	end

	for _, descendant in ipairs(match.ghost:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if shouldHideGhostControlPart(descendant) then
				descendant.Transparency = 1
			else
				descendant.Transparency = transparency
			end
		end
	end
end

function Service:_tryPromoteGhostVisualVariant(match, ghostState)
	if type(match) ~= "table" or typeof(match.ghost) ~= "Instance" then
		return false
	end

	local currentVisualGhostType = resolveGhostVisualTypeName(match.ghost) or match.ghostType
	local preferredTemplate, preferredVisualGhostType = resolveGhostModelTemplate(currentVisualGhostType, {
		ghostState = ghostState,
		initialAggression = tonumber(match.initialAggression),
		personalityType = type(ghostState) == "table" and type(ghostState.personality) == "table" and ghostState.personality.type or nil,
	})
	if typeof(preferredTemplate) ~= "Instance" then
		return false
	end
	if type(preferredVisualGhostType) ~= "string" or preferredVisualGhostType == "" then
		preferredVisualGhostType = preferredTemplate.Name
	end
	if preferredVisualGhostType == currentVisualGhostType then
		return false
	end

	local previousGhost = match.ghost
	local currentPivot = previousGhost:GetPivot()
	local logicalGhostType = match.ghostType or previousGhost:GetAttribute("GhostType") or currentVisualGhostType
	local promotedGhost = createGhostFromTemplate(currentPivot, preferredVisualGhostType, {
		forcedTemplate = preferredTemplate,
		logicalGhostType = logicalGhostType,
	})
	if typeof(promotedGhost) ~= "Instance" then
		return false
	end

	for attributeName, attributeValue in pairs(previousGhost:GetAttributes()) do
		if attributeName ~= "GhostType" and attributeName ~= "VisualGhostType" and attributeName ~= "VisualTemplateName" then
			promotedGhost:SetAttribute(attributeName, attributeValue)
		end
	end

	local parentTarget = previousGhost.Parent
	if typeof(parentTarget) ~= "Instance" then
		promotedGhost:Destroy()
		return false
	end
	local parentOk = pcall(function()
		promotedGhost.Parent = parentTarget
	end)
	if not parentOk then
		promotedGhost:Destroy()
		return false
	end

	match.ghost = promotedGhost
	previousGhost:Destroy()
	match.ghostVisualCurrentPosition = currentPivot.Position
	return true
end

function Service:_syncGhostVisual(match, ghostState)
	if type(match) ~= "table" or typeof(match.ghost) ~= "Instance" or type(ghostState) ~= "table" then
		return false
	end

	self:_tryPromoteGhostVisualVariant(match, ghostState)
	ensureGhostPlacement(match)
	local roomId = ghostState.currentRoomId or ghostState.favoriteRoomId
	match.ghost:SetAttribute("CurrentRoomId", ghostState.currentRoomId)
	match.ghost:SetAttribute("FavoriteRoomId", ghostState.favoriteRoomId)
	local roomAnchor = self:_resolveRoomAnchor(match, roomId)
	if match.ghost.PrimaryPart then
		local chasePosition, chaseTargetUserId = resolveGhostChasePosition(match, ghostState)
		local targetPosition = nil
		if typeof(chasePosition) == "Vector3" then
			targetPosition = resolveGhostGroundPosition(match, chasePosition) or chasePosition
		elseif roomAnchor then
			targetPosition = resolveGhostGroundPosition(match, roomAnchor)
		end

		match.ghost:SetAttribute("VisualTargetMode", chasePosition and "Player" or "Room")
		match.ghost:SetAttribute("ChaseTargetUserId", chaseTargetUserId)

		if typeof(targetPosition) ~= "Vector3" then
			self:_applyGhostVisualState(match, ghostState)
			return true
		end

		local stateName = select(1, resolveGhostVisualStateName(ghostState)) or "Roaming"
		local now = Workspace:GetServerTimeNow()
		local lastSyncAt = tonumber(match.ghostVisualLastSyncAt) or now
		local deltaTime = math.clamp(now - lastSyncAt, 1 / 60, 0.25)
		match.ghostVisualLastSyncAt = now

		local currentPosition = match.ghostVisualCurrentPosition
		if typeof(currentPosition) ~= "Vector3" then
			currentPosition = match.ghost:GetPivot().Position
		end

		targetPosition = keepGhostOutsideSafeZones(match, currentPosition, targetPosition)

		match.ghostVisualTargetPosition = targetPosition
		match.ghostVisualTargetRoomId = roomId

		local distanceToTarget = (targetPosition - currentPosition).Magnitude
		local roomChanged = match.ghostVisualCurrentRoomId ~= roomId
		local effectiveStateName = stateName
		if (stateName == "Idle" or stateName == "Cooldown") and (distanceToTarget > 0.75 or roomChanged) then
			effectiveStateName = "Roaming"
		end

		local moveSpeed = GHOST_VISUAL_MOVE_SPEED_BY_STATE[effectiveStateName] or GHOST_VISUAL_MOVE_SPEED_BY_STATE.Roaming

		local resolvedPosition = nil
		if typeof(match.ghostVisualCurrentPosition) ~= "Vector3" then
			resolvedPosition = targetPosition
		else
			local maxStep = moveSpeed * deltaTime
			if roomChanged and distanceToTarget > 0.1 then
				resolvedPosition = moveTowardsVector3(currentPosition, targetPosition, maxStep)
			else
				resolvedPosition = moveTowardsVector3(currentPosition, targetPosition, maxStep)
			end
		end

		resolvedPosition = keepGhostOutsideSafeZones(match, currentPosition, resolvedPosition)
		if typeof(resolvedPosition) ~= "Vector3" then
			resolvedPosition = currentPosition
		end

		match.ghostVisualCurrentPosition = resolvedPosition
		if (targetPosition - resolvedPosition).Magnitude <= 0.15 then
			match.ghostVisualCurrentRoomId = roomId
		end

		match.ghost:SetAttribute("VisualMoveSpeed", moveSpeed)
		match.ghost:SetAttribute("VisualTargetDistance", math.floor(((targetPosition - resolvedPosition).Magnitude * 100) + 0.5) / 100)
		match.ghost:SetAttribute("VisualMotionState", effectiveStateName)
		local visualCFrame = computeGhostVisualCFrame(match, match.ghost, resolvedPosition, ghostState, effectiveStateName, match.ghostSeed or match.matchId)
		match.ghost:PivotTo(visualCFrame or CFrame.new(resolvedPosition))
	end

	self:_applyGhostVisualState(match, ghostState)
	return true
end

function Service:_syncGhostVisualByMatch(matchOrId)
	local liveMatch, matchId = self:_resolveLiveMatch(matchOrId)
	if not matchId then
		return false
	end

	local ghostState = self._ghostService:GetGhostState(matchId)
	if type(liveMatch) == "table" and type(ghostState) == "table" then
		return self:_syncGhostVisual(liveMatch, ghostState)
	end
	return false
end

function Service:_ensureGhostReady(matchOrId, payload)
	local liveMatch, matchId = self:_resolveLiveMatch(matchOrId)
	if not matchId then
		return nil, nil, "missing_match_id"
	end

	local lastReason = nil
	for _ = 1, GHOST_RETRY_COUNT do
		if type(liveMatch) == "table" and not liveMatch.ghost then
			local _, initializeReason = self:InitializeMatch(liveMatch)
			if initializeReason then
				lastReason = initializeReason
			end
		end

		if self._ghostService:GetGhostState(matchId) == nil then
			local spawnedSession = self._ghostService:SpawnGhost(matchId, self:_buildGhostPayload(liveMatch, payload))
			if not spawnedSession then
				lastReason = lastReason or "spawn_returned_nil"
			end
		end

		if type(liveMatch) == "table" and liveMatch.ghost then
			ensureGhostPlacement(liveMatch)
			if liveMatch.ghostSpawnPart == nil then
				self:SelectGhostRoom(liveMatch)
			end
		end

		if self._ghostService:GetGhostState(matchId) ~= nil then
			self:_syncGhostVisualByMatch(liveMatch or matchId)
			return liveMatch, matchId, nil
		end

		task.wait(GHOST_RETRY_WAIT)
		liveMatch = select(1, self:_resolveLiveMatch(matchId)) or liveMatch
	end

	warn(string.format("[GhostSystem] Failed to ensure ghost for match %s (%s)", tostring(matchId), tostring(lastReason or "unknown")))
	return liveMatch, matchId, lastReason or "ghost_spawn_failed"
end

function Service:InitGhost(matchId, payload)
	local liveMatch, _, err = self:_ensureGhostReady(matchId, payload)
	if err then
		return nil, err
	end
	return liveMatch
end

function Service:SpawnGhost(match, payload)
	local liveMatch, _, err = self:_ensureGhostReady(match, payload)
	if err then
		return nil, err
	end
	return liveMatch
end

function Service:SelectGhostRoom(match)
	if type(match) ~= "table" or not match.ghost then
		return nil, "missing_ghost"
	end
	if not ensureGhostPlacement(match) then
		return nil, "missing_container"
	end
	local container = match.container
	if not container then
		return nil, "missing_container"
	end
	local ghostSpawns = container:FindFirstChild("GhostSpawns") or container:FindFirstChild("GhostSpawnZones")
	local spawnParts = collectSpawnParts(ghostSpawns)
	if #spawnParts == 0 then
		local fallbackSpawn = resolveSpawnPart(container)
		if fallbackSpawn then
			spawnParts = { fallbackSpawn }
		end
	end
	if #spawnParts == 0 then
		return nil, "no_spawn_parts"
	end
	local seed = tonumber(match.ghostSeed) or os.time()
	local rng = Random.new(seed + 1)
	local selectedPart = spawnParts[rng:NextInteger(1, #spawnParts)]
	if not selectedPart then
		return nil, "missing_selected_part"
	end
	local ghostRoom = selectedPart.Parent or ghostSpawns
	match.ghostRoom = ghostRoom
	match.ghostSpawnPart = selectedPart
	if match.ghost.PrimaryPart then
		local targetPosition = resolveGhostGroundPosition(match, selectedPart)
		match.ghost:PivotTo(CFrame.new(targetPosition))
		resetGhostVisualMotion(match, targetPosition, ghostRoom and ghostRoom.Name or nil)
	end
	return selectedPart
end

function Service:InitializeMatch(match)
	if type(match) ~= "table" then
		return nil, "invalid_match"
	end
	if match.ghost then
		return match.ghost
	end
	local matchId = match.matchId or match.id
	if not matchId then
		return nil, "missing_match_id"
	end
	local seed = tonumber(match.ghostSeed) or os.time()
	local rng = Random.new(seed)
	local forcedGhostType = resolveForcedStudioGhostType()
	local ghostType = forcedGhostType
		or match.ghostType
		or DEFAULT_GHOST_TYPES[rng:NextInteger(1, #DEFAULT_GHOST_TYPES)]
	match.ghostType = ghostType

	local container = resolveMatchContainer(match)
	if not container then
		return nil, "missing_match_container"
	end

	local spawnPart = resolveSpawnPart(container)
	local spawnCFrame = spawnPart and spawnPart.CFrame or CFrame.new(0, 5, 0)

	local ghostModel = createGhostFromTemplate(spawnCFrame, ghostType, {
		logicalGhostType = ghostType,
		initialAggression = tonumber(match.initialAggression),
		personalityType = match.personalityType,
	})
		or createVisibleGhostPlaceholder(spawnCFrame, ghostType)
	local parentOk, parentErr = tryParentGhostModel(ghostModel, container)
	if not parentOk then
		if ghostModel and ghostModel.Parent == nil then
			pcall(function()
				ghostModel:Destroy()
			end)
		end
		ghostModel = createVisibleGhostPlaceholder(spawnCFrame, ghostType)
		local fallbackOk, fallbackErr = tryParentGhostModel(ghostModel, container)
		if not fallbackOk then
			return nil, string.format("ghost_parent_failed:%s|fallback=%s", tostring(parentErr), tostring(fallbackErr))
		end
		setGhostTraceState("InitializeMatchFallback", string.format(
			"match=%s;ghostType=%s;reason=%s",
			tostring(matchId),
			tostring(ghostType),
			tostring(parentErr)
		))
	end
	setGhostTraceState("InitializeMatch", string.format(
		"match=%s;ghostType=%s;model=%s;placeholder=%s",
		tostring(matchId),
		tostring(ghostType),
		tostring(ghostModel.Name),
		tostring(ghostModel:GetAttribute("PlaceholderVisual"))
	))
	traceGhost("InitializeMatch", {
		matchId = matchId,
		ghostType = ghostType,
		modelName = ghostModel.Name,
		container = container:GetFullName(),
		placeholder = ghostModel:GetAttribute("PlaceholderVisual"),
	})

	match.ghost = ghostModel

	self:SelectGhostRoom(match)

	local ghostState = self._ghostService and self._ghostService.GetGhostState and self._ghostService:GetGhostState(matchId) or nil
	if type(ghostState) == "table" then
		self:_syncGhostVisual(match, ghostState)
	else
		self:_applyGhostVisualState(match, {
			state = "Idle",
			currentRoomId = match.ghostRoom and match.ghostRoom.Name or nil,
			favoriteRoomId = match.ghostRoom and match.ghostRoom.Name or nil,
		})
		match.ghost:SetAttribute("CurrentRoomId", match.ghostRoom and match.ghostRoom.Name or nil)
		match.ghost:SetAttribute("FavoriteRoomId", match.ghostRoom and match.ghostRoom.Name or nil)
		match.ghost:SetAttribute("VisualMotionState", "Idle")
		match.ghost:SetAttribute("VisualTargetMode", "Room")
	end

	return ghostModel
end

function Service:OnSanityCritical(matchId)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self:_startProtectedHunt(matchId, {}, os.clock())
end

function Service:OnAggressionThreshold(matchId)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self:_startProtectedHunt(matchId, {}, os.clock())
end

function Service:_startProtectedHunt(match, snapshot, now)
	local _, authoritativeMatchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end

	if self._investigationToolService and type(self._investigationToolService.TryConsumeHuntProtection) == "function" then
		local ghostState = self._ghostService:GetGhostState(authoritativeMatchId) or {}
		local ok, blocked = pcall(function()
			return self._investigationToolService:TryConsumeHuntProtection(authoritativeMatchId, {
				now = now or os.clock(),
				roomId = ghostState.currentRoomId or ghostState.favoriteRoomId or (snapshot and snapshot.roomId),
				snapshot = snapshot,
			})
		end)
		if ok and blocked == true then
			return false, "hunt_blocked"
		end
	end

	local result = self._ghostService:StartHunt(authoritativeMatchId, snapshot or {}, now)
	self:_syncGhostVisualByMatch(authoritativeMatchId)
	return result
end

function Service:TransitionGhostState(matchId, stateName, now, snapshot)
	if not matchId then
		return nil, "missing_match_id"
	end
	local _, authoritativeMatchId, err = self:_ensureGhostReady(matchId)
	if err then
		return nil, err
	end
	local result = self._ghostService:TransitionGhostState(authoritativeMatchId, stateName, now, snapshot)
	self:_syncGhostVisualByMatch(authoritativeMatchId)
	return result
end

function Service:TickGhost(match, snapshot, dt, now)
	local liveMatch, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	local result = self._ghostService:TickGhost(matchId, snapshot, dt, now)
	if type(liveMatch) == "table" then
		self:_syncGhostVisual(liveMatch, self._ghostService:GetGhostState(matchId))
	end
	return result
end

function Service:StartHunt(match, snapshot, now)
	return self:_startProtectedHunt(match, snapshot, now)
end

function Service:TriggerHunt(match, snapshot, now)
	local liveMatch, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self:_startProtectedHunt(matchId, snapshot or (liveMatch and liveMatch.snapshot) or {}, now)
end

function Service:ForceHunt(match, snapshot, now)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	local result = self._ghostService:StartHunt(matchId, snapshot or {}, now)
	self:_syncGhostVisualByMatch(matchId)
	return result
end

function Service:EndHunt(match, now)
	local _, matchId = self:_resolveLiveMatch(match)
	if not matchId then
		return nil, "missing_match_id"
	end
	local result = self._ghostService:EndHunt(matchId, now)
	self:_syncGhostVisualByMatch(matchId)
	return result
end

function Service:GetGhostState(match)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self._ghostService:GetGhostState(matchId)
end

function Service:DespawnGhost(match)
	local matchData, matchId = self:_resolveLiveMatch(match)
	if not matchId then
		warn("[GhostSystem] Missing match id for DespawnGhost")
		return nil, "missing_match_id"
	end

	if matchData and matchData.ghost then
		local ghostModel = matchData.ghost
		matchData.ghost = nil
		matchData.ghostRoom = nil
		matchData.ghostSpawnPart = nil
		matchData.ghostVisualCurrentPosition = nil
		matchData.ghostVisualTargetPosition = nil
		matchData.ghostVisualCurrentRoomId = nil
		matchData.ghostVisualTargetRoomId = nil
		matchData.ghostVisualLastSyncAt = nil
		if ghostModel and ghostModel.Parent then
			for _, part in ipairs(ghostModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
			ghostModel:Destroy()
		end
	end

	return self._ghostService:DespawnGhost(matchId)
end

function Service:ApplyDirectorEvent(match, eventName, payload)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self._ghostService:ApplyDirectorEvent(matchId, eventName, payload)
end

function Service:ForceManifest(match, now)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	local result = self._ghostService:ForceManifest(matchId, now)
	self:_syncGhostVisualByMatch(matchId)
	return result
end

return Service
