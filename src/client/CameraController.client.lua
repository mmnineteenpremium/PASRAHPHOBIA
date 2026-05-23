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
local CameraResolver = require(script.Parent:WaitForChild("CameraResolver"))
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
local FLASHLIGHT_ATTRIBUTE = "FlashlightEnabled"
local CURSOR_TOGGLE_KEY = Enum.KeyCode.LeftAlt
local CURSOR_TOGGLE_FALLBACK_KEY = Enum.KeyCode.Backquote
local CURSOR_UNLOCK_REQUEST_ATTR = "PasrahCursorUnlockRequested"
local CURSOR_MODE_ATTR = "PasrahCursorMode"
local RESULTS_SURFACE_VISIBLE_ATTR = "PasrahResultsSurfaceVisible"
local HEAD_BOB_PROBE_ATTR = "PasrahHeadBobProbeActive"
local HEAD_BOB_OFFSET_ATTR = "PasrahHeadBobOffset"
local FLASHLIGHT_AIM_OFFSET_ATTR = "PasrahFlashlightAimOffset"
local CURSOR_TOGGLE_GUI_NAME = "FPVCursorToggleUI"
local CURSOR_TOGGLE_BUTTON_NAME = "CursorToggleButton"
local CURSOR_RUNTIME_STAMP_INTERVAL = 0.12
local FPV_RUNTIME_STAMP_INTERVAL = 0.12
local MOTION_RUNTIME_STAMP_INTERVAL = 0.08
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
local MOTION_WALK_SPEED_REFERENCE = tonumber(MOTION_CONFIG.walkSpeedReference) or 14
local MOTION_CURSOR_UNLOCK_BOB_SCALE = tonumber(MOTION_CONFIG.cursorUnlockedBobScale) or 0.18
local MOTION_IDLE_BREATH_AMPLITUDE = tonumber(MOTION_CONFIG.idleBreathAmplitude) or 0.018
local MOTION_IDLE_BREATH_SPEED = tonumber(MOTION_CONFIG.idleBreathSpeed) or 1.35
local MOTION_CAMERA_LAG_ALPHA = tonumber(MOTION_CONFIG.cameraLagAlpha) or 0.15
local MOTION_LOOK_SWAY_X = tonumber(MOTION_CONFIG.lookSwayX) or 0.035
local MOTION_LOOK_SWAY_Y = tonumber(MOTION_CONFIG.lookSwayY) or 0.024
local MOTION_MOVE_SWAY_SCALE = tonumber(MOTION_CONFIG.moveSwayScale) or 0.5
local MOTION_STATIC_HOLD_TOOLS = MOTION_CONFIG.staticHoldTools == true
local MOTION_FLASHLIGHT_CARRY_OFFSET = MOTION_CONFIG.flashlightCarryOffset or Vector3.new(0.04, -0.015, -0.045)
local MOTION_FLASHLIGHT_CARRY_ROLL = tonumber(MOTION_CONFIG.flashlightCarryRoll) or -2.5
local RESULTS_TPV_MIN_ZOOM = 7
local RESULTS_TPV_MAX_ZOOM = 14
local fpvArmsModel = nil
local fpvArmsSourceParts = {}
local lastArmCamCF = nil
local _fpvJustActivated = false
local fpvCursorUnlocked = false
local fpvCursorToggleGui = nil
local fpvCursorToggleButton = nil
local fpvCursorToggleConnection = nil
local fpvFlashlightCarryAlpha = 0
local lastLoggedCameraMode = nil
local windowFocused = true
local setCursorUnlocked
local lastCursorRuntimeStampAt = 0
local lastFpvRuntimeStampAt = 0
local lastAimOffsetRuntimeStampAt = 0
local lastHeadBobRuntimeStampAt = 0
local cursorToggleContractWarned = false

local function setAttributeIfChanged(instance, attributeName, value, numberEpsilon, vectorEpsilon)
	if not instance then
		return
	end
	local current = instance:GetAttribute(attributeName)
	if typeof(current) == "number" and typeof(value) == "number" and tonumber(numberEpsilon) then
		if math.abs(current - value) <= numberEpsilon then
			return
		end
	elseif typeof(current) == "Vector3" and typeof(value) == "Vector3" and tonumber(vectorEpsilon) then
		if (current - value).Magnitude <= vectorEpsilon then
			return
		end
	elseif current == value then
		return
	end
	instance:SetAttribute(attributeName, value)
