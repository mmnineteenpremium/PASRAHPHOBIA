# Duplication and Runtime Drift 2026-04-03

## Tujuan

Dokumen ini menyorot masalah duplikasi, drift, dan inkonsistensi runtime yang paling menghambat proyek. Fokusnya pada blocker struktural, bukan daftar bug kecil.

## Prioritas

| Priority | Masalah | Dampak | Arah Perbaikan |
| --- | --- | --- | --- |
| P0 | Client dual-stack antara controller modern dan LocalScript legacy | behavior ganda, event ganda, debugging kacau | tetapkan satu stack canonical, migrasikan atau matikan legacy script satu per satu |
| P0 | Remote surface drift | client lama menunggu remote yang tidak source-controlled | definisikan canonical remote contract, hapus listener legacy, source-control semua remote runtime penting |
| P0 | Extraction zone mismatch | loop match bisa gagal finish walau pemain sudah di map clone aktif | pindahkan ownership extraction ke map clone aktif atau inject zone dari hasil clone |
| P0 | Audio fallback rusak | sistem sanitize menutupi error dengan ID yang tetap gagal load | ganti fallback ke asset valid dan audit semua SoundId placeholder/broken |
| P1 | Ghost visual masih placeholder | gameplay ghost tidak mewakili target game sebenarnya | buat vertical slice satu ghost final yang benar-benar terhubung ke spawn, movement, dan replication |
| P1 | UI ownership tersebar | folder UI kosong tapi `UI/Main.lua` memuat banyak state dan panel | pecah `UI/Main.lua` secara bertahap atau tetapkan sebagai canonical sementara dan hapus folder semu |
| P1 | Registry autoload terlalu lebar | banyak sistem boot tanpa prioritas implementasi yang jelas | audit `SystemRegistry`, matikan yang tidak ikut vertical slice |
| P1 | Telemetry duplicate init surface | risiko init ganda atau side effect sulit dilacak | satukan surface module `TelemetrySystem` |
| P2 | Runtime-created remotes belum source-controlled | drift antar place/runtime | deklarasikan remote seperti `SpectatorEvidence` di repo atau dokumentasikan sebagai runtime-only dengan owner jelas |
| P2 | File txt contoh ikut termount ke runtime | noise di ReplicatedStorage dan kebocoran file non-gameplay | keluarkan file contoh dari path yang dimount oleh Rojo |

## Detail Masalah

### P0. Client dual-stack

Masalah:

- `StarterPlayerScripts.Client` memuat sistem modern dan script lama secara bersamaan

Gejala:

- sensory pipeline bisa bersaing
- remote/event lama masih dikonsumsi
- sulit membuktikan flow mana yang canonical

Aksi:

1. buat daftar script legacy yang masih benar-benar dipakai
2. petakan owner penggantinya di stack modern
3. matikan legacy script yang redundant
4. ulangi smoke test setelah setiap pemadaman

### P0. Remote surface drift

Masalah:

- repo hanya punya remote canonical baru
- script legacy masih menunggu remote lama
- runtime membuat remote tambahan di luar repo

Aksi:

1. tetapkan contract remote final per sistem
2. source-control remote runtime yang harus ada sejak boot
3. hapus konsumsi remote lama dari client
4. tambahkan sanity check saat boot untuk memastikan surface remote lengkap

### P0. Extraction mismatch

Masalah:

- map match aktif tinggal di `Workspace.ActiveMatches`
- extraction zone didaftarkan dari `Workspace.Maps`

Aksi:

1. tetapkan map clone aktif sebagai satu-satunya source extraction runtime
2. saat map clone dibuat, register ulang zone berdasarkan clone
3. tutup jalur fallback lama setelah terbukti lolos test

### P0. Audio fallback rusak

Masalah:

- `AudioSanitizer` mengganti sound rusak ke ID fallback yang saat boot masih `403`

Aksi:

1. ganti ID fallback ke asset internal yang valid
2. audit semua sound placeholder dan broken ID
3. pisahkan antara placeholder dev dan asset fallback production

### P1. Ghost placeholder

Masalah:

- ghost backend ada
- representasi visual final belum canonical

Aksi:

1. pilih satu ghost dulu sebagai vertical slice
2. simpan asset final ke repo, bukan hanya di Studio live
3. sambungkan spawn path dan config movement ke model final
4. baru perluas ke tipe ghost lain

### P1. UI ownership tidak jelas

Masalah:

- folder UI modular banyak yang kosong
- `UI/Main.lua` menampung terlalu banyak surface sekaligus

Aksi:

1. tetapkan apakah `UI/Main.lua` adalah canonical sementara
2. jika ya, hapus ekspektasi palsu dari folder kosong
3. jika tidak, pecah panel-panel ke modul nyata secara bertahap

### P1. Registry autoload terlalu luas

Masalah:

- banyak sistem boot walau belum ikut deliverable inti

Aksi:

1. tandai sistem wajib vertical slice
2. nonaktifkan sistem sampingan sementara
3. kecilkan boot surface sampai log lebih mudah dibaca

### P1. Telemetry duplicate surface

Masalah:

- indikasi init ganda dari struktur module yang bertumpuk

Aksi:

1. pilih satu entrypoint module
2. hapus alias/module duplikat
3. verifikasi `Init` dan `Start` hanya muncul sekali

### P2. Runtime-created remotes

Masalah:

- `SpectatorEvidence` muncul di runtime, tetapi tidak ada di repo

Aksi:

1. putuskan apakah remote ini harus predeclared
2. jika ya, pindahkan ke `src/ReplicatedStorage/RemoteEvents`
3. jika tidak, dokumentasikan dengan owner yang jelas

### P2. Noise file yang ikut termount

Masalah:

- file txt contoh di `src/shared/GamePhaseSystem` ikut muncul di runtime

Aksi:

1. keluarkan file non-runtime dari tree Rojo
2. buat folder notes/reference di luar path yang dimount

## Urutan Perbaikan

Urutan minimum yang disarankan:

1. client dual-stack
2. remote surface drift
3. extraction mismatch
4. audio fallback valid
5. one-ghost vertical slice
6. UI ownership cleanup
7. registry trimming

## Definition of Done

Masalah duplikasi dianggap selesai jika:

- hanya ada satu owner aktif per surface utama
- playtest log tidak lagi menunjukkan bootstrap atau listener yang ambigu
- file repo bisa menjelaskan runtime tanpa bergantung pada state Studio yang tersembunyi

## Update 2026-04-04 03:57 ICT - Drift Nyata yang Terdeteksi

Temuan runtime:

- `ShopCatalog` dan `GlobalOperationsConfig` sempat berbeda antara source lokal dan script yang benar-benar jalan di Studio.
- gejala langsung:
  - item termurah `MM/PP` tetap `insufficient_currency` walau source lokal sudah menyiapkan wallet baseline.

Mitigasi yang dipakai:

1. baca script target langsung di Studio (`script_read`) untuk verifikasi source aktual runtime.
2. sinkronkan patch ekonomi minimum pada script runtime yang aktif.
3. ulangi smoke test purchase setelah restart play.

Rule operasional tambahan:

- untuk bug runtime kritikal, verifikasi harus berbasis:
  - source lokal
  - source yang aktif di Studio
- jika keduanya tidak sama, status wajib ditandai sebagai drift sampai tervalidasi kembali.
