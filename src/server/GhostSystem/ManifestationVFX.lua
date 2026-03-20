--[[
    GHOST MANIFESTATION VFX
    Handles ghost appearance/disappearance effects

    Effects:
    - Particle smoke/mist during manifestation
    - Transparency fade (0.3 -> 0.0 over 2 seconds)
    - Sound effect (whoosh + static)

    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.2
]]

local TweenService = game:GetService("TweenService")

local ManifestationVFX = {}

-- Create particle emitter for manifestation
function ManifestationVFX.CreateMistEmitter(parent)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "ManifestationMist"
    emitter.Parent = parent
    emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
    emitter.Rate = 50
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.Speed = NumberRange.new(0, 2)
    emitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255)) -- Ghostly blue
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 3)
    })
    emitter.Enabled = false

    return emitter
end

-- Manifest ghost (fade in)
function ManifestationVFX.Manifest(ghostModel, duration)
    duration = duration or 2

    local primaryPart = ghostModel.PrimaryPart or ghostModel:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then
        warn("[ManifestationVFX] No PrimaryPart found for ghost model")
        return
    end

    -- Create mist emitter
    local mistEmitter = ManifestationVFX.CreateMistEmitter(primaryPart)
    mistEmitter.Enabled = true

    -- Fade transparency (0.3 -> 0.0)
    for _, part in ipairs(ghostModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0.3 -- Start semi-transparent

            local tween = TweenService:Create(
                part,
                TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {Transparency = 0} -- Fully visible
            )
            tween:Play()
        end
    end

    -- Play manifestation sound (if available)
    local manifestSound = primaryPart:FindFirstChild("ManifestSound")
    if manifestSound and manifestSound:IsA("Sound") then
        manifestSound:Play()
    end

    -- Disable mist after duration
    task.delay(duration, function()
        mistEmitter.Enabled = false
        task.wait(2) -- Wait for particles to fade
        mistEmitter:Destroy()
    end)

    print("[ManifestationVFX] Ghost manifesting over", duration, "seconds")
end

-- Dematerialize ghost (fade out)
function ManifestationVFX.Dematerialize(ghostModel, duration)
    duration = duration or 2

    local primaryPart = ghostModel.PrimaryPart or ghostModel:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then
        warn("[ManifestationVFX] No PrimaryPart found for ghost model")
        return
    end

    -- Create mist emitter
    local mistEmitter = ManifestationVFX.CreateMistEmitter(primaryPart)
    mistEmitter.Enabled = true

    -- Fade transparency (current -> 1.0)
    for _, part in ipairs(ghostModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local tween = TweenService:Create(
                part,
                TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                {Transparency = 1} -- Fully invisible
            )
            tween:Play()
        end
    end

    -- Play dematerialization sound (if available)
    local dematerializeSound = primaryPart:FindFirstChild("DematerializeSound")
    if dematerializeSound and dematerializeSound:IsA("Sound") then
        dematerializeSound:Play()
    end

    -- Disable mist after duration
    task.delay(duration, function()
        mistEmitter.Enabled = false
        task.wait(2)
        mistEmitter:Destroy()
    end)

    print("[ManifestationVFX] Ghost dematerializing over", duration, "seconds")
end

return ManifestationVFX