end

local function stampCursorToggleRuntime(force)
	local now = os.clock()
	if force ~= true and (now - lastCursorRuntimeStampAt) < CURSOR_RUNTIME_STAMP_INTERVAL then
		return
	end
	lastCursorRuntimeStampAt = now

	if fpvCursorToggleGui then
		setAttributeIfChanged(fpvCursorToggleGui, "PasrahFlashlightOwner", "CameraController")
		setAttributeIfChanged(fpvCursorToggleGui, "PasrahFlashlightChannel", "CursorToggleUI")
		setAttributeIfChanged(fpvCursorToggleGui, "PasrahCursorMode", tostring(player:GetAttribute(CURSOR_MODE_ATTR) or ""))
		setAttributeIfChanged(fpvCursorToggleGui, "PasrahFpvLocked", FPV_LOCKED == true)
		setAttributeIfChanged(fpvCursorToggleGui, "PasrahCursorUnlocked", fpvCursorUnlocked == true)
	end
	if fpvCursorToggleButton then
		setAttributeIfChanged(fpvCursorToggleButton, "PasrahFlashlightOwner", "CameraController")
		setAttributeIfChanged(fpvCursorToggleButton, "PasrahFlashlightChannel", "CursorToggleButton")
		setAttributeIfChanged(fpvCursorToggleButton, "PasrahCursorMode", tostring(player:GetAttribute(CURSOR_MODE_ATTR) or ""))
		setAttributeIfChanged(fpvCursorToggleButton, "PasrahFpvLocked", FPV_LOCKED == true)
		setAttributeIfChanged(fpvCursorToggleButton, "PasrahCursorUnlocked", fpvCursorUnlocked == true)
		setAttributeIfChanged(fpvCursorToggleButton, "PasrahCursorToggleVisible", fpvCursorToggleButton.Visible == true)
	end
end

local function stampFpvRuntime(force)
	local now = os.clock()
	if force ~= true and (now - lastFpvRuntimeStampAt) < FPV_RUNTIME_STAMP_INTERVAL then
		return
	end
	lastFpvRuntimeStampAt = now

	local flashlightEnabled = player:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true
	if fpvArmsModel then
		setAttributeIfChanged(fpvArmsModel, "PasrahFlashlightOwner", "CameraController")
		setAttributeIfChanged(fpvArmsModel, "PasrahFlashlightChannel", "FPVArms")
		setAttributeIfChanged(fpvArmsModel, "PasrahFpvLocked", FPV_LOCKED == true)
		setAttributeIfChanged(fpvArmsModel, "PasrahCursorUnlocked", fpvCursorUnlocked == true)
		setAttributeIfChanged(fpvArmsModel, "PasrahFlashlightEnabled", flashlightEnabled)
	end
end

local function stampAimOffsetRuntime(value, force)
	local now = os.clock()
	if force ~= true and (now - lastAimOffsetRuntimeStampAt) < MOTION_RUNTIME_STAMP_INTERVAL then
		return
	end
	lastAimOffsetRuntimeStampAt = now
	setAttributeIfChanged(player, FLASHLIGHT_AIM_OFFSET_ATTR, value, nil, 0.008)
end

local function stampHeadBobRuntime(value, force)
	local now = os.clock()
	if force ~= true and (now - lastHeadBobRuntimeStampAt) < MOTION_RUNTIME_STAMP_INTERVAL then
		return
	end
	lastHeadBobRuntimeStampAt = now
	setAttributeIfChanged(player, HEAD_BOB_OFFSET_ATTR, value, nil, 0.006)
end

local function lerpNumber(a, b, alpha)
	return a + ((b - a) * math.clamp(alpha, 0, 1))
end

setAttributeIfChanged(player, CURSOR_MODE_ATTR, "Default")
setAttributeIfChanged(player, FLASHLIGHT_AIM_OFFSET_ATTR, Vector3.zero, nil, 0.001)

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

