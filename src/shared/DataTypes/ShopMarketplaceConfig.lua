local ShopMarketplaceConfig = {
    -- Jika true: item Robux otomatis enabled saat marketplaceId > 0.
    -- Tetap isi sesuai jenis resmi Roblox:
    -- GamePass -> entitlement/unlock permanen
    -- DeveloperProduct -> pembelian berulang seperti currency pack
    autoEnableWhenIdPresent = true,
    items = {
        -- GamePass
        royalpass_premium_track = {
            marketplaceId = 0,
            enabled = false,
        },
        class_dukun_unlock = {
            marketplaceId = 0,
            enabled = false,
        },
        class_detective_unlock = {
            marketplaceId = 0,
            enabled = false,
        },
        lifetime_bonus_pass = {
            marketplaceId = 0,
            enabled = false,
        },

        -- DeveloperProduct
        mm_pack_small = {
            marketplaceId = 0,
            enabled = false,
        },
        mm_pack_medium = {
            marketplaceId = 0,
            enabled = false,
        },
        mm_pack_large = {
            marketplaceId = 0,
            enabled = false,
        },
        pp_pack_standard = {
            marketplaceId = 0,
            enabled = false,
        },
    },
}

return ShopMarketplaceConfig
