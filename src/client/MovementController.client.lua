--[[
    MOVEMENT CONTROLLER
    Realistic player movement: walk, sprint, jump
    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.5
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Movement speeds (studs/second)
local WALK_SPEED = 10 -- Realistic human walk
local SPRINT_SPEED = 14 -- Sprint with Shift
local CROUCH_SPEED = 5 -- Crouch with Ctrl (optional)
local BACKWARD_SPEED_MULTIPLIER = 0.65 -- Slower backward movement for realism

-- Jump power
local JUMP_POWER = 32 -- Realistic jump height

-- Apply default movement
humanoid.WalkSpeed = WALK_SPEED
humanoid.JumpPower = JUMP_POWER
humanoid.UseJumpPower = true
humanoid.AutoRotate = true

-- Sprint state
local sprinting = false

local function stampMovementRuntime(targetSpeed, moveDirection, inMatch, backwardPenaltyActive)
    local moveMagnitude = typeof(moveDirection) == "Vector3" and moveDirection.Magnitude or 0
    player:SetAttribute("PasrahMovementOwner", "MovementController")
    player:SetAttribute("PasrahMovementSprinting", sprinting == true)
    player:SetAttribute("PasrahMovementInMatch", inMatch == true)
    player:SetAttribute("PasrahMovementTargetSpeed", tonumber(targetSpeed))
    player:SetAttribute("PasrahMovementCurrentWalkSpeed", humanoid and tonumber(humanoid.WalkSpeed) or nil)
    player:SetAttribute("PasrahMovementBackwardPenalty", backwardPenaltyActive == true)
    player:SetAttribute("PasrahMovementMoveMagnitude", math.floor((moveMagnitude or 0) * 100 + 0.5) / 100)
    if humanoid then
        humanoid:SetAttribute("PasrahMovementOwner", "MovementController")
        humanoid:SetAttribute("PasrahMovementTargetSpeed", tonumber(targetSpeed))
        humanoid:SetAttribute("PasrahMovementSprinting", sprinting == true)
        humanoid:SetAttribute("PasrahMovementInMatch", inMatch == true)
        humanoid:SetAttribute("PasrahMovementBackwardPenalty", backwardPenaltyActive == true)
    end
    if humanoidRootPart then
        humanoidRootPart:SetAttribute("PasrahMovementOwner", "MovementController")
        humanoidRootPart:SetAttribute("PasrahMovementTargetSpeed", tonumber(targetSpeed))
        humanoidRootPart:SetAttribute("PasrahMovementSprinting", sprinting == true)
        humanoidRootPart:SetAttribute("PasrahMovementInMatch", inMatch == true)
        humanoidRootPart:SetAttribute("PasrahMovementBackwardPenalty", backwardPenaltyActive == true)
    end
end

local function bindCharacter(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid.WalkSpeed = WALK_SPEED
    humanoid.JumpPower = JUMP_POWER
    humanoid.UseJumpPower = true
    humanoid.AutoRotate = true
    stampMovementRuntime(humanoid.WalkSpeed, Vector3.zero, player:GetAttribute("InMatch") == true, false)
end

player.CharacterAdded:Connect(bindCharacter)

-- Sprint toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = true
        humanoid.WalkSpeed = SPRINT_SPEED
        stampMovementRuntime(humanoid.WalkSpeed, humanoid.MoveDirection, player:GetAttribute("InMatch") == true, false)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = false
        humanoid.WalkSpeed = WALK_SPEED
        stampMovementRuntime(humanoid.WalkSpeed, humanoid.MoveDirection, player:GetAttribute("InMatch") == true, false)
    end
end)

RunService.RenderStepped:Connect(function()
    if not humanoid or not humanoidRootPart then
        return
    end

    if camera ~= workspace.CurrentCamera then
        camera = workspace.CurrentCamera or camera
    end

    -- Keep Roblox default rotation ownership to avoid local/client drift desync in FPV.
    if not humanoid.AutoRotate then
        humanoid.AutoRotate = true
    end

    local moveDirection = humanoid.MoveDirection
    local inMatch = player:GetAttribute("InMatch") == true
    local baseSpeed = sprinting and SPRINT_SPEED or WALK_SPEED
    local targetSpeed = baseSpeed
    local backwardPenaltyActive = false

    -- Enforce planar movement in investigation so FPV/camera vectors cannot inject Y motion.
    if inMatch and moveDirection.Magnitude > 0 then
        local flatMove = Vector3.new(moveDirection.X, 0, moveDirection.Z)
        if flatMove.Magnitude > 1e-4 then
            humanoid:Move(flatMove.Unit * math.min(moveDirection.Magnitude, 1), false)
            moveDirection = flatMove
        else
            humanoid:Move(Vector3.zero, false)
            moveDirection = Vector3.zero
        end
    end

    if moveDirection.Magnitude > 0 then
        local flatMove = Vector3.new(moveDirection.X, 0, moveDirection.Z)
        if flatMove.Magnitude > 0 then
            local flatForward = Vector3.new(humanoidRootPart.CFrame.LookVector.X, 0, humanoidRootPart.CFrame.LookVector.Z)
            local dot = flatForward:Dot(flatMove.Unit)
            if dot < -0.1 then
                targetSpeed = baseSpeed * BACKWARD_SPEED_MULTIPLIER
                backwardPenaltyActive = true
            end
        end
    end

    if humanoid.WalkSpeed ~= targetSpeed then
        humanoid.WalkSpeed = targetSpeed
    end

    stampMovementRuntime(targetSpeed, moveDirection, inMatch, backwardPenaltyActive)

end)

print("[Phase7.1] Movement Controller initialized")
print(" WalkSpeed:", WALK_SPEED, "studs/s")
print(" SprintSpeed:", SPRINT_SPEED, "studs/s")
print(" JumpPower:", JUMP_POWER)