local function bindCursorToggleButton(button)
	if not button then
		return
	end
	if fpvCursorToggleButton == button and fpvCursorToggleConnection then
		return
	end
	if fpvCursorToggleConnection then
		fpvCursorToggleConnection:Disconnect()
		fpvCursorToggleConnection = nil
	end
	fpvCursorToggleConnection = button.MouseButton1Click:Connect(function()
		if setCursorUnlocked then
			setCursorUnlocked(not fpvCursorUnlocked)
		end
	end)
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
		bindCursorToggleButton(fpvCursorToggleButton)
		return fpvCursorToggleButton
	end

	local existingGui = playerGui:FindFirstChild(CURSOR_TOGGLE_GUI_NAME)
		or playerGui:WaitForChild(CURSOR_TOGGLE_GUI_NAME, 5)
	if not existingGui or not existingGui:IsA("ScreenGui") then
		if not cursorToggleContractWarned then
			cursorToggleContractWarned = true
			warn("[CameraController] Missing authored FPVCursorToggleUI ScreenGui; check StarterGui shell contract.")
		end
		return nil
	end

	local button = existingGui:FindFirstChild(CURSOR_TOGGLE_BUTTON_NAME)
	if not button or not button:IsA("TextButton") then
		if not cursorToggleContractWarned then
			cursorToggleContractWarned = true
			warn("[CameraController] Missing CursorToggleButton in authored FPVCursorToggleUI; preserve canonical widget names.")
		end
		return nil
	end

	fpvCursorToggleGui = existingGui
	fpvCursorToggleButton = button
	bindCursorToggleButton(button)
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
	stampCursorToggleRuntime(true)
end

local function applyFpvMouseMode()
	if FPV_LOCKED then
		if fpvCursorUnlocked then
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMinZoomDistance = UNLOCKED_CURSOR_FPV_ZOOM
			player.CameraMaxZoomDistance = UNLOCKED_CURSOR_FPV_ZOOM
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
			setAttributeIfChanged(player, CURSOR_MODE_ATTR, "UnlockedUI")
		else
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMinZoomDistance = DEFAULT_CAMERA_MIN_ZOOM
			player.CameraMaxZoomDistance = DEFAULT_CAMERA_MAX_ZOOM
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
			setAttributeIfChanged(player, CURSOR_MODE_ATTR, "LockedFPV")
		end
	else
		local resultsSurfaceVisible = player:GetAttribute(RESULTS_SURFACE_VISIBLE_ATTR) == true
		player.CameraMode = Enum.CameraMode.Classic
		if resultsSurfaceVisible then
			player.CameraMinZoomDistance = math.max(DEFAULT_CAMERA_MIN_ZOOM, RESULTS_TPV_MIN_ZOOM)
			player.CameraMaxZoomDistance = math.max(player.CameraMinZoomDistance, RESULTS_TPV_MAX_ZOOM)
		else
			player.CameraMinZoomDistance = DEFAULT_CAMERA_MIN_ZOOM
			player.CameraMaxZoomDistance = DEFAULT_CAMERA_MAX_ZOOM
		end
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		setAttributeIfChanged(player, CURSOR_MODE_ATTR, resultsSurfaceVisible and "ResultsTPV" or "Default")
	end
	setAttributeIfChanged(player, "PasrahCursorUnlocked", FPV_LOCKED and fpvCursorUnlocked or false)
	updateCursorToggleUi()
	stampCursorToggleRuntime(true)
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

local PREPARATION_CAMERA_TARGET_NAMES = {
	"PreparationEntrySign",
	"PreparationRoadsideSign",
	"PreparationSignalDisplay",
	"PreparationGuideStrip",
}

local function getActiveMatchMapModel()
	local matchId = tostring(player:GetAttribute("MatchId") or "")
	if matchId == "" then
		return nil
	end

	local activeMatches = workspace:FindFirstChild("ActiveMatches")
	if not activeMatches then
		return nil
	end

	local matchFolder = activeMatches:FindFirstChild("Match_" .. matchId)
	if not matchFolder then
		for _, child in ipairs(activeMatches:GetChildren()) do
			if child:IsA("Folder") and tostring(child:GetAttribute("MatchId") or "") == matchId then
				matchFolder = child
				break
			end
		end
	end
	if not matchFolder then
		return nil
	end

	for _, child in ipairs(matchFolder:GetChildren()) do
		if (child:IsA("Model") or child:IsA("Folder"))
			and not child.Name:match("^GhostPlaceholder_")
			and not child.Name:match("^Ghost_") then
			return child
		end
	end

	return nil
end

local function getInstanceWorldPosition(instance)
	if not instance then
		return nil
	end
	if instance:IsA("BasePart") then
		return instance.Position
	end
	if instance:IsA("Attachment") then
		return instance.WorldPosition
	end
	if instance:IsA("Model") then
		return instance:GetPivot().Position
	end
	return nil
end

