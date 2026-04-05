# Creator Hub Marketplace Mapping 2026-04-06

## Tujuan

Dokumen ini memecah lane `Creator Hub marketplaceId` menjadi daftar item yang eksplisit. Gunakan ini saat membuat `GamePass` dan `DeveloperProduct` di Creator Hub, lalu isi ID resminya ke:

- `src/shared/DataTypes/ShopMarketplaceConfig.lua`

Jangan isi placeholder dengan `UserId`. Catatan lama untuk `10576163165` tetap berlaku: itu tampak seperti `UserId/account id`, bukan `GamePassId/ProductId`.

## Safe To Create And Enable Now

Item di bawah ini sudah selaras dengan guard fairness saat ini karena hanya memberi currency in-game:

| itemId | Creator Hub Type | Price | Grant | Status |
| --- | --- | ---: | --- | --- |
| `pp_pack_small` | `DeveloperProduct` | `29` | `PP +10` | boleh aktif setelah ID resmi diisi |
| `pp_pack_standard` | `DeveloperProduct` | `79` | `PP +25` | boleh aktif setelah ID resmi diisi |
| `pp_pack_large` | `DeveloperProduct` | `149` | `PP +55` | boleh aktif setelah ID resmi diisi |
| `mm_pack_small` | `DeveloperProduct` | `19` | `MM +2500` | boleh aktif setelah ID resmi diisi |
| `mm_pack_medium` | `DeveloperProduct` | `49` | `MM +8000` | boleh aktif setelah ID resmi diisi |
| `mm_pack_large` | `DeveloperProduct` | `99` | `MM +18000` | boleh aktif setelah ID resmi diisi |

## Create But Keep Disabled

Item di bawah ini sudah punya bridge code, tetapi belum boleh diaktifkan untuk publish sampai desainnya benar-benar lolos fairness/compliance review:

| itemId | Creator Hub Type | Price | Alasan tetap disabled |
| --- | --- | ---: | --- |
| `royalpass_premium_track` | `GamePass` | `149` | hanya boleh aktif jika premium track tetap cosmetic/progression-safe |
| `class_dukun_unlock` | `GamePass` | `89` | jangan aktif sampai class terbukti cosmetic-only dan tidak memengaruhi `Ranked` |
| `class_detective_unlock` | `GamePass` | `89` | jangan aktif sampai class terbukti cosmetic-only dan tidak memengaruhi `Ranked` |
| `lifetime_bonus_pass` | `GamePass` | `249` | jangan aktif sampai tidak memberi bonus ekonomi/gameplay |

## File Yang Harus Diisi

Isi hanya di:

- `src/shared/DataTypes/ShopMarketplaceConfig.lua`

Contoh bentuk yang benar:

```lua
pp_pack_small = {
    marketplaceId = 1234567890,
    enabled = true,
},
```

Untuk item yang harus tetap mati:

```lua
royalpass_premium_track = {
    marketplaceId = 1234567890,
    enabled = false,
},
```

## Urutan Eksekusi

1. Buat 6 `DeveloperProduct` currency pack di Creator Hub.
2. Salin `ProductId` resmi ke `ShopMarketplaceConfig.lua`.
3. Biarkan `autoEnableWhenIdPresent = true`.
4. Pastikan `enabled = true` hanya untuk 6 currency pack di atas.
5. Jangan aktifkan 4 `GamePass` yang masih ditahan.
6. Jalankan ulang:
   - `GetShopReadiness`
   - `GetPublishReadiness`
7. Opsional dari terminal lokal:
   - `pwsh ./scripts/audit-marketplace-mapping.ps1`

## PASS Criteria

- `GetShopReadiness` tidak lagi menunjukkan `robuxMissingId` untuk item yang visible
- `GetPublishReadiness` tidak gagal karena commerce mapping
- tab `R$` hanya menampilkan offer yang memang sudah resmi dan boleh aktif

## Referensi Source

- `src/shared/DataTypes/ShopCatalog.lua`
- `src/shared/DataTypes/ShopMarketplaceConfig.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/FINAL_RELEASE_CHECKLIST_2026-04-06.md`
