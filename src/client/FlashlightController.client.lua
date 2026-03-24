--[[
    FLASHLIGHT CONTROLLER (SENTER)
    Server-driven aim:
    - Client sends camera look vector for pitch up/down.
    - Server orients head-locked flashlight for all players.
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local REMOTE_NAME = "FlashlightEvent"
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local flashlightRemote = remoteFolder:WaitForChild(REMOTE_NAME)

local AIM_SEND_RATE = 1 / 20

local flashlightOn = false
local lastAimSend = 0
local camera = workspace.CurrentCamera
local toggleGui = nil
local toggleButton = nil
local toggleFlashlight

local function makeButtonDraggable(button)
	if not button or button:GetAttribute("DragBound") == true then
		return
	end
	button:SetAttribute("DragBound", true)

	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function updateDrag(input)
		if not dragging or not dragStart or not startPos then
			return
		end
		local delta = input.Position - dragStart
		button.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = button.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)
end

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

local function updateToggleVisual()
	if not toggleButton then
		return
	end
	if flashlightOn then
		toggleButton.Text = "SENTER\nON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(196, 154, 64)
	else
		toggleButton.Text = "SENTER\nOFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(52, 62, 80)
	end
end

local function ensureToggleUI()
	local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("FlashlightToggleUI")
	if existing and existing:IsA("ScreenGui") then
		existing:Destroy()
	end

	toggleGui = Instance.new("ScreenGui")
	toggleGui.Name = "FlashlightToggleUI"
	toggleGui.ResetOnSpawn = false
	toggleGui.IgnoreGuiInset = false
	toggleGui.DisplayOrder = 250
	toggleGui.Parent = playerGui

	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.AnchorPoint = Vector2.new(1, 0.5)
	toggleButton.Position = UDim2.new(1, -18, 0.62, 0)
	toggleButton.Size = UDim2.fromOffset(72, 72)
	toggleButton.BackgroundColor3 = Color3.fromRGB(52, 62, 80)
	toggleButton.TextColor3 = Color3.fromRGB(245, 245, 245)
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextScaled = true
	toggleButton.TextWrapped = true
	toggleButton.AutoButtonColor = true
	toggleButton.Parent = toggleGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = toggleButton

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(135, 155, 185)
	stroke.Parent = toggleButton
	makeButtonDraggable(toggleButton)

	toggleButton.Activated:Connect(function()
		toggleFlashlight()
	end)

	updateToggleVisual()
end

toggleFlashlight = function()
	flashlightOn = not flashlightOn

	flashlightRemote:FireServer({
		action = "Toggle",
		enabled = flashlightOn,
	})
	updateToggleVisual()

	if flashlightOn then
		print("[Flashlight] ON")
	else
		print("[Flashlight] OFF")
	end
end

ensureToggleUI()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		toggleFlashlight()
	end
end)

RunService.RenderStepped:Connect(function()
	if not flashlightOn then
		return
	end

	if camera ~= workspace.CurrentCamera then
		camera = workspace.CurrentCamera or camera
	end

	local now = os.clock()
	if now - lastAimSend < AIM_SEND_RATE then
		return
	end
	lastAimSend = now

	if camera then
		flashlightRemote:FireServer({
			action = "Aim",
			lookVector = camera.CFrame.LookVector,
		})
	end
end)

print("[Phase7.1] Flashlight Controller initialized (Server Aim)")
print(" Toggle: F key")