local function resolvePreparationCameraLookVector(rootPart)
	if not rootPart then
		return nil
	end
	if tostring(player:GetAttribute("MatchLifecyclePhase") or "") ~= "PreparationPhase" then
		return nil
	end

	local mapModel = getActiveMatchMapModel()
	if not mapModel then
		return nil
	end

	for _, targetName in ipairs(PREPARATION_CAMERA_TARGET_NAMES) do
		local target = mapModel:FindFirstChild(targetName, true)
		local targetPosition = getInstanceWorldPosition(target)
		if typeof(targetPosition) == "Vector3" then
			local flatOffset = Vector3.new(
				targetPosition.X - rootPart.Position.X,
				0,
				targetPosition.Z - rootPart.Position.Z
			)
			if flatOffset.Magnitude > 1e-3 then
				return flatOffset.Unit
			end
		end
	end

	return nil
end

local function shouldRealignMatchCamera()
	if player:GetAttribute("InMatch") ~= true then
		return false
	end
	local lifecyclePhase = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	return lifecyclePhase == "PreparationPhase"
		or lifecyclePhase == "InvestigationPhase"
		or lifecyclePhase == "HuntPhase"
end

local function realignCameraToCharacter()
	local character = player.Character
	if not character then
		return
	end

	if camera ~= workspace.CurrentCamera then
		camera = workspace.CurrentCamera or camera
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not (camera and humanoid and rootPart) then
		return
	end

	ensureCameraAuthority(humanoid)

	local flatLook = resolvePreparationCameraLookVector(rootPart)
	if not flatLook then
		flatLook = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
	end
	if flatLook.Magnitude <= 1e-4 then
		return
	end
	flatLook = flatLook.Unit

	if player.CameraMode == Enum.CameraMode.LockFirstPerson and head then
		local eye = head.Position + Vector3.new(0, 0.18, 0)
		local targetCamera = CFrame.lookAt(eye, eye + flatLook, Vector3.yAxis)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = targetCamera
		task.spawn(function()
			for _ = 1, 2 do
				RunService.RenderStepped:Wait()
				if camera ~= workspace.CurrentCamera then
					camera = workspace.CurrentCamera or camera
				end
				if camera then
					camera.CameraType = Enum.CameraType.Scriptable
					camera.CFrame = targetCamera
				end
			end
			if camera then
				camera.CameraType = Enum.CameraType.Custom
				ensureCameraAuthority(humanoid)
			end
		end)
		return
	end

	local focus = rootPart.Position + Vector3.new(0, 2.25, 0)
	local cameraDistance = math.clamp((camera.CFrame.Position - camera.Focus.Position).Magnitude, 8, 14)
	local cameraHeight = math.clamp(cameraDistance * 0.32, 2.8, 5)
	local cameraPosition = focus - (flatLook * cameraDistance) + Vector3.new(0, cameraHeight, 0)
	local targetCamera = CFrame.lookAt(cameraPosition, focus, Vector3.yAxis)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = targetCamera
	task.spawn(function()
		for _ = 1, 3 do
			RunService.RenderStepped:Wait()
			if camera ~= workspace.CurrentCamera then
				camera = workspace.CurrentCamera or camera
			end
			if camera then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = targetCamera
			end
		end
		if camera then
			camera.CameraType = Enum.CameraType.Custom
			ensureCameraAuthority(humanoid)
		end
	end)
end

local matchCameraRealignToken = 0

local function scheduleMatchCameraRealign()
	if not shouldRealignMatchCamera() then
		return
	end
	matchCameraRealignToken += 1
	local token = matchCameraRealignToken

	task.spawn(function()
		local lifecyclePhase = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
		local delays = lifecyclePhase == "PreparationPhase"
			and { 0.05, 0.18, 0.42, 0.9, 1.6, 2.4, 3.2 }
			or { 0.05, 0.18, 0.42, 0.9 }
		for _, delaySeconds in ipairs(delays) do
			task.wait(delaySeconds)
			if token ~= matchCameraRealignToken then
				return
			end
			if not shouldRealignMatchCamera() then
				return
			end
			realignCameraToCharacter()
		end
	end)
end

local function clearFpvArms()
	if fpvArmsModel and fpvArmsModel.Parent then
		fpvArmsModel:Destroy()
	end
	fpvArmsModel = nil
	fpvFlashlightCarryAlpha = 0

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

	model.PrimaryPart = viewRoot
	fpvArmsModel = model
	stampFpvRuntime(true)
	return true
