local GhostService = require(script.Parent.GhostService)
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local InsertService = game:GetService("InsertService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local GHOST_TRACE_ATTRIBUTE = "PasrahGhostTrace"
local GHOST_FORCE_VISUAL_STATE_ATTRIBUTE = "PasrahForceGhostVisualState"
local STUDIO_GHOST_PREVIEW_LABEL_TEMPLATE_PATH = { "Assets", "VisualTemplates", "GhostVisuals", "StudioGhostPreviewLabelTemplate" }

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
local DEFAULT_GHOST_TEMPLATE_VISUAL_ROTATIONS = {}

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

local function cloneStudioGhostPreviewLabelTemplate()
	local template = resolveChildPath(ReplicatedStorage, STUDIO_GHOST_PREVIEW_LABEL_TEMPLATE_PATH)
	if template and template:IsA("BillboardGui") then
		local clone = template:Clone()
		clone.Name = "PreviewLabel"
		return clone
	end
	return nil
end

local DEFAULT_GHOST_TEMPLATE_ROOT_SIZES = {}

local DEFAULT_GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES = {}

local DEFAULT_GHOST_TEMPLATE_TARGET_BOUNDS = {
	Kuntilanak = Vector3.new(7.4, 7.4, 7.4),
	KuntilanakAggressive = Vector3.new(7.4, 7.4, 7.4),
	Genderuwo = Vector3.new(7.4, 7.4, 7.4),
	Leak = Vector3.new(7.4, 7.4, 7.4),
	Pocong = Vector3.new(7.4, 7.4, 7.4),
	Tuyul = Vector3.new(7.4, 7.4, 7.4),
	Banaspati = Vector3.new(7.4, 7.4, 7.4),
	Jerangkong = Vector3.new(7.4, 7.4, 7.4),
	WeweGombel = Vector3.new(7.4, 7.4, 7.4),
	Palasik = Vector3.new(7.4, 7.4, 7.4),
	SilumanUlar = Vector3.new(7.4, 7.4, 7.4),
	SundelBolong = Vector3.new(7.4, 7.4, 7.4),
	HantuTanah = Vector3.new(7.4, 7.4, 7.4),
}

local DEFAULT_GHOST_TEMPLATE_MAX_HOVER_HEIGHT = {
	Kuntilanak = 0.05,
	KuntilanakAggressive = 0.05,
	Pocong = 0.0,
	Genderuwo = 0.0,
	Leak = 0.0,
}

local DEFAULT_GHOST_TEMPLATE_GROUNDED = {
	Pocong = true,
	Genderuwo = true,
	Leak = true,
	HantuTanah = true,
	Jerangkong = true,
}

local DEFAULT_GHOST_TEMPLATE_MESH_PART_NAMES = {}

local DEFAULT_GHOST_TEMPLATE_CAST_SHADOW = {}

local DEFAULT_GHOST_TEMPLATE_TEXTURE_MODEL_ASSET_IDS = {
	Banaspati = "rbxassetid://97456316811319",
	BanaspatiAggressive = "rbxassetid://97456316811319",
	HantuTanah = "rbxassetid://139296725422008",
	Jerangkong = "rbxassetid://111398758078419",
	Kuntilanak = "rbxassetid://85391462330878",
	Leak = "rbxassetid://123810909037540",
	LeakAggressive = "rbxassetid://123810909037540",
	Palasik = "rbxassetid://91886890215469",
	PalasikAngry = "rbxassetid://91886890215469",
	SilumanUlar = "rbxassetid://137287114113323",
	SundelBolong = "rbxassetid://131700767022518",
	SundelBolongAggressive = "rbxassetid://70983571304250",
	Tuyul = "rbxassetid://127455958486834",
	WeweGombel = "rbxassetid://137426068299766",
}

local GHOST_TEMPLATE_VISUAL_OFFSETS = {}
local GHOST_TEMPLATE_VISUAL_ROTATIONS = {}
local GHOST_TEMPLATE_ROOT_SIZES = {}
local GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES = {}
local GHOST_TEMPLATE_TARGET_BOUNDS = {}
local GHOST_TEMPLATE_MAX_HOVER_HEIGHT = {}
local GHOST_TEMPLATE_GROUNDED = {}
local GHOST_TEMPLATE_MESH_PART_NAMES = {}
local GHOST_TEMPLATE_CAST_SHADOW = {}
local GHOST_TEMPLATE_INVENTORY_MODEL_ASSET_IDS = {}
local GHOST_TEMPLATE_TEXTURE_MODEL_ASSET_IDS = {}
local GHOST_MODEL_ASSET_TEMPLATE_CACHE = {}
local GHOST_TEXTURE_DONOR_TEMPLATE_CACHE = {}

local GHOST_VISUAL_MOVE_SPEED_BY_STATE = {
	Idle = 1.75,
	Roaming = 3.6,
	Manifestation = 4.4,
	Hunting = 7.8,
	Cooldown = 2.1,
}

local GHOST_MAX_TRANSPARENCY = 0.5
local GHOST_VISUAL_TRANSPARENCY_BY_STATE = {
	Idle = 0.45,
	Roaming = 0.35,
	Manifestation = 0.0,
	Hunting = 0.05,
	Cooldown = 0.45,
}

local GHOST_NAV_NODE_LINK_DISTANCE = 34
local GHOST_NAV_MAX_RAYCAST_PASSES = 16
local GHOST_NAV_PATH_RECOMPUTE_INTERVAL = 0.45
local GHOST_NAV_PATH_TARGET_REUSE_DISTANCE = 5
local GHOST_NAV_ROOM_MARGIN = 1.25
local GHOST_NAV_VERTICAL_TOLERANCE = 12

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

local function ensureGhostAnimator(model)
	if typeof(model) ~= "Instance" then
		return nil
	end

	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	if controller then
		local animator = controller:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = controller
		end
		return animator
	end

	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	controller = Instance.new("AnimationController")
	controller.Name = "GhostAnimationController"
	controller.Parent = model

	local animator = Instance.new("Animator")
	animator.Parent = controller
	return animator
end

local function shouldUseGhostAnimationControllerRig(model)
	if typeof(model) ~= "Instance" then
		return false
	end
	if not model:FindFirstChildWhichIsA("AnimationController", true) then
		return false
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Bone") then
			return true
		end
		if descendant:IsA("MeshPart") and descendant.HasSkinnedMesh then
			return true
		end
	end

	return false
end

local function createGhostHumanoid(model)
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "GhostHumanoid"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid:SetAttribute("PasrahRuntimeGhostHumanoid", true)
	humanoid.Parent = model
	ensureGhostAnimator(model)
	return humanoid
end

local function createVisibleGhostPlaceholder(spawnCFrame, ghostType)
	local ghostModel = Instance.new("Model")
	ghostModel.Name = string.format("GhostPlaceholder_%s", tostring(ghostType or "Unknown"))
	ghostModel:SetAttribute("GhostType", ghostType)
	ghostModel:SetAttribute("PlaceholderVisual", true)
	ghostModel:SetAttribute("PasrahGhostRuntimeAssetTemplate", true)
	ghostModel:SetAttribute("PasrahAllowRuntimeScale", true)
	ghostModel:SetAttribute("PasrahGhostInventoryModelAssetId", nil)

	local root = createGhostRigPart(ghostModel, "HumanoidRootPart", Vector3.new(2.2, 2.2, 2.2), spawnCFrame, Color3.fromRGB(80, 86, 96))
	root.Transparency = 1

	local torso = createGhostRigPart(ghostModel, "Torso", Vector3.new(2.2, 2.2, 2.2), spawnCFrame * CFrame.new(0, 0, 0), Color3.fromRGB(168, 176, 188))
	local head = createGhostRigPart(ghostModel, "Head", Vector3.new(2.2, 1.1, 1.1), spawnCFrame * CFrame.new(0, 1.55, 0), Color3.fromRGB(214, 220, 228))
	local leftArm = createGhostRigPart(ghostModel, "Left Arm", Vector3.new(1.1, 2.2, 1.1), spawnCFrame * CFrame.new(-1.65, 0, 0), Color3.fromRGB(160, 168, 182))
	local rightArm = createGhostRigPart(ghostModel, "Right Arm", Vector3.new(1.1, 2.2, 1.1), spawnCFrame * CFrame.new(1.65, 0, 0), Color3.fromRGB(160, 168, 182))
	local leftLeg = createGhostRigPart(ghostModel, "Left Leg", Vector3.new(1.1, 2.2, 1.1), spawnCFrame * CFrame.new(-0.55, -2.15, 0), Color3.fromRGB(124, 132, 148))
	local rightLeg = createGhostRigPart(ghostModel, "Right Leg", Vector3.new(1.1, 2.2, 1.1), spawnCFrame * CFrame.new(0.55, -2.15, 0), Color3.fromRGB(124, 132, 148))

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

local function buildGhostTemplateCandidateNames(ghostType)
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

local function normalizeGhostModelAssetId(value)
	if type(value) ~= "string" then
		return nil
	end
	local digits = value:match("(%d+)$")
	if not digits then
		return nil
	end
	return digits
end

local function resolveGhostModelAssetId(ghostType)
	return normalizeGhostModelAssetId(resolveGhostTemplateConfigValue(GHOST_TEMPLATE_INVENTORY_MODEL_ASSET_IDS, ghostType))
end

local function resolveGhostTextureModelAssetId(ghostType)
	if type(ghostType) ~= "string" or ghostType == "" then
		return nil
	end
	return normalizeGhostModelAssetId(resolveGhostTemplateConfigValue(GHOST_TEMPLATE_TEXTURE_MODEL_ASSET_IDS, ghostType))
end

local function collectGhostRigSignals(model)
	local signals = {
		baseParts = 0,
		animationControllers = 0,
		animators = 0,
		bones = 0,
		skinnedMeshes = 0,
	}
	if typeof(model) ~= "Instance" then
		return signals
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			signals.baseParts += 1
		end
		if descendant:IsA("AnimationController") then
			signals.animationControllers += 1
		elseif descendant:IsA("Animator") then
			signals.animators += 1
		elseif descendant:IsA("Bone") then
			signals.bones += 1
		elseif descendant:IsA("MeshPart") then
			local ok, hasSkinnedMesh = pcall(function()
				return descendant.HasSkinnedMesh
			end)
			if ok and hasSkinnedMesh == true then
				signals.skinnedMeshes += 1
			end
		end
	end
	return signals
end

local function isAnimatableGhostModel(model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false
	end
	local signals = collectGhostRigSignals(model)
	if signals.baseParts <= 0 then
		return false
	end
	if signals.skinnedMeshes > 0 then
		return true
	end
	return signals.bones > 0 and (signals.animationControllers > 0 or signals.animators > 0)
end

local function stampGhostRigSignalAttributes(model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return
	end
	local signals = collectGhostRigSignals(model)
	local animatable = signals.baseParts > 0 and (signals.skinnedMeshes > 0
		or (signals.bones > 0 and (signals.animationControllers > 0 or signals.animators > 0)))
	model:SetAttribute("PasrahGhostTemplateAnimatable", animatable)
	model:SetAttribute("PasrahGhostBasePartCount", signals.baseParts)
	model:SetAttribute("PasrahGhostAnimationControllerCount", signals.animationControllers)
	model:SetAttribute("PasrahGhostAnimatorCount", signals.animators)
	model:SetAttribute("PasrahGhostBoneCount", signals.bones)
	model:SetAttribute("PasrahGhostSkinnedMeshCount", signals.skinnedMeshes)
end

local function warnRejectedGhostTemplate(reason, ghostType, candidate)
	if not RunService:IsStudio() then
		return
	end
	local candidateName = typeof(candidate) == "Instance" and candidate.Name or tostring(candidate)
	warn(string.format(
		"[GhostSystem] Rejected %s ghost template for '%s': %s",
		tostring(reason or "invalid"),
		tostring(ghostType or "Unknown"),
		tostring(candidateName)
	))
end

local function findUsableGhostModelFromAssetContainer(container, requireAnimatable)
	if typeof(container) ~= "Instance" or not container:IsA("Model") then
		return nil
	end
	local fallbackModel = nil
	local function consider(candidate)
		if not (candidate and candidate:IsA("Model") and candidate:FindFirstChildWhichIsA("BasePart", true)) then
			return nil
		end
		if requireAnimatable ~= true or isAnimatableGhostModel(candidate) then
			return candidate
		end
		if not fallbackModel then
			fallbackModel = candidate
		end
		return nil
	end

	local selected = consider(container)
	if selected then
		return selected
	end
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("Model") then
			selected = consider(descendant)
			if selected then
				return selected
			end
		end
	end
	if requireAnimatable ~= true then
		return fallbackModel
	end
	return nil
end

local function loadGhostModelAssetTemplate(ghostType)
	local assetId = resolveGhostModelAssetId(ghostType)
	if not assetId then
		return nil
	end

	local cached = GHOST_MODEL_ASSET_TEMPLATE_CACHE[assetId]
	if typeof(cached) == "Instance" and cached:IsA("Model") then
		return cached
	elseif cached == false then
		return nil
	end

	local ok, containerOrErr = pcall(function()
		return InsertService:LoadAsset(tonumber(assetId))
	end)
	if not ok or typeof(containerOrErr) ~= "Instance" then
		warn(string.format(
			"[GhostSystem] Failed to load ghost asset '%s' for '%s': %s",
			tostring(assetId),
			tostring(ghostType),
			tostring(containerOrErr)
		))
		GHOST_MODEL_ASSET_TEMPLATE_CACHE[assetId] = false
		return nil
	end

	local selectedModel = findUsableGhostModelFromAssetContainer(containerOrErr, true)
	if not selectedModel then
		containerOrErr:Destroy()
		GHOST_MODEL_ASSET_TEMPLATE_CACHE[assetId] = false
		warnRejectedGhostTemplate("non-animatable asset", ghostType, assetId)
		return nil
	end

	local template = selectedModel
	if selectedModel ~= containerOrErr then
		template = selectedModel:Clone()
		containerOrErr:Destroy()
	end

	template.Name = tostring(ghostType)
	template:SetAttribute("PasrahLoadedFromAssetId", assetId)
	template:SetAttribute("PasrahGhostRuntimeAssetTemplate", true)
	stampGhostRigSignalAttributes(template)
	template.Parent = nil
	GHOST_MODEL_ASSET_TEMPLATE_CACHE[assetId] = template
	return template
end

local function loadGhostTextureDonorTemplate(ghostType)
	local assetId = resolveGhostTextureModelAssetId(ghostType)
	if not assetId then
		return nil
	end

	local cached = GHOST_TEXTURE_DONOR_TEMPLATE_CACHE[assetId]
	if typeof(cached) == "Instance" and cached:IsA("Model") then
		return cached
	elseif cached == false then
		return nil
	end

	local ok, containerOrErr = pcall(function()
		return InsertService:LoadAsset(tonumber(assetId))
	end)
	if not ok or typeof(containerOrErr) ~= "Instance" then
		warn(string.format(
			"[GhostSystem] Failed to load ghost texture donor asset '%s' for '%s': %s",
			tostring(assetId),
			tostring(ghostType),
			tostring(containerOrErr)
		))
		GHOST_TEXTURE_DONOR_TEMPLATE_CACHE[assetId] = false
		return nil
	end

	local selectedModel = findUsableGhostModelFromAssetContainer(containerOrErr, false)
	if not selectedModel then
		containerOrErr:Destroy()
		GHOST_TEXTURE_DONOR_TEMPLATE_CACHE[assetId] = false
		return nil
	end

	local template = selectedModel
	if selectedModel ~= containerOrErr then
		template = selectedModel:Clone()
		containerOrErr:Destroy()
	end

	template.Name = tostring(ghostType) .. "_TextureDonor"
	template:SetAttribute("PasrahTextureDonorAssetId", assetId)
	template.Parent = nil
	GHOST_TEXTURE_DONOR_TEMPLATE_CACHE[assetId] = template
	return template
end

local function resolveGhostModelTemplate(ghostType, options)
	if type(ghostType) ~= "string" or ghostType == "" then
		return nil
	end

	local context = type(options) == "table" and options or {}
	local baseGhostType = resolveGhostBaseType(ghostType)
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
	appendCandidates(buildGhostTemplateCandidateNames(ghostType))
	if baseGhostType ~= ghostType then
		appendCandidates(buildGhostTemplateCandidateNames(baseGhostType))
	end

	local ghosts = resolveGhostTemplatesFolder()
	local configuredAssetId = resolveGhostModelAssetId(ghostType) or resolveGhostModelAssetId(baseGhostType)
	if ghosts and configuredAssetId then
		for _, candidateName in ipairs(preferredCandidates) do
			local candidate = ghosts:FindFirstChild(candidateName)
			if candidate and candidate:IsA("Model") then
				local candidateAssetId = normalizeGhostModelAssetId(candidate:GetAttribute("PasrahLoadedFromAssetId"))
				if candidateAssetId == configuredAssetId then
					if isAnimatableGhostModel(candidate) then
						return candidate, candidateName
					end
					warnRejectedGhostTemplate("non-animatable local asset match", ghostType, candidate)
				end
			end
		end
	end

	local assetTemplate = loadGhostModelAssetTemplate(ghostType) or loadGhostModelAssetTemplate(baseGhostType)
	if assetTemplate then
		return assetTemplate, baseGhostType or ghostType
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

local function shouldApplyRuntimeGhostScale(ghostModel)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return false
	end
	return ghostModel:GetAttribute("PasrahGhostRuntimeAssetTemplate") == true
		or ghostModel:GetAttribute("PasrahAllowRuntimeScale") == true
end

local function clampGhostTemplateScale(ghostModel, ghostType)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return
	end
	if not shouldApplyRuntimeGhostScale(ghostModel) then
		return
	end

	local explicitTargetBounds = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_TARGET_BOUNDS, ghostType)
	local targetBounds = explicitTargetBounds or Vector3.new(7.4, 7.4, 7.4)
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

local function ensureGhostMinimumVisualSize(ghostModel, minimumMaxAxis, maximumMaxAxis)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return
	end
	if not shouldApplyRuntimeGhostScale(ghostModel) then
		return
	end

	local ok, _, currentBounds = pcall(function()
		return ghostModel:GetBoundingBox()
	end)
	if not ok or typeof(currentBounds) ~= "Vector3" then
		return
	end

	local currentMaxAxis = math.max(currentBounds.X, currentBounds.Y, currentBounds.Z)
	local minAxis = tonumber(minimumMaxAxis) or 5.5
	local maxAxis = tonumber(maximumMaxAxis) or 6.0
	if currentMaxAxis >= minAxis then
		return
	end

	local desiredFactor = minAxis / math.max(currentMaxAxis, 0.001)
	local cappedFactor = math.min(desiredFactor, maxAxis / math.max(currentMaxAxis, 0.001))
	if cappedFactor <= 1.0 then
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
		ghostModel:ScaleTo(currentScale * cappedFactor)
	end)
end

local function resizeGhostVisualParts(ghostModel, factor)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return
	end
	local scaleFactor = tonumber(factor)
	if not scaleFactor or scaleFactor <= 1 then
		return
	end
	local okPivot, pivot = pcall(function()
		return ghostModel:GetPivot()
	end)
	if not okPivot or typeof(pivot) ~= "CFrame" then
		return
	end
	for _, descendant in ipairs(ghostModel:GetDescendants()) do
		if descendant:IsA("BasePart") and not shouldHideGhostControlPart(descendant) then
			local relative = pivot:ToObjectSpace(descendant.CFrame)
			local pos = relative.Position
			local rotation = relative - relative.Position
			descendant.Size = Vector3.new(
				descendant.Size.X * scaleFactor,
				descendant.Size.Y * scaleFactor,
				descendant.Size.Z * scaleFactor
			)
			descendant.CFrame = pivot * (CFrame.new(pos.X * scaleFactor, pos.Y * scaleFactor, pos.Z * scaleFactor) * rotation)
		end
	end
end

local function configureGhostRootPart(root, preferredRootSize)
	if not (root and root:IsA("BasePart")) then
		return
	end
	if typeof(preferredRootSize) == "Vector3" then
		root.Size = preferredRootSize
	else
		root.Size = Vector3.new(2.2, 2.2, 2.2)
	end
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Anchored = true
	root.CastShadow = false
end

local function ensureGhostRuntimeRoot(ghostModel, spawnCFrame, preferredRootSize)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return nil
	end

	local root = ghostModel:FindFirstChild("HumanoidRootPart", true)
	if not (root and root:IsA("BasePart")) then
		local firstPart = ghostModel:FindFirstChildWhichIsA("BasePart", true)
		if not firstPart then
			return nil
		end
		root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Parent = ghostModel
	end

	configureGhostRootPart(root, preferredRootSize)
	ghostModel.PrimaryPart = root
	ghostModel:SetPrimaryPartCFrame(spawnCFrame)
	return root
end

local function findFirstGhostMeshPart(model)
	if typeof(model) ~= "Instance" then
		return nil
	end
	return model:FindFirstChildWhichIsA("MeshPart", true)
end

local function countGhostSurfaceAppearances(model)
	local count = 0
	if typeof(model) ~= "Instance" then
		return count
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("SurfaceAppearance") then
			count += 1
		end
	end
	return count
end

local function isNonEmptyAssetContent(value)
	if value == nil then
		return false
	end
	local text = tostring(value)
	if text == "" or text == "nil" then
		return false
	end
	local compactText = text:gsub("%s+", "")
	if compactText == "Content{SourceType=None}" or compactText == "Content{}" then
		return false
	end
	return true
end

local function getInstanceProperty(instance, propertyName)
	local ok, value = pcall(function()
		return instance[propertyName]
	end)
	if ok then
		return value
	end
	return nil
end

local function setInstanceProperty(instance, propertyName, value)
	if value == nil then
		return false
	end
	local ok = pcall(function()
		instance[propertyName] = value
	end)
	return ok == true
end

local SURFACE_APPEARANCE_CONTENT_PROPERTIES = {
	"ColorMap",
	"ColorMapContent",
	"NormalMap",
	"NormalMapContent",
	"RoughnessMap",
	"RoughnessMapContent",
	"MetalnessMap",
	"MetalnessMapContent",
	"AlphaMap",
	"AlphaMapContent",
}

local SURFACE_APPEARANCE_STYLE_PROPERTIES = {
	"AlphaMode",
	"ResampleMode",
	"EmissiveStrength",
	"EmissiveTint",
}

local function surfaceAppearanceHasRenderableContent(surface)
	if not (surface and surface:IsA("SurfaceAppearance")) then
		return false
	end
	for _, propertyName in ipairs(SURFACE_APPEARANCE_CONTENT_PROPERTIES) do
		if isNonEmptyAssetContent(getInstanceProperty(surface, propertyName)) then
			return true
		end
	end
	return false
end

local function meshPartHasRenderableTexture(meshPart)
	if not (meshPart and meshPart:IsA("MeshPart")) then
		return false
	end
	return isNonEmptyAssetContent(getInstanceProperty(meshPart, "TextureID"))
		or isNonEmptyAssetContent(getInstanceProperty(meshPart, "TextureId"))
end

local function readMeshPartTexture(meshPart)
	local texture = getInstanceProperty(meshPart, "TextureID")
	if isNonEmptyAssetContent(texture) then
		return texture
	end
	texture = getInstanceProperty(meshPart, "TextureId")
	if isNonEmptyAssetContent(texture) then
		return texture
	end
	return nil
end

local function modelHasRenderableGhostSurface(model)
	if typeof(model) ~= "Instance" then
		return false
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("SurfaceAppearance") and surfaceAppearanceHasRenderableContent(descendant) then
			return true
		elseif descendant:IsA("MeshPart") and meshPartHasRenderableTexture(descendant) then
			return true
		end
	end
	return false
end

local function findTexturedGhostMeshPart(model)
	if typeof(model) ~= "Instance" then
		return nil
	end
	local fallback = nil
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			fallback = fallback or descendant
			local surface = descendant:FindFirstChildWhichIsA("SurfaceAppearance")
			if meshPartHasRenderableTexture(descendant) or surfaceAppearanceHasRenderableContent(surface) then
				return descendant
			end
		end
	end
	return fallback
end

local function ensureTargetSurfaceAppearance(targetMesh)
	if not (targetMesh and targetMesh:IsA("MeshPart")) then
		return nil
	end
	local surface = targetMesh:FindFirstChildWhichIsA("SurfaceAppearance")
	if surface then
		return surface
	end
	surface = Instance.new("SurfaceAppearance")
	surface.Name = "SurfaceAppearance"
	surface.Parent = targetMesh
	return surface
end

local function copySurfaceAppearanceProperties(sourceSurface, targetSurface)
	if not (sourceSurface and sourceSurface:IsA("SurfaceAppearance")) then
		return false
	end
	if not (targetSurface and targetSurface:IsA("SurfaceAppearance")) then
		return false
	end

	local copied = false
	for _, propertyName in ipairs(SURFACE_APPEARANCE_CONTENT_PROPERTIES) do
		local value = getInstanceProperty(sourceSurface, propertyName)
		if isNonEmptyAssetContent(value) then
			if setInstanceProperty(targetSurface, propertyName, value) then
				copied = true
			end
			local assetUri = tostring(value):match("rbxassetid://%d+")
			if assetUri then
				if propertyName == "ColorMapContent" and setInstanceProperty(targetSurface, "ColorMap", assetUri) then
					copied = true
				elseif propertyName == "NormalMapContent" and setInstanceProperty(targetSurface, "NormalMap", assetUri) then
					copied = true
				elseif propertyName == "RoughnessMapContent" and setInstanceProperty(targetSurface, "RoughnessMap", assetUri) then
					copied = true
				elseif propertyName == "MetalnessMapContent" and setInstanceProperty(targetSurface, "MetalnessMap", assetUri) then
					copied = true
				end
			end
		end
	end
	for _, propertyName in ipairs(SURFACE_APPEARANCE_STYLE_PROPERTIES) do
		local value = getInstanceProperty(sourceSurface, propertyName)
		if value ~= nil then
			setInstanceProperty(targetSurface, propertyName, value)
		end
	end
	return copied
end

local function copyGhostMeshTexture(sourceMesh, targetMesh)
	if not (sourceMesh and sourceMesh:IsA("MeshPart")) or not (targetMesh and targetMesh:IsA("MeshPart")) then
		return false
	end

	local copied = false
	local sourceTexture = readMeshPartTexture(sourceMesh)
	if isNonEmptyAssetContent(sourceTexture)
		and not meshPartHasRenderableTexture(targetMesh)
		and (setInstanceProperty(targetMesh, "TextureID", sourceTexture) or setInstanceProperty(targetMesh, "TextureId", sourceTexture)) then
		copied = true
	end

	local sourceSurface = sourceMesh:FindFirstChildWhichIsA("SurfaceAppearance")
	if sourceSurface and surfaceAppearanceHasRenderableContent(sourceSurface) then
		local targetSurface = ensureTargetSurfaceAppearance(targetMesh)
		copied = copySurfaceAppearanceProperties(sourceSurface, targetSurface) or copied
	end

	if not copied then
		local sourceColor = getInstanceProperty(sourceMesh, "Color")
		if typeof(sourceColor) == "Color3" then
			setInstanceProperty(targetMesh, "Color", sourceColor)
			copied = true
		end
	end
	return copied
end

local function repairGhostSurfaceAppearanceFromTemplate(ghostModel, sourceTemplate, sourceLabel)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return false
	end
	if not (sourceTemplate and sourceTemplate:IsA("Model")) then
		return false
	end

	local targetMesh = findFirstGhostMeshPart(ghostModel)
	local sourceMesh = findTexturedGhostMeshPart(sourceTemplate)
	if not (targetMesh and sourceMesh) then
		return false
	end

	local copied = copyGhostMeshTexture(sourceMesh, targetMesh)
	if copied then
		ghostModel:SetAttribute("PasrahSurfaceAppearanceRepairedFrom", tostring(sourceLabel or sourceTemplate.Name))
		local donorAssetId = sourceTemplate:GetAttribute("PasrahTextureDonorAssetId")
		if donorAssetId then
			ghostModel:SetAttribute("PasrahSurfaceAppearanceDonorAssetId", tostring(donorAssetId))
		end
	end
	return copied
end

local function repairVariantGhostSurfaceAppearance(ghostModel, visualGhostType)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return
	end
	if modelHasRenderableGhostSurface(ghostModel) then
		return
	end

	local baseGhostType = resolveGhostBaseType(visualGhostType)
	if type(baseGhostType) ~= "string" or baseGhostType == "" or baseGhostType == visualGhostType then
		return
	end

	local ghostsFolder = resolveGhostTemplatesFolder()
	local baseTemplate = ghostsFolder and ghostsFolder:FindFirstChild(baseGhostType)
	if not (baseTemplate and baseTemplate:IsA("Model")) then
		return
	end
	repairGhostSurfaceAppearanceFromTemplate(ghostModel, baseTemplate, baseGhostType)
end

local function repairGhostTextureDonorSurfaceAppearance(ghostModel, visualGhostType, logicalGhostType)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return
	end

	local baseGhostType = resolveGhostBaseType(visualGhostType or logicalGhostType)
	local textureMaps = nil
	if visualGhostType == "WeweGombel" or logicalGhostType == "WeweGombel" or baseGhostType == "WeweGombel" then
		textureMaps = {
			colorMap = "rbxassetid://129620806316127",
			normalMap = "rbxassetid://137526021041912",
		}
	end
	if type(textureMaps) ~= "table" then
		local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
		local gameData = shared and shared:FindFirstChild("GameData")
		local tuningModule = gameData and gameData:FindFirstChild("GhostVisualTuning")
		local tuning = safeRequire(tuningModule)
		local ghosts = type(tuning) == "table" and tuning.ghosts or nil
		local directConfig = type(ghosts) == "table" and (
			ghosts[visualGhostType] or ghosts[logicalGhostType] or ghosts[baseGhostType]
		) or nil
		textureMaps = type(directConfig) == "table" and directConfig.textureMaps or nil
	end
	if type(textureMaps) ~= "table" and modelHasRenderableGhostSurface(ghostModel) then
		return
	end

	local donorTemplate = loadGhostTextureDonorTemplate(visualGhostType)
		or loadGhostTextureDonorTemplate(logicalGhostType)
		or loadGhostTextureDonorTemplate(baseGhostType)
	if donorTemplate then
		repairGhostSurfaceAppearanceFromTemplate(ghostModel, donorTemplate, visualGhostType or logicalGhostType or baseGhostType)
	end
	if type(textureMaps) ~= "table" and modelHasRenderableGhostSurface(ghostModel) then
		return
	end
	if type(textureMaps) == "table" then
		local targetMesh = findFirstGhostMeshPart(ghostModel)
		local targetSurface = ensureTargetSurfaceAppearance(targetMesh)
		if targetSurface then
			local copied = false
			if isNonEmptyAssetContent(textureMaps.colorMap or textureMaps.ColorMap) then
				local colorMap = textureMaps.colorMap or textureMaps.ColorMap
				local colorMapSet = setInstanceProperty(targetSurface, "ColorMap", colorMap)
				if not colorMapSet and targetMesh and targetMesh:IsA("MeshPart") then
					colorMapSet = setInstanceProperty(targetMesh, "TextureID", colorMap)
						or setInstanceProperty(targetMesh, "TextureId", colorMap)
				end
				copied = colorMapSet or copied
			end
			if isNonEmptyAssetContent(textureMaps.normalMap or textureMaps.NormalMap) then
				copied = setInstanceProperty(targetSurface, "NormalMap", textureMaps.normalMap or textureMaps.NormalMap) or copied
			end
			if isNonEmptyAssetContent(textureMaps.roughnessMap or textureMaps.RoughnessMap) then
				copied = setInstanceProperty(targetSurface, "RoughnessMap", textureMaps.roughnessMap or textureMaps.RoughnessMap) or copied
			end
			if isNonEmptyAssetContent(textureMaps.metalnessMap or textureMaps.MetalnessMap) then
				copied = setInstanceProperty(targetSurface, "MetalnessMap", textureMaps.metalnessMap or textureMaps.MetalnessMap) or copied
			end
			if copied then
				ghostModel:SetAttribute("PasrahSurfaceAppearanceRepairedFrom", tostring(visualGhostType or logicalGhostType or baseGhostType))
				ghostModel:SetAttribute("PasrahSurfaceAppearanceDirectMaps", true)
			end
		end
	end
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
	ghostModel:SetAttribute("PasrahLoadedFromAssetId", template:GetAttribute("PasrahLoadedFromAssetId"))
	stampGhostRigSignalAttributes(ghostModel)
	repairVariantGhostSurfaceAppearance(ghostModel, visualGhostType)
	repairGhostTextureDonorSurfaceAppearance(ghostModel, visualGhostType, logicalGhostType)

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

	local root = ensureGhostRuntimeRoot(ghostModel, spawnCFrame, preferredRootSize)

	if ghostModel.PrimaryPart then
		local visualOffset = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_VISUAL_OFFSETS, visualGhostType)
		local visualRotation = resolveGhostTemplateConfigValue(GHOST_TEMPLATE_VISUAL_ROTATIONS, visualGhostType)
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
			if typeof(visualOffset) == "Vector3" or typeof(visualRotation) == "Vector3" then
				local meshLocalCFrame = typeof(visualOffset) == "Vector3" and CFrame.new(visualOffset) or CFrame.new()
				if typeof(visualRotation) == "Vector3" then
					meshLocalCFrame *= CFrame.Angles(
						math.rad(visualRotation.X),
						math.rad(visualRotation.Y),
						math.rad(visualRotation.Z)
					)
				end
				visualMesh.CFrame = ghostModel.PrimaryPart.CFrame * meshLocalCFrame
			end
		end
	end

	clampGhostTemplateScale(ghostModel, visualGhostType)
	ensureGhostMinimumVisualSize(ghostModel, 5.5, 6.0)
	do
		local okExtents, extents = pcall(function()
			return ghostModel:GetExtentsSize()
		end)
		if okExtents and typeof(extents) == "Vector3" then
			local currentMaxAxis = math.max(extents.X, extents.Y, extents.Z)
			if currentMaxAxis < 5.5 then
				local factor = math.min(6.0 / math.max(currentMaxAxis, 0.001), 5.5 / math.max(currentMaxAxis, 0.001))
				resizeGhostVisualParts(ghostModel, factor)
			end
		end
	end
	if root and root:IsDescendantOf(ghostModel) then
		configureGhostRootPart(root, preferredRootSize)
		ghostModel.PrimaryPart = root
		ghostModel:SetPrimaryPartCFrame(spawnCFrame)
	end

	if shouldUseGhostAnimationControllerRig(ghostModel) then
		ensureGhostAnimator(ghostModel)
		local runtimeHumanoid = ghostModel:FindFirstChildWhichIsA("Humanoid", true)
		if runtimeHumanoid and (runtimeHumanoid.Name == "GhostHumanoid" or runtimeHumanoid:GetAttribute("PasrahRuntimeGhostHumanoid") == true) then
			runtimeHumanoid:Destroy()
		end
	elseif not ghostModel:FindFirstChildOfClass("Humanoid") then
		createGhostHumanoid(ghostModel)
	else
		ensureGhostAnimator(ghostModel)
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
	if ok and ghostModel.Parent == container then
		return true
	end
	return false, tostring(err or "parent_not_applied")
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

