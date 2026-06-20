local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local EQUIPPED_TOOL_ATTRIBUTE = "PasrahEquippedToolType"
local PREPARATION_TOOL_ATTRIBUTE = "PasrahPreparationFocusTool"
local LOADOUT_TOOL_ATTR_PREFIX = "PasrahLoadoutTool"
local TOOL_USE_STAMP_ATTRIBUTE = "PasrahToolUseStamp"
local TOOL_LAST_SUCCESS_ATTRIBUTE = "PasrahToolLastSuccess"
local TOOL_LAST_EVENT_ATTRIBUTE = "PasrahToolLastEvent"
local FLASHLIGHT_ENABLED_ATTRIBUTE = "PasrahFlashlightEnabled"
local FLASHLIGHT_VISUAL_ALPHA_ATTRIBUTE = "PasrahFlashlightVisualAlpha"
local FLASHLIGHT_LIGHT_ENABLED_ATTRIBUTE = "PasrahFlashlightLightEnabled"
local CAMERA_SCAN_GHOST_ATTR = "PasrahCameraScanGhostType"
local CAMERA_SCAN_CANDIDATES_ATTR = "PasrahCameraScanCandidates"
local CAMERA_SCAN_EVIDENCE_ATTR = "PasrahCameraScanEvidence"
local CAMERA_SCAN_REASON_ATTR = "PasrahCameraScanReason"
local CAMERA_SCAN_STAMP_ATTR = "PasrahCameraScanStamp"
local CAMERA_PREVIEW_TARGET_ATTR = "PasrahCameraPreviewTarget"
local CAMERA_PREVIEW_DISTANCE_ATTR = "PasrahCameraPreviewDistance"
local CAMERA_PREVIEW_EVIDENCE_ATTR = "PasrahCameraPreviewEvidenceType"
local EMF_SCREEN_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "EMFScreenBillboardTemplate" }
local THERMO_SCREEN_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "ThermoScreenBillboardTemplate" }
local CAMERA_SCREEN_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "CameraScreenSurfaceTemplate" }
local FLASHLIGHT_LOCAL_SPOTLIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "FlashlightLocalSpotLightTemplate" }
local TOOL_USE_BURST_EMITTER_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "ToolUseBurstEmitterTemplate" }
local TOOL_USE_SMOKE_PLUME_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "ToolUseSmokePlumeEmitterTemplate" }
local TOOL_USE_HOLY_HALO_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "ToolUseHolyHaloEmitterTemplate" }
local TOOL_USE_SCAN_PULSE_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "ToolUseScanPulseEmitterTemplate" }
local TOOL_USE_PULSE_LIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "ToolVisuals", "ToolUsePulseLightTemplate" }

local FPV_ARMS_MODEL_NAME = "FPV_Arms"
local FPV_VIEW_ROOT_NAME = "FPV_ViewRoot"
local HELD_TOOL_MODEL_NAME = "FPV_HeldTool"
local HELD_FLASHLIGHT_MODEL_NAME = "FPV_FlashlightTool"
local REMOTE_HELD_TOOL_MODEL_NAME = "PasrahRemoteHeldTool"
local FLASHLIGHT_AIM_HOST_NAME = "FPV_FlashlightAimHost"
local EMF_SCREEN_HOST_NAME = "FPV_EMFScreenHost"
local THERMO_SCREEN_HOST_NAME = "FPV_ThermoScreenHost"
local FPV_GRIP_PART_GROUPS = {
	Left = {
		hand = { "FPV_LeftHand", "FPV_LeftArm", "LeftHand", "Left Arm" },
		lower = { "FPV_LeftLowerArm", "FPV_LeftArm", "LeftLowerArm", "Left Arm" },
		upper = { "FPV_LeftUpperArm", "LeftUpperArm" },
	},
	Right = {
		hand = { "FPV_RightHand", "FPV_RightArm", "RightHand", "Right Arm" },
		lower = { "FPV_RightLowerArm", "FPV_RightArm", "RightLowerArm", "Right Arm" },
		upper = { "FPV_RightUpperArm", "RightUpperArm" },
	},
}
local LOADOUT_SLOT_KEY_CODES = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
}

local DEFAULT_MOUNT_SPEC = {
	style = "SingleHand",
	hand = "Right",
	secondaryHand = "Left",
	twoHandBlend = 0.4,
	cframe = { x = 0.12, y = -0.24, z = -0.18, rx = -90, ry = 0, rz = 0 },
	holdSeconds = 2.2,
}

local DEFAULT_USE_ANIMATION = {
	duration = 0.24,
	push = 0.05,
	lift = 0.03,
	rollDeg = -6,
	pitchDeg = -8,
}

local DEFAULT_USE_VFX = {
	burst = 12,
	speed = 3,
	lifetime = 0.22,
	color = { r = 218, g = 232, b = 255 },
	style = "Auto",
}

local TOOL_USE_VFX_STYLE = {
	JejakEnergi = "EMF",
	KotakArwah = "Echo",
	SuhuMembeku = "Frost",
	BukuTerkutuk = "Arcane",
	BolaArwah = "Scan",
	GerakanGaib = "Static",
	Garam = "Salt",
	PilSanity = "Calm",
	Salib = "Holy",
	Dupa = "Smoke",
	Flashlight = "Light",
}

local USE_VFX_STYLES = {
	Default = {
		texture = "rbxassetid://6489023589",
		spread = 22,
		acceleration = Vector3.new(0, 2.2, 0),
		drag = 2.1,
		lightEmission = 0.45,
		sizeStart = 0.11,
		sizeEnd = 0.02,
		pulseBrightness = 2.4,
		pulseRange = 5.2,
	},
	EMF = {
		texture = "rbxassetid://6489023589",
		spread = 18,
		acceleration = Vector3.new(0, 0.8, 0),
		drag = 1.6,
		lightEmission = 0.58,
		sizeStart = 0.13,
		sizeEnd = 0.03,
		pulseBrightness = 2.9,
		pulseRange = 5.8,
	},
	Frost = {
		texture = "rbxassetid://6489023589",
		spread = 30,
		acceleration = Vector3.new(0, -1.2, 0),
		drag = 2.8,
		lightEmission = 0.36,
		sizeStart = 0.1,
		sizeEnd = 0.02,
		pulseBrightness = 1.8,
		pulseRange = 4.6,
	},
	Echo = {
		texture = "rbxassetid://6489023589",
		spread = 16,
		acceleration = Vector3.new(0, 0.3, 0),
		drag = 1.3,
		lightEmission = 0.4,
		sizeStart = 0.16,
		sizeEnd = 0.03,
		pulseBrightness = 2.2,
		pulseRange = 5.1,
	},
	Arcane = {
		texture = "rbxassetid://6489023589",
		spread = 26,
		acceleration = Vector3.new(0, 1.8, 0),
		drag = 1.8,
		lightEmission = 0.52,
		sizeStart = 0.14,
		sizeEnd = 0.03,
		pulseBrightness = 2.8,
		pulseRange = 5.6,
	},
	Scan = {
		texture = "rbxassetid://6489023589",
		spread = 12,
		acceleration = Vector3.new(0, 0, 0),
		drag = 0.8,
		lightEmission = 0.62,
		sizeStart = 0.12,
		sizeEnd = 0.01,
		pulseBrightness = 2.6,
		pulseRange = 6,
	},
	Static = {
		texture = "rbxassetid://6489023589",
		spread = 24,
		acceleration = Vector3.new(0, 1.1, 0),
		drag = 1.4,
		lightEmission = 0.5,
		sizeStart = 0.12,
		sizeEnd = 0.02,
		pulseBrightness = 2.3,
		pulseRange = 5.2,
	},
	Salt = {
		texture = "rbxassetid://6489023589",
		spread = 34,
		acceleration = Vector3.new(0, -1.6, 0),
		drag = 3.2,
		lightEmission = 0.28,
		sizeStart = 0.09,
		sizeEnd = 0.02,
		pulseBrightness = 1.7,
		pulseRange = 4.2,
	},
	Calm = {
		texture = "rbxassetid://6489023589",
		spread = 20,
		acceleration = Vector3.new(0, 1.2, 0),
		drag = 1.9,
		lightEmission = 0.38,
		sizeStart = 0.1,
		sizeEnd = 0.02,
		pulseBrightness = 1.9,
		pulseRange = 4.5,
	},
	Holy = {
		texture = "rbxassetid://6489023589",
		spread = 28,
		acceleration = Vector3.new(0, 2.8, 0),
		drag = 2.4,
		lightEmission = 0.64,
		sizeStart = 0.17,
		sizeEnd = 0.04,
		pulseBrightness = 3.4,
		pulseRange = 6.4,
	},
	Smoke = {
		texture = "rbxassetid://241685934",
		spread = 24,
		acceleration = Vector3.new(0, 2.6, 0),
		drag = 0.85,
		lightEmission = 0.2,
		sizeStart = 0.16,
		sizeEnd = 0.08,
		pulseBrightness = 1.4,
		pulseRange = 3.8,
	},
	Light = {
		texture = "rbxassetid://6489023589",
		spread = 12,
		acceleration = Vector3.new(0, 0.4, 0),
		drag = 1.2,
		lightEmission = 0.66,
		sizeStart = 0.1,
		sizeEnd = 0.02,
		pulseBrightness = 2.8,
		pulseRange = 6.2,
	},
}

local USE_VFX_STYLE_ALIAS = {
	default = "Default",
	emf = "EMF",
	echo = "Echo",
	frost = "Frost",
	arcane = "Arcane",
	scan = "Scan",
	static = "Static",
	salt = "Salt",
	calm = "Calm",
	holy = "Holy",
	smoke = "Smoke",
	light = "Light",
}

local DEFAULT_FLASHLIGHT_LENS = {
	onColor = Color3.fromRGB(255, 232, 186),
	offColor = Color3.fromRGB(120, 132, 148),
	onTransparency = 0.04,
	offTransparency = 0.34,
}

local DEFAULT_FLASHLIGHT_LOCAL_LIGHT = {
	brightness = 1.35,
	range = 12,
	angle = 24,
	offBrightness = 0,
	offRange = 2,
	offAngle = 12,
	fadeInSpeed = 10,
	fadeOutSpeed = 7,
	color = Color3.fromRGB(255, 244, 214),
}

local CAMERA_SCREEN_THEME = {
	background = Color3.fromRGB(18, 28, 34),
	grid = Color3.fromRGB(52, 94, 102),
	accent = Color3.fromRGB(255, 72, 72),
	text = Color3.fromRGB(230, 242, 244),
}

local EMF_SCREEN_THEME = {
	background = Color3.fromRGB(20, 24, 32),
	accent = Color3.fromRGB(92, 212, 255),
	text = Color3.fromRGB(230, 238, 248),
}

local THERMO_SCREEN_THEME = {
	background = Color3.fromRGB(22, 32, 28),
	cold = Color3.fromRGB(128, 212, 255),
	warm = Color3.fromRGB(255, 178, 112),
	text = Color3.fromRGB(236, 244, 240),
}

local CAMERA_PREVIEW_SAMPLE_PATTERN = {
	Vector2.new(0, 0),
	Vector2.new(-0.34, 0),
	Vector2.new(0.34, 0),
	Vector2.new(0, -0.24),
	Vector2.new(0, 0.24),
	Vector2.new(-0.26, -0.2),
	Vector2.new(0.26, -0.2),
	Vector2.new(-0.26, 0.2),
	Vector2.new(0.26, 0.2),
}
local CAMERA_PREVIEW_RAY_DISTANCE = 260
local CAMERA_SCREEN_HOST_NAME = "FPV_CameraScreenHost"
local CAMERA_SCREEN_HOST_OFFSET = Vector3.new(0.08, -0.04, -0.24)
local CAMERA_PREVIEW_RENDERED_ATTR = "PasrahCameraPreviewRenderedCount"
local INSTRUMENT_RAY_DISTANCE = 90
local INSTRUMENT_PROBE_INTERVAL = 0.09
local INSTRUMENT_SAMPLE_PATTERN = {
	Vector2.new(0, 0),
	Vector2.new(-0.22, 0),
	Vector2.new(0.22, 0),
	Vector2.new(0, -0.2),
	Vector2.new(0, 0.2),
	Vector2.new(-0.18, -0.16),
	Vector2.new(0.18, -0.16),
	Vector2.new(-0.18, 0.16),
	Vector2.new(0.18, 0.16),
}

local SCREEN_FACE_NORMALS = {
	{ face = Enum.NormalId.Front, normal = Vector3.new(0, 0, -1) },
	{ face = Enum.NormalId.Back, normal = Vector3.new(0, 0, 1) },
	{ face = Enum.NormalId.Right, normal = Vector3.new(1, 0, 0) },
	{ face = Enum.NormalId.Left, normal = Vector3.new(-1, 0, 0) },
	{ face = Enum.NormalId.Top, normal = Vector3.new(0, 1, 0) },
	{ face = Enum.NormalId.Bottom, normal = Vector3.new(0, -1, 0) },
}

local function tokenizeName(value)
	local text = string.lower(tostring(value or ""))
	local tokens = {}
	for token in string.gmatch(text, "[%a%d]+") do
		tokens[token] = true
	end
	return tokens
end

local function resolveToolScreenPart(model, primaryPart, preferredTokens)
	if not (model and model:IsA("Model")) then
		return primaryPart
	end
	local camera = Workspace.CurrentCamera
	local cameraPosition = camera and camera.CFrame.Position or nil
	local bestPart = primaryPart
	local bestScore = -math.huge
	local bestTokenPart = nil
	local bestTokenScore = -math.huge
	local tokenLookup = {}
	for _, token in ipairs(preferredTokens or {}) do
		tokenLookup[string.lower(tostring(token))] = true
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local score = 0
			local tokens = tokenizeName(descendant.Name)
			local matchedToken = false
			for token in pairs(tokenLookup) do
				if tokens[token] then
					score += 60
					matchedToken = true
				end
			end

			local size = descendant.Size
			local maxAxis = math.max(size.X, size.Y, size.Z)
			local minAxis = math.min(size.X, size.Y, size.Z)
			if minAxis > 0 then
				local flatRatio = maxAxis / minAxis
				score += math.clamp(flatRatio, 1, 8) * 4
			end
			score += math.min(24, maxAxis * 20)

			if cameraPosition then
				local distance = (cameraPosition - descendant.Position).Magnitude
				score += math.max(0, 24 - distance * 4)
			end

			if descendant == primaryPart then
				score += 4
			end

			if score > bestScore then
				bestScore = score
				bestPart = descendant
			end
			if matchedToken and score > bestTokenScore then
				bestTokenScore = score
				bestTokenPart = descendant
			end
		end
	end

	if bestTokenPart then
		return bestTokenPart
	end
	return primaryPart or bestPart
end

local function orientSurfaceToCamera(surfaceGui, hostPart)
	if not (surfaceGui and surfaceGui:IsA("SurfaceGui") and hostPart and hostPart:IsA("BasePart")) then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local toCamera = camera.CFrame.Position - hostPart.Position
	if toCamera.Magnitude <= 0.001 then
		return
	end
	local look = toCamera.Unit
	local bestFace = Enum.NormalId.Front
	local bestDot = -math.huge
	for _, entry in ipairs(SCREEN_FACE_NORMALS) do
		local worldNormal = hostPart.CFrame:VectorToWorldSpace(entry.normal)
		local dot = worldNormal:Dot(look)
		if dot > bestDot then
			bestDot = dot
			bestFace = entry.face
		end
	end
	if surfaceGui.Face ~= bestFace then
		surfaceGui.Face = bestFace
	end
end

local resolveVisualTemplate

local function cloneBillboardTemplateAsSurfaceGui(path, name)
	local template = resolveVisualTemplate(path)
	if not template then
		return nil
	end
	if template:IsA("SurfaceGui") then
		local clone = template:Clone()
		clone.Name = name
		return clone
	end
	if not template:IsA("BillboardGui") then
		return nil
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = name
	for _, child in ipairs(template:GetChildren()) do
		child:Clone().Parent = surfaceGui
	end
	return surfaceGui
end

local function ensureConfiguredScreenHostPart(mounted, hostName, screenConfig)
	if not (mounted and mounted.model and screenConfig and screenConfig.hostCFrame) then
		return nil
	end
	local host = mounted.model:FindFirstChild(hostName)
	if host and not host:IsA("BasePart") then
		host:Destroy()
		host = nil
	end
	if not host then
		host = Instance.new("Part")
		host.Name = hostName
		host.Anchored = true
		host.CanCollide = false
		host.CanTouch = false
		host.CanQuery = false
		host.CastShadow = false
		host.Massless = true
		host.Material = Enum.Material.SmoothPlastic
		host.Color = Color3.fromRGB(0, 255, 220)
		host.Transparency = 1
		host.Parent = mounted.model
	end
	host.Size = screenConfig.hostSize or Vector3.new(0.22, 0.01, 0.12)
	host.CFrame = mounted.model:GetPivot() * screenConfig.hostCFrame
	return host
