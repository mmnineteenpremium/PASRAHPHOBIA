--[[
    EVIDENCE VISUAL EFFECTS
    Cold breath, UV fingerprints, ghost orbs

    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.4
]]

-- Disabled on 2026-04-03.
-- This legacy LocalScript depends on the removed "TemperatureUpdate" remote
-- and conflicts with the modern evidence/UI pipeline.
return {
	Disabled = true,
	Reason = "Legacy Evidence VFX script archived after evidence/UI consolidation.",
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")

local EvidenceVFX = {}

-- Cold Breath Particle (Freezing Temperature evidence)
EvidenceVFX.ColdBreath = Instance.new("ParticleEmitter")
EvidenceVFX.ColdBreath.Name = "ColdBreath"
EvidenceVFX.ColdBreath.Parent = head
EvidenceVFX.ColdBreath.Texture = "rbxasset://textures/particles/smoke_main.dds"
EvidenceVFX.ColdBreath.Rate = 10
EvidenceVFX.ColdBreath.Lifetime = NumberRange.new(0.5, 1)
EvidenceVFX.ColdBreath.Speed = NumberRange.new(1, 3)
EvidenceVFX.ColdBreath.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
EvidenceVFX.ColdBreath.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.3),
    NumberSequenceKeypoint.new(1, 1)
})
EvidenceVFX.ColdBreath.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(1, 0.5)
})
EvidenceVFX.ColdBreath.Enabled = false

-- Enable/disable cold breath based on room temperature
local function updateColdBreath(temperature)
    if temperature < 5 then
        EvidenceVFX.ColdBreath.Enabled = true
    else
        EvidenceVFX.ColdBreath.Enabled = false
    end
end

-- Listen for temperature updates
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local temperatureUpdateEvent = remoteEvents:WaitForChild("TemperatureUpdate", 5)

if temperatureUpdateEvent then
    temperatureUpdateEvent.OnClientEvent:Connect(function(temp)
        updateColdBreath(temp)
    end)
    print("[EvidenceVFX] Listening for temperature updates")
else
    warn("[EvidenceVFX] TemperatureUpdate RemoteEvent not found")
end

-- UV Fingerprint reveal (called when UV light hits evidence node)
function EvidenceVFX.RevealFingerprint(evidenceNode)
    local fingerprint = evidenceNode:FindFirstChild("FingerprintDecal")
    if not fingerprint then
        fingerprint = Instance.new("Decal")
        fingerprint.Name = "FingerprintDecal"
        fingerprint.Parent = evidenceNode
        fingerprint.Face = Enum.NormalId.Top
        fingerprint.Texture = "rbxassetid://2036442782"
        fingerprint.Transparency = 1
    end

    -- Check if UV light is active
    local uvLight = character:FindFirstChild("UVFlashlight")
    if uvLight and uvLight:FindFirstChild("Handle") then
        local distance = (uvLight.Handle.Position - evidenceNode.Position).Magnitude

        if distance < 10 then
            fingerprint.Transparency = 0 -- Visible under UV
        else
            fingerprint.Transparency = 1 -- Hidden
        end
    else
        fingerprint.Transparency = 1
    end
end

-- Ghost Orb (floating light particle)
function EvidenceVFX.CreateTounVisual(position)
    local orb = Instance.new("Part")
    orb.Name = "TounVisual"
    orb.Size = Vector3.new(0.5, 0.5, 0.5)
    orb.Shape = Enum.PartType.Ball
    orb.Material = Enum.Material.Neon
    orb.BrickColor = BrickColor.new("Cyan")
    orb.Transparency = 0.5
    orb.CanCollide = false
    orb.Anchored = true
    orb.Position = position
    orb.Parent = workspace

    local orbLight = Instance.new("PointLight")
    orbLight.Parent = orb
    orbLight.Brightness = 2
    orbLight.Range = 10
    orbLight.Color = Color3.fromRGB(0, 255, 255)

    -- Float animation (sine wave)
    local startY = orb.Position.Y
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if not orb.Parent then
            connection:Disconnect()
            return
        end

        local offset = math.sin(tick() * 2) * 0.5
        orb.Position = Vector3.new(orb.Position.X, startY + offset, orb.Position.Z)
    end)

    return orb
end

print("[Phase7.4] Evidence VFX initialized")
return EvidenceVFX