local function copyGhostVisualRotationMap(source)
	local out = {}
	for ghostType, rotation in pairs(source or {}) do
		if type(ghostType) == "string" and typeof(rotation) == "Vector3" then
			out[ghostType] = rotation
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
	local rotations = copyGhostVisualRotationMap(DEFAULT_GHOST_TEMPLATE_VISUAL_ROTATIONS)
	local rootSizes = copyGhostVisualVectorMap(DEFAULT_GHOST_TEMPLATE_ROOT_SIZES)
	local meshSizes = copyGhostVisualVectorMap(DEFAULT_GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES)
	local bounds = copyGhostVisualVectorMap(DEFAULT_GHOST_TEMPLATE_TARGET_BOUNDS)
	local maxHoverHeights = copyGhostVisualNumberMap(DEFAULT_GHOST_TEMPLATE_MAX_HOVER_HEIGHT)
	local grounded = copyGhostVisualBooleanMap(DEFAULT_GHOST_TEMPLATE_GROUNDED)
	local meshPartNames = copyGhostVisualStringMap(DEFAULT_GHOST_TEMPLATE_MESH_PART_NAMES)
	local castShadow = copyGhostVisualBooleanMap(DEFAULT_GHOST_TEMPLATE_CAST_SHADOW)
	local inventoryModelAssetIds = copyGhostVisualStringMap({})
	local textureModelAssetIds = copyGhostVisualStringMap(DEFAULT_GHOST_TEMPLATE_TEXTURE_MODEL_ASSET_IDS)
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
			if typeof(config.meshRotation) == "Vector3" then
				rotations[ghostType] = config.meshRotation
			elseif typeof(config.visualRotation) == "Vector3" then
				rotations[ghostType] = config.visualRotation
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
			if type(config.textureModelAssetId) == "string" and config.textureModelAssetId ~= "" then
				textureModelAssetIds[ghostType] = config.textureModelAssetId
			end
		end
	end

	return offsets, rotations, meshSizes, bounds, maxHoverHeights, grounded, rootSizes, meshPartNames, castShadow, inventoryModelAssetIds, textureModelAssetIds
