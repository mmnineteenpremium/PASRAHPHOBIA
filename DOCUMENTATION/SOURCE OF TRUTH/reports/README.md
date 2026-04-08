# Reports README

## Tujuan

Folder ini adalah paket laporan operasional yang disusun dari:

- pembacaan dokumen internal proyek
- pemindaian source code yang aktif
- inspeksi Studio live melalui MCP
- playtest log dari runtime yang sedang berjalan

Folder ini dibuat untuk menggantikan pembacaan dokumen yang tersebar dan saling tertinggal. Fokusnya bukan sejarah ide, tetapi status aktual proyek pada `2026-04-03`.

## Hierarki Kebenaran

Urutan pegangan kerja untuk project ini adalah:

1. source code aktif di `src` + state Studio live yang sedang terbuka
2. `DOCUMENTATION/SOURCE OF TRUTH/REPORTS.md`
3. `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
4. `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
5. dokumen lain di `DOCUMENTATION/`

Catatan penting:

- `PASRAHPHOBIA_DOC_INDEX.md` berguna sebagai indeks sejarah, bukan sumber kebenaran runtime.
- dokumen di `DOCUMENTATION/Asset Import Guide/reports` berguna sebagai alarm gap asset, tetapi beberapa detail flow sudah stale terhadap kode aktif.
- dokumen pihak ketiga di `Packages/` dan dokumen subproject seperti `Codex-Switcher-Web/` tidak dipakai sebagai landasan gameplay.

## Cara Pakai

- Jalankan `pwsh ./scripts/release-preflight.ps1` jika ingin satu ringkasan lokal cepat sebelum masuk lane publish manual.
- Baca `REALITY_SCAN_2026-04-03.md` dulu untuk status aktual proyek.
- Baca `DUPLICATION_AND_RUNTIME_DRIFT_2026-04-03.md` untuk blocker struktural dan prioritas perbaikan.
- Baca `E2E_TO_PUBLISH_BACKLOG_2026-04-03.md` untuk daftar pekerjaan yang belum selesai.
- Baca `E2E_TEST_MATRIX_2026-04-03.md` untuk panduan uji end-to-end di Studio.
- Baca `FULL_EXECUTION_ROADMAP_2026-04-03.md` sebagai peta kerja utama sampai siap publish.
- Baca `ASSET_LICENSE_LEDGER_2026-04-03.md` untuk status ownership/licensing asset aktif yang benar-benar terlihat di source.
- Baca `AUDIO_REPLACEMENT_PLAN_2026-04-03.md` untuk slot audio kosong yang masih perlu diganti dan jalur apply setelah upload asset.
- Baca `ROBLOX_CLOUD_PLACE_IDENTITY_2026-04-08.md` untuk identity `PlaceId/GameId` cloud yang canonical saat task membutuhkan context akun Roblox, inventory Toolbox, atau asset upload private.
- Baca `CREATOR_HUB_ID_TEMPLATE_2026-04-03.md` untuk blocker manual yang masih diperlukan agar bridge monetization bisa ditutup end-to-end.
- Baca `EXECUTION_LOG.md` untuk progres task yang sudah dikerjakan selama fase eksekusi.
- Baca `PUBLISH_REVIEW_FINAL_2026-04-06.md` untuk status publish saat ini.
- Baca `FINAL_RELEASE_CHECKLIST_2026-04-06.md` untuk urutan final sebelum publish.
- Baca `CREATOR_HUB_MARKETPLACE_MAPPING_2026-04-06.md` untuk daftar item Robux yang aman diaktifkan dan item yang harus tetap disabled.
- Baca `QA_MULTIPLAYER_MANUAL_CHECKLIST_2026-04-06.md` dan `PERSISTENCE_MANUAL_CHECKLIST_2026-04-06.md` untuk gate manual terakhir.
- Baca `QA_MULTIPLAYER_RESULT_TEMPLATE_2026-04-06.md` dan `PERSISTENCE_RESULT_TEMPLATE_2026-04-06.md` untuk mencatat hasil run manual terakhir.
- Baca `VISUAL_RUNTIME_VERIFICATION_2026-04-06.md` untuk bukti visual live terbaru dari Studio.
- Baca `RETENTION_LOOP_BLUEPRINT_2026-04-06.md` untuk blueprint retention pasca backlog teknis utama selesai.

## Aturan Kerja yang Berlaku
- READ `executionmode.md` (tidak boleh di ubah atau di hapus!)
- source of truth tetap file lokal di repo
- `Rojo` dipakai hanya untuk `local -> Studio`
- `Rojo Two-Way Edit` tidak dipakai
- `MCP` dipakai untuk inspect state live, playtest, input simulation, dan operasi Studio-only
- jika task membutuhkan `Toolbox -> Inventory`, `My Audio`, atau `My Models`, verifikasi dulu identity cloud canonical di `ROBLOX_CLOUD_PLACE_IDENTITY_2026-04-08.md`
- setiap perubahan Studio yang dianggap final harus dimirror kembali ke source lokal sebelum dianggap selesai
- jangan menambah sistem baru sebelum drift dan duplikasi owner utama dibersihkan

## Status Saat Ini

- backlog engineering utama sudah tertutup
- lane yang tersisa sebelum publish bersifat manual/compliance:
  - Creator Hub ID resmi
  - multiplayer smoke dua client nyata
  - persistence target non-mock
  - legal/licensing final review
