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
  - `mm_pack_small`
  - `mm_pack_medium`
  - `mm_pack_large`
  - `pp_pack_standard`

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