end

local function applySurfaceGuiContentRotation(surfaceGui, screenConfig)
	if not (surfaceGui and surfaceGui:IsA("SurfaceGui")) then
		return
	end
	local rotation = tonumber(screenConfig and screenConfig.contentRotationDeg) or 0
	for _, child in ipairs(surfaceGui:GetChildren()) do
		if child:IsA("GuiObject") then
			child.AnchorPoint = Vector2.new(0.5, 0.5)
			child.Position = UDim2.fromScale(0.5, 0.5)
			child.Size = UDim2.fromScale(1, 1)
			child.Rotation = rotation
		end
	end
end

local function configureSurfaceGuiForScreen(surfaceGui, screenConfig, fallbackFace, fallbackCanvasSize, fallbackPixelsPerStud)
	if not (surfaceGui and surfaceGui:IsA("SurfaceGui")) then
		return
	end
	surfaceGui.Face = (screenConfig and screenConfig.face) or fallbackFace or Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = (screenConfig and screenConfig.pixelsPerStud) or fallbackPixelsPerStud or 180
	surfaceGui.CanvasSize = (screenConfig and screenConfig.canvasSize) or fallbackCanvasSize or Vector2.new(180, 120)
	surfaceGui.LightInfluence = 0
	surfaceGui.AlwaysOnTop = screenConfig == nil or screenConfig.alwaysOnTop ~= false
	applySurfaceGuiContentRotation(surfaceGui, screenConfig)
end

local function orientSpotLightToCameraLook(spotlight, hostPart)
	if not (spotlight and spotlight:IsA("SpotLight") and hostPart and hostPart:IsA("BasePart")) then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local look = camera.CFrame.LookVector
	if look.Magnitude <= 0.001 then
		return
	end
	look = look.Unit
	if hostPart.Name == FLASHLIGHT_AIM_HOST_NAME then
		local hostPosition = camera.CFrame.Position + (camera.CFrame.LookVector * 0.75)
		hostPart.CFrame = CFrame.lookAt(hostPosition, hostPosition + look, camera.CFrame.UpVector)
		spotlight.Face = Enum.NormalId.Front
		return
	end
	local bestFace = Enum.NormalId.Front
	local bestDot = -math.huge
	for _, entry in ipairs(SCREEN_FACE_NORMALS) do
		local worldNormal = hostPart.CFrame:VectorToWorldSpace(entry.normal)
		local dot = worldNormal:Dot(look)
		if dot > bestDot then
			bestDot = dot
			bestFace = entry.face
		end
	end
	if spotlight.Face ~= bestFace then
		spotlight.Face = bestFace
	end
end

local function safeRequire(moduleScript)
	if not moduleScript then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

local function resolveSharedGameData()
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	return shared and shared:FindFirstChild("GameData") or nil
end

local GAME_DATA = resolveSharedGameData()
local TOOL_VISUAL_CONFIG = (safeRequire(GAME_DATA and GAME_DATA:FindFirstChild("ToolVisualConfig")) or {}).tools or {}
local FLASHLIGHT_CONFIG = safeRequire(GAME_DATA and GAME_DATA:FindFirstChild("FlashlightConfig")) or {}
local TOOL_USAGE_RULES = safeRequire(GAME_DATA and GAME_DATA:FindFirstChild("ToolUsageRules")) or nil

local FLASHLIGHT_LENS_CONFIG = type(FLASHLIGHT_CONFIG.lens) == "table" and FLASHLIGHT_CONFIG.lens or DEFAULT_FLASHLIGHT_LENS
local FLASHLIGHT_LIGHT_CONFIG = type(FLASHLIGHT_CONFIG.localLight) == "table"
	and FLASHLIGHT_CONFIG.localLight
	or DEFAULT_FLASHLIGHT_LOCAL_LIGHT
local FLASHLIGHT_MOTION_CONFIG = type(FLASHLIGHT_CONFIG.motion) == "table" and FLASHLIGHT_CONFIG.motion or {}
local STATIC_HOLD_TOOLS = FLASHLIGHT_MOTION_CONFIG.staticHoldTools == true

local function resolveToolsFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	return models and models:FindFirstChild("Tools") or nil
end

function resolveVisualTemplate(path)
	local node = ReplicatedStorage
	for _, segment in ipairs(path or {}) do
		if typeof(node) ~= "Instance" then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local function cloneVisualTemplate(path, name)
	local template = resolveVisualTemplate(path)
	if template then
		local clone = template:Clone()
		clone.Name = name
		return clone
	end
	return nil
end

local missingVisualTemplateWarnings = {}

local function warnMissingVisualTemplate(templateName)
	if missingVisualTemplateWarnings[templateName] then
		return
	end
	missingVisualTemplateWarnings[templateName] = true
	warn("[ToolVisualController] Missing authored visual template: " .. tostring(templateName))
end

local TOOLS_FOLDER = resolveToolsFolder()
local state

local function coerceVector3(value)
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

local function coerceVector2(value)
	if typeof(value) == "Vector2" then
		return value
	end
	if type(value) ~= "table" then
		return nil
	end
	local x = tonumber(value.x or value.X or value[1])
	local y = tonumber(value.y or value.Y or value[2])
	if x and y then
		return Vector2.new(x, y)
	end
	return nil
end

local function coerceColor3(value, fallback)
	if typeof(value) == "Color3" then
		return value
	end
	if type(value) ~= "table" then
		return fallback
	end
	local default = fallback or Color3.fromRGB(218, 232, 255)
	local r = math.clamp(math.floor(tonumber(value.r or value.R or value[1]) or math.floor(default.R * 255)), 0, 255)
	local g = math.clamp(math.floor(tonumber(value.g or value.G or value[2]) or math.floor(default.G * 255)), 0, 255)
	local b = math.clamp(math.floor(tonumber(value.b or value.B or value[3]) or math.floor(default.B * 255)), 0, 255)
	return Color3.fromRGB(r, g, b)
end

local function cframeFromSpec(spec)
	if typeof(spec) == "CFrame" then
		return spec
	end
	if type(spec) ~= "table" then
		return CFrame.new()
	end
	local x = tonumber(spec.x or spec.X or spec[1]) or 0
	local y = tonumber(spec.y or spec.Y or spec[2]) or 0
	local z = tonumber(spec.z or spec.Z or spec[3]) or 0
	local rx = math.rad(tonumber(spec.rx or spec.RX or spec[4]) or 0)
	local ry = math.rad(tonumber(spec.ry or spec.RY or spec[5]) or 0)
	local rz = math.rad(tonumber(spec.rz or spec.RZ or spec[6]) or 0)
	return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
end

local function normalizeViewportTargetSpec(value)
	if type(value) ~= "table" then
		return nil
	end
	local x = tonumber(value.x or value.X or value[1])
	local y = tonumber(value.y or value.Y or value[2])
	if not (x and y) then
		return nil
	end
	return {
		x = math.clamp(x, 0.05, 0.95),
		y = math.clamp(y, 0.05, 0.95),
	}
end

local function normalizeScreenSpec(value)
	if type(value) ~= "table" then
		return nil
	end
	local mode = type(value.mode) == "string" and value.mode or nil
	local hostCFrameSpec = value.hostCFrame or value.HostCFrame or value.cframe or value.CFrame
	local hostCFrame = hostCFrameSpec and cframeFromSpec(hostCFrameSpec) or nil
	local faceName = type(value.face) == "string" and value.face or "Front"
	local face = Enum.NormalId[faceName] or Enum.NormalId.Front
	return {
		enabled = value.enabled ~= false,
		mode = mode,
		size = coerceVector2(value.size or value.Size),
		studsOffset = coerceVector3(value.studsOffset or value.StudsOffset or value.offset or value.Offset),
		hostCFrame = hostCFrame,
		hostSize = coerceVector3(value.hostSize or value.HostSize or value.sizeStuds or value.SizeStuds),
		canvasSize = coerceVector2(value.canvasSize or value.CanvasSize),
		pixelsPerStud = math.max(1, tonumber(value.pixelsPerStud or value.PixelsPerStud) or 180),
		contentRotationDeg = tonumber(value.contentRotationDeg or value.ContentRotationDeg or value.rotationDeg or value.RotationDeg) or 0,
		face = face,
		alwaysOnTop = value.alwaysOnTop ~= false,
	}
end

local function normalizeFpvArmSideSpec(value)
	if type(value) ~= "table" then
		return nil
	end
	local x = tonumber(value.x or value.X or value[1]) or 0
	local y = tonumber(value.y or value.Y or value[2]) or 0
	local z = tonumber(value.z or value.Z or value[3]) or 0
	local rx = math.rad(tonumber(value.rx or value.RX or value[4]) or 0)
	local ry = math.rad(tonumber(value.ry or value.RY or value[5]) or 0)
	local rz = math.rad(tonumber(value.rz or value.RZ or value[6]) or 0)
	return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
end

local function normalizeFpvArmsSpec(value)
	if type(value) ~= "table" then
		return nil
	end
	local left = normalizeFpvArmSideSpec(value.Left or value.left)
	local right = normalizeFpvArmSideSpec(value.Right or value.right)
	if not (left or right) then
		return nil
	end
	return {
		handScale = math.max(0.05, tonumber(value.handScale or value.HandScale or value.scale) or 1),
		visible = value.visible ~= false,
		hideUpper = value.hideUpper ~= false,
		lowerCFrame = cframeFromSpec(value.lowerCFrame or value.LowerCFrame or value.lowerOffset),
		Left = left,
		Right = right,
	}
end

local function normalizeMountSpec(spec)
	local mount = type(spec) == "table" and spec or DEFAULT_MOUNT_SPEC
	return {
		style = mount.style == "TwoHanded" and "TwoHanded" or "SingleHand",
		hand = mount.hand == "Left" and "Left" or "Right",
		secondaryHand = mount.secondaryHand == "Right" and "Right" or "Left",
		twoHandBlend = math.clamp(tonumber(mount.twoHandBlend) or DEFAULT_MOUNT_SPEC.twoHandBlend, 0, 0.8),
		holdSeconds = math.max(0.6, tonumber(mount.holdSeconds) or DEFAULT_MOUNT_SPEC.holdSeconds),
		viewportBias = type(mount.viewportBias) == "string" and mount.viewportBias or nil,
		viewportTarget = normalizeViewportTargetSpec(mount.viewportTarget),
		handTransparency = math.clamp(tonumber(mount.handTransparency) or 0, 0, 1),
		lowerArmTransparency = math.clamp(tonumber(mount.lowerArmTransparency) or 0, 0, 1),
		upperArmTransparency = math.clamp(tonumber(mount.upperArmTransparency) or 0.65, 0, 1),
		cameraSpace = mount.cameraSpace == true,
		fitToViewport = mount.fitToViewport ~= false,
		cameraCFrame = cframeFromSpec(mount.cameraCFrame),
		cframe = cframeFromSpec(mount.cframe or DEFAULT_MOUNT_SPEC.cframe),
		fpvArms = normalizeFpvArmsSpec(mount.fpvArms),
	}
end

local function ensurePrimaryPart(model)
	if not (model and model:IsA("Model")) then
		return nil
	end
	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end
	local basePart = model:FindFirstChildWhichIsA("BasePart", true)
	if basePart then
		model.PrimaryPart = basePart
	end
	return basePart
end

local function getRenderableBoundsSize(model)
	if not (model and model:IsA("Model")) then
		return nil
	end
	local maxSize = Vector3.zero
	local foundRenderable = false
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart")
			and descendant.Transparency < 0.98
			and descendant.Name ~= FLASHLIGHT_AIM_HOST_NAME
			and descendant.Name ~= CAMERA_SCREEN_HOST_NAME
			and descendant.Name ~= EMF_SCREEN_HOST_NAME
			and descendant.Name ~= THERMO_SCREEN_HOST_NAME
		then
			local size = descendant.Size
			maxSize = Vector3.new(
				math.max(maxSize.X, size.X),
				math.max(maxSize.Y, size.Y),
				math.max(maxSize.Z, size.Z)
			)
			foundRenderable = true
		end
	end
	if foundRenderable then
		return maxSize
	end
	return nil
end

local function clampModelBounds(model, targetBounds)
	if not (model and model:IsA("Model")) then
		return
	end
	if typeof(targetBounds) ~= "Vector3" then
		return
	end
	local renderableExtents = getRenderableBoundsSize(model)
	local okExtents, extents = true, renderableExtents
	if typeof(extents) ~= "Vector3" then
		okExtents, extents = pcall(function()
			return model:GetExtentsSize()
		end)
	end
	if not okExtents or typeof(extents) ~= "Vector3" then
		return
	end
	if extents.X <= 0 or extents.Y <= 0 or extents.Z <= 0 then
		return
	end
	local factor = math.min(
		targetBounds.X / extents.X,
		targetBounds.Y / extents.Y,
		targetBounds.Z / extents.Z
	)
	if factor <= 0 then
		return
	end
	if factor >= 0.98 and factor <= 1.02 then
		return
	end
	local currentScale = 1
	local okScale, modelScale = pcall(function()
		return model:GetScale()
	end)
	if okScale and type(modelScale) == "number" and modelScale > 0 then
		currentScale = modelScale
	end
	pcall(function()
		model:ScaleTo(math.max(0.001, currentScale * factor))
	end)
end

local function sanitizeModel(model)
	if not (model and model:IsA("Model")) then
		return
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("Humanoid") or descendant:IsA("AnimationController") or descendant:IsA("Animator") then
			descendant:Destroy()
		elseif descendant:IsA("Sound") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CastShadow = false
			descendant.Massless = true
		end
	end
end

local function buildFallbackModel(toolType)
	local model = Instance.new("Model")
	model.Name = tostring(toolType or "Tool")

	local body = Instance.new("Part")
	body.Name = "Handle"
	body.Size = Vector3.new(0.22, 0.22, 0.42)
	body.Color = Color3.fromRGB(90, 96, 112)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.CastShadow = false
	body.Massless = true
	body.Parent = model
	model.PrimaryPart = body

	return model
end

local function cloneToolModel(toolType, targetBounds)
	local template = TOOLS_FOLDER and TOOLS_FOLDER:FindFirstChild(toolType)
	local model = nil
	if template and template:IsA("Model") then
		model = template:Clone()
	elseif template and template:IsA("BasePart") then
		model = Instance.new("Model")
		model.Name = toolType
		template:Clone().Parent = model
	else
		model = buildFallbackModel(toolType)
	end

	sanitizeModel(model)
	ensurePrimaryPart(model)
	if targetBounds then
		clampModelBounds(model, targetBounds)
	end
	ensurePrimaryPart(model)
	return model
end

local function applyInventoryMeshAssetId(model, inventoryModelAssetId)
	if not (model and model:IsA("Model")) or type(inventoryModelAssetId) ~= "string" or inventoryModelAssetId == "" then
		return
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			pcall(function()
				descendant.MeshId = inventoryModelAssetId
			end)
		elseif descendant:IsA("SpecialMesh") then
			pcall(function()
				descendant.MeshId = inventoryModelAssetId
			end)
		end
	end
end

local function getFpvArmsModel()
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local fpvArms = camera:FindFirstChild(FPV_ARMS_MODEL_NAME)
	if fpvArms and fpvArms:IsA("Model") then
		return fpvArms
	end
	return nil
end

local function findFpvGripPart(fpvArms, hand, role)
	if not fpvArms then
		return nil
	end
	local group = FPV_GRIP_PART_GROUPS[hand]
	local names = group and group[role]
	if type(names) ~= "table" then
		return nil
	end
	for _, name in ipairs(names) do
		local part = fpvArms:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function resetFpvGripPose(fpvArms)
	if not fpvArms then
		return nil
	end
	local viewRoot = fpvArms:FindFirstChild(FPV_VIEW_ROOT_NAME)
	if not (viewRoot and viewRoot:IsA("BasePart")) then
		return nil
	end

	for _, part in ipairs(fpvArms:GetChildren()) do
		if part:IsA("BasePart") and part ~= viewRoot then
			if state.fpvBaseLocalCFrames[part] == nil then
				state.fpvBaseLocalCFrames[part] = viewRoot.CFrame:ToObjectSpace(part.CFrame)
				state.fpvBaseTransparency[part] = part.Transparency
			end
			local localCFrame = state.fpvBaseLocalCFrames[part]
			if typeof(localCFrame) == "CFrame" then
				part.CFrame = viewRoot.CFrame * localCFrame
			end
			part.Transparency = 1
		end
	end
	return viewRoot
end

