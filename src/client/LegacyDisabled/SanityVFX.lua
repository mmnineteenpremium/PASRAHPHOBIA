--[[
    SANITY VISUAL EFFECTS
    Vignette, blur, color desaturation, heartbeat based on sanity level

    Effects scale with sanity (0-100):
    - 100 sanity: No effects
    - 50 sanity: Mild vignette, heartbeat starts
    - 0 sanity: Full vignette, heavy blur, desaturation, fast heartbeat

    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.4
]]

-- Disabled on 2026-04-03.
-- This legacy LocalScript listens for the removed "SanityUpdate" remote and
-- duplicates the modern sensory stack driven by SoundSystem/VFXController.
return {
	Disabled = true,
	Reason = "Legacy Sanity VFX script archived after sensory stack consolidation.",
}

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui for vignette
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SanityVFX"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Vignette Frame
local vignetteFrame = Instance.new("Frame")
vignetteFrame.Name = "Vignette"
vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
vignetteFrame.Position = UDim2.new(0, 0, 0, 0)
vignetteFrame.BackgroundTransparency = 1
vignetteFrame.ZIndex = 10
vignetteFrame.Parent = screenGui

local vignetteImage = Instance.new("ImageLabel")
vignetteImage.Name = "VignetteImage"
vignetteImage.Size = UDim2.new(1, 0, 1, 0)
vignetteImage.Image = "rbxassetid://1885779457" -- Replace with actual vignette texture
vignetteImage.ImageTransparency = 1 -- Hidden by default
vignetteImage.BackgroundTransparency = 1
vignetteImage.Parent = vignetteFrame

-- Blur Effect
local blurEffect = Lighting:FindFirstChild("SanityBlur")
if not blurEffect then
    blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "SanityBlur"
    blurEffect.Size = 0 -- No blur by default
    blurEffect.Parent = Lighting
end

-- Color Correction for desaturation
local colorCorrection = Lighting:FindFirstChild("HorrorColorGrading")
if not colorCorrection then
    warn("[SanityVFX] HorrorColorGrading not found, creating default")
    colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "HorrorColorGrading"
    colorCorrection.Parent = Lighting
end

-- Heartbeat Sound
local heartbeatSound = Instance.new("Sound")
heartbeatSound.Name = "Heartbeat"
heartbeatSound.SoundId = "rbxassetid://138884191945388" -- Replace with actual heartbeat sound
heartbeatSound.Looped = true
heartbeatSound.Volume = 0
heartbeatSound.Parent = playerGui

-- Update effects based on sanity
local function updateSanityEffects(sanity)
    sanity = math.clamp(sanity, 0, 100)

    -- Vignette intensity (0 sanity = full vignette, 100 sanity = no vignette)
    local vignetteIntensity = 1 - (sanity / 100)
    vignetteImage.ImageTransparency = 1 - vignetteIntensity

    -- Blur intensity (0 sanity = 10 blur, 100 sanity = 0 blur)
    blurEffect.Size = (100 - sanity) / 10

    -- Color desaturation (0 sanity = -0.5, 100 sanity = -0.3)
    colorCorrection.Saturation = -0.3 - ((100 - sanity) / 500)

    -- Heartbeat (starts at 50 sanity, increases as sanity drops)
    if sanity < 50 then
        local heartbeatVolume = (50 - sanity) / 50
        heartbeatSound.Volume = heartbeatVolume
        heartbeatSound.PlaybackSpeed = 1 + ((50 - sanity) / 100)

        if not heartbeatSound.IsPlaying then
            heartbeatSound:Play()
        end
    else
        if heartbeatSound.IsPlaying then
            heartbeatSound:Stop()
        end
    end
end

-- Listen for sanity updates from server
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local sanityUpdateEvent = remoteEvents:WaitForChild("SanityUpdate", 5)

if sanityUpdateEvent then
    sanityUpdateEvent.OnClientEvent:Connect(function(sanity)
        updateSanityEffects(sanity)
    end)
    print("[SanityVFX] Listening for sanity updates")
else
    warn("[SanityVFX] SanityUpdate RemoteEvent not found")
    -- Default to full sanity
    updateSanityEffects(100)
end
