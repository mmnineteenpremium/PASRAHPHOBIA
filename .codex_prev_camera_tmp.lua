--[[
    CAMERA CONTROLLER
    FPV lock in investigation maps, TPV allowed in lobby
    Head bobbing for immersive walking feel

    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.5
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local DEFAULT_CAMERA_MIN_ZOOM = player.CameraMinZoomDistance
local DEFAULT_CAMERA_MAX_ZOOM = player.CameraMaxZoomDistance
local UNLOCKED_CURSOR_FPV_ZOOM = 0.5

-- Head bobbing parameters
local bobFrequency = 2.4 -- Bob cycles per second
local bobAmplitude = 0.18 -- Vertical bob amount (studs)
local swayAmplitude = 0.08 -- Horizontal sway amount (studs)
local bobOffset = Vector3.new(0, 0, 0)

-- FPV lock (will be toggled based on map)
local FPV_LOCKED = false
local FPV_ARMS_MODEL_NAME = "FPV_Arms"
local FPV_VIEW_ROOT_NAME = "FPV_ViewRoot"
local FPV_FLASHLIGHT_MODEL_NAME = "FPV_Flashlight"
local FLASHLIGHT_ATTRIBUTE = "FlashlightEnabled"
local UV_FLASHLIGHT_OWNED_ATTR = "PasrahOwnsUVFlashlight"
local CURSOR_TOGGLE_KEY = Enum.KeyCode.LeftAlt
local CURSOR_TOGGLE_FALLBACK_KEY = Enum.KeyCode.Backquote
local CURSOR_UNLOCK_REQUEST_ATTR = "PasrahCursorUnlockRequested"
local CURSOR_MODE_ATTR = "PasrahCursorMode"
local HEAD_BOB_PROBE_ATTR = "PasrahHeadBobProbeActive"
local HEAD_BOB_OFFSET_ATTR = "PasrahHeadBobOffset"
local FLASHLIGHT_VISUAL_ALPHA_ATTR = "PasrahFlashlightVisualAlpha"
local FLASHLIGHT_LIGHT_ENABLED_ATTR = "PasrahFlashlightLightEnabled"
local FLASHLIGHT_AIM_OFFSET_ATTR = "PasrahFlashlightAimOffset"
local CURSOR_TOGGLE_GUI_NAME = "FPVCursorToggleUI"
local CURSOR_TOGGLE_BUTTON_NAME = "CursorToggleButton"
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

local function loadFlashlightConfig()
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	local gameData = shared and shared:FindFirstChild("GameData")
	return safeRequire(gameData and gameData:FindFirstChild("FlashlightConfig")) or {}
end

local FLASHLIGHT_CONFIG = loadFlashlightConfig()
local HANDLE_CONFIG = FLASHLIGHT_CONFIG.handle or {}
local LENS_CONFIG = FLASHLIGHT_CONFIG.lens or {}
local LOCAL_LIGHT_CONFIG = FLASHLIGHT_CONFIG.localLight or {}
local VIEWMODEL_CONFIG = FLASHLIGHT_CONFIG.viewmodel or {}
local MOTION_CONFIG = FLASHLIGHT_CONFIG.motion or {}
local FPV_BASE_OFFSET = VIEWMODEL_CONFIG.baseOffset or (CFrame.new(0, -1.36, -1.54) * CFrame.Angles(math.rad(-12), 0, 0))
local FPV_PART_SCALE = tonumber(VIEWMODEL_CONFIG.partScale) or 0.86
local VIEWMODEL_HANDS_ONLY = VIEWMODEL_CONFIG.handsOnly == true
local VIEWMODEL_ARM_MATERIAL = VIEWMODEL_CONFIG.armMaterial or Enum.Material.SmoothPlastic
local VIEWMODEL_ARM_BRIGHTNESS_SCALE = tonumber(VIEWMODEL_CONFIG.armBrightnessScale) or 0.62
local VIEWMODEL_HAND_BRIGHTNESS_SCALE = tonumber(VIEWMODEL_CONFIG.handBrightnessScale) or 0.52
local VIEWMODEL_ARM_MIN_CHANNEL = tonumber(VIEWMODEL_CONFIG.armMinChannel) or 0.12
local VIEWMODEL_ARM_MAX_CHANNEL = tonumber(VIEWMODEL_CONFIG.armMaxChannel) or 0.62
local LOCAL_LIGHT_ON_BRIGHTNESS = tonumber(LOCAL_LIGHT_CONFIG.brightness) or 1.35
local LOCAL_LIGHT_ON_RANGE = tonumber(LOCAL_LIGHT_CONFIG.range) or 12
local LOCAL_LIGHT_ON_ANGLE = tonumber(LOCAL_LIGHT_CONFIG.angle) or 24
local LOCAL_LIGHT_OFF_BRIGHTNESS = tonumber(LOCAL_LIGHT_CONFIG.offBrightness) or 0
local LOCAL_LIGHT_OFF_RANGE = tonumber(LOCAL_LIGHT_CONFIG.offRange) or 2
local LOCAL_LIGHT_OFF_ANGLE = tonumber(LOCAL_LIGHT_CONFIG.offAngle) or 12
local LOCAL_LIGHT_FADE_IN_SPEED = tonumber(LOCAL_LIGHT_CONFIG.fadeInSpeed) or 10
local LOCAL_LIGHT_FADE_OUT_SPEED = tonumber(LOCAL_LIGHT_CONFIG.fadeOutSpeed) or 7
local LOCAL_LIGHT_DEFAULT_COLOR = LOCAL_LIGHT_CONFIG.color or Color3.fromRGB(255, 244, 214)
local UV_FLASHLIGHT_ON_COLOR = Color3.fromRGB(168, 214, 255)
local UV_FLASHLIGHT_OFF_COLOR = Color3.fromRGB(98, 116, 136)
local UV_FLASHLIGHT_LIGHT_COLOR = Color3.fromRGB(186, 224, 255)
local MOTION_WALK_SPEED_REFERENCE = tonumber(MOTION_CONFIG.walkSpeedReference) or 14
local MOTION_CURSOR_UNLOCK_BOB_SCALE = tonumber(MOTION_CONFIG.cursorUnlockedBobScale) or 0.18
local MOTION_IDLE_BREATH_AMPLITUDE = tonumber(MOTION_CONFIG.idleBreathAmplitude) or 0.018
local MOTION_IDLE_BREATH_SPEED = tonumber(MOTION_CONFIG.idleBreathSpeed) or 1.35
local MOTION_CAMERA_LAG_ALPHA = tonumber(MOTION_CONFIG.cameraLagAlpha) or 0.15
local MOTION_LOOK_SWAY_X = tonumber(MOTION_CONFIG.lookSwayX) or 0.035
local MOTION_LOOK_SWAY_Y = tonumber(MOTION_CONFIG.lookSwayY) or 0.024
local MOTION_MOVE_SWAY_SCALE = tonumber(MOTION_CONFIG.moveSwayScale) or 0.5
local MOTION_FLASHLIGHT_CARRY_OFFSET = MOTION_CONFIG.flashlightCarryOffset or Vector3.new(0.04, -0.015, -0.045)
local MOTION_FLASHLIGHT_CARRY_ROLL = tonumber(MOTION_CONFIG.flashlightCarryRoll) or -2.5
local fpvArmsModel = nil
local fpvFlashlightModel = nil
local fpvFlashlightHandle = nil
local fpvFlashlightLens = nil
local fpvFlashlightLight = nil
local fpvArmsSourceParts = {}
local lastArmCamCF = nil
local _fpvJustActivated = false
local fpvCursorUnlocked = false
local fpvCursorToggleGui = nil
local fpvCursorToggleButton = nil
local fpvFlashlightVisualAlpha = 0
local lastLoggedCameraMode = nil
local setCursorUnlocked

local function lerpNumber(a, b, alpha)
	return a + ((b - a) * math.clamp(alpha, 0, 1))
end

player:SetAttribute(FLASHLIGHT_VISUAL_ALPHA_ATTR, 0)
player:SetAttribute(FLASHLIGHT_LIGHT_ENABLED_ATTR, false)
player:SetAttribute(CURSOR_MODE_ATTR, "Default")
player:SetAttribute(FLASHLIGHT_AIM_OFFSET_ATTR, Vector3.zero)

local function toneMapArmChannel(value)
	return math.clamp(value, VIEWMODEL_ARM_MIN_CHANNEL, VIEWMODEL_ARM_MAX_CHANNEL)
end

local function buildArmColor(sourceColor, brightnessScale)
	local color = sourceColor or Color3.fromRGB(190, 170, 150)
	local scale = brightnessScale or VIEWMODEL_ARM_BRIGHTNESS_SCALE
	return Color3.new(
		toneMapArmChannel(color.R * scale),
		toneMapArmChannel(color.G * scale),
		toneMapArmChannel(color.B * scale)
	)
end

local function getPlayerGui()
	return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
end

local function ensureCursorToggleUi()
	local playerGui = getPlayerGui()
	if not playerGui then
		return nil
	end
	if fpvCursorToggleGui and fpvCursorToggleGui.Parent ~= playerGui then
		fpvCursorToggleGui = nil
		fpvCursorToggleButton = nil
	end
	if fpvCursorToggleGui and fpvCursorToggleButton then
		return fpvCursorToggleButton
	end

	local existingGui = playerGui:FindFirstChild(CURSOR_TOGGLE_GUI_NAME)
	if existingGui and existingGui:IsA("ScreenGui") then
		fpvCursorToggleGui = existingGui
		fpvCursorToggleButton = existingGui:FindFirstChild(CURSOR_TOGGLE_BUTTON_NAME)
		if fpvCursorToggleButton and fpvCursorToggleButton:IsA("TextButton") then
			return fpvCursorToggleButton
		end
		existingGui:Destroy()
		fpvCursorToggleGui = nil
		fpvCursorToggleButton = nil
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = CURSOR_TOGGLE_GUI_NAME
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 260
	gui.Enabled = false
	gui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = CURSOR_TOGGLE_BUTTON_NAME
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, 112)
	button.Size = UDim2.fromOffset(154, 38)
	button.BackgroundColor3 = Color3.fromRGB(48, 64, 84)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.TextSize = 13
	button.Text = "FREE CURSOR [ALT/~]"
	button.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Color = Color3.fromRGB(124, 150, 186)
	stroke.Parent = button

	button.MouseButton1Click:Connect(function()
		if setCursorUnlocked then
			setCursorUnlocked(not fpvCursorUnlocked)
		end
	end)

	fpvCursorToggleGui = gui
	fpvCursorToggleButton = button
	return button
end

local function updateCursorToggleUi()
	local button = ensureCursorToggleUi()
	if not fpvCursorToggleGui or not button then
		return
	end
	local show = FPV_LOCKED and UserInputService.KeyboardEnabled
	fpvCursorToggleGui.Enabled = show
	button.Visible = show
	button.Text = fpvCursorUnlocked and "RETURN FPV [ALT/~]" or "UI CURSOR [ALT/~]"
	button.BackgroundColor3 = fpvCursorUnlocked and Color3.fromRGB(82, 98, 58) or Color3.fromRGB(48, 64, 84)
end

local function applyFpvMouseMode()
	if FPV_LOCKED then
		if fpvCursorUnlocked then
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMinZoomDistance = UNLOCKED_CURSOR_FPV_ZOOM
			player.CameraMaxZoomDistance = UNLOCKED_CURSOR_FPV_ZOOM
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
			player:SetAttribute(CURSOR_MODE_ATTR, "UnlockedUI")
		else
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMinZoomDistance = DEFAULT_CAMERA_MIN_ZOOM
			player.CameraMaxZoomDistance = DEFAULT_CAMERA_MAX_ZOOM
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
			player:SetAttribute(CURSOR_MODE_ATTR, "LockedFPV")
		end
	else
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = DEFAULT_CAMERA_MIN_ZOOM
		player.CameraMaxZoomDistance = DEFAULT_CAMERA_MAX_ZOOM
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		player:SetAttribute(CURSOR_MODE_ATTR, "Default")
	end
	player:SetAttribute("PasrahCursorUnlocked", FPV_LOCKED and fpvCursorUnlocked or false)
	updateCursorToggleUi()
end

setCursorUnlocked = function(unlocked)
	fpvCursorUnlocked = unlocked == true
	applyFpvMouseMode()
end

local function ensureCameraAuthority(humanoid)
	if not camera or not humanoid then
		return
	end
	camera.CameraType = Enum.CameraType.Custom
	if camera.CameraSubject ~= humanoid then
		camera.CameraSubject = humanoid
	end
end

local function clearFpvArms()
	if fpvArmsModel and fpvArmsModel.Parent then
		fpvArmsModel:Destroy()
	end
	fpvArmsModel = nil
	fpvFlashlightModel = nil
	fpvFlashlightHandle = nil
	fpvFlashlightLens = nil
	fpvFlashlightLight = nil
	fpvFlashlightVisualAlpha = 0
	player:SetAttribute(FLASHLIGHT_VISUAL_ALPHA_ATTR, 0)
	player:SetAttribute(FLASHLIGHT_LIGHT_ENABLED_ATTR, false)

	for _, info in ipairs(fpvArmsSourceParts) do
		local sourcePart = info.part
		if sourcePart and sourcePart.Parent and sourcePart:IsA("BasePart") then
			sourcePart.LocalTransparencyModifier = info.originalTransparency or 0
		end
	end
	table.clear(fpvArmsSourceParts)
end

local function appendCloneDefinition(definitions, sourcePart, cloneName, isPrimary)
	if sourcePart and sourcePart:IsA("BasePart") then
		table.insert(definitions, {
			source = sourcePart,
			cloneName = cloneName,
			isPrimary = isPrimary == true,
		})
	end
end

local function collectArmParts(character)
	if not character then
		return nil
	end

	local definitions = {}
	local rightUpperArm = character:FindFirstChild("RightUpperArm")
	local rightLowerArm = character:FindFirstChild("RightLowerArm")
	local rightHand = character:FindFirstChild("RightHand")
	local leftUpperArm = character:FindFirstChild("LeftUpperArm")
	local leftLowerArm = character:FindFirstChild("LeftLowerArm")
	local leftHand = character:FindFirstChild("LeftHand")
	if rightUpperArm or rightLowerArm or rightHand or leftUpperArm or leftLowerArm or leftHand then
		appendCloneDefinition(definitions, leftUpperArm, "FPV_LeftUpperArm", false)
		appendCloneDefinition(definitions, leftLowerArm, "FPV_LeftLowerArm", false)
		appendCloneDefinition(definitions, leftHand, "FPV_LeftHand", false)
		appendCloneDefinition(definitions, rightUpperArm, "FPV_RightUpperArm", false)
		appendCloneDefinition(definitions, rightLowerArm, "FPV_RightLowerArm", false)
		appendCloneDefinition(definitions, rightHand, "FPV_RightHand", true)
		return definitions
	end

	local leftArm = character:FindFirstChild("Left Arm")
	local rightArm = character:FindFirstChild("Right Arm")
	if leftArm or rightArm then
		appendCloneDefinition(definitions, leftArm, "FPV_LeftArm", false)
		appendCloneDefinition(definitions, rightArm, "FPV_RightArm", true)
		return definitions
	end

	return nil
end

local function findAttachmentByNames(parent, names)
	if not parent then
		return nil
	end
	for _, name in ipairs(names) do
		local attachment = parent:FindFirstChild(name)
		if attachment and attachment:IsA("Attachment") then
			return attachment
		end
	end
	return nil
end

local function ensureToolGrip(handPart)
	if not handPart then
		return nil
	end
	local grip = findAttachmentByNames(handPart, { "ToolGrip", "RightGripAttachment", "GripAttachment" })
	if grip then
		return grip
	end
	grip = Instance.new("Attachment")
	grip.Name = "ToolGrip"
	grip.CFrame = CFrame.new(0, 0, -0.2)
	grip.Parent = handPart
	return grip
end

local function ensureSpecialMesh(parent, meshName)
	if not parent then
		return nil
	end

	local existing = parent:FindFirstChild(meshName)
	if existing and existing:IsA("SpecialMesh") then
		existing.MeshType = Enum.MeshType.FileMesh
		existing.MeshId = tostring(HANDLE_CONFIG.meshId or "")
		existing.TextureId = tostring(HANDLE_CONFIG.textureId or "")
		existing.Scale = HANDLE_CONFIG.meshScale or Vector3.new(0.7, 0.7, 0.7)
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = meshName
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = tostring(HANDLE_CONFIG.meshId or "")
	mesh.TextureId = tostring(HANDLE_CONFIG.textureId or "")
	mesh.Scale = HANDLE_CONFIG.meshScale or Vector3.new(0.7, 0.7, 0.7)
	mesh.Parent = parent
	return mesh
end

local function createFpvFlashlightPart(name, size, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.Transparency = transparency or 0
	return part
end

local function createFpvFlashlightHandlePart(name)
	local size = HANDLE_CONFIG.size or Vector3.new(0.5, 0.5, 2)
	local color = HANDLE_CONFIG.color or Color3.fromRGB(44, 46, 50)
	local material = HANDLE_CONFIG.material or Enum.Material.SmoothPlastic
	local part = createFpvFlashlightPart(name, size, color, material, 0)
	ensureSpecialMesh(part, "Mesh")
	return part
end

local function ensureLocalFlashlightLight(parent)
	if not parent then
		return nil
	end

	local existing = parent:FindFirstChild("FPV_LocalSpotLight")
	if existing and existing:IsA("SpotLight") then
		fpvFlashlightLight = existing
		return existing
	end

	local spotlight = Instance.new("SpotLight")
	spotlight.Name = "FPV_LocalSpotLight"
	spotlight.Face = Enum.NormalId.Front
	spotlight.Brightness = LOCAL_LIGHT_OFF_BRIGHTNESS
	spotlight.Range = LOCAL_LIGHT_OFF_RANGE
	spotlight.Angle = LOCAL_LIGHT_OFF_ANGLE
	spotlight.Color = LOCAL_LIGHT_CONFIG.color or Color3.fromRGB(255, 244, 214)
	spotlight.Enabled = false
	spotlight.Shadows = false
	spotlight.Parent = parent
	fpvFlashlightLight = spotlight
	return spotlight
end

local function ensureFpvFlashlight(model, handPart)
	if not model or not handPart then
		return nil
	end

	local existing = model:FindFirstChild(FPV_FLASHLIGHT_MODEL_NAME)
	if existing and existing:IsA("Model") then
		fpvFlashlightModel = existing
		fpvFlashlightHandle = existing:FindFirstChild("Handle")
		fpvFlashlightLens = existing:FindFirstChild("Lens")
		if fpvFlashlightLens then
			ensureLocalFlashlightLight(fpvFlashlightLens)
		end
		return existing
	end

	local grip = ensureToolGrip(handPart)
	if not grip then
		return nil
	end

	local flashlightModel = Instance.new("Model")
	flashlightModel.Name = FPV_FLASHLIGHT_MODEL_NAME
	flashlightModel.Parent = model

	local handle = createFpvFlashlightHandlePart("Handle")
	handle.CFrame = grip.WorldCFrame * (VIEWMODEL_CONFIG.flashlightMountCFrame or CFrame.new(0.12, -0.39, -0.04))
	handle.Parent = flashlightModel

	local lens = createFpvFlashlightPart(
		"Lens",
		LENS_CONFIG.size or Vector3.new(0.2, 0.2, 0.05),
		LENS_CONFIG.offColor or Color3.fromRGB(120, 132, 148),
		Enum.Material.SmoothPlastic,
		LENS_CONFIG.offTransparency or 0.34
	)
	lens.CFrame = handle.CFrame * (HANDLE_CONFIG.lensOffset or CFrame.new(0, 0, -0.96))
	lens.Parent = flashlightModel
	ensureLocalFlashlightLight(lens)

	flashlightModel.PrimaryPart = handle
	fpvFlashlightModel = flashlightModel
	fpvFlashlightHandle = handle
	fpvFlashlightLens = lens
	return flashlightModel
end

local function updateFpvFlashlightVisual(deltaTime)
	if not fpvFlashlightLens or not fpvFlashlightLens:IsA("BasePart") then
		return
	end

	local enabled = player:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true
	local ownsUvFlashlight = player:GetAttribute(UV_FLASHLIGHT_OWNED_ATTR) == true
	local targetAlpha = enabled and 1 or 0
	local fadeSpeed = enabled and LOCAL_LIGHT_FADE_IN_SPEED or LOCAL_LIGHT_FADE_OUT_SPEED
	local stepAlpha = math.clamp((tonumber(deltaTime) or (1 / 60)) * fadeSpeed, 0, 1)
	fpvFlashlightVisualAlpha = fpvFlashlightVisualAlpha + ((targetAlpha - fpvFlashlightVisualAlpha) * stepAlpha)
	if math.abs(targetAlpha - fpvFlashlightVisualAlpha) <= 0.01 then
		fpvFlashlightVisualAlpha = targetAlpha
	end

	local onColor = ownsUvFlashlight and UV_FLASHLIGHT_ON_COLOR or (LENS_CONFIG.onColor or Color3.fromRGB(255, 232, 186))
	local offColor = ownsUvFlashlight and UV_FLASHLIGHT_OFF_COLOR or (LENS_CONFIG.offColor or Color3.fromRGB(120, 132, 148))
	local onTransparency = LENS_CONFIG.onTransparency or 0.04
	local offTransparency = LENS_CONFIG.offTransparency or 0.36
	fpvFlashlightLens.Color = offColor:Lerp(onColor, fpvFlashlightVisualAlpha)
	fpvFlashlightLens.Transparency = lerpNumber(offTransparency, onTransparency, fpvFlashlightVisualAlpha)
	if fpvFlashlightLight then
		fpvFlashlightLight.Color = ownsUvFlashlight and UV_FLASHLIGHT_LIGHT_COLOR or LOCAL_LIGHT_DEFAULT_COLOR
		fpvFlashlightLight.Brightness = lerpNumber(LOCAL_LIGHT_OFF_BRIGHTNESS, LOCAL_LIGHT_ON_BRIGHTNESS, fpvFlashlightVisualAlpha)
		fpvFlashlightLight.Range = lerpNumber(LOCAL_LIGHT_OFF_RANGE, LOCAL_LIGHT_ON_RANGE, fpvFlashlightVisualAlpha)
		fpvFlashlightLight.Angle = lerpNumber(LOCAL_LIGHT_OFF_ANGLE, LOCAL_LIGHT_ON_ANGLE, fpvFlashlightVisualAlpha)
		fpvFlashlightLight.Enabled = fpvFlashlightVisualAlpha > 0.02
	end
	player:SetAttribute(FLASHLIGHT_VISUAL_ALPHA_ATTR, fpvFlashlightVisualAlpha)
	player:SetAttribute(FLASHLIGHT_LIGHT_ENABLED_ATTR, fpvFlashlightVisualAlpha > 0.02)
end

local function sanitizeFpvClonePart(clonePart, sourcePart, cloneName)
	if not (clonePart and clonePart:IsA("BasePart")) then
		return
	end

	-- Avoid linking cloned FPV parts back to live character joints/constraints.
	-- Cloned Motor6D/Weld/Constraint instances can still reference original rig parts
	-- and pull the real character when camera arms are pivoted.
	for _, descendant in ipairs(clonePart:GetDescendants()) do
		if descendant:IsA("JointInstance") or descendant:IsA("Constraint") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant:Destroy()
		elseif descendant:IsA("Humanoid") then
			descendant:Destroy()
		elseif descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			descendant:Destroy()
		elseif descendant:IsA("Highlight") or descendant:IsA("Beam") or descendant:IsA("Trail") or descendant:IsA("ParticleEmitter") then
			descendant:Destroy()
		end
	end

	local isHandPart = string.find(tostring(cloneName or ""), "Hand") ~= nil
	local brightnessScale = isHandPart and VIEWMODEL_HAND_BRIGHTNESS_SCALE or VIEWMODEL_ARM_BRIGHTNESS_SCALE

	clonePart.Material = VIEWMODEL_ARM_MATERIAL
	clonePart.Color = buildArmColor(sourcePart and sourcePart.Color or clonePart.Color, brightnessScale)
	clonePart.Transparency = 0
	clonePart.Reflectance = 0
	clonePart.CastShadow = false

	for _, child in ipairs(clonePart:GetChildren()) do
		if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
			child:Destroy()
		end
	end
end

local function getSegmentLayout(partName)
	local layouts = VIEWMODEL_CONFIG.segmentLayouts
	if type(layouts) == "table" then
		return layouts[partName]
	end
	return nil
end

local function shouldHideSegmentInHandsOnly(partName)
	if not VIEWMODEL_HANDS_ONLY then
		return false
	end
	return partName == "FPV_LeftUpperArm"
		or partName == "FPV_LeftLowerArm"
		or partName == "FPV_RightUpperArm"
		or partName == "FPV_RightLowerArm"
end

local function applyViewmodelSegmentLayout(model, viewRoot)
	if not (model and viewRoot) then
		return
	end

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") and child ~= viewRoot then
			local layout = getSegmentLayout(child.Name)
			if layout then
				child.Size = child.Size * FPV_PART_SCALE
				child.CFrame = viewRoot.CFrame
					* CFrame.new(layout.position)
					* CFrame.Angles(
						math.rad(layout.rotation.X),
						math.rad(layout.rotation.Y),
						math.rad(layout.rotation.Z)
					)
				if shouldHideSegmentInHandsOnly(child.Name) then
					child.Transparency = 1
				else
					child.Transparency = 0
				end
			end
		end
	end
end

local function ensureFpvArms(character)
	if not character then
		clearFpvArms()
		return false
	end

	if camera ~= workspace.CurrentCamera then
		camera = workspace.CurrentCamera or camera
	end
	if not camera then
		return false
	end

	if fpvArmsModel and fpvArmsModel.Parent ~= camera then
		fpvArmsModel.Parent = camera
	end
	if fpvArmsModel and fpvArmsModel.PrimaryPart then
		return true
	end

	clearFpvArms()
	local armDefinitions = collectArmParts(character)
	if not armDefinitions or #armDefinitions == 0 then
		return false
	end
	local existing = camera:FindFirstChild(FPV_ARMS_MODEL_NAME)
	if existing and existing:IsA("Model") then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = FPV_ARMS_MODEL_NAME
	model.Parent = camera

	local handClone = nil
	local leftHandClone = nil
	for _, def in ipairs(armDefinitions) do
		local sourcePart = def.source
		if sourcePart and sourcePart:IsA("BasePart") then
			local clone = sourcePart:Clone()
			sanitizeFpvClonePart(clone, sourcePart, def.cloneName)
			clone.Name = def.cloneName
			clone.Anchored = true
			clone.CanCollide = false
			clone.CanTouch = false
			clone.CanQuery = false
			clone.Massless = true
			clone.CastShadow = false
			clone.Parent = model

			table.insert(fpvArmsSourceParts, {
				part = sourcePart,
				originalTransparency = sourcePart.LocalTransparencyModifier,
			})
			sourcePart.LocalTransparencyModifier = 1

			if def.isPrimary == true then
				handClone = clone
			elseif string.find(def.cloneName, "LeftHand") or def.cloneName == "FPV_LeftArm" then
				leftHandClone = clone
			end
		end
	end

	if not handClone then
		handClone = model:FindFirstChildWhichIsA("BasePart")
	end
	if not handClone then
		model:Destroy()
		return false
	end

	local viewRoot = model:FindFirstChild(FPV_VIEW_ROOT_NAME)
	if viewRoot and not viewRoot:IsA("BasePart") then
		viewRoot:Destroy()
		viewRoot = nil
	end
	if not viewRoot then
		viewRoot = Instance.new("Part")
		viewRoot.Name = FPV_VIEW_ROOT_NAME
		viewRoot.Size = Vector3.new(0.2, 0.2, 0.2)
		viewRoot.Transparency = 1
		viewRoot.Anchored = true
		viewRoot.CanCollide = false
		viewRoot.CanTouch = false
		viewRoot.CanQuery = false
		viewRoot.Massless = true
		viewRoot.CastShadow = false
		viewRoot.Parent = model
	end

	if leftHandClone and leftHandClone:IsA("BasePart") then
		local midpoint = handClone.Position:Lerp(leftHandClone.Position, 0.5)
		viewRoot.CFrame = CFrame.new(midpoint, midpoint + camera.CFrame.LookVector)
	else
		viewRoot.CFrame = handClone.CFrame
	end
	applyViewmodelSegmentLayout(model, viewRoot)

	ensureToolGrip(handClone)
	ensureFpvFlashlight(model, handClone)
	updateFpvFlashlightVisual()
	model.PrimaryPart = viewRoot
	fpvArmsModel = model
	return true
end

-- Detect map and set camera mode
local function resolveCamera()
	local cam = workspace.CurrentCamera
	if cam then
		return cam
	end
	local resolved = nil
	local conn
	conn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if workspace.CurrentCamera then
			resolved = workspace.CurrentCamera
		end
	end)
	while not resolved do
		task.wait()
	end
	if conn then
		conn:Disconnect()
	end
	return resolved
end

camera = resolveCamera()

local function logCameraMode(modeLabel, message)
	if lastLoggedCameraMode == modeLabel then
		return
	end
	lastLoggedCameraMode = modeLabel
	print(message)
end

local function setFpvLocked(enabled)
	FPV_LOCKED = enabled == true
	if FPV_LOCKED then
		fpvCursorUnlocked = false
		local character = player.Character
		if not character then
			applyFpvMouseMode()
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local head = character:FindFirstChild("Head")
		if not humanoid or not head then
			applyFpvMouseMode()
			return
		end

		player.CameraMode = Enum.CameraMode.LockFirstPerson
		camera.CameraType = Enum.CameraType.Custom
		ensureCameraAuthority(humanoid)
		_fpvJustActivated = true
		lastArmCamCF = nil
		applyFpvMouseMode()
		logCameraMode("FPV", "[CameraController] FPV LOCKED (Match)")
	else
		fpvCursorUnlocked = false
		player.CameraMode = Enum.CameraMode.Classic
		_fpvJustActivated = false
		lastArmCamCF = nil
		clearFpvArms()
		applyFpvMouseMode()
		logCameraMode("TPV", "[CameraController] TPV ALLOWED (Lobby)")
	end
end

local matchAttributeConnection = nil
local function bindMatchAttribute()
	if matchAttributeConnection then
		return
	end
	local inMatch = player:GetAttribute("InMatch") == true
	if player.Character then
		setFpvLocked(inMatch)
	end
	matchAttributeConnection = player:GetAttributeChangedSignal("InMatch"):Connect(function()
		local shouldLock = player:GetAttribute("InMatch") == true
		if shouldLock then
			task.wait(0.5)
			if player:GetAttribute("InMatch") ~= true then
				shouldLock = false
			end
		end
		if player.Character then
			setFpvLocked(shouldLock)
		else
			FPV_LOCKED = shouldLock
		end
	end)
end

bindMatchAttribute()

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	character:WaitForChild("Head")
	character:WaitForChild("HumanoidRootPart")
	task.wait(0.2)

	if camera ~= workspace.CurrentCamera then
		camera = workspace.CurrentCamera or camera
	end
	ensureCameraAuthority(humanoid)
	humanoid.CameraOffset = Vector3.zero

	lastArmCamCF = nil
	clearFpvArms()
	setFpvLocked(player:GetAttribute("InMatch") == true)
	bindMatchAttribute()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end
	if (input.KeyCode == CURSOR_TOGGLE_KEY or input.KeyCode == CURSOR_TOGGLE_FALLBACK_KEY)
		and FPV_LOCKED
		and UserInputService.KeyboardEnabled
	then
		setCursorUnlocked(not fpvCursorUnlocked)
	end
end)