local function setGripPartVisible(part, transparency)
	if not (part and part:IsA("BasePart")) then
		return
	end
	part.Transparency = math.clamp(tonumber(transparency) or 0, 0, 1)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.LocalTransparencyModifier = 0
end

local function poseGripArm(fpvArms, hand, gripPosition, focusPosition, camera, mount)
	local sideSign = hand == "Left" and -1 or 1
	local handPart = findFpvGripPart(fpvArms, hand, "hand")
	local lowerPart = findFpvGripPart(fpvArms, hand, "lower")
	local upperPart = findFpvGripPart(fpvArms, hand, "upper")
	if not (handPart and camera) then
		return
	end

	local handForward = (focusPosition - gripPosition)
	if handForward.Magnitude <= 0.001 then
		handForward = camera.CFrame.LookVector
	end
	handForward = handForward.Unit
	local palmRoll = math.rad(hand == "Left" and -16 or 16)
	handPart.CFrame = CFrame.lookAt(gripPosition, gripPosition + handForward, camera.CFrame.UpVector)
		* CFrame.Angles(math.rad(-8), math.rad(sideSign * 10), palmRoll)
	setGripPartVisible(handPart, mount and mount.handTransparency or 0)

	if lowerPart and lowerPart ~= handPart then
		local elbowPosition = gripPosition
			- camera.CFrame.UpVector * 0.23
			+ camera.CFrame.RightVector * (sideSign * 0.10)
			+ camera.CFrame.LookVector * 0.08
		lowerPart.CFrame = CFrame.lookAt(elbowPosition, gripPosition, camera.CFrame.UpVector)
			* CFrame.Angles(math.rad(82), 0, math.rad(sideSign * 8))
		setGripPartVisible(lowerPart, mount and mount.lowerArmTransparency or 0)
	end

	if upperPart and upperPart ~= lowerPart and upperPart ~= handPart then
		local shoulderPosition = gripPosition
			- camera.CFrame.UpVector * 0.46
			+ camera.CFrame.RightVector * (sideSign * 0.22)
			+ camera.CFrame.LookVector * 0.14
		upperPart.CFrame = CFrame.lookAt(shoulderPosition, gripPosition, camera.CFrame.UpVector)
			* CFrame.Angles(math.rad(76), 0, math.rad(sideSign * 10))
		setGripPartVisible(upperPart, mount and mount.upperArmTransparency or 0.65)
	end
end

local function scaleFpvGripPart(part, scale)
	if not (part and part:IsA("BasePart")) then
		return
	end
	local baseSize = part:GetAttribute("PasrahFpvBaseSize")
	if typeof(baseSize) ~= "Vector3" then
		baseSize = part.Size
		part:SetAttribute("PasrahFpvBaseSize", baseSize)
	end
	part.Size = baseSize * math.max(0.05, tonumber(scale) or 1)
end

local function applyCameraSpaceFpvArmPose(fpvArms, mount, camera)
	local armPose = mount and mount.fpvArms
	if not (fpvArms and armPose and camera) then
		return false
	end
	local scale = tonumber(armPose.handScale) or 1
	local applied = false
	for _, hand in ipairs({ "Left", "Right" }) do
		local sideCFrame = armPose[hand]
		if typeof(sideCFrame) == "CFrame" then
			local handPart = findFpvGripPart(fpvArms, hand, "hand")
			local lowerPart = findFpvGripPart(fpvArms, hand, "lower")
			local upperPart = findFpvGripPart(fpvArms, hand, "upper")
			local worldCFrame = camera.CFrame * sideCFrame
			if handPart then
				scaleFpvGripPart(handPart, scale)
				handPart.CFrame = worldCFrame
				setGripPartVisible(handPart, armPose.visible == false and 1 or mount.handTransparency)
				applied = true
			end
			if lowerPart and lowerPart ~= handPart then
				scaleFpvGripPart(lowerPart, scale)
				lowerPart.CFrame = worldCFrame * (armPose.lowerCFrame or CFrame.new(0, -0.32, 0.10))
				setGripPartVisible(lowerPart, armPose.visible == false and 1 or mount.lowerArmTransparency)
				applied = true
			end
			if upperPart and upperPart ~= lowerPart and upperPart ~= handPart then
				upperPart.Transparency = armPose.hideUpper ~= false and 1 or mount.upperArmTransparency
				upperPart.LocalTransparencyModifier = 0
			end
		end
	end
	return applied
end

local function applyFpvToolGripPose(fpvArms, mounted)
	if not (fpvArms and mounted and mounted.model and mounted.profile and mounted.profile.mount) then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local okPivot, toolPivot = pcall(function()
		return mounted.model:GetPivot()
	end)
	if not okPivot or typeof(toolPivot) ~= "CFrame" then
		return
	end

	local okExtents, extents = pcall(function()
		return mounted.model:GetExtentsSize()
	end)
	if not okExtents or typeof(extents) ~= "Vector3" then
		extents = Vector3.new(0.35, 0.35, 0.35)
	end

	local mount = mounted.profile.mount
	if applyCameraSpaceFpvArmPose(fpvArms, mount, camera) then
		return
	end
	local primaryHand = mount.hand == "Left" and "Left" or "Right"
	local secondaryHand = primaryHand == "Left" and "Right" or "Left"
	if mount.style == "TwoHanded" and mount.secondaryHand then
		secondaryHand = mount.secondaryHand == "Right" and "Right" or "Left"
	end

	local halfWidth = math.clamp(extents.X * 0.34, 0.08, 0.22)
	local lowerOffset = math.clamp(extents.Y * 0.18, 0.04, 0.13)
	local forwardOffset = math.clamp(extents.Z * 0.25, 0.04, 0.16)
	local focusPosition = toolPivot.Position
	fpvArms:SetAttribute("PasrahCurrentHeldToolType", mounted.toolType)
	local function gripPositionFor(hand, secondary)
		local sideSign = hand == "Left" and -1 or 1
		local width = secondary and (halfWidth * 1.05) or (halfWidth * 0.18)
		return focusPosition
			+ camera.CFrame.RightVector * (sideSign * width)
			- camera.CFrame.UpVector * lowerOffset
			+ camera.CFrame.LookVector * forwardOffset
	end

	poseGripArm(fpvArms, primaryHand, gripPositionFor(primaryHand, false), focusPosition, camera, mount)
	if mount.style == "TwoHanded" then
		poseGripArm(fpvArms, secondaryHand, gripPositionFor(secondaryHand, true), focusPosition, camera, mount)
	end
end

local function getHandPart(fpvArms, hand)
	if not fpvArms then
		return nil
	end
	if hand == "Left" then
		for _, name in ipairs({ "FPV_LeftHand", "FPV_LeftArm", "LeftHand", "Left Arm" }) do
			local part = fpvArms:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				return part
			end
		end
		return nil
	end

	for _, name in ipairs({ "FPV_RightHand", "FPV_RightArm", "RightHand", "Right Arm" }) do
		local part = fpvArms:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function resolveToolProfile(toolType)
	local raw = type(toolType) == "string" and TOOL_VISUAL_CONFIG[toolType] or nil
	if type(raw) ~= "table" then
		raw = {}
	end

	local mount = type(raw.mount) == "table" and raw.mount or DEFAULT_MOUNT_SPEC
	local useAnimation = type(raw.useAnimation) == "table" and raw.useAnimation or DEFAULT_USE_ANIMATION
	local useVfx = type(raw.useVfx) == "table" and raw.useVfx or DEFAULT_USE_VFX

	return {
		mount = normalizeMountSpec(mount),
		useAnimation = {
			duration = math.max(0.1, tonumber(useAnimation.duration) or DEFAULT_USE_ANIMATION.duration),
			push = tonumber(useAnimation.push) or DEFAULT_USE_ANIMATION.push,
			lift = tonumber(useAnimation.lift) or DEFAULT_USE_ANIMATION.lift,
			rollDeg = tonumber(useAnimation.rollDeg) or DEFAULT_USE_ANIMATION.rollDeg,
			pitchDeg = tonumber(useAnimation.pitchDeg) or DEFAULT_USE_ANIMATION.pitchDeg,
		},
		useVfx = {
			burst = math.clamp(math.floor(tonumber(useVfx.burst) or DEFAULT_USE_VFX.burst), 4, 48),
			speed = math.max(0.8, tonumber(useVfx.speed) or DEFAULT_USE_VFX.speed),
			lifetime = math.max(0.08, tonumber(useVfx.lifetime) or DEFAULT_USE_VFX.lifetime),
			color = coerceColor3(useVfx.color, Color3.fromRGB(218, 232, 255)),
			style = type(useVfx.style) == "string" and useVfx.style or DEFAULT_USE_VFX.style,
		},
		inventoryModelAssetId = type(raw.inventoryModelAssetId) == "string" and raw.inventoryModelAssetId or nil,
		targetBounds = coerceVector3(raw.targetBounds),
		screen = normalizeScreenSpec(raw.screen),
	}
end

local function cloneProfile(profile)
	if type(profile) ~= "table" then
		return nil
	end

	return {
		mount = normalizeMountSpec(profile.mount),
		useAnimation = {
			duration = profile.useAnimation.duration,
			push = profile.useAnimation.push,
			lift = profile.useAnimation.lift,
			rollDeg = profile.useAnimation.rollDeg,
			pitchDeg = profile.useAnimation.pitchDeg,
		},
		useVfx = {
			burst = profile.useVfx.burst,
			speed = profile.useVfx.speed,
			lifetime = profile.useVfx.lifetime,
			color = profile.useVfx.color,
			style = profile.useVfx.style,
		},
		inventoryModelAssetId = profile.inventoryModelAssetId,
		targetBounds = profile.targetBounds,
		screen = profile.screen,
	}
end

local function resolveUsageRule(toolType)
	if TOOL_USAGE_RULES and type(TOOL_USAGE_RULES.GetRule) == "function" then
		local ok, rule = pcall(TOOL_USAGE_RULES.GetRule, toolType)
		if ok and type(rule) == "table" then
			return rule
		end
	end
	return nil
end

local function applyUsageRuleToProfile(toolType, profile)
	local rule = resolveUsageRule(toolType)
	if not rule then
		return profile
	end

	local adjusted = cloneProfile(profile)
	if not adjusted then
		return profile
	end

	if rule.holdStyle == "TwoHanded" then
		adjusted.mount.style = "TwoHanded"
	elseif rule.holdStyle == "SingleHand" then
		adjusted.mount.style = "SingleHand"
	end

	if rule.preferredHand == "Left" then
		adjusted.mount.hand = "Left"
		adjusted.mount.secondaryHand = "Right"
	elseif rule.preferredHand == "Right" then
		adjusted.mount.hand = "Right"
		adjusted.mount.secondaryHand = "Left"
	end

	return adjusted
end

local function canUseWithFlashlight(toolType)
	if type(toolType) ~= "string" or toolType == "" then
		return true
	end
	if toolType == "Flashlight" then
		return true
	end
	if TOOL_USAGE_RULES and type(TOOL_USAGE_RULES.CanUseWithFlashlight) == "function" then
		return TOOL_USAGE_RULES.CanUseWithFlashlight(toolType) == true
	end
	return true
end

local function normalizeStyleToken(value)
	if type(value) ~= "string" then
		return ""
	end
	local token = string.gsub(value, "^%s*(.-)%s*$", "%1")
	return token
end

local function resolveUseVfxStyleProfile(toolType, useVfx, succeeded)
	local requestedStyle = normalizeStyleToken(useVfx and useVfx.style)
	if requestedStyle == "" or string.lower(requestedStyle) == "auto" then
		requestedStyle = TOOL_USE_VFX_STYLE[toolType] or "Default"
	else
		local alias = USE_VFX_STYLE_ALIAS[string.lower(requestedStyle)]
		if alias then
			requestedStyle = alias
		end
	end

	local style = USE_VFX_STYLES[requestedStyle] or USE_VFX_STYLES.Default
	local failed = succeeded == false
	local baseColor = (useVfx and useVfx.color) or Color3.fromRGB(218, 232, 255)
	local resolvedColor = baseColor
	if failed then
		resolvedColor = baseColor:Lerp(Color3.fromRGB(255, 122, 122), 0.68)
	elseif requestedStyle == "Holy" then
		resolvedColor = baseColor:Lerp(Color3.fromRGB(255, 234, 168), 0.34)
	elseif requestedStyle == "Smoke" then
		resolvedColor = baseColor:Lerp(Color3.fromRGB(198, 206, 214), 0.22)
	end

	local burstScale = failed and 0.62 or 1
	local speedScale = failed and 0.82 or 1
	local lifetimeScale = failed and 0.86 or 1
	local pulseScale = failed and 0.58 or 1

	return {
		token = requestedStyle,
		texture = style.texture or USE_VFX_STYLES.Default.texture,
		spread = tonumber(style.spread) or USE_VFX_STYLES.Default.spread,
		acceleration = typeof(style.acceleration) == "Vector3" and style.acceleration or USE_VFX_STYLES.Default.acceleration,
		drag = tonumber(style.drag) or USE_VFX_STYLES.Default.drag,
		lightEmission = tonumber(style.lightEmission) or USE_VFX_STYLES.Default.lightEmission,
		sizeStart = math.max(0.01, tonumber(style.sizeStart) or USE_VFX_STYLES.Default.sizeStart),
		sizeEnd = math.max(0.005, tonumber(style.sizeEnd) or USE_VFX_STYLES.Default.sizeEnd),
		pulseBrightness = math.max(0.8, tonumber(style.pulseBrightness) or USE_VFX_STYLES.Default.pulseBrightness),
		pulseRange = math.max(2, tonumber(style.pulseRange) or USE_VFX_STYLES.Default.pulseRange),
		burstScale = burstScale,
		speedScale = speedScale,
		lifetimeScale = lifetimeScale,
		pulseScale = pulseScale,
		color = resolvedColor,
		failed = failed,
	}
end

state = {
	dirty = true,
	lastUseStamp = 0,
	useAnimationUntil = 0,
	pendingUseVfx = false,
	pendingUseVfxToolType = nil,
	pendingUseVfxSucceeded = true,
	pendingUseVfxEventName = nil,
	pendingUseVfxUntil = 0,
	useAnimationToolType = nil,
	useAnimationSucceeded = true,
	useAnimationEventName = nil,
	mounted = nil,
	flashlightMounted = nil,
	flashlightVisualAlpha = 0,
	bolaArwahStartedAt = 0,
	instrumentStartedAt = 0,
	instrumentLastProbeAt = 0,
	instrumentSignal = 0.12,
	instrumentTargetName = nil,
	instrumentTargetDistance = nil,
	instrumentTargetIsGhost = false,
	emfDisplayLevel = 1,
	thermoDisplayC = 18,
	thermoLastDisplayC = 18,
	fpvBaseLocalCFrames = setmetatable({}, { __mode = "k" }),
	fpvBaseTransparency = setmetatable({}, { __mode = "k" }),
	remoteTools = {},
}

local function clearMountedTool()
	local clearedToolType = state.mounted and state.mounted.toolType or nil
	if state.mounted and state.mounted.model and state.mounted.model.Parent then
		state.mounted.model:Destroy()
	end
	state.mounted = nil
	if clearedToolType and state.useAnimationToolType == clearedToolType then
		state.useAnimationToolType = nil
		state.useAnimationEventName = nil
	end
	state.bolaArwahStartedAt = 0
	state.instrumentStartedAt = 0
	state.instrumentLastProbeAt = 0
	state.instrumentSignal = 0.12
	state.instrumentTargetName = nil
	state.instrumentTargetDistance = nil
	state.instrumentTargetIsGhost = false
	state.emfDisplayLevel = 1
	state.thermoDisplayC = 18
	state.thermoLastDisplayC = 18
end

local function clearFlashlightMount()
	if state.flashlightMounted and state.flashlightMounted.model and state.flashlightMounted.model.Parent then
		state.flashlightMounted.model:Destroy()
	end
	state.flashlightMounted = nil
end

local function resolveActiveToolType(now)
	local inMatch = player:GetAttribute("InMatch") == true or tostring(player:GetAttribute("MatchId") or "") ~= ""
	if not inMatch then
		return nil
	end

	local toolType = player:GetAttribute(EQUIPPED_TOOL_ATTRIBUTE)
	if type(toolType) == "string" and toolType ~= "" then
		return toolType
	end

	local focusTool = player:GetAttribute(PREPARATION_TOOL_ATTRIBUTE)
	if type(focusTool) == "string" and focusTool ~= "" then
		return focusTool
	end

	if state.mounted and state.mounted.toolType and now <= (state.mounted.holdUntil or 0) then
		return state.mounted.toolType
	end
	if state.flashlightMounted and now <= (state.flashlightMounted.holdUntil or 0) then
		return state.flashlightMounted.toolType
	end
	return nil
end