end

GHOST_TEMPLATE_VISUAL_OFFSETS,
	GHOST_TEMPLATE_VISUAL_ROTATIONS,
	GHOST_TEMPLATE_VISUAL_SIZE_OVERRIDES,
	GHOST_TEMPLATE_TARGET_BOUNDS,
	GHOST_TEMPLATE_MAX_HOVER_HEIGHT,
	GHOST_TEMPLATE_GROUNDED,
	GHOST_TEMPLATE_ROOT_SIZES,
	GHOST_TEMPLATE_MESH_PART_NAMES,
	GHOST_TEMPLATE_CAST_SHADOW,
	GHOST_TEMPLATE_INVENTORY_MODEL_ASSET_IDS,
	GHOST_TEMPLATE_TEXTURE_MODEL_ASSET_IDS = loadGhostVisualTuning()

local function ensureCanonicalGhostTemplatesFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "Assets"
		assets.Parent = ReplicatedStorage
	end

	local models = assets:FindFirstChild("Models")
	if not models then
		models = Instance.new("Folder")
		models.Name = "Models"
		models.Parent = assets
	end

	local ghosts = models:FindFirstChild("Ghosts")
	if not ghosts then
		ghosts = Instance.new("Folder")
		ghosts.Name = "Ghosts"
		ghosts.Parent = models
	end

	return ghosts
