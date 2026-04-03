# Execution Log

## Format

Setiap entry mencatat:

- waktu
- task
- file yang diubah
- validasi
- blocker atau next step

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
