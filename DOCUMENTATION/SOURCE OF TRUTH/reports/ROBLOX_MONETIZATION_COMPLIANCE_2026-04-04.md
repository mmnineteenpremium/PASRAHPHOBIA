# Roblox Monetization Compliance - 2026-04-04

## Prinsip Prioritas

- untuk semua implementasi `Robux`, acuan utama adalah aturan dan dokumentasi resmi Roblox
- jika ada konflik antara `SOURCE OF TRUTH` dan aturan Roblox, yang dipakai adalah aturan Roblox
- item `Robux` tidak boleh diaktifkan hanya karena UI sudah siap; harus lolos klasifikasi dan setup marketplace resmi

## Klasifikasi Aman

### GamePass

- dipakai untuk unlock/entitlement permanen
- cocok untuk:
  - `royalpass_premium_track`
  - `class_dukun_unlock`
  - `class_detective_unlock`
  - `lifetime_bonus_pass`

### DeveloperProduct

- dipakai untuk pembelian berulang / consumable
- cocok untuk:
  - `pp_pack_small`
  - `pp_pack_standard`
  - `pp_pack_large`
  - `mm_pack_small`
  - `mm_pack_medium`
  - `mm_pack_large`

## Guard yang Sudah Dipasang di Source

- item `Robux` otomatis `disabled` jika:
  - `marketplaceType` bukan `GamePass` atau `DeveloperProduct`
  - `marketplaceId <= 0`
- item `GamePass` otomatis `disabled` jika disalahgunakan untuk `CurrencyPack`
- item `DeveloperProduct` otomatis `disabled` jika dipakai untuk entitlement permanen
- item `DeveloperProduct` `CurrencyPack` otomatis `disabled` jika `grantCurrency/grantCurrencyAmount` belum valid
- UI shop sekarang menjelaskan bahwa status `SETUP` berarti item belum compliant atau belum selesai diset di Creator Hub

## Setup Checklist Sebelum Enable Robux

1. Buat asset marketplace di Creator Hub dengan tipe yang benar.
2. Isi `marketplaceId` ke `src/shared/DataTypes/ShopMarketplaceConfig.lua`.
3. Jangan ubah `marketplaceType` sembarangan.
4. Untuk `DeveloperProduct`, pastikan grant bersifat repeatable dan diproses lewat `ProcessReceipt`.
5. Untuk `GamePass`, pastikan grant adalah unlock permanen, bukan top-up currency berulang.
6. Jalankan test Studio setelah ID diisi:
   - prompt terbuka
   - callback kembali ke server
   - snapshot client ikut update
   - grant tidak dobel

## Risiko Yang Harus Dihindari

- `GamePass` dipakai untuk currency pack
- `DeveloperProduct` dipakai untuk unlock permanen
- item `Robux` aktif tanpa `marketplaceId`
- grant currency/entitlement dilakukan di client
- `ProcessReceipt` tidak idempotent

## Status Saat File Ini Ditulis

- flow soft currency `MM/PP` aman dan terpisah dari flow `Robux`
- flow `Robux` belum diaktifkan untuk produksi karena `marketplaceId` masih `0`
- source sudah diberi guard compliance agar salah setup tidak langsung bocor ke pembelian live

## Update 2026-04-04 - In-Game Currency Boundary

- `PP` diperlakukan sebagai currency in-game, bukan entitlement lintas game
- `MM` tetap currency in-game dan sekarang boleh dibeli lewat:
  - `Robux -> MM` melalui `DeveloperProduct`
  - `PP -> MM` melalui exchange soft-currency di experience yang sama
- `PP` sekarang punya beberapa paket `Robux`:
  - `pp_pack_small`
  - `pp_pack_standard`
  - `pp_pack_large`
- exchange `PP -> MM` tetap lokal ke experience ini:
  - `pp_to_mm_small`
  - `pp_to_mm_medium`
  - `pp_to_mm_large`
- tidak ada jalur source yang memperlakukan `PP` sebagai mata uang lintas experience

## Update 2026-04-04 - Ranked Fairness Guard

- item bantuan kemenangan sekarang diberi `modeAccess = ClassicOnly` di katalog shop:
  - `eq_sanitypill_standard`
  - `eq_sanitypill_advanced`
  - `eq_saltbag_reinforced`
  - `eq_spiritbox_modded`
  - `pp_eq_spiritbox_elite`