local function ensureMountedTool(toolType, fpvArms, now)
	if not fpvArms or type(toolType) ~= "string" or toolType == "" or toolType == "Flashlight" then
		clearMountedTool()
		return nil
	end

	if state.mounted and state.mounted.toolType == toolType and state.mounted.model and state.mounted.model.Parent == fpvArms then
		state.mounted.holdUntil = math.max(state.mounted.holdUntil or 0, now + (state.mounted.profile.mount.holdSeconds or 1.8))
		return state.mounted
	end

	clearMountedTool()
	local profile = applyUsageRuleToProfile(toolType, resolveToolProfile(toolType))
	local model = cloneToolModel(toolType, profile.targetBounds)
	if not model then
		return nil
	end
	applyInventoryMeshAssetId(model, profile.inventoryModelAssetId)
	if profile.targetBounds then
		clampModelBounds(model, profile.targetBounds)
	end
	ensurePrimaryPart(model)
	model.Name = HELD_TOOL_MODEL_NAME
	model.Parent = fpvArms
	model:SetAttribute("PasrahHeldToolType", toolType)
	model:SetAttribute("PasrahHeldToolMountHand", profile.mount.hand)
	model:SetAttribute("PasrahHeldToolStyle", profile.mount.style)

	state.mounted = {
		toolType = toolType,
		model = model,
		profile = profile,
		holdUntil = now + (profile.mount.holdSeconds or 1.8),

	}
	return state.mounted
end

local function ensureFlashlightMount(fpvArms, now, activeToolType)
	if not fpvArms then
		clearFlashlightMount()
		return nil
	end

	if state.flashlightMounted
		and state.flashlightMounted.model
		and state.flashlightMounted.model.Parent == fpvArms
		and state.flashlightMounted.profile
	then
		state.flashlightMounted.holdUntil =
			math.max(state.flashlightMounted.holdUntil or 0, now + (state.flashlightMounted.profile.mount.holdSeconds or 1.8))
		return state.flashlightMounted
	end

	clearFlashlightMount()
	local profile = resolveToolProfile("Flashlight")
	if activeToolType and activeToolType ~= "Flashlight" then
		profile = cloneProfile(profile)
		local activeRule = resolveUsageRule(activeToolType)
		if activeRule and activeRule.preferredHand == "Right" then
			profile.mount.hand = "Left"
			profile.mount.secondaryHand = "Right"
		else
			profile.mount.hand = "Right"
			profile.mount.secondaryHand = "Left"
		end
	end
	local model = cloneToolModel("Flashlight", profile.targetBounds)
	if not model then
		return nil
	end
	applyInventoryMeshAssetId(model, profile.inventoryModelAssetId)
	if profile.targetBounds then
		clampModelBounds(model, profile.targetBounds)
	end
	ensurePrimaryPart(model)
	model.Name = HELD_FLASHLIGHT_MODEL_NAME
	model.Parent = fpvArms
	model:SetAttribute("PasrahHeldToolType", "Flashlight")
	model:SetAttribute("PasrahHeldToolMountHand", profile.mount.hand)
	model:SetAttribute("PasrahHeldToolStyle", profile.mount.style)

	state.flashlightMounted = {
		toolType = "Flashlight",
		model = model,
		profile = profile,
		holdUntil = now + (profile.mount.holdSeconds or 2),
		lens = nil,
		localLight = nil,

	}
	return state.flashlightMounted
end

local function enforceMountedTargetBounds(mounted)
	if not (mounted and mounted.model and mounted.profile and mounted.profile.targetBounds) then
		return
	end
	clampModelBounds(mounted.model, mounted.profile.targetBounds)
	ensurePrimaryPart(mounted.model)
end

local function computeAnimatedOffset(mounted, now)
	if STATIC_HOLD_TOOLS then
		return CFrame.new()
	end
	if not mounted then
		return CFrame.new()
	end
	if mounted.toolType ~= state.useAnimationToolType then
		return CFrame.new()
	end
	if now >= (state.useAnimationUntil or 0) then
		return CFrame.new()
	end
	local anim = mounted.profile.useAnimation
	local duration = math.max(0.1, tonumber(anim.duration) or 0.24)
	local remaining = math.max(0, state.useAnimationUntil - now)
	local alpha = 1 - math.clamp(remaining / duration, 0, 1)
	local pushWave = math.sin(alpha * math.pi)
	local settleWave = math.sin(alpha * math.pi * 0.5)
	local successScale = state.useAnimationSucceeded == false and 0.52 or 1
	local styleScale = mounted.profile.mount.style == "TwoHanded" and 0.84 or 1
	local handSign = mounted.profile.mount.hand == "Left" and -1 or 1

	local lift = anim.lift * settleWave * styleScale * successScale
	if state.useAnimationSucceeded == false then
		lift = -math.abs(anim.lift) * pushWave * 0.4
	end
	local push = anim.push * pushWave * successScale
	local pitch = math.rad(anim.pitchDeg * pushWave * styleScale * successScale)
	local roll = math.rad(anim.rollDeg * pushWave * styleScale * successScale * handSign)
	return CFrame.new(0, lift, -push) * CFrame.Angles(pitch, 0, roll)
end

local function resolveMountWorldCFrame(fpvArms, mount, animOffset)
	if mount.cameraSpace == true then
		local camera = Workspace.CurrentCamera
		if not camera then
			return nil, nil
		end
		local worldCFrame = camera.CFrame * (mount.cameraCFrame or CFrame.new())
		if typeof(animOffset) == "CFrame" then
			worldCFrame *= animOffset
		end
		return worldCFrame, camera.CFrame
	end

	local primaryHand = getHandPart(fpvArms, mount.hand)
	if not primaryHand then
		return nil, nil
	end
	local baseCFrame = primaryHand.CFrame
	if mount.style == "TwoHanded" then
		local secondaryHand = getHandPart(fpvArms, mount.secondaryHand)
		if secondaryHand then
			baseCFrame = baseCFrame:Lerp(secondaryHand.CFrame, mount.twoHandBlend)
		end
	end
	local mountOffset = cframeFromSpec(mount.cframe)
	local worldCFrame = baseCFrame * mountOffset
	if typeof(animOffset) == "CFrame" then
		worldCFrame *= animOffset
	end
	return worldCFrame, baseCFrame
end

local function fitMountToViewport(mountWorldCFrame, mount)
	if mount and mount.fitToViewport == false then
		return mountWorldCFrame, nil
	end
	local camera = Workspace.CurrentCamera
	if not (camera and camera.ViewportSize) then
		return mountWorldCFrame, nil
	end
	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return mountWorldCFrame, nil
	end

	local adjustedCFrame = mountWorldCFrame
	local totalOffset = Vector3.zero

	for _ = 1, 3 do
		local projected, onScreen = camera:WorldToViewportPoint(adjustedCFrame.Position)
		local top = viewport.Y * 0.42
		local bottom = viewport.Y * 0.74
		local left = viewport.X * 0.22
		local right = viewport.X * 0.78
		if mount.hand == "Left" then
			left = viewport.X * 0.12
			right = viewport.X * 0.44
		elseif mount.hand == "Right" then
			left = viewport.X * 0.54
			right = viewport.X * 0.80
		end
		if mount.viewportBias == "Center" then
			left = viewport.X * 0.50
			right = viewport.X * 0.72
			top = viewport.Y * 0.46
			bottom = viewport.Y * 0.72
		elseif mount.viewportBias == "CenterRight" then
			left = viewport.X * 0.48
			right = viewport.X * 0.76
		end
		if mount.style == "TwoHanded" then
			left = viewport.X * 0.32
			right = viewport.X * 0.76
			bottom = viewport.Y * 0.74
		end

		local targetSpec = mount.viewportTarget
		local targetX = targetSpec and (viewport.X * targetSpec.x) or math.clamp(projected.X, left, right)
		local targetY = targetSpec and (viewport.Y * targetSpec.y) or math.clamp(projected.Y, top, bottom)
		local needsFit = (not onScreen)
			or (math.abs(targetX - projected.X) > 1)
			or (math.abs(targetY - projected.Y) > 1)
		if not needsFit then
			break
		end

		local depth = math.max(0.4, tonumber(projected.Z) or 1)
		local currentRay = camera:ViewportPointToRay(projected.X, projected.Y, depth)
		local targetRay = camera:ViewportPointToRay(targetX, targetY, depth)
		local worldOffset = targetRay.Origin - currentRay.Origin
		totalOffset += worldOffset
		local adjustedPosition = adjustedCFrame.Position + worldOffset
		adjustedCFrame = CFrame.new(adjustedPosition) * adjustedCFrame.Rotation
	end

	if totalOffset.Magnitude <= 0 then
		return adjustedCFrame, nil
	end
	return adjustedCFrame, totalOffset
end

local function ensureFlashlightLens(mounted)
	if not (mounted and mounted.model) then
		return nil
	end
	local lens = mounted.lens
	if lens and lens.Parent then
		return lens
	end

	for _, candidate in ipairs({ "Lens", "Lensa", "Glass", "Light", "Head" }) do
		local part = mounted.model:FindFirstChild(candidate, true)
		if part and part:IsA("BasePart") then
			mounted.lens = part
			return part
		end
	end

	local fallback = mounted.model:FindFirstChildWhichIsA("BasePart", true)
	if fallback then
		mounted.lens = fallback
	end
	return mounted.lens
end

local function ensureFlashlightLocalLight(mounted)
	local lens = ensureFlashlightLens(mounted)
	if not (lens and mounted and mounted.model) then
		return nil
	end
	local host = mounted.model:FindFirstChild(FLASHLIGHT_AIM_HOST_NAME)
	if not (host and host:IsA("BasePart")) then
		if host then
			host:Destroy()
		end
		host = Instance.new("Part")
		host.Name = FLASHLIGHT_AIM_HOST_NAME
		host.Size = Vector3.new(0.05, 0.05, 0.05)
		host.Transparency = 1
		host.Anchored = true
		host.CanCollide = false
		host.CanTouch = false
		host.CanQuery = false
		host.CastShadow = false
		host.Parent = mounted.model
	end

	local legacyLight = lens:FindFirstChild("FPV_LocalSpotLight")
	if legacyLight and legacyLight:IsA("SpotLight") then
		legacyLight:Destroy()
	elseif legacyLight then
		legacyLight:Destroy()
	end

	local light = mounted.localLight
	if light and light.Parent == host and light:IsA("SpotLight") then
		return light
	end

	local existing = host:FindFirstChild("FPV_LocalSpotLight")
	if existing and existing:IsA("SpotLight") then
		mounted.localLight = existing
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local spotlight = cloneVisualTemplate(FLASHLIGHT_LOCAL_SPOTLIGHT_TEMPLATE_PATH, "FPV_LocalSpotLight")
	if not (spotlight and spotlight:IsA("SpotLight")) then
		warnMissingVisualTemplate("ToolVisuals.FlashlightLocalSpotLightTemplate")
		return nil
	end
	spotlight.Name = "FPV_LocalSpotLight"
	spotlight.Face = Enum.NormalId.Front
	spotlight.Brightness = tonumber(FLASHLIGHT_LIGHT_CONFIG.offBrightness) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.offBrightness
	spotlight.Range = tonumber(FLASHLIGHT_LIGHT_CONFIG.offRange) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.offRange
	spotlight.Angle = tonumber(FLASHLIGHT_LIGHT_CONFIG.offAngle) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.offAngle
	spotlight.Color = coerceColor3(FLASHLIGHT_LIGHT_CONFIG.color, DEFAULT_FLASHLIGHT_LOCAL_LIGHT.color)
	spotlight.Enabled = false
	spotlight.Shadows = false
	spotlight.Parent = host
	mounted.localLight = spotlight
	return spotlight
end

local function ensureViewmodelFillLight(mounted)
	if not (mounted and mounted.model) then
		return nil
	end
	local primaryPart = mounted.model.PrimaryPart or mounted.model:FindFirstChildWhichIsA("BasePart", true)
	if not primaryPart then
		return nil
	end
	local light = primaryPart:FindFirstChild("FPV_ViewmodelFillLight")
	if light and light:IsA("PointLight") then
		return light
	end
	if light then
		light:Destroy()
	end
	light = Instance.new("PointLight")
	light.Name = "FPV_ViewmodelFillLight"
	light.Brightness = mounted.toolType == "Flashlight" and 0.42 or 0.22
	light.Range = mounted.toolType == "Flashlight" and 2.4 or 1.8
	light.Color = Color3.fromRGB(255, 238, 202)
	light.Shadows = false
	light.Parent = primaryPart
	return light
end

local function updateFlashlightViewmodelProxy(mounted)
	if not (mounted and mounted.toolType == "Flashlight" and mounted.model) then
		return
	end
	local existingProxy = mounted.model:FindFirstChild("FPV_FlashlightReadableProxy")
	if existingProxy then
		existingProxy:Destroy()
	end
	return
end

local function captureBolaArwahScreenRefs(mounted, surfaceGui)
	if not (mounted and surfaceGui and surfaceGui:IsA("SurfaceGui")) then
		return
	end
	local background = surfaceGui:FindFirstChild("Background")
	local preview = background and background:FindFirstChild("Preview")
	local viewport = preview and preview:FindFirstChild("LiveViewport")
	local worldModel = viewport and viewport:FindFirstChild("LiveWorld")
	local viewCamera = viewport and viewport:FindFirstChild("LiveCamera")
	local recBadge = background and background:FindFirstChild("RecBadge")
	local timer = background and background:FindFirstChild("Timer")
	local battery = background and background:FindFirstChild("Battery")
	local mode = background and background:FindFirstChild("Mode")
	local status = preview and preview:FindFirstChild("Status")
	local scan = preview and preview:FindFirstChild("ScanResult")
	local lockFrame = preview and preview:FindFirstChild("LockFrame")
	local recDot = recBadge and recBadge:FindFirstChild("RecDot")
	if viewport and viewCamera then
		viewport.CurrentCamera = viewCamera
	end
	mounted.screenRefs = {
		surface = surfaceGui,
		preview = preview,
		viewport = viewport,
		worldModel = worldModel,
		viewCamera = viewCamera,
		recBadge = recBadge,
		recDot = recDot,
		timer = timer,
		battery = battery,
		mode = mode,
		status = status,
		scan = scan,
		lockFrame = lockFrame,
	}
end

