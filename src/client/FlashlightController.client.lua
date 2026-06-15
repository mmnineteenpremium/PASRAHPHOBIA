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
local CameraResolver = require(script.Parent:WaitForChild("CameraResolver"))

local REMOTE_NAME = "FlashlightEvent"
local FLASHLIGHT_ATTRIBUTE = "FlashlightEnabled"
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local flashlightRemote = remoteFolder:WaitForChild(REMOTE_NAME)

local AIM_SEND_RATE = 1 / 20
local AIM_DOT_DELTA_THRESHOLD = 0.001
local AIM_STATIONARY_KEEPALIVE_SECONDS = 1.2

local flashlightOn = false
local lastAimSend = 0
local lastAimTransmitAt = 0
local lastAimLookVector = nil
local camera = workspace.CurrentCamera
local toggleGui = nil
local toggleButton = nil
local toggleButtonConnection = nil
local toggleFlashlight
local aimRenderConnection = nil
local TOOL_BLOCKED_ATTRIBUTE = "PasrahFlashlightBlockedByTool"
local TOOL_EQUIPPED_ATTRIBUTE = "PasrahEquippedToolType"
local PREPARATION_TOOL_ATTRIBUTE = "PreparationFocusTool"
local toggleUiContractWarned = false
local runtimeDragBindings = setmetatable({}, { __mode = "k" })
local ProximityPromptService = game:GetService("ProximityPromptService")
local visiblePromptCount = 0

ProximityPromptService.PromptShown:Connect(function()
	visiblePromptCount = visiblePromptCount + 1
end)
ProximityPromptService.PromptHidden:Connect(function()
	visiblePromptCount = math.max(0, visiblePromptCount - 1)
end)

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

local function loadToolUsageRules()
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	local gameData = shared and shared:FindFirstChild("GameData")
	return safeRequire(gameData and gameData:FindFirstChild("ToolUsageRules")) or nil
end

local TOOL_USAGE_RULES = loadToolUsageRules()

local function setAttributeIfChanged(instance, attributeName, value, numberEpsilon)
	if not instance then
		return
	end
	local current = instance:GetAttribute(attributeName)
	if typeof(current) == "number" and typeof(value) == "number" and tonumber(numberEpsilon) then
		if math.abs(current - value) <= numberEpsilon then
			return
		end
	elseif current == value then
		return
	end
	instance:SetAttribute(attributeName, value)
end

local function isPlayerInMatch()
	return player:GetAttribute("InMatch") == true
		or tostring(player:GetAttribute("MatchId") or "") ~= ""
end

local function resolveActiveToolType()
	local equippedTool = player:GetAttribute(TOOL_EQUIPPED_ATTRIBUTE)
	if type(equippedTool) == "string" and equippedTool ~= "" then
		return equippedTool
	end
	local preparationTool = player:GetAttribute(PREPARATION_TOOL_ATTRIBUTE)
	if type(preparationTool) == "string" and preparationTool ~= "" then
		return preparationTool
	end
	return nil
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

local function resolveBlockedTool()
	local activeToolType = resolveActiveToolType()
	if canUseWithFlashlight(activeToolType) then
		return nil
	end
	return activeToolType
end

local function shouldShowToggleUI()
	return UserInputService.TouchEnabled == true and isPlayerInMatch()
end

local function dedupeScreenGuiByName(playerGui, guiName)
	local keeper = nil
	for _, child in ipairs(playerGui:GetChildren()) do
		if child.Name == guiName then
			if child:IsA("ScreenGui") and not keeper then
				keeper = child
			else
				child:Destroy()
			end
		end
	end
	return keeper
end

local function stampFlashlightClientState()
	setAttributeIfChanged(player, "PasrahFlashlightClientEnabled", flashlightOn == true)
	setAttributeIfChanged(player, "PasrahFlashlightClientTouchEligible", UserInputService.TouchEnabled == true)
	setAttributeIfChanged(player, "PasrahFlashlightClientToggleVisible", shouldShowToggleUI())
	setAttributeIfChanged(player, TOOL_BLOCKED_ATTRIBUTE, resolveBlockedTool())
end

local function stampToggleRuntime()
	if toggleGui then
		setAttributeIfChanged(toggleGui, "PasrahFlashlightOwner", "FlashlightController")
		setAttributeIfChanged(toggleGui, "PasrahFlashlightChannel", "ToggleUI")
		setAttributeIfChanged(toggleGui, "PasrahFlashlightTouchEligible", UserInputService.TouchEnabled == true)
		setAttributeIfChanged(toggleGui, "PasrahFlashlightVisible", shouldShowToggleUI())
	end
	if toggleButton then
		setAttributeIfChanged(toggleButton, "PasrahFlashlightOwner", "FlashlightController")
		setAttributeIfChanged(toggleButton, "PasrahFlashlightChannel", "ToggleButton")
		setAttributeIfChanged(toggleButton, "PasrahFlashlightState", flashlightOn and "On" or "Off")
		setAttributeIfChanged(toggleButton, "PasrahFlashlightVisible", shouldShowToggleUI())
		setAttributeIfChanged(
			toggleButton,
			"PasrahFlashlightInputMode",
			UserInputService.TouchEnabled == true and "Touch" or "Keyboard"
		)
	end
	stampFlashlightClientState()
