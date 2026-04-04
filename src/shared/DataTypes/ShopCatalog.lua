local ShopCatalog = {
    -- MM soft-currency catalog (aktif dan bisa dibeli sekarang).
    {
        id = "eq_sanitypill_standard",
        name = "Sanity Pill (Standard)",
        price = 300,
        currency = "MM",
        category = "Equipment",
        modeAccess = "ClassicOnly",
        rarity = "R1",
        rarityLabel = "R1 B-ajah",
        tags = { "consumable", "sanity" },
    },
    {
        id = "eq_saltbag_reinforced",
        name = "Reinforced Salt Bag",
        price = 650,
        currency = "MM",
        category = "Equipment",
        modeAccess = "ClassicOnly",
        rarity = "R1",
        rarityLabel = "R1 B-ajah",
        tags = { "tool" },
    },
    {
        id = "cos_emote_steadybreath",
        name = "Steady Breath Emote",
        price = 500,
        currency = "MM",
        category = "Cosmetic",
        slot = "emote",
        rarity = "R1",
        rarityLabel = "R1 B-ajah",
        tags = { "emote" },
    },
    {
        id = "cos_accessory_wardingcharm",
        name = "Warding Charm",
        price = 700,
        currency = "MM",
        category = "Cosmetic",
        slot = "accessory",
        rarity = "R1",
        rarityLabel = "R1 B-ajah",
        tags = { "accessory", "charm" },
    },
    {
        id = "cos_head_duskmask",
        name = "Dusk Mask",
        price = 850,
        currency = "MM",
        category = "Cosmetic",
        slot = "head",
        rarity = "R1",
        rarityLabel = "R1 B-ajah",
        tags = { "horror", "mask" },
    },
    {
        id = "eq_sanitypill_advanced",
        name = "Sanity Pill (Advanced)",
        price = 900,
        currency = "MM",
        category = "Equipment",
        modeAccess = "ClassicOnly",
        rarity = "R2",
        rarityLabel = "R2 B-Lebih",
        tags = { "consumable", "sanity" },
    },
    {
        id = "cos_emote_ghostmock",
        name = "Ghost Mock Emote",
        price = 1200,
        currency = "MM",
        category = "Cosmetic",
        slot = "emote",
        rarity = "R2",
        rarityLabel = "R2 B-Lebih",
        tags = { "emote" },
    },
    {
        id = "cos_body_gravetunic",
        name = "Grave Tunic",
        price = 1250,
        currency = "MM",
        category = "Cosmetic",
        slot = "body",
        rarity = "R2",
        rarityLabel = "R2 B-Lebih",
        tags = { "outfit" },
    },
    {
        id = "eq_flashlight_uv",
        name = "UV Flashlight Mk2",
        price = 1500,
        currency = "MM",
        category = "Equipment",
        rarity = "R3",
        rarityLabel = "R3 Lumayan",
        tags = { "tool", "uv" },
    },
    {
        id = "cos_accessory_spiritlantern",
        name = "Spirit Lantern",
        price = 1800,
        currency = "MM",
        category = "Cosmetic",
        slot = "accessory",
        rarity = "R3",
        rarityLabel = "R3 Lumayan",
        tags = { "accessory", "lantern" },
    },
    {
        id = "cos_head_mortisveil",
        name = "Mortis Veil",
        price = 2400,
        currency = "MM",
        category = "Cosmetic",
        slot = "head",
        rarity = "R3",
        rarityLabel = "R3 Lumayan",
        tags = { "horror", "veil" },
    },
    {
        id = "eq_spiritbox_modded",
        name = "Modded Spirit Box",
        price = 2900,
        currency = "MM",
        category = "Equipment",
        modeAccess = "ClassicOnly",
        rarity = "R4",
        rarityLabel = "R4 Langka",
        tags = { "tool", "spiritbox" },
    },
    {
        id = "cos_body_scarletritual",
        name = "Scarlet Ritual Coat",
        price = 3800,
        currency = "MM",
        category = "Cosmetic",
        slot = "body",
        rarity = "R4",
        rarityLabel = "R4 Langka",
        tags = { "outfit", "ritual" },
    },
    {
        id = "cos_outfit_fieldinvestigator",
        name = "Field Investigator Set",
        price = 5100,
        currency = "MM",
        category = "Cosmetic",
        slot = "outfit",
        rarity = "R5",
        rarityLabel = "R5 Gagah",
        tags = { "bundle", "investigator" },
    },
    {
        id = "pp_to_mm_small",
        name = "MM Exchange - Small",
        price = 5,
        currency = "PP",
        category = "CurrencyPack",
        rarity = "R2",
        rarityLabel = "Exchange",
        tags = { "exchange", "mm", "pack" },
        grantItem = false,
        grantCurrency = "MM",
        grantCurrencyAmount = 1500,
    },
    {
        id = "pp_to_mm_medium",
        name = "MM Exchange - Medium",
        price = 12,
        currency = "PP",
        category = "CurrencyPack",
        rarity = "R3",
        rarityLabel = "Exchange",
        tags = { "exchange", "mm", "pack" },
        grantItem = false,
        grantCurrency = "MM",
        grantCurrencyAmount = 4200,
    },
    {
        id = "pp_to_mm_large",
        name = "MM Exchange - Large",
        price = 24,
        currency = "PP",
        category = "CurrencyPack",
        rarity = "R4",
        rarityLabel = "Exchange",
        tags = { "exchange", "mm", "pack" },
        grantItem = false,
        grantCurrency = "MM",
        grantCurrencyAmount = 9600,
    },

    -- PP prestige catalog (soft-currency, non-Robux).
    {
        id = "pp_cos_head_nightoracle",
        name = "Night Oracle Hood",
        price = 12,
        currency = "PP",
        category = "Cosmetic",
        slot = "head",
        rarity = "R4",
        rarityLabel = "R4 Prestige",
        tags = { "prestige", "horror" },
    },
    {
        id = "pp_cos_body_voidpriest",
        name = "Void Priest Robe",
        price = 18,
        currency = "PP",
        category = "Cosmetic",
        slot = "body",
        rarity = "R4",
        rarityLabel = "R4 Prestige",
        tags = { "prestige", "outfit" },
    },
    {
        id = "pp_eq_spiritbox_elite",
        name = "Spirit Box Elite",
        price = 25,
        currency = "PP",
        category = "Equipment",
        modeAccess = "ClassicOnly",
        rarity = "R5",
        rarityLabel = "R5 Prestige",
        tags = { "prestige", "tool", "spiritbox" },
    },
    {
        id = "pp_cos_outfit_royalwarden",
        name = "Royal Warden Outfit",
        price = 40,
        currency = "PP",
        category = "Cosmetic",
        slot = "outfit",
        rarity = "R5",
        rarityLabel = "R5 Prestige",
        tags = { "prestige", "bundle" },
    },

    -- Robux catalog (bridge siap, aktifkan setelah marketplaceId diisi).
    {
        id = "royalpass_premium_track",
        name = "Royal Pass Premium Track",
        price = 149,
        currency = "Robux",
        category = "Entitlement",
        slot = "pass",
        rarity = "R5",
        rarityLabel = "Premium",
        tags = { "pass", "premium" },
        marketplaceType = "GamePass",
        marketplaceId = 0,
        royalPassPremium = true,
        grantItem = false,
        enabled = false,
        setupHint = "Isi marketplaceId Creator Hub agar item aktif.",
    },
    {
        id = "class_dukun_unlock",
        name = "Dukun Class Unlock",
        price = 89,
        currency = "Robux",
        category = "Entitlement",
        slot = "class",
        rarity = "R4",
        rarityLabel = "Class Unlock",
        tags = { "class", "dukun" },
        marketplaceType = "GamePass",
        marketplaceId = 0,
        entitlementKey = "RoyalPass_Dukun",
        grantItem = false,
        enabled = false,
        setupHint = "Tahan dulu. Unlock class Robux belum boleh aktif sampai kelas terbukti cosmetic-only dan tidak memengaruhi fairness Ranked.",
    },
    {
        id = "class_detective_unlock",
        name = "Detective Class Unlock",
        price = 89,
        currency = "Robux",
        category = "Entitlement",
        slot = "class",
        rarity = "R4",
        rarityLabel = "Class Unlock",
        tags = { "class", "detective" },
        marketplaceType = "GamePass",
        marketplaceId = 0,
        entitlementKey = "RoyalPass_Detective",
        grantItem = false,
        enabled = false,
        setupHint = "Tahan dulu. Unlock class Robux belum boleh aktif sampai kelas terbukti cosmetic-only dan tidak memengaruhi fairness Ranked.",
    },
    {
        id = "lifetime_bonus_pass",
        name = "Lifetime Bonus Pass",
        price = 249,
        currency = "Robux",
        category = "Entitlement",
        slot = "pass",
        rarity = "R5",
        rarityLabel = "Lifetime",
        tags = { "pass", "lifetime" },
        marketplaceType = "GamePass",
        marketplaceId = 0,
        entitlementKey = "LifetimePass",
        grantItem = false,
        enabled = false,
        setupHint = "Tahan dulu. Lifetime pass belum boleh aktif sampai efeknya cosmetic-only dan tidak memberi bonus ekonomi/gameplay.",
    },
    {
        id = "pp_pack_small",
        name = "PP Pack - Small",
        price = 29,
        currency = "Robux",
        category = "CurrencyPack",
        rarity = "R2",
        rarityLabel = "Top Up",
        tags = { "currency", "pp", "pack" },
        marketplaceType = "DeveloperProduct",
        marketplaceId = 0,
        grantItem = false,
        grantCurrency = "PP",
        grantCurrencyAmount = 10,
        enabled = false,
        setupHint = "Isi marketplaceId Creator Hub agar item aktif.",
    },
    {
        id = "mm_pack_small",
        name = "MM Pack - Small",
        price = 19,
        currency = "Robux",
        category = "CurrencyPack",
        rarity = "R1",
        rarityLabel = "Top Up",
        tags = { "currency", "mm", "pack" },
        marketplaceType = "DeveloperProduct",
        marketplaceId = 0,
        grantItem = false,
        grantCurrency = "MM",
        grantCurrencyAmount = 2500,
        enabled = false,
        setupHint = "Isi marketplaceId Creator Hub agar item aktif.",
    },
    {
        id = "mm_pack_medium",
        name = "MM Pack - Medium",
        price = 49,
        currency = "Robux",
        category = "CurrencyPack",
        rarity = "R2",
        rarityLabel = "Top Up",
        tags = { "currency", "mm", "pack" },
        marketplaceType = "DeveloperProduct",
        marketplaceId = 0,
        grantItem = false,
        grantCurrency = "MM",
        grantCurrencyAmount = 8000,
        enabled = false,
        setupHint = "Isi marketplaceId Creator Hub agar item aktif.",
    },
    {
        id = "mm_pack_large",
        name = "MM Pack - Large",
        price = 99,
        currency = "Robux",
        category = "CurrencyPack",
        rarity = "R3",
        rarityLabel = "Top Up",
        tags = { "currency", "mm", "pack" },
        marketplaceType = "DeveloperProduct",
        marketplaceId = 0,
        grantItem = false,
        grantCurrency = "MM",
        grantCurrencyAmount = 18000,
        enabled = false,
        setupHint = "Isi marketplaceId Creator Hub agar item aktif.",
    },
    {
        id = "pp_pack_standard",
        name = "PP Pack - Standard",
        price = 79,
        currency = "Robux",
        category = "CurrencyPack",
        rarity = "R3",
        rarityLabel = "Top Up",
        tags = { "currency", "pp", "pack" },
        marketplaceType = "DeveloperProduct",
        marketplaceId = 0,
        grantItem = false,
        grantCurrency = "PP",
        grantCurrencyAmount = 25,
        enabled = false,
        setupHint = "Isi marketplaceId Creator Hub agar item aktif.",
    },
    {
        id = "pp_pack_large",
        name = "PP Pack - Large",
        price = 149,
        currency = "Robux",
        category = "CurrencyPack",
        rarity = "R4",
        rarityLabel = "Top Up",
        tags = { "currency", "pp", "pack" },
        marketplaceType = "DeveloperProduct",
        marketplaceId = 0,
        grantItem = false,
        grantCurrency = "PP",
        grantCurrencyAmount = 55,
        enabled = false,
        setupHint = "Isi marketplaceId Creator Hub agar item aktif.",
    },
}

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function applyMarketplaceConfig(catalog)
    local configModule = script.Parent:FindFirstChild("ShopMarketplaceConfig")
    local config = safeRequire(configModule)
    if type(config) ~= "table" then
        return
    end

    local catalogById = {}
    for _, entry in ipairs(catalog) do
        if type(entry) == "table" and type(entry.id) == "string" and entry.id ~= "" then
            catalogById[entry.id] = entry
        end
    end

    local itemOverrides = type(config.items) == "table" and config.items or {}
    for itemId, override in pairs(itemOverrides) do
        local item = catalogById[itemId]
        if item and type(override) == "table" then
            if override.price ~= nil then
                local parsedPrice = tonumber(override.price)
                if parsedPrice and parsedPrice > 0 then
                    item.price = math.floor(parsedPrice)
                end
            end
            if override.marketplaceId ~= nil then
                item.marketplaceId = tonumber(override.marketplaceId) or 0
            end
            if override.marketplaceType ~= nil then
                item.marketplaceType = override.marketplaceType
            end
            if override.enabled ~= nil then
                item.enabled = override.enabled == true
            end
        end
    end

    local autoEnable = config.autoEnableWhenIdPresent == true
    if autoEnable then
        for _, item in ipairs(catalog) do
            if tostring(item.currency or "MM") == "Robux" then
                local id = tonumber(item.marketplaceId) or 0
                if id > 0 then
                    item.enabled = true
                end
            end
        end
    end
end

applyMarketplaceConfig(ShopCatalog)

return ShopCatalog