end

-- Detect map and set camera mode
camera = CameraResolver.ResolveOrFallback(5, camera)

local function logCameraMode(modeLabel, message)
	if lastLoggedCameraMode == modeLabel then
		return
	end
	lastLoggedCameraMode = modeLabel
	print(message)
end

local function setFpvLocked(enabled)
	local shouldLock = enabled == true
	local wasLocked = FPV_LOCKED
	FPV_LOCKED = shouldLock
	if FPV_LOCKED then
		if not wasLocked then
			fpvCursorUnlocked = false
		end
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
		if not wasLocked then
			_fpvJustActivated = true
			lastArmCamCF = nil
		end
		applyFpvMouseMode()
		logCameraMode("FPV", "[CameraController] FPV LOCKED (Match)")
	else
		fpvCursorUnlocked = false
		player.CameraMode = Enum.CameraMode.Classic
		_fpvJustActivated = false
		lastArmCamCF = nil
		clearFpvArms()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			ensureCameraAuthority(humanoid)
		end
		applyFpvMouseMode()
		logCameraMode("TPV", "[CameraController] TPV ALLOWED (Lobby)")
	end
end

local matchAttributeConnection = nil
local spectatorAttributeConnection = nil
local spectatorClientAttributeConnection = nil
local lifecyclePhaseConnection = nil
local resultsSurfaceConnection = nil

local function isResultsLifecyclePhase()
	local lifecyclePhase = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	local normalized = lifecyclePhase:gsub("[%s_%-]+", ""):lower()
	return normalized == "result"
		or normalized == "results"
		or normalized == "resultphase"
		or normalized == "resultsphase"
		or normalized == "end"
		or normalized == "endphase"
		or normalized == "endgame"
		or normalized == "endgamephase"
		or normalized == "matchended"
		or normalized == "matchcompleted"
end

local function shouldLockForMatchCamera()
	if player:GetAttribute("PasrahSpectatorActive") == true then
		return false
	end
	if player:GetAttribute("PasrahSpectatorClientActive") == true then
		return false
	end
	if player:GetAttribute(RESULTS_SURFACE_VISIBLE_ATTR) == true or isResultsLifecyclePhase() then
		return false
	end
	return player:GetAttribute("InMatch") == true
end

local function bindMatchAttribute()
	if matchAttributeConnection then
		return
	end
	local function syncMatchCameraLock()
		local shouldLock = shouldLockForMatchCamera()
		if shouldLock then
			task.wait(0.5)
			if shouldLockForMatchCamera() ~= true then
				shouldLock = false
			end
		end
		if player.Character then
			setFpvLocked(shouldLock)
		else
			FPV_LOCKED = shouldLock
		end
		if shouldLock then
			scheduleMatchCameraRealign()
		end
	end
	local inMatch = shouldLockForMatchCamera()
	if player.Character then
		setFpvLocked(inMatch)
	end
	matchAttributeConnection = player:GetAttributeChangedSignal("InMatch"):Connect(syncMatchCameraLock)
	spectatorAttributeConnection = player:GetAttributeChangedSignal("PasrahSpectatorActive"):Connect(syncMatchCameraLock)
	spectatorClientAttributeConnection = player:GetAttributeChangedSignal("PasrahSpectatorClientActive"):Connect(syncMatchCameraLock)
	resultsSurfaceConnection = player:GetAttributeChangedSignal(RESULTS_SURFACE_VISIBLE_ATTR):Connect(syncMatchCameraLock)
	if not lifecyclePhaseConnection then
		lifecyclePhaseConnection = player:GetAttributeChangedSignal("MatchLifecyclePhase"):Connect(function()
			syncMatchCameraLock()
			if shouldLockForMatchCamera() then
				scheduleMatchCameraRealign()
			end
		end)
	end
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
	setFpvLocked(shouldLockForMatchCamera())
	bindMatchAttribute()
	scheduleMatchCameraRealign()
end)

if UserInputService.WindowFocusReleased then
	UserInputService.WindowFocusReleased:Connect(function()
		windowFocused = false
	end)
end
if UserInputService.WindowFocused then
	UserInputService.WindowFocused:Connect(function()
		windowFocused = true
		if FPV_LOCKED then
			applyFpvMouseMode()
		end
	end)
