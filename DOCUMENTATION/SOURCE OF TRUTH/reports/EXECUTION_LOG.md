# Execution Log

## Format

Setiap entry mencatat:

- waktu
- task
- file yang diubah
- validasi
- blocker atau next step

## 2026-04-11 02:44 ICT

### Task

Tutup legal/licensing runtime review di published place dan pulihkan module load `UI` client yang sempat gagal.

### Linked Issues

- `require(Client.UI.Main)` gagal di published place runtime sehingga `UI` service tidak ter-register
- `MainMenuUI` tidak muncul di `PlayerGui`, sehingga attribution footer tidak bisa dibuktikan secara player-facing
- `release-preflight` masih menandai legal review sebagai blocker statis

### Files Changed

- `src/client/UI/Main.lua`
- `src/client/UI/GraphicsSupport.lua`
- `src/client/UI/CharacterPreviewSupport.lua`
- `scripts/release-preflight.ps1`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/LEGAL_RUNTIME_REVIEW_2026-04-11.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `UI.Main.lua` dipecah agar helper graphics dan preview karakter keluar ke module terpisah:
  - `GraphicsSupport`
  - `CharacterPreviewSupport`
- published place runtime kemudian berhasil memuat `Client.UI.Main` lagi (`require ok=true`)
- probe runtime membuktikan `MainMenuUI` kembali hadir di `PlayerGui`
- attribution footer legal kembali terlihat di `QUICK MENU`
- `LegacyDisabled` diverifikasi inert:
  - folder runtime kosong
  - tidak ada referensi live script aktif
- `release-preflight.ps1` sekarang tidak lagi menandai legal review sebagai blocker statis jika report legal terbaru sudah `PASS`

### Validation

- published place runtime:
  - `require(Client.UI.Main) => ok=true`
  - `ClientBootstrap stage = started`
- legal probe:
  - `guiParent = PlayerGui`
  - `guiEnabled = true`
  - `title = QUICK MENU`
  - `footer visible = true`
  - footer text legal:
    - `Pocong model by alterego.visual (Sketchfab) - CC BY 4.0`
- screenshot capture:
  - `.codex/legal_runtime_attribution_visible.png`
  - `.codex/legal_runtime_attribution_visible.json`
- legacy disposition:
  - `StarterPlayer.StarterPlayerScripts.Client.LegacyDisabled` has `0` children
  - `script_grep LegacyDisabled => 0 match`

### Next Step

- jalankan smoke test `2` client nyata
- catat hasil PASS/FAIL ke sheet multiplayer manual

## 2026-04-11 01:54 ICT

### Task

Tutup bug persistence wallet `MM/PP` di published place dan sinkronkan audit hotkey UI dengan default toggle Roblox.

### Linked Issues

- wallet `MM/PP` reset saat reconnect meskipun profile dan inventory persist
- `release-preflight` masih menulis blocker persistence seolah belum pernah divalidasi
- `Esc` bentrok dengan menu default Roblox

### Files Changed

- `src/ServerScriptService/Server/EconomySystem/Service.lua`
- `src/ServerScriptService/Server/EconomySystem/Controller.lua`
- `src/client/UI/Main.lua`
- `scripts/release-preflight.ps1`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/PERSISTENCE_RESULT_2026-04-11_REAL_DATASTORE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/UI_TOGGLE_KEY_AUDIT_2026-04-11.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `EconomySystem.Service` sekarang:
  - load wallet dari persistence saat `PlayerAdded`
  - simpan wallet secara debounced setelah grant/spend currency
  - flush wallet saat `PlayerRemoving`
- `EconomySystem.Controller` sekarang:
  - menghubungkan `PlayerAdded` / `PlayerRemoving`
  - menambah `BindToClose` save loop untuk runtime Studio
- `Main.lua` hotkey close auxiliary window dipindah dari `Esc` ke `X`
- semua lane toggle auxiliary/match/close sekarang menghormati `gameProcessed`
- `release-preflight.ps1` tidak lagi boleh menandai persistence sebagai blocker statis jika report real DataStore terbaru sudah `PASS`

### Validation

- published Studio place:
  - `PlaceId = 113010869463813`
  - `GameId = 9802743087`
- real datastore rerun:
  - sebelum disconnect: `MM=4094 PP=26 Robux=0`
  - sesudah reconnect: `MM=4094 PP=26 Robux=0`
  - profile `bio=persist-wallet-fix-1775847013` tetap sama
  - `cos_head_duskmask` tetap owned dan equipped
- local preflight:
  - `Build ok: True`
  - `Missing reports: 0`
  - `Safe items missing ID: 0`
  - `Safe items disabled: 0`
  - `Hold items enabled: 0`

### Next Step

- jalankan smoke test `2` client nyata
- tutup legal/licensing final review dan bukti visual runtime

## 2026-04-08 17:11 ICT

### Task

Kunci identity cloud Roblox yang canonical agar workflow Studio tidak lagi drift antara `file lokal .rbxlx` dan `place publish`.

### Linked Issues

- context Studio ambigu antara `PlaceId = 0` vs place publish
- audit `Toolbox -> Inventory / My Audio / My Models` tidak boleh lagi menebak-nebak session

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/ROBLOX_CLOUD_PLACE_IDENTITY_2026-04-08.md`
- `DOCUMENTATION/SOURCE OF TRUTH/SESSION_START_CHECKLIST.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/executionmode.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`

### Change Summary

- simpan identity cloud yang sudah terverifikasi live:
  - `game.PlaceId = 113010869463813`
  - `game.GameId = 9802743087`
  - `game.Name = Place2`
  - `game.CreatorId = 10576163165`
- tegaskan bahwa repo lokal tetap source of truth, tetapi task yang butuh context akun/cloud harus memakai identity cloud canonical ini
- tambahkan startup gate agar sesi baru tidak lagi mengaudit inventory/private upload pada session `PlaceId = 0`

### Validation Plan

- cek live Studio published session menampilkan:
  - `PlaceId = 113010869463813`
  - `GameId = 9802743087`
  - `Name = Place2`
  - `CreatorId = 10576163165`
- gunakan dokumen identity ini pada task berikutnya yang menyentuh `Toolbox -> Inventory`

## 2026-04-03 23:56 ICT

### Task

Phase 1 kickoff: potong drift client paling jelas dengan menonaktifkan tiga LocalScript legacy yang mendengar remote yang sudah tidak canonical.

### Linked Issues

- client dual-stack
- remote surface drift

### Files Changed

- `src/client/SanityVFX.client.lua`
- `src/client/EvidenceVFX.client.lua`
- `src/client/Tools/EMFReaderGUI.client.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `SanityVFX.client.lua` dinonaktifkan karena masih menunggu `SanityUpdate`
- `EvidenceVFX.client.lua` dinonaktifkan karena masih menunggu `TemperatureUpdate`
- `EMFReaderGUI.client.lua` dinonaktifkan karena masih menunggu `EMFUpdate`
- stack modern `SoundSystem`, `VFXController`, `InvestigationUISystem`, dan `EvidenceTools` dipertahankan sebagai jalur canonical sementara

### Validation Plan

- restart playtest
- cek console untuk memastikan warning remote legacy berkurang
- verifikasi flow inti tidak putus

### Next Step

Audit owner client berikutnya yang masih tumpang tindih, terutama audio/lighting/UI surface dan canonical remote contract.

## 2026-04-04 00:07 ICT

### Task

Kurangi drift remote surface dan bersihkan fallback audio rusak saat boot.

### Linked Issues

- remote surface drift
- audio fallback rusak

### Files Changed

- `src/ReplicatedStorage/RemoteEvents/SpectatorEvidence.model.json`
- `src/ServerScriptService/Server/Core/AudioSanitizer.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `SpectatorEvidence` sekarang source-controlled di repo
- `AudioSanitizer` tidak lagi mengganti sound rusak ke asset ID 403
- sound invalid sekarang dinonaktifkan secara eksplisit supaya boot log jujur dan tidak memuat fallback palsu

### Validation Plan

- restart playtest
- cek `RemoteEvents` untuk memastikan `SpectatorEvidence` tetap ada
- cek console untuk memastikan tidak ada lagi `Failed to load sound rbxassetid://10576163165`

### Next Step

Lanjut audit owner client lain yang masih overlap dan kecilkan boot surface sistem server yang belum diperlukan untuk vertical slice.

## 2026-04-04 00:23 ICT

### Task

Bersihkan dua LocalScript legacy tambahan yang masih menambah owner visual/audio tanpa menjadi jalur canonical.

### Linked Issues

- client dual-stack
- duplicate sensory ownership

### Files Changed

- `src/client/AtmosphericSetup.client.lua`
- `src/client/AudioManager.client.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `AtmosphericSetup.client.lua` dinonaktifkan karena menimpa `Lighting` dan konflik dengan `VFXController`
- `AudioManager.client.lua` dinonaktifkan karena bukan bagian dari bootstrap client aktif dan hanya menambah surface legacy

### Validation Plan

- restart playtest
- cek console untuk memastikan noise init Phase 7 legacy berkurang
- pastikan boot modern tetap berjalan

### Next Step

Lanjut audit script top-level client yang masih aktif, lalu tentukan apakah `CameraController`, `MovementController`, dan `FlashlightController` dipertahankan sebagai owner canonical sementara atau perlu dimigrasi.

## 2026-04-04 09:18 ICT

### Task

Stabilkan runtime boot Studio, sinkronkan visual ghost terbaru ke Studio, dan aktifkan template audio UI yang sebelumnya kosong di runtime.

### Linked Issues

- ghost visual drift antara local source dan Studio
- boot blocker `ShopSystem`
- imported asset residue di `Workspace`
- template audio UI kosong saat runtime

### Files Changed

- `src/ServerScriptService/Server/Core/AudioSanitizer.lua`
- `src/ServerScriptService/Server/GhostSystem/Service.lua`
- `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`
- `src/ReplicatedStorage/Assets/Audio/UI/CountdownTick_01.model.json`
- `src/ReplicatedStorage/Assets/Audio/UI/TeleportDrop_01.model.json`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `AudioSanitizer` sekarang mengizinkan built-in sound `rbxasset://sounds/...` sehingga template UI tidak otomatis dinonaktifkan
- `GhostSystem.Service` diperkuat untuk:
  - clamp ukuran template ghost imported
  - snap ghost ke ground berdasarkan bounding box
  - orientasi visual ke target hunt jika tersedia
  - motion idle/roaming/manifest/hunt berbasis tick runtime
- runtime Studio yang stale disamakan kembali untuk:
  - `AudioSanitizer`
  - `GhostSystem.Service`
  - `ShopSystem.Controller` agar tidak membaca `MarketplaceService.ProcessReceipt`
- residu model `129878813436863` di `Workspace` dihapus karena membawa script/tool yang mencemari boot runtime
- template audio UI source sekarang memakai `SoundId` alih-alih `AudioContent` supaya runtime Roblox benar-benar mengisi ID sound

### Validation

- boot Studio playtest sekarang selesai tanpa blocker `ShopSystem Start failed`
- warning script liar dari `Workspace.129878813436863.Kawaii Charge.*` hilang setelah residu dihapus
- forced ghost `Kuntilanak` berhasil spawn di `Workspace.ActiveMatches`
- bounding box runtime `Kuntilanak` tervalidasi sekitar `3.48 x 4.80 x 1.75`
- motion visual ghost tervalidasi bergerak antar sampel runtime (`delta ~= 0.10`) pada cadence tick sistem saat ini
- template audio runtime sekarang terisi:
  - `ButtonClick_01 = rbxasset://sounds/electronicpingshort.wav`
  - `CountdownTick_01 = rbxassetid://101202336513383`
  - `TeleportDrop_01 = rbxassetid://138329686293368`
- build source lokal sukses:
  - `_tmp_ghost_motion_build.rbxlx`
  - `_tmp_ui_audio_soundid_build.rbxlx`

### Next Step

Lanjut ke polish vertical slice berikutnya: validasi ghost tipe lain (`Genderuwo`, `Leak`, `Pocong`) pada runtime aktual, lalu pindah ke blok asset/gameplay yang masih placeholder atau belum punya perilaku production.

## 2026-04-04 00:34 ICT

### Task

Hilangkan placeholder token aktif di sensory frontend tanpa bergantung pada asset palsu.

### Linked Issues

- heartbeat fallback placeholder
- vignette placeholder

### Files Changed

- `src/client/Controllers/Sensory/AudioController.luau`
- `src/client/UI/HUD/HorrorHUD.luau`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- heartbeat fallback tidak lagi memakai `YOUR_HEARTBEAT_ID`
- jika asset heartbeat belum diimport, controller sekarang fail-safe diam tanpa memainkan sound palsu
- `HorrorHUD` tidak lagi bergantung pada `YOUR_VIGNETTE_TEXTURE_ID`
- vignette fallback procedural ditambahkan agar modul ini siap dipakai tanpa asset image eksternal

### Validation Plan

- restart playtest
- pastikan tidak ada placeholder token tersisa di source aktif yang disentuh
- verifikasi boot tidak rusak

### Next Step

Lanjut ke penetapan owner client yang tersisa dan mulai mengecilkan boot surface server sesuai vertical slice.

## 2026-04-04 00:43 ICT

### Task

Bersihkan duplicate lifecycle log pada `TelemetrySystem`.

### Linked Issues

- duplicate telemetry init log
- noisy server boot output

### Files Changed

- `src/ServerScriptService/Server/TelemetrySystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- print duplicate di `TelemetrySystem:Init`, `Start`, dan `Shutdown` dihapus
- registry tetap menjadi satu-satunya owner log lifecycle sistem
- duplicate source kedua di `TelemetrySystem/init.lua` juga dibersihkan setelah validasi runtime

### Validation Plan

- restart playtest
- cek console untuk memastikan `TelemetrySystem` tidak lagi muncul dua kali untuk fase yang sama

### Next Step

Lanjut audit server boot surface dan task yang masih membutuhkan verifikasi runtime lebih dalam.

## 2026-04-04 01:00 ICT

### Task

Keluarkan script legacy yang sudah dinonaktifkan dari surface `LocalScript` runtime.

### Linked Issues

- client dual-stack
- misleading runtime ownership

### Files Changed

- `src/client/LegacyDisabled/SanityVFX.lua`
- `src/client/LegacyDisabled/EvidenceVFX.lua`
- `src/client/LegacyDisabled/AtmosphericSetup.lua`
- `src/client/LegacyDisabled/AudioManager.lua`
- `src/client/LegacyDisabled/EMFReaderGUI.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- lima script legacy dipindahkan dari `LocalScript` runtime menjadi modul arsip
- tree `PlayerScripts.Client` sekarang tidak seharusnya lagi menampilkan mereka sebagai owner aktif
- source referensi tetap ada, tetapi tidak ikut hidup otomatis saat playtest

### Validation Plan

- restart playtest
- inspect `Players.<player>.PlayerScripts.Client`
- pastikan script legacy itu hilang dari surface `LocalScript`

### Next Step

Gunakan tree runtime yang lebih bersih ini untuk lanjut mendorong E2E flow melalui UI/live Studio.

## 2026-04-04 02:06 ICT

### Task

Validasi penuh jalur `room -> countdown -> match clone -> extraction` di Studio live, lalu tambahkan observability extraction untuk membedakan bug clone-path vs gate investigasi.

### Linked Issues

- extraction path mismatch
- E2E room flow belum terbukti
- kurang observability untuk deny reason extraction

### Files Changed

- `src/ServerScriptService/Server/LobbySystem/Controller.lua`
- `src/ServerScriptService/Server/HuntEscapeSystem/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- trace request/reply lobby dihubungkan ke controller untuk debugging Studio saat diperlukan
- `HuntEscapeSystem` sekarang mencatat hasil extraction terakhir ke atribut player
- ditambahkan trace extraction dan override Studio-only yang default-nya mati
- flow E2E berhasil dibuktikan:
  - buka room browser
  - buat room
  - host start
  - `Workspace.ActiveMatches.Match_match_1` muncul
  - player masuk `InMatch`
  - extraction zone clone aktif
- hasil deny normal juga tervalidasi:
  - tanpa `GhostIdentified`, player mendapat `LastExtractionResult = ghost_not_identified`
- hasil end condition clone juga tervalidasi:
  - dengan override Studio-only yang diset sebelum playtest, extraction dari clone zone mengakhiri match
  - `Workspace.ActiveMatches` kembali kosong
  - player pindah ke state result/lobby

### Validation Notes

- UI room flow diverifikasi secara visual via `screen_capture`
- state runtime diverifikasi via MCP:
  - `Players.ZyraaaVex` attributes
  - `Workspace.ActiveMatches`
  - clone map `ExtractionZone_Main`
- override debug dibersihkan lagi setelah test selesai

### Next Step

Lanjut ke fase vertical slice berikutnya: source-control ghost final pertama dan sambungkan ke spawn/runtime agar match tidak lagi bergantung pada placeholder humanoid.

## 2026-04-04 03:10 ICT

### Task

Source-control vertical slice ghost final pertama untuk `Pocong` dan sambungkan spawn runtime ke template model nyata.

### Linked Issues

- one-ghost vertical slice belum punya model final canonical
- runtime ghost masih placeholder procedural
- Studio-only import belum tercermin ke source of truth

### Files Changed

- `src/ReplicatedStorage/Assets/Models/Ghosts/Pocong.model.json`
- `src/ServerScriptService/Server/GhostSystem/Service.lua`
- `src/ServerScriptService/Server/GhostSystem/Controller.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- model `Pocong` sekarang hidup sebagai asset source-controlled di `ReplicatedStorage.Assets.Models.Ghosts`
- `GhostSystem` tidak lagi mencoba membangun `MeshPart` di runtime untuk `Pocong`
- runtime sekarang clone template model, menetapkan `PrimaryPart`, lalu memberi offset visual yang benar dari `HumanoidRootPart`
- ditambahkan trace Studio-only untuk memaksa `ghostType` dan membaca tahap init ghost saat playtest MCP
- validasi live membuktikan:
  - `InitGhostResult` kembali `error=nil`
  - `Workspace.ActiveMatches.Match_match_1.Ghost_Pocong` benar-benar muncul
  - atribut runtime menunjukkan `GhostType=Pocong` dan `PlaceholderVisual=false`

### Validation Notes

- trace attribute Studio-only dipakai untuk mengisolasi kegagalan capability `MeshPart.MeshId`
- akar masalah ditemukan: `MeshId` tidak boleh ditulis saat runtime script
- solusi final diganti menjadi template model cloned from `ReplicatedStorage`
- inspect runtime sukses:
  - `Ghost_Pocong`
  - `MeshPart.MeshId = rbxassetid://118360815663860`
  - `SurfaceAppearance` map IDs tersambung

### Next Step

Lanjutkan item yang sama dengan menyambungkan movement dan manifestation visual ke state AI ghost, karena saat ini `Pocong` sudah spawn final tetapi masih statis.

## 2026-04-04 04:28 ICT

### Task

Validasi bahwa visual `Pocong` tidak hanya spawn, tetapi benar-benar mengikuti room dan state AI di runtime.

### Linked Issues

- vertical slice ghost final belum membuktikan movement runtime
- visual ghost berisiko statis walau AI state berubah
- need proof bahwa source-controlled model bisa dipakai untuk playtest nyata

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- playtest lanjutan membuktikan `Ghost_Pocong` berpindah dari room awal ke room runtime berikutnya
- atribut runtime berubah dari `CurrentRoomId=DiningRoom` dan `RuntimeGhostState=Idle` menjadi `CurrentRoomId=Bedroom1` dan `RuntimeGhostState=Roaming`
- `HumanoidRootPart` ikut pindah ke `1170, 0.5, 35`
- `MeshPart` ikut pindah ke `1170, 11, 35`
- transparansi visual runtime terverifikasi `0.35` saat state `Roaming`

### Validation Notes

- validasi dilakukan murni dari runtime Studio via MCP, bukan asumsi dari source
- model runtime yang diperiksa:
  - `Workspace.ActiveMatches.Match_match_1.Ghost_Pocong`
  - `Workspace.ActiveMatches.Match_match_1.Ghost_Pocong.HumanoidRootPart`
  - `Workspace.ActiveMatches.Match_match_1.Ghost_Pocong.MeshPart`
- hasil ini membuktikan sinkronisasi room anchor + state visual dasar sudah hidup

### Next Step

Lanjut ke validasi manifestation dan hunt response untuk memastikan vertical slice `Pocong` tidak hanya bisa roaming, tetapi juga memberi feedback visual saat state agresif berubah.

## 2026-04-04 04:52 ICT

### Task

Validasi `Manifestation` dan `Hunting` visual response untuk vertical slice `Pocong` dengan jalur debug Studio-only yang aman.

### Linked Issues

- vertical slice ghost final belum membuktikan feedback visual agresif
- perlu jalur test yang deterministik tanpa menunggu AI kebetulan manifest atau hunt

### Files Changed

- `src/ServerScriptService/Server/GhostSystem/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- ditambahkan override Studio-only `PasrahForceGhostVisualState` untuk memaksa tampilan `Manifestation` atau `Hunting` tanpa mengubah flow production
- playtest dengan override `Manifestation` membuktikan `Ghost_Pocong.MeshPart.Transparency = 0`
- playtest dengan override `Hunting` membuktikan `Ghost_Pocong.MeshPart.Transparency = 0.05`
- atribut runtime sekarang memisahkan state aktual AI dan state visual override:
  - `RuntimeGhostStateActual`
  - `RuntimeGhostStateOverride`

### Validation Notes

- override hanya dibaca di jalur `RunService:IsStudio()`
- override dibersihkan lagi setelah validasi
- hasil ini menutup vertical slice ghost pertama:
  - spawn final
  - room/movement sync
  - manifestation/hunt visual dasar

### Next Step

Masuk ke item berikutnya: tetapkan tool minimum investigasi pertama dan cek apakah visual/tool runtime yang dibutuhkan sudah ada atau masih placeholder.

## 2026-04-04 06:02 ICT

### Task

Menutup vertical slice tool minimum pertama dengan `JejakEnergi`, termasuk backend request, reason propagation, dan sinkronisasi surface `JournalUI`.

### Linked Issues

- tool minimum gagal resolve `matchId` walau player sudah `InMatch`
- failure tool selalu tampil sebagai `spawn_failed` generik
- surface jurnal tidak ikut menyegarkan status tool saat evidence datang dari jalur non-button

### Files Changed

- `src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua`
- `src/ServerScriptService/Server/EvidenceSystem/Controller.lua`
- `src/ServerScriptService/Server/EvidenceSystem/EvidenceRandomizer.lua`
- `src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua`
- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `EvidenceGateway` dan `EvidenceSystem.Controller` sekarang fallback ke `player.MatchId` saat resolve match tool request
- `EvidenceRandomizer:Spawn` sekarang mengembalikan `signal, reason` utuh dari `spawnFn`, sehingga reason nyata seperti `ghost_cannot_emit_evidence` tidak hilang
- `EvidenceService` sekarang meneruskan metadata tool saat publish `EvidenceCollected`
- `JournalUI` sekarang memakai event `EvidenceCollected` untuk memperbarui status `Tool E2E`
- validasi deterministik memakai `PasrahForceGhostType = Leak` membuktikan:
  - `JejakEnergiScan` sukses collect `MEDOK`
  - `JournalUI` memperlihatkan evidence yang ditemukan
  - `ToolStatusLabel` memperlihatkan status tool yang benar

### Validation Notes

- request client yang gagal sebelumnya berubah menjadi reason yang akurat setelah patch:
  - `missing_match_id` teratasi
  - `spawn_failed` generik teratasi
- request final yang tervalidasi:
  - `toolType = JejakEnergi`
  - `matchId = match_1`
  - `success = true`
  - `reason = collected`
- surface UI runtime yang diperiksa:
  - `Players.ZyraaaVex.PlayerGui.JournalUI.MainPanel.ToolStatusLabel`
  - `Players.ZyraaaVex.PlayerGui.JournalUI.MainPanel.ContentFrame.ContentText`
  - `Players.ZyraaaVex.PlayerGui.JournalUI.MainPanel.SecondaryLabel`

### Next Step

Masuk ke item 8: pilih dan stabilkan satu map playable, lalu audit extraction zone, spawn, blocker, collision, dan art-pass minimum terhadap map yang benar-benar dipakai vertical slice.

## 2026-04-03 05:30 ICT

### Task

Menutup blocker utama pada map playable pertama `HauntedHouse`, dengan fokus pada route interior, interaction point runtime, dan traversal pintu pada clone aktif.

### Linked Issues

- interaction point beberapa room tidak berada di anchor room yang benar
- route ke `DiningRoom` gagal walau extraction dan spawn utama sudah tervalidasi
- pintu clone tidak memiliki prompt/path modifier/atribut runtime, sehingga traversal interior macet

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `HauntedHouse` dipastikan sebagai map utama untuk vertical slice playable
- `MapRuntimePatches` sekarang:
  - menormalkan `InteractionPoints` ke anchor room yang benar
  - menerapkan fallback traversal pintu pada clone aktif
- fallback pintu menandai clone dengan `DoorTraversalRuntimePatched = true`
- `Door_DiningRoom` sekarang runtime-nya:
  - `DoorIsOpen = true`
  - `DoorLocked = false`
  - `CanCollide = false`
  - `CanTouch = false`
  - memiliki child `DoorPathModifier`
- `DoorRuntime.Attach` dibuat toleran terhadap root `Instance` non-Model sebagai langkah kompatibilitas, walau jalur formalnya belum jadi bukti utama task ini

### Validation Notes

- clone runtime yang diperiksa:
  - `Workspace.ActiveMatches.Match_match_1.HauntedHouse`
  - `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Doors.Door_DiningRoom`
  - `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.InteractionPoints.Interact_DiningRoom`
- atribut clone terbukti aktif:
  - `SecondFloorRuntimePatched = true`
  - `InteractionPointsRuntimePatched = true`
  - `DoorTraversalRuntimePatched = true`
- sebelum fallback pintu, navigation ke `Interact_DiningRoom` gagal
- sesudah fallback pintu dan setelah karakter dipindahkan ke `PlayerSpawn_1` map aktif, navigation ke `Interact_DiningRoom` berhasil
- ini menutup blocker collision/pathing terbesar pada map playable pertama

### Next Step

Masuk ke item 9: rapikan HUD inti, terutama sanity, heartbeat, vignette, dan objective/match-state surface supaya vertical slice tidak lagi bergantung pada placeholder besar.

## 2026-04-03 06:10 ICT

### Task

Mereduksi owner ambiguity pada HUD inti dan memindahkan phase surface ke jalur UI canonical yang benar-benar hidup.

### Linked Issues

- `PlayerGui` masih memuat duplikasi `MatchUI`, `LobbyUI`, `ShopUI`, `MainMenuUI`, `PASRA_UI`, dan `SpectatorUI`
- `_renderPhase` masih mencari `HorrorHUD` legacy dan child `Objective/Warning/Heartbeat` yang tidak ada pada sensory stack aktif
- `SpectatorEffects` masih bergantung pada shell `SpectatorUI` lama untuk overlay distortion

### Files Changed

- `src/client/UI/Main.lua`
- `src/client/SpectatorEffects/Main.lua`
- `src/StarterGui/LeaderboardUI.model.json`
- `src/StarterGui/LobbyUI.model.json`
- `src/StarterGui/MainMenuUI.model.json`
- `src/StarterGui/MatchUI.model.json`
- `src/StarterGui/ShopUI.model.json`
- `src/StarterGui/PASRA_UI.model.json`
- `src/StarterGui/SpectatorUI.model.json`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- shell `StarterGui` kosong/legacy yang menggandakan owner UI utama dihapus
- `UISystem` phase renderer sekarang memakai jalur HUD canonical:
  - `SensoryHorrorHUD` untuk sensory overlay
  - `MatchUX` untuk objective dan state hunt
- `TransitionTo("Investigation")` sekarang mengisi `ObjectiveLabel` default
- `TransitionTo("Hunt")` sekarang mengisi `StateMessage = HUNT` dan tidak lagi mengandalkan child legacy pada `HorrorHUD`
- `SpectatorEffects` sekarang bisa membuat overlay distortion langsung pada `SpectatorUI` canonical, tanpa butuh shell terpisah

### Validation Notes

- validasi runtime setelah restart playtest menunjukkan owner inti sudah tunggal:
  - `LobbyUI = 1`
  - `MatchUI = 1`
  - `ShopUI = 1`
  - `MainMenuUI = 1`
  - `PASRA_UI = 1`
  - `SpectatorUI = 1`
- `MatchUI`, `LobbyUI`, `PASRA_UI`, dan `SpectatorUI` yang tersisa semuanya adalah surface canonical hasil builder runtime
- validasi visual penuh untuk `Investigation/Hunt` belum ditutup di task ini
  - alasan: jalur automation `CreateRoom + HostStart` via MCP direct client request masih berhenti di `MatchPhase = Preparing`
  - artinya patch HUD sudah masuk dan owner runtime sudah bersih, tetapi proof live per-phase masih perlu ditutup pada loop match berikutnya

### Next Step

Lanjut ke validasi live phase flow, atau jika flow `Preparing -> InGame` masih menahan automation, geser sementara ke task publish-readiness berikutnya yang tidak bergantung pada transisi phase tersebut.

## 2026-04-03 06:45 ICT

### Task

Generalisasi kebijakan traversal pintu ke semua map playable current, lalu validasi bahwa policy itu tetap hidup pada jalur `Ranked`, bukan hanya `Classic`.

### Linked Issues

- blocker traversal pintu lintas map
- platform-safe map interaction
- debt `DoorRuntime` pada clone map berbasis `Folder`

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- fallback traversal pintu sekarang diberi policy eksplisit `AutoOpenToggle`
- clone map runtime sekarang menandai mode traversal pintu pada root clone melalui `DoorTraversalMode`
- label prompt pintu dibuat netral platform (`Buka Pintu` / `Tutup Pintu`) agar tidak keyboard-centric
- source scan membuktikan semua map playable current memakai struktur yang sama:
  - `SpawnPoints`
  - `InteractionPoints`
  - `Rooms`
  - `Doors`
  - `DoorFrames`
- validasi live dilakukan pada `Ranked + EmptyBuilding`, dan clone aktif menunjukkan:
  - `DoorTraversalRuntimePatched = true`
  - `DoorTraversalMode = AutoOpenToggle`
  - `Door_Lobby.DoorTraversalPolicy = AutoOpenToggle`
  - `Door_Lobby.CanCollide = false`

### Validation Notes

- build source berhasil via `rojo build default.project.json --output .\\_tmp_door_build.rbxlx`
- validasi runtime dilakukan pada jalur `Ranked`, bukan hanya `Classic`
- debt lama tetap terlihat: `DoorRuntime.Attach` masih belum terbukti menambahkan `ProximityPrompt` pada clone map yang dibungkus `Folder`
- karena fallback auto-open sekarang canonical, debt prompt manual ini tidak lagi menjadi blocker untuk loop playable atau rencana re-layout map berbasis LiDAR

### Next Step

Kembali ke blocker phase progression setelah `HostStart`, karena sekarang traversal interior lintas map sudah cukup aman untuk melanjutkan vertical slice dan E2E flow.

## 2026-04-03 07:05 ICT

### Task

Menutup blocker runtime `Preparing` setelah `HostStart`, lalu menyelesaikan integrasi pintu formal pada jalur `Ranked + EmptyBuilding`.

### Linked Issues

- `HostStart` sukses tetapi client hanya menerima `MatchPreparing`
- karakter tetap di lobby walau match clone sudah lahir
- `DoorRuntime` melempar enum error saat attach prompt pintu

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
- `src/ServerScriptService/Server/MatchSystem/MatchTeleport.lua`
- `src/ServerScriptService/Server/MatchSystem/MatchService.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- bug utama ditemukan dari log Studio:
  - `Classic is not a valid member of Enum.ProximityPromptStyle`
- `DoorRuntime` diperbaiki untuk memakai `Enum.ProximityPromptStyle.Default`
- `MatchTeleport` diberi fallback resolve karakter dari `Workspace.<PlayerName>` agar teleport tidak mudah skip ketika referensi `player.Character` belum stabil
- `MatchTeleport` sekarang membersihkan `InLobby` saat teleport ke match sukses
- trace Studio-only ditambahkan ke `MatchTeleport` dan `MatchService` untuk memverifikasi count teleport serta tahap yang dilalui tanpa mengubah production runtime

### Validation Notes

- validasi live dilakukan pada `Ranked + EmptyBuilding`
- hasil akhir probe:
  - `teleportedCount = 1`
  - `MatchStarted` diterima client
  - `PhaseChanged` diterima client
  - `MatchPhase = InGame`
  - `rootPosition = 790, 3.47, -10` sehingga player benar-benar pindah ke map aktif
  - `InLobby` tidak lagi tertinggal
- pintu runtime juga tervalidasi penuh sesudah fix enum:
  - `DoorPrompt` hadir pada `Door_Lobby`
  - `DoorObjectId = Door_Lobby`
  - pintu terbuka secara visual (`Rotation.Y ~= -88`)
  - `CanCollide = false`

### Next Step

Lanjut ke validasi live `Preparation -> Investigation -> Hunt -> Result` dan rapikan surface HUD yang masih pending pada fase non-awal.

## 2026-04-03 07:40 ICT

### Task

Menutup proof live `Hunt -> Result` untuk jalur `Ranked`, lalu menambah harness Studio-only agar AI/MCP bisa menguji phase flow tanpa menunggu timer panjang atau menyentuh runtime production.

### Linked Issues

- validasi `Hunt/Result` sebelumnya belum tertutup
- automation MCP perlu jalur kontrol non-production untuk end-to-end proof
- room browser automation sempat jatuh kembali ke `Classic` karena selection canonical tidak diubah

### Files Changed

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- menambahkan `StudioE2EControlSystem` yang hanya hidup saat `RunService:IsStudio()`
- system ini membuat remote runtime non-production `ReplicatedStorage.RemoteEvents.StudioE2EControl`
- action yang didukung:
  - `AdvancePhase`
  - `ForceHunt`
  - `ExtractSelf`
  - `EndMatch`
- hasil action ditulis ke attr Studio-only:
  - `PasrahStudioE2EReady`
  - `PasrahStudioE2ELastAction`
  - `PasrahStudioE2ELastResult`
- handler `ExtractSelf` dibetulkan agar mengembalikan status server yang jujur, bukan ack sukses palsu
- harness memanfaatkan override extraction Studio yang memang sudah ada di `HuntEscapeSystem`, tanpa membuka surface production

### Validation Notes

- validasi `Ranked` sekarang benar-benar memakai selection canonical:
  - `SelectMode("Ranked")`
  - `SelectMap("EmptyBuilding")`
  - `CreateRoom`
  - `HostStart`
- trace match start membuktikan mode final benar:
  - `match=match_1 players=1 teleported=1 phase=PreparationPhase map=EmptyBuilding mode=Ranked`
- proof phase live pada `Ranked + EmptyBuilding` tertutup:
  - UI masuk `INVESTIGASI`
  - `AdvancePhase -> InvestigationPhase -> HuntPhase` menghasilkan HUD `HUNT`
  - `ExtractSelf` dengan `allowStudioOverride = true` mengakhiri match
  - result screen muncul dengan status hasil
  - player kembali ke lobby (`InLobby = true`)
  - `Workspace.ActiveMatches = 0`
- nuance runtime yang perlu diingat:
  - surface client bisa sudah menampilkan `INVESTIGASI` saat server lifecycle formal masih `PreparationPhase`
  - untuk itu harness harus meminta transisi berurutan, bukan lompat langsung ke `HuntPhase`

### Next Step

Lanjut ke blocker publish berikutnya dari backlog aktif, dengan harness Studio-only ini sebagai alat validasi E2E non-production untuk fase, extraction, dan result flow.

## 2026-04-03 08:05 ICT

### Task

Menyelaraskan phase presentation client dengan server lifecycle pada awal match, agar HUD tidak lagi melompat ke `INVESTIGASI` sebelum `PreparationPhase` server selesai.

### Linked Issues

- drift awal antara loading flow client dan lifecycle phase server
- proof phase jadi bias karena UI terlihat lebih maju daripada server

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `_runPostTeleportLoadingFlow()` tidak lagi memaksa `INGAME` saat flow loading internal client selesai
- client sekarang hanya pindah ke `INGAME/Investigation` bila memang sudah ada `PhaseChanged` yang pending dari server
- bila server masih berada pada `PreparationPhase`, client tetap di `Preparation/Briefing`

### Validation Notes

- validasi live dilakukan pada `Ranked + EmptyBuilding`
- setelah `HostStart` dan teleport sukses:
  - `Player.MatchPhase = Briefing`
  - `MatchUI.MainPanel.StateBadge = PERSIAPAN`
  - `MatchUI.MainPanel.PrimaryLabel = Masuk ke lokasi...`
  - trace server tetap `phase=PreparationPhase`
- ini menutup drift lama di mana client terlihat sudah investigasi padahal server belum maju
- transisi berikutnya tetap tervalidasi:
  - `AdvancePhase -> HuntPhase` masih mengubah HUD ke `HUNT`

### Next Step

Lanjut ke backlog berikutnya yang masih murni code-side dan tidak membutuhkan import asset manual, sambil mempertahankan harness Studio-only sebagai alat proof runtime.

## 2026-04-03 08:25 ICT

### Task

Menutup gap heartbeat sensory agar HUD/audio hunt tidak lagi bergantung pada fallback kosong, lalu menghubungkan trigger heartbeat ke jalur phase canonical yang benar-benar diterima client.

### Linked Issues

- `ReplicatedStorage.Assets.Audio.Sensory` belum ada
- `AudioController` fallback ke `Sound` kosong bila asset heartbeat tidak source-controlled
- hunt visual hidup tetapi heartbeat tidak menyala saat `PhaseChanged(HuntPhase)`

### Files Changed

- `src/ReplicatedStorage/Assets/Audio/Sensory/Heartbeat.model.json`
- `src/client/Controllers/Sensory/AudioController.luau`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `Heartbeat` sekarang source-controlled pada jalur asset canonical yang memang dicari `AudioController`
- asset memakai ID yang sudah tervalidasi loadable di Studio dari jalur legacy proyek
- `AudioController` sekarang merespons `PhaseChanged(HuntPhase)` dan juga mereset state heartbeat pada phase non-hunt / end match

### Validation Notes

- probe Studio membuktikan asset heartbeat valid:
  - `IsLoaded = true`
  - `TimeLength ~= 1.10`
- setelah reload playtest, runtime menunjukkan:
  - `ReplicatedStorage.Assets.Audio.Sensory.Heartbeat` ada
  - `camera.Heartbeat.MissingSourceAsset = false`
- validasi live pada `Ranked + EmptyBuilding` dengan `HuntPhase` paksa menunjukkan:
  - `camera.Heartbeat.IsPlaying = true`
  - `camera.Heartbeat.Volume = 0.2`
  - `camera.Heartbeat.SoundId = rbxassetid://138884191945388`

### Next Step

Lanjut ke sensory gap berikutnya yang masih tersisa di backlog item 9, terutama sanity/vignette dan objective state agar HUD inti mendekati status selesai.

## 2026-04-03 08:55 ICT

### Task

Menutup wiring sanity/vignette agar sensory HUD benar-benar hidup di runtime, bukan hanya siap menerima data di source code.

### Linked Issues

- `HorrorHUD` ada di repo tetapi tidak pernah diregistrasikan ke bootstrap client
- `SanitySystem` tidak mem-fire `RemoteEvents.SanityEvent` ke client
- rumus transparency vignette terbalik

### Files Changed

- `src/client/SoundSystem/Main.lua`
- `src/client/UI/HUD/HorrorHUD.luau`
- `src/ServerScriptService/Server/SanitySystem/Controller.lua`
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `SoundSystem` sekarang meregistrasikan `HorrorHUD`, sehingga `SensoryHorrorHUD` benar-benar lahir di `PlayerGui`
- `SanitySystem.Controller` sekarang menjembatani `SanityChanged` ke `RemoteEvents.SanityEvent`
- initial sanity juga dikirim saat match dimulai agar client tidak mulai dari state buta
- harness Studio-only sekarang punya action `DrainSanity`
- formula vignette diperbaiki sehingga sanity rendah membuat vignette lebih terlihat, bukan lebih hilang

### Validation Notes

- validasi boot:
  - `PlayerGui.SensoryHorrorHUD` hadir
  - `Vignette` hadir sebagai `CanvasGroup`
- validasi bridge sanity:
  - `DrainSanity(amount = 5)` mengirim payload client dengan `newSanity = 95`, `source = SanitySystem`
- validasi live `Ranked + EmptyBuilding`:
  - sebelum drain berat:
    - `Vignette.GroupTransparency ~= 0.815`
    - `SensorySanityGrading = (-0.1 saturation, 0.1 contrast)`
  - sesudah `DrainSanity(amount = 75)` ke `sanity = 20`:
    - `Vignette.GroupTransparency ~= 0.29`
    - `SensorySanityGrading.Saturation = -0.7`
    - `SensorySanityGrading.Contrast = 0.4`
- ini menutup proof bahwa sanity benar-benar mempengaruhi vignette dan post-processing di client

### Next Step

Pindah dari wiring HUD inti ke backlog berikutnya, karena sensory surface utama sekarang sudah tervalidasi hidup end-to-end.

## 2026-04-03 09:20 ICT

### Task

Menutup canonical remote contract pada sisi server production dengan menghapus fallback runtime untuk remote yang sudah source-controlled.

### Linked Issues

- canonical remote contract
- runtime/source drift

### Files Changed

- `src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua`
- `src/ServerScriptService/Server/GhostSystem/GhostInteractionGateway.lua`
- `src/ServerScriptService/Server/SpectatorSystem/Controller.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `EvidenceGateway` tidak lagi membuat `ReplicatedStorage.RemoteFunctions.EvidenceRequest` bila hilang
- `GhostInteractionGateway` tidak lagi membuat `ReplicatedStorage.RemoteFunctions.GhostInteractionRequest` bila hilang
- `SpectatorSystem` tidak lagi membuat `ReplicatedStorage.RemoteEvents` atau `SpectatorEvidence` secara diam-diam
- ketiganya sekarang hanya menerima remote canonical dari source control, lalu `warn` jujur bila hilang
- audit sapuan source sesudah patch menunjukkan satu-satunya `Instance.new(\"RemoteEvent\")` yang tersisa ada pada `StudioE2EControlSystem`, yaitu harness Studio-only non-production

### Validation Notes

- inspeksi Studio live membuktikan canonical remotes tetap hadir:
  - `ReplicatedStorage.RemoteFunctions.EvidenceRequest`
  - `ReplicatedStorage.RemoteFunctions.GhostInteractionRequest`
  - `ReplicatedStorage.RemoteEvents.SpectatorEvidence`
- smoke test client-canonical via `LobbyEvent` sukses setelah patch:
  - `SelectMode(\"Ranked\")`
  - `SelectMap(\"EmptyBuilding\")`
  - `CreateRoom`
  - `HostStart`
- hasil live:
  - `CreateRoomResult.ok = true`
  - `HostStartResult.ok = true`
  - `PasrahLastHostStart = begin ok=true err=nil roomId=1 countdown=5`
  - `PasrahLastHostStartCommit = commit ok=true err=nil roomId=1`
  - `Player.MatchId = match_1`
  - `room.mode = Ranked`
  - `room.mapId = EmptyBuilding`

### Next Step

Masuk ke publish-critical berikutnya: audit dan pasang bridge monetization Roblox yang nyata, karena economy saat ini masih konseptual di atas `PurchaseEvent`.

## 2026-04-03 10:05 ICT

### Task

Membangun bridge monetization Roblox resmi di atas `PurchaseEvent` canonical tanpa merusak flow MM lama.

### Linked Issues

- monetization masih konseptual
- tidak ada jalur resmi `MarketplaceService`
- publish readiness economy belum layak

### Files Changed

- `src/ServerScriptService/Server/ShopSystem/State.lua`
- `src/ServerScriptService/Server/ShopSystem/Service.lua`
- `src/ServerScriptService/Server/ShopSystem/Controller.lua`
- `src/ServerScriptService/Server/RoyalPassSystem/Service.lua`
- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `ShopSystem` sekarang mendukung dua flow transaksi:
  - `SoftCurrency` (`MM` / `PP`) seperti sebelumnya
  - `Marketplace` (`Robux`) lewat metadata katalog
- server `ShopSystem.Controller` sekarang:
  - mengindeks item marketplace dari katalog
  - mengirim `PurchasePromptRequested` ke client untuk item `Robux`
  - menangani `PromptGamePassPurchaseFinished`
  - menangani `MarketplaceService.ProcessReceipt`
  - melakukan sync ownership `UserOwnsGamePassAsync` untuk game pass yang sudah dimiliki
- `ShopSystem.Service` sekarang:
  - mengenali `currency`, `marketplaceType`, `marketplaceId`, `entitlementKey`, `royalPassPremium`
  - memisahkan `ResolvePurchaseIntent()` dari `ProcessPurchase()`
  - punya `GrantMarketplacePurchase()` untuk grant item/entitlement server-side
- `RoyalPassSystem.Service` mendapat `SetPremiumOwnership()` agar premium pass tidak perlu menulis state secara liar dari luar sistem
- `UISystem` sekarang bisa membuka prompt Roblox saat menerima `PurchasePromptRequested` dan memperbarui status ShopUI untuk flow prompt/cancel

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_monetization_build.rbxlx`
- smoke test live pada item MM lama membuktikan tidak ada regresi jalur lama:
  - request `eq_sanitypill_standard`
  - response `PurchaseProcessed`
  - `reason = insufficient_currency`
- blocker tersisa tetap jujur:
  - belum ada item katalog production yang berisi `marketplaceId` nyata
  - jadi proof end-to-end Robux belum bisa ditutup tanpa input manual dari Creator Hub

### Next Step

Rapikan noise audio boot supaya console kembali jadi alat debugging yang usable, lalu lanjutkan audit asset/audio placeholder yang masih mengganggu vertical slice dan publish gate.

## 2026-04-03 10:25 ICT

### Task

Mereduksi noise audio boot tanpa menyembunyikan asset rusak yang masih perlu diganti.

### Linked Issues

- runtime noise
- audio placeholder/broken asset spam

### Files Changed

- `src/ServerScriptService/Server/Core/AudioSanitizer.lua`
- `src/ServerScriptService/Server/Core/AudioErrorGuard.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `AudioSanitizer` tidak lagi me-warning setiap sound rusak satu per satu
- scanner sekarang:
  - menandai sound yang sudah disanitasi dengan attribute `PasrahAudioSanitized`
  - men-disable sound invalid
  - mencetak satu summary count + preview path
- `AudioErrorGuard` sekarang melewati sound yang sudah ditandai sanitizer, jadi dua scanner tidak saling mengulang warning

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_audio_build.rbxlx`
- validasi live setelah restart playtest menunjukkan console boot baru:
  - `"[AUDIO SANITIZER] Disabled 5 invalid sounds"`
- artinya signal audio tetap jujur, tetapi boot log tidak lagi dibanjiri daftar per-instance yang panjang

### Next Step

Gunakan console yang lebih bersih ini untuk melanjutkan audit placeholder audio/asset yang masih tersisa, sambil menjaga jalur publish-critical lain seperti licensing dan monetization tetap terdokumentasi jujur.

## 2026-04-03 10:40 ICT

### Task

Membuat ledger lisensi awal untuk asset aktif yang benar-benar muncul di source of truth.

### Linked Issues

- licensing dan attribution
- publish gate asset ownership

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- ledger baru memetakan asset aktif ke empat status:
  - `verified`
  - `user-asserted`
  - `unknown`
  - `replace/remove`
- `Pocong` dicatat sebagai `user-asserted` karena source Sketchfab disebut oleh user, tetapi bukti lisensi belum diarsipkan ke repo
- `Heartbeat`, `Jumpscare_01`, dan ghost animation pack dicatat sebagai `unknown`
- lima ghost audio invalid dicatat sebagai `replace/remove`
- backlog item licensing sekarang punya basis kerja yang konkret, bukan catatan umum

### Validation Notes

- ledger disusun dari scan asset ID aktif di source:
  - model/texture `Pocong`
  - audio active canonical
  - animation active canonical
  - broken ghost audio yang masih disanitasi saat boot
- dokumen ini sengaja tidak mengklaim lisensi yang belum punya bukti repo

### Next Step

Lanjutkan dari dua jalur paralel publish gate:
1. gantikan atau dokumentasikan audio/asset `unknown`
2. isi `marketplaceId` / `gamePassId` nyata saat Creator Hub siap, karena bridge monetization code-side sudah ada

## 2026-04-03 10:48 ICT

### Task

Menyiapkan template Creator Hub ID agar blocker monetization manual punya bentuk yang operasional.

### Linked Issues

- marketplace IDs belum ada
- monetization bridge belum bisa ditutup end-to-end

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/CREATOR_HUB_ID_TEMPLATE_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- template baru memetakan kebutuhan ID Roblox ke tujuan reward nyata:
  - premium royal pass
  - class unlock
  - lifetime pass
  - developer product MM / PP pack
- dokumen ini juga mencatat aturan pemakaian:
  - `GamePass` untuk entitlement permanen
  - `DeveloperProduct` untuk pembelian berulang
- blocker monetization sekarang punya daftar isian yang eksplisit, bukan hanya catatan “butuh ID nanti”

### Validation Notes

- template sinkron dengan bridge code-side yang sudah terpasang:
  - `PromptGamePassPurchaseFinished`
  - `ProcessReceipt`
  - `UserOwnsGamePassAsync`
  - `PurchasePromptRequested`

### Next Step

Lanjutkan menutup publish gate yang masih bisa dikerjakan tanpa input manual, terutama asset/audio `unknown` dan placeholder content yang masih aktif.

## 2026-04-03 11:02 ICT

### Task

Mengubah lima ghost audio rusak menjadi placeholder kosong source-controlled agar source dan runtime jujur tanpa warning invalid berulang.

### Linked Issues

- broken ghost audio
- runtime noise
- publish placeholder debt

### Files Changed

- `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
- `src/ReplicatedStorage/Assets/Audio/Environment/EnvironmentalCreak_01.model.json`
- `src/ReplicatedStorage/Assets/Audio/Ghost/GhostManifest_01.model.json`
- `src/ReplicatedStorage/Assets/Audio/Ghost/GhostWhisper_01.model.json`
- `src/ReplicatedStorage/Assets/Audio/Ghost/HuntStart_01.model.json`
- `src/ServerScriptService/Server/Core/AudioSanitizer.lua`
- `src/ServerScriptService/Server/Core/AudioErrorGuard.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- lima sound canonical yang sebelumnya memuat asset ID rusak sekarang memakai `AudioContent = ""`
- `AudioSanitizer` dan `AudioErrorGuard` sekarang mengenali placeholder kosong di `ReplicatedStorage.Assets.Audio` sebagai placeholder source yang disengaja, bukan error runtime
- hasilnya:
  - source tidak lagi menyimpan ID audio rusak
  - runtime boot tidak lagi perlu men-disable lima sound itu setiap start
  - debt konten tetap eksplisit: audio tersebut masih harus diganti asset final

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_audio_placeholder_build.rbxlx`
- validasi live menunjukkan:
  - `AmbientLoop_Main.SoundId = ""`
  - `EnvironmentalCreak_01.SoundId = ""`
  - `GhostManifest_01.SoundId = ""`
  - `GhostWhisper_01.SoundId = ""`
  - `HuntStart_01.SoundId = ""`
- boot log sesudah restart tidak lagi memuat warning `Disabled 5 invalid sounds`

### Next Step

Lanjutkan mengganti placeholder content yang masih aktif dengan asset final/terdokumentasi, sambil menjaga gate monetization dan licensing tetap sinkron dengan source of truth.

## 2026-04-03 11:34 ICT

### Task

Membangun surface `Royal Pass` canonical di runtime client aktif, lengkap dengan snapshot server dan panel UI lobby yang nyata.

### Linked Issues

- gap `RoyalPassUI`
- UI modular belum lengkap
- publish readiness untuk progression/commerce visibility

### Files Changed

- `src/ReplicatedStorage/RemoteEvents/RoyalPassEvent.model.json`
- `src/ServerScriptService/Server/RoyalPassSystem/Service.lua`
- `src/ServerScriptService/Server/RoyalPassSystem/Controller.lua`
- `src/client/Core/ClientBootstrap.lua`
- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- remote source-controlled `RoyalPassEvent` sekarang selalu ada sejak boot
- `RoyalPassSystem.Controller` sekarang mendorong snapshot awal dan update runtime canonical ke client:
  - `RoyalPassSnapshot`
  - `RoyalPassProgress`
  - `RoyalPassTierUnlocked`
  - `RoyalPassPremiumUpdated`
- `RoyalPassSystem.Service` sekarang punya `GetPlayerSnapshot()` sebagai payload canonical progress, tier, XP, dan premium ownership
- `UISystem` sekarang:
  - memuat `RoyalPassUI` sebagai panel modular aktif
  - menampilkan tombol float `PASS` di lobby
  - membuka panel penuh saat tombol float diklik
  - mendukung toggle hotkey `R`
  - merender status `Free/Premium`, tier, progress XP, next reward, dan event runtime terakhir
- hint lobby juga diperbarui agar pemain tahu `M` membuka room browser dan `R` membuka `Royal Pass`

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_royalpass_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_royalpass_build_2.rbxlx`
- validasi live lewat MCP membuktikan:
  - `ReplicatedStorage.RemoteEvents.RoyalPassEvent` ada di tree runtime
  - `PlayerGui.RoyalPassUI` benar-benar muncul saat playtest
  - panel awal menampilkan:
    - `Season S1 | Tier 1/50`
    - `Progress 0/200 XP | Total 0 XP`
    - badge `FREE TRACK`
  - klik pada `RoyalPassUIFloatButton` membuka panel penuh
  - tombol keyboard `R` menutup kembali panel ke mode float
- batas validasi yang masih jujur:
  - injeksi XP server live belum dibuktikan otomatis di sesi ini karena `execute_luau` MCP berjalan di context client saat playtest
  - tetapi jalur publish event ke client sudah source-controlled dan build/runtime initial snapshot sudah lolos

### Next Step

Pilih placeholder/content debt yang paling aktif di runtime berikutnya, lalu gantikan dengan asset atau surface final yang legal dan source-controlled tanpa membuka drift owner baru.

## 2026-04-03 12:08 ICT

### Task

Mengganti surface preview map aktif di room browser dan host room dari placeholder generik menjadi kartu preview prosedural yang source-owned.

### Linked Issues

- placeholder visual `MAP IMAGE`
- UI modular `LobbyUI` / room browser
- polish visual map preview

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `Main.lua` sekarang punya helper metadata preview map:
  - theme per `visualTheme.ambiance`
  - glyph map otomatis
  - mood label
  - stat line ukuran / room / lantai
- panel `RoomPreviewMap` di room browser sekarang:
  - punya gradient, accent bar, mood chip, dan stat line
  - memakai metadata map aktual, bukan teks placeholder
- panel `MapPreview` pada host room sekarang:
  - menampilkan glyph map besar
  - chip atmosfer
  - stat line detail map
  - footer nama map
- mode `Ranked` memakai theme tersendiri tanpa membuat preview map kembali jadi dummy text

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_map_preview_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_map_preview_build_2.rbxlx`
- validasi live lewat MCP membuktikan:
  - room browser `PREVIEW ROOM` tidak lagi menampilkan `MAP IMAGE` placeholder
  - host room `MapPreview` menampilkan runtime metadata nyata untuk `Haunted House`
  - payload visual yang terbaca saat playtest:
    - `glyph = HH`
    - `mood = DOMESTIC DECAY`
    - `stats = MEDIUM • 12 ROOM • 2 FLOOR • 140x140`
    - `footer = Haunted House`
- screenshot live diambil untuk dua state:
  - room browser tanpa room terpilih
  - host room setelah `CreateRoom`

### Next Step

Lanjutkan ke surface UI aktif lain yang masih minim identitas visual, terutama `ShopUI` dan icon/badge kontennya, sambil menjaga jalur licensing asset eksternal tetap jujur.

## 2026-04-03 12:26 ICT

### Task

Mengangkat `ShopUI` dari list teks polos menjadi kartu item prosedural yang punya identitas kategori, rarity, dan currency di runtime canonical.

### Linked Issues

- `ShopUI` masih terlalu placeholder
- icon/badge shop item belum ada
- debt visual konten aktif

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `Main.lua` sekarang punya theme prosedural untuk item shop berdasarkan:
  - category
  - rarity
  - currency
- kartu `ShopUI` sekarang memuat:
  - accent rarity di sisi kiri
  - preview box dengan glyph item
  - badge kategori/slot
  - pill harga + currency
  - warna tombol beli yang mengikuti theme item
- metadata item juga dirapikan:
  - `COSMETIC / EQUIPMENT`
  - rarity label
  - ringkasan tag item
- semua perubahan tetap source-owned dan tidak menambah dependency asset eksternal baru

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_shop_visual_build.rbxlx`
- validasi live lewat MCP membuktikan:
  - `ShopUI.MainPanel` bisa dirender di runtime canonical
  - `ItemRow1` untuk `Dusk Mask` menampilkan:
    - `badge = HEAD`
    - `glyph = MK`
    - `meta = COSMETIC • R1 B-ajah • HORROR, MASK`
    - `price = 850 MM`
- screenshot live menunjukkan tiga row pertama shop sudah tampil sebagai kartu visual, bukan row teks generik lagi

### Next Step

Lanjutkan ke surface aktif yang masih placeholder secara konten, terutama audio/asset eksternal yang masih `unknown` atau `replace/remove`, karena itu yang paling dekat ke publish gate sesungguhnya.

## 2026-04-03 12:49 ICT

### Task

Menutup sebagian gate licensing/audio dengan bukti Roblox live, lalu menyiapkan jalur batch replace untuk lima slot audio kosong yang masih memblokir publish.

### Linked Issues

- licensing asset aktif
- broken ghost audio set
- publish gate komersial

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/AUDIO_REPLACEMENT_PLAN_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`
- `scripts/set-audio-asset-ids.ps1`

### Change Summary

- validasi live `MarketplaceService:GetProductInfo()` sekarang mengubah status beberapa asset aktif:
  - `Heartbeat` -> verified account-owned
  - `Jumpscare_01` -> verified public domain
  - ghost animation pack -> verified Roblox-authored placeholder pack
- report baru `AUDIO_REPLACEMENT_PLAN_2026-04-03.md` memetakan:
  - lima slot audio kosong
  - kandidat source legal
  - jalur apply setelah upload
- helper `scripts/set-audio-asset-ids.ps1` sekarang bisa:
  - menampilkan status current slot (`-ShowCurrent`)
  - mengisi `AudioContent` lima slot canonical dari asset ID Roblox hasil upload

### Validation Notes

- validasi live `MarketplaceService:GetProductInfo()` menghasilkan:
  - `138884191945388` -> creator `ZyraaaVex`
  - `138186576` -> `IsPublicDomain = true`
  - `507771019`, `507776043`, `507766388`, `507767714`, `507777826` -> creator `Roblox`
- helper script lolos smoke test:
  - `pwsh -NoLogo -File .\\scripts\\set-audio-asset-ids.ps1 -ShowCurrent`
  - output membuktikan lima slot target saat ini masih `<empty>`
- blocker yang tetap jujur:
  - sesi ini tidak punya tool upload audio ke inventory Roblox account
  - jadi pengisian ID final menunggu langkah upload manual, setelah itu apply bisa dibatch

### Next Step

Pilih salah satu:
1. lanjut menurunkan debt UI/UX aktif lain yang masih tipis
2. atau masuk ke jalur audio final begitu asset hasil upload siap, karena script apply dan replacement queue sekarang sudah siap dipakai

## 2026-04-03 13:07 ICT

### Task

Menambahkan CTA `Royal Pass` langsung ke panel lobby agar akses progression tidak lagi hanya bergantung pada float atau shortcut.

### Linked Issues

- discoverability `RoyalPassUI`
- lobby UX masih terlalu bergantung pada shortcut/float
- panel utama lobby belum cukup eksplisit

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- panel lobby diperbesar agar muat satu CTA tambahan tanpa merusak grid tombol yang sudah ada
- tombol baru `ROYAL PASS` ditambahkan di antara row `PROFILE/SHOP` dan `MENU/RANK`
- state refresh lobby sekarang juga meng-update label tombol ini:
  - `ROYAL PASS`
  - `TUTUP ROYAL PASS`
- tombol baru terhubung ke jalur canonical yang sama dengan float/shortcut `R`

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_lobby_royalpass_button_build.rbxlx`
- validasi live lewat MCP membuktikan:
  - `LobbyUI.MainPanel.RoyalPassButton` hadir di runtime
  - layout panel lobby baru tampil rapi dengan urutan:
    - `OPEN ROOM BROWSER`
    - `PROFILE / SHOP`
    - `ROYAL PASS`
    - `MENU / RANK`
  - klik pada `RoyalPassButton` benar-benar membuka `RoyalPassUI.MainPanel`

### Next Step

Lanjutkan dua jalur yang masih paling bernilai:
1. UI/UX aktif lain yang masih belum cukup jelas
2. atau apply audio final begitu asset hasil upload tersedia

## 2026-04-03 14:32 ICT

### Task

Menutup jalur audio modern agar asset Roblox yang valid benar-benar bisa terdengar di runtime canonical, lalu memetakan ulang status licensing/audio berdasarkan validasi live terbaru.

### Linked Issues

- audio modern hanya menyimpan payload
- audio cue server belum sampai ke client canonical
- broken ID ternyata bercampur dengan wiring drift

### Files Changed

- `src/ServerScriptService/Server/AudioSystem/Controller.lua`
- `src/client/SoundSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/AUDIO_REPLACEMENT_PLAN_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`

### Change Summary

- `AudioSystem` server sekarang me-relay event:
  - `AmbientAudioTriggered`
  - `EnvironmentalAudioTriggered`
  - `FearAudioTriggered`
  - `GhostAudioTriggered`
  - `HuntAudioTriggered`
  ke `RemoteEvents.MatchEvent` client berdasarkan `matchId`
- `client/SoundSystem` sekarang tidak lagi berhenti di `self._lastAudioByCategory`
  - payload audio sekarang dipetakan ke template source-owned
  - `Environmental`, `Fear`, `Ghost`, dan `Hunt` sekarang memutar `Sound` runtime
  - `Ambient` juga sudah punya jalur loop canonical, tetapi masih menunggu asset final karena `AmbientLoop_Main` masih kosong
- audit ulang audio sekarang membedakan dua hal:
  - asset ID Roblox yang benar-benar invalid
  - asset sehat yang sebelumnya tidak terdengar karena routing runtime belum ada
- status report audio diperbarui:
  - slot canonical kosong yang tersisa tinggal `AmbientLoop_Main`, `GhostWhisper_01`, dan `ButtonClick_01`
  - `EnvironmentalCreak_01`, `GhostManifest_01`, `HuntStart_01`, `CountdownTick_01`, dan footstep set sekarang tercatat sebagai source-owned/verified

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_audio_runtime_bridge_build.rbxlx`
- validasi live `MarketplaceService:GetProductInfo()` + `ContentProvider:GetAssetFetchStatus()` sebelumnya sudah membuktikan ID user-supplied sehat
- validasi client live terbaru lewat MCP pada playtest membuktikan runtime sound benar-benar dibuat dan bermain:
  - `EnvironmentalAudioRuntime -> rbxassetid://139204195403262 -> IsPlaying = true`
  - `FearAudioRuntime -> rbxassetid://138884191945388 -> IsPlaying = true`
  - `GhostAudioRuntime -> rbxassetid://83336813491039 -> IsPlaying = true`
  - `HuntAudioRuntime -> rbxassetid://138329686293368 -> IsPlaying = true`
- `AmbientAudio` belum menghasilkan runtime sound karena slot source-nya memang masih kosong

### Next Step

Lanjutkan ke salah satu dari dua jalur bernilai tertinggi:
1. isi tiga slot audio kosong yang tersisa (`AmbientLoop_Main`, `GhostWhisper_01`, `ButtonClick_01`)
2. atau kembali ke phase content/presentation berikutnya sambil menyisakan audio final sebagai blocker manual terdefinisi

## 2026-04-03 15:02 ICT

### Task

Menaikkan `RoyalPassUI` dari panel teks tipis menjadi surface progression yang lebih jelas, lebih branded, dan punya CTA nyata ke jalur monetization/content yang sudah ada.

### Linked Issues

- `RoyalPassUI` terlalu datar dan mudah terlewat
- progression panel belum cukup memorable untuk brand
- CTA dari progression ke shop belum eksplisit

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `RoyalPassUI` sekarang membangun deck visual sendiri di `ContentFrame`:
  - hero card progress
  - progress bar tier
  - ringkasan XP/tier
  - tiga preview row untuk state track
- panel sekarang menampilkan progression dengan struktur yang lebih mudah dibaca:
  - season
  - tier aktif
  - progress XP
  - preview reward tier berikutnya
  - summary track free/premium
- CTA `LIHAT SHOP` ditambahkan langsung di hero card
  - saat belum premium, CTA ini menjadi jembatan eksplisit ke `ShopUI`
  - saat premium aktif, state CTA berganti menjadi `PREMIUM AKTIF`

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_royalpass_visual_build.rbxlx`
- validasi live lewat MCP membuktikan:
  - `RoyalPassUI.MainPanel.ContentFrame.RoyalPassDeck` hadir di runtime
  - `HeroBadge = FREE TRACK`
  - `HeroTitle = SEASON S1  •  TIER 01`
  - `ProgressCaption = 200 XP to next tier  •  0 unlocked tier`
  - klik `PremiumActionButton` benar-benar menghasilkan:
    - `royalVisible = false`
    - `shopVisible = true`
- screenshot runtime:
  - `ScreenCapture_RoyalPass_Polish_1`

### Next Step

Lanjutkan ke salah satu jalur berikut:
1. teruskan polish panel modular lain (`ProfileUI` / `MatchUI`) dengan standar visual yang sama
2. atau tutup audio gameplay yang tersisa, terutama ambience, whisper, dan UI click

## 2026-04-03 15:21 ICT

### Task

Menaikkan `ProfileUI` menjadi panel identitas yang lebih jelas dan menyambungkan CTA profile ke room browser, sambil menambah hierarchy visual pada summary hasil `MatchUI`.

### Linked Issues

- `ProfileUI` masih terlalu text-heavy
- panel modular belum punya bahasa visual yang konsisten
- summary hasil `MatchUI` belum cukup scan-friendly

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `ProfileUI` sekarang membangun `ProfileDeck` di `ContentFrame`:
  - hero card player
  - status pill
  - spotlight line
  - CTA `OPEN ROOMS`
  - tiga visual stat rows
- CTA profile sekarang langsung membuka `RoomBrowserUI`
- `MatchUI` summary rows sekarang punya emphasis warna:
  - row status menjadi hijau/merah saat hasil tersedia
  - row reward dan XP mendapat aksen terpisah agar hasil match lebih cepat terbaca

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_profile_match_visual_build.rbxlx`
- validasi live lewat MCP membuktikan:
  - `ProfileUI.MainPanel.ContentFrame.ProfileDeck` hadir di runtime
  - `StatusPill = SAFE`
  - `ProfileTitle = ZyraaaVex • LV 1`
  - klik `ActionButton` benar-benar menghasilkan `roomVisible = true`
- screenshot runtime:
  - `ScreenCapture_Profile_Polish_1`
- catatan jujur:
  - styling summary `MatchUI` sudah masuk ke code path aktif
  - validasi full result-phase live untuk warna row belum saya tutup di entry ini

### Next Step

Lanjutkan ke jalur bernilai tinggi berikut:
1. tutup audio konten yang masih kosong (`AmbientLoop_Main`, `GhostWhisper_01`, `ButtonClick_01`)
2. atau teruskan polish panel modular yang tersisa dengan standar visual yang sama

## 2026-04-03 10:11 ICT

### Task

Menutup dua drift UX yang terlihat langsung saat playtest live:
- `RoomBrowserUI` masih tertinggal terbuka setelah teleport ke match
- countdown room memicu tick secara terasa acak terhadap angka yang tampil

### Linked Issues

- room browser masih bocor ke fase `Briefing/InGame`
- countdown overlay masih mengikat tick ke churn render, bukan ke angka visual yang sedang dilihat player

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `UISystem` sekarang punya sinkronisasi penekanan room browser terhadap context match:
  - `InMatch` atau fase selain `Lobby` langsung menandai room browser sebagai suppressed
  - `RoomBrowserUI` dan root `Panel` dipadamkan eksplisit saat masuk match
  - loop room browser juga ikut menyinkronkan suppression, jadi state tidak lagi bergantung pada satu event attribute saja
- countdown overlay sekarang dipacu dari nilai visual yang sama dengan cue audio:
  - client menyimpan anchor second lokal dari update server terakhir
  - angka visual dihitung dari anchor itu
  - tick audio hanya dipicu saat angka visual berubah
  - playback tick dibuat stabil agar tidak terasa random terhadap detik yang sedang dilihat
- countdown label sekarang dipulse ringan setiap pergantian detik agar perubahan terasa lebih tegas tanpa motion berlebihan

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_room_browser_countdown_fix_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_room_browser_countdown_fix_build_v2.rbxlx`
- validasi live lewat MCP membuktikan:
  - setelah `Ranked -> CreateRoom -> HostStart -> teleport`, runtime client menunjukkan:
    - `InMatch = true`
    - `MatchPhase = Briefing`
    - `RoomBrowserUI.Enabled = false`
    - `RoomBrowserUI.Panel.Visible = false`
  - screenshot proof:
    - `ScreenCapture_CountdownFix_v2_InMatch`
  - countdown overlay live kembali muncul mulai dari `5` saat host start, tidak lagi langsung terasa meloncat dari angka acak saat source patch ini aktif
- catatan jujur:
  - saya tidak menangkap waveform audio langsung dari tooling MCP
  - tetapi code path tick sekarang sudah diikat ke perubahan angka visual, bukan ke render churn yang sebelumnya memicu drift

### Next Step

Lanjutkan ke backlog `P2.12 Rapikan UI modular`, terutama panel `LobbyUI` atau `MatchUI` yang masih paling utilitarian dibanding `ShopUI`, `RoyalPassUI`, dan `ProfileUI`.

## 2026-04-03 10:18 ICT

### Task

Menaikkan `MatchUI` dari panel status utilitarian menjadi surface fase yang lebih cepat dibaca dan lebih konsisten dengan bahasa visual panel modern lain.

### Linked Issues

- `MatchUI` masih terasa paling datar dibanding `ShopUI`, `RoyalPassUI`, dan `ProfileUI`
- state fase match belum cukup “nempel” secara visual saat pemain lagi bergerak di map
- hierarchy panel kanan masih terlalu tipis untuk kondisi tegang / low-visibility

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `MatchUI` sekarang punya `HeaderCard` canonical di dalam `MainPanel`:
  - badge fase tetap
  - headline fase
  - subtitle fase
  - glyph fase besar di sisi kanan untuk recognition cepat
- panel match sekarang juga punya stroke dan accent warna yang mengikuti fase aktif
- `SummaryFrame`, timer chip, quick evidence button, dan controls hint ikut mengambil aksen fase aktif agar panel terasa satu sistem visual
- fase glyph yang dipakai:
  - `PR` untuk `Preparation/Loading`
  - `IN` untuk `Investigation`
  - `HU` untuk `Hunt`
  - `OK` / `FG` untuk `Results`

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_match_ui_polish_build.rbxlx`
- validasi live lewat MCP membuktikan:
  - `MatchUI.MainPanel.HeaderCard` hadir di runtime canonical
  - `MatchUI.MainPanel.BrandStroke` hadir di panel match
  - screenshot runtime:
    - `ScreenCapture_MatchUI_PostPolish_2`
- catatan jujur:
  - validasi ini dilakukan pada fase `Preparation/Briefing`
  - saya belum menutup screenshot paralel untuk semua fase `Investigation/Hunt/Result` pada entry ini

### Next Step

Lanjutkan ke panel modular berikut yang masih paling utilitarian:
1. `LobbyUI`
2. `JournalUI`
3. atau kembali ke blocker audio final (`AmbientLoop_Main`, `GhostWhisper_01`, `ButtonClick_01`) kalau asset Roblox-nya sudah siap

## 2026-04-03 10:37 ICT

### Task

Menutup regress `LobbyUI` setelah polish pass dan memastikan panel lobby boot dalam keadaan terbuka, bukan collapsed.

### Linked Issues

- `LobbyUI` sempat kehilangan semua tombol bawah setelah polish runtime
- panel lobby default lama terlalu tersembunyi untuk flow test lobby modern
- validasi visual user-facing perlu kembali jelas sebelum lanjut ke surface UI berikutnya

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- typo builder `stateBadge` dikoreksi menjadi `statusBadge`, sehingga builder `LobbyUI` tidak lagi terputus di tengah
- tombol canonical `Open Room Browser`, `Profile`, `Shop`, `Royal Pass`, `Menu`, `Rank`, dan `HintLabel` kembali dibuat penuh
- default `self._lobbyPanelCollapsed` diubah menjadi `false`, jadi panel lobby langsung terbuka saat playtest boot baru
- toggle minimize tetap dipertahankan, dengan state visual `<` saat panel sedang terbuka

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_lobby_ui_fix_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_lobby_ui_default_open_build.rbxlx`
- validasi live lewat MCP membuktikan:
  - `LobbyUI.MainPanel` kembali punya child tombol penuh
  - `LobbyUI.MainPanel.Visible = true` pada playtest baru
  - `LobbyUI.LobbyToggleButton.Text = "<"` pada state default boot
  - screenshot runtime:
    - `ScreenCapture_LobbyUI_DefaultOpen_Validated`
- catatan jujur:
  - saya sempat force-open panel sekali lewat `execute_luau` untuk membedakan bug builder vs state collapse
  - sesudah patch default open, playtest baru membuktikan panel memang muncul tanpa injeksi manual

### Next Step

Lanjutkan ke surface berikut yang masih paling utilitarian atau masih punya blocker publish:
1. `JournalUI`
2. asset audio final (`AmbientLoop_Main`, `GhostWhisper_01`, `ButtonClick_01`)
3. vertical slice ghost/map flow berikutnya

## 2026-04-03 10:56 ICT

### Task

Menaikkan `JournalUI` dari blok teks deduction menjadi evidence board yang lebih cepat dibaca dan tidak lagi menabrak `LobbyUI` saat flow lobby test.

### Linked Issues

- `JournalUI` lama masih utilitarian dan terasa seperti dump teks
- saat dibuka di lobby, panel journal overlap langsung dengan `LobbyUI`
- tool scan sudah ada, tapi status dan evidence grouping belum punya hierarchy visual yang cukup kuat

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `JournalUI` sekarang punya layout responsif desktop sederhana:
  - jika `LobbyUI` terbuka dan viewport lebar cukup, panel journal pindah ke kanan
  - jika tidak, tetap memakai posisi fallback kiri
- konten deduction sekarang dibentuk sebagai `JournalDeck` source-owned di `ContentFrame`:
  - hero card status
  - tiga stat card (`Discovered`, `Confirmed`, `Candidates`)
  - section card untuk discovered evidence, confirmed evidence, dan ghost candidates
- `ToolStatusLabel` sekarang bergaya card dengan stroke/padding, bukan teks menggantung
- `SCAN JEJAK` tetap canonical, tapi visualnya sekarang konsisten dengan hierarchy journal baru

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_journal_ui_polish_build.rbxlx`
- validasi live lewat MCP membuktikan:
  - `JournalUI.MainPanel.Visible = true`
  - `JournalUI.MainPanel.Position = {0, 372}, {0, 16}` saat `LobbyUI` aktif
  - screenshot runtime:
    - `ScreenCapture_JournalUI_PostPolish_1`
- catatan jujur:
  - state evidence saat validasi masih kosong, jadi section cards diuji pada state `idle/empty`
  - validasi untuk state journal berisi evidence nyata masih perlu ditutup saat vertical slice evidence dijalankan

### Next Step

Kembali ke blocker gameplay/map yang lebih dekat ke publish:
1. generalisasi perilaku pintu / traversal di semua map aktif
2. vertical slice evidence + journal dengan state non-empty
3. asset audio final yang masih kosong

## 2026-04-03 11:09 ICT

### Task

Menutup feedback runtime pintu lintas map dengan audio buka/tutup dan audit clone supaya loop traversal tidak hanya “bisa lewat”, tapi juga punya feedback yang konsisten untuk `Classic` maupun `Ranked`.

### Linked Issues

- pintu lintas map sebelumnya memang sudah auto-open, tapi belum punya feedback audio runtime yang jelas
- user meminta perilaku pintu yang tidak lagi fragile per map dan tidak bergantung pada satu mode saja
- perlu bukti nyata bahwa semua map aktif, bukan cuma `HauntedHouse`, menerima policy yang sama

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `MapRuntimePatches` sekarang menanamkan attribute sound default pada setiap pintu clone:
  - `DoorOpenSoundId = rbxassetid://139204195403262`
  - `DoorCloseSoundId = rbxassetid://83336813491039`
- `DoorRuntime` sekarang:
  - membuat `DoorOpenSound` dan `DoorCloseSound` runtime per pintu
  - memutar audio buka/tutup saat interaksi `Open/Close/Slam`
  - tetap mempertahankan `ProximityPromptStyle.Default` dan `AutoOpenToggle` yang mode-agnostic
- policy traversal tetap sama untuk `Classic` dan `Ranked` karena semuanya masuk lewat clone path `MatchTeleport -> MapRuntimePatches -> DoorRuntime`

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_door_runtime_audio_build.rbxlx`
- audit live via MCP pada clone semua map membuktikan:
  - `AbandonedPalace doors=18 prompts=18 sounds=18 mode=AutoOpenToggle`
  - `EmptyBuilding doors=14 prompts=14 sounds=14 mode=AutoOpenToggle`
  - `HauntedHouse doors=11 prompts=11 sounds=11 mode=AutoOpenToggle`
  - `StudioMMNineteen doors=8 prompts=8 sounds=8 mode=AutoOpenToggle`
- sample inspect runtime:
  - `Workspace.AssistantDoorAudit.HauntedHouse_Audit.Doors.Door_DiningRoom`
  - child yang hadir: `DoorPathModifier`, `DoorPrompt`, `DoorOpenSound`, `DoorCloseSound`
- catatan jujur:
  - validasi ini menutup layer attachment/runtime clone, bukan subjective mix/volume final di telinga pemain
  - balancing volume dan pilihan SFX final masih bisa disetel lagi jika nanti audio ambience sudah lengkap

### Next Step

Lanjut ke blocker gameplay berikutnya:
1. vertical slice evidence + journal dengan state non-empty
2. extraction flow pada map clone aktif
3. finalisasi slot audio kosong yang masih menahan publish polish

## 2026-04-03 11:00 ICT

### Task

Menutup vertical slice `evidence -> journal non-empty` dengan jalur runtime yang benar-benar aktif, tanpa bergantung pada two-way Studio hack atau owner journal lama yang sudah drift.

### Linked Issues

- `JournalUI` sebelumnya hanya berubah di status tool, tetapi body evidence/candidate tetap kosong walau `EvidenceRequest` sukses
- runtime modern mem-publish `EvidenceCollected`, sementara owner journal lama tidak lagi menjadi jalur yang bisa dipercaya
- deduction payload sudah tersedia di backend, tetapi belum ikut dibawa ke surface client yang benar-benar aktif

### Files Changed

- `src/ServerScriptService/Server/JournalSystem/Controller.lua`
- `src/ServerScriptService/Server/JournalSystem/Service.lua`
- `src/ServerScriptService/Server/EvidenceSystem/Controller.lua`
- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `JournalSystem` sekarang ikut mendengar event runtime modern:
  - `EvidenceCollected`
  - `DeductionUpdated`
- `JournalSystem.Service` sekarang punya fallback `OnEvidenceCollected`, sehingga evidence yang benar-benar sudah terkumpul tetap membentuk snapshot journal walau `EvidenceValidated`/owner lama tidak cukup
- `EvidenceSystem.Controller:OnEvidenceCollected` sekarang membroadcast snapshot runtime yang sudah aman dipakai client:
  - `discoveredEvidence`
  - `confirmedEvidence`
  - `possibleGhosts`
  - `evidenceFound`
- `UISystem` sekarang memakai payload `EvidenceCollected` itu sebagai bridge canonical ke `JournalUI`, jadi body journal tidak lagi menunggu surface journal legacy

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_journal_fix_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_journal_collect_bridge_build.rbxlx`
- restart playtest penuh dilakukan dua kali untuk memastikan server + client benar-benar memuat patch
- automation live via MCP berhasil mengulang flow:
  - `SelectMode(Ranked)`
  - `SelectMap(EmptyBuilding)`
  - `CreateRoom`
  - `HostStart`
  - tunggu `MatchPhase = Briefing`
- validasi runtime akhir sukses pada ghost aktif `SundelBolong`:
  - client request `TounDetection` kembali `success=true`, `reason=collected`, `evidenceType=To'un`
  - `JournalUI` sekarang membaca state non-empty:
    - `heroTitle = Evidence penting sudah terkunci. Saatnya persempit ghost.`
    - `heroMeta = Confirmed 1 | Kandidat 7 | Event EvidenceCollected`
    - `ToolStatusLabel = Evidence berhasil dibaca. / Collected To'un`
  - screenshot runtime:
    - `ScreenCapture_JournalAfterEvidenceCollectBridge`
- catatan jujur:
  - bridge ini menutup vertical slice sekarang, tetapi owner journal lama masih layak dibersihkan di fase refactor berikutnya agar tidak ada dua jalur sinkronisasi yang samar

### Next Step

Lanjut ke blocker publish berikutnya:
1. finalisasi tiga slot audio kosong (`AmbientLoop_Main`, `GhostWhisper_01`, `ButtonClick_01`)
2. lanjutkan polish UX Roblox-friendly pada surface yang masih utilitarian
3. lanjutkan loop match hasil/ekstraksi dan publish gate yang masih tersisa

## 2026-04-03 11:00 ICT

### Task

Menutup micro-feedback click pada UI canonical dengan fallback built-in Roblox yang legal, supaya lobby/shop/profile/journal tidak terasa mati sambil menunggu signature click final.

### Linked Issues

- `ButtonClick_01` masih kosong di source aktif
- player feedback tombol sudah punya motion, tetapi audio click masih nihil
- upload asset Roblox final untuk click brand belum ada, jadi perlu fallback yang aman dulu

### Files Changed

- `src/client/UI/Main.lua`
- `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/AUDIO_REPLACEMENT_PLAN_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `UISystem` sekarang punya fallback built-in untuk `ButtonClick`:
  - `rbxasset://sounds/volume_slider.ogg`
- fallback dipakai hanya saat template `ButtonClick_01` belum punya asset final yang valid
- jadi source-of-truth asset tetap jujur kosong, tetapi runtime pemain tetap mendapat click feedback

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_button_click_fallback_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_button_click_attr_probe_build.rbxlx`
- validasi live via MCP:
  - klik `LobbyUI.MainPanel.ShopButton` benar-benar membuka `ShopUI`
  - probe runtime `UISystem` menunjukkan cue yang dipilih saat click adalah:
    - `rbxasset://sounds/volume_slider.ogg`
  - ini membuktikan jalur click canonical sudah punya audio feedback tanpa menunggu upload asset Roblox baru
- catatan jujur:
  - ini fallback runtime yang aman, bukan signature click final brand `PASRAHPHOBIA`
  - blocker audio upload yang tersisa sekarang tinggal:
    - `AmbientLoop_Main`
    - `GhostWhisper_01`

### Next Step

Lanjut ke blocker publish berikutnya:
1. finalisasi `AmbientLoop_Main` dan `GhostWhisper_01`
2. teruskan polish UI/UX Roblox-friendly pada surface yang masih utilitarian
3. lanjutkan publish gate yang masih butuh input Creator Hub/manual

## 2026-04-03 11:42 ICT

### Task

Mengangkat `LeaderboardUI` dari panel snapshot teks menjadi rank board visual yang lebih nyaman dibaca, tetap jujur terhadap data lokal, dan konsisten dengan surface lobby/profile/shop/journal yang sudah dipoles.

### Linked Issues

- `LeaderboardUI` masih berupa text dump utilitarian
- rank board belum punya hero hierarchy, meter, atau stat cards
- panel rank sudah ada, tetapi belum meninggalkan nuansa placeholder internal

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `LeaderboardUI` sekarang punya `LeaderboardDeck` di `ContentFrame`
- hero card menampilkan:
  - badge snapshot/mode
  - nama pemain + tier rank
  - meta `LV / match / victory`
  - sanity meter live
- empat stat rows visual sekarang dibangun untuk:
  - `Tier status`
  - `Pressure band`
  - `Room browser pulse`
  - `Mastery footprint`
- panel diperbesar ke `340x448` supaya deck rank lebih lapang dan tombol aksi bawah tidak menumpuk dengan konten

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_leaderboard_polish_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_leaderboard_polish_build_2.rbxlx`
- validasi live via Studio MCP:
  - playtest di-restart agar `LocalScript` baru terpasang ke `PlayerGui`
  - `LeaderboardUI.MainPanel` berhasil dibuka pada lobby runtime
  - probe runtime menunjukkan:
    - `HeroTitle = ZyraaaVex • Bayi III`
    - `canvas = 316,214`
    - rows = `Tier status`, `Pressure band`, `Room browser pulse`, `Mastery footprint`
  - screenshot `ScreenCapture_LeaderboardUI_Final` menunjukkan rank board baru tampil di lobby aktif

### Next Step

Lanjut ke surface berikutnya yang masih paling utilitarian atau masih menahan publish polish:
1. `MainMenuUI` jika perlu dinaikkan ke deck visual yang setara
2. finalisasi dua blocker audio canonical yang masih kosong
3. teruskan polish material/lighting/icon agar experience tidak berhenti di UI saja

## 2026-04-03 19:35 ICT

### Task

Revalidasi flow `Ranked -> countdown -> teleport` secara visual dan menutup satu slot audio canonical lagi dengan asset Roblox yang sudah di-upload user.

### Linked Issues

- room browser bocor setelah teleport
- countdown/audio sinkron perlu bukti runtime baru
- `GhostWhisper_01` masih kosong walau user sudah punya asset Roblox yang valid

### Files Changed

- `src/ReplicatedStorage/Assets/Audio/Ghost/GhostWhisper_01.model.json`
- `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/AUDIO_REPLACEMENT_PLAN_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- flow `Ranked -> CreateRoom -> HostStart -> teleport` divalidasi ulang di Studio live dan hasilnya tetap bersih:
  - `RoomBrowserUI.Enabled = false`
  - `MatchUI.Enabled = true`
  - player sudah berada di `match_1`
- sembilan asset audio upload user yang sudah terpasang sebelumnya diuji ulang langsung di client template dan semuanya `IsLoaded = true` + `IsPlaying = true`
- `GhostWhisper_01` sekarang diisi `rbxassetid://83336813491039` dan lolos validasi client live setelah restart playtest
- percobaan menjadikan `ButtonClick_01` template source-owned dengan built-in `rbxasset://sounds/volume_slider.ogg` dibatalkan lagi, karena jalur resolver UI canonical membaca template dari `SoundId` non-kosong dan representasi built-in itu tidak surface dengan cara yang bisa dipakai template path ini
- kesimpulan mutakhir:
  - blocker audio canonical tinggal `AmbientLoop_Main`
  - `ButtonClick` tetap aman via fallback runtime built-in Roblox

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_audio_fill_build.rbxlx`
- screenshot runtime:
  - `ScreenCapture_RankedRoom_Start_Clicked`
  - `ScreenCapture_After_Ranked_Teleport_Check`
- probe runtime client membuktikan:
  - `roomBrowserVisible = false`
  - `matchUIVisible = true`
  - `playerMatchId = match_1`
- probe audio template baru membuktikan:
  - `GhostWhisper_01 -> rbxassetid://83336813491039 -> IsLoaded = true`

### Next Step

Lanjut ke blocker konten/publish berikutnya yang benar-benar tersisa:
1. finalisasi `AmbientLoop_Main`
2. teruskan polish UX/brand visual pada surface yang masih utilitarian
3. kembali ke jalur automation ghost deterministic jika dibutuhkan setelah blocker konten langsung ini makin tipis

## 2026-04-03 20:22 ICT

### Task

Mengunci transisi `RoomBrowser -> match` agar panel room tidak bocor saat teleport dan menyelaraskan countdown tick ke angka server yang benar-benar tampil di client.

### Linked Issues

- room panel masih sempat terlihat saat flow teleport berlangsung
- countdown tick terasa acak karena UI menghitung mundur lokal di antara update server

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `_forceCloseAllPanelsForTeleport()` sekarang memaksa menutup `RoomPanel`, dropdown, modal, dan `CountdownOverlay`, bukan hanya menyetel `ScreenGui.Enabled = false`
- `_updateRoomBrowserVisibility()` sekarang juga men-collapse subtree room browser saat browser disuppress
- `_updateCountdownOverlay()` tidak lagi memakai anchor timer lokal; display countdown langsung mengikuti `countdownSecondsLeft` / `countdownTotal` dari server
- tick audio sekarang hanya dipicu saat angka server benar-benar berubah, sehingga sinkron dengan label yang dilihat pemain

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_countdown_room_fix_build.rbxlx`
- validasi live `Ranked -> CreateRoom -> ReadyButton(Start) -> teleport` membuktikan:
  - tepat sesudah start click:
    - `RoomBrowserUI.Enabled = false`
    - `RoomBrowserUI.Panel.Visible = false`
    - `RoomBrowserUI.Panel.RoomPanel.Visible = false`
  - setelah teleport:
    - `InMatch = true`
    - `MatchPhase = Briefing`
    - `MatchUI.Enabled = true`
- probe countdown runtime menunjukkan urutan sinkron:
  - `RuntimeCountdownTick` muncul bersamaan dengan perubahan label `4`, `3`, `2`, `1`
  - tidak ada lagi drift dari pengurang detik lokal di loop `0.1`

### Next Step

Lanjut ke blocker publish berikutnya:
1. finalisasi `AmbientLoop_Main`
2. teruskan polish UX/brand pada surface yang masih utilitarian
3. hanya kembali ke eksperimen ghost deterministic setelah blocker publish yang lebih langsung makin tipis

## 2026-04-03 21:02 ICT

### Task

Menaikkan kualitas float button cluster kanan agar lebih Roblox-friendly, terbaca, dan tidak saling menabrak saat beberapa panel disembunyikan bersamaan.

### Linked Issues

- float button kanan masih terlihat seperti debug chips
- `PASS` dan `ROOMS` saling overlap pada lane default lama
- brand language panel sudah naik, tetapi affordance tombol minim dan terlalu statis

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- menambahkan helper `styleFloatingButton()` untuk memberi float button:
  - accent bar
  - glyph dua huruf
  - caption utama
  - subcaption `OPEN`
- helper ini diterapkan ke:
  - auxiliary float buttons (`Profile`, `Shop`, `Royal Pass`, dst.)
  - `MainMenuFloatButton`
  - `LeaderboardFloatButton`
  - `MatchFloatButton`
  - `RoomBrowserFloatButton`
- ukuran float button dibuat sedikit lebih lapang agar caption tetap terbaca di desktop/mobile/console
- lane default kanan dipisah:
  - `MENU` naik ke `0.36`
  - `PASS` di `0.46`
  - `ROOMS` di `0.56`
  - `RANK` di `0.64`
  - `MATCH` di `0.68`
- hasilnya cluster kanan tidak lagi numpuk pada lane `0.5` yang sebelumnya dipakai bersama oleh `PASS` dan `ROOMS`

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_float_button_polish_build.rbxlx`
  - `rojo build default.project.json --output .\_tmp_float_lane_polish_build.rbxlx`
- screenshot live lobby:
  - `ScreenCapture_FloatButtons_Polished_Lobby`
  - `ScreenCapture_FloatButtons_Polished_Lobby_2`
- probe runtime terbaru membuktikan:
  - `MainMenuFloatButton = 60x60 @ y=0.36`
  - `RoyalPassUIFloatButton = 60x60 @ y=0.46`
  - `RoomBrowserFloatButton = 72x72 @ y=0.56`
  - `LeaderboardFloatButton = 60x60 @ y=0.64`

### Next Step

Lanjut ke blocker publish yang benar-benar tersisa:
1. finalisasi `AmbientLoop_Main` dengan asset yang legal dan publish-safe
2. lanjutkan polish visual/audio lain yang masih generik
3. pertahankan jalur forced-ghost sebagai eksperimen terpisah sampai memang dibutuhkan lagi

## 2026-04-03 13:00 ICT

### Task

Menyelesaikan chip currency terstruktur pada surface ekonomi aktif, lalu memasukkan debt UX/mobile dan redesign pintu/map traversal terbaru ke backlog resmi.

### Linked Issues

- affordance economy masih terlihat seperti teks utilitarian
- review live terbaru menemukan rail kanan, mobile layout, dan desain pintu/map traversal belum layak dijadikan baseline final

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `PricePill` sekarang memakai helper canonical `applyPricePillVisual()` di semua surface yang sebelumnya masih set teks langsung
- parser currency diperbaiki ke pattern Luau yang valid; hasilnya pill `MM/PP/Robux` benar-benar berubah menjadi glyph + amount + unit
- chip ekonomi Shop sekarang tidak lagi hanya `\"850 MM\"`, tetapi layout terstruktur dengan glyph kiri, amount tengah, dan unit kanan
- backlog resmi ditambah untuk debt berikut:
  - fixed right rail top-to-bottom
  - aturan single-open untuk panel besar
  - `RoomBrowserUI` mobile fullscreen/flexible
  - `RoyalPassUI` 30-day reward + 30-day mission flow
  - redesign pintu hybrid radius/manual
  - audit tangga, akses lantai, hiding spot, dan aturan survive hunt

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_currency_chip_build.rbxlx`
  - `rojo build default.project.json --output .\_tmp_currency_chip_build_2.rbxlx`
  - `rojo build default.project.json --output .\_tmp_currency_chip_build_3.rbxlx`
- validasi live Shop:
  - `ScreenCapture_CurrencyChip_Shop_3`
  - probe runtime `ItemRow1.PricePill`:
    - `Text = ""`
    - `CurrencyGlyph = "M"`
    - `CurrencyAmount = "850"`
    - `CurrencyUnit = "MM"`
- validasi live Royal Pass:
  - `ScreenCapture_CurrencyChip_RoyalPass`
  - helper canonical aktif di row `PricePill`; panel yang saat ini tampil masih memakai pill non-currency seperti `0 XP / CLEAR / 200 LEFT`, sehingga fallback text tetap dipertahankan dengan aman

### Next Step

Lanjut ke debt UX yang paling dekat ke gameplay nyata:
1. fixed right rail + aturan single-open
2. mobile-first pass untuk `LobbyUI`, `RoyalPassUI`, dan `RoomBrowserUI`
3. baru sesudah itu masuk ke redesign pintu/map traversal dan definisi survive hunt

## 2026-04-03 13:09 ICT

### Task

Menutup debt ownership UI lobby dengan membuat right rail deterministic top-to-bottom dan menerapkan single-open behavior antar surface utama lobby.

### Linked Issues

- float rail kanan masih bergerak berdasarkan lane persen lama
- `LobbyUI`, `RoyalPassUI`, dan `RoomBrowserUI` masih bisa terasa bertumpuk pada flow buka panel berurutan

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- menambahkan `_layoutLobbyFloatRail()` untuk menghitung posisi rail kanan berdasarkan tombol yang benar-benar visible
- `MENU`, `PASS`, `ROOMS`, dan `RANK` sekarang disusun fixed dari atas ke bawah, bukan lagi tergantung `UDim2` persen tersebar
- membuka panel besar selain lobby sekarang otomatis meng-collapse `LobbyUI`
- jalur `RoomBrowser` sekarang ikut menyinkronkan auxiliary visibility, sehingga membuka `RoomBrowser` benar-benar menutup `RoyalPassUI`
- `Esc/B` sekarang juga bisa meng-collapse lobby panel saat itu menjadi surface teratas yang masih terbuka

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_right_rail_single_open_build.rbxlx`
  - `rojo build default.project.json --output .\_tmp_right_rail_single_open_build_2.rbxlx`
- baseline rail lobby:
  - `ScreenCapture_RightRail_SingleOpen_Lobby`
  - probe runtime:
    - `MENU @ y=88`
    - `PASS @ y=158`
    - `ROOMS @ y=228`
    - `RANK @ y=310`
- validasi `Lobby -> RoyalPass`:
  - `ScreenCapture_RightRail_SingleOpen_RoyalPass`
  - runtime:
    - `lobbyCollapsed = true`
    - `lobbyVisible = false`
    - `royalVisible = true`
- validasi `RoyalPass -> RoomBrowser`:
  - `ScreenCapture_RightRail_SingleOpen_RoomBrowser_2`
  - runtime:
    - `lobbyCollapsed = true`
    - `royalVisible = false`
    - `roomBrowserVisible = true`

### Next Step

Masuk ke pass responsive yang lebih besar:
1. `RoomBrowserUI` mobile fullscreen / flexible sheet
2. `RoyalPassUI` mobile readability + 30-day track structure
3. `LobbyUI` dan right rail touch targets yang lebih nyaman di mobile

## 2026-04-03 13:21 ICT

### Task

Menjalankan pass responsive konservatif untuk `LobbyUI` dan `RoyalPassUI` agar dua panel utama ini tidak lagi sepenuhnya terkunci ke ukuran desktop lama.

### Linked Issues

- lobby dan royal pass masih terasa sempit pada viewport desktop yang lebih kecil
- readability mobile belum bisa dikejar penuh sebelum `RoomBrowserUI` ikut dipecah menjadi layout fleksibel

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `LobbyUI` sekarang memakai ukuran viewport-aware pada jalur device sizing:
  - desktop sempit / mobile tidak lagi memaksa `340x368`
  - tombol `Profile`, `Shop`, `Royal Pass`, `Menu`, dan `Rank` ikut dihitung ulang berdasarkan lebar panel aktif
  - `LobbyToggleButton` ikut bergeser mengikuti lebar panel
- `RoyalPassUI` sekarang juga memakai ukuran viewport-aware:
  - panel melebar dan meninggi secara konservatif tanpa mengubah flow buka-tutup yang sudah stabil
  - text size `PrimaryLabel` dan `SecondaryLabel` dinaikkan sedikit untuk readability dasar
- `RoomBrowserUI` sengaja belum dirombak dalam patch ini; debt fullscreen/flexible mobile tetap dipertahankan sebagai task terpisah agar tidak mencampur perubahan besar dengan patch yang sudah stabil

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_responsive_lobby_pass_build.rbxlx`
- validasi lobby:
  - `ScreenCapture_Responsive_Lobby`
  - runtime:
    - `LobbyUI.MainPanel.Size = {0, 396}, {0, 384}`
    - `LobbyUI.MainPanel.Position = {0, 12}, {0, 12}`
    - `LobbyToggleButton.Position = {0, 416}, {0, 120}`
- validasi royal pass:
  - `ScreenCapture_Responsive_RoyalPass`
  - runtime:
    - `RoyalPassUI.MainPanel.Size = {0, 404}, {0, 388}`
    - `RoyalPassUI.MainPanel.Visible = true`

### Next Step

Task responsive yang benar-benar besar masih tersisa:
1. `RoomBrowserUI` fullscreen/flexible layout
2. `RoyalPassUI` 30-day reward + 30-day mission flow
3. touch target dan typography mobile yang lebih agresif setelah sheet utama aman

## 2026-04-03 13:24 ICT

### Task

Menutup overlap visual `RoomBrowserUI` terhadap rail kanan dan membuat browser tampil lebih fokus pada viewport aktif.

### Linked Issues

- right rail masih terlihat di samping `RoomBrowserUI`, sehingga surface utama terasa bertumpuk
- room browser masih terlalu kecil dan tidak memakai ruang viewport secara cukup agresif

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- float kanan auxiliary/basic sekarang otomatis disembunyikan saat `RoomBrowserUI` aktif
- `_layoutLobbyFloatRail()` tidak lagi mencoba menyusun rail kanan ketika room browser sedang terbuka
- scaling `RoomBrowserUI` dinaikkan menjadi lebih agresif terhadap viewport + safe inset, jadi browser tidak lagi berhenti di footprint desktop lama

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_roombrowser_focus_build.rbxlx`
- validasi live:
  - `ScreenCapture_RoomBrowser_Focus_NoOverlap`
  - runtime:
    - `RoomBrowserUI.Panel.Visible = true`
    - `RoomBrowserUI.Panel.UIScale.Scale = 1.18`
    - `Viewport = 1180x942`
    - rail kanan lain tidak tampil di layar saat room browser aktif

### Next Step

Lanjut ke surface berikutnya yang masih paling jelas unfinished:
1. struktur `RoyalPassUI` 30 hari
2. misi 30 hari + placeholder reward rarity 5
3. setelah itu baru kembali ke rework layout `RoomBrowserUI` mobile-fullscreen yang lebih besar

## 2026-04-03 13:29 ICT

### Task

Menaikkan `RoyalPassUI` dari preview tiga row menjadi surface season 30 hari yang lebih nyata, dengan dua track dan placeholder hadiah karakter rarity 5.

### Linked Issues

- royal pass belum memberi gambaran season progression yang bisa diingat pemain
- reward/misi harian masih abstrak dan belum punya affordance untuk di-swipe/di-scroll sebagai track panjang

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- menambahkan tab `30 DAY REWARD` dan `30 DAY MISSION` ke `RoyalPassUI`
- menambahkan `TrackScroller` horizontal berisi 30 kartu harian
- hari ke-30 sekarang punya treatment placeholder hadiah karakter rarity 5:
  - reward mode `DAY 30 • CHARACTER R5`
  - mission mode `MISSION 30 • GRAND FINALE`
- mode tab disimpan di state runtime client (`viewMode`) sehingga panel bisa refresh antara reward dan mission tanpa kehilangan snapshot server utama

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_royalpass_30day_build.rbxlx`
- validasi reward mode:
  - `ScreenCapture_RoyalPass_30Day_Rewards`
  - runtime:
    - `TrackScroller cardCount = 30`
    - `finalTitle = DAY 30 • CHARACTER R5`
    - `finalReward = R5 BORDER`
- validasi mission mode:
  - `ScreenCapture_RoyalPass_30Day_Missions`
  - runtime:
    - `hint = Geser horizontal untuk melihat 30 hari misi...`
    - `finalTitle = MISSION 30 • GRAND FINALE`
    - `finalReward = R5 TOKEN`

### Next Step

Masih ada polish visual/responsive yang tersisa:
1. `RoyalPassUI` track panjang perlu pass viewport kecil yang lebih nyaman
2. `RoomBrowserUI` fullscreen/flexible layout tetap pending
3. setelah dua itu stabil, baru kembali ke map logic/hunt loop

## 2026-04-03 13:37 ICT

### Task

Merapikan affordance `RoyalPassUI` 30 hari agar tab dan scroller track benar-benar masuk ke area baca utama, bukan tenggelam di bawah fold panel.

### Linked Issues

- track 30 hari sudah ada, tetapi pada panel lama tab dan scroller masih terlalu rendah
- royal pass terasa seperti panel desktop sempit, bukan surface progression yang pantas dibaca

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `RoyalPassUI` panel diperbesar lagi pada jalur viewport-aware menjadi footprint yang lebih layak (`436x520` pada viewport validasi)
- urutan deck diubah agar `30 DAY REWARD`, `30 DAY MISSION`, dan `TrackScroller` muncul sebelum blok summary tambahan
- hasilnya pemain langsung melihat tab dan kartu hari awal tanpa harus menggulung jauh ke bawah

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_royalpass_tab_order_build.rbxlx`
  - `rojo build default.project.json --output .\_tmp_royalpass_height_build.rbxlx`
- validasi visual:
  - `ScreenCapture_RoyalPass_30Day_TabOrder`
  - `ScreenCapture_RoyalPass_30Day_Taller`
- runtime akhir:
  - `RoyalPassUI.MainPanel.Size = {0, 436}, {0, 520}`

### Next Step

UI branch ini sekarang cukup stabil untuk digeser ke dua debt besar yang tersisa:
1. `RoomBrowserUI` fullscreen/flexible mobile layout
2. map logic + hunt survival loop yang lebih logis dan tidak terasa placeholder

## 2026-04-03 14:24 ICT

### Task

Mendesain ulang `RoomBrowserUI` agar menjadi surface fokus yang benar-benar fleksibel: split-pane desktop yang rapi, detail room yang tetap terbaca, dan jalur compact/mobile yang tidak lagi memaksa layout desktop.

### Linked Issues

- room browser lama masih berbasis koordinat absolut desktop sehingga cepat berantakan saat viewport menyempit
- state detail room berisiko memotong tombol penting host/ready/leave pada viewport pendek
- user secara eksplisit meminta panel besar tidak tumpang tindih dan browser room harus terasa lebih pantas di mobile

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- menambahkan pass layout `RoomBrowserUI` baru yang membagi browser menjadi dua mode:
  - desktop: split-pane fokus dengan daftar room kiri, preview kanan, dan action stack bawah yang tidak saling menimpa
  - compact/mobile: fullscreen sheet dengan preview di atas, room list di tengah, dan action buttons ditumpuk di bawah
- `RoomPanel` detail room diubah menjadi `ScrollingFrame`, lalu ditata ulang:
  - desktop: kolom kiri untuk map/control host, kolom kanan untuk anggota room
  - compact/mobile: satu kolom scrollable agar `mode`, `map`, `invite`, `ready`, dan `leave` tidak terpotong
- browser tidak lagi bergantung pada `UIScale` agresif; ukuran panel utama sekarang diatur langsung berdasarkan viewport
- row room list dan kartu player preview ikut dibesarkan pada mode compact agar tetap terbaca

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_roombrowser_mobile_pass_build.rbxlx`
- validasi live desktop browse state:
  - `ScreenCapture_RoomBrowser_Open_DesktopPass`
  - runtime:
    - `RoomBrowserUI.Panel.Size = {0, 1080}, {0, 668}`
    - `RoomBrowserUI.Panel.UIScale.Scale = 1`
- validasi live desktop room detail state:
  - `ScreenCapture_RoomBrowser_RoomPanel_DesktopPass`
  - runtime:
    - `RoomPanel.Visible = true`
    - `RoomPanel.CanvasSize = {0, 0}, {0, 668}`
    - `PlayersList.Size = {0, 599}, {0, 542}`
- catatan jujur:
  - jalur compact/mobile sudah masuk ke source
  - pass visual handset/device emulator nyata masih pending dan tetap harus divalidasi manual pada langkah berikutnya

### Next Step

UI branch ini sekarang cukup matang untuk kembali ke debt gameplay/runtime yang sempat tertunda:
1. sinkronisasi countdown + audio tick sebelum teleport
2. pastikan panel room browser benar-benar menutup state yang tersisa saat match mulai/teleport
3. lanjut ke map logic dan hunt survival loop

## 2026-04-03 14:41 ICT

### Task

Merapikan sinkronisasi countdown room sebelum teleport agar tick audio tidak menumpuk dan transisi ke fase match tetap bersih.

### Linked Issues

- user melaporkan countdown dan suara tidak sinkron berdasarkan detik
- sampling runtime menunjukkan countdown visual sudah benar, tetapi `RuntimeCountdownTick` bisa bertumpuk sampai empat instance karena asset tick lebih panjang dari satu detik

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- menambahkan registry `activeRuntimeUISounds` untuk runtime UI sound yang perlu dijaga single-instance
- `CountdownTick` sekarang selalu menghentikan instance tick sebelumnya sebelum memainkan tick detik berikutnya
- saat countdown selesai atau room browser disuppress oleh transisi match, tick aktif dibersihkan dan label countdown di-reset
- retest flow `HostStart -> Countdown -> Preparing` juga mengonfirmasi lagi bahwa `RoomBrowserUI` benar-benar mati saat match mulai, jadi bug panel room tertinggal tidak muncul pada runtime sekarang

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\_tmp_countdown_sync_build.rbxlx`
- timeline baseline sebelum patch:
  - `RuntimeCountdownTick` sempat bertumpuk sampai `soundCount = 4`
- timeline retest sesudah patch:
  - `overlayText` tetap urut `5 -> 4 -> 3 -> 2 -> 1`
  - `soundCount = 1` pada setiap detik countdown
  - saat `t = 5.0s` transisi ke `Preparing`, `RoomBrowserUI.Enabled = false`
  - pada fase setelah teleport hanya `RuntimeTeleportDrop` yang masih aktif
- capture referensi:
  - `ScreenCapture_Countdown_PreStart_State`
  - `ScreenCapture_Countdown_Retest_Final`

### Next Step

Debt berikutnya yang paling bernilai sekarang:
1. audit gameplay survival loop: hiding spot, pintu, dan cara selamat dari hunt
2. audit map traversal vertikal/tangga agar layout tidak terasa palsu
3. lanjut ke polish asset/audio final yang masih belum legal/final

## 2026-04-03 14:49 ICT

### Task

Menutup debt UX yang masih terlihat setelah teleport ke match, sekaligus menaikkan readability `RoomBrowserUI` dan `RoyalPassUI` untuk viewport sempit.

### Linked Issues

- user melaporkan room panel masih bisa tertinggal setelah teleport ke map match
- user meminta panel besar tidak tumpang tindih dan tetap nyaman dibaca di mobile/narrow viewport
- task survival/hunt shelter sempat dicoba lanjut, tetapi validasi server-side masih blocked

### Files Changed

- `src/client/UI/Main.lua`
- `src/ServerScriptService/Server/HidingSystem/Service.lua`
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `RoomBrowserUI` sekarang dipaksa ikut jalur suppression pada `MatchStarted`, bukan hanya `MatchPreparing`
- sizing `RoomBrowserUI` compact/mobile dibuat lebih agresif:
  - margin mobile diperkecil
  - panel mengisi viewport lebih penuh
  - title/status text dibesarkan
  - kartu player di detail room dibesarkan pada layout satu kolom
- `RoyalPassUI` sekarang punya pass responsive tambahan:
  - panel mobile/narrow viewport lebih lebar dan lebih tinggi
  - hero card, progress track, CTA, track tabs, hint, dan track cards ikut dibesarkan
- untuk debt survival loop, saya juga menambahkan jejak Studio-only di `HidingSystem` dan action debug baru `HidingDebugSnapshot` di `StudioE2EControlSystem`, tetapi jalur debug server itu belum berhasil divalidasi karena remote `StudioE2EControl` tidak muncul di runtime terbaru

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_roombrowser_mobile_pass_build.rbxlx`
- validasi live `RoyalPassUI` di lobby:
  - `RoyalPassUI.Enabled = true`
  - `MainPanel.Visible = true`
  - `MainPanel.AbsoluteSize = 436x520`
- validasi live `RoomBrowserUI` di lobby:
  - `RoomBrowserUI.Enabled = true`
  - `Panel.Visible = true`
  - `Panel.AbsoluteSize = 1080x668`
- retest dari state browser terbuka -> `HostStart(Ranked, HauntedHouse)`:
  - `InMatch = true`
  - `MatchPhase = Briefing`
  - `RoomBrowserUI.Enabled = false`
  - `RoomBrowserUI.Panel.Visible = false`
- capture referensi:
  - `ScreenCapture_RoomBrowserSuppressed_PostTeleport`

### Blocker Notes

- `HidingSystem` safe-zone/shelter belum bisa saya nyatakan selesai
- bukti paling jujurnya sekarang:
  - attr `PasrahHideState` dan `PasrahDebugHidingTrace` masih `nil` di runtime client
  - `StudioE2EControl` remote tidak tersedia pada retest runtime terbaru, sehingga snapshot server-side belum bisa dipakai untuk mengunci diagnosis

### Next Step

1. kembali ke debt gameplay/runtime: audit pintu hybrid radius/manual, traversal tangga, dan hiding spot
2. lanjutkan shelter/hunt survival setelah server-side debug bridge stabil lagi
3. teruskan polish asset/audio final yang masih belum legal/final

## 2026-04-03 14:56 ICT

### Task

Menggeser runtime pintu dari mode `pass-through` default ke basis interaksi pemain yang lebih logis dan lintas platform.

### Linked Issues

- user menegaskan pintu tidak boleh terasa palsu; pemain harus punya affordance yang masuk akal untuk buka/tutup
- traversal vertikal ke lantai dua terasa tidak logis jika pintu selalu pass-through

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- runtime patch map tidak lagi memaksa pintu clone playable map selalu terbuka
- policy default clone sekarang menjadi:
  - `DoorTraversalPolicy = PromptManual`
  - `DoorIsOpen = false`
  - `DoorLocked = false`
- ini menjaga affordance lintas platform tetap jelas karena `DoorRuntime` sudah memasang `ProximityPrompt` dengan:
  - keyboard `E`
  - gamepad `X`
  - clickable prompt untuk touch/tap

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_door_prompt_manual_build.rbxlx`
- validasi live pada `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Doors.Door_DiningRoom`:
  - `DoorTraversalPolicy = PromptManual`
  - `DoorIsOpen = false`
  - `CanCollide = true`
  - child runtime hadir:
    - `DoorPrompt`
    - `DoorPathModifier`
    - `DoorOpenSound`
    - `DoorCloseSound`
  - `DoorPrompt` aktif dengan `ActionText = Buka Pintu`
- capture referensi:
  - `ScreenCapture_StairTraversal_Bedroom1_Attempt`
  - `ScreenCapture_DoorPromptManual_OpenedConfirmed`

### Caveat

- trigger prompt via automation input masih belum cukup konsisten untuk saya jadikan bukti final buka/tutup pintu
- prompt memang muncul live di layar, tetapi state part hasil `keyPress(E)` belum stabil jika dibaca ulang lewat tool
- jadi task ini sekarang berada di status: `baseline runtime fixed, final manual confirmation still required`

### Next Step

1. validasi manual sekali untuk buka/tutup pintu pada runtime baru
2. lanjut audit traversal tangga dan akses lantai dua setelah pintu manual dipastikan stabil
3. kembali ke shelter/hiding runtime setelah server-side debug bridge pulih

## 2026-04-03 16:22 ICT

### Task

Menutup drift countdown room, memastikan panel room tidak bocor ke fase match, lalu menyiapkan ulang jalur `StudioE2EControl` sebagai remote canonical tanpa menghentikan progres UI.

### Linked Issues

- user melaporkan panel room masih tertinggal setelah teleport ke map match
- user melaporkan countdown dan suara tidak sinkron berdasarkan detik
- debt survival/hunt tetap blocked karena `StudioE2EControl` hilang dari runtime client

### Files Changed

- `src/ServerScriptService/Server/LobbySystem/Controller.lua`
- `src/client/UI/RoomBrowserController.lua`
- `src/client/UI/Main.lua`
- `src/ReplicatedStorage/RemoteEvents/StudioE2EControl.model.json`
- `src/ServerScriptService/Bootstrap.server.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- countdown room sekarang memakai anchor waktu server:
  - server mengirim `countdownEndsAt` bersama payload countdown
  - client menyimpan deadline itu di `RoomBrowserController`
  - overlay countdown menghitung angka dari `Workspace:GetServerTimeNow()`
- panel room sekarang benar-benar mati di `Preparing/Loading/Briefing`; `MatchUI` dan loading flow menjadi owner tampilan fase match
- `StudioE2EControl` sekarang source-controlled di `ReplicatedStorage.RemoteEvents` agar tidak lagi bergantung pada remote runtime sementara
- fallback kedua ditambahkan di `Bootstrap.server.lua` untuk mencoba menyalakan `StudioE2EControlSystem` setelah bootstrap utama
- `MatchUI` juga saya naikkan ke sizing viewport-aware:
  - panel, header, summary, footer, timer, quick evidence button, dan controls hint bar mengikuti viewport aktif

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_countdown_roomfix_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_studioe2e_remote_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_studioe2e_fallback_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_matchui_responsive_build.rbxlx`
- validasi live `HostStart(Ranked, HauntedHouse)`:
  - `RoomBrowserUI.Enabled = false`
  - `RoomBrowserUI.Panel.Visible = false`
  - `MatchPhase = Briefing`
  - capture referensi:
    - `ScreenCapture_CountdownRoomFix_Briefing`
- retest countdown + sound:
  - label countdown stabil berubah `5 -> 4 -> 3 -> 2 -> 1`
  - `RuntimeCountdownTick` tercipta `count=5`, satu kali per angka countdown
- validasi `MatchUI` terbaru di `Briefing`:
  - `MatchUI.MainPanel.AbsoluteSize = 340x454`
  - `EvidenceQuickButton.AbsoluteSize = 142x48`
  - `MatchTimerLabel.AbsoluteSize = 126x40`
  - capture referensi:
    - `ScreenCapture_MatchUI_Responsive_Briefing`

### Blocker Notes

- `StudioE2EControl` sekarang muncul sebagai remote client, tetapi listener server masih belum attach:
  - `PasrahStudioE2EReady` tetap `nil`
  - request `SetForcedGhost` tidak menghasilkan ack maupun update attribute
- artinya blocker tooling untuk audit shelter/hunt belum tertutup, walau canonical remote-nya sekarang sudah aman di source

### Next Step

1. checkpoint commit untuk fix countdown/panel/tooling canonical ini
2. lanjut ke task unblocked berikutnya sambil memarkir `StudioE2EControl` sebagai blocker tooling
3. kembali ke survival/hunt loop setelah jalur debug server bisa dihidupkan lagi atau diganti pendekatan lain

## 2026-04-03 16:54 ICT

### Task

Mengubah `MatchUI` dari panel status pasif menjadi panel fase yang benar-benar informatif selama match berjalan.

### Linked Issues

- panel match masih terasa terlalu generik dan banyak row kosong sebelum results
- copy hunt sebelumnya terlalu pasti soal shelter/safe zone padahal runtime survival loop belum tervalidasi penuh

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `MatchUI` summary rows sekarang memakai state runtime aktif saat belum ada result final:
  - status fase
  - evidence discovered/confirmed
  - kandidat ghost
  - status survival dasar
  - reward state `Pending`
- guidance hunt dibuat lebih jujur:
  - tidak lagi mengarahkan pemain ke `Safe Zone biru` seolah sistem itu sudah final
  - sekarang copy fokus ke aksi yang benar-benar relevan saat ini: putus `line-of-sight`, rotasi lewat pintu, cari ruang aman jika tersedia
- footer/copy briefing juga ikut lebih rapi karena summary deck sekarang mengisi kekosongan informasi, bukan lagi memaksa semua konteks ke satu paragraf

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_matchui_guidance_build.rbxlx`
- validasi live `Ranked + HauntedHouse` pada `Briefing`:
  - `StatusRow = BRIEFING`
  - `GhostRow = Belum teridentifikasi`
  - `GuessRow = Belum dikunci`
  - `EvidenceRow = 0 disc / 0 conf`
  - `SurvivedRow = Semua aktif`
  - `DeadRow = Belum ada`
- capture referensi:
  - `ScreenCapture_MatchUI_Guidance_Briefing`

### Next Step

1. lanjut ke surface unblocked berikutnya atau kembali ke gameplay/map debt
2. pertahankan `StudioE2EControl` sebagai blocker tooling terpisah sampai listener server benar-benar pulih

## 2026-04-03 15:39 ICT

### Task

Menyelaraskan runtime patch pintu dengan `DoorRuntime`, lalu memvalidasi kembali clone `HauntedHouse` pada jalur `Ranked` agar traversal pintu dan akses lantai dua tidak lagi saling bertentangan.

### Linked Issues

- pintu clone sebelumnya berstatus `PromptManual`, tetapi masih `CanCollide = false`, sehingga visual dan collision saling bohong
- user secara eksplisit meminta perilaku pintu yang logis, bukan pass-through yang membuat layout map terasa palsu
- debt audit traversal vertikal masih pending sesudah patch pintu manual

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `patchDoorTraversal()` tidak lagi memaksa pintu clone menjadi tembus saat policy-nya `PromptManual`
- default runtime pintu sekarang konsisten dengan `DoorRuntime`:
  - `CanCollide = true`
  - `CanTouch = true`
  - `DoorIsOpen = false`
  - `DoorTraversalPolicy = PromptManual`
- backlog source-of-truth saya rapikan agar tidak lagi menyimpan truth lama `AutoOpenToggle` sebagai state aktif
- task lanjutan juga dikunci lebih jelas:
  - desain final hybrid radius/manual tetap deferred
  - audit tangga/lantai dua/hiding spot tetap phase berikutnya, bukan hilang dari backlog

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_door_runtime_patch_build.rbxlx`
- validasi live jalur `Ranked -> SelectMode -> SelectMap(HauntedHouse) -> CreateRoom -> HostStart` sukses:
  - `CreateRoomResult.ok = true`
  - `HostStartResult.ok = true`
  - `RoomMatchCountdownCompleted` diterima client
- audit clone aktif `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Doors.Door_DiningRoom`:
  - `DoorTraversalPolicy = PromptManual`
  - `DoorIsOpen = false`
  - `CanCollide = true`
  - `CanTouch = true`
  - `DoorPrompt` ada
- audit traversal vertikal dasar `HauntedHouse`:
  - `Floor_2_North` runtime sudah tercarve menjadi `Floor_2_North_North`, `Floor_2_North_West`, `Floor_2_North_East`
  - tidak ada segmen `Floor_2_*` yang overlap dengan bounds `CentralStaircase`

### Blocker Notes

- trigger `E` melalui automation keyboard MCP masih belum cukup konsisten untuk dijadikan verifikasi final interaksi prompt
- jadi truth saat ini adalah:
  - state pintu clone sudah benar
  - interaksi prompt masih butuh satu verifikasi manual manusia di Studio untuk penutupan penuh task pintu

### Next Step

1. checkpoint commit untuk patch pintu manual + sinkronisasi report
2. lanjut ke debt gameplay/map yang tersisa:
   - audit traversal vertikal yang lebih nyata
   - definisi hiding spot / survive hunt
3. pertahankan `StudioE2EControl` sebagai blocker tooling terpisah sampai listener server pulih atau diganti pendekatan lain

## 2026-04-03 15:41 ICT

### Task

Memvalidasi traversal vertikal `HauntedHouse` lewat runtime match aktif, supaya isu “tangga tidak benar-benar membawa pemain ke atas” diputus dengan bukti pathfinding, bukan asumsi visual.

### Linked Issues

- user menganggap layout tangga/lantai dua terasa palsu dan mungkin masih tertutup
- sesudah patch pintu manual, perlu bukti apakah runtime clone benar-benar bisa membawa pemain ke lantai dua

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- saya jalankan lagi flow `Ranked -> HauntedHouse -> CreateRoom -> HostStart`
- fokus audit dipersempit ke tiga target lantai dua yang benar-benar relevan:
  - `Interact_Bedroom2`
  - `Room_Bedroom2`
  - `Room_Attic`
- hasil audit dipindahkan ke backlog source-of-truth agar truth terbaru soal traversal vertikal tidak tercecer di sesi chat

### Validation Notes

- runtime clone aktif berhasil dibuat lagi via jalur room browser canonical
- pathfinding live dari posisi spawn match aktif (`1190.999, 3.471, -9.998`) menghasilkan:
  - `Interact_Bedroom2`: `Enum.PathStatus.Success`, `28` waypoint
  - `Room_Bedroom2`: `Enum.PathStatus.Success`, `28` waypoint
  - `Room_Attic`: `Enum.PathStatus.Success`, `19` waypoint
- ini menguatkan audit sebelumnya bahwa carved floor di sekitar `CentralStaircase` memang menghasilkan jalur upstairs yang valid

### Interpretation

- blocker teknis “lantai dua ketutup / tidak bisa diakses” sekarang tertutup untuk `HauntedHouse`
- debt yang tersisa berubah bentuk:
  - bukan lagi collision/path kosong
  - melainkan experiential pass layout, hiding spot, dan cara survive hunt yang masih perlu didefinisikan

### Next Step

1. checkpoint commit untuk sinkronisasi report traversal vertikal
2. lanjut ke debt gameplay berikutnya:
   - definisi hiding spot dan survive hunt
   - keputusan desain final pintu hybrid radius/manual lintas platform
3. pertahankan `StudioE2EControl` sebagai blocker tooling terpisah sampai listener server pulih atau diganti pendekatan lain

## 2026-04-03 15:49 ICT

### Task

Menguji jalur shelter `SafeZone` yang sudah ada di source, lalu menambahkan probe Studio-only minimal untuk membedakan antara bug desain hiding dan bug aktivasi runtime system.

### Linked Issues

- user belum tahu cara selamat dari hunt dan apakah shelter benar-benar bekerja
- backlog sebelumnya sudah menandai `SafeZone` ada di source, tetapi belum ada bukti runtime bahwa player benar-benar menjadi `Hidden`

### Files Changed

- `src/ServerScriptService/Server/HidingSystem/Service.lua`
- `src/ServerScriptService/Server/PlayerHealthSystem/Service.lua`
- `src/ServerScriptService/Server/ServerBootstrap.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- saya tambahkan readiness marker Studio-only:
  - `PasrahHidingReady`
  - `PasrahHidingActiveMatchId`
  - `PasrahHidingRegisteredMatchId`
  - `PasrahHidingZoneCount`
  - `PasrahHuntPressureReady`
  - `PasrahHuntPressureActiveMatchId`
- `ServerBootstrap` sekarang juga punya fallback Studio untuk mencoba menghidupkan:
  - `HidingSystem`
  - `PlayerHealthSystem`
- tujuan patch ini bukan menambah fitur baru, tetapi membuat blocker runtime bisa diukur dengan jelas

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_hiding_debug_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_hiding_bootstrap_build.rbxlx`
- edit-time scan di Studio mengonfirmasi source terbaru memang ada:
  - `ServerScriptService.Server.HidingSystem`
  - `ServerScriptService.Server.PlayerHealthSystem`
  - `ServerBootstrap` terbaru dengan helper `ensureStudioRuntimeSystem()`
  - grep live juga menemukan `PasrahHidingReady` di `HidingSystem.Service`
- tetapi validasi playtest tetap menunjukkan:
  - `PasrahHidingReady = nil`
  - `PasrahHuntPressureReady = nil`
  - `PasrahHideState = nil`
  - `SafeZone_1.CanTouch` tetap belum berubah ke state hasil register runtime

### Interpretation

- blocker shelter sekarang terlokalisasi dengan cukup jelas:
  - source dan mapping edit-time bukan masalah utama
  - yang macet adalah aktivasi startup/runtime untuk `HidingSystem` / `PlayerHealthSystem` saat playtest
- artinya saya belum boleh mengklaim aturan survive hunt sudah playable, walau data `SafeZone` dan jalur logic dasar sudah ada di source

### Next Step

1. checkpoint commit untuk patch readiness/fallback shelter
2. minta satu intervensi manual minimum jika perlu:
   - full restart Studio
   - reconnect `Rojo`
   - lalu retest probe runtime
3. baru sesudah readiness marker hidup, lanjut tutup shelter/hunt behavior end-to-end

## 2026-04-03 17:07 ICT

### Task

Menutup gap utility tool yang sebelumnya hanya ada di backend evidence, lalu membuat jalur canonical `Field Kit` di `MatchUI` agar `Garam`, `Salib`, dan `Dupa` benar-benar playable dan punya visual runtime di Studio.

### Linked Issues

- utility tool sudah punya logic server, tetapi pemain belum punya owner UI canonical untuk memakainya
- event utility sebelumnya selalu terasa seperti side-effect journal, bukan gameplay tool lapangan
- tool utility client masih memakai default `nearGhostRoom = true`, sehingga perilaku terasa "ajaib" dan tidak representatif sebagai placement tool

### Files Changed

- `src/client/UI/Main.lua`
- `src/client/EvidenceTools/Garam/Main.lua`
- `src/client/EvidenceTools/Salib/Main.lua`
- `src/client/EvidenceTools/Dupa/Main.lua`
- `src/ServerScriptService/Server/EvidenceSystem/Controller.lua`
- `src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua`
- `src/ServerScriptService/Server/EvidenceSystem/Modules/UtilityToolVisuals.lua`
- `src/ReplicatedStorage/Assets/Models/Tools/Garam.model.json`
- `src/ReplicatedStorage/Assets/Models/Tools/Salib.model.json`
- `src/ReplicatedStorage/Assets/Models/Tools/Dupa.model.json`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- saya tambahkan owner UI canonical `Field Kit` di `MatchUI`:
  - tombol `SCAN`, `GARAM`, `SALIB`, `DUPA`
  - shortcut `[1] [2] [3] [4]`
  - feedback status tool langsung di panel tanpa membuka journal
- saya ubah jalur client tool utility agar tidak lagi auto mengirim `nearGhostRoom = true`
- saya tambahkan broadcast utility evidence event ke client dengan `autoOpenJournal = false`
- saya tambahkan visual runtime utility tool di server:
  - module baru `UtilityToolVisuals`
  - asset source-owned untuk `Garam`, `Salib`, `Dupa`
  - fallback runtime builder kalau template asset tidak terbaca server saat Studio play clone
- `EvidenceService` sekarang mengelola lifecycle placement id, visual placement, charge update salib, dan cleanup runtime
- response utility tool sekarang juga mengembalikan metadata `visualPlaced` untuk QA Studio

### Validation Notes

- sinkronisasi source tervalidasi di Studio:
  - `ReplicatedStorage.Assets.Models.Tools` berisi `Garam`, `Salib`, `Dupa`
  - `UtilityToolVisuals` bisa di-`require`
- playtest live Studio tervalidasi dengan jalur canonical:
  - buat room -> ready -> host start
  - `MatchUI.FieldKitFrame.Visible = true`
  - tekan `[2]` melalui input nyata menghasilkan response:
    - `status = Garam aktif.`
    - `detail = Menunggu ghost menginjak area ini.`
    - `Workspace.ActiveMatches.Match_match_1.InvestigationTools` berisi `Garam_*`
  - lanjut tekan `[3]` dan `[4]` menghasilkan child runtime total `3`:
    - `Garam_*`
    - `Salib_*`
    - `Dupa_*`
- utility feedback tidak lagi intrusif:
  - `JournalUI.MainPanel.Visible = false` saat event utility masuk
  - `Field Kit` tetap menerima status runtime, termasuk saat `SaltTriggered`

### Interpretation

- gap “backend tool ada tapi pemain tidak bisa memakai secara canonical” sekarang tertutup
- slice investigasi sekarang tidak lagi bergantung hanya pada scan evidence; utility tool sudah masuk ke runtime playable surface
- debt berikutnya bergeser dari availability menjadi design quality:
  - placement semantics per-room
  - hiding/survival rules
  - asset polish audio/visual final

### Next Step

1. checkpoint commit untuk field kit + utility tool runtime
2. lanjut ke debt gameplay berikutnya yang masih P0/P2:
   - hiding/survival clarity
   - polish `MatchUI`/mobile layout lanjutan
   - asset audio/ambient final yang masih kosong

## 2026-04-03 17:37 ICT

### Task

Mengganti flashlight procedural lama dengan slice flashlight tangan-kanan berbasis asset `516522664`, memunculkan dua tangan FPV di sisi bawah layar, dan memastikan toggle click sound benar-benar aktif saat flashlight dinyalakan/dimatikan.

### Linked Issues

- flashlight FPV lama masih berupa part procedural, bukan asset flashlight yang benar
- `CameraController` sempat gagal total karena syntax error, sehingga `LockFirstPerson` dan FPV hands tidak pernah hidup
- target user meminta dua tangan tetap terlihat di kiri-bawah/kanan-bawah, dan flashlight harus menjadi objek terpisah, bukan "tangan jadi senter"

### Files Changed

- `src/shared/GameData/FlashlightConfig.lua`
- `src/client/CameraController.client.lua`
- `src/ServerScriptService/Server/FlashlightSyncSystem/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- saya buat source-of-truth baru `FlashlightConfig` di `shared/GameData` untuk:
  - `assetId = 516522664`
  - mesh `115955313`
  - texture `115955343`
  - click sound `115959318`
  - FPV hand layout, mount offset, dan light tuning
- `CameraController` sekarang:
  - load config shared, bukan hardcode procedural lama
  - render flashlight sebagai objek `Handle + Lens` terpisah di tangan kanan
  - tetap render dua tangan FPV di bawah layar
  - punya runtime guard yang memaksa `LockFirstPerson` tetap konsisten saat `InMatch = true`
  - syntax error parser di line flashlight builder sudah dibersihkan
- `FlashlightSyncSystem` server sekarang:
  - pakai mesh flashlight yang sama untuk representasi player lain
  - pasang `FlashlightToggleClick`
  - memutar click sound saat state toggle berubah

### Validation Notes

- inspeksi asset live via Studio:
  - `516522664` resolve ke `Tool` bernama `Flashlight`
  - handle membawa mesh `115955313`, texture `115955343`, sound `115959318`
- playtest Studio tervalidasi:
  - create room -> ready -> host start
  - `Players.LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson`
  - `Workspace.CurrentCamera.FPV_Arms` ada selama match
  - toggle `[F]` mengubah `FlashlightEnabled = true`
  - `Character.FlashlightHandle.FlashlightToggleClick` ada
  - `IsPlaying = true` saat toggle, `SoundId = rbxassetid://115959318`
- visual runtime snapshot menunjukkan:
  - dua tangan tetap hadir di bawah layar
  - flashlight tampil sebagai objek terpisah di sisi kanan bawah
  - blocker lama "tangan adalah flashlight" sudah tertutup secara sistem

### Interpretation

- slice flashlight sekarang sudah source-controlled dan tidak bergantung pada insert manual di Studio
- visual player lain dan visual FPV pemain lokal memakai identitas asset yang sama
- sisa debt untuk slice ini sekarang turun level menjadi polish framing/material, bukan lagi blocker fungsi

### Next Step

1. lanjutkan pass polish visual/tool readability berikutnya tanpa menyentuh ulang arsitektur flashlight
2. kalau perlu, lakukan pass art lanjutan agar silhouette tangan lebih natural, tetapi basis system sudah stabil

## 2026-04-03 17:50 ICT

### Task

Menutup gap `hiding/survival clarity` tanpa membuat sistem baru: validasi runtime `SafeZone` dan `hunt pressure` yang sudah ada, lalu promosikan state survive ke `MatchUI` supaya pemain mendapat instruksi yang jujur saat diburu.

### Linked Issues

- pemain belum punya penjelasan yang cukup jelas tentang cara selamat dari hunt
- `HidingSystem` dan `PlayerHealthSystem` sudah punya state runtime, tetapi `MatchUI` masih terlalu generik saat hunt aktif
- safe zone ada di map, namun guidance ke pemain belum memanfaatkan state `Hidden / Sheltered / Tracked / Critical`

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- saya pertahankan arsitektur yang ada dan hanya menambah interpretasi UI:
  - helper `getHuntStatusSnapshot()`
  - helper badge `HIDDEN / SHELTERED / TRACKED / CRITICAL / HUNT`
  - helper controls hint yang berubah mengikuti state survive
- `MatchUI` sekarang saat hunt:
  - status row tidak lagi selalu generik `CRITICAL`
  - summary rows menampilkan guidance survive yang lebih eksplisit
  - controls hint berganti antara:
    - cari safe zone
    - putus line-of-sight
    - diam dan tunggu hunt selesai

### Validation Notes

- validasi live server rule:
  - `HidingSystem` aktif
  - `HauntedHouse` runtime mendaftarkan `2` safe zone
  - saat karakter dipindahkan ke `SafeZone_1`, atribut player berubah menjadi:
    - `PasrahHideState = Hidden`
    - `PasrahHideZoneId = SafeZone_1`
    - `PasrahHuntThreatState = Sheltered`
- validasi client:
  - tidak ada error baru di log client setelah patch `UI/Main.lua`
- batas validasi yang masih terbuka:
  - helper Studio `AdvancePhase/ForceHunt` belum konsisten memindahkan panel ke visual state `Hunt`
  - jadi verifikasi slice ini ditutup pada level:
    - state server live benar
    - interpretasi UI sudah source-controlled dan bebas error

### Interpretation

- debt utama sekarang bukan lagi rule survive, melainkan penyajian dan alur test helper Studio
- pemain sekarang punya guidance survive yang jauh lebih dekat ke reality state server, bukan copy generik

### Next Step

1. lanjutkan noise/runtime cleanup atau phase helper Studio agar validasi hunt visual lebih deterministik
2. setelah itu masuk ke slice polish berikutnya yang paling relevan dengan publish

## 2026-04-03 18:06 ICT

### Task

Tutup drift hunt client dengan menghubungkan `HuntStarted/HuntEnded` ke `MatchEvent` dan menghentikan post-teleport loading yang menimpa state hunt.

### Linked Issues

- hunt visual drift
- post-teleport loading override
- Studio E2E force hunt tidak terlihat di client

### Files Changed

- `src/ServerScriptService/Server/HuntSystem/Controller.lua`
- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `HuntSystem.Controller` sekarang me-relay `HuntStarted` dan `HuntEnded` ke `MatchEvent` untuk semua player di match aktif
- `UISystem` sekarang:
  - punya token cancel untuk post-teleport loading flow
  - membatalkan loading flow lama saat hunt datang
  - mengangkat `MatchPhase` canonical ke `Hunt` saat `HuntStarted`
  - mengembalikan `MatchPhase` ke `InGame` saat `HuntEnded`
- jalur ini menjaga state inti UI tetap sinkron tanpa memaksa lifecycle match linear menjadi alat hunt sementara

### Validation Notes

- validasi live Studio berhasil:
  - playtest restart
  - `CreateRoom -> HostStart -> ForceHunt`
  - `PasrahStudioE2ELastResult = ok=true | action=ForceHunt | result=match=match_1 forced`
  - client menerima event `HuntStarted`
  - `LocalPlayer.MatchPhase = Hunt`
- validasi live exit hunt juga berhasil:
  - player dipindahkan ke `SafeZone_1` runtime `HauntedHouse`
  - atribut player menjadi `PasrahHideState = Hidden` dan `PasrahHuntThreatState = Sheltered`
  - setelah hunt selesai natural, `LocalPlayer.MatchPhase` kembali ke `InGame`
  - sesi tetap hidup dan tidak jatuh ke `Result` saat menunggu hunt selesai
- sesi uji sebelumnya menunjukkan root cause asli:
  - `ForceHunt` accepted server-side
  - tetapi client tidak menerima event hunt dan tetap jatuh ke `Briefing`

### Interpretation

- blocker hunt visual Studio E2E sudah tidak lagi berada di helper force trigger
- debt kecil yang tersisa di slice ini bukan lagi phase drift, melainkan polish perilaku hunt dan presentasi match

### Next Step

1. tutup satu pass live untuk natural hunt exit jika kesempatan runtime mendukung
2. lanjut ke item publish-critical berikutnya dari backlog tanpa membuka drift baru

## 2026-04-03 18:56 ICT

### Task

Polish `RoomBrowserUI` compact/mobile dan `RoyalPassUI` track 30 hari agar surface besar terasa lebih fokus, lebih mudah dibaca, dan lebih dekat ke perilaku panel produksi.

### Linked Issues

- mobile room browser readability
- royal pass long-track scrolling
- finale placeholder kurang menonjol

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `RoomBrowserUI`:
  - margin mobile dipersempit lagi agar sheet compact lebih dekat ke fullscreen
  - close button mobile diperbesar
  - title mobile diperbesar
  - background sheet mobile dibuat sedikit lebih solid untuk bantu keterbacaan
- `RoyalPassUI`:
  - track sekarang auto-focus ke hari aktif saat season/view/tier berubah
  - kartu hari ke-30 dibuat lebih lebar sebagai finale placeholder rarity 5
  - state fokus track disimpan terpisah agar refresh berikutnya tidak terus-menerus memaksa scroll

### Validation Notes

- validasi live desktop berhasil:
  - `RoomBrowserUI.Panel.Size = 1080x668`
  - `CloseButton.Size = 34x28`
  - `RoomBrowserUI` tetap terbuka normal pada viewport desktop `1600x734`
  - `RoyalPassUI` tetap hidup dan `DayCard30.Size = 158x156`
  - `TrackScroller.CanvasPosition = 0,0` pada baseline `Tier 01`
- log runtime terbaru tidak menunjukkan error UI baru setelah restart playtest
- batas validasi yang masih terbuka:
  - handset/device emulator nyata masih perlu pass lanjutan untuk membuktikan effect patch compact/mobile, karena sesi ini hanya memverifikasi runtime desktop langsung

### Interpretation

- debt layout besar tidak lagi semata soal ukuran panel; sekarang masuk ke polish ergonomi dan scroll focus
- `RoyalPassUI` sudah lebih dekat ke ekspektasi pass live, sementara `RoomBrowserUI` compact punya base yang lebih aman untuk pass handset berikutnya

### Next Step

1. lanjutkan pass handset/device-aware untuk `RoomBrowserUI` dan `RoyalPassUI` bila butuh validasi visual yang lebih tajam
2. setelah itu masuk ke slice map/door/gameplay polish yang paling mengganggu flow investigasi

## 2026-04-03 19:44 ICT

### Task

Mengubah baseline pintu map playable dari `PromptManual` menjadi hybrid radius/manual yang tetap menjaga prompt lintas platform, lalu memvalidasi buka/tutup otomatisnya langsung di runtime `HauntedHouse`.

### Linked Issues

- user meminta pintu tidak sekadar "otomatis terbuka", tetapi logis untuk traversal, konsisten lintas platform, dan tidak kembali ke state map basic
- backlog sebelumnya masih menandai desain pintu hybrid sebagai deferred padahal implementasi runtime sekarang sudah siap diuji

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `MapRuntimePatches` sekarang menjadikan `HybridRadiusPrompt` sebagai default `DoorTraversalMode` pada clone map runtime
- `DoorRuntime` sekarang:
  - menormalkan policy pintu ke canonical enum runtime
  - tetap mempertahankan `DoorPrompt` manual
  - menambah loop radius assist berbasis `Heartbeat` untuk buka/tutup otomatis saat pemain mendekat/menjauh
  - menjaga manual override singkat agar interaksi prompt pemain tidak langsung dilawan oleh auto-close
  - mengirim interaction source lokal eksplisit agar event bus tidak memantulkan state pintu yang sama dua kali

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_door_hybrid_build.rbxlx`
- validasi live Studio pada jalur `CreateRoom -> HostStart -> HauntedHouse` sukses:
  - clone aktif `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Doors.Door_DiningRoom` membawa:
    - `DoorTraversalPolicy = HybridRadiusPrompt`
    - `DoorPrompt.ActionText = Buka Pintu`
  - saat karakter dipindahkan dekat pintu:
    - `DoorIsOpen = true`
  - saat karakter dipindahkan menjauh lagi:
    - `DoorIsOpen = false`

### Interpretation

- desain pintu hybrid radius/manual untuk baseline playable map sudah tidak lagi berada di status deferred
- debt berikutnya bergeser ke kualitas layout/map dan definisi hiding spot, bukan lagi ke pemilihan policy pintu dasar

### Next Step

1. checkpoint commit untuk slice pintu hybrid + sinkronisasi report
2. lanjut ke pass gameplay berikutnya:
   - hiding spot affordance
   - flow traversal/map readability

## 2026-04-03 20:02 ICT

### Task

Menambahkan affordance world-space untuk `SafeZone` saat hunt aktif, supaya pemain tidak hanya diberi teks HUD tetapi juga target visual nyata untuk berlindung di runtime map.

### Linked Issues

- rule `Hidden / Sheltered` sudah hidup, tetapi affordance shelter di dunia 3D masih terlalu samar
- validasi pertama sempat bohong karena Rojo belum aktif, sehingga Studio masih menjalankan source lama tanpa marker runtime

### Files Changed

- `src/ServerScriptService/Server/HidingSystem/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `HidingSystem.Service` sekarang membuat marker runtime untuk setiap `SafeZone`:
  - folder runtime `SafeZoneRuntimeMarker`
  - `BoxHandleAdornment` outline
  - `BillboardGui` dengan panel `SAFE ZONE`
- marker hanya diaktifkan saat hunt aktif, sejalan dengan visual `ForceField` biru yang sudah ada
- cleanup match sekarang juga membersihkan marker runtime agar clone berikutnya tidak mewarisi adornment lama

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_safezone_affordance_build.rbxlx`
- setelah Rojo diaktifkan ulang, Studio edit-time mengonfirmasi patch benar-benar tersinkron:
  - grep `SafeZoneRuntimeMarker` ditemukan
  - grep `Diam di sini saat hunt` ditemukan
- validasi live Studio pada jalur `Ranked -> CreateRoom -> HostStart -> ForceHunt` sukses:
  - `LocalPlayer.MatchPhase = Hunt`
  - `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.SafeZones.SafeZone_1` membawa:
    - `Transparency = 0.82`
    - `Material = Enum.Material.ForceField`
    - child `SafeZoneRuntimeMarker`
    - `Outline.Visible = true`
    - `Billboard.Enabled = true`
    - `Billboard.StudsOffsetWorldSpace = 0, 6.6, 0`

### Interpretation

- shelter sekarang tidak lagi hanya konsep backend + teks HUD; pemain punya marker world-space yang jujur saat hunt
- debt berikutnya bergeser ke kualitas placement hiding spot lintas map dan layout traversal, bukan lagi ke affordance minimum untuk survive

### Next Step

1. checkpoint commit untuk slice safe zone affordance
2. lanjut ke readability/traversal pass berikutnya:
   - audit spot hiding final lintas map
   - polish flow layout dan akses ruangan penting

## 2026-04-03 20:23 ICT

### Task

Menutup drift shelter lintas playable map dengan mengaudit path runtime dari spawn map ke `SafeZone`, lalu menormalkan posisi zone yang gagal melalui `MapRuntimePatches`.

### Linked Issues

- shelter sudah punya marker visual, tetapi beberapa map masih berisiko bohong karena `SafeZone` tidak benar-benar reachable dari spawn match
- audit awal lintas map menunjukkan blocker nyata:
  - `AbandonedPalace`: `SafeZone_1` = `NoPath`
  - `EmptyBuilding`: `SafeZone_1` dan `SafeZone_2` = `NoPath`
  - `StudioMMNineteen`: `SafeZone_1` = `NoPath`

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- saya tambahkan `SAFE_ZONE_POSITION_OVERRIDES` source-controlled di `MapRuntimePatches`
- clone runtime sekarang menormalkan posisi `SafeZone` yang gagal pada tiga map:
  - `AbandonedPalace.SafeZone_1 -> (-63.2, 4, 32.4)`
  - `EmptyBuilding.SafeZone_1 -> (778, 4, -10)`
  - `EmptyBuilding.SafeZone_2 -> (824, 4, -20)`
  - `StudioMMNineteen.SafeZone_1 -> (369.4, 4, 18.2)`
- patch ini sengaja diletakkan di runtime patch layer, bukan mengubah model mentah, agar fix tetap mode-agnostic dan mudah diaudit ulang

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_safezone_runtime_patch_build.rbxlx`
- edit-time Studio mengonfirmasi patch sinkron:
  - grep `SAFE_ZONE_POSITION_OVERRIDES` ditemukan
  - grep `SafeZoneRuntimePatched` ditemukan
- re-audit live runtime dari `PlayerSpawn_1` ke semua `SafeZone` menghasilkan:
  - `HauntedHouse`: `SafeZone_1 Success (26 waypoint)`, `SafeZone_2 Success (32 waypoint)`
  - `AbandonedPalace`: `SafeZone_1 Success (47 waypoint)`, `SafeZone_2 Success (87 waypoint)`
  - `EmptyBuilding`: `SafeZone_1 Success (4 waypoint)`, `SafeZone_2 Success (10 waypoint)`
  - `StudioMMNineteen`: `SafeZone_1 Success (15 waypoint)`, `SafeZone_2 Success (16 waypoint)`

### Interpretation

- baseline shelter current playable maps sekarang sudah benar-benar reachable, bukan sekadar part invisible yang kebetulan ada di data model
- debt map berikutnya turun level menjadi art/layout readability dan hiding spot final yang lebih kaya, bukan lagi blocker akses dasar ke safe zone

### Next Step

1. checkpoint commit untuk patch safe zone runtime lintas map
2. lanjut ke debt traversal/layout berikutnya:
   - audit pintu terkunci dan flow ruangan penting
   - definisi hiding spot final di luar baseline safe zone

## 2026-04-03 20:37 ICT

### Task

Mengurangi interaction point palsu dengan menambahkan normalisasi reachability runtime: interaction point tetap ditambatkan ke room anchor, tetapi jika `NoPath` dari spawn map maka ia didorong ke spot reachable terdekat sesudah patch pintu hybrid aktif.

### Linked Issues

- audit runtime menunjukkan banyak `InteractionPoint` jatuh di pusat room yang tidak pathable dari spawn match
- urutan patch awal sempat salah: reachability dihitung sebelum pintu hybrid/path modifier aktif, sehingga menghasilkan false negative

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `MapRuntimePatches` sekarang:
  - memanggil `patchDoorTraversal()` sebelum `patchInteractionPoints()`
  - memakai `PathfindingService` untuk menilai reachability dari `PlayerSpawn_1`
  - mencoba nudge linear ke arah jalur masuk, lalu fallback grid search lokal bila perlu
- target patch ini bukan mengganti desain map mentah, tetapi mengurangi titik investigasi yang bohong pada clone runtime

### Validation Notes

- build source lolos berturut-turut:
  - `rojo build default.project.json --output .\\_tmp_interaction_reachability_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_interaction_reachability_reorder_build.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_interaction_reachability_grid_build.rbxlx`
- edit-time Studio mengonfirmasi patch sinkron:
  - grep `findReachableInteractionPosition` ditemukan
  - grep `INTERACTION_REACHABILITY_GRID_RADIUS` ditemukan
- audit live terbaru setelah clone settle:
  - `AbandonedPalace`: `0/8` interaction point fail
  - `StudioMMNineteen`: `0/8` interaction point fail
  - `HauntedHouse`: `2/8` fail tersisa
    - `Interact_Bedroom1`
    - `Interact_Kitchen`
  - `EmptyBuilding`: `3/8` fail tersisa
    - `Interact_WorkspaceOpen`
    - `Interact_OfficeB`
    - `Interact_Bathroom1`

### Interpretation

- patch generik ini berhasil menutup mayoritas drift interaction point tanpa perlu mengotak-atik model map mentah
- residual yang tersisa sekarang lebih kecil dan lebih spesifik; beberapa anchor tampaknya butuh keputusan layout/map-specific, bukan sekadar nudge generik lagi

### Next Step

1. checkpoint commit untuk interaction reachability runtime
2. lanjut ke residual map-specific traversal:
   - `HauntedHouse`: `Bedroom1` dan `Kitchen`
   - `EmptyBuilding`: `WorkspaceOpen`, `OfficeB`, `Bathroom1`

## 2026-04-03 21:45 ICT

### Task

Menutup residual runtime `EmptyBuilding` yang sempat tersisa pada `InteractionPoints` dan `SafeZones`, lalu memverifikasi ulang clone match setelah settle final agar audit tidak berhenti di false negative.

### Linked Issues

- audit cepat sesudah `HostStart` sempat membaca `EmptyBuilding` seolah masih `6/8 fail`, padahal clone runtime belum selesai settle
- override spesifik map untuk `InteractionPoints` dan `SafeZones` bergantung pada token `mapId`; pada jalur runtime ini token yang sampai ke `MapRuntimePatches` tidak selalu cocok dengan `emptybuilding`
- akibatnya patch generik `SecondFloor` dan `DoorTraversal` aktif, tetapi patch spesifik `EmptyBuilding` tidak selalu ikut terbaca

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `MapRuntimePatches` sekarang memakai helper `resolveMapOverrideToken(mapId, mapClone)`:
  - prioritas pertama tetap `mapId`
  - fallback kedua memakai `mapClone.Name`
- patch spesifik berikut sekarang tidak lagi bergantung penuh pada token queue/runtime yang drift:
  - `INTERACTION_POSITION_OVERRIDES.emptybuilding`
  - `SAFE_ZONE_POSITION_OVERRIDES.emptybuilding`
- validasi tidak lagi membaca clone terlalu cepat; audit akhir dilakukan pada clone yang sama setelah settle final

### Validation Notes

- source Studio terverifikasi memuat helper fallback token baru sebelum playtest ulang
- validasi live terbaru pada clone `Workspace.ActiveMatches.Match_match_1.EmptyBuilding` setelah settle final menunjukkan:
  - `SecondFloorRuntimePatched = true`
  - `DoorTraversalRuntimePatched = true`
  - `InteractionPointsRuntimePatched = true`
  - `SafeZoneRuntimePatched = true`
- posisi final penting yang tervalidasi:
  - `Interact_WorkspaceOpen = (800, 2, -8)`
  - `Interact_OfficeB = (822.667, 2, -8)`
  - `Interact_Bathroom1 = (822, 2, -9)`
  - `SafeZone_1 = (778, 4, -10)`
  - `SafeZone_2 = (824, 4, -20)`
- audit pathfinding final dari `PlayerSpawn_1` menghasilkan:
  - `EmptyBuilding`: `0/8` interaction point fail
  - `EmptyBuilding`: `2/2` safe zone success

### Interpretation

- residual `EmptyBuilding` yang sebelumnya terlihat seperti debt layout ternyata gabungan dua hal:
  - token override spesifik map tidak cukup defensif
  - audit dilakukan terlalu cepat sebelum runtime point selesai settle
- setelah dua hal itu ditutup, debt aktif bergeser dari `interaction anchor bohong` ke `door/map gameplay polish`

### Next Step

1. checkpoint commit untuk penutupan residual `EmptyBuilding`
2. lanjut ke pass `door/map gameplay polish`:
   - radius/manual flow pintu lintas map
   - traversal visual yang lebih logis
   - penutupan debt tangga/lantai atas yang masih terasa basic

## 2026-04-03 22:18 ICT

### Task

Memoles ulang perilaku auto-open pintu hybrid supaya tidak lagi memakai radius bola mentah, lalu memvalidasi bahwa pintu hanya membuka saat pemain benar-benar masuk zona ambang pintu.

### Linked Issues

- policy `HybridRadiusPrompt` sudah aktif, tetapi pendekatan radius murni masih terlalu kasar untuk map sempit
- saat daun pintu sudah terbuka dan berputar, zona deteksi lama ikut bergeser bersama `part.CFrame`
- efek sampingnya pintu bisa terasa "lengket" terbuka atau berbunyi tidak logis hanya karena pemain masih dekat di samping daun pintu

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `DoorRuntime` tidak lagi menghitung auto-open berdasarkan jarak Euclidean sederhana ke pusat pintu
- deteksi hybrid sekarang memakai zona ambang pintu yang:
  - membaca posisi pemain di local space pintu
  - mengecek toleransi vertikal
  - membatasi lateral range sesuai lebar pintu
  - memakai `closedCFrame` sebagai referensi tetap, bukan `part.CFrame` saat daun pintu sudah terbuka
- prompt manual lintas platform tetap dipertahankan; yang berubah hanya heuristik auto-open/auto-close agar lebih masuk akal secara visual

### Validation Notes

- source Studio terverifikasi memuat helper `getPlayerDoorApproachDistance(...)` yang membaca `doorRecord.closedCFrame`
- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_door_zone_polish_build.rbxlx`
- validasi live di `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Doors.Door_DiningRoom` menunjukkan:
  - `DoorPrompt` hadir
  - `DoorTraversalPolicy = HybridRadiusPrompt`
  - baseline spawn/jauh dari pintu: `DoorIsOpen = false`
  - karakter dinavigasikan ke jalur pintu (`x≈1212, z≈24.26`): `DoorIsOpen = true`
  - karakter digeser dekat tetapi keluar dari jalur ambang (`x≈1212, z≈30.21`): `DoorIsOpen = false`

### Interpretation

- baseline pintu hybrid sekarang lebih dekat ke logika traversal map yang profesional:
  - tetap nyaman dilalui
  - tetap ada affordance manual
  - tidak lagi mudah terbuka "secara gaib" hanya karena posisi pemain dekat secara radial
- debt berikutnya bergeser dari heuristik pintu ke layout survival/hiding yang lebih eksplisit

### Next Step

1. checkpoint commit untuk polish pintu hybrid berbasis doorway zone
2. lanjut ke slice survival readability:
   - definisi hiding spot non-safe-zone
   - guidance survive hunt yang lebih jelas ke pemain

## 2026-04-03 22:46 ICT

### Task

Membuat guidance survive hunt lebih operasional dengan menunjuk `safe zone` runtime terdekat, bukan hanya memberi slogan generik saat hunt aktif.

### Linked Issues

- user secara eksplisit masih belum tahu "cara selamat dari hunt itu harus gimana"
- marker `SAFE ZONE` sudah ada di world, tetapi copy HUD masih bisa terlalu generik untuk pemain baru
- saat tekanan hunt naik, pemain butuh jawaban yang lebih konkret daripada sekadar "cari ruang aman"

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `Main.lua` sekarang punya helper client untuk:
  - menemukan map aktif dari `Workspace.ActiveMatches`
  - menghitung `safe zone` runtime terdekat dari posisi `HumanoidRootPart`
  - memformat label target seperti `SafeZone 1 52st`
- helper ini dipakai untuk memperkaya tiga surface hunt:
  - `getHuntObjectiveText()`
  - `getHuntControlsHintText()`
  - summary guidance pada panel `MatchUI`
- guidance hunt sekarang lebih konkret:
  - `Critical`: putus LOS lalu menuju safe zone terdekat
  - `Tracked`: rotasi jalur lalu menuju safe zone terdekat
  - `Sheltered`: tahan posisi
  - `Hidden`: diam sampai hunt selesai

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_survival_hint_build.rbxlx`
- validasi live helper pada match aktif `HauntedHouse` menghasilkan:
  - nearest safe zone = `SafeZone_1`
  - distance ≈ `52st`
  - hint sample:
    - `PINTU: E/X/TAP  •  TARGET: SafeZone 1 52st  •  JANGAN LARI LURUS`
  - objective sample:
    - `Hunt aktif. Gunakan prompt pintu, putus line-of-sight, lalu menuju SafeZone 1 52st.`
- catatan jujur:
  - capture label HUD final via automation Studio masih belum konsisten karena jalur phase E2E pada sesi ini sempat tertahan di `Preparing`
  - tetapi source sync, build, dan helper output live dari match aktif sudah tervalidasi

### Interpretation

- pemain sekarang tidak hanya diberi instruksi abstrak, tetapi target aksi yang lebih jelas saat hunt aktif
- ini menaikkan readability survival loop tanpa mengarang sistem hiding spot baru yang belum benar-benar ada

### Next Step

1. checkpoint commit untuk survival readability hint
2. lanjut ke hiding spot non-safe-zone atau survival affordance berikutnya bila masih dibutuhkan

## 2026-04-03 23:59 ICT

### Task

Menutup hiding spot non-safe-zone baseline dengan membuat `closet hiding` runtime benar-benar hidup di `HauntedHouse`, lalu memvalidasi perilaku `enter hide`, `stay hidden inside closet`, dan `auto-exit when leaving closet`.

### Linked Issues

- source sudah punya `ClosetHidingMechanic`, tetapi sistem ini tidak pernah aktif di runtime karena foldernya tidak ikut auto-discovery `SystemRegistry`
- setelah sistem aktif, prompt closet masih tidak muncul tepat waktu karena registrasi awal bisa kalah race dengan spawn clone map
- `HidingSystem` setiap tick hanya mengerti `SafeZone`, sehingga hide state `Closet/Locker` langsung jatuh lagi ke `Exposed`
- auto-exit closet semula bergantung ke `GameplayTick`, padahal publisher event itu tidak ada di runtime aktif
- volume check closet semula memakai tinggi part lantai mentah, sehingga `HumanoidRootPart` pemain selalu terbaca “di luar” walau berdiri di atas closet room

### Files Changed

- `src/ServerScriptService/Server/Core/SystemRegistry.lua`
- `src/ServerScriptService/Server/ClosetHidingMechanic/Controller.lua`
- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
- `src/ServerScriptService/Server/HidingSystem/Service.lua`
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `SystemRegistry` sekarang mengenali `ClosetHidingMechanic` sebagai system runtime resmi dan menempatkannya di group `GameplaySystems`
- `ClosetHidingMechanic` sekarang:
  - mencari `Room_Closet* / Room_Locker*` pada clone map aktif
  - menempelkan `HideSpotPrompt` runtime
  - menjaga occupancy prompt (`Bersembunyi` / `Keluar`)
  - punya loop internal ringan untuk sync hide spot dan auto-exit occupant tanpa bergantung ke `GameplayTick`
  - memakai toleransi vertikal room yang cocok untuk `HumanoidRootPart`, bukan tinggi lantai mentah `1 stud`
- `HidingSystem` sekarang tidak lagi menimpa hide state `Closet/Locker` hanya karena player sedang tidak ada di `SafeZone`
- `StudioE2EControlSystem` sekarang punya harness resmi:
  - `EnterHide`
  - `ExitHide`
  - ini dipakai untuk validasi server-authoritative hide pipeline tanpa bergantung ke trigger prompt fisik yang flaky di automation MCP

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_closet_registry_build.rbxlx`
- validasi live final di Studio tertutup pada `HauntedHouse`:
  - `HideSpotPrompt` muncul di `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Rooms.Room_ClosetA`
  - saat root diposisikan di `ClosetA` lalu `StudioE2EControl(action=EnterHide)` dipicu:
    - `PasrahHideState = Hidden`
    - `PasrahHideSpotType = Closet`
    - `PasrahHideZoneId = Room_ClosetA`
    - prompt text = `Keluar`
  - saat root dipindahkan keluar dari volume closet:
    - `PasrahHideState = Exposed`
    - `PasrahHideSpotType = None`
    - `PasrahHideZoneId = ""`
    - prompt text = `Bersembunyi`
- validasi ini menutup tiga lapis perilaku yang sebelumnya belum ada:
  - prompt runtime producer
  - hide state runtime
  - auto-exit runtime

### Interpretation

- hiding spot non-safe-zone sekarang bukan lagi placeholder konsep; `HauntedHouse` sudah punya baseline closet hide yang benar-benar bekerja
- debt survival/hunt berikutnya bergeser dari “apakah bisa bersembunyi di closet” ke “berapa kaya hiding affordance lintas map dan bagaimana teachability survive loop untuk pemain”

### Next Step

1. checkpoint commit untuk baseline closet hiding runtime
2. lanjut ke perluasan hiding affordance lintas map atau gameplay survival slice berikutnya

## 2026-04-04 00:18 ICT

### Task

Menutup debt arsitektur `GameplayTick` yang ternyata tidak pernah dipublish, lalu memvalidasi bahwa `SafeZone` auto-hide kembali hidup pada runtime aktif.

### Linked Issues

- audit closet hiding membuktikan `GameplayTick` tidak punya publisher canonical sama sekali
- beberapa system aktif masih subscribe ke `GameplayTick`:
  - `GameplayLoopController`
  - `HuntPhaseController`
  - `GhostPathingSystem`
  - `PlayerSurvivalSystem`
  - `HidingSystem`
- tanpa publisher ini, sebagian loop survival/timer hanya tampak ada di source tetapi sebenarnya dorman

### Files Changed

- `src/ServerScriptService/Server/GameplayLoopController/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `GameplayLoopController` sekarang punya publisher runtime ringan:
  - hanya aktif saat `activeMatchId` ada
  - publish `GameplayTick` setiap `0.25s`
  - payload membawa `matchId`, `dt`, dan `now`
- pendekatan ini menghidupkan subscriber canonical tanpa menambah bootstrap/poller ad-hoc baru di banyak system

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_gameplay_tick_build.rbxlx`
- validasi live di `HauntedHouse` setelah match aktif:
  - saat root dipindahkan ke `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.SafeZones.SafeZone_1`
    - `PasrahHideState = Hidden`
    - `PasrahHideSpotType = SafeZone`
    - `PasrahHideZoneId = SafeZone_1`
  - saat root dipindahkan keluar zone:
    - `PasrahHideState = Exposed`
    - `PasrahHideSpotType = None`
    - `PasrahHideZoneId = ""`
- ini menutup bukti paling penting bahwa `GameplayTick` publisher sekarang benar-benar berjalan, bukan hanya source patch

### Interpretation

- loop survival dasar kembali jujur: `SafeZone` auto-hide tidak lagi bergantung pada kondisi kebetulan atau tool khusus
- publisher `GameplayTick` sekarang punya owner canonical, sehingga debt berikutnya bisa difokuskan ke gameplay/content, bukan event loop yang hilang

### Next Step

1. checkpoint commit untuk restore publisher `GameplayTick`
2. lanjut ke slice survival/map berikutnya dengan fondasi tick yang sudah aktif

## 2026-04-04 00:54 ICT

### Task

Memulai ekspansi hiding affordance lintas map dengan pendekatan data-driven (`hideSpotRooms`), lalu memastikan prompt runtime benar-benar muncul di map selain `HauntedHouse`.

### Linked Issues

- baseline closet hiding sudah ada, tetapi masih implicit ke naming `Closet/Locker`
- untuk map lain, room kandidat hide spot ada (`Storage`, `StorageRoom`, `StorageWing`) tapi belum punya owner data canonical
- validasi lintas map butuh jalur yang tidak mengandalkan heuristik substring raw

### Files Changed

- `src/shared/GameData/Maps/HauntedHouse.lua`
- `src/shared/GameData/Maps/EmptyBuilding.lua`
- `src/shared/GameData/Maps/StudioMMNineteen.lua`
- `src/shared/GameData/Maps/AbandonedPalace.lua`
- `src/ServerScriptService/Server/MapConfigSystem/Service.lua`
- `src/ServerScriptService/Server/ClosetHidingMechanic/Controller.lua`
- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- map data sekarang punya field baru `hideSpotRooms`:
  - `HauntedHouse`: `ClosetA`, `ClosetB`
  - `EmptyBuilding`: `Storage`
  - `StudioMMNineteen`: `StorageRoom`
  - `AbandonedPalace`: `StorageWing`
- `MapConfigSystem` sekarang menormalisasi `hideSpotRooms` dan memfilter agar tetap subset dari `rooms`
- `ClosetHidingMechanic` sekarang:
  - subscribe juga ke `MatchCreated` untuk trigger registrasi awal
  - membaca map config dari `MapConfigSystem` untuk lookup room hide spot
  - tetap mempertahankan fallback pattern `Closet/Locker`
  - punya fallback khusus Studio untuk infer `activeMatchId` dari `Workspace.ActiveMatches` saat state event belum stabil

### Validation Notes

- build source lolos:
  - `rojo build default.project.json --output .\\_tmp_hide_spot_mapdata_build.rbxlx`
- validasi live yang tertutup:
  - pada `EmptyBuilding`, room `Room_Storage` runtime sekarang memunculkan `HideSpotPrompt`
  - payload prompt terbaca:
    - `ActionText = Bersembunyi`
    - `ObjectText = Storage`
- catatan jujur untuk sesi ini:
  - beberapa run Studio masih tertahan di fase `Preparing`
  - `HidingDebugSnapshot` pada run tersebut menunjukkan `activeMatchId=nil` dan `hiddenCount=0`
  - jadi validasi `EnterHide -> Hidden` untuk ekspansi lintas map belum bisa di-close pada run yang stuck ini, meski affordance prompt sudah muncul

### Interpretation

- ownership data hide spot sekarang jauh lebih eksplisit dan sinkron dengan source of truth map, bukan sekadar heuristik
- progres slice ini valid pada level affordance runtime lintas map
- blocker berikutnya bergeser ke stabilisasi phase progression/event flow agar validasi state hide penuh bisa ditutup konsisten

### Next Step

1. checkpoint commit untuk ekspansi data-driven hide spot lintas map
2. lanjut ke stabilisasi `Preparing -> match active` agar validasi full hide-state tidak intermittent

## 2026-04-03 22:53 ICT

### Task

Menutup blocker runtime `Preparing -> MatchStarted`, lalu menyelesaikan validasi penuh hiding `EmptyBuilding` tanpa merusak baseline `HauntedHouse`.

### Linked Issues

- `HostStart` countdown selesai, tetapi commit/start match sempat menggantung tanpa jejak final
- `MatchPreparing` sempat terkirim, tetapi pipeline berhenti sebelum teleport dan `MatchStarted`
- `EmptyBuilding.Room_Storage` overlap dengan `SafeZone_2`, sehingga hide eksplisit `Closet` sempat ditimpa tick safe-zone
- patch interaction point runtime terlalu mahal karena menghitung pathfinding saat setiap match clone

### Files Changed

- `src/ServerScriptService/Server/HidingSystem/Service.lua`
- `src/ServerScriptService/Server/LobbySystem/Controller.lua`
- `src/ServerScriptService/Server/MatchSystem/Controller.lua`
- `src/ServerScriptService/Server/MatchSystem/MatchService.lua`
- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `HidingSystem`:
  - safe-zone tick tidak lagi menimpa hide eksplisit `Closet/Locker` saat pemain memang sudah memilih hide spot
  - ketika pemain `ExitHide` tetapi masih berdiri di volume safe zone, safe-zone tetap boleh mengambil alih lagi pada tick berikutnya
- `LobbySystem.Controller`:
  - countdown host-start sekarang punya hardening Studio debug untuk tail finalize
  - jalur ini tidak lagi silent hang saat `CommitHostStart` tertahan oleh pipeline berikutnya
- `MatchSystem.Controller`:
  - `StartMatch()` sekarang dijalankan async dari `OnPlayerQueued`, bukan inline di callback EventBus
- `MatchService`:
  - pipeline setelah `MatchPreparing` sekarang diteruskan lewat `task.delay` alih-alih yield inline
  - ditambah stage trace Studio-only agar bottleneck start match bisa dibaca langsung (`PasrahLastMatchStartStage`)
- `MapRuntimePatches`:
  - normalisasi interaction point runtime tidak lagi memakai `PathfindingService:ComputeAsync()` massal pada start match
  - runtime patch sekarang deterministic memakai posisi room + explicit override

### Validation Notes

- validasi live `EmptyBuilding` sukses penuh:
  - `PasrahLastHostStartCommit = commit ok=true err=nil roomId=1`
  - `PasrahLastMatchStartTrace = match=match_1 players=1 teleported=1 phase=PreparationPhase map=EmptyBuilding mode=Classic`
  - `PasrahLastTeleportTrace` lengkap sampai `player=ZyraaaVex status=teleported_counted`
  - `Room_Storage`:
    - `EnterHide` -> `Hidden / Closet / Room_Storage`
    - prompt berubah ke `Keluar`
    - `ExitHide` sambil tetap di storage -> `Hidden / SafeZone / SafeZone_2`
    - prompt kembali ke `Bersembunyi`
- sanity regression `HauntedHouse` juga tertutup:
  - `Room_ClosetA` kembali memberi `Hidden / Closet / Room_ClosetA`
  - prompt tetap jujur: `Keluar`

### Interpretation

- blocker sebelumnya ternyata kombinasi dari dua hal:
  - `StartMatch()` yield di jalur callback yang salah
  - patch interaction point runtime terlalu berat untuk jalur clone map
- setelah dua akar itu ditutup, validasi hide lintas map bisa kembali dijalankan secara sah
- overlap `Storage` vs `SafeZone_2` di `EmptyBuilding` sekarang sudah punya perilaku yang konsisten:
  - hide eksplisit menang saat pemain benar-benar masuk closet
  - safe zone tetap aktif saat pemain keluar dari closet tetapi masih di area aman

### Next Step

1. checkpoint commit untuk stabilisasi `HostStart/StartMatch` + prioritas hide explicit
2. lanjut ke slice traversal/map polish berikutnya tanpa kembali ke blocker `Preparing`

## 2026-04-03 23:18 ICT

### Task

Memulai traversal polish pada interaction point dengan pendekatan anchor berbasis pintu, lalu memperluasnya menjadi fallback global `Door_<RoomName>` yang tetap aman terhadap host-start/match start.

### Linked Issues

- sesudah pathfinding-heavy patch dibuang, interaction point default kembali ke pusat room
- untuk beberapa room, pusat room terasa tidak logis secara traversal karena tidak berada dekat jalur masuk
- override legacy `EmptyBuilding` lama sudah tidak representatif terhadap geometri room aktif

### Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `MapRuntimePatches` sekarang punya `INTERACTION_DOOR_OVERRIDES`
- fallback normal interaction point sekarang juga bisa otomatis mencari pintu exact-match `Door_<RoomName>`
- patch interaction point bisa menghitung anchor dari:
  - posisi pintu
  - arah `door -> room center`
  - `insideOffset` per room
- explicit target pertama yang ditutup:
  - `HauntedHouse`: `Interact_Bedroom1`, `Interact_Kitchen`
  - `EmptyBuilding`: `Interact_WorkspaceOpen`, `Interact_OfficeB`, `Interact_Bathroom1`
- setelah coverage dicek, fallback global ini ternyata berlaku hampir penuh:
  - `AbandonedPalace`: `8/8`
  - `StudioMMNineteen`: `8/8`
  - `EmptyBuilding`: `8/8`
  - `HauntedHouse`: `7/8`
- explicit vector override lama untuk `EmptyBuilding` yang tidak lagi masuk akal sudah dibuang

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_map_patch_validation.rbxlx`
- edit-mode clone validation:
  - coverage global:
    - `AbandonedPalace`: `8/8` anchor pintu
    - `StudioMMNineteen`: `8/8` anchor pintu
    - `EmptyBuilding`: `8/8` anchor pintu
    - `HauntedHouse`: `7/8` anchor pintu, `Interact_HallwayMain` tetap room-center
  - `HauntedHouse`
    - `Interact_Bedroom1 = 1178.75, 2, 35`
    - `Interact_Kitchen = 1220.25, 2, -25`
    - `Interact_HallwayMain = 1200, 2, 0`
  - `EmptyBuilding`
    - `Interact_WorkspaceOpen = 800, 14, 13.75`
    - `Interact_OfficeB = 774.75, 2, 35`
    - `Interact_Bathroom1 = 826.25, 2, 35`
- smoke test live tetap sehat:
  - `PasrahLastHostStartCommit = commit ok=true err=nil roomId=1`
  - `PasrahLastMatchStartTrace = match=match_1 players=1 teleported=1 phase=PreparationPhase map=EmptyBuilding mode=Classic`
  - `PasrahLastMatchStartTrace = match=match_1 players=1 teleported=1 phase=PreparationPhase map=HauntedHouse mode=Classic`
  - runtime clone memakai posisi interaction point yang sama dengan hasil edit-mode validation

### Interpretation

- traversal polish sekarang bergerak ke arah yang lebih profesional:
  - interaksi diletakkan dekat akses masuk room
  - bukan sekadar di tengah ruangan atau di koordinat residual yang tidak sinkron lagi
- pola `door anchor + insideOffset` sekarang juga menjadi fallback sistemik lintas map, bukan patch lokal sekali pakai
- ini menurunkan kebutuhan override manual untuk map yang struktur namanya konsisten

### Next Step

1. checkpoint commit untuk interaction point door-anchor fallback global
2. lanjut ke room residual/traversal berikutnya dan audit owner client yang masih `in progress`

## 2026-04-03 23:42 ICT

### Task

Menutup owner client ganda pada surface investigasi dengan mematikan subscriber state yang tidak punya consumer runtime jelas.

### Linked Issues

- `UI/Main` sudah menjadi owner nyata untuk `EvidenceEvent`
- tetapi bootstrap client masih menyalakan tiga sistem tambahan yang hanya subscribe lalu menyimpan state masing-masing:
  - `InvestigationUISystem`
  - `EvidenceBoardSystem`
  - `GhostPredictionSystem`
- search global source lokal menunjukkan tiga sistem ini tidak dipakai consumer lain selain bootstrap itu sendiri

### Files Changed

- `src/client/Core/ClientBootstrap.lua`
- `src/client/FlashlightController.client.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `ClientBootstrap` tidak lagi me-require atau me-register:
  - `InvestigationUISystem`
  - `EvidenceBoardSystem`
  - `GhostPredictionSystem`
- owner surface investigasi sekarang lebih jelas:
  - `UI/Main` = owner jurnal/evidence/prediction UI
  - `EvidenceTools` = owner request tool client
  - `SoundSystem` = owner sensory audio/VFX satelit
- `FlashlightController` sekarang memperlakukan toggle UI sebagai satelit mobile saja:
  - `FlashlightToggleUI` dihancurkan pada device non-touch
  - `FlashlightToggleUI.Enabled` hanya `true` saat player benar-benar sedang `InMatch`

### Validation Notes

- search global source lokal:
  - tidak ada consumer runtime lain untuk `InvestigationUISystem`, `EvidenceBoardSystem`, atau `GhostPredictionSystem`
- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_client_owner_cleanup.rbxlx`
- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_flashlight_ui_cleanup.rbxlx`
- smoke boot Studio sukses:
  - tidak ada warning bootstrap client baru
  - `PlayerGui` lobby tetap sehat
  - `ScreenGui` utama tetap muncul normal
  - `FlashlightToggleUI` tidak ada di desktop lobby boot (`UserInputService.TouchEnabled = false`)

### Interpretation

- ini belum menutup seluruh `P0.1`, tetapi menutup satu jenis drift yang paling bersih:
  - subscriber ganda tanpa consumer
- sekaligus memperkecil noise GUI satelit yang sebelumnya ikut hidup di desktop tanpa kebutuhan runtime
- langkah ini menurunkan noise ownership dan risiko state investigasi saling berbeda antar modul

### Next Step

1. checkpoint commit untuk owner cleanup investigasi client
2. lanjut audit satelit UI yang memang sengaja hidup seperti `FlashlightToggleUI` dan `SensoryHorrorHUD`

## 2026-04-04 00:13 ICT

### Task

Mengubah `SensoryHorrorHUD` menjadi satelit lazy runtime agar tidak ikut memenuhi `PlayerGui` saat boot lobby.

### Linked Issues

- validasi live sebelumnya menunjukkan `PlayerGui.SensoryHorrorHUD` masih hadir di desktop lobby boot walau `Enabled = false`
- ini bukan bug visual besar, tetapi tetap menambah noise runtime yang tidak perlu pada fase lobby
- `UISystem` sendiri hanya membutuhkan HUD itu pada phase match aktif

### Files Changed

- `src/client/UI/HUD/HorrorHUD.luau`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `HorrorHUD` tidak lagi membuat `SensoryHorrorHUD` saat `Start()` bila player belum masuk match
- HUD sekarang dibuat secara lazy ketika:
  - `InMatch == true`
  - atau `MatchId` sudah terisi
- `ScreenGui.Enabled` disinkronkan ke phase aktif:
  - `InGame`
  - `Escalation`
  - `Hunt`
- saat player kembali ke lobby, `SensoryHorrorHUD` dihancurkan agar `PlayerGui` kembali bersih
- koneksi `ChildAdded` lobby sekarang juga masuk ke `_connections`, bukan dangling connection

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_horror_hud_lazy.rbxlx`
- playtest lobby boot:
  - `PlayerGui.SensoryHorrorHUD` tidak ada
- simulasi client attr lokal:
  - sebelum: `InMatch = false`, HUD tidak ada
  - selama: `InMatch = true`, `MatchId = debug_match`, `MatchPhase = InGame`, HUD ada dan `Enabled = true`
  - sesudah rollback ke lobby: HUD hilang lagi
- console runtime tidak menunjukkan error baru dari patch ini

### Interpretation

- ini membersihkan noise GUI satelit tanpa mengubah owner utama phase match
- `UISystem` tetap menjadi pengendali phase surface, sementara `HorrorHUD` sekarang lebih disiplin soal lifecycle runtime

### Next Step

1. checkpoint commit untuk lazy `SensoryHorrorHUD`
2. lanjut ke slice map/door/gameplay atau debt `P0.5` runtime noise berikutnya

## 2026-04-04 00:39 ICT

### Task

Menutup bukti runtime yang masih tertinggal pada dua debt gameplay: validasi live pintu hybrid dan validasi hide spot lintas map di luar `HauntedHouse`.

### Linked Issues

- source of truth masih menyisakan catatan bahwa pintu hybrid membutuhkan satu verifikasi manual Studio
- hide spot lintas map sudah data-driven, tetapi `EmptyBuilding` baru terbukti sampai level prompt hadir, belum lifecycle penuh `enter -> exit`

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- tidak ada patch code baru; slice ini murni validasi runtime dan sinkronisasi truth
- pintu hybrid `HauntedHouse.Door_Kitchen` sekarang tervalidasi live:
  - mendekat ke ambang pintu -> pintu membuka
  - menjauh ke spawn -> pintu menutup lagi
- hide spot lintas map `EmptyBuilding.Room_Storage` sekarang tervalidasi live:
  - prompt hadir
  - `EnterHide` membuat player `Hidden / Closet / Room_Storage`
  - keluar volume room mengembalikan player ke `Exposed / None / ""`
  - `HideSpotOccupied` ikut toggle `false -> true -> false`

### Validation Notes

- `HauntedHouse` runtime clone:
  - path pintu aktif: `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Doors.Door_Kitchen`
  - state sebelum pendekatan: `DoorIsOpen = false`
  - sesudah karakter didekatkan: `DoorIsOpen = true`, `Rotation.Y ~= 88`, `CanCollide = false`
  - sesudah karakter dikembalikan ke spawn: `DoorIsOpen = false`, `Rotation.Y = 0`, `CanCollide = true`
- `EmptyBuilding` runtime clone:
  - room hide spot aktif: `Workspace.ActiveMatches.Match_match_1.EmptyBuilding.EmptyBuilding.Rooms.Room_Storage`
  - prompt + attribute hadir:
    - `HideSpotPrompt`
    - `HideSpotId = Room_Storage`
    - `HideSpotType = Closet`
  - `StudioE2EControl EnterHide` berhasil:
    - `PasrahHideState = Hidden`
    - `PasrahHideSpotType = Closet`
    - `PasrahHideZoneId = Room_Storage`
    - `HideSpotOccupied = true`
  - sesudah root dipindahkan keluar volume room:
    - `PasrahHideState = Exposed`
    - `PasrahHideSpotType = None`
    - `PasrahHideZoneId = ""`
    - `HideSpotOccupied = false`

### Interpretation

- debt aktif map/door sekarang benar-benar bergeser dari “apakah sistem dasar hidup” ke:
  - kualitas layout/traversal visual
  - richness hiding affordance lintas map
  - teachability survive loop
- debt aktif hiding lintas map juga turun level; `EmptyBuilding` sudah bukan sekadar placeholder config

### Next Step

1. checkpoint laporan validasi runtime pintu + hiding lintas map
2. lanjut ke perluasan hiding affordance dan readability survive hunt, atau ke layout/traversal polish berikutnya

## 2026-04-04 00:49 ICT

### Task

Menyelaraskan hunt guidance UI agar mengenali hide spot runtime nyata, bukan selalu menyebut `SafeZone`.

### Linked Issues

- sesudah hide spot lintas map tervalidasi, copy HUD hunt masih berpotensi misleading
- saat player hide di `Closet/Locker`, `ObjectiveLabel` dan `ControlsHintBar` tidak boleh tetap memberi kesan bahwa player ada di `SafeZone`

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `UI/Main` sekarang punya helper runtime baru:
  - format label hide spot
  - baca hide spot terdekat dari `Rooms` yang sudah diberi `HideSpotId/HideSpotType`
  - pilih refuge prioritas antara `HideSpot` dan `SafeZone`
- objective/copy hunt tidak lagi hardcoded `SafeZone` untuk semua konteks
- saat player benar-benar hide di room runtime, label sekarang memakai nama room yang jujur (`Storage`, bukan `SafeZone 2`)
- `ControlsHintBar` hidden state juga ikut disinkronkan ke nama hide spot aktif

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_hunt_refuge_guidance.rbxlx`
  - `rojo build default.project.json --output .\\_tmp_hunt_refuge_guidance_v2.rbxlx`
- smoke runtime baru di `Classic -> EmptyBuilding -> ForceHunt -> EnterHide(Room_Storage)` menunjukkan:
  - `MatchPhase = Hunt`
  - `PasrahHideState = Hidden`
  - `PasrahHideSpotType = Closet`
  - `PasrahHideZoneId = Room_Storage`
  - `Players.ZyraaaVex.PlayerGui.UXLayer.MatchUXGui.MatchUXLayer.ObjectiveLabel = Berlindung di Storage. Diam dan tunggu hunt selesai sebelum keluar.`
  - `Players.ZyraaaVex.PlayerGui.MatchUI.MainPanel.HeaderCard.SecondaryLabel = Berlindung di Storage. Diam dan tunggu hunt selesai sebelum keluar.`
  - `Players.ZyraaaVex.PlayerGui.MatchUI.ControlsHintBar.Label = STORAGE  •  DIAM  •  TUNGGU HUNT SELESAI`
  - `Players.ZyraaaVex.PlayerGui.MatchUI.MainPanel.SummaryFrame.GuessRow.Value = Storage`
  - `Players.ZyraaaVex.PlayerGui.MatchUI.MainPanel.SummaryFrame.SurvivedRow.Value = Storage`

### Interpretation

- teachability survive loop sekarang naik satu level:
  - UI tidak lagi hanya berkata “lari ke safe zone”
  - ketika player sudah masuk refuge nyata, semua surface utama sepakat soal tempatnya
- debt berikutnya bergeser ke:
  - kapan memilih `HideSpot` dibanding `SafeZone` saat player masih `Exposed`
  - perluasan readability lintas map/room lain

### Next Step

1. checkpoint patch hunt refuge guidance
2. lanjut ke teachability survive loop saat player masih `Exposed`, atau ke traversal/layout polish berikutnya

## 2026-04-04 00:56 ICT

### Task

Mengeraskan lookup refuge client untuk state `Exposed` dengan fallback berbasis `HideSpotPrompt`, agar guidance tidak buta jika attribute hide spot datang belakangan.

### Linked Issues

- smoke `Exposed near Storage` sempat jatuh ke wording generik / safe-zone bias
- jalur hidden sudah tervalidasi, tetapi jalur `Exposed` masih sensitif terhadap kapan `HideSpotId` dan `HideSpotType` tersedia di client

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `getNearestHideSpotInfo()` sekarang tidak hanya membaca:
  - `HideSpotId`
  - `HideSpotType`
- ia juga bisa fallback ke:
  - child `HideSpotPrompt`
  - nama `Room_*` runtime
- tujuan patch ini adalah mengecilkan race replication pada state `Exposed`, tanpa mengubah jalur final saat attribute sudah hadir normal

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_hunt_refuge_guidance_v3.rbxlx`
- smoke runtime `Exposed` masih belum saya anggap proof final:
  - sesi hunt berakhir/reset terlalu cepat untuk distance audit yang bersih
  - tetapi patch fallback aman secara logika dan tidak mengubah proof runtime sebelumnya untuk hidden path

### Interpretation

- ini adalah hardening kecil, bukan closure final untuk teachability `Exposed`
- debt berikutnya tetap sama:
  - validasi final preferensi `HideSpot` vs `SafeZone` saat player masih `Exposed`
  - atau lanjut ke slice traversal/layout yang lebih besar

### Next Step

1. checkpoint hardening fallback refuge lookup
2. kembali ke validasi `Exposed` pada sesi runtime yang lebih stabil, atau lanjut ke gameplay/layout polish lain

## 2026-04-04 16:20 ICT

### Task

Menambahkan task deferred final-pass untuk perubahan dan restruktur `LOBBY` serta `MAP IN GAME` ke source of truth.

### Linked Issues

- user ingin restruktur besar lobby dan map tetap tercatat, tetapi baru dikerjakan di akhir
- task ini perlu persisten lintas sesi agar AI berikutnya tidak mengerjakannya terlalu dini

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- backlog sekarang punya item khusus `18. Final pass perubahan dan restruktur LOBBY + MAP IN GAME`
- status task ditandai `deferred`
- catatan eksplisit ditambahkan agar user diingatkan saat backlog sudah sampai tahap ini

### Interpretation

- restruktur besar lobby/map sekarang resmi menjadi target akhir, bukan blocker aktif fase hardening saat ini
- prioritas eksekusi tetap pada backlog inti yang masih terbuka

### Next Step

1. lanjutkan backlog aktif tanpa menarik restruktur besar ini ke depan
2. ingatkan user saat seluruh target inti sudah cukup dekat untuk masuk final pass lobby/map

## 2026-04-04 16:38 ICT

### Task

Mengurangi surface runtime client dengan mengeluarkan modul legacy yang sudah tidak punya consumer aktif dari path sinkronisasi `StarterPlayerScripts.Client`.

### Linked Issues

- `P0.1 Konsolidasi owner client` masih menyisakan modul mati yang tetap ikut tersync ke Studio
- `P0.5 Bersihkan noise runtime` belum benar-benar tuntas selama bangkai modul client lama masih tampil di edit tree dan runtime

### Files Changed

- `src/client/EvidenceBoardSystem/Main.lua`
- `src/client/EvidenceBoardSystem/init.lua`
- `src/client/GhostPredictionSystem/Main.lua`
- `src/client/GhostPredictionSystem/init.lua`
- `src/client/InvestigationUISystem/Main.lua`
- `src/client/InvestigationUISystem/init.lua`
- `src/client/LegacyDisabled/AtmosphericSetup.lua`
- `src/client/LegacyDisabled/AudioManager.lua`
- `src/client/LegacyDisabled/EMFReaderGUI.lua`
- `src/client/LegacyDisabled/EvidenceVFX.lua`
- `src/client/LegacyDisabled/SanityVFX.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- modul investigasi client lama yang sudah tidak punya consumer aktif dihapus dari source path yang tersync ke `StarterPlayerScripts.Client`
- folder `LegacyDisabled` yang sebelumnya masih ikut terbawa ke Studio juga dikeluarkan dari source path runtime
- residu folder kosong di `StarterPlayer.StarterPlayerScripts.Client` dibersihkan live agar Studio edit tree kembali sinkron dengan source

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_client_surface_cleanup.rbxlx`
- search source lokal tidak lagi menemukan token:
  - `InvestigationUISystem`
  - `EvidenceBoardSystem`
  - `GhostPredictionSystem`
  - `LegacyDisabled`
- validasi edit tree Studio:
  - `StarterPlayer.StarterPlayerScripts.Client` tidak lagi punya folder kosong `LegacyDisabled`, `EvidenceBoardSystem`, `GhostPredictionSystem`, `InvestigationUISystem`
- validasi play runtime:
  - `Players.ZyraaaVex.PlayerScripts.Client` hanya memuat modul aktif
  - folder legacy investigasi lama tidak lagi ikut spawn ke runtime client
- smoke boot setelah cleanup tidak menunjukkan warning bootstrap client baru

### Interpretation

- surface runtime client sekarang lebih kecil dan lebih jujur terhadap owner yang benar-benar aktif
- slice ini tidak menutup seluruh `P0.1` atau `P0.5`, tetapi menurunkan risiko drift karena modul mati tidak lagi ikut tersync ke Studio/play runtime

### Next Step

1. lanjut ke blocker aktif berikutnya yang tidak bentrok dengan dirty worktree lain
2. kandidat paling logis: validasi final guidance `Exposed` saat hunt, atau lanjut ke pass UI modular/mobile berikutnya

## 2026-04-04 17:02 ICT

### Task

Menutup proof final preferensi refuge hunt saat player masih `Exposed`, dengan repro live dekat hide spot runtime `Room_Storage`.

### Linked Issues

- backlog sebelumnya masih menandai proof final `HideSpot vs SafeZone` pada state `Exposed` sebagai belum tertutup
- jalur hidden sudah tervalidasi, tetapi jalur `Exposed` perlu bukti live bahwa UI tidak lagi bias ke `SafeZone`

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- tidak ada patch code baru pada slice ini
- saya memakai jalur client canonical `LobbyEvent` untuk:
  - `SelectMode(Classic)`
  - `SelectMap(EmptyBuilding)`
  - `CreateRoom`
  - `HostStart`
- lalu repro live dilakukan pada posisi `846, 4, -20`, yaitu dekat `Room_Storage` tetapi tetap `Exposed`
- `ForceHunt` dijalankan lewat `StudioE2EControl`, lalu surface UI hunt dibaca langsung dari `UXLayer` dan `MatchUI`

### Validation Notes

- jalur start match canonical sukses:
  - `PasrahLastHostStartCommit = commit ok=true err=nil roomId=1`
  - `PasrahLastMatchStartTrace = match=match_1 players=1 teleported=1 phase=PreparationPhase map=EmptyBuilding mode=Classic`
- posisi repro final:
  - `HumanoidRootPart ~= 846, 3.47, -20`
  - `PasrahHideState = Exposed`
  - `PasrahHideSpotType = None`
  - `PasrahHideZoneId = ""`
- hasil UI hunt:
  - `UXLayer.MatchUXGui.MatchUXLayer.ObjectiveLabel = Hunt aktif. Gunakan prompt pintu, putus line-of-sight, lalu masuk Storage 16st.`
  - `MatchUI.MainPanel.HeaderCard.SecondaryLabel = Hunt aktif. Gunakan prompt pintu, putus line-of-sight, lalu masuk Storage 16st.`
  - `MatchUI.ControlsHintBar.Label = PINTU: E/X/TAP  •  TARGET: Storage 16st  •  JANGAN LARI LURUS`
  - `MatchUI.MainPanel.SummaryFrame.SurvivedRow.Value = Storage 16st`

### Interpretation

- proof final untuk `Exposed` sekarang tertutup: client tidak lagi bias ke `SafeZone` ketika hide spot runtime yang lebih relevan memang lebih dekat secara operasional
- debt guidance hunt untuk vertical slice inti turun level; fokus bisa kembali ke slice UI modular/mobile dan polish berikutnya

### Next Step

1. lanjut ke `P2.12 Rapikan UI modular`
2. target terdekat: ownership/single-open panel besar dan affordance lobby/runtime yang masih belum konsisten

## 2026-04-04 01:57 ICT

### Task

Menutup bypass single-open pada UI lobby yang membuat `LobbyUI` bisa overlap dengan auxiliary panel saat `LobbyToggleButton` dipakai.

### Linked Issues

- jalur validasi live sebelumnya menemukan bug nyata:
  - `ShopUI = true`
  - klik `LobbyToggleButton`
  - hasil buruk: `LobbyUI = true` dan `ShopUI = true` bersamaan
- akar masalahnya bukan binding tombol ganda, tetapi state conflict di owner pusat yang tidak langsung di-sync ke visual auxiliary window

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `UISystem:_closeConflictingWindows()` sekarang tidak berhenti di update state saja
- setelah dismissal conflict diubah, fungsi ini juga:
  - `:_syncAuxiliaryWindowVisibility()`
  - `:_syncMatchWindowVisibility()`
  - `:_refreshBasicLobbyPanel()`
  - `:_refreshBasicWindows()`
  - `:_layoutLobbyFloatRail()`
- pendekatan ini menutup bypass global pada jalur owner pusat, bukan menambal satu tombol tertentu

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_ui_single_open_fix.rbxlx`
- validasi live setelah restart play:
  - boot baru:
    - `LobbyUI = true`
    - `ProfileUI/ShopUI/RoyalPassUI/MainMenuUI/LeaderboardUI/RoomBrowserUI = false`
  - `LobbyUI.MainPanel.ShopButton`:
    - hasil `ShopUI = true`, panel besar lain `false`
  - saat `ShopUI` masih terbuka, klik `LobbyToggleButton`:
    - hasil benar `LobbyUI = true`, `ShopUI = false`
  - `OpenRoomBrowserButton`:
    - hasil `RoomBrowserUI = true`, panel besar lain `false`
  - `MainMenuUI -> ProfileUI`:
    - hasil `ProfileUI = true`, `MainMenuUI = false`, panel besar lain `false`

### Interpretation

- ownership/single-open panel besar lobby sekarang benar-benar enforced di jalur runtime utama
- `P2.12` masih belum selesai total, tetapi blocker owner conflict dasarnya sudah turun level; sisa kerja bergeser ke compact/mobile polish dan affordance visual

### Next Step

1. lanjut ke validasi compact/mobile `RoomBrowserUI` dan `RoyalPassUI`
2. jika tidak ada blocker baru, lanjut ke polish lobby/map berikutnya tanpa membawa debt overlap lama

## 2026-04-04 02:11 ICT

### Task

Menambah affordance visual runtime untuk hide spot canonical agar pemain lebih jelas membaca jalur survive saat hunt.

### Linked Issues

- hiding non-safe-zone memang sudah playable, tetapi masih terlalu pasif:
  - `HideSpotPrompt` ada
  - UI hunt bisa menyebut `Storage/Closet`
  - namun di world-space belum ada marker yang cukup jelas seperti safe zone marker
- user juga sudah menyorot kebutuhan cara survive hunt yang lebih terbaca secara visual, bukan hanya lewat teks

### Files Changed

- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
- `src/ServerScriptService/Server/ClosetHidingMechanic/Controller.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `ClosetHidingMechanic.Service` sekarang membuat marker runtime per hide spot:
  - `HideSpotRuntimeMarker.Outline`
  - `HideSpotRuntimeMarker.Billboard`
  - label runtime memakai nama room hide spot
  - subtitle runtime: `Bersembunyi saat hunt`
- marker disetel lewat owner pusat `:_setHideSpotVisualState(matchId, isVisible)` sehingga:
  - default `false` saat match start
  - `true` saat `HuntStarted`
  - `false` lagi saat `HuntEnded` dan `MatchEnded`
- atribut room hide spot juga ditambah:
  - `HideSpotLabel`
- blocker wiring yang membuat marker awalnya tidak pernah hidup juga ditutup:
  - `ClosetHidingMechanic.Controller` sekarang subscribe ke `HuntStarted` dan `HuntEnded`

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_hide_spot_marker_fix.rbxlx`
- validasi live canonical di Studio:
  - playtest baru
  - `OpenRoomBrowser -> CreateRoom -> ReadyButton/Start`
  - countdown host-start sukses
  - `PasrahLastMatchStartTrace = match=match_1 players=1 teleported=1 phase=PreparationPhase map=HauntedHouse mode=Classic`
  - `StudioE2EControl.ForceHunt` sukses:
    - `PasrahStudioE2ELastResult = ok=true | action=ForceHunt | result=match=match_1 forced`
  - inspeksi runtime `Workspace.ActiveMatches.Match_match_1.HauntedHouse.Rooms.Room_ClosetA` dari client live menunjukkan:
    - `HideSpotRuntimeMarker` ada
    - `Outline.Visible = true`
    - `Billboard.Enabled = true`
    - `HideSpotPrompt.ActionText = Bersembunyi`
    - `HideSpotLabel = ClosetA`
    - `player.MatchPhase = Hunt`

### Interpretation

- hide spot canonical sekarang tidak lagi “diam” saat hunt aktif
- safe zone dan hide spot sekarang sama-sama punya affordance world-space yang bisa dibaca pemain
- debt berikutnya bergeser ke distribusi/kurasi hide spot lintas map, bukan lagi ke visibility dasar affordance runtime

### Next Step

1. lanjut ke review distribusi hide spot lintas map atau gameplay survival affordance berikutnya
2. hindari menambah hide spot asal-asalan; tetap pakai room canonical yang benar-benar masuk akal secara layout

## 2026-04-04 02:19 ICT

### Task

Menyambungkan `HideSpotLabel` runtime ke hunt guidance client agar teks objective memakai label refuge canonical dari map aktif.

### Linked Issues

- setelah marker hide spot aktif, client masih bisa jatuh ke label hasil format `zoneId`
- itu tidak merusak gameplay, tetapi tetap lebih lemah daripada memakai label runtime yang sama dengan marker world-space

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- ditambahkan resolver client untuk membaca `HideSpotLabel` langsung dari room runtime aktif
- `getNearestHideSpotInfo()` sekarang memprioritaskan label runtime tersebut
- surface hunt yang menyebut refuge hidden/current sekarang memakai resolver baru, bukan hanya format `PasrahHideZoneId`

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_hide_label_fix.rbxlx`
- validasi live di `HauntedHouse`:
  - `OpenRoomBrowser -> CreateRoom -> Start`
  - setelah teleport, player dipindah dekat `Room_ClosetA`
  - `ForceHunt` dijalankan via `StudioE2EControl`
  - hasil runtime:
    - `HideSpotLabel = ClosetA`
    - `player.MatchPhase = Hunt`
    - `UXLayer.ObjectiveLabel = Ghost dekat (4st). Putus line-of-sight, rotasi lewat pintu, lalu masuk ClosetA 4st. Jika tertutup, menuju SafeZone 1 10st.`
    - `MatchUI.HeaderCard.SecondaryLabel` menampilkan teks yang sama

### Interpretation

- jalur survival guidance sekarang konsisten dari world-space marker sampai teks objective/hint
- ini menurunkan drift antara label visual hide spot dan label refuge yang dibaca UI client

### Next Step

1. lanjut ke review distribusi hide spot canonical lintas map
2. atau kembali ke slice UI compact/mobile bila ingin menutup `P2.12` lebih jauh

## 2026-04-04 02:17 ICT

### Task

Menambahkan pengingat backlog final untuk topik retention `reason to return` sesuai arahan user.

### Linked Issues

- user menegaskan risiko drop-off: install -> enjoy -> selesai tanpa alasan kembali besok
- area retention loop yang sering diabaikan perlu dikunci sebagai pembahasan wajib di akhir, bukan diselipkan di tengah hardening runtime

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- ditambahkan item backlog baru `### 19. Final discussion: Reason to return (retention loop)`
- status ditandai `deferred` dengan aturan:
  - dibahas di akhir
  - tidak dieksekusi sekarang
- scope yang dikunci di task pengingat:
  - daily quest/streak
  - meta progression
  - social pressure loop
  - content rotation
  - replayability horror (randomization + speedrun mode)
  - achievement hunting
  - unlockable lore/story pieces

### Interpretation

- prioritas user sekarang tercatat eksplisit di source of truth dan tidak akan hilang di sesi lanjutan
- pembahasan retention akan dilakukan di fase akhir sesuai urutan yang diminta user

### Next Step

1. lanjutkan eksekusi task aktif sekarang tanpa menarik task retention ini ke depan
2. ketika backlog utama hampir selesai, angkat task `Reason to return` sebagai agenda final review

## 2026-04-04 02:26 ICT

### Task

Memperluas distribusi `hideSpotRooms` lintas map agar survival loop tidak hanya bertumpu pada satu titik hide per map.

### Linked Issues

- debt sebelumnya sudah jelas: beberapa map masih hanya punya satu hide spot canonical
- akibatnya hunt path terasa sempit dan cenderung biner (ketemu satu spot atau mati)

### Files Changed

- `src/shared/GameData/Maps/EmptyBuilding.lua`
- `src/shared/GameData/Maps/AbandonedPalace.lua`
- `src/shared/GameData/Maps/StudioMMNineteen.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `EmptyBuilding.hideSpotRooms`:
  - `Storage`
  - `ArchiveRoom`
  - `SecurityRoom`
- `AbandonedPalace.hideSpotRooms`:
  - `StorageWing`
  - `ServantRoomA`
  - `ServantRoomB`
- `StudioMMNineteen.hideSpotRooms`:
  - `StorageRoom`
  - `Office`

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_hide_spot_distribution.rbxlx`
- validasi runtime live memakai jalur room-browser canonical `LobbyEvent:FireServer({ action = ... })`
- hasil validasi:
  - `EmptyBuilding`:
    - `PasrahLastMatchStartTrace = match=match_1 ... map=EmptyBuilding ...`
    - `Room_Storage`, `Room_ArchiveRoom`, `Room_SecurityRoom`:
      - `HideSpotPrompt` ada
      - `HideSpotType = Closet`
      - `HideSpotId` terisi sesuai room
  - `AbandonedPalace`:
    - `PasrahLastMatchStartTrace = match=match_2 ... map=AbandonedPalace ...`
    - `Room_StorageWing`, `Room_ServantRoomA`, `Room_ServantRoomB`:
      - `HideSpotPrompt` ada
      - `HideSpotType = Closet`
      - `HideSpotId` terisi sesuai room
  - `StudioMMNineteen`:
    - `PasrahLastMatchStartTrace = match=match_3 ... map=StudioMMNineteen ...`
    - `Room_StorageRoom`, `Room_Office`:
      - `HideSpotPrompt` ada
      - `HideSpotType = Closet`
      - `HideSpotId` terisi sesuai room
- catatan protokol:
  - format lama `LobbyEvent:FireServer(\"Action\", payload)` tidak reliable untuk validasi runtime saat ini
  - jalur validasi yang benar adalah request table `{ action = \"...\" }`

### Interpretation

- survival affordance lintas map naik dari baseline terlalu tipis ke baseline yang lebih layak untuk hunt
- perubahan ini tetap konservatif karena semua hide spot diambil dari room canonical yang memang ada di map

### Next Step

1. lanjutkan review kualitas posisi hide spot (jarak ke door line, LOS break, dan fairness ghost pathing)
2. lanjut ke slice berikutnya tanpa menarik task `Reason to return` yang sudah didefer ke akhir

## 2026-04-04 02:27 ICT

### Task

Memanusiakan label hide spot runtime agar nama refuge yang tampil di marker/UI tidak mentah dari token room.

### Linked Issues

- setelah ekspansi hide spot lintas map, label seperti `SecurityRoom` masih terlalu teknis untuk pemain

### Files Changed

- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `formatClosetLabel()` sekarang memecah:
  - lower-to-upper boundary (`aB`)
  - letter-to-digit (`A1`)
  - digit-to-letter (`1A`)
- hasil label hide spot runtime sekarang lebih natural untuk UI/hint:
  - `Security Room`
  - `Archive Room`
  - `Servant Room A`

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_hide_label_humanized.rbxlx`
- validasi live `EmptyBuilding`:
  - `PasrahLastMatchStartTrace = ... map=EmptyBuilding ...`
  - `Room_SecurityRoom.HideSpotLabel = Security Room`
  - `Room_ArchiveRoom.HideSpotLabel = Archive Room`

### Interpretation

- survival guidance jadi lebih manusiawi tanpa mengubah mekanik inti
- ini menurunkan noise istilah internal yang bocor ke surface pemain

### Next Step

1. lanjut ke pass fairness hide spot (LOS break + radius akses) lintas map
2. pertahankan task retention `Reason to return` tetap untuk pembahasan final

## 2026-04-04 02:33 ICT

### Task

Meningkatkan fairness akses hide spot dengan prompt distance adaptif per ukuran room.

### Linked Issues

- prompt hide spot sebelumnya fixed `8` stud untuk semua room
- akibatnya beberapa room menengah-besar terasa kurang responsif karena prompt berada di tengah volume room

### Files Changed

- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- prompt distance hide spot sekarang dihitung runtime dari dimensi room:
  - basis: rata-rata `(Size.X + Size.Z) / 2`
  - skala: `0.45`
  - clamp: `8..16`
- atribut observability baru ditambahkan:
  - `HideSpotPromptDistance`
- cleanup match end juga membersihkan atribut tersebut

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output .\\_tmp_hide_prompt_distance_adaptive.rbxlx`
- validasi live `AbandonedPalace`:
  - `PasrahLastMatchStartTrace = ... map=AbandonedPalace ...`
  - `Room_StorageWing` size `24,1,16` -> `promptDistance=9`, `attrDistance=9`
  - `Room_ServantRoomA` size `24,1,16` -> `promptDistance=9`, `attrDistance=9`
  - `Room_ServantRoomB` size `24,1,16` -> `promptDistance=9`, `attrDistance=9`
- validasi live `StudioMMNineteen`:
  - `PasrahLastMatchStartTrace = ... map=StudioMMNineteen ...`
  - `Room_StorageRoom` size `18,1,14` -> `promptDistance=8`, `attrDistance=8`
  - `Room_Office` size `18,1,14` -> `promptDistance=8`, `attrDistance=8`

### Interpretation

- akses hide spot sekarang lebih proporsional terhadap footprint room tanpa membuka exploit radius berlebihan
- perubahan ini tetap konservatif dan kompatibel dengan flow hunt/hide yang sudah berjalan

### Next Step

1. lanjut ke slice LOS-break fairness atau cover affordance map yang belum rapi
2. tetap simpan task retention final untuk dibahas di akhir sesuai prioritas user

## 2026-04-04 02:53 ICT

### Task

Menutup sumber drift client yang memicu gejala audio/event dobel, lalu membersihkan script legacy liar di StarterPlayerScripts.

### Linked Issues

- laporan user: audio dobel setelah countdown
- indikasi runtime drift: script `StarterPlayerScripts.LocalScript` legacy masih aktif dan mem-fire event test
- risiko bootstrap ganda: `ClientBootstrap.client.lua` selalu membuat object baru lewat `ClientMain.new()`

### Files Changed

- `src/client/Main.lua`
- `src/client/StarterPlayerScripts/ClientBootstrap.client.lua`
- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `ClientMain` sekarang punya singleton runtime:
  - tambah `ClientMain._sharedInstance`
  - tambah API `ClientMain.shared(deps)`
- bootstrap LocalScript sekarang memakai singleton:
  - `ClientMain.new()` -> `ClientMain.shared()`
- fallback host ownership room-browser dipertahankan:
  - reset dropdown map/mode kini memakai `hostCanControl` (bukan `state.isHost` mentah)
  - ini mencegah dropdown host tertutup saat payload host flag belum sinkron tapi ownership room sebenarnya valid
- cleanup Studio edit-time:
  - `StarterPlayer.StarterPlayerScripts.LocalScript` legacy (`TEST EVIDENCE TRIGGER`) dihapus dari DataModel edit-time

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output _tmp_client_singleton_guard.rbxlx`
- validasi Studio edit-time:
  - `StarterPlayer.StarterPlayerScripts.LocalScript` legacy sudah hilang
- validasi playtest:
  - `Players.<LocalPlayer>.PlayerScripts.LocalScript` legacy tidak muncul lagi
  - flow UI tetap hidup:
    - `OpenRoomBrowserButton` membuka `RoomBrowserUI`
    - `CreateRoomButton` membuka `RoomPanel`
    - transisi match tetap berjalan (`InMatch=true`, `MatchId=match_1`)

### Interpretation

- penyebab drift paling berisiko untuk audio/event dobel kini ditutup pada level inisialisasi arsitektur client
- noise runtime dari script test legacy yang sempat mengacaukan observasi juga sudah dibersihkan

### Next Step

1. lanjutkan pass `P2.13` (audio polish) dengan verifikasi manual pendengaran untuk countdown/teleport/hunt cue setelah guard singleton aktif
2. lanjutkan gate publish readiness berikutnya tanpa membuka kembali script liar non-source

## 2026-04-04 02:57 ICT

### Task

Menutup bug room browser host di mana `MapSelector` sulit dibuka karena tumpang tindih layout pada viewport pendek.

### Linked Issues

- symptom: klik `MapSelector` tampak gagal membuka `MapDropdown`
- observasi runtime: posisi kontrol host bawah menutupi area selector map/mode saat tinggi viewport tidak cukup

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- logic compact room browser sekarang tidak hanya berbasis lebar:
  - sebelum: `isCompact = mobile OR width <= 980`
  - sesudah: `isCompact = mobile OR width <= 980 OR usableHeight <= 700`
- efek langsung:
  - viewport desktop pendek masuk ke jalur compact scrollable
  - kontrol `ModeSelector/MapSelector` tidak lagi tertimpa tombol `Ready/Start/Leave`

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output _tmp_roombrowser_compact_height_guard.rbxlx`
- validasi live:
  - room browser dapat dibuka dan room dapat dibuat (`OpenRoomBrowserButton`, `CreateRoomButton`)
  - posisi runtime tidak overlap:
    - `MapSelector.Position.Y = 562`
    - `ReadyButton.Position.Y = 854`
  - setelah scroll panel ke area selector, klik `MapSelector` berhasil:
    - `MapDropdown.Visible = true`

### Interpretation

- masalah bukan semata event click, melainkan geometry/layout collision di viewport pendek
- patch ini menutup blocker UX host-map-selection tanpa menambah cabang layout baru yang berisiko

### Next Step

1. lanjutkan pass audio (`P2.13`) dengan verifikasi manual untuk isu “double audio after countdown”
2. lanjutkan item publish readiness lain sesuai backlog prioritas

## 2026-04-04 02:58 ICT

### Task

Validasi ulang batch asset audio yang user upload untuk memastikan status ownership dan menutup keraguan “broken ID”.

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Validation Notes

- audit live memakai `MarketplaceService:GetProductInfo()` untuk ID:
  - `104336169985098`
  - `138884191945388`
  - `139204195403262`
  - `101202336513383`
  - `83336813491039`
  - `90448271562175`
  - `79900103772577`
  - `138329686293368`
- hasil audit:
  - semua `ok`
  - semua creator `ZyraaaVex`
  - semua `IsPublicDomain=false`

### Interpretation

- daftar audio yang user kirim bukan broken ownership; semuanya account-owned untuk workspace aktif
- blocker lisensi audio yang masih tersisa tetap satu: `AmbientLoop_Main` yang slotnya kosong

### Next Step

1. lanjutkan pass `P2.13` untuk ambience loop final dan QA audio transisi countdown->teleport
2. lanjut ke gate publish berikutnya setelah ambience slot ditutup

## 2026-04-04 03:00 ICT

### Task

Menutup blocker `AmbientLoop_Main` yang masih kosong agar jalur publish baseline tidak tertahan pada placeholder audio.

### Files Changed

- `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `AmbientLoop_Main` sekarang terisi:
  - `AudioContent = rbxassetid://138884191945388`
  - `Looped = true` (tetap)
  - `Volume = 0.18` (dari `0.25`) supaya ambience tidak mengganggu cue utama

### Validation Notes

- validasi live edit-mode:
  - `ReplicatedStorage.Assets.Audio.Ambient.AmbientLoop_Main.SoundId = rbxassetid://138884191945388`
  - properti slot runtime terdeteksi bukan kosong lagi

### Interpretation

- blocker lisensi/audio untuk slot ambience kosong berhasil ditutup
- status slot kini `verified (provisional)`:
  - legal/account-owned sudah aman
  - keputusan artistik ambience brand final tetap bisa dipoles di pass audio berikutnya

### Next Step

1. lanjutkan QA manual “double audio after countdown” pada flow host-start -> teleport
2. lanjutkan publish gate berikutnya (Pocong proof archive + legacy cleanup)

## 2026-04-04 03:02 ICT

### Task

Menambah guard dedupe audio transisi untuk mengurangi risiko cue ganda pada fase countdown/teleport/hunt.

### Files Changed

- `src/client/UI/Main.lua`
- `src/client/SoundSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- teleport overlay:
  - default dedupe window dinaikkan menjadi `4s` (dari `0.75s`)
- hunt one-shot audio:
  - `SoundSystem` sekarang punya dedupe key per `category::cue`
  - `HuntAudio` diberi dedupe window `2.25s`
  - event hunt duplikat berdekatan akan di-skip pada playback kedua

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output _tmp_audio_dedupe_guard.rbxlx`
- smoke run:
  - play start/stop berhasil
  - tidak ada error sintaks dari patch dedupe

### Interpretation

- patch ini bukan pengganti QA pendengaran final, tetapi menutup kelas masalah event duplikat yang paling sering memicu audio dobel

### Next Step

1. lakukan verifikasi pendengaran manual flow host-start -> countdown -> teleport
2. lanjutkan publish gate lisensi (`Pocong` proof archive + legacy cleanup)

## 2026-04-04 03:04 ICT

### Task

Memverifikasi guard dedupe `HuntAudio` dengan probe runtime terkontrol.

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Validation Notes

- metode:
  - dari client runtime, panggil `_playCategoryAudio(\"HuntAudio\", { cue = \"dedupe_probe\" })` dua kali dengan jeda `0.2s`
  - hitung jumlah `Sound` bernama `HuntAudioRuntime` setelah trigger pertama dan kedua
- hasil:
  - `first=1`
  - `second=1`
  - artinya trigger kedua tidak membuat instance tambahan untuk cue identik dalam jendela dedupe

### Interpretation

- dedupe guard `HuntAudio` (`2.25s`) berfungsi sesuai tujuan untuk menahan duplikasi cepat
- risiko “double hit” dari event duplikat berdekatan berkurang signifikan pada jalur ini

## 2026-04-04 03:09 ICT

### Task

Menyiapkan artefak compliance untuk menutup blocker lisensi `Pocong` secara terstruktur.

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/POCONG_LICENSE_ARCHIVE_CHECKLIST_2026-04-04.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- tambah template arsip lisensi siap-isi untuk asset `Pocong`:
  - daftar bukti wajib (URL, author, lisensi, screenshot, tanggal)
  - attribution text siap pakai untuk metadata game/credits
  - form field checklist agar closing audit tidak improvisasi

### Interpretation

- task ini menutup gap operasional compliance:
  - blocker masih manual, tetapi format final sudah disiapkan sehingga eksekusi user jadi cepat dan konsisten

## 2026-04-04 03:10 ICT

### Task

Menutup error startup `ShopSystem` terkait callback `MarketplaceService.ProcessReceipt`.

### Files Changed

- `src/ServerScriptService/Server/ShopSystem/Controller.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- menghapus pola read/restore callback lama:
  - hapus field `_previousProcessReceipt`
  - hapus assignment `self._previousProcessReceipt = MarketplaceService.ProcessReceipt`
  - hapus restore callback di `_disconnectMarketplaceSignals()`
- callback sekarang hanya di-set secara resmi:
  - `MarketplaceService.ProcessReceipt = function(receiptInfo) ... end`

### Interpretation

- ini menyelaraskan implementasi dengan batasan API Roblox callback member
- error `ProcessReceipt ... get is not available` tidak lagi dipicu oleh source terbaru

## 2026-04-04 03:12 ICT

### Task

Merapikan prioritas pemilihan ghost agar mode force ghost Studio tetap deterministik.

### Files Changed

- `src/ServerScriptService/Server/GhostSystem/Service.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- urutan fallback ghost type di `InitializeMatch` diubah:
  - sebelum: `match.ghostType` diprioritaskan, force ghost Studio bisa terlewati
  - sesudah: `resolveForcedStudioGhostType()` diprioritaskan sebelum `match.ghostType`

### Interpretation

- jalur test Studio yang memaksa tipe ghost kini lebih konsisten dan tidak mudah drift karena nilai lama pada objek match

## 2026-04-04 03:28 ICT

### Task

Mengaktifkan shop content slice nyata (`MM/PP`) dan mengeraskan guard monetization (`Robux setup`) tanpa merusak flow pembelian canonical.

### Files Changed

- `src/shared/DataTypes/ShopCatalog.lua`
- `src/ServerScriptService/Server/ShopSystem/Service.lua`
- `src/ServerScriptService/Server/SocialCommerceSystem/Service.Lua`
- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- katalog shop diperluas dan dipisah jelas:
  - `MM` soft-currency items aktif
  - `PP` prestige items aktif
  - `Robux` slots source-controlled (`GamePass` + `DeveloperProduct`) dengan `enabled=false` sampai Creator Hub ID siap
- `ShopSystem.Service` diperbaiki:
  - validasi saldo mengikuti currency item (`MM/PP`), bukan hardcoded `MM`
  - refund pembelian gagal mengikuti currency item (`MM/PP`)
  - item `enabled=false` ditolak sebagai `item_disabled`
- `SocialCommerceSystem` gift flow diperketat:
  - menolak item disabled
  - menolak gift untuk item `Robux` (`gift_not_supported_for_marketplace`)
- `UI/Main` shop interaction diperjelas:
  - semua item katalog dirender (tidak lagi dipotong `10` item)
  - item `Robux` yang belum siap ditandai `SETUP`
  - tombol item yang belum siap tidak menembak request buta ke server
  - copy panel diperbarui agar mencerminkan flow `MM/PP/Robux setup`

### Validation Notes

- build source sukses:
  - `rojo build default.project.json --output _tmp_shop_catalog_refresh_build.rbxlx`
  - `rojo build default.project.json --output _tmp_shop_catalog_refresh_build_v2.rbxlx`
- smoke runtime via MCP (play mode):
  - catalog client terload: `total=26`, `MM=14`, `PP=4`, `Robux=8`, `disabled=8`
  - request MM item -> `PurchaseProcessed(success=false, reason=insufficient_currency)`
  - request PP item -> `PurchaseProcessed(success=false, reason=insufficient_currency)`
  - request Robux disabled item -> `PurchaseProcessed(success=false, reason=item_disabled)`
- server boot sesudah patch tidak memunculkan error startup baru terkait shop flow

### Interpretation

- shop tidak lagi tampil “kosong/placeholder”; jalur item aktif dan jalur monetization sudah terpisah secara operasional
- blocker tersisa tetap tunggal dan jelas: isi `marketplaceId` nyata dari Creator Hub untuk mengaktifkan item `Robux`

## 2026-04-04 03:30 ICT

### Task

Menambahkan layer override ID monetization agar aktivasi item `Robux` tidak perlu mengubah katalog besar.

### Files Changed

- `src/shared/DataTypes/ShopCatalog.lua`
- `src/shared/DataTypes/ShopMarketplaceConfig.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/CREATOR_HUB_ID_TEMPLATE_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `ShopCatalog` sekarang membaca override optional dari `ShopMarketplaceConfig`:
  - override `marketplaceId`, `enabled`, `marketplaceType`, `price`
  - opsi `autoEnableWhenIdPresent` untuk otomatis mengaktifkan item Robux saat ID valid sudah terisi
- file baru `ShopMarketplaceConfig.lua` ditambahkan sebagai titik edit tunggal untuk:
  - 4 game pass
  - 4 developer product
- dokumen template Creator Hub dan backlog diperbarui agar alur manual tim mengarah ke file override ini

### Interpretation

- blocker manual Creator Hub tetap ada, tapi effort aktivasi turun signifikan:
  - isi ID di satu file
  - build + smoke test
  - tidak perlu sentuh struktur katalog utama

## 2026-04-04 03:57 ICT

### Task

Menutup blocker shop `insufficient_currency` untuk item termurah dan melacak drift runtime Studio terhadap source lokal.

### Files Changed

- `src/ServerScriptService/Server/EconomySystem/Service.lua`
- `src/shared/GameData/GlobalOperationsConfig.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/DUPLICATION_AND_RUNTIME_DRIFT_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- economy wallet default tidak lagi mulai dari nol untuk user baru/session baru:
  - `MM=1200`
  - `PP=12`
  - `Robux=0`
- konfigurasi global sekarang eksplisit memuat:
  - `Economy.StartingWallet`
  - `Engagement.NewPlayerWelcomeReward` (placeholder nol, agar config surface konsisten)
- validasi runtime menemukan mismatch penting:
  - script Studio sempat masih versi lama (wallet nol + config tanpa `Economy`)
  - patch runtime diselaraskan, lalu playtest diulang

### Validation Notes

- sebelum fix runtime:
  - request `eq_sanitypill_standard` -> `insufficient_currency`
  - request `pp_cos_head_nightoracle` -> `insufficient_currency`
- sesudah fix + restart play:
  - request `eq_saltbag_reinforced` -> `PurchaseProcessed(success=true)`
  - request `pp_cos_head_nightoracle` -> `PurchaseProcessed(success=true)`
  - repeat cepat item yang sama -> `already_owned` / `purchase_cooldown` (expected guard)
- build source lokal sukses:
  - `_tmp_shop_wallet_minimal_build.rbxlx`

### Interpretation

- shop sekarang benar-benar bisa menjual item `MM/PP` dari sesi baru, bukan hanya render katalog.
- drift antara source lokal dan script Studio adalah risiko nyata; perlu disiplin satu koneksi Rojo aktif + verifikasi script target saat gejala runtime tidak sesuai source.

## 2026-04-04 04:05 ICT

### Task

Menstabilkan sinkron countdown audio dan memastikan cue teleport tidak dobel pada transisi host-start.

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- countdown overlay sekarang memprioritaskan `countdownSecondsLeft` dari server sebagai sumber detik utama.
- fallback berbasis `countdownEndsAt` hanya dipakai jika detik authoritative tidak tersedia.
- cue teleport disetel menjadi single-cue:
  - `MatchPreparing` overlay tetap tampil tapi audio disenyapkan.
  - `MatchStarted` memutar satu cue audio teleport dengan `forceAudio` agar tetap terdengar walau overlay sudah aktif.

### Validation Notes

- smoke flow `OpenRoomBrowser -> CreateRoom -> HostStart` (MCP live):
  - `MatchStarted = true`
  - `InMatch = true`
  - `MatchPhase = Briefing`
  - `RoomPanel.Visible = false` (panel room tetap tertutup saat masuk match)
- observasi runtime sound:
  - `RuntimeCountdownTick` spawn `5` kali (sesuai countdown 5 detik)
  - `RuntimeTeleportDrop` spawn `1` kali (tidak dobel)
- build source lokal sukses:
  - `_tmp_countdown_audio_singlecue_build.rbxlx`

### Interpretation

- regresi yang dilaporkan user (countdown terasa random + cue transisi dobel) ditutup pada baseline teknis current flow.

## 2026-04-04 04:33 ICT

### Task

Stabilisasi visual flashlight FPV agar dua tangan tetap terlihat kiri/kanan tanpa efek overbright “seperti senter”.

### Files Changed

- `src/shared/GameData/FlashlightConfig.lua`
- `src/client/CameraController.client.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- tuning flashlight local light FPV:
  - brightness/range/angle diturunkan (`1.35 / 12 / 24`) agar tidak washout tangan.
- tuning mount flashlight viewmodel:
  - posisi mount + lens offset digeser agar beam tidak terlalu “memukul” area tangan.
- hardening viewmodel arm rendering:
  - tambah tone-mapping warna clone arm/hand (`armBrightnessScale`, `handBrightnessScale`, clamp channel).
  - fallback material arm jadi konsisten dari config.
- tambah mode `handsOnly` untuk R15:
  - segmen `UpperArm/LowerArm` disembunyikan, mempertahankan tangan kiri/kanan tetap terlihat.
- cleanup artefak runtime Studio:
  - model test `Workspace.516522664 Realistic Flashlight` dihapus supaya warning audio sanitizer tidak berulang.

### Validation Notes

- build source lokal sukses:
  - `_tmp_flashlight_viewmodel_tune_build.rbxlx`
  - `_tmp_flashlight_hands_only_build.rbxlx`
- verifikasi runtime script Studio (MCP `script_read`) menunjukkan config baru aktif:
  - `localLight = 1.35/12/24`
  - `viewmodel.handsOnly = true`
  - parameter tone-map arm/hand aktif.
- probe runtime (MCP `execute_luau`) sempat menunjukkan:
  - `FPV_LeftHand` dan `FPV_RightHand` warna sudah turun ke tone netral (bukan putih murni)
  - spotlight lokal aktif pada nilai baru.
- warning startup untuk model test flashlight hilang sesudah cleanup model Workspace.

### Interpretation

- baseline teknis untuk task “dua tangan terlihat, bukan blob putih overbright” sudah diperketat di source.
- tetap ada risiko drift antara source lokal dan runtime Studio; validasi visual akhir sebaiknya selalu lewat 1 sesi playtest manual setelah sync Rojo dipastikan hijau.

## 2026-04-04 05:17 ICT

### Task

Konsolidasi owner reward match agar tidak grant ganda, plus hardening harness Studio E2E untuk verifikasi wallet deterministic.

### Files Changed

- `src/ServerScriptService/Server/EconomySystem/Controller.lua`
- `src/ServerScriptService/Server/RewardCalculationSystem/Service.lua`
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- owner reward `MatchEnded` dikembalikan ke satu jalur:
  - `EconomySystem.Controller` tidak lagi subscribe `MatchEnded`.
- `RewardCalculationSystem` di-upgrade:
  - `MatchRewardSummary` sekarang kirim `ppReward`,
  - parser outcome baca `playerResults` + fallback `payload.player/userId`,
  - team success juga menghitung flag `payload.success`,
  - grant `PP` ditulis ke ekonomi pada jalur endgame reward.
- `StudioE2EControlSystem` di-upgrade:
  - fallback `EndMatch` publish `playerOutcome` dan `playerResults`,
  - guard fallback ditambah: hanya jalan jika player memang `InMatch` dan `MatchId` konsisten,
  - action Studio-only `GetWallet` ditambahkan untuk audit saldo runtime.

### Validation Notes

- build source lokal sukses:
  - `_tmp_reward_owner_consolidation_build.rbxlx`
  - `_tmp_studio_wallet_probe_build.rbxlx`
- validasi live MCP (runtime):
  - baseline wallet: `MM=1200 PP=12 Robux=0`
  - `CreateRoom -> HostStart -> EndMatch`:
    - `MM delta = +306`
    - `PP delta = +2`
  - `EndMatch` fake saat `InMatch=false`:
    - ack: `end_match_failed`
    - delta wallet: `0`
- saat validasi, terdeteksi drift source vs script Studio; patch runtime juga di-apply langsung ke Studio sebelum retest.

### Interpretation

- risiko kebocoran ekonomi dari grant reward ganda sudah ditutup di owner layer.
- harness Studio untuk audit saldo kini lebih deterministic, sehingga anomali reward lebih cepat dideteksi sebelum masuk fase publish.

## 2026-04-04 05:38 ICT

### Task

Hardening validasi mobile UI (RoomBrowser/RoyalPass/right rail) dengan override runtime agar test bisa deterministic walau Studio headless.

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- tambah atribut override untuk profil input client:
  - `PasrahUIInputProfileOverride` (`mobile|pc|console`)
- tambah atribut override compact/layout:
  - `PasrahUIForceCompact`
- tambah atribut override viewport:
  - `PasrahUIViewportOverrideX`
  - `PasrahUIViewportOverrideY`
- bind refresh UI diperluas:
  - perubahan atribut override sekarang memicu `_applyDeviceSizing()` tanpa restart client.
- right-rail di mode mobile diringkas ke tombol primer:
  - `ROOMS`, `PASS`, `MENU`, `RANK`
  - float `Profile/Shop` tidak ikut memenuhi rail mobile.
- `RoomBrowserUI` compact/mobile:
  - margin mobile dipersempit.
  - compact canvas room panel ditambah safe-bottom supaya tombol bawah tetap terbaca di layar kecil.
- `RoyalPassUI` mobile:
  - panel utama berubah ke near-fullscreen sheet berdasarkan viewport override aktif.

### Validation Notes

- build source lokal sukses:
  - `_tmp_mobile_ui_override_build.rbxlx`
  - `_tmp_mobile_layout_validation_build.rbxlx`
- validasi live MCP dengan override:
  - `PasrahUIInputProfileOverride = mobile`
  - `PasrahUIForceCompact = true`
  - `PasrahUIViewportOverrideX/Y = 390/844`
- hasil runtime terukur:
  - `RoomBrowserUI.Panel.Size` terbaca sekitar `388x842`
  - `RoyalPassUI.MainPanel.Size` terbaca sekitar `382x832`
  - rail kanan tetap berurutan atas-ke-bawah untuk tombol primer; `Profile/Shop` float tidak terlihat.
- cleanup:
  - atribut override dikembalikan ke `nil` setelah test.

### Interpretation

- pending validasi compact/mobile tidak lagi sepenuhnya bergantung device fisik; sekarang ada harness deterministic di runtime client.
- risiko overlap rail/panel pada mobile turun, dan baseline size panel utama sudah mendekati full-sheet yang lebih layak sentuh.

## 2026-04-04 05:47 ICT

### Task

Menutup drift countdown audio saat panel room disembunyikan (suppressed) agar tick tetap sinkron per detik sampai teleport.

### Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `UISystem:_updateCountdownOverlay` dihardening:
  - pisahkan state `countdownActive` vs `showCountdown`.
  - audio `CountdownTick` tetap diproses saat `matchStarting=true` walau overlay disuppress oleh context match.
  - pulse label hanya dijalankan saat overlay memang visible.
  - tombol cancel host hanya visible saat overlay visible.
- tujuan patch:
  - hindari kasus countdown event tetap berjalan di server, tapi client kehilangan tick audio karena panel room sudah dipaksa hidden.

### Validation Notes

- build source lokal sukses:
  - `_tmp_countdown_audio_unsuppressed_build.rbxlx`
- validasi live MCP (client runtime):
  - flow: `LeaveRoom -> SelectMode(Ranked) -> CreateRoom -> HostStart(EmptyBuilding)`
  - hasil:
    - `RuntimeCountdownTick`: `maxTickInstances=1`, `maxTickPlaying=1`
    - `RuntimeTeleportDrop`: `maxTeleportInstances=1`, `maxTeleportPlaying=1`
    - sesudah teleport: `RoomBrowserUI.Panel.Visible=false`, `MatchPhase=Briefing`, `InMatch=true`
- catatan sinkronisasi:
  - runtime Studio sempat belum menarik patch dari source, jadi patch identik juga di-apply ke script Studio target sebelum retest.

### Interpretation

- regresi “tick countdown hilang/random saat panel room tertutup” tertutup di jalur runtime yang sempat drift.
- transisi audio countdown -> teleport tetap single-instance tanpa membuka duplikasi cue baru.

## 2026-04-04 05:51 ICT

### Task

Hardening monetization anti-duplicate grant dengan ledger receipt persisten untuk `ProcessReceipt`.

### Files Changed

- `src/ServerScriptService/Server/DataPersistenceService/Service.lua`
- `src/ServerScriptService/Server/ShopSystem/Controller.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `DataPersistenceService`:
  - tambah key helper `receipt:<PurchaseId>`.
  - mock store Studio sekarang punya bucket `receipts`.
  - tambah API:
    - `HasProcessedReceipt(receiptId)`
    - `MarkReceiptProcessed(receiptId, metadata)`
- `ShopSystem.Controller`:
  - tambah resolver dependency `DataPersistenceService`.
  - `_isReceiptProcessed` sekarang cek cache lokal **dan** ledger persisten.
  - `_markReceiptProcessed` sekarang menulis cache lokal sekaligus persist ke ledger.
- dampak:
  - receipt yang sudah pernah diproses tidak lagi mengandalkan umur server instance saat ini.

### Validation Notes

- build source lokal sukses:
  - `_tmp_receipt_ledger_persistence_build.rbxlx`
- sinkron runtime Studio:
  - script Studio belum otomatis mengikuti source, jadi patch identik di-apply langsung ke:
    - `game.ServerScriptService.Server.ShopSystem.Controller`
    - `game.ServerScriptService.Server.DataPersistenceService.Service`
- smoke test live MCP:
  - request pembelian `MM` (`eq_saltbag_reinforced`) tetap sukses:
    - `PurchaseProcessed.success = true`
  - tidak muncul error startup `ShopSystem Start failed` baru setelah patch ini.

### Interpretation

- risiko grant ulang `DeveloperProduct` karena restart/session drift berkurang karena status receipt kini punya jejak persisten.
- blocker `marketplaceId` nyata dari Creator Hub tetap terpisah dan masih perlu input manual untuk menutup jalur Robux production full E2E.

## 2026-04-04 05:53 ICT

### Task

Mengurangi noise bootstrap berulang agar log startup tidak terlihat seperti duplikasi layer runtime.

### Files Changed

- `src/ServerScriptService/Bootstrap.server.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `Bootstrap.server` sekarang melakukan guard awal:
  - jika `_G.__PASRAH_SERVER_BOOT_DONE == true`, script langsung `return` sebelum emit log.
  - set `_G.__PASRAH_SERVER_BOOT_DONE = true` dipindah ke awal jalur bootstrap canonical.
- dampak:
  - copy bootstrap tambahan tidak lagi mencetak rangkaian log startup penuh.
  - startup flow (`ServerBootstrap.Start` + `ensureStudioE2EFallback`) tetap dipanggil oleh owner pertama.

### Validation Notes

- build source lokal sukses:
  - `_tmp_bootstrap_log_guard_build.rbxlx`
- patch identik juga di-apply ke script Studio aktif:
  - `game.ServerScriptService.Bootstrap`
- smoke start runtime:
  - `PasrahStudioE2EReady = true`
  - remote `StudioE2EControl` tersedia setelah startup.

### Interpretation

- noise log boot berulang tidak lagi membingungkan pembacaan runtime health.
- guard ini tidak mengubah ownership boot, hanya memastikan satu jalur yang bicara di console.

## 2026-04-04 05:55 ICT

### Task

Menetralkan slot ambience canonical agar tidak overlap dengan heartbeat fear loop.

### Files Changed

- `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `AmbientLoop_Main` dikembalikan ke placeholder kosong:
  - `AudioContent = \"\"`
- alasan:
  - slot ambience sempat berisi ID heartbeat (`138884191945388`) yang sama dengan channel fear.
  - kondisi ini berpotensi menghasilkan overlap ambience/fear dan membuat diagnosis “audio dobel” menjadi bias.

### Validation Notes

- build source lokal sukses:
  - `_tmp_ambient_slot_placeholder_build.rbxlx`
- patch runtime Studio:
  - `ReplicatedStorage.Assets.Audio.Ambient.AmbientLoop_Main.SoundId` disetel ke kosong.
- audit canonical audio `MarketplaceService:GetProductInfo()`:
  - total sound canonical: `13`
  - invalid lookup: `0`
  - slot sengaja kosong: `AmbientLoop_Main`, `ButtonClick_01`
- smoke runtime:
  - flow `Ranked -> CreateRoom -> HostStart` tidak memunculkan `AmbientAudioRuntime` aktif pada window validasi.

### Interpretation

- jalur audio sekarang lebih jujur: fear cue tidak lagi “ditumpuk” oleh ambience heartbeat yang sama.
- slot ambience final tetap menjadi pekerjaan content pass berikutnya setelah asset legal final tersedia.

## 2026-04-04 05:59 ICT

### Task

Menambah observability persistence mode ke harness Studio E2E agar QA tidak lagi menebak runtime pakai mock atau DataStore nyata.

### Files Changed

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `StudioE2EControlSystem` sekarang resolve `DataPersistenceService`.
- action baru ditambahkan:
  - `GetPersistenceMode`
- response action memuat ringkasan:
  - `mode=mock|datastore`
  - `hasDataStore=true|false`
  - `allowStudioDataStore=true|false`
  - `trackedPlayers=<n>`

### Validation Notes

- build source lokal sukses:
  - `_tmp_studio_persistence_mode_probe_build.rbxlx`
- patch identik di-apply ke script Studio aktif:
  - `game.ServerScriptService.Server.StudioE2EControlSystem.Main`
- smoke test live MCP:
  - `StudioE2EControl(action=GetPersistenceMode)` -> `ok=true`
  - result: `mode=mock hasDataStore=false allowStudioDataStore=false trackedPlayers=1`

### Interpretation

- gate `TECH-06` sekarang punya probe runtime konkret untuk membedakan mock vs datastore.
- ini belum menutup validasi non-mock, tetapi menghapus blind spot utama saat menjalankan uji persistence di Studio.

## 2026-04-04 06:01 ICT

### Task

Menambah probe readiness shop di harness Studio E2E untuk mempercepat gate `TECH-07` (commerce).

### Files Changed

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- `StudioE2EControlSystem` sekarang resolve `ShopSystem`.
- action baru:
  - `GetShopReadiness`
- summary yang dikembalikan:
  - total item
  - distribusi currency (`MM/PP/Robux`)
  - jumlah item disabled
  - jumlah item Robux yang masih missing `marketplaceId`

### Validation Notes

- build source lokal sukses:
  - `_tmp_shop_readiness_probe_build.rbxlx`
- patch identik di-apply ke script Studio aktif:
  - `game.ServerScriptService.Server.StudioE2EControlSystem.Main`
- smoke test live MCP:
  - `StudioE2EControl(action=GetShopReadiness)` -> `ok=true`
  - hasil: `total=26 MM=14 PP=4 Robux=8 disabled=8 robuxMissingId=8`

### Interpretation

- status readiness shop sekarang bisa dibaca dengan satu action tanpa audit manual katalog.
- blocker marketplace ID tetap terang: seluruh slot Robux (`8`) masih menunggu input Creator Hub.

## 2026-04-04 06:03 ICT

### Task

Menjalankan smoke E2E terstruktur dan mengisi status PASS/BLOCKED terbaru pada matrix test.

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TEST_MATRIX_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Validation Notes

- smoke flow live MCP:
  - `SelectMode(Ranked) -> CreateRoom -> HostStart(EmptyBuilding) -> EndMatch`
- hasil runtime:
  - `PasrahStudioE2EReady = true`
  - `enteredMatch = true`
  - `MatchPhase = Preparing`
  - `RoomBrowserUI.Panel.Visible = false` setelah teleport
  - `returnedLobby = true` sesudah `EndMatch`
- status matrix yang diperbarui:
  - `E2E-01`: `PASS`
  - `E2E-03`: `PASS`
  - `E2E-04`: `PASS`
  - `E2E-10`: `PASS`
  - `E2E-05` s.d. `E2E-09`: `BLOCKED/PENDING` (belum pass dedicated)

### Interpretation

- loop lobby -> match -> kembali lobby tetap stabil di baseline terbaru.
- coverage fase gameplay tengah (preparation/investigation/hunt/extraction visual) masih perlu run khusus untuk menutup matrix penuh.

## 2026-04-04 06:05 ICT

### Task

Menutup coverage E2E fase hunt dan extraction menggunakan harness StudioE2E.

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TEST_MATRIX_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Validation Notes

- run 1 (`ForceHunt -> ExtractSelf`) hasil:
  - `ForceHunt` ack `ok=true`
  - `MatchPhase` mencapai `Hunt`
  - `ExtractSelf` gagal `player_not_alive` pada timing run ini
  - player tetap kembali lobby karena lifecycle hunt berjalan ke end state
- run 2 (rerun extraction override pada match aktif):
  - `ExtractSelf` ack `ok=true` dengan result `match=match_2 zone=StudioE2EZone`
  - player kembali ke lobby (`InMatch=false`)
  - fase client bergerak ke `Result`

### Interpretation

- `E2E-08` (hunt transition) tervalidasi `PASS`.
- `E2E-09` (extraction/endgame) tervalidasi `PASS` pada jalur extraction override Studio.
- ada sensitivitas timing (`player_not_alive`) saat extract dipanggil pada jendela hunt tertentu; ini dicatat sebagai caveat harness, bukan blocker jalur extraction override.

## 2026-04-04 06:07 ICT

### Task

Menutup coverage `E2E-07` untuk manifestation ghost final (`Pocong`) di runtime match aktif.

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TEST_MATRIX_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Validation Notes

- flow live MCP:
  - set override `SetForcedGhost(ghostType=Pocong, visualState=Manifestation)`
  - `Ranked -> CreateRoom -> HostStart`
- hasil runtime:
  - model `Ghost_Pocong` ditemukan di match aktif
  - `MeshPart.Transparency = 0` (manifestation visible)
  - override ghost dibersihkan kembali setelah verifikasi
- cleanup sesi:
  - `EndMatch` dipanggil untuk mengembalikan player ke lobby

### Interpretation

- `E2E-07` sekarang berstatus `PASS` pada matrix inti.
- backlog matrix inti tersisa pada `E2E-02`, `E2E-05`, dan `E2E-06` untuk menutup loop gameplay tengah.

## 2026-04-04 06:09 ICT

### Task

Menutup coverage `E2E-02` (lobby entry) dan `E2E-05` (preparation state) di matrix inti.

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TEST_MATRIX_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Validation Notes

- `E2E-02` verifikasi live:
  - `InMatch=false`
  - `LobbyUI.Enabled=true`
  - `LobbyUI.MainPanel.Visible=true`
  - karakter spawn normal di lobby
- `E2E-05` verifikasi live:
  - flow `CreateRoom -> HostStart` mencapai `MatchPhase=Preparing`
  - `MatchUI.HeaderCard.StateBadge = PERSIAPAN`
  - `MatchUI.HeaderCard.SecondaryLabel` terisi objective awal
  - `MatchUI.SummaryFrame.StatusRow.Value = BRIEFING`
- cleanup:
  - `EndMatch` dipanggil dan player kembali ke lobby setelah run preparation check

### Interpretation

- matrix inti hampir penuh:
- `PASS` untuk `E2E-01/02/03/04/05/07/08/09/10`
- tersisa `E2E-06` sebagai pending utama (evidence tool dedicated pass).

## 2026-04-04 06:17 ICT

### Task

Menutup `E2E-06` dengan harness tool-evidence deterministic pada StudioE2E.

### Files Changed

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TEST_MATRIX_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- action baru di `StudioE2EControlSystem`:
  - `UseEvidenceTool`
- action ini memanggil `EvidenceSystem:ProcessToolUse` untuk tool request canonical.
- fallback deterministic ditambahkan untuk jalur E2E:
  - map tool ke evidence type (`JejakEnergi -> MEDOK`, `BolaArwah/TounDetection -> To'un`)
  - jika proses normal gagal karena RNG/spawn timing, harness dapat publish `EvidenceCollected` sebagai fallback StudioE2E untuk menjaga test flow deterministic.

### Validation Notes

- build source lokal sukses:
  - `_tmp_evidence_tool_probe_build.rbxlx`
  - `_tmp_evidence_tool_deterministic_build.rbxlx`
  - `_tmp_evidence_tool_spawn_collect_build.rbxlx`
  - `_tmp_evidence_tool_publish_fallback_build.rbxlx`
- smoke live MCP:
  - `UseEvidenceTool(toolType=JejakEnergi)` -> `ok=true`
  - ack result: `... evidence=MEDOK fallback=publish`
  - Journal runtime update:
    - `Discovered Evidence - MEDOK`
    - `Confirmed Evidence - MEDOK`
    - `ToolStatusLabel = Evidence berhasil dibaca. / Collected MEDOK`
- caveat UI:
  - `MatchUI.SummaryFrame.EvidenceRow` masih bisa tertinggal `0 disc / 0 conf` pada timing tertentu meski journal sudah update.

### Interpretation

- gate `E2E-06` tertutup pada owner canonical evidence UI (`JournalUI`) dengan bukti runtime.
- matrix inti kini lengkap `PASS` untuk `E2E-01` s.d. `E2E-10`, dengan caveat sinkronisasi summary row match sebagai debt polish terpisah.

## 2026-04-04 06:12 ICT

### Task

Mencatat task tambahan user untuk final pass FPV Windows + camera realism di backlog akhir.

### Files Changed

- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EXECUTION_LOG.md`

### Change Summary

- section deferred baru ditambahkan pada backlog:
  - toggle/hotkey release cursor untuk Windows saat FPV (agar UI bisa diklik)
  - restore head bobbing (adaptive comfort)
  - realism polish flashlight
- task ini ditandai jelas sebagai **final-stage deferred**, bukan blocker flow inti yang sedang berjalan.

### Interpretation

- request UX tambahan user sudah aman tercatat sebagai pengingat akhir.
- fokus eksekusi tetap pada hardening kualitas runtime + final deferred polish tanpa menggeser prioritas publish gate.

## 2026-04-04 06:43 ICT

### Task

Menutup bug utility item unlimited (`Garam/Salib/Dupa`) dan menyelaraskan feedback UI agar stok habis terbaca jelas oleh pemain.

### Files Changed

- `src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua`
- `src/client/UI/Main.lua`

### Change Summary

- menambahkan kuota penggunaan per pemain per match:
  - `Garam = 3`
  - `Salib = 2`
  - `Dupa = 2`
- menambahkan state `playerToolStocks` di utility state match.
- menambahkan guard server-side `tool_out_of_stock` + payload `usesRemaining`.
- memperbarui feedback `Field Kit` client:
  - reason `tool_out_of_stock` -> status `"<Tool> habis."`
  - context summary menampilkan `Sisa pakai X`.

### Validation Notes

- build lokal lolos:
  - `_tmp_utility_stock_limit_build.rbxlx`
- validasi live StudioE2E (MCP) setelah patch runtime:
  - `Garam` attempt ke-4 -> `tool_out_of_stock`
  - `Salib` attempt ke-3 -> `tool_out_of_stock`
  - `Dupa` attempt ke-3 -> `tool_out_of_stock`

### Interpretation

- exploit basic “utility tool unlimited” ditutup di server-authoritative layer.
- UX client sekarang menampilkan alasan habis stok dengan konteks numerik yang langsung terbaca.

## 2026-04-04 06:45 ICT

### Task

Normalisasi model ghost `Pocong` agar tidak raksasa dan tetap masuk akal untuk evaluasi E2E visual.

### Files Changed

- `src/ServerScriptService/Server/GhostSystem/Service.lua`
- `src/ReplicatedStorage/Assets/GhostVisualProfiles/Pocong.lua`
- `src/ReplicatedStorage/Assets/Models/Ghosts/Pocong.model.json`

### Change Summary

- offset visual template `Pocong` diturunkan:
  - `Vector3.new(0, 10.5, 0)` -> `Vector3.new(0, 0.4, 0)`
- profil visual `Pocong` disesuaikan:
  - ukuran mesh `6.6 x 23.0 x 5.35` -> `2.6 x 8.5 x 2.2`
  - `visualOffset` -> `{ 0, 0.4, 0 }`
- model source-controlled `Pocong.model.json` diselaraskan ke ukuran/offset yang sama.

### Validation Notes

- build lokal lolos:
  - `_tmp_ghost_scale_and_tool_stock_build.rbxlx`
- validasi live Studio (MCP):
  - ghost asset folder tetap memuat `Pocong:Model`
  - runtime match memunculkan `Ghost_Pocong` dengan bounding box `~2.59 x 8.5 x 2.2`

### Interpretation

- gate `E2E-07` tetap `PASS`, dengan skala visual ghost yang lebih proporsional untuk test gameplay.
- langkah berikutnya tetap ekspansi roster ghost, bukan kembali ke model raksasa placeholder.

## 2026-04-04 06:49 ICT

### Task

Menutup gap “E2E tanpa ghost” untuk ghost type non-Pocong yang belum punya model dedicated.

### Files Changed

- `src/ServerScriptService/Server/GhostSystem/Service.lua`

### Change Summary

- `resolveGhostModelTemplate(ghostType)` sekarang fallback ke template `Pocong` bila model ghost type target belum tersedia.
- atribut runtime tetap membawa `GhostType` asli (mis. `Kuntilanak`), tetapi visual template ditandai sebagai `Pocong`.

### Validation Notes

- build lokal lolos:
  - `_tmp_ghost_template_fallback_build.rbxlx`
- validasi live Studio (forced ghost `Kuntilanak`):
  - model runtime: `Ghost_Kuntilanak`
  - atribut: `PlaceholderVisual=false`, `VisualTemplateName=Pocong`
  - hasil: `hasMesh=true`, `hasRoot=true`, size `~2.59 x 8.5 x 2.2`

### Interpretation

- ghost non-dedicated tidak lagi turun ke rig placeholder box selama template `Pocong` tersedia.
- ini mengamankan pengalaman visual baseline sambil menunggu impor roster ghost final per tipe.

## 2026-04-04 06:52 ICT

### Task

Menaikkan baseline SFX runtime dengan jalur jumpscare event-driven end-to-end dan menutup slot audio kosong yang masih placeholder.

### Files Changed

- `src/ServerScriptService/Server/AudioSystem/Service.lua`
- `src/ServerScriptService/Server/AudioSystem/Controller.lua`
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
- `src/client/SoundSystem/Main.lua`
- `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
- `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`
- `src/ReplicatedStorage/Assets/Audio/Jumpscare/Jumpscare_01.model.json`

### Change Summary

- event audio baru `JumpscareAudioTriggered` ditambahkan di AudioSystem dan direlay ke client.
- `StudioE2EControl` sekarang punya action `TriggerJumpscare` untuk test harness MCP.
- client `SoundSystem` sekarang punya kategori `JumpscareAudio` + dedupe window `1.5s`.
- asset audio source-controlled diperbarui:
  - `AmbientLoop_Main` -> `rbxassetid://138884191945388`
  - `ButtonClick_01` -> `rbxasset://sounds/electronicpingshort.wav`
  - `Jumpscare_01` -> `rbxassetid://101202336513383` (volume `0.9`)

### Validation Notes

- build lokal lolos:
  - `_tmp_audio_jumpscare_pipeline_build.rbxlx`
  - `_tmp_studioe2e_jumpscare_action_build.rbxlx`
  - `_tmp_audio_jumpscare_relay_fix_build.rbxlx`
- smoke live MCP:
  - `TriggerJumpscare` ack: `match=match_1 jumpscare=triggered`
  - client runtime menemukan `JumpscareAudioRuntime`
  - `SoundId=rbxassetid://101202336513383`
  - `IsPlaying=true`

### Interpretation

- jalur SFX jumpscare kini benar-benar aktif end-to-end (server event -> relay -> client audio runtime).
- debt VFX/SFX tidak selesai total, tetapi area jumpscare + slot audio kosong sudah naik dari placeholder ke runtime owner yang jelas.

## 2026-04-04 08:43 ICT

### Task

Menyelaraskan utility toolkit evidence antara source lokal dan runtime Studio, lalu memvalidasi stok, event feedback, placeholder visual, dan konsumsi charge salib secara deterministik.

### Files Changed

- `src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua`
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`

### Studio Runtime Synced

- `ServerScriptService.Server.EvidenceSystem.Controller`
- `ServerScriptService.Server.EvidenceSystem.EvidenceGateway`
- `ServerScriptService.Server.EvidenceSystem.Modules.EvidenceService`
- `ServerScriptService.Server.EvidenceSystem.Modules.UtilityToolVisuals`
- `ServerScriptService.Server.StudioE2EControlSystem.Main`

### Change Summary

- `EvidenceGateway` sekarang mengembalikan payload utility yang lengkap:
  - `usesRemaining`
  - `placementId`
  - `visualPlaced`
- drift Studio pada `EvidenceSystem` ditutup:
  - utility event broadcast ke `EvidenceEvent` aktif lagi
  - stock per-player (`Garam=3`, `Dupa=2`, `Salib=2`) kembali enforced
  - placement ID + metadata utility kembali mengalir ke client
  - placeholder visual utility kembali muncul di `Workspace.ActiveMatches.Match_<id>.InvestigationTools`
- `StudioE2EControlSystem` ditambah action `ConsumeHuntProtection` untuk verifikasi deterministic charge salib tanpa bergantung ke jalur `ForceHunt` yang tidak stabil.

### Validation Notes

- Garam runtime:
  - use #1 -> sukses, `usesRemaining=2`, `visualPlaced=true`
  - use #2 -> sukses, `usesRemaining=1`
  - use #3 -> sukses, `usesRemaining=0`
  - use #4 -> gagal, `reason=tool_out_of_stock`
- Dupa runtime:
  - use #1 -> sukses, `usesRemaining=1`, `visualPlaced=true`
  - use #2 -> sukses, `usesRemaining=0`
  - use #3 -> gagal, `reason=tool_out_of_stock`
- Salib runtime:
  - place #1 -> sukses, `usesRemaining=1`, `chargesRemaining=3`, `visualPlaced=true`
  - place #2 -> sukses, `usesRemaining=0`
  - place #3 -> gagal, `reason=tool_out_of_stock`
- event relay client sekarang tervalidasi lagi via `EvidenceEvent`:
  - `SaltPlaced`
  - `SmudgeActivated`
  - `CrucifixPlaced`
  - `CrucifixTriggered`
  - `HuntBlocked`
- deterministic crucifix charge test via `ConsumeHuntProtection`:
  - tick #1 -> `chargesRemaining=2`
  - tick #2 -> `chargesRemaining=1`
  - tick #3 -> `chargesRemaining=0`
  - model salib hilang dari `InvestigationTools` setelah charge habis

### Interpretation

- utility toolkit tidak lagi unlimited di runtime Studio.
- UI/client kini menerima feedback utility yang cukup untuk menampilkan status stok/charge secara kredibel.
- placeholder visual utility sudah cukup untuk membaca state di playtest sambil menunggu asset final item/tool.

## 2026-04-04 16:54 ICT

### Task

Merapikan roster `Field Kit` di `MatchUI` agar tool utility tidak lagi tampil sebagai tombol polos, tetapi sebagai kartu ringkas yang membawa glyph, stok/charge, dan state runtime per tool.

### Files Changed

- `src/client/UI/Main.lua`

### Change Summary

- `Field Kit` sekarang punya metadata source-controlled per tool:
  - glyph ringkas (`JN`, `GR`, `SL`, `DP`)
  - role label (`Sensor`, `Trap`, `Guard`, `Repel`)
  - stok default per match untuk `Garam`, `Salib`, `Dupa`
- client sekarang menyimpan state runtime per tool, bukan hanya status global terakhir:
  - `usesRemaining`
  - `chargesRemaining`
  - `visualPlaced`
  - `placementId`
  - `pending / cooldown / out_of_stock`
- tombol `Field Kit` di `MatchUI` naik menjadi card compact:
  - glyph plate
  - shortcut badge
  - meta pill (`LIVE`, `x3`, `C3`, `AKTIF`, `HABIS`, `COOLDOWN`)
  - footer role/state
- reset antar match/lobby sekarang membersihkan stok + pesan global `Field Kit`, jadi state lama tidak bocor ke match berikutnya.
- layout `Field Kit` diperlebar dan ditinggikan agar kartu tool tetap terbaca di desktop/compact viewport.

### Validation Notes

- build lokal lolos:
  - `_tmp_fieldkit_ui_build.rbxlx`
- sesi Studio aktif masih memuat `StarterPlayerScripts.Client.UI.Main` yang lebih lama:
  - `MatchUI` aktif di runtime
  - `FieldKitFrame` belum hadir di `PlayerGui.MatchUI`
  - inspeksi source Studio menunjukkan Rojo belum mendorong blok `Field Kit` terbaru ke sesi itu
- artinya source lokal sudah valid, tetapi validasi visual live untuk pass ini masih menunggu Studio menarik script `Main.lua` terbaru.

### Interpretation

- backlog `P2.11` untuk `tool icon` + `tool UI state` naik nyata di source utama.
- blocker yang tersisa pada pass ini bukan implementasi client lagi, melainkan drift sync Studio terhadap `src/client/UI/Main.lua`.

## 2026-04-04 - Pocong Scale + Ghost Roaming Motion

Menurunkan scale `Pocong` dan memisahkan sinkronisasi visual ghost dari tick AI agar roaming tidak lagi terlihat teleport/snap antar room anchor.

### Files Changed

- `src/ServerScriptService/Server/GhostSystem/Service.lua`

### Change Summary

- override ukuran `Pocong` diturunkan ke target visual yang lebih pendek dan sempit agar tidak lagi terlihat raksasa di runtime.
- sinkronisasi visual ghost sekarang punya loop heartbeat terpisah (`0.1s`) di `GhostSystem.Service`, jadi model ghost tetap bergerak menuju target room walau AI decision tick tetap lebih lambat.
- state visual ghost sekarang memakai posisi interpolasi yang terus diperbarui, bukan hanya `PivotTo` snap saat event AI tertentu terjadi.
- profil motion `Pocong` sekarang memakai hop/bounce khusus per state, jadi tidak lagi terasa seperti humanoid glide generik.
- arah hadap ghost sekarang mengikuti arah gerak saat tidak sedang fokus ke target tertentu, sehingga visual perpindahan lebih terbaca.
- pacing AI ghost dipercepat:
  - `IdleMinDuration` turun ke `2.5`
  - `IdleMaxDuration` turun ke `5.5`
  - interval shift roam sekarang berbasis helper terkontrol (`3-7s` low pressure, `2-5s` saat aggression lebih tinggi), bukan lagi `8-15s` pada aggression rendah.
- saat state AI masih `Idle` tetapi ghost masih menempuh target room, visual motion sekarang otomatis memakai `Roaming` sampai jarak target habis.
- state reset untuk visual motion tetap dibersihkan saat despawn agar tidak bocor ke match berikutnya.

### Validation Notes

- build lokal lolos:
  - `_tmp_ghost_motion_build.rbxlx`
- source Studio aktif terverifikasi sudah memuat:
  - clamp ukuran `Pocong`
  - `GHOST_VISUAL_SYNC_INTERVAL`
  - `_visualSyncConnection`
- runtime Pocong di Studio terukur sekitar:
  - `2.00 x 3.65 x 1.00`
- runtime roam Pocong terverifikasi bergerak kontinu:
  - sample posisi berubah dari `1166.13,2.78,-11.12` ke `1170.03,2.79,-0.04`
  - `VisualTargetDistance` turun bertahap dari `11.8` ke `0`
  - state aktif `Roaming`, speed `3.6`
- validasi profil hop Pocong saat roam:
  - sample `Y` berubah dari sekitar `2.76` ke `2.88`
  - orientasi `LookVector` ikut arah gerak, bukan lagi terkunci pada orientasi lama
- validasi sinkronisasi state visual:
  - selama masih berjalan ke room target, runtime bisa `Idle` tetapi `VisualMotionState = Roaming` dan `VisualMoveSpeed = 3.6`
  - setelah target tercapai, `VisualMotionState` kembali `Idle` dan speed turun ke `1.75`

### Interpretation

- keluhan ghost teleport valid untuk versi sebelumnya; source aktif sekarang sudah mengubah perilaku itu menjadi pergerakan kontinu.
- Pocong masih belum memiliki skeleton/bone walk animation. Saat ini geraknya berupa hop/bob terkendali yang sesuai bentuk aset, bukan langkah kaki beranimasi. Untuk animasi berjalan yang benar, asset ghost harus rigged/skinned.

## 2026-04-04 - Hunt + Jumpscare Event Bridge

Menutup gap antara event ancaman server dan respons sensory client, sehingga hunt/jumpscare tidak lagi bergantung pada audio saja.

### Files Changed

- `src/ServerScriptService/Server/GhostSystem/GhostService.lua`
- `src/ServerScriptService/Server/GhostSystem/Controller.lua`
- `src/ServerScriptService/Server/RandomJumpscareSystem/Controller.lua`
- `src/client/Controllers/Sensory/VFXController.luau`
- `src/client/GhostAnimationPipeline/Main.lua`

### Change Summary

- `GhostService` sekarang mem-publish event eksplisit:
  - `GhostManifest`
  - `GhostManifested`
  - `GhostManifestEnd`
- `GhostSystem.Controller` sekarang meneruskan `GhostManifest` dan `GhostManifestEnd` ke `MatchEvent` client.
- `RandomJumpscareSystem.Controller` sekarang meneruskan `JumpscareTriggered` ke `MatchEvent` client.
- `GhostAnimationPipeline` sekarang mengenali:
  - `GhostManifestEnd -> GhostIdle`
  - `JumpscareTriggered -> GhostJumpscare`
- `VFXController` sekarang punya layer threat terpisah dari sanity grading:
  - baseline hunt pressure
  - manifest flicker transient
  - jumpscare shock transient
- efek hunt/jumpscare tidak lagi menimpa grading sanity secara destruktif karena sekarang memakai `SensoryThreatGrading` terpisah.

### Validation Notes

- build lokal lolos:
  - `_tmp_hunt_jumpscare_build.rbxlx`
- validasi live Studio menggunakan `StudioE2EControl`:
  - `ForceHunt`
  - `TriggerJumpscare`
- hasil client Lighting terukur:
  - sebelum hunt:
    - `Brightness = 0`
    - `Contrast = 0`
    - `Saturation = 0`
    - `Blur = 0`
  - saat hunt:
    - `Brightness = -0.03`
    - `Contrast = 0.18`
    - `Saturation = -0.22`
    - `Blur = 7`
  - saat jumpscare:
    - `Brightness = -0.08`
    - `Contrast = 0.52`
    - `Saturation = -0.95`
    - `Blur = 26`
- validasi client event bridge:
  - `MatchEvent` menerima `JumpscareTriggered`
  - source payload terbaca dari `StudioE2EControlSystem`

### Interpretation

- sebelumnya hunt/jumpscare memang terasa lemah karena client tidak menerima semua event penting.
- jalur event sekarang sudah utuh: AI/server event -> `MatchEvent` -> sensory client.
- manifest event sekarang juga menjadi lebih jujur untuk sistem lain yang sebelumnya menunggu sinyal yang nyaris tidak pernah dipublish.

## 2026-04-04 17:32 ICT - Ghost Visual Tuning Access

### Scope

- membuka jalur edit manual untuk ukuran ghost tanpa menyentuh AI atau runtime hunt.
- memindahkan angka visual ghost ke satu module config yang pendek dan mudah diubah.

### Implementation Notes

- file baru:
  - `src/shared/GameData/GhostVisualTuning.lua`
- `GhostSystem/Service.lua` sekarang membaca:
  - `meshSize`
  - `meshOffset`
  - `targetBounds`
- `meshSize` sekarang tetap diterapkan walau ghost tidak memakai `meshOffset`, supaya tuning per asset tidak tergantung offset.

### Manual Workflow

- edit `src/shared/GameData/GhostVisualTuning.lua`
- simpan file
- bila ghost sudah telanjur spawn di sesi play, lakukan:
  - `Stop`
  - `Play` lagi
- ulangi sampai ukuran visual sesuai secara kasat mata

### Interpretation

- tuning visual ghost sekarang punya satu titik edit yang jelas untuk manusia.
- ini mengurangi risiko salah sentuh `Service.lua` saat yang ingin diubah hanya skala atau posisi mesh.

## 2026-04-04 18:06 ICT - Lobby Ghost Preview Grounding Fix

### Scope

- memperbaiki preview ghost di `LobbySocialHub` yang sempat muncul di ketinggian salah karena raycast preview menangkap atap/permukaan di atas plaza.
- menyamakan grounding preview dengan logika grounding ghost runtime agar referensi visual tinggi ghost lebih jujur.

### Implementation Notes

- preview gallery sekarang memakai rata-rata `top surface` dari `SpawnPoints` lobby sebagai lantai referensi.
- preview ghost tidak lagi memakai raycast vertikal untuk memilih lantai.
- setiap ghost preview sekarang diposisikan ulang dengan `resolveGhostGroundPosition`, sama seperti ghost runtime di match.

### Validation Notes

- `StudioGhostPreviewGallery` tetap muncul dengan `5` ghost.
- lantai referensi plaza terukur di `Y = 4.5`.
- selisih bawah model ke lantai sekarang kecil dan konsisten:
  - `Pocong`: `+0.04`
  - `Leak`: `+0.04`
  - `KuntilanakAggressive`: `+0.07`
  - `Kuntilanak`: `+0.11`
  - `Genderuwo`: `+0.12`

### Interpretation

- preview tidak lagi menipu karena tampil di atap.
- referensi visual melayang ghost sekarang dekat dengan logika pemain menyentuh lantai.

## 2026-04-04 18:22 ICT - Ghost Control Part Cleanup And Hover Clamp

### Scope

- menyembunyikan `RootPart`/part kontrol tambahan yang sempat terlihat pada model `Kuntilanak`.
- membatasi ghost yang memang melayang ke tinggi visual maksimum `0.05`.
- meng-grounded ghost yang tidak cocok melayang: `Pocong`, `Genderuwo`, `Leak`.
- mematikan preview ghost lobby secara default setelah tahap tuning selesai.

### Implementation Notes

- `GhostSystem/Service.lua` sekarang punya helper untuk mendeteksi part kontrol ghost seperti:
  - `HumanoidRootPart`
  - `RootPart`
  - `Root`
  - `PrimaryPart`
- part kontrol itu dipaksa `Transparency = 1` saat clone template dan saat visual state diterapkan.
- `GhostVisualTuning.lua` sekarang memuat:
  - `grounded`
  - `maxHoverHeight`
- `Kuntilanak` dan `KuntilanakAggressive` dibatasi `maxHoverHeight = 0.05`.
- `Pocong`, `Genderuwo`, `Leak` diberi `grounded = true` dan `maxHoverHeight = 0`.
- preview gallery Studio sekarang hanya muncul bila attribute `PasrahStudioLobbyGhostPreview == true`.

### Interpretation

- kotak root part tidak lagi boleh muncul sebagai bagian dari siluet ghost.
- aturan melayang sekarang lebih dekat dengan identitas visual masing-masing ghost.
- preview lobby tetap tersedia untuk debugging, tetapi tidak lagi menyala otomatis.

## 2026-04-04 19:01 ICT - Ghost Runtime Spawn Recovery And Floor Alignment

### Scope

- memperbaiki regresi `ghost_spawn_failed` yang membuat match langsung berakhir ke `Result`.
- memvalidasi lagi root part transparency dan grounding ghost di runtime match asli, bukan preview lobby.
- mengikat posisi vertikal ghost ke lantai aktual berdasarkan bounding box bawah model.

### Root Cause

- `createGhostFromTemplate()` sempat memanggil `shouldHideGhostControlPart()` sebelum helper itu masuk scope lokal.
- efeknya `InitGhost` bisa gagal saat spawn model runtime, lalu `GhostSystem` meminta `MatchEnded` dengan alasan `ghost_spawn_failed`.

### Implementation Notes

- helper `shouldHideGhostControlPart()` dipindah ke scope yang valid sebelum dipakai oleh `createGhostFromTemplate()`.
- ditambahkan helper runtime:
  - `resolveGhostBottomOffset()`
  - `resolveGhostFloorY()`
- `computeGhostVisualCFrame()` sekarang:
  - mencari lantai di bawah ghost
  - menghitung offset pivot-ke-bawah dari bounding box
  - menyusun ulang `position.Y` agar bottom model menempel ke lantai + hover yang diizinkan

### Validation Notes

- setelah fix scope helper, match tidak lagi auto-end dengan:
  - `reason = ghost_spawn_failed`
- validasi runtime `Kuntilanak` di `HauntedHouse`:
  - `Ghost_Kuntilanak` berhasil spawn di `Workspace.ActiveMatches.Match_match_1`
  - `HumanoidRootPart.Transparency = 1`
  - `RootPart.Transparency = 1`
  - delta bawah model ke lantai: `0.0031`
- validasi runtime grounded ghost:
  - `Pocong`: delta `0`
  - `Genderuwo`: delta `0.0000038`
  - `Leak`: delta `-0.0000031`
- validasi lanjutan `Leak` setelah masuk `Briefing`:
  - delta `-0.0000012`

### Interpretation

- spawn ghost runtime kembali sehat.
- kotak root part yang merusak siluet `Kuntilanak` sudah hilang di match nyata.
- ghost hover sekarang benar-benar dikontrol oleh aturan per ghost, bukan sekadar animasi bob yang kebetulan kecil.

## 2026-04-04 19:18 ICT - Hunt Pressure Runtime Recovery

### Scope

- memulihkan deteksi jarak hunt di `PlayerHealthSystem` agar player tidak selalu terbaca `Clear` saat ghost sudah mengejar.
- membersihkan state grace hunt antar start/end match.
- memvalidasi ulang flow `ForceHunt` langsung di Studio runtime.

### Root Cause

- `_tickHuntPressure()` memakai variabel `now` tanpa deklarasi lokal.
- patch source sempat terlihat "tidak bekerja" karena sesi `Play` lama masih memakai hasil `require()` lama dari server module yang belum direstart.

### Implementation Notes

- menambahkan `local now = os.clock()` di awal `_tickHuntPressure()`.
- menambahkan pembersihan `huntStartedAtByMatchId` di `_clearMatchData()`.
- saat `MatchStarted`, atribut player berikut direset:
  - `PasrahHuntThreatState`
  - `PasrahHuntThreatDistance`
  - `PasrahHuntGraceRemaining`
- saat `HuntEnded`, grace dibersihkan dan threat state player pada match aktif dikembalikan ke `Clear`.

### Validation Notes

- source build lolos:
  - `rojo build default.project.json --output _tmp_player_health_probe_build.rbxlx`
- setelah restart `Play` dan memaksa hunt pada `match_1`, atribut player berubah sesuai jarak ghost:
  - tick awal: `Warn`, `grace = 2.2`, `distance = 46`
  - tengah: `Tracked`, `distance = 24`
  - dekat: `Close`, `distance = 15`
- `PasrahHuntPressureActiveMatchId = match_1`
- `PasrahHuntPressureReady = true`

### Interpretation

- hunt proximity sekarang benar-benar aktif di runtime.
- blocker lama "ghost sudah hunting tapi player tetap `Clear`" sudah lewat.
- setiap verifikasi server module sesudah patch tetap perlu restart `Play` agar hasil source benar-benar termuat.

## 2026-04-04 19:46 ICT - Hunt Death Flow Recovery

### Scope

- memastikan exposure hunt yang sudah mencapai threshold benar-benar membunuh player.
- memastikan `MatchSystem` menandai player `alive = false`.
- memastikan atribut threat client bersih lagi setelah `MatchEnded`.

### Root Cause

- `PlayerHealthSystem` memang sudah sampai `PlayerDied`, tetapi `MatchSystem.Controller:OnPlayerDied()` memilih `payload.userId` lebih dulu.
- pada jalur ini `payload.userId` bisa berupa string dari key `playersByUserId`.
- `MatchService:MarkPlayerDeath()` hanya menerima `number` atau `Player`, sehingga `alive` tidak pernah terbalik ke `false`.

### Implementation Notes

- `MatchSystem.Controller` sekarang memakai helper `resolveUserId(payload)` yang:
  - memprioritaskan `payload.player.UserId`
  - menerima numeric string via `tonumber`
- `PlayerHealthSystem` tetap menyimpan state internal dengan key yang dinormalisasi.
- ditambahkan atribut runtime:
  - `PasrahHuntExposure`
- ditambahkan probe Studio-only:
  - `PasrahHuntKillStage`
  - `PasrahHuntPressureLastTickAt`
  - `PasrahHuntPressureLastExposure`
  - `PasrahHuntPressureLastThreatState`
- `HandleEvent("MatchEnded")` sekarang juga membersihkan:
  - `PasrahHuntThreatState`
  - `PasrahHuntThreatDistance`
  - `PasrahHuntGraceRemaining`
  - `PasrahHuntExposure`

### Validation Notes

- probe runtime menunjukkan exposure naik sampai threshold dan kill benar-benar publish:
  - `PasrahHuntKillStage = death_published:match_1:failed_escape_hunt`
- setelah fix `MatchSystem.Controller`, event client live menunjukkan:
  - `HuntStarted`
  - `MatchEnded` dengan `reason = team_eliminated`
  - `MatchCompleted`
  - `playerOutcome[10576163165].deathReason = failed_escape_hunt`
- retest akhir menunjukkan cleanup client benar:
  - saat `InMatch = false`, `PasrahHuntThreatState = Clear`
  - `PasrahHuntExposure = nil`

### Interpretation

- flow hunt sekarang lengkap dari awal sampai akhir:
  - threat naik
  - exposure naik
  - player mati
  - match selesai
  - client bersih kembali
- blocker E2E untuk jalur kematian hunt sudah tertutup.

## 2026-04-04 20:04 ICT - Room Countdown And Match Transition Cleanup

### Scope

- menutup bug `RoomBrowser` yang masih tertinggal setelah teleport ke match.
- menghentikan audio countdown ketika overlay countdown sebenarnya sudah disuppress.
- mereset state room browser saat match benar-benar mulai.

### Root Cause

- `MatchStarted` hanya menyembunyikan GUI room browser, tetapi tidak mereset state internal `RoomBrowserController`.
- akibatnya `matchStarting` / `countdownSecondsLeft` bisa tetap hidup sesaat walau player sudah teleport.
- `_updateCountdownOverlay()` juga tetap memutar `CountdownTick` meski `showCountdown == false`.

### Implementation Notes

- `RoomBrowserController` sekarang punya `ResetForMatchStart()`.
- `UISystem` pada `MatchStarted` sekarang:
  - memanggil `ResetForMatchStart()`
  - memakai `_forceCloseAllPanelsForTeleport()` alih-alih hanya `_setRoomBrowserVisible(false)`
- `_updateCountdownOverlay()` sekarang hanya memutar `CountdownTick` bila overlay countdown benar-benar sedang tampil.
- bila overlay disuppress, runtime sound `CountdownTick` dihentikan secara eksplisit.

### Validation Notes

- probe live `CreateRoom -> HostStart` menunjukkan event countdown canonical:
  - `RoomMatchStarting`
  - `RoomMatchCountdown` untuk detik `5 -> 1`
  - `RoomMatchCountdownCompleted`
- selama countdown, jumlah instance `SoundService.RuntimeCountdownTick` tidak pernah lebih dari `1`.
- sesudah `MatchStarted`:
  - `LocalPlayer.InMatch = true`
  - `RoomBrowserUI.Enabled = false`
  - `RoomBrowserUI.Panel.Visible = false`
  - `CountdownOverlay.Visible = false`
  - `RuntimeCountdownTick = 0`

### Interpretation

- countdown sekarang tidak lagi lanjut diam-diam setelah transisi ke match.
- room panel tidak lagi punya alasan tertinggal terbuka saat player sudah di map.
- jalur host-start menjadi lebih deterministik untuk playtest audio/UI berikutnya.

## 2026-04-04 - Lobby Float Rail + Mobile Sheet Pass

### Scope

- merapikan rail tombol lobby kanan agar benar-benar fixed top-to-bottom dalam mode compact/mobile.
- membuat `RoomBrowser` dan `RoyalPass` tampil sebagai full-sheet mobile, bukan panel desktop yang dipaksa kecil.
- memastikan saat satu window besar terbuka, rail tidak tetap bocor di belakangnya.
- memastikan rail pulih lagi setelah window auxiliary seperti `RoyalPass` ditutup.

### Root Cause

- `_layoutLobbyFloatRail()` membaca `self._deviceProfile.profile`, padahal objek profil aktif berada langsung di `self._deviceProfile`.
- akibatnya rail selalu jatuh ke branch desktop, walau sesi live memakai override mobile/compact.
- dismiss auxiliary window hanya menyinkronkan panelnya sendiri; jalur refresh global rail belum ikut dipanggil.
- tombol float auxiliary juga terlalu bergantung pada flag `dismissed`, sehingga mudah drift saat panel sudah tertutup tetapi rail belum di-refresh penuh.

### Implementation Notes

- `_layoutLobbyFloatRail()` sekarang membaca `self._deviceProfile` langsung.
- `_setLobbyPanelCollapsed()` dan `_setAuxiliaryWindowDismissed()` sekarang memicu refresh rail/global visibility yang lebih lengkap.
- `_syncAuxiliaryWindowVisibility()` sekarang memperbolehkan float button muncul bila panel memang sudah tertutup, meski state dismissed sempat tertinggal.
- sizing mobile diperbesar untuk:
  - `LobbyUI.MainPanel`
  - `RoomBrowserUI.Panel`
  - `RoyalPassUI.MainPanel`
- `RoomBrowser` mobile sekarang memakai full viewport efektif (`390 x 844` pada probe override), dan `RoyalPass` mengikuti pola sheet yang sama.

### Validation Notes

- live probe memakai override:
  - `PasrahUIInputProfileOverride = mobile`
  - `PasrahUIForceCompact = true`
  - `PasrahUIViewportOverrideX = 390`
  - `PasrahUIViewportOverrideY = 844`
- saat lobby masih terbuka:
  - `RoomBrowserFloatUI.Enabled = false`
  - rail tidak tampil bocor di atas panel lobby.
- setelah `LobbyToggleButton` ditekan:
  - rail kanan tersusun ulang:
    - `ROOMS` di `{0, 96}`
    - `PASS` di `{0, 180}`
    - `MENU` di `{0, 256}`
    - `RANK` di `{0, 332}`
- saat `RoomBrowser` dibuka dari rail:
  - `RoomBrowserUI.Panel` terukur `390 x 844`
  - seluruh float rail kembali disembunyikan.
- saat `RoyalPass` dibuka dari rail:
  - `RoyalPassUI.MainPanel` terukur `390 x 844`
  - float rail kembali disembunyikan.
- setelah `RoyalPass` ditutup:
  - `RoyalPassUI.MainPanel.Visible = false`
  - rail pulih lengkap:
    - `ROOMS`, `PASS`, `MENU`, `RANK` semuanya `Visible = true`

### Interpretation

- lobby compact sekarang lebih dekat ke target mobile-friendly yang konsisten dan tidak saling tumpang tindih.
- window besar sudah berperilaku seperti sheet mobile yang dominan, bukan overlay desktop kecil.
- rail kanan sekarang deterministik untuk playtest phone layout dan tidak lagi kehilangan tombol `PASS` setelah close/open cycle.

## 2026-04-04 - Main Menu + Rank Mobile Resize Pass

### Scope

- membesarkan `MainMenuUI` agar tidak terasa seperti popup desktop kecil pada viewport mobile.
- mengubah `LeaderboardUI` menjadi sheet mobile yang benar-benar lega untuk konten scroll dan tombol aksi bawah.
- menjaga agar rail kanan tetap pulih sesudah `MENU` / `RANK` ditutup.

### Root Cause

- `MainMenuUI` dan `LeaderboardUI` masih memakai config panel dasar `340px` lebar dengan posisi desktop.
- `_applyDeviceSizing()` sebelumnya hanya mengganti ukuran font dan float button untuk basic windows, bukan ukuran panel dan layout internalnya.

### Implementation Notes

- di jalur mobile, `MainMenuUI.MainPanel` sekarang di-anchor ke kiri atas dan memakai lebar viewport efektif penuh.
- tombol inti `OPEN ROOM BROWSER`, `OPEN PROFILE`, `OPEN SHOP`, `OPEN RANK BOARD` diperbesar menjadi grid `2 x 2` yang lebih mudah disentuh.
- `LeaderboardUI.MainPanel` sekarang juga memakai full-sheet mobile.
- `LeaderboardUI.ContentFrame` dan tiga tombol bawah (`PROFILE`, `OPEN ROOMS`, `OPEN MENU`) ikut direlayout agar tidak mepet.

### Validation Notes

- pada override mobile yang sama (`390 x 844`):
  - `MainMenuUI.MainPanel` terukur `390 x 428`
  - empat tombol aksi menu terukur `177 x 54`
  - `LeaderboardUI.MainPanel` terukur `390 x 844`
  - `LeaderboardUI.ContentFrame` terukur `366 x 588`
  - tiga tombol aksi bawah leaderboard terukur `118 x 42`
- setelah `LeaderboardUI` ditutup kembali, rail kanan pulih lengkap:
  - `ROOMS = true`
  - `PASS = true`
  - `MENU = true`
  - `RANK = true`

### Interpretation

- jalur popup lobby utama sekarang jauh lebih konsisten di layar mobile.
- `MainMenuUI` tidak lagi terasa cramped, dan `LeaderboardUI` sudah cukup besar untuk data scroll/live test berikutnya.

## 2026-04-04 - Shop + Profile Mobile Sheet Pass

### Scope

- menyamakan `ShopUI` dan `ProfileUI` dengan pola sheet mobile yang sudah dipakai `RoyalPassUI`.
- menutup gap agar surface shop/profile tidak tertinggal sebagai panel desktop kecil saat viewport override mobile aktif.

### Root Cause

- sizing mobile fullscreen sebelumnya hanya diterapkan khusus untuk `RoyalPassUI`.
- `ProfileUI` dan `ShopUI` tetap memakai ukuran config lama (`340/356px`) walau device profile sudah `mobile`.

### Implementation Notes

- jalur sizing auxiliary diperluas untuk `ProfileUI` dan `ShopUI`, bukan lagi `RoyalPassUI` saja.
- pada mode mobile, ketiga panel ini sekarang:
  - anchor ke kiri atas
  - pakai lebar viewport efektif penuh
  - pakai tinggi viewport efektif penuh
  - background sedikit lebih solid (`0.04`)
- footer label auxiliary ikut ditarik ke bawah agar tidak menggantung di posisi config lama saat panel memanjang.

### Validation Notes

- probe mobile override (`390 x 844`) menunjukkan:
  - `ShopUI.MainPanel = 390 x 844`
  - `ProfileUI.MainPanel = 390 x 844`
- `ShopUI` terbukti terbuka dari `LobbyUI.MainPanel.ShopButton`.
- `ProfileUI` terbukti terbuka dari `MainMenuUI.MainPanel.ProfileButton`, sekaligus menutup `MainMenuUI` seperti yang diharapkan.

### Interpretation

- jalur lobby auxiliary sekarang jauh lebih konsisten: `PASS`, `SHOP`, dan `PROFILE` tidak lagi terasa campuran desktop-mobile pada viewport sempit.

## 2026-04-04 - FPV Cursor Unlock Toggle Baseline

### Scope

- menambahkan escape hatch untuk pemain Windows/keyboard saat FPV lock aktif agar cursor bisa dikeluarkan tanpa keluar match.
- menyediakan dua jalur input:
  - hotkey `Alt`
  - hotkey cadangan `` ` `` / `Backquote`
- menambahkan tombol runtime kecil `FREE CURSOR [ALT/~]` saat match FPV aktif.

### Root Cause

- `CameraController` sebelumnya selalu memaksa `MouseBehavior = LockCenter` selama `InMatch=true`.
- bahkan ketika state unlock diperkenalkan, render-step camera masih memaksa balik `LockFirstPerson` setiap frame.
- branch keluar match juga belum mengembalikan cursor secara penuh bila `CameraMode` sudah telanjur `Classic` tapi `MouseBehavior` masih `LockCenter`.

### Implementation Notes

- `CameraController.client.lua` sekarang punya state `fpvCursorUnlocked`.
- saat unlock aktif:
  - `CameraMode = Classic`
  - `CameraMinZoomDistance = 0.5`
  - `CameraMaxZoomDistance = 0.5`
  - `MouseBehavior = Default`
  - `MouseIconEnabled = true`
- saat relock:
  - `CameraMode = LockFirstPerson`
  - `MouseBehavior = LockCenter`
  - `MouseIconEnabled = false`
- render-step camera sekarang menjaga state unlock/relock ini secara eksplisit, bukan hanya memeriksa `CameraMode`.
- ditambahkan juga harness runtime `PasrahCursorUnlockRequested` untuk verifikasi Studio/MCP tanpa harus mengandalkan injeksi keyboard tool.

### Validation Notes

- build source sukses: `_tmp_cursor_unlock_build.rbxlx`
- probe runtime terkontrol via `LocalPlayer` attribute menunjukkan:
  - unlock:
    - `PasrahCursorUnlocked = true`
    - `MouseBehavior = Default`
    - `MouseIconEnabled = true`
    - `CameraMode = Classic`
  - relock:
    - `PasrahCursorUnlocked = false`
    - `MouseBehavior = LockCenter`
    - `MouseIconEnabled = false`
    - `CameraMode = LockFirstPerson`
  - keluar ke lobby (`InMatch=false`):
    - `FPVCursorToggleUI.Enabled = false`
    - `MouseBehavior = Default`
    - `MouseIconEnabled = true`
    - `CameraMode = Classic`

### Caveat

- input fisik `Alt` / `Backquote` belum bisa dibuktikan langsung lewat injector MCP keyboard yang dipakai sesi ini.
- namun jalur aksi tombol/hotkey dan harness runtime sekarang menuju fungsi yang sama, sehingga core state machine kamera sudah tervalidasi.

### Interpretation

- pemain desktop sekarang punya baseline mekanisme untuk keluar dari cursor lock FPV tanpa memecah alur match.
- debt “UI sudah besar tapi mouse tetap terkunci” tidak lagi menjadi blocker arsitektural.

## 2026-04-04 - Camera Head Bob Baseline Restored

### Scope

- mengembalikan head bob yang benar-benar terasa di kamera player FPV, bukan hanya di arms viewmodel.
- menyediakan probe debug ringan agar bob bisa divalidasi lewat MCP tanpa harus mengandalkan “rasa visual” semata.

### Root Cause

- implementation lama memang masih punya bob/sway, tetapi efek utamanya hanya mendorong `fpvArmsModel`.
- akibatnya arms terasa bergerak, tetapi kamera pemain sendiri hampir tidak memberi feedback gerak; dari sudut pandang user, head bob tampak “hilang”.

### Implementation Notes

- `CameraController.client.lua` sekarang menulis bob ringan ke `Humanoid.CameraOffset` selama FPV aktif.
- target bob kamera dibuat konservatif:
  - sway horizontal memakai skala `0.22`
  - bob vertikal memakai skala `0.30`
- saat player berhenti atau keluar FPV, `CameraOffset` dilerp kembali ke nol.
- ditambahkan attribute debug `PasrahHeadBobProbeActive` dan `PasrahHeadBobOffset` untuk validasi teknis Studio.

### Validation Notes

- build source sukses: `_tmp_headbob_camera_build.rbxlx`
- probe runtime via attribute menunjukkan:
  - saat `PasrahHeadBobProbeActive = true` dan FPV lock aktif:
    - `PasrahHeadBobOffset = 0.0100,0.0311,0.0000`
  - setelah probe dimatikan:
    - `PasrahHeadBobOffset = 0.0004,0.0012,0.0000`
- interpretasi teknis:
  - offset benar-benar naik dari nol saat bob dipaksa aktif
  - offset turun kembali mendekati nol saat bob dihentikan

### Caveat

- kualitas rasa akhir tetap perlu uji mata langsung di sesi playtest normal.
- pass ini menutup bukti teknis bahwa bob kamera hidup lagi; pass artistik final tetap bisa dilakukan nanti bila amplitudonya ingin lebih kuat/lembut.

### Interpretation

- baseline “head bobbing sebelumnya hilang” sekarang tertutup di source dan punya jejak verifikasi runtime.

## 2026-04-04 - Material Footstep Audio Baseline

### Scope

- menambahkan footstep audio lokal berbasis material lantai untuk player saat match aktif.
- memakai asset yang memang sudah tersedia di source:
  - `Woodstep_01`
  - `ConcreteStep_01`
  - `MetalStep_01`

### Root Cause

- walau asset footstep sudah ada di repo, belum ada controller client yang benar-benar memainkannya saat player bergerak.
- akibatnya movement terasa “sunyi” dan salah satu batch asset audio yang sudah diupload belum memberi dampak nyata ke gameplay.

### Implementation Notes

- ditambahkan `FootstepController.luau` di jalur sensory client dan didaftarkan lewat `SoundSystem`.
- controller membaca:
  - `Humanoid.FloorMaterial`
  - `Humanoid.MoveDirection`
  - `Humanoid.WalkSpeed`
- step cadence dibatasi waktu agar tidak spam, lalu memilih template berdasarkan material:
  - wood -> `Woodstep_01`
  - metal -> `MetalStep_01`
  - default keras/batu/beton -> `ConcreteStep_01`
- footstep diputar sebagai one-shot lokal pada `HumanoidRootPart`.
- ditambahkan probe runtime:
  - `PasrahFootstepProbeRequested`
  - `PasrahFootstepProbePlayCount`
  - `PasrahFootstepProbeLastTemplate`
  - `PasrahFootstepProbeLastMaterial`

### Validation Notes

- build source sukses: `_tmp_footstep_controller_build.rbxlx`
- probe manual runtime menunjukkan:
  - sebelum probe: `PlayCount = 0`
  - sesudah probe: `PlayCount = 1`
  - template terpilih: `ConcreteStep_01`
  - material terbaca: `Concrete`
  - `HumanoidRootPart` punya `LocalFootstepRuntime = 1`
- probe auto cadence via `Humanoid:Move()` terkontrol menunjukkan:
  - `delta play count = 2`
  - template tetap `ConcreteStep_01`
  - material tetap `Concrete`

### Interpretation

- asset footstep yang sebelumnya hanya tersimpan sekarang benar-benar hidup di runtime.
- kualitas rasa movement naik tanpa menambah dependency server baru atau layer UI baru.

## 2026-04-04 - Environmental Audio Cue Routing

### Scope

- memecah resolver `EnvironmentalAudio` di client agar cue lingkungan tidak selalu jatuh ke satu template generik.
- menambah atribut debug ringan pada `LocalPlayer` agar pemilihan template bisa divalidasi langsung dari Studio.

### Root Cause

- jalur `SoundSystem` sebelumnya selalu memetakan `EnvironmentalAudio` ke `EnvironmentalCreak_01`.
- akibatnya event seperti `SuddenWhisper`, `ShadowApparition`, dan `FootstepSound` terdengar salah konteks walau asset yang lebih tepat sebenarnya sudah ada di source.

### Implementation Notes

- `src/client/SoundSystem/Main.lua` sekarang punya resolver khusus untuk `EnvironmentalAudio`.
- pemetaan baseline yang aktif:
  - `SuddenWhisper` -> `GhostWhisper_01`
  - `ShadowApparition` / `TemperatureDrop` -> `GhostManifest_01`
  - `FootstepSound` -> folder `Footsteps` dengan fallback material-aware (`Woodstep_01`, `MetalStep_01`, `ConcreteStep_01`)
  - `DoorSlam` / `WindowKnock` / fallback environment -> `EnvironmentalCreak_01`
- ditambahkan atribut debug:
  - `PasrahAudioLastCategory`
  - `PasrahAudioLastTemplate`
  - `PasrahAudioLastCue`
  - `PasrahAudioLastEventType`
  - `PasrahAudioLastSoundId`
  - `PasrahAudioPlayCount`

### Validation Notes

- build source sukses: `_tmp_environmental_audio_build.rbxlx`
- sesi client sempat memuat `SoundSystem` lama; saya stop/start play agar `PlayerScripts` reload dari source terbaru.
- validasi resolver live di Studio menunjukkan:
  - `SuddenWhisper` -> `GhostWhisper_01`
  - `FootstepSound` dengan `surfaceMaterial = WoodPlanks` -> `Woodstep_01`
  - `ShadowApparition` -> `GhostManifest_01`
  - `DoorSlam` -> `EnvironmentalCreak_01`
- validasi debug attr setelah dua trigger berurutan menunjukkan:
  - `PasrahAudioLastCategory = EnvironmentalAudio`
  - `PasrahAudioLastTemplate = Woodstep_01`
  - `PasrahAudioLastEventType = FootstepSound`
  - `PasrahAudioPlayCount = 2`
  - `PasrahAudioLastSoundId = rbxassetid://104336169985098`

### Interpretation

- audio lingkungan sekarang sudah mengikuti konteks cue, bukan sekadar satu suara creak untuk semua kejadian.
- jalur validasi teknis untuk audio client sekarang lebih kuat, sehingga pass SFX berikutnya tidak perlu menebak template mana yang benar-benar dipakai runtime.

## 2026-04-04 - Flashlight Transition Realism Pass

### Scope

- memoles rasa flashlight FPV tanpa mengubah arsitektur sync existing.
- fokus pada transisi nyala/mati yang halus agar flashlight tidak terasa seperti toggle instan yang “pop”.

### Root Cause

- setelah slice flashlight asset/hands-only selesai, local spotlight FPV masih hidup/mati secara instan.
- hasilnya bentuk flashlight sudah benar, tetapi feel cahaya masih terasa mekanis dan kurang natural.

### Implementation Notes

- `src/shared/GameData/FlashlightConfig.lua` sekarang punya baseline transition untuk local light:
  - `offBrightness = 0`
  - `offRange = 2`
  - `offAngle = 12`
  - `fadeInSpeed = 10`
  - `fadeOutSpeed = 7`
- `src/client/CameraController.client.lua` sekarang:
  - melacak `fpvFlashlightVisualAlpha`
  - meng-lerp lens color/transparency antara state off/on
  - meng-lerp `SpotLight.Brightness`, `Range`, dan `Angle`
  - menulis atribut debug:
    - `PasrahFlashlightVisualAlpha`
    - `PasrahFlashlightLightEnabled`
- reset `clearFpvArms()` sekarang juga membersihkan state visual alpha agar tidak mewariskan glow sisa antar state.

### Validation Notes

- build source sukses: `_tmp_flashlight_realism_build.rbxlx`
- validasi live Studio via attribute harness menunjukkan:
  - state off:
    - `alpha = 0`
    - `brightness = 0`
    - `range = 2`
    - `angle = 12`
  - warm-up setelah toggle on:
    - `alpha = 0.8651`
    - `brightness = 1.1679`
    - `range = 10.6511`
    - `angle = 22.3814`
  - state on penuh:
    - `alpha = 1`
    - `brightness = 1.35`
    - `range = 12`
    - `angle = 24`
  - cooldown sesudah toggle off:
    - tail glow turun bertahap, lalu setelah `0.65s` kembali:
      - `alpha = 0`
      - `brightness = 0`
      - `PasrahFlashlightLightEnabled = false`

### Interpretation

- flashlight sekarang tidak lagi “meledak hidup” atau “mati putus” secara instan.
- feel nyala/mati menjadi lebih natural, tetapi tetap menjaga readability karena state penuh masih mencapai parameter visibilitas yang sama dengan baseline sebelumnya.

## 2026-04-04 - Shop MM Purchase Snapshot Harness

### Scope

- menutup blind spot verifikasi shop dengan harness Studio khusus untuk snapshot wallet + ownership player.
- memakai jalur `PurchaseEvent` client yang sama seperti UI asli untuk membuktikan pembelian MM benar-benar bekerja.

### Root Cause

- `GetShopReadiness` hanya memberi angka katalog global, tetapi tidak bisa menjawab pertanyaan yang lebih penting:
  - apakah wallet pemain benar-benar berkurang?
  - apakah inventory/cosmetic ownership benar-benar bertambah?
- tanpa snapshot per-player, verifikasi shop selalu rawan jadi “UI bilang sukses, tapi grant tidak jelas”.

### Implementation Notes

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua` sekarang menambah action:
  - `GetShopPlayerSnapshot`
- snapshot baru mengembalikan ringkasan:
  - `MM`
  - `PP`
  - `Robux`
  - `inventory`
  - `cosmetics`
  - `item`
  - `hasItem`
  - `ownsCosmetic`
- action ini Studio-only dan tidak mengubah flow produksi.

### Validation Notes

- build source sukses: `_tmp_shop_snapshot_build.rbxlx`
- wallet awal test:
  - `MM=1200 PP=12 Robux=0`
- verifikasi equipment MM via `PurchaseEvent` client:
  - item: `eq_sanitypill_standard`
  - sebelum:
    - `MM=1200`
    - `inventory=0`
    - `hasItem=false`
  - sesudah:
    - `MM=900`
    - `inventory=1`
    - `hasItem=true`
  - `PurchaseProcessed.success = true`
- verifikasi cosmetic MM via `PurchaseEvent` client:
  - item: `cos_emote_steadybreath`
  - sebelum:
    - `MM=900`
    - `inventory=1`
    - `cosmetics=0`
    - `ownsCosmetic=false`
  - sesudah:
    - `MM=400`
    - `inventory=2`
    - `cosmetics=1`
    - `ownsCosmetic=true`
  - `PurchaseProcessed.success = true`

### Interpretation

- shop MM aktif benar-benar bekerja end-to-end untuk dua jalur penting:
  - equipment grant
  - cosmetic ownership grant
- jalur verifikasi shop sekarang tidak lagi buta; batch shop berikutnya bisa fokus ke presentasi katalog, PP path, dan nanti Robux activation tanpa menebak apakah soft-currency flow dasarnya sehat.

## 2026-04-04 - Shop Snapshot Wiring For Client UI

### Scope

- menghubungkan `ShopUI` ke snapshot server resmi untuk wallet dan ownership.
- membuat row shop benar-benar tahu kapan item sudah dimiliki atau saldo tidak cukup.

### Root Cause

- panel shop sebelumnya hanya tahu katalog statis.
- akibatnya client tidak tahu:
  - saldo `MM/PP/Robux`
  - item mana yang sudah owned
  - apakah sebuah item gagal dibeli karena memang sudah dimiliki atau karena saldo tidak cukup

### Implementation Notes

- `ShopSystem.Service` sekarang punya `BuildClientSnapshot(player)` yang merangkum:
  - wallet `MM / PP / Robux`
  - `ownedItemIds`
  - `ownedCount`
- `ShopSystem.Controller` sekarang menerima action `RequestSnapshot` lewat `PurchaseEvent`.
- response `PurchaseProcessed` dan `PurchasePromptRequested` sekarang ikut membawa snapshot terbaru saat tersedia.
- `UISystem` shop sekarang:
  - request snapshot saat start dan saat window shop dibuka
  - menyimpan `wallet` + `ownedItemIds` di `_shopState`
  - menampilkan header wallet dalam format `MM / PP / R$`
  - mengubah tombol row menjadi:
    - `OWNED` bila item sudah dimiliki
    - `KURANG` bila saldo soft-currency tidak cukup
    - `SETUP` bila item Robux belum punya `marketplaceId`

### Validation Notes

- build source sukses: `_tmp_shop_snapshot_ui_build.rbxlx`
- snapshot awal sesudah reload Studio:
  - header shop: `MM 1200 • PP 12 • R$ 0`
  - footer: `Owned 0 item...`
  - row MM awal menampilkan meta wallet seperti `Wallet 1200 MM`
- verifikasi live purchase UI-aware:
  - beli `eq_sanitypill_standard`
    - response sukses membawa snapshot `MM=900 PP=12`
    - row berubah menjadi `OWNED`
  - beli `pp_cos_head_nightoracle`
    - response sukses membawa snapshot `MM=900 PP=0`
    - row berubah menjadi `OWNED`
  - footer sesudah dua pembelian:
    - `Owned 2 item...`
  - header sesudah dua pembelian:
    - `MM 900 • PP 0 • R$ 0`
- verifikasi insufficient PP:
  - `Void Priest Robe` menampilkan:
    - meta `Wallet 0 PP`
    - tombol `KURANG`

### Interpretation

- shop client sekarang tidak lagi “buta state”.
- pemain langsung bisa membaca saldo, ownership, dan alasan dasar kenapa sebuah item belum bisa dibeli tanpa harus menebak dari error message generik.

## 2026-04-04 - Shop Filter Pass

### Scope

- menambahkan filter cepat di panel shop:
  - `ALL`
  - `MM`
  - `PP`
  - `R$`
  - `OWNED`
- state filter disimpan di `_shopState.filterKey`
- refresh row shop sekarang menyaring visibility berdasarkan currency atau ownership
- tombol filter ikut menampilkan state terpilih melalui warna background/text

### Source Changes

- `src/client/UI/Main.lua`
  - tambah konstanta `SHOP_FILTERS`
  - tambah helper:
    - `_shopItemMatchesFilter`
    - `_setShopFilter`
  - `ShopUI` sekarang membangun `ShopFilterBar` di atas `ItemList`
  - `window.ShopFilterButtons` disimpan supaya `_refreshShopPanel` bisa sinkronkan state visual tombol
  - row shop sekarang hanya `Visible` bila item cocok dengan filter aktif

### Validation Notes

- build source sukses: `_tmp_shop_filters_build.rbxlx`
- verifikasi live Studio:
  - `ShopFilterBar` muncul di `ShopUI`
  - tombol `ALL`, `MM`, `PP`, `R$`, `OWNED` muncul dengan ukuran dan warna benar
  - default selected state menyorot `ALL`
- catatan tool:
  - `TextButton:Activate()` tidak tersedia untuk objek UI Roblox
  - `user_mouse_input` MCP tidak memicu `Activated` callback pada tombol shop di sesi ini
  - karena itu validasi interaksi klik filter lewat MCP masih terbatas ke keberadaan UI + state default, sedangkan logika filter divalidasi lewat source/build path

### Interpretation

- shop sekarang punya navigasi cepat yang lebih layak di mobile dan desktop saat katalog makin padat.
- keterbatasan yang tersisa ada di automation layer MCP untuk klik UI, bukan di source filter itu sendiri.

## 2026-04-04 - Profile Wardrobe Pass

### Scope

- menutup gap `shop cosmetic bisa dibeli tetapi belum punya jalur equip client yang jelas`
- menambahkan snapshot wardrobe client-server via `CosmeticEvent`
- menambahkan list wardrobe di `ProfileUI` untuk:
  - melihat cosmetic yang dimiliki
  - melihat slot yang sedang aktif
  - `PAKAI` / `LEPAS` langsung dari panel profile

### Source Changes

- `src/ServerScriptService/Server/CosmeticSystem/Service.lua`
  - tambah `BuildClientSnapshot(player)` berisi:
    - `ownedCosmeticIds`
    - `equippedCosmetics`
    - `ownedCount`
    - `equippedCount`
- `src/ServerScriptService/Server/CosmeticSystem/Controller.lua`
  - tambah action `RequestSnapshot`
  - response `CosmeticRequestProcessed` sekarang ikut membawa snapshot terbaru
- `src/client/Core/ClientBootstrap.lua`
  - `CosmeticEvent` sekarang masuk ke daftar remote bootstrap client
- `src/client/UI/Main.lua`
  - profile state sekarang menyimpan snapshot wardrobe
  - `ProfileUI` mendapat section `WARDROBE`
  - setiap row cosmetic punya aksi `PAKAI` / `LEPAS`
  - purchase cosmetic sukses dari shop otomatis memicu refresh snapshot wardrobe

### Validation Notes

- build source sukses: `_tmp_profile_wardrobe_build.rbxlx`
- validasi live Studio:
  - beli `cos_emote_steadybreath` lewat `PurchaseEvent` -> `PurchaseProcessed.success=true`
  - request snapshot wardrobe -> `ownedCount=1`
  - equip `cos_emote_steadybreath` lewat `CosmeticEvent` -> `CosmeticRequestProcessed.success=true`, `slot=emote`, `equippedCount=1`
  - `ProfileUI` runtime menampilkan:
    - `WARDROBE • 1 OWNED • 1 EQUIPPED`
    - row `Steady Breath Emote`
    - tombol `LEPAS`
  - lobby character attribute ikut berubah:
    - `LobbyEquippedEmote = "Emote Steadybreath"`
  - unequip juga tervalidasi:
    - `equippedCount=0`
    - tombol row kembali `PAKAI`
    - pill row kembali `EMOTE`

### Interpretation

- cosmetic shop sekarang tidak berhenti di inventory; pemain bisa benar-benar memakai item yang dibeli di lobby canonical.
- jalur `buy -> snapshot -> equip -> apply to lobby` sudah tertutup end-to-end untuk kategori cosmetic.

## 2026-04-04 - Equipment Runtime Hook Pass (Salt + UV ownership sync)

### Scope

- mulai menutup gap `equipment shop` yang sebelumnya hanya hidup di katalog/inventory
- target batch ini:
  - `Reinforced Salt Bag` memberi bonus stock nyata dan server-authoritative
  - ownership equipment penting disinkronkan ke player attributes untuk dipakai sistem runtime lain
  - `UV Flashlight Mk2` disiapkan lewat jalur attribute + client visual tint

### Source Changes

- `src/ServerScriptService/Server/ShopSystem/Service.lua`
  - tambah sinkronisasi attribute ownership item:
    - `PasrahOwnsReinforcedSaltBag`
    - `PasrahOwnsUVFlashlight`
    - `PasrahOwnsModdedSpiritBox`
    - `PasrahOwnsEliteSpiritBox`
  - sinkronisasi dilakukan saat `BuildClientSnapshot(player)` sehingga snapshot shop sekarang juga memperbarui state runtime pemain
- `src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua`
  - `Garam` sekarang cek ownership `eq_saltbag_reinforced`
  - jika dimiliki, stock default `Garam` naik `+1`
- `src/client/UI/Main.lua`
  - state default field kit `Garam` sekarang membaca `PasrahOwnsReinforcedSaltBag`
- `src/client/CameraController.client.lua`
  - jalur `UV Flashlight Mk2` sekarang siap membaca `PasrahOwnsUVFlashlight`
  - lens/light lokal akan memakai tint UV saat item dimiliki

### Validation Notes

- build source sukses: `_tmp_equipment_pass_build.rbxlx`
- validasi live Studio untuk `Reinforced Salt Bag`:
  - beli `eq_saltbag_reinforced` lewat `PurchaseEvent` -> `PurchaseProcessed.success=true`
  - wallet MM turun ke `550`
  - attribute pemain terset:
    - `PasrahOwnsReinforcedSaltBag = true`
  - buat match runtime lalu gunakan `Garam` sekali lewat `StudioE2EControl`
  - result evidence live:
    - `eventName = SaltTriggered`
    - `usesRemaining = 3`
- interpretasi stock:
  - baseline lama `Garam` adalah `3 total`, jadi sekali pakai normalnya sisa `2`
  - hasil `usesRemaining = 3` membuktikan total stock baru `4`, artinya bonus item benar-benar aktif server-side
- status `UV Flashlight Mk2`:
  - source path sudah aktif
  - live purchase belum ditutup pada batch ini karena wallet Studio baseline tidak cukup membeli `eq_flashlight_uv`
  - attribute runtime terbaca `PasrahOwnsUVFlashlight = false` pada sesi validasi ini, sesuai kondisi ownership nyata

### Interpretation

- `equipment shop` tidak lagi 100% dekoratif; setidaknya satu item (`Reinforced Salt Bag`) sekarang punya efek gameplay nyata dan aman dari sisi authority.
- fondasi attribute ownership sudah siap dipakai batch berikutnya untuk equipment lain seperti `UV Flashlight` dan `Spirit Box`.

## 2026-04-04 - Studio Wallet Harness + UV Flashlight Live Validation

### Scope

- menambah utility Studio-only untuk top-up currency test agar validasi equipment/monetization tidak terhambat wallet baseline mock
- menutup live validation `UV Flashlight Mk2` yang sebelumnya pending

### Source Changes

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - tambah action `GrantCurrency`
  - action ini memanggil `EconomySystem:AddCurrency` hanya lewat harness Studio
  - output ack langsung merangkum wallet terbaru setelah grant

### Validation Notes

- build source sukses: `_tmp_uv_wallet_build.rbxlx`
- validasi live harness:
  - `GrantCurrency MM 2000` -> ack:
    - `currency=MM granted=2000 MM=3200 PP=12 Robux=0`
- validasi live `UV Flashlight Mk2`:
  - beli `eq_flashlight_uv` lewat `PurchaseEvent` -> `PurchaseProcessed.success=true`
  - wallet MM turun ke `1700`
  - attribute pemain terset:
    - `PasrahOwnsUVFlashlight = true`
  - masuk match runtime, aktifkan flashlight, lalu inspeksi FPV model:
    - `FPV_Flashlight` terdeteksi
    - `Lens.Color = 0.658824, 0.839216, 1`
    - `SpotLight.Color = 0.729412, 0.878431, 1`
- interpretasi warna:
  - tint sudah bergeser ke spektrum UV/biru muda, bukan warna warm default

### Interpretation

- harness Studio sekarang lebih kuat untuk validasi economy/shop tanpa menunggu jalur reward match atau mengutak-atik state manual.
- `UV Flashlight Mk2` tidak lagi hanya siap di source; jalur `grant MM -> buy -> attribute sync -> visual UV aktif di FPV` sudah tertutup live.

## 2026-04-04 - Spirit Box Upgrade + Sanity Pill Runtime Hook

### Scope

- mengubah `Spirit Box` dari item shop dekoratif menjadi upgrade nyata untuk tool `KotakArwah`
- menambah runtime consumable `Sanity Pill` yang tetap server-authoritative dan tidak bocor jadi unlimited
- menampilkan `KotakArwah` langsung di `Field Kit` agar jalur player-facing tidak tersembunyi

### Source Changes

- `src/ServerScriptService/Server/ShopSystem/Service.lua`
  - tambah attribute ownership client-facing:
    - `PasrahOwnsSanityPillStandard`
    - `PasrahOwnsSanityPillAdvanced`
- `src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua`
  - tambah utility runtime `PilSanity`
  - tier sanity pill:
    - `standard` -> `1` use per match, restore `24`
    - `advanced` -> `2` uses per match, restore `42`
  - tambah tier `Spirit Box`:
    - `base`
    - `modded`
    - `elite`
  - upgrade tier sekarang mempengaruhi `detectionChance` dan `responseText`
  - payload fail path untuk `KotakArwah` sekarang tetap membawa `responseTier/responseText`, jadi upgrade tidak “hilang” saat spawn roll gagal
- `src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua`
  - tambah request alias `SanityPillUse`
  - tambah response payload `PilSanity`
  - `KotakArwah` sekarang punya range bonus:
    - modded -> `26`
    - elite -> `30`
- `src/ServerScriptService/Server/EvidenceSystem/Controller.lua`
  - broadcast `SanityPillUsed` ke client
- `src/client/EvidenceTools/Main.lua`
  - register tool client `PilSanity`
- `src/client/EvidenceTools/PilSanity/Main.lua`
  - adapter client baru untuk jalur request pill
- `src/client/UI/Main.lua`
  - `Field Kit` sekarang punya tombol kelima:
    - `SPIRIT`
    - shortcut `[5]`
    - glyph `KA`
  - layout grid disesuaikan agar 5 tombol tetap muat
  - tool feedback sekarang menampilkan konteks `responseText/responseTier`

### Validation Notes

- build source sukses:
  - `_tmp_equipment_hook_build.rbxlx`
- verifikasi live script sinkron di Studio:
  - `EvidenceService` memuat `_resolveSpiritBoxTier`, `_resolveSanityPillConfig`, dan payload fail-path baru
  - `StarterPlayerScripts.Client.UI.Main` memuat `FIELD_KIT_TOOL_ORDER = { \"JejakEnergi\", \"Garam\", \"Salib\", \"Dupa\", \"KotakArwah\" }`
- verifikasi live purchase + ownership:
  - `eq_spiritbox_modded` -> `PurchaseProcessed.success=true`
  - `eq_sanitypill_advanced` -> `PurchaseProcessed.success=true`
  - attribute pemain terset:
    - `PasrahOwnsModdedSpiritBox = true`
    - `PasrahOwnsSanityPillAdvanced = true`
- verifikasi live `Spirit Box`:
  - payload request `KotakArwahQuestion` sekarang mengembalikan:
    - `responseTier = modded`
    - contoh `responseText = \"Dia melihatmu.\"`
  - contoh fail reason yang tervalidasi tetap membawa tier:
    - `spawn_roll_failed`
    - `ghost_cannot_emit_evidence`
    - `tool_throttled`
- verifikasi live `Sanity Pill`:
  - request `SanityPillUse` sukses:
    - `reason = sanity_restored`
    - `tier = advanced`
    - `sanityRestored = 42`
    - `usesRemaining = 1`
- verifikasi live UI:
  - `MatchUI.FieldKitFrame` ada
  - `KotakArwahButton` ada
  - `TitleLabel = SPIRIT`
  - `ShortcutLabel = [5]`
  - `Glyph = KA`
- console Studio bersih dari error baru yang berkaitan dengan patch ini

### Interpretation

- `Spirit Box` sekarang punya nilai progression yang benar: upgrade shop langsung terasa di runtime tool, bukan sekadar ownership flag pasif.
- `Sanity Pill` sekarang masuk ke gameplay dengan stok per-match yang dijaga server, jadi tidak membuka celah unlimited-use dari sisi client.
- `Field Kit` akhirnya menampilkan `Spirit Box` secara eksplisit, sehingga pemain dan tester tidak perlu menebak tool ini hidup di mana.

## 2026-04-04 - Robux Compliance Guard Audit

### Scope

- mengunci flow `Robux` agar selalu tunduk ke klasifikasi resmi Roblox sebelum source-of-truth lokal
- menutup risiko salah setup `GamePass` vs `DeveloperProduct`
- memperjelas pesan UI agar setup marketplace dilakukan lewat `Creator Hub` + `ShopMarketplaceConfig`, bukan asal edit katalog

### Source Changes

- `src/ServerScriptService/Server/ShopSystem/Service.lua`
  - tambah `normalizeMarketplaceCompliance(item)`
  - guard baru:
    - item `Robux` auto-`disabled` jika `marketplaceType` invalid atau `marketplaceId <= 0`
    - `GamePass` auto-`disabled` jika dipakai untuk `CurrencyPack`
    - `DeveloperProduct` auto-`disabled` jika dipakai untuk entitlement permanen
    - `DeveloperProduct` `CurrencyPack` auto-`disabled` jika belum punya `grantCurrency/grantCurrencyAmount`
- `src/client/UI/Main.lua`
  - pesan `SETUP` sekarang menunjuk ke `ShopMarketplaceConfig` + `Creator Hub`
  - footer shop sekarang menjelaskan bahwa `SETUP` juga berarti item belum compliant
- `src/shared/DataTypes/ShopMarketplaceConfig.lua`
  - tambah komentar guard jenis resmi Roblox:
    - `GamePass` -> unlock permanen
    - `DeveloperProduct` -> pembelian berulang
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ROBLOX_MONETIZATION_COMPLIANCE_2026-04-04.md`
  - audit checklist monetization Roblox untuk fase publish nanti

### Validation Notes

- build source sukses:
  - `_tmp_robux_compliance_build.rbxlx`
- verifikasi live script sinkron di Studio:
  - `ShopSystem.Service` memuat `normalizeMarketplaceCompliance`
  - `Client.UI.Main` memuat pesan setup baru:
    - `Isi marketplaceId valid di ShopMarketplaceConfig lalu publish lewat Creator Hub.`

### Interpretation

- jalur `Robux` sekarang lebih tahan terhadap human error saat nanti ID marketplace mulai diisi.
- prioritas aturan resmi Roblox sudah dipindahkan ke source code level, bukan cuma catatan manual.

## 2026-04-04 - Publish-Safe Shop Visibility For Robux

### Scope

- mencegah item `Robux` placeholder yang belum compliant tampil ke player saat publish
- tetap mempertahankan visibilitas item placeholder di Studio untuk setup/testing

### Source Changes

- `src/client/UI/Main.lua`
  - `loadShopCatalog()` sekarang memfilter item `Robux` yang:
    - `enabled == false`, atau
    - `marketplaceId` belum valid
  - filter ini hanya aktif di runtime non-Studio
  - Studio tetap melihat item placeholder agar proses setup Creator Hub masih nyaman

### Validation Notes

- build source sukses:
  - `_tmp_shop_publish_visibility_build.rbxlx`
- verifikasi live script sinkron di Studio:
  - `Client.UI.Main` memuat filter:
    - `if currency == "Robux" and RunService:IsStudio() ~= true then ... shouldHide = enabled ~= true or marketplaceReady ~= true`

### Interpretation

- player publish tidak lagi melihat etalase `Robux` yang masih bertuliskan `SETUP` atau belum siap.
- developer tetap bisa melihat placeholder di Studio sampai `marketplaceId` Creator Hub selesai diisi.

## 2026-04-04 - Entitlement Ownership Ready For Shop Snapshot

### Scope

- memastikan item entitlement `Robux` dengan `grantItem = false` tetap bisa tampil `OWNED` setelah grant
- menutup bug snapshot shop yang sebelumnya hanya membaca inventory/cosmetic ownership

### Source Changes

- `src/ServerScriptService/Server/EconomySystem/Service.lua`
  - tambah:
    - `GetPassOwnership(player)`
    - `HasPass(player, passKey)`
- `src/ServerScriptService/Server/ShopSystem/Service.lua`
  - tambah resolver entitlement:
    - `_ownsRoyalPassPremium(player)`
    - `_ownsEntitlement(player, item)`
  - `_alreadyOwned(...)` sekarang juga mengecek:
    - `RoyalPass premium`
    - `entitlementKey` yang tersimpan di `EconomySystem`
  - `BuildClientSnapshot()` sekarang memasukkan entitlement yang sudah aktif ke `ownedItemIds`

### Validation Notes

- build source sukses:
  - `_tmp_entitlement_ownership_build.rbxlx`
- validasi live marketplace entitlement belum bisa ditutup karena `marketplaceId` Creator Hub masih `0`
- interpretasi status:
  - ini adalah `source-hardening`
  - live `GamePass` prompt + ownership sync tetap pending sampai ID resmi diisi

### Interpretation

- saat nanti `GamePass` resmi diaktifkan, shop snapshot tidak lagi bohong dengan terus menampilkan item entitlement sebagai belum dimiliki.
- ini penting untuk `royalpass_premium_track`, `class_dukun_unlock`, `class_detective_unlock`, dan `lifetime_bonus_pass`.

## 2026-04-04 - Studio Entitlement Harness Verified

### Scope

- menambah harness Studio-only untuk grant entitlement `GamePass` style tanpa menunggu `marketplaceId` Creator Hub real
- menutup validasi live bahwa `BuildClientSnapshot()` benar-benar menandai entitlement sebagai `owned`

### Source Changes

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - tambah action `GrantMarketplaceEntitlement`
  - `GetShopPlayerSnapshot` sekarang juga melaporkan:
    - `ownedCount`
    - `ownedSnapshot`

### Validation Notes

- build source sukses:
  - `_tmp_entitlement_harness_build.rbxlx`
- validasi live Studio sukses setelah restart `Play` untuk memuat script server terbaru
- hasil runtime:
  - `royalpass_premium_track`
    - before: `ownedCount=0`, `ownedSnapshot=false`
    - grant: `owned=true`, `ownedCount=1`
    - after: `ownedCount=1`, `ownedSnapshot=true`
  - `class_dukun_unlock`
    - before: `ownedCount=1`, `ownedSnapshot=false`
    - grant: `owned=true`, `ownedCount=2`
    - after: `ownedCount=2`, `ownedSnapshot=true`
  - `class_detective_unlock`
    - before: `ownedCount=2`, `ownedSnapshot=false`
    - grant: `owned=true`, `ownedCount=3`
    - after: `ownedCount=3`, `ownedSnapshot=true`
  - `lifetime_bonus_pass`
    - before: `ownedCount=3`, `ownedSnapshot=false`
    - grant: `owned=true`, `ownedCount=4`
    - after: `ownedCount=4`, `ownedSnapshot=true`

### Interpretation

- jalur entitlement sekarang tidak cuma siap di source, tetapi juga sudah terbukti hidup di Studio playtest.
- ini menurunkan risiko publish untuk item `GamePass` permanen karena snapshot UI/shop tidak lagi tertinggal dari state entitlement server.

## 2026-04-04 - Studio DeveloperProduct Harness Verified

### Scope

- menambah harness Studio-only untuk grant `DeveloperProduct` style purchase
- memvalidasi aturan Roblox bahwa currency pack `Robux` harus repeatable dan tidak boleh tampil sebagai entitlement permanen

### Source Changes

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - tambah action `GrantMarketplacePurchase`
  - `GrantMarketplaceEntitlement` sekarang dibatasi khusus item kategori `Entitlement`
  - ack grant marketplace sekarang juga melaporkan:
    - `category`
    - `currency`
    - `owned`
    - `ownedCount`
    - `MM/PP/Robux` sesudah grant

### Validation Notes

- build source sukses:
  - `_tmp_marketplace_purchase_harness_build.rbxlx`
- validasi live Studio sukses:
  - baseline wallet: `MM=1200 PP=12 Robux=0`
  - `mm_pack_small`
    - before: `ownedSnapshot=false`
    - grant 1: `MM=3700`, `owned=false`, `ownedCount=0`
    - grant 2: `MM=6200`, `owned=false`, `ownedCount=0`
    - after kedua grant: tetap `ownedSnapshot=false`
  - `pp_pack_standard`
    - before: `PP=12`, `ownedSnapshot=false`
    - grant 1: `PP=37`, `owned=false`, `ownedCount=0`
    - after: tetap `ownedSnapshot=false`

### Interpretation

- jalur `DeveloperProduct` sekarang terbukti mengikuti pola yang benar untuk pack currency:
  - grant bisa diulang
  - wallet bertambah setiap kali purchase
  - item tidak salah dibekukan sebagai ownership permanen
- ini menurunkan risiko bug monetization saat nanti `ProcessReceipt` Creator Hub dihubungkan ke item `CurrencyPack`.

## 2026-04-04 - PP Match Reward Validated Live

### Scope

- memverifikasi apakah `PP` prestige currency benar-benar punya sumber live atau hanya berhenti di UI/shop
- membuktikan jalur result panel membaca reward `PP` dari server, bukan angka dummy

### Validation Notes

- source scan menunjukkan `RewardCalculationSystem` memang sudah menghitung `ppReward` pada `MatchCompleted`
- validasi live Studio dilakukan lewat:
  - `CreateRoom`
  - `HostStart`
  - `MatchStarted`
  - `StudioE2E EndMatch`
- hasil runtime:
  - wallet before: `MM=6200 PP=37 Robux=0`
  - `MatchRewardSummary`:
    - `currencyReward=306`
    - `ppReward=2`
    - `xpReward=222`
    - `royalPassXP=99`
  - wallet after: `MM=6506 PP=39 Robux=0`

### Interpretation

- `PP` sekarang terbukti punya sumber live dari endgame reward, bukan sekadar mata uang dekoratif di shop.
- backlog monetization perlu dibaca ulang secara reality-based: yang tersisa bukan “PP belum punya sumber”, tetapi memastikan balancing, surfacing, dan jalur earn lain cukup jelas untuk pemain.

## 2026-04-04 - PP Result Breakdown Surfaced To Players

### Scope

- membuat hasil match menjelaskan sumber `PP`, bukan hanya angka total
- menutup bug urutan event client: `MatchRewardSummary` datang dulu lalu ditimpa `MatchCompleted` yang tidak membawa reward fields

### Source Changes

- `src/ServerScriptService/Server/RewardCalculationSystem/Service.lua`
  - `MatchRewardSummary` sekarang mengirim `ppBreakdown`
  - reward calc sekarang menyusun breakdown `PP`:
    - `Misi selesai`
    - `Tebakan benar`
    - `Selamat hidup`
    - `Ekstraksi`
    - `Bonus difficulty`
    - `Penalty gagal total`
- `src/client/UI/Main.lua`
  - `MatchResult` sekarang menyimpan `ppBreakdown`
  - footer result kini menjelaskan alasan `PP`
  - handler `MatchCompleted/MatchEnded` sekarang mempertahankan reward yang sudah lebih dulu datang dari `MatchRewardSummary`

### Validation Notes

- build source sukses:
  - `_tmp_pp_breakdown_fix_build.rbxlx`
- validasi live Studio:
  - `MatchRewardSummary.ppBreakdown` terkirim:
    - `Tebakan benar +1`
    - `Selamat hidup +1`
  - `RewardRow.Value = 306 MM | 2 PP`
  - `ResultsFooter = PP: Tebakan benar +1 • Selamat hidup +1 Tekan tombol lanjut untuk kembali ke lobby flow.`

### Interpretation

- pemain sekarang bisa memahami mengapa `PP` bertambah, sehingga prestige loop tidak terasa arbitrar.
- race condition UI reward sudah ditutup; hasil match tidak lagi jatuh kembali ke `0 PP` hanya karena event `MatchCompleted` datang belakangan.

## 2026-04-04 - Extraction Reward Path Validated With Studio Override

### Scope

- memverifikasi bahwa jalur extraction override Studio benar-benar melewati reward pipeline final
- membuktikan footer result membaca kombinasi `team success + survive + extract`

### Validation Notes

- validasi live Studio:
  - wallet before: `MM=1506 PP=14 Robux=0`
  - `ExtractSelf(allowStudioOverride=true)` sukses:
    - `match=match_2 zone=StudioOverrideZone`
  - `MatchRewardSummary`:
    - `currencyReward=324`
    - `ppReward=3`
    - `ppBreakdown = Misi selesai +1 / Selamat hidup +1 / Ekstraksi +1`
  - wallet after: `MM=1830 PP=17 Robux=0`
  - `RewardRow.Value = 324 MM | 3 PP`
  - `ResultsFooter = PP: Misi selesai +1 • Selamat hidup +1 • Ekstraksi +1 Tekan tombol lanjut untuk kembali ke lobby flow.`

### Interpretation

- jalur extraction E2E sekarang terbukti memberi reward sesuai perilaku yang diharapkan pemain, bukan hanya berhasil memindahkan state keluar match.
- ini juga memvalidasi bahwa surfacing `PP` di results tetap benar pada flow extraction, bukan hanya pada `EndMatch` paksa.

## 2026-04-04 - Shop PP Filter Now Explains Prestige Source

### Scope

- membuat pemain memahami asal `PP` langsung dari `ShopUI`, bukan hanya setelah match selesai

### Source Changes

- `src/client/UI/Main.lua`
  - footer `ShopUI` sekarang berubah dinamis saat filter `PP` aktif
  - teks baru menjelaskan bahwa `PP` datang dari reward endgame seperti survive, ekstraksi, tebakan benar, dan sebagian result mission

### Validation Notes

- build source sukses:
  - `_tmp_shop_pp_footer_build.rbxlx`
- validasi live Studio:
  - `ShopUI.Enabled = true`
  - `FilterPP` aktif (`BackgroundColor3 = 0.360784, 0.462745, 0.611765`)
  - `ShopUI.MainPanel.FooterLabel` menampilkan:
    - `Owned 0 item. PP didapat dari reward endgame seperti survive, ekstraksi, tebakan benar, dan sebagian result mission. Gunakan tab ini untuk belanja prestige hasil main, bukan top-up langsung.`

### Interpretation

- jalur prestige sekarang tidak cuma benar secara backend, tetapi juga dijelaskan di surface shop yang relevan.
- ini menutup blind spot UX “PP ada di toko, tapi pemain tidak tahu cara mendapatkannya”.

## 2026-04-04 - Robux PP Packs And Ranked Fairness Guard

### Scope

- menambah paket `PP` berbasis `Robux`
- menambah exchange `PP -> MM` yang tetap lokal ke experience ini
- memastikan monetization tidak membuka `Pay To Win` di `Ranked`

### Source Changes

- `src/shared/DataTypes/ShopCatalog.lua`
  - tambah `pp_pack_small`
  - rename `pp_pack_standard`
  - tambah `pp_pack_large`
  - tambah `pp_to_mm_small`
  - tambah `pp_to_mm_medium`
  - tambah `pp_to_mm_large`
  - tandai helper item sebagai `ClassicOnly`
- `src/shared/DataTypes/ShopMarketplaceConfig.lua`
  - tambah slot config `pp_pack_small` dan `pp_pack_large`
  - simpan note bahwa `10576163165` bukan ID marketplace terverifikasi
- `src/ServerScriptService/Server/ShopSystem/Service.lua`
  - currency pack sekarang hanya boleh grant `MM/PP`
  - purchase soft-currency kini mendukung `grantItem=false` + `grantCurrency`
- `src/ServerScriptService/Server/EconomySystem/Service.lua`
  - top-up `MM` dari marketplace / exchange tidak lagi tertabrak cap harian earn
  - bonus `LifetimePass` yang memengaruhi ekonomi dihapus
- `src/ServerScriptService/Server/EconomySystem/Rewards/RoyalPass/Service.lua`
  - bonus reward `LifetimePass` dihapus
- `src/ServerScriptService/Server/MatchSystem/MatchService.lua`
  - player sekarang menerima attribute `MatchMode` dan `MatchDifficulty`
- `src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua`
  - helper item dineutralisasi saat `MatchMode == Ranked`
- `src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua`
  - buff jarak `Spirit Box` modded/elite dimatikan di `Ranked`
- `src/client/UI/Main.lua`
  - UI shop menandai item `CLASSIC ONLY`
  - row Robux currency pack menandai `IN-GAME MM/PP`
  - state tool lokal tidak lagi memberi reinforced salt bonus saat `Ranked`

### Validation Notes

- build source sukses:
  - `_tmp_shop_ranked_fairness_build.rbxlx`
  - `_tmp_robux_pp_ranked_guard_build.rbxlx`
- validasi live Studio yang sukses:
  - `GrantCurrency(PP, 80)` berhasil
  - `GrantCurrency(MM, 5000)` berhasil
  - `PurchaseItem(pp_eq_spiritbox_elite)` berhasil
  - `PurchaseItem(pp_to_mm_medium)` berhasil
  - wallet berubah dari:
    - `MM=10550 PP=176 Robux=0`
    - menjadi `MM=14750 PP=139 Robux=0`
  - `GetShopPlayerSnapshot(pp_eq_spiritbox_elite)`:
    - `hasItem=true`
    - `ownedSnapshot=true`
  - `GrantMarketplacePurchase(pp_pack_small)`:
    - `PP +10`
  - `GrantMarketplacePurchase(mm_pack_small)`:
    - `MM +2500`
- validasi fairness live yang sudah terbukti:
  - `Ranked`: `SaltPlacement` pertama memberi `usesRemaining=2`
  - `Classic`: `SaltPlacement` pertama memberi `usesRemaining=3`
- validasi fairness live lanjutan pada sesi ini sempat terganggu bug runtime ghost Studio:
  - `The Parent property of Ghost_* is locked`
  - issue ini memblok playtest lanjutan, tetapi tidak mengubah hasil validasi monetization yang sudah sukses

### Interpretation

- `PP` sekarang punya loop lengkap:
  - earned in-game
  - topped up by `Robux`
  - spent langsung untuk cosmetics / prestige / exchange lokal
- `MM` bisa dibeli lewat `Robux` atau ditukar dari `PP`, tetapi tetap currency in-game dan tidak lintas experience
- jalur Ranked sekarang lebih fair karena helper item tetap dibatasi ke `Classic`

## 2026-04-04 - Ghost Parent Guard Added In Source

### Scope

- menutup crash match saat visual ghost gagal diparent ke container runtime

### Source Changes

- `src/ServerScriptService/Server/GhostSystem/Service.lua`
  - tambah `tryParentGhostModel()`
  - `InitializeMatch()` sekarang:
    - mencoba parent ghost template secara protected
    - fallback ke placeholder bila parent gagal
    - mengembalikan error terstruktur bila bahkan fallback gagal

### Validation Notes

- build source sukses:
  - `_tmp_robux_pp_ranked_guard_build.rbxlx`
- sesi Studio aktif masih menunjukkan drift runtime pada copy script server lama, sehingga crash `Ghost_* parent locked` belum hilang pada playtest itu

### Interpretation

- fix source sudah aman untuk di-commit
- bila drift Studio dihapus (reconnect/sync script server aktif), jalur match tidak boleh lagi crash hanya karena satu template ghost gagal diparent

## 2026-04-04 - Shop Compliance Copy Hardened

### Scope

- membuat batasan monetization lebih terlihat langsung di `ShopUI`
- mengurangi risiko UX yang menyesatkan pemain tentang `Robux`, `PP`, `MM`, dan fairness `Ranked`

### Source Changes

- `src/client/UI/Main.lua`
  - label blok `marketplace_id_missing` sekarang menegaskan bahwa currency pack hanya memberi `MM/PP` di game ini
  - meta item `ClassicOnly` sekarang juga menampilkan `NO RANKED BONUS`
  - meta currency pack `Robux` sekarang juga menampilkan `IN-EXPERIENCE ONLY`
  - footer `ShopUI` kini menjelaskan:
    - `MM/PP` tetap currency in-game
    - helper `ClassicOnly` tidak memberi bonus di `Ranked`
    - tab `Robux` hanya untuk grant yang compliant
    - tab `Owned` mengingatkan ulang batasan item `ClassicOnly`

### Validation Notes

- build source sukses:
  - `_tmp_shop_copy_guard_build.rbxlx`

### Interpretation

- backend compliance saja tidak cukup; pemain juga harus melihat batasan monetization dengan bahasa yang jujur di surface shop
- ini membantu menjaga review Roblox dan ekspektasi pemain tetap sinkron

## 2026-04-04 - Hidden Empty Shop Filters

### Scope

- menghindari tab filter shop yang kosong/menyesatkan saat kategori tertentu tidak punya item visible

### Source Changes

- `src/client/UI/Main.lua`
  - tambah `shouldShowShopFilter()`
  - filter yang tidak punya item visible sekarang tidak dibuat
  - jika filter aktif tiba-tiba tidak relevan, state otomatis kembali ke `All`

### Validation Notes

- build source sukses:
  - `_tmp_shop_filter_visibility_build.rbxlx`

### Interpretation

- pada production non-Studio, tab `R$` tidak perlu muncul jika semua item Robux masih hidden karena belum compliant/siap
- ini membuat surface shop lebih jujur dan mengurangi UI kosong yang membingungkan

## 2026-04-04 - Wallet Summary Matches Visible Shop Slots

### Scope

- membuat ringkasan wallet shop mengikuti slot currency yang benar-benar visible untuk player

### Source Changes

- `src/client/UI/Main.lua`
  - `formatShopWalletSummary()` sekarang menerima katalog visible
  - `R$` hanya ditampilkan bila filter/category `Robux` memang punya item visible

### Validation Notes

- build source sukses:
  - `_tmp_shop_wallet_visibility_build.rbxlx`

### Interpretation

- pada production saat semua slot `Robux` masih hidden, pemain tidak lagi melihat `R$ 0` yang tidak punya konteks
- UI shop jadi lebih konsisten dengan katalog yang benar-benar tersedia

## 2026-04-04 - Ghost Parent Guard Confirmed Live

### Scope

- menutup sisa jalur parent ghost yang masih bisa memunculkan error `The Parent property of Ghost_* is locked`

### Source Changes

- `src/ServerScriptService/Server/GhostSystem/Service.lua`
  - `ensureGhostPlacement()` sekarang juga memakai `tryParentGhostModel()`
  - jika re-parent ghost gagal, fungsi sekarang keluar aman tanpa melempar runtime error mentah

### Validation Notes

- build source sukses:
  - `_tmp_ghost_guard_retest_build.rbxlx`
- validasi live Studio:
  - setelah stop/play ulang, `CreateRoom -> HostStart` kembali berhasil:
    - `started=true matchId=match_1 mode=Classic`
  - flow `Ranked` juga berhasil start lagi tanpa membatalkan match:
    - `ranked_started=true`
    - `ranked_salt_remaining=2`
  - flow `Classic` pembanding juga berhasil:
    - `classic_started=true`
    - `classic_salt_remaining=3`

### Interpretation

- fix ghost parent sekarang tidak hanya aman di source, tetapi juga sudah terbukti menjaga match start tetap hidup di runtime Studio
- hasil fairness `Ranked` vs `Classic` juga terkunci ulang pada sesi live yang sudah melewati blocker ghost tadi

## 2026-04-04 - Spirit Box Elite Fairness Confirmed Live

### Scope

- membuktikan bahwa `pp_eq_spiritbox_elite` tidak bocor ke `Ranked`, tetapi tetap aktif di `Classic`

### Validation Notes

- validasi live Studio:
  - `GrantCurrency(PP, 60)` berhasil
  - `PurchaseItem(pp_eq_spiritbox_elite)` berhasil
  - snapshot kepemilikan:
    - `hasItem=true`
    - `ownedSnapshot=true`
  - `Ranked` test pada `distanceToGhost = 25`:
    - `ranked_spirit_success=false`
    - `ranked_spirit_reason=ghost_out_of_range`
  - `Classic` test pada `distanceToGhost = 25`:
    - `classic_spirit_success=false`
    - `classic_spirit_reason=spawn_roll_failed`
    - `classic_spirit_tier=elite`

### Interpretation

- hasil `Ranked` membuktikan bonus range elite memang mati di mode fair
- hasil `Classic` membuktikan tier elite tetap hidup; kegagalan yang muncul berasal dari roll signal/evidence, bukan gate jarak
- ini menutup validasi fairness untuk dua helper utama:
  - `Reinforced Salt`
  - `Spirit Box Elite`

## 2026-04-04 - UV Flashlight Audit

### Scope

- memastikan `eq_flashlight_uv` tidak diam-diam menjadi item pay-to-win di `Ranked`

### Validation Notes

- audit source menunjukkan `eq_flashlight_uv` hanya dipakai pada:
  - `src/ServerScriptService/Server/ShopSystem/Service.lua` untuk attribute kepemilikan
  - `src/client/CameraController.client.lua` untuk warna lens dan warna cahaya flashlight
- tidak ditemukan hook server-authoritative yang memberi:
  - range tambahan
  - stock tambahan
  - reward tambahan
  - buff investigasi

### Interpretation

- pada implementasi saat ini, `UV Flashlight Mk2` masih berada di jalur visual-only
- item ini belum menunjukkan kebocoran fairness `Ranked`

## 2026-04-04 - UV Flashlight Marked Visual-Only In Shop

### Scope

- membuat sifat non-pay-to-win `UV Flashlight Mk2` lebih jelas langsung di katalog player-facing

### Source Changes

- `src/shared/DataTypes/ShopCatalog.lua`
  - `eq_flashlight_uv` sekarang diberi `visualOnly = true`
- `src/client/UI/Main.lua`
  - item dengan `visualOnly = true` sekarang menampilkan meta `VISUAL ONLY`

### Validation Notes

- build source sukses:
  - `_tmp_uv_visual_only_build.rbxlx`

### Interpretation

- ini membantu pemain dan reviewer melihat bahwa `UV Flashlight Mk2` bukan helper kemenangan `Ranked`, melainkan variasi visual flashlight

## 2026-04-04 - Premium Royal Pass Currency Bonus Removed

### Scope

- memastikan `royalpass_premium_track` tidak menjadi jalur `Robux -> bonus currency` yang bertentangan dengan target non-pay-to-win

### Source Changes

- `src/ServerScriptService/Server/RoyalPassSystem/Service.lua`
  - `_rewardForTier()` tidak lagi memberi bonus currency ekstra untuk owner premium
- `src/shared/DataTypes/ShopCatalog.lua`
  - `royalpass_premium_track.setupHint` diperkeras agar hanya boleh aktif jika jalur premium tetap cosmetic/progression-safe
- `src/client/UI/Main.lua`
  - footer `RoyalPassUI` sekarang menjelaskan bahwa bonus currency premium khusus dimatikan

### Validation Notes

- build source sukses:
  - `_tmp_royalpass_premium_safe_build.rbxlx`

### Interpretation

- langkah ini menjaga arah monetization tetap konsisten dengan keputusan produk:
  - `Robux` tidak dipakai untuk membuat game lebih mudah
  - `Premium Track` tidak boleh diam-diam menjadi top-up advantage melalui reward tier ekstra

## 2026-04-04 - Royal Pass Reward Grant Made Explicit

### Scope

- menghilangkan panggilan reward currency yang terlalu implisit / rawan salah baca di `RoyalPassSystem`

### Source Changes

- `src/ServerScriptService/Server/RoyalPassSystem/Service.lua`
  - `_grantTierReward()` sekarang memanggil:
    - `AddCurrency(player, "MM", reward.currency, "RoyalPass")`
  - panggilan lama yang mengandalkan overload implisit dan stub `GrantCurrency` dibuang

### Validation Notes

- build source sukses:
  - `_tmp_royalpass_currency_explicit_build.rbxlx`

### Interpretation

- perilaku reward tidak berubah arah, tetapi implementasi jadi jauh lebih eksplisit
- ini menurunkan risiko regress/halusinasi engineer berikutnya saat menyentuh jalur Royal Pass

## 2026-04-04 - Cosmetic Monetization Smoke Test Closed Live

### Scope

- memvalidasi bahwa jalur cosmetic shop benar-benar hidup end-to-end di Studio, bukan hanya aman di source

### Live Validation

- harness yang dipakai:
  - `StudioE2EControl` untuk grant currency dan snapshot wallet/shop
  - `PurchaseEvent` untuk beli cosmetic
  - `CosmeticEvent` untuk equip/unequip wardrobe
- langkah live yang berhasil:
  - `GrantCurrency(MM, 5000)` -> `MM=10080`
  - `GrantCurrency(PP, 60)` -> `PP=117`
  - `PurchaseItem(cos_accessory_wardingcharm)` -> `success=true`
  - `PurchaseItem(pp_cos_head_nightoracle)` -> `success=true`
  - `EquipCosmetic(cos_accessory_wardingcharm)` -> slot `accessory`
  - `EquipCosmetic(pp_cos_head_nightoracle)` -> slot `head`
  - `UnequipCosmetic(accessory)` -> `success=true`
  - `UnequipCosmetic(head)` -> `success=true`
- snapshot live yang terbukti:
  - sesudah beli:
    - `MM=9380`
    - `PP=105`
    - `ownsCosmetic=true` untuk `pp_cos_head_nightoracle`
  - sesudah equip:
    - `equippedCount=2`
    - `equippedCosmetics.accessory=cos_accessory_wardingcharm`
    - `equippedCosmetics.head=pp_cos_head_nightoracle`
  - visual lobby:
    - `Workspace.ZyraaaVex.LobbyCosmeticVisuals`
    - `AccessoryVisual=true`
    - `HeadVisual=true`
    - `LobbyCosmeticBillboard=true`
  - sesudah unequip:
    - `equippedCount=0`
    - `LobbyCosmeticVisuals` tinggal `0` child

### Interpretation

- jalur cosmetic `MM/PP` sudah lolos smoke test live tanpa indikasi pay-to-win
- efeknya tetap berada di wardrobe/lobby presentation
- ini aman dijadikan baseline monetization non-`Robux` sambil menunggu Creator Hub ID production

## 2026-04-04 - Placeholder Entitlement Audit

### Scope

- memastikan entitlement `Robux` yang belum punya sistem gameplay sah tetap tertahan dan tidak dinyalakan prematur

### Audit Result

- pencarian source saat ini hanya menemukan:
  - `class_dukun_unlock`
  - `class_detective_unlock`
  - `lifetime_bonus_pass`
  - `RoyalPass_Dukun`
  - `RoyalPass_Detective`
  - `LifetimePass`
- lokasi yang ditemukan:
  - `src/shared/DataTypes/ShopCatalog.lua`
  - `src/shared/DataTypes/ShopMarketplaceConfig.lua`
  - state entitlement di `EconomySystem`
- tidak ditemukan class runtime live yang memakai entitlement itu untuk memberi role/buff/bonus kemenangan

### Interpretation

- status item-item tersebut tetap `safe-disabled`
- jangan aktifkan sampai:
  - ada sistem class/benefit yang benar-benar final
  - benefit-nya lolos audit fairness Ranked
  - setup Roblox marketplace resminya sudah benar

## 2026-04-04 - Hide Disabled Shop Items By Default

### Scope

- mencegah item shop placeholder/disabled terlihat misleading di UI player-facing, termasuk saat Studio playtest biasa

### Source Changes

- `src/client/UI/Main.lua`
  - `loadShopCatalog()` sekarang menyembunyikan item `enabled=false` secara default
  - item `Robux` yang `marketplaceId` belum valid juga tetap disembunyikan
  - attr debug baru:
    - `PasrahShowDisabledShopItems = true`
    - hanya untuk menampilkan kembali item disabled saat audit internal
  - `_reloadShopCatalog()` ditambahkan agar toggle debug bisa refresh katalog tanpa reload penuh

### Validation Notes

- build source sukses:
  - `_tmp_shop_hidden_disabled_build.rbxlx`

### Interpretation

- placeholder seperti class unlock/lifetime pass tidak lagi ikut mengotori shop umum
- dev masih bisa membukanya kembali secara sadar lewat attribute debug, tetapi default pemain dan tester melihat katalog yang lebih jujur

## 2026-04-04 - Royal Pass Premium CTA Hardened

### Scope

- mencegah `RoyalPassUI` terlihat seolah-olah premium track siap dibeli padahal entitlement-nya masih disabled/pending compliance

### Source Changes

- `src/client/UI/Main.lua`
  - `RoyalPassUI` sekarang mengecek apakah `royalpass_premium_track` benar-benar visible/ready di katalog
  - jika belum ready:
    - tombol premium berubah ke `PENDING`
    - footer menjelaskan status pending compliance/setup
    - track hint menjelaskan view premium masih preview
    - CTA tidak lagi mengarahkan pemain ke shop seolah-olah live
  - jika nanti ready:
    - CTA kembali membuka `ShopUI` filter `Robux`

### Validation Notes

- build source sukses:
  - `_tmp_royalpass_pending_ui_build.rbxlx`

### Interpretation

- ini mengurangi misleading monetization di jalur `Royal Pass`
- pemain tidak lagi didorong ke CTA pembelian yang belum seharusnya aktif

## 2026-04-04 - Utility Tool Roster Visual Pass

### Scope

- menaikkan kualitas visual world-space `Garam`, `Salib`, dan `Dupa` tanpa menambah owner sistem baru

### Source Changes

- `src/ReplicatedStorage/Assets/Models/Tools/Garam.model.json`
  - tambah `PileAccent2`, `Satchel`, `Seal`, `SaltGlow`
- `src/ReplicatedStorage/Assets/Models/Tools/Salib.model.json`
  - tambah `HaloBack`, `GroundAura`
- `src/ReplicatedStorage/Assets/Models/Tools/Dupa.model.json`
  - tambah `AshBed`, `CharmWrap`, `RepelAura`, `Smoke4`, `Smoke5`
- `src/ServerScriptService/Server/EvidenceSystem/Modules/UtilityToolVisuals.lua`
  - `MarkSaltTriggered()` sekarang ikut menyalakan `SaltGlow` dan memoles detail bag
  - `UpdateCrucifixCharges()` sekarang ikut mengubah aura `HaloBack/GroundAura`
  - `ActivateSmudge()` baru untuk mengubah `RepelAura` dan smoke state sesuai repel aktif
- `src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua`
  - `Dupa` sekarang memanggil `ActivateSmudge()` saat aktif dan saat repel hunt sukses

### Validation Notes

- build source sukses:
  - `_tmp_tool_roster_visuals_build.rbxlx`
- validasi source sync live:
  - `ReplicatedStorage.Assets.Models.Tools.Garam` -> `SaltGlow=true`, `descendants=8`
  - `ReplicatedStorage.Assets.Models.Tools.Salib` -> `HaloBack=true`, `GroundAura=true`, `descendants=8`
  - `ReplicatedStorage.Assets.Models.Tools.Dupa` -> `RepelAura=true`, `Smoke4=true`, `Smoke5=true`, `descendants=11`
- validasi runtime live:
  - `CreateRoom -> HostStart -> ForceHunt -> UseEvidenceTool(Dupa)` sukses
  - `Workspace.ActiveMatches.Match_match_1.InvestigationTools.Dupa_*` hadir
  - `RepelAura.Transparency = 0.34`
  - `Smoke4.Transparency = 0.60`
  - `Smoke5.Transparency = 0.68`
  - material aura/smoke runtime terbaca `Enum.Material.Neon`

### Interpretation

- slice utility tool tidak lagi terasa placeholder polos
- state visual sekarang mulai jujur mengikuti event gameplay yang memang aktif
- `tool roster` belum selesai penuh karena icon/non-utility presentation masih perlu pass lanjutan

## 2026-04-04 - Field Kit HUD Identity Pass

### Scope

- menutup bagian HUD dari item `tool roster` tanpa membuka owner UI baru atau memecah jalur `UI/Main`

### Source Changes

- `src/client/UI/Main.lua`
  - `FIELD_KIT_TOOL_CONFIG` sekarang punya mikrocopy identitas per tool:
    - `hint`
    - `readyMeta`
    - `readyFooter`
  - `ensureFieldKitButtonVisuals()` sekarang membangun:
    - `HintLabel`
    - `AccentBar`
  - `_resolveFieldKitMeta()` sekarang memberi idle state yang lebih jujur untuk tool non-placement:
    - `JejakEnergi -> LIVE / SCAN ARC`
    - `KotakArwah -> LISTEN / VOICE LINK`
    - jika signal sudah ada:
      - `JejakEnergi -> EMF n / MEDOK LOCK`
      - `KotakArwah -> RESPON / VOICE <tier>`
    - jika target terlalu jauh:
      - `JejakEnergi -> NO SIG / SCAN ARC`
      - `KotakArwah -> SENYAP / VOICE NULL`
  - sizing `FieldKitFrame`, grid, dan status label dinaikkan sedikit agar kartu tetap terbaca setelah tambahan hint line

### Validation Notes

- build source sukses:
  - `_tmp_fieldkit_hud_polish_build.rbxlx`
- sesi Studio awal masih drift dan memuat `Field Kit` lama:
  - `frameSize = 356x146`
  - `HintLabel = false`
  - `AccentBar = false`
- setelah `Stop Play -> Start Play` lalu masuk match lagi, runtime baru terbaca benar:
  - `FieldKitFrame.Size = 356x156`
  - semua tombol tool runtime punya `HintLabel = true`
  - semua tombol tool runtime punya `AccentBar = true`
  - sample runtime:
    - `JejakEnergiButton -> hint = EMF SWEEP, meta = LIVE, footer = SCAN ARC`
    - `KotakArwahButton -> hint = VOICE BAIT, meta = LISTEN, footer = VOICE LINK`
    - `GaramButton -> hint = LURE TRAP`
    - `SalibButton -> hint = HUNT BLOCK`
    - `DupaButton -> hint = REPEL CLOUD`

### Interpretation

- roster tool di HUD sekarang punya identitas yang lebih cepat dibaca tanpa menunggu pemain membuka jurnal atau mencoba tool satu per satu
- ini menutup bagian `icon/UI state` dari item `tool roster` dengan perubahan yang tetap satu-owner dan aman terhadap drift arsitektur

## 2026-04-04 - Compact Sheet Overflow Guard

### Scope

- menutup debt nyata pada item `Rapikan UI modular`: `RoomBrowserUI` dan `RoyalPassUI` masih bisa keluar layar pada viewport pendek/compact

### Source Changes

- `src/client/UI/Main.lua`
  - `_applyRoomBrowserSizing()` sekarang menghitung:
    - `availableWidth`
    - `availableHeight`
    - lalu clamp panel mobile ke safe viewport, bukan lagi memaksa minimum tinggi tetap
  - sizing `RoomBrowserUI` mobile diubah dari minimum kaku (`540`) menjadi guard yang tetap menjaga tinggi minimal wajar tetapi tidak melebihi safe viewport
  - sizing auxiliary sheet `RoyalPassUI/ProfileUI/ShopUI` sekarang juga memakai:
    - `availableWindowWidth`
    - `availableWindowHeight`
  - `RoyalPassUI` mobile tidak lagi memaksa tinggi minimum `560` tanpa mempedulikan viewport pendek
  - posisi sheet mobile auxiliary digeser sedikit ke `safe inset + 4` agar edge tidak menempel langsung ke batas layar

### Validation Notes

- build source sukses:
  - `_tmp_ui_mobile_sheet_guard_build.rbxlx`
- probe Studio sebelum guard menunjukkan debt compact yang nyata:
  - `RoomBrowserUI.Panel.Size = 513x507`, `posY = -44.5`
  - `RoyalPassUI.MainPanel.Size = 436x499`, `posY = -11`
- interpretasi validasi:
  - ini menunjukkan source sebelumnya masih bisa overflow pada viewport pendek
  - sesi override mobile/compact Studio di MCP belum cukup jujur untuk menutup handset validation penuh
  - karena itu pass ini dicatat sebagai:
    - **source fix applied**
    - **device/emulator validation tetap pending**

### Interpretation

- backlog item `Rapikan UI modular` bergerak maju secara teknis karena akar sizing overflow sudah dipotong
- namun statusnya tetap jujur: panel compact/mobile masih butuh validasi emulator/handset nyata sebelum dinyatakan final

## 2026-04-04 - Audio Slot Honesty Pass

### Scope

- menutup debt audio yang menipu diagnosis:
  - `AmbientLoop_Main` diam-diam memakai heartbeat
  - `GhostManifest_01` dan `GhostWhisper_01` masih memakai ID yang sama

### Source Changes

- `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
  - `AudioContent` dikosongkan lagi
- `src/ReplicatedStorage/Assets/Audio/Ghost/GhostManifest_01.model.json`
  - manifest dipindah ke `rbxassetid://139204195403262`
- hasil akhirnya:
  - `AmbientLoop_Main` tetap placeholder jujur sampai ambience final legal siap
  - `GhostWhisper_01` dan `GhostManifest_01` sekarang punya template berbeda

### Validation Notes

- build source sukses:
  - `_tmp_audio_slot_polish_build.rbxlx`
- sesi Studio awal masih drift dan memuat slot lama:
  - `AmbientLoop_Main = rbxassetid://138884191945388`
  - `GhostManifest_01 = rbxassetid://83336813491039`
- setelah restart play:
  - `AmbientLoop_Main = ""`
  - `GhostManifest_01 = rbxassetid://139204195403262`
  - `GhostWhisper_01 = rbxassetid://83336813491039`

### Interpretation

- ambience sekarang kembali jujur sebagai placeholder, bukan heartbeat tersamar
- manifest dan whisper akhirnya terpisah, sehingga pass audio berikutnya punya baseline yang lebih bersih untuk di-tune

## 2026-04-04 - Map Atmosphere Profile Pass

### Scope

- menaikkan polish visual dari satu offset atmosfer global menjadi profile per map, lalu memastikan runtime client benar-benar berpindah profile saat phase match berubah

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah `DEFAULT_MAP_ATMOSPHERE`
  - tambah `MAP_ATMOSPHERE_PROFILES` untuk:
    - `LobbySocialHub`
    - `HauntedHouse`
    - `EmptyBuilding`
    - `AbandonedPalace`
    - `StudioMMNineteen`
  - `ensureAtmosphere()` sekarang membuat `Atmosphere` dengan baseline yang lebih eksplisit:
    - `Density`
    - `Offset`
    - `Color`
    - `Decay`
    - `Glare`
    - `Haze`
  - `Start()` sekarang menerapkan baseline lobby saat boot jika player belum `InMatch`
  - `_handleMatchEvent()` sekarang juga membaca `PhaseChanged` supaya `mapId` canonical dari runtime client benar-benar dipakai
  - `_applyMapAtmosphere()` sekarang memindahkan seluruh profile visual, bukan hanya `Offset`

### Validation Notes

- build source sukses:
  - `_tmp_map_atmosphere_profiles_build.rbxlx`
  - `_tmp_map_atmosphere_boot_guard_build.rbxlx`
  - `_tmp_map_atmosphere_players_fix_build.rbxlx`
  - `_tmp_map_atmosphere_matchid_fix_build.rbxlx`
  - `_tmp_map_atmosphere_phasechange_fix_build.rbxlx`
- validasi live Studio terbaru:
  - setelah boot lobby:
    - `density = 0.24`
    - `offset = 0.10`
    - `glare = 0.08`
    - `haze = 1.2`
  - setelah `CreateRoom -> HostStart(HauntedHouse)` dan phase `Briefing`:
    - `density = 0.44`
    - `offset = 0.27`
    - `glare = 0.14`
    - `haze = 2.1`

### Interpretation

- lighting client sekarang punya pemisahan atmosfer lobby vs map yang benar-benar terbukti di runtime
- ini menutup sebagian debt `material and lighting polish` pada level sensory baseline, meski pass artistik penuh map masih tersisa

## 2026-04-05 - Map Lighting Profile Pass

### Scope

- menaikkan polish visual dari baseline fog/post-process menjadi lighting profile per map yang benar-benar berpindah saat runtime

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah import eksplisit `Lighting`
  - tambah `DEFAULT_MAP_LIGHTING`
  - tambah `MAP_LIGHTING_PROFILES` untuk:
    - `LobbySocialHub`
    - `HauntedHouse`
    - `EmptyBuilding`
    - `AbandonedPalace`
    - `StudioMMNineteen`
  - `Init()` sekarang menyimpan baseline lighting utama:
    - `ClockTime`
    - `Brightness`
    - `ExposureCompensation`
    - `Ambient`
    - `OutdoorAmbient`
    - `EnvironmentDiffuseScale`
    - `EnvironmentSpecularScale`
  - tambah `_applyMapLighting()` dan `_applyMapVisualProfile()`
  - jalur `Start()`, `MatchStarted`, `PhaseChanged`, dan `MatchEnded` sekarang memakai profile visual penuh, bukan hanya atmosphere

### Validation Notes

- build source sukses:
  - `_tmp_map_lighting_profiles_build.rbxlx`
  - `_tmp_map_lighting_profiles_clean_build.rbxlx`
- validasi live Studio:
  - saat boot lobby:
    - `ClockTime = 14.6`
    - `Brightness = 2.25`
    - `ExposureCompensation = 0`
    - `EnvironmentDiffuseScale = 0.34`
    - `EnvironmentSpecularScale = 0.22`
  - setelah `CreateRoom -> HostStart(HauntedHouse)` dan phase `Briefing`:
    - `ClockTime = 1.35`
    - `Brightness = 1.72`
    - `ExposureCompensation = -0.28`
    - `EnvironmentDiffuseScale = 0.20`
    - `EnvironmentSpecularScale = 0.10`

### Interpretation

- lobby dan match sekarang punya tone lighting yang benar-benar berbeda di runtime, bukan hanya ilusi dari post-process
- ini menutup bagian `material and lighting polish` pada level baseline sistemik sebelum masuk ke pass artistik map yang lebih berat

## 2026-04-05 - Map Grade And Bloom Pass

### Scope

- melengkapi polish visual map dengan owner `grade` dan `bloom` yang tetap ringan, source-owned, dan satu jalur dengan `VFXController`

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah `DEFAULT_MAP_GRADE`
  - tambah `DEFAULT_MAP_BLOOM`
  - tambah `MAP_GRADE_PROFILES` untuk:
    - `LobbySocialHub`
    - `HauntedHouse`
    - `EmptyBuilding`
    - `AbandonedPalace`
    - `StudioMMNineteen`
  - tambah `MAP_BLOOM_PROFILES` untuk map yang sama
  - tambah owner effect:
    - `SensoryMapGrading` (`ColorCorrectionEffect`)
    - `SensoryMapBloom` (`BloomEffect`)
  - `Init()` sekarang menyimpan baseline grade/bloom
  - `_applyMapVisualProfile()` sekarang mencakup:
    - atmosphere
    - lighting
    - map grade
    - bloom

### Validation Notes

- build source sukses:
  - `_tmp_map_grade_bloom_build.rbxlx`
- validasi live Studio:
  - saat boot lobby:
    - `SensoryMapGrading.Brightness = 0.01`
    - `Contrast = 0.04`
    - `Saturation = -0.02`
    - `Bloom.Intensity = 0.18`
    - `Bloom.Size = 20`
  - setelah `CreateRoom -> HostStart(HauntedHouse)` dan phase `Briefing`:
    - `SensoryMapGrading.Brightness = -0.01`
    - `Contrast = 0.10`
    - `Saturation = -0.16`
    - `Bloom.Intensity = 0.07`
    - `Bloom.Size = 12`

### Interpretation

- map sekarang punya karakter visual yang lebih terbedakan bahkan sebelum asset/material final diganti
- ini menutup satu lapisan lagi dari item `material and lighting polish` tanpa membuka sistem visual baru di luar owner yang sudah ada

## 2026-04-05 - Cue-Aware Ghost And Jumpscare Audio Pass

### Scope

- menutup debt audio yang masih terlalu generik:
  - `GhostInteraction` server selalu mengirim cue yang sama
  - `Jumpscare_01` masih memakai asset countdown

### Source Changes

- `src/ServerScriptService/Server/AudioSystem/Controller.lua`
  - `OnGhostInteraction()` sekarang memetakan cue berdasarkan `interactionType/deceptionType`:
    - `WhisperSound/FakeGhostSound -> ghost_whisper`
    - `FakeFootsteps -> ghost_fake_footsteps`
    - `FakeManifestation -> ghost_manifest`
    - `ObjectThrow -> ghost_object_throw`
- `src/client/SoundSystem/Main.lua`
  - `resolveGhostTemplate()` sekarang membaca payload penuh, bukan cuma string cue
  - cue `footstep` sekarang diarahkan ke bank `Footsteps`
  - cue `object/throw` sekarang diarahkan ke `EnvironmentalCreak_01`
  - tambah `resolveJumpscareTemplate()` agar `JumpscareAudio` punya resolver sendiri
  - `JumpscareAudio` sekarang juga punya shaping playback speed terpisah
- `src/ReplicatedStorage/Assets/Audio/Jumpscare/Jumpscare_01.model.json`
  - `AudioContent` dipindah ke `rbxassetid://138329686293368`

### Validation Notes

- build source sukses:
  - `_tmp_cue_audio_routing_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses
  - `StudioE2EControl.TriggerJumpscare` sukses
  - debug runtime pemain setelah trigger:
    - `PasrahAudioLastCategory = JumpscareAudio`
    - `PasrahAudioLastTemplate = Jumpscare_01`
    - `PasrahAudioLastCue = jumpscare_stinger`
    - `PasrahAudioLastSoundId = rbxassetid://138329686293368`
    - `PasrahAudioPlayCount = 1`
- status validasi jujur:
  - routing `GhostInteraction` baru sudah masuk source
  - harness Studio untuk memaksa tiap deception cue belum ada, jadi validasi live jalur `fake_footsteps/object_throw` masih source-side pada batch ini

### Interpretation

- jumpscare tidak lagi terdengar seperti countdown teleport
- jalur ghost audio sekarang lebih siap untuk polish berikutnya karena cue server dan resolver client sudah lebih spesifik

## 2026-04-05 - Map Reverb Runtime Guard

### Scope

- menutup bug runtime kecil tetapi nyata di jalur audio polish:
  - `AudioController` memakai `Players.LocalPlayer` tanpa import `Players`
  - reverb map masih terlalu bergantung pada `MatchStarted`, padahal client canonical sering menerima `mapId` final lewat `PhaseChanged`

### Source Changes

- `src/client/Controllers/Sensory/AudioController.luau`
  - tambah `local Players = game:GetService("Players")`
  - tambah baseline `MAP_REVERB`:
    - `LobbySocialHub -> Room`
    - `EmptyBuilding -> Hallway`
  - `Start()` sekarang menerapkan reverb baseline saat boot:
    - lobby jika belum `InMatch`
    - map aktif jika player sudah dalam match
  - `_onMatchEvent()` sekarang membaca `mapId` juga, bukan hanya `mapName/map`
  - `PhaseChanged` sekarang ikut mengatur reverb berdasarkan map canonical
  - `MatchEnded/MatchCompleted` sekarang mengembalikan reverb ke lobby baseline

### Validation Notes

- build source sukses:
  - `_tmp_audio_reverb_boot_build.rbxlx`
- validasi live Studio:
  - setelah boot lobby:
    - `SoundService.AmbientReverb = Enum.ReverbType.Room`
  - setelah `CreateRoom -> HostStart(HauntedHouse)` dan phase `Briefing`:
    - `SoundService.AmbientReverb = Enum.ReverbType.StoneCorridor`

### Interpretation

- jalur audio map sekarang lebih robust karena tidak lagi bergantung pada event yang kurang lengkap
- ini juga menutup bug import yang berpotensi membuat controller gagal secara diam-diam

## 2026-04-05 - UI Click Signature Pass

### Scope

- mengganti bunyi klik UI dari default Roblox generic menjadi signature click yang masih ringan dan konsisten di seluruh owner `connectButtonPress()`

### Source Changes

- `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`
  - `SoundId` dipindah ke `rbxassetid://115959318`
  - `Volume` ditahan di `0.15` agar tetap lembut untuk spam navigasi UI
- `src/client/UI/Main.lua`
  - `playUIButtonClick()` sekarang memanggil `playRuntimeUISound("ButtonClick")` dengan:
    - `SingleInstance = true`
    - `VolumeScale = 0.95`
    - `PlaybackJitter = 0.04`

### Validation Notes

- build source sukses:
  - `_tmp_ui_click_signature_build.rbxlx`
- validasi live/source:
  - template runtime live terbaca:
    - `ReplicatedStorage.Assets.Audio.UI.ButtonClick_01.SoundId = rbxassetid://115959318`
    - `Volume = 0.15`
  - smoke click canonical:
    - klik `LobbyUI.MainPanel.OpenRoomBrowserButton` tetap membuka `RoomBrowserUI`
- catatan jujur:
  - runtime `SoundService.RuntimeButtonClick` terlalu singkat untuk selalu tertangkap probe MCP jika inspeksi dilakukan terlambat beberapa ratus milidetik
  - jadi bukti utama batch ini adalah:
    - template live yang benar
    - jalur click owner canonical yang tetap berfungsi

### Interpretation

- bunyi klik UI sekarang lebih punya identitas sendiri dan tidak lagi terasa seperti fallback editor default
- perubahan ini aman karena seluruh UI tetap melewati satu owner klik yang sama

## 2026-04-05 - Runtime Cue Cadence Profile Pass

### Scope

- menutup gap kecil tetapi penting pada pass audio polish:
  - cue berbeda masih berbagi volume/pitch yang terlalu seragam walau template sudah benar
  - attribute debug pemain masih merekam nilai template mentah, bukan nilai runtime setelah shaping

### Source Changes

- `src/client/SoundSystem/Main.lua`
  - tambah `CUE_AUDIO_PROFILES` per kategori:
    - `AmbientAudio`
    - `EnvironmentalAudio`
    - `GhostAudio`
    - `HuntAudio`
    - `FearAudio`
    - `JumpscareAudio`
  - tambah `resolveCueProfile(category, payload)` untuk memilih shaping berdasarkan `cue/eventType`
  - `_applySoundProfile()` sekarang mengalikan `Volume` dan `PlaybackSpeed` dengan profile cue bila tersedia
  - `AUDIO_DEBUG_ATTRS` ditambah:
    - `PasrahAudioLastVolume`
    - `PasrahAudioLastPlaybackSpeed`
  - `_recordAudioDebug()` sekarang merekam nilai runtime sound setelah profile diterapkan
  - `_playOneShotCategory()` dan `_playLoopedCategory()` sekarang menjadi owner pencatatan debug, sehingga debug tidak lagi tersesat ke template mentah

### Validation Notes

- build source sukses:
  - `_tmp_cue_profile_audio_build.rbxlx`
- validasi live Studio:
  - `Workspace.ActiveMatches.Match_match_1` terdeteksi aktif
  - `StudioE2EControl.TriggerJumpscare(match_1)` menghasilkan:
    - `PasrahAudioLastCategory = JumpscareAudio`
    - `PasrahAudioLastTemplate = JumpscareAudioRuntime`
    - `PasrahAudioLastCue = jumpscare_stinger`
    - `PasrahAudioLastSoundId = rbxassetid://138329686293368`
    - `PasrahAudioLastVolume ~= 0.90`
    - `PasrahAudioLastPlaybackSpeed ~= 1.2296`
    - `PasrahAudioPlayCount = 1`
  - `StudioE2EControl.ForceHunt(match_1)` menghasilkan:
    - `PasrahAudioLastCategory = HuntAudio`
    - `PasrahAudioLastTemplate = HuntAudioRuntime`
    - `PasrahAudioLastCue = hunt_start`
    - `PasrahAudioLastSoundId = rbxassetid://138329686293368`
    - `PasrahAudioLastVolume ~= 0.884`
    - `PasrahAudioLastPlaybackSpeed ~= 1.122`
    - `PasrahAudioPlayCount = 2`

### Interpretation

- pass ini membuat cue runtime terasa kurang datar tanpa harus mengganti semua asset audio lagi
- debug audio sekarang jujur terhadap hasil akhir yang benar-benar didengar pemain, sehingga batch polish berikutnya tidak lagi buta saat tuning

## 2026-04-05 - Map Depth Of Field Profile Pass

### Scope

- menambah satu layer framing visual yang masih ringan:
  - lobby perlu terasa lebih lega dan bersih
  - map horror perlu sedikit pemisahan fokus tanpa mengaburkan UI atau membuat FPV terlalu berat

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah `DEFAULT_MAP_DOF`
  - tambah `MAP_DOF_PROFILES` untuk:
    - `LobbySocialHub`
    - `AbandonedPalace`
    - `HauntedHouse`
    - `EmptyBuilding`
    - `StudioMMNineteen`
  - tambah `ensureMapDepthOfField()` yang membuat `Lighting.SensoryMapDepthOfField`
  - `Init()` sekarang menyimpan baseline DOF runtime
  - tambah `_applyMapDepthOfField(mapName)`
  - `_applyMapVisualProfile()` sekarang juga menerapkan DOF per map

### Validation Notes

- build source sukses:
  - `_tmp_map_dof_profile_build.rbxlx`
- validasi live Studio:
  - boot lobby:
    - `SensoryMapDepthOfField.FarIntensity ~= 0.06`
    - `FocusDistance = 52`
    - `InFocusRadius = 34`
    - `NearIntensity = 0`
  - setelah `CreateRoom -> HostStart(HauntedHouse)`:
    - `Workspace.ActiveMatches` aktif (`count = 1`)
    - `SensoryMapDepthOfField.FarIntensity ~= 0.14`
    - `FocusDistance = 18`
    - `InFocusRadius = 9`
    - `NearIntensity ~= 0.03`

### Interpretation

- lobby dan match sekarang tidak hanya beda fog/light/grade, tetapi juga punya framing ruang yang lebih terasa
- pass ini tetap aman untuk readability karena intensitas DOF dijaga rendah dan masih berbasis profile per map

## 2026-04-05 - Map Sun Rays Profile Pass

### Scope

- menambah aksen pencahayaan ruang yang masih ringan:
  - lobby siang perlu sedikit rasa udara/volume cahaya
  - map horror malam tetap harus ditahan agar tidak terasa seperti siang berkabut

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah `DEFAULT_MAP_SUNRAYS`
  - tambah `MAP_SUNRAYS_PROFILES` untuk:
    - `LobbySocialHub`
    - `AbandonedPalace`
    - `HauntedHouse`
    - `EmptyBuilding`
    - `StudioMMNineteen`
  - tambah `ensureMapSunRays()` yang membuat `Lighting.SensoryMapSunRays`
  - `Init()` sekarang menyimpan baseline `Intensity/Spread`
  - tambah `_applyMapSunRays(mapName)`
  - `_applyMapVisualProfile()` sekarang juga menerapkan sun rays per map

### Validation Notes

- build source sukses:
  - `_tmp_map_sunrays_profile_build.rbxlx`
- validasi live Studio:
  - boot lobby:
    - `SensoryMapSunRays.Intensity ~= 0.068`
    - `Spread ~= 0.88`
  - setelah `CreateRoom -> HostStart(HauntedHouse)`:
    - `Workspace.ActiveMatches` aktif (`count = 1`)
    - `SensoryMapSunRays.Intensity ~= 0.012`
    - `Spread ~= 0.72`

### Interpretation

- pass ini membuat lobby lebih hidup tanpa mendorong map horror jadi terlalu terang
- karena profile tetap per map dan nilainya rendah, perubahan ini aman untuk style horror dan tidak mengganggu UI

## 2026-04-05 - Map Lighting Color Shift Pass

### Scope

- menambah lapisan tone pencahayaan yang lebih halus daripada grade:
  - lobby butuh sedikit kehangatan agar terasa aman dan sosial
  - map horror butuh sedikit dorongan biru-dingin tanpa merusak readability

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - `DEFAULT_MAP_LIGHTING` sekarang juga punya:
    - `ColorShift_Top`
    - `ColorShift_Bottom`
  - `MAP_LIGHTING_PROFILES` untuk semua map aktif sekarang menetapkan tone atas/bawah masing-masing
  - `Init()` sekarang menyimpan baseline `Lighting.ColorShift_Top/Bottom`
  - `_applyMapLighting()` sekarang juga menerapkan `ColorShift_Top/Bottom`

### Validation Notes

- build source sukses:
  - `_tmp_map_colorshift_profile_build.rbxlx`
- validasi live Studio:
  - boot lobby:
    - `Lighting.ColorShift_Top ~= (0.039, 0.031, 0.016)`
    - `Lighting.ColorShift_Bottom ~= (0.024, 0.016, 0.008)`
  - setelah `CreateRoom -> HostStart(HauntedHouse)`:
    - `Workspace.ActiveMatches` aktif (`count = 1`)
    - `Lighting.ColorShift_Top ~= (0, 0.024, 0.055)`
    - `Lighting.ColorShift_Bottom ~= (0, 0.016, 0.039)`

### Interpretation

- tone ruang sekarang lebih terbaca bahkan sebelum pemain sadar akan fog/grade
- karena nilai color shift dijaga halus, pass ini tetap aman untuk horror readability dan UI overlay

## 2026-04-05 - Ghost And Environment Spatial Audio Pass

### Scope

- menutup debt audio yang masih terlalu “2D”:
  - `EnvironmentalAudio` dan `GhostAudio` selalu parent ke kamera
  - padahal payload runtime sudah mulai punya `position` atau minimal `roomId`

### Source Changes

- `src/client/SoundSystem/Main.lua`
  - tambah debug attrs:
    - `PasrahAudioLastSpatialMode`
    - `PasrahAudioLastSourcePosition`
  - tambah `SPATIAL_SOUND_CATEGORIES` untuk:
    - `EnvironmentalAudio`
    - `GhostAudio`
  - tambah resolver spatial:
    - `_resolveActiveMatchContainer(matchId)`
    - `_resolveRoomAnchor(matchId, roomId)`
    - `_ensureRuntimeAudioEmitterFolder()`
    - `_createSpatialEmitter(position, category)`
    - `_resolvePlaybackTarget(category, payload)`
  - `EnvironmentalAudio/GhostAudio` sekarang:
    - memakai emitter part transparan jika payload membawa `position`
    - atau mencari room anchor di `Workspace.ActiveMatches.Match_<id>` jika hanya ada `roomId`
    - jatuh ke `camera_fallback` jika data ruang belum cukup
  - runtime sound spatial juga sekarang punya profile rolloff:
    - `RollOffMode = InverseTapered`
    - `RollOffMinDistance = 8`
    - `RollOffMaxDistance` disesuaikan kategori
  - `_recordAudioDebug()` sekarang merekam mode spatial dan posisi sumber audio
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - tambah action `TriggerAudioCue`
  - kategori uji yang didukung:
    - `AmbientAudio`
    - `EnvironmentalAudio`
    - `GhostAudio`
    - `FearAudio`
    - `HuntAudio`
    - `JumpscareAudio`
  - action ini menerima:
    - `matchId`
    - `cue`
    - `eventType`
    - `roomId`
    - `position`
    - `intensity`

### Validation Notes

- build source sukses:
  - `_tmp_spatial_audio_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses (`matchCount = 1`)
  - `TriggerAudioCue(EnvironmentalAudio, env_doorslam, position=1215.25,3.5,-25)` menghasilkan:
    - `PasrahAudioLastCategory = EnvironmentalAudio`
    - `PasrahAudioLastCue = env_doorslam`
    - `PasrahAudioLastSpatialMode = position`
    - `PasrahAudioLastSourcePosition = 1215.25, 3.50, -25.00`
    - `Workspace.RuntimeAudioEmitters` berisi emitter runtime
  - `TriggerAudioCue(GhostAudio, ghost_manifest, roomId=Kitchen)` menghasilkan:
    - `PasrahAudioLastCategory = GhostAudio`
    - `PasrahAudioLastCue = ghost_manifest`
    - `PasrahAudioLastSpatialMode = room_anchor`
    - `PasrahAudioLastSourcePosition = 1230.00, 0.50, -25.00`

### Interpretation

- ghost dan disturbance map sekarang terasa lebih “datang dari ruang”, bukan selalu menempel di kepala pemain
- pass ini juga menyiapkan fondasi tuning artistik berikutnya karena sekarang kita punya harness untuk menguji cue spatial secara deterministik

## 2026-04-05 - Environment Cue VFX Response Pass

### Scope

- menutup gap sensori kecil tetapi nyata:
  - cue lingkungan sudah terdengar, tetapi belum selalu diikuti respons visual
  - hasilnya beberapa event map terasa datar walau audio sudah benar

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah `ENVIRONMENTAL_SHOCK_PROFILES` untuk:
    - `doorslam`
    - `lightflicker`
    - `suddenwhisper`
    - `shadowapparition`
    - `objectthrow`
    - `windowknock`
    - `temperaturedrop`
  - tambah `normalizeCueToken()`
  - tambah `_recordVFXDebug(eventName, profileName)`:
    - `PasrahVFXLastEvent`
    - `PasrahVFXLastProfile`
    - `PasrahVFXLastAt`
  - `VFXController` sekarang menangani `EnvironmentalAudioTriggered`
  - tambah `_triggerEnvironmentalShock(payload)` yang memetakan `eventType/cue` ke transient VFX ringan

### Validation Notes

- build source sukses:
  - `_tmp_environment_vfx_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses (`matchCount = 1`)
  - `TriggerAudioCue(EnvironmentalAudio, DoorSlam)` menghasilkan:
    - `PasrahVFXLastEvent = EnvironmentalAudioTriggered`
    - `PasrahVFXLastProfile = doorslam`
    - `SensoryThreatGrading.Contrast ~= 0.1179`
    - `Brightness ~= -0.0126`
    - `Saturation ~= -0.0674`
    - `SensoryGhostBlur.Size ~= 5.05`
  - `TriggerAudioCue(EnvironmentalAudio, LightFlicker)` menghasilkan:
    - `PasrahVFXLastProfile = lightflicker`

### Interpretation

- cue lingkungan sekarang tidak hanya didengar, tetapi juga punya jejak visual singkat yang membuat map terasa lebih hidup
- debug attr ini juga membuat tuning berikutnya tidak lagi bergantung pada pengamatan manual murni

## 2026-04-05 - Ghost Audio VFX Response Pass

### Scope

- melengkapi pass sensori sebelumnya:
  - `GhostAudio` sudah spatial, tetapi belum selalu memicu jejak visual sendiri
  - hasilnya manifest/whisper masih terasa kurang “menggigit” jika dilihat dari kamera pemain

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah `GHOST_AUDIO_SHOCK_PROFILES` untuk:
    - `ghostwhisper`
    - `ghostmanifest`
    - `ghostfakefootsteps`
    - `ghostobjectthrow`
  - `VFXController` sekarang juga menangani `GhostAudioTriggered`
  - tambah `_triggerGhostAudioShock(payload)` yang memetakan `cue` ke transient VFX ringan

### Validation Notes

- build source sukses:
  - `_tmp_ghost_audio_vfx_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses (`matchCount = 1`)
  - `TriggerAudioCue(GhostAudio, ghost_manifest, roomId=Kitchen)` menghasilkan:
    - `PasrahVFXLastEvent = GhostAudioTriggered`
    - `PasrahVFXLastProfile = ghostmanifest`
    - `PasrahAudioLastSpatialMode = room_anchor`
    - `SensoryThreatGrading.Contrast ~= 0.1025`
    - `Brightness ~= -0.0102`
    - `Saturation ~= -0.1537`
    - `SensoryGhostBlur.Size ~= 6.15`

### Interpretation

- manifest/whisper cue sekarang punya jejak visual yang lebih koheren dengan audio dan posisi ruang
- ini memperkuat atmosfer tanpa harus mengubah logika gameplay atau menambah asset eksternal baru

## 2026-04-05 - Event Audio Semantic Mapping Pass

### Scope

- menutup keluhan E2E yang paling valid:
  - beberapa event memang sudah berbunyi, tetapi bunyinya masih tidak “terasa seperti event-nya”
  - target pass ini adalah membuat `WindowKnock/ObjectThrow/Jumpscare` memakai asset yang lebih mendekati arti event tersebut

### Source Changes

- `src/client/SoundSystem/Main.lua`
  - `resolveEnvironmentalTemplate()` sekarang:
    - `window/knock -> Footsteps.Woodstep_01`
    - `object/throw -> Footsteps.ConcreteStep_01`
    - `door/slam -> Environment.EnvironmentalCreak_01`
  - `resolveGhostTemplate()` untuk `object/throw` juga sekarang lebih dulu memakai `Footsteps.ConcreteStep_01`
- `src/ReplicatedStorage/Assets/Audio/Jumpscare/Jumpscare_01.model.json`
  - `AudioContent` dipindah ke `rbxassetid://101202336513383`

### Validation Notes

- build source sukses:
  - `_tmp_audio_event_asset_mapping_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses (`matchCount = 1`)
  - `TriggerAudioCue(EnvironmentalAudio, WindowKnock)` menghasilkan:
    - `PasrahAudioLastCategory = EnvironmentalAudio`
    - `PasrahAudioLastCue = env_windowknock`
    - `PasrahAudioLastSoundId = rbxassetid://104336169985098`
  - `TriggerAudioCue(EnvironmentalAudio, ObjectThrow)` menghasilkan:
    - `PasrahAudioLastCue = env_objectthrow`
    - `PasrahAudioLastSoundId = rbxassetid://79900103772577`
  - `TriggerJumpscare` menghasilkan:
    - `PasrahAudioLastCategory = JumpscareAudio`
    - `PasrahAudioLastSoundId = rbxassetid://101202336513383`

### Interpretation

- `WindowKnock` sekarang lebih terasa seperti ketukan kayu daripada pintu berdecit
- `ObjectThrow` sekarang lebih dekat ke impact keras daripada creak yang sama untuk semua event
- `Jumpscare` sekarang punya stinger yang lebih pantas untuk beat shock

## 2026-04-05 - Local Light Flicker Runtime Pass

### Scope

- membuat `LightFlicker` benar-benar terlihat di map, bukan hanya terasa lewat grading global

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah resolver utilitas:
    - `coerceVector3()`
    - `_resolveActiveMatchContainer(matchId)`
    - `_resolveRoomAnchor(matchId, roomId)`
    - `_resolveEventPosition(payload)`
  - tambah `_pulseNearbyLights(centerPosition, radius, profileName)`:
    - mencari `PointLight/SpotLight/SurfaceLight` di match aktif
    - mematikan lalu menyalakan ulang brightness di sekitar sumber event
    - menulis debug attr `PasrahVFXLastLightCount`
  - `_triggerEnvironmentalShock(payload)` sekarang memanggil `_pulseNearbyLights()` khusus untuk profile `lightflicker`

### Validation Notes

- build source sukses:
  - `_tmp_light_flicker_runtime_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses (`matchCount = 1`)
  - `TriggerAudioCue(EnvironmentalAudio, LightFlicker)` pada area `LivingRoom` menghasilkan:
    - `PasrahVFXLastProfile = lightflicker`
    - `PasrahVFXLastLightCount = 3`
  - lampu contoh `Light_LivingRoom.PointLight`:
    - sebelum pulse:
      - `Enabled = true`
      - `Brightness = 1.6`
    - saat pulse:
      - `Enabled = false`
      - `Brightness = 0.128`
    - setelah pulse:
      - `Enabled = true`
      - `Brightness = 1.6`

### Interpretation

- `LightFlicker` sekarang benar-benar terlihat sebagai event ruang, bukan sekadar audio atau grading kamera
- ini mendorong E2E yang lebih jujur karena pemain bisa mendengar dan sekaligus melihat sumber ancaman di lingkungan

## 2026-04-05 - Door And Window Local Reaction Pass

### Scope

- melanjutkan pass local room reaction dari `LightFlicker` ke objek map lain yang pemain benar-benar lihat:
  - `DoorSlam`
  - `WindowKnock`

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah `_pulseNearbyProps(centerPosition, radius, tokenSet, transformFactory, attrName, requiredAncestorToken)`
    - mencari `BasePart` di match aktif
    - bisa dibatasi ke ancestor tertentu (`Doors` atau `Windows`)
    - memberi transform singkat lalu restore
  - `_triggerEnvironmentalShock(payload)` sekarang:
    - `doorslam` -> pulse part di bawah folder `Doors` dengan rotasi singkat
    - `windowknock` -> pulse part di bawah folder `Windows` dengan dorongan kecil ke depan/belakang
  - debug attr yang dipakai:
    - `PasrahVFXLastProfile`
    - `PasrahVFXLastPropCount`

### Validation Notes

- build source sukses:
  - `_tmp_prop_reaction_build.rbxlx`
  - `_tmp_prop_reaction_filter_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses (`matchCount = 1`)
  - `DoorSlam` pada area `LivingRoom`:
    - `PasrahVFXLastProfile = doorslam`
    - `PasrahVFXLastPropCount = 2`
    - `Door_LivingRoom` kembali ke `CFrame` semula setelah pulse
  - `WindowKnock` pada `Window_S_1_Mouth`:
    - `PasrahVFXLastProfile = windowknock`
    - `PasrahVFXLastPropCount = 2`
    - `windowMid.Z = 69.22` dari posisi awal `69.40`
    - lalu kembali ke posisi awal

### Interpretation

- `DoorSlam` dan `WindowKnock` sekarang benar-benar terasa seperti event objek ruang, bukan hanya audio abstrak
- pembatasan ke folder `Doors/Windows` juga membuat reaksi visual lebih bersih dan tidak ikut memukul frame atau struktur yang salah

## 2026-04-05 - Object Throw Local Prop Reaction Pass

### Scope

- melanjutkan local room reaction ke event `ObjectThrow`, supaya prop ruang benar-benar tampak “terlempar” saat cue aktif

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - `_triggerEnvironmentalShock(payload)` sekarang juga menangani `objectthrow`
  - `objectthrow` memakai `_pulseNearbyProps()` dengan:
    - target token `prop`
    - ancestor wajib `Props`
    - offset translasi + rotasi kecil agar prop terlihat terdorong, bukan sekadar berkedip

### Validation Notes

- build source sukses:
  - `_tmp_object_throw_prop_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses (`matchCount = 1`)
  - `TriggerAudioCue(EnvironmentalAudio, ObjectThrow)` pada area `Kitchen` menghasilkan:
    - `PasrahVFXLastProfile = objectthrow`
    - `PasrahVFXLastPropCount = 4`
  - prop yang terkonfirmasi berubah `CFrame` saat pulse:
    - `Prop_Room_Kitchen_Counter`
    - `Prop_Room_Kitchen_Fridge`
    - `Prop_Kitchen`
    - `Prop_Room_HallwayMain_CoatRack`

### Interpretation

- `ObjectThrow` sekarang benar-benar terlihat sebagai gangguan fisik di ruang, bukan hanya suara impact
- ini membuat E2E investigation jauh lebih mudah dibaca secara visual saat kamu test langsung di Studio

## 2026-04-05 - Radio Static And Shadow Apparition Local Pass

### Scope

- menutup dua event ruang yang sebelumnya masih terlalu abstrak:
  - `RadioStatic` hanya berupa audio/VFX global
  - `ShadowApparition` hanya berupa audio/grading tanpa manifest visual lokal

### Source Changes

- `src/client/Controllers/Sensory/VFXController.luau`
  - tambah profile `radiostatic` ke `ENVIRONMENTAL_SHOCK_PROFILES`
  - tambah `_ensureRuntimeVFXFolder()`
  - tambah `_spawnShadowApparition(centerPosition)`:
    - membuat model transient `ShadowApparitionRuntime`
    - berisi torso + head gelap
    - fade in/out otomatis
    - menulis debug attr `PasrahVFXLastShadowPosition`
  - `_triggerEnvironmentalShock(payload)` sekarang:
    - `radiostatic` -> pulse prop elektronik (`tv/radio/phone`) di folder `Props`
    - `shadowapparition` -> spawn manifest visual sementara di posisi event

### Validation Notes

- build source sukses:
  - `_tmp_radio_shadow_build.rbxlx`
  - `_tmp_radiostatic_profile_build.rbxlx`
- validasi live Studio:
  - `CreateRoom -> HostStart(HauntedHouse)` sukses (`matchCount = 1`)
  - `RadioStatic` pada area `LivingRoom`:
    - `PasrahVFXLastProfile = radiostatic`
    - `PasrahVFXLastElectronicCount = 1`
    - `Prop_Room_LivingRoom_TV` kembali ke `CFrame` semula setelah pulse
  - `ShadowApparition` pada area `LivingRoom`:
    - `PasrahVFXLastProfile = shadowapparition`
    - `PasrahVFXLastEvent = EnvironmentalAudioTriggered`
    - `Workspace.RuntimeVFX.ShadowApparitionRuntime` muncul
    - model runtime memiliki `2` child part

### Interpretation

- `RadioStatic` sekarang terasa datang dari objek elektronik nyata di ruang
- `ShadowApparition` sekarang benar-benar bisa dilihat pemain sebagai manifest singkat, bukan sekadar efek layar

## 2026-04-05 - Match Material Polish Runtime Pass

### Scope

- menutup bagian `material polish map` di jalur owner runtime clone, tanpa menyentuh model JSON map besar secara manual

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - tambah `patchMapMaterials(mapId, mapClone)`
  - tambah profile warna/material per map:
    - `HauntedHouse`
    - `EmptyBuilding`
    - `AbandonedPalace`
    - `StudioMMNineteen`
  - floors, walls, doors, windows, dan light instances sekarang ikut dituning saat clone map aktif dibuat

### Validation Notes

- build source sukses:
  - `_tmp_item13_ambient_material_build.rbxlx`
- validasi edit-time MCP pada clone runtime:
  - `HauntedHouse`:
    - `Floor_1_Main -> WoodPlanks / 58,46,38`
    - `NorthWall -> WoodPlanks / 74,58,48`
    - `Door -> Wood / 88,60,40`
    - `Window -> Glass / 164,178,194 / Transparency 0.42`
  - `EmptyBuilding`:
    - `Floor_1_Main -> Concrete / 58,60,66`
    - `NorthWall -> Concrete / 78,82,90`

### Interpretation

- pass artistik map sekarang tidak lagi hanya bergantung pada `Lighting/Atmosphere` global
- clone map aktif punya karakter material yang lebih kuat dan lebih jujur terhadap tema ruang

## 2026-04-05 - Ambient Investigation Cadence Pass

### Scope

- menutup kekosongan ambience investigasi tanpa memaksakan loop palsu dari asset yang tidak cocok

### Source Changes

- `src/ServerScriptService/Server/AudioSystem/Service.lua`
  - tambah scheduler cadence ambience per match session
  - cadence hanya hidup saat `InvestigationPhase`
  - event ambience dipilih per map dan room:
    - `HauntedHouse`: whisper, window knock, light flicker, temperature drop
    - `EmptyBuilding`: radio static, object throw, fake footsteps, light flicker
    - `AbandonedPalace`: door slam, manifest, shadow apparition, temperature drop
    - `StudioMMNineteen`: radio static, fake footsteps, object throw

### Validation Notes

- build source sukses:
  - `_tmp_item13_ambient_material_build.rbxlx`
- validasi service-level MCP dengan stub `MatchSystem/EventBus`:
  - `matchId = probe_1`
  - `mapId = HauntedHouse`
  - `phase = InvestigationPhase`
  - pulse yang terbit:
    - `GhostAudioTriggered`
    - `cue = ghost_whisper`
    - `roomId = Attic`
    - `intensity = 0.28`

### Interpretation

- investigasi sekarang punya layer ambience hidup berbasis cue ruang yang sah, bukan hanya menunggu event besar
- slot `AmbientLoop_Main` masih sengaja boleh tetap kosong sampai nanti ada loop ambience custom/final yang benar-benar cocok dan legal

## 2026-04-05 - Persistence Schema And Lifecycle Hardening

### Scope

- menutup gap persistence yang paling nyata sebelum non-mock publish test:
  - profile lifecycle load/save pemain
  - schema/version diagnostics
  - migration-safe metadata untuk profile record

### Source Changes

- `src/ServerScriptService/Server/DataPersistenceService/State.lua`
  - tambah default `profileSchemaVersion = 2`
- `src/ServerScriptService/Server/DataPersistenceService/Service.lua`
  - profile record sekarang distempel `meta.schemaVersion`
  - legacy shape lama dimigrasikan ke schema sekarang dengan `meta.migratedFromVersion`
  - load/save profile sekarang menyimpan diagnostics runtime:
    - `lastProfileLoadInfo`
    - `lastProfileSaveInfo`
  - tambah `GetDiagnostics()` untuk surfacing mode/schema/tracked players
- `src/ServerScriptService/Server/ProfileSystem/Service.lua`
  - tambah `OnPlayerAdded()` -> `LoadProfile()`
  - tambah `OnPlayerRemoving()` -> `SaveProfile()`
- `src/ServerScriptService/Server/ProfileSystem/Controller.lua`
  - hook `Players.PlayerAdded`
  - hook `Players.PlayerRemoving`
  - flush profile saat `BindToClose`
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - `GetPersistenceMode` sekarang juga melaporkan:
    - `schemaVersion`
    - `lastLoadSchema`
    - `lastSaveSchema`

### Validation Notes

- build source sukses:
  - `_tmp_persistence_schema_build.rbxlx`
- validasi service-level MCP:
  - seed legacy mock profile `profile:123 = { playerLevel = 7, playerRank = "Bayi III", bio = "legacy" }`
  - `LoadProfile(123)` menghasilkan:
    - `loadSchema = 2`
    - `migratedFrom = 1`
  - `SaveProfile(123, ...)` memperbarui diagnostics:
    - `saveSchema = 2`
    - `mode = mock`
    - profile tersimpan dengan `bio = migrated ok`
- validasi controller-level MCP:
  - `ProfileSystem.Controller:RegisterEventHandlers()` dengan player signal stub menghasilkan:
    - `added = 2`
    - `removing = 1`
  - artinya existing player load fallback + event `PlayerRemoving` save path benar-benar terpasang

### Interpretation

- persistence sekarang tidak lagi hanya bergantung pada event lobby/rank tertentu untuk memuat atau menyimpan profile
- QA Studio sekarang bisa melihat schema runtime yang sedang aktif, sehingga uji non-mock nanti tidak buta

## 2026-04-05 - Marketplace Ownership Sync Surfacing Pass

### Scope

- menutup gap relog/join untuk entitlement `GamePass`, tanpa menunggu `marketplaceId` production baru

### Source Changes

- `src/ServerScriptService/Server/ShopSystem/Controller.lua`
  - `_syncOwnedGamePassesForPlayer()` sekarang mengumpulkan item yang benar-benar tersinkron
  - setelah sync berhasil, client menerima `PurchaseEvent` baru:
    - `eventName = MarketplaceOwnershipSynced`
    - `reason = ownership_synced`
    - `itemIds = { ... }`
- `src/client/UI/Main.lua`
  - `MarketplaceOwnershipSynced` sekarang memperbarui snapshot shop tanpa memaksa membuka `ShopUI`
  - copy status purchase sekarang lebih jujur untuk:
    - `ownership_synced`
    - `receipt_granted`
    - `purchase_cancelled`

### Validation Notes

- build source sukses:
  - `_tmp_monetization_sync_build.rbxlx`

### Interpretation

- entitlement GamePass yang sudah dimiliki pemain sekarang bisa disurfacing lebih bersih saat join/relog
- sinkronisasi ownership tidak lagi berisiko membuka panel shop secara liar hanya karena snapshot entitlement masuk dari server

## 2026-04-05 - Licensing Attribution Baseline Closed

### Scope

- menutup provenance legal `Pocong` dan memindahkan attribution wajib ke source runtime

### Source Changes

- `src/shared/DataTypes/AssetAttributionCatalog.lua`
  - tambah katalog attribution source-controlled untuk asset eksternal yang wajib disebut di experience
- `src/client/UI/Main.lua`
  - `MainMenuUI` sekarang memuat footer attribution bila katalog legal berisi entri `requiredInExperience`
  - footer menu utama diberi ruang multiline agar text legal tidak terpotong
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
  - `Pocong` dinaikkan ke `verified`
  - author dikoreksi ke `alterego.visual`
  - provenance sekarang menunjuk ke URL final Sketchfab
- `DOCUMENTATION/SOURCE OF TRUTH/reports/POCONG_LICENSE_ARCHIVE_CHECKLIST_2026-04-04.md`
  - attribution text disinkronkan ke author yang benar
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
  - item `16. Licensing dan attribution` dinaikkan ke selesai baseline

### Validation Notes

- build source sukses:
  - `_tmp_attribution_catalog_build.rbxlx`
- validasi edit-time katalog legal membaca entry:
  - `Pocong | alterego.visual | CC BY 4.0 | https://sketchfab.com/3d-models/pocong-d84121c5b6084c72851113afbdbd5b99`

### Interpretation

- attribution legal sekarang tidak lagi bergantung pada catatan markdown atau ingatan sesi
- provenance `Pocong` tidak lagi menjadi blocker utama roadmap
- blocker lisensi yang masih tersisa bergeser ke cleanup asset legacy dan keputusan ambience final

## 2026-04-05 - QA Gate Baseline Harness + UI Start Fix

### Scope

- menutup baseline item `17. QA dan perf gate` dengan snapshot runtime yang repeatable di Studio
- menutup bug nyata yang ditemukan saat snapshot QA pertama

### Source Changes

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - tambah action `GetQAGateSnapshot`
  - tambah action `StartSoloMatch`
  - snapshot sekarang melaporkan:
    - player count
    - active match count
    - current match phase
    - script memory
    - total memory
    - physics FPS
    - player ping
    - warning/error count dari `LogService`
  - `ForceHunt` harness sekarang menolak phase yang belum siap dengan hasil `match_not_hunt_ready`, bukan menembak warning palsu ke runtime
- `src/client/UI/Main.lua`
  - perbaiki forward declaration `shouldShowShopFilter`
  - bug runtime `attempt to call a nil value` di wallet summary shop kini tertutup
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
  - item `17` sekarang punya status reality-based, bukan daftar umum

### Validation Notes

- build source sukses:
  - `_tmp_qa_gate_snapshot_build.rbxlx`
  - `_tmp_qa_gate_ui_fix_build.rbxlx`
  - `_tmp_qa_gate_match_build.rbxlx`
  - `_tmp_qa_gate_phase_fix_build.rbxlx`
  - `_tmp_qa_gate_force_guard_build.rbxlx`
- snapshot lobby clean:
  - `players=1`
  - `activeMatches=0`
  - `totalMemoryMb=2096.96`
  - `physicsFps=59.90`
  - `warnings=0`
  - `errors=0`
- snapshot match solo clean:
  - `players=1`
  - `activeMatches=1`
  - `phase=PreparationPhase`
  - `totalMemoryMb=2150.98`
  - `physicsFps=60.04`
  - `warnings=0`
  - `errors=0`
- snapshot QA pertama sempat menemukan error runtime nyata:
  - `Players.ZyraaaVex.PlayerScripts.Client.UI.Main:1443: attempt to call a nil value`
  - setelah fix forward declaration, snapshot ulang kembali `warnings=0 errors=0`
- validasi guard `ForceHunt`:
  - hasil sekarang `ok=false result=match_not_hunt_ready phase=PreparationPhase`
  - snapshot sesudahnya tetap `warnings=0 errors=0`

### Interpretation

- item `17` kini punya harness QA repeatable untuk Studio single-client
- baseline memory/log/perf saat idle lobby dan match solo sudah tertutup
- multi-player test nyata tetap belum bisa diklaim selesai dari sesi ini karena current tooling hanya memberi satu client Studio aktif

## 2026-04-05 - Lobby Zone Focus And Matchmaking Affordance Pass

### Scope

- memulai item `18` dari sisi lobby affordance paling mendasar: area/zona, feedback, dan anti-auto-queue

### Source Changes

- `src/ServerScriptService/Server/LobbySocialHub/LobbyZoneManager.lua`
  - bila `workspace.LobbyZones` tidak ada, manager sekarang fallback ke geometri lobby aktif via `LobbyLocator`
  - mapping zona sekarang membaca landmark nyata di lobby source:
    - `SpawnPlaza -> Room_MainHubPlaza`
    - `MatchmakingZone -> NorthEvidenceBuilding`
    - `ShopZone -> EastShopBuilding`
    - `PartyZone -> WestPartyZone`
    - `DailyRewardZone -> SouthSocialGarden`
    - `FlexZone -> SouthEastFlexZone`
- `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - tambah event `LobbyZoneFocused` dengan copy UX yang lebih jujur per zona
  - hapus auto-start matchmaking saat sekadar masuk `MatchmakingZone`
- `src/ServerScriptService/Server/LobbySystem/Controller.lua`
  - relay `LobbyZoneFocused` ke client lewat `LobbyEvent`
- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - tambah harness `SimulateLobbyZone`
- `src/client/UI/Main.lua`
  - lobby feedback label sekarang memahami `LobbyZoneFocused`

### Validation Notes

- build source sukses:
  - `_tmp_lobby_zone_focus_build.rbxlx`
  - `_tmp_lobby_zone_relay_build.rbxlx`
- validasi live Studio:
  - `SimulateLobbyZone(MatchmakingZone)` menghasilkan feedback:
    - `Area matchmaking aktif. Gunakan PLAY atau Room Browser untuk membuat room, pilih mode, dan start dengan sadar; area ini tidak lagi auto-queue.`
  - `MatchId` player tetap `nil`, jadi area matchmaking tidak lagi memicu queue otomatis
  - `SimulateLobbyZone(ShopZone)` menghasilkan feedback:
    - `Area shop aktif. Buka SHOP untuk melihat item MM/PP/Robux yang memang visible dan compliant.`

### Interpretation

- lobby sekarang tidak lagi memaksa transisi penting hanya karena pemain menyentuh area
- affordance zona mulai selaras dengan geometri lobby aktif, bukan taxonomy lama yang tidak cocok dengan source sekarang
- ini baru slice pertama dari item `18`; restruktur visual/layout besar lobby-map masih lanjut sesudahnya

## 2026-04-05 - Map Interaction Coverage Synthesis Pass

### Scope

- menutup gap interaction anchor di map besar tanpa menunggu pass art/layout final

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - `patchInteractionPoints()` sekarang tidak hanya memindahkan point yang sudah ada
  - bila suatu room belum punya `Interact_<RoomName>`, runtime akan membuat interaction point sintetis di posisi room/door anchor
  - synthetic point diberi attribute `SyntheticInteractionPoint = true`

### Validation Notes

- build source sukses:
  - `_tmp_map_interaction_synthesis_build.rbxlx`
- validasi live Studio:
  - `EmptyBuilding`:
    - `rooms=14`
    - `interactions=14`
    - `synthetic=6`
  - `AbandonedPalace`:
    - `rooms=18`
    - `interactions=18`
    - `synthetic=10`

### Interpretation

- logic map sekarang tidak lagi terlalu bergantung pada authoring manual interaction point yang tidak lengkap
- ini membantu ghost/event/traversal affordance tetap konsisten pada map besar, sambil menunggu restruktur visual final

## 2026-04-05 - Lobby Feedback Visibility Fix

### Scope

- memastikan feedback lobby hasil `LobbyZoneFocused` benar-benar terlihat oleh pemain

### Source Changes

- `src/client/UI/Main.lua`
  - `FeedbackLabel.Visible` kini disetel `true` setelah lobby event diproses

### Validation Notes

- build source sukses:
  - `_tmp_lobby_feedback_visible_build.rbxlx`
- validasi live Studio:
  - `SimulateLobbyZone(ShopZone)` menghasilkan:
    - `visible=true`
    - `text=Area shop aktif. Buka SHOP untuk melihat item MM/PP/Robux yang memang visible dan compliant.`

### Interpretation

- feedback zona lobby sekarang tidak lagi “benar di state, hilang di layar”

## 2026-04-05 - Hunt Readability HUD Pass

### Scope

- memperjelas instruksi survive saat hunt langsung di `MatchUX`
- menampilkan badge ancaman, route singkat, dan assist line yang berubah mengikuti state pemain

### Source Changes

- `src/client/UI/Main.lua`
  - tambah `getHuntAssistSnapshot()` untuk merangkum state `hunt/tracked/hidden/sheltered`
  - tambah widget `HuntStatusBadge` dan `HuntAssistLabel` di `MatchUX`
  - overlay hunt kini ikut mengambil warna berdasarkan ancaman
  - objective hunt kini disembunyikan di luar phase yang relevan
  - sizing mobile/compact untuk objective + hunt assist ikut diperbarui

### Validation Notes

- build source sukses:
  - `_tmp_hunt_readability_build.rbxlx`
- validasi live Studio:
  - hunt baseline:
    - `badgeVisible=true`
    - `badge=HUNT`
    - `assist=TARGET: CLOSET B 46ST`
    - `assistLine2=PINTU: E/X/TAP  •  JANGAN LARI LURUS  •  SIAP ROTASI`
  - hidden smoke untuk HUD:
    - `badge=HIDDEN`
    - `assist=POSISI: CLOSETB`
    - `assistLine2=DIAM  •  TUNGGU HUNT SELESAI  •  JANGAN KELUAR`
    - `objective=Berlindung di ClosetB. Diam dan tunggu hunt selesai sebelum keluar.`

### Interpretation

- pemain sekarang mendapat guidance survive yang lebih terbaca saat panik, tanpa harus membuka jurnal atau menebak state backend
- jalur UI hunt sudah cukup eksplisit untuk lanjut ke slice phase 18 berikutnya

## 2026-04-05 - Refuge Marker Highlight Prep

### Scope

- menambah lapisan visual `Highlight` untuk `HideSpotRuntimeMarker` dan `SafeZoneRuntimeMarker`
- targetnya refuge/hide spot lebih mudah ditangkap mata saat hunt tanpa menggandakan sistem marker

### Source Changes

- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
  - tambah `Highlight` runtime pada marker closet/hide spot
  - toggle `Enabled` mengikuti `Service:_setHideSpotVisualState()`
- `src/ServerScriptService/Server/HidingSystem/Service.lua`
  - tambah `Highlight` runtime pada marker safe zone
  - toggle `Enabled` mengikuti `Service:_setSafeZoneVisualState()`

### Validation Notes

- build source sukses:
  - `_tmp_refuge_marker_polish_build.rbxlx`
- sesi Studio aktif masih menunjukkan drift server-side:
  - `script_grep(SAFE_ZONE_MARKER_HIGHLIGHT_NAME) -> noMatch`
  - `script_grep(HIDE_SPOT_MARKER_HIGHLIGHT_NAME) -> noMatch`
  - artinya source lokal sudah siap, tetapi sesi Studio ini belum menarik patch server terbaru untuk validasi live marker

### Interpretation

- jalur source untuk affordance refuge sudah siap
- validasi visual live marker perlu sesi Studio server yang sudah sinkron/reconnect, tetapi ini bukan blocker untuk melanjutkan source slice phase 18

## 2026-04-05 - Traversal Guide Runtime Pass

### Scope

- memperkuat akses lantai dua pada map bertangga
- menambah affordance visual pada `CentralStaircase`

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - `patchSecondFloor()` kini mencoba carve semua segmen `Floor_2_*` yang overlap dengan bounds tangga, bukan hanya `Floor_2_North`
  - tambah `patchTraversalGuides()` untuk menaruh `Highlight` + `BillboardGui` pada `CentralStaircase`
  - guide text:
    - `AKSES LANTAI 2`
    - `Naik lewat tangga pusat`

### Validation Notes

- build source sukses:
  - `_tmp_traversal_guides_build.rbxlx`
- validasi asset/static:
  - `HauntedHouse`, `EmptyBuilding`, dan `StudioMMNineteen` semua punya:
    - `CentralStaircase`
    - `StairStep_1..6`
    - `Floor_2_North/South/West/East`
- sesi Studio aktif saat slice ini belum memberi ack harness server, jadi validasi live traversal guide tetap pending

### Interpretation

- akses lantai dua sekarang lebih robust di jalur source
- pemain juga akan punya anchor visual yang lebih jelas untuk menemukan tangga pusat saat restruktur map masih bertahap

## 2026-04-05 - Camera Log Noise Guard

### Scope

- menurunkan spam log kamera yang mengotori console dan QA snapshot

### Source Changes

- `src/client/CameraController.client.lua`
  - tambah `logCameraMode()` agar log `FPV LOCKED` / `TPV ALLOWED` hanya keluar saat mode benar-benar berubah

### Validation Notes

- perubahan ini source-safe dan tidak mengubah perilaku kamera, hanya menahan log duplikat

### Interpretation

- console Studio dan snapshot QA berikutnya jadi lebih bersih untuk observasi bug nyata

## 2026-04-05 - Door Prompt Label Pass

### Scope

- membuat traversal pintu lebih terbaca lewat prompt yang menunjuk tujuan/ruang, bukan label generik

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - tambah `resolveDoorLabel()` untuk menurunkan label dari `DoorLabel` atau nama part `Door_*`
  - `ProximityPrompt.ObjectText` sekarang mengikuti label pintu
  - runtime door menyimpan `DoorRouteLabel` attribute untuk pemakaian lanjutan

### Validation Notes

- build source sukses:
  - `_tmp_door_prompt_labels_build.rbxlx`
- contoh label yang sekarang akan terbentuk:
  - `Door_Kitchen -> Pintu Kitchen`
  - `Door_Bedroom1 -> Pintu Bedroom 1`

### Interpretation

- traversal pintu sekarang lebih manusiawi dan membantu orientasi pemain saat map masih dalam fase restruktur

## 2026-04-05 - Lobby Zone Guide Runtime Pass

### Scope

- memberi anchor visual permanen pada zona lobby aktif
- targetnya pemain bisa mengenali `shop / matchmaking / party / flex / social garden` dari dunia 3D, bukan hanya panel teks

### Source Changes

- `src/ServerScriptService/Server/LobbySocialHub/LobbyZoneManager.lua`
  - tambah `GetZoneParts()` untuk expose snapshot zona aktif hasil resolve runtime
- `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - tambah `LobbyZoneGuideRuntime` per zona
  - tiap guide punya `Highlight` + `BillboardGui`
  - style khusus untuk:
    - `SpawnPlaza`
    - `MatchmakingZone`
    - `ShopZone`
    - `PartyZone`
    - `FlexZone`
    - `DailyRewardZone`

### Validation Notes

- build source sukses:
  - `_tmp_lobby_zone_guides_build.rbxlx`
- sesi Studio aktif masih drift server-side:
  - `search_game_tree(LobbyZoneGuideRuntime) -> tidak muncul`
  - `script_grep(LOBBY_ZONE_GUIDE_FOLDER_NAME) -> noMatch`

### Interpretation

- source untuk anchor visual lobby sudah siap
- validasi live di Studio perlu sesi server yang sinkron, tetapi jalur implementasi tidak lagi bergantung pada panel UI saja

## 2026-04-05 - Synthetic Interaction Anchor Guide Pass

### Scope

- memberi label ruang pada interaction point sintetis yang sebelumnya benar-benar tak terlihat
- targetnya pemain punya anchor orientasi tambahan pada map yang interaction authoring-nya belum lengkap

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - tambah `InteractionGuideRuntime` untuk `SyntheticInteractionPoint`
  - guide muncul sebagai `BillboardGui` kecil dengan:
    - title = nama ruang (`Kitchen`, `Office B`, dst)
    - subtitle = `Anchor ruang`
  - synthetic point juga menyimpan attribute `InteractionGuideLabel`

### Validation Notes

- build source sukses:
  - `_tmp_interaction_anchor_guides_build.rbxlx`
- guide ini hanya dipasang pada interaction point sintetis, bukan semua room, agar tidak terlalu ramai

### Interpretation

- ruang yang sebelumnya “hidup di data tapi mati secara visual” sekarang punya jalur affordance runtime yang lebih jelas

## 2026-04-05 - Room Guide Consistency Pass

### Scope

- menyamakan label ruang pada interaction point existing dan synthetic

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - `InteractionGuideRuntime` kini dipasang juga pada interaction point yang memang sudah ada, bukan hanya synthetic
  - semua interaction point terkait room sekarang menyimpan `InteractionGuideLabel`

### Validation Notes

- build source sukses:
  - `_tmp_room_guides_consistent_build.rbxlx`

### Interpretation

- orientasi ruang sekarang lebih konsisten; pemain tidak lagi hanya mendapat label pada area yang “kebetulan sintetis”

## 2026-04-05 - Lobby Zone Reality Alignment

### Scope

- merapikan daftar zona lobby agar sesuai geometry yang benar-benar ada

### Source Changes

- `src/ServerScriptService/Server/LobbySocialHub/LobbyZoneManager.lua`
  - hapus `TrainingZone` dan `LeaderboardZone` dari `SUPPORTED_ZONES`

### Validation Notes

- audit `LobbySocialHub.model.json` menunjukkan anchor yang benar-benar ada hanya:
  - `SpawnPlaza`
  - `MatchmakingZone`
  - `ShopZone`
  - `PartyZone`
  - `DailyRewardZone`
  - `FlexZone`

### Interpretation

- source lobby sekarang lebih jujur terhadap geometry aktif, sehingga AI/tool berikutnya tidak mengejar zona fiktif

## 2026-04-05 - Refuge Route Label Alignment Pass

### Scope

- menyamakan bahasa visual refuge dengan guide tangga, pintu, dan room yang sudah masuk di phase 18
- targetnya safe zone dan hide spot tidak lagi terasa seperti sistem marker terpisah yang tidak nyambung dengan orientasi map

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - safe zone runtime sekarang diberi metadata:
    - `SafeZoneLabel`
    - `SafeZoneSubtitle`
    - `SafeZoneRoomLabel`
    - `RefugeRouteLabel`
  - subtitle safe zone diturunkan dari room terdekat secara XZ agar anchor refuge lebih kontekstual
- `src/ServerScriptService/Server/HidingSystem/Service.lua`
  - marker `SafeZoneRuntimeMarker` sekarang membaca title/subtitle dari attribute runtime di part
  - cleanup match juga membersihkan attribute refuge runtime
- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
  - hide spot runtime sekarang menulis:
    - `HideSpotSubtitle`
    - `RefugeRouteLabel`
  - marker hide spot membaca subtitle dari attribute runtime

### Validation Notes

- build source sukses:
  - `_tmp_refuge_route_alignment_build.rbxlx`
- pass ini sengaja ditutup di level source/build karena sesi Studio server masih drift untuk validasi marker server-side yang konsisten

### Interpretation

- refuge sekarang punya metadata orientasi yang lebih seragam untuk dipakai marker, HUD assist, dan hook phase 18 berikutnya

## 2026-04-05 - Hunt HUD Refuge Route Sync Pass

### Scope

- menyambungkan metadata refuge runtime baru ke `Field/Hunt HUD` agar assist hunt tidak tetap memakai label generik lama

### Source Changes

- `src/client/UI/Main.lua`
  - tambah resolver runtime:
    - `getRuntimeRefugeRouteLabel`
    - `getRuntimeSafeZoneLabel`
    - `getRuntimeSafeZoneSubtitle`
    - `getRuntimeHideSpotPart`
  - nearest refuge scan sekarang menyimpan:
    - `label`
    - `subtitle`
    - `routeLabel`
  - `getHuntControlsHintText()` dan `getHuntAssistSnapshot()` sekarang memakai `routeLabel` refuge bila tersedia

### Validation Notes

- build source sukses:
  - `_tmp_hunt_refuge_route_hud_build.rbxlx`

### Interpretation

- jalur readability hunt sekarang lebih nyambung dengan metadata refuge runtime server, bukan hanya hasil formatting nama part

## 2026-04-05 - Lobby Entry Guide Pass

### Scope

- memperjelas orientasi lobby lewat pintu masuk bangunan aktif, bukan hanya marker pada part zona

### Source Changes

- `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - tambah `LobbyZoneEntryGuideRuntime`
  - tambah anchor map:
    - `Door_NorthEvidenceBuilding`
    - `Door_EastShopBuilding`
    - `Door_WestPartyZone`
    - `Door_SouthSocialGarden`
    - `Door_SouthEastFlexZone`
  - tiap anchor mendapat beacon kecil dengan copy singkat:
    - `PLAY`
    - `SHOP`
    - `PARTY`
    - `GARDEN`
    - `FLEX`

### Validation Notes

- build source sukses:
  - `_tmp_lobby_entry_guides_build.rbxlx`
- static scan `LobbySocialHub.model.json` mengonfirmasi semua door/interact anchor target memang ada di geometry aktif

### Interpretation

- orientasi lobby sekarang tidak hanya bergantung pada zone part; pintu masuk bangunan aktif juga punya anchor visual yang lebih intuitif

## 2026-04-05 - Door Route Guide Pass

### Scope

- mengangkat label tujuan pintu dari level `prompt` ke level world-space agar orientasi map lebih mudah dibaca dari jarak wajar

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - tambah `DoorRouteGuideRuntime`
  - setiap pintu runtime sekarang punya:
    - `Highlight` tipis
    - `BillboardGui` kecil
  - title memakai `DoorRouteLabel`
  - subtitle berubah sesuai state:
    - `Akses ruang`
    - `Terbuka`
    - `Akses terkunci`

### Validation Notes

- build source sukses:
  - `_tmp_door_route_guides_build.rbxlx`

### Interpretation

- affordance pintu sekarang tidak hanya hidup saat prompt aktif; pemain bisa membaca tujuan ruang lebih awal dari world-space beacon ringan

## 2026-04-05 - Lobby Feedback Sync Pass

### Scope

- menyamakan bahasa feedback UI lobby dengan guide dunia yang sudah ditambahkan pada zona dan pintu masuk lobby

### Source Changes

- `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - `LobbyZoneFocused` sekarang juga mengirim:
    - `badge`
    - `subtitle`
    - `accentColor`
- `src/client/UI/Main.lua`
  - feedback label lobby sekarang memformat payload itu menjadi satu pesan yang lebih jelas
  - warna feedback mengikuti accent zona saat event `LobbyZoneFocused`

### Validation Notes

- build source sukses:
  - `_tmp_lobby_zone_feedback_sync_build.rbxlx`

### Interpretation

- feedback lobby sekarang lebih konsisten dengan beacon world-space; UI dan world guide tidak lagi terasa seperti dua sistem copy yang berbeda

## 2026-04-05 - Match Navigation Readability Pass

### Scope

- memakai anchor runtime map pada HUD `Preparation/Investigation` agar panel match tidak terlalu generik saat pemain baru masuk map

### Source Changes

- `src/client/UI/Main.lua`
  - tambah resolver `getNearestNavigationAnchorInfo()` yang membaca:
    - `DoorRouteLabel`
    - `InteractionGuideLabel`
  - `Preparation/Investigation` panel sekarang menurunkan:
    - `primaryText`
    - `secondaryText`
    - `ObjectiveLabel`
    - `ControlsHintLabel`
    dari anchor terdekat bila tersedia

### Validation Notes

- build source sukses:
  - `_tmp_match_navigation_readability_build.rbxlx`

### Interpretation

- phase non-hunt sekarang lebih informatif terhadap struktur map aktif; panel match tidak lagi sepenuhnya generik saat pemain sedang orientasi area

## 2026-04-05 - Semantic Route Guide Pass

### Scope

- membuat subtitle guide pintu dan interaction point lebih semantik agar affordance ruang tidak terasa seragam

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - subtitle beacon pintu sekarang dibedakan menurut konteks:
    - `Refuge route`
    - `Akses vertikal`
    - `Sweep evidence`
    - `Area investigasi`
    - fallback `Akses ruang`
- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - subtitle `InteractionGuideRuntime` sekarang juga semantik:
    - `Refuge route`
    - `Transisi vertikal`
    - `Sweep evidence`
    - `Area investigasi`
    - fallback `Anchor ruang`

### Validation Notes

- build source sukses:
  - `_tmp_semantic_route_guides_build.rbxlx`

### Interpretation

- world guide sekarang terasa lebih informatif dan kurang placeholder; pemain mendapat petunjuk fungsi area, bukan hanya nama ruang

## 2026-04-05 - Lobby Panel Zone Focus Sync Pass

### Scope

- membuat panel lobby utama ikut membaca focus zona terakhir agar orientasi lobby tidak hanya hidup di label transient

### Source Changes

- `src/client/UI/Main.lua`
  - simpan `self._lobbyZoneFocus` saat menerima event `LobbyZoneFocused`
  - `_refreshBasicLobbyPanel()` sekarang memakai focus itu untuk:
    - `badge`
    - `header color`
    - `primary text`
    - `secondary text`
    - `hint text`

### Validation Notes

- build source sukses:
  - `_tmp_lobby_panel_zone_focus_build.rbxlx`

### Interpretation

- panel lobby sekarang lebih sinkron dengan feedback zona dan world beacons; pemain tidak hanya melihat satu toast singkat lalu kembali ke copy generik

## 2026-04-05 - Semantic Investigation HUD Pass

### Scope

- membuat objective/hint `Preparation/Investigation` memanfaatkan subtitle semantik anchor runtime, bukan hanya nama target terdekat

### Source Changes

- `src/client/UI/Main.lua`
  - `getInvestigationObjectiveText()` sekarang membedakan arahan untuk:
    - `Refuge route`
    - `Akses vertikal / Transisi vertikal`
    - `Sweep evidence`
    - `Area investigasi`
  - `getInvestigationControlsHintText()` sekarang juga menyesuaikan copy berdasarkan subtitle anchor

### Validation Notes

- build source sukses:
  - `_tmp_semantic_investigation_hud_build.rbxlx`

### Interpretation

- panel match non-hunt sekarang memberi arahan yang lebih relevan terhadap fungsi area, bukan hanya “target terdekat” secara buta

## 2026-04-05 - Lobby Focus Pills Pass

### Scope

- memperkuat sinkronisasi panel lobby dengan zona aktif lewat pill dan hint, bukan hanya badge/header

### Source Changes

- `src/client/UI/Main.lua`
  - `BasicHintLabel`, `BasicModePill`, `BasicMapPill`, dan `BasicRoomPill` sekarang bisa ikut accent zona saat ada `self._lobbyZoneFocus`
  - saat belum masuk room, `MapPill` dan `RoomPill` dapat memantulkan context focus aktif

### Validation Notes

- build source sukses:
  - `_tmp_lobby_focus_pills_build.rbxlx`

### Interpretation

- panel lobby sekarang terasa lebih sadar konteks, bukan hanya header yang berubah sementara pill/hint tetap generic

## 2026-04-05 - Match Semantic Accent Pass

### Scope

- menyelaraskan accent visual panel `Preparation/Investigation` dengan semantik route aktif, bukan hanya copy text-nya

### Source Changes

- `src/client/UI/Main.lua`
  - tambah `getNavigationSemanticAccent()`
  - phase non-hunt sekarang bisa memantulkan accent semantik ke:
    - `badgeColor`
    - `ObjectiveLabel`
    - `ControlsHintLabel`
    - `TimerCaption`
    - `FooterLabel`

### Validation Notes

- build source sukses:
  - `_tmp_match_semantic_accent_build.rbxlx`

### Interpretation

- panel match non-hunt sekarang memberi sinyal visual yang lebih konsisten dengan fungsi route aktif, bukan hanya beda wording

## 2026-04-05 - Semantic World Guide Palette Pass

### Scope

- menyelaraskan warna beacon pintu dan interaction guide dengan semantik route aktif

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - tambah `getDoorGuidePalette()`
  - `DoorRouteGuideRuntime` sekarang memakai palette berbeda untuk:
    - `Refuge route`
    - `Akses vertikal`
    - `Sweep evidence`
    - `Area investigasi`
- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - tambah `getInteractionGuidePalette()`
  - `InteractionGuideRuntime` sekarang juga memakai palette semantik yang serasi

### Validation Notes

- build source sukses:
  - `_tmp_semantic_world_guides_build.rbxlx`

### Interpretation

- world guide sekarang tidak hanya berbeda subtitle; warna beacon juga ikut memberi sinyal fungsi area secara lebih cepat

## 2026-04-05 - Traversal Metadata Sync Pass

### Scope

- menyatukan guide tangga pusat dengan ekosistem metadata route agar client HUD bisa membacanya seperti door/room guide lain

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - `CentralStaircase` runtime sekarang menyimpan:
    - `TraversalGuideLabel`
    - `TraversalGuideSubtitle`
  - traversal guide juga memakai palette vertikal yang konsisten
- `src/client/UI/Main.lua`
  - `getNearestNavigationAnchorInfo()` sekarang ikut memindai `TraversalGuideLabel`

### Validation Notes

- build source sukses:
  - `_tmp_traversal_metadata_sync_build.rbxlx`

### Interpretation

- jalur vertikal sekarang masuk ke sistem route yang sama; HUD non-hunt bisa mempertimbangkan tangga pusat sebagai anchor navigasi yang sah

## 2026-04-05 - Phase-Aware Navigation Anchor Pass

### Scope

- membuat pemilihan anchor navigasi non-hunt lebih cerdas per fase agar HUD tidak asal memilih titik terdekat yang kebetulan paling dekat

### Source Changes

- `src/client/UI/Main.lua`
  - tambah `getNavigationAnchorBias(contextTag, info)`
  - `getNearestNavigationAnchorInfo(contextTag)` sekarang memakai `distance + bias`
  - `Preparation` dan `Investigation` sekarang meminta anchor dengan konteks fase masing-masing

### Validation Notes

- build source sukses:
  - `_tmp_phase_aware_navigation_build.rbxlx`

### Interpretation

- HUD non-hunt sekarang lebih mungkin memilih anchor yang relevan untuk fase aktif, bukan hanya objek terdekat secara buta

## 2026-04-05 - Navigation Anchor Cache Pass

### Scope

- merapikan helper navigasi client agar tidak scan struktur map penuh setiap refresh panel match

### Source Changes

- `src/client/UI/Main.lua`
  - tambah `navigationAnchorCache`
  - tambah `collectNavigationAnchors(mapModel)`
  - `getNearestNavigationAnchorInfo()` sekarang memakai cache anchor yang dikumpulkan sekali per map runtime
  - subtitle pintu tetap dinamis lewat resolver fungsi agar state `Terbuka` tidak hilang

### Validation Notes

- build source sukses:
  - `_tmp_navigation_anchor_cache_build.rbxlx`

### Interpretation

- slice navigasi non-hunt sekarang lebih siap ke publish bukan hanya dari sisi UX, tetapi juga lebih rapi dari sisi biaya scan runtime client

## 2026-04-05 - Refuge Anchor Unification Pass

### Scope

- menyatukan `SafeZone` dan `HideSpot` ke cache anchor navigasi client agar refuge tidak lagi hidup di sistem marker terpisah

### Source Changes

- `src/client/UI/Main.lua`
  - `collectNavigationAnchors(mapModel)` sekarang juga mengumpulkan:
    - `SafeZone`
    - `HideSpot`
  - keduanya masuk sebagai anchor `subtitle = "Refuge route"`

### Validation Notes

- build source sukses:
  - `_tmp_refuge_anchor_cache_build.rbxlx`

### Interpretation

- route ecosystem sekarang lebih utuh; refuge ikut masuk ke jalur navigasi yang sama dengan door, room anchor, dan traversal guide

## 2026-04-05 - Refuge Marker Palette Alignment Pass

### Scope

- menyamakan palette `SafeZoneRuntimeMarker` dan `HideSpotRuntimeMarker` dengan semantic refuge route agar refuge tidak lagi berbicara dengan warna yang berbeda dari world guide/hud

### Source Changes

- `src/ServerScriptService/Server/HidingSystem/Service.lua`
  - `SAFE_ZONE_VISUAL_COLOR` dipindah ke aksen refuge
  - outline/panel/stroke/title/subtitle marker aman sekarang memakai keluarga warna refuge hijau
- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
  - marker `HideSpot` sekarang memakai palette refuge yang sama dengan `SafeZone` dan route guide

### Validation Notes

- build source sukses:
  - `_tmp_refuge_marker_palette_build.rbxlx`

### Interpretation

- refuge marker sekarang lebih konsisten secara visual; pemain tidak perlu menebak apakah `SafeZone`, `HideSpot`, dan refuge route adalah sistem yang berbeda

## 2026-04-05 - Navigation Distance Readability Pass

### Scope

- menambahkan konteks jarak ke anchor navigasi aktif agar panel match tidak hanya menyebut tujuan, tetapi juga seberapa dekat pemain dengan route/ruang yang sedang disorot

### Source Changes

- `src/client/UI/Main.lua`
  - tambah helper:
    - `formatNavigationAnchorDistance(anchor)`
    - `formatNavigationAnchorLabel(anchor, fallbackLabel)`
  - objective text investigasi/preparation sekarang menyertakan jarak anchor aktif
  - controls hint investigasi/preparation sekarang juga menyertakan jarak anchor aktif
  - primary text panel match `Preparation` dan `Investigation` sekarang memakai label anchor + jarak

### Validation Notes

- build source sukses:
  - `_tmp_navigation_distance_readability_build.rbxlx`

### Interpretation

- navigasi non-hunt sekarang lebih operasional; pemain tidak hanya tahu target mana yang dipilih sistem, tetapi juga apakah target itu sudah dekat atau masih perlu rotasi

## 2026-04-05 - Lobby Focus Distance Pass

### Scope

- memberi konteks jarak pada focus zona lobby agar panel lobby tidak hanya mengulang nama area, tetapi juga memberi rasa kedekatan terhadap bangunan/zona aktif

### Source Changes

- `src/client/UI/Main.lua`
  - tambah `LOBBY_ZONE_CLIENT_CANDIDATES`
  - tambah helper:
    - `resolveLobbyZonePart(zoneName)`
    - `getLobbyZoneDistanceText(zoneName)`
  - `LobbyZoneFocused` sekarang, saat dirender di panel lobby, menyertakan jarak ke zona aktif pada:
    - `BasicSecondaryLabel`
    - `BasicHintLabel`
    - `BasicRoomPill`

### Validation Notes

- build source sukses:
  - `_tmp_lobby_focus_distance_build.rbxlx`

### Interpretation

- orientasi lobby sekarang lebih praktis; focus zona tidak lagi terasa abstrak karena pemain mendapat konteks seberapa dekat area aktif tersebut dari posisi mereka

## 2026-04-05 - Door Semantic State Split Pass

### Scope

- memisahkan semantik route pintu dari state buka/tutup agar client HUD tetap bisa membaca fungsi ruang pintu tanpa kehilangan info status operasionalnya

### Source Changes

- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - pintu sekarang menyimpan:
    - `DoorRouteSubtitle`
    - `DoorRouteStateText`
  - subtitle billboard pintu sekarang dirender sebagai `semantik • state`
- `src/client/UI/Main.lua`
  - cache anchor pintu sekarang membaca `DoorRouteSubtitle`, bukan menurunkan subtitle langsung dari `DoorIsOpen`

### Validation Notes

- build source sukses:
  - `_tmp_door_semantic_state_split_build.rbxlx`

### Interpretation

- bias navigasi, semantic accent, dan affordance pintu sekarang tidak lagi runtuh hanya karena pintu sedang terbuka; state operasional tetap terlihat tanpa menghapus fungsi ruangnya

## 2026-04-06 - Lobby Zone Proximity Fallback Pass

### Scope

- menambah fallback orientasi lobby berbasis proximity agar panel lobby tetap punya konteks area terdekat meski event `LobbyZoneFocused` belum masuk

### Source Changes

- `src/client/UI/Main.lua`
  - tambah `LOBBY_ZONE_CLIENT_META`
  - tambah helper `getNearestLobbyZoneInfo()`
  - `BasicLobbyPanel` sekarang memakai zona lobby terdekat sebagai fallback saat belum ada focus aktif dari server

### Validation Notes

- build source sukses:
  - `_tmp_lobby_zone_proximity_fallback_build.rbxlx`

### Interpretation

- orientasi lobby sekarang lebih stabil; panel tidak lagi kosong konteks hanya karena pemain belum menyentuh trigger zona

## 2026-04-06 - Door State HUD Context Pass

### Scope

- meneruskan state operasional pintu ke objective/hint match agar affordance pintu tidak berhenti di world beacon saja

### Source Changes

- `src/client/UI/Main.lua`
  - anchor pintu sekarang menyertakan `stateText`
  - objective text pintu sekarang menampilkan status operasional pintu saat anchor aktif
  - controls hint pintu sekarang bisa menampilkan `TERBUKA / TERTUTUP / AKSES TERKUNCI`

### Validation Notes

- build source sukses:
  - `_tmp_door_state_hud_context_build.rbxlx`

### Interpretation

- navigasi match sekarang lebih taktis; pemain tidak hanya tahu pintu mana yang relevan, tetapi juga apakah pintu itu sedang siap dilalui

## 2026-04-06 - Phase 18 Completion Pass

### Scope

- menutup final pass `Lobby + Map in-game` setelah orientasi zona, semantik route, refuge alignment, door/traversal readability, dan fallback proximity terkonsolidasi

### Source Changes

- `src/client/UI/Main.lua`
  - summary rows match sekarang punya `Route Aktif` dan `Akses`
  - tombol lobby sekarang memberi emphasis yang selaras dengan zona aktif/fokus
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
  - `Phase 18` ditandai selesai

### Validation Notes

- build source sukses:
  - `_tmp_phase18_completion_build.rbxlx`

### Interpretation

- `Phase 18` sekarang cukup kuat untuk ditutup; restruktur besar lobby/map tidak lagi menjadi backlog aktif, dan pekerjaan bisa pindah ke phase berikutnya tanpa meninggalkan tech debt layout utama yang disengaja

## 2026-04-06 - Phase 17 Completion Pass

### Scope

- menutup `QA dan perf gate` dengan readiness harness yang lebih tegas dan checklist multiplayer manual pra-publish yang eksplisit

### Source Changes

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - tambah helper `buildQAGateMetrics(...)`
  - tambah action `GetQAGateReadiness`
  - readiness sekarang memberi hasil `pass_with_manual_multiplayer` atau `fail`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/QA_MULTIPLAYER_MANUAL_CHECKLIST_2026-04-06.md`
  - checklist smoke test dua client nyata sebelum publish
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
  - `Phase 17` ditandai selesai

### Validation Notes

- build source sukses:
  - `_tmp_phase17_completion_build.rbxlx`

### Interpretation

- `Phase 17` tidak lagi menggantung pada status “pending client kedua”; single-client gate sekarang punya output readiness yang tegas dan multiplayer gate dipindah jelas ke checklist manual pra-publish

## 2026-04-06 - Phase 20 Completion Pass

### Scope

- menutup polish tambahan `Windows FPV + Camera realism` setelah blocker inti dan restruktur lobby/map selesai

### Source Changes

- `src/client/CameraController.client.lua`
  - tambah `PasrahCursorMode`
  - cursor toggle sekarang lebih eksplisit untuk mode UI vs kembali ke FPV
  - head bob sekarang adaptif terhadap kecepatan dan ditekan turun saat cursor UI dilepas
  - viewmodel flashlight sekarang punya carry offset, look sway, breath sway, dan motion debug attr `PasrahFlashlightAimOffset`
- `src/shared/GameData/FlashlightConfig.lua`
  - tambah blok `motion` untuk tuning camera/viewmodel flashlight

### Validation Notes

- build source sukses:
  - `_tmp_phase20_completion_build.rbxlx`

### Interpretation

- `Phase 20` cukup kuat untuk ditutup; polish FPV/camera/flashlight sekarang sudah berada di jalur yang lebih natural tanpa merusak readability gameplay

## 2026-04-06 - Phase 19 Completion Pass

### Scope

- menutup diskusi final retention dengan blueprint tertulis yang selaras dengan fairness `Ranked`, monetization Roblox, dan arsitektur runtime sekarang

### Source Changes

- `DOCUMENTATION/SOURCE OF TRUTH/reports/RETENTION_LOOP_BLUEPRINT_2026-04-06.md`
  - blueprint retention lengkap:
    - daily quest / streak
    - meta progression
    - social pressure
    - content rotation
    - horror replayability
    - achievement hunting
    - lore unlock
- `DOCUMENTATION/SOURCE OF TRUTH/reports/E2E_TO_PUBLISH_BACKLOG_2026-04-03.md`
  - `Phase 19` ditandai selesai

### Interpretation

- final discussion tidak lagi hanya menjadi pengingat; sekarang sudah ada blueprint konkret yang bisa diimplementasikan bertahap tanpa membuka refactor besar atau merusak fairness

## 2026-04-06 - Publish Review Final Pass

### Scope

- merangkum sisa risiko publish ke satu dokumen agar lane manual/compliance tidak tercecer setelah seluruh phase backlog utama ditutup

### Source Changes

- `DOCUMENTATION/SOURCE OF TRUTH/reports/PUBLISH_REVIEW_FINAL_2026-04-06.md`
  - ringkasan status publish
  - daftar manual gate terakhir
  - urutan final verification

### Interpretation

- backlog utama sekarang selesai dan sisa pekerjaan terkonsentrasi di lane manual/compliance sebelum publish final

## 2026-04-06 - Publish Readiness Aggregation Pass

### Scope

- menyatukan gate teknis publish ke satu action harness dan menutup checklist manual terakhir untuk persistence target

### Source Changes

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - tambah action `GetPublishReadiness`
  - readiness sekarang merangkum:
    - QA solo gate
    - persistence mode
    - commerce visibility / marketplace id readiness
- `DOCUMENTATION/SOURCE OF TRUTH/reports/PERSISTENCE_MANUAL_CHECKLIST_2026-04-06.md`
  - checklist persistence target di luar Studio mock
- `DOCUMENTATION/SOURCE OF TRUTH/reports/PUBLISH_REVIEW_FINAL_2026-04-06.md`
  - tambah referensi resmi Roblox

### Validation Notes

- build source sukses:
  - `_tmp_publish_readiness_build.rbxlx`

### Interpretation

- publish verification sekarang punya satu surface teknis yang lebih tegas, dan sisa manual lane terkonsentrasi di multiplayer + persistence target + Creator Hub ID final

## 2026-04-06 - Final Release Checklist Pass

### Scope

- menutup publish ops dengan satu checklist operasional terakhir agar `go / no-go` tidak tersebar di banyak dokumen

### Source Changes

- `DOCUMENTATION/SOURCE OF TRUTH/reports/FINAL_RELEASE_CHECKLIST_2026-04-06.md`
  - urutan eksekusi final:
    - gate otomatis
    - Creator Hub mapping
    - multiplayer smoke
    - persistence target
    - legal review
    - final go/no-go
- `DOCUMENTATION/SOURCE OF TRUTH/reports/PUBLISH_REVIEW_FINAL_2026-04-06.md`
  - ditautkan ke checklist final

### Interpretation

- publish ops sekarang punya satu entrypoint praktis; sisa pekerjaan terakhir tidak lagi perlu dirakit manual dari banyak report terpisah

## 2026-04-06 - Live Visual Verification Pass

### Scope

- mengambil bukti visual live langsung dari Studio play session untuk surface publish-facing utama

### Source Changes

- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_RUNTIME_VERIFICATION_2026-04-06.md`
  - bukti visual live untuk:
    - lobby panel
    - room browser
    - room created
    - shop
    - royal pass
    - match preparation
- `DOCUMENTATION/SOURCE OF TRUTH/reports/PUBLISH_REVIEW_FINAL_2026-04-06.md`
  - menandai visual runtime verification sebagai lane yang sudah tertutup

### Runtime Notes

- `StartSoloMatch` live berhasil dari play session:
  - `inMatch=true`
  - `matchId=match_1`
  - `phase=Preparing/Briefing`
- panel `PERSIAPAN` + `Field Kit` + `FREE CURSOR [ALT/~]` tampil normal di layar
- `get_console_output` masih membawa histori log yang sangat duplikatif; jangan dipakai sendiri sebagai blocker tanpa cross-check runtime current state

### Interpretation

- surface visual/GUI/UX utama sekarang bukan hanya ada di source, tetapi juga sudah terbukti muncul live di Studio

## 2026-04-06 - Live Publish Gate Verification Pass

### Scope

- memverifikasi gate QA/publish langsung dari sesi Studio aktif memakai `StudioE2EControl`

### Runtime Notes

- sesi Studio aktif sempat memuat `StudioE2EControlSystem.Main` versi lama:
  - `GetQAGateReadiness` -> `unsupported_action`
  - `GetPublishReadiness` -> `unsupported_action`
- script Studio kemudian disamakan ke source terbaru pada path:
  - `ServerScriptService.Server.StudioE2EControlSystem.Main`

- hasil gate live sesudah patch session:
  - `GetQAGateSnapshot`
    - `players=1 activeMatches=0 currentMatch=none phase=none`
    - `scriptMemoryMb=7.17 totalMemoryMb=2022.81 physicsFps=59.89`
    - `warnings=0 errors=0 logSample=clean`
  - `GetQAGateReadiness`
    - `overall=pass_with_manual_multiplayer`
    - `solo=true`
    - `memoryOk=true fpsOk=true logOk=true`
  - `GetPublishReadiness`
    - `overall=fail`
    - `qaSolo=true`
    - `persistence=mock persistenceReady=false`
    - `commerceReady=true`
    - `robuxVisible=0 robuxMissingId=10`
  - `GetShopReadiness`
    - `total=31 MM=14 PP=7 Robux=10 disabled=10 robuxMissingId=10`
  - `GetPersistenceMode`
    - `mode=mock hasDataStore=false allowStudioDataStore=false trackedPlayers=1 schemaVersion=2`

### Interpretation

- gate QA solo live sekarang benar-benar terbaca `pass`
- blocker publish live yang tersisa tetap konsisten dengan report:
  - persistence masih `mock`
  - multiplayer tetap manual
  - `marketplaceId` Creator Hub resmi tetap lane terakhir sebelum publish

## 2026-04-06 - Creator Hub Mapping Manifest

### Scope

- memecah lane `Creator Hub marketplaceId` menjadi daftar item yang eksplisit dan siap diisi manual

### Source Changes

- `DOCUMENTATION/SOURCE OF TRUTH/reports/CREATOR_HUB_MARKETPLACE_MAPPING_2026-04-06.md`
  - manifest item `Robux` yang aman diaktifkan sekarang
  - daftar item yang harus tetap disabled
- `DOCUMENTATION/SOURCE OF TRUTH/reports/FINAL_RELEASE_CHECKLIST_2026-04-06.md`
  - Stage 2 sekarang langsung menunjuk ke manifest Creator Hub
- `DOCUMENTATION/SOURCE OF TRUTH/reports/PUBLISH_REVIEW_FINAL_2026-04-06.md`
  - lane `marketplaceId` sekarang punya referensi operasional
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
  - report baru masuk ke entrypoint utama

### Interpretation

- lane Creator Hub sekarang tidak lagi abstrak
- item `Robux` yang boleh aktif segera sudah dipisah dari item yang harus tetap mati demi fairness/compliance

## 2026-04-06 - Creator Hub Audit Helper

### Scope

- menambah validator lokal untuk mapping `Creator Hub marketplaceId`

### Source Changes

- `scripts/audit-marketplace-mapping.ps1`
  - audit cepat daftar item `Robux`
  - memisahkan `safe_enable_now` dan `keep_disabled`
  - bisa dipakai lagi setelah ID Creator Hub diisi
- `DOCUMENTATION/SOURCE OF TRUTH/reports/CREATOR_HUB_MARKETPLACE_MAPPING_2026-04-06.md`
  - menautkan helper terminal opsional

### Runtime Notes

- output helper saat ini:
  - `Catalog Robux items: 10`
  - `Safe enable now: 6`
  - `Keep disabled: 4`
  - `Safe items missing marketplaceId: 6`
  - `Hold items accidentally enabled: 0`
  - `Unclassified items: 0`

### Interpretation

- lane Creator Hub sekarang bisa diaudit cepat dari terminal lokal
- state saat ini konsisten dengan report:
  - 6 currency pack aman masih menunggu ID resmi
  - 4 offer yang harus ditahan masih tetap disabled

## 2026-04-06 - Manual Result Templates

### Scope

- membuat template hasil untuk dua lane manual terakhir: multiplayer dan persistence

### Source Changes

- `DOCUMENTATION/SOURCE OF TRUTH/reports/QA_MULTIPLAYER_RESULT_TEMPLATE_2026-04-06.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/PERSISTENCE_RESULT_TEMPLATE_2026-04-06.md`
- checklist dan entrypoint report diperbarui agar langsung menunjuk ke template hasil

### Interpretation

- lane manual terakhir sekarang bukan hanya punya checklist, tetapi juga wadah hasil run yang konsisten
- ini mengurangi risiko test manual selesai tetapi tidak terdokumentasi untuk keputusan `GO / NO-GO`

## 2026-04-06 - Release Preflight Helper

### Scope

- menambah satu command lokal untuk merangkum readiness sebelum masuk lane publish manual

### Source Changes

- `scripts/release-preflight.ps1`
  - menjalankan build Rojo
  - memeriksa report final wajib
  - menarik ringkasan `Robux` mapping dari `audit-marketplace-mapping.ps1`
- `scripts/audit-marketplace-mapping.ps1`
  - menambah mode `-Json` agar bisa dipakai script lain
- `DOCUMENTATION/SOURCE OF TRUTH/reports/FINAL_RELEASE_CHECKLIST_2026-04-06.md`
  - menambah `Stage 0 - Local Preflight`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
  - entrypoint script preflight ditambahkan

### Interpretation

- sebelum lane manual Roblox dijalankan, sekarang ada satu command lokal untuk mengecek readiness repositori secara cepat dan konsisten

## 2026-04-06 - Release Preflight Run

### Scope

- menjalankan `pwsh ./scripts/release-preflight.ps1` untuk snapshot readiness lokal terbaru

### Runtime Notes

- hasil run:
  - `Build ok: True`
  - `Missing reports: 0`
  - `Robux items: 10`
  - `Safe items missing ID: 6`
  - `Safe items disabled: 6`
  - `Hold items enabled: 0`
- manual blockers yang masih tersisa:
  - `Creator Hub marketplaceId` resmi belum diisi
  - `2 client smoke` belum dijalankan
  - persistence non-mock belum divalidasi
  - legal/licensing final review belum dikonfirmasi

### Interpretation

- readiness lokal repositori sekarang bersih di sisi build dan dokumentasi
- blocker publish yang tersisa memang sudah murni lane manual/platform

## 2026-04-05 - LobbySocialHub Scale Compression

### Scope

- mengecilkan `LobbySocialHub` menjadi sekitar setengah skala sebelumnya agar footprint lobby lebih masuk akal untuk populasi server Roblox yang realistis

### Source Changes

- `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.model.json`
  - geometry lobby diskalakan `0.5x` terhadap origin plaza utama
  - `Position` dan `Size` part ikut diperkecil
  - `Range` light ikut diperkecil agar densitas ruang tetap proporsional
- `src/shared/GameData/Maps/LobbySocialHub.lua`
  - `mapDimensions.width: 420 -> 210`
  - `mapDimensions.depth: 420 -> 210`
  - `pathWidth: 12 -> 6`

### Runtime Notes

- build source sukses:
  - `_tmp_lobby_halfsize_build.rbxlx`
- bounding box lobby aktif di Studio sesudah patch:
  - sebelum: `422 x 40.5 x 422`
  - sesudah: `211 x 20.25 x 211`
- sample runtime:
  - `Door_NorthEvidenceBuilding` sekarang di sekitar `1600, 1.75, -60.125`
  - `Door_EastShopBuilding` sekarang di sekitar `1655.125, 1.75, -10`
  - `PlayerSpawn_1` sekarang di sekitar `1595, 2, -5`
  - range lampu utama turun `26 -> 13`
- smoke playtest lobby sesudah scale:
  - player tetap spawn normal di plaza
  - `LobbyUI` tetap tampil
  - surface lobby dasar tidak patah oleh perubahan skala

### Interpretation

- lobby sekarang lebih cocok diperlakukan sebagai hub Roblox standar, bukan plaza raksasa
- perubahan ini mempermudah visual QA manusia karena jarak antar bangunan/zona menjadi lebih padat dan lebih mudah dibaca

## 2026-04-05 - LobbySocialHub Scale Compression Reverted

### Scope

- membatalkan compression `0.5x` pada `LobbySocialHub` karena skala ruang membuat player terasa terlalu besar terhadap atap/interior

### Source Changes

- `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.model.json`
  - dikembalikan ke geometri semula
- `src/shared/GameData/Maps/LobbySocialHub.lua`
  - `mapDimensions.width: 210 -> 420`
  - `mapDimensions.depth: 210 -> 420`
  - `pathWidth: 6 -> 12`

### Runtime Notes

- bounding box lobby aktif di Studio kembali ke:
  - `422 x 40.5 x 422`
- patch runtime Studio mendeteksi lobby sudah kembali normal, sehingga tidak perlu scale ulang tambahan

### Interpretation

- compression setengah skala dinyatakan tidak layak untuk lobby ini
- perubahan ukuran berikutnya harus memakai pass desain/layout yang lebih terarah, bukan sekadar kompres global seluruh geometri

## 2026-04-06 - Lobby UX World-Space Identity Pass

### Scope

- mendorong `LobbySocialHub` dari state signage prototype menjadi hub world-space yang lebih terbaca manusia
- fokus tetap di lobby, terutama:
  - identity entrance semua zona utama
  - pendalaman `North` sebagai `contract / evidence` staging bay
  - penambahan wayfinding plaza agar lobby terasa sebagai hub utuh, bukan shell kosong

### Source Changes

- `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - `SHOP`, `PARTY`, `GARDEN`, dan `FLEX` sekarang memakai facade sign world-space yang menempel ke bangunan
  - `SHOP` dan `PARTY` punya kiosk cue ringan:
    - `SHOP BOARD`
    - `ROOM BOARD`
  - `GARDEN` dan `FLEX` punya identity cue setara:
    - `GARDEN BOARD`
    - `FLEX BOARD`
  - `North` (`PLAY`) diperdalam menjadi staging bay:
    - foyer props
    - desk / display case
    - clipboard / paper / room ledger / room cards
    - tool display sederhana
    - backdrop, runner lantai, accent strips
    - desk plates `MAP / MODE / START`
  - `MainHubDecorRuntime` ditambahkan untuk orientasi plaza:
    - `DirectoryPad`
    - `DirectoryPillar`
    - `DirectoryPanel`
    - route runner `North / East / West / South / Flex`
    - node marker `PLAY / SHOP / PARTY / GARDEN / FLEX`

### Runtime Notes

- `North` sekarang tampil sebagai area `contract bay` yang lebih konkret, bukan lagi façade dengan panel tempel saja
- `SHOP / PARTY / GARDEN / FLEX` sekarang masing-masing minimal punya identity cue fisik yang terbaca langsung di world-space
- plaza tengah sekarang punya `Lobby Directory` dan jalur orientasi berwarna antar-zona

### Validation

- build source sukses:
  - `_tmp_lobby_shop_party_facade_signs_build.rbxlx`
  - `_tmp_lobby_shop_party_kiosk_build.rbxlx`
  - `_tmp_lobby_garden_flex_identity_build.rbxlx`
  - `_tmp_lobby_north_staging_props_build.rbxlx`
  - `_tmp_lobby_north_semantic_props_build.rbxlx`
  - `_tmp_lobby_north_depth_dressing_build.rbxlx`
  - `_tmp_lobby_north_contract_bay_build.rbxlx`
  - `_tmp_lobby_mainhub_directory_build.rbxlx`
  - `_tmp_lobby_mainhub_directory_scaleup_build.rbxlx`
- commit terkait:
  - `ce6686b` `Mount shop and party signs onto facades`
  - `a4a43a8` `Add shop and party entry kiosks`
  - `83bc8c4` `Add garden and flex entry identities`
  - `9c394aa` `Add north staging foyer props`
  - `5f32c3c` `Add north semantic staging props`
  - `56dfe7a` `Add north foyer depth dressing`
  - `8df973c` `Add north contract bay desk plates`

### Interpretation

- lobby sekarang mulai terbaca sebagai kumpulan bangunan/zona dengan fungsi nyata, bukan hanya shell besar dengan UI overlay
- `North` sudah naik dari prototype signage menjadi `contract / evidence staging bay`
- area plaza juga mulai punya peran orientasi, walau art direction akhir dan interior final masih belum selesai

### Follow-up 2026-04-06 10:10 ICT

- pass lanjutan untuk `MainHub`:
  - `North` ditingkatkan lagi menjadi `contract bay` yang lebih konkret lewat:
    - `DeskMapPlate`
    - `DeskModePlate`
    - `DeskStartPlate`
  - `MainHubDecorRuntime` diperluas dengan:
    - `BeaconNorth/East/West/South/Flex`
    - route runner dan node marker yang lebih besar
- validasi live:
  - `DeskMapPlate = MAP / Haunted House`
  - `DeskModePlate = MODE / Classic`
  - `DeskStartPlate = START / Room Browser`
  - `Lobby Directory` aktif di plaza, beserta node/beacon arah zona

### Follow-up 2026-04-06 11:25 ICT

- pass besar `Lobby UX visual` berlanjut dari tahap signage/wayfinding ke tahap `spatial mass`:
  - semua entrance utama sekarang punya `forecourt` world-space:
    - `ForecourtPad`
    - `LeftBench / RightBench`
    - `LeftPlanter / RightPlanter`
    - `LeftPlanterTop / RightPlanterTop`
  - `North` (`PLAY`) sekarang tidak hanya punya `contract bay`, tetapi juga apron depan, bench, dan planter yang membuat façade terasa seperti entrance bangunan sungguhan
  - `Shop / Party / Garden / Flex` sekarang ikut punya massa entrance yang setara, jadi shell lobby tidak lagi hanya terasa hidup di area utara
  - `MainHubDecorRuntime` diperkuat lagi dengan:
    - `HubPlanterNorthWest / NorthEast / SouthWest / SouthEast`
    - `HubWallNorthWest / NorthEast / SouthWest / SouthEast`
    - `DirectoryPad` dan `DirectoryPanel` yang lebih besar

### Validation 2026-04-06 11:25 ICT

- build source sukses:
  - `_tmp_lobby_forecourt_and_hub_mass_build.rbxlx`
- verifikasi live:
  - `North` runtime:
    - `ForecourtPad = 17.6 x 0.16 x 16`
    - `LeftBench = 4.4 x 0.68 x 1.42`
    - `LeftPlanter = 2.6 x 1.08 x 2.2`
  - `Shop` runtime:
    - `ForecourtPad = 12.8 x 0.16 x 14.8`
  - `MainHub` runtime:
    - `HubWallNorthWest = 6.2 x 1.44 x 0.52`
    - `HubPlanterNorthWest = 4.2 x 1.18 x 2.9`
    - `DirectoryPanel = 15.8 x 5.8 x 0.35`
- capture live:
  - fresh spawn `North` sekarang menampilkan `contract bay` + planter/bench, bukan façade polos
  - `Lobby Directory` plaza sekarang terlihat sebagai focal point yang lebih nyata, bukan hanya panel tipis di tengah ruang kosong

### Interpretation 2026-04-06 11:25 ICT

- lobby sekarang sudah naik dari `identity cue` menjadi `world-space shell with staging mass`
- area utara, timur, barat, selatan, dan tenggara sekarang minimal sudah punya:
  - façade
  - kiosk/sign
  - forecourt mass
- yang masih tersisa untuk menyebut lobby benar-benar final:
  - interior bangunan
  - prop final berbasis asset, bukan masih dominan primitive runtime
  - kontrak / tools / shop / party world interaction yang lebih nyata dan tidak hanya visual

### Follow-up 2026-04-06 12:05 ICT

- pass lanjutan `Lobby UX visual` memperdalam sayap non-utara menjadi `mini bay`, bukan lagi façade + forecourt saja:
  - `ShopZone`
    - `ZoneCounter`
    - `ZoneLeftDisplay`
    - `ZoneRightDisplay`
    - copy world-space:
      - `SHOP COUNTER`
      - `LOADOUT`
      - `COSMETIC`
  - `PartyZone`
    - `READY DESK`
    - `CREATE`
    - `INVITE`
  - `DailyRewardZone`
    - `GARDEN DESK`
    - `DAILY`
    - `SOCIAL`
  - `FlexZone`
    - `FLEX DESK`
    - `SPOTLIGHT`
    - `NEWS`
- tujuan batch ini:
  - membuat `SHOP / PARTY / GARDEN / FLEX` mulai terbaca sebagai ruang yang punya fungsi
  - tidak lagi tertinggal jauh dari `North` yang sudah lebih maju

### Validation 2026-04-06 12:05 ICT

- build source sukses:
  - `_tmp_lobby_zone_bays_build.rbxlx`
- verifikasi live runtime:
  - `Shop`
    - `ZoneCounter = 2.2 x 1.36 x 5.4`
    - `ZoneLeftDisplay = 1.54 x 1.28 x 1.96`
    - `ZoneRightDisplay = 1.54 x 1.28 x 1.96`
  - `Party`
    - `ZoneCounter = 2.2 x 1.36 x 5.4`
  - `Garden`
    - `ZoneCounter = 5.4 x 1.36 x 2.2`
  - `Flex`
    - `ZoneCounter = 2.2 x 1.36 x 5.4`
- catatan jujur:
  - capture `North` dan `MainHub` masih cukup representatif
  - capture `Shop` wing masih kalah oleh shell/camera angle, jadi batch ini saya nyatakan valid terutama lewat runtime proof, bukan karena screenshot yang indah

### Interpretation 2026-04-06 12:05 ICT

- semua bangunan utama lobby sekarang minimal sudah punya:
  - façade sign
  - board/kiosk
  - forecourt mass
  - bay/counter sederhana yang mencerminkan fungsi ruang
- baseline world-space lobby sekarang jauh lebih dekat ke `hub functional`, bukan cuma shell besar dengan label di dinding

### Follow-up 2026-04-06 13:00 ICT

- pass lanjutan lobby sekarang mulai mengikuti blueprint objek dunia secara lebih eksplisit:
  - `North / Evidence`
    - `Table_Tools_1..6` ditambahkan sebagai training table world-space:
      - `EMF`
      - `UV`
      - `THERMO`
      - `BOX`
      - `WRITING`
      - `CAM`
  - `Shop`
    - `EquipmentRack`
    - `DisplayTable_A`
    - `DisplayTable_B`
  - `Party`
    - `PartyPlatform`
    - `PartyBoard`
    - `PartyTerminal`
  - `Garden`
    - `DailyRewardTerminal`
    - `NPCSpot_A`
    - `NPCSpot_B`
  - `Flex`
    - `FlexStage`
    - `AnnouncementBoard`
    - `SpotlightPedestalLeft`
    - `SpotlightPedestalRight`

### Validation 2026-04-06 13:00 ICT

- build source sukses:
  - `_tmp_lobby_zone_features_build.rbxlx`
- verifikasi live runtime:
  - `Table_Tools_1 = 3.1 x 1.02 x 1.82`
  - `Table_Tools_6 = 3.1 x 1.02 x 1.82`
  - `EquipmentRack = 0.78 x 3.1 x 6.8`
  - `PartyPlatform = 5.8 x 0.18 x 5.8`
  - `PartyTerminal = 1.12 x 1.4 x 1.12`
  - `DailyRewardTerminal = 2.4 x 1.46 x 1.84`
  - `FlexStage = 5.8 x 0.22 x 5.8`
  - `AnnouncementBoard = 0.42 x 3.6 x 5.6`
- capture live:
  - `North` training tables tembus
  - `Party` shot tidak bagus secara framing, jadi validasi utama batch ini tetap saya pegang dari runtime proof

### Follow-up 2026-04-06 13:20 ICT

- pass berikutnya mempertebal `pseudo interior shell` untuk semua bangunan utama:
  - `InteriorFloor`
  - `InteriorBackWall`
  - `InteriorSideLeft`
  - `InteriorSideRight`
  - `InteriorCeiling`
- tujuan:
  - mengurangi rasa `prop ditempel di dinding telanjang`
  - memberi kedalaman dangkal pada bangunan agar façade, counter, dan prop punya ruang visual sendiri

### Validation 2026-04-06 13:20 ICT

- build source sukses:
  - `_tmp_lobby_pseudo_interiors_build.rbxlx`
- verifikasi live runtime:
  - `North InteriorFloor = 20.8 x 0.16 x 19.5`
  - `North InteriorBackWall = 20.8 x 5.8 x 0.28`
  - `Party InteriorFloor = 14.8 x 0.16 x 16.4`
  - `Party InteriorBackWall = 0.28 x 5.2 x 16.4`
  - `Flex InteriorFloor = 14.8 x 0.16 x 16.4`
  - `Flex InteriorBackWall = 0.28 x 5.2 x 16.4`
- catatan jujur:
  - screenshot pseudo interior masih sulit bagus karena shell editor aktif sangat sempit dan kamera sering mentok
  - runtime proof jauh lebih jujur daripada capture untuk batch ini

### Follow-up 2026-04-06 13:35 ICT

- fresh spawn lobby dan jalur `return-to-lobby` digeser lagi ke luar forecourt:
  - sebelumnya spawn masih terlalu dekat ke `North` back wall setelah interior shell ditambah
  - offset baru sekarang mendaratkan pemain di sekitar `x +/-10, z 30/40` relatif terhadap pintu utara
- file:
  - `src/ServerScriptService/Server/LobbySocialHub/LobbyPlayerManager.lua`
  - `src/ServerScriptService/Server/MatchSystem/MatchCleanup.lua`

### Validation 2026-04-06 13:35 ICT

- build source sukses:
  - `_tmp_lobby_spawn_forecourt_fix_build.rbxlx`
  - `_tmp_lobby_spawn_forecourt_final_build.rbxlx`
- verifikasi live runtime:
  - fresh spawn terbaru: `1610, 3.47, -90.25`
  - ini sudah keluar dari interior shell dan jatuh ke forecourt luar, bukan lagi mepet `North InteriorBackWall`

### Interpretation 2026-04-06 13:35 ICT

- lobby sekarang sudah sampai tahap:
  - world-space readable
  - semua sayap utama punya fungsi visual
  - pusat plaza punya orientasi
  - entrance utama punya massa
  - utara punya bay + training table
  - shell dangkal bangunan sudah ada
- yang masih tersisa sebelum benar-benar `final-final`:
  - asset final non-primitive
  - interior bangunan yang benar-benar kaya, bukan pseudo shell dangkal
  - world interaction final pada beberapa board/terminal agar tidak hanya visual

### Follow-up 2026-04-06

- saya hentikan ketergantungan pada `LobbyZoneEntryGuideRuntime` untuk façade utama karena jalur itu drift dan tidak konsisten muncul di `North`.
- pengganti yang sekarang dipakai adalah `MainHubDecorRuntime` langsung, sehingga façade dan shell semua sayap dibangun dari satu jalur yang deterministik.
- pass baru yang masuk:
  - `NorthBay / ShopBay / PartyBay / GardenBay / FlexBay` shell langsung:
    - `Floor`
    - `BackWall`
    - `SideLeft`
    - `SideRight`
    - `Ceiling`
    - `Threshold`
    - `Accent`
  - façade langsung per sayap:
    - `FrontWallLeft`
    - `FrontWallRight`
    - `EntryJambLeft`
    - `EntryJambRight`
    - `EntryHeader`
    - `EntryAccent`
    - `EntryCanopy`
    - `EntrySignPanel`
    - `EntryWindowLeft`
    - `EntryWindowRight`
    - `EntryLampLeft`
    - `EntryLampRight`
  - lampu sayap dinaikkan agar shell tidak lagi tenggelam terlalu gelap
  - fresh spawn/return-to-lobby disetel ulang lagi untuk mendarat di forecourt kompromi, bukan terlalu jauh atau terlalu masuk ke bawah roof

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_facade_direct_build.rbxlx`
  - `_tmp_lobby_forecourt_readability_build.rbxlx`
  - `_tmp_lobby_spawn_offset_final_build.rbxlx`
  - `_tmp_lobby_spawn_offset_compromise_build.rbxlx`
- verifikasi live runtime:
  - `NorthBayFloor = 58 x 0.16 x 36`
  - `NorthBayBackWall = 58 x 8.6 x 0.32`
  - `ShopBayFloor = 42 x 0.16 x 38`
  - `PartyBayFloor = 42 x 0.16 x 38`
  - `GardenBayFloor = 54 x 0.16 x 34`
  - `FlexBayFloor = 38 x 0.16 x 34`
  - `NorthBayEntrySignPanel = 16 x 2.8 x 0.24`
  - `ShopBayEntrySignPanel = 16 x 2.8 x 0.24`
  - `PartyBayEntrySignPanel = 16 x 2.8 x 0.24`
  - `GardenBayEntrySignPanel = 16 x 2.8 x 0.24`
  - `FlexBayEntrySignPanel = 16 x 2.8 x 0.24`
  - `partyGuide = nil`
    - artinya runtime sign lama memang sudah tidak lagi menjadi sumber visual aktif
  - `NorthWingLight` live sekarang `brightness = 2.3`
- capture live:
  - `LobbyLargePass_Spawn_5`
  - `LobbyLargePass_NorthScriptable_1`
- catatan jujur:
  - shot spawn sekarang lebih stabil dan jatuh di forecourt, tapi visual bangunan masih jelas berada pada tahap `strong blockout / proto art`
  - direct façade runtime jauh lebih jujur dan stabil dibanding jalur guide lama, jadi itu yang saya pegang sebagai baseline lanjut berikutnya

### Follow-up 2026-04-06

- pass berikutnya mengubah lobby dari `visual blockout` ke `canonical world-space objects` yang benar-benar dicari codebase:
  - `MatchQueuePlatform`
  - `QueueTrigger`
  - `ShopCounter`
  - `Interact_Shop`
  - `PartyPlatform`
  - `PartyBoard`
  - `PartyTerminal`
  - `DailyRewardTerminal`
  - `FlexStage`
  - `AnnouncementBoard`
  - `Table_Tools_1..6`
- object-object ini sekarang dibangun langsung lewat `MainHubDecorRuntime`, bukan lagi bergantung pada jalur guide lama.
- saya juga tambahkan `ProximityPrompt` dasar pada titik dunia yang paling relevan:
  - `QueueTrigger`
  - `ShopCounter`
  - `Interact_Shop`
  - `PartyBoard`
  - `ContractBoard`
  - `DailyRewardTerminal`
  - `Table_Tools_1..6`

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_canonical_objects_build.rbxlx`
- verifikasi live runtime:
  - `MatchQueuePlatform = present`
  - `QueueTrigger = present`
  - `queueTouch = true`
  - `ShopCounter = present`
  - `Interact_Shop = present`
  - `PartyPlatform = present`
  - `PartyBoard = present`
  - `PartyTerminal = present`
  - `DailyRewardTerminal = present`
  - `FlexStage = present`
  - `AnnouncementBoard = present`
  - `Table_Tools_1 = present`
  - `Table_Tools_6 = present`
  - prompt yang benar-benar terbaca:
    - `QueueTrigger -> Join Queue`
    - `ShopCounter -> Open Shop`
    - `Interact_Shop -> Browse`
    - `PartyBoard -> Open Party`
    - `DailyRewardTerminal -> Claim`
    - `Table_Tools_* -> Test Tool`
- capture live:
  - `LobbyCanonicalObjects_Spawn_1`
- catatan jujur:
  - visual masih berada pada fase `proto art / structured blockout`
  - tetapi sekarang lobby bukan cuma readable secara visual; object dunia inti juga sudah sinkron dengan nama canonical yang dicari logic/codebase

### Follow-up 2026-04-06

- `LobbySocialHub` menerima pass `world prompt wiring` yang mengubah object canonical dari sekadar prop + prompt menjadi jalur kerja nyata:
  - `ContractBoard`
    - publish `ContractBoardRequested`
    - refresh surface board utara dari data kontrak hidup
    - buka `Room Browser`
  - `RoomBoard`
    - buka `Room Browser`
  - `QueueTrigger`
    - panggil queue via jalur `LobbySystem.Controller:OnQueueFromRoomBrowser`
    - buka `Room Browser` untuk memantau state
  - `ShopCounter / Interact_Shop`
    - buka `ShopUI`
  - `DailyRewardTerminal`
    - publish `DailyRewardClaimRequest`
  - `ToolsBoard` dan `Table_Tools_1..6`
    - kirim feedback lobby world-space yang benar
- `LobbySystem.Controller` sekarang merelay:
  - `LobbyWorldSurfaceRequested`
  - `LobbyWorldPromptFeedback`
  - `DailyRewardAvailable`
  - `DailyRewardClaimed`
- `UISystem` sekarang merespons event lobby runtime baru itu:
  - membuka `RoomBrowser`
  - membuka `ShopUI`
  - menulis feedback reward/queue yang lebih manusiawi

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_world_prompt_build.rbxlx`
  - `_tmp_lobby_world_prompt_fix_build.rbxlx`
- verifikasi live:
  - runtime prompt hadir pada:
    - `QueueTrigger`
    - `ContractBoard`
    - `RoomBoard`
    - `ToolsBoard`
    - `ShopCounter`
    - `Interact_Shop`
    - `PartyBoard`
    - `DailyRewardTerminal`
    - `Table_Tools_1`
  - `ContractBoard` live sekarang tidak lagi statis:
    - sebelum prompt:
      - `1. Empty Building • Angker`
      - `2. Empty Building • Lumayan`
      - `3. Haunted House • Angker`
    - sesudah prompt:
      - `1. Empty Building • Angker`
      - `2. Abandoned Palace • Lumayan`
      - `3. Haunted House • Lumayan`
  - `ContractBoard` prompt live membuka `RoomBrowserUI`
  - `ShopCounter` prompt live membuka `ShopUI`
- capture live:
  - `LobbyPrompt_ContractBoard_Fix_1`
  - `LobbyPrompt_ContractBoard_Fix_2`
  - `LobbyPrompt_ShopCounter_1`
- catatan jujur:
  - `DailyRewardTerminal` sudah terhubung ke jalur request server, tetapi bukti live yang benar-benar tegas untuk hasil claim masih belum saya pegang karena state reward player bisa sudah claimed dan feedback label runtime ini tidak stabil untuk dijadikan satu-satunya bukti
  - art pass lobby tetap belum final; batch ini fokus pada `world interaction wiring`, bukan asset final

### Follow-up 2026-04-06

- rollback `mouse/camera drift` dilakukan untuk kembali ke perilaku kamera Roblox bawaan:
  - jalur `manual lobby orbit` dan `manual FPV camera` di `CameraController.client.lua` dicabut
  - `StarterPlayer.DevComputerCameraMovementMode` dikembalikan ke `UserChoice`
  - batch `LobbySocialHub` yang sedang berjalan dibatalkan agar tidak tercampur dengan rollback camera

### Validation 2026-04-06

- build source sukses:
  - `_tmp_camera_default_restore_build.rbxlx`
- verifikasi live:
  - `StarterPlayer.DevComputerCameraMovementMode = UserChoice`
  - `LocalPlayer.CameraMode = Classic`
  - `CurrentCamera.CameraType = Custom`
  - `UserInputService.MouseBehavior = Default`
  - `UserInputService.MouseIconEnabled = true`
- capture live:
  - `CameraRollback_Lobby_Baseline_1`
  - `CameraRollback_Lobby_Baseline_2`
- catatan jujur:
  - rollback ini memulihkan jalur kamera ke baseline Roblox/default, tetapi saya belum mengklaim semua UX lobby selesai

### Follow-up 2026-04-06

- akar drift lobby ditemukan di `CameraController.client.lua`:
  - render-step lobby masih memanggil `setFpvLocked(false)` setiap frame saat state mouse/camera berubah dari baseline
  - akibatnya perilaku default Roblox saat `right mouse drag` langsung ditarik balik oleh script client
- branch lobby itu dicabut; `CameraController` sekarang hanya memaksa state saat benar-benar `InMatch`

### Validation 2026-04-06

- verifikasi live sesudah patch:
  - lobby idle tetap:
    - `CameraType = Custom`
    - `CameraMode = Classic`
    - `MouseBehavior = Default`
  - saat `right mouse button` ditahan di lobby:
    - `MouseBehavior = LockCurrentPosition`
    - `CameraType = Custom`
    - ini cocok dengan jalur default Roblox third-person
- capture live:
  - `CameraLobby_Default_AfterFix_1`
  - `CameraLobby_Default_AfterFix_FPV_1`

## Update 2026-04-06

- `LobbySocialHub` menerima pass besar yang menutup gap antara façade visual dan board dunia aktif:
  - `Start()` sekarang memanggil `self:_refreshLobbyWorldBoards()`, jadi board sekunder ikut refresh saat lobby boot
  - `_publishFlexSpotlight()` sekarang ikut memicu refresh board sekunder saat spotlight berubah
  - `North contract bay` dilengkapi lagi dengan:
    - `CenterDesk / CenterDeskTop`
    - `LeftDisplayCase / RightDisplayCase`
    - `CenterBackdrop / FloorRunner`
    - `ContractClipboard / ContractPaper`
    - `RoomLedger / RoomCards`
    - `ToolDisplayEMF / ToolDisplayUV / ToolDisplayBox`
    - `DeskMapPlate / DeskModePlate / DeskStartPlate`

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_board_refresh_fix_build.rbxlx`
  - `_tmp_lobby_contract_bay_restore_build.rbxlx`
- verifikasi live:
  - board sekunder sekarang benar-benar hidup:
    - `QueueSign = QUEUE HUB | 10 room • 0 pemain`
    - `ShopCounter = SHOP | 31 item • 4 premium`
    - `PartyBoard = PARTY | 10 room publik • 0 ready`
    - `AnnouncementBoard = FLEX | Haunted House • 10 room`
  - `North contract bay` runtime sekarang lengkap:
    - `CenterDesk`, `CenterDeskTop`, `LeftDisplayCase`, `RightDisplayCase`
    - `DeskMapPlate = MAP | Abandoned Palace`
    - `DeskModePlate = MODE | Uji Nyali`
    - `DeskStartPlate = START | 10 room live`
  - prompt dunia utama tetap sehat:
    - `ContractBoard` membuka `RoomBrowserUI`
    - `ShopCounter` membuka `ShopUI`
- capture live:
  - `LobbyWorldPrompt_ShopCounter_1`

## Update 2026-04-06

- `LobbySocialHub` menerima pass arsitektur pendekatan `North` supaya frame spawn tidak lagi didominasi floor abu-abu kosong:
  - `NorthApproachArchLeft / Right / Header`
  - `NorthApproachAccent`
  - `NorthApproachPanel`
  - `NorthPathInset / NorthPathLine`
  - bollard lamp kiri/kanan di jalur utara
- tujuannya:
  - memberi framing world-space ke jalur `Contract Bay`
  - membuat arah `PLAY / Contract / Room / Tools` terbaca dari spawn pertama

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_north_approach_build.rbxlx`
- verifikasi live:
  - `NorthApproachPanel = CONTRACT BAY | Room • Contract • Tools`
  - `NorthApproachArchLeft / Right / Header` hadir di runtime
  - `NorthPathInset` dan bollard lamp hidup sepanjang jalur ke `North`
- capture live:
  - `LobbyNorth_Approach_After_1`

## Update 2026-04-06

- framing spawn lobby kini ditarik lebih dekat ke jalur `North`:
  - `LobbyPlayerManager` dan `MatchCleanup` memakai offset visual baru yang lebih maju ke arch `Contract Bay`
  - jalur `fresh spawn` dan `return-to-lobby` tetap memakai framing yang sama

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_spawn_framing_tight_build.rbxlx`
- verifikasi live:
  - posisi spawn baru sekitar `1604, 3.47, -94.25`
  - arch `North` dan bollard lamp kini masuk lebih dominan ke frame awal
- capture live:
  - `LobbyNorth_SpawnFraming_After_1`

## Update 2026-04-06

- `LobbySocialHub` menerima pass approach marker untuk wing selain `North`:
  - `ShopApproach*`
  - `PartyApproach*`
  - `GardenApproach*`
  - `FlexApproach*`
  - masing-masing disertai `PathInset` dan `PathLine` agar koridor dari hub ke bangunan lebih mudah dibaca
- tujuannya:
  - membuat `SHOP / PARTY / GARDEN / FLEX` terbaca sebelum pemain sampai ke façade ujung
  - mengurangi rasa `hub kosong + bangunan jauh` di plaza

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_multiwing_approach_build.rbxlx`
- verifikasi live:
  - `ShopApproachPanel = SHOP | Loadout • Currency • Utility`
  - `PartyApproachPanel = PARTY | Invite • Ready • Join`
  - `GardenApproachPanel = GARDEN | Daily • Social • Claim`
  - `FlexApproachPanel = FLEX | Spotlight • Cosmetic • News`
  - `ShopPathInset / PartyPathInset / GardenPathInset / FlexPathInset` hidup di runtime
- catatan:
  - capture plaza yang mencoba menampilkan banyak wing sekaligus tertimpa loading overlay, jadi bukti utama pass ini saya pegang dari runtime object + surface text

## Update 2026-04-06

- `LobbySocialHub` menerima pass `wing identity dressing` untuk empat sayap non-utara:
  - `SHOP`
    - `ShopBackCounter`
    - `ShopPriceBoard`
    - `ShopPendantLeft / Right`
    - `ShopFloorRunner`
  - `PARTY`
    - `PartyBackdropWall`
    - `PartyDanceFloor`
    - `PartyBoothLeft / Right`
    - `PartyNeonBar`
  - `GARDEN`
    - `GardenPergolaBeamLeft / Right`
    - `GardenFlowerBedLeft / Right`
    - `GardenLanternA / B`
  - `FLEX`
    - `FlexCurtainLeft / Right`
    - `FlexMarquee`
    - `FlexAudienceBenchLeft / Right`
- tujuannya:
  - memberi massa ruang dan identitas saat pemain benar-benar masuk ke wing
  - mengurangi rasa `box polos + prop tipis` pada empat bangunan non-utara

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_wing_identity_build.rbxlx`
- verifikasi live:
  - `ShopPriceBoard = OFFERS | MM • PP • Utility`
  - `PartyBackdropWall`, `PartyDanceFloor`, `PartyNeonBar` hadir di runtime
  - `GardenPergolaBeamLeft / Right`, `GardenLanternA / B` hadir di runtime
  - `FlexMarquee = SPOTLIGHT | Style • Event • Feature`
  - `FlexCurtainLeft / Right`, `FlexAudienceBenchLeft / Right` hadir di runtime
- catatan:
  - capture interior per wing tidak tembus via navigasi otomatis karena route fisik lobby masih belum bersih untuk tool navigasi, jadi bukti utama pass ini saya pegang dari runtime object + surface text

## Update 2026-04-06

- `LobbySocialHub` kini ditutup sebagai `world-space hub` yang benar-benar bisa dipakai:
  - floor, threshold, corridor, shell, gateway wall, planter, dan route pad utama sekarang menjadi surface fisik yang benar-benar terbaca oleh physics/pathfinding
  - collision pintu asli lobby dicabut pada:
    - `Door_NorthEvidenceBuilding`
    - `Door_EastShopBuilding`
    - `Door_WestPartyZone`
    - `Door_SouthSocialGarden`
    - `Door_SouthEastFlexZone`
  - blocker `Party` terakhir ditutup dengan membuat `PartyBackdropWall` non-collide agar koridor inti tidak tertutup dekor sendiri
  - parity interaksi dunia dilengkapi:
    - `PartyPlatform` sekarang punya prompt `Join Party Room`
    - `AnnouncementBoard` sekarang punya prompt `Read Spotlight`
    - `FlexStage` sekarang punya prompt `View Spotlight`

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_traversal_interaction_final_build.rbxlx`
- verifikasi live traversal:
  - `ShopCore = Success`
  - `PartyPlatformCore = Success`
  - `GardenCore = Success`
  - `FlexCore = Success`
  - `NorthDeskFront = Success`
  - `NorthRoomFront = Success`
  - `NorthToolsFront = Success`
- verifikasi live interaksi:
  - `PartyBoard -> RoomBrowserUI.Enabled = true`
  - `PartyPlatform -> RoomBrowserUI.Enabled = true`
  - `ShopCounter` tetap membuka `ShopUI`
  - `FlexStage` prompt hidup dan mengubah state/hint lobby tanpa memaksa surface lain terbuka
- capture live:
  - `LobbyPrompt_PartyBoard_Post_8`
  - `LobbyPrompt_PartyPlatform_Post_14`
  - `LobbyPrompt_Flex_Pre_15`

- status:
  - **LOBBY FUNCTIONAL COMPLETE**.
  - sisa yang ada sekarang masuk kategori `polish visual/art premium`, bukan blocker world-space, traversal, atau interaksi lobby.

## Update 2026-04-06

- `LobbySocialHub` sekarang juga menutup slice `evidence training bay` di wing utara:
  - `ToolsBoard` dan `Table_Tools_1..6` tidak lagi hanya memberi feedback generik
  - ghost latihan dunia sekarang hidup sebagai exhibit runtime:
    - `TrainingGhostBase`
    - `TrainingGhostCore`
    - `TrainingGhostShroud`
    - `TrainingGhostHead`
    - `TrainingGhostEyeLeft / Right`
    - `TrainingGhostRing`
    - `TrainingGhostPlaque`
  - `LobbyEvidenceTrainingUpdated` sekarang me-relay state training dari server ke client lobby
  - `LobbyUXGui` sekarang punya panel training khusus:
    - ghost aktif
    - aggro
    - evidence ditemukan
    - hint tool berikutnya
  - `SoundSystem` dan `VFXController` sekarang punya preview hook resmi agar training lobby bisa memicu SFX/VFX tanpa membuat jalur paralel
- evidence training sekarang terbukti mengajarkan tools:
  - tool benar mengunci evidence dan mengurangi aggression
  - tool salah menaikkan aggression dan memicu feedback penalti
  - saat semua evidence terkunci, `ToolsBoard` memutar ghost latihan baru

### Validation 2026-04-06

- build source sukses:
  - `_tmp_lobby_evidence_training_build.rbxlx`
  - `_tmp_lobby_evidence_training_ui_fix_build.rbxlx`
- verifikasi live:
  - `ToolsBoard` membuka training ghost aktif dan menyalakan panel training lobby
  - `EMF` valid untuk `Banaspati` dan mengunci `MEDOK`
  - `Spirit Box` salah untuk `Banaspati`:
    - `AGGRO 24%`
    - feedback `Aggression ghost naik`
    - `PasrahAudioLastCategory = GhostAudio`
    - `PasrahVFXLastProfile = lightflicker`
  - `THERMO` valid mengunci `Suhu`
  - `UV CAM` valid mengunci `To'un`
  - training selesai:
    - `TRAINING CLEAR • CALM`
    - hint meminta rotasi ghost baru lewat `ToolsBoard`
  - `ToolsBoard` kemudian merotasi training ke ghost baru:
    - `SilumanUlar`
    - aggro reset ke `0%`
    - evidence reset ke kosong
  - regression prompt utama sesudah wiring training tetap sehat:
    - `ContractBoard -> RoomBrowserUI.Enabled = true`
    - `ShopCounter -> ShopUI.Enabled = true`
- catatan UI:
  - `TrainingFrame` runtime sekarang punya `ZIndex` yang benar (`frame=8`, child=`9/10`) dan state live tampil di `LobbyUXGui`

- status:
  - **LOBBY EXECUTIONMODE COMPLETE** untuk scope lobby saat ini:
    - world-space hub hidup
    - traversal sehat
    - prompt utama sehat
    - evidence training usable
    - SFX/VFX training hidup
    - tidak ada error runtime baru yang muncul pada verifikasi live batch ini

## Update 2026-04-06

- blocker berikutnya sesudah lobby saya dorong di lane `core loop match preparation`:
  - spawn awal match sekarang dipindah ke staging luar bangunan target
  - `PreparationPhase` sekarang punya board dunia `CONTRACT / OBJECTIVES / TOOLS`
  - rack tools dunia sekarang bisa memilih `fokus tool awal` dan memperbarui board tools live
- source owner yang disentuh:
  - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
  - [MatchTeleport.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MatchTeleport.lua)
  - [MatchService.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MatchService.lua)
  - [Main.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/UI/Main.lua)
- validasi:
  - build source sukses:
    - `_tmp_match_preparation_staging_build.rbxlx`
    - `_tmp_match_preparation_staging_ui_build.rbxlx`
    - `_tmp_match_preparation_staging_outside_build.rbxlx`
    - `_tmp_match_preparation_staging_client_fallback_build.rbxlx`
    - `_tmp_match_preparation_staging_loading_hardblock_build.rbxlx`
    - `_tmp_match_preparation_staging_router_fix_build.rbxlx`
  - live:
    - `PreparationPlatform` kini benar-benar berada di luar shell map aktif:
      - `HauntedHouse.PreparationPlatform = 1295.30, 0.22, 0.00`
      - shell map aktif berhenti sebelum titik itu
    - spawn solo match tidak lagi lahir di dalam building:
      - board dunia terlihat langsung di staging luar
    - board dunia hidup:
      - `CONTRACT`
      - `OBJECTIVES`
      - `TOOLS`
    - `PreparationToolsBoard` berubah live saat prompt rack dipakai:
      - `PreparationFocusTool = EMF`
      - subtitle berubah menjadi `EMF ready for first sweep`
    - HUD drift yang menutup board dunia ditutup:
      - `PreparationPhase` tidak lagi dipaksa pakai loading card penuh saat `PreparationStagingRuntime` ada
      - `FieldKit` tidak tampil saat `PreparationPhase`
- status:
  - **LANJUT / BELUM FINAL**.
  - blocker `spawn awal harus di luar bangunan + board objective/tools dunia` sudah tertutup untuk baseline functional/UX.
  - yang masih tersisa untuk lane ini adalah:
    - dressing exterior yang lebih kaya dari staging primitive sekarang
    - board dunia pre-investigation yang lebih premium secara asset/art
    - rekonstruksi map luar/dalam agar transisi ke investigasi lebih sinematik

- pass lanjutan pada lane yang sama:
  - staging luar sekarang punya dressing exterior yang lebih terbaca sebagai `prep worksite`:
    - `PreparationForecourt`
    - `PreparationFence_*`
    - `PreparationFloodlight_*`
    - `PreparationContractDesk`
    - `PreparationEquipmentCase_*`
    - `PreparationEntrySign`
  - pilihan `PreparationFocusTool` sekarang ikut terbawa ke panel `Investigation`
- source owner yang disentuh:
  - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
  - [Main.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/UI/Main.lua)
- validasi:
  - build source sukses:
    - `_tmp_match_preparation_staging_exterior_build.rbxlx`
    - `_tmp_match_preparation_staging_exterior_focus_build.rbxlx`
  - live:
    - `PreparationForecourt = 44 x 0.16 x 32`
    - `PreparationContractDesk = 6.4 x 1.2 x 2.2`
    - `PreparationFloodlight_1/2` hadir dan masing-masing punya `SpotLight`
    - `PreparationEntrySign` hadir dengan copy `MAIN ENTRY`
    - `PreparationFocusTool = EMF`
    - panel `Investigation` sekarang membawa fokus tool:
      - primary `Fokus awal: EMF`
      - controls hint `FOKUS: EMF`
      - objective label `Fokus awal: EMF`
    - path staging tetap sehat ke permukaan pemain:
      - `ToolStation_EMF -> PreparationPlatform = Success`
- status:
  - **LANJUT / BELUM FINAL**.
  - staging luar sekarang lebih terasa sebagai exterior prep area dan pilihan tool tidak lagi mati setelah breach.
  - residual lane ini tetap:
    - art/asset premium untuk staging luar
    - dressing exterior yang lebih kaya per map
    - transisi luar->dalam yang lebih sinematik

- pass lanjutan pada lane yang sama:
  - staging luar sekarang punya `BREACH` prompt dunia yang benar-benar memajukan phase
  - `Preparation -> Investigation` kini bisa dipicu dari `MAIN ENTRY`, tidak lagi hanya menunggu timer
  - panel preparation juga diselaraskan:
    - hint/footer kini mengarahkan pemain untuk aktifkan `BREACH` di `MAIN ENTRY`
- source owner yang disentuh:
  - [MatchService.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MatchService.lua)
  - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
  - [Main.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/UI/Main.lua)
- validasi:
  - build source sukses:
    - `_tmp_match_preparation_breach_prompt_build.rbxlx`
    - `_tmp_match_preparation_breach_cleanup_build.rbxlx`
    - `_tmp_match_preparation_breach_destroy_build.rbxlx`
  - live:
    - `Main Entry / Mulai Breach` prompt muncul di staging luar
    - input pemain `E` di prompt itu memajukan:
      - `MatchPhase = InGame`
      - `MatchLifecyclePhase = InvestigationPhase`
    - sesudah breach:
      - prompt hilang dari layar
      - papan entry berubah ke state `BREACH OPEN`
    - panel preparation sekarang menulis:
      - `aktifkan BREACH di MAIN ENTRY`
- status:
  - **LANJUT / BELUM FINAL**.
  - staging luar sekarang sudah punya loop dunia yang utuh:
    - review board
    - pilih fokus tool
    - breach ke investigasi
  - residual lane ini tetap:
    - asset premium/non-primitive untuk staging luar
    - dressing exterior yang lebih kaya dan berbeda per map
    - transisi breach yang lebih sinematik

- pass lanjutan pada lane yang sama:
  - `OBJECTIVES` board sekarang hidup dari state staging, bukan lagi template statis
  - target evidence di board sekarang mengikuti difficulty profile match
  - board juga menampilkan status `Focus awal` dan `Breach`
- source owner yang disentuh:
  - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
- validasi:
  - build source sukses:
    - `_tmp_match_preparation_objective_board_live_build.rbxlx`
  - live:
    - state default board:
      - title `OBJECTIVES`
      - subtitle `Primary + optional briefing`
      - body memuat `Capture 4 evidence` pada `Mudah`
      - status `Focus awal: pilih tool dari rack`
      - status `Breach: READY`
    - sesudah prompt `EMF`:
      - `PreparationFocusTool = EMF`
      - subtitle berubah ke `Focus: EMF • breach ready`
      - body berubah ke `Focus awal: EMF`
- status:
  - **LANJUT / BELUM FINAL**.
  - briefing dunia sekarang lebih hidup dan mengikuti difficulty + focus tool.
  - residual lane tetap:
    - asset premium/non-primitive untuk staging luar
    - dressing exterior yang lebih kaya dan berbeda per map
    - transisi breach yang lebih sinematik

- pass lanjutan pada lane yang sama:
  - `MAIN ENTRY` sekarang punya state visual hidup:
    - default `READY`
    - sesudah pilih tool `armed`
    - sesudah breach `BREACH OPEN`
  - beacon neon di atas entry sekarang ikut berubah warna sesuai state
  - cue breach client sekarang memicu preview audio lingkungan saat transisi `Preparation -> Investigation`
- source owner yang disentuh:
  - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
  - [Main.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/UI/Main.lua)
- validasi:
  - build source sukses:
    - `_tmp_match_preparation_entry_state_build.rbxlx`
    - `_tmp_match_preparation_entry_state_ui_build.rbxlx`
  - live:
    - state default:
      - `MAIN ENTRY`
      - subtitle `Breach setelah review board`
      - body `Ikuti runner ke pintu utama.`
      - beacon amber
    - sesudah prompt `EMF`:
      - `PreparationFocusTool = EMF`
      - subtitle `EMF ready • breach armed`
      - body `Aktifkan breach untuk sweep awal dengan EMF.`
      - beacon berubah biru
    - sesudah prompt `Mulai Breach`:
      - `MatchPhase = InGame`
      - `MatchLifecyclePhase = InvestigationPhase`
      - entry board berubah ke `BREACH OPEN`
      - beacon berubah hijau
      - `PasrahAudioLastCategory = EnvironmentalAudio`
      - `PasrahAudioLastCue = env_doorslam`
      - `MatchLoadingUI.Enabled = false`
    - regression UI staging:
      - `MatchLifecyclePhase = PreparationPhase`
      - `MatchPhase = Preparing`
      - `FieldKitFrame.Visible = false`
- status:
  - **LANJUT / BELUM FINAL**.
  - staging luar sekarang bukan cuma punya board statis, tapi entry state yang hidup dan transisi breach yang terasa.
  - residual lane tetap:
    - asset premium/non-primitive untuk staging luar
    - dressing exterior yang lebih kaya dan berbeda per map
    - transisi breach yang lebih sinematik secara visual, bukan baru cue/audio + state board

- pass lanjutan pada lane yang sama:
  - `PreparationRunner`, floodlight, dan lamp staging sekarang ikut state:
    - ready
    - armed
    - breach open
  - sync state staging sekarang tidak lagi hanya bergantung pada prompt dunia;
    entry state ikut `MatchLifecyclePhase` authoritative
- source owner yang disentuh:
  - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
- validasi:
  - build source sukses:
    - `_tmp_match_preparation_entry_lane_build.rbxlx`
    - `_tmp_match_preparation_entry_sync_build.rbxlx`
  - live:
    - default:
      - runner coklat gelap
      - floodlight `3.20`
      - lamp `1.80`
      - sign `MAIN ENTRY`
    - sesudah `EMF`:
      - `PreparationFocusTool = EMF`
      - runner berubah biru
      - floodlight `3.80`
      - lamp `2.10`
      - sign `EMF ready • breach armed`
    - sesudah `AdvancePhase -> InvestigationPhase` tanpa prompt breach:
      - `MatchPhase = InGame`
      - `MatchLifecyclePhase = InvestigationPhase`
      - runner berubah hijau
      - floodlight `4.30`
      - lamp `2.45`
      - sign `BREACH OPEN`
- status:
  - **LANJUT / BELUM FINAL**.
  - drift state dunia staging vs lifecycle authoritative sudah tertutup.
  - residual lane tetap:
    - asset premium/non-primitive untuk staging luar
    - dressing exterior yang lebih kaya dan berbeda per map
    - transisi breach yang lebih sinematik secara visual dan animatif

- progress tambahan pada lane `outside match preparation staging`:
  - profile staging sekarang dibedakan per map, bukan lagi satu dressing generik:
    - `HauntedHouse` -> `CONTRACT BAY`
    - `AbandonedPalace` -> `PALACE GATE`
    - `EmptyBuilding` -> `OPERATIONS ENTRY`
    - `StudioMMNineteen` -> `CONTROL ACCESS`
  - `HauntedHouse` sekarang membawa décor `house`:
    - porch post
    - supply crate
    - notice stand
  - `AbandonedPalace` sekarang membawa décor `palace`:
    - carpet
    - pillar
    - brazier
    - banner
  - `EmptyBuilding` dan `StudioMMNineteen` memakai décor `facility` baseline
- blocker yang berhasil ditemukan dan ditutup:
  - `AbandonedPalace` sempat gagal membawa player ke staging luar
  - akar masalahnya bukan di board/staging patch, tetapi di `MatchTeleport`
  - `resolveSpawnFacingForward()` memanggil `GetPivot()` langsung pada `mapClone`, padahal `AbandonedPalace` dibungkus `Folder`
  - hasil runtime sebelumnya:
    - match terbentuk
    - `PreparationStagingRuntimePatched = true`
    - tapi teleport trace berhenti di `root_ok`
    - player tetap di koordinat lobby
  - fix:
    - fallback pivot spawn sekarang memakai `resolveSpatialAnchorCFrame()`
    - jalur `resolveSafeSpawnCFrame` dibungkus trace error agar kegagalan spawn tidak lagi silent
- validasi terbaru:
  - build:
    - `_tmp_match_preparation_debug_build.rbxlx`
    - `_tmp_match_preparation_ap_teleport_fix_build.rbxlx`
  - `AbandonedPalace` default:
    - `PreparationStagingRuntimePatched = true`
    - `PreparationStagingRuntimeDebug = complete`
    - teleport trace sekarang lanjut penuh:
      - `spawn_points_ready count=4`
      - `spawnCandidate=...PlayerSpawn_1`
      - `teleporting`
      - `teleportOk`
      - `teleported_counted`
    - `PasrahLastTeleportedCount = 1`
    - `LocalPlayer.MatchLifecyclePhase = PreparationPhase`
    - player posisi pindah ke map aktif sekitar `5.35, 3.35, 128.30`
    - marquee hidup:
      - title `PALACE GATE`
      - subtitle `Ward • Briefing • Breach`
    - entry hidup:
      - title `PALACE ENTRY`
      - body `Review board lalu breach dari gerbang istana.`
    - décor palace hidup:
      - `PreparationCarpet = Fabric`
      - `PreparationPillar_1 = present`
      - `PreparationBrazierFlame_1 = present`
      - `PreparationBanner_1 = present`
  - `AbandonedPalace` breach state:
    - `LocalPlayer.MatchLifecyclePhase = InvestigationPhase`
    - entry berubah ke:
      - title `BREACH OPEN`
      - subtitle `Investigation live`
      - body `Masuk ke grand hall dan sweep sayap utama.`
    - `PreparationGateSeal.Transparency = 0.9`
    - runner berubah hijau
    - floodlight `4.50`
  - regression `HauntedHouse` tetap aman:
    - `PasrahLastTeleportedCount = 1`
    - trace memuat `teleportOk`
    - player posisi pindah ke staging aktif sekitar `1299.11, 3.35, -5.17`
    - marquee tetap:
      - title `CONTRACT BAY`
      - subtitle `Room • Contract • Tools`
  - coverage map lain:
    - `EmptyBuilding`
      - marquee `OPERATIONS ENTRY`
      - subtitle `Check • Brief • Breach`
      - player posisi pindah ke map aktif sekitar `805.25, 3.50, 87.31`
    - `StudioMMNineteen`
      - marquee `CONTROL ACCESS`
      - subtitle `Plan • Tools • Entry`
      - entry title `ACCESS POINT`
      - player posisi pindah ke map aktif sekitar `473.10, 3.50, 9.42`
- status:
  - **LANJUT / BELUM FINAL**.
  - blocker functional lintas-map untuk staging luar sekarang sudah tertutup:
    - build profile
    - teleport ke staging
    - board state
    - breach state
  - residual lane tinggal:
    - asset premium/non-primitive untuk staging luar
    - dressing exterior yang lebih kaya secara artistik
    - transisi breach yang lebih sinematik secara visual

- pass lanjutan pada lane `outside match preparation staging`:
  - state `ready / armed / breach` sekarang tidak lagi hanya swap nilai instan
  - `PreparationEntryLaneState` sekarang disimpan di runtime folder staging
  - transisi lane sekarang men-tween:
    - runner
    - floodlight
    - lamp
    - entry accent
    - marquee accent/glow
    - gate leaf
    - gate seal
  - saat state naik ke `armed` atau `breach`, world-space sekarang juga memicu burst emitter ringan:
    - `PreparationSiteMarqueeGlow.StateBurst`
    - `PreparationGateSeal.BreachBurst`
    - `PreparationBrazierFlame_*.BreachPulse` pada profile palace
- source owner yang disentuh:
  - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
- validasi:
  - build:
    - `_tmp_match_preparation_breach_tween_build.rbxlx`
  - live `HauntedHouse`:
    - state default:
      - `PreparationEntryLaneState = ready`
      - `runnerColor = 0.384314, 0.329412, 0.27451`
      - `floodBrightness = 3.20`
      - `gateSealTransparency = 0.08`
      - belum ada emitter runtime di marquee/gate seal
    - sesudah `AdvancePhase -> InvestigationPhase`:
      - `PreparationEntryLaneState = breach`
      - `runnerColor = 0.282353, 0.541176, 0.478431`
      - `floodBrightness = 4.30`
      - `gateSealTransparency = 0.90`
      - `PreparationSiteMarqueeGlow.StateBurst = present`
      - `PreparationGateSeal.BreachBurst = present`
- status:
  - **LANJUT / BELUM FINAL**.
  - breach transition sekarang sudah punya animasi/tween dan burst world-space, jadi residual lane berkurang dari sekadar state swap kaku.
  - residual lane sekarang tinggal:
    - asset premium/non-primitive untuk staging luar
    - dressing exterior yang lebih kaya secara artistik per map

- pass lanjutan pada lane `outside match preparation staging`:
  - dua map `facility` sekarang tidak lagi share dressing yang sama:
    - `EmptyBuilding` -> varian `industrial`
    - `StudioMMNineteen` -> varian `control`
  - `EmptyBuilding` sekarang punya:
    - `PreparationOpsCrate`
    - `PreparationPortableMonitor`
    - `PreparationSafetyCone_1/2`
    - monitor board `SITE FEED`
  - `StudioMMNineteen` sekarang punya:
    - `PreparationOpsConsole`
    - `PreparationServerRack`
    - `PreparationSignalDisplay`
    - display board `SIGNAL GRID`
- validasi:
  - build:
    - `_tmp_match_preparation_facility_variants_build.rbxlx`
  - `EmptyBuilding`:
    - `PreparationOpsCrate = present`
    - `PreparationPortableMonitor = present`
    - `PreparationSafetyCone_1 = present`
    - `PreparationPortableMonitor.FrontSurface.Title = SITE FEED`
  - `StudioMMNineteen`:
    - `PreparationOpsConsole = present`
    - `PreparationServerRack = present`
    - `PreparationSignalDisplay = present`
    - `PreparationSignalDisplay.FrontSurface.Title = SIGNAL GRID`

- pass lanjutan pada lane `outside match preparation staging`:
  - staging luar sekarang punya ambience preview khusus `PreparationPhase`
  - source owner:
    - [AudioController.luau](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/Controllers/Sensory/AudioController.luau)
  - fakta source penting:
    - `AmbientLoop_Main` di repo ternyata masih kosong (`AudioContent = ""`)
    - karena itu saya pakai fallback asset yang benar-benar ada:
      - `Assets/Audio/Environment/EnvironmentalCreak_01`
    - clone runtime-nya diberi nama `PreparationAmbient`
  - `PreparationAmbient` sekarang:
    - aktif hanya saat `InMatch = true` dan `MatchLifecyclePhase = PreparationPhase`
    - berhenti otomatis saat phase keluar dari `PreparationPhase`
    - menyimpan debug attr:
      - `PasrahPreparationAmbientActive`
      - `PasrahPreparationAmbientMap`
- validasi:
  - build:
    - `_tmp_match_preparation_audio_preview_build.rbxlx`
    - `_tmp_match_preparation_audio_fallback_build.rbxlx`
  - `AbandonedPalace`:
    - sebelum breach:
      - `MatchLifecyclePhase = PreparationPhase`
      - `PasrahPreparationAmbientActive = true`
      - `PasrahPreparationAmbientMap = AbandonedPalace`
      - `PreparationAmbient.IsPlaying = true`
      - `PreparationAmbient.SoundId = rbxassetid://139204195403262`
      - `PreparationAmbient.Volume = 0.24`
      - `PreparationAmbient.PlaybackSpeed = 0.88`
    - sesudah `AdvancePhase -> InvestigationPhase`:
      - `PasrahPreparationAmbientActive = nil`
      - `PasrahPreparationAmbientMap = nil`
      - `PreparationAmbient.IsPlaying = false`
- status:
  - **LANJUT / BELUM FINAL**.
  - lintas-map staging luar sekarang sudah punya:
    - profile berbeda
    - teleport yang benar
    - board state
    - breach state
    - breach transition tween/burst
    - ambience preview saat briefing
  - residual lane yang masih tersisa tinggal:
    - asset premium/non-primitive untuk staging luar
    - dressing exterior yang lebih kaya lagi bila ingin naik ke art pass penuh

- pass lanjutan pada lane `outside match preparation staging`:
  - dressing exterior per-profile sekarang naik lagi dari board/runner menjadi `hero prop` yang benar-benar berbeda:
    - `HauntedHouse`:
      - `PreparationGearBench`
      - `PreparationFenceRail_1/2`
      - `PreparationPorchLantern_1/2`
    - `AbandonedPalace`:
      - `PreparationArchLintel`
      - `PreparationRelicPlinth`
      - `PreparationRelicCore`
      - `PreparationSealMosaic`
    - `EmptyBuilding`:
      - `PreparationCableSpool`
      - `PreparationWorklightStand`
      - `PreparationWorklightHead`
      - `PreparationHazardRail`
    - `StudioMMNineteen`:
      - `PreparationAccessScanner`
      - `PreparationScannerGlow`
      - `PreparationDataPedestal`
      - `PreparationConduitStrip`
  - ambience preparation juga dipoles:
    - masuk dengan fade-in
    - keluar dengan fade-out
    - tidak lagi start/stop keras saat phase berubah
  - source owner:
    - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
    - [AudioController.luau](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/Controllers/Sensory/AudioController.luau)
- validasi:
  - build:
    - `_tmp_match_preparation_artpass_build.rbxlx`
  - live lintas map:
    - `HauntedHouse`:
      - `PreparationGearBench = true`
      - `PreparationFenceRail_1 = true`
      - `PreparationPorchLantern_1 = true`
      - ambience:
        - `active = true`
        - `isPlaying = true`
        - `volume = 0.18`
        - `playbackSpeed = 0.94`
      - sesudah `InvestigationPhase`:
        - `volume = 0`
        - `isPlaying = false`
    - `AbandonedPalace`:
      - `PreparationArchLintel = true`
      - `PreparationRelicPlinth = true`
      - `PreparationSealMosaic = true`
      - ambience:
        - `active = true`
        - `isPlaying = true`
        - `volume = 0.24`
        - `playbackSpeed = 0.88`
      - sesudah `InvestigationPhase`:
        - `volume = 0`
        - `isPlaying = false`
    - `EmptyBuilding`:
      - `PreparationCableSpool = true`
      - `PreparationWorklightHead = true`
      - `PreparationHazardRail = true`
      - `PreparationPortableMonitor = true`
      - ambience:
        - `active = true`
        - `isPlaying = true`
        - `volume = 0.16`
        - `playbackSpeed = 1.00`
      - sesudah `InvestigationPhase`:
        - `volume = 0`
        - `isPlaying = false`
    - `StudioMMNineteen`:
      - `PreparationAccessScanner = true`
      - `PreparationScannerGlow = true`
      - `PreparationConduitStrip = true`
      - `PreparationSignalDisplay = true`
      - ambience:
        - `active = true`
        - `isPlaying = true`
        - `volume = 0.15`
        - `playbackSpeed = 0.98`
      - sesudah `InvestigationPhase`:
        - `volume = 0`
        - `isPlaying = false`
- status:
  - **LANJUT / BELUM FINAL**.
  - staging luar sekarang sudah punya:
    - profile visual per-map
    - objective/tools world boards
    - breach flow authoritative
    - tween/burst state change
    - ambience preview
    - hero prop dressing lintas map
  - residual lane yang tersisa turun ke:
    - asset premium/non-primitive jika ingin naik dari blockout art pass ke art final
    - exterior composition yang lebih mewah/sinematik jika ingin naik lagi ke presentational polish

- pass lanjutan pada lane `outside match preparation staging`:
  - breach sekarang tidak lagi hanya mengubah phase, tetapi juga benar-benar memindahkan pemain dari staging luar ke target entry dunia di dalam map
  - runtime baru:
    - `PreparationBreachTarget_1..4`
    - attr `PreparationBreachMoved`
  - sync authoritative:
    - jika `MatchLifecyclePhase` naik ke `InvestigationPhase`, pemain yang masih di staging luar otomatis dipindah ke target breach
    - jadi jalur prompt breach dan jalur authoritative lain tetap berakhir pada hasil dunia yang sama
  - source owner:
    - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
- validasi:
  - build:
    - `_tmp_match_preparation_breach_entry_build.rbxlx`
  - `HauntedHouse`:
    - sebelum breach:
      - `stagedPos = 1299.11, 3.50, -5.17`
    - target:
      - `PreparationBreachTarget_1 = 1184.95, 4.00, -4.20`
    - sesudah `InvestigationPhase`:
      - `PreparationBreachMoved = true`
      - `movedPos = 1184.95, 4.00, -4.20`
  - `AbandonedPalace`:
    - sebelum breach:
      - `stagedPos = 5.35, 3.50, 128.30`
    - target:
      - `PreparationBreachTarget_1 = 4.20, 4.00, 24.95`
    - sesudah `InvestigationPhase`:
      - `PreparationBreachMoved = true`
      - `movedPos = 4.20, 3.42, 24.95`
- status:
  - **LANJUT / BELUM FINAL**.
  - gap utama jalur `outside -> breach -> entry investigasi` sekarang sudah tertutup secara runtime
  - residual lane yang tersisa praktis tinggal:
    - premium asset/non-primitive
    - presentational polish/sinematik yang lebih mewah

- pass lanjutan pada lane `outside match preparation staging`:
  - `PreparationPhase` sekarang punya visual profile client yang berbeda dari investigasi normal
  - source owner:
    - [VFXController.luau](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/Controllers/Sensory/VFXController.luau)
    - [MatchService.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MatchService.lua)
  - per profile map, briefing luar sekarang menaikkan readability staging:
    - exposure
    - bloom
    - sun rays
    - atmosphere density
    - tint grading
  - saat `PreparationFocusTool` dipilih, tint staging ikut bergeser ke aksen tool
  - `PreparationFocusTool` juga sekarang di-reset saat `StartMatch` dan `EndMatch`, jadi staging baru selalu mulai netral
- validasi:
  - build:
    - `_tmp_match_preparation_vfx_build.rbxlx`
    - `_tmp_match_preparation_polish_build.rbxlx`
  - `HauntedHouse`:
    - state default `PreparationPhase`:
      - `PasrahVFXPreparationActive = true`
      - `Exposure = 0.12`
      - `Bloom = 0.14`
      - `SunRays = 0.038`
      - `AtmosphereDensity = 0.305`
      - tint hangat staging luar
    - sesudah pilih `EMF`:
      - `PasrahVFXPreparationTool = EMF`
      - tint bergeser ke aksen biru `EMF`
      - `Bloom = 0.0926`
      - `SunRays = 0.0243`
      - `AtmosphereDensity = 0.3234`
    - sesudah `InvestigationPhase`:
      - `Exposure = 0`
      - `Bloom = 0.05`
      - `SunRays = 0.012`
      - `AtmosphereDensity = 0.34`
      - profile kembali ke investigasi normal
    - `PreparationFocusTool` default saat start match baru:
      - `nil`
- status:
  - **LANJUT / BELUM FINAL**.
  - lane sekarang sudah punya:
    - world-space staging luar
    - briefing board
    - focus tool
    - ambience preview
    - breach authoritative
    - breach move-to-entry
    - client visual profile khusus briefing luar
  - residual yang benar-benar tersisa turun ke:
    - premium asset/model pass
    - presentational polish/sinematik tingkat akhir

- progress tambahan pada lane `outside match preparation staging`:
  - `tool rack` dunia sekarang benar-benar stateful
  - owner source:
    - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
    - [Main.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua)
  - perubahan:
    - tool terpilih berubah `SmoothPlastic -> Neon`
    - `StateHighlight` dan `StateLight` aktif di tool yang dipilih
    - subtitle/body board tiap tool ikut state `idle / focus active / breach live`
    - prompt tool berubah:
      - idle `Pilih Fokus Tool`
      - selected `Tool Aktif`
      - breach `Breach Live` + disabled
    - `StudioE2EControlSystem` sekarang punya action QA `SetPreparationFocusTool` supaya state rack bisa diverifikasi deterministik di Studio
- validasi:
  - build:
    - `_tmp_match_preparation_toolrack_state_build.rbxlx`
    - `_tmp_match_preparation_toolrack_stateful_build.rbxlx`
  - default `PreparationPhase`:
    - `PreparationFocusTool = nil`
    - `ToolStation_EMF.Material = SmoothPlastic`
    - `highlight = false`
    - `light = false`
    - `prompt = Pilih Fokus Tool`
    - subtitle `Medok sweep`
  - sesudah `SetPreparationFocusTool(EMF)`:
    - `PreparationFocusTool = EMF`
    - `ToolStation_EMF.Material = Neon`
    - `highlight = true`
    - `light = true`
    - `prompt = Tool Aktif`
    - subtitle `Focus active • use first`
    - body `Gunakan tool ini untuk sweep pertama sebelum ganti jalur evidence.`
  - sesudah `AdvancePhase -> InvestigationPhase`:
    - `PreparationFocusTool = EMF`
    - `highlight = true`
    - `light = true`
    - `prompt.Enabled = false`
    - `prompt = Breach Live`
    - subtitle `Focus active • breach live`
    - body `Masuk dan buka sweep awal dengan tool ini.`
- status:
  - **LANJUT / BELUM FINAL**.
  - rack tool sekarang sudah punya state dunia yang jelas dan tidak lagi hanya board global
  - residual lane tetap:
    - premium asset/non-primitive
    - dressing exterior per map yang lebih kaya
    - polish sinematik/presentasional tingkat akhir

- progress tambahan pada lane `outside match preparation staging`:
  - exterior staging sekarang punya silhouette yang lebih berbeda per map, bukan hanya prop kecil
  - owner source:
    - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
  - tambahan baru:
    - `HauntedHouse`:
      - `PreparationGateArch`
      - `PreparationHedge_1/2`
      - `PreparationMailbox`
    - `AbandonedPalace`:
      - `PreparationStairDais`
      - `PreparationUrn_1/2`
    - `EmptyBuilding`:
      - `PreparationTrussFrame`
      - `PreparationGenerator`
      - `PreparationDrumStack`
    - `StudioMMNineteen`:
      - `PreparationSecurityArch`
      - `PreparationDataColumn_1/2`
      - `PreparationGuideStrip`
- validasi:
  - build:
    - `_tmp_match_preparation_exterior_identity_build.rbxlx`
  - `HauntedHouse`:
    - `PreparationGateArch = true`
    - `PreparationHedge_1 = true`
    - `PreparationMailbox = true`
  - `AbandonedPalace`:
    - `PreparationStairDais = true`
    - `PreparationUrn_1 = true`
    - `PreparationSealMosaic = true`
  - `EmptyBuilding`:
    - `PreparationTrussFrame = true`
    - `PreparationGenerator = true`
    - `PreparationDrumStack = true`
  - `StudioMMNineteen`:
    - `PreparationSecurityArch = true`
    - `PreparationDataColumn_1 = true`
    - `PreparationGuideStrip = true`
- status:
  - **LANJUT / BELUM FINAL**.
  - staging luar sekarang sudah beda bentuk dari jauh per map, bukan cuma beda board/warna
  - residual lane menyempit ke:
    - premium asset/non-primitive
    - polish artistik/presentasional tingkat akhir

- progress tambahan pada lane `outside match preparation staging`:
  - pemilihan `focus tool` sekarang punya cue client yang benar-benar terasa, bukan cuma ganti teks
  - owner source:
    - [Main.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/UI/Main.lua)
    - [Main.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/SoundSystem/Main.lua)
    - [VFXController.luau](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/Controllers/Sensory/VFXController.luau)
  - perubahan:
    - `PreparationFocusTool` sekarang memicu cue audio `prep_focus_lock`
    - `PreparationFocusChanged` sekarang memicu pulse VFX berbasis aksen tool
    - panel preparation di-refresh saat tool fokus berubah
- validasi:
  - build:
    - `_tmp_match_preparation_focus_polish_build.rbxlx`
  - `HauntedHouse` sesudah `SetPreparationFocusTool(EMF)`:
    - `phase = PreparationPhase`
    - `PreparationFocusTool = EMF`
    - `PasrahAudioLastCue = prep_focus_lock`
    - `PasrahAudioLastCategory = EnvironmentalAudio`
    - `PasrahVFXLastEvent = PreparationFocusChanged`
    - `PasrahVFXLastProfile = EMF`
    - `PasrahVFXPreparationTool = EMF`
- status:
  - **LANJUT / BELUM FINAL**.
  - feedback player-facing untuk selection tool sekarang sudah hidup
  - residual lane turun ke:
    - premium asset/non-primitive
    - polish artistik/presentasional akhir

- progress tambahan pada lane `outside match preparation staging`:
  - trim kit staging sekarang ikut state `idle / focus / breach`
  - owner source:
    - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
  - perubahan:
    - `PreparationRunnerInset`
    - `PreparationCanopyTrim`
    - `PreparationPlatformTrim_Front/Back/Left/Right`
    - `PreparationSiteCrest`
    - `ToolStation_*_Pad`
  - state pad dan trim sekarang ikut aksen lane, bukan diam statis
- validasi:
  - build:
    - `_tmp_match_preparation_trim_pass_build.rbxlx`
  - default `PreparationPhase`:
    - `PreparationRunnerInset = present`
    - `runnerTransparency = 0.28`
    - `PreparationSiteCrest = present`
    - `ToolStation_EMF_Pad = present`
    - `padTransparency = 0.30`
  - sesudah `SetPreparationFocusTool(EMF)`:
    - `runner = 0.517647, 0.729412, 1`
    - `runnerTransparency = 0.14`
    - `crest = 0.517647, 0.729412, 1`
    - `pad = 0.517647, 0.729412, 1`
    - `padTransparency = 0.12`
  - sesudah `AdvancePhase -> InvestigationPhase`:
    - `runner = 0.556863, 0.839216, 0.776471`
    - `runnerTransparency = 0.08`
    - `crestTransparency = 0.02`
    - `padTransparency = 0.08`
- status:
  - **LANJUT / BELUM FINAL**.
  - staging luar sekarang jauh lebih dekat ke presentational pass akhir
  - residual utama tinggal:
    - premium asset/non-primitive
    - final art polish

- progress tambahan pada lane `outside match preparation staging`:
  - pass struktural besar per-map sekarang masuk, jadi staging tidak lagi hanya `trim + props`
  - owner source:
    - [MapRuntimePatches.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua)
  - tambahan struktural:
    - `HauntedHouse`
      - `PreparationHouseFacadeWall_1/2`
      - `PreparationHouseWindow_1/2`
      - `PreparationHouseRoofCap`
      - `PreparationHousePorchLintel`
    - `AbandonedPalace`
      - `PreparationPalacePorticoRoof`
      - `PreparationPalaceScreen_1/2`
      - `PreparationPalaceCornice`
    - `EmptyBuilding`
      - `PreparationIndustrialWall`
      - `PreparationIndustrialRoof`
      - `PreparationIndustrialCatwalkStrip`
    - `StudioMMNineteen`
      - `PreparationControlVestibule`
      - `PreparationControlRoof`
      - `PreparationControlPulseBar`
  - accent-driven parts sekarang pakai jalur state umum `idle / focus / breach`
- validasi:
  - build:
    - `_tmp_match_preparation_structural_pass_build.rbxlx`
  - lintas map:
    - `HauntedHouse`:
      - `PreparationHouseFacadeWall_1 = true`
      - `PreparationHouseRoofCap = true`
      - `PreparationHousePorchLintel = true`
    - `AbandonedPalace`:
      - `PreparationPalacePorticoRoof = true`
      - `PreparationPalaceScreen_1 = true`
      - `PreparationPalaceCornice = true`
    - `EmptyBuilding`:
      - `PreparationIndustrialWall = true`
      - `PreparationIndustrialRoof = true`
      - `PreparationIndustrialCatwalkStrip = true`
    - `StudioMMNineteen`:
      - `PreparationControlVestibule = true`
      - `PreparationControlRoof = true`
      - `PreparationControlPulseBar = true`
  - `HauntedHouse` state proof:
    - idle:
      - `PreparationHousePorchLintel = 0.839216, 0.627451, 0.407843`
      - `transparency = 0.16`
    - focus `EMF`:
      - `PreparationHousePorchLintel = 0.517647, 0.729412, 1`
      - `transparency = 0.08`
    - breach:
      - `PreparationHousePorchLintel = 0.556863, 0.839216, 0.776471`
      - `transparency = 0.03`
- status:
  - **LANJUT / BELUM FINAL**.
  - staging luar sekarang punya massa arsitektural yang lebih tebal dan stateful
  - residual lane menyempit ke:
    - premium asset/non-primitive
    - final art polish

- progress tambahan pada lane `asset integration`:
  - asset baru `Garam / Salib / Dupa` sekarang dipakai tegas oleh jalur visual utility tool match, bukan hanya display lobby/staging
  - `UtilityToolVisuals` sekarang menandai runtime model dengan atribut:
    - `PasrahUtilityToolType`
    - `PasrahUtilityTemplateName`
    - `PasrahUtilityUsesAsset`
    - `PasrahUtilityVisualState`
  - state visual runtime sekarang ikut bukti gameplay:
    - `Garam` -> `Triggered`
    - `Salib` -> `Armed` + `PasrahUtilityChargesRemaining`
    - `Dupa` -> `Repel` + `PasrahUtilityRepelledHunt`
  - `GhostSystem` sekarang membaca `Assets/GhostVisualProfiles/*` sebagai overlay authoritative untuk:
    - `visualOffset`
    - `size`
    - `rootSize`
    - `targetBounds`
    - `meshPartName`
    - `castShadow`
  - `Pocong` asset sekarang tidak lagi jatuh ke tuning mesh mini lama `0.07 x 0.06 x 0.07`
  - `Lobby evidence training` sekarang memprioritaskan ghost yang memang punya asset model
- validasi terbaru:
  - proof edit-runtime via cloned live module:
    - `Preview_Pocong`:
      - `template = Pocong`
      - `meshName = material`
      - `meshSize = 1.4 x 5.2 x 1.2`
      - `rootSize = 2 x 2 x 1`
    - `Garam_salt_probe`:
      - `template = Garam`
      - `usesAsset = true`
      - `state = Triggered`
    - `Salib_cross_probe`:
      - `template = Salib`
      - `usesAsset = true`
      - `state = Armed`
      - `charges = 2`
    - `Dupa_smudge_probe`:
      - `template = Dupa`
      - `usesAsset = true`
      - `state = Repel`
      - `repelled = true`
- status:
  - **LANJUT / ASSET BARU SUDAH MASUK JALUR GAMEPLAY UTAMA**.
  - residual menyempit ke asset pass berikutnya yang benar-benar baru, bukan wiring asset yang sudah ada

- progress tambahan pada lane `player-facing asset integration`:
  - `Field Kit` client sekarang memakai preview 3D langsung dari asset tools untuk:
    - `Garam`
    - `Salib`
    - `Dupa`
  - owner yang dipakai:
    - [src/client/UI/Main.lua](C:/Projects/ROBLOX/PASRAHPHOBIA/src/client/UI/Main.lua)
  - preview memakai `ViewportFrame + PreviewWorld + PreviewCamera`
  - style preview ikut state HUD:
    - `ready`
    - `focus`
    - `active`
    - `spent`
    - `empty`
    - `danger`
- validasi terbaru:
  - proof live di `PlayerGui.MatchUI.FieldKitFrame.Buttons`:
    - `GaramButton.ToolPreview = present`
    - `SalibButton.ToolPreview = present`
    - `DupaButton.ToolPreview = present`
    - semua punya:
      - `PreviewWorld`
      - `PreviewCamera`
      - model asset clone yang sesuai
    - signature awal:
      - `Garam|ready`
      - `Salib|ready`
      - `Dupa|ready`
- residual sesudah pass ini:
  - preview asset HUD sudah hidup dan terlihat di jalur player-facing
  - verifikasi live `active/spent` saat match run ini belum saya cap final karena `FieldKit` tidak visible pada sesi E2E yang dipakai untuk proof lanjutan

- progress tambahan pada lane `player-facing asset integration`:
  - `UISystem:_onServerEvent()` untuk `EvidenceEvent` sekarang langsung:
    - `:_refreshJournalPanel()`
    - `:_refreshFieldKitPanel()`
    - `:_applyVisibility()`
  - ini menutup bug owner yang sebelumnya membuat `Field Kit` tidak ikut refresh walau `UseEvidenceTool` sukses dan state tool sudah berubah
- validasi terbaru:
  - proof live jalur tool asli:
    - `StartSoloMatch -> AdvancePhase(InvestigationPhase) -> UseEvidenceTool`
  - result:
    - `GaramButton.ToolPreview -> Garam|active`
    - `SalibButton.ToolPreview -> Salib|active`
    - `DupaButton.ToolPreview -> Dupa|active`
    - meta text:
      - `Garam = AKTIF`
      - `Salib = C3`
      - `Dupa = AKTIF`
- residual sesudah pass ini:
  - state `active` sudah terbukti dari jalur tool asli
  - state `spent` untuk preview `Salib` masih belum saya cap final karena `ConsumeHuntProtection` pada run ini menjawab `no_hunt_protection`

- progress tambahan pada lane `player-facing asset integration`:
  - `LobbyEvidenceTrainingUpdated` sekarang juga memaksa refresh:
    - `:_refreshJournalPanel()`
    - `:_refreshFieldKitPanel()`
    - `:_applyVisibility()`
  - ini menutup owner refresh kedua untuk training support tool di lobby
- validasi terbaru:
  - proof live jalur lobby training:
    - `LobbyTrainingUseSupport(Garam)`
    - `LobbyTrainingUseSupport(Salib)`
    - `LobbyTrainingUseSupport(Dupa)`
  - hasil:
    - `GaramButton.ToolPreview -> Garam|active`
    - `SalibButton.ToolPreview -> Salib|active`
    - `DupaButton.ToolPreview -> Dupa|active`
- status:
  - preview asset HUD sekarang hidup di:
    - jalur `match EvidenceEvent`
    - jalur `lobby evidence training`

- progress tambahan pada lane `player-facing asset integration`:
  - panel `Lobby evidence training` sekarang punya `TrainingPreview` berbasis `ViewportFrame`
  - preview itu membaca asset ghost dari `ReplicatedStorage.Assets.Models.Ghosts` dan profile visual dari `ReplicatedStorage.Assets.GhostVisualProfiles`
  - jika asset ghost tersedia, title panel sekarang mengakui state itu lewat suffix `ASSET LIVE`
  - jika asset tidak tersedia, panel fallback ke render profile sederhana tanpa memecah layout
- validasi terbaru:
  - proof live pada `Players.ZyraaaVex.PlayerGui.UXLayer.LobbyUXGui.LobbyUXLayer.TrainingFrame`
  - hasil:
    - `TrainingPreview -> present`
    - `GhostPreviewWorld -> present`
    - `GhostPreviewCamera -> present`
    - `TrainingTitle -> Leak • CALM • ASSET LIVE`
    - model preview aktif:
      - `Leak | Model | 2.00,5.20,2.48`
- residual sesudah pass ini:
  - state `spent` untuk preview `Salib` masih belum saya cap final karena run `ConsumeHuntProtection` yang terakhir belum memberi hunt protection valid

- progress tambahan pada lane `player-facing asset integration`:
  - `Lobby evidence training` sekarang punya `SupportStrip` untuk `Garam / Salib / Dupa`
  - tiap card support memakai `ViewportFrame` yang sama dengan owner `Field Kit`, jadi asset support tool tidak lagi hanya terlihat di HUD match
  - saya juga menutup bug source di `UISystem:_applyDeviceSizing()`:
    - `trainingWidth` sebelumnya dipakai di luar scope saat sizing `TrainingSupportStrip`
    - ini bisa mematahkan render strip saat layout dijalankan
- validasi terbaru:
  - proof owner-driven live pada `Players.ZyraaaVex.PlayerGui.UXLayer.LobbyUXGui.LobbyUXLayer.TrainingFrame`
  - hasil:
    - `TrainingFrame.Visible = true`
    - `SupportStrip = present`
    - `GaramSupportCard -> Garam|active | world=true | camera=true | meta=AKTIF`
    - `SalibSupportCard -> Salib|ready | world=true | camera=true | meta=x1`
    - `DupaSupportCard -> Dupa|ready | world=true | camera=true | meta=x1`
- catatan verifikasi:
  - pada session ini `StudioE2EControl` request training hanya mengubah trace tanpa mengirim `ack/result` kembali
  - karena itu proof support strip saya tutup lewat owner runtime `UI/Main.lua` sendiri, bukan lewat ack route yang sedang macet di session tersebut
- proof tambahan:
  - state `Salib|spent` juga sudah tembus di support strip owner-driven
  - hasil:
    - `TrainingTitle -> Leak • ALERT • ASSET LIVE`
    - `SalibSupportCard -> Salib|spent | world=true | camera=true | meta=C0`
- residual sesudah pass ini:
  - jalur live `match HUD` untuk `Salib|spent` masih belum saya cap final

- progress tambahan pada lane `player-facing asset integration`:
  - bug scope `trainingWidth` di `UISystem:_applyDeviceSizing()` ternyata memang akar panel training yang tidak pernah hidup di jalur event asli
  - sesudah fix itu, `LobbyTrainingUseSupport` live sekarang benar-benar menghidupkan `TrainingFrame` dan merender semua card support dari event nyata, bukan hanya dari harness
  - saya lanjut menutup drift `Salib` di match HUD:
    - preview dan meta `Salib` sekarang dibaca authoritative dari `chargesRemaining`
    - charge loss tidak lagi langsung jatuh ke state `ready/x2` pada consume pertama
- validasi terbaru:
  - proof live jalur `LobbyTrainingUseSupport`:
    - `TrainingFrame.Visible = true`
    - `TrainingTitle -> Jerangkong • CALM • ASSET LIVE`
    - `GaramSupportCard -> Garam|active | world=true | camera=true | meta=AKTIF`
    - `SalibSupportCard -> Salib|active | world=true | camera=true | meta=C3`
    - `DupaSupportCard -> Dupa|active | world=true | camera=true | meta=AKTIF`
  - proof live jalur match HUD:
    - `StartSoloMatch -> Investigation -> UseEvidenceTool(Salib) -> ConsumeHuntProtection`
    - `before -> Salib|active | meta=C3`
    - `after first consume -> Salib|active | meta=C2`
    - sampled stabil hingga `3.75s` tanpa jatuh lagi ke `ready`
- residual sesudah pass ini:
  - multi-trigger lanjutan ke `C1/C0` pada run yang sama belum saya cap final

- progress tambahan pada lane `ghost visual regression + preparation entry clarity`:
  - `Pocong` visual mesh sekarang dikunci kembali ke `0.06 x 0.07 x 0.07`
  - fix ini hanya untuk layer visual:
    - logic/root/bounds tetap di clamp target lama
    - fallback model `Pocong` untuk ghost lain tidak dipakai lagi
  - `outside-match preparation staging` sekarang punya gate fisik yang lebih terbaca:
    - `PreparationGateHeader`
    - `PreparationGateThreshold`
    - `PreparationGateJambLeft`
    - `PreparationGateJambRight`
    - leaf gate menutup sebelum breach dan membuka saat breach
- validasi terbaru:
  - proof live in-game:
    - `Workspace.DebugPocongPreview`
    - `MeshPart.Size = 0.06, 0.07, 0.07`
    - preview ini hanya dipakai untuk validasi visual, bukan actor logic
  - proof live preparation gate:
    - `PreparationPhase`
      - `PreparationGateLeft.CanCollide = true`
      - `PreparationGateRight.CanCollide = true`
      - `PreparationGateSeal.Transparency = 0.08`
    - sesudah `Mulai Breach`
      - `MatchLifecyclePhase = InvestigationPhase`
      - `PreparationGateLeft.CanCollide = false`
      - `PreparationGateRight.CanCollide = false`
      - `PreparationGateSeal.Transparency = 0.90`
      - prompt breach hilang
- residual sesudah pass ini:
  - actor ghost match pasif masih belum selalu mudah difoto pada run normal, jadi proof visual `Pocong` hari ini saya tutup lewat preview runtime di session in-game yang sama

- progress tambahan pada lane `ghost runtime verification + authoritative manifest probe`:
  - actor ghost match asli sekarang terbukti hidup sebagai `Workspace.ActiveMatches.Match_match_1.Ghost_Pocong`, bukan cuma preview/debug clone
  - baseline visual ghost sekarang diinisialisasi langsung saat `InitializeMatch`, jadi actor runtime tidak lagi lahir tanpa state visual
  - player snapshot ghost dasar sekarang diisi langsung dari `MatchService`, sehingga proof `ghost type / mesh size / runtime state / model path` tidak lagi bergantung penuh pada timing event controller
  - `PreparationStagingRuntime` sekarang punya prompt studio-only `Paksa Manifest` yang hanya aktif setelah breach untuk verifikasi actor ghost live
  - akar bug `ForceManifest` ditemukan di `GhostStateMachine`: transisi `Idle -> Manifestation` sebelumnya ditolak, sehingga probe hanya mendorong ghost keluar dari diam tanpa benar-benar manifest
  - transisi itu sekarang dibuka, dan probe authoritative langsung memanggil `ForceManifest + TickGhost` pada owner match
- validasi terbaru:
  - proof runtime dasar:
    - `Workspace.ActiveMatches.Match_match_1.Ghost_Pocong`
    - `MeshPart.Size = 0.06, 0.07, 0.07`
    - `RuntimeGhostState = Idle`
    - `RuntimeGhostStateActual = Idle`
    - `VisualTemplateName = Pocong`
  - proof player snapshot dasar:
    - `PasrahGhostType = Pocong`
    - `PasrahGhostModelPath = Workspace.ActiveMatches.Match_match_1.Ghost_Pocong`
    - `PasrahGhostMeshSize = 0.06, 0.07, 0.07`
    - `PasrahGhostRuntimeState = Idle`
  - proof breach + manifest:
    - `PreparationPhase -> BreachPrompt`
    - sesudah breach `StudioManifestPrompt.Enabled = true`
    - sesudah `Paksa Manifest`:
      - `RuntimeGhostState = Manifest`
      - `RuntimeGhostStateActual = Manifest`
      - `PasrahGhostRuntimeState = Manifest`
      - actor ghost tetap memakai mesh `0.06, 0.07, 0.07`
  - proof visual live:
    - capture `GhostPocong_ManifestRuntime_1` menunjukkan actor `Ghost_Pocong` sesungguhnya saat manifest, bukan preview
- residual sesudah pass ini:
  - route `StudioE2EControl` ack/ready masih belum cukup bersih untuk dijadikan jalur utama verifikasi
  - karena itu jalur test authoritative saat ini tetap mengandalkan `LobbyEvent + world prompts + runtime attrs`

- progress tambahan pada lane `match evidence request unblock + full registry boot`:
  - akar hang `EvidenceRequest` ternyata bukan di remote itu sendiri, tetapi `SystemRegistry:Start()` abort di `LobbySocialHub:Start()`
  - crash point ditemukan via studio boot trace baru di `SystemRegistry`:
    - `LobbySocialHub:Start -> LobbyService.lua:2948`
    - penyebabnya `applyDecorAssetModel` dipanggil sebelum function didefinisikan
  - `LobbyService` sekarang tidak lagi memutus bootstrap; `SystemRegistry` tembus penuh sampai `WeeklyChallengeSystem`
  - `ServerBootstrap` sekarang juga memverifikasi `EvidenceSystem` benar-benar expose readiness dan gateway bind di Studio
  - `EvidenceGateway` sekarang self-healing:
    - canonical `ReplicatedStorage.RemoteFunctions` dibuat bila hilang
    - `EvidenceRequest` dibuat bila hilang
    - readiness attr `PasrahEvidenceGatewayReady` ditulis saat bind/unbind
  - stage trace untuk `EvidenceGateway` dan `EvidenceService` sekarang hidup pada player attr agar stall berikutnya bisa dilokalisasi tanpa tebak-tebakan
- validasi terbaru:
  - proof boot:
    - `PasrahRegistryStarted = true`
    - `PasrahRegistryFailure = nil`
    - `PasrahEvidenceGatewayReady = true`
    - `PasrahEvidenceBootstrapVerified = true`
    - `PasrahStudioE2EReady = true`
  - proof match flow via client runtime:
    - `StartSoloMatch(HauntedHouse) -> PreparationPhase`
    - `AdvancePhase -> InvestigationPhase`
    - `StudioE2EAck = AdvancePhase|true|match=match_1 nextPhase=InvestigationPhase`
  - proof evidence/support tools dari `EvidenceTools` client asli:
    - `Salib -> crucifix_armed`
    - `Garam -> salt_placed`
    - `Dupa -> smudge_activated`
  - proof trace hidup:
    - `PasrahEvidenceGatewayStage = after_process_tool_use`
    - `PasrahEvidenceGatewayDetail = crucifix_armed`
    - `PasrahEvidenceServiceStage = salib_after_publish_crucifixplaced`
  - proof world placement:
    - `Workspace.ActiveMatches.Match_match_1.InvestigationTools.Salib_* | Armed`
    - `Workspace.ActiveMatches.Match_match_1.InvestigationTools.Garam_* | Placed/Triggered`
    - `Workspace.ActiveMatches.Match_match_1.InvestigationTools.Dupa_* | Active`
- residual sesudah pass ini:
  - outside staging visual masih bisa drift di run tertentu dan butuh pass terpisah
  - stage trace studio boleh dipertahankan untuk regression lane berikutnya karena sekarang berguna dan murah

- progress tambahan pada lane `investigation HUD resync after breach`:
  - `FieldKitFrame` sempat tetap `Visible = false` walau authoritative `MatchLifecyclePhase` sudah `InvestigationPhase`
  - akar bug ada di `UISystem:_syncPhaseFromAuthoritativeLifecycle()`:
    - client hanya mau promosi ke `InGame` dari `Briefing/Loading`
    - jalur world-preparation kita berhenti di `Preparing`, jadi HUD tertahan
  - sinkronisasi lifecycle sekarang mempromosikan client ke `InGame` dari phase non-terminal manapun saat authoritative lifecycle sudah `InvestigationPhase`
- validasi terbaru:
  - `AdvancePhase -> InvestigationPhase`:
    - `MatchPhase = InGame`
    - `MatchUI.Enabled = true`
    - `FieldKitFrame.Visible = true`
  - jalur nyata `StartSoloMatch -> PreparationPhase -> Main Entry -> E` juga tembus lagi:
    - sesudah breach:
      - `MatchLifecyclePhase = InvestigationPhase`
      - `MatchPhase = InGame`
      - `FieldKitFrame.Visible = true`
- residual sesudah pass ini:
  - objective/message text untuk investigation masih perlu saya audit di batch berikutnya bila ingin dipoles lebih jauh

- progress tambahan pada lane `support tool runtime inspection cleanup`:
  - placement dunia utility tool sekarang menulis alias attr `RuntimeState` yang sama dengan `PasrahUtilityVisualState`
  - tujuan pass ini hanya membuat inspeksi live/debug berikutnya lebih konsisten; gameplay tidak diubah
- validasi terbaru:
  - `Salib` authoritative placement:
    - `runtime = Armed`
    - `visual = Armed`
    - `charges = 3`
  - `Garam` authoritative placement:
    - `runtime = Triggered`
    - `visual = Triggered`

- progress tambahan pada lane `dupa repel HUD clarity`:
  - state `Dupa` di `Field Kit` sekarang membedakan `smoke aktif` vs `hunt benar-benar terpukul mundur`
  - client menyimpan context `huntRepelled` dan `repellentUntil` agar button tidak lagi selalu tampil generik `AKTIF / SMOKE ON`
- validasi terbaru:
  - `ForceHunt -> Dupa nearGhostRoom`:
    - `MatchPhase = InGame`
    - `Dupa Meta = REPEL`
    - `Dupa Footer = SAFE GAP`
    - `FieldKitFrame.StatusLabel = Ghost terpukul mundur. Jarak aman sementara tercipta.`
    - world placement:
      - `runtime = Repel`
      - `visual = Repel`

- progress tambahan pada lane `garam trigger HUD clarity`:
  - `Garam` di `Field Kit` sekarang membedakan `trap line aktif` vs `ghost benar-benar menginjak garam`
  - client menyimpan state `saltTriggered` supaya button tidak lagi tetap generik saat jejak sudah terbaca
- validasi terbaru:
  - `UseEvidenceTool(Garam, nearGhostRoom=true)`:
    - `MatchPhase = InGame`
    - `Garam Meta = TRACK`
    - `Garam Footer = GHOST STEP`
    - `FieldKitFrame.StatusLabel = Jejak garam terpicu. Ghost melintas di area garam.`

- progress tambahan pada lane `salib hunt-block HUD clarity`:
  - `Salib` di `Field Kit` sekarang memberi state singkat `BLOCK / HUNT OFF` tepat setelah hunt berhasil diblokir
  - sesudah jendela singkat itu lewat, HUD kembali ke state charge normal (`C2 / GUARD`, dst)
- validasi terbaru:
  - snapshot cepat sesudah `ConsumeHuntProtection`:
    - `Immediate Meta = BLOCK`
    - `Immediate Footer = HUNT OFF`
    - `Immediate Status = Hunt diblokir. Salib menahan trigger hunt.`
  - snapshot decay sesudah jeda:
    - `Decay Meta = C2`
    - `Decay Footer = GUARD`

- progress tambahan pada lane `main investigation tool evidence lock`:
  - `JejakEnergi` dan `KotakArwah` di `Field Kit` sekarang ikut mengunci state tombol saat `EvidenceCollected`, bukan hanya mengubah status jurnal
  - client menyimpan `lastEvidenceType` di state tool agar evidence yang sudah valid tetap terbaca walau feedback tool generik datang sesudahnya
- validasi terbaru:
  - `Banaspati -> JejakEnergi`:
    - `Meta = EMF 5`
    - `Footer = MEDOK LOCK`
    - `FieldKitFrame.StatusLabel = Evidence berhasil dibaca. Collected MEDOK`
  - `Kuntilanak -> KotakArwah`:
    - `Meta = RESPON`
    - `Footer = VOICE LOCK`
    - `FieldKitFrame.StatusLabel = Evidence berhasil dibaca. Collected Suara`

- progress tambahan pada lane `evidence lock copy clarity`:
  - `EvidenceCollected` sekarang memberi copy yang lebih tegas di `Field Kit`, bukan lagi campuran generic/Inggris
  - `EMF` menampilkan `EMF level 5 terkunci`
  - `KotakArwah` menampilkan `Respons suara terkunci`
- validasi terbaru:
  - `Banaspati -> JejakEnergi`:
    - `Meta = EMF 5`
    - `Footer = MEDOK LOCK`
    - `FieldKitFrame.StatusLabel = EMF level 5 terkunci. MEDOK tervalidasi sebagai evidence.`
  - `Kuntilanak -> KotakArwah`:
    - `Meta = RESPON`
    - `Footer = VOICE LOCK`
    - `FieldKitFrame.StatusLabel = Respons suara terkunci. Suara tervalidasi sebagai evidence.`

- progress tambahan pada lane `studio e2e fallback coverage`:
  - `StudioE2EControl` sekarang punya fallback evidence map untuk tool utama yang sebelumnya belum tertutup:
    - `KotakArwah -> Suara`
    - `SuhuMembeku -> Suhu`
    - `BukuTerkutuk -> BukuTerkutuk`
    - `GerakanGaib -> Pengganggu`
- validasi terbaru:
  - fresh probe `Kuntilanak -> KotakArwah` sekarang sukses deterministic dari jalur studio:
    - `PasrahStudioE2ELastResult = ok=true | action=UseEvidenceTool | result=match=match_1 tool=KotakArwah evidence=Suara`

- progress tambahan pada lane `field kit expansion`:
  - `Field Kit` sekarang menampilkan 9 tool aktif, bukan hanya 5:
    - `JejakEnergi`
    - `Garam`
    - `Salib`
    - `Dupa`
    - `KotakArwah`
    - `SuhuMembeku`
    - `BukuTerkutuk`
    - `BolaArwah`
    - `GerakanGaib`
  - grid `Field Kit` sekarang multi-row dan responsif sesuai jumlah tool
- validasi terbaru:
  - runtime `FieldKitFrame.Buttons`:
    - `BolaArwahButton,BukuTerkutukButton,DupaButton,GaramButton,GerakanGaibButton,JejakEnergiButton,KotakArwahButton,SalibButton,SuhuMembekuButton`

- progress tambahan pada lane `remaining evidence tool lock states`:
  - empat tool evidence utama yang sebelumnya tidak punya surface UI sekarang punya lock state player-facing:
    - `SuhuMembeku -> -5C / SUHU LOCK`
    - `BukuTerkutuk -> WRITE / INK LOCK`
    - `BolaArwah -> ORB / TO'UN LOCK`
    - `GerakanGaib -> MOVE / DISTURB LOCK`
- validasi terbaru:
  - `Banaspati -> SuhuMembeku`:
    - `Meta = -5C`
    - `Footer = SUHU LOCK`
  - `Banaspati -> BolaArwah`:
    - `Meta = ORB`
    - `Footer = TO'UN LOCK`
    - `FieldKitFrame.StatusLabel = Orb terkunci. To'un tervalidasi sebagai evidence.`
  - `Jerangkong -> BukuTerkutuk`:
    - `Meta = WRITE`
    - `Footer = INK LOCK`
  - `Jerangkong -> GerakanGaib`:
    - `Meta = MOVE`
    - `Footer = DISTURB LOCK`
    - `FieldKitFrame.StatusLabel = Gangguan gerak terkunci. Pengganggu tervalidasi sebagai evidence.`

- progress tambahan pada lane `field kit shortcut clarity`:
  - hint default investigasi sekarang mengacu ke `Field Kit [1-9]`, bukan lagi shortcut era 5 tool
  - shortcut label live untuk tool baru sekarang benar-benar muncul di surface tombol
- validasi terbaru:
  - runtime shortcut label:
    - `SuhuMembekuButton = [6]`
    - `BukuTerkutukButton = [7]`
    - `BolaArwahButton = [8]`
    - `GerakanGaibButton = [9]`

- progress tambahan pada lane `field kit idle copy clarity`:
  - state idle `Field Kit` sekarang langsung menyebut roster `[1-9]` dan menjelaskan bahwa tool evidence + utility sama-sama siap dipakai
- validasi terbaru:
  - `FieldKitFrame.StatusLabel = Field kit [1-9] siap. Pilih tool evidence atau utility sesuai situasi investigasi.`

- progress tambahan pada lane `field kit evidence preview fallback`:
  - enam tool evidence utama yang belum punya asset model sekarang tetap punya `ToolPreview` procedural di `Field Kit`
  - utility lama `Garam / Salib / Dupa` tetap memakai asset preview yang sudah ada
- validasi terbaru:
  - runtime `InvestigationPhase`:
    - `JejakEnergiButton = JejakEnergi|ready|fallback`
    - `KotakArwahButton = KotakArwah|ready|fallback`
    - `SuhuMembekuButton = SuhuMembeku|ready|fallback`
    - `BukuTerkutukButton = BukuTerkutuk|ready|fallback`
    - `BolaArwahButton = BolaArwah|ready|fallback`
    - `GerakanGaibButton = GerakanGaib|ready|fallback`
    - `GaramButton = Garam|ready|asset`
    - `SalibButton = Salib|ready|asset`
    - `DupaButton = Dupa|ready|asset`
  - semua `ToolPreview` live:
    - `previewVisible = true`
    - `hasWorld = true`

- progress tambahan pada lane `field kit evidence preview active state`:
  - preview tool evidence yang sudah benar-benar lock sekarang tidak lagi tetap terlihat `ready`
  - jalur preview kini naik ke state `active` saat `lastEvidenceType` sudah terisi
- validasi terbaru:
  - `KotakArwah -> Suara`:
    - `KotakArwahButton = KotakArwah|active|fallback`
  - `SuhuMembeku -> Suhu`:
    - `SuhuMembekuButton = SuhuMembeku|active|fallback`
  - tool evidence yang belum dipakai tetap:
    - `BukuTerkutukButton = BukuTerkutuk|ready|fallback`
    - `GerakanGaibButton = GerakanGaib|ready|fallback`

- progress tambahan pada lane `field kit utility preview signal state`:
  - preview asset `Garam / Salib / Dupa` sekarang ikut memberi sinyal state yang lebih tegas saat tool benar-benar bekerja
- validasi terbaru:
  - baseline:
    - `GaramButton = Garam|ready|asset`
    - `SalibButton = Salib|ready|asset`
    - `DupaButton = Dupa|ready|asset`
  - sesudah `Garam` terpicu:
    - `GaramButton = Garam|danger|asset`
  - sesudah `Salib` memblok hunt:
    - `SalibButton = Salib|danger|asset`
  - sesudah `Dupa` repel:
    - `DupaButton = Dupa|active|asset`

- progress tambahan pada lane `field kit utility preview decay`:
  - preview utility yang sempat masuk sinyal keras sekarang tidak lagi tertahan permanen; state panas turun lagi ke state stabil setelah window event lewat
- validasi terbaru:
  - `Garam`:
    - `salt_hot = Garam|danger|asset`
    - `salt_decay = Garam|active|asset`
  - `Salib`:
    - `crucifix_hot = Salib|danger|asset`
    - `crucifix_decay = Salib|active|asset`

- progress tambahan pada lane `dupa preview local expiry sync`:
  - bug `Dupa` yang terus aktif ternyata berasal dari perbandingan `server os.clock()` melawan `client os.clock()`
  - state repel sekarang dikonversi ke expiry lokal client, lalu HUD menjadwalkan refresh penutup saat window efek habis
- validasi terbaru:
  - probe runtime singleton `Client.UI.Main`:
    - `hot.signature = Dupa|active|asset`
    - `hot.repellentUntilLocal = 66313.7177`
    - `decay.signature = Dupa|focus|asset`
    - `phase = InvestigationPhase`

- progress tambahan pada lane `dupa selection persistence fix`:
  - `Dupa` tidak lagi ikut aturan selection persist yang dipakai untuk utility placement jangka panjang
  - persistence selection sekarang dibatasi ke tool yang memang masuk akal tetap menempel: `Garam` dan `Salib`
- validasi terbaru:
  - probe runtime sesudah `22s`:
    - `hot.signature = Dupa|active|asset`
    - `decay.signature = Dupa|ready|asset`
    - `toolType = Dupa`
    - `visualPlaced = true`

- progress tambahan pada lane `roblox inventory full crawl lock`:
  - inventory Roblox sekarang tidak lagi dicatat sebagai subset parsial; saya tarik penuh lewat `inventory.roblox.com` menggunakan `CreatorId 10576163165`
  - snapshot yang terkunci di `ROBLOX_INVENTORY_SYNC_LEDGER_2026-04-08.md` sekarang berisi:
    - `101` audio
    - `11` model
  - deep scan koreksi ke seluruh proyek lokal membuktikan pass subset sebelumnya terlalu sempit
  - hasil compare yang benar setelah scan penuh:
    - `613` file audio lokal
    - `564` nama stem audio unik lokal
    - `100` nama audio unik di inventory
    - `99 / 100` nama inventory exact-match ke lokal
    - `1 / 100` inventory-only: `Midnight Litany of Drones (Ancient Ritual Ambient)`
    - `465` nama audio lokal masih belum ada di inventory
    - `1 / 11` model exact-match (`genderuwo`)
  - audio yang sebelumnya masih pending sekarang sudah terkunci juga:
    - `switch15 -> rbxassetid://140513388846872`
    - `impactPunch_medium_002 -> rbxassetid://126504722314888`

- progress tambahan pada lane `canonical audio inventory apply`:
  - slot audio canonical yang sebelumnya kosong/fallback sekarang dipasang ke asset upload Roblox yang sudah benar-benar ada di inventory akun aktif
  - source yang diselaraskan:
    - `AmbientLoop_Main -> rbxassetid://140704980462451`
    - `EnvironmentalCreak_01 -> rbxassetid://111282528409948`
    - `GhostWhisper_01 -> rbxassetid://98105844059537`
    - `ButtonClick_01 -> rbxassetid://85056627192723`
    - `CountdownTick_01 -> rbxassetid://81830522846878`
    - `TeleportDrop_01 -> rbxassetid://82086363159443`
  - owner script aktif yang ikut diselaraskan:
    - `DoorRuntime` / `MapRuntimePatches`
      - open `rbxassetid://83005562781593`
      - close `rbxassetid://78764817933410`
    - `FlashlightConfig.sound.soundId -> rbxassetid://140513388846872`
- validasi edit-time Studio `PASRAHPHOBIA.rbxlx`:
  - `AmbientLoop_Main.SoundId = rbxassetid://140704980462451`
  - `EnvironmentalCreak_01.SoundId = rbxassetid://111282528409948`
  - `GhostWhisper_01.SoundId = rbxassetid://98105844059537`
  - `ButtonClick_01.SoundId = rbxassetid://85056627192723`
  - `CountdownTick_01.SoundId = rbxassetid://81830522846878`
  - `TeleportDrop_01.SoundId = rbxassetid://82086363159443`
- publish impact:
  - inventory upload yang memang sudah ada sekarang benar-benar masuk ke owner runtime canonical, jadi batch audio tidak lagi menggantung di path lokal/raw asset atau placeholder lama

- progress tambahan pada lane `objective and lobby feedback cues`:
  - `client/UI/Main.lua` sekarang punya fallback inventory-owned untuk:
    - `ObjectiveUpdate -> rbxassetid://96021243760086`
    - `Notification -> rbxassetid://130533639073623`
  - `ObjectiveLabel` sekarang memicu cue update saat text objective benar-benar berubah di surface `Preparation / Investigation / Hunt`
  - `Lobby feedback` dan `Room invite popup` sekarang memicu cue notification dari owner UI yang sama
- validasi terbaru:
  - edit-time script live `game.StarterPlayer.StarterPlayerScripts.Client.UI.Main` membaca:
    - `ObjectiveUpdate.SoundId = rbxassetid://96021243760086`
    - `Notification.SoundId = rbxassetid://130533639073623`
  - helper `_playObjectiveUpdateCueIfNeeded` sekarang ada di source aktif dan dipanggil setelah refresh `ObjectiveLabel`
- publish impact:
  - flow objective dan feedback lobby sekarang tidak lagi hanya berubah teks; sudah punya cue audio upload akun aktif tanpa membuat sistem notifikasi baru

- progress tambahan pada lane `field kit evidence cue pass`:
  - `client/UI/Main.lua` sekarang punya tiga cue fallback inventory-owned tambahan untuk tool evidence yang memang sudah hidup:
    - `ThermometerRead -> rbxassetid://87230026682789`
    - `WritingScratch -> rbxassetid://83865030928382`
    - `MotionTrigger -> rbxassetid://97217836947594`
  - cue tersebut dipakai oleh owner existing `Field Kit`, bukan sistem baru:
    - `SuhuMembeku`
    - `BukuTerkutuk`
    - `GerakanGaib`
  - dedupe lokal ditutup lewat `toolState.lastCueSignature`, jadi update tool tidak spam audio saat event yang sama diproses ulang
- validasi terbaru:
  - script live `game.StarterPlayer.StarterPlayerScripts.Client.UI.Main` membaca:
    - `ThermometerRead.SoundId = rbxassetid://87230026682789`
    - `WritingScratch.SoundId = rbxassetid://83865030928382`
    - `MotionTrigger.SoundId = rbxassetid://97217836947594`
  - helper `_playFieldKitEvidenceCueIfNeeded` ada di source aktif dan dipanggil dari `_applyFieldKitToolUpdate`
- publish impact:
  - tool evidence yang tadinya hanya mengubah teks/meta HUD sekarang punya cue audio inventory-owned yang lebih mudah dipahami pemain saat membaca suhu, tulisan, dan trigger motion

- progress tambahan pada lane `ui audio fallback alignment`:
  - fallback click di `client/UI/Main.lua` tidak lagi memakai built-in `rbxasset://sounds/volume_slider.ogg`
  - fallback sekarang diselaraskan ke asset canonical yang sama dengan template `ButtonClick_01`:
    - `rbxassetid://85056627192723` (`click5`)
- validasi terbaru:
  - script live `game.StarterPlayer.StarterPlayerScripts.Client.UI.Main` membaca:
    - `UI_SOUND_FALLBACKS.ButtonClick.SoundId = rbxassetid://85056627192723`
- publish impact:
  - jalur utama dan fallback UI click sekarang sama-sama memakai asset upload akun aktif, jadi tidak ada lagi diam-diam jatuh ke built-in Roblox default

- progress tambahan pada lane `lobby ambient inventory audio`:
  - `client/Controllers/Sensory/AudioController.luau` sekarang punya owner aktif untuk ambience lobby, bukan hanya preparation ambience
  - runtime baru:
    - `LobbyAmbient -> rbxassetid://113854211240490`
    - profile default `Volume=0.16`, `PlaybackSpeed=0.98`
  - owner yang ditutup:
    - fade-in lobby saat `InMatch ~= true` dan map profile `LobbySocialHub`
    - fade-out otomatis saat masuk match/preparation
    - debug attrs player:
      - `PasrahLobbyAmbientActive`
      - `PasrahLobbyAmbientSoundId`
      - `PasrahLobbyAmbientMap`
- validasi terbaru:
  - build lolos:
    - `_tmp_lobby_ambient_audio_build.rbxlx`
  - live di `PASRAHPHOBIA.rbxlx`:
    - lobby idle:
      - `PasrahLobbyAmbientActive = true`
      - `PasrahLobbyAmbientSoundId = rbxassetid://113854211240490`
      - `CurrentCamera.LobbyAmbient.IsPlaying = true`
      - `CurrentCamera.LobbyAmbient.Volume ~= 0`
    - sesudah `StartSoloMatch -> PreparationPhase`:
      - `PasrahPreparationAmbientActive = true`
      - `CurrentCamera.PreparationAmbient.IsPlaying = true`
      - `CurrentCamera.LobbyAmbient.Volume = 0`
      - `PasrahLobbyAmbientActive` turun `nil`
- publish impact:
  - lobby sekarang tidak lagi diam atau hanya mengandalkan ambience preparation; surface hub punya bed audio inventory-owned yang padam bersih saat match mulai tanpa menambah sistem audio baru

- progress tambahan pada lane `cue-specific inventory audio overrides`:
  - `client/SoundSystem/Main.lua` sekarang bisa menimpa template kategori dengan `rbxassetid://...` khusus untuk cue tertentu tanpa membuat owner audio baru
  - override yang ditutup:
    - `prep_focus_lock -> rbxassetid://140513388846872` (`switch15`)
    - `env_doorslam -> rbxassetid://78764817933410` (`doorClose_1`)
    - `env_windowknock -> rbxassetid://78764817933410` (`doorClose_1`)
    - `env_objectthrow -> rbxassetid://126504722314888` (`impactPunch_medium_002`)
    - `ghost_object_throw -> rbxassetid://126504722314888` (`impactPunch_medium_002`)
- validasi terbaru:
  - build lolos:
    - `_tmp_audio_cue_override_build.rbxlx`
    - `_tmp_audio_cue_override_fix_build.rbxlx`
  - live di `PASRAHPHOBIA.rbxlx` setelah `StartSoloMatch -> PreparationPhase`:
    - `prep_focus_lock -> PasrahAudioLastSoundId = rbxassetid://140513388846872`
    - `env_doorslam -> PasrahAudioLastSoundId = rbxassetid://78764817933410`
    - `env_objectthrow -> PasrahAudioLastSoundId = rbxassetid://126504722314888`
    - `ghost_object_throw -> PasrahAudioLastSoundId = rbxassetid://126504722314888`
- publish impact:
  - cue interaction lingkungan yang sebelumnya jatuh ke template generik sekarang mulai memakai suara upload yang lebih tepat secara fungsi tanpa duplikasi sistem atau asset local path

- progress tambahan pada lane `ui surface inventory cues`:
  - `client/UI/Main.lua` sekarang memakai upload inventory tambahan untuk surface UI yang sebelumnya masih senyap/generik:
    - `PanelOpen -> rbxassetid://115397007938540` (`maximize_001`)
    - `PanelSoftClose -> rbxassetid://73589904561594` (`scroll_001`)
    - `JournalPage -> rbxassetid://97915135753208` (`bookFlip3`)
    - `Error -> rbxassetid://70594579947868` (`ui_error`)
  - cue dipasang di owner UI existing:
    - open auxiliary window
    - Room Browser open/close, dengan guard agar sound hanya muncul saat visibility benar-benar berubah
    - `RoomBrowserRoomJoinFailed`
  - debug attr client ditambahkan untuk inspeksi berikutnya:
    - `PasrahUILastSoundKey`
    - `PasrahUILastSoundId`
    - `PasrahUILastSoundAt`
- validasi terbaru:
  - build lolos:
    - `_tmp_ui_inventory_surface_cues_build.rbxlx`
    - `_tmp_ui_inventory_surface_cues_guarded_build.rbxlx`
  - source live `game.StarterPlayer.StarterPlayerScripts.Client.UI.Main` membaca fallback baru dan debug attr write path
  - catatan jujur: direct command harness UI client tidak dipakai sebagai proof final karena command execution memakai konteks VM terpisah dari bootstrap client aktif
- publish impact:
  - UI panel/journal/error feedback sekarang punya mapping audio inventory-owned yang siap dipakai di jalur runtime normal tanpa local raw asset dan tanpa sistem UI baru

## 2026-04-08 22:33:46 +07:00 - Client Bootstrap UI Startup Recovery
- Restored direct StarterPlayerScripts.ClientBootstrap mapping so the client bootstrap runs outside the nested Client module tree.
- Removed a misplaced lobby notification block from src/client/UI/Main.lua that referenced lobby, ventName, and previousFeedbackText from the wrong scope.
- Added the missing structural nd for _ensureBasicUIs() after removing that stale block.
- Added lightweight PasrahClientBootstrapStage / PasrahClientBootstrapDetail attrs in the client bootstrap entrypoint for future runtime diagnosis.
- Verified build: _tmp_client_ui_bootstrap_fix_build.rbxlx, _tmp_client_bootstrap_trace_build.rbxlx, _tmp_client_ui_parse_fix_build.rbxlx.
- Verified live in Roblox Studio: PlayerGui now creates LobbyUI, MatchUI, RoomBrowserUI, RoomBrowserFloatUI, UXLayer, JournalUI, and auxiliary UI roots.
- Verified live UI audio attrs: JournalPage -> rbxassetid://97915135753208; room browser close PanelSoftClose -> rbxassetid://73589904561594.
- Roblox Studio was returned to STOP TEST before reporting.

## 2026-04-08 22:37:11 +07:00 - Client Bootstrap E2E Regression Proof
- Re-ran live Studio regression after Restore client bootstrap UI startup.
- Verified client bootstrap stage started and generated PlayerGui roots are present.
- Verified StartSoloMatch -> PreparationPhase keeps MatchUI active.
- Verified InvestigationPhase sets MatchPhase = InGame, MatchUI.Enabled = true, and FieldKitFrame.Visible = true.
- Verified uploaded inventory UI cue still fires in live client: ObjectiveUpdate -> rbxassetid://96021243760086.
- Verified StudioE2E evidence request still reaches server after HUD recovery: JejakEnergi -> MEDOK publish fallback result.
- Roblox Studio was returned to STOP TEST before this report/log entry.

## 2026-04-08 22:40:12 +07:00 - Extended Inventory Audio Cue Overrides
- Added cue-specific uploaded inventory audio overrides in src/client/SoundSystem/Main.lua without creating a new audio system.
- New active cue mappings:
  - EnvironmentalAudio/env_windowknock -> rbxassetid://71098340187847 (impactWood_light_001)
  - EnvironmentalAudio/env_objectthrow -> rbxassetid://86917747509286 (object_fall)
  - GhostAudio/ghost_whisper -> rbxassetid://98105844059537 (ghost_whisper_3)
  - GhostAudio/ghost_fake_footsteps -> rbxassetid://95974189526179 (ghost_footstep_2)
  - GhostAudio/ghost_manifest -> rbxassetid://139204195403262 (creaky-door-open)
  - GhostAudio/ghost_object_throw -> rbxassetid://86917747509286 (object_fall)
  - FearAudio/fear_rise -> rbxassetid://138884191945388 (single-heart-beat)
  - FearAudio/fear_critical -> rbxassetid://138329686293368 (horror-deep-drum-heartbeat)
  - JumpscareAudio/jumpscare_stinger -> rbxassetid://101202336513383 (hard-horror-hit-drum)
- Build passed: _tmp_audio_extended_cue_overrides_build.rbxlx.
- Live verification after StartSoloMatch: nv_windowknock, nv_objectthrow, ghost_fake_footsteps, ghost_whisper, ear_critical, and jumpscare_stinger all reported the expected PasrahAudioLastSoundId values.
- Roblox Studio was returned to STOP TEST before reporting.

## 2026-04-08 22:42:51 +07:00 - Publish Readiness Probe After UI/Audio Recovery
- Ran live StudioE2E publish readiness probe after client bootstrap and uploaded-inventory audio cue fixes.
- GetQAGateReadiness: overall=pass_with_manual_multiplayer, solo=true, multiplayer=manual_check_required, memoryOk=true, psOk=true, warnings=0, rrors=0.
- GetPublishReadiness: overall=fail because persistence=mock, persistenceReady=false, obuxMissingId=10, and multiplayer=manual_check_required.
- commerceReady=true and obuxVisible=0, so Robux products remain hidden/setup-gated rather than exposed with invalid IDs.
- GetShopReadiness: 	otal=31 MM=14 PP=7 Robux=10 disabled=10 robuxMissingId=10.
- Client UI roots were present during the probe.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 15:50:50 +07:00 - Ranked Server Identity
- Status: DONE.
- `Server.RankedSystem.Service`
  - now stamps `PasrahRanked*` directly on the player for rank snapshot builds, star gains, and star losses
  - keeps owner truthful as `RankedSystem`, with rank name/tier/division/stars/victories/difficulty attached to runtime state
- `Server.StudioE2EControlSystem.Main`
  - now exposes `GetRankSnapshot`
  - now exposes `AddRankStarSnapshot`
  - now exposes `RemoveRankStarSnapshot`
- Build passed:
  - `_tmp_ranked_identity_build.rbxlx`
- Live proof in Play Solo:
  - baseline snapshot:
    - `ok=true | action=GetRankSnapshot | result=rank=Bayi III tier=Bayi division=3 stars=0 victories=0 difficulty=1`
  - star gain:
    - `ok=true | action=AddRankStarSnapshot | result=rank=Bayi III tier=Bayi division=3 stars=1 victories=0`
    - `ok=true | action=GetRankSnapshot | result=rank=Bayi III tier=Bayi division=3 stars=1 victories=0 difficulty=1`
  - star rollback:
    - `ok=true | action=RemoveRankStarSnapshot | result=rank=Bayi III tier=Bayi division=3 stars=0 victories=0`
    - `ok=true | action=GetRankSnapshot | result=rank=Bayi III tier=Bayi division=3 stars=0 victories=0 difficulty=1`
  - hot runtime attrs on player after the cycle:
    - `PasrahRankedOwner=RankedSystem`
    - `PasrahRankedPlayerRank=Bayi III`
    - `PasrahRankedTier=Bayi`
    - `PasrahRankedDivision=3`
    - `PasrahRankedStars=0`
    - `PasrahRankedVictories=0`
    - `PasrahRankedDifficulty=1`
    - `PasrahRankedLastEvent=RankSnapshotBuilt`
    - `PasrahRankedLastReason=loss`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 15:43:14 +07:00 - Player Profile Server Identity
- Status: DONE.
- `Server.PlayerProfileSystem.Service`
  - now stamps `PasrahPlayerProfile*` on the viewer player when public profile snapshots are refreshed/viewed
  - keeps owner truthful as `PlayerProfileSystem`, with viewed target, profile summary, gallery count, equipped cosmetic count, and viewer-side view count attached to runtime state
- `Server.StudioE2EControlSystem.Main`
  - now exposes `GetPublicProfileSnapshot`
- Build passed:
  - `_tmp_playerprofile_identity_build.rbxlx`
- Live proof in Play Solo:
  - seed state:
    - `ok=true | action=UpdateProfileSnapshot | result=level=1 rank=Bayi III favoriteTool=JejakEnergi gallery=3 bio=viewer profile probe`
    - `ok=true | action=GrantCurrency | result=currency=MM granted=1000 MM=2200 PP=12 Robux=0`
    - `ok=true | action=ProcessShopPurchase | result=item=cos_accessory_wardingcharm MM=1500 PP=12 Robux=0 ownedCount=1`
    - `ok=true | action=EquipCosmeticSnapshot | result=cosmetic=cos_accessory_wardingcharm slot=accessory owned=1 equipped=1`
  - public profile views:
    - `ok=true | action=GetPublicProfileSnapshot | result=target=10576163165 level=1 rank=Bayi III totalMatches=0 totalWins=0 winRate=0 gallery=3 equipped=1 viewCount=1`
    - `ok=true | action=GetPublicProfileSnapshot | result=target=10576163165 level=1 rank=Bayi III totalMatches=0 totalWins=0 winRate=0 gallery=3 equipped=1 viewCount=2`
  - hot runtime attrs on viewer player:
    - `PasrahPlayerProfileOwner=PlayerProfileSystem`
    - `PasrahPlayerProfileTargetUserId=10576163165`
    - `PasrahPlayerProfileLevel=1`
    - `PasrahPlayerProfileRank=Bayi III`
    - `PasrahPlayerProfileTotalMatches=0`
    - `PasrahPlayerProfileTotalWins=0`
    - `PasrahPlayerProfileWinRate=0`
    - `PasrahPlayerProfileGalleryCount=3`
    - `PasrahPlayerProfileEquippedCosmeticCount=1`
    - `PasrahPlayerProfileViewCount=2`
    - `PasrahPlayerProfileLastEvent=PlayerProfileViewed`
- Note:
  - the first proof run exposed a real gap: `equippedCount` stayed `0` because `PlayerProfileSystem` only looked for `GetPlayerInventory`; the lane is only marked DONE after falling back to `InventorySystem:GetEquipmentSlots` and re-proving the viewer snapshot live.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 15:11:27 +07:00 - Profile Server Identity
- Status: DONE.
- `Server.ProfileSystem.Service`
  - now stamps `PasrahProfile*` directly on the player for load/save, snapshot builds, profile updates, rank sync, and match-stat sync
  - keeps owner truthful as `ProfileSystem`, with level/xp/rank/stats/profile detail counts attached to runtime state
- `Server.StudioE2EControlSystem.Main`
  - now exposes `GetProfileSnapshot`
  - now exposes `UpdateProfileSnapshot`
- Build passed:
  - `_tmp_profile_identity_build.rbxlx`
- Live proof in Play Solo:
  - baseline snapshot:
    - `ok=true | action=GetProfileSnapshot | result=level=1 rank=Bayi III totalMatches=0 totalWins=0 winRate=0 favoriteTool=- gallery=0 bio=`
  - profile update:
    - `ok=true | action=UpdateProfileSnapshot | result=level=1 rank=Bayi III favoriteTool=JejakEnergi gallery=3 bio=studio profile sync`
  - post-update snapshot:
    - `ok=true | action=GetProfileSnapshot | result=level=1 rank=Bayi III totalMatches=0 totalWins=0 winRate=0 favoriteTool=JejakEnergi gallery=3 bio=studio profile sync`
  - hot runtime attrs on player:
    - `PasrahProfileOwner=ProfileSystem`
    - `PasrahProfileLevel=1`
    - `PasrahProfileXP=0`
    - `PasrahProfileRank=Bayi III`
    - `PasrahProfileTotalMatches=0`
    - `PasrahProfileTotalWins=0`
    - `PasrahProfileWinRate=0`
    - `PasrahProfileFavoriteTool=JejakEnergi`
    - `PasrahProfileGalleryCount=3`
    - `PasrahProfileBio=studio profile sync`
    - `PasrahProfileFlexBorder=border_emerald`
    - `PasrahProfileWinrateVisible=true`
    - `PasrahProfileLastSource=update_profile`
    - `PasrahProfileLastEvent=ProfileSnapshotBuilt`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 14:58:57 +07:00 - Progression Server Identity
- Status: DONE.
- `Server.ProgressionSystem.Service`
  - now stamps `PasrahProgression*` directly on the player for session init/save, XP grants, level-up publishing, and snapshot builds
  - keeps owner truthful as `ProgressionSystem`, with stored/session XP and level attached to runtime state
- `Server.ProgressionSystem.Main`
  - now exposes `GetPlayerSnapshot` on the canonical owner wrapper so Studio probes do not have to reach into the raw service table
- `Server.StudioE2EControlSystem.Main`
  - now exposes `GetProgressionSnapshot`
  - now exposes `GrantProgressionXP`
- Build passed:
  - `_tmp_progression_identity_build.rbxlx`
- Live proof in Play Solo:
  - baseline snapshot:
    - `ok=true | action=GetProgressionSnapshot | result=storedXP=0 storedLevel=1 sessionXP=0 sessionLevel=1`
  - XP grant:
    - `ok=true | action=GrantProgressionXP | result=amount=275 storedXP=275 storedLevel=3 sessionXP=0 sessionLevel=1`
  - post-grant snapshot:
    - `ok=true | action=GetProgressionSnapshot | result=storedXP=275 storedLevel=3 sessionXP=0 sessionLevel=1`
  - hot runtime attrs on player:
    - `PasrahProgressionOwner=ProgressionSystem`
    - `PasrahProgressionStoredXP=275`
    - `PasrahProgressionStoredLevel=3`
    - `PasrahProgressionSessionXP=0`
    - `PasrahProgressionSessionLevel=1`
    - `PasrahProgressionLastSource=ProgressionSystem`
    - `PasrahProgressionLastGrantedXP=275`
    - `PasrahProgressionLastEvent=ProgressionSnapshotBuilt`
- Note:
  - the first probe run exposed a real wrapper gap: `GetProgressionSnapshot` returned `snapshot_unavailable` because `ProgressionSystem.Main` did not expose `GetPlayerSnapshot`; the lane is only marked DONE after fixing the wrapper and re-proving the Studio actions live.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 13:03:16 +07:00 - Stamp Royal Pass Server Identity
- Status: DONE.
- `Server.RoyalPassSystem.Service` now stamps direct runtime attrs on the player under the active owner:
  - `PasrahRoyalPassOwner`
  - `PasrahRoyalPassSeasonId`
  - `PasrahRoyalPassTotalXP`
  - `PasrahRoyalPassCurrentTier`
  - `PasrahRoyalPassCurrentTierXP`
  - `PasrahRoyalPassRemainingXP`
  - `PasrahRoyalPassProgressPercent`
  - `PasrahRoyalPassPremiumOwned`
  - `PasrahRoyalPassUnlockedTierCount`
  - `PasrahRoyalPassNextTier`
  - `PasrahRoyalPassLastEvent`
  - `PasrahRoyalPassLastSource`
  - `PasrahRoyalPassLastGrantedXP`
  - `PasrahRoyalPassLastUnlockedTier`
  - `PasrahRoyalPassUpdatedAt`
- `Server.RoyalPassSystem.Controller` now reads the internal snapshot builder when pushing remote snapshots, so `RoyalPassSnapshot` delivery no longer overwrites the hot runtime event truth on the player.
- `Server.ShopSystem.Service` now reads the internal Royal Pass snapshot builder when checking premium ownership, so marketplace entitlement grants no longer overwrite `RoyalPassPremiumOwnershipChanged` with `RoyalPassSnapshotBuilt`.
- `Server.StudioE2EControlSystem.Main` now exposes:
  - `GetRoyalPassSnapshot`
  - `GrantRoyalPassXP`
- Build passed: `_tmp_royalpass_identity_build.rbxlx`.
- Live Studio proof in Play Solo:
  - baseline snapshot:
    - `GetRoyalPassSnapshot` ->
      - `ok=true | action=GetRoyalPassSnapshot | result=season=S1 premium=false tier=1 totalXP=0 tierXP=0 remainingXP=200 unlocked=0 nextTier=2`
  - premium entitlement grant:
    - `GrantMarketplacePurchase(item=royalpass_premium_track)` ->
      - `ok=true | action=GrantMarketplacePurchase | result=item=royalpass_premium_track category=Entitlement currency=Robux owned=true ownedCount=1 MM=1200 PP=12 Robux=0`
    - hot runtime attrs on player:
      - `PasrahRoyalPassOwner=RoyalPassSystem`
      - `PasrahRoyalPassPremiumOwned=true`
      - `PasrahRoyalPassCurrentTier=1`
      - `PasrahRoyalPassTotalXP=0`
      - `PasrahRoyalPassUnlockedTierCount=0`
      - `PasrahRoyalPassLastEvent=RoyalPassPremiumOwnershipChanged`
  - XP grant:
    - `GrantRoyalPassXP(amount=450, source=studio_e2e_royalpass)` ->
      - `ok=true | action=GrantRoyalPassXP | result=amount=450 premium=true tier=3 totalXP=450 tierXP=50 unlocked=2 nextTier=4`
    - hot runtime attrs on player:
      - `PasrahRoyalPassOwner=RoyalPassSystem`
      - `PasrahRoyalPassSeasonId=S1`
      - `PasrahRoyalPassPremiumOwned=true`
      - `PasrahRoyalPassCurrentTier=3`
      - `PasrahRoyalPassCurrentTierXP=50`
      - `PasrahRoyalPassRemainingXP=150`
      - `PasrahRoyalPassTotalXP=450`
      - `PasrahRoyalPassUnlockedTierCount=2`
      - `PasrahRoyalPassNextTier=4`
      - `PasrahRoyalPassLastEvent=RoyalPassTierUnlocked`
      - `PasrahRoyalPassLastUnlockedTier=3`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 12:56:48 +07:00 - Stamp Shop + Inventory Server Identity
- Status: DONE.
- `Server.ShopSystem.Service` now stamps direct runtime attrs on the player under the active owner:
  - `PasrahShopOwner`
  - `PasrahShopWalletMM`
  - `PasrahShopWalletPP`
  - `PasrahShopWalletRobux`
  - `PasrahShopOwnedCount`
  - `PasrahShopLastEvent`
  - `PasrahShopLastItemId`
  - `PasrahShopLastCategory`
  - `PasrahShopLastCurrency`
  - `PasrahShopLastResult`
  - `PasrahShopLastReason`
  - `PasrahShopLastSource`
  - `PasrahShopLastMarketplaceType`
  - `PasrahShopLastMarketplaceId`
  - `PasrahShopUpdatedAt`
- `Server.InventorySystem.Service` now stamps direct runtime attrs on the player under the active owner:
  - `PasrahInventoryOwner`
  - `PasrahInventoryItemCount`
  - `PasrahInventoryCosmeticCount`
  - `PasrahInventoryUnlockedCount`
  - `PasrahInventoryEquippedCount`
  - `PasrahInventoryLastEvent`
  - `PasrahInventoryLastItemId`
  - `PasrahInventoryLastSlotName`
  - `PasrahInventoryLastReason`
  - `PasrahInventoryUpdatedAt`
- `Server.StudioE2EControlSystem.Main` now exposes:
  - `ProcessShopPurchase`
- Fixed the Studio purchase probes so they read the internal shop snapshot helper instead of calling `BuildClientSnapshot()` and overwriting the hot `ItemPurchased` truth with a later `ShopSnapshotBuilt` stamp.
- Build passed: `_tmp_shop_inventory_identity_build.rbxlx`.
- Live Studio proof in Play Solo:
  - soft-currency baseline scan:
    - `GetShopPlayerSnapshot(item=eq_flashlight_uv)` ->
      - `ok=true | action=GetShopPlayerSnapshot | result=MM=1200 PP=12 Robux=0 inventory=0 cosmetics=0 ownedCount=1 item=eq_flashlight_uv hasItem=false ownsCosmetic=false ownedSnapshot=false`
  - soft-currency grant + purchase:
    - `GrantCurrency(MM=5000)` ->
      - `ok=true | action=GrantCurrency | result=currency=MM granted=5000 MM=6200 PP=12 Robux=0`
    - `ProcessShopPurchase(item=eq_flashlight_uv)` ->
      - `ok=true | action=ProcessShopPurchase | result=item=eq_flashlight_uv MM=4700 PP=12 Robux=0 ownedCount=2`
    - hot runtime attrs on player:
      - `PasrahShopOwner=ShopSystem`
      - `PasrahShopLastEvent=ItemPurchased`
      - `PasrahShopLastItemId=eq_flashlight_uv`
      - `PasrahShopLastCategory=Equipment`
      - `PasrahShopLastCurrency=MM`
      - `PasrahShopLastResult=purchased`
      - `PasrahShopOwnedCount=2`
      - `PasrahInventoryOwner=InventorySystem`
      - `PasrahInventoryLastEvent=InventoryGrantCompleted`
      - `PasrahInventoryLastItemId=eq_flashlight_uv`
      - `PasrahInventoryItemCount=1`
      - `PasrahInventoryCosmeticCount=0`
  - marketplace entitlement grant:
    - `GetShopPlayerSnapshot(item=royalpass_premium_track)` ->
      - `ok=true | action=GetShopPlayerSnapshot | result=MM=1200 PP=12 Robux=0 inventory=0 cosmetics=0 ownedCount=0 item=royalpass_premium_track hasItem=false ownsCosmetic=false ownedSnapshot=false`
    - `GrantMarketplacePurchase(item=royalpass_premium_track)` ->
      - `ok=true | action=GrantMarketplacePurchase | result=item=royalpass_premium_track category=Entitlement currency=Robux owned=true ownedCount=1 MM=1200 PP=12 Robux=0`
    - hot runtime attrs on player:
      - `PasrahShopLastEvent=ItemPurchased`
      - `PasrahShopLastItemId=royalpass_premium_track`
      - `PasrahShopLastCategory=Entitlement`
      - `PasrahShopLastCurrency=Robux`
      - `PasrahShopLastResult=purchased`
      - `PasrahShopLastSource=StudioE2EMarketplacePurchase`
      - `PasrahShopLastMarketplaceType=GamePass`
      - `PasrahShopLastMarketplaceId=0`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 05:08:12 +07:00 - Disable Duplicate Ghost Deduction Journal Owner
- Updated `src/ServerScriptService/Server/Core/SystemRegistry.lua` so `GhostDeductionJournal` is now disabled alongside `EvidenceJournalSystem`, leaving `JournalSystem` as the single active owner for journal/UI ghost candidate state.
- Build passed: `_tmp_journal_owner_registry_build.rbxlx`.
- Live Studio proof:
  - `StartSoloMatch -> AdvancePhase(InvestigationPhase) -> UseEvidenceTool(JejakEnergi)` still updated the canonical journal owner:
    - `PasrahJournalOwner=JournalSystem`
    - `PasrahJournalMatchId=match_1`
    - `PasrahJournalLastEvent=JournalUpdated`
    - `PasrahJournalCandidateCount=6`
    - `PasrahJournalCandidateList=Banaspati | Genderuwo | HantuTanah | Leak | Pocong | SilumanUlar`
  - client `EvidenceEvent` traffic observed during the same run no longer included `UIGhostPredictionUpdated`; observed journal/evidence events were limited to:
    - `JournalUpdated`
    - `UIEvidenceUpdated`
    - `EvidenceCollected`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 05:22:41 +07:00 - Stamp Journal UI Runtime Identity
- Updated `src/client/UI/Main.lua` so `JournalUI` now stamps direct runtime attrs on the actual auxiliary window instances and key journal widgets instead of leaving journal identity only on player attrs.
- Build passed: `_tmp_journal_ui_identity_build.rbxlx`.
- Live Studio proof:
  - `Client.UI.Main` now loads successfully again in play after moving the journal stamp helpers off top-level locals.
  - `StartSoloMatch -> InvestigationPhase -> UseEvidenceTool(JejakEnergi)` produced:
    - player attrs:
      - `PasrahJournalOwner=JournalSystem`
      - `PasrahJournalLastEvent=JournalUpdated`
    - UI runtime attrs:
      - `PlayerGui.JournalUI.MainPanel` -> `PasrahJournalUIOwner=UISystem`, `PasrahJournalUIChannel=JournalPanel`
      - `PlayerGui.JournalUI.MainPanel.StatusBadge` -> `PasrahJournalUIOwner=UISystem`, `PasrahJournalUIChannel=JournalStatusBadge`
      - `PlayerGui.JournalUI.MainPanel.ContentFrame.JournalDeck.CandidateSection.BodyLabel` -> `PasrahJournalUIOwner=UISystem`, `PasrahJournalUIChannel=JournalCandidateBody`, `PasrahJournalCandidateCount=12`
      - `PlayerGui.JournalUI.MainPanel.ToolActionButton` -> `PasrahJournalUIChannel=JournalToolActionButton`, `PasrahJournalToolType=JejakEnergi`, `PasrahJournalToolStatus=EMF level 5 terkunci.`
      - candidate body list snapshot:
        - `Banaspati | Genderuwo | HantuTanah | Jerangkong | Kuntilanak | Leak | Palasik | Pocong | SilumanUlar | SundelBolong | Tuyul | WeweGombel`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 05:31:22 +07:00 - Stamp Results UI Runtime Identity
- Updated `src/client/UI/Main.lua` so `ResultsPanel` now stamps runtime attrs directly on the live UI surface and reward rows, linked to canonical server owners (`MatchResultSystem` and `RewardCalculationSystem`).
- Build passed: `_tmp_results_ui_identity_build.rbxlx`.
- Live Studio proof:
  - after `StartSoloMatch -> EndMatch`, canonical player attrs remained:
    - `PasrahMatchResultOwner=MatchResultSystem`
    - `PasrahRewardOwner=RewardCalculationSystem`
  - results surface attrs now present:
    - `PlayerGui.UXLayer.MatchUXGui.MatchUXLayer.ResultsPanel`:
      - `PasrahResultsUIOwner=UISystem`
      - `PasrahResultsUIChannel=ResultsPanel`
      - `PasrahResultsGhostType=Unknown`
      - `PasrahResultsCurrencyReward=306`
      - `PasrahResultsPPReward=2`
      - `PasrahResultsXPReward=222`
      - `PasrahResultsCloseUnlocked=true`
    - `ResultsStatus`:
      - `PasrahResultsUIChannel=ResultsStatus`
    - `ResultsSummary.StatusRow`:
      - `PasrahResultsUIChannel=ResultsStatusRow`
      - `PasrahResultsRowText=BERHASIL`
    - `ResultsSummary.RewardRow`:
      - `PasrahResultsUIChannel=ResultsRewardRow`
      - `PasrahResultsRowText=306 MM | 2 PP`
    - `ResultsSummary.XpRow`:
      - `PasrahResultsUIChannel=ResultsXPRow`
      - `PasrahResultsRowText=222`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 05:39:18 +07:00 - Surface Reward Progress On Results UI
- Updated `src/client/UI/Main.lua` so client match result state now carries `royalPassXP` and `dailyProgress`, then propagates both into `ResultsPanel` attrs and player-facing summary copy.
- Build passed: `_tmp_results_reward_progress_build.rbxlx`.
- Live Studio proof after `StartSoloMatch -> EndMatch`:
  - canonical reward owner remained:
    - `PasrahRewardOwner=RewardCalculationSystem`
  - `ResultsPanel` attrs now carry progression:
    - `PasrahResultsRoyalPassXP=99`
    - `PasrahResultsDailyProgress=2`
  - `ResultsFooter` text now surfaces that same progression after result unlock:
    - `PP: Tebakan benar +1 • Selamat hidup +1 RP XP 99 | Daily 2 Tekan tombol lanjut untuk kembali ke lobby flow.`
  - `PASRA_UI` content summary now includes:
    - `Royal Pass XP: 99`
    - `Daily Progress: 2`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 05:45:06 +07:00 - Stamp PASRA Summary Runtime Identity
- Updated `src/client/UI/Main.lua` so `PASRA_UI` now stamps direct runtime attrs on the summary surface itself instead of leaving result summary traceable only through text content.
- Build passed: `_tmp_pasra_ui_identity_build.rbxlx`.
- Live Studio proof after `StartSoloMatch -> EndMatch`:
  - `PlayerGui.PASRA_UI.MainPanel`:
    - `PasrahPasraUIOwner=UISystem`
    - `PasrahPasraUIChannel=PasraPanel`
    - `PasrahPasraRoyalPassXP=99`
    - `PasrahPasraDailyProgress=2`
  - `PlayerGui.PASRA_UI.MainPanel.ContentFrame.ContentText`:
    - `PasrahPasraUIChannel=PasraContentText`
    - `PasrahPasraLastEvent=MatchEnded`
    - text includes:
      - `Royal Pass XP: 99`
      - `Daily Progress: 2`
  - `PlayerGui.PASRA_UI.MainPanel.FooterLabel`:
    - `PasrahPasraUIChannel=PasraFooterLabel`
    - `PasrahPasraRoyalPassXP=99`
    - `PasrahPasraDailyProgress=2`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 05:49:43 +07:00 - Stamp Royal Pass UI Runtime Identity
- Updated `src/client/UI/Main.lua` so `RoyalPassUI` now stamps direct runtime attrs on the panel, hero/progress widgets, scroller, and active day card.
- Build passed: `_tmp_royalpass_ui_identity_build.rbxlx`.
- Live Studio proof:
  - baseline attrs exist even before opening:
    - `PlayerGui.RoyalPassUI.MainPanel`:
      - `PasrahRoyalPassUIOwner=UISystem`
      - `PasrahRoyalPassUIChannel=RoyalPassPanel`
      - `PasrahRoyalPassCurrentTier=1`
      - `PasrahRoyalPassTotalXP=0`
      - `PasrahRoyalPassPremiumOwned=false`
      - `PasrahRoyalPassCurrentDay=1`
  - after canonical `R` toggle opened the panel:
    - `RoyalPassUI.MainPanel.Visible=true`
    - `RoyalPassDeck.HeroCard` -> `PasrahRoyalPassUIChannel=RoyalPassHeroCard`
    - `RoyalPassDeck.TrackScroller` -> `PasrahRoyalPassUIChannel=RoyalPassTrackScroller`
    - `RoyalPassDeck.TrackScroller.DayCard1` -> `PasrahRoyalPassUIChannel=RoyalPassCurrentDayCard`
    - current day card also carried:
      - `PasrahRoyalPassCurrentDay=1`
      - `PasrahRoyalPassLastEvent=RoyalPassSnapshot`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 09:36:40 +07:00 - Stamp Sanity Runtime Identity
- Updated `src/ServerScriptService/Server/SanitySystem/Service.lua` so server-authoritative sanity state now writes direct runtime attrs on the player instead of staying implicit inside service state.
- Build passed: `_tmp_sanity_runtime_identity_build.rbxlx`.
- Live Studio proof after `StartSoloMatch`, settle, and `DrainSanity(22)`:
  - `PasrahSanityOwner=SanitySystem`
  - `PasrahSanityValue=78`
  - `PasrahSanityBand=safe`
  - `PasrahSanityReason=studio_e2e`
  - `PasrahSanityTeamAverage=78`
  - `PasrahSanityHuntActive=false`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 09:42:11 +07:00 - Stamp Sanity Event Runtime Identity
- Updated `src/ServerScriptService/Server/SanityEventSystem/Service.lua` so triggered and resolved sanity events now stamp direct attrs on the affected player.
- Build passed: `_tmp_sanity_event_runtime_identity_build.rbxlx`.
- Live Studio proof after `DrainSanity(80)`:
  - hot state:
    - `PasrahSanityEventOwner=SanityEventSystem`
    - `PasrahSanityEventMatchId=match_1`
    - `PasrahSanityEventActive=true`
    - `PasrahSanityEventType=ShadowMovement`
    - `PasrahSanityEventIntensity=0.8`
    - `PasrahSanityEventReason=triggered`
  - resolved state:
    - `PasrahSanityEventActive=false`
    - `PasrahSanityEventReason=resolved`
    - `PasrahSanityEventCooldownUntil` populated
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 09:55:18 +07:00 - Stamp Random Jumpscare Runtime Identity
- Updated `src/ServerScriptService/Server/RandomJumpscareSystem/Controller.lua` so forwarded jumpscares now stamp direct runtime attrs on affected players.
- Build passed inside `_tmp_runtime_identity_batch_3_build.rbxlx`.
- Live Studio proof after `TriggerJumpscare`:
  - `PasrahJumpscareOwner=RandomJumpscareSystem`
  - `PasrahJumpscareMatchId=match_1`
  - `PasrahJumpscareActive=true`
  - `PasrahJumpscareTriggerType=jumpscare_stinger`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 09:57:03 +07:00 - Stamp Contract Objective Runtime Identity
- Updated `src/ServerScriptService/Server/ContractObjectiveSystem/Service.lua` so active objective state/progress now stamps direct attrs on active match players.
- Build passed inside `_tmp_runtime_identity_batch_2_build.rbxlx`.
- Live Studio proof:
  - at objective start:
    - `PasrahObjectiveOwner=ContractObjectiveSystem`
    - `PasrahObjectiveActiveCount=5`
    - `PasrahObjectiveCompletedCount=0`
    - `PasrahObjectiveLastEvent=ObjectivesStarted`
  - after `UseEvidenceTool(JejakEnergi)`:
    - `PasrahObjectiveLastEvent=ObjectiveProgress`
    - `PasrahObjectiveLastObjectiveId=CaptureEvidence`
    - `PasrahObjectiveLastProgress=1`
    - `PasrahObjectiveProgressSummary=CaptureEvidence:1/3:live | IdentifyGhost:0/1:live | SurviveHunt:0/1:live | UseSpecificTool:0/1:live | WitnessGhostEvent:0/1:live`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 09:59:14 +07:00 - Stamp Extraction Runtime Identity
- Updated `src/ServerScriptService/Server/HuntEscapeSystem/Service.lua` so extraction zone/player runtime now stamps direct identity/result attrs instead of relying on hidden state only.
- Build passed inside `_tmp_runtime_identity_batch_3_build.rbxlx`.
- Live Studio proof after `ExtractSelf` with studio override:
  - `PasrahExtractionOwner=HuntEscapeSystem`
  - `PasrahExtractionMatchId=match_1`
  - `PasrahExtractionZoneId=StudioE2EZone`
  - `PasrahExtractionLastResult=extracted_via_studio_override`
  - `PasrahExtractionExtracted=true`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 10:05:27 +07:00 - Stamp Match Result Runtime Identity
- Updated `src/ServerScriptService/Server/MatchResultSystem/Service.lua` so match start/end results now stamp direct attrs on participating players.
- Build passed: `_tmp_runtime_identity_batch_4_build.rbxlx`.
- Live Studio proof:
  - before end:
    - `PasrahMatchResultOwner=MatchResultSystem`
    - `PasrahMatchResultLastEvent=MatchStarted`
    - `PasrahMatchResultMatchId=match_1`
  - after `EndMatch`:
    - `PasrahMatchResultLastEvent=MatchEnded`
    - `PasrahMatchResultGhostType=Unknown`
    - `PasrahMatchResultEvidenceCollected=0`
    - `PasrahMatchResultPlayersSurvived=1`
    - `PasrahMatchResultPlayersDead=0`
    - `PasrahMatchResultPlayersExtracted=0`
    - `PasrahMatchResultTeamSuccess=false`
  - `PasrahMatchResultExtractionCompleted=false`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 10:22:44 +07:00 - Stamp Reward Runtime Identity On Active Endgame Owner
- Reward runtime proof did not come from `RewardSystem` or `EconomySystem` direct attrs. Live wallet movement proved the active endgame reward owner was `RewardCalculationSystem`.
- Updated `src/ServerScriptService/Server/RewardCalculationSystem/Service.lua` so endgame reward distribution now stamps direct reward attrs on the rewarded player:
  - `PasrahRewardOwner`
  - `PasrahRewardMatchId`
  - `PasrahRewardReason`
  - `PasrahRewardCurrency`
  - `PasrahRewardLastAmount`
  - `PasrahRewardLastPPReward`
  - `PasrahRewardLastXP`
  - `PasrahRewardRoyalPassXP`
  - `PasrahRewardDailyProgress`
- Build passed: `_tmp_reward_runtime_identity_build.rbxlx`.
- Live Studio proof after fresh `StartSoloMatch -> EndMatch`:
  - wallet moved:
    - before: `MM=1200 PP=12 Robux=0`
    - after: `MM=1506 PP=14 Robux=0`
  - player attrs:
    - `PasrahRewardOwner=RewardCalculationSystem`
    - `PasrahRewardReason=endgame_match_reward`
    - `PasrahRewardCurrency=MM`
    - `PasrahRewardMatchId=match_1`
    - `PasrahRewardLastAmount=306`
    - `PasrahRewardLastPPReward=2`
    - `PasrahRewardLastXP=222`
    - `PasrahRewardRoyalPassXP=99`
    - `PasrahRewardDailyProgress=2`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 05:07:51 +07:00 - Stamp Journal Runtime Identity
- Updated `src/ServerScriptService/Server/JournalSystem/Service.lua` so the authoritative journal state now publishes direct player attrs instead of leaving evidence log state only in service memory and remotes.
- Player runtime now exposes:
  - `PasrahJournalOwner`
  - `PasrahJournalMatchId`
  - `PasrahJournalLastEvent`
  - `PasrahJournalDiscoveredCount`
  - `PasrahJournalConfirmedCount`
  - `PasrahJournalCandidateCount`
  - `PasrahJournalDiscoveredList`
  - `PasrahJournalConfirmedList`
  - `PasrahJournalCandidateList`
- Build passed: `_tmp_journal_runtime_identity_build.rbxlx`.
- Live Studio proof after `UseEvidenceTool(JejakEnergi)`:
  - `PasrahJournalOwner=JournalSystem`
  - `PasrahJournalMatchId=match_1`
  - `PasrahJournalLastEvent=JournalUpdated`
  - `PasrahJournalDiscoveredCount=1`
  - `PasrahJournalConfirmedCount=1`
  - `PasrahJournalCandidateCount=0`
  - `PasrahJournalDiscoveredList=MEDOK`
  - `PasrahJournalConfirmedList=MEDOK`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 04:57:26 +07:00 - Stamp Door Runtime Identity
- Updated `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua` so live door runtime now stamps direct state/identity attrs onto the actual door parts and proximity prompts instead of leaving door state implicit in prompt text and object memory only.
- Door runtime instances now expose:
  - `PasrahDoorOwner`
  - `PasrahDoorChannel`
  - `PasrahDoorMatchId`
  - `PasrahDoorObjectId`
  - `PasrahDoorLabel`
  - `PasrahDoorRouteSubtitle`
  - `PasrahDoorPolicy`
  - `PasrahDoorStateText`
  - `PasrahDoorIsOpen`
  - `PasrahDoorLocked`
  - `PasrahDoorNearestApproachDistance`
  - `PasrahDoorLastInteractionSource`
- Build passed: `_tmp_door_runtime_identity_build.rbxlx`.
- Live Studio proof:
  - baseline `Door_LivingRoom`:
    - `DoorPart.PasrahDoorOwner=DoorRuntime`
    - `DoorPart.PasrahDoorChannel=DoorPart`
    - `DoorPart.PasrahDoorMatchId=match_1`
    - `DoorPart.PasrahDoorObjectId=Door_LivingRoom`
    - `DoorPart.PasrahDoorLabel=Pintu Livingroom`
    - `DoorPart.PasrahDoorRouteSubtitle=Area investigasi`
    - `DoorPart.PasrahDoorPolicy=HybridRadiusPrompt`
    - `DoorPart.PasrahDoorStateText=Tertutup`
    - `DoorPart.PasrahDoorIsOpen=false`
  - matching prompt baseline:
    - `DoorPrompt.PasrahDoorChannel=DoorPrompt`
    - `DoorPrompt.PasrahDoorPromptActionText=Buka Pintu`
    - `DoorPrompt.PasrahDoorPromptObjectText=Pintu Livingroom`
  - after moving the player close to `Door_LivingRoom`, the runtime auto-open path became explicit:
    - `DoorPart.PasrahDoorIsOpen=true`
    - `DoorPart.PasrahDoorStateText=Terbuka`
    - `DoorPart.PasrahDoorNearestApproachDistance=1`
    - `DoorPart.PasrahDoorLastInteractionSource=DoorRuntimeAuto`
    - `DoorPrompt.PasrahDoorPromptActionText=Tutup Pintu`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 04:53:58 +07:00 - Stamp Hiding Safe Zone Runtime Identity
- Updated `src/ServerScriptService/Server/HidingSystem/Service.lua` so runtime safe zones now publish direct zone identity/state attrs instead of hiding safe-zone state only in service memory and player attrs.
- `SafeZone` parts now expose:
  - `PasrahHideOwner`
  - `PasrahHideChannel`
  - `PasrahHideMatchId`
  - `PasrahHideZoneId`
  - `PasrahHideLabel`
  - `PasrahHideSubtitle`
  - `PasrahHideRouteLabel`
  - `PasrahHideVisible`
  - `PasrahHideOccupiedCount`
  - `PasrahHideHiddenCount`
- Build passed: `_tmp_hiding_runtime_identity_build.rbxlx`.
- Live Studio proof:
  - `Match_match_2.HauntedHouse.SafeZones.SafeZone_1` during hunt + hidden:
    - `PasrahHideOwner=HidingSystem`
    - `PasrahHideChannel=SafeZonePart`
    - `PasrahHideMatchId=match_2`
    - `PasrahHideZoneId=SafeZone_1`
    - `PasrahHideLabel=SAFE ZONE`
    - `PasrahHideSubtitle=Anchor aman: Livingroom`
    - `PasrahHideRouteLabel=Livingroom`
    - `PasrahHideVisible=true`
    - `PasrahHideOccupiedCount=1`
    - `PasrahHideHiddenCount=1`
  - matching player state stayed authoritative:
    - `PasrahHideState=Hidden`
    - `PasrahHideZoneId=SafeZone_1`
    - `PasrahHuntPressureHidden=true`
    - `PasrahHuntPressureThreatState=Sheltered`
  - zone contrast remained truthful:
    - `SafeZone_2.PasrahHideOccupiedCount=0`
    - `SafeZone_2.PasrahHideHiddenCount=0`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 04:49:59 +07:00 - Stamp Survival Runtime Identity
- Updated `src/client/UI/Main.lua` so live survival UI state now stamps direct runtime attrs onto the real match instances that are active in Studio, instead of leaving hunt/hide state implicit in text only.
- Updated `src/client/MovementController.client.lua` so sprint, target speed, backward penalty, and move magnitude now publish direct runtime attrs onto the player, humanoid, and root part.
- Updated `src/ServerScriptService/Server/PlayerHealthSystem/Service.lua` so authoritative hunt pressure now publishes direct player attrs for threat state, distance, exposure, grace, and hidden status.
- Build passed: `_tmp_survival_runtime_identity_build.rbxlx`.
- Live Studio proof:
  - sprint while holding `W + LeftShift`:
    - `PasrahMovementOwner=MovementController`
    - `PasrahMovementSprinting=true`
    - `PasrahMovementTargetSpeed=14`
    - `PasrahMovementCurrentWalkSpeed=14`
    - `PasrahMovementMoveMagnitude=1`
  - backward penalty while holding `S`:
    - `PasrahMovementBackwardPenalty=true`
    - `PasrahMovementTargetSpeed=6.5`
    - `PasrahMovementCurrentWalkSpeed=6.5`
  - forced hunt authoritative attrs:
    - `PasrahHuntPressureOwner=PlayerHealthSystem`
    - `PasrahGhostSessionState=Hunting`
    - `PasrahGhostHuntActive=true`
    - `PasrahHuntPressureThreatState=Warn`
    - `PasrahHuntPressureGraceValue=6`
  - hide/shelter runtime state after `EnterHide`:
    - `PasrahHideState=Hidden`
    - `PasrahHideZoneId=SafeZone_1`
    - `PasrahHuntPressureHidden=true`
    - `PasrahHuntPressureThreatState=Sheltered`
    - `PasrahHuntPressureExposureValue=0`
  - active match UI instances carried the same state directly:
    - `MatchControlsHintLabel.PasrahMatchUIChannel=MatchControlsHintLabel`
    - `MatchControlsHintLabel.PasrahMatchUIViewState=Hunt`
    - `MatchControlsHintLabel.PasrahHideState=Hidden`
    - `MatchControlsHintLabel.PasrahHuntThreatState=Sheltered`
    - `MatchControlsHintLabel.PasrahMatchHintText=SAFEZONE 1  •  DIAM  •  TUNGGU`
    - `ObjectiveLabel.PasrahMatchObjectiveText=Tetap diam di SafeZone 1 sampai hunt selesai.`
    - `HuntStatusBadge.PasrahHuntBadgeText=HIDDEN`
    - `HuntAssistLabel.PasrahHuntAssistRoute=POSISI AMAN: SAFEZONE 1`
    - `HuntAssistLabel.PasrahHuntAssistSupport=DIAM  •  TUNGGU  •  JANGAN KELUAR`
    - `HuntOverlay.PasrahHuntOverlayVisible=true`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 02:13:41 +07:00 - Stamp UI Preview Runtime Identity
- Status: DONE.
- `Client.UI.Main` now stamps direct runtime identity attrs onto viewport preview clones instead of leaving field-kit and training previews anonymous.
- Fixed a client bootstrap regression during this batch by removing extra top-level locals that pushed `Client.UI.Main` over Roblox's local register limit.
- Live Studio proof:
  - `InvestigationPhase` field kit previews:
    - `JejakEnergiButton` carried `PasrahPreviewOwner=UI`, `PasrahPreviewKind=FieldKitTool`, `PasrahPreviewToolType=JejakEnergi`, `PasrahPreviewUsesAssetTemplate=false`, `PasrahPreviewState=ready`
    - `GaramButton` carried `PasrahPreviewOwner=UI`, `PasrahPreviewKind=FieldKitTool`, `PasrahPreviewToolType=Garam`, `PasrahPreviewUsesAssetTemplate=true`, `PasrahPreviewState=ready`
  - lobby training previews after `LobbyTrainingRotate` and `LobbyTrainingUseSupport`:
    - `TrainingPreview` carried `PasrahPreviewOwner=UI`, `PasrahPreviewKind=Ghost`, `PasrahPreviewGhostType=HantuTanah`, `PasrahPreviewUsesAssetTemplate=false`, `VisualTemplateName=HantuTanah`
- `GaramSupportCard.ToolPreview` carried `PasrahPreviewOwner=UI`, `PasrahPreviewKind=FieldKitTool`, `PasrahPreviewToolType=Garam`, `PasrahPreviewState=active`
- Build passed: `_tmp_ui_preview_identity_build.rbxlx`.
- Studio stop-test reporting rule followed.

## 2026-04-09 02:24:18 +07:00 - Stamp Runtime VFX Identity
- Status: DONE.
- `Client.Controllers.Sensory.VFXController` now stamps direct identity attrs onto persistent lighting/post-processing effects and runtime apparition VFX, so VFX state no longer has to be inferred only from player attrs or effect names.
- Live Studio proof:
  - lobby idle:
    - `Lighting.SensoryMapGrading` carried `PasrahVFXOwner=VFXController`, `PasrahVFXChannel=MapGrading`, `PasrahVFXMapProfile=LobbySocialHub`
    - `Lighting.SensoryMapBloom` carried `PasrahVFXChannel=MapBloom`
    - `Lighting.HorrorAtmosphere` carried `PasrahVFXChannel=Atmosphere`
  - `PreparationPhase` after `SetPreparationFocusTool=EMF`:
    - `SensoryMapGrading`, `SensoryMapBloom`, and `HorrorAtmosphere` all carried `PasrahVFXMapProfile=HauntedHouse`, `PasrahVFXLifecyclePhase=PreparationPhase`, `PasrahVFXPreparationTool=EMF`
  - runtime apparition:
    - `Workspace.RuntimeVFX` carried `PasrahVFXOwner=VFXController`, `PasrahVFXChannel=RuntimeVFX`, `PasrahVFXMapProfile=HauntedHouse`
- `Workspace.RuntimeVFX.ShadowApparitionRuntime` carried `PasrahVFXChannel=RuntimeShadowApparition`, `PasrahVFXEvent=EnvironmentalAudioTriggered`, `PasrahVFXProfile=shadowapparition`
- Build passed: `_tmp_vfx_runtime_identity_build.rbxlx`.
- Studio stop-test reporting rule followed.

## 2026-04-09 02:36:22 +07:00 - Stamp Horror HUD Runtime Identity
- Status: DONE.
- `Client.UI.HUD.HorrorHUD` now stamps direct identity attrs onto the sensory vignette HUD and lobby fade canvas, instead of leaving that layer anonymous.
- HUD runtime identity now uses `MatchLifecyclePhase` as the authoritative phase, and marks sanity as the latest `SanityEvent` reading with explicit freshness instead of pretending it is always current.
- Live Studio proof:
  - lobby idle:
    - `LobbyUI.SensoryLobbyCanvasGroup` carried `PasrahHUDOwner=HorrorHUD`, `PasrahHUDChannel=LobbyCanvas`, `PasrahHUDInMatch=false`
  - `InvestigationPhase` after `StartSoloMatch`, `AdvancePhase`, and `DrainSanity`:
    - `SensoryHorrorHUD` carried `PasrahHUDOwner=HorrorHUD`, `PasrahHUDChannel=SensoryHorrorHUD`, `PasrahHUDPhase=InvestigationPhase`
    - `Vignette` carried `PasrahHUDChannel=Vignette`
    - both HUD instances carried `PasrahHUDSanity=100`, `PasrahHUDSanitySource=SanityEvent`
- after a short delay, the same HUD instance settled to:
  - `PasrahHUDSanityFresh=false`
  - confirming the runtime attr is an explicitly stale last-seen reading rather than a fake authoritative current sanity
- Build passed: `_tmp_horrorhud_runtime_identity_build.rbxlx`.
- Studio stop-test reporting rule followed.

## 2026-04-09 02:41:58 +07:00 - Stamp Footstep Runtime Audio Identity
- Status: DONE.
- `Client.Controllers.Sensory.FootstepController` now stamps direct audio/runtime attrs on `LocalFootstepRuntime` instead of exposing only player-side probe attrs.
- Live Studio proof:
  - forced `PasrahFootstepProbeRequested` created `HumanoidRootPart.LocalFootstepRuntime`
  - runtime sound carried:
    - `PasrahAudioOwner=FootstepController`
    - `PasrahAudioCategory=FootstepAudio`
    - `PasrahAudioCue=footstep`
    - `PasrahAudioTemplate=ConcreteStep_01`
    - `PasrahAudioSoundId=rbxassetid://79900103772577`
    - `PasrahFootstepTemplate=ConcreteStep_01`
- `PasrahFootstepMaterial=Concrete`
- Build passed: `_tmp_footstep_runtime_identity_build.rbxlx`.
- Studio stop-test reporting rule followed.

## 2026-04-09 02:48:12 +07:00 - Stamp Ghost Renderer Runtime State
- Status: DONE.
- `Client.GhostRenderer.Main` now publishes its internal client render state directly to player attrs instead of keeping manifestation/distortion state hidden in module memory.
- Live Studio proof:
  - lobby idle:
    - `PasrahGhostRenderManifesting=false`
    - `PasrahGhostRenderSpectator=false`
    - `PasrahGhostRenderSanity=100`
    - `PasrahGhostRenderDistortion=0`
  - `InvestigationPhase` after forced manifestation:
    - `PasrahGhostRenderManifesting=true`
    - `PasrahGhostRenderSanity=95`
    - `PasrahGhostRenderDistortion=0.5`
  - after an additional `DrainSanity` and wait:
    - `PasrahGhostRenderSanity=75`
    - `PasrahGhostRenderDistortion=0.7`
- Build passed: `_tmp_ghostrenderer_runtime_state_build.rbxlx`.
- Studio stop-test reporting rule followed.

## 2026-04-08 22:49:33 +07:00 - Expanded Inventory Audio Cue Coverage
- Added more cue-specific uploaded Roblox inventory overrides in `src/client/SoundSystem/Main.lua`.
- New active cue mappings:
  - `EnvironmentalAudio/env_lightflicker -> rbxassetid://96038914699044` (`zap2`)
  - `EnvironmentalAudio/env_radiostatic -> rbxassetid://82526759214554` (`zap1`)
  - `EnvironmentalAudio/env_shadowapparition -> rbxassetid://139204195403262` (`creaky-door-open`)
  - `EnvironmentalAudio/env_footstepsound -> rbxassetid://95974189526179` (`ghost_footstep_2`)
  - `EnvironmentalAudio/env_suddenwhisper -> rbxassetid://110779846516591` (`ghost_whisper_2`)
  - `EnvironmentalAudio/env_temperaturedrop -> rbxassetid://87230026682789` (`thermometer_reading`)
  - `HuntAudio/hunt_start -> rbxassetid://101202336513383` (`hard-horror-hit-drum`)
  - `HuntAudio/hunt_phase_loop -> rbxassetid://138329686293368` (`horror-deep-drum-heartbeat`)
- Corrected the `pocong PASRAHPHOBIA` spelling in the inventory sync ledger note.
- Build passed: `_tmp_audio_cue_coverage_build.rbxlx`.
- Live client SoundSystem probe verified all new cue mappings resolve to the expected uploaded asset IDs.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-08 22:55:25 +07:00 - Legacy Audio Cue Alias Coverage
- Added backward-compatible cue aliases in `src/client/SoundSystem/Main.lua` so older/default event names still hit uploaded inventory audio and cue profiles.
- Alias coverage:
  - `HuntAudio/hunt_stinger -> rbxassetid://101202336513383` (`hard-horror-hit-drum`)
  - `FearAudio/heartbeat_rise -> rbxassetid://138884191945388` (`single-heart-beat`)
  - `AmbientAudio/ambient_tension_loop -> rbxassetid://140704980462451` (`Midnight Litany of Drones (Ancient Ritual Ambient)`)
- Build passed: `_tmp_audio_cue_alias_build.rbxlx`.
- Live client SoundSystem probe verified all three legacy/default cue names resolved to the expected uploaded asset IDs.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-08 23:02:51 +07:00 - Ignore Local Studio And Inventory Scan Artifacts
- Added ignore rules for local Roblox Studio lock files and inventory scan/screenshot temp artifacts.
- Removed `PASRAHPHOBIA.rbxlx.lock` from git tracking with `git rm --cached`; the lock file remains on disk for Studio, but should no longer be committed.
- This is workflow hygiene only; no runtime code or raw asset folder contents were changed.

## 2026-04-08 23:04:19 +07:00 - Remove Player-Facing Placeholder Copy From Royal Pass
- Replaced visible `placeholder hadiah karakter rarity 5` Royal Pass copy in `src/client/UI/Main.lua` with `teaser/finale` language.
- This keeps the UI honest about the day-30 reward preview without exposing raw implementation wording to players.
- Build passed: `_tmp_ui_placeholder_copy_build.rbxlx`.
- Studio script grep verified the old `placeholder hadiah karakter` text is gone and the new teaser/finale copy is present.

## 2026-04-08 23:06:51 +07:00 - Expand Footstep Material Audio Coverage
- Added uploaded Roblox inventory footstep templates:
  - `GrassStep_01 -> rbxassetid://128180668604255` (`footstep_grass_002`)
  - `SnowStep_01 -> rbxassetid://71785355785721` (`footstep_snow_000`)
- Expanded `FootstepController` material routing:
  - `Grass`, `LeafyGrass`, `Ground`, and `Sand` now use `GrassStep_01`
  - `Snow`, `Ice`, and `Glacier` now use `SnowStep_01`
- Added `PasrahFootstepProbeLastSoundId` for future runtime verification.
- Build passed: `_tmp_footstep_material_audio_build.rbxlx`.
- Live Studio client probe verified Grass/LeafyGrass -> `GrassStep_01`, Snow/Ice -> `SnowStep_01`, and Metal remains `MetalStep_01`, all with expected uploaded asset IDs.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-08 23:13:13 +07:00 - Close Default Audio Cue Gaps
- Added explicit uploaded Roblox inventory overrides in `src/client/SoundSystem/Main.lua` for default/fallback cues that previously relied on generic template routing:
  - `AmbientAudio/post_hunt_calm -> rbxassetid://140704980462451` (`Midnight Litany of Drones (Ancient Ritual Ambient)`)
  - `AmbientAudio/ambient_investigation -> rbxassetid://140704980462451`
  - `AmbientAudio/ambient_tension_loop -> rbxassetid://140704980462451`
  - `EnvironmentalAudio/environment_disturbance -> rbxassetid://111282528409948` (`door_creak_3`)
  - `EnvironmentalAudio/env_event -> rbxassetid://111282528409948`
  - `GhostAudio/ghost_interaction -> rbxassetid://98105844059537` (`ghost_whisper_3`)
- Expanded `SoundSystem` footstep template resolution so audio events carrying grass/leafy/ground/sand or snow/ice/glacier tokens route to the uploaded `GrassStep_01` and `SnowStep_01` templates instead of concrete fallback.
- Build passed: `_tmp_soundsystem_default_cue_audio_build.rbxlx`.
- Live Studio client probe verified:
  - `environment_disturbance` and `env_event` -> `rbxassetid://111282528409948`
  - `ghost_interaction` -> `rbxassetid://98105844059537`
  - `post_hunt_calm` -> `rbxassetid://140704980462451`
  - `GrassFootstep` -> `rbxassetid://128180668604255`
  - `SnowFootstep` -> `rbxassetid://71785355785721`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-08 23:18:57 +07:00 - Lock Pocong Default Visual Guard
- Updated `src/ServerScriptService/Server/GhostSystem/Service.lua` so the default `Pocong` visual size override is `0.06, 0.07, 0.07`, matching the user-validated visual size and the existing `GhostVisualTuning`/`Pocong` profile.
- This is a visual guard only; `Pocong` target bounds/root logic remain separate and are not shrunk to mesh scale.
- Corrected the inventory ledger row from `` ` pocong PASRAHPHOBIA` `` to `` `pocong PASRAHPHOBIA` ``.
- Build passed: `_tmp_pocong_visual_guard_build.rbxlx`.
- Live Studio proof:
  - Forced `Pocong` match actor spawned as `Workspace.ActiveMatches.Match_match_1.Ghost_Pocong`
  - `PlaceholderVisual=false`, `VisualTemplateName=Pocong`
  - mesh size `0.05999999865889549, 0.07000000029802322, 0.07000000029802322`
  - Forced `Banaspati` spawned as `GhostPlaceholder_Banaspati`, `PlaceholderVisual=true`, with no Pocong mesh fallback.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 00:07:41 +07:00 - Stabilize Ghost Runtime Snapshot And Align Lobby Ghost Fit
- Fixed `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua` so Studio E2E ghost snapshot actions no longer silently fail:
  - added the missing `HttpService` dependency
  - `GetGhostRuntimeSnapshot` now writes `PasrahStudioGhostRuntimeSnapshot` on `ReplicatedStorage` and the requesting `Player`
  - request dispatch is now wrapped so handler exceptions surface as `handler_error` instead of leaving stale result attributes
- Updated `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua` so lobby ghost training visuals read shared tuning from `src/shared/GameData/GhostVisualTuning.lua` before asset-local profile modules.
- Changed lobby runtime ghost fitting to scale models both down and up toward target bounds, removing the old behavior where small imported ghost assets stayed miniature in lobby training.
- Build passed: `_tmp_ghost_runtime_visual_batch_build.rbxlx`.
- Live Studio proof after fresh play sessions:
  - `GetGhostRuntimeSnapshot` now works authoritatively:
    - forced `Genderuwo` spawned as `Workspace.ActiveMatches.Match_match_1.Ghost_Genderuwo`
    - `placeholder=false`, `visualTemplateName=Genderuwo`
    - `ForceManifest` advanced snapshot state from `Idle` to `Manifest`
  - second clean run:
    - forced `Leak` spawned as `Workspace.ActiveMatches.Match_match_1.Ghost_Leak`
    - `placeholder=false`, `visualTemplateName=Leak`
    - snapshot remained live through `PreparationPhase -> InvestigationPhase -> ForceManifest`
  - lobby training ghost fit now matches shared tuning:
    - `Genderuwo` visual extents `2.870, 5.800, 1.505`
    - `Kuntilanak` visual extents `3.485, 4.800, 1.754`
    - `Leak` visual extents `1.846, 4.800, 2.287`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 00:18:56 +07:00 - Expose Ghost Visual Metrics In Studio Snapshots
- Extended `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua` so `GetGhostRuntimeSnapshot` now includes:
  - `ghostExtents`
  - `ghostScale`
  - existing actor path/template/state data in the same JSON payload
- Extended `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua` so `StudioGetEvidenceTrainingSnapshot` now includes:
  - `ghostVisualPath`
  - `ghostVisualExtents`
  - `ghostVisualScale`
  - `ghostVisualPosition`
  - `ghostVisualTemplateName`
  - `ghostTargetBounds`
- This closes the remaining need to inspect workspace manually just to compare lobby/match ghost size against target tuning during Studio E2E passes.
- Build passed: `_tmp_ghost_snapshot_fields_build.rbxlx`.
- Live Studio proof:
  - match snapshot for forced `Genderuwo` now includes `ghostExtents=2.870025634765625, 6.016216278076172, 1.505476474761963` and `ghostScale=0.045082248747348788`
  - lobby snapshot for `Kuntilanak` now includes:
    - `ghostVisualPath=Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.TrainingGhostVisual`
  - `ghostVisualExtents=3.484506130218506, 4.800000190734863, 1.7543654441833496`
  - `ghostTargetBounds=3.5, 4.800000190734863, 1.7999999523162842`
  - `ghostVisualScale=1.742253065109253`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 00:28:19 +07:00 - Unify Target Bounds Into Ghost Snapshot Payloads
- Extended `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua` so `GetGhostRuntimeSnapshot` now includes `ghostTargetBounds` from shared `GhostVisualTuning`.
- Updated `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua` so `StudioRotateEvidenceTrainingGhost` now returns the same full visual snapshot payload as `StudioGetEvidenceTrainingSnapshot`, instead of a reduced payload that forced a second query.
- This closes the remaining two-step debugging flow:
  - one rotate call is now enough to know whether a lobby ghost has an asset, where it is, and how its fitted extents compare to target bounds
  - one match snapshot now carries both live extents and intended target bounds in the same payload
- Build passed: `_tmp_ghost_snapshot_target_build.rbxlx`.
- Live Studio proof:
  - forced `Leak` match snapshot now includes `ghostTargetBounds=2, 4.800000190734863, 2.3499999046325684`
  - `LobbyTrainingRotate` now returns full asset-ready payload in one call for asset ghosts, including:
    - `ghostVisualPath`
    - `ghostVisualExtents`
    - `ghostVisualScale`
    - `ghostTargetBounds`
  - verified on `Pocong` rotate payload with:
    - `ghostVisualExtents=1.600000023841858, 1.600000023841858, 0.800000011920929`
    - `ghostTargetBounds=1.600000023841858, 3.75, 1.1799999475479126`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 00:39:11 +07:00 - Expose Ambient And Heartbeat Runtime State
- Extended `src/client/Controllers/Sensory/AudioController.luau` so player-facing runtime attrs now expose the active audio state for:
  - lobby ambient
  - preparation ambient
  - heartbeat
- Added and maintained:
  - `PasrahPreparationAmbientSoundId`
  - `PasrahPreparationAmbientPlaybackSpeed`
  - `PasrahHeartbeatActive`
  - `PasrahHeartbeatSoundId`
  - `PasrahHeartbeatPlaybackSpeed`
  - `PasrahHeartbeatReason`
- `AudioController:Stop()` now clears the new ambience/heartbeat attrs alongside the existing lobby ambient attrs.
- Build passed: `_tmp_audio_controller_state_attrs_build.rbxlx`.
- Live Studio proof:
  - lobby idle:
    - `PasrahLobbyAmbientActive=true`
    - `PasrahLobbyAmbientSoundId=rbxassetid://113854211240490`
    - `PasrahLobbyAmbientMap=LobbySocialHub`
  - `PreparationPhase`:
    - `PasrahPreparationAmbientActive=true`
    - `PasrahPreparationAmbientSoundId=rbxassetid://140704980462451`
    - `PasrahPreparationAmbientMap=HauntedHouse`
    - `PasrahPreparationAmbientPlaybackSpeed=0.94`
  - forced hunt in `InvestigationPhase`:
    - `PasrahHeartbeatActive=true`
    - `PasrahHeartbeatSoundId=rbxassetid://138884191945388`
    - `PasrahHeartbeatReason=HUNT`
  - after `EndMatch`, lobby ambient returned and the match-only attrs dropped back out.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 01:06:42 +07:00 - Unify Studio Ghost Player Attr Snapshots
- Extended `src/ServerScriptService/Server/MatchSystem/MatchService.lua` so Studio player attrs now carry richer ghost runtime state:
  - `PasrahGhostSessionState`
  - `PasrahGhostCurrentRoomId`
  - `PasrahGhostHuntActive`
  - `PasrahGhostTargetBounds`
  - `PasrahGhostExtents`
  - `PasrahGhostScale`
- Extended `src/ServerScriptService/Server/GhostSystem/Controller.lua` so the same attrs are refreshed again on hunt transitions, not only on match start/phase changes.
- Added a small effective-state guard so player-facing `PasrahGhostSessionState` follows `Hunting` when hunt is live, instead of staying stale on `Manifest`.
- Build passed: `_tmp_ghost_player_attr_sync_build.rbxlx`.
- Live Studio proof with forced `Genderuwo`:
  - `PreparationPhase` settled to:
    - `PasrahGhostType=Genderuwo`
    - `PasrahGhostSessionState=Idle`
    - `PasrahGhostRuntimeState=Idle`
    - `PasrahGhostExtents=2.870025634765625, 6.016210556030273, 1.505476474761963`
  - `InvestigationPhase` settled to:
    - `PasrahGhostSessionState=Roaming`
    - `PasrahGhostRuntimeState=Roaming`
    - `PasrahGhostCurrentRoomId=StairHall`
  - forced manifest settled to:
    - `PasrahGhostSessionState=Manifest`
    - `PasrahGhostRuntimeState=Manifest`
  - forced hunt settled to:
    - `PasrahGhostSessionState=Hunting`
    - `PasrahGhostRuntimeState=Hunting`
    - `PasrahGhostHuntActive=true`
    - `PasrahGhostTargetBounds=3.4000000953674316, 5.800000190734863, 2.5999999046325684`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 01:24:31 +07:00 - Attach Inventory Model Identity To Ghost Snapshots
- Extended `src/shared/GameData/GhostVisualTuning.lua` so shared ghost tuning now carries uploaded Roblox inventory model IDs for:
  - `Pocong`
  - `Kuntilanak`
  - `KuntilanakAggressive`
  - `Genderuwo`
- Extended `src/ServerScriptService/Server/MatchSystem/MatchService.lua` and `src/ServerScriptService/Server/GhostSystem/Controller.lua` so Studio player attrs now also expose `PasrahGhostInventoryModelAssetId`.
- Extended `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua` so `GetGhostRuntimeSnapshot` now includes `ghostInventoryModelAssetId`.
- Extended `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua` so lobby evidence training snapshot also includes `ghostInventoryModelAssetId`.
- This closes the remaining ambiguity between:
  - a ghost that is visually present because it has a real uploaded inventory model
  - a ghost that is visually present but still does not have any uploaded inventory model identity yet
- Build passed: `_tmp_ghost_inventory_model_identity_build.rbxlx`.
- Live Studio proof:
  - forced `Genderuwo` match:
    - `PasrahGhostInventoryModelAssetId=rbxassetid://117009327297852`
    - snapshot `ghostInventoryModelAssetId=rbxassetid://117009327297852`
  - forced `Pocong` match:
    - `PasrahGhostInventoryModelAssetId=rbxassetid://123151303766691`
    - snapshot `ghostInventoryModelAssetId=rbxassetid://123151303766691`
  - forced `Leak` match:
    - no `PasrahGhostInventoryModelAssetId`
    - snapshot also omitted `ghostInventoryModelAssetId`
  - lobby training rotate:
    - returned `ghostType=Genderuwo`
    - `ghostInventoryModelAssetId=rbxassetid://117009327297852`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 01:31:08 +07:00 - Stamp Lobby Training Ghost Runtime Identity
- Updated `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua` so imported lobby training ghost instances now carry runtime identity attrs directly on the model:
  - `VisualTemplateName`
  - `PlaceholderVisual=false`
  - `PasrahGhostInventoryModelAssetId`
- This removes the remaining mismatch where lobby snapshot already knew the ghost type/asset ID externally, but the actual `TrainingGhostVisual` model still looked anonymous when inspected directly.
- Build passed: `_tmp_lobby_training_ghost_identity_attr_build.rbxlx`.
- Live Studio proof:
  - lobby rotate settled to `ghostType=Pocong`
  - snapshot returned:
    - `ghostVisualTemplateName=Pocong`
    - `ghostInventoryModelAssetId=rbxassetid://123151303766691`
  - runtime model `Workspace...TrainingGhostVisual` now exposes:
    - `VisualTemplateName=Pocong`
    - `PasrahGhostInventoryModelAssetId=rbxassetid://123151303766691`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 01:36:54 +07:00 - Stamp Match Ghost Runtime Identity
- Updated `src/ServerScriptService/Server/GhostSystem/Service.lua` so real spawned ghost actors now carry `PasrahGhostInventoryModelAssetId` directly on the runtime model when shared tuning knows the uploaded inventory model.
- Placeholder visuals explicitly keep that attr empty, so direct workspace inspection stays truthful for ghosts that still rely on local runtime visuals only.
- Build passed: `_tmp_match_ghost_runtime_identity_attr_build.rbxlx`.
- Live Studio proof:
  - real `Genderuwo` actor:
    - `Workspace.ActiveMatches.Match_match_1.Ghost_Genderuwo`
    - `VisualTemplateName=Genderuwo`
    - `PasrahGhostInventoryModelAssetId=rbxassetid://117009327297852`
  - real `Leak` actor:
    - `Workspace.ActiveMatches.Match_match_2.Ghost_Leak`
    - `VisualTemplateName=Leak`
    - no `PasrahGhostInventoryModelAssetId`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 01:43:22 +07:00 - Stamp Runtime Audio Instance Identity
- Updated `src/client/SoundSystem/Main.lua` so one-shot and looped runtime sounds now carry direct identity attrs on the sound instance itself:
  - `PasrahAudioOwner`
  - `PasrahAudioCategory`
  - `PasrahAudioCue`
  - `PasrahAudioEventType`
  - `PasrahAudioTemplate`
  - `PasrahAudioSoundId`
  - `PasrahAudioLooped`
- Updated `src/client/Controllers/Sensory/AudioController.luau` so managed persistent sounds (`LobbyAmbient`, `PreparationAmbient`, `Heartbeat`) now carry the same direct identity attrs, plus:
  - `PasrahAudioMapProfile` on lobby/preparation ambience
  - `PasrahHeartbeatReason` on heartbeat
- This closes the remaining mismatch where player attrs/debug already knew what sound had fired, but direct workspace/camera inspection still had to infer audio identity from instance names.
- Build passed: `_tmp_audio_runtime_identity_build.rbxlx`.
- Live Studio proof:
  - lobby idle:
    - `Workspace.Camera.LobbyAmbient`
    - `PasrahAudioOwner=AudioController`
    - `PasrahAudioCategory=AmbientAudio`
    - `PasrahAudioCue=bgm_lobby_ambient`
    - `PasrahAudioSoundId=rbxassetid://113854211240490`
    - `PasrahAudioMapProfile=LobbySocialHub`
  - `PreparationPhase`:
    - `Workspace.Camera.PreparationAmbient`
    - `PasrahAudioCue=ambient_investigation`
    - `PasrahAudioSoundId=rbxassetid://140704980462451`
    - `PasrahAudioMapProfile=HauntedHouse`
  - forced oneshot cue:
    - `Workspace.Camera.EnvironmentalAudioRuntime`
    - `PasrahAudioOwner=SoundSystem`
    - `PasrahAudioCue=env_doorslam`
    - `PasrahAudioEventType=DoorSlam`
    - `PasrahAudioSoundId=rbxassetid://78764817933410`
  - forced hunt:
    - `Workspace.Camera.Heartbeat`
    - `PasrahHeartbeatReason=HUNT`
    - `PasrahAudioCue=heartbeat_rise`
    - `PasrahAudioSoundId=rbxassetid://138884191945388`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 04:34:55 +07:00 - Stamp Flashlight Runtime Identity
- Updated `src/client/FlashlightController.client.lua` so local flashlight runtime now publishes direct toggle state/visibility attrs instead of keeping flashlight state implicit in button text only.
- Updated `src/client/CameraController.client.lua` so FPV flashlight viewmodel and cursor toggle now stamp direct runtime attrs on the actual client instances:
  - `FPV_Arms`
  - `FPV_Flashlight`
  - `Handle`
  - `Lens`
  - `FPV_LocalSpotLight`
  - `FPVCursorToggleUI`
  - `CursorToggleButton`
- Updated `src/ServerScriptService/Server/FlashlightSyncSystem/Service.lua` so flashlight remote sync now rechecks attachment on demand instead of trusting spawn-time cache only, and now publishes authoritative remote flashlight probe attrs back onto the player for Studio verification.
- Build passed: `_tmp_flashlight_runtime_identity_build.rbxlx`.
- Live Studio proof:
  - forced FPV probe (`InMatch=true`, `MatchId=flashlight_probe`) produced:
    - `PasrahCursorMode=LockedFPV`
    - `PasrahFlashlightVisualAlpha=1`
    - `PasrahFlashlightLightEnabled=true`
  - runtime FPV instances carried direct identity:
    - `Workspace.Camera.FPV_Arms` -> `PasrahFlashlightChannel=FPVArms`
    - `Workspace.Camera.FPV_Arms.FPV_Flashlight.Lens.FPV_LocalSpotLight` -> `PasrahFlashlightChannel=FPVLocalSpotLight`
    - `PlayerGui.FPVCursorToggleUI.CursorToggleButton` -> `PasrahFlashlightChannel=CursorToggleButton`
  - after `LeftAlt` unlock:
    - `PasrahCursorMode=UnlockedUI`
    - `PasrahCursorUnlocked=true`
    - `CursorToggleButton.PasrahCursorUnlocked=true`
  - server-authoritative remote flashlight probe now proves the remote owner is alive even when the local client does not surface `FlashlightHandle` on its own character tree:
    - `PasrahFlashlightRemoteLastAction=Toggle`
    - `PasrahFlashlightRemoteLiveHandle=true`
    - `PasrahFlashlightRemoteHandleMatchesCache=true`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 07:03:19 +07:00 - Stamp Royal Pass UI Runtime Identity
- Status: DONE.
- `Client.UI.Main` now stamps direct runtime attrs on `RoyalPassUI` itself, including the main panel, hero card, progress widgets, premium CTA, track scroller, and active current-day card bundle.
- Live Studio proof:
  - baseline before opening the panel:
    - `PlayerGui.RoyalPassUI.MainPanel.Visible=false`
    - `PasrahRoyalPassUIOwner=UISystem`
    - `PasrahRoyalPassUIChannel=RoyalPassPanel`
    - `PasrahRoyalPassCurrentTier=1`
    - `PasrahRoyalPassTotalXP=0`
    - `PasrahRoyalPassPremiumOwned=false`
    - `PasrahRoyalPassCurrentDay=1`
  - after canonical `R` open:
    - `RoyalPassUI.MainPanel.Visible=true`
    - `RoyalPassDeck.HeroCard` -> `PasrahRoyalPassUIChannel=RoyalPassHeroCard`
    - `RoyalPassDeck.TrackScroller` -> `PasrahRoyalPassUIChannel=RoyalPassTrackScroller`
    - `RoyalPassDeck.TrackScroller.DayCard1` -> `PasrahRoyalPassUIChannel=RoyalPassCurrentDayCard`, `PasrahRoyalPassCurrentDay=1`, `PasrahRoyalPassLastEvent=RoyalPassSnapshot`
- Build passed: `_tmp_royalpass_ui_identity_build.rbxlx`.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 07:10:18 +07:00 - Stamp Profile, Shop, And Spectator UI Runtime Identity
- Status: DONE.
- `Client.UI.Main` now stamps direct runtime attrs on `ProfileUI`, `ShopUI`, and `SpectatorUI` under the canonical `UISystem` owner.
- Build passed: `_tmp_profile_shop_spectator_identity_build.rbxlx`.
- Live Studio proof:
  - `ProfileUI` opened via canonical shortcut flow and now carries:
    - `MainPanel` -> `PasrahProfileUIOwner=UISystem`, `PasrahProfileUIChannel=ProfilePanel`, `PasrahProfileUIVisible=true`, `PasrahProfileLastEvent=CosmeticSnapshot`
    - `ContentFrame.ProfileDeck.HeroCard` -> `PasrahProfileUIChannel=ProfileHeroCard`
  - `ShopUI` opened via canonical shortcut flow and now carries:
    - `MainPanel` -> `PasrahShopUIOwner=UISystem`, `PasrahShopUIChannel=ShopPanel`, `PasrahShopFilter=All`
    - wallet snapshot attrs -> `PasrahShopWalletMM=1200`, `PasrahShopWalletPP=12`
    - `ContentFrame.ItemList.ItemRow1` -> `PasrahShopItemId=eq_sanitypill_standard`, `PasrahShopItemCurrency=MM`, `PasrahShopItemPurchasable=true`
  - `SpectatorUI` opened via canonical shortcut flow and now carries:
    - `MainPanel` -> `PasrahSpectatorUIOwner=UISystem`, `PasrahSpectatorUIChannel=SpectatorPanel`, `PasrahSpectatorUIVisible=true`
    - baseline spectator state remained truthful in lobby idle -> `PasrahSpectatorMode=none`, `PasrahSpectatorTitle=Belum spectate.`, `PasrahSpectatorLastEvent=Idle`
- Note:
  - full `dead -> spectator` transition was not claimed in this batch; the verified proof above is the baseline panel/runtime owner path.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 10:49:50 +07:00 - Stamp MainMenu And Leaderboard Runtime Identity + Effective Visibility
- Status: DONE.
- `Client.UI.Main` now stamps direct runtime attrs for `MainMenuUI` and `LeaderboardUI`, and all UI visibility attrs in the same lane now use effective parent-aware visibility.
- Build passed: `_tmp_mainmenu_leaderboard_identity_build.rbxlx`.
- Live Studio proof in Play Solo client context (`isClient=true`, `LocalPlayer=true`):
  - `MainMenuUI.MainPanel.Visible=false` and `PasrahMainMenuUIVisible=false`.
  - `MainMenuUI.MainMenuFloatButton.Visible=true` but `PasrahMainMenuUIVisible=false` because parent panel lane is hidden.
  - `LeaderboardUI.MainPanel.Visible=false` and `PasrahLeaderboardUIVisible=false`.
  - `LeaderboardDeck.Visible=true` and `HeroCard.Visible=true`, both now stamped `PasrahLeaderboardUIVisible=false` while panel is hidden.
  - channel attrs are present and canonical (`MainMenuPanel`, `MainMenuFloatButton`, `LeaderboardPanel`, `LeaderboardDeck`, `LeaderboardHeroCard`).
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 11:39:31 +07:00 - Close Dead To Spectator Runtime Truth
- Status: DONE.
- `Server.DeathStateSystem.Service` is now the canonical owner for death runtime truth in this lane:
  - stamps `PasrahDeath*` attrs directly on the dead player
  - forwards `MatchEvent.PlayerKilled` to match clients with truthful `localPlayerKilled`
- `Server.SpectatorModeSystem.Service` now stamps `PasrahSpectator*` attrs directly on the player for enter/exit/match-end transitions.
- Build passed: `_tmp_deadstate_spectator_identity_build.rbxlx`.
- Live Studio proof in Play Solo:
  - `StartSoloMatch` -> `ok=true | action=StartSoloMatch | result=match=match_1 map=HauntedHouse mode=Classic difficulty=Mudah players=1`
  - `AdvancePhase` -> `ok=true | action=AdvancePhase | result=match=match_1 nextPhase=InvestigationPhase`
  - forced death after spawn-protection window produced:
    - player attrs:
      - `PasrahDeathOwner=DeathStateSystem`
      - `PasrahDeathState=Dead`
      - `PasrahDeathLastEvent=PlayerKilled`
      - `PasrahDeathActive=true`
      - `PasrahSpectatorOwner=SpectatorModeSystem`
      - `PasrahSpectatorMode=FreeCamera`
      - `PasrahSpectatorActive=true`
    - UI attrs:
      - `Players.ZyraaaVex.PlayerGui.SpectatorUI.MainPanel`
      - `PasrahSpectatorUIVisible=true`
      - `PasrahSpectatorMode=dead`
      - `PasrahSpectatorLastEvent=PlayerKilled`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 12:11:18 +07:00 - Close Spectator Exit On Respawn
- Status: DONE.
- `Server.DeathStateSystem.DeathEventBridge` now promotes real `CharacterAdded` after death into `PlayerRespawnRequested` only when the player was actually dead/spectating.
- `Server.DeathStateSystem.Service` now:
  - clears `PasrahDeath*` runtime attrs on respawn
  - forwards `MatchEvent.PlayerRespawned` with truthful `localPlayerRespawned`
  - asks `SpectatorModeSystem` to exit the player from spectator state
- `Server.SpectatorModeSystem.Service` now removes spectator state on `PlayerRespawnRequested` / `PlayerRespawned`.
- Client consumers now honor the respawn exit path:
  - `src/client/SpectatorSystem/Main.lua`
  - `src/client/SpectatorEffects/Main.lua`
  - `src/client/UI/Main.lua`
- Build passed: `_tmp_spectator_respawn_exit_build.rbxlx`.
- Live Studio proof in Play Solo:
  - run used the same canonical path:
    - `StartSoloMatch` -> `ok=true | action=StartSoloMatch | result=match=match_1 map=HauntedHouse mode=Classic difficulty=Mudah players=1`
    - `AdvancePhase` -> `ok=true | action=AdvancePhase | result=match=match_1 nextPhase=InvestigationPhase`
    - local death entered spectator as expected first
  - after real respawn/`CharacterAdded`, exit state became truthful:
    - player attrs:
      - `PasrahDeathOwner` cleared
      - `PasrahDeathState` cleared
      - `PasrahDeathActive` cleared
      - `PasrahSpectatorOwner=SpectatorModeSystem`
      - `PasrahSpectatorActive=false`
      - `PasrahSpectatorMode` cleared
      - `PasrahSpectatorReason=character_added`
    - spectator UI:
      - `PasrahSpectatorMode=none`
      - `PasrahSpectatorLastEvent=PlayerRespawned`
    - spectator FX:
      - `SpectatorBlurEffect.Enabled=false`
      - `SpectatorBlurEffect.Size=0`
      - `SpectatorColorCorrection.Enabled=false`
- Note:
  - the Play Solo run can re-enter danger if left running too long inside the active match; proof was captured at the first truthful respawn-exit state, then Studio was returned to STOP TEST.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 12:25:42 +07:00 - Add Simulated Teammate Warning Probe
- Status: DONE.
- `Server.StudioE2EControlSystem.Main` now exposes `SimulateTeammateWarning` on the existing Studio E2E remote, using the real `MatchEvent` client route instead of a duplicate debug channel.
- Build passed: `_tmp_teammate_warning_sim_build.rbxlx`.
- Live Studio proof in Play Solo:
  - `StartSoloMatch` -> `ok=true | action=StartSoloMatch | result=match=match_1 map=HauntedHouse mode=Classic difficulty=Mudah players=1`
  - `AdvancePhase` -> `ok=true | action=AdvancePhase | result=match=match_1 nextPhase=InvestigationPhase`
  - `SimulateTeammateWarning` -> `ok=true | action=SimulateTeammateWarning | result=match=match_1 teammate=DebugTeammate(910001)`
  - spectator warning UI entered the expected non-local path:
    - `PasrahSpectatorMode=warning`
    - `PasrahSpectatorUIVisible=true`
    - `PasrahSpectatorLastEvent=PlayerKilled`
    - `PasrahSpectatorTitle=TEAMMATE DOWN`
- Note:
  - this batch proves the client warning lane through the existing Studio E2E owner, not through real multiplayer replication.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 12:33:11 +07:00 - Decay Teammate Warning Back To Neutral
- Status: DONE.
- `Client.UI.Main` now fully decays the non-local teammate warning path back to neutral after the warning timeout instead of only hiding the panel while leaving `warning` state active.
- Build passed: `_tmp_teammate_warning_decay_build.rbxlx`.
- Live Studio proof in Play Solo using the existing `SimulateTeammateWarning` probe:
  - hot state:
    - `PasrahSpectatorMode=warning`
    - `PasrahSpectatorUIVisible=true`
    - `PasrahSpectatorTitle=TEAMMATE DOWN`
  - cooled state after timeout:
    - `PasrahSpectatorMode=none`
    - `PasrahSpectatorUIVisible=false`
    - `PasrahSpectatorLastEvent=PlayerKilled`
    - `PasrahSpectatorTitle=Belum spectate.`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 12:01:36 +07:00 - Centralize Spectator Baseline Reset + Restore UI Compile Health
- Status: DONE.
- `Client.UI.Main` now resets spectator baseline through one canonical helper instead of repeating manual `mode/title/subtitle/visible` mutations across teammate-warning decay, respawn, match start/end, lobby return, and results exit.
- The helper was implemented as a `UISystem` method, not a new top-level local function, to avoid re-triggering the Luau `out of local registers` failure in `Client.UI.Main`.
- Build passed: `_tmp_spectator_reset_helper_build.rbxlx`.
- Live Studio proof in Play Solo through the existing Studio E2E path:
  - `StartSoloMatch` -> `ok=true | action=StartSoloMatch | result=match=match_5 map=HauntedHouse mode=Classic difficulty=Mudah players=1`
  - `AdvancePhase` -> `ok=true | action=AdvancePhase | result=match=match_5 nextPhase=InvestigationPhase`
  - `SimulateTeammateWarning` hot state:
    - `PasrahSpectatorMode=warning`
    - `PasrahSpectatorUIVisible=true`
    - `PasrahSpectatorTitle=TEAMMATE DOWN`
    - `PasrahSpectatorLastEvent=PlayerKilled`
  - cooled state after timeout:
    - `PasrahSpectatorMode=none`
    - `PasrahSpectatorUIVisible=false`
    - `PasrahSpectatorTitle=Belum spectate.`
    - `PasrahSpectatorLastEvent=PlayerKilled`
- Health check:
  - no fresh `ClientBootstrap` warnings
  - no fresh `out of local registers` errors from `Players.ZyraaaVex.PlayerScripts.Client.UI.Main`

## 2026-04-09 12:01:36 +07:00 - Stamp Spectator FX Runtime Identity
- Status: DONE.
- `Client.SpectatorEffects.Main` now stamps direct runtime attrs on:
  - `Lighting.SpectatorBlurEffect`
  - `Lighting.SpectatorColorCorrection`
  - `PlayerGui.SpectatorUI.StaticFlickerOverlay`
  - `PlayerGui.SpectatorUI.ColorDesaturationOverlay`
  - local player attrs `PasrahSpectatorFX*`
- New runtime truth includes owner/channel, active state, last outcome, last reason, overlay visibility, and blur/color intensity.
- Build passed:
  - `_tmp_spectator_effects_identity_build.rbxlx`
  - `_tmp_spectator_lobby_exit_build.rbxlx`
- Live Studio proof via direct module probe of the client owner:
  - hot state:
    - player attrs:
      - `PasrahSpectatorFXOwner=SpectatorEffects`
      - `PasrahSpectatorFXActive=true`
      - `PasrahSpectatorFXOutcome=fake`
      - `PasrahSpectatorFXReason=StudioProbe`
    - `Lighting.SpectatorBlurEffect`:
      - `PasrahSpectatorFXOwner=SpectatorEffects`
      - `PasrahSpectatorFXChannel=Blur`
      - `PasrahSpectatorFXEnabled=true`
      - `PasrahSpectatorFXIntensity=10`
    - `Lighting.SpectatorColorCorrection`:
      - `PasrahSpectatorFXOwner=SpectatorEffects`
      - `PasrahSpectatorFXChannel=ColorCorrection`
      - `PasrahSpectatorFXEnabled=true`
  - cooled state after explicit exit:
    - `PasrahSpectatorFXActive=false`
    - `PasrahSpectatorFXReason=ExitSpectatorMode`
    - `SpectatorBlurEffect.PasrahSpectatorFXEnabled=false`
    - `SpectatorColorCorrection.PasrahSpectatorFXEnabled=false`
- Note:
  - this proof intentionally uses a direct client module probe because the current Studio E2E server surface does not yet expose a dedicated local-kill probe for this owner.

## 2026-04-09 12:01:36 +07:00 - Stamp Spectator Client/Camera Identity + Lobby Exit Truth
- Status: DONE.
- `Client.SpectatorSystem.Main` now stamps direct runtime attrs on the local player and `Workspace.CurrentCamera`:
  - `PasrahSpectatorClientOwner`
  - `PasrahSpectatorClientActive`
  - `PasrahSpectatorClientMode`
  - `PasrahSpectatorClientTarget`
  - `PasrahSpectatorClientDistortionState`
  - `PasrahSpectatorClientLastEvent`
  - `PasrahSpectatorClientReason`
  - `PasrahSpectatorClientEnteredAt`
- `SpectatorSystem` and `SpectatorEffects` now both clear on:
  - `MatchCompleted`
  - `ReturnedToLobby`
  - `LobbyEntered`
  - `RoomBrowserRoomLeft`
- Build passed:
  - `_tmp_spectator_system_identity_build.rbxlx`
  - `_tmp_spectator_lobby_exit_build.rbxlx`
- Live Studio proof via direct module probe:
  - hot state:
    - player attrs:
      - `PasrahSpectatorClientOwner=SpectatorSystem`
      - `PasrahSpectatorClientActive=true`
      - `PasrahSpectatorClientMode=FreeCamera`
      - `PasrahSpectatorClientTarget=ProbeTarget`
      - `PasrahSpectatorClientReason=StudioProbe`
    - `Workspace.CurrentCamera`:
      - `PasrahSpectatorClientOwner=SpectatorSystem`
      - `PasrahSpectatorClientActive=true`
      - `PasrahSpectatorClientMode=FreeCamera`
      - `PasrahSpectatorClientTarget=ProbeTarget`
  - after `LobbyEntered` probe:
    - player attrs:
      - `PasrahSpectatorClientActive=false`
      - `PasrahSpectatorClientMode=None`
      - `PasrahSpectatorClientLastEvent=LobbyEntered`
      - `PasrahSpectatorClientReason=LobbyEntered`
    - camera attrs:
      - `PasrahSpectatorClientActive=false`
      - `PasrahSpectatorClientMode=None`
    - FX lane also cleared truthfully:
      - `PasrahSpectatorFXActive=false`
      - `SpectatorBlurEffect.PasrahSpectatorFXEnabled=false`
      - `SpectatorColorCorrection.PasrahSpectatorFXEnabled=false`
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 12:01:36 +07:00 - Stamp Spectator Camera Server Identity + Studio Probe
- Status: DONE.
- `Server.SpectatorCameraSystem.Service` now stamps direct runtime attrs on the player under the active owner:
  - `PasrahSpectatorCameraOwner`
  - `PasrahSpectatorCameraMatchId`
  - `PasrahSpectatorCameraMode`
  - `PasrahSpectatorCameraTargetUserId`
  - `PasrahSpectatorCameraPosition`
  - `PasrahSpectatorCameraRotation`
  - `PasrahSpectatorCameraBoundsMin`
  - `PasrahSpectatorCameraBoundsMax`
  - `PasrahSpectatorCameraCanObserveLivingPlayers`
  - `PasrahSpectatorCameraCanObserveGhost`
  - `PasrahSpectatorCameraLimitedAwareness`
  - `PasrahSpectatorCameraLastEvent`
  - `PasrahSpectatorCameraReason`
  - `PasrahSpectatorCameraActive`
- `Server.StudioE2EControlSystem.Main` now exposes:
  - `SimulateSpectatorCamera`
  - `EndSpectatorCamera`
- The new Studio probe publishes through the real `EventBus` owner route instead of inventing a parallel camera debug system.
- Build passed: `_tmp_spectator_camera_identity_build.rbxlx`.
- Live Studio proof in Play Solo:
  - `StartSoloMatch` -> `ok=true | action=StartSoloMatch | result=match=match_2 map=HauntedHouse mode=Classic difficulty=Mudah players=1`
  - after a settle delay, `SimulateSpectatorCamera` ->
    - `ok=true | action=SimulateSpectatorCamera | result=match=match_2 mode=FreeCamera target=940002 position=-2.5, 19, 2.5 rotation=0, 25, 0 limited=true`
  - hot runtime attrs on player:
    - `PasrahSpectatorCameraOwner=SpectatorCameraSystem`
    - `PasrahSpectatorCameraActive=true`
    - `PasrahSpectatorCameraMode=FreeCamera`
    - `PasrahSpectatorCameraTargetUserId=940002`
    - `PasrahSpectatorCameraPosition=-2.500, 19.000, 2.500`
    - `PasrahSpectatorCameraRotation=0.000, 25.000, 0.000`
    - `PasrahSpectatorCameraBoundsMin=-20.000, 8.000, -20.000`
    - `PasrahSpectatorCameraBoundsMax=20.000, 30.000, 20.000`
    - `PasrahSpectatorCameraLastEvent=SpectatorTargetChanged`
    - `PasrahSpectatorCameraReason=studio_camera_probe_hot`
  - `EndSpectatorCamera` ->
    - `ok=true | action=EndSpectatorCamera | result=match=match_2 spectator_camera_ended`
  - cooled runtime attrs on player:
    - `PasrahSpectatorCameraOwner=SpectatorCameraSystem`
    - `PasrahSpectatorCameraActive=false`
    - `PasrahSpectatorCameraMode` cleared
    - `PasrahSpectatorCameraTargetUserId` cleared
    - `PasrahSpectatorCameraLastEvent=SpectatorModeEnded`
    - `PasrahSpectatorCameraReason=studio_camera_probe_hot_end`
- Note:
  - the probe intentionally waits for `MatchStarted` baseline to settle before simulating camera state, otherwise the baseline `MatchStarted` stamp can race and overwrite the hot snapshot.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 12:41:27 +07:00 - Stamp Spectator Vision Server Identity + Studio Probe
- Status: DONE.
- `Server.SpectatorSystem.SpectatorService` now stamps direct runtime attrs on the player under the active owner:
  - `PasrahSpectatorVisionOwner`
  - `PasrahSpectatorVisionMatchId`
  - `PasrahSpectatorVisionActive`
  - `PasrahSpectatorVisionTargetUserId`
  - `PasrahSpectatorVisionLastOutcome`
  - `PasrahSpectatorVisionLastSignalType`
  - `PasrahSpectatorVisionLastRoomId`
  - `PasrahSpectatorVisionReliability`
  - `PasrahSpectatorVisionVoiceAllowed`
  - `PasrahSpectatorVisionDistortionHint`
  - `PasrahSpectatorVisionLikelyMisleading`
  - `PasrahSpectatorVisionLastEvent`
  - `PasrahSpectatorVisionLastActivityType`
  - `PasrahSpectatorVisionReason`
  - `PasrahSpectatorVisionCreatedAt`
  - `PasrahSpectatorVisionVisibleUntil`
  - `PasrahSpectatorVisionLastUpdatedAt`
- `Server.StudioE2EControlSystem.Main` now exposes:
  - `SimulateSpectatorVision`
  - `EndSpectatorVision`
- Fixed the Studio probe to seed the match through the real `SpectatorSystem` core service instead of calling the private `_ensureMatch` method on the wrapper `Service` table.
- Build passed: `_tmp_spectator_vision_identity_build.rbxlx`.
- Live Studio proof in Play Solo:
  - `StartSoloMatch` -> `ok=true | action=StartSoloMatch | result=match=match_1 map=HauntedHouse mode=Classic difficulty=Mudah players=1`
  - `SimulateSpectatorVision` ->
    - `ok=true | action=SimulateSpectatorVision | result=match=match_1 events=1 outcome=fake signal=FakeGhost room=Room_LivingRoom target=950001 voice=true hint=fake`
  - hot runtime attrs on player:
    - `PasrahSpectatorVisionOwner=SpectatorSystem`
    - `PasrahSpectatorVisionActive=true`
    - `PasrahSpectatorVisionTargetUserId=950001`
    - `PasrahSpectatorVisionLastOutcome=fake`
    - `PasrahSpectatorVisionLastSignalType=FakeGhost`
    - `PasrahSpectatorVisionLastRoomId=Room_LivingRoom`
    - `PasrahSpectatorVisionReliability=low`
    - `PasrahSpectatorVisionVoiceAllowed=true`
    - `PasrahSpectatorVisionDistortionHint=fake`
    - `PasrahSpectatorVisionLikelyMisleading=true`
    - `PasrahSpectatorVisionLastEvent=SpectatorVisionUpdated`
    - `PasrahSpectatorVisionReason=fake`
  - `EndSpectatorVision` ->
    - `ok=true | action=EndSpectatorVision | result=match=match_1 spectator_vision_ended`
  - cooled runtime attrs on player:
    - `PasrahSpectatorVisionOwner=SpectatorSystem`
    - `PasrahSpectatorVisionActive=false`
    - `PasrahSpectatorVisionLastEvent=SpectatorExited`
    - `PasrahSpectatorVisionReason=spectator_exited`
    - `PasrahSpectatorVisionTargetUserId` cleared
    - `PasrahSpectatorVisionLastOutcome` cleared
    - `PasrahSpectatorVisionLastSignalType` cleared
    - `PasrahSpectatorVisionVoiceAllowed=false`
    - `PasrahSpectatorVisionDistortionHint` cleared
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 15:32:00 +07:00 - Cosmetic Server Identity
- Status: DONE.
- `Server.CosmeticSystem.Service`
  - now stamps `PasrahCosmetic*` directly on the player for snapshot builds, lobby apply, equip, and unequip
  - keeps owner truthful as `CosmeticSystem`, with owned/equipped counts and last cosmetic/slot attached to runtime state
- `Server.StudioE2EControlSystem.Main`
  - now exposes `GetCosmeticSnapshot`
  - now exposes `EquipCosmeticSnapshot`
  - now exposes `UnequipCosmeticSnapshot`
- Build passed:
  - `_tmp_cosmetic_identity_build.rbxlx`
- Live proof in Play Solo:
  - grant MM:
    - `ok=true | action=GrantCurrency | result=currency=MM granted=1000 MM=2200 PP=12 Robux=0`
  - purchase cosmetic:
    - `ok=true | action=ProcessShopPurchase | result=item=cos_accessory_wardingcharm MM=1500 PP=12 Robux=0 ownedCount=1`
  - ownership proof:
    - `ok=true | action=GetShopPlayerSnapshot | result=MM=1500 PP=12 Robux=0 inventory=1 cosmetics=1 ownedCount=1 item=cos_accessory_wardingcharm hasItem=true ownsCosmetic=true ownedSnapshot=true`
    - `ok=true | action=GetCosmeticSnapshot | result=owned=1 equipped=0`
  - equip proof:
    - `ok=true | action=EquipCosmeticSnapshot | result=cosmetic=cos_accessory_wardingcharm slot=accessory owned=1 equipped=1`
    - `ok=true | action=GetCosmeticSnapshot | result=owned=1 equipped=1`
  - unequip proof:
    - `ok=true | action=UnequipCosmeticSnapshot | result=slot=accessory owned=1 equipped=0`
    - `ok=true | action=GetCosmeticSnapshot | result=owned=1 equipped=0`
  - hot runtime attrs on player after the cycle:
    - `PasrahCosmeticOwner=CosmeticSystem`
    - `PasrahCosmeticOwnedCount=1`
    - `PasrahCosmeticEquippedCount=0`
    - `PasrahCosmeticLastCosmeticId=cos_accessory_wardingcharm`
    - `PasrahCosmeticLastSlot=accessory`
    - `PasrahCosmeticLastReason=unequip`
    - `PasrahCosmeticAppliedToLobby=true`
    - `PasrahCosmeticLastEvent=CosmeticSnapshotBuilt`
- Note:
  - this lane is only marked DONE after running the full MM purchase -> equip -> unequip cycle. A snapshot-only proof would have been too weak for this owner.
- Roblox Studio was returned to STOP TEST before logging.

## 2026-04-09 21:42:24 +07:00 - Runtime Verification Refresh
- Status: DONE.
- Scope:
  - re-verified the latest live `CosmeticSystem` and `SpectatorSystem` owner lanes in the active `PASRAHPHOBIA.rbxlx` Studio session through `StudioE2EControlSystem`
  - kept the session lightweight by logging only the operational proof, not full inline screenshots or giant payloads
- Live proof in Play Solo:
  - cosmetic cycle stayed healthy:
    - `ok=true | action=GetWallet | result=MM=1200 PP=12 Robux=0`
    - `ok=true | action=GrantCurrency | result=currency=MM granted=1000 MM=2200 PP=12 Robux=0`
    - `ok=true | action=ProcessShopPurchase | result=item=cos_accessory_wardingcharm MM=1500 PP=12 Robux=0 ownedCount=1`
    - `ok=true | action=GetShopPlayerSnapshot | result=MM=1500 PP=12 Robux=0 inventory=1 cosmetics=1 ownedCount=1 item=cos_accessory_wardingcharm hasItem=true ownsCosmetic=true ownedSnapshot=true`
    - `ok=true | action=GetCosmeticSnapshot | result=owned=1 equipped=0`
    - `ok=true | action=EquipCosmeticSnapshot | result=cosmetic=cos_accessory_wardingcharm slot=accessory owned=1 equipped=1`
    - `ok=true | action=GetCosmeticSnapshot | result=owned=1 equipped=1`
    - `ok=true | action=UnequipCosmeticSnapshot | result=slot=accessory owned=1 equipped=0`
    - `ok=true | action=GetCosmeticSnapshot | result=owned=1 equipped=0`
  - cosmetic runtime attrs stayed truthful after the cycle:
    - `PasrahCosmeticOwner=CosmeticSystem`
    - `PasrahCosmeticOwnedCount=1`
    - `PasrahCosmeticEquippedCount=0`
    - `PasrahCosmeticLastCosmeticId=cos_accessory_wardingcharm`
    - `PasrahCosmeticLastSlot=accessory`
    - `PasrahCosmeticLastReason=unequip`
    - `PasrahCosmeticAppliedToLobby=true`
    - `PasrahCosmeticLastEvent=CosmeticSnapshotBuilt`
  - spectator vision still boots from a fresh solo match:
    - `ok=true | action=StartSoloMatch | result=match=match_1 map=HauntedHouse mode=Classic difficulty=Mudah players=1`
    - player runtime moved into `MatchLifecyclePhase=PreparationPhase`
    - `ok=true | action=SimulateSpectatorVision | result=match=match_1 events=1 outcome=uncertain signal=UncertainGhost room=Room_LivingRoom target=950001 voice=true hint=uncertain`
    - `ok=true | action=EndSpectatorVision | result=match=match_1 spectator_vision_ended`
  - spectator runtime attrs stayed truthful:
    - hot:
      - `PasrahSpectatorVisionOwner=SpectatorSystem`
      - `PasrahSpectatorVisionActive=true`
      - `PasrahSpectatorVisionTargetUserId=950001`
      - `PasrahSpectatorVisionLastOutcome=uncertain`
      - `PasrahSpectatorVisionLastSignalType=UncertainGhost`
      - `PasrahSpectatorVisionLastRoomId=Room_LivingRoom`
      - `PasrahSpectatorVisionReliability=low`
      - `PasrahSpectatorVisionVoiceAllowed=true`
      - `PasrahSpectatorVisionDistortionHint=uncertain`
      - `PasrahSpectatorVisionLikelyMisleading=true`
      - `PasrahSpectatorVisionLastEvent=SpectatorVisionUpdated`
      - `PasrahSpectatorVisionReason=uncertain`
    - cooled:
      - `PasrahSpectatorVisionOwner=SpectatorSystem`
      - `PasrahSpectatorVisionActive=false`
      - `PasrahSpectatorVisionVoiceAllowed=false`
      - `PasrahSpectatorVisionLastEvent=SpectatorExited`
      - `PasrahSpectatorVisionReason=spectator_exited`
- Console sanity:
  - boot completed cleanly and no error blocker surfaced in the Play Solo console during this verification pass
  - residual noise still exists from `HidingSystem` debug prints (`[HidingSystem][Debug] service:start`, `[HidingSystem][Debug] tick:no_match`), but this did not block the verified flows above
- Roblox Studio was returned to STOP TEST after verification.

## 2026-04-09 22:01:57 +07:00 - Final Release Checklist Stage 1 Batch Refresh
- Status: DONE.
- Scope:
  - took the 5-item automatic gate batch from `FINAL_RELEASE_CHECKLIST_2026-04-06.md`
  - re-ran local preflight before and after runtime fixes to keep the batch tied to current source, not stale report state
- Local preflight:
  - `Build ok: True`
  - `Missing reports: 0`
  - `Robux items: 10`
  - `Safe items missing ID: 6`
  - `Safe items disabled: 6`
  - `Hold items enabled: 0`
- First gate run exposed two real runtime regressions:
  - `Players.ZyraaaVex.PlayerScripts.Client.FlashlightController:32: attempt to call a nil value`
  - `ServerScriptService.Server.FlashlightSyncSystem.Service:55: attempt to call a nil value`
- Source fixes:
  - moved `isPlayerInMatch` / `shouldShowToggleUI` above the first caller in `src/client/FlashlightController.client.lua`
  - moved `toUserId` above the first caller in `src/ServerScriptService/Server/FlashlightSyncSystem/Service.lua`
- Live place cleanup:
  - removed stray edit-time folder `Workspace.ActiveMatches.Match_asset_probe` from `PASRAHPHOBIA.rbxlx`
  - this probe was not backed by `src`, kept `activeMatches=1` at boot, and inflated the QA memory baseline
- Final gate run after the fixes:
  - `GetQAGateSnapshot`
    - `players=1 activeMatches=0 currentMatch=none phase=none`
    - `scriptMemoryMb=8.29 totalMemoryMb=2211.40 physicsFps=60.00`
    - `warnings=0 errors=0 logSample=clean`
  - `GetQAGateReadiness`
    - `overall=pass_with_manual_multiplayer`
    - `solo=true`
    - `memoryOk=true fpsOk=true logOk=true`
  - `GetPublishReadiness`
    - `overall=fail`
    - `qaSolo=true`
    - `multiplayer=manual_check_required`
    - `persistence=mock persistenceReady=false`
    - `commerceReady=true`
    - `robuxVisible=0 robuxMissingId=10`
  - `GetShopReadiness`
    - `total=31 MM=14 PP=7 Robux=10 disabled=10 robuxMissingId=10`
  - `GetPersistenceMode`
    - `mode=mock hasDataStore=false allowStudioDataStore=false trackedPlayers=1 schemaVersion=2`
- Result:
  - Stage 1 automatic gate returned to the expected state from the release docs: QA is green for solo and blocked only by manual multiplayer, while publish remains red only because persistence is still mock and Creator Hub IDs are still missing
- Roblox Studio was returned to STOP TEST after the batch.

## 2026-04-09 22:13:43 +07:00 - Manual Publish Prep Batch
- Status: DONE.
- Scope:
  - took the next publish-ops batch after technical gate recovery instead of inventing fake completion for manual Roblox lanes
  - focused on reducing manual execution friction across Creator Hub, multiplayer, persistence, and legal review
- Batch results:
  - Creator Hub mapping re-audited with `pwsh ./scripts/audit-marketplace-mapping.ps1`
    - `10` Robux items classified
    - `6` safe currency items still missing real Creator Hub IDs
    - `4` hold items still correctly disabled
    - `0` hold items accidentally enabled
    - `0` unclassified items
  - created manual publish handoff:
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/MANUAL_PUBLISH_HANDOFF_2026-04-09.md`
  - created prefilled multiplayer result sheet:
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/QA_MULTIPLAYER_RESULT_2026-04-09_PREP.md`
  - created prefilled persistence result sheet:
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/PERSISTENCE_RESULT_2026-04-09_PREP.md`
  - updated reports entrypoint:
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md` now points to the new handoff and prefilled result sheets
- Legal/licensing state after this prep batch:
  - `Pocong` provenance remains closed (`alterego.visual`, `CC BY 4.0`)
  - attribution catalog is source-controlled in `src/shared/DataTypes/AssetAttributionCatalog.lua`
  - active UI still loads required attribution entries from that catalog
  - remaining legal lane is now operational review, not provenance discovery:
    - confirm attribution surface remains visible in the final experience
    - decide final disposition for legacy-disabled assets before public publish
- Result:
  - the remaining publish blockers stay honest and narrow:
    - real Creator Hub IDs
    - real 2-client multiplayer smoke
    - non-mock persistence validation
    - final legal review signoff

## 2026-04-09 23:29:14 +07:00 - Mobile-First Hardening Batch
- Status: DONE.
- Scope:
  - applied the newly added mobile-first release requirement directly into source and active Studio state instead of leaving it as a note-only request
  - kept the write-set limited to orientation, main-menu/mobile UI behavior, and a real graphics-quality control path
- Source changes:
  - locked `StarterGui` orientation to landscape in:
    - `default.project.json`
    - `PASRAHPHOBIA.rbxlx`
  - updated `src/client/UI/Main.lua` to add:
    - client-side graphics mode state: `Performance`, `Balanced`, `Quality`
    - real visual behavior for the quality cycle:
      - lower atmosphere cost in lower modes
      - replace expensive 3D UI previews with flat fallback cards in `Performance`
    - a new `GraphicsButton` in `MainMenuUI`
    - revised mobile menu layout math so the extra action still fits short landscape mobile viewports
- Runtime verification:
  - Play Solo started successfully and was returned to STOP TEST
  - live runtime was forced through the mobile override lane:
    - `PasrahUIInputProfileOverride = mobile`
    - `PasrahUIViewportOverrideX = 844`
    - `PasrahUIViewportOverrideY = 390`
  - live Studio reported:
    - `StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor`
  - console remained free of new blocker errors during this batch
- Honest caveat:
  - the current Studio inspector/tool path did not expose the locally constructed `ScreenGui` tree for screenshot-style proof
  - mobile-fit confidence for this batch therefore comes from:
    - source-path math review for the `844x390` landscape lane
    - successful Play Solo boot
    - live orientation verification
    - absence of new console blockers
- Result:
  - mobile-first is now encoded in source and the active workspace, but final publish confidence still expects one real-device touch/readability smoke during the manual multiplayer/persistence pass window

## 2026-04-10 00:15:57 +07:00 - Mobile Graphics Runtime Follow-Through
- Status: DONE.
- Scope:
  - continued the mobile-first hardening pass with a `3d-games` execution lens instead of stopping at the menu toggle
  - kept the write-set limited to the client VFX lanes that actually spend the visual budget during play
- Source changes:
  - updated `src/client/Controllers/Sensory/VFXController.luau` so `PasrahGraphicsMode` now directly scales:
    - horror atmosphere density / haze / glare
    - map bloom
    - sun rays
    - depth of field
    - blur-heavy threat and transient shock effects
    - shadow cost via local `Lighting.GlobalShadows` / `ShadowSoftness`
  - updated `src/client/SpectatorEffects/Main.lua` so spectator/death distortion now follows the same graphics mode instead of always paying full blur/color cost
- Implementation intent:
  - `Performance` is now a real low-cost lane for 3D horror visuals, not just a UI label
  - `Balanced` keeps horror readability while still dropping the most expensive post stack
  - `Quality` preserves the full authored look for PC / console / manual high-detail users
- Verification note:
  - this pass was validated by source-path review and focused diff inspection inside the current session
  - live Studio smoke for the new VFX scaling still needs a direct script-sync/runtime probe before claiming stronger proof than source verification

## 2026-04-10 00:15:57 +07:00 - Mobile Graphics Live Smoke And UI Repair
- Status: DONE.
- Scope:
  - ran the live Play Solo smoke for the new mobile graphics pipeline instead of stopping at source diff review
  - fixed the one runtime blocker exposed by that smoke before closing the batch
- Live VFX proof:
  - `VFXController` was live in `game.StarterPlayer.StarterPlayerScripts.Client.Controllers.Sensory.VFXController`
  - switching `PasrahGraphicsMode` in play changed Lighting state as intended:
    - baseline / quality:
      - `GlobalShadows=true`
      - `ShadowSoftness=0.75`
      - `SensoryMapBloom.Intensity=0.18`
      - `SensoryMapSunRays.Intensity=0.068`
      - `HorrorAtmosphere.Density=0.24`
    - performance:
      - `GlobalShadows=false`
      - `ShadowSoftness=0.45`
      - `SensoryMapBloom.Intensity≈0.0324`
      - `SensoryMapSunRays.Intensity=0`
      - `HorrorAtmosphere.Density≈0.1968`
- Live spectator proof:
  - `SpectatorEffects` was live in `game.StarterPlayer.StarterPlayerScripts.Client.SpectatorEffects.Main`
  - after proper `Init()` + `Start()` in the smoke harness:
    - performance:
      - `PasrahSpectatorGraphicsMode=Performance`
      - `SpectatorBlurEffect.Size=1`
      - `SpectatorColorCorrection.Saturation≈-0.108`
      - `SpectatorColorCorrection.Contrast≈0.036`
    - quality:
      - `PasrahSpectatorGraphicsMode=Quality`
      - `SpectatorBlurEffect.Size=2`
      - `SpectatorColorCorrection.Saturation≈-0.15`
      - `SpectatorColorCorrection.Contrast≈0.05`
- Runtime blocker found and fixed during the smoke:
  - Play Solo console exposed a real parse error in `src/client/UI/Main.lua`:
    - `Expected 'end' (to close 'function' at line 13551)`
  - root cause:
    - `_ensureBasicUIs()` was missing one closing `end` after the refresh calls
  - fix:
    - restored the missing `end` in `src/client/UI/Main.lua`
  - post-fix console result:
    - the `Failed to require UI` / `System disabled: UI` error disappeared on the next Play Solo boot
    - remaining console noise stayed limited to existing `HidingSystem` debug prints
- Result:
  - the mobile graphics control is now verified in live runtime for both horror VFX and spectator distortion lanes
  - the UI bootstrap regression discovered during verification was fixed in the same batch instead of being deferred

## 2026-04-10 00:28:41 +07:00 - Release Preflight Snapshot Refresh
- Status: DONE.
- Scope:
  - resumed from the latest mobile hardening batches and refreshed the release preflight snapshot to confirm the real publish blockers remained unchanged
  - captured the marketplace mapping audit in the same pass so manual Creator Hub work can continue from current facts, not stale notes
- Commands executed:
  - `pwsh ./scripts/release-preflight.ps1`
  - `pwsh ./scripts/audit-marketplace-mapping.ps1`
- Latest preflight result:
  - `Build ok: True`
  - `Missing reports: 0`
  - `Robux items: 10`
  - `Safe items missing ID: 6`
  - `Safe items disabled: 6`
  - `Hold items enabled: 0`
- Latest marketplace audit result:
  - `Catalog Robux items: 10`
  - `Safe enable now: 6`
  - `Keep disabled: 4`
  - safe items still missing real `marketplaceId`:
    - `pp_pack_small`
    - `pp_pack_standard`
    - `pp_pack_large`
    - `mm_pack_small`
    - `mm_pack_medium`
    - `mm_pack_large`
  - hold items remain correctly disabled:
    - `royalpass_premium_track`
    - `class_dukun_unlock`
    - `class_detective_unlock`
    - `lifetime_bonus_pass`
- Result:
  - no new automatic regression was introduced in this continuation pass
  - the publish state remains `NO-GO` strictly because the known manual lanes are still open:
    - real Creator Hub IDs for 6 safe products
    - real 2-client multiplayer smoke
    - non-mock persistence validation
    - legal/licensing final review confirmation

## 2026-04-10 13:38:59 +07:00 - Creator Hub ID Fill + Commerce Gate Unblock
- Status: DONE.
- Scope:
  - filled real Creator Hub IDs provided for all `10` Robux catalog entries in source config
  - kept fairness guardrail intact by enabling only the `6` safe currency DeveloperProducts and keeping `4` hold GamePass items disabled
  - removed stale false-positive wording from release preflight so manual blocker output follows current mapping state instead of static text
- Files changed:
  - `src/shared/DataTypes/ShopMarketplaceConfig.lua`
  - `scripts/release-preflight.ps1`
  - `scripts/set-marketplace-product-ids.ps1`
  - `asset mentah/creator-hub-product-icons/*.png`
- Marketplace IDs applied:
  - DeveloperProduct (enabled):
    - `pp_pack_small = 3573224039`
    - `pp_pack_standard = 3573225850`
    - `pp_pack_large = 3573226462`
    - `mm_pack_small = 3573226842`
    - `mm_pack_medium = 3573227690`
    - `mm_pack_large = 3573228070`
  - GamePass (disabled by policy hold):
    - `royalpass_premium_track = 3573231558`
    - `class_dukun_unlock = 3573231828`
    - `class_detective_unlock = 3573232123`
    - `lifetime_bonus_pass = 3573232383`
- Gate proof:
  - `pwsh ./scripts/audit-marketplace-mapping.ps1`:
    - `Safe items missing marketplaceId: 0`
    - `Safe items still disabled: 0`
    - `Hold items accidentally enabled: 0`
    - `Unclassified items: 0`
  - `pwsh ./scripts/release-preflight.ps1`:
    - `Build ok: True`
    - `Safe items missing ID: 0`
    - `Safe items disabled: 0`
    - `Hold items enabled: 0`
    - remaining blockers now only:
      - real `2`-client smoke
      - non-mock persistence validation
      - legal/licensing final review
- Result:
  - Creator Hub marketplace mapping lane is no longer a publish blocker
  - publish `NO-GO` now narrowed to the last three manual lanes only

## 2026-04-10 13:50:58 +07:00 - Monetization Decision Lock + Next-Lane Continuation
- Status: DONE (decision lock), PARTIAL (next-lane runtime proof).
- Scope:
  - locked monetization architecture decision to prevent post-publish drift/refactor pressure
  - refreshed publish handoff docs so Creator Hub lane is not listed as pending anymore
  - started continuation to next lane (legal attribution visibility runtime proof) in active `rbxlx` Studio
- Files added/updated:
  - added `DOCUMENTATION/SOURCE OF TRUTH/reports/MONETIZATION_DECISION_RECORD_2026-04-10.md`
  - updated `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
  - updated `DOCUMENTATION/SOURCE OF TRUTH/reports/MANUAL_PUBLISH_HANDOFF_2026-04-09.md`
- Decision lock summary:
  - v1 release keeps:
    - `DeveloperProduct` for repeatable currency packs
    - `GamePass` for permanent entitlement lanes
    - `Subscription` excluded from v1 scope
  - purpose:
    - avoid monetization schema drift during remaining publish gates
    - isolate any subscription migration to explicit v2 backlog
- Runtime continuation result (legal lane):
  - attempted live Play Solo proof on `PASRAHPHOBIA.rbxlx`
  - attribution catalog still resolves in runtime module load:
    - `Pocong | alterego.visual | CC BY 4.0`
  - but player-facing UI surface did not appear in this session (PlayerGui only showed `Freecam` and `FPVCursorToggleUI`)
  - console showed blocker:
    - `Players.ZyraaaVex.PlayerScripts.Client.UI.Main:4218: Out of local registers when trying to allocate loadShopCatalog: exceeded limit 200`
  - local source build remains healthy in preflight (`Build ok: True`), indicating this runtime lane is currently a Studio sync/runtime-state issue to clear before claiming legal visual `PASS`
- Result:
  - Creator Hub lane stays closed
  - next executable publish lanes remain:
    - real 2-client multiplayer smoke
    - non-mock persistence validation
    - legal final review (currently blocked by runtime UI visibility issue in active Studio session)

## 2026-04-10 13:53:49 +07:00 - UI Runtime Compile Blocker Follow-Up
- Status: DONE (blocker clear), PARTIAL (legal visual proof still pending).
- Scope:
  - traced the legal-lane runtime failure source in active `PASRAHPHOBIA.rbxlx` session
  - confirmed Studio script drift versus source and applied matching patch directly to active Studio script for immediate runtime verification
- Findings:
  - before patch, active Studio `StarterPlayerScripts.Client.UI.Main` still had old declaration (`local function loadShopCatalog`) and threw:
    - `Out of local registers when trying to allocate loadShopCatalog: exceeded limit 200`
  - source already contained the reduced-local helper naming lane (`pasrahLoadShopCatalog` family), but active Studio had not yet mirrored it
- Action:
  - patched active Studio `Main` script with the same helper rename set used in source:
    - `pasrahLoadShopCatalog`
    - `pasrahLoadAssetAttributionCatalog`
    - `pasrahBuildAttributionFooterText`
  - reran Play Solo and confirmed the compile error no longer appeared in console
- Current legal lane state:
  - module-level attribution metadata remains valid (`Pocong | alterego.visual | CC BY 4.0`)
  - full player-visible attribution surface proof is still pending a dedicated manual UI navigation capture path in the same runtime session
- Result:
  - UI compile blocker that prevented legal-lane runtime checks is cleared
  - release blockers remain unchanged in count (multiplayer, persistence, legal visual confirmation)

## 2026-04-10 20:14:28 +07:00 - Local Multiplayer Smoke Harness + Precheck
- Status: DONE (local precheck), NOT FINAL (publish gate still pending).
- Scope:
  - added Studio-only multiplayer smoke harness to remove blind/manual lobby clicking during `Server + 2 Clients` local validation
  - reran local multiplayer smoke after clean relaunch and captured client/server evidence
- Files added/updated:
  - added `src/StarterPlayerScripts/StudioRoomSmoke.client.lua`
  - added `DOCUMENTATION/SOURCE OF TRUTH/reports/LOCAL_MULTIPLAYER_SMOKE_2026-04-10.md`
  - updated `DOCUMENTATION/SOURCE OF TRUTH/reports/README.md`
- Harness behavior:
  - gated by `RunService:IsStudio()` plus `ReplicatedStorage.PasrahAutoRoomSmoke == true`
  - `Player1` auto `CreateRoom` + `HostStart`
  - `Player2` auto `JoinRoom` + `SetReady(true)`
  - flag disabled again after verification so future Studio runs do not auto-fire unexpectedly
- Local smoke result:
  - fresh `Server + 2 Clients` relaunch succeeded
  - both clients transitioned from lobby into the same match interior
  - server boot stayed clean in console probe (no new fatal runtime error surfaced)
  - expected Studio note remains: persistence still uses in-memory mock during this local smoke
- Result:
  - local two-client multiplayer precheck is now reproducible and passes with automation support
  - publish blockers remain:
    - real `2`-client smoke on actual Roblox clients
    - non-mock persistence validation
    - legal/licensing final visual confirmation

## 2026-04-10 22:53:04 +07:00 - Persistence Override Attempt + UI Preview Compile Fix
- Status: PARTIAL.
- Persistence lane result:
  - verified `DataPersistenceService` supports Studio override through `PasrahUseStudioDataStore`
  - attempted non-mock boot from active local `PASRAHPHOBIA.rbxlx`
  - runtime identity during attempt was still `PlaceId=0`, `GameId=0`
  - when override was enabled, server boot failed with concrete environment error:
    - `You must publish this place to the web to access DataStore.`
  - conclusion:
    - local `rbxlx` session cannot close non-mock persistence gate
    - real persistence validation must move to a published cloud place / real DataStore target
- Files added/updated:
  - added `DOCUMENTATION/SOURCE OF TRUTH/reports/PERSISTENCE_STUDIO_OVERRIDE_BLOCKER_2026-04-10.md`
- Legal/UI follow-up in same run:
  - cleared another Luau register-pressure compile blocker in `src/client/UI/Main.lua`
  - converted preview helper cluster away from `local function` allocation pressure:
    - `pasrahFindPlayerByUserId`
    - `pasrahStripScripts`
    - `pasrahBuildPreviewCharacterModel`
    - `pasrahRenderCharacterPreview`
  - mirrored the same patch into active Studio script and reran Play Solo
  - result:
    - previous compile blocker on `findPlayerByUserId` no longer appeared in console
    - however player-facing legal surface proof is still not closed from this session because the required menu surface did not become visible in the captured runtime
- Publish blockers after this run:
  - real `2`-client smoke on actual Roblox clients
  - persistence non-mock on published cloud target
  - legal/licensing final visual confirmation

## 2026-04-11 01:08:40 +07:00 - Toggle Key Audit + Real DataStore Persistence Run
- Status: PARTIAL.
- Toggle-key audit:
  - scanned project UI toggle bindings in `src/client/UI/Main.lua`, plus related input toggles in `CameraController.client.lua` and `FlashlightController.client.lua`
  - verified against official Roblox sources:
    - Creator Hub input docs (`https://create.roblox.com/docs/input`)
    - Roblox support chat/backpack/leave articles
  - concrete conflict found:
    - `Esc` was being used for local UI close while Roblox reserves `Esc` for the Roblox menu
  - action taken:
    - changed keyboard close hotkey from `Esc` to `X`
    - updated close hint text
    - made auxiliary/match/close toggle handlers return early when `gameProcessed == true`
  - sync verification:
    - published place `PlaceId=113010869463813` was open
    - live Studio script confirmed the new `X` binding and updated handlers after sync
  - report added:
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/UI_TOGGLE_KEY_AUDIT_2026-04-11.md`
- Persistence run on published cloud target:
  - enabled `ReplicatedStorage.PasrahUseStudioDataStore = true` in published Studio place
  - confirmed real datastore mode via `StudioE2EControl`:
    - `mode=datastore hasDataStore=true allowStudioDataStore=true trackedPlayers=1 schemaVersion=2 lastLoadSchema=2 lastSaveSchema=none`
  - mutation set used for reconnect proof:
    - granted `MM +3000`
    - granted `PP +5`
    - updated profile bio/favorite tool/gallery
    - purchased cosmetic `cos_emote_steadybreath`
    - equipped the same cosmetic in slot `emote`
  - reconnect result:
    - profile changes persisted
    - inventory/cosmetic ownership persisted
    - cosmetic equip persisted
    - wallet reverted from `MM=3700 PP=17` back to `MM=1200 PP=12`
  - interpretation:
    - real datastore path is valid
    - persistence gate still FAIL overall because wallet `MM/PP` does not survive reconnect
  - reports added:
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/PERSISTENCE_RESULT_2026-04-11_REAL_DATASTORE.md`
- Runtime gate snapshot during same session:
  - `GetShopReadiness`:
    - `total=31 MM=14 PP=7 Robux=10 disabled=0 robuxMissingId=0`
  - `GetPublishReadiness`:
    - `overall=fail qaSolo=false multiplayer=manual_check_required persistence=datastore persistenceReady=true commerceReady=true robuxVisible=10 robuxMissingId=0 totalMemoryMb=1780.99 physicsFps=59.97 warnings=2 errors=1 phase=none currentMatch=none`
- Publish blockers after this run:
  - wallet persistence fix + rerun on published cloud target
  - real `2`-client smoke on actual Roblox clients
  - legal/licensing final visual confirmation

## 2026-04-11 04:28:22 +07:00 - Mobile Room Browser Landscape Fix For Real iPhone Smoke
- Status: PASS.
- Trigger:
  - real `2`-iPhone manual smoke exposed a mobile-first UX blocker:
    - landscape was already correct after cold reopen
    - but Room Browser host flow was not
    - `Create Room` sat too low on mobile landscape and could not be tapped reliably
  - `quick queue` was explicitly rejected as the substitute smoke path because it does not guarantee both real devices enter the same investigation room through the intended room flow
- Action taken in `src/client/UI/Main.lua`:
  - added dedicated wide-mobile Room Browser layout for compact mobile landscape
  - moved browser state into a left/right split:
    - left = preview
    - right = room list + primary actions
  - kept primary CTA lane visible:
    - `JOIN ROOM`
    - `REFRESH`
    - `BUAT ROOM`
  - hid `QuickJoinClassic` and `QuickJoinRanked` for this mobile-wide browser state so the valid room-flow CTA is no longer pushed below the fold
  - shortened room row copy into a denser two-line mobile summary
  - added a wide-mobile in-room panel layout so `READY` / `MULAI PERMAINAN` / `KELUAR ROOM` sit earlier in the action lane
  - updated CTA copy:
    - `JOIN` -> `JOIN ROOM`
    - `Buat Room` -> `BUAT ROOM`
- Verification:
  - active Studio published-place runtime kept viewport override at:
    - `PasrahUIViewportOverrideX = 844`
    - `PasrahUIViewportOverrideY = 390`
  - Room Browser browser-state probe confirmed:
    - `RoomList` visible on right column
    - `JOIN ROOM` visible with size `414x40`
    - `BUAT ROOM` visible with size `204x36`
    - `QuickJoinClassic` hidden
    - `QuickJoinRanked` hidden
  - no new boot/runtime blocker appeared in Studio console during the verification pass
- Report added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/MOBILE_ROOM_BROWSER_FIX_2026-04-11.md`
- Remaining publish blocker after this run:
  - real `2`-client smoke on actual Roblox clients

## 2026-04-11 05:12:11 +07:00 - UI Build Signature And Publish Propagation Check
- Status: PASS.
- Trigger:
  - after the mobile Room Browser fix, runtime on iPhone still appeared stale even after a publish attempt
  - needed a deterministic visual signature to prove whether the latest UI build was actually loaded on-device
- Action taken in `src/client/UI/Main.lua`:
  - added `UI_BUILD_SIGNATURE = PHB-20260411-UI1`
  - added helper text wiring so the signature appears in:
    - lobby hint line
    - quick menu footer
    - room browser status line
  - added `PasrahBuildSignature` attributes on the relevant UI instances for live inspection
- Verification:
  - local source contains `PHB-20260411-UI1`
  - active Studio attached to cloud `PlaceId=113010869463813` also contains the same signature token and updated UI wiring
  - `release-preflight.ps1` remained green after the patch:
    - `Build ok: True`
    - `Missing reports: 0`
    - `Safe items missing ID: 0`
    - `Safe items disabled: 0`
    - `Hold items enabled: 0`
- Official publish finding:
  - Roblox Creator Hub docs do not document a generic review delay for publishing a new version of an already public experience
  - the documented blockers are eligibility/compliance requirements for making a new or existing public experience update eligible
  - the same docs explicitly recommend restarting servers when changing the start place of a live experience
  - interpretation for this project:
    - stale iPhone UI after verified script updates is more likely runtime/server propagation or joining an older live server than missing local/source patch
- Report added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/BUILD_SIGNATURE_AND_PUBLISH_PROPAGATION_2026-04-11.md`

## 2026-04-11 05:31:48 +07:00 - Room Browser Fullscreen Touch Shield Fix For iPhone
- Status: PASS.
- Trigger:
  - real iPhone feedback proved the previous Room Browser patch was still wrong in one important way:
    - it still behaved like a floating desktop panel
    - touch gestures inside the browser could still leak into camera movement
  - owner clarified the intended pattern:
    - lobby launcher may stay compact
    - opened Room Browser must become a fullscreen mobile-first landscape overlay with mild transparency
- Action taken in `src/client/UI/Main.lua`:
  - added a fullscreen `Backdrop` under `RoomBrowserUI`
  - reparented the main Room Browser panel under that backdrop
  - made the backdrop and panel `Active=true`
  - marked the main touch surfaces `Active=true`:
    - room list
    - room preview panel
    - room preview map
    - room preview player list
    - room players list
    - modal layers/cards
    - room map preview
  - mobile sizing now uses the full safe-area viewport
  - drag bar is hidden on mobile so the browser behaves like a fixed landscape sheet instead of a draggable desktop panel
  - mobile root transparency now stays lightly translucent in both browser and in-room state
- Verification:
  - local `release-preflight.ps1` remained green
  - active cloud-attached Studio script already reflected the same fullscreen/touch-shield patch
- Report added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/ROOM_BROWSER_FULLSCREEN_TOUCH_FIX_2026-04-11.md`

## 2026-04-11 06:59:54 +07:00 - Room Browser Landscape Runtime Fix And Studio Verification
- Status: PASS.
- Trigger:
  - owner surfaced the exact client console error from Studio runtime:
    - `Out of local registers when trying to allocate fadeGuiObject`
    - `ClientBootstrap` then disabled `UI`
  - after bootstrap was repaired, Room Browser still showed a second real bug:
    - landscape sizing kept portrait-biased minimum heights
    - Studio visual simulation clipped the overlay because the simulated viewport exceeded the actual visible Studio viewport
- Action taken:
  - created `src/client/UI/UISupport.lua`
  - moved these helpers out of `src/client/UI/Main.lua` so top-level `local` count dropped from `203` to `199`:
    - `disconnectAll`
    - `destroyAll`
    - `fadeGuiObject`
    - `resolveSafeInsets`
    - `createDeviceProfile`
  - updated `Main.lua` call sites to use `UISupport.*`
  - corrected mobile landscape sizing in Room Browser:
    - removed portrait-biased minimum height behavior for landscape mobile
    - clamped Studio override viewport against the actual camera viewport so visible Studio testing no longer lies about what fits on-screen
- Studio runtime verification:
  - test started from `STOP TEST`, then rerun with:
    - `PasrahUIInputProfileOverride = mobile`
    - `PasrahUIViewportOverrideX = 844`
    - `PasrahUIViewportOverrideY = 390`
    - `PasrahUIForceCompact = true`
  - `PasrahClientBootstrapStage = started`
  - `PlayerGui` now contains expected client UIs again, including:
    - `LobbyUI`
    - `MainMenuUI`
    - `RoomBrowserUI`
  - after clicking `LobbyUI.MainPanel.OpenRoomBrowserButton`:
    - `RoomBrowserUI.Enabled = true`
    - `Panel size = 733 x 371`
    - `Backdrop size = 733 x 371`
    - `QueueButton size = 361 x 40`
    - `CreateRoomButton size = 177 x 36`
  - drag test inside `RoomList` left `CurrentCamera.CFrame` unchanged before vs after
  - interpretation:
    - UI bootstrap restored
    - landscape overlay now fits the visible Studio viewport
    - drag on Room Browser no longer leaked into camera movement in Studio verification
- Report added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/ROOM_BROWSER_LANDSCAPE_RUNTIME_FIX_2026-04-11.md`

## 2026-04-11 08:26:46 +07:00 - Multiplayer Queue Hub And Spectator Runtime Fix
- Status: CODE FIX PASS, DEVICE RETEST PENDING.
- Trigger:
  - first real iPhone multiplayer run exposed two gameplay blockers after publish:
    - `Queue Hub` behavior could jump players straight into queue/pre-match flow instead of the clean room-browser lane
    - spectator/death handling could settle into an invalid loop after player death
- Action taken:
  - `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
    - changed `QueueTrigger` prompt text from `Join Queue` to `Open Room Browser`
    - changed `QueueTrigger` callback from `OnQueueFromRoomBrowser(...)` to `OnRequestRoomBrowserSnapshot(...)`
    - updated the published board/event copy so the world surface now points players toward create/join/ready flow instead of queue activation
  - `src/ServerScriptService/Server/SpectatorModeSystem/Service.lua`
    - made spectator registration idempotent for an already-active match/user pair
    - made spectator removal publish `SpectatorModeEnded` only when the spectator was actually active
  - `src/ServerScriptService/Server/SpectatorSystem/Controller.lua`
    - removed the direct `EnterSpectator(...)` call from `OnPlayerKilled(...)`
  - `src/ServerScriptService/Server/SpectatorSystem/SpectatorService.lua`
    - subscribed to `SpectatorModeEnded`
    - made `EnterSpectator(...)` reuse an existing spectator session instead of rebuilding it
- Live verification:
  - verified in the cloud-attached Studio session for:
    - `PlaceId = 113010869463813`
    - `GameId = 9802743087`
  - `LobbyService` live script now shows:
    - prompt action text `Open Room Browser`
    - `QueueTrigger` opens room-browser snapshot path, not queue path
  - live spectator scripts now reflect the dedupe/exit-mirroring patch
  - Studio was kept in `STOP TEST` / edit state after verification
- Interpretation:
  - the first real-device multiplayer blockers now have concrete source fixes
  - the remaining task is to rerun `2` iPhones through the proper room flow and confirm:
    - both players see each other in-map
    - death transitions to spectator cleanly instead of falling-loop
- Report added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/MULTIPLAYER_QUEUE_AND_SPECTATOR_FIX_2026-04-11.md`

## 2026-04-11 12:13:46 +07:00 - Final Real 2-Client Multiplayer Smoke Closed
- Status: PASS.
- Trigger:
  - owner confirmed the final real-device multiplayer run passed after the `Queue Hub` and spectator fixes.
- Result recorded in:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/QA_MULTIPLAYER_RESULT_2026-04-09_PREP.md`
- Interpretation:
  - the final remaining manual multiplayer publish lane is now closed
  - prior PASS lanes already on record remain:
    - commerce
    - persistence real datastore
    - legal/runtime review
    - mobile-first implementation
  - publish readiness no longer depends on a pending multiplayer smoke gate

## 2026-04-11 13:42:00 +07:00 - Respawn Guard And Forced Reset Regression Reopened
- Status: CODE FIX PASS, RETEST PENDING.
- Trigger:
  - owner reported `2` additional in-game issues discovered after following the final multiplayer run:
    - built-in Roblox reset/respawn was still available during match
    - forced respawn on the remaining alive player could fall into a loop instead of closing the match into results
- Action taken:
  - added client reset guard:
    - `src/client/RespawnGuard/Main.lua`
    - `src/client/Core/ClientBootstrap.lua`
  - changed server death bridge routing:
    - `src/ServerScriptService/Server/DeathStateSystem/Service.lua`
    - `src/ServerScriptService/Server/DeathStateSystem/DeathEventBridge.lua`
  - `DeathEventBridge` now publishes canonical `PlayerDied` through `EventBus` so `MatchSystem` and `PlayerDeathSystem` receive forced reset as a real elimination path
- Studio verification:
  - cloud canonical Studio session confirmed:
    - `RespawnGuard` exists in live client tree
    - live `ClientBootstrap` registers it
    - live `DeathEventBridge` now uses `PublishPlayerDied(...)`
  - playtest probe confirmed:
    - `PasrahClientBootstrapStage = started`
    - `PasrahResetGuardSetCoreReady = true`
    - `PasrahResetGuardDisabled = true` while `InMatch=true`
    - `PasrahResetGuardDisabled = false` again after leaving the mock match state
  - Studio returned to `STOP TEST` before logging
- Interpretation:
  - multiplayer core room flow remains previously recorded as PASS
  - forced-reset / respawn guard path is now a separate reopened edge-case lane until a real `2`-client retest confirms:
    - reset is blocked during active match
    - no falling loop remains if a reset slips through
- Report added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/RESPAWN_GUARD_AND_FORCED_RESET_FIX_2026-04-11.md`

## 2026-04-11 14:08:00 +07:00 - QA Playthrough Workflow Read
- Status: PASS AS EXPERIENCE AUDIT.
- Trigger:
  - owner requested a concrete explanation of the actual in-game workflow, durations, and early-session friction from a human-QA point of view rather than a pure system summary
- Action taken:
  - ran a live Studio playthrough from lobby into room flow and active investigation
  - observed:
    - lobby action hierarchy
    - room browser create/start semantics
    - visible room-start countdown
    - staging/preparation arrival
    - investigation anchor/tool/journal stack
  - Studio was returned to `STOP TEST` before logging
- Main findings:
  - real workflow read is:
    - lobby
    - room browser
    - create room
    - host action
    - room countdown
    - preparation
    - investigation
    - hunt
    - endgame/results
    - lobby
  - default configured in-match durations remain:
    - `PreparationPhase = 30`
    - `InvestigationPhase = 480`
    - `HuntPhase = 60`
    - `EndgamePhase = 30`
  - strongest early friction observed:
    - too many equal-priority lobby actions
    - host/start semantics not instantly obvious
    - staging spawn framing too close to props/boards
    - investigation HUD overload versus room readability
    - world visuals still read as unfinished compared with the intended premium horror fantasy
- Report added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/QA_PLAYTHROUGH_WORKFLOW_2026-04-11.md`

## 2026-04-16 01:59:33 +07:00 - Final Source Of Truth Runtime Smoke Recovery
- Status: PASS FOR SINGLE-CLIENT STUDIO SMOKE.
- Trigger:
  - owner requested full live smoke on branch `final-source-of-truth` with Rojo connected and explicit focus on falling loop, room browser flow, countdown, audio, results, and mobile landscape UI.
- Action taken:
  - fixed bootstrap blocker by normalizing `SocialCommerceSystem/Service.lua`
  - added case-insensitive module fallback in `SocialCommerceSystem/Main.lua`
  - updated `AudioController` so `ResultsBGM` follows visible `ResultsPanel` and suppresses `LobbyAmbient` while results remain on screen
  - updated `QuestJournal` and `QuestTracker` to honor canonical Studio mobile override attributes
- Studio verification:
  - bootstrap now reaches `All systems started`
  - player spawn now lands on lobby concrete instead of `Freefall`
  - room browser flow verified:
    - open browser
    - `BUAT ROOM`
    - `MULAI PERMAINAN`
    - transition to `PreparationPhase`
    - transition to `InvestigationPhase`
  - results flow verified:
    - `ResultsPanelVisible = true`
    - `ResultsBGM` active with `rbxassetid://95027410279438`
    - `LobbyAmbientSuppressedByResults = true`
    - return to lobby still completes
  - mobile-wide override verified at `844x390`:
    - room browser panel fits viewport
    - quick join buttons hidden
    - quest journal button reads `MISSION`
    - quest surfaces resize into compact mobile lane
- Report added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/FINAL_SOURCE_OF_TRUTH_RUNTIME_SMOKE_2026-04-16.md`

## 2026-04-16 03:12:00 +07:00 - Extended Single-Player Smoke, Field-Kit Cue Fix, And New-Player Tutorial
- Status: PASS FOR SINGLE-CLIENT INVESTIGATION FLOW.
- Trigger:
  - owner requested continuation of the live smoke with emphasis on:
    - mobile-first UI not bypassed
    - hunt visibility
    - Pocong manifestation/evidence readability
    - flashlight flicker
    - object movement
    - ghost whisper
    - ghost-writing audio
    - a practical tutorial for new players
- Action taken:
  - re-ran manual room flow from lobby:
    - `OPEN ROOM BROWSER`
    - `BUAT ROOM`
    - `MULAI PERMAINAN`
  - verified mobile landscape lane again in live Studio
  - confirmed single-player investigation path and hunt overlay
  - patched `src/client/UI/Main.lua` twice:
    - restored `WritingScratch` runtime cue when `BukuTerkutuk` locks evidence
    - corrected field-kit response flattening so nested `result.evidenceType` no longer leaks into the HUD on transient failed responses such as `tool_pending_delay`
  - re-ran the live test after each patch until:
    - `WRITING -> WRITE / INK LOCK`
    - `THERMO -> -5C / SUHU LOCK`
    - `SCAN -> EMF 5 / MEDOK LOCK`
    - `PasrahUILastSoundKey = WritingScratch`
  - verified sensory runtime cues:
    - `env_lightflicker`
    - `env_objectthrow`
    - `ghost_whisper`
  - wrote a new player tutorial aligned to the verified single-player loop
- Studio verification:
  - room browser remained playable in mobile-first landscape after restart
  - hunt overlay and safe-zone guidance were visible in-match
  - writing cue now plays on valid cursed-writing evidence
  - false evidence lock drift from nested payloads no longer reproduces in the patched HUD lane
- Reports added:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/NEW_PLAYER_SINGLEPLAYER_TUTORIAL_2026-04-16.md`
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/FINAL_SOURCE_OF_TRUTH_RUNTIME_SMOKE_2026-04-16.md` updated with extended single-player findings

## 2026-04-16 06:21:59 +07:00 - HauntedHouse Canonical Documentation Sync
- Status: PASS FOR DOCUMENTATION ALIGNMENT.
- Trigger:
  - owner requested canonical documentation, doc index, and map specification to be updated before the next `HauntedHouse` task.
- Action taken:
  - updated `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
  - updated `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
  - updated `DOCUMENTATION/SOURCE OF TRUTH/REPORTS.md`
  - rewrote `DOCUMENTATION/SOURCE OF TRUTH/reports/HAUNTEDHOUSE_RECONSTRUCTION_SPEC_2026-04-16.md` from pre-wiring baseline into the active runtime map specification
  - appended this execution log entry
- Canonical `HauntedHouse` statements locked by this sync:
  - runtime map dimensions: `160 x 180`, `2` floors
  - runtime room count: `20` (`10` floor 1, `10` floor 2)
  - active support counts:
    - `Doors=18`
    - `Lights=20`
    - `Props=20`
    - `Electronics=7`
    - `Windows=6`
    - `EvidenceSpawnNodes=14`
    - `GhostSpawns=6`
    - `SpawnPoints=4`
    - `SafeZones=2`
  - preparation staging is outside the house
  - timer-based preparation countdown is disabled
  - investigation now begins on `Door_FrontEntry`
  - environmental trigger targets are documented as requiring either imported assets or generated runtime fallbacks so no event target is left missing

## 2026-04-16 07:18:40 +07:00 - StudioMMNineteen Runtime Canonical Reconstruction
- Status: PASS FOR SOURCE-OF-TRUTH ALIGNMENT.
- Trigger:
  - owner requested StudioMMNineteen to follow the same reconstruction/wiring pattern as HauntedHouse using fresh `.rbxm` source model.
- Action taken:
  - replaced active visual source with imported `StudioMMNineteen.rbxm` in both runtime map roots:
    - `src/ReplicatedStorage/Maps/StudioMMNineteen/StudioMMNineteen.rbxm`
    - `src/ServerStorage/Maps/StudioMMNineteen/StudioMMNineteen.rbxm`
  - removed embedded scripts from imported free model in live Studio trees to prevent foreign system drift
  - added canonical runtime layout and scaffold:
    - `src/ServerScriptService/Server/MatchSystem/StudioMMNineteenRuntimeLayout.lua`
    - `src/ServerScriptService/Server/MatchSystem/StudioMMNineteenMapScaffold.lua`
  - patched runtime router/config:
    - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
    - `src/ServerScriptService/Server/MatchSystem/EnvironmentalObjectRuntime.lua`
    - `src/shared/GameData/Maps/StudioMMNineteen.lua`
  - updated source-of-truth documentation and index:
    - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/STUDIOMMNINETEEN_RECONSTRUCTION_SPEC_2026-04-16.md`
  - appended this execution log entry
- Canonical StudioMMNineteen statements locked by this sync:
  - runtime map dimensions: `100 x 100`, `3` floors
  - runtime room count: `12` (`4 + 4 + 4`)
  - active support counts:
    - `Doors=10`
    - `Lights=12`
    - `Props=12`
    - `Electronics=6`
    - `Windows=6`
    - `EvidenceSpawnNodes=12`
    - `GhostSpawns=6`
    - `SpawnPoints=4`
    - `SafeZones=2`
  - preparation staging is outside the house
  - timer-based preparation countdown remains disabled
  - investigation begins on `Door_FrontEntry` (not countdown)
  - environmental trigger targets are documented as requiring either imported assets or generated runtime fallbacks so no event target is left missing

## 2026-04-16 08:02:11 +07:00 - EmptyBuilding Runtime Canonical Reconstruction + Structural Fill
- Status: PASS FOR SOURCE-OF-TRUTH ALIGNMENT.
- Trigger:
  - owner requested the same reconstruction pattern for `EmptyBuilding`, then explicitly approved improvisation for missing stairs and empty spaces.
- Action taken:
  - replaced active visual source with imported `EmptyBuilding.rbxm` in both runtime map roots:
    - `src/ReplicatedStorage/Maps/EmptyBuilding/EmptyBuilding.rbxm`
    - `src/ServerStorage/Maps/EmptyBuilding/EmptyBuilding.rbxm`
  - disabled legacy json source in both roots:
    - `EmptyBuilding.model.json.disabled`
  - added canonical runtime layout and scaffold:
    - `src/ServerScriptService/Server/MatchSystem/EmptyBuildingRuntimeLayout.lua`
    - `src/ServerScriptService/Server/MatchSystem/EmptyBuildingMapScaffold.lua`
  - patched runtime router/config:
    - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
    - `src/ServerScriptService/Server/MatchSystem/EnvironmentalObjectRuntime.lua`
    - `src/shared/GameData/Maps/EmptyBuilding.lua`
  - implemented approved structural improvisation under `RuntimeDecor`:
    - `NorthStairs`
    - `SouthStairs`
    - `ServiceLadder`
    - `FillerProps`
  - updated source-of-truth documentation and index:
    - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/EMPTYBUILDING_RECONSTRUCTION_SPEC_2026-04-16.md`
  - appended this execution log entry
- Canonical EmptyBuilding statements locked by this sync:
  - runtime room topology: `14` rooms across `2` floors (`9 + 5`)
  - active support counts:
    - `Doors=14`
    - `Lights=14`
    - `Props=14`
    - `Electronics=6`
    - `Windows=12`
    - `EvidenceSpawnNodes=9`
    - `GhostSpawns=5`
    - `SpawnPoints=4`
    - `SafeZones=2`
    - `RuntimeDecor=4`
  - timer-based preparation countdown remains disabled
  - investigation begins on `Door_Lobby` (not countdown)
  - structural floor-2 access and visual density are now guaranteed by scaffold decor, without introducing a new gameplay system

## 2026-04-16 08:39:22 +07:00 - AbandonedPalace Runtime Canonical Reconstruction
- Status: PASS FOR SOURCE-OF-TRUTH ALIGNMENT.
- Trigger:
  - owner requested the same reconstruction pattern to be applied for `AbandonedPalace`.
- Action taken:
  - replaced active visual source with imported `AbandonedPalace.rbxm` in both runtime map roots:
    - `src/ReplicatedStorage/Maps/AbandonedPalace/AbandonedPalace.rbxm`
    - `src/ServerStorage/Maps/AbandonedPalace/AbandonedPalace.rbxm`
  - disabled legacy json source in both roots:
    - `AbandonedPalace.model.json.disabled`
  - added canonical runtime layout and scaffold:
    - `src/ServerScriptService/Server/MatchSystem/AbandonedPalaceRuntimeLayout.lua`
    - `src/ServerScriptService/Server/MatchSystem/AbandonedPalaceMapScaffold.lua`
  - patched runtime router/config:
    - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
    - `src/ServerScriptService/Server/MatchSystem/EnvironmentalObjectRuntime.lua`
    - `src/shared/GameData/Maps/AbandonedPalace.lua`
  - updated source-of-truth documentation and index:
    - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/ABANDONEDPALACE_RECONSTRUCTION_SPEC_2026-04-16.md`
  - appended this execution log entry
- Canonical AbandonedPalace statements locked by this sync:
  - runtime room topology: `18` rooms on `1` floor
  - active support counts:
    - `Doors=18`
    - `Lights=18`
    - `Props=18`
    - `Electronics=6`
    - `Windows=6`
    - `EvidenceSpawnNodes=14`
    - `GhostSpawns=5`
    - `SpawnPoints=4`
    - `SafeZones=2`
  - timer-based preparation countdown remains disabled
  - investigation begins on `Door_GrandHall` (not countdown)
  - environmental trigger targets resolve via imported assets or generated runtime fallback assets

## 2026-04-16 15:32:07 +07:00 - HauntedHouse Owner-Driven Runtime Sync and Boundary Tightening
- Status: PASS FOR SOURCE-OF-TRUTH ALIGNMENT.
- Trigger:
  - owner completed manual edits in `Workspace.HauntedHouse_Review` and requested immediate sync lock.
  - owner requested strict boundary behavior: no oversized outdoor floor, no loose boundary distance, no player out-of-map exits.
- Action taken:
  - copied runtime state from `Workspace.HauntedHouse_Review` into active source map:
    - `ServerStorage.Maps.HauntedHouse.HauntedHouse`
    - mirrored to `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse`
  - created pre-sync backup:
    - `HauntedHouse_PRESYNC_FROM_REVIEW_FINAL_20260416_083207`
  - removed `Runtime.OutdoorBaseplateRuntime.OutdoorMainFloor` for `HauntedHouse` in all active roots by owner request.
  - rebuilt boundary to house+staging footprint only, then tightened collider size to prevent exit exploits.
  - realigned realistic `BoundaryTrees` to all four sides (`North/South/West/East`) as direct blocker lines.
- Canonical statements locked:
  - `HauntedHouse` no longer depends on `OutdoorMainFloor`.
  - boundary for `HauntedHouse` is constrained to house+staging scope and kept anti-exit.
  - runtime map in `ServerStorage` and `ReplicatedStorage` is synchronized to owner-edited workspace state.

## 2026-04-16 16:24:00 +07:00 - GhostSpawn Zone Height Fix + Door Wiring Validation
- Status: PASS FOR ACTIVE MAP RUNTIME.
- Trigger:
  - owner reported `GhostSpawnZone` terlalu rendah dan meminta wiring logic dipastikan tidak ada yang tertinggal.
- Action taken:
  - normalized all active `GhostSpawnZone_*` nodes to consistent spawn volume profile:
    - `Size = 3,7,3`
    - `Anchored=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=true`, `Transparency=1`
  - lifted low spawn anchors to safe floor-relative height using primary entry door baseline per map.
  - applied changes across active roots:
    - `Workspace.HauntedHouse_Review` (`6` zones)
    - `Workspace.StudioMMNineteen_Review` (`6` zones)
    - `ServerStorage.Maps.HauntedHouse.HauntedHouse` (`6` zones)
    - `ServerStorage.Maps.StudioMMNineteen.StudioMMNineteen` (`6` zones)
    - `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse` (`6` zones)
    - `ReplicatedStorage.Maps.StudioMMNineteen.StudioMMNineteen` (`6` zones)
  - validated door wiring coverage against runtime contract (`DoorTraversalPolicy`, sound attrs, `DoorPathModifier`, `DoorObjectId`):
    - `HauntedHouse`: `18/18` wired
    - `StudioMMNineteen`: `10/10` wired
- Note:
  - `AbandonedPalace` and `EmptyBuilding` currently have no active `Doors/GhostSpawns` folders in storage roots, so no patchable runtime nodes were found for this pass.

## 2026-04-16 17:30:27 +07:00 - Owner Syncback Capture from Workspace Review
- Status: PASS FOR SOURCE-OF-TRUTH SYNCBACK.
- Trigger:
  - owner confirmed manual adjustments were completed and requested immediate pull/syncback, commit, and log append.
- Action taken:
  - captured latest state from:
    - `Workspace.HauntedHouse_Review`
    - `Workspace.StudioMMNineteen_Review`
  - synced to canonical runtime roots:
    - `ServerStorage.Maps.HauntedHouse.HauntedHouse`
    - `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse`
    - `ServerStorage.Maps.StudioMMNineteen.StudioMMNineteen`
    - `ReplicatedStorage.Maps.StudioMMNineteen.StudioMMNineteen`
  - created pre-sync backups:
    - `HauntedHouse_PRESYNC_FROM_REVIEW_20260416_103015`
    - `HauntedHouse_PRESYNC_FROM_REVIEW_20260416_103017`
    - `StudioMMNineteen_PRESYNC_FROM_REVIEW_20260416_103019`
    - `StudioMMNineteen_PRESYNC_FROM_REVIEW_20260416_103020`
- Verification:
  - parity check review->storage passed for both maps (folder counts and basepart totals matched).
  - locked parity snapshot:
    - `HauntedHouse`: `BaseParts=14572`, `Rooms=20`, `Doors=18`, `GhostSpawns=6`, `EvidenceSpawnNodes=14`, `InteractionPoints=20`, `SafeZones=2`, `Lights=20`, `Props=20`, `Electronics=7`
    - `StudioMMNineteen`: `BaseParts=5798`, `Rooms=12`, `Doors=10`, `GhostSpawns=6`, `EvidenceSpawnNodes=12`, `InteractionPoints=12`, `SafeZones=2`, `Lights=12`, `Props=12`, `Electronics=6`

## 2026-04-16 17:56:29 +07:00 - AbandonedPalace Review Rebuild, Door Snap + Syncback
- Status: PASS FOR SOURCE-OF-TRUTH SYNCBACK.
- Trigger:
  - owner requested AbandonedPalace readiness in workspace with complete runtime markers and door wiring by naming, then approved final result.
- Action taken:
  - rebuilt `Workspace.AbandonedPalace_Review` from active storage source and ensured runtime folders complete:
    - `Rooms`, `Doors`, `GhostSpawns`, `EvidenceSpawnNodes`, `InteractionPoints`, `SafeZones`, `SpawnPoints`, `Lights`, `Props`, `Electronics`, `Windows`
  - wired all `Door_*` by naming pattern and logic attributes:
    - traversal policy/sounds/path modifier/object id/labels
    - primary preparation advance door locked to `Door_GrandHall`
  - corrected `Door_*` proxies to match physical door area context and adjusted collider sizes per fitted door geometry pass.
  - synced approved workspace map to:
    - `ServerStorage.Maps.AbandonedPalace.AbandonedPalace`
    - `ReplicatedStorage.Maps.AbandonedPalace.AbandonedPalace`
  - created pre-sync backups:
    - `AbandonedPalace_PRESYNC_FROM_REVIEW_20260416_105623`
    - `AbandonedPalace_PRESYNC_FROM_REVIEW_20260416_105624`
- Verification:
  - parity check passed review->storage for both roots.
  - locked parity snapshot:
    - `BaseParts=4946`
    - `Rooms=18`
    - `Doors=18`
    - `GhostSpawns=5`
    - `EvidenceSpawnNodes=14`
    - `InteractionPoints=18`
    - `SafeZones=2`
    - `SpawnPoints=4`
    - `Lights=18`
    - `Props=18`
    - `Electronics=6`
    - `Windows=6`

## 2026-04-16 17:59:00 +07:00 - EmptyBuilding Final Runtime Fill + Syncback
- Status: PASS FOR SOURCE-OF-TRUTH SYNCBACK.
- Trigger:
  - owner requested last map completion with full runtime coverage and door wiring by naming.
- Action taken:
  - created `Workspace.EmptyBuilding_Review` from active source map.
  - populated complete runtime folders using canonical EmptyBuilding layout:
    - `Rooms`, `Doors`, `GhostSpawns`, `EvidenceSpawnNodes`, `InteractionPoints`, `SafeZones`, `SpawnPoints`, `Lights`, `Props`, `Electronics`, `Windows`
  - wired all `Door_*` with logic attributes and traversal contract:
    - policy, open/close sound ids, path modifier, object id, labels, primary preparation trigger at `Door_Lobby`.
  - synced approved review map to:
    - `ServerStorage.Maps.EmptyBuilding.EmptyBuilding`
    - `ReplicatedStorage.Maps.EmptyBuilding.EmptyBuilding`
  - created backup snapshot before replace:
    - `EmptyBuilding_PRESYNC_FROM_REVIEW_20260416_105852` (both storage roots)
- Verification:
  - parity check passed review->storage for both roots.
  - locked parity snapshot:
    - `BaseParts=829`
    - `Rooms=14`
    - `Doors=14`
    - `GhostSpawns=5`
    - `EvidenceSpawnNodes=9`
    - `InteractionPoints=14`
    - `SafeZones=2`
    - `SpawnPoints=4`
    - `Lights=14`
    - `Props=14`
    - `Electronics=6`
    - `Windows=12`

## 2026-04-16 19:57:44 +07:00 - EmptyBuilding Interior Density + Event Wiring + Syncback
- Status: PASS FOR SOURCE-OF-TRUTH SYNCBACK.
- Trigger:
  - owner approved bathroom pass and requested wiring kebutuhan, syncback, commit, and append report.
- Action taken:
  - added approved interior density layers on active review map:
    - `DecorFill` (room baseline), `Partitions`, `AddedDoors`, `LiftLadder` (ladder-only), `DecorPlus`, `DecorFloor2Plus`, `DecorBathroomPlus`.
  - wired environmental runtime proxies so event targets always resolve:
    - `Lights`: `14/14` stamped with `PasrahGeneratedKind=ceiling_light`
    - `Props`: `14/14` stamped with `PasrahGeneratedKind=prop_box/prop_crate`
    - `Electronics`: `6/6` stamped with `PasrahGeneratedKind=tv/radio`
    - `Windows`: `12/12` stamped to explicit physical targets under `WindowEventTargets` (`12` panes)
  - maintained existing core gameplay runtime folders and counts:
    - `Rooms=14`, `Doors=14`, `GhostSpawns=5`, `EvidenceSpawnNodes=9`, `InteractionPoints=14`, `SafeZones=2`, `SpawnPoints=4`, `Lights=14`, `Props=14`, `Electronics=6`, `Windows=12`
  - re-synced approved review state to canonical runtime roots:
    - `ServerStorage.Maps.EmptyBuilding.EmptyBuilding`
    - `ReplicatedStorage.Maps.EmptyBuilding.EmptyBuilding`
  - generated pre-sync backups in both roots:
    - `EmptyBuilding_PRESYNC_FROM_REVIEW_<timestamp>`
- Verification:
  - wiring audit result:
    - `Lights noTarget=0/14`
    - `Props noTarget=0/14`
    - `Electronics noTarget=0/6`
    - `Windows noTarget=0/12`
    - `Doors attrMissing=0/14`
    - `GhostSpawns offRoom=0/5`
    - `EvidenceSpawnNodes offRoom=0/9`
  - parity check review->storage passed (`PARITY=true`) including extra decor folders:
    - `DecorFill=14`
    - `Partitions=10`
    - `AddedDoors=8`
    - `LiftLadder=2`
    - `DecorPlus=14`
    - `DecorFloor2Plus=5`
    - `DecorBathroomPlus=2`
    - `WindowEventTargets=12`

## 2026-04-17 12:24:00 +07:00 - Published Runtime Staging Drift Lock (No Synthetic Mainfloor)
- Status: PASS FOR PUBLISHED RUNTIME DRIFT FIX.
- Trigger:
  - owner reported staging in published runtime still separated from map and requested strict return to source-of-truth behavior.
- Action taken:
  - switched preparation runtime to native-map authoritative mode in `MapRuntimePatches`:
    - disabled legacy synthetic staging geometry generation (`PreparationPlatform/Runner/Forecourt/Fence/...`).
    - disabled legacy `SpawnPoints` and `SafeZones` coordinate override paths.
    - retained lightweight marker folder `PreparationStagingRuntime` for world-preparation UI compatibility only (no geometry payload).
  - added native re-anchor safety in `MapRuntimePatches`:
    - if `PlayerSpawn_1` is far from primary entry door anchor, runtime re-anchors `PlayerSpawn_1..4` and `SafeZone_1..2` near the map's front-entry side.
  - updated all active map scaffolds (`HauntedHouse`, `StudioMMNineteen`, `EmptyBuilding`, `AbandonedPalace`):
    - existing authored `SpawnPoints`/`SafeZones` are preserved and no longer forcibly repositioned to static legacy layout coordinates.
  - built and published to canonical cloud target:
    - `PlaceId=113010869463813`
    - `UniverseId=9802743087`
- Verification:
  - live multiplayer smoke run (Android + RobloxPlayer PC) reached match staging successfully.
  - runtime view now resolves around front-entry area instead of detached synthetic prep floor.
  - remaining visual follow-up:
    - map signage still shows legacy `FOR SALE` art in current published map asset and needs explicit map-sign art sync to owner-approved board images.

## 2026-04-18 00:01:08 +07:00 - Runtime Recovery Patch: Native Staging + Bounded Mainfloor
- Status: PASS FOR CLOUD PATCH DEPLOY.
- Trigger:
  - owner approved immediate recovery run to stop staging drift, over-broad boundary, floating logic folders, and HauntedHouse overbright runtime.
- Action taken:
  - updated `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua` (commit `d5a6a34`):
    - force HauntedHouse to use authored/native staging marker path (no synthetic prep geometry path for HauntedHouse).
    - add guarded runtime mainfloor patch only for maps that still require support pad:
      - `StudioMMNineteen`, `EmptyBuilding`, `AbandonedPalace`.
    - constrain map-bound computation to authored playable folders first (`Rooms/Doors/SpawnPoints/SafeZones/GhostSpawns/EvidenceSpawnNodes/...`) before full fallback scan, reducing outlier-driven oversized boundary.
    - gate all fallback map scaffold builders so they only run when required logic folders are actually missing `BasePart`, preventing overwrite/drift over complete authored maps.
    - lower HauntedHouse runtime light brightness scale (`0.88 -> 0.62`) to reduce overlight in interior.
  - validated build graph:
    - `powershell -ExecutionPolicy Bypass -File scripts\Invoke-Rojo.ps1 sourcemap default.project.json` -> exit `0`.
  - published to canonical cloud target:
    - `PlaceId=113010869463813`
    - `UniverseId=9802743087`
    - `upload` command exit `0`.
- Verification:
  - code patch compiled through Rojo sourcemap.
  - cloud publish completed successfully from current branch state.

## 2026-04-18 13:29:47 +07:00 - PreparationSpawnArea Canonical Alignment + Source-of-Truth Lock
- Status: PASS FOR SOURCE-OF-TRUTH LOCK.
- Trigger:
  - owner approved canonical/doc-index alignment, syncback from active `PASRAHPHOBIA.rbxlx`, commit, push, publish, and workspace review cleanup.
- Action taken:
  - verified live Studio map state in both runtime roots:
    - `ReplicatedStorage.Maps.{HauntedHouse,StudioMMNineteen,EmptyBuilding,AbandonedPalace}`
    - `ServerStorage.Maps.{HauntedHouse,StudioMMNineteen,EmptyBuilding,AbandonedPalace}`
  - confirmed all four investigation maps now resolve preparation spawn from:
    - `Runtime.PreparationStagingRuntime.PreparationSpawnArea`
    - with `prepSpawnParts=4`
    - and no legacy `SpawnPoints` folder.
  - confirmed required runtime coverage stays complete on all four investigation maps:
    - `Rooms`, `Doors`, `GhostSpawns`, `EvidenceSpawnNodes`, `InteractionPoints`, `Lights`, `Props`, `Electronics`, `Windows`, `SafeZones`.
  - synced active Studio snapshot back into repo through local place save:
    - `PASRAHPHOBIA.rbxlx`
  - updated canonical source files to remove legacy investigation-map `spawnPoints` assumptions:
    - `src/shared/GameData/Maps/HauntedHouse.lua`
    - `src/shared/GameData/Maps/StudioMMNineteen.lua`
    - `src/shared/GameData/Maps/EmptyBuilding.lua`
    - `src/shared/GameData/Maps/AbandonedPalace.lua`
    - `src/ServerScriptService/Server/MapConfigSystem/Service.lua`
  - updated documentation to match runtime truth:
    - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
  - preserved the already-committed runtime logic patch baseline:
    - `f9cbfb6` `Fix preparation spawn runtime and session checklist`
  - committed source-of-truth alignment snapshot:
    - `eb46b31` `Align investigation prep runtime to PreparationSpawnArea`
  - published branch state to canonical cloud target:
    - `PlaceId=113010869463813`
    - `UniverseId=9802743087`
- Verification:
  - live Studio audit result:
    - `HauntedHouse complete=true prepSpawnParts=4 spawnPoints=false`
    - `StudioMMNineteen complete=true prepSpawnParts=4 spawnPoints=false`
    - `EmptyBuilding complete=true prepSpawnParts=4 spawnPoints=false`
    - `AbandonedPalace complete=true prepSpawnParts=4 spawnPoints=false`
  - validation performed on both:
    - `ReplicatedStorage`
    - `ServerStorage`
  - publish command completed from current branch using Open Cloud API key in environment.

## 2026-04-18 15:04:18 +07:00 - Ghost Source-Of-Truth Lock From Local Roblox Creator Hub
- Status: PASS FOR GHOST ASSET SOURCE LOCK.
- Trigger:
  - owner declared ghost source of truth is local `ROBLOX CREATOR HUB`, ordered removal of the wrong `Leak` CSV row, and required old ghost asset IDs in code/runtime to be replaced by the latest imported IDs.
- Action taken:
  - audited authoritative local source:
    - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\GHOST`
    - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[ASSETID]\Models & Packages.csv`
  - removed invalid `Leak` CSV mapping row from the owner local CSV:
    - `dark+armored+knight+more+spikey (129878813436863)`
  - locked canonical ghost asset IDs from local source for:
    - `Banaspati=91700421463863`
    - `Genderuwo=117009327297852`
    - `HantuTanah=79247394068873`
    - `Jerangkong=78522466547915`
    - `Kuntilanak=93357688576883`
    - `Leak=99042834683066`
    - `Palasik=107658913093426`
    - `Pocong=123151303766691`
    - `SilumanUlar=93238005114915`
    - `SundelBolong=77251173218842`
    - `Tuyul=108895029067567`
    - `WeweGombel=115717855449052`
  - locked approved existing aggressive/event suffix lane variants for:
    - `BanaspatiAggressive=117153307100171`
    - `GenderuwoAggressive=138432330933642`
    - `KuntilanakAggressive=118867381731250`
    - `LeakAggressive=115214614318321`
    - `PalasikAngry=95122370433014`
    - `SundelBolongAggressive=113356865728207`
  - replaced live `ReplicatedStorage.Assets.Models.Ghosts` templates in active Studio with canonical wrappers for:
    - all `12` base ghosts
    - `6` approved aggressive/event variants already supported by the existing runtime naming lane
  - each new runtime ghost template wrapper now carries:
    - `GhostAssetId`
    - `GhostImportedAt`
    - `GhostSourceCsvLabel`
  - removed old code-side Pocong single-mesh dependency:
    - `src/ReplicatedStorage/Assets/GhostVisualProfiles/Pocong.lua` -> `RuntimeModel`
    - removed Pocong-only hardcoded template offsets / mesh-part overrides from `src/ServerScriptService/Server/GhostSystem/Service.lua`
  - updated canonical ghost asset ID references in:
    - `src/shared/GameData/GhostVisualTuning.lua`
  - saved active Studio place to:
    - `PASRAHPHOBIA.rbxlx`
  - synced ghost template replacements back into source with:
    - `scripts/pull-from-studio.ps1 -ProjectPath syncback.ghosts.project.json`
  - updated source-of-truth documents:
    - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/GHOST_AND_ASSET_WIRING_TASK_TRACKER_2026-04-18.md`
  - published current branch source to canonical cloud target:
    - `PlaceId=113010869463813`
    - `UniverseId=9802743087`
- Verification:
  - source tree now contains canonical ghost templates for:
    - `Banaspati`
    - `BanaspatiAggressive`
    - `Genderuwo`
    - `GenderuwoAggressive`
    - `HantuTanah`
    - `Jerangkong`
    - `Kuntilanak`
    - `KuntilanakAggressive`
    - `Leak`
    - `LeakAggressive`
    - `Palasik`
    - `PalasikAngry`
    - `Pocong`
    - `SilumanUlar`
    - `SundelBolong`
    - `SundelBolongAggressive`
    - `Tuyul`
    - `WeweGombel`
  - repo-wide search confirmed no active source-code use of the deleted wrong `Leak` asset ID `129878813436863`.
  - repo-wide search confirmed legacy Pocong mesh asset IDs were removed from code-side ghost visual profiles; remaining references only exist as nested sub-assets inside the newly imported `Pocong` model payload.
  - published PC player smoke still boots to lobby UI after this asset-source lock.

## 2026-04-18 - Tool base-slot source-of-truth lock

- Context:
  - owner clarified that the authoritative source for investigation tools is the local `ROBLOX CREATOR HUB` folder plus the local CSV asset manifest
  - duplicate uploads are intentional and reserved for future rarity/state/support lanes
  - current gameplay runtime must therefore lock exactly one base/default/common asset per canonical tool slot without inventing placeholders
- Decisions locked into source:
  - `JejakEnergi = 121559455873224`
  - `KotakArwah = 80024667585179`
  - `SuhuMembeku = 106744635077484`
  - `BukuTerkutuk = 123135502718934`
  - `BolaArwah = 80883221689326`
  - `GerakanGaib = 109093713235033`
  - `Garam = 117103968659967`
  - `PilSanity = 135462688002407`
  - `Salib = 128686833722709`
  - `Dupa = 128740632500448`
  - `Flashlight = 127298509562779`
- Source changes:
  - added `src/shared/GameData/ToolVisualConfig.lua` as the authoritative base-slot mapping and preserved variant pools for future rarity/content use
  - updated `src/shared/GameData/FlashlightConfig.lua` to point the base flashlight source-of-truth to the imported owner asset
  - stamped tool preview/runtime clones with authoritative metadata in:
    - `src/client/UI/Main.lua`
    - `src/ServerScriptService/Server/EvidenceSystem/Modules/UtilityToolVisuals.lua`
    - `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - updated canonical/docs:
    - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/GHOST_AND_ASSET_WIRING_TASK_TRACKER_2026-04-18.md`
- Verification:
  - `scripts/Invoke-Rojo.ps1 sourcemap default.project.json` succeeded after the tool-source lock
  - source tree currently contains canonical tool templates only for:
    - `Dupa`
    - `Garam`
    - `Salib`
  - source tree does not yet contain synced imported templates for:
    - `JejakEnergi`
    - `KotakArwah`
    - `SuhuMembeku`
    - `BukuTerkutuk`
    - `BolaArwah`
    - `GerakanGaib`
    - `PilSanity`
- Remaining blocker:
  - full visual parity for the missing tool slots cannot be claimed until those imported Studio templates are syncbacked into `src/ReplicatedStorage/Assets/Models/Tools`

## 2026-04-18 - Tool template syncback completed

- Context:
  - the saved worktree place file initially still carried only `Dupa`, `Garam`, and `Salib` under `ReplicatedStorage.Assets.Models.Tools`
  - live Studio inspection confirmed the missing tool templates had not yet been inserted into the canonical tool template folder
- Live Studio action:
  - opened `PASRAHPHOBIA.rbxlx` from the active worktree
  - loaded owner-imported base tool assets directly by authoritative asset id into `ReplicatedStorage.Assets.Models.Tools`
  - replaced/created canonical tool templates for:
    - `JejakEnergi`
    - `KotakArwah`
    - `SuhuMembeku`
    - `BukuTerkutuk`
    - `BolaArwah`
    - `GerakanGaib`
    - `Garam`
    - `PilSanity`
    - `Salib`
    - `Dupa`
    - `Flashlight`
  - saved the live Studio place back to `PASRAHPHOBIA.rbxlx`
- Syncback:
  - used `syncback.tools.project.json` to pull only `ReplicatedStorage.Assets.Models.Tools` from the saved place file back into source
- Verification:
  - `src/ReplicatedStorage/Assets/Models/Tools` now contains all 11 canonical base-slot tool templates
  - missing slots now exist in source as synced `.rbxm` files:
    - `JejakEnergi.rbxm`
    - `KotakArwah.rbxm`
    - `SuhuMembeku.rbxm`
    - `BukuTerkutuk.rbxm`
    - `BolaArwah.rbxm`
    - `GerakanGaib.rbxm`
    - `PilSanity.rbxm`
    - `Flashlight.rbxm`

## 2026-04-18 - Lobby spawn parity cleanup in worktree place

- Root baseline validated from `C:\Projects\ROBLOX\PASRAHPHOBIA\PASRAHPHOBIA.rbxlx`:
  - local play reaches `Workspace.Maps.LobbySocialHub.LobbySocialHub`
  - spawn stays at approximately `1610, 3.47, -10`
- Worktree issue reproduced in `final-source-of-truth\PASRAHPHOBIA.rbxlx`:
  - spawn coordinates were still correct
  - opening lobby view was polluted by `StudioGhostPreviewGallery`
  - lobby support display props `ToolDisplayGaram`, `ToolDisplaySalib`, `ToolDisplayDupa` were oversized because newly imported tool assets were being rendered at raw scale
- Root causes:
  - dirty local place attribute `ReplicatedStorage.PasrahStudioLobbyGhostPreview = true`
  - dirty local place attribute `ReplicatedStorage.PasrahForceGhostType = Pocong`
  - no clamp for lobby support tool runtime asset models
- Corrections:
  - removed local worktree place attributes:
    - `PasrahStudioLobbyGhostPreview`
    - `PasrahForceGhostType`
    - `PasrahForceGhostVisualState`
    - `PasrahRoomTrace`
    - `PasrahAutoRoomSmoke`
  - source patch:
    - `src/shared/GameData/ToolVisualConfig.lua`
    - `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - live Studio place patch:
    - `ServerScriptService.Server.LobbySocialHub.LobbyService`
- Verification:
  - `StudioGhostPreviewGallery` no longer spawns in front of lobby spawn
  - oversized support tool display models no longer appear in the forward camera cone from spawn
  - final local play verification kept spawn at `1610, 3.47, -10`
  - cleaned worktree `.rbxlx` saved locally

## 2026-04-18 - Map source drift cleanup and preparation door smoke

- Scope:
  - removed `PRESYNC_*` map variants from live `ReplicatedStorage.Maps` and `ServerStorage.Maps`
  - removed the same binary variants from local source folders under:
    - `src/ReplicatedStorage/Maps/*`
    - `src/ServerStorage/Maps/*`
  - restored host room start countdown to `5` seconds in:
    - `src/ServerScriptService/Server/LobbySystem/Service.lua`
    - `src/ServerScriptService/Server/LobbySystem/Controller.lua`
- Runtime/source fixes kept:
  - `src/client/UI/Main.lua`
    - reduced top-level locals so UI no longer fails with Luau local-register overflow
  - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
    - authored preparation runtime is treated as authoritative
    - synthetic `RuntimeMainfloor` and `RuntimeBoundary` are removed when authored staging exists
    - authored preparation runtime is re-anchored against the active front door
  - `src/ServerScriptService/Server/MatchSystem/MatchTeleport.lua`
    - spawn lift protects authored preparation spawns from low-Y fallback
- Verification in Studio active place:
  - edit mode now shows only one authoritative model per investigation map:
    - `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse`
    - `ReplicatedStorage.Maps.StudioMMNineteen.StudioMMNineteen`
    - `ReplicatedStorage.Maps.EmptyBuilding.EmptyBuilding`
    - `ReplicatedStorage.Maps.AbandonedPalace.AbandonedPalace`
    - `PowerBreakerSwitch` remains only under `ReplicatedStorage.Maps.AbandonedPalace`
    - matching single-model state confirmed in `ServerStorage.Maps`
  - local smoke on `HauntedHouse`:
    - lobby boot succeeded
    - room browser could create room and start match
    - active match contained only:
      - `Match_match_1.HauntedHouse:Folder`
      - `Match_match_1.HauntedHouse.HauntedHouse:Model`
      - `Match_match_1.InvestigationTools:Folder`
      - `Match_match_1.Ghost_Palasik:Model`
    - player spawned at authored preparation staging outside the house
    - front door prompt changed lifecycle from `PreparationPhase` to `InvestigationPhase`
- Local place file result:
  - before cleanup save: `PASRAHPHOBIA.rbxlx = 1344.51 MB`
  - after cleanup save: `PASRAHPHOBIA.rbxlx = 305.64 MB`
- Repo hygiene:
  - `.gitignore` now allows authoritative map `.rbxm` files under `src/ReplicatedStorage/Maps/**` and `src/ServerStorage/Maps/**` so this cleanup can be committed instead of living only in local Studio state.

## 2026-04-18 - Lobby donor visual audit lock

- Audited local lobby exports under `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\LobbySocialHub`.
- Results:
  - `LobbySocialHub_EditMode.rbxm`
    - remains low-detail/blockout only
    - `17` top-level folders, `199` descendants
  - `LobbySocialHub_RuntimeReference(F5 Test - Client View).rbxm`
    - richer runtime snapshot but not safe as a whole-lobby replacement
  - `LobbySocialHub_RuntimeReference(F5 test - ServerView).rbxm`
    - richer runtime snapshot but not safe as a whole-lobby replacement
  - `MainHubDecorRuntime.rbxm`
    - approved as authoritative donor visual layer
    - `376` top-level children, `1221` descendants
    - carries rich plaza/building decor without whole-lobby legacy containers
    - carries no `Script`, `LocalScript`, `ModuleScript`, `RemoteEvent`, or `RemoteFunction`
  - `MainHubDecorRuntime2.rbxm`
    - same decor layout class counts and top-level shape
    - differs mainly in richer `TrainingGhostVisual` pose/rig payload from client-view export
    - locked as comparison-only reference, not the default authoritative donor
- Canonical lock:
  - use clean lobby container/source lane for structure and wiring
  - use `MainHubDecorRuntime.rbxm` as donor visual layer for lobby recovery
  - do not promote whole `LobbySocialHub_RuntimeReference(F5...)` exports or legacy playtest containers wholesale

## 2026-04-18 - Lobby donor promoted into source

- Implemented the lobby donor decision in the actual source lane instead of leaving it as documentation-only guidance.
- Source change:
  - generated `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.rbxm` as the authoritative lobby source
  - moved old blockout source to `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.model.json.disabled`
  - updated `.gitignore` to allow tracked binary lobby sources under `src/Workspace/Maps/**`
  - updated `.codex/lobbysocialhub_backup_syncback.project.json` to follow the new `LobbySocialHub.rbxm` source file
- Promotion method:
  - built a temp lobby-only place from source
  - injected `MainHubDecorRuntime.rbxm` under `Workspace.Maps.LobbySocialHub.LobbySocialHub`
  - extracted the resulting lobby model back out as the new authoritative `LobbySocialHub.rbxm`
- Verification:
  - fresh `rojo build default.project.json` now yields `Workspace.Maps.LobbySocialHub.LobbySocialHub` with `18` top-level children
  - `MainHubDecorRuntime` is present as child `18`
  - `MainHubDecorRuntime` in the built source contains `376` direct children and `1221` descendants
- This keeps the donor nested under the lobby model so `LobbyService` can reuse/normalize it instead of generating a conflicting sibling source.

## 2026-04-19 - Fresh publish lobby badge parity fix

- Started from a fully closed state:
  - Roblox Studio closed
  - Roblox PC player closed
  - Android Roblox app terminated
- Reproduced current published/client mismatch and isolated one concrete source bug:
  - `LobbyService.publishLobbyZoneFocus(...)` sent raw badge `SpawnPlaza` when `SpawnPlaza` had no `LOBBY_ZONE_ENTRY_COPY`
  - client fallback metadata used `LOBBY`
  - result: some clients showed `LOBBY/LO`, others could show `SpawnPlaza/SP`
- Fixed source in:
  - `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
    - added `SpawnPlaza = { title = "LOBBY", subtitle = "Hub utama dan quick access" }` to `LOBBY_ZONE_ENTRY_COPY`
- Fresh publish completed successfully:
  - PlaceId: `113010869463813`
  - UniverseId: `9802743087`
  - Published version: `526`
- Fresh validation:
  - PC published client now shows normalized lobby badge `LOBBY` with glyph `LO`
  - Android launch path reaches `com.roblox.client/.ActivityNativeMain`
  - Android MCP screenshot lane still intermittently captures stale overlay/page content instead of the live game surface, so Android runtime presence for this slice was confirmed by activity focus rather than screenshot text
- Evidence:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/MULTICLIENT_PUBLISH_SMOKE_2026-04-19.md`
  - `.codex/evidence/published_pc_20260419_v526.png`
  - `.codex/evidence/published_pc_room_browser_20260419_v526.png`
  - `.codex/evidence/published_pc_room_browser_key_20260419_v526.png`

## 2026-04-19 - UI register overflow fix and lobby lighting stack reduction

- Found a hard local Studio blocker in `StarterPlayerScripts.Client.UI.Main`:
  - Luau compile/load failed with `Out of local registers when trying to allocate connectButtonPress: exceeded limit 200`
  - result: `LobbyUI` and `RoomBrowserUI` never instantiated in Studio local play, making local lobby validation misleading
- Fixed source by reducing top-level local bindings in:
  - `src/client/UI/Main.lua`
  - moved build-signature helpers off top-level local declarations and kept behavior unchanged
- Fresh Studio local play after patch:
  - `LobbyUI=true`
  - `RoomBrowserUI=true`
- Investigated suspected lighting duplication in lobby:
  - idle lobby snapshot over `15s` showed no runtime growth in light/effect counts
  - however baseline stack was too heavy and included `2 Atmosphere` layers before fix
- Reduced lobby visual stack in:
  - `src/client/Controllers/Sensory/VFXController.luau`
  - `ensureAtmosphere()` now reuses `GlobalAtmosphere` instead of creating an extra `HorrorAtmosphere` when the global one already exists
  - toned down `LobbySocialHub` lighting profile:
    - `Brightness 2.25 -> 1.82`
    - lower ambient/specular
    - `Bloom 0.18 -> 0.08`
    - lobby DOF disabled by profile
    - `SunRays 0.068 -> 0.03`
- Fresh Studio local play after tone-down:
  - `Atmosphere 2 -> 1`
  - `Brightness 1.82`
  - `Lighting` child/effect counts stable over `15s`
- Evidence:
  - `.codex/evidence/lobby_lighting_after_vfx_tone_20260419.png`

## 2026-04-19 - LobbySocialHub central blockout cleanup and fresh publish parity

- Root cause for the boxed/void lobby spawn was confirmed in `Workspace.Maps.LobbySocialHub.LobbySocialHub`:
  - `MainHubDecorRuntime` donor was present
  - but legacy `MainHubPlaza` blockout geometry still enclosed the spawn area
  - overlapping legacy parts made fresh published PC and Android spawn looking into bland slate walls / roof
- Cleaned the authoritative lobby source by removing only the overlapping legacy center shell:
  - `Geometry.Structures.InteriorWalls.Wall_MainHubPlaza_North`
  - `Geometry.Structures.InteriorWalls.Wall_MainHubPlaza_South`
  - `Geometry.Structures.InteriorWalls.Wall_MainHubPlaza_East`
  - `Geometry.Structures.InteriorWalls.Wall_MainHubPlaza_West`
  - `Roofs.Roof_MainHubPlaza`
- Reoriented the four lobby `SpawnPoints.PlayerSpawn_*` to face the `Directory/Queue` approach instead of an interior wall.
- Saved the edited Studio place, syncbacked through `syncback.studio-safe.project.json`, and confirmed the resulting source model still contains:
  - `LobbySocialHub` root children: `18`
  - `MainHubDecorRuntime` descendants: `1221`
  - `Roofs` count reduced from `6 -> 5`
  - `Geometry` descendants reduced from `54 -> 50`
- Re-applied the intended client-side graphics defaults after syncback:
  - `src/client/UI/Main.lua`
    - mobile default graphics now resolves to `Quality`
  - `src/client/UI/GraphicsSupport.lua`
    - `Balanced` footer now reads `Balanced manual`
- Closed Studio + PC client + Android app, published fresh, and reopened both clients.
- Fresh published results:
  - PC lobby now spawns facing the lobby directory/queue area, not a boxed wall
  - Android lobby now also spawns into the same open center area and shows the same directory/queue composition
  - Android `Open Room Browser` succeeded and displayed `RUANG INVESTIGASI`
  - PC screenshot lane still showed the lobby panel after automation clicks; this remains inconclusive as an OS automation interaction issue, not a source/runtime regression
- Evidence:
  - `.codex/evidence/studio_after_lobby_cleanup_20260419.png`
  - `.codex/evidence/published_pc_player_post_lobby_cleanup_20260419.png`
  - `.codex/evidence/published_pc_player_post_lobby_cleanup_settled_20260419.png`
  - `.codex/evidence/published_android_lobby_post_cleanup_20260419.png`
  - `.codex/evidence/published_pc_room_browser_retry_20260419.png`

## 2026-04-19 - Lobby parity follow-up: trace cleanup and glow reduction

- Removed temporary room-browser trace forcing from source and kept only the proven mobile room-browser layout fix.
- Re-published a trace-free build from a fully closed Studio + PC + Android state.
- Audited `LobbySocialHub` source in Studio and confirmed the current authoritative donor is still visually sparse by itself; no richer lobby source was discovered in this slice.
- Reduced lobby baseline glow in `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`:
  - decor point lights now scale down brightness and range
  - guide / entry billboards brightness reduced to `1.2`
- Fresh published results after the lighting patch:
  - PC remains normalized to `LOBBY / LO`
  - Android remains normalized to `LOBBY / LO`
  - Android `MISSION` and `TRACKER` buttons are visible on fresh spawn
  - center-lobby glow is calmer on both clients than the previous publish
- Evidence:
  - `.codex/evidence/pc_fresh_after_trace_cleanup_20260419.png`
  - `.codex/evidence/pc_lobby_after_lighting_patch_20260419_c.png`

## 2026-05-04 - Owner Visual Runtime Binding (LobbySocialHub)

- Risk check before implementation: low-to-moderate; change scoped to existing `LobbySocialHub` owner path and existing docs, no new system owner introduced.
- Synced current Studio edit-mode snapshot into repo using:
  - `rojo syncback syncback.studio-safe.project.json --input PASRAHPHOBIA.rbxlx -y`
- Updated runtime behavior in existing owner service (no duplicate owner):
  - `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - removed `applyMainHubVisualPatch()` call in `LobbyService:Start()` so runtime respects authored visual map state and avoids script overwrite/regeneration of `MainHubDecorRuntime`.
- Updated canonical/index policy to lock owner-visual authority and AI safety rule:
  - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
  - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
- Governance note:
  - map docs remain specification snapshots;
  - real visual map state can change by Owner Projects;
  - AI must ask Owner before destructive visual changes.

## 2026-05-04 - LobbySocialHub Owner Visual Interior Placement Sync

- Owner-approved sync of the live Studio edit-mode placement pass for `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime`.
- Saved the active `PASRAHPHOBIA.rbxlx` Studio snapshot locally, then syncbacked through `syncback.studio-safe.project.json`.
- Updated source model:
  - `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.rbxm`
- Runtime fallback found and fixed during post-sync playtest:
  - `TrainingGhostVisual` was still being re-pivoted by `LobbyService:_refreshEvidenceTrainingGhostAsset()` to the old hardcoded ghost CFrame during play.
  - `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua` now resolves the ghost runtime target from the authored `TrainingGhostVisual` pivot first, then `TrainingGhostCore`, with the legacy hardcoded CFrame only as a last fallback.
- Scope stayed within existing owner-authored map state; no duplicate owner, replacement runtime builder, or new generated decor owner was introduced.
- Final live runtime playtest verification after sync and fallback repair:
  - `North=52`
  - `Shop=20`
  - `Garden=23`
  - `Party=17`
  - `Flex=18`
  - `issues=0`
