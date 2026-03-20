--[[
    DYNAMIC ATMOSPHERE SYSTEM
    Atmosphere density and fog increase as average team sanity drops

    Sanity 100-80: Light fog (Density 0.3)
    Sanity 79-50: Medium fog (Density 0.5)
    Sanity 49-20: Heavy fog (Density 0.7)
    Sanity <20: Extreme fog (Density 0.9)
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local atmosphere = Lighting:FindFirstChild("HorrorAtmosphere")
if not atmosphere then
    warn("[DynamicAtmosphere] HorrorAtmosphere not found")
    return
end

local function updateAtmosphere(averageSanity)
    averageSanity = math.clamp(averageSanity, 0, 100)

    local targetDensity
    if averageSanity >= 80 then
        targetDensity = 0.3 -- Light fog
    elseif averageSanity >= 50 then
        targetDensity = 0.5 -- Medium fog
    elseif averageSanity >= 20 then
        targetDensity = 0.7 -- Heavy fog
    else
        targetDensity = 0.9 -- Extreme fog (hunt imminent)
    end

    local tween = TweenService:Create(
        atmosphere,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {Density = targetDensity}
    )
    tween:Play()

    print("[DynamicAtmosphere] Sanity:", averageSanity, "Density:", targetDensity)
end

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local teamSanityEvent = remoteFolder:FindFirstChild("TeamSanityUpdate")

if not teamSanityEvent then
    teamSanityEvent = Instance.new("RemoteEvent")
    teamSanityEvent.Name = "TeamSanityUpdate"
    teamSanityEvent.Parent = remoteFolder
end

teamSanityEvent.OnClientEvent:Connect(function(averageSanity)
    updateAtmosphere(averageSanity)
end)

print("[DynamicAtmosphere] Initialized")
