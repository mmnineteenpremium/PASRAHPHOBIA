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
- Untuk status publish final lintas seluruh `SOURCE OF TRUTH`, baca `SOURCE_OF_TRUTH_RECONCILIATION_2026-04-11.md` lebih dulu.
- Baca `REALITY_SCAN_2026-04-03.md` dulu untuk status aktual proyek.
- Baca `DUPLICATION_AND_RUNTIME_DRIFT_2026-04-03.md` untuk blocker struktural dan prioritas perbaikan.
- Baca `E2E_TO_PUBLISH_BACKLOG_2026-04-03.md` untuk daftar pekerjaan yang belum selesai.
- Baca `E2E_TEST_MATRIX_2026-04-03.md` untuk panduan uji end-to-end di Studio.
- Baca `FULL_EXECUTION_ROADMAP_2026-04-03.md` sebagai peta kerja utama sampai siap publish.
- Baca `ASSET_LICENSE_LEDGER_2026-04-03.md` untuk status ownership/licensing asset aktif yang benar-benar terlihat di source.
- Baca `AUDIO_REPLACEMENT_PLAN_2026-04-03.md` untuk slot audio kosong yang masih perlu diganti dan jalur apply setelah upload asset.
- Baca `ROBLOX_CLOUD_PLACE_IDENTITY_2026-04-08.md` untuk identity `PlaceId/GameId` cloud yang canonical saat task membutuhkan context akun Roblox, inventory Toolbox, atau asset upload private.
- Baca `ROBLOX_INVENTORY_SYNC_LEDGER_2026-04-08.md` untuk snapshot penuh inventory upload Roblox (`101` audio, `11` model) dan mapping `raw asset lokal -> upload inventory Roblox -> rbxassetid` yang sudah dikunci hari ini.
- Baca `CREATOR_HUB_ID_TEMPLATE_2026-04-03.md` untuk blocker manual yang masih diperlukan agar bridge monetization bisa ditutup end-to-end.
- Baca `EXECUTION_LOG.md` untuk progres task yang sudah dikerjakan selama fase eksekusi.
- Baca `PUBLISH_REVIEW_FINAL_2026-04-06.md` untuk status publish saat ini.
- Baca `FINAL_RELEASE_CHECKLIST_2026-04-06.md` untuk urutan final sebelum publish.
- Baca `MANUAL_PUBLISH_HANDOFF_2026-04-09.md` untuk state manual publish terbaru yang sudah diprefill dari branch/commit aktif, gate otomatis terakhir, dan urutan next step yang masih tersisa.
- Baca `CREATOR_HUB_MARKETPLACE_MAPPING_2026-04-06.md` untuk daftar item Robux yang aman diaktifkan dan item yang harus tetap disabled.
- Baca `MONETIZATION_DECISION_RECORD_2026-04-10.md` untuk keputusan monetization v1 yang dikunci agar lane release tidak drift ke refactor subscription.
- Baca `LOCAL_MULTIPLAYER_SMOKE_2026-04-10.md` untuk bukti precheck multiplayer lokal otomatis (`Server + 2 Clients`) dan batas interpretasinya terhadap gate publish final.
- Baca `PERSISTENCE_STUDIO_OVERRIDE_BLOCKER_2026-04-10.md` untuk bukti bahwa `rbxlx` lokal `PlaceId=0` tidak bisa dipakai menutup gate persistence non-mock meskipun override Studio DataStore diaktifkan.
- Baca `PERSISTENCE_RESULT_2026-04-11_REAL_DATASTORE.md` untuk hasil real DataStore di published place, kegagalan awal wallet `MM/PP`, dan bukti rerun PASS setelah wiring `EconomySystem` diperbaiki.
- Baca `LEGAL_RUNTIME_REVIEW_2026-04-11.md` untuk bukti runtime bahwa attribution `Pocong ... CC BY 4.0` terlihat di `QUICK MENU`, plus keputusan final bahwa `LegacyDisabled` kini inert dan bukan blocker publish v1.
- Baca `UI_TOGGLE_KEY_AUDIT_2026-04-11.md` untuk audit hotkey UI terhadap default Roblox resmi dan refactor `Esc -> X` pada lane close/toggle.
- Baca `MOBILE_ROOM_BROWSER_FIX_2026-04-11.md` untuk blocker multiplayer manual yang ditemukan di iPhone landscape, refactor layout Room Browser mobile-wide, dan alasan `quick join` sengaja didemote dari lane utama smoke.
- Baca `BUILD_SIGNATURE_AND_PUBLISH_PROPAGATION_2026-04-11.md` untuk token build UI live (`PHB-20260411-UI1`), lokasi tampilnya di UI, dan kesimpulan resmi bahwa publish public Roblox tidak mendokumentasikan review delay umum untuk update place.
- Baca `ROOM_BROWSER_FULLSCREEN_TOUCH_FIX_2026-04-11.md` untuk perbaikan overlay fullscreen mobile Room Browser, touch shield, dan alasan kamera sebelumnya masih ikut bergerak saat UI disentuh.
- Baca `ROOM_BROWSER_LANDSCAPE_RUNTIME_FIX_2026-04-11.md` untuk root cause Luau register overflow pada `Client.UI.Main`, koreksi sizing landscape yang sebelumnya masih bias portrait, dan bukti Studio play test bahwa drag di `Room List` tidak lagi menggerakkan kamera.
- Baca `MULTIPLAYER_QUEUE_AND_SPECTATOR_FIX_2026-04-11.md` untuk root cause server-side setelah run dua iPhone pertama, perbaikan `Queue Hub` agar tidak auto-queue, dan deduplikasi flow spectator yang sebelumnya bisa masuk ganda.
- Baca `RESPAWN_GUARD_AND_FORCED_RESET_FIX_2026-04-11.md` untuk regression tambahan yang ditemukan setelah run multiplayer real-client, root cause jalur reset bawaan Roblox, dan patch kanonik `PlayerDied` + reset guard client.
- Baca `QA_PLAYTHROUGH_WORKFLOW_2026-04-11.md` untuk urutan workflow in-game yang dialami langsung di Studio, durasi tiap phase, dan daftar kebingungan/roughness/rage-quit risk dari sudut pandang QA manusia.
- Baca `SOURCE_OF_TRUTH_RECONCILIATION_2026-04-11.md` untuk rekonsiliasi final antara report snapshot lama yang masih memuat blocker historis vs lane PASS terbaru yang menjadi dasar status publish saat ini.
- Baca `OWNER_BRAND_RELEASE_POSITION_2026-04-11.md` untuk pemisahan tegas antara `technical/platform GO` vs `public launch NO-GO` dari sudut owner dan brand.
- Baca `QA_MULTIPLAYER_MANUAL_CHECKLIST_2026-04-06.md` dan `PERSISTENCE_MANUAL_CHECKLIST_2026-04-06.md` untuk gate manual terakhir.
- Baca `QA_MULTIPLAYER_RESULT_TEMPLATE_2026-04-06.md` dan `PERSISTENCE_RESULT_TEMPLATE_2026-04-06.md` untuk mencatat hasil run manual terakhir.
- Baca `QA_MULTIPLAYER_RESULT_2026-04-09_PREP.md` dan `PERSISTENCE_RESULT_2026-04-09_PREP.md` jika ingin mulai dari sheet hasil yang sudah diprefill dengan baseline teknis terbaru.
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

- backlog engineering utama belum bisa dianggap sepenuhnya tertutup
- lane manual publish teknis saat ini:
  - multiplayer smoke dua client nyata core flow: `PASS`
  - multiplayer forced-reset / respawn guard retest: `PENDING`
  - persistence target non-mock: `PASS`
  - legal/runtime review: `PASS`
  - commerce / Creator Hub mapping: `PASS`
- catatan:
  - beberapa file snapshot lama di `SOURCE OF TRUTH` masih memuat blocker historis; lihat `SOURCE_OF_TRUTH_RECONCILIATION_2026-04-11.md` untuk aturan precedence final
  - status di atas tidak sama dengan owner/brand approval untuk peluncuran publik; lihat `OWNER_BRAND_RELEASE_POSITION_2026-04-11.md`

