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
local FPV_BASE_OFFSET = VIEWMODEL_CONFIG.baseOffset or (CFrame.new(0, -1.36, -1.54) * CFrame.Angles(math.rad(-12), 0, 0))
local FPV_PART_SCALE = tonumber(VIEWMODEL_CONFIG.partScale) or 0.86
local fpvArmsModel = nil
local fpvFlashlightModel = nil
local fpvFlashlightHandle = nil
local fpvFlashlightLens = nil
local fpvFlashlightLight = nil
local fpvArmsSourceParts = {}
local lastArmCamCF = nil
local _fpvJustActivated = false

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
	spotlight.Brightness = tonumber(LOCAL_LIGHT_CONFIG.brightness) or 2.6
	spotlight.Range = tonumber(LOCAL_LIGHT_CONFIG.range) or 18
	spotlight.Angle = tonumber(LOCAL_LIGHT_CONFIG.angle) or 38
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

local function updateFpvFlashlightVisual()
	if not fpvFlashlightLens or not fpvFlashlightLens:IsA("BasePart") then
		return
	end

	local enabled = player:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true
	fpvFlashlightLens.Color = enabled and (LENS_CONFIG.onColor or Color3.fromRGB(255, 232, 186)) or (LENS_CONFIG.offColor or Color3.fromRGB(120, 132, 148))
	fpvFlashlightLens.Transparency = enabled and (LENS_CONFIG.onTransparency or 0.04) or (LENS_CONFIG.offTransparency or 0.36)
	if fpvFlashlightLight then
		fpvFlashlightLight.Enabled = enabled
	end
end

local function sanitizeFpvClonePart(clonePart)
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

	clonePart.Material = Enum.Material.Plastic
	clonePart.Reflectance = 0
	clonePart.CastShadow = false

	for _, child in ipairs(clonePart:GetChildren()) do
		if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
			child:Destroy()
		end
	end
	if clonePart:IsA("MeshPart") then
		clonePart.TextureID = clonePart.TextureID
	end
end

local function getSegmentLayout(partName)
	local layouts = VIEWMODEL_CONFIG.segmentLayouts
	if type(layouts) == "table" then
		return layouts[partName]
	end
	return nil
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
			sanitizeFpvClonePart(clone)
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

local function setFpvLocked(enabled)
	FPV_LOCKED = enabled == true
	if FPV_LOCKED then
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local head = character:FindFirstChild("Head")
		if not humanoid or not head then
			return
		end

		player.CameraMode = Enum.CameraMode.LockFirstPerson
		camera.CameraType = Enum.CameraType.Custom
		ensureCameraAuthority(humanoid)
		_fpvJustActivated = true
		lastArmCamCF = nil
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		print("[CameraController] FPV LOCKED (Match)")
	else
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		_fpvJustActivated = false
		lastArmCamCF = nil
		clearFpvArms()
		print("[CameraController] TPV ALLOWED (Lobby)")
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

	lastArmCamCF = nil
	clearFpvArms()
	setFpvLocked(player:GetAttribute("InMatch") == true)
	bindMatchAttribute()
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
	elseif shouldLockFromState and player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
		setFpvLocked(true)
	elseif (not shouldLockFromState) and player.CameraMode ~= Enum.CameraMode.Classic then
		setFpvLocked(false)
	end

	if humanoid.MoveDirection.Magnitude > 0 and FPV_LOCKED then
		-- Walking - apply bob
		local time = tick()
		local verticalBob = math.sin(time * bobFrequency * 2 * math.pi) * bobAmplitude
		local horizontalSway = math.sin(time * bobFrequency * math.pi) * swayAmplitude

		bobOffset = Vector3.new(horizontalSway, verticalBob, 0)
	else
		-- Standing still or not in FPV - reduce bob
		bobOffset = bobOffset:Lerp(Vector3.new(0, 0, 0), deltaTime * 5)
	end

	if FPV_LOCKED and camera and ensureFpvArms(character) and fpvArmsModel and fpvArmsModel.PrimaryPart then
		updateFpvFlashlightVisual()
		local currentCamCF = camera.CFrame
		if _fpvJustActivated then
			_fpvJustActivated = false
			lastArmCamCF = currentCamCF
			return
		end
		if not lastArmCamCF then
			lastArmCamCF = currentCamCF
		end
		lastArmCamCF = lastArmCamCF:Lerp(currentCamCF, 0.15)

		local look = currentCamCF.LookVector
		local pitchOffset = look.Y * 0.2
		local t = tick()
		local swayX = math.sin(t * 1.5) * 0.02
		local swayY = math.cos(t * 2) * 0.015
		local swayOffset = CFrame.new(swayX, swayY, 0)
		local bobCF = CFrame.new(bobOffset.X * 0.6, bobOffset.Y * 0.6, 0)
		local pitchCF = CFrame.new(0, pitchOffset, 0)
		fpvArmsModel:PivotTo(lastArmCamCF * FPV_BASE_OFFSET * pitchCF * bobCF * swayOffset)
	else
		_fpvJustActivated = false
		lastArmCamCF = nil
		if not FPV_LOCKED then
			clearFpvArms()
		end
	end
end)

print("[Phase7.1] Camera Controller initialized")
print("  FPV Lock: Active in investigation maps")
print("  Head Bobbing: Enabled")
