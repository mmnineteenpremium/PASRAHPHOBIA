# Full Execution Roadmap 2026-04-03

## Tujuan

Roadmap ini adalah acuan kerja utama sampai proyek:

1. punya vertical slice yang benar
2. lolos end-to-end test inti
3. siap masuk publish gate

Roadmap ini dibangun dari reality scan, bukan dari asumsi dokumen lama.

## Prinsip Operasional

- source code lokal adalah source of truth
- `Rojo` hanya untuk `local -> Studio`
- `MCP` dipakai untuk observasi live, playtest, input, dan operasi Studio-only
- perubahan Studio yang diterima harus kembali ke repo
- jangan menambah fitur baru sebelum drift owner utama dibersihkan
- setiap fase harus punya exit criteria yang objektif

## Phase 0 - Freeze Baseline

### Goal

Membekukan baseline kerja yang bersih dan mengurangi kebingungan operasional.

### Pekerjaan

- pakai report di folder ini sebagai baseline baru
- pertahankan workflow `VS Code + Rojo + MCP`
- jangan pakai `Two-Way Edit`
- tandai satu branch aktif untuk cleanup dan vertical slice

### Exit Criteria

- semua orang kerja dari baseline yang sama
- tidak ada lagi asumsi bahwa Studio state adalah source of truth utama

## Phase 1 - Runtime Consolidation

### Goal

Menghapus drift yang membuat runtime sulit dipercaya.

### Pekerjaan

- audit dan matikan script client legacy yang redundant
- tetapkan remote contract final
- source-control remote runtime penting
- potong registry boot ke sistem yang benar-benar dibutuhkan vertical slice
- satukan entrypoint module yang masih duplikat

### Output

- boot log lebih pendek dan lebih jelas
- satu owner per surface utama

### Exit Criteria

- client tidak lagi dual-stack untuk HUD, sanity, evidence, audio, dan tools
- remote legacy tidak lagi dipakai

## Phase 2 - Core E2E Repair

### Goal

Membuat satu loop match penuh yang benar-benar bisa selesai.

### Pekerjaan

- perbaiki extraction zone agar mengikuti map clone aktif
- pastikan transisi room -> match -> result -> return bekerja
- audit phase chain aktual dan rapikan condition akhir
- ganti audio fallback rusak

### Output

- satu flow match penuh tanpa blocker struktural

### Exit Criteria

- test `E2E-01` sampai `E2E-10` lolos untuk jalur dasar tanpa ghost final

## Phase 3 - One-Ghost Vertical Slice

### Goal

Membuat satu ghost final benar-benar hidup di game.

### Pekerjaan

- pilih satu ghost utama
- import model final dan dependency ke repo
- tentukan root, scale, collision, anchor, dan owner folder
- sambungkan spawn, movement, manifestation, dan audio
- validasi di Studio live memakai MCP

### Output

- satu ghost final playable

### Exit Criteria

- ghost tampil benar
- ghost bergerak benar
- ghost bisa diuji di satu match penuh

## Phase 4 - One-Map One-Tool Playable Slice

### Goal

Menjadikan satu map dan tool minimum benar-benar playable.

### Pekerjaan

- pilih satu map utama
- audit spawn, blocker, extraction, interaction point
- sambungkan satu tool minimum ke evidence flow
- rapikan HUD inti dan objective loop

### Output

- vertical slice investigasi minimum

### Exit Criteria

- pemain bisa masuk match, investigasi, melihat ghost, menyelesaikan match, lalu kembali ke lobby

## Phase 5 - Content Expansion

### Goal

Menambah konten setelah pipeline inti stabil.

### Pekerjaan

- tambah ghost lain
- tambah tool lain
- rapikan panel UI modular
- tambah audio dan visual polish

### Output

- content breadth bertambah tanpa mengorbankan stabilitas

### Exit Criteria

- penambahan konten tidak membuka lagi drift owner lama

## Phase 6 - Persistence and Commerce Hardening

### Goal

Menutup gap antara prototipe playable dan produk publishable.

### Pekerjaan

- validasi persistence di luar mock Studio
- sambungkan commerce bridge Roblox yang nyata
- audit reward, entitlement, dan recovery path
- audit lisensi semua asset eksternal

### Output

- data dan monetization siap diuji di environment target

### Exit Criteria

- purchase flow, entitlement, dan persistence lolos test
- tidak ada asset komersial yang status lisensinya abu-abu

## Phase 7 - E2E Campaign and Publish Gate

### Goal

Menyiapkan keputusan publish berdasarkan bukti, bukan feeling.

### Pekerjaan

- jalankan matrix E2E penuh
- kumpulkan bukti visual dan log
- audit performa minimum
- buat daftar blocker publish final
- tentukan `go / no-go`

### Output

- publish gate report final

### Exit Criteria

- seluruh test case kritis `PASS`
- blocker publish tidak tersisa di P0

## Execution Order yang Direkomendasikan

1. Phase 1
2. Phase 2
3. Phase 3
4. Phase 4
5. Phase 5
6. Phase 6
7. Phase 7

## Peran MCP dalam Roadmap Ini

MCP dipakai untuk:

- reality check state Studio
- inspeksi tree dan property live
- playtest automation
- verifikasi bahwa perubahan source benar-benar muncul di Studio
- tuning visual dan perilaku yang tidak nyaman dikerjakan hanya dari file lokal

MCP tidak dipakai untuk menggantikan source of truth. Setiap hasil final tetap harus tercermin di repo.

## Definition of Final Success

Roadmap ini dianggap selesai jika:

- runtime inti sudah bersih dari drift owner utama
- ada minimal satu vertical slice yang lengkap
- E2E matrix inti lolos
- persistence dan commerce bridge siap
- asset/lisensi aman untuk proyek komersial
- publish decision bisa dibuat berdasarkan bukti yang jelas

