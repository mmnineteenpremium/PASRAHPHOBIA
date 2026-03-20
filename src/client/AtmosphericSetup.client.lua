--[[
    ATMOSPHERIC MASTER SETUP
    Configures Future Lighting, ColorCorrection, and Atmosphere for horror aesthetic
    
    Based on: CANONICAL_SPECIFICATIONS_v2.md
    Phase: 7.1
]]

local Lighting = game:GetService("Lighting")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Future Lighting Configuration
Lighting.Brightness = 0.22 -- Slightly brighter for visibility
Lighting.Ambient = Color3.fromRGB(20, 26, 38) -- Dark blue-grey ambient (lifted)
Lighting.OutdoorAmbient = Color3.fromRGB(14, 14, 30) -- Deep blue night sky (lifted)
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.2 -- Subtle shadow edges

-- Remove existing ColorCorrection if present
for _, effect in ipairs(Lighting:GetChildren()) do
    if effect:IsA("ColorCorrectionEffect") then
        effect:Destroy()
    end
end

-- ColorCorrection Effect
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "HorrorColorGrading"
colorCorrection.Parent = Lighting
colorCorrection.Brightness = -0.1 -- Slightly darker
colorCorrection.Contrast = 0.2 -- Sharper shadows
colorCorrection.Saturation = -0.3 -- Desaturated horror look
colorCorrection.TintColor = Color3.fromRGB(200, 210, 255) -- Slight blue tint

-- Remove existing Atmosphere if present
for _, effect in ipairs(Lighting:GetChildren()) do
    if effect:IsA("Atmosphere") then
        effect:Destroy()
    end
end

-- Atmosphere Effect
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "HorrorAtmosphere"
atmosphere.Parent = Lighting
atmosphere.Density = 0.4 -- Visible fog
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(150, 160, 180) -- Misty blue
atmosphere.Decay = Color3.fromRGB(100, 110, 130)
atmosphere.Glare = 0 -- No glare (darker feel)
atmosphere.Haze = 2 -- Increased haze for depth

print("[Phase7.1] Atmospheric Master Setup complete")
print(" Lighting.Brightness:", Lighting.Brightness)
print(" ColorCorrection:", colorCorrection.Brightness, colorCorrection.Contrast, colorCorrection.Saturation)
print(" Atmosphere Density:", atmosphere.Density)
