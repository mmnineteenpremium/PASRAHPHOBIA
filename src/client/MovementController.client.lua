--[[
    MOVEMENT CONTROLLER
    Realistic player movement: walk, sprint, jump
    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.5
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local humanoidRootPart = nil

-- Movement speeds (studs/second)
local WALK_SPEED = 10 -- Realistic human walk
local SPRINT_SPEED = 14 -- Sprint with Shift
local BACKWARD_SPEED_MULTIPLIER = 0.65 -- Slower backward movement for realism

-- Jump power
local JUMP_POWER = 32 -- Realistic jump height

-- Sprint state
local sprinting = false

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

local function stampMovementRuntime(targetSpeed, moveDirection, inMatch, backwardPenaltyActive, activeHumanoid, activeRootPart)
	local moveMagnitude = typeof(moveDirection) == "Vector3" and moveDirection.Magnitude or 0
	setAttributeIfChanged(player, "PasrahMovementOwner", "MovementController")
	setAttributeIfChanged(player, "PasrahMovementSprinting", sprinting == true)
	setAttributeIfChanged(player, "PasrahMovementInMatch", inMatch == true)
	setAttributeIfChanged(player, "PasrahMovementTargetSpeed", tonumber(targetSpeed), 0.001)
	setAttributeIfChanged(player, "PasrahMovementCurrentWalkSpeed", activeHumanoid and tonumber(activeHumanoid.WalkSpeed) or nil, 0.001)
	setAttributeIfChanged(player, "PasrahMovementBackwardPenalty", backwardPenaltyActive == true)
	setAttributeIfChanged(
		player,
		"PasrahMovementMoveMagnitude",
		math.floor((moveMagnitude or 0) * 100 + 0.5) / 100,
		0.001
	)

	if activeHumanoid then
		setAttributeIfChanged(activeHumanoid, "PasrahMovementOwner", "MovementController")
		setAttributeIfChanged(activeHumanoid, "PasrahMovementTargetSpeed", tonumber(targetSpeed), 0.001)
		setAttributeIfChanged(activeHumanoid, "PasrahMovementSprinting", sprinting == true)
		setAttributeIfChanged(activeHumanoid, "PasrahMovementInMatch", inMatch == true)
		setAttributeIfChanged(activeHumanoid, "PasrahMovementBackwardPenalty", backwardPenaltyActive == true)
	end

	if activeRootPart then
		setAttributeIfChanged(activeRootPart, "PasrahMovementOwner", "MovementController")
		setAttributeIfChanged(activeRootPart, "PasrahMovementTargetSpeed", tonumber(targetSpeed), 0.001)
		setAttributeIfChanged(activeRootPart, "PasrahMovementSprinting", sprinting == true)
		setAttributeIfChanged(activeRootPart, "PasrahMovementInMatch", inMatch == true)
		setAttributeIfChanged(activeRootPart, "PasrahMovementBackwardPenalty", backwardPenaltyActive == true)
	end
end

local function applyDefaultMovement(activeHumanoid)
	if not activeHumanoid then
		return
	end
	activeHumanoid.WalkSpeed = WALK_SPEED
	activeHumanoid.JumpPower = JUMP_POWER
	activeHumanoid.UseJumpPower = true
	activeHumanoid.AutoRotate = true
end

local function resolveLiveCharacterRefs()
	local activeCharacter = player.Character
	if not activeCharacter or activeCharacter.Parent == nil then
		character = nil
		humanoid = nil
		humanoidRootPart = nil
		return nil, nil, nil
	end

	if activeCharacter ~= character then
		character = activeCharacter
		humanoid = nil
		humanoidRootPart = nil
	end

	if not humanoid or humanoid.Parent ~= character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end
	if not humanoidRootPart or humanoidRootPart.Parent ~= character then
		humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	end

	if not humanoid
		or not humanoidRootPart
		or not humanoid:IsA("Humanoid")
		or not humanoidRootPart:IsA("BasePart") then
		return character, nil, nil
	end
	return character, humanoid, humanoidRootPart
end

local function bindCharacter(newCharacter)
	if not newCharacter then
		return
	end

	character = newCharacter
	humanoid = newCharacter:FindFirstChildOfClass("Humanoid") or newCharacter:WaitForChild("Humanoid", 8)
	humanoidRootPart = newCharacter:FindFirstChild("HumanoidRootPart") or newCharacter:WaitForChild("HumanoidRootPart", 8)

	if not humanoid or not humanoidRootPart then
		return
	end

	sprinting = false
	if player:GetAttribute("PasrahNpcDialogueActive") == true then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.UseJumpPower = true
		humanoid.AutoRotate = false
		stampMovementRuntime(0, Vector3.zero, player:GetAttribute("InMatch") == true, false, humanoid, humanoidRootPart)
	else
		applyDefaultMovement(humanoid)
		stampMovementRuntime(humanoid.WalkSpeed, Vector3.zero, player:GetAttribute("InMatch") == true, false, humanoid, humanoidRootPart)
	end
end

if player.Character then
	bindCharacter(player.Character)
end
player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function(removingCharacter)
	if removingCharacter == character then
		sprinting = false
		character = nil
		humanoid = nil
		humanoidRootPart = nil
	end
end)

-- Sprint toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode ~= Enum.KeyCode.LeftShift then
		return
	end
	if player:GetAttribute("PasrahNpcDialogueActive") == true then
		return
	end

	local _, activeHumanoid, activeRootPart = resolveLiveCharacterRefs()
	if not activeHumanoid then
		return
	end

	sprinting = true
	activeHumanoid.WalkSpeed = SPRINT_SPEED
	stampMovementRuntime(
		activeHumanoid.WalkSpeed,
		activeHumanoid.MoveDirection,
		player:GetAttribute("InMatch") == true,
		false,
		activeHumanoid,
		activeRootPart
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.LeftShift then
		return
	end
	if player:GetAttribute("PasrahNpcDialogueActive") == true then
		return
	end

	sprinting = false
	local _, activeHumanoid, activeRootPart = resolveLiveCharacterRefs()
	if not activeHumanoid then
		return
	end
	activeHumanoid.WalkSpeed = WALK_SPEED
	stampMovementRuntime(
		activeHumanoid.WalkSpeed,
		activeHumanoid.MoveDirection,
		player:GetAttribute("InMatch") == true,
		false,
		activeHumanoid,
		activeRootPart
	)
end)

RunService.RenderStepped:Connect(function()
	local activeCharacter, activeHumanoid, activeRootPart = resolveLiveCharacterRefs()
	if not activeCharacter or not activeHumanoid or not activeRootPart then
		return
	end
	if activeHumanoid.Parent ~= activeCharacter or activeRootPart.Parent ~= activeCharacter then
		return
	end
	if activeHumanoid.Health <= 0 then
		return
	end

	local inMatch = player:GetAttribute("InMatch") == true
	local dialogueActive = player:GetAttribute("PasrahNpcDialogueActive") == true

	if dialogueActive then
		activeHumanoid.WalkSpeed = 0
		activeHumanoid.JumpPower = 0
		activeHumanoid.UseJumpPower = true
		activeHumanoid.AutoRotate = false
		activeHumanoid:Move(Vector3.zero, false)
		stampMovementRuntime(0, Vector3.zero, inMatch, false, activeHumanoid, activeRootPart)
		return
	end

	-- Keep Roblox default rotation ownership to avoid local/client drift desync in FPV.
	if not activeHumanoid.AutoRotate then
		activeHumanoid.AutoRotate = true
	end

	local moveDirection = activeHumanoid.MoveDirection
	local baseSpeed = sprinting and SPRINT_SPEED or WALK_SPEED
	local targetSpeed = baseSpeed
	local backwardPenaltyActive = false

	-- Enforce planar movement in investigation so FPV/camera vectors cannot inject Y motion.
	if inMatch and moveDirection.Magnitude > 0 then
		local flatMove = Vector3.new(moveDirection.X, 0, moveDirection.Z)
		if flatMove.Magnitude > 1e-4 then
			activeHumanoid:Move(flatMove.Unit * math.min(moveDirection.Magnitude, 1), false)
			moveDirection = flatMove
		else
			activeHumanoid:Move(Vector3.zero, false)
			moveDirection = Vector3.zero
		end
	end

	if moveDirection.Magnitude > 0 then
		local flatMove = Vector3.new(moveDirection.X, 0, moveDirection.Z)
		if flatMove.Magnitude > 0 then
			local flatForward = Vector3.new(activeRootPart.CFrame.LookVector.X, 0, activeRootPart.CFrame.LookVector.Z)
			local dot = flatForward:Dot(flatMove.Unit)
			if dot < -0.1 then
				targetSpeed = baseSpeed * BACKWARD_SPEED_MULTIPLIER
				backwardPenaltyActive = true
			end
		end
	end

	if activeHumanoid.WalkSpeed ~= targetSpeed then
		activeHumanoid.WalkSpeed = targetSpeed
	end

	stampMovementRuntime(targetSpeed, moveDirection, inMatch, backwardPenaltyActive, activeHumanoid, activeRootPart)
end)

print("[Phase7.1] Movement Controller initialized")
print(" WalkSpeed:", WALK_SPEED, "studs/s")
print(" SprintSpeed:", SPRINT_SPEED, "studs/s")
print(" JumpPower:", JUMP_POWER)