- `MatchMode` sekarang di-set server-authoritative saat match mulai
- jika `MatchMode == Ranked`, helper item di atas dineutralisasi pada jalur runtime:
  - bonus stok `Garam` tidak aktif
  - buff `Spirit Box` tidak aktif
  - `Sanity Pill` helper tidak aktif
- ini menjaga Ranked tetap fair; pembelian `Robux/MM/PP` tidak boleh memberi keunggulan kemenangan di Ranked

## Update 2026-04-04 - Royal Pass Premium Safety

- `royalpass_premium_track` tetap ditahan `disabled`
- bonus currency premium khusus dari `RoyalPassSystem` sudah dimatikan di source
- artinya jika premium track nanti diaktifkan, jalurnya harus tetap:
  - cosmetic
  - visual
  - progression-safe
- premium track tidak boleh menambah currency ekstra hanya karena player membayar `Robux`

## Update 2026-04-04 - Validation Snapshot

- build source sukses:
  - `_tmp_shop_ranked_fairness_build.rbxlx`
  - `_tmp_robux_pp_ranked_guard_build.rbxlx`
- validasi live Studio yang berhasil:
  - `GrantMarketplacePurchase(pp_pack_small)` menambah `PP +10`
  - `GrantMarketplacePurchase(mm_pack_small)` menambah `MM +2500`
  - `PurchaseItem(pp_to_mm_medium)` sukses mengubah wallet `PP -12` dan `MM +4200`
- validasi fairness yang sudah terbukti pada sesi live sebelumnya:
  - `Ranked`: `Garam` tetap base stock (`usesRemaining = 2` setelah 1 pakai)
  - `Classic`: `Garam` mendapat bonus reinforced (`usesRemaining = 3` setelah 1 pakai)
- validasi live lanjutan di sesi ini sempat terganggu oleh drift runtime ghost Studio, bukan oleh jalur monetization

## Update 2026-04-04 - Cosmetic Purchase And Equip Smoke Test

- smoke test live Studio berhasil untuk jalur cosmetic non-`Robux`:
  - grant wallet:
    - `MM +5000`
    - `PP +60`
  - pembelian:
    - `cos_accessory_wardingcharm`
    - `pp_cos_head_nightoracle`
  - equip:
    - slot `accessory`
    - slot `head`
  - unequip:
    - slot `accessory`
    - slot `head`
- bukti live:
  - `PurchaseProcessed success=true` untuk kedua cosmetic
  - `CosmeticRequestProcessed success=true` untuk equip dan unequip
  - `CosmeticSnapshot` menunjukkan:
    - `equippedCount = 2` setelah equip
    - `equippedCount = 0` setelah unequip
  - visual lobby ikut terpasang saat equip:
    - `Workspace.ZyraaaVex.LobbyCosmeticVisuals`
    - `AccessoryVisual = true`
    - `HeadVisual = true`
    - `LobbyCosmeticBillboard = true`
- interpretasi:
  - jalur cosmetic saat ini sudah aman sebagai monetization non-pay-to-win
  - pembelian cosmetic terbukti hanya memengaruhi presentasi lobby/wardrobe, bukan helper gameplay

## Update 2026-04-04 - Placeholder Entitlements Must Stay Disabled

- audit source saat ini menunjukkan `class_dukun_unlock`, `class_detective_unlock`, dan `lifetime_bonus_pass` masih berada di status placeholder aman:
  - ada di `ShopCatalog` dan `ShopMarketplaceConfig`
  - ada state entitlement di `EconomySystem`
  - belum ditemukan hook gameplay/class runtime yang sah untuk diaktifkan ke player live
- konsekuensi implementasi:
  - jangan isi `marketplaceId` production untuk item ini dulu
  - jangan set `enabled = true`
  - jangan pakai item ini sebagai alasan memberi:
    - buff investigasi
    - bonus reward
    - helper Ranked
    - unlock kelas yang memengaruhi kemenangan
- jika nanti class system benar-benar dibuat, syarat minimumnya:
  - cosmetic-only atau presentation-only untuk Ranked
  - tidak memberi keunggulan investigasi/hunt/economy
  - lolos review ulang compliance Roblox sebelum GamePass diaktifkan

## Note Terakhir

- `10576163165` tampak seperti `UserId/account id`, bukan `GamePassId/ProductId` Creator Hub yang terverifikasi. Jangan dipakai sebagai `marketplaceId` production sampai ID marketplace resmi benar-benar dibuat di Creator Hub.
