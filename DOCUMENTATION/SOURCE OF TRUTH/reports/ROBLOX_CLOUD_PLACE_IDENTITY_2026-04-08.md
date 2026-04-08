# ROBLOX CLOUD PLACE IDENTITY 2026-04-08

## Tujuan

Dokumen ini mengunci identitas cloud Roblox yang sekarang valid untuk project `PASRAHPHOBIA`.

Ini bukan pengganti source of truth lokal di repo.

Fungsinya:

- mencegah drift antara `file lokal .rbxlx` dan `place cloud` yang ter-publish
- memberi pegangan tetap untuk task yang butuh context akun Roblox di Studio
- menjadi acuan tetap saat memeriksa `Toolbox -> Inventory -> My Audio / My Models`

## Canonical Cloud Identity

Hasil verifikasi live dari Roblox Studio:

- `game.PlaceId = 113010869463813`
- `game.GameId = 9802743087`
- `game.Name = Place2`
- `game.CreatorId = 10576163165`

## Arti Operasional

- `PASRAHPHOBIA.rbxlx` lokal tetap dipakai sebagai workspace dev lokal dan source of truth repo
- publish cloud di atas adalah identity Roblox yang sekarang valid untuk session Studio yang butuh context akun/cloud
- `Place2` adalah nama cloud yang sedang terbaca saat verifikasi live; jangan diasumsikan sebagai rename produk final

## Kapan Harus Dipakai

Gunakan identity cloud ini jika task membutuhkan:

- `Toolbox -> Inventory`
- `My Audio`
- `My Models`
- verifikasi asset upload milik akun
- pengecekan perilaku Studio yang butuh `PlaceId/GameId` non-zero

## Kapan Tidak Menggantikan Source Lokal

Identity cloud ini tidak mengubah aturan berikut:

- source of truth implementasi tetap file lokal di repo
- `Rojo` tetap `local -> Studio`
- jangan mengandalkan state Studio-only sebagai hasil akhir

## Guardrail Penting

- `CreatorId = 10576163165` adalah `UserId/account id`, bukan `marketplaceId` production
- jangan pakai `10576163165` sebagai `GamePassId`, `ProductId`, atau audio/model asset id
- jika session Studio kembali menunjukkan `PlaceId = 0`, anggap context cloud belum terpasang dan jangan audit inventory private sampai session kembali terhubung ke place ini
