local ShopMarketplaceConfig = {
    -- NOTE 2026-04-04:
    -- `10576163165` tampak seperti UserId/account id, bukan marketplace asset id Creator Hub.
    -- Jangan dipakai sebagai marketplaceId production sampai ada GamePass/Product ID yang benar-benar terverifikasi.
    -- Jika true: item Robux otomatis enabled saat marketplaceId > 0.
    -- Tetap isi sesuai jenis resmi Roblox:
    -- GamePass -> entitlement/unlock permanen
    -- DeveloperProduct -> pembelian berulang seperti currency pack
    autoEnableWhenIdPresent = true,
    items = {
        -- GamePass
        royalpass_premium_track = {
            marketplaceId = 3573231558,
            enabled = false,
        },
        class_dukun_unlock = {
            marketplaceId = 3573231828,
            enabled = false,
        },
        class_detective_unlock = {
            marketplaceId = 3573232123,
            enabled = false,
        },
        lifetime_bonus_pass = {
            marketplaceId = 3573232383,
            enabled = false,
        },

        -- DeveloperProduct
        pp_pack_small = {
            marketplaceId = 3573224039,
            enabled = true,
        },
        mm_pack_small = {
            marketplaceId = 3573226842,
            enabled = true,
        },
        mm_pack_medium = {
            marketplaceId = 3573227690,
            enabled = true,
        },
        mm_pack_large = {
            marketplaceId = 3573228070,
            enabled = true,
        },
        pp_pack_standard = {
            marketplaceId = 3573225850,
            enabled = true,
        },
        pp_pack_large = {
            marketplaceId = 3573226462,
            enabled = true,
        },
    },
}

return ShopMarketplaceConfig
