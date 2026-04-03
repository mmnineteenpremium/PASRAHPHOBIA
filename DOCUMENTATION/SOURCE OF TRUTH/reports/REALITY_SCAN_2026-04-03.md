# Reality Scan 2026-04-03

## Metode

Reality scan ini disusun dari empat lapisan bukti:

- pembacaan dokumen utama di `DOCUMENTATION/SOURCE OF TRUTH`
- pembacaan dokumen pendukung di `DOCUMENTATION/`
- scan source aktif di `src`, `default.project.json`, dan konfigurasi runtime
- inspeksi Studio live dan playtest log melalui `Roblox_Studio` MCP

## Ringkasan Eksekutif

Project ini belum siap publish, tetapi sudah punya fondasi backend yang luas. Masalah utama sekarang bukan ketiadaan sistem, melainkan:

- ownership runtime masih ganda
- surface client dan remotes masih drift
- asset final belum terintegrasi ke loop inti
- beberapa fallback penting masih placeholder atau rusak
- flow end-to-end ada, tetapi belum konsisten dari lobby sampai results

Kesimpulan utamanya:

- proyek ini bukan kosong
- proyek ini juga belum siap dianggap vertical slice yang bersih
- pekerjaan terdekat harus fokus pada konsolidasi runtime dan playable slice yang benar

## Temuan yang Terkonfirmasi

### 1. Boot chain server aktif dan panjang

Server benar-benar boot melalui:

- `src/ServerScriptService/Bootstrap.server.lua`
- `src/ServerScriptService/Server/ServerBootstrap.lua`
- `src/ServerScriptService/Server/Core/SystemRegistry.lua`

`SystemRegistry` masih memuat banyak sistem aktif. Runtime bukan lagi sekadar core minimal. Playtest log menunjukkan sistem seperti `AdaptiveHuntSystem`, `ContractSystem`, `DailyMissionSystem`, `GhostPathingSystem`, `RoyalPassSystem`, `SocialCommerceSystem`, `WeeklyChallengeSystem`, dan banyak lainnya masih boot.

Implikasi:

- dokumen yang mengasumsikan hanya segelintir owner aktif sudah tidak sepenuhnya cocok
- debugging dan integration risk naik karena surface sistem terlalu lebar

### 2. Client runtime masih dual-stack

Client modern ada, tetapi LocalScript lama juga masih hidup di tree yang sama.

Yang aktif bersamaan:

- controller/systems modern seperti `SoundSystem`, `GhostRenderer`, `InvestigationUISystem`
- script lama seperti `SanityVFX.client.lua`, `EvidenceVFX.client.lua`, `AudioManager.client.lua`, `MovementController.client.lua`, `CameraController.client.lua`, `Tools/EMFReaderGUI.client.lua`

Implikasi:

- event ganda
- UI dan sensory behavior bisa konflik
- sulit memastikan jalur mana yang benar-benar canonical

### 3. Surface remotes tidak bersih

Source remote events yang dikontrol repo saat ini:

- `CosmeticEvent`
- `EvidenceEvent`
- `FlashlightEvent`
- `LobbyEvent`
- `MatchEvent`
- `PurchaseEvent`
- `SanityEvent`

Namun script client lama masih menunggu remote yang tidak ada di repo:

- `SanityUpdate`
- `TemperatureUpdate`
- `EMFUpdate`

Di runtime juga muncul remote `SpectatorEvidence` yang dibuat saat boot, bukan source-controlled asset.

Implikasi:

- surface network tidak stabil
- debugging client sulit
- replayability dan spectator flow rawan drift dari repo

### 4. Flow match inti ada, tetapi dokumennya sebagian stale

Flow room ke match tetap ada dan aktif melalui `LobbySystem` dan `MatchSystem`.

Namun ada beberapa drift penting:

- beberapa dokumen lama masih mengasumsikan `MatchmakingSystem` dan `ServerQueueSystem` sebagai jalur utama
- durasi fase aktual sekarang `30 / 480 / 60 / 30`, bukan angka lama yang lebih pendek
- `AllEvidenceDiscovered` masih disubscribe, tetapi publisher aktifnya tidak terbukti ditemukan
- `GameplayLoopController` masih mengenal `Extraction`, sementara timed chain utama saat ini berakhir di `Endgame`

