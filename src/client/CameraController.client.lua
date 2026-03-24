--[[
    CAMERA CONTROLLER
    FPV lock in investigation maps, TPV allowed in lobby
    Head bobbing for immersive walking feel

    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.5
]]

local Players = game:GetService("Players")
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
local FPV_BASE_OFFSET = CFrame.new(0.6, -0.9, -1.2) * CFrame.Angles(math.rad(-10), math.rad(5), math.rad(2))
local fpvArmsModel = nil
local fpvArmsSourceParts = {}
local lastArmCamCF = nil

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

	for _, info in ipairs(fpvArmsSourceParts) do
		local sourcePart = info.part
		if sourcePart and sourcePart.Parent and sourcePart:IsA("BasePart") then
			sourcePart.LocalTransparencyModifier = info.originalTransparency or 0
		end
	end
	table.clear(fpvArmsSourceParts)
end

local function collectRightArmParts(character)
	if not character then
		return nil
	end

	local rightUpperArm = character:FindFirstChild("RightUpperArm")
	local rightLowerArm = character:FindFirstChild("RightLowerArm")
	local rightHand = character:FindFirstChild("RightHand")
	if rightUpperArm or rightLowerArm or rightHand then
		local parts = {}
		if rightUpperArm and rightUpperArm:IsA("BasePart") then
			table.insert(parts, { source = rightUpperArm, cloneName = "FPV_UpperArm" })
		end
		if rightLowerArm and rightLowerArm:IsA("BasePart") then
			table.insert(parts, { source = rightLowerArm, cloneName = "FPV_LowerArm" })
		end
		if rightHand and rightHand:IsA("BasePart") then
			table.insert(parts, { source = rightHand, cloneName = "FPV_Hand" })
		end
		return parts
	end

	local rightArm = character:FindFirstChild("Right Arm")
	if rightArm and rightArm:IsA("BasePart") then
		return {
			{ source = rightArm, cloneName = "FPV_Hand" },
		}
	end

	return nil
end

local function ensureToolGrip(handPart)
	if not handPart then
		return
	end
	local grip = handPart:FindFirstChild("ToolGrip")
	if grip and grip:IsA("Attachment") then
		return
	end
	grip = Instance.new("Attachment")
	grip.Name = "ToolGrip"
	grip.CFrame = CFrame.new(0, 0, -0.2)
	grip.Parent = handPart
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
	local armDefinitions = collectRightArmParts(character)
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
	for _, def in ipairs(armDefinitions) do
		local sourcePart = def.source
		if sourcePart and sourcePart:IsA("BasePart") then
			local clone = sourcePart:Clone()
			clone.Name = def.cloneName
			clone.Anchored = true
			clone.CanCollide = false
			clone.Massless = true
			clone.CastShadow = false
			clone.Parent = model

			table.insert(fpvArmsSourceParts, {
				part = sourcePart,
				originalTransparency = sourcePart.LocalTransparencyModifier,
			})
			sourcePart.LocalTransparencyModifier = 1

			if def.cloneName == "FPV_Hand" then
				handClone = clone
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

	ensureToolGrip(handClone)
	model.PrimaryPart = handClone
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
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		print("[CameraController] FPV LOCKED (Match)")
	else
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
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
	FPV_LOCKED = inMatch
	if player.Character then
		setFpvLocked(inMatch)
	end
	matchAttributeConnection = player:GetAttributeChangedSignal("InMatch"):Connect(function()
		local shouldLock = player:GetAttribute("InMatch") == true
		FPV_LOCKED = shouldLock
		if player.Character then
			setFpvLocked(shouldLock)
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
	if FPV_LOCKED then
		ensureCameraAuthority(humanoid)
	end

	if camera ~= workspace.CurrentCamera then
		camera = workspace.CurrentCamera or camera
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
		local currentCamCF = camera.CFrame
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
		lastArmCamCF = nil
		if not FPV_LOCKED then
			clearFpvArms()
		end
	end
end)

print("[Phase7.1] Camera Controller initialized")
print("  FPV Lock: Active in investigation maps")
print("  Head Bobbing: Enabled")