local function ensureBolaArwahScreen(mounted)
	if not (mounted and mounted.model and mounted.toolType == "BolaArwah") then
		return nil
	end

	local primaryPart = mounted.model.PrimaryPart or mounted.model:FindFirstChildWhichIsA("BasePart", true)
	if not primaryPart then
		return nil
	end
	local screenConfig = mounted.profile and mounted.profile.screen
	if screenConfig and screenConfig.enabled == false then
		for _, descendant in ipairs(mounted.model:GetDescendants()) do
			if descendant.Name == "FPV_CameraScreen" and descendant:IsA("SurfaceGui") then
				descendant:Destroy()
			end
		end
		mounted.screenRefs = nil
		mounted.screenPart = nil
		mounted.cameraScreenFixedToModel = nil
		return nil
	end

	local useSurfaceHost = screenConfig and (screenConfig.mode == "SurfaceHost" or screenConfig.hostCFrame ~= nil)
	if useSurfaceHost then
		local screenPart = ensureConfiguredScreenHostPart(mounted, CAMERA_SCREEN_HOST_NAME, screenConfig)
		if not screenPart then
			return nil
		end
		mounted.screenPart = screenPart
		mounted.cameraScreenFixedToModel = true
		for _, descendant in ipairs(mounted.model:GetDescendants()) do
			if descendant.Name == "FPV_CameraScreen"
				and descendant.Parent ~= screenPart
				and descendant:IsA("SurfaceGui")
			then
				descendant:Destroy()
			end
		end

		local surfaceGui = screenPart:FindFirstChild("FPV_CameraScreen")
		if surfaceGui and not surfaceGui:IsA("SurfaceGui") then
			surfaceGui:Destroy()
			surfaceGui = nil
		end
		if not surfaceGui then
			surfaceGui = cloneVisualTemplate(CAMERA_SCREEN_TEMPLATE_PATH, "FPV_CameraScreen")
			if surfaceGui and surfaceGui:IsA("SurfaceGui") then
				surfaceGui.Parent = screenPart
			end
		end
		if surfaceGui and surfaceGui:IsA("SurfaceGui") then
			configureSurfaceGuiForScreen(surfaceGui, screenConfig, Enum.NormalId.Front, Vector2.new(212, 352), 900)
			captureBolaArwahScreenRefs(mounted, surfaceGui)
			return surfaceGui
		end

		warnMissingVisualTemplate("ToolVisuals.CameraScreenSurfaceTemplate")
		return nil
	end
	mounted.cameraScreenFixedToModel = false

	local function alignCameraScreenHostPart(hostPart, anchorPart)
		if not (hostPart and anchorPart and anchorPart:IsA("BasePart")) then
			return
		end
		local camera = Workspace.CurrentCamera
		if not camera then
			hostPart.CFrame = anchorPart.CFrame * CFrame.new(CAMERA_SCREEN_HOST_OFFSET)
			return
		end
		local anchorPos = anchorPart.CFrame:PointToWorldSpace(CAMERA_SCREEN_HOST_OFFSET)
		hostPart.CFrame = CFrame.lookAt(anchorPos, camera.CFrame.Position, camera.CFrame.UpVector)
	end

	local function ensureCameraScreenHostPart()
		local host = mounted.model:FindFirstChild(CAMERA_SCREEN_HOST_NAME)
		if host and not host:IsA("BasePart") then
			host:Destroy()
			host = nil
		end
		if not host then
			host = Instance.new("Part")
			host.Name = CAMERA_SCREEN_HOST_NAME
			host.Size = Vector3.new(0.36, 0.58, 0.03)
			host.Anchored = true
			host.CanCollide = false
			host.CanTouch = false
			host.CanQuery = false
			host.CastShadow = false
			host.Massless = true
			host.Material = Enum.Material.SmoothPlastic
			host.Color = Color3.fromRGB(14, 20, 26)
			host.Transparency = 0.98
			host.Parent = mounted.model
		end
		alignCameraScreenHostPart(host, primaryPart)
		return host
	end

	local screenPart = mounted.screenPart
	if not (screenPart and screenPart.Parent) then
		screenPart = ensureCameraScreenHostPart()
		mounted.screenPart = screenPart
	elseif screenPart.Name == CAMERA_SCREEN_HOST_NAME then
		alignCameraScreenHostPart(screenPart, primaryPart)
	end

	local surfaceGui = screenPart:FindFirstChild("FPV_CameraScreen")
	if surfaceGui and surfaceGui:IsA("SurfaceGui") then
		local background = surfaceGui:FindFirstChild("Background")
		local preview = background and background:FindFirstChild("Preview")
		local viewport = preview and preview:FindFirstChild("LiveViewport")
		local worldModel = viewport and viewport:FindFirstChild("LiveWorld")
		local viewCamera = viewport and viewport:FindFirstChild("LiveCamera")
		local recBadge = background and background:FindFirstChild("RecBadge")
		local timer = background and background:FindFirstChild("Timer")
		local battery = background and background:FindFirstChild("Battery")
		local mode = background and background:FindFirstChild("Mode")
		local status = preview and preview:FindFirstChild("Status")
		local scan = preview and preview:FindFirstChild("ScanResult")
		local lockFrame = preview and preview:FindFirstChild("LockFrame")
		local recDot = recBadge and recBadge:FindFirstChild("RecDot")
		if viewport and viewCamera then
			viewport.CurrentCamera = viewCamera
		end
		mounted.screenRefs = {
			surface = surfaceGui,
			preview = preview,
			viewport = viewport,
			worldModel = worldModel,
			viewCamera = viewCamera,
			recBadge = recBadge,
			recDot = recDot,
			timer = timer,
			battery = battery,
			mode = mode,
			status = status,
			scan = scan,
			lockFrame = lockFrame,
		}
		return surfaceGui
	end
	if surfaceGui then
		surfaceGui:Destroy()
	end

	surfaceGui = cloneVisualTemplate(CAMERA_SCREEN_TEMPLATE_PATH, "FPV_CameraScreen")
	if surfaceGui and surfaceGui:IsA("SurfaceGui") then
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surfaceGui.PixelsPerStud = 170
		surfaceGui.CanvasSize = Vector2.new(212, 352)
		surfaceGui.LightInfluence = 0
		surfaceGui.AlwaysOnTop = true
		surfaceGui.Parent = screenPart

		local background = surfaceGui:FindFirstChild("Background")
		local preview = background and background:FindFirstChild("Preview")
		local viewport = preview and preview:FindFirstChild("LiveViewport")
		local worldModel = viewport and viewport:FindFirstChild("LiveWorld")
		local viewCamera = viewport and viewport:FindFirstChild("LiveCamera")
		local recBadge = background and background:FindFirstChild("RecBadge")
		local timer = background and background:FindFirstChild("Timer")
		local battery = background and background:FindFirstChild("Battery")
		local mode = background and background:FindFirstChild("Mode")
		local status = preview and preview:FindFirstChild("Status")
		local scan = preview and preview:FindFirstChild("ScanResult")
		local lockFrame = preview and preview:FindFirstChild("LockFrame")
		local recDot = recBadge and recBadge:FindFirstChild("RecDot")
		if viewport and viewCamera then
			viewport.CurrentCamera = viewCamera
		end
		mounted.screenRefs = {
			surface = surfaceGui,
			preview = preview,
			viewport = viewport,
			worldModel = worldModel,
			viewCamera = viewCamera,
			recBadge = recBadge,
			recDot = recDot,
			timer = timer,
			battery = battery,
			mode = mode,
			status = status,
			scan = scan,
			lockFrame = lockFrame,
		}
		return surfaceGui
	end

	warnMissingVisualTemplate("ToolVisuals.CameraScreenSurfaceTemplate")
	return nil
end

local CAMERA_EVIDENCE_PREVIEW_COLORS = {
	MEDOK = Color3.fromRGB(92, 222, 255),
	Suhu = Color3.fromRGB(128, 214, 255),
	BukuTerkutuk = Color3.fromRGB(190, 96, 255),
	["To'un"] = Color3.fromRGB(142, 236, 255),
	Suara = Color3.fromRGB(184, 148, 255),
	Pengganggu = Color3.fromRGB(146, 255, 188),
}

local function resolveEvidencePreviewType(instance)
	local cursor = instance
	while typeof(cursor) == "Instance" do
		local evidenceType = cursor:GetAttribute("PasrahEvidenceType")
		if type(evidenceType) == "string" and evidenceType ~= "" then
			return evidenceType
		end
		if cursor:GetAttribute("PasrahEvidenceVisual") == true then
			local nameToken = tostring(cursor.Name or ""):gsub("^Evidence_", "")
			if nameToken ~= "" and nameToken ~= tostring(cursor.Name or "") then
				return nameToken
			end
		end
		cursor = cursor.Parent
	end
	return nil
end

