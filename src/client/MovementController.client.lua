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
local TELEMETRY_INTERVAL_SECONDS = 0.5
local TELEMETRY_PREFIX = "[MovementTelemetry]"

-- Jump power
local JUMP_POWER = 32 -- Realistic jump height

-- Apply default movement
humanoid.WalkSpeed = WALK_SPEED
humanoid.JumpPower = JUMP_POWER
humanoid.UseJumpPower = true
humanoid.AutoRotate = true

-- Sprint state
local sprinting = false
local lastTelemetryAt = 0

local function bindCharacter(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid.WalkSpeed = WALK_SPEED
    humanoid.JumpPower = JUMP_POWER
    humanoid.UseJumpPower = true
    humanoid.AutoRotate = true
    lastTelemetryAt = 0
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
            end
        end
    end

    if humanoid.WalkSpeed ~= targetSpeed then
        humanoid.WalkSpeed = targetSpeed
    end

    if inMatch then
        local now = os.clock()
        if (now - lastTelemetryAt) >= TELEMETRY_INTERVAL_SECONDS then
            lastTelemetryAt = now
            print(string.format(
                "%s name=%s state=%s floor=%s velY=%.3f posY=%.3f moveY=%.3f",
                TELEMETRY_PREFIX,
                player.Name,
                tostring(humanoid:GetState()),
                tostring(humanoid.FloorMaterial),
                humanoidRootPart.AssemblyLinearVelocity.Y,
                humanoidRootPart.Position.Y,
                moveDirection.Y
            ))
        end
    end
end)

print("[Phase7.1] Movement Controller initialized")
print(" WalkSpeed:", WALK_SPEED, "studs/s")
print(" SprintSpeed:", SPRINT_SPEED, "studs/s")
print(" JumpPower:", JUMP_POWER)
