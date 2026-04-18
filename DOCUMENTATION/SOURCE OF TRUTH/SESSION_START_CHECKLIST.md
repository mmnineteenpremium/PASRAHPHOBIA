# SESSION START CHECKLIST

## Tujuan

File ini adalah checklist startup wajib untuk setiap sesi AI/Codex baru di project `PASRAHPHOBIA`.

Gunakan file ini agar:

- AI tidak membaca dokumen lama sebagai landasan utama
- AI tidak mengasumsikan MCP aktif tanpa verifikasi
- AI tidak mengaktifkan workflow yang sudah terbukti tidak aman
- source of truth proyek tetap konsisten

## Urutan Baca Wajib

Baca file berikut dalam urutan ini:

1. `DOCUMENTATION/SOURCE OF TRUTH/readfirst.md`
2. `DOCUMENTATION/SOURCE OF TRUTH/REPORTS.md`
3. `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
4. `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
5. `DOCUMENTATION/SOURCE OF TRUTH/reports/ROBLOX_CLOUD_PLACE_IDENTITY_2026-04-08.md`
6. `DOCUMENTATION/SOURCE OF TRUTH/reports/REALITY_SCAN_2026-04-03.md`
7. `DOCUMENTATION/SOURCE OF TRUTH/reports/DUPLICATION_AND_RUNTIME_DRIFT_2026-04-03.md`
8. `DOCUMENTATION/SOURCE OF TRUTH/reports/FULL_EXECUTION_ROADMAP_2026-04-03.md`
9. `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
10. `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TEST_MATRIX_2026-04-03.md`

## Dokumen yang Bukan Landasan Utama

Dokumen di bawah ini boleh dipakai hanya jika memang perlu sebagai referensi spesifik:

- `DOCUMENTATION/PASRAHPHOBIA_UI_REQUIREMENTS.md`
- `DOCUMENTATION/Asset Import Guide/*`
- `DOCUMENTATION/SYSTEM_MAP.md`
- `DOCUMENTATION/CODEMAP.md`
- `DOCUMENTATION/README_*`

Jangan jadikan file-file itu sebagai sumber kebenaran utama jika bertentangan dengan source aktif atau report reality scan terbaru.

## Startup Check MCP

Lakukan verifikasi ini di awal sesi:

1. Pastikan Roblox Studio terbuka pada project yang benar.
2. Pastikan Assistant MCP di Studio aktif.
3. Jalankan `/mcp` di sesi Codex.
4. Pastikan `Roblox_Studio` muncul dalam daftar tool.
5. Jika perlu, jalankan `codex mcp list`.

Sesi hanya dianggap siap jika:

- `Roblox_Studio` terlihat di `/mcp`
- Studio menunjukkan client MCP terhubung

## Minimum Yang Harus Dibuka Sebelum Interaksi Dengan Codex

Urutan minimum yang aman untuk project ini:

1. Buka `PASRAHPHOBIA.rbxlx`
2. Pastikan Studio yang terbuka memang project ini, bukan place lain
3. Pastikan Assistant MCP di Studio sudah terhubung
4. Pastikan tool `Roblox_Studio` terbaca di sesi Codex
5. Jangan nyalakan `Rojo` dulu kecuali memang mau kirim perubahan local ke Studio
6. Jika butuh publish/test cloud, verifikasi dulu identity place:
   - `PlaceId = 113010869463813`
   - `GameId = 9802743087`
7. Jika butuh test multiplayer:
   - buka Roblox Player PC setelah Studio siap
   - buka Android client setelah Studio siap
8. Baru setelah itu beri task ke Codex

Aturan singkat:

- default aman: `Studio + MCP` dulu
- `Rojo` hanya dinyalakan saat perlu workflow `local -> Studio`
- jangan anggap state Studio otomatis sudah balik ke repo
- perubahan Studio final harus dimirror/syncback dengan sengaja, lalu commit

## Startup Check Cloud Place Identity

Jika task membutuhkan context akun/cloud Roblox, verifikasi identity berikut di Studio:

- `game.PlaceId = 113010869463813`
- `game.GameId = 9802743087`
- `game.Name = Place2`
- `game.CreatorId = 10576163165`

Task yang termasuk:

- scan `Toolbox -> Inventory`
- audit `My Audio`
- audit `My Models`
- verifikasi asset upload yang sudah ada di akun Roblox

Jika salah satu ID di atas tidak cocok:

- jangan menebak-nebak context Studio
- anggap session belum terhubung ke place cloud yang benar
- perbaiki dulu context Studio sebelum audit inventory/private upload

## Startup Check Rojo

Lakukan verifikasi ini di awal sesi:

1. Pastikan hanya plugin `RojoManagedPlugin` yang dipakai.
2. Pastikan plugin marketplace `Rojo` tidak dipakai.
3. Jalankan server jika belum hidup:

```powershell
pwsh -NoLogo -File .\scripts\serve-rojo.ps1
```

4. Connect plugin Rojo ke `localhost:34872`.
5. Pastikan `Two-Way Edit` tetap `OFF`.

## Workflow Resmi Project

Aturan kerja yang berlaku:

- source code lokal di repo adalah source of truth
- identity cloud Roblox yang canonical untuk session Studio ter-publish saat ini:
  - `PlaceId = 113010869463813`
  - `GameId = 9802743087`
  - `Name = Place2`
  - `CreatorId = 10576163165`
- `Rojo` dipakai untuk `local -> Studio`
- `MCP` dipakai untuk inspect state live, playtest, input, dan operasi Studio-only
- perubahan Studio yang dianggap final harus dimirror kembali ke repo
- `Rojo Two-Way Edit` tidak dipakai
- jangan mengandalkan state Studio-only sebagai hasil akhir

## Aturan Teknis Kritis

- jangan aktifkan kembali `Two-Way Edit`
- jangan pakai workflow `Studio-only lalu berharap balik otomatis ke local`
- jangan menambah fitur baru sebelum drift owner utama dibersihkan
- jangan menilai readiness publish dari Studio mock persistence
- jangan menyimpulkan monetization aman sebelum purchase bridge Roblox benar-benar terpasang

## Baseline Masalah yang Sudah Diketahui

AI sesi baru harus menganggap masalah berikut masih nyata sampai terbukti selesai:

- client dual-stack
- remote surface drift
- extraction mismatch terhadap map clone aktif
- audio fallback rusak
- ghost visual final belum canonical
- monetization Roblox bridge belum ada
- persistence Studio masih mock

## Titik Mulai Default

Jika tidak ada instruksi lain dari user, fase kerja default dimulai dari:

- `DOCUMENTATION/SOURCE OF TRUTH/reports/FULL_EXECUTION_ROADMAP_2026-04-03.md`
- Phase 1: runtime consolidation

## Perintah Ringkas untuk AI Baru

Jika sesi baru dimulai, AI sebaiknya memulai dengan prinsip ini:

1. baca `SOURCE OF TRUTH`
2. verifikasi `/mcp`
3. verifikasi `Rojo`
4. scan source aktif
5. lanjutkan task dari roadmap dan backlog terbaru