local function clonePartForCameraPreview(sourcePart)
	if not (sourcePart and sourcePart:IsA("BasePart")) then
		return nil
	end
	local evidenceType = resolveEvidencePreviewType(sourcePart)
	local evidenceColor = evidenceType and (CAMERA_EVIDENCE_PREVIEW_COLORS[evidenceType] or Color3.fromRGB(142, 236, 255)) or nil
	local cloned = sourcePart:Clone()
	for _, descendant in ipairs(cloned:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("Sound") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			if evidenceColor then
				descendant.Material = Enum.Material.Neon
				descendant.Color = descendant.Color:Lerp(evidenceColor, 0.72)
				descendant.Transparency = math.min(descendant.Transparency, 0.18)
			else
				descendant.Material = Enum.Material.SmoothPlastic
				descendant.Color = descendant.Color:Lerp(Color3.fromRGB(178, 220, 232), 0.38)
			end
			descendant.Reflectance = 0
		end
	end
	if cloned:IsA("BasePart") then
		cloned.Anchored = true
		if evidenceColor then
			cloned.Material = Enum.Material.Neon
			cloned.Color = cloned.Color:Lerp(evidenceColor, 0.72)
			cloned.Transparency = math.min(cloned.Transparency, 0.18)
		else
			cloned.Material = Enum.Material.SmoothPlastic
			cloned.Color = cloned.Color:Lerp(Color3.fromRGB(178, 220, 232), 0.38)
		end
		cloned.Reflectance = 0
	end
	return cloned
end

local function collectCameraPreviewParts(camera, mounted, focusPart)
	if not (camera and focusPart and focusPart:IsA("BasePart")) then
		return {}
	end
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	local character = player.Character
	if character then
		table.insert(exclude, character)
	end
	local fpvArms = camera:FindFirstChild(FPV_ARMS_MODEL_NAME)
	if fpvArms then
		table.insert(exclude, fpvArms)
	end
	if mounted and mounted.model then
		table.insert(exclude, mounted.model)
	end
	overlapParams.FilterDescendantsInstances = exclude
	overlapParams.MaxParts = 24

	local gathered = { focusPart }
	local seen = {
		[focusPart] = true,
	}
	local nearby = Workspace:GetPartBoundsInRadius(focusPart.Position, 8, overlapParams)
	table.sort(nearby, function(a, b)
		return (a.Position - focusPart.Position).Magnitude < (b.Position - focusPart.Position).Magnitude
	end)

	for _, part in ipairs(nearby) do
		if #gathered >= 12 then
			break
		end
		if part:IsA("BasePart") and not seen[part] and part.Transparency < 0.98 then
			local size = part.Size
			local tooLarge = math.max(size.X, size.Y, size.Z) > 80
			if not tooLarge then
				seen[part] = true
				table.insert(gathered, part)
			end
		end
	end

	return gathered
end

local function sampleCameraPreviewParts(camera, mounted, rayParams)
	if not (camera and camera.ViewportSize) then
		return {}, nil
	end
	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return {}, nil
	end

	local unique = {}
	local centerResult = nil
	for index, sample in ipairs(CAMERA_PREVIEW_SAMPLE_PATTERN) do
		local sx = (viewport.X * 0.5) + (sample.X * viewport.X * 0.35)
		local sy = (viewport.Y * 0.5) + (sample.Y * viewport.Y * 0.32)
		local ray = camera:ViewportPointToRay(sx, sy)
		local result = Workspace:Raycast(ray.Origin, ray.Direction * CAMERA_PREVIEW_RAY_DISTANCE, rayParams)
		if index == 1 then
			centerResult = result
		end
		if result and result.Instance and result.Instance:IsA("BasePart") and result.Instance.Transparency < 0.98 then
			local current = unique[result.Instance]
			if (not current) or result.Distance < current.distance then
				unique[result.Instance] = {
					part = result.Instance,
					distance = result.Distance,
				}
			end
		end
	end

	local parts = {}
	for _, entry in pairs(unique) do
		table.insert(parts, entry)
	end
	table.sort(parts, function(a, b)
		return a.distance < b.distance
	end)
	return parts, centerResult
end

local function updateBolaArwahLivePreview(mounted, now)
	if not (mounted and mounted.screenRefs and mounted.screenRefs.viewport and mounted.screenRefs.worldModel and mounted.screenRefs.viewCamera) then
		return nil, nil
	end
	local refs = mounted.screenRefs
	local viewport = refs.viewport
	local worldModel = refs.worldModel
	local viewCamera = refs.viewCamera
	local camera = Workspace.CurrentCamera
	if not (viewport and worldModel and viewCamera and camera) then
		return nil, nil
	end
	if now - (mounted.lastPreviewUpdateAt or 0) < 0.1 then
		return mounted.lastPreviewTargetName, mounted.lastPreviewDistance
	end
	mounted.lastPreviewUpdateAt = now

	viewCamera.CFrame = CFrame.new()
	viewCamera.FieldOfView = math.clamp(camera.FieldOfView * 0.9, 48, 74)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	local character = player.Character
	if character then
		table.insert(exclude, character)
	end
	local fpvArms = camera:FindFirstChild(FPV_ARMS_MODEL_NAME)
	if fpvArms then
		table.insert(exclude, fpvArms)
	end
	if mounted.model then
		table.insert(exclude, mounted.model)
	end
	rayParams.FilterDescendantsInstances = exclude

	local sampledParts, centerResult = sampleCameraPreviewParts(camera, mounted, rayParams)
	if not centerResult then
		local origin = camera.CFrame.Position
		local fallbackDirection = (camera.CFrame.LookVector + Vector3.new(0, -0.34, 0)).Unit
		centerResult = Workspace:Raycast(origin, fallbackDirection * CAMERA_PREVIEW_RAY_DISTANCE, rayParams)
	end
	if not (centerResult and centerResult.Instance and centerResult.Instance:IsA("BasePart")) then
		return mounted.lastPreviewTargetName, mounted.lastPreviewDistance
	end

	for _, child in ipairs(worldModel:GetChildren()) do
		if child ~= viewCamera then
			child:Destroy()
		end
	end

	local focusPart = centerResult.Instance
	local previewParts = collectCameraPreviewParts(camera, mounted, focusPart)
	local orderedParts = {}
	local seen = {}
	for _, sampled in ipairs(sampledParts) do
		if not seen[sampled.part] then
			seen[sampled.part] = true
			table.insert(orderedParts, sampled.part)
		end
	end
	for _, nearby in ipairs(previewParts) do
		if not seen[nearby] then
			seen[nearby] = true
			table.insert(orderedParts, nearby)
		end
		if #orderedParts >= 14 then
			break
		end
	end

	local xyScale = 0.42
	local depthScale = 0.30
	local renderedCount = 0
	for _, sourcePart in ipairs(orderedParts) do
		local cloned = clonePartForCameraPreview(sourcePart)
		if cloned then
			local relative = camera.CFrame:ToObjectSpace(sourcePart.CFrame)
			local sourcePos = relative.Position
			local depth = math.clamp(math.abs(sourcePos.Z) * depthScale, 2.6, 16)
			local position = Vector3.new(sourcePos.X * xyScale, sourcePos.Y * xyScale, -depth)
			local previewCFrame = CFrame.new(position) * relative.Rotation
			cloned.CFrame = previewCFrame
			local distance = math.max(1, sourcePos.Magnitude)
			local fade = math.clamp((distance - 8) / 20, 0, 0.45)
			local baseTransparency = math.min(0.85, cloned.Transparency + fade)
			if sourcePart == focusPart then
				cloned.Transparency = math.min(0.28, baseTransparency)
				local tintPart = cloned:IsA("BasePart") and cloned or cloned:FindFirstChildWhichIsA("BasePart", true)
				if tintPart then
					tintPart.Color = tintPart.Color:Lerp(Color3.fromRGB(120, 234, 224), 0.25)
				end
			else
				cloned.Transparency = baseTransparency
			end
			cloned.Parent = worldModel
			renderedCount += 1
		end
	end

	if renderedCount <= 1 then
		local fallbackPlane = Instance.new("Part")
		fallbackPlane.Name = "PreviewFallbackPlane"
		fallbackPlane.Anchored = true
		fallbackPlane.CanCollide = false
		fallbackPlane.CanTouch = false
		fallbackPlane.CanQuery = false
		fallbackPlane.CastShadow = false
		fallbackPlane.Material = Enum.Material.SmoothPlastic
		fallbackPlane.Color = Color3.fromRGB(52, 132, 156)
		fallbackPlane.Transparency = 0.22
		fallbackPlane.Size = Vector3.new(9, 5.4, 0.16)
		fallbackPlane.CFrame = CFrame.new(0, 0, -13)
		fallbackPlane.Parent = worldModel

		local fallbackReticle = Instance.new("Part")
		fallbackReticle.Name = "PreviewFallbackReticle"
		fallbackReticle.Anchored = true
		fallbackReticle.CanCollide = false
		fallbackReticle.CanTouch = false
		fallbackReticle.CanQuery = false
		fallbackReticle.CastShadow = false
		fallbackReticle.Material = Enum.Material.Neon
		fallbackReticle.Color = Color3.fromRGB(172, 242, 228)
		fallbackReticle.Transparency = 0.16
		fallbackReticle.Size = Vector3.new(0.12, 1.4, 0.08)
		fallbackReticle.CFrame = CFrame.new(0, 0, -8)
		fallbackReticle.Parent = worldModel
	end
	local evidenceType = resolveEvidencePreviewType(focusPart)
	mounted.lastPreviewEvidenceType = evidenceType
	mounted.lastPreviewTargetName = evidenceType and ("Evidence_" .. evidenceType) or focusPart.Name
	mounted.lastPreviewDistance = math.floor(centerResult.Distance + 0.5)
	player:SetAttribute(CAMERA_PREVIEW_RENDERED_ATTR, renderedCount)
	player:SetAttribute(CAMERA_PREVIEW_EVIDENCE_ATTR, evidenceType or nil)
	return mounted.lastPreviewTargetName, mounted.lastPreviewDistance
end

local function ensureJejakEnergiScreen(mounted)
	if not (mounted and mounted.model and mounted.toolType == "JejakEnergi") then
		return nil
	end
	local primaryPart = mounted.model.PrimaryPart or mounted.model:FindFirstChildWhichIsA("BasePart", true)
	if not primaryPart then
		return nil
	end
	local screenConfig = mounted.profile and mounted.profile.screen
	if screenConfig and screenConfig.enabled == false then
		for _, descendant in ipairs(mounted.model:GetDescendants()) do
			if descendant.Name == "FPV_EMFScreen" and (descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui")) then
				descendant:Destroy()
			end
		end
		mounted.emfRefs = nil
		mounted.emfScreenPart = nil
		mounted.emfScreenFixedToModel = nil
		return nil
	end

	local useSurfaceHost = screenConfig and (screenConfig.mode == "SurfaceHost" or screenConfig.hostCFrame ~= nil)
	if useSurfaceHost then
		local screenPart = ensureConfiguredScreenHostPart(mounted, EMF_SCREEN_HOST_NAME, screenConfig)
		if not screenPart then
			return nil
		end
		mounted.emfScreenPart = screenPart
		mounted.emfScreenFixedToModel = true
		for _, descendant in ipairs(mounted.model:GetDescendants()) do
			if descendant.Name == "FPV_EMFScreen"
				and descendant.Parent ~= screenPart
				and (descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui"))
			then
				descendant:Destroy()
			end
		end

		local surface = screenPart:FindFirstChild("FPV_EMFScreen")
		if surface and not surface:IsA("SurfaceGui") then
			surface:Destroy()
			surface = nil
		end
		if surface and surface:IsA("SurfaceGui") then
			surface.Face = screenConfig.face or Enum.NormalId.Top
			surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			surface.PixelsPerStud = screenConfig.pixelsPerStud or 760
			surface.CanvasSize = screenConfig.canvasSize or Vector2.new(220, 124)
			surface.LightInfluence = 0
			surface.AlwaysOnTop = screenConfig.alwaysOnTop ~= false
			applySurfaceGuiContentRotation(surface, screenConfig)
			mounted.emfRefs = {
				bars = {
					surface:FindFirstChild("B1", true),
					surface:FindFirstChild("B2", true),
					surface:FindFirstChild("B3", true),
					surface:FindFirstChild("B4", true),
					surface:FindFirstChild("B5", true),
				},
				label = surface:FindFirstChild("Threat", true),
			}
			return surface
		end

		surface = cloneBillboardTemplateAsSurfaceGui(EMF_SCREEN_TEMPLATE_PATH, "FPV_EMFScreen")
		if surface and surface:IsA("SurfaceGui") then
			surface.Face = screenConfig.face or Enum.NormalId.Top
			surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			surface.PixelsPerStud = screenConfig.pixelsPerStud or 760
			surface.CanvasSize = screenConfig.canvasSize or Vector2.new(220, 124)
			surface.LightInfluence = 0
			surface.AlwaysOnTop = screenConfig.alwaysOnTop ~= false
			surface.Parent = screenPart
			applySurfaceGuiContentRotation(surface, screenConfig)
			mounted.emfRefs = {
				bars = {
					surface:FindFirstChild("B1", true),
					surface:FindFirstChild("B2", true),
					surface:FindFirstChild("B3", true),
					surface:FindFirstChild("B4", true),
					surface:FindFirstChild("B5", true),
				},
				label = surface:FindFirstChild("Threat", true),
			}
			return surface
		end

		warnMissingVisualTemplate("ToolVisuals.EMFScreenBillboardTemplate")
		return nil
	end

	mounted.emfScreenFixedToModel = false
	local screenPart = mounted.emfScreenPart
	if not (screenPart and screenPart.Parent) then
		screenPart = resolveToolScreenPart(mounted.model, primaryPart, { "screen", "display", "lcd", "monitor", "panel", "emf" })
		mounted.emfScreenPart = screenPart
	end
	local surface = screenPart:FindFirstChild("FPV_EMFScreen")
	if surface and (surface:IsA("SurfaceGui") or surface:IsA("BillboardGui")) then
		mounted.emfRefs = {
			bars = {
				surface:FindFirstChild("B1", true),
				surface:FindFirstChild("B2", true),
				surface:FindFirstChild("B3", true),
				surface:FindFirstChild("B4", true),
				surface:FindFirstChild("B5", true),
			},
			label = surface:FindFirstChild("Threat", true),
		}
		orientSurfaceToCamera(surface, screenPart)
		return surface
	end
	if surface then
		surface:Destroy()
	end

	surface = cloneVisualTemplate(EMF_SCREEN_TEMPLATE_PATH, "FPV_EMFScreen")
	if surface and surface:IsA("BillboardGui") then
		local screenSize = screenConfig and screenConfig.size or Vector2.new(170, 96)
		surface.Size = UDim2.fromOffset(screenSize.X, screenSize.Y)
		surface.StudsOffset = screenConfig and screenConfig.studsOffset or Vector3.new(0, 0.06, 0)
		surface.LightInfluence = 0
		surface.AlwaysOnTop = not screenConfig or screenConfig.alwaysOnTop ~= false
		surface.Parent = screenPart
		mounted.emfRefs = {
			bars = {
				surface:FindFirstChild("B1", true),
				surface:FindFirstChild("B2", true),
				surface:FindFirstChild("B3", true),
				surface:FindFirstChild("B4", true),
				surface:FindFirstChild("B5", true),
			},
			label = surface:FindFirstChild("Threat", true),
		}
		return surface
	end

	warnMissingVisualTemplate("ToolVisuals.EMFScreenBillboardTemplate")
	return nil
end

local function ensureSuhuMembekuScreen(mounted)
	if not (mounted and mounted.model and mounted.toolType == "SuhuMembeku") then
		return nil
	end
	local primaryPart = mounted.model.PrimaryPart or mounted.model:FindFirstChildWhichIsA("BasePart", true)
	if not primaryPart then
		return nil
	end
	local screenConfig = mounted.profile and mounted.profile.screen
	if screenConfig and screenConfig.enabled == false then
		for _, descendant in ipairs(mounted.model:GetDescendants()) do
			if descendant.Name == "FPV_ThermoScreen" and (descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui")) then
				descendant:Destroy()
			end
		end
		mounted.thermoRefs = nil
		mounted.thermoScreenPart = nil
		mounted.thermoScreenFixedToModel = nil
		return nil
	end

	local useSurfaceHost = screenConfig and (screenConfig.mode == "SurfaceHost" or screenConfig.hostCFrame ~= nil)
	if useSurfaceHost then
		local screenPart = ensureConfiguredScreenHostPart(mounted, THERMO_SCREEN_HOST_NAME, screenConfig)
		if not screenPart then
			return nil
		end
		mounted.thermoScreenPart = screenPart
		mounted.thermoScreenFixedToModel = true
		for _, descendant in ipairs(mounted.model:GetDescendants()) do
			if descendant.Name == "FPV_ThermoScreen"
				and descendant.Parent ~= screenPart
				and (descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui"))
			then
				descendant:Destroy()
			end
		end

		local surface = screenPart:FindFirstChild("FPV_ThermoScreen")
		if surface and not surface:IsA("SurfaceGui") then
			surface:Destroy()
			surface = nil
		end
		if not surface then
			surface = cloneBillboardTemplateAsSurfaceGui(THERMO_SCREEN_TEMPLATE_PATH, "FPV_ThermoScreen")
			if surface and surface:IsA("SurfaceGui") then
				surface.Parent = screenPart
			end
		end
		if surface and surface:IsA("SurfaceGui") then
			configureSurfaceGuiForScreen(surface, screenConfig, Enum.NormalId.Front, Vector2.new(214, 124), 950)
			mounted.thermoRefs = {
				value = surface:FindFirstChild("TempValue", true),
				trend = surface:FindFirstChild("Trend", true),
			}
			return surface
		end

		warnMissingVisualTemplate("ToolVisuals.ThermoScreenBillboardTemplate")
		return nil
	end
	mounted.thermoScreenFixedToModel = false

	local screenPart = mounted.thermoScreenPart
	if not (screenPart and screenPart.Parent) then
		screenPart = resolveToolScreenPart(mounted.model, primaryPart, { "screen", "display", "lcd", "monitor", "panel", "thermo", "temperature" })
		mounted.thermoScreenPart = screenPart
	end
	local surface = screenPart:FindFirstChild("FPV_ThermoScreen")
	if surface and (surface:IsA("SurfaceGui") or surface:IsA("BillboardGui")) then
		mounted.thermoRefs = {
			value = surface:FindFirstChild("TempValue", true),
			trend = surface:FindFirstChild("Trend", true),
		}
		orientSurfaceToCamera(surface, screenPart)
		return surface
	end
	if surface then
		surface:Destroy()
	end

	surface = cloneVisualTemplate(THERMO_SCREEN_TEMPLATE_PATH, "FPV_ThermoScreen")
	if surface and surface:IsA("BillboardGui") then
		surface.Size = UDim2.fromOffset(214, 124)
		surface.StudsOffset = Vector3.new(0, 0.05, 0)
		surface.LightInfluence = 0
		surface.AlwaysOnTop = true
		surface.Parent = screenPart
		mounted.thermoRefs = {
			value = surface:FindFirstChild("TempValue", true),
			trend = surface:FindFirstChild("Trend", true),
		}
		return surface
	end

	warnMissingVisualTemplate("ToolVisuals.ThermoScreenBillboardTemplate")
	return nil
end

local function formatCameraTimer(seconds)
	local whole = math.max(0, math.floor(tonumber(seconds) or 0))
	local mins = math.floor(whole / 60)
	local secs = whole % 60
	return string.format("%02d:%02d", mins, secs)
end

local function updateBolaArwahScreenVisual(mounted, now)
	if not mounted then
		return
	end
	ensureBolaArwahScreen(mounted)
	if mounted
		and mounted.model
		and mounted.screenPart
		and mounted.screenPart.Name == CAMERA_SCREEN_HOST_NAME
		and mounted.cameraScreenFixedToModel ~= true
	then
		local primaryPart = mounted.model.PrimaryPart or mounted.model:FindFirstChildWhichIsA("BasePart", true)
		if primaryPart then
			local camera = Workspace.CurrentCamera
			local anchorPos = primaryPart.CFrame:PointToWorldSpace(CAMERA_SCREEN_HOST_OFFSET)
			if camera then
				mounted.screenPart.CFrame = CFrame.lookAt(anchorPos, camera.CFrame.Position, camera.CFrame.UpVector)
			else
				mounted.screenPart.CFrame = primaryPart.CFrame * CFrame.new(CAMERA_SCREEN_HOST_OFFSET)
			end
		end
	end
	local refs = mounted.screenRefs
	if type(refs) ~= "table" then
		return
	end
	local targetName, targetDistance = updateBolaArwahLivePreview(mounted, now)
	player:SetAttribute(CAMERA_PREVIEW_TARGET_ATTR, targetName or nil)
	player:SetAttribute(CAMERA_PREVIEW_DISTANCE_ATTR, targetDistance or nil)
	player:SetAttribute(CAMERA_PREVIEW_EVIDENCE_ATTR, mounted.lastPreviewEvidenceType or nil)

	if state.bolaArwahStartedAt <= 0 then
		state.bolaArwahStartedAt = now
	end
	local elapsed = math.max(0, now - state.bolaArwahStartedAt)
	local batteryPct = math.max(24, math.floor(100 - (elapsed * 0.6)))
	local lifecycle = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	local lastUseSucceeded = player:GetAttribute(TOOL_LAST_SUCCESS_ATTRIBUTE)
	local scanGhostType = tostring(player:GetAttribute(CAMERA_SCAN_GHOST_ATTR) or "")
	local scanCandidates = tostring(player:GetAttribute(CAMERA_SCAN_CANDIDATES_ATTR) or "")
	local scanEvidence = tostring(player:GetAttribute(CAMERA_SCAN_EVIDENCE_ATTR) or "")
	local scanReason = tostring(player:GetAttribute(CAMERA_SCAN_REASON_ATTR) or "")
	local scanStamp = tonumber(player:GetAttribute(CAMERA_SCAN_STAMP_ATTR)) or 0
	local statusText = "SCANNING"
	local statusColor = Color3.fromRGB(194, 228, 236)
	if lastUseSucceeded == false then
		statusText = "NO SIGNAL"
		statusColor = Color3.fromRGB(248, 170, 170)
	elseif state.pendingUseVfx == true then
		statusText = "CAPTURED"
		statusColor = Color3.fromRGB(156, 248, 198)
	elseif lifecycle == "PreparationPhase" then
		statusText = "STAGING"
	end

	if refs.timer then
		refs.timer.Text = formatCameraTimer(elapsed)
	end
	if refs.battery then
		refs.battery.Text = string.format("BAT %d%%", batteryPct)
		refs.battery.TextColor3 = batteryPct <= 30 and Color3.fromRGB(255, 168, 168) or Color3.fromRGB(184, 236, 214)
	end
	if refs.mode then
		if lifecycle == "HuntPhase" then
			refs.mode.Text = "NV ALERT REC"
		elseif targetName then
			refs.mode.Text = "NV LIVE REC"
		else
			refs.mode.Text = "NV STANDBY"
		end
	end
	if refs.status then
		if targetName then
			refs.status.Text = string.format("LOCK %dm", tonumber(targetDistance) or 0)
			refs.status.TextColor3 = Color3.fromRGB(172, 242, 228)
		else
			refs.status.Text = statusText
			refs.status.TextColor3 = statusColor
		end
	end
	if refs.scan then
		local scanText = "SCAN READY"
		local scanColor = Color3.fromRGB(172, 242, 228)
		local scanFresh = scanStamp > 0 and (now - scanStamp) <= 10
		if scanGhostType ~= "" then
			scanText = string.format("GHOST: %s", string.upper(scanGhostType))
			scanColor = Color3.fromRGB(255, 224, 156)
		elseif scanFresh and scanCandidates ~= "" then
			local candidateText = scanCandidates
			if #candidateText > 14 then
				candidateText = string.sub(candidateText, 1, 14) .. "..."
			end
			scanText = string.format("CAND: %s", string.upper(candidateText))
		elseif scanFresh and scanEvidence ~= "" then
			scanText = string.format("EVIDENCE: %s", string.upper(scanEvidence))
		elseif scanReason ~= "" and lastUseSucceeded == false then
			scanText = string.format("NO LOCK: %s", string.upper(scanReason))
			scanColor = Color3.fromRGB(248, 170, 170)
		end
		refs.scan.Text = scanText
		refs.scan.TextColor3 = scanColor
	end
	if refs.lockFrame then
		refs.lockFrame.Visible = targetName ~= nil
		local stroke = refs.lockFrame:FindFirstChild("Stroke")
		if stroke and stroke:IsA("UIStroke") then
			if targetName then
				stroke.Color = (scanGhostType ~= "") and Color3.fromRGB(255, 224, 156) or Color3.fromRGB(172, 242, 228)
				stroke.Transparency = 0.1
			else
				stroke.Color = Color3.fromRGB(172, 242, 228)
				stroke.Transparency = 0.35
			end
		end
	end
	if refs.recBadge then
		refs.recBadge.BackgroundColor3 = Color3.fromRGB(198, 62, 62)
	end
	if refs.recDot then
		local blinkOn = math.sin(now * 10) > 0
		refs.recDot.BackgroundTransparency = blinkOn and 0 or 0.75
	end
end

local function formatInstrumentDistance(distance)
	local meters = math.max(1, math.floor((tonumber(distance) or 0) + 0.5))
	return string.format("%dm", meters)
end

local function normalizeInstrumentTargetName(name)
	if type(name) ~= "string" then
		return "TARGET"
	end
	local token = string.gsub(name, "^Ghost_", "")
	token = string.gsub(token, "_", " ")
	token = string.gsub(token, "^%s*(.-)%s*$", "%1")
	if token == "" then
		return "TARGET"
	end
	return string.upper(token)
end

local function resolveInstrumentTargetPartName(part)
	if not (part and part:IsA("BasePart")) then
		return nil
	end
	local cursor = part
	while cursor and cursor ~= Workspace do
		if cursor:IsA("Model") and cursor.Name ~= "" then
			return cursor.Name
		end
		cursor = cursor.Parent
	end
	return part.Name
end

local function isGhostSignalPart(part)
	if not (part and part:IsA("BasePart")) then
		return false
	end
	local partName = string.lower(part.Name)
	if string.find(partName, "ghost", 1, true) then
		return true
	end
	local cursor = part
	while cursor and cursor ~= Workspace do
		if cursor:IsA("Model") then
			local modelName = string.lower(cursor.Name)
			if string.find(modelName, "ghost", 1, true) then
				return true
			end
			if cursor:GetAttribute("GhostType") ~= nil or cursor:GetAttribute("GhostId") ~= nil then
				return true
			end
		end
		cursor = cursor.Parent
	end
	return false
end

local function sampleInstrumentSignal(mounted, now)
	if (now - (state.instrumentLastProbeAt or 0)) < INSTRUMENT_PROBE_INTERVAL then
		return {
			signal = state.instrumentSignal or 0.12,
			targetName = state.instrumentTargetName,
			targetDistance = state.instrumentTargetDistance,
			targetIsGhost = state.instrumentTargetIsGhost == true,
		}
	end
	state.instrumentLastProbeAt = now

	local baselineSignal = math.clamp(0.12 + (math.sin(now * 0.55) * 0.03), 0.08, 0.24)
	local camera = Workspace.CurrentCamera
	if not (camera and camera.ViewportSize and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0) then
		state.instrumentSignal = baselineSignal
		state.instrumentTargetName = nil
		state.instrumentTargetDistance = nil
		state.instrumentTargetIsGhost = false
		return {
			signal = state.instrumentSignal,
			targetName = nil,
			targetDistance = nil,
			targetIsGhost = false,
		}
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	local character = player.Character
	if character then
		table.insert(exclude, character)
	end
	local fpvArms = camera:FindFirstChild(FPV_ARMS_MODEL_NAME)
	if fpvArms then
		table.insert(exclude, fpvArms)
	end
	if mounted and mounted.model then
		table.insert(exclude, mounted.model)
	end
	rayParams.FilterDescendantsInstances = exclude

	local viewport = camera.ViewportSize
	local bestScore = 0
	local bestDistance = nil
	local bestName = nil
	local bestIsGhost = false

	for _, sample in ipairs(INSTRUMENT_SAMPLE_PATTERN) do
		local sx = viewport.X * (0.5 + (sample.X * 0.32))
		local sy = viewport.Y * (0.5 + (sample.Y * 0.28))
		local ray = camera:ViewportPointToRay(sx, sy)
		local result = Workspace:Raycast(ray.Origin, ray.Direction * INSTRUMENT_RAY_DISTANCE, rayParams)
		if result and result.Instance and result.Instance:IsA("BasePart") and result.Instance.Transparency < 0.98 then
			local distance = math.max(0.5, result.Distance)
			local proximity = math.clamp(1 - (distance / INSTRUMENT_RAY_DISTANCE), 0, 1)
			proximity *= proximity
			local isGhost = isGhostSignalPart(result.Instance)
			local materialBoost = (result.Material == Enum.Material.Neon or result.Material == Enum.Material.Glass) and 0.06 or 0
			local score = (proximity * (isGhost and 1 or 0.42)) + materialBoost
			if isGhost then
				score = math.max(score, 0.58 + (proximity * 0.36))
			end
			score = math.clamp(score, 0, 1)
			if score > bestScore then
				bestScore = score
				bestDistance = distance
				bestName = resolveInstrumentTargetPartName(result.Instance)
				bestIsGhost = isGhost
			end
		end
	end

	local lifecycle = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	local scanGhostType = tostring(player:GetAttribute(CAMERA_SCAN_GHOST_ATTR) or "")
	local scanBoost = scanGhostType ~= "" and 0.18 or 0
	local huntBoost = lifecycle == "HuntPhase" and 0.26 or 0
	local useBoost = state.pendingUseVfx == true and 0.08 or 0
	local signal = math.clamp(math.max(baselineSignal, bestScore) + scanBoost + huntBoost + useBoost, 0, 1)

	state.instrumentSignal = signal
	state.instrumentTargetDistance = bestDistance
	state.instrumentTargetIsGhost = bestIsGhost
	state.instrumentTargetName = bestName and normalizeInstrumentTargetName(bestName) or nil
	return {
		signal = state.instrumentSignal,
		targetName = state.instrumentTargetName,
		targetDistance = state.instrumentTargetDistance,
		targetIsGhost = state.instrumentTargetIsGhost == true,
	}
end

local function updateJejakEnergiScreenVisual(mounted, now)
	if not mounted then
		return
	end
	ensureJejakEnergiScreen(mounted)
	local refs = mounted.emfRefs
	if type(refs) ~= "table" or type(refs.bars) ~= "table" then
		return
	end
	local emfSurface = mounted.emfScreenPart and mounted.emfScreenPart:FindFirstChild("FPV_EMFScreen")
	if emfSurface and emfSurface:IsA("SurfaceGui") and mounted.emfScreenFixedToModel ~= true then
		orientSurfaceToCamera(emfSurface, mounted.emfScreenPart)
	end
	if state.instrumentStartedAt <= 0 then
		state.instrumentStartedAt = now
	end
	local lifecycle = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	local probe = sampleInstrumentSignal(mounted, now)
	local level = 1 + math.floor((probe.signal * 4) + 0.5)
	if probe.targetDistance then
		local proximityLevel = math.clamp(5 - math.floor(probe.targetDistance / 6), 1, 5)
		if probe.targetIsGhost then
			proximityLevel = math.max(proximityLevel, 4)
		end
		level = math.max(level, proximityLevel)
	end
	if lifecycle == "HuntPhase" then
		level = math.max(level, 4)
	end
	level = math.clamp(level, 1, 5)
	state.emfDisplayLevel += (level - state.emfDisplayLevel) * 0.28
	local displayLevel = math.clamp(state.emfDisplayLevel, 1, 5)
	for index, bar in ipairs(refs.bars) do
		if bar and bar:IsA("Frame") then
			local fill = math.clamp(displayLevel - (index - 1), 0, 1)
			bar.BackgroundTransparency = 0.82 - (0.72 * fill)
			if fill <= 0.001 then
				bar.BackgroundTransparency = 0.84
			end
			if index >= 4 and fill > 0 then
				local alertBlend = math.clamp(fill + (index == 5 and 0.2 or 0), 0, 1)
				bar.BackgroundColor3 = EMF_SCREEN_THEME.accent:Lerp(Color3.fromRGB(255, 120, 120), alertBlend)
			else
				bar.BackgroundColor3 = EMF_SCREEN_THEME.accent
			end
		end
	end
	if refs.label and refs.label:IsA("TextLabel") then
		local severity = math.clamp(math.floor(displayLevel + 0.35), 1, 5)
		local label = "EMF LOW"
		if severity >= 5 then
			label = "EMF CRITICAL"
		elseif severity >= 4 then
			label = "EMF HIGH"
		elseif severity >= 3 then
			label = "EMF MEDIUM"
		end
		local suffix = ""
		if probe.targetDistance then
			local tag = probe.targetIsGhost and "GHOST" or "LOCK"
			suffix = string.format(" • %s %s", tag, formatInstrumentDistance(probe.targetDistance))
		elseif lifecycle == "PreparationPhase" and severity <= 2 then
			suffix = " • STAGING"
		end
		refs.label.Text = label .. suffix
	end
end

local function updateSuhuMembekuScreenVisual(mounted, now)
	if not mounted then
		return
	end
	ensureSuhuMembekuScreen(mounted)
	local refs = mounted.thermoRefs
	if type(refs) ~= "table" then
		return
	end
	local thermoSurface = mounted.thermoScreenPart and mounted.thermoScreenPart:FindFirstChild("FPV_ThermoScreen")
	if thermoSurface and thermoSurface:IsA("SurfaceGui") and mounted.thermoScreenFixedToModel ~= true then
		orientSurfaceToCamera(thermoSurface, mounted.thermoScreenPart)
	end
	if state.instrumentStartedAt <= 0 then
		state.instrumentStartedAt = now
	end
	local lifecycle = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	local probe = sampleInstrumentSignal(mounted, now)
	local ambient = 18.4 + (math.sin(now * 0.33) * 0.9)
	local coldDrop = probe.signal * 11.8
	if probe.targetIsGhost then
		coldDrop += 3.6
	end
	if lifecycle == "HuntPhase" then
		coldDrop += 3.2
	end
	local target = math.clamp(ambient - coldDrop, -8, 24)
	state.thermoDisplayC += (target - state.thermoDisplayC) * 0.2
	local display = state.thermoDisplayC
	local previousDisplay = state.thermoLastDisplayC or display
	local velocity = display - previousDisplay
	state.thermoLastDisplayC = display
	if refs.value and refs.value:IsA("TextLabel") then
		local freezeSuffix = display <= 0 and "  FREEZE" or ""
		refs.value.Text = string.format("%.1fC%s", display, freezeSuffix)
		local coldMix = math.clamp((12 - display) / 18, 0, 1)
		refs.value.TextColor3 = THERMO_SCREEN_THEME.warm:Lerp(THERMO_SCREEN_THEME.cold, coldMix)
	end
	if refs.trend and refs.trend:IsA("TextLabel") then
		local trend = "TREND STABLE"
		if velocity <= -0.045 then
			trend = "TREND DROPPING"
		elseif velocity >= 0.045 then
			trend = "TREND RISING"
		end
		if probe.targetDistance then
			local tag = probe.targetIsGhost and "COLD SPOT" or "LOCK"
			trend = string.format("%s • %s %s", trend, tag, formatInstrumentDistance(probe.targetDistance))
		elseif lifecycle == "PreparationPhase" and probe.signal < 0.35 then
			trend = trend .. " • STAGING"
		end
		refs.trend.Text = trend
	end
end

local function updateSpecialToolVisuals(mounted, now)
	if not mounted then
		return
	end
	if mounted.toolType == "BolaArwah" then
		updateBolaArwahScreenVisual(mounted, now)
	elseif mounted.toolType == "JejakEnergi" then
		updateJejakEnergiScreenVisual(mounted, now)
	elseif mounted.toolType == "SuhuMembeku" then
		updateSuhuMembekuScreenVisual(mounted, now)
	end
end

local function updateFlashlightVisual(mounted, deltaTime, flashlightEnabled)
	local hasMountedFlashlight = mounted and mounted.model and mounted.model.Parent ~= nil
	local targetAlpha = (hasMountedFlashlight and flashlightEnabled == true) and 1 or 0
	local fadeInSpeed = math.max(1, tonumber(FLASHLIGHT_LIGHT_CONFIG.fadeInSpeed) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.fadeInSpeed)
	local fadeOutSpeed = math.max(1, tonumber(FLASHLIGHT_LIGHT_CONFIG.fadeOutSpeed) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.fadeOutSpeed)
	local speed = targetAlpha > state.flashlightVisualAlpha and fadeInSpeed or fadeOutSpeed
	local stepAlpha = math.clamp((tonumber(deltaTime) or (1 / 60)) * speed, 0, 1)
	state.flashlightVisualAlpha += (targetAlpha - state.flashlightVisualAlpha) * stepAlpha
	if math.abs(targetAlpha - state.flashlightVisualAlpha) <= 0.01 then
		state.flashlightVisualAlpha = targetAlpha
	end

	if hasMountedFlashlight then
		local lens = ensureFlashlightLens(mounted)
		if lens then
			local onColor = coerceColor3(FLASHLIGHT_LENS_CONFIG.onColor, DEFAULT_FLASHLIGHT_LENS.onColor)
			local offColor = coerceColor3(FLASHLIGHT_LENS_CONFIG.offColor, DEFAULT_FLASHLIGHT_LENS.offColor)
			local onTransparency = tonumber(FLASHLIGHT_LENS_CONFIG.onTransparency) or DEFAULT_FLASHLIGHT_LENS.onTransparency
			local offTransparency = tonumber(FLASHLIGHT_LENS_CONFIG.offTransparency) or DEFAULT_FLASHLIGHT_LENS.offTransparency
			lens.Material = state.flashlightVisualAlpha > 0.18 and Enum.Material.Neon or Enum.Material.SmoothPlastic
			lens.Color = offColor:Lerp(onColor, state.flashlightVisualAlpha)
			lens.Transparency = offTransparency + ((onTransparency - offTransparency) * state.flashlightVisualAlpha)
		end

		local light = ensureFlashlightLocalLight(mounted)
		if light then
			orientSpotLightToCameraLook(light, light.Parent)
			local onBrightness = tonumber(FLASHLIGHT_LIGHT_CONFIG.brightness) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.brightness
			local offBrightness = tonumber(FLASHLIGHT_LIGHT_CONFIG.offBrightness) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.offBrightness
			local onRange = tonumber(FLASHLIGHT_LIGHT_CONFIG.range) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.range
			local offRange = tonumber(FLASHLIGHT_LIGHT_CONFIG.offRange) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.offRange
			local onAngle = tonumber(FLASHLIGHT_LIGHT_CONFIG.angle) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.angle
			local offAngle = tonumber(FLASHLIGHT_LIGHT_CONFIG.offAngle) or DEFAULT_FLASHLIGHT_LOCAL_LIGHT.offAngle

			light.Color = coerceColor3(FLASHLIGHT_LIGHT_CONFIG.color, DEFAULT_FLASHLIGHT_LOCAL_LIGHT.color)
			light.Brightness = offBrightness + ((onBrightness - offBrightness) * state.flashlightVisualAlpha)
			light.Range = offRange + ((onRange - offRange) * state.flashlightVisualAlpha)
			light.Angle = offAngle + ((onAngle - offAngle) * state.flashlightVisualAlpha)
			light.Enabled = state.flashlightVisualAlpha > 0.02
		end
		updateFlashlightViewmodelProxy(mounted)
	end

	player:SetAttribute(FLASHLIGHT_VISUAL_ALPHA_ATTRIBUTE, state.flashlightVisualAlpha)
	player:SetAttribute(FLASHLIGHT_LIGHT_ENABLED_ATTRIBUTE, state.flashlightVisualAlpha > 0.02)
end

local function emitUseBurst(worldCFrame, mounted, succeeded, eventName)
	if not mounted then
		return
	end
	local vfx = mounted.profile.useVfx
	local style = resolveUseVfxStyleProfile(mounted.toolType, vfx, succeeded)
	local burstCount = math.max(2, math.floor((vfx.burst * style.burstScale) + 0.5))
	local speedMin = math.max(0.4, vfx.speed * style.speedScale * 0.7)
	local speedMax = math.max(speedMin + 0.1, vfx.speed * style.speedScale * 1.2)
	local lifeMin = math.max(0.08, vfx.lifetime * style.lifetimeScale * 0.8)
	local lifeMax = math.max(lifeMin + 0.02, vfx.lifetime * style.lifetimeScale * 1.15)

	local part = Instance.new("Part")
	part.Name = "ToolUseVFX"
	part.Size = Vector3.new(0.12, 0.12, 0.12)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.CFrame = worldCFrame
	part.Parent = Workspace.CurrentCamera or Workspace

	local attachment = Instance.new("Attachment")
	attachment.Name = "UseVFXAttachment"
	attachment.Parent = part

	local emitter = cloneVisualTemplate(TOOL_USE_BURST_EMITTER_TEMPLATE_PATH, "UseBurst")
	if not (emitter and emitter:IsA("ParticleEmitter")) then
		warnMissingVisualTemplate("ToolVisuals.ToolUseBurstEmitterTemplate")
		part:Destroy()
		return
	end
	emitter.Name = "UseBurst"
	emitter.Texture = style.texture
	emitter.Rate = 0
	emitter.SpreadAngle = Vector2.new(style.spread, style.spread)
	emitter.Speed = NumberRange.new(speedMin, speedMax)
	emitter.Lifetime = NumberRange.new(lifeMin, lifeMax)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.LightEmission = style.lightEmission
	emitter.Color = ColorSequence.new(style.color)
	emitter.Acceleration = style.acceleration
	emitter.Drag = style.drag
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, style.sizeStart),
		NumberSequenceKeypoint.new(1, style.sizeEnd),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, style.failed and 0.2 or 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = attachment
	emitter:Emit(burstCount)

	if style.token == "Smoke" then
		local plume = cloneVisualTemplate(TOOL_USE_SMOKE_PLUME_TEMPLATE_PATH, "UseSmokePlume")
		if not (plume and plume:IsA("ParticleEmitter")) then
			warnMissingVisualTemplate("ToolVisuals.ToolUseSmokePlumeEmitterTemplate")
			plume = nil
		end
		if plume then
			plume.Name = "UseSmokePlume"
			plume.Texture = "rbxassetid://241685934"
			plume.Rate = 0
			plume.SpreadAngle = Vector2.new(16, 16)
			plume.Speed = NumberRange.new(math.max(0.45, vfx.speed * 0.32), math.max(0.8, vfx.speed * 0.58))
			plume.Lifetime = NumberRange.new(math.max(0.24, vfx.lifetime * 1.2), math.max(0.4, vfx.lifetime * 1.8))
			plume.Rotation = NumberRange.new(-20, 20)
			plume.RotSpeed = NumberRange.new(-28, 28)
			plume.LightEmission = 0.08
			plume.Color = ColorSequence.new(style.color)
			plume.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.22),
				NumberSequenceKeypoint.new(1, 1),
			})
			plume.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, style.sizeStart * 0.9),
				NumberSequenceKeypoint.new(1, math.max(style.sizeEnd * 4, 0.08)),
			})
			plume.Acceleration = Vector3.new(0, 2.8, 0)
			plume.Drag = 0.4
			plume.Parent = attachment
			plume:Emit(math.max(4, math.floor(burstCount * 0.45)))
		end
	elseif style.token == "Holy" then
		local halo = cloneVisualTemplate(TOOL_USE_HOLY_HALO_TEMPLATE_PATH, "UseHolyHalo")
		if not (halo and halo:IsA("ParticleEmitter")) then
			warnMissingVisualTemplate("ToolVisuals.ToolUseHolyHaloEmitterTemplate")
			halo = nil
		end
		if halo then
			halo.Name = "UseHolyHalo"
			halo.Texture = "rbxassetid://6489023589"
			halo.Rate = 0
			halo.SpreadAngle = Vector2.new(42, 42)
			halo.Speed = NumberRange.new(math.max(0.6, vfx.speed * 0.42), math.max(0.9, vfx.speed * 0.78))
			halo.Lifetime = NumberRange.new(math.max(0.2, vfx.lifetime), math.max(0.34, vfx.lifetime * 1.6))
			halo.RotSpeed = NumberRange.new(-90, 90)
			halo.LightEmission = 0.72
			halo.Color = ColorSequence.new(style.color:Lerp(Color3.fromRGB(255, 244, 196), 0.5))
			halo.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.16),
				NumberSequenceKeypoint.new(1, 1),
			})
			halo.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, style.sizeStart * 1.2),
				NumberSequenceKeypoint.new(1, style.sizeEnd * 2.2),
			})
			halo.Acceleration = Vector3.new(0, 3.2, 0)
			halo.Parent = attachment
			halo:Emit(math.max(6, math.floor(burstCount * 0.55)))
		end
	elseif style.token == "Scan" then
		local scanEmitter = cloneVisualTemplate(TOOL_USE_SCAN_PULSE_TEMPLATE_PATH, "UseScanPulse")
		if not (scanEmitter and scanEmitter:IsA("ParticleEmitter")) then
			warnMissingVisualTemplate("ToolVisuals.ToolUseScanPulseEmitterTemplate")
			scanEmitter = nil
		end
		if scanEmitter then
			scanEmitter.Name = "UseScanPulse"
			scanEmitter.Texture = "rbxassetid://6489023589"
			scanEmitter.Rate = 0
			scanEmitter.SpreadAngle = Vector2.new(8, 8)
			scanEmitter.Speed = NumberRange.new(math.max(0.7, vfx.speed * 0.65), math.max(1.2, vfx.speed * 1.05))
			scanEmitter.Lifetime = NumberRange.new(math.max(0.14, vfx.lifetime * 0.9), math.max(0.24, vfx.lifetime * 1.4))
			scanEmitter.RotSpeed = NumberRange.new(-120, 120)
			scanEmitter.LightEmission = 0.66
			scanEmitter.Color = ColorSequence.new(style.color)
			scanEmitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.04),
				NumberSequenceKeypoint.new(1, 1),
			})
			scanEmitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, style.sizeStart * 0.8),
				NumberSequenceKeypoint.new(1, style.sizeEnd * 1.6),
			})
			scanEmitter.Acceleration = Vector3.new(0, 0, 0)
			scanEmitter.Drag = 0.6
			scanEmitter.Parent = attachment
			scanEmitter:Emit(math.max(5, math.floor(burstCount * 0.5)))
		end
	end

	local pulse = cloneVisualTemplate(TOOL_USE_PULSE_LIGHT_TEMPLATE_PATH, "UsePulse")
	if not (pulse and pulse:IsA("PointLight")) then
		warnMissingVisualTemplate("ToolVisuals.ToolUsePulseLightTemplate")
		pulse = nil
	end
	if pulse then
		pulse.Name = "UsePulse"
		pulse.Color = style.color
		pulse.Brightness = style.pulseBrightness * style.pulseScale
		pulse.Range = style.pulseRange * style.pulseScale
		pulse.Shadows = false
		pulse.Parent = part
	end

	task.delay(0.08, function()
		if pulse and pulse.Parent then
			pulse.Enabled = false
		end
	end)

	Debris:AddItem(part, math.max(0.45, (vfx.lifetime * 2.1)))
	player:SetAttribute("PasrahToolUseVfxStyle", style.token)
	player:SetAttribute("PasrahToolUseVfxSuccess", succeeded ~= false)
	player:SetAttribute("PasrahToolUseEvent", (type(eventName) == "string" and eventName ~= "") and eventName or nil)
