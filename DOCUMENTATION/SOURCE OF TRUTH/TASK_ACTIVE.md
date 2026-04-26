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
- Batch visual T6 untuk panel canonical berbasis snapshot runtime sudah masuk:
  - `ProfileUI`: hierarchy visual untuk Rank/EXP, Daily Quest, Daily Check-In, Daily Spin, Inventory/Gacha, dan cap messaging `PP 3/hari`.
  - `RoyalPassUI`: tab/row/card wording diseragamkan ke lane `Daily Check-In` dan `Daily Quest` tanpa sistem baru.
  - wording lobby daily reward diselaraskan ke istilah `Daily check-in`.
- Batch visual T7 untuk hidden gems + daily lane clarity sudah masuk:
  - tracker visual `Hidden Gems` sekarang membaca snapshot `ppBreakdown` (jika ada) untuk progress `x/3` tanpa menambah sistem ekonomi baru.
  - `ShopUI` dan `PASRA_UI` menampilkan cap lane hidden gems dengan wording yang konsisten.
  - `DailyRewardZone` lobby copy dan tombol `Royal Pass` diselaraskan ke konteks `Daily Check-In`/harian.
- Batch visual T8 untuk lobby/menu/shop micro-state sudah masuk:
  - `Lobby Panel` sekarang menampilkan micro-state wallet MM/PP + daily quest/check-in + hidden gems + gacha snapshot untuk lane harian.
  - `Quick Menu` menampilkan micro-state canonical (wallet, daily, gacha, hidden gems) di secondary/footer.
  - `ShopUI` menambahkan detail visual gacha snapshot (`owned/equipped`) di lane secondary/footer dan attribute stamp.
- Batch visual T9 untuk mobile readability tuning sudah masuk:
  - copy micro-state di `Lobby Panel`, `Quick Menu`, dan `ShopUI` dipadatkan khusus mode mobile agar tidak overflow.
  - sizing/text scale pada lane lobby header hint + menu mobile disetel ulang untuk readability lintas rasio layar.
  - semua tuning tetap visual-only berbasis snapshot runtime.
- Batch visual T10 untuk footer compaction mobile sudah masuk:
  - footer `Quick Menu` mobile disederhanakan ke format ringkas + build signature agar tidak overpadat.
  - footer `ShopUI` mobile dipadatkan per-filter (`MM/PP/Robux/Owned`) dengan arti tetap sama.
  - lane desktop tetap mempertahankan copy detail penuh.
- Batch visual T11 untuk ShopUI mobile layout stability sudah masuk:
  - tinggi panel mobile `ShopUI` ditambah agar area footer tidak menabrak konten saat copy state panjang.
  - area `ContentFrame` + footer mobile diatur ulang spacing-nya untuk lane filter/item list.
  - text size filter/secondary/footer `ShopUI` mobile diturunkan sedikit agar stabil di viewport sempit.
- Batch visual T12 untuk ProfileUI + RoyalPassUI mobile stability sudah masuk:
  - footer mobile `ProfileUI` dan `RoyalPassUI` diberi reserve spacing lebih longgar agar tidak tabrakan dengan konten.
  - `ContentFrame` mobile kedua panel di-offset ulang untuk menjaga hierarki header-content-footer tetap bersih.
  - tuning text-size secondary/footer mobile diturunkan ringan agar copy canonical tetap terbaca pada viewport sempit.
- Batch visual T13 untuk LeaderboardUI mobile clarity sudah masuk:
  - text sizing mobile `Primary/Secondary/Footer` pada `LeaderboardUI` dituning agar copy snapshot tetap terbaca saat padat.
  - `ContentFrame` + action-row + footer `LeaderboardUI` mobile diatur ulang untuk mengurangi tabrakan area bawah panel.
  - semua perubahan tetap visual-only tanpa ubah logic rank/progression.
- Batch visual T14 untuk MainMenuUI mobile stack density sudah masuk:
  - ritme vertical stack tombol + footer `MainMenuUI` mobile dipadatkan terkontrol khusus viewport tinggi sempit.
  - text-size tombol aksi `Room/Profile/Shop/Rank/Graphics` dituning khusus lane compact agar tidak sesak.
  - perubahan tetap murni visual tanpa perubahan logic sistem/menu flow.
- Batch visual T15 untuk PASRA_UI + JournalUI mobile readability sudah masuk:
  - `PASRA_UI` mobile mendapat reserve footer + ukuran konten yang lebih aman untuk copy snapshot panjang.
  - `JournalUI` mobile mendapat tuning area scan (`ToolActionButton` + `ToolStatusLabel`) agar tidak overlap saat panel padat.
  - tuning text-size secondary/footer mobile untuk kedua panel tetap di lane visual-only tanpa ubah runtime logic.
- Batch visual T16 untuk SpectatorUI mobile stability sudah masuk:
  - `SpectatorUI` mobile mendapat reserve footer khusus agar copy distorsi/spectate tidak menabrak area konten.
  - `ContentFrame` mobile `SpectatorUI` di-rebalance untuk hierarchy header-content-footer yang lebih stabil.
  - tuning text-size secondary/footer mobile tetap visual-only tanpa ubah behavior spectator.
- Pending closure operasional (owner-manual lane):
  - `smoke test 2 client nyata` tetap diperlukan untuk verifikasi end-to-end runtime + visual di device lane aktif, namun ini tugas owner/user (bukan eksekusi agent).

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

## Remaining Work (Excluding Owner 2-Client Smoke)

- Final pass visual canonical UI dari referensi `asset mentah/ref ui/*.html` untuk panel yang masih perlu penyetaraan akhir layout/spacing/typography lintas device (terutama verifikasi akhir readability pada device nyata setelah T9) tanpa menambah sistem baru.
- Bukti visual + catatan perubahan per panel canonical perlu terus ditambah per batch report source-of-truth agar tidak ada drift antara implementasi aktif dan indeks dokumen.

## Definition Of Done

- Runtime spawn di 4 map hanya dari `PreparationSpawnArea` authored (tanpa fallback/recreate).
- Boundary anti-staging untuk ghost tervalidasi ada pada semua map canonical.
- Door trigger preparation -> investigation tervalidasi ada pada semua map canonical.
- Tidak ada drift/duplikasi antara runtime lama dan runtime aktif untuk logic visual tool/hand.
- Seluruh panel visual scope di atas dipoles secara menyeluruh (UI/GUI/UX) tanpa membuat sistem baru.
- Canonical + doc index sudah sinkron terhadap lock ini.