end

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

	local shouldLockFromState = shouldLockForMatchCamera()
	if shouldLockFromState ~= FPV_LOCKED then
		setFpvLocked(shouldLockFromState)
	elseif shouldLockFromState
		and (not fpvCursorUnlocked)
		and windowFocused
		and (player.CameraMode ~= Enum.CameraMode.LockFirstPerson
			or UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter
			or UserInputService.MouseIconEnabled ~= false)
	then
		applyFpvMouseMode()
		ensureCameraAuthority(humanoid)
	elseif shouldLockFromState
		and fpvCursorUnlocked
		and (player.CameraMode ~= Enum.CameraMode.Classic
			or UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
			or UserInputService.MouseIconEnabled ~= true)
	then
		applyFpvMouseMode()
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
	stampHeadBobRuntime(humanoid.CameraOffset, false)

	if FPV_LOCKED and camera and ensureFpvArms(character) and fpvArmsModel and fpvArmsModel.PrimaryPart then
		local currentCamCF = camera.CFrame
		local staticViewmodel = MOTION_STATIC_HOLD_TOOLS
		if _fpvJustActivated then
			_fpvJustActivated = false
			lastArmCamCF = currentCamCF
			return
		end
		if not lastArmCamCF then
			lastArmCamCF = currentCamCF
		end
		if staticViewmodel then
			lastArmCamCF = currentCamCF
		else
			lastArmCamCF = lastArmCamCF:Lerp(currentCamCF, MOTION_CAMERA_LAG_ALPHA)
		end

		local look = currentCamCF.LookVector
		local pitchOffset = staticViewmodel and 0 or (look.Y * 0.2)
		local t = tick()
		local swayX = staticViewmodel and 0 or (math.sin(t * 1.5) * 0.02)
		local swayY = staticViewmodel and 0 or (math.cos(t * 2) * 0.015)
		local breathSway = staticViewmodel
			and CFrame.new()
			or CFrame.new(0, math.sin(t * MOTION_IDLE_BREATH_SPEED * 2 * math.pi) * (MOTION_IDLE_BREATH_AMPLITUDE * 0.65), 0)
		local lookSway = staticViewmodel
			and CFrame.new()
			or CFrame.new(-look.X * MOTION_LOOK_SWAY_X, -look.Y * MOTION_LOOK_SWAY_Y, 0)
		local flashlightTargetAlpha = player:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true and 1 or 0
		fpvFlashlightCarryAlpha = lerpNumber(fpvFlashlightCarryAlpha, flashlightTargetAlpha, math.clamp(deltaTime * 8, 0, 1))
		local carryOffset = fpvFlashlightCarryAlpha > 0.02 and MOTION_FLASHLIGHT_CARRY_OFFSET * fpvFlashlightCarryAlpha or Vector3.zero
		local carryCF = CFrame.new(carryOffset)
			* CFrame.Angles(0, 0, math.rad(MOTION_FLASHLIGHT_CARRY_ROLL * fpvFlashlightCarryAlpha))
		local swayOffset = CFrame.new(swayX, swayY, 0) * breathSway * lookSway
		local bobCF = staticViewmodel and CFrame.new() or CFrame.new(bobOffset.X * 0.6, bobOffset.Y * 0.6, 0)
		local pitchCF = CFrame.new(0, pitchOffset, 0)
		local moveSwayCF = staticViewmodel
			and CFrame.new()
			or CFrame.new(planarVelocity.X * 0.0012 * MOTION_MOVE_SWAY_SCALE, 0, -planarVelocity.Magnitude * 0.0006 * MOTION_MOVE_SWAY_SCALE)
		stampAimOffsetRuntime(
			staticViewmodel and Vector3.zero or Vector3.new(-look.X * MOTION_LOOK_SWAY_X, -look.Y * MOTION_LOOK_SWAY_Y, 0),
			false
		)
		setAttributeIfChanged(player, "PasrahFpvStaticHoldTools", MOTION_STATIC_HOLD_TOOLS)
		fpvArmsModel:PivotTo(lastArmCamCF * FPV_BASE_OFFSET * carryCF * pitchCF * bobCF * moveSwayCF * swayOffset)
	else
		_fpvJustActivated = false
		lastArmCamCF = nil
		stampAimOffsetRuntime(Vector3.zero, true)
		if not FPV_LOCKED then
			clearFpvArms()
		end
	end
end)

print("[Phase7.1] Camera Controller initialized")
print("  FPV Lock: Active in investigation maps")
print("  Head Bobbing: Enabled")
