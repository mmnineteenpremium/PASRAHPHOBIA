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