end

local function makeButtonDraggable(button)
	if not button or runtimeDragBindings[button] == true then
		return
	end
	runtimeDragBindings[button] = true

	local dragging = false
	local dragStart = nil
	local startPos = nil
	local userInputChangedConnection = nil

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

	userInputChangedConnection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)

	button.Destroying:Connect(function()
		if userInputChangedConnection then
			userInputChangedConnection:Disconnect()
			userInputChangedConnection = nil
		end
	end)
end

local function bindToggleButton(button)
	if not button then
		return
	end
	if toggleButton == button and toggleButtonConnection then
		return
	end
	if toggleButtonConnection then
		toggleButtonConnection:Disconnect()
		toggleButtonConnection = nil
	end
	toggleButtonConnection = button.Activated:Connect(function()
		toggleFlashlight()
	end)
end

local function resolveActiveCamera()
	local current = workspace.CurrentCamera
	if current then
		camera = current
		return current
	end
	camera = CameraResolver.ResolveOrFallback(5, camera)
	return camera
end

local function shouldSendAim(now, lookVector)
	if typeof(lookVector) ~= "Vector3" then
		return false
	end
	if typeof(lastAimLookVector) ~= "Vector3" then
		return true
	end

	local dot = math.clamp(lastAimLookVector:Dot(lookVector), -1, 1)
	local dotDelta = 1 - dot
	if dotDelta >= AIM_DOT_DELTA_THRESHOLD then
		return true
	end
	return (now - lastAimTransmitAt) >= AIM_STATIONARY_KEEPALIVE_SECONDS
end

local function stopAimLoop()
	if aimRenderConnection then
		aimRenderConnection:Disconnect()
		aimRenderConnection = nil
	end
end

local function sendAimUpdate()
	if flashlightOn ~= true or isPlayerInMatch() ~= true then
		return
	end

	local now = os.clock()
	if now - lastAimSend < AIM_SEND_RATE then
		return
	end

	local activeCamera = resolveActiveCamera()
	if not activeCamera then
		return
	end

	local lookVector = activeCamera.CFrame.LookVector
	if not shouldSendAim(now, lookVector) then
		return
	end

	lastAimSend = now
	lastAimTransmitAt = now
	lastAimLookVector = lookVector
	flashlightRemote:FireServer({
		action = "Aim",
		lookVector = lookVector,
	})
end

local function syncAimLoop()
	local shouldRun = flashlightOn == true and isPlayerInMatch() == true
	if shouldRun and not aimRenderConnection then
		aimRenderConnection = RunService.RenderStepped:Connect(sendAimUpdate)
	elseif not shouldRun then
		stopAimLoop()
	end
end

local function updateToggleVisual()
	if not toggleButton then
		stampFlashlightClientState()
		return
	end
	local blockedTool = resolveBlockedTool()
	if blockedTool and flashlightOn ~= true then
		toggleButton.Text = "SENTER\nLOCK"
		toggleButton.BackgroundColor3 = Color3.fromRGB(108, 62, 62)
	elseif flashlightOn then
		toggleButton.Text = "SENTER\nON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(196, 154, 64)
	else
		toggleButton.Text = "SENTER\nOFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(52, 62, 80)
	end
	stampToggleRuntime()
end

local function ensureToggleUI()
	local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
	local existing = dedupeScreenGuiByName(playerGui, "FlashlightToggleUI")
	if not existing then
		existing = playerGui:FindFirstChild("FlashlightToggleUI") or playerGui:WaitForChild("FlashlightToggleUI", 5)
	end
	if not existing or not existing:IsA("ScreenGui") then
		if not toggleUiContractWarned then
			toggleUiContractWarned = true
			warn("[FlashlightController] Missing authored FlashlightToggleUI ScreenGui; check StarterGui shell contract.")
		end
		toggleGui = nil
		toggleButton = nil
		return nil
	end
	local button = existing:FindFirstChild("ToggleButton")
	if not button or not button:IsA("TextButton") then
		if not toggleUiContractWarned then
			toggleUiContractWarned = true
			warn("[FlashlightController] Missing ToggleButton in authored FlashlightToggleUI; preserve canonical widget names.")
		end
		toggleGui = nil
		toggleButton = nil
		return nil
	end

	toggleGui = existing
	toggleButton = button
	makeButtonDraggable(toggleButton)
	bindToggleButton(toggleButton)
	toggleGui.Enabled = shouldShowToggleUI()
	updateToggleVisual()
	stampToggleRuntime()
	return toggleGui
