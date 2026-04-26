# TASK ACTIVE - RUNTIME AUTHORITY + TOTAL VISUAL POLISH LOCK

Last updated: 2026-04-26 (Asia/Bangkok)
Owner context: Miftah
Status: ACTIVE
Confidence target: 99%

## Active Mandate

Task aktif saat ini dikunci ke dua hal berikut:

1. Runtime map/spawn wajib 100% mengikuti authored map source-of-truth di `ServerStorage`/`ReplicatedStorage`.
2. Penyempurnaan visual total lintas canonical UI/GUI/UX tanpa membuat sistem baru.

## Execution Update (2026-04-26)

- Runtime spawn fallback/recreate lane di source sudah dipangkas:
  - `MapRuntimePatches.patchPreparationStaging` sekarang strict-authored only (tanpa synthetic staging builder).
  - Jalur teleport fallback direct CFrame pada spawn gagal dihapus.
- Runtime authoritative gate ditambah di teleport:
  - match gagal lanjut jika `PreparationStagingRuntime` tidak lolos validasi strict authored (spawn/door/boundary).
- Override hardcoded legacy untuk spawn points (`PlayerSpawn_*`) dinonaktifkan dari lane aktif.
- Pending closure operasional tetap:
  - `smoke test 2 client nyata` untuk verifikasi end-to-end runtime + visual di device lane aktif.

## Runtime Authority Lock (Non-Negotiable)

- Spawn source satu-satunya untuk match:  
  `game.ServerStorage.Maps.<Map>.<Map>.Runtime.PreparationStagingRuntime.PreparationSpawnArea`
- Jalur fallback/recreate otomatis untuk spawn **dilarang**.
- Tidak boleh ada duplikasi logic runtime lama vs runtime sekarang.
- Jika ada logic visual penting yang belum terbawa (contoh: tool hold-hand visual), wajib migrasi ke runtime aktif tanpa membuat lane baru.
- Boundary anti-ghost-ke-staging wajib ada dan tervalidasi.
- Trigger phase by-door wajib ada dan tervalidasi.

## Runtime Validation Matrix (4 Canonical Maps)

- `HauntedHouse`
  - Door trigger: `Door_FrontEntry`
  - Preparation spawn: `Runtime.PreparationStagingRuntime.PreparationSpawnArea`
  - Runtime boundary authored wajib ada
- `StudioMMNineteen`
  - Door trigger: `Door_FrontEntry`
  - Preparation spawn: `Runtime.PreparationStagingRuntime.PreparationSpawnArea`
  - Runtime boundary authored wajib ada
- `EmptyBuilding`
  - Door trigger: `Door_Lobby`
  - Preparation spawn: `Runtime.PreparationStagingRuntime.PreparationSpawnArea`
  - Runtime boundary authored wajib ada
- `AbandonedPalace`
  - Door trigger: `Door_GrandHall`
  - Preparation spawn: `Runtime.PreparationStagingRuntime.PreparationSpawnArea`
  - Runtime boundary authored wajib ada

## Visual-Only Execution Lock

- Tidak membuat sistem baru.
- Tidak membuat fitur gameplay/economy baru.
- Tidak menambah arsitektur lane baru.
- Fokus 100% ke kualitas visual manusia (readability, hierarchy, consistency, layout, spacing, state clarity, motion clarity).

### Visual Reference Source (Wajib)

- Referensi visual utama diambil dari:
  - `asset mentah/ref ui/*.html`
- Konversi dari HTML ke Roblox UI hanya di level visual (komposisi, warna, hierarchy, readability, state clarity).
- Tidak boleh menyuntik logic sistem baru saat proses konversi visual.

## Total Visual Scope (Canonical UI/GUI/UX)

- Rank
- EXP
- Profiling
- Daily Quest
- Daily Reward
- Daily Check-In
- Daily Spin Reward
- Gacha
- Shop
- RoyalPass
- MM wallet visual
- PP wallet visual
- Item inventory visual
- Hidden Gems visual + cap messaging (`maks 3 PP coin per hari`)
- Semua panel pendukung lain yang terhubung ke alur match/lobby

## Tool + Hand Visual Parity Lock

- Flashlight tetap jelas di tangan kanan pada lane yang diizinkan.
- Tool lain wajib mount/pose tangan benar dan konsisten antar tool.
- Jika runtime lama punya kualitas visual tool/hand lebih baik, port ke runtime aktif tanpa duplikasi.
- VFX/use animation hanya dipoles pada sisi visual/readability (tanpa menambah sistem baru).

## Canonical + Doc Index Sync Lock

Wajib sinkron pada dokumen source-of-truth:

- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md` (dokumen ini)
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

Semua dokumen harus menyatakan lock runtime-spawn authored + visual-only execution lane.

## Definition Of Done

- Runtime spawn di 4 map hanya dari `PreparationSpawnArea` authored (tanpa fallback/recreate).
- Boundary anti-staging untuk ghost tervalidasi ada pada semua map canonical.
- Door trigger preparation -> investigation tervalidasi ada pada semua map canonical.
- Tidak ada drift/duplikasi antara runtime lama dan runtime aktif untuk logic visual tool/hand.
- Seluruh panel visual scope di atas dipoles secara menyeluruh (UI/GUI/UX) tanpa membuat sistem baru.
- Canonical + doc index sudah sinkron terhadap lock ini.