end

local function buildCanonicalGhostTemplateTypes()
	local types = {}
	for ghostType in pairs(GHOST_TEMPLATE_INVENTORY_MODEL_ASSET_IDS) do
		table.insert(types, ghostType)
	end
	table.sort(types)
	return types
end

local function refreshCanonicalGhostTemplate(ghostsFolder, ghostType)
	local configuredAssetId = resolveGhostModelAssetId(ghostType)
	if not configuredAssetId then
		return false, "missing_asset_id"
	end

	local existing = ghostsFolder:FindFirstChild(ghostType)
	if existing and existing:IsA("Model") then
		local existingAssetId = normalizeGhostModelAssetId(existing:GetAttribute("PasrahLoadedFromAssetId"))
		if existingAssetId == configuredAssetId and isAnimatableGhostModel(existing) then
			existing:SetAttribute("PasrahCanonicalLocalTemplate", true)
			stampGhostRigSignalAttributes(existing)
			return true
		end
	end

	local template = loadGhostModelAssetTemplate(ghostType)
	if not template then
		return false, "asset_load_failed"
	end

	local clone = template:Clone()
	clone.Name = ghostType
	clone:SetAttribute("PasrahLoadedFromAssetId", configuredAssetId)
	clone:SetAttribute("PasrahGhostRuntimeAssetTemplate", true)
	clone:SetAttribute("PasrahCanonicalLocalTemplate", true)
	clone:SetAttribute("PasrahCanonicalTemplateRefreshUtc", os.date("!%Y-%m-%dT%H:%M:%SZ"))
	stampGhostRigSignalAttributes(clone)
	clone.Parent = ghostsFolder

	if existing and existing ~= clone then
		existing:Destroy()
	end

	return true
