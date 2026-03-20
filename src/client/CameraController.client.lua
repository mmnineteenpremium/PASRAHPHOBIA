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
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		camera.CameraType = Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		print("[CameraController] FPV LOCKED (Match)")
	else
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		print("[CameraController] TPV ALLOWED (Lobby)")
	end
end

local matchAttributeConnection = nil
local function bindMatchAttribute()
	if matchAttributeConnection then
		return
	end
	local inMatch = player:GetAttribute("InMatch") == true
	setFpvLocked(inMatch)
	matchAttributeConnection = player:GetAttributeChangedSignal("InMatch"):Connect(function()
		setFpvLocked(player:GetAttribute("InMatch") == true)
	end)
end

bindMatchAttribute()

player.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
	bindMatchAttribute()
end)

-- Head bobbing effect
RunService:BindToRenderStep("HeadBob", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

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

    -- Apply offset to camera
    if FPV_LOCKED and camera then
        camera.CFrame = camera.CFrame * CFrame.new(bobOffset)
    end
end)

print("[Phase7.1] Camera Controller initialized")
print("  FPV Lock: Active in investigation maps")
print("  Head Bobbing: Enabled")
