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
            marketplaceId = 1846924611,
            enabled = false,
        },
        class_dukun_unlock = {
            marketplaceId = 1847326612,
            enabled = false,
        },
        class_detective_unlock = {
            marketplaceId = 1846726626,
            enabled = false,
        },
        lifetime_bonus_pass = {
            marketplaceId = 1846342643,
            enabled = false,
        },

        -- DeveloperProduct
        pp_pack_small = {
            marketplaceId = 3595563338,
            enabled = true,
        },
        mm_pack_small = {
            marketplaceId = 3595563373,
            enabled = true,
        },
        mm_pack_medium = {
            marketplaceId = 3595563381,
            enabled = true,
        },
        mm_pack_large = {
            marketplaceId = 3595563400,
            enabled = true,
        },
        pp_pack_standard = {
            marketplaceId = 3595563345,
            enabled = true,
        },
        pp_pack_large = {
            marketplaceId = 3595563353,
            enabled = true,
        },
    },
}

return ShopMarketplaceConfig