end

local function refreshCanonicalGhostTemplates()
	local ghostsFolder = ensureCanonicalGhostTemplatesFolder()
	for _, ghostType in ipairs(buildCanonicalGhostTemplateTypes()) do
		local ok, reason = refreshCanonicalGhostTemplate(ghostsFolder, ghostType)
		if not ok and RunService:IsStudio() then
			warn(string.format(
				"[GhostSystem] Failed to refresh canonical ReplicatedStorage ghost template '%s': %s",
				tostring(ghostType),
				tostring(reason)
			))
		end
	end
end

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

	local billboard = cloneStudioGhostPreviewLabelTemplate()
	if not billboard then
		warn("[GhostSystem] Missing authored visual template: GhostVisuals.StudioGhostPreviewLabelTemplate")
		return
	end
	billboard.Name = "PreviewLabel"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 100
	billboard.Size = UDim2.fromOffset(180, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	billboard.Adornee = model.PrimaryPart
	billboard.Parent = model.PrimaryPart

	local label = billboard:FindFirstChild("Text")
	if not (label and label:IsA("TextLabel")) then
		if label then
			label:Destroy()
		end
		warn("[GhostSystem] StudioGhostPreviewLabelTemplate missing required child: Text")
		return
	end
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	label.BorderSizePixel = 0
	label.Text = tostring(ghostType)
	label.TextColor3 = Color3.fromRGB(237, 240, 244)
	label.TextStrokeTransparency = 0.6
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
end

local function resolveGhostGroundPosition(match, targetAnchor)
	if type(match) ~= "table" or typeof(match.ghost) ~= "Instance" then
		return nil
	end

	local targetPosition = nil
	local targetGroundY = nil
	if typeof(targetAnchor) == "Instance" and targetAnchor:IsA("BasePart") then
		targetPosition = targetAnchor.Position
		targetGroundY = targetAnchor.Position.Y - (targetAnchor.Size.Y * 0.5)
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

	local bestEdge = nil
	local bestDist2D = math.huge
	for _, sz in ipairs(safeZoneParts) do
		local localPos = sz.CFrame:PointToObjectSpace(desiredPosition)
		local half = sz.Size * 0.5
		local dx = math.abs(localPos.X) - half.X
		local dz = math.abs(localPos.Z) - half.Z
		local dy = math.abs(localPos.Y) - half.Y
		if dx > 0 or dz > 0 or dy > 0 then
			local pushX = 0
			if localPos.X > half.X then pushX = localPos.X - half.X
			elseif localPos.X < -half.X then pushX = localPos.X + half.X end
			local pushZ = 0
			if localPos.Z > half.Z then pushZ = localPos.Z - half.Z
			elseif localPos.Z < -half.Z then pushZ = localPos.Z + half.Z end
			local pushY = 0
			if localPos.Y > half.Y then pushY = localPos.Y - half.Y
			elseif localPos.Y < -half.Y then pushY = localPos.Y + half.Y end
			local worldPush = sz.CFrame:VectorToWorldSpace(Vector3.new(pushX, pushY, pushZ))
			local edgePos = desiredPosition - worldPush
			local dist2D = math.sqrt((edgePos.X - desiredPosition.X) ^ 2 + (edgePos.Z - desiredPosition.Z) ^ 2)
			if dist2D < bestDist2D then
				bestDist2D = dist2D
				bestEdge = edgePos
			end
		end
	end

	return bestEdge or desiredPosition
end

local function collectMatchRoomParts(match)
	if type(match) ~= "table" then
		return {}
	end
	local container = match.container
	if typeof(container) ~= "Instance" then
		return {}
	end
	local roomsFolder = container:FindFirstChild("Rooms", true)
	if not roomsFolder then
		return {}
	end

	local roomParts = {}
	for _, descendant in ipairs(roomsFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and string.find(descendant.Name, "Room_", 1, true) == 1 then
			table.insert(roomParts, descendant)
		end
	end
	return roomParts
end

local function isPositionInsideRoomPart(roomPart, position)
	if typeof(position) ~= "Vector3" or not (typeof(roomPart) == "Instance" and roomPart:IsA("BasePart")) then
		return false
	end

	local localPosition = roomPart.CFrame:PointToObjectSpace(position)
	local halfSize = roomPart.Size * 0.5
	local verticalTolerance = math.max(halfSize.Y, GHOST_NAV_VERTICAL_TOLERANCE)
	return math.abs(localPosition.X) <= (halfSize.X + 0.75)
		and math.abs(localPosition.Y) <= verticalTolerance
		and math.abs(localPosition.Z) <= (halfSize.Z + 0.75)
end

local function findContainingRoomPart(match, position)
	for _, roomPart in ipairs(collectMatchRoomParts(match)) do
		if isPositionInsideRoomPart(roomPart, position) then
			return roomPart
		end
	end
	return nil
end

local function clampPositionToRoom(roomPart, position)
	if typeof(position) ~= "Vector3" or not (typeof(roomPart) == "Instance" and roomPart:IsA("BasePart")) then
		return position
	end

	local localPosition = roomPart.CFrame:PointToObjectSpace(position)
	local halfSize = roomPart.Size * 0.5
	local marginX = math.min(GHOST_NAV_ROOM_MARGIN, math.max(0, halfSize.X - 0.25))
	local marginZ = math.min(GHOST_NAV_ROOM_MARGIN, math.max(0, halfSize.Z - 0.25))
	local clampedLocal = Vector3.new(
		math.clamp(localPosition.X, -halfSize.X + marginX, halfSize.X - marginX),
		localPosition.Y,
		math.clamp(localPosition.Z, -halfSize.Z + marginZ, halfSize.Z - marginZ)
	)
	return roomPart.CFrame:PointToWorldSpace(clampedLocal)
end

local function findNearestRoomPart(match, position)
	if typeof(position) ~= "Vector3" then
		return nil
	end

	local bestRoom = nil
	local bestDistance = math.huge
	for _, roomPart in ipairs(collectMatchRoomParts(match)) do
		local clamped = clampPositionToRoom(roomPart, position)
		local distance = (Vector3.new(clamped.X, 0, clamped.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
		if distance < bestDistance then
			bestRoom = roomPart
			bestDistance = distance
		end
	end
	return bestRoom
end

local function clampGhostToInvestigationArea(match, desiredPosition, currentPosition)
	if typeof(desiredPosition) ~= "Vector3" then
		return desiredPosition
	end

	local containingRoom = findContainingRoomPart(match, desiredPosition)
	if containingRoom then
		return desiredPosition
	end

	local nearestRoom = findNearestRoomPart(match, desiredPosition)
	if nearestRoom then
		return clampPositionToRoom(nearestRoom, desiredPosition)
	end

	if typeof(currentPosition) == "Vector3" then
		local currentRoom = findContainingRoomPart(match, currentPosition)
		if currentRoom then
			return currentPosition
		end
	end

	return desiredPosition
end

local function hasAncestorNamed(instance, name)
	local node = instance
	while typeof(node) == "Instance" do
		if node.Name == name then
			return true
		end
		node = node.Parent
	end
	return false
end

local function isDoorTraversalName(name)
	if type(name) ~= "string" or name == "" then
		return false
	end

	local lowerName = string.lower(name)
	if lowerName == "door" or lowerName == "doors" then
		return true
	end
	if string.find(lowerName, "door_", 1, true) == 1 then
		return true
	end
	if string.find(lowerName, " door", 1, true)
		or string.find(lowerName, "_door", 1, true)
		or string.find(lowerName, "-door", 1, true)
		or string.find(lowerName, "door ", 1, true)
		or string.find(lowerName, "door-", 1, true)
		or string.find(lowerName, "door)", 1, true)
		or string.find(lowerName, "slidingdoor", 1, true)
		or string.find(lowerName, "entrydoor", 1, true) then
		return true
	end
	return false
end

local function isGhostDoorTraversalPart(instance)
	local node = instance
	while typeof(node) == "Instance" and node ~= Workspace do
		if isDoorTraversalName(node.Name) then
			return true
		end
		local policy = node:GetAttribute("DoorTraversalPolicy")
		local mode = node:GetAttribute("DoorTraversalMode")
		local owner = node:GetAttribute("PasrahDoorOwner")
		if type(owner) == "string" and owner == "DoorRuntime" then
			return true
		end
		if (type(policy) == "string" and policy ~= "")
			or (type(mode) == "string" and mode ~= "") then
			-- DoorTraversalMode also exists on the map clone as global metadata.
			-- Only door-named/proxy objects should make ghost navigation pass through a hit.
			return isDoorTraversalName(node.Name) or hasAncestorNamed(node, "Doors")
		end
		if node.Name == "Doors" then
			return true
		end
		node = node.Parent
	end
	return false
end

local function shouldIgnoreGhostNavigationHit(instance)
	if not (typeof(instance) == "Instance" and instance:IsA("BasePart")) then
		return true
	end
	if isGhostDoorTraversalPart(instance) then
		return true
	end
	if hasAncestorNamed(instance, "NavigationNodes")
		or hasAncestorNamed(instance, "GhostSpawns")
		or hasAncestorNamed(instance, "GhostSpawnZones")
		or hasAncestorNamed(instance, "EvidenceSpawnNodes")
		or hasAncestorNamed(instance, "EvidenceSpawns")
		or hasAncestorNamed(instance, "InteractionPoints")
		or hasAncestorNamed(instance, "SafeZones")
		or hasAncestorNamed(instance, "Rooms") then
		return true
	end
	if instance.Transparency >= 0.98
		and not hasAncestorNamed(instance, "RuntimeBoundary")
		and not hasAncestorNamed(instance, "MapBoundaryRuntime")
		and instance.CanCollide ~= true then
		return true
	end
	return false
end

local function buildGhostNavigationIgnoreList(match)
	local ignored = {}
	if type(match) == "table" and typeof(match.ghost) == "Instance" then
		table.insert(ignored, match.ghost)
	end
	if type(match) == "table" then
		for _, playerState in pairs(match.playersByUserId or {}) do
			local player = type(playerState) == "table" and playerState.player or nil
			if typeof(player) == "Instance" and player:IsA("Player") and typeof(player.Character) == "Instance" then
				table.insert(ignored, player.Character)
			end
		end
	end
	return ignored
end

local function resolveGhostNavigationRayHeight(match, fromPosition, toPosition)
	local fromRoom = findContainingRoomPart(match, fromPosition)
	local toRoom = findContainingRoomPart(match, toPosition)
	local roomPart = fromRoom or toRoom
	if fromRoom and toRoom then
		roomPart = fromRoom.Position.Y <= toRoom.Position.Y and fromRoom or toRoom
	end

	if roomPart then
		local roomHalfHeight = roomPart.Size.Y * 0.5
		local shoulderOffset = math.min(4, math.max(1.5, roomHalfHeight - 0.5))
		return roomPart.Position.Y + shoulderOffset
	end

	return math.min(fromPosition.Y, toPosition.Y) + 1.6
end

local function raycastGhostNavigationBlock(match, fromPosition, toPosition)
	if typeof(fromPosition) ~= "Vector3" or typeof(toPosition) ~= "Vector3" then
		return nil
	end

	local delta = toPosition - fromPosition
	if delta.Magnitude <= 0.05 then
		return nil
	end

	local ignored = buildGhostNavigationIgnoreList(match)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.IgnoreWater = true

	local rayHeight = resolveGhostNavigationRayHeight(match, fromPosition, toPosition)
	local origin = Vector3.new(fromPosition.X, rayHeight, fromPosition.Z)
	local destination = Vector3.new(toPosition.X, rayHeight, toPosition.Z)
	for _ = 1, GHOST_NAV_MAX_RAYCAST_PASSES do
		local direction = destination - origin
		if direction.Magnitude <= 0.05 then
			return nil
		end
		raycastParams.FilterDescendantsInstances = ignored
		local result = Workspace:Raycast(origin, direction, raycastParams)
		if not result then
			return nil
		end
		if shouldIgnoreGhostNavigationHit(result.Instance) then
			table.insert(ignored, result.Instance)
			origin = result.Position + direction.Unit * 0.08
		else
			return result
		end
	end

	return nil
end

local function isGhostNavigationLineClear(match, fromPosition, toPosition)
	return raycastGhostNavigationBlock(match, fromPosition, toPosition) == nil
end

local function collectGhostNavigationNodes(match)
	if type(match) ~= "table" or typeof(match.container) ~= "Instance" then
		return {}
	end
	local nodesFolder = match.container:FindFirstChild("NavigationNodes", true)
	local nodes = {}
	if nodesFolder then
		for _, descendant in ipairs(nodesFolder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(nodes, descendant)
			end
		end
	end

	if #nodes == 0 then
		local roomsFolder = match.container:FindFirstChild("Rooms", true)
		if roomsFolder then
			for _, roomPart in ipairs(roomsFolder:GetChildren()) do
				if roomPart:IsA("BasePart") and string.find(roomPart.Name, "Room_", 1, true) == 1 then
					table.insert(nodes, roomPart)
				end
			end
		end
		local doorsFolder = match.container:FindFirstChild("Doors", true)
		if doorsFolder then
			for _, doorPart in ipairs(doorsFolder:GetDescendants()) do
				if doorPart:IsA("BasePart") and isGhostDoorTraversalPart(doorPart) then
					table.insert(nodes, doorPart)
				end
			end
		end
	end
	table.sort(nodes, function(a, b)
		return a.Name < b.Name
	end)
	return nodes
end

local function getNodePosition(node)
	return node.Position
end

local function findNearestVisibleGhostNavNode(match, nodes, position)
	local bestIndex = nil
	local bestDistance = math.huge
	for index, node in ipairs(nodes) do
		local nodePosition = getNodePosition(node)
		local distance = (nodePosition - position).Magnitude
		if distance < bestDistance and isGhostNavigationLineClear(match, position, nodePosition) then
			bestIndex = index
			bestDistance = distance
		end
	end
	return bestIndex
end

local function findNearestGhostNavNode(nodes, position)
	local bestIndex = nil
	local bestDistance = math.huge
	for index, node in ipairs(nodes) do
		local distance = (getNodePosition(node) - position).Magnitude
		if distance < bestDistance then
			bestIndex = index
			bestDistance = distance
		end
	end
	return bestIndex
end

local function buildGhostNavigationAdjacency(match, nodes)
	local adjacency = {}
	for index = 1, #nodes do
		adjacency[index] = {}
	end

	for leftIndex = 1, #nodes do
		local leftPosition = getNodePosition(nodes[leftIndex])
		for rightIndex = leftIndex + 1, #nodes do
			local rightPosition = getNodePosition(nodes[rightIndex])
			local horizontalDistance = (Vector3.new(leftPosition.X, 0, leftPosition.Z) - Vector3.new(rightPosition.X, 0, rightPosition.Z)).Magnitude
			local verticalDistance = math.abs(leftPosition.Y - rightPosition.Y)
			if horizontalDistance <= GHOST_NAV_NODE_LINK_DISTANCE
				and verticalDistance <= GHOST_NAV_VERTICAL_TOLERANCE
				and isGhostNavigationLineClear(match, leftPosition, rightPosition) then
				table.insert(adjacency[leftIndex], { index = rightIndex, distance = horizontalDistance + verticalDistance })
				table.insert(adjacency[rightIndex], { index = leftIndex, distance = horizontalDistance + verticalDistance })
			end
		end
	end

	return adjacency
end

local function resolveGhostNavigationPath(adjacency, startIndex, targetIndex)
	if type(adjacency) ~= "table" or type(startIndex) ~= "number" or type(targetIndex) ~= "number" then
		return nil
	end
	if startIndex == targetIndex then
		return { startIndex }
	end

	local distances = {}
	local previous = {}
	local visited = {}
	for index in pairs(adjacency) do
		distances[index] = math.huge
	end
	distances[startIndex] = 0

	while true do
		local currentIndex = nil
		local currentDistance = math.huge
		for index, distance in pairs(distances) do
			if not visited[index] and distance < currentDistance then
				currentIndex = index
				currentDistance = distance
			end
		end
		if not currentIndex or currentDistance == math.huge then
			break
		end
		if currentIndex == targetIndex then
			break
		end
		visited[currentIndex] = true

		for _, edge in ipairs(adjacency[currentIndex] or {}) do
			local candidateDistance = currentDistance + edge.distance
			if candidateDistance < (distances[edge.index] or math.huge) then
				distances[edge.index] = candidateDistance
				previous[edge.index] = currentIndex
			end
		end
	end

	if distances[targetIndex] == math.huge then
		return nil
	end

	local path = {}
	local cursor = targetIndex
	while cursor do
		table.insert(path, 1, cursor)
		if cursor == startIndex then
			break
		end
		cursor = previous[cursor]
	end
	return path[1] == startIndex and path or nil
end

local function getCachedPathfindingGhostNavigationStep(match, currentPosition, targetPosition)
	if type(match) ~= "table" then
		return nil
	end

	local cache = match._ghostPathfindingCache
	if type(cache) ~= "table" then
		return nil
	end
	if typeof(cache.targetPosition) ~= "Vector3"
		or (cache.targetPosition - targetPosition).Magnitude > GHOST_NAV_PATH_TARGET_REUSE_DISTANCE then
		return nil
	end

	local waypoints = cache.waypoints
	if type(waypoints) ~= "table" or #waypoints == 0 then
		return nil
	end

	local index = math.max(tonumber(cache.index) or 2, 2)
	while index <= #waypoints and typeof(waypoints[index]) == "Vector3" and (waypoints[index] - currentPosition).Magnitude <= 2.25 do
		index += 1
	end
	cache.index = index

	local nextPosition = waypoints[index]
	if typeof(nextPosition) == "Vector3" and isGhostNavigationLineClear(match, currentPosition, nextPosition) then
		return nextPosition
	end
	return nil
end

local function computePathfindingGhostNavigationStep(match, currentPosition, targetPosition)
	if type(match) ~= "table" then
		return nil
	end

	local now = os.clock()
	local cache = match._ghostPathfindingCache
	if type(cache) == "table"
		and typeof(cache.targetPosition) == "Vector3"
		and (cache.targetPosition - targetPosition).Magnitude <= GHOST_NAV_PATH_TARGET_REUSE_DISTANCE
		and now - (tonumber(cache.computedAt) or 0) < GHOST_NAV_PATH_RECOMPUTE_INTERVAL then
		return getCachedPathfindingGhostNavigationStep(match, currentPosition, targetPosition)
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 1.6,
		AgentHeight = 6,
		AgentCanJump = false,
		AgentCanClimb = false,
		WaypointSpacing = 5,
		Costs = {
			Doorway = 0.2,
		},
	})

	local ok = pcall(function()
		path:ComputeAsync(currentPosition, targetPosition)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		match._ghostPathfindingCache = {
			computedAt = now,
			targetPosition = targetPosition,
			waypoints = {},
			index = 2,
		}
		return nil
	end

	local waypointPositions = {}
	for _, waypoint in ipairs(path:GetWaypoints()) do
		if typeof(waypoint.Position) == "Vector3" then
			table.insert(waypointPositions, clampGhostToInvestigationArea(match, waypoint.Position, currentPosition))
		end
	end

	match._ghostPathfindingCache = {
		computedAt = now,
		targetPosition = targetPosition,
		waypoints = waypointPositions,
		index = 2,
	}
	return getCachedPathfindingGhostNavigationStep(match, currentPosition, targetPosition)
end

local function setGhostNavigationMode(match, mode)
	if type(match) == "table" then
		match._ghostNavigationLastMode = tostring(mode or "")
	end
end

local function resolveGhostNavigationStep(match, currentPosition, targetPosition)
	if typeof(currentPosition) ~= "Vector3" or typeof(targetPosition) ~= "Vector3" then
		setGhostNavigationMode(match, "invalid_target")
		return targetPosition
	end
	if isGhostNavigationLineClear(match, currentPosition, targetPosition) then
		setGhostNavigationMode(match, "direct")
		return targetPosition
	end

	local nodes = collectGhostNavigationNodes(match)
	if #nodes == 0 then
		local pathStep = computePathfindingGhostNavigationStep(match, currentPosition, targetPosition)
		setGhostNavigationMode(match, pathStep and "pathfinding" or "blocked_no_nodes")
		return pathStep or currentPosition
	end

	local startIndex = findNearestVisibleGhostNavNode(match, nodes, currentPosition) or findNearestGhostNavNode(nodes, currentPosition)
	local targetIndex = findNearestVisibleGhostNavNode(match, nodes, targetPosition) or findNearestGhostNavNode(nodes, targetPosition)
	if not startIndex or not targetIndex then
		setGhostNavigationMode(match, "blocked_missing_node")
		return currentPosition
	end

	local adjacency = buildGhostNavigationAdjacency(match, nodes)
	local path = resolveGhostNavigationPath(adjacency, startIndex, targetIndex)
	if type(path) ~= "table" or #path == 0 then
		local pathStep = computePathfindingGhostNavigationStep(match, currentPosition, targetPosition)
		setGhostNavigationMode(match, pathStep and "pathfinding_no_node_path" or "blocked_no_node_path")
		return pathStep or currentPosition
	end

	local nextIndex = path[1]
	if #path >= 2 and (getNodePosition(nodes[nextIndex]) - currentPosition).Magnitude <= 2 then
		nextIndex = path[2]
	end

	local nextNode = nodes[nextIndex]
	if nextNode and isGhostNavigationLineClear(match, currentPosition, nextNode.Position) then
		setGhostNavigationMode(match, "node_path")
		return nextNode.Position
	end
	local pathStep = computePathfindingGhostNavigationStep(match, currentPosition, targetPosition)
	setGhostNavigationMode(match, pathStep and "pathfinding_fallback" or "blocked_next_node")
	return pathStep or currentPosition
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
	local origin = Vector3.new(position.X, position.Y + 100, position.Z)
	local direction = Vector3.new(0, -120, 0)
	for _ = 1, 16 do
		raycastParams.FilterDescendantsInstances = ignoreInstances
		local rayResult = Workspace:Raycast(origin, direction, raycastParams)
		if not rayResult then
			break
		end
		if not shouldIgnoreGhostNavigationHit(rayResult.Instance) then
			local hitY = rayResult.Position.Y
			if hitY < position.Y - 0.5 then
				return hitY
			end
		end
		table.insert(ignoreInstances, rayResult.Instance)
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

local function isRuntimeGhostUsable(ghostModel)
	if typeof(ghostModel) ~= "Instance" or not ghostModel:IsA("Model") then
		return false, "invalid_model"
	end
	if not ghostModel:FindFirstChildWhichIsA("BasePart", true) then
		return false, "missing_basepart"
	end
	local okExtents, extents = pcall(function()
		return ghostModel:GetExtentsSize()
	end)
	if okExtents and typeof(extents) == "Vector3" and extents.Magnitude <= 0.001 then
		return false, "zero_extents"
	end
	return true
end

local function resolveGhostRepairCFrame(match, container)
	if type(match) == "table" and typeof(match.ghostVisualCurrentPosition) == "Vector3" then
		return CFrame.new(match.ghostVisualCurrentPosition)
	end
	if type(match) == "table" and typeof(match.ghost) == "Instance" and match.ghost:IsA("Model") then
		local okPivot, pivot = pcall(function()
			return match.ghost:GetPivot()
		end)
		if okPivot and typeof(pivot) == "CFrame" then
			return pivot
		end
	end
	local spawnPart = type(match) == "table" and match.ghostSpawnPart or nil
	if not (typeof(spawnPart) == "Instance" and spawnPart:IsA("BasePart")) then
		spawnPart = resolveSpawnPart(container)
	end
	return spawnPart and spawnPart.CFrame or CFrame.new(0, 5, 0)
end

local function copyGhostRuntimeAttributes(source, target)
	if typeof(source) ~= "Instance" or typeof(target) ~= "Instance" then
		return
	end
	for attributeName, attributeValue in pairs(source:GetAttributes()) do
		if attributeName ~= "GhostType"
			and attributeName ~= "VisualGhostType"
			and attributeName ~= "VisualTemplateName"
			and attributeName ~= "PlaceholderVisual" then
			target:SetAttribute(attributeName, attributeValue)
		end
	end
end

local function repairRuntimeGhost(match, container, reason)
	if type(match) ~= "table" or typeof(container) ~= "Instance" then
		return false, "missing_container"
	end

	local previousGhost = match.ghost
	local ghostType = match.ghostType
	if type(ghostType) ~= "string" or ghostType == "" then
		ghostType = typeof(previousGhost) == "Instance" and previousGhost:GetAttribute("GhostType") or nil
	end
	if type(ghostType) ~= "string" or ghostType == "" then
		ghostType = DEFAULT_GHOST_TYPES[1]
	end
	match.ghostType = ghostType

	local spawnCFrame = resolveGhostRepairCFrame(match, container)
	local repairedGhost = createGhostFromTemplate(spawnCFrame, ghostType, {
		logicalGhostType = ghostType,
		initialAggression = tonumber(match.initialAggression),
		personalityType = match.personalityType,
	}) or createVisibleGhostPlaceholder(spawnCFrame, ghostType)
	copyGhostRuntimeAttributes(previousGhost, repairedGhost)
	repairedGhost:SetAttribute("PasrahGhostRepaired", true)
	repairedGhost:SetAttribute("PasrahGhostRepairReason", tostring(reason or "unknown"))

	local parentOk, parentErr = tryParentGhostModel(repairedGhost, container)
	if not parentOk then
		pcall(function()
			repairedGhost:Destroy()
		end)
		return false, parentErr
	end
	repairGhostTextureDonorSurfaceAppearance(
		repairedGhost,
		repairedGhost:GetAttribute("VisualGhostType") or ghostType,
		repairedGhost:GetAttribute("GhostType") or ghostType
	)

	match.ghost = repairedGhost
	if typeof(previousGhost) == "Instance" and previousGhost ~= repairedGhost then
		pcall(function()
			previousGhost:Destroy()
		end)
	end
	return true
end

local function ensureGhostPlacement(match)
	if type(match) ~= "table" or not match.ghost then
		return false
	end
	local container = resolveMatchContainer(match)
	if not container then
		return false
	end
	local usable, unusableReason = isRuntimeGhostUsable(match.ghost)
	if not usable then
		return repairRuntimeGhost(match, container, unusableReason)
	end
	if match.ghost.Parent ~= container then
		local parentOk, parentErr = tryParentGhostModel(match.ghost, container)
		if not parentOk then
			return repairRuntimeGhost(match, container, parentErr)
		end
	end
	repairGhostTextureDonorSurfaceAppearance(
		match.ghost,
		match.ghost:GetAttribute("VisualGhostType") or match.ghost.Name,
		match.ghost:GetAttribute("GhostType") or match.ghostType
	)
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
	refreshCanonicalGhostTemplates()
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
		local sc = 0
		for _ in pairs(sessions) do sc = sc + 1 end
		if sc == 0 then return end
		for matchId in pairs(sessions) do
			local liveMatch = select(1, self:_resolveLiveMatch(matchId))
			local ghostState = self._ghostService:GetGhostState(matchId)
			if liveMatch and ghostState then
				self:_syncGhostVisual(liveMatch, ghostState)
			end
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
	local transparency = math.min(GHOST_MAX_TRANSPARENCY, GHOST_VISUAL_TRANSPARENCY_BY_STATE[stateName] or 0.35)

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
	if not ensureGhostPlacement(match) then
		return false
	end
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
		if findContainingRoomPart(match, currentPosition) == nil and findContainingRoomPart(match, targetPosition) ~= nil then
			currentPosition = targetPosition
			match.ghostVisualCurrentPosition = targetPosition
			match.ghostVisualCurrentRoomId = roomId
		end

		targetPosition = clampGhostToInvestigationArea(match, targetPosition, currentPosition)
		if typeof(targetPosition) ~= "Vector3" then
			self:_applyGhostVisualState(match, ghostState)
			return true
		end
		targetPosition = resolveGhostNavigationStep(match, currentPosition, targetPosition)
		targetPosition = keepGhostOutsideSafeZones(match, currentPosition, targetPosition)

		match.ghost:SetAttribute("VisualNavigationMode", tostring(match._ghostNavigationLastMode or ""))
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

		resolvedPosition = clampGhostToInvestigationArea(match, resolvedPosition, currentPosition)
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
			if not ensureGhostPlacement(liveMatch) then
				lastReason = "ghost_placement_failed"
			end
			if liveMatch.ghostSpawnPart == nil then
				self:SelectGhostRoom(liveMatch)
			end
		end

		if self._ghostService:GetGhostState(matchId) ~= nil then
			local synced = self:_syncGhostVisualByMatch(liveMatch or matchId)
			if type(liveMatch) ~= "table" or synced or ensureGhostPlacement(liveMatch) then
				return liveMatch, matchId, nil
			end
			lastReason = "ghost_visual_sync_failed"
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
	if typeof(match.ghost) == "Instance" then
		if ensureGhostPlacement(match) then
			return match.ghost
		end
		match.ghost = nil
	elseif match.ghost then
		match.ghost = nil
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
