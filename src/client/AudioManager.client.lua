--[[
    SPATIAL AUDIO MANAGER
    Handles 3D positional audio for ghost sounds, environmental audio

    Features:
    - Ghost footsteps (3D positioned)
    - Environmental sounds (doors, lights)
    - Material-based footstep sounds

    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.4
]]

local AudioManager = {}

-- Material-based footstep sounds
AudioManager.FootstepSounds = {
    [Enum.Material.Wood] = "rbxassetid://910433616998508",
    [Enum.Material.Concrete] = "rbxassetid://79900103772577",
    [Enum.Material.Metal] = "rbxassetid://90448271562175",
    Default = "rbxassetid://910433616998508"
}

-- Create 3D spatial sound
function AudioManager.Create3DSound(parent, soundId, volume, rollOffDistance)
    volume = volume or 0.5
    rollOffDistance = rollOffDistance or {10, 100} -- {min, max}

    local sound = Instance.new("Sound")
    sound.Parent = parent
    sound.SoundId = soundId
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = rollOffDistance[1]
    sound.RollOffMaxDistance = rollOffDistance[2]
    sound.Volume = volume

    return sound
end

-- Play ghost footstep at position
function AudioManager.PlayGhostFootstep(position, material)
    material = material or Enum.Material.Wood

    -- Create temporary part for sound positioning
    local soundPart = Instance.new("Part")
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Transparency = 1
    soundPart.Size = Vector3.new(1, 1, 1)
    soundPart.Position = position
    soundPart.Parent = workspace

    -- Get appropriate footstep sound
    local soundId = AudioManager.FootstepSounds[material] or AudioManager.FootstepSounds.Default

    -- Create and play sound
    local sound = AudioManager.Create3DSound(soundPart, soundId, 0.5, {10, 50})
    sound:Play()

    -- Clean up after sound finishes
    sound.Ended:Connect(function()
        soundPart:Destroy()
    end)

    -- Failsafe cleanup after 5 seconds
    task.delay(5, function()
        if soundPart.Parent then
            soundPart:Destroy()
        end
    end)
end

-- Detect player footstep material (for ambient sound)
function AudioManager.GetFloorMaterial(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return Enum.Material.Plastic end

    local rayOrigin = humanoidRootPart.Position
    local rayDirection = Vector3.new(0, -5, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        return raycastResult.Instance.Material
    end

    return Enum.Material.Plastic
end

print("[Phase7.4] Audio Manager initialized")
return AudioManager