player:GetAttributeChangedSignal(CURSOR_UNLOCK_REQUEST_ATTR):Connect(function()
	local requested = player:GetAttribute(CURSOR_UNLOCK_REQUEST_ATTR)
	if type(requested) == "boolean" and FPV_LOCKED then
		setCursorUnlocked(requested)
	end
end)

-- Head bobbing effect
RunService:BindToRenderStep("HeadBob", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	local character = player.Character
	if not character then
		clearFpvArms()
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	if camera ~= workspace.CurrentCamera then
		camera = workspace.CurrentCamera or camera
	end

	local shouldLockFromState = player:GetAttribute("InMatch") == true
	if shouldLockFromState ~= FPV_LOCKED then
		setFpvLocked(shouldLockFromState)
	elseif shouldLockFromState
		and (not fpvCursorUnlocked)
		and (player.CameraMode ~= Enum.CameraMode.LockFirstPerson
			or UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter)
	then
		setFpvLocked(true)
	elseif shouldLockFromState
		and fpvCursorUnlocked
		and (player.CameraMode ~= Enum.CameraMode.Classic
			or UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
			or UserInputService.MouseIconEnabled ~= true)
	then
		applyFpvMouseMode()
	elseif (not shouldLockFromState)
		and (player.CameraMode ~= Enum.CameraMode.Classic
			or UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
			or UserInputService.MouseIconEnabled ~= true)
	then
		setFpvLocked(false)
	end

	local cameraBobTarget = Vector3.zero
	local headBobProbeActive = player:GetAttribute(HEAD_BOB_PROBE_ATTR) == true
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local planarVelocity = Vector3.zero
	if rootPart and rootPart:IsA("BasePart") then
		planarVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z)
	end
	local speedAlpha = math.clamp(planarVelocity.Magnitude / math.max(1, MOTION_WALK_SPEED_REFERENCE), 0, 1.4)
	local bobIntensity = fpvCursorUnlocked and MOTION_CURSOR_UNLOCK_BOB_SCALE or lerpNumber(0.42, 1, speedAlpha)
	local shouldApplyHeadBob = FPV_LOCKED and (humanoid.MoveDirection.Magnitude > 0 or headBobProbeActive)
	if shouldApplyHeadBob then
		local time = tick()
		local dynamicFrequency = bobFrequency * lerpNumber(0.85, 1.24, speedAlpha)
		local verticalBob = math.sin(time * dynamicFrequency * 2 * math.pi) * bobAmplitude * bobIntensity
		local horizontalSway = math.sin(time * dynamicFrequency * math.pi) * swayAmplitude * bobIntensity

		bobOffset = Vector3.new(horizontalSway, verticalBob, 0)
		cameraBobTarget = Vector3.new(horizontalSway * 0.22, verticalBob * 0.3, 0) * bobIntensity
	elseif FPV_LOCKED and not fpvCursorUnlocked then
		local time = tick()
		local idleBreath = math.sin(time * MOTION_IDLE_BREATH_SPEED * 2 * math.pi) * MOTION_IDLE_BREATH_AMPLITUDE
		bobOffset = bobOffset:Lerp(Vector3.new(0, idleBreath, 0), math.clamp(deltaTime * 4, 0, 1))
		cameraBobTarget = Vector3.new(0, idleBreath * 0.2, 0)
	else
		bobOffset = bobOffset:Lerp(Vector3.new(0, 0, 0), deltaTime * 5)
	end
	if FPV_LOCKED then
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(cameraBobTarget, math.clamp(deltaTime * 10, 0, 1))
	elseif humanoid.CameraOffset.Magnitude > 0.0005 then
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.zero, math.clamp(deltaTime * 10, 0, 1))
	else
		humanoid.CameraOffset = Vector3.zero
	end
	player:SetAttribute(HEAD_BOB_OFFSET_ATTR, humanoid.CameraOffset)

	if FPV_LOCKED and camera and ensureFpvArms(character) and fpvArmsModel and fpvArmsModel.PrimaryPart then
		updateFpvFlashlightVisual(deltaTime)
		local currentCamCF = camera.CFrame
		if _fpvJustActivated then
			_fpvJustActivated = false
			lastArmCamCF = currentCamCF
			return
		end
		if not lastArmCamCF then
			lastArmCamCF = currentCamCF
		end
		lastArmCamCF = lastArmCamCF:Lerp(currentCamCF, MOTION_CAMERA_LAG_ALPHA)

		local look = currentCamCF.LookVector
		local pitchOffset = look.Y * 0.2
		local t = tick()
		local swayX = math.sin(t * 1.5) * 0.02
		local swayY = math.cos(t * 2) * 0.015
		local breathSway = CFrame.new(0, math.sin(t * MOTION_IDLE_BREATH_SPEED * 2 * math.pi) * (MOTION_IDLE_BREATH_AMPLITUDE * 0.65), 0)
		local lookSway = CFrame.new(-look.X * MOTION_LOOK_SWAY_X, -look.Y * MOTION_LOOK_SWAY_Y, 0)
		local carryOffset = fpvFlashlightVisualAlpha > 0.02 and MOTION_FLASHLIGHT_CARRY_OFFSET * fpvFlashlightVisualAlpha or Vector3.zero
		local carryCF = CFrame.new(carryOffset) * CFrame.Angles(0, 0, math.rad(MOTION_FLASHLIGHT_CARRY_ROLL * fpvFlashlightVisualAlpha))
		local swayOffset = CFrame.new(swayX, swayY, 0) * breathSway * lookSway
		local bobCF = CFrame.new(bobOffset.X * 0.6, bobOffset.Y * 0.6, 0)
		local pitchCF = CFrame.new(0, pitchOffset, 0)
		local moveSwayCF = CFrame.new(planarVelocity.X * 0.0012 * MOTION_MOVE_SWAY_SCALE, 0, -planarVelocity.Magnitude * 0.0006 * MOTION_MOVE_SWAY_SCALE)
		player:SetAttribute(FLASHLIGHT_AIM_OFFSET_ATTR, Vector3.new(-look.X * MOTION_LOOK_SWAY_X, -look.Y * MOTION_LOOK_SWAY_Y, 0))
		fpvArmsModel:PivotTo(lastArmCamCF * FPV_BASE_OFFSET * carryCF * pitchCF * bobCF * moveSwayCF * swayOffset)
	else
		_fpvJustActivated = false
		lastArmCamCF = nil
		player:SetAttribute(FLASHLIGHT_AIM_OFFSET_ATTR, Vector3.zero)
		if not FPV_LOCKED then
			clearFpvArms()
		end
	end
end)

print("[Phase7.1] Camera Controller initialized")
print("  FPV Lock: Active in investigation maps")
print("  Head Bobbing: Enabled")