end

local function resolveRemoteHandPart(character)
	if not character then
		return nil
	end
	for _, name in ipairs({ "RightHand", "Right Arm", "RightLowerArm", "HumanoidRootPart" }) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return character:FindFirstChildWhichIsA("BasePart")
end

local function resolveRemotePlayerActiveTool(remotePlayer)
	if remotePlayer == player then
		return nil
	end
	if typeof(remotePlayer) ~= "Instance" or not remotePlayer:IsA("Player") then
		return nil
	end
	local inMatch = remotePlayer:GetAttribute("InMatch") == true or tostring(remotePlayer:GetAttribute("MatchId") or "") ~= ""
	if not inMatch then
		return nil
	end
	local toolType = remotePlayer:GetAttribute(EQUIPPED_TOOL_ATTRIBUTE)
	if type(toolType) ~= "string" or toolType == "" then
		toolType = remotePlayer:GetAttribute(PREPARATION_TOOL_ATTRIBUTE)
	end
	if type(toolType) ~= "string" or toolType == "" or toolType == "Flashlight" then
		return nil
	end
	return toolType
end

local function clearRemoteTool(remotePlayer)
	local record = state.remoteTools[remotePlayer]
	if not record then
		return
	end
	if record.model and record.model.Parent then
		record.model:Destroy()
	end
	if type(record.connections) == "table" then
		for _, connection in ipairs(record.connections) do
			connection:Disconnect()
		end
	end
	state.remoteTools[remotePlayer] = nil
