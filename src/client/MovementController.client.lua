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
local ROTATION_SMOOTH_SPEED = 12 -- Higher = snappier camera-yaw alignment in FPV

-- Jump power
local JUMP_POWER = 32 -- Realistic jump height

-- Apply default movement
humanoid.WalkSpeed = WALK_SPEED
humanoid.JumpPower = JUMP_POWER
humanoid.UseJumpPower = true
humanoid.AutoRotate = true

-- Sprint state
local sprinting = false
local currentYaw = nil

local function bindCharacter(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid.WalkSpeed = WALK_SPEED
    humanoid.JumpPower = JUMP_POWER
    humanoid.UseJumpPower = true
    humanoid.AutoRotate = true
end

player.CharacterAdded:Connect(bindCharacter)

-- Sprint toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = true
        humanoid.WalkSpeed = SPRINT_SPEED
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = false
        humanoid.WalkSpeed = WALK_SPEED
    end
end)

local function normalizeAngleDelta(delta)
    local twoPi = math.pi * 2
    delta = (delta + math.pi) % twoPi - math.pi
    return delta
end

RunService.RenderStepped:Connect(function(deltaTime)
    if not humanoid or not humanoidRootPart then
        return
    end

    if camera ~= workspace.CurrentCamera then
        camera = workspace.CurrentCamera or camera
    end

    local fpvActive = player.CameraMode == Enum.CameraMode.LockFirstPerson
    if fpvActive then
        if humanoid.AutoRotate then
            humanoid.AutoRotate = false
        end
        if camera then
            local _, targetYaw, _ = camera.CFrame:ToOrientation()
            if currentYaw == nil then
                currentYaw = targetYaw
            end
            local deltaYaw = normalizeAngleDelta(targetYaw - currentYaw)
            local alpha = math.clamp(deltaTime * ROTATION_SMOOTH_SPEED, 0, 1)
            currentYaw = currentYaw + deltaYaw * alpha
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.Angles(0, currentYaw, 0)
        end
    else
        if not humanoid.AutoRotate then
            humanoid.AutoRotate = true
        end
        currentYaw = nil
    end

    local moveDirection = humanoid.MoveDirection
    local baseSpeed = sprinting and SPRINT_SPEED or WALK_SPEED
    local targetSpeed = baseSpeed

    if moveDirection.Magnitude > 0 then
        local flatMove = Vector3.new(moveDirection.X, 0, moveDirection.Z)
        if flatMove.Magnitude > 0 then
            local flatForward = Vector3.new(humanoidRootPart.CFrame.LookVector.X, 0, humanoidRootPart.CFrame.LookVector.Z)
            local dot = flatForward:Dot(flatMove.Unit)
            if dot < -0.1 then
                targetSpeed = baseSpeed * BACKWARD_SPEED_MULTIPLIER
            end
        end
    end

    if humanoid.WalkSpeed ~= targetSpeed then
        humanoid.WalkSpeed = targetSpeed
    end
end)

print("[Phase7.1] Movement Controller initialized")
print(" WalkSpeed:", WALK_SPEED, "studs/s")
print(" SprintSpeed:", SPRINT_SPEED, "studs/s")
print(" JumpPower:", JUMP_POWER)
