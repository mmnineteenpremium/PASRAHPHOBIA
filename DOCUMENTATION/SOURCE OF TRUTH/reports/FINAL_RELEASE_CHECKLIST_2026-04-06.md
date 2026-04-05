# Final Release Checklist 2026-04-06

## Tujuan

Checklist ini adalah jalur terakhir sebelum publish. Gunakan dokumen ini sebagai urutan eksekusi praktis, bukan sekadar referensi.

## Stage 1 - Gate Otomatis

Jalankan lewat harness Studio / assistant:

1. `GetQAGateSnapshot`
2. `GetQAGateReadiness`
3. `GetPublishReadiness`
4. `GetShopReadiness`
5. `GetPersistenceMode`

## PASS Jika

- `GetQAGateReadiness` memberi `overall=pass_with_manual_multiplayer`
- `GetPublishReadiness` minimal tidak gagal karena warning/error/fps/memory
- `GetShopReadiness` tidak menunjukkan item Robux visible yang masih `robuxMissingId > 0`
- `GetPersistenceMode` tidak ambigu saat sudah masuk environment target

## Stage 2 - Creator Hub Mapping

1. isi `GamePassId / ProductId` resmi ke:
   - `src/shared/DataTypes/ShopMarketplaceConfig.lua`
   - `CREATOR_HUB_MARKETPLACE_MAPPING_2026-04-06.md`
2. jangan isi placeholder dengan `UserId`
3. setelah diisi, cek ulang:
   - `GetShopReadiness`
   - `GetPublishReadiness`

## Stage 3 - Multiplayer Smoke

Ikuti:

- `QA_MULTIPLAYER_MANUAL_CHECKLIST_2026-04-06.md`
- `QA_MULTIPLAYER_RESULT_TEMPLATE_2026-04-06.md`

Hasil akhir yang dicatat:

- `PASS`
- `FAIL`
- `BLOCKED`

## Stage 4 - Persistence Target

Ikuti:

- `PERSISTENCE_MANUAL_CHECKLIST_2026-04-06.md`
- `PERSISTENCE_RESULT_TEMPLATE_2026-04-06.md`

Hasil akhir yang dicatat:

- `PASS`
- `FAIL`
- `BLOCKED`

## Stage 5 - Legal / Licensing

1. cek attribution dan lisensi asset eksternal
2. pastikan ledger lisensi masih akurat
3. pastikan asset komersial abu-abu tidak ikut publish

Referensi file:

- `ASSET_LICENSE_LEDGER_2026-04-03.md`
- `POCONG_LICENSE_ARCHIVE_CHECKLIST_2026-04-04.md`

## Stage 6 - Final Go / No-Go

### GO

- Creator Hub ID resmi sudah terisi
- multiplayer smoke `PASS`
- persistence target `PASS`
- legal review `PASS`
- gate otomatis tidak menunjukkan blocker teknis baru

### NO-GO

- salah satu dari empat lane di atas gagal
- ada warning/error blocker baru di runtime
- ada monetization mapping yang belum resmi

## Catatan Eksekusi

- jangan publish hanya karena build hijau
- jangan aktifkan offer Robux yang belum punya ID resmi
- jangan menilai persistence siap dari Studio mock
- jika satu gate manual `BLOCKED`, status publish tetap `NO-GO`