end

local function ensureRemoteTool(remotePlayer, toolType)
	local character = remotePlayer and remotePlayer.Character
	local handPart = resolveRemoteHandPart(character)
	if not (character and handPart) then
		local record = state.remoteTools[remotePlayer]
		if record and record.model and record.model.Parent then
			record.model:Destroy()
			record.model = nil
		end
		return nil
	end

	local record = state.remoteTools[remotePlayer]
	if record and record.toolType == toolType and record.model and record.model.Parent == character then
		record.handPart = handPart
		return record
	end
	if record and record.model and record.model.Parent then
		record.model:Destroy()
	end

	local profile = applyUsageRuleToProfile(toolType, resolveToolProfile(toolType))
	local model = cloneToolModel(toolType, profile.targetBounds)
	if not model then
		return nil
	end
	applyInventoryMeshAssetId(model, profile.inventoryModelAssetId)
	if profile.targetBounds then
		clampModelBounds(model, profile.targetBounds)
	end
	ensurePrimaryPart(model)
	model.Name = REMOTE_HELD_TOOL_MODEL_NAME
	model:SetAttribute("PasrahRemoteHeldToolType", toolType)
	model:SetAttribute("PasrahRemoteHeldToolOwnerUserId", remotePlayer.UserId)
	model.Parent = character

	record = record or {
		connections = {},
	}
	record.toolType = toolType
	record.model = model
	record.profile = profile
	record.handPart = handPart
	state.remoteTools[remotePlayer] = record
	return record
end

local function updateRemotePlayerTool(remotePlayer)
	local toolType = resolveRemotePlayerActiveTool(remotePlayer)
	if not toolType then
		local record = state.remoteTools[remotePlayer]
		if record then
			if record.model and record.model.Parent then
				record.model:Destroy()
			end
			record.model = nil
			record.toolType = nil
		end
		return
	end
	local record = ensureRemoteTool(remotePlayer, toolType)
	if not (record and record.model and record.handPart) then
		return
	end
	local mountOffset = CFrame.new(0, -0.54, -0.22) * CFrame.Angles(math.rad(-84), 0, math.rad(8))
	record.model:PivotTo(record.handPart.CFrame * mountOffset)
end

local function updateAllRemoteTools()
	for _, remotePlayer in ipairs(Players:GetPlayers()) do
		if remotePlayer ~= player then
			updateRemotePlayerTool(remotePlayer)
		end
	end
end

local function bindRemotePlayerTool(remotePlayer)
	if remotePlayer == player or state.remoteTools[remotePlayer] then
		return
	end
	state.remoteTools[remotePlayer] = {
		connections = {},
	}
	local record = state.remoteTools[remotePlayer]
	local function markDirty()
		record.dirty = true
	end
	table.insert(record.connections, remotePlayer:GetAttributeChangedSignal(EQUIPPED_TOOL_ATTRIBUTE):Connect(markDirty))
	table.insert(record.connections, remotePlayer:GetAttributeChangedSignal(PREPARATION_TOOL_ATTRIBUTE):Connect(markDirty))
	table.insert(record.connections, remotePlayer:GetAttributeChangedSignal("InMatch"):Connect(markDirty))
	table.insert(record.connections, remotePlayer:GetAttributeChangedSignal("MatchId"):Connect(markDirty))
	table.insert(record.connections, remotePlayer.CharacterAdded:Connect(function()
		if record.model and record.model.Parent then
			record.model:Destroy()
		end
		record.model = nil
		record.dirty = true
	end))
	record.dirty = true
end

local function updateMountedTool(deltaTime)
	local now = os.clock()
	if state.useAnimationToolType and now >= (state.useAnimationUntil or 0) then
		state.useAnimationToolType = nil
		state.useAnimationEventName = nil
	end
	if state.pendingUseVfx == true and now > (state.pendingUseVfxUntil or 0) then
		state.pendingUseVfx = false
		state.pendingUseVfxToolType = nil
		state.pendingUseVfxSucceeded = true
		state.pendingUseVfxEventName = nil
	end
	local fpvArms = getFpvArmsModel()
	local activeToolType = resolveActiveToolType(now)
	local flashlightEnabled = player:GetAttribute(FLASHLIGHT_ENABLED_ATTRIBUTE) == true
	local flashlightPrimary = activeToolType == "Flashlight"
	local shouldShowFlashlight = flashlightPrimary

	if not fpvArms then
		clearMountedTool()
		clearFlashlightMount()
		updateFlashlightVisual(nil, deltaTime, false)
		return
	end
	resetFpvGripPose(fpvArms)

	if activeToolType and activeToolType ~= "Flashlight" then
		local mounted = ensureMountedTool(activeToolType, fpvArms, now)
		if mounted and mounted.model and mounted.model.Parent == fpvArms then
			enforceMountedTargetBounds(mounted)
			local mountWorldCFrame, baseCFrame = resolveMountWorldCFrame(fpvArms, mounted.profile.mount, computeAnimatedOffset(mounted, now))
			if mountWorldCFrame and baseCFrame then
				local viewportOffset = nil
				mountWorldCFrame, viewportOffset = fitMountToViewport(mountWorldCFrame, mounted.profile.mount)
				mounted.model:PivotTo(mountWorldCFrame)
				ensureViewmodelFillLight(mounted)
				updateSpecialToolVisuals(mounted, now)
				applyFpvToolGripPose(fpvArms, mounted)

				if state.pendingUseVfx == true and state.pendingUseVfxToolType == mounted.toolType then
					local succeeded = state.pendingUseVfxSucceeded ~= false
					local eventName = state.pendingUseVfxEventName
					state.pendingUseVfx = false
					state.pendingUseVfxToolType = nil
					state.pendingUseVfxSucceeded = true
					state.pendingUseVfxEventName = nil
					local useWorldCFrame = baseCFrame * cframeFromSpec(mounted.profile.mount.cframe)
					if viewportOffset then
						local adjustedUsePosition = useWorldCFrame.Position + viewportOffset
						useWorldCFrame = CFrame.new(adjustedUsePosition) * useWorldCFrame.Rotation
					end
					emitUseBurst(useWorldCFrame, mounted, succeeded, eventName)
				end

				mounted.holdUntil = math.max(mounted.holdUntil or 0, now + math.max(0.35, deltaTime * 2))
			end
		end
	elseif activeToolType == "Flashlight" then
		clearMountedTool()
	elseif state.mounted then
		if now > (state.mounted.holdUntil or 0) then
			clearMountedTool()
		end
	end

	if shouldShowFlashlight then
		local flashlightMount = ensureFlashlightMount(fpvArms, now, activeToolType)
		if flashlightMount and flashlightMount.model and flashlightMount.model.Parent == fpvArms then
			enforceMountedTargetBounds(flashlightMount)
			local flashlightWorld = resolveMountWorldCFrame(fpvArms, flashlightMount.profile.mount, nil)
			if flashlightWorld then
				flashlightWorld = fitMountToViewport(flashlightWorld, flashlightMount.profile.mount)
				flashlightMount.model:PivotTo(flashlightWorld)
				ensureViewmodelFillLight(flashlightMount)
				applyFpvToolGripPose(fpvArms, flashlightMount)
				flashlightMount.holdUntil = math.max(flashlightMount.holdUntil or 0, now + math.max(0.35, deltaTime * 2))
			end
		end
	else
		clearFlashlightMount()
	end

	updateFlashlightVisual(state.flashlightMounted, deltaTime, flashlightEnabled)
end

local function onToolUseStampChanged()
	local stamp = tonumber(player:GetAttribute(TOOL_USE_STAMP_ATTRIBUTE))
	if not stamp or stamp <= state.lastUseStamp then
		return
	end
	state.lastUseStamp = stamp

	local now = os.clock()
	local activeToolType = resolveActiveToolType(now)
	if not activeToolType or activeToolType == "Flashlight" then
		return
	end

	local profile = resolveToolProfile(activeToolType)
	local succeeded = player:GetAttribute(TOOL_LAST_SUCCESS_ATTRIBUTE) ~= false
	local eventName = tostring(player:GetAttribute(TOOL_LAST_EVENT_ATTRIBUTE) or "")
	local shouldDriveUseVisual = (eventName == "ClientToolRequest") or (succeeded == false)
	if not shouldDriveUseVisual then
		return
	end
	state.useAnimationUntil = now + math.max(0.1, profile.useAnimation.duration)
	state.useAnimationToolType = activeToolType
	state.useAnimationSucceeded = succeeded
	state.useAnimationEventName = eventName
	state.pendingUseVfx = true
	state.pendingUseVfxToolType = activeToolType
	state.pendingUseVfxSucceeded = succeeded
	state.pendingUseVfxEventName = eventName
	state.pendingUseVfxUntil = now + 0.35
	player:SetAttribute("PasrahToolUseAnimationTool", activeToolType)
	player:SetAttribute("PasrahToolUseAnimationSuccess", succeeded)
	player:SetAttribute("PasrahToolUseAnimationEvent", eventName ~= "" and eventName or nil)
	state.dirty = true
end

player:GetAttributeChangedSignal(EQUIPPED_TOOL_ATTRIBUTE):Connect(function()
	state.dirty = true
end)
player:GetAttributeChangedSignal(TOOL_USE_STAMP_ATTRIBUTE):Connect(onToolUseStampChanged)
player:GetAttributeChangedSignal(PREPARATION_TOOL_ATTRIBUTE):Connect(function()
	state.dirty = true
end)
player:GetAttributeChangedSignal("InMatch"):Connect(function()
	state.dirty = true
end)
player:GetAttributeChangedSignal("MatchId"):Connect(function()
	state.dirty = true
end)
player:GetAttributeChangedSignal(FLASHLIGHT_ENABLED_ATTRIBUTE):Connect(function()
	state.dirty = true
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if UserInputService:GetFocusedTextBox() then
		return
	end

	local requestedSlot = nil
	for slot, keyCode in ipairs(LOADOUT_SLOT_KEY_CODES) do
		if input.KeyCode == keyCode then
			requestedSlot = slot
			break
		end
	end
	if not requestedSlot then
		return
	end
	if gameProcessed and input.KeyCode ~= Enum.KeyCode.One and input.KeyCode ~= Enum.KeyCode.Two and input.KeyCode ~= Enum.KeyCode.Three then
		return
	end

	local toolType = player:GetAttribute(LOADOUT_TOOL_ATTR_PREFIX .. tostring(requestedSlot))
	if type(toolType) ~= "string" or toolType == "" then
		return
	end

	player:SetAttribute(EQUIPPED_TOOL_ATTRIBUTE, toolType)
	state.dirty = true
end)

player.CharacterAdded:Connect(function()
	state.dirty = true
end)

for _, remotePlayer in ipairs(Players:GetPlayers()) do
	bindRemotePlayerTool(remotePlayer)
end
Players.PlayerAdded:Connect(bindRemotePlayerTool)
Players.PlayerRemoving:Connect(clearRemoteTool)

RunService.RenderStepped:Connect(function(deltaTime)
	updateMountedTool(deltaTime)
	updateAllRemoteTools()
	if state.dirty then
		state.dirty = false
	end
end)

print("[ToolVisualController] unified tool + flashlight visual runtime active")