Implikasi:

- flow E2E harus diuji berdasarkan runtime nyata, bukan doc flow lama

### 5. Extraction masih berisiko mismatch

`MatchTeleport` meng-clone map ke `Workspace.ActiveMatches`, tetapi `HuntEscapeSystem` masih mendaftarkan extraction zone dari `Workspace.Maps`.

Implikasi:

- ada risiko pemain berada di map clone aktif tetapi extraction logic membaca zone dari tempat lain
- ini blocker E2E yang nyata

### 6. Ghost visual final belum terhubung ke gameplay inti

`GhostSystem` masih membuat placeholder visual procedural. Repo `ReplicatedStorage/Assets` belum berisi model ghost final yang source-controlled.

Saat ini:

- ghost loop backend ada
- config ghost ada
- model final belum menjadi bagian canonical dari runtime

Implikasi:

- import model di Studio belum otomatis berarti gameplay ghost siap
- integrasi harus menyentuh asset ownership, spawn path, scale, movement, dan replication

### 7. Asset placeholder masih nyata

Masih ada placeholder atau fallback yang belum production-ready:

- HUD vignette masih token
- heartbeat fallback masih token
- map preview placeholder masih ada
- beberapa audio di-sanitize ke ID fallback yang justru `403`

Implikasi:

- polish layer belum siap
- fallback saat ini bisa menutupi error tanpa benar-benar menyelesaikannya

### 8. Monetization concept ada, Roblox commerce bridge belum ada

Project punya:

- `EconomySystem`
- `ShopSystem`
- `RoyalPassSystem`
- `SocialCommerceSystem`
- data MM, PP, Robux di layer data

Tetapi scan source tidak menunjukkan integrasi Roblox commerce nyata:

- tidak ada `MarketplaceService`
- tidak ada `PromptGamePassPurchase`
- tidak ada `PromptProductPurchase`

Implikasi:

- konsep monetisasi ada
- monetisasi publish-ready belum ada

### 9. Persistence studio masih mock

Playtest log mengonfirmasi `DataPersistenceService` memakai in-memory/mock behavior di Studio.

Implikasi:

- test loop Studio belum memvalidasi persistence sesungguhnya
- publish readiness tidak boleh diasumsikan dari hasil Studio test saja

## Kesesuaian dengan Dokumen Utama

### Yang masih cocok

- `CANONICAL_SPECIFICATIONS_v2.md` masih berguna sebagai target desain
- `REPORTS.md` masih berguna sebagai status ringkas lintas sistem
- `Asset Import Guide/reports/ASSET_AUDIT.md` masih tepat untuk menunjukkan gap asset placeholder

### Yang perlu direvisi terhadap runtime

- asumsi bahwa hanya beberapa sistem inti yang benar-benar aktif
- flow match lama yang masih terlalu menonjolkan queue/matchmaking lama
- ekspektasi extraction phase yang sepenuhnya sinkron dengan kode aktif
- asumsi bahwa UI tertentu belum ada sama sekali, padahal sebagian dibangun terpusat di `src/client/UI/Main.lua`

## Status Nyata Proyek Hari Ini

### Sudah ada

- boot server yang konsisten
- banyak subsystem backend
- room flow dasar
- phase manager dasar
- config ghost, evidence, contract, economy
- jalur live inspect/test melalui MCP
- jalur local-to-Studio melalui Rojo

### Belum beres

- owner client tunggal
- canonical remote surface
- one-map one-ghost vertical slice yang bersih
- extraction yang sinkron dengan map clone aktif
- audio fallback yang valid
- asset ghost dan tool final yang source-controlled
- UI Royal Pass dan beberapa surface frontend yang masih kosong atau placeholder
- monetization bridge Roblox
- publish gate dan QA matrix yang disiplin

## Putusan Kerja

Mulai titik ini, semua task harus mengacu pada prinsip berikut:

- runtime nyata lebih tinggi prioritasnya daripada doc lama
- sebelum menambah fitur, bersihkan drift owner utama
- target teknis pertama adalah vertical slice playable, bukan content expansion
- semua perubahan Studio-only harus kembali ke repo sebelum dianggap selesai

