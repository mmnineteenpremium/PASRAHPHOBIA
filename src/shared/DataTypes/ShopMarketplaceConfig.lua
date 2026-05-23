local function loadAssetIdConfig()
    local sharedRoot = script.Parent and script.Parent.Parent
    local configFolder = sharedRoot and sharedRoot:FindFirstChild("Config")
    local generatedFolder = configFolder and configFolder:FindFirstChild("Generated")
    local moduleScript = generatedFolder and generatedFolder:FindFirstChild("AssetIdConfig")
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok and type(result) == "table" then
        return result
    end
    return nil
end

local AssetIdConfig = loadAssetIdConfig()
local DeveloperProducts = AssetIdConfig
    and AssetIdConfig.Monetization
    and AssetIdConfig.Monetization.DeveloperProducts
    or {}
local GamePasses = AssetIdConfig
    and AssetIdConfig.Monetization
    and AssetIdConfig.Monetization.GamePasses
    or {}

local function developerProductId(key, fallback)
    return tonumber(DeveloperProducts[key]) or fallback
end

local function gamePassId(key, fallback)
    return tonumber(GamePasses[key]) or fallback
end

local ShopMarketplaceConfig = {
    -- NOTE 2026-04-04:
    -- `10576163165` tampak seperti UserId/account id, bukan marketplace asset id Creator Hub.
    -- Jangan dipakai sebagai marketplaceId production sampai ada GamePass/Product ID yang benar-benar terverifikasi.
    -- Brian lane marketplace IDs created 2026-05-20 for universe 10138560838 / owner briankotak.
    -- Keep this false so entitlement GamePass hold items stay disabled even when their official IDs exist.
    -- If true: item Robux otomatis enabled saat marketplaceId > 0.
    -- Tetap isi sesuai jenis resmi Roblox:
    -- GamePass -> entitlement/unlock permanen
    -- DeveloperProduct -> pembelian berulang seperti currency pack
    autoEnableWhenIdPresent = false,
    items = {
        -- GamePass
        royalpass_premium_track = {
            marketplaceId = gamePassId("royalpass_premium_track", 1846924611),
            enabled = false,
        },
        class_dukun_unlock = {
            marketplaceId = gamePassId("class_dukun_unlock", 1847326612),
            enabled = false,
        },
        class_detective_unlock = {
            marketplaceId = gamePassId("class_detective_unlock", 1846726626),
            enabled = false,
        },
        lifetime_bonus_pass = {
            marketplaceId = gamePassId("lifetime_bonus_pass", 1846342643),
            enabled = false,
        },

        -- DeveloperProduct
        pp_pack_small = {
            marketplaceId = developerProductId("pp_pack_small", 3595563338),
            enabled = true,
        },
        mm_pack_small = {
            marketplaceId = developerProductId("mm_pack_small", 3595563373),
            enabled = true,
        },
        mm_pack_medium = {
            marketplaceId = developerProductId("mm_pack_medium", 3595563381),
            enabled = true,
        },
        mm_pack_large = {
            marketplaceId = developerProductId("mm_pack_large", 3595563400),
            enabled = true,
        },
        pp_pack_standard = {
            marketplaceId = developerProductId("pp_pack_standard", 3595563345),
            enabled = true,
        },
        pp_pack_large = {
            marketplaceId = developerProductId("pp_pack_large", 3595563353),
            enabled = true,
        },
    },
}

return ShopMarketplaceConfig