end

toggleFlashlight = function()
	local blockedTool = resolveBlockedTool()
	if flashlightOn ~= true and blockedTool then
		setAttributeIfChanged(player, TOOL_BLOCKED_ATTRIBUTE, blockedTool)
		updateToggleVisual()
		stampToggleRuntime()
		print(string.format("[Flashlight] BLOCKED by tool=%s", tostring(blockedTool)))
		return
	end

	flashlightOn = not flashlightOn
	setAttributeIfChanged(player, FLASHLIGHT_ATTRIBUTE, flashlightOn)
	setAttributeIfChanged(player, TOOL_BLOCKED_ATTRIBUTE, flashlightOn and nil or blockedTool)

	flashlightRemote:FireServer({
		action = "Toggle",
		enabled = flashlightOn,
	})
	updateToggleVisual()
	stampToggleRuntime()

	if flashlightOn then
		lastAimSend = 0
		lastAimTransmitAt = 0
		lastAimLookVector = nil
		print("[Flashlight] ON")
	else
		print("[Flashlight] OFF")
	end
	syncAimLoop()
end

local function refreshToggleUIVisibility()
	local inMatch = isPlayerInMatch()
	local blockedTool = resolveBlockedTool()
	if blockedTool and flashlightOn == true then
		flashlightOn = false
		setAttributeIfChanged(player, FLASHLIGHT_ATTRIBUTE, false)
		setAttributeIfChanged(player, TOOL_BLOCKED_ATTRIBUTE, blockedTool)
		flashlightRemote:FireServer({
			action = "Toggle",
			enabled = false,
		})
	end
	if inMatch ~= true and flashlightOn == true then
		flashlightOn = false
		setAttributeIfChanged(player, FLASHLIGHT_ATTRIBUTE, false)
		flashlightRemote:FireServer({
			action = "Toggle",
			enabled = false,
		})
	end

	if UserInputService.TouchEnabled ~= true then
		if not toggleGui or not toggleGui.Parent then
			ensureToggleUI()
		end
		if toggleGui then
			toggleGui.Enabled = false
		end
		updateToggleVisual()
		stampToggleRuntime()
		syncAimLoop()
		return
	end
	if not toggleGui or not toggleGui.Parent then
		ensureToggleUI()
	end
	if toggleGui then
		toggleGui.Enabled = shouldShowToggleUI()
	end
	updateToggleVisual()
	stampToggleRuntime()
	syncAimLoop()
end

local function syncFlashlightStateFromAttribute()
	local attributeEnabled = player:GetAttribute(FLASHLIGHT_ATTRIBUTE) == true
	local blockedTool = resolveBlockedTool()

	if blockedTool and attributeEnabled == true then
		flashlightOn = false
		setAttributeIfChanged(player, FLASHLIGHT_ATTRIBUTE, false)
		setAttributeIfChanged(player, TOOL_BLOCKED_ATTRIBUTE, blockedTool)
		flashlightRemote:FireServer({
			action = "Toggle",
			enabled = false,
		})
		updateToggleVisual()
		stampToggleRuntime()
		syncAimLoop()
		return
	end

	if flashlightOn == attributeEnabled then
		updateToggleVisual()
		stampToggleRuntime()
		syncAimLoop()
		return
	end

	flashlightOn = attributeEnabled
	if flashlightOn then
		lastAimSend = 0
		lastAimTransmitAt = 0
		lastAimLookVector = nil
	end

	updateToggleVisual()
	stampToggleRuntime()
	syncAimLoop()
end

setAttributeIfChanged(player, FLASHLIGHT_ATTRIBUTE, flashlightOn)
ensureToggleUI()
refreshToggleUIVisibility()
stampFlashlightClientState()

player:GetAttributeChangedSignal(FLASHLIGHT_ATTRIBUTE):Connect(syncFlashlightStateFromAttribute)
player:GetAttributeChangedSignal("InMatch"):Connect(refreshToggleUIVisibility)
player:GetAttributeChangedSignal("MatchId"):Connect(refreshToggleUIVisibility)
player:GetAttributeChangedSignal(TOOL_EQUIPPED_ATTRIBUTE):Connect(refreshToggleUIVisibility)
player:GetAttributeChangedSignal(PREPARATION_TOOL_ATTRIBUTE):Connect(refreshToggleUIVisibility)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		if visiblePromptCount > 0 then
			return
		end
		toggleFlashlight()
	end
end)

print("[Phase7.1] Flashlight Controller initialized (Server Aim)")
print(" Toggle: F key")
