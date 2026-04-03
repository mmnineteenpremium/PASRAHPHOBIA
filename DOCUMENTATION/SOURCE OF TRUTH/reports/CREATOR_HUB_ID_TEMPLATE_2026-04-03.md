# Creator Hub ID Template 2026-04-03

## Tujuan

Template ini dipakai untuk menutup blocker manual pada bridge monetization Roblox yang sudah terpasang di code.

Isi file ini dengan ID nyata dari Creator Hub / Dashboard sebelum item `Robux` diaktifkan di katalog.

## Cara Pakai

1. Buat asset di Creator Hub:
   - game pass untuk entitlement permanen
   - developer product untuk pembelian berulang
2. Tempel ID-nya ke tabel di bawah.
3. Setelah ID nyata siap, mirror ke source katalog item yang akan dijual.
4. Jalankan smoke test lagi:
   - prompt muncul
   - grant server-side terjadi
   - entitlement / reward benar-benar tersimpan

## Template

| Purpose | Suggested Item Id | Marketplace Type | Creator Hub ID | Entitlement / Reward | Status |
| --- | --- | --- | --- | --- | --- |
| Premium Royal Pass track | `royalpass_premium_track` | `GamePass` | `TODO` | `royalPassPremium = true` | blocked |
| Dukun class unlock | `class_dukun_unlock` | `GamePass` | `TODO` | `entitlementKey = RoyalPass_Dukun` | blocked |
| Detective class unlock | `class_detective_unlock` | `GamePass` | `TODO` | `entitlementKey = RoyalPass_Detective` | blocked |
| Lifetime bonus pass | `lifetime_bonus_pass` | `GamePass` | `TODO` | `entitlementKey = LifetimePass` | blocked |
| Small MM pack | `mm_pack_small` | `DeveloperProduct` | `TODO` | `grantCurrency = MM` | blocked |
| Medium MM pack | `mm_pack_medium` | `DeveloperProduct` | `TODO` | `grantCurrency = MM` | blocked |
| Large MM pack | `mm_pack_large` | `DeveloperProduct` | `TODO` | `grantCurrency = MM` | blocked |
| PP pack | `pp_pack_standard` | `DeveloperProduct` | `TODO` | `grantCurrency = PP` | blocked |

## Minimum Rules

1. Jangan pakai satu ID Roblox untuk dua reward berbeda.
2. Semua entitlement permanen sebaiknya pakai `GamePass`.
3. Semua pembelian berulang sebaiknya pakai `DeveloperProduct`.
4. Jangan aktifkan item `Robux` di UI production sebelum ID nyata masuk ke source.
5. Setelah ID masuk, uji:
   - cancel prompt
   - purchase sukses
   - relog ownership sync untuk game pass
   - duplicate receipt safety untuk developer product

## Catatan Integrasi

Bridge code-side yang sudah siap hari ini:

- server `ShopSystem.Controller`:
  - `PromptGamePassPurchaseFinished`
  - `ProcessReceipt`
  - `UserOwnsGamePassAsync`
- server `ShopSystem.Service`:
  - `ResolvePurchaseIntent()`
  - `GrantMarketplacePurchase()`
- client `UISystem`:
  - `PurchasePromptRequested`
  - prompt Roblox dari `MarketplaceService`

Artinya blocker saat ini bukan lagi arsitektur pembelian, tetapi `ID nyata` dan `mapping item` yang belum diisi.
