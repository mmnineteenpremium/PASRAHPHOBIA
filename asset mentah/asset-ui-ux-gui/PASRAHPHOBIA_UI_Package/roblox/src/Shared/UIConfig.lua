local UIConfig = {}

UIConfig.Theme = {
    Colors = {
        VoidBlack = Color3.fromRGB(2, 4, 8),
        DeepPanel = Color3.fromRGB(8, 16, 22),
        FearBlue = Color3.fromRGB(0, 170, 255),
        DangerRed = Color3.fromRGB(255, 0, 51),
        SanityGreen = Color3.fromRGB(0, 255, 136),
        StaminaAmber = Color3.fromRGB(255, 170, 0),
        TextPrimary = Color3.fromRGB(200, 221, 232),
        TextDim = Color3.fromRGB(136, 162, 180),
        TextGhost = Color3.fromRGB(72, 88, 99),
    },
    Transparencies = {
        NoiseIdle = 0.95,
        NoiseFear = 0.7,
    },
}

UIConfig.RemoteNames = {
    SanityUpdate = "SanityUpdate",
    ObjectiveUpdate = "ObjectiveUpdate",
    HUDSnapshot = "HUDSnapshot",
    MapSync = "MapSync",
    InventorySnapshot = "InventorySnapshot",
    InventoryAction = "InventoryAction",
    RankedSync = "RankedSync",
    RoyalPassSync = "RoyalPassSync",
    RoyalPassClaim = "RoyalPassClaim",
    RoyalPassPurchase = "RoyalPassPurchase",
    EffectsEvent = "EffectsEvent",
}

UIConfig.SanityStates = {
    { Name = "Stable", Min = 70, Max = 100 },
    { Name = "Uneasy", Min = 40, Max = 69 },
    { Name = "Scared", Min = 20, Max = 39 },
    { Name = "Breaking", Min = 0, Max = 19 },
}

UIConfig.Rarities = {
    Common = { Color = Color3.fromRGB(90, 100, 114), Glow = 0 },
    Uncommon = { Color = Color3.fromRGB(31, 168, 98), Glow = 0.15 },
    Rare = { Color = Color3.fromRGB(20, 112, 212), Glow = 0.3 },
    Epic = { Color = Color3.fromRGB(136, 32, 224), Glow = 0.45 },
    Legendary = { Color = Color3.fromRGB(212, 146, 10), Glow = 0.65 },
}

UIConfig.HUD = {
    LowSanityThreshold = 30,
    QuickslotCount = 4,
}

local function addTier(tiers, groupName, divisions, starRequirement, badge)
    for index = divisions, 1, -1 do
        tiers[#tiers + 1] = {
            Id = string.lower(groupName) .. "_" .. index,
            Name = string.format("%s %d", groupName, index),
            Group = groupName,
            StarsRequired = starRequirement,
            Badge = badge,
        }
    end
end

local rankTiers = {}
addTier(rankTiers, "Bayi", 3, 3, "SilverSword")
addTier(rankTiers, "Balita", 3, 3, "BronzeShield")
addTier(rankTiers, "Anak-Anak", 3, 3, "GoldTrophy")
addTier(rankTiers, "Remaja", 4, 4, "PlatinumCrystal")
addTier(rankTiers, "Dewasa", 5, 5, "DiamondGem")
addTier(rankTiers, "Profesional", 5, 5, "OniMask")
addTier(rankTiers, "Detektive", 5, 5, "DragonHead")
rankTiers[#rankTiers + 1] = {
    Id = "sang_ahli",
    Name = "Sang Ahli",
    Group = "Sang Ahli",
    StarsRequired = 50,
    Badge = "PasrahSkull",
    Final = true,
}

do
    local totalStars = 0
    for _, tier in ipairs(rankTiers) do
        if tier.Final then
            tier.CumulativeStars = totalStars
        else
            totalStars += tier.StarsRequired
            tier.CumulativeStars = totalStars
        end
    end
end

UIConfig.RankTiers = rankTiers

function UIConfig.GetSanityState(value)
    local clamped = math.clamp(value, 0, 100)
    for _, state in ipairs(UIConfig.SanityStates) do
        if clamped >= state.Min and clamped <= state.Max then
            return state.Name
        end
    end
    return "Stable"
end

function UIConfig.GetRankTier(totalStars)
    local stars = math.max(0, totalStars or 0)
    for _, tier in ipairs(UIConfig.RankTiers) do
        if tier.Final then
            if stars >= tier.StarsRequired then
                return tier
            end
        elseif stars <= tier.CumulativeStars then
            return tier
        end
    end
    return UIConfig.RankTiers[#UIConfig.RankTiers]
end

return UIConfig
