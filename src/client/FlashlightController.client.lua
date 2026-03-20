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

local function toggleFlashlight()
	flashlightOn = not flashlightOn

	flashlightRemote:FireServer({
		action = "Toggle",
		enabled = flashlightOn,
	})

	if flashlightOn then
		print("[Flashlight] ON")
	else
		print("[Flashlight] OFF")
	end
end

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
