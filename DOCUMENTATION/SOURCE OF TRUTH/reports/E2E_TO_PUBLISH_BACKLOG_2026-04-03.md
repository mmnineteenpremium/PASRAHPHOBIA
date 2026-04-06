# E2E to Publish Backlog 2026-04-03

## Tujuan

Dokumen ini adalah backlog kerja dari kondisi proyek hari ini sampai:

1. end-to-end test yang stabil
2. vertical slice yang layak dimainkan
3. publish readiness

## P0 - Blocker E2E

### 1. Konsolidasi owner client

Status:

- in progress
- dual-stack paling jelas sudah dipotong
- legacy remote consumer utama sudah keluar dari surface runtime
- owner investigasi client sekarang tidak lagi ganda pada jalur bootstrap:
  - `InvestigationUISystem`
  - `EvidenceBoardSystem`
  - `GhostPredictionSystem`
  sudah dikeluarkan dari bootstrap aktif
- modul legacy client yang tidak lagi punya consumer sekarang juga sudah dikeluarkan dari path sinkronisasi `StarterPlayerScripts.Client`:
  - `InvestigationUISystem`
  - `EvidenceBoardSystem`
  - `GhostPredictionSystem`
  - `LegacyDisabled/*`
- `UI/Main` tetap menjadi owner tunggal untuk:
  - `UIEvidenceUpdated`
  - `JournalUpdated`
  - `UIGhostPredictionUpdated`
- satelit yang masih hidup dan disengaja saat ini:
  - `SoundSystem -> SensoryHorrorHUD`
  - `FlashlightController -> FlashlightToggleUI` hanya untuk device touch saat player sudah masuk match

Pekerjaan:

- audit semua LocalScript legacy di `src/client`
- putuskan mana yang dipertahankan, dimigrasi, atau dimatikan
- pastikan hanya satu jalur HUD, audio, sanity, evidence, dan tool UI

Done jika:

- client boot tidak lagi memuat owner ganda untuk surface utama

Catatan validasi terbaru:

- search global source lokal menunjukkan:
  - `InvestigationUISystem`, `EvidenceBoardSystem`, dan `GhostPredictionSystem` tidak punya consumer lain selain bootstrap + file modulnya sendiri
- build source sukses:
  - `_tmp_client_owner_cleanup.rbxlx`
- smoke boot Studio sukses tanpa warning bootstrap client baru
- `PlayerGui` saat boot lobby tetap sehat:
  - `LobbyUI`, `MatchUI`, `ProfileUI`, `RoyalPassUI`, `JournalUI`, `ShopUI`, `PASRA_UI`, `SpectatorUI`, `RoomBrowserUI`
- satelit runtime desktop saat boot lobby:
  - `SensoryHorrorHUD` masih hadir sebagai overlay sanity/vignette yang disengaja
  - `FlashlightToggleUI` tidak lagi hadir di desktop lobby boot
- `FlashlightToggleUI` sekarang hanya dibuat dan ditampilkan untuk:
  - `UserInputService.TouchEnabled == true`
  - player sedang `InMatch`
- build source terbaru sukses:
  - `_tmp_client_surface_cleanup.rbxlx`
- validasi edit tree Studio terbaru:
  - `StarterPlayer.StarterPlayerScripts.Client` tidak lagi membawa folder kosong:
    - `LegacyDisabled`
    - `EvidenceBoardSystem`
    - `GhostPredictionSystem`
    - `InvestigationUISystem`
- validasi play runtime terbaru:
  - `Players.ZyraaaVex.PlayerScripts.Client` hanya membawa modul aktif (`Core`, `UI`, `SoundSystem`, `EvidenceTools`, `GhostRenderer`, `GhostAnimationPipeline`, `Spectator*`, controller lokal)
  - folder legacy investigasi lama tidak lagi ikut spawn ke runtime client

### 2. Canonical remote contract

Status:

- done
- remote legacy utama sudah tidak lagi dipakai oleh consumer client aktif
- remote runtime penting `SpectatorEvidence` sudah source-controlled
- gateway server production tidak lagi membuat `RemoteEvent` / `RemoteFunction` fallback di runtime
- smoke test live setelah patch membuktikan jalur canonical `LobbyEvent -> SelectMode(Ranked) -> CreateRoom -> HostStart` tetap sukses:
  - `CreateRoomResult.ok = true`
  - `HostStartResult.ok = true`
  - `PasrahLastHostStartCommit = commit ok=true err=nil roomId=1`
  - `room.mode = Ranked`
  - `room.mapId = EmptyBuilding`

Pekerjaan:

- definisikan daftar remote event/fungsi final
- hapus dependensi remote lama seperti `SanityUpdate`, `TemperatureUpdate`, `EMFUpdate`
- source-control remote yang wajib ada sejak boot

Done jika:

- semua consumer client/server memakai daftar remote yang sama

### 3. Fix extraction path

Status:

- done untuk jalur clone runtime
- room -> countdown -> match clone -> extraction zone clone sudah tervalidasi di Studio
- extraction tetap butuh `GhostIdentified` pada flow normal
- tersedia override Studio-only untuk validasi E2E tanpa mengubah perilaku production
- validasi live terbaru di `Ranked + EmptyBuilding` membuktikan jalur extraction override Studio benar-benar:
  - menerima `ExtractSelf` hanya saat override Studio aktif
  - mengakhiri match aktif
  - mengembalikan player ke lobby spawn
  - mengosongkan `Workspace.ActiveMatches`

Pekerjaan:

- pastikan extraction zone membaca map clone aktif
- verifikasi end condition match tidak bergantung ke map template lama

Done jika:

- satu match bisa selesai melalui jalur extraction secara konsisten

### 4. Ganti fallback audio yang rusak

Status:

- done
- fallback `403` palsu sudah dibuang
- sound invalid sekarang dimatikan secara eksplisit

Pekerjaan:

- ganti `AudioSanitizer` fallback
- audit SoundId placeholder dan broken
- tetapkan asset fallback internal yang valid

Done jika:

- playtest log tidak lagi menunjukkan fallback `403`

### 5. Bersihkan noise runtime yang tidak pantas

Status:

- in progress
- duplicate telemetry lifecycle log sudah dibersihkan
- surface runtime client jauh lebih kecil dari baseline awal
- startup noise bootstrap juga sudah dipersempit:
  - `Bootstrap.server` sekarang keluar awal jika `_G.__PASRAH_SERVER_BOOT_DONE == true` sebelum mencetak log
  - log boot canonical (`Studio runtime detected`, `skeleton loaded`, `server ready`) sekarang hanya dicetak oleh instance bootstrap pertama
  - ini menutup kesan “duplikasi layer” pada sesi yang membawa lebih dari satu copy script bootstrap
- duplikasi `StarterGui` kosong untuk `LobbyUI`, `MatchUI`, `ShopUI`, `MainMenuUI`, `LeaderboardUI`, `PASRA_UI`, dan `SpectatorUI` sudah dibersihkan
- `PlayerGui` runtime sekarang hanya punya satu owner untuk surface inti:
  - `LobbyUI`
  - `MatchUI`
  - `ShopUI`
  - `MainMenuUI`
  - `PASRA_UI`
  - `SpectatorUI`
- scanner audio boot sekarang tidak lagi spam satu warning per sound rusak:
  - `AudioSanitizer` merangkum invalid sound menjadi summary count + preview
  - `AudioErrorGuard` melewati sound yang sudah ditandai `PasrahAudioSanitized`
  - validasi live terbaru menunjukkan boot cukup menulis `Disabled 5 invalid sounds` alih-alih daftar panjang per-instance
- slot canonical yang dulu broken sekarang sudah terbelah jelas:
  - sudah dipulihkan:
    - `EnvironmentalCreak_01`
    - `GhostManifest_01`
    - `HuntStart_01`
    - `ButtonClick_01` sekarang punya fallback runtime built-in Roblox di `UISystem`
  - masih kosong eksplisit:
    - `AmbientLoop_Main`
- `AmbientLoop_Main` sekarang ditegaskan kembali sebagai placeholder kosong source-owned:
  - slot ini sempat terisi ID heartbeat yang sama dengan `FearAudio`, sehingga berisiko overlap ambience/fear yang menipu diagnosis audio dobel
  - sekarang dikosongkan lagi (`AudioContent = ""`) sampai asset ambience final legal benar-benar siap
- validasi live terbaru menunjukkan boot tidak lagi mengeluarkan warning audio invalid sama sekali
- root cause audio modern juga sudah ditutup:
  - `AudioSystem` sekarang me-relay event audio ke `MatchEvent` client
  - `client/SoundSystem` sekarang memutar `Sound` runtime nyata, bukan sekadar menyimpan payload
- smoke test client live terbaru membuktikan cue ini benar-benar `IsPlaying = true`:
  - `EnvironmentalAudioRuntime`
  - `FearAudioRuntime`
  - `GhostAudioRuntime`
  - `HuntAudioRuntime`
- hunt/survival clarity sudah naik satu level:
  - `HidingSystem` live tervalidasi mendaftarkan safe zone aktif
  - safe zone hunt sekarang juga punya affordance world-space runtime:
    - zone berubah menjadi bidang biru `ForceField`
    - marker `SafeZoneRuntimeMarker` menampilkan outline + billboard `SAFE ZONE`
  - `MatchUI` hunt sekarang membaca state survive live:
    - `HIDDEN`
    - `SHELTERED`
    - `TRACKED`
    - `CRITICAL`
  - `HuntSystem.Controller` sekarang me-relay `HuntStarted` dan `HuntEnded` ke `MatchEvent` client
  - `UISystem` sekarang membatalkan post-teleport loading lama saat hunt datang dan mengangkat `MatchPhase` canonical ke `Hunt`
  - smoke test live terbaru di Studio membuktikan jalur `CreateRoom -> HostStart -> ForceHunt` sekarang menghasilkan:
    - event client `HuntStarted`
    - `LocalPlayer.MatchPhase = Hunt`
    - hunt tidak lagi diam-diam tertimpa flow `Loading/Briefing`
  - validasi exit hunt natural juga sudah tertutup pada level perilaku:
    - player dipindahkan ke `SafeZone_1`
    - state live menjadi `Hidden / Sheltered`
    - setelah hunt selesai natural, `LocalPlayer.MatchPhase` kembali ke `InGame`
    - sesi tidak jatuh ke `Result` saat menunggu hunt selesai
- `SensoryHorrorHUD` sekarang tidak lagi ikut hidup di lobby boot:
  - `PlayerGui.SensoryHorrorHUD` absen saat `InMatch = false`
  - HUD baru dibuat saat player masuk match dan `MatchPhase` aktif (`InGame`, `Escalation`, `Hunt`)
  - HUD kembali hilang saat state kembali ke lobby
- surface client runtime sekarang juga tidak lagi membawa bangkai modul investigasi lama:
  - `LegacyDisabled`
  - `EvidenceBoardSystem`
  - `GhostPredictionSystem`
  - `InvestigationUISystem`
- hasilnya, `StarterPlayerScripts.Client` dan `PlayerScripts.Client` menjadi lebih jujur terhadap owner runtime yang benar-benar aktif

Pekerjaan:

- keluarkan txt contoh dari tree runtime
- trim registry untuk vertical slice
- ganti slot ambience loop terakhir dengan asset final yang sah

Done jika:

- runtime surface hanya memuat asset dan module yang relevan

## P1 - Vertical Slice Playable

### 6. Integrasi satu ghost final

Status:

- done
- `Pocong` sudah source-controlled sebagai template model di `ReplicatedStorage.Assets.Models.Ghosts`
- `GhostSystem` sudah clone template runtime untuk `Pocong`, tidak lagi memakai placeholder untuk slice ini
- spawn final `Ghost_Pocong` sudah tervalidasi di `Workspace.ActiveMatches.Match_match_1`
- movement visual sudah tersambung ke state AI:
  - `CurrentRoomId` runtime ikut berubah
  - `RuntimeGhostState` runtime ikut berubah
  - `HumanoidRootPart` dan `MeshPart` ikut berpindah ke room anchor
  - transparansi visual mengikuti state `Idle/Roaming`
- manifestation dan hunt visual dasar sudah tervalidasi via override Studio-only:
  - `PasrahForceGhostVisualState = Manifestation` menghasilkan `MeshPart.Transparency = 0`
  - `PasrahForceGhostVisualState = Hunting` menghasilkan `MeshPart.Transparency = 0.05`
  - override dibersihkan lagi setelah test

Pekerjaan:

- pilih satu ghost sebagai slice pertama
- source-control model final dan dependency-nya
- tentukan scale, anchor, root, dan spawn behavior
- sambungkan manifestation dan hunt response ke model final

Done jika:

- satu ghost muncul, bergerak, dan menampilkan response visual dasar dari Studio playtest

### 7. Integrasi tool minimum

Status:

- done
- tool minimum pertama ditetapkan sebagai `JejakEnergi`
- resolver `matchId` pada jalur `EvidenceGateway` dan `EvidenceSystem.Controller` sudah diperbaiki
- propagasi reason pada `EvidenceRandomizer` sudah diperbaiki, sehingga kegagalan tool tidak lagi jatuh ke `spawn_failed` generik
- `JournalUI` sekarang menyegarkan blok `Tool E2E` saat menerima `EvidenceCollected` dari tool yang berhasil
- validasi deterministik sukses dengan ghost kompatibel `Leak`:
  - client request `JejakEnergiScan` berhasil untuk `match_1`
  - response tool kembali `success=true`, `reason=collected`, `evidenceType=MEDOK`
  - `JournalUI` menampilkan `Discovered Evidence - MEDOK`
  - `ToolStatusLabel` menampilkan `Evidence berhasil dibaca. / Collected MEDOK`
- bridge runtime modern `EvidenceCollected -> JournalUI` sekarang juga mengisi state deduction non-empty tanpa menunggu journal owner lama:
  - `EvidenceSystem.Controller` menyiarkan `discoveredEvidence`, `confirmedEvidence`, dan `possibleGhosts` ke `EvidenceEvent`
  - `UISystem` memakai payload itu sebagai fallback canonical saat collect berhasil
- validasi live terbaru sukses dengan ghost kompatibel `SundelBolong`:
  - client request `TounDetection` berhasil untuk `match_1`
  - response tool kembali `success=true`, `reason=collected`, `evidenceType=To'un`
  - `JournalUI` sekarang tampil non-empty dengan `Confirmed 1 | Kandidat 7 | Event EvidenceCollected`
  - hero copy berubah ke `Evidence penting sudah terkunci. Saatnya persempit ghost.`
  - `ToolStatusLabel` menampilkan `Evidence berhasil dibaca. / Collected To'un`
- harness StudioE2E sekarang punya action `UseEvidenceTool` untuk pass deterministic tool evidence:
  - `UseEvidenceTool(toolType=JejakEnergi)` tervalidasi menghasilkan update journal:
    - `Discovered Evidence - MEDOK`
    - `Confirmed Evidence - MEDOK`
    - `ToolStatusLabel = Evidence berhasil dibaca. / Collected MEDOK`
  - fallback harness sengaja ditambahkan agar jalur E2E tidak gagal hanya karena RNG spawn evidence saat smoke test

Pekerjaan:

- tetapkan tool minimum untuk loop investigasi pertama
- import model/tool visual jika memang dibutuhkan
- sinkronkan UI tool dengan evidence system

Done jika:

- satu tool minimum bisa dipakai dari awal match sampai evidence terbaca

### 8. Stabilkan satu map playable

Status:

- done untuk baseline blocker/collision map utama
- `HauntedHouse` ditetapkan sebagai map playable pertama
- runtime clone sekarang menormalkan `InteractionPoints` ke room anchor yang benar
- pintu interior clone sekarang memiliki owner runtime yang konsisten:
  - `DoorTraversalRuntimePatched = true`
  - `DoorTraversalMode = HybridRadiusPrompt`
  - `Door_DiningRoom.CanCollide = true`
  - `Door_DiningRoom.CanTouch = true`
  - `Door_DiningRoom.DoorIsOpen = false`
  - `Door_DiningRoom.DoorTraversalPolicy = HybridRadiusPrompt`
  - `Door_DiningRoom` membawa `DoorPrompt` + `DoorPathModifier`
- rute interior yang sebelumnya gagal sekarang lolos setelah karakter ditempatkan di spawn map aktif
- fallback pintu sekarang digeneralisasi ke semua map playable current:
  - `HauntedHouse`
  - `AbandonedPalace`
  - `EmptyBuilding`
  - `StudioMMNineteen`
- validasi live terbaru pada jalur `Ranked -> CreateRoom -> HostStart -> HauntedHouse` membuktikan:
  - clone aktif tetap memakai policy pintu yang sama, bukan hanya `Classic`
  - `Door_DiningRoom` mulai tertutup dan collidable
  - `DoorPrompt` benar-benar ada pada pintu clone aktif
  - `ActionText = Buka Pintu`
  - ini membuat traversal pemain kembali logis, sementara path modifier tetap ada untuk menjaga runtime owner pintu tetap konsisten
- validasi live terbaru sekarang juga sudah menutup hutang “manual validation satu kali” untuk pintu hybrid:
  - jalur `Classic -> CreateRoom -> HostStart -> HauntedHouse` tervalidasi sampai clone aktif `Door_Kitchen`
  - saat karakter didekatkan ke jalur ambang pintu:
    - `DoorIsOpen = true`
    - `Rotation.Y ~= 88`
    - `CanCollide = false`
  - saat karakter dijauhkan kembali ke spawn:
    - `DoorIsOpen = false`
    - `Rotation.Y = 0`
    - `CanCollide = true`
  - artinya hybrid `radius + prompt` bukan lagi asumsi teknis; lifecycle buka/tutup pintu aktif benar-benar berjalan di runtime
- audit clone `HauntedHouse` terbaru juga mengonfirmasi traversal vertikal dasar tidak lagi diblok lantai dua:
  - `Floor_2_North` runtime sudah terpecah menjadi segmen carved di sekitar `CentralStaircase`
  - tidak ada segmen `Floor_2_*` yang overlap dengan bounds tangga aktif
  - audit pathfinding live dari spawn match aktif juga sukses ke target lantai dua:
    - `Interact_Bedroom2`: `Success`, `28` waypoint
    - `Room_Bedroom2`: `Success`, `28` waypoint
    - `Room_Attic`: `Success`, `19` waypoint
  - artinya blocker teknis `tangga tertutup lantai 2` sudah tertutup untuk `HauntedHouse`; sisa pekerjaan berikutnya adalah experiential/layout pass, bukan lubang collision mentah
- audit runtime clone terbaru sekarang juga menutup feedback layer pintu:
  - semua map aktif membawa pasangan `DoorOpenSound` + `DoorCloseSound` pada setiap pintu clone
  - hasil audit:
    - `AbandonedPalace`: `18/18` prompt + `18/18` pasangan sound
    - `EmptyBuilding`: `14/14` prompt + `14/14` pasangan sound
    - `HauntedHouse`: `11/11` prompt + `11/11` pasangan sound
    - `StudioMMNineteen`: `8/8` prompt + `8/8` pasangan sound
- sample runtime `Door_DiningRoom` sekarang punya:
  - `DoorOpenSoundId = rbxassetid://139204195403262`
  - `DoorCloseSoundId = rbxassetid://83336813491039`
- art pass map masih belum final, tetapi tidak lagi menjadi blocker untuk loop vertical slice
- policy pintu `HybridRadiusPrompt` sekarang menjadi baseline traversal runtime yang source-controlled:
  - prompt manual tetap ada untuk lintas platform
  - radius membuka/menutup pintu otomatis untuk mengurangi friction traversal
  - validasi live terbaru di `HauntedHouse` membuktikan:
    - pemain didekatkan ke `Door_DiningRoom` -> `DoorIsOpen = true`
    - pemain dijauhkan lagi -> `DoorIsOpen = false`
  - baseline hybrid ini sekarang juga tidak lagi memakai radius bola mentah:
    - auto-open dihitung dari zona ambang pintu yang dikunci ke `closedCFrame`
    - ini mencegah pintu terasa "lengket" terbuka hanya karena daun pintu yang sudah berputar mengubah arah deteksi
    - validasi live terbaru juga membuktikan:
      - karakter diposisikan tepat di jalur `Door_DiningRoom` -> `DoorIsOpen = true`
      - karakter digeser dekat tapi keluar dari jalur ambang pintu -> `DoorIsOpen = false`
- affordance survive dasar sekarang juga tidak lagi buta:
  - saat hunt aktif, `SafeZone_1` runtime tervalidasi membawa:
    - `SafeZoneRuntimeMarker`
    - `Outline.Visible = true`
    - `Billboard.Enabled = true`
  - ini memberi target visual yang jujur untuk shelter tanpa mengubah rule `Hidden / Sheltered` yang sudah hidup
- shelter baseline playable maps sekarang juga tidak lagi bohong soal akses:
  - `HauntedHouse`: `2/2` safe zone path success
  - `AbandonedPalace`: `2/2` safe zone path success setelah runtime nudge `SafeZone_1`
  - `EmptyBuilding`: `2/2` safe zone path success setelah runtime nudge `SafeZone_1` dan `SafeZone_2`
  - `StudioMMNineteen`: `2/2` safe zone path success setelah runtime nudge `SafeZone_1`
- interaction point reachability sekarang sudah tertutup untuk map yang sudah diaudit settle final:
  - `AbandonedPalace`: `0/8` fail setelah patch order + runtime nudge
  - `StudioMMNineteen`: `0/8` fail setelah runtime nudge settle
  - `EmptyBuilding`: `0/8` fail setelah fallback token override + settle final
  - catatan penting:
    - audit yang membaca clone terlalu cepat bisa menghasilkan false negative karena point runtime masih bergerak beberapa detik setelah match start
    - residual `HauntedHouse` sebelumnya diperlakukan sebagai candidate layout debt, bukan blocker aktif, kecuali muncul lagi pada audit settle final berikutnya
- follow-up deferred yang wajib masuk phase berikutnya:
  - audit tangga, akses lantai 2, dan jalur traversal map harus ditutup agar layout tidak terasa palsu saat investigasi/hunt
  - hiding spot final lintas map masih perlu didefinisikan lebih kaya dari sekadar safe zone baseline
  - kualitas pintu dan flow traversal antar-ruang masih perlu dinaikkan dari baseline teknis ke logika map yang lebih profesional

Pekerjaan:

- pilih satu map utama
- audit extraction zone, spawn, blocker, collision, dan art pass minimum
- audit traversal vertikal, tangga, pintu terkunci, dan akses lantai antar-map
- definisikan hiding spot, jalur selamat hunt, dan feedback yang menjelaskan cara survive kepada pemain

Done jika:

- satu map bisa dipakai untuk satu match penuh tanpa blocker besar

### 9. Rapikan HUD inti

Status:

- done
- phase renderer client tidak lagi bergantung pada `HorrorHUD` legacy yang child-nya tidak ada
- `UISystem` sekarang menargetkan jalur canonical:
  - `SensoryHorrorHUD` untuk overlay sanity/vignette
  - `MatchUX` untuk objective / hunt state
- `TransitionTo(\"Investigation\")` sekarang menampilkan objective text default pada `MatchUX`
- `TransitionTo(\"Hunt\")` sekarang menampilkan state `HUNT` di `MatchUX`
- validasi runtime owner berhasil:
  - `PlayerGui.MatchUI = 1`
  - `PlayerGui.LobbyUI = 1`
  - `PlayerGui.PASRA_UI = 1`
  - `PlayerGui.SpectatorUI = 1`
- blocker automation `CreateRoom + HostStart` via MCP direct path sudah tertutup:
  - client menerima `MatchPreparing`
  - client menerima `MatchStarted`
  - client menerima `PhaseChanged`
  - `MatchPhase` client sekarang mencapai `InGame`
  - karakter benar-benar berpindah ke map aktif
  - `InLobby` tidak lagi tertinggal saat teleport sukses
- validasi full live terhadap state `Hunt/Result` sekarang sudah tertutup via jalur Studio-only E2E harness:
  - `Ranked + EmptyBuilding` tervalidasi memakai selection canonical `Ranked`
  - `Hunt` tampil pada HUD dengan state `HUNT`
  - `Result` tampil pada HUD setelah extraction override Studio
  - player kembali ke lobby dan `ActiveMatches = 0`
- room browser tidak lagi bocor ke fase match:
  - validasi live terbaru di `Ranked + HauntedHouse` membuktikan saat `InMatch = true` dan `MatchPhase = Briefing`:
    - `RoomBrowserUI.Enabled = false`
    - `RoomBrowserUI.Panel.Visible = false`
  - jadi panel room besar tidak lagi menumpuk di atas `MatchUI` setelah teleport
  - retest runtime terbaru untuk flow `HostStart -> Countdown -> Preparing` juga mengonfirmasi hasil yang sama:
    - pada `t = 5.0s` room browser sudah `Enabled = false`
    - overlay countdown ikut hilang bersih (`CountdownOverlay.Visible = false`)
- drift fase awal client juga sudah dipotong:
  - setelah `HostStart` pada `Ranked + EmptyBuilding`, client tetap berada di `Preparation/Briefing`
  - `Player.MatchPhase = Briefing`
  - `MatchUI.MainPanel.StateBadge = PERSIAPAN`
  - trace server tetap `phase=PreparationPhase`
  - jadi client tidak lagi meloncat ke `INVESTIGASI` sebelum server lifecycle benar-benar maju
- jalur heartbeat sensory sekarang sudah canonical:
  - `ReplicatedStorage.Assets.Audio.Sensory.Heartbeat` sudah source-controlled
  - `AudioController` tidak lagi berhenti pada fallback kosong
  - validasi live pada `Ranked + HuntPhase` menunjukkan runtime heartbeat:
    - `MissingSourceAsset = false`
    - `IsPlaying = true`
    - `Volume = 0.2`
- owner `SensoryHorrorHUD` sekarang benar-benar boot:
  - `SoundSystem` meregistrasikan `HorrorHUD`
  - `PlayerGui.SensoryHorrorHUD` hadir saat playtest
- bridge `SanitySystem -> RemoteEvents.SanityEvent` sekarang hidup:
  - update sanity runtime benar-benar sampai ke client
  - validasi live `DrainSanity` pada `Ranked + EmptyBuilding` menunjukkan:
    - `PasrahStudioE2ELastResult = match=match_1 sanity=20`
    - `SensoryHorrorHUD.Vignette.GroupTransparency` turun `0.815 -> 0.29`
    - `Lighting.SensorySanityGrading.Saturation` berubah `-0.1 -> -0.7`
    - `Lighting.SensorySanityGrading.Contrast` berubah `0.1 -> 0.4`
- catatan penting untuk automation:
  - jalur room browser memakai `player selection` sebagai sumber mode canonical
  - jadi automation harus memanggil `SelectMode("Ranked")` sebelum `CreateRoom/HostStart`
  - payload `HostStart(mode = "Ranked")` saja tidak mengganti selection yang tersimpan
- countdown room sekarang dipacu dari angka visual yang sama dengan cue audio:
  - server sekarang membroadcast `countdownEndsAt` sebagai anchor waktu yang sama untuk semua client
  - `RoomBrowserController` menyimpan deadline countdown canonical itu, lalu overlay menghitung angka dari `Workspace:GetServerTimeNow()`
  - tick audio hanya dipicu saat angka visual benar-benar berubah, bukan dari pengurang waktu lokal `0.1s`
  - pitch tick dibuat stabil (`PlaybackSpeed = 1`) dan `RuntimeCountdownTick` dipaksa `single-instance`
  - validasi runtime terbaru menunjukkan:
    - countdown visual tetap urut `5 -> 4 -> 3 -> 2 -> 1`
    - `soundCount` untuk tick stabil `= 1` di tiap detik countdown
    - saat transisi ke `Preparing`, tick dibersihkan dan hanya `RuntimeTeleportDrop` yang tersisa
- hardening countdown audio terbaru menutup celah saat panel room disuppress sebelum countdown selesai:
  - `UISystem:_updateCountdownOverlay` sekarang memisahkan `countdownActive` vs `showCountdown`
  - audio tick tetap ikut detik authoritative saat `matchStarting=true`, walau overlay room disembunyikan karena context phase
  - pulse visual label hanya dijalankan saat overlay memang visible, jadi UI tidak memicu animasi tersembunyi
  - validasi live terbaru (`Ranked -> CreateRoom -> HostStart`) membuktikan:
    - `RuntimeCountdownTick` terdeteksi aktif dengan `maxTickInstances=1`, `maxTickPlaying=1`
    - `RuntimeTeleportDrop` tetap single-cue (`maxTeleportInstances=1`, `maxTeleportPlaying=1`)
    - setelah teleport, `RoomBrowserUI.Panel.Visible=false` dan `MatchPhase=Briefing`
- `MatchUI` sekarang juga punya sizing viewport-aware dasar, bukan sekadar typography pass:
  - panel utama, header card, summary frame, footer action, timer chip, quick evidence button, dan controls hint bar ikut mengikuti viewport
  - basis desktop tetap kanan-atas
  - basis compact/mobile kini diposisikan sebagai sheet yang lebih lebar dan lebih mudah dibaca
  - validasi live desktop terbaru membuktikan layout canonical tetap stabil pada `Briefing` tanpa overlap baru:
    - `MatchUI.MainPanel.AbsoluteSize = 340x454`
    - `EvidenceQuickButton.AbsoluteSize = 142x48`
    - `MatchTimerLabel.AbsoluteSize = 126x40`
- summary deck `MatchUI` sekarang juga tidak lagi kosong selama fase aktif:
  - sebelum `Results`, row deck sekarang menampilkan status fase, progress evidence, kandidat, dan status survival dasar
  - validasi live `Briefing` terbaru menunjukkan:
    - `StatusRow = BRIEFING`
    - `GhostRow = Belum teridentifikasi`
    - `EvidenceRow = 0 disc / 0 conf`
    - `SurvivedRow = Semua aktif`
  - copy `HUNT` juga dibuat lebih jujur:
    - tidak lagi mengklaim `Safe Zone biru` sebagai sistem final
    - guidance sekarang tetap berguna tetapi conditional: putus `line-of-sight`, gunakan prompt pintu, dan cari ruang aman jika tersedia
    - hunt guidance sekarang juga tidak lagi generik:
      - client menghitung `safe zone` runtime terdekat dari match aktif
      - objective/hint sekarang bisa menunjuk target operasional seperti `SafeZone 1 52st`
      - ini memberi jawaban yang lebih konkret untuk pemain: bukan sekadar "lari", tetapi ke mana mereka seharusnya bergerak saat hunt aktif
  - guidance hunt sekarang juga sudah paham hide spot runtime:
    - jika player benar-benar hide di `Closet/Locker`, label tidak lagi dipaksa `SAFE ZONE`
    - validasi live terbaru di `EmptyBuilding.Room_Storage` menunjukkan:
      - `ObjectiveLabel = Berlindung di Storage. Diam dan tunggu hunt selesai sebelum keluar.`
      - `MatchUI.HeaderCard.SecondaryLabel = Berlindung di Storage...`
      - `ControlsHintBar = STORAGE • DIAM • TUNGGU HUNT SELESAI`
      - `SummaryFrame.GuessRow/SurvivedRow = Storage`
    - artinya surface UI hunt sekarang sinkron dengan hide spot runtime nyata, bukan wording generik yang membingungkan
  - lookup refuge client sekarang juga punya fallback ke `HideSpotPrompt` pada room runtime:
    - jika `HideSpotId/HideSpotType` belum datang tepat waktu, UI masih bisa menginfer hide spot dari prompt aktif
    - build hardening ini sudah lolos, sehingga race kecil pada state `Exposed` tidak lagi sepenuhnya bergantung pada replication order attribute
    - proof final untuk preferensi `HideSpot` saat player masih `Exposed` sekarang sudah tertutup:
      - repro live `Classic -> EmptyBuilding -> posisi 846,4,-20 -> ForceHunt`
      - state tetap `PasrahHideState = Exposed`, `PasrahHideSpotType = None`
      - `UXLayer.MatchUXGui.MatchUXLayer.ObjectiveLabel = Hunt aktif. Gunakan prompt pintu, putus line-of-sight, lalu masuk Storage 16st.`
      - `MatchUI.HeaderCard.SecondaryLabel = Hunt aktif. Gunakan prompt pintu, putus line-of-sight, lalu masuk Storage 16st.`
      - `MatchUI.ControlsHintBar.Label = PINTU: E/X/TAP  •  TARGET: Storage 16st  •  JANGAN LARI LURUS`
      - `MatchUI.SummaryFrame.SurvivedRow.Value = Storage 16st`
    - artinya jalur `Exposed` tidak lagi bias ke `SafeZone` ketika hide spot runtime yang lebih relevan memang lebih dekat secara operasional

Pekerjaan:

- lanjut ke polish asset/audio final bila diperlukan, bukan lagi wiring HUD inti

Done jika:

- HUD inti tampil konsisten tanpa placeholder besar

## P2 - Content dan Presentation

### 10. Lengkapi ghost roster

Pekerjaan:

- tambah model final untuk ghost lain
- sambungkan animation/audio per ghost

### 11. Lengkapi tool roster

Status:

- in progress
- roster utility world-space sekarang tidak lagi hanya baseline blok lama:
  - `Garam` template aktif sekarang punya `SaltGlow`, `Satchel`, dan detail spill tambahan
  - `Salib` template aktif sekarang punya `HaloBack` dan `GroundAura`
  - `Dupa` template aktif sekarang punya `RepelAura`, `Smoke4`, `Smoke5`, `AshBed`, dan `CharmWrap`
- state visual runtime juga mulai sinkron dengan event gameplay:
  - `Dupa` sekarang mengubah `RepelAura` + smoke color/transparency saat repel aktif
  - `Salib` aura sekarang meredup mengikuti charge yang tersisa
  - `Garam` sekarang menyalakan `SaltGlow` dan detail bag/seal saat trigger terjadi
- validasi live Studio terbaru menutup source sync untuk template tool:
  - `ReplicatedStorage.Assets.Models.Tools.Garam` memuat `SaltGlow`
  - `ReplicatedStorage.Assets.Models.Tools.Salib` memuat `HaloBack` + `GroundAura`
  - `ReplicatedStorage.Assets.Models.Tools.Dupa` memuat `RepelAura` + `Smoke4` + `Smoke5`
- validasi live runtime juga membuktikan state `Dupa` benar-benar bereaksi:
  - `InvestigationTools` runtime memuat model `Dupa_*`
  - `RepelAura.Transparency = 0.34`
  - `Smoke4.Transparency = 0.60`
  - `Smoke5.Transparency = 0.68`
  - warna smoke bergeser ke cyan saat repel aktif
- `Field Kit` HUD sekarang tidak lagi hanya kartu teks tipis:
  - setiap tool punya `hint` mikro yang membedakan fungsi (`EMF sweep`, `Voice bait`, `Lure trap`, dst.)
  - kartu sekarang punya `accent bar` dan ruang vertikal lebih lega sehingga lebih terbaca di desktop/mobile
  - `JejakEnergi` dan `KotakArwah` tidak lagi tampil generik saat idle:
    - `JejakEnergi -> LIVE / SCAN ARC`
    - `KotakArwah -> LISTEN / VOICE LINK`
- validasi live Studio terbaru membuktikan HUD baru benar-benar masuk ke runtime:
  - `FieldKitFrame.Size = 356x156`
  - seluruh tombol tool runtime sekarang punya `HintLabel = true`
  - seluruh tombol tool runtime sekarang punya `AccentBar = true`
  - `JejakEnergiButton -> hint EMF SWEEP`
  - `KotakArwahButton -> hint VOICE BAIT`

Pekerjaan:

- tool visual
- icon
- placement
- UI state

### 12. Rapikan UI modular

Status:

- in progress
- aturan single-open untuk surface lobby utama sekarang sudah tertutup di jalur yang sebelumnya bocor:
  - `ShopUI -> LobbyToggleButton` tidak lagi menghasilkan overlap `LobbyUI + ShopUI`
  - `RoomBrowserUI` terbuka sendirian tanpa panel besar lain ikut hidup
  - transisi silang `MainMenuUI -> ProfileUI` menutup panel asal dengan benar
- `RoyalPassUI` sekarang sudah punya owner canonical aktif di `src/client/UI/Main.lua`
- `RoyalPassEvent` sekarang source-controlled dan mendorong snapshot runtime ke client
- validasi live di Studio membuktikan:
  - tombol float `PASS` muncul di lobby
  - klik membuka panel `Royal Pass`
  - hotkey `R` menutup dan membuka kembali panel
- `RoyalPassUI` tidak lagi hanya panel teks tipis:
  - sekarang punya hero card progress
  - progress bar tier yang nyata
  - tiga row preview track
  - CTA `LIHAT SHOP` yang membuka `ShopUI`
- `RoyalPassUI` sekarang juga punya struktur season yang lebih konkret:
  - tab `30 DAY REWARD`
  - tab `30 DAY MISSION`
  - horizontal scroller berisi 30 kartu harian
  - hari ke-30 menampilkan placeholder hadiah karakter rarity 5
- validasi live terbaru membuktikan:
  - `RoyalPassUI.MainPanel.ContentFrame.RoyalPassDeck` hadir di runtime
  - `HeroTitle = SEASON S1 • TIER 01`
  - `HeroBadge = FREE TRACK`
  - klik `PremiumActionButton` menutup `RoyalPassUI` dan membuka `ShopUI`
  - `TrackScroller` berisi `30` kartu
  - reward mode final card:
    - `Title = DAY 30 • CHARACTER R5`
    - `Reward = R5 BORDER`
  - mission mode final card:
    - `Title = MISSION 30 • GRAND FINALE`
    - `Reward = R5 TOKEN`
- room browser dan host room sekarang tidak lagi memakai literal `MAP IMAGE` placeholder:
  - preview map sudah menjadi kartu prosedural source-owned
  - kartu menampilkan glyph map, atmosfer, ukuran, jumlah room, lantai, dan footer nama map
  - validasi live membuktikan perubahan muncul di daftar room dan panel host room
- `ShopUI` item rows sekarang tidak lagi hanya teks + tombol polos:
  - tiap item punya glyph prosedural, badge kategori/slot, accent rarity, dan pill harga/currency
  - validasi live membuktikan kartu shop tampil di runtime canonical `ShopUI.MainPanel`
- chip currency ekonomi sekarang sudah memakai layout terstruktur, bukan teks datar:
  - `ShopUI` price pill aktif menampilkan glyph ringkas + amount + unit
  - validasi live terbaru membuktikan `ItemRow1.PricePill = glyph M / amount 850 / unit MM`
- panel lobby sekarang punya CTA `ROYAL PASS` langsung:
  - layout tombol lobby naik menjadi grid yang lebih jelas
  - tombol baru terbukti membuka `RoyalPassUI.MainPanel` di runtime live
- `LobbyUI` sekarang kembali stabil setelah polish pass:
  - runtime typo yang memutus builder (`stateBadge` vs `statusBadge`) sudah ditutup
  - tombol `Open Room Browser`, `Profile`, `Shop`, `Royal Pass`, `Menu`, dan `Rank` kembali hadir di panel canonical
  - panel lobby sekarang default terbuka saat join, tapi tetap bisa diminimize lewat toggle `<`
  - validasi live membuktikan `LobbyUI.MainPanel.Visible = true` dan `LobbyToggleButton.Text = "<"` pada boot playtest baru
- `JournalUI` sekarang tidak lagi menumpuk di atas `LobbyUI` saat lobby test:
  - panel journal diposisikan ulang ke kanan ketika `LobbyUI` terbuka pada viewport desktop
  - konten deduction tidak lagi hanya blok teks panjang; sekarang ada hero card, count cards, dan section cards untuk discovered / confirmed / candidates
  - `ToolStatusLabel` dan `SCAN JEJAK` sekarang tampil sebagai control card yang lebih readable
  - validasi live membuktikan `JournalUI.MainPanel.Position = {0, 372}, {0, 16}` dan board baru muncul di runtime canonical
- `ProfileUI` sekarang juga naik dari panel teks polos menjadi kartu identitas + stat deck:
  - hero card player
  - status pill
  - spotlight line
  - CTA `OPEN ROOMS`
  - tiga stat rows visual
- validasi live terbaru membuktikan:
  - `ProfileUI.MainPanel.ContentFrame.ProfileDeck` hadir di runtime
  - `ProfileTitle = ZyraaaVex • LV 1`
  - klik `ActionButton` benar-benar membuka `RoomBrowserUI`
- `MatchUI` sekarang juga punya header card yang lebih scan-friendly:
  - hero header dengan accent warna per fase
  - glyph fase besar (`PR`, `IN`, `HU`, `OK/FG`) untuk membantu recognition cepat
  - summary frame dan quick action sekarang ikut memakai accent fase aktif
- validasi live terbaru membuktikan:
  - `MatchUI.MainPanel.HeaderCard` hadir di runtime
  - `MatchUI.MainPanel.BrandStroke` hadir di panel canonical
  - screenshot `ScreenCapture_MatchUI_PostPolish_2` menunjukkan panel persiapan lebih jelas terbaca di map aktif
- `LeaderboardUI` sekarang tidak lagi berupa blok snapshot teks:
  - rank board memakai hero card, sanity meter, dan empat stat rows yang konsisten dengan bahasa visual panel lain
  - panel tetap jujur sebagai snapshot lokal tanpa memalsukan leaderboard server
  - aksi bawah `Profile`, `Open Rooms`, dan `Open Menu` tetap hidup setelah layout baru masuk
- validasi live terbaru membuktikan:
  - `LeaderboardUI.MainPanel.Size = 340x448`
  - `LeaderboardDeck` hadir di runtime canonical
  - `HeroTitle = ZyraaaVex • Bayi III`
  - rows yang terbentuk: `Tier status`, `Pressure band`, `Room browser pulse`, `Mastery footprint`
  - screenshot `ScreenCapture_LeaderboardUI_Final` menunjukkan rank board baru tampil di lobby aktif
- cluster float button kanan sekarang tidak lagi sekadar lingkaran teks polos:
  - `MENU`, `PASS`, `ROOMS`, dan `RANK` sudah memakai chip branded dengan glyph + caption + accent warna
  - lane default kanan dipisah agar tidak saling menumpuk saat beberapa surface disembunyikan sekaligus
  - validasi live terbaru `ScreenCapture_FloatButtons_Polished_Lobby_2` menunjukkan cluster kanan lebih terbaca dan tidak overlap antar lane internal PASRA
- right rail lobby sekarang sudah dipaku menjadi stack top-to-bottom yang deterministik:
  - `MENU @ y=88`
  - `PASS @ y=158`
  - `ROOMS @ y=228`
  - `RANK @ y=310`
  - posisi dihitung ulang dari state tombol yang benar-benar visible, bukan lagi lane persen yang loncat
- aturan single-open untuk surface lobby sekarang juga lebih tegas:
  - membuka `RoyalPassUI` dari lobby otomatis collapse `LobbyUI`
  - membuka `RoomBrowserUI` dari float `ROOMS` otomatis menyembunyikan `RoyalPassUI`
  - validasi live terbaru membuktikan `lobbyCollapsed = true`, `royalVisible = false`, `roomBrowserVisible = true` setelah transisi `Lobby -> RoyalPass -> RoomBrowser`
- review live terbaru juga menandai debt UX baru yang harus diprioritaskan setelah task aktif selesai:
  - `RoomBrowserUI` sekarang sudah berubah jadi surface fokus split-pane di desktop dan sheet adaptif di viewport compact; overlap panel besar ditutup dan panel detail room dibuat scrollable
  - validasi live desktop sudah lolos, tetapi pass device-emulator/handset nyata untuk mode compact masih pending agar mobile behavior tidak hanya diasumsikan dari source
  - `RoyalPassUI` track 30 hari sudah ada, tetapi polish responsive/scrolling untuk track panjang masih perlu pass lanjutan
- pass responsive konservatif terbaru sudah menutup readability dasar dua panel utama:
  - `LobbyUI` sekarang memakai viewport-aware size `396x384` pada viewport desktop sempit saat ini, bukan lagi fixed `340x368`
  - `RoyalPassUI` sekarang memakai viewport-aware size `436x520` pada viewport desktop sempit saat ini, bukan lagi fixed `348x340`
  - `LobbyToggleButton` juga ikut bergeser mengikuti lebar panel aktif (`x=416` pada viewport validasi)
- pass focus terbaru untuk room browser menutup overlap visual yang paling tidak etis:
  - saat `RoomBrowserUI` aktif, float kanan lain (`MENU`, `PASS`, `RANK`, dst.) tidak lagi tampil
  - validasi live terbaru menunjukkan hanya `RoomBrowserFloatButton` yang masih visible secara properti internal screen, sementara `RoomBrowserFloatUI.Enabled = false` dan rail kanan lain tidak tampil di layar
  - panel room browser juga sekarang tidak lagi bergantung pada `UIScale` agresif; panel utamanya memakai layout responsif penuh (`1080x668` pada viewport validasi desktop), bukan sekadar footprint 920px lama yang dikecil-besarkan
- pass layout besar terbaru untuk `RoomBrowserUI` juga sudah menutup debt visual yang sebelumnya paling mengganggu:
  - browse state sekarang menjadi split-pane fokus dengan daftar room di kiri, preview di kanan, dan action stack yang tidak lagi berhimpitan
  - room detail state sekarang memakai panel kanan-kiri yang lebih logis di desktop, plus `RoomPanel` scrollable agar control host/ready/leave tidak terpotong di viewport pendek
  - jalur compact/mobile sekarang ada di source: browser berubah menjadi fullscreen sheet, daftar room dan preview ditumpuk vertikal, dan detail room pindah ke layout satu kolom
- pass responsive lanjutan terbaru sudah membuat dua panel besar lebih aman dipakai tanpa overlap state:
  - `RoomBrowserUI` sekarang juga dipaksa tutup pada `MatchStarted`, bukan hanya mengandalkan `MatchPreparing`
  - validasi live terbaru dari state browser terbuka -> `HostStart` membuktikan:
    - `RoomBrowserUI.Enabled = false`
    - `RoomBrowserUI.Panel.Visible = false`
    - `MatchPhase = Briefing`
  - `RoyalPassUI` sekarang punya layout yang lebih lebar/tinggi untuk viewport kecil dan track card lebih besar agar 30-day pass tidak terasa sempit
- pass compact terbaru untuk `RoomBrowserUI` juga menyiapkan handset dengan sheet yang lebih rapat dan lebih mudah disentuh:
  - margin mobile dipersempit lagi agar footprint lebih dekat ke fullscreen sheet
  - close button mobile dibesarkan
  - judul mobile dibesarkan dan background sheet dibuat sedikit lebih solid agar keterbacaan naik
  - validasi live desktop tetap stabil:
    - `RoomBrowserUI.Panel.Size = 1080x668`
    - `CloseButton.Size = 34x28`
    - tidak muncul error UI baru di boot/runtime desktop
- guard sizing terbaru sekarang juga menutup risiko overflow viewport pendek pada jalur compact/mobile:
  - `RoomBrowserUI` tidak lagi memaksa minimum tinggi yang bisa lebih besar dari safe viewport kecil
  - `RoyalPassUI` mobile sheet juga tidak lagi memaksa minimum `560px` yang berisiko keluar layar pada viewport pendek
  - sizing mobile sekarang di-clamp ke `available viewport + safe inset`, bukan hanya memakai minimum absolut
- status validasi jujur untuk pass ini:
  - build source sukses untuk guard baru
  - sesi Studio aktif berhasil memunculkan debt lama (`RoomBrowserUI` dan `RoyalPassUI` sempat overflow/negatif pada override compact)
  - validasi handset/device emulator nyata tetap **pending**, tetapi akar sizing yang menyebabkan overflow sudah ditutup di source
- polish lanjutan `RoyalPassUI` juga sudah membuat track 30 hari muncul lebih cepat di viewport aktif:
  - tab `30 DAY REWARD` dan `30 DAY MISSION` sekarang terlihat di atas scroller track
  - screenshot validasi `ScreenCapture_RoyalPass_30Day_Taller` menunjukkan kartu hari awal langsung terlihat tanpa scroll panjang
- polish track terbaru juga membuat `RoyalPassUI` terasa lebih seperti pass yang bisa di-swipe:
  - track sekarang auto-focus ke hari aktif saat season/view/tier berubah
  - kartu hari ke-30 dibuat lebih lebar sebagai finale placeholder agar hadiah karakter rarity 5 tidak tenggelam di antara kartu lain
  - validasi live desktop terbaru membuktikan:
    - `TrackScroller.CanvasPosition = 0,0` pada baseline `Tier 01`
    - `DayCard30.Size = 158x156`
- `MatchUI` sekarang ikut masuk pass viewport-aware agar tidak hanya nyaman di desktop lebar:
  - panel match, header, summary, footer, timer, hint bar, dan quick evidence action sekarang dihitung ulang dari viewport aktif
  - pada desktop validasi terbaru layout tetap rapih dan tidak overlap dengan rail kanan lain
  - basis compact/mobile sudah masuk ke source untuk phase berikutnya, walau validasi device-emulator/handset nyata masih pending
- `MatchUI` guidance pass terbaru juga membuat panel match terasa lebih informatif saat live:
  - summary rows tidak lagi berupa deretan `-` selama `Preparation/Investigation/Hunt`
  - footer dan objective hunt sekarang tidak overclaim tentang shelter yang belum tervalidasi
  - screenshot validasi `ScreenCapture_MatchUI_Guidance_Briefing` menunjukkan panel briefing lebih jujur dan lebih mudah dipindai
- `MatchUI` sekarang juga punya `Field Kit` canonical untuk tool utility:
  - tombol `SCAN`, `GARAM`, `SALIB`, `DUPA` hadir di surface runtime `MatchUI`
  - shortcut keyboard `[1] [2] [3] [4]` hidup pada jalur UI canonical, bukan debug path terpisah
  - event utility `SaltPlaced`, `SaltTriggered`, `CrucifixPlaced`, `CrucifixTriggered`, `SmudgeActivated`, `GhostRepelled`, dan `HuntBlocked` sekarang memberi feedback ke client tanpa memaksa panel journal terbuka
  - default client tool utility tidak lagi auto-claim `nearGhostRoom`, jadi tool benar-benar dipasang sebagai field tool pemain
- validasi live Studio terbaru membuktikan:
  - `MatchUI.FieldKitFrame.Visible = true` saat match aktif
  - tekan `[2]` menghasilkan `Garam aktif. Menunggu ghost menginjak area ini.`
  - `Workspace.ActiveMatches.Match_match_1.InvestigationTools` berisi model runtime nyata:
    - `Garam_*`
    - `Salib_*`
    - `Dupa_*`
  - `JournalUI.MainPanel.Visible` tetap `false` saat event utility masuk, jadi feedback non-intrusif benar-benar berjalan
- panel modular lain masih perlu dirapikan agar ownership UI sepenuhnya konsisten

Pekerjaan:

- `RoyalPassUI`
- `ShopUI`
- `ProfileUI`
- `JournalUI`
- `MatchUI`
- `LobbyUI`
- `LeaderboardUI`
- ubah right rail menjadi stack fixed top-to-bottom dengan affordance mobile yang lebih jelas
- validasi nyata `RoomBrowserUI` compact/mobile pada device emulator atau handset
- validasi nyata `RoyalPassUI` compact/mobile pada device emulator atau handset

Done jika:

- semua panel utama punya owner file yang jelas

### 13. Polish audio dan visual

Status:

- in progress
- surface preview map aktif sudah naik dari placeholder generik ke visual prosedural source-owned
- `LeaderboardUI` active snapshot juga sudah naik dari text dump ke deck visual source-owned
- debt polish yang masih tersisa tetap besar:
  - ambient loops final
  - signature UI click audio final jika nanti ingin mengganti fallback built-in
  - jumpscare cues final
  - material/lighting pass map
  - icon dan asset visual konten lain
- hygiene audio terbaru menutup dua debt yang paling menipu debugging:
  - `AmbientLoop_Main` dikosongkan lagi supaya ambience tidak diam-diam memakai asset heartbeat
  - `GhostManifest_01` sekarang dibedakan dari `GhostWhisper_01`, jadi manifest dan whisper tidak lagi memakai template yang sama
- validasi live Studio terbaru setelah restart play membuktikan:
  - `AmbientLoop_Main.SoundId = ""`
  - `GhostManifest_01.SoundId = rbxassetid://139204195403262`
  - `GhostWhisper_01.SoundId = rbxassetid://83336813491039`
- routing cue audio terbaru sekarang lebih jujur terhadap konteks:
  - `GhostInteraction` server tidak lagi selalu memaksa `ghost_interaction`
  - `WhisperSound/FakeGhostSound -> ghost_whisper`
  - `FakeFootsteps -> ghost_fake_footsteps`
  - `FakeManifestation -> ghost_manifest`
  - `ObjectThrow -> ghost_object_throw`
  - client `SoundSystem` sekarang membaca cue itu untuk memilih template ghost/environment yang lebih masuk akal
- `Jumpscare_01` juga tidak lagi memakai asset countdown:
  - sekarang memakai `rbxassetid://138329686293368`
  - client `JumpscareAudio` punya resolver khusus sendiri, tidak lagi hanya mengandalkan path default generik
- validasi live Studio terbaru membuktikan:
  - `TriggerJumpscare` menghasilkan debug runtime:
    - `PasrahAudioLastCategory = JumpscareAudio`
    - `PasrahAudioLastTemplate = Jumpscare_01`
    - `PasrahAudioLastCue = jumpscare_stinger`
    - `PasrahAudioLastSoundId = rbxassetid://138329686293368`
- `AudioController` sekarang juga tidak lagi membawa bug service import tersembunyi:
  - `Players` kini di-resolve eksplisit
  - reverb map sekarang diterapkan di boot lobby dan ikut membaca `PhaseChanged.mapId`
  - baseline:
    - lobby `LobbySocialHub -> Enum.ReverbType.Room`
    - `HauntedHouse -> Enum.ReverbType.StoneCorridor`
    - `EmptyBuilding -> Enum.ReverbType.Hallway`
- `ButtonClick_01` sekarang tidak lagi memakai bunyi UI default Roblox yang terlalu generik:
  - slot canonical dipindah ke `rbxassetid://115959318`
  - playback UI sekarang `SingleInstance` agar spam klik tidak menumpuk berantakan
  - jitter kecil tetap dipertahankan supaya bunyinya tidak terasa datar
- validasi live/source terbaru:
  - template runtime live `ReplicatedStorage.Assets.Audio.UI.ButtonClick_01.SoundId = rbxassetid://115959318`
  - klik tombol lobby canonical tetap berhasil membuka `RoomBrowserUI`, jadi jalur owner `connectButtonPress()` tetap sehat setelah pass ini
- pass map atmosphere sekarang tidak lagi hanya offset tunggal:
  - `LobbySocialHub`, `HauntedHouse`, `EmptyBuilding`, `AbandonedPalace`, dan `StudioMMNineteen` punya profile `Density/Offset/Color/Decay/Glare/Haze` sendiri
  - `VFXController` juga sekarang membaca `PhaseChanged.mapId`, bukan hanya `MatchStarted`, sehingga profile map benar-benar applied pada jalur runtime client yang canonical
- validasi live Studio terbaru membuktikan perpindahan atmosfer:
  - lobby baseline: `density=0.24`, `offset=0.10`, `glare=0.08`, `haze=1.2`
  - setelah `HostStart(HauntedHouse)` dan phase `Briefing`: `density=0.44`, `offset=0.27`, `glare=0.14`, `haze=2.1`
- pass lighting baseline sekarang juga tidak lagi netral tunggal:
  - `VFXController` kini memegang profile `ClockTime/Brightness/ExposureCompensation/Ambient/OutdoorAmbient/Diffuse/Specular` per map
  - lobby dan map aktif sekarang beda bukan hanya lewat fog, tetapi juga tone lighting
  - validasi live Studio terbaru:
    - lobby `LobbySocialHub`: `ClockTime=14.6`, `Brightness=2.25`, `Exposure=0`
    - `HauntedHouse` briefing: `ClockTime=1.35`, `Brightness=1.72`, `Exposure=-0.28`
- pass post-grade map sekarang juga sudah naik:
  - `SensoryMapGrading` dan `SensoryMapBloom` sekarang source-owned di `VFXController`
  - tiap map punya baseline `grade` dan `bloom` sendiri, sehingga karakter visual tidak hanya mengandalkan fog + lighting
  - validasi live Studio terbaru:
    - lobby:
      - `grade contrast=0.04`, `saturation=-0.02`, `bloom intensity=0.18`
    - `HauntedHouse` briefing:
      - `grade contrast=0.10`, `saturation=-0.16`, `bloom intensity=0.07`
- catatan kandidat ambience:
  - kandidat Roblox `Cloudy Space (7399811837)` dan `No Light (7399814871)` sudah dicek lewat `MarketplaceService:GetProductInfo()`
  - keduanya `IsPublicDomain = false`, jadi tidak dipakai sebagai solusi publish-safe

Pekerjaan:

- map preview
- ambient loops
- impact sounds
- jumpscare cues
- material and lighting polish

## P3 - Publish Readiness

### Flashlight hand/viewmodel slice

Status:

- completed baseline
- flashlight asset `516522664` sekarang sudah masuk ke source-controlled path melalui `shared/GameData/FlashlightConfig.lua`
- mesh/texture/toggle click sound sudah canonical untuk client FPV dan server sync
- `CameraController` tidak lagi hanya mengandalkan flashlight procedural
- blocker lama "hands are flashlight" sudah ditutup
- residual polish yang masih boleh dikerjakan belakangan:
  - silhouette tangan masih bisa dibuat lebih natural
  - material/skin readability bisa dipoles lagi saat pass visual akhir
  - mobile/brightness balancing masih bisa disempurnakan bersamaan dengan pass UI/VFX berikutnya

### 14. Persistence nyata

Status:

- in progress
- `DataPersistenceService` sekarang expose ledger receipt persisten (`HasProcessedReceipt` / `MarkReceiptProcessed`) untuk menurunkan risiko grant ulang setelah restart session
- `StudioE2EControlSystem` sekarang punya action `GetPersistenceMode` untuk cek mode persistence runtime secara eksplisit saat playtest
- validasi live terbaru `GetPersistenceMode` mengembalikan:
  - `mode=mock`
  - `hasDataStore=false`
  - `allowStudioDataStore=false`
  - ini membuat status mock-vs-real tidak lagi asumsi buta di fase QA
- blocker utama tetap:
  - belum ada validasi non-mock end-to-end di environment target publish
  - belum ada uji migration/failover lintas versi schema

Pekerjaan:

- validasi di lingkungan non-mock
- audit schema player data
- failover dan migration plan

Done jika:

- data session penting tersimpan dan pulih dengan benar

## Update 2026-04-05 19:42 ICT

- `P3.14 Persistence nyata` naik lagi di sisi schema dan lifecycle pemain:
  - `DataPersistenceService` sekarang punya `profileSchemaVersion = 2` dan metadata record:
    - `meta.schemaVersion`
    - `meta.migratedFromVersion`
    - `meta.lastSavedAt`
  - diagnostics runtime sekarang expose:
    - `mode`
    - `dataStoreName`
    - `trackedPlayers`
    - `schemaVersion`
    - `lastProfileLoad`
    - `lastProfileSave`
  - `ProfileSystem` tidak lagi hanya mengandalkan event `PlayerEnteredLobby`:
    - existing player fallback load saat startup
    - `Players.PlayerAdded -> LoadProfile`
    - `Players.PlayerRemoving -> SaveProfile`
    - `BindToClose -> flush SaveProfile` untuk pemain yang masih ada
- validasi MCP:
  - build source sukses: `_tmp_persistence_schema_build.rbxlx`
  - mock legacy profile `profile:123`:
    - `loadSchema = 2`
    - `migratedFrom = 1`
    - `saveSchema = 2`
  - lifecycle controller stub:
    - `added = 2`
    - `removing = 1`
- status:
  - **SELESAI (profile lifecycle + schema diagnostics baseline)**.
  - **PENDING** tetap pada non-mock validation, schema migration live test lintas versi, dan failover target publish.

### 15. Monetization bridge Roblox

Status:

- in progress
- `PurchaseEvent` tidak lagi dianggap final owner transaksi untuk item `Robux`
- server sekarang punya bridge resmi ke `MarketplaceService` untuk:
  - `PromptGamePassPurchaseFinished`
  - `ProcessReceipt`
  - ownership sync `UserOwnsGamePassAsync`
- `ShopSystem` sekarang mengenali item katalog dengan metadata:
  - `currency`
  - `marketplaceType`
  - `marketplaceId`
  - `entitlementKey`
  - `royalPassPremium`
- UI shop sekarang siap menerima `PurchasePromptRequested` dan membuka prompt Roblox dari client canonical
- validasi live memastikan purchase MM lama tidak regress:
  - request `eq_sanitypill_standard` tetap diproses pada jalur lama
  - hasil runtime tetap jujur `PurchaseProcessed(success=false, reason=insufficient_currency)`
- katalog shop aktif sekarang benar-benar terisi:
  - total `31` item (`MM=14`, `PP=7`, `Robux=10`)
  - jalur `PP` sudah ada sebagai prestige soft-currency
  - jalur `PP -> MM` juga sudah source-controlled sebagai exchange soft-currency in-game
  - jalur `Robux` sudah source-controlled sebagai slot produksi (`GamePass` + `DeveloperProduct`)
- harness monetization Studio sekarang punya probe readiness cepat:
  - action `StudioE2EControl:GetShopReadiness`
  - validasi live terbaru mengembalikan:
    - `total=31 MM=14 PP=7 Robux=10 disabled=10 robuxMissingId=10`
  - ini menutup blind spot “shop terlihat ada item, tapi status readiness Robux tidak terukur”
- guard transaksi sekarang lebih ketat dan konsisten:
  - validasi saldo mengikuti mata uang item (`MM/PP`), tidak lagi hardcoded `MM`
  - refund pembelian gagal mengikuti mata uang item (`MM/PP`), tidak lagi hardcoded `MM`
  - item `enabled=false` ditolak sebagai `item_disabled` dari server
  - gift path juga menolak item disabled dan menolak item `Robux`
- ledger receipt `DeveloperProduct` sekarang tidak lagi murni in-memory:
  - `ShopSystem` kini memeriksa receipt cache lokal **dan** ledger persisten `DataPersistenceService`
  - receipt yang sudah pernah diproses akan dipetakan kembali ke cache runtime lalu langsung dianggap `PurchaseGranted`
  - saat grant berhasil, receipt juga ditulis ke ledger persisten sehingga restart server tidak membuka grant ulang untuk `PurchaseId` yang sama
- validasi live terbaru:
  - jalur shop `MM` tetap sehat (`eq_saltbag_reinforced -> success=true`)
  - tidak muncul error startup baru pada jalur `ShopSystem` sesudah hardening receipt ledger
- jalur prestige `PP` sekarang juga sudah tervalidasi live sebagai reward endgame:
  - `RewardCalculationSystem` mengirim `ppReward` ke `MatchRewardSummary`
  - playtest Studio terbaru menghasilkan:
    - wallet before `PP=37`
    - reward summary `ppReward=2`
    - wallet after `PP=39`
  - artinya `PP` bukan lagi mata uang dekoratif di shop
- validasi monetization live terbaru:
  - `PurchaseItem(pp_to_mm_medium)` sukses menukar `PP -12` menjadi `MM +4200`
  - `GrantMarketplacePurchase(pp_pack_small)` sukses memberi `PP +10`
  - `GrantMarketplacePurchase(mm_pack_small)` sukses memberi `MM +2500`
- fairness Ranked sekarang dijaga oleh source, bukan hanya kebiasaan desain:
  - helper item diberi label `ClassicOnly`
  - runtime Ranked menonaktifkan bonus `Reinforced Salt`, `Spirit Box` modded/elite, dan `Sanity Pill` helper
  - validasi live yang sudah tembus:
    - `Ranked`: `Garam` base stock (`usesRemaining = 2` setelah 1 pakai)
    - `Classic`: `Garam` reinforced stock (`usesRemaining = 3` setelah 1 pakai)
- UI shop sekarang menandai item yang belum siap:
  - tombol `SETUP` untuk item `Robux` yang `marketplaceId` belum valid
  - klik item yang belum siap tidak mengirim request buta ke server
- blocker tersisa:
  - belum ada item source-controlled yang benar-benar punya `gamePassId/productId` nyata dari Creator Hub
  - jadi jalur Robux production belum bisa ditutup end-to-end tanpa input manual dari Creator Hub

Pekerjaan:

- isi `marketplaceId` nyata pada `shared/DataTypes/ShopMarketplaceConfig.lua` (override utama)
- jalankan smoke test `cancel / success / relog ownership sync / duplicate receipt`
- rapikan surfacing `PP` earn di UI/flow pemain agar jalur prestige tidak terasa tersembunyi walau reward servernya sudah hidup

Done jika:

- pembelian Roblox benar-benar bekerja end-to-end

## Update 2026-04-05 19:58 ICT

- `P3.15 Monetization bridge Roblox` naik lagi di sisi relog/ownership sync:
  - server `ShopSystem.Controller` sekarang mengirim `MarketplaceOwnershipSynced` setelah `UserOwnsGamePassAsync` berhasil mensinkron entitlement yang memang dimiliki pemain
  - payload itu membawa snapshot + `itemIds` yang benar-benar tersinkron
  - client `ShopUI` sekarang menerima sync ownership ini tanpa membuka shop secara paksa
  - copy UI juga lebih jujur untuk:
    - `ownership_synced`
    - `receipt_granted`
    - `purchase_cancelled`
- validasi:
  - build source sukses: `_tmp_monetization_sync_build.rbxlx`
- status:
  - **SELESAI (ownership sync surfacing baseline)**.
  - **PENDING** tetap pada Creator Hub `marketplaceId` nyata dan smoke test production prompt `cancel/success`.

### 16. Licensing dan attribution

Status:

- **SELESAI (attribution baseline + verified Pocong provenance)**.
- ledger awal sudah dibuat di `reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- validasi live `MarketplaceService:GetProductInfo()` sekarang sudah menutup sebagian asset aktif:
  - `Heartbeat` terverifikasi account-owned (`Creator = ZyraaaVex`)
  - `Jumpscare_01` terverifikasi `IsPublicDomain = true`
  - pack animasi aktif terverifikasi sebagai animasi default `Roblox`
- source eksternal `Pocong` kini juga sudah diverifikasi:
  - source URL final: `https://sketchfab.com/3d-models/pocong-d84121c5b6084c72851113afbdbd5b99`
  - author: `alterego.visual`
  - lisensi: `CC BY 4.0`
  - attribution runtime sekarang source-controlled lewat `src/shared/DataTypes/AssetAttributionCatalog.lua`
- blocker yang masih nyata sekarang menyempit ke:
  - satu slot audio canonical masih `replace/remove` (`AmbientLoop_Main`)
  - cleanup asset legacy dan arsip audit manual tambahan bila ingin bukti screenshot tersimpan di repo
- replacement queue dan helper apply sekarang sudah siap:
  - `reports/AUDIO_REPLACEMENT_PLAN_2026-04-03.md`
  - `scripts/set-audio-asset-ids.ps1`
- validasi live `MarketplaceService:GetProductInfo()` dan client playback sekarang juga sudah menutup beberapa asset aktif:
  - `EnvironmentalCreak_01`
  - `GhostManifest_01`
  - `HuntStart_01`
  - `CountdownTick_01`
  - footstep set `Wood/Concrete/Metal`
- `ButtonClick_01` juga sudah punya signature click canonical (`rbxassetid://115959318`), jadi bukan lagi blocker licensing.
- UI sekarang juga punya jalur attribution footer legal untuk menu utama, sehingga kewajiban attribution tidak hanya tinggal catatan dokumen.

Pekerjaan:

- audit seluruh asset eksternal
- catat lisensi dan atribusi
- gantikan asset yang tidak aman untuk komersial

Done jika:

- tidak ada asset komersial yang status lisensinya meragukan

### 17. QA dan perf gate

Status:

- **SELESAI**.
- baseline Studio single-client sekarang sudah tersedia lewat harness `StudioE2EControl`:
  - `GetQAGateSnapshot`
  - `GetQAGateReadiness`
  - `StartSoloMatch`
- baseline yang sudah tertutup:
  - memory baseline
  - network sanity untuk Studio single-client
  - server log cleanliness baseline
- multi-player test nyata dipindah jelas ke checklist manual pra-publish:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/QA_MULTIPLAYER_MANUAL_CHECKLIST_2026-04-06.md`

Pekerjaan:

- memory baseline
- network sanity
- server log cleanliness
- multi-player test

Catatan reality scan:

- snapshot lobby clean:
  - `players=1`
  - `activeMatches=0`
  - `totalMemoryMb≈2096.96`
  - `physicsFps≈59.90`
  - `warnings=0`
  - `errors=0`
- snapshot match solo clean:
  - `players=1`
  - `activeMatches=1`
  - `phase=PreparationPhase`
  - `totalMemoryMb≈2150.98`
  - `physicsFps≈60.04`
  - `warnings=0`
  - `errors=0`
- bug runtime yang ditemukan QA dan sudah ditutup:
  - `Client.UI.Main` sempat gagal start karena `shouldShowShopFilter()` dipanggil sebelum ter-bind
- `ForceHunt` harness sekarang menolak phase yang belum siap dengan hasil jujur `match_not_hunt_ready`, jadi tidak lagi menambah warning palsu ke log runtime.
- raw Studio console masih menampilkan info bootstrap berulang, tetapi snapshot `LogService` untuk warning/error saat baseline ini tetap bersih.

Done jika:

- pass gate minimum sebelum publish
- smoke test multi-player nyata dengan client kedua selesai atau jelas dipindah ke checklist manual pra-publish

## Update 2026-04-06 00:28 ICT

- `Phase 17 QA dan perf gate` resmi ditutup:
  - harness Studio sekarang punya `GetQAGateReadiness` selain `GetQAGateSnapshot`.
  - multi-player smoke test dua client dipindah tegas ke checklist manual pra-publish, bukan dibiarkan menggantung sebagai pending abstrak.
- validasi:
  - build source sukses:
    - `_tmp_phase17_completion_build.rbxlx`
- status:
  - **SELESAI (phase 17 complete)**.
  - **NEXT**: lanjut ke phase penutup berikutnya yang masih actionable.

### 18. Final pass perubahan dan restruktur LOBBY + MAP IN GAME

Status:

- **SELESAI**.
- fase ini memang baru disentuh setelah blocker E2E, vertical slice, content fill utama, dan publish gate inti tertutup
- slice pertama yang sudah masuk:
  - lobby zone taxonomy sekarang disejajarkan ke geometri lobby aktif
  - masuk area matchmaking tidak lagi auto-queue
  - UI lobby sekarang menerima `LobbyZoneFocused` feedback yang lebih jujur untuk `MatchmakingZone` dan `ShopZone`
  - feedback lobby tersebut sekarang benar-benar visible di layar, bukan hanya terisi text-nya
- slice map yang baru tertutup:
  - runtime sekarang mensintesis `InteractionPoints` yang hilang dari `Rooms`, jadi coverage interaksi tidak lagi timpang di map besar
  - validasi live:
    - `EmptyBuilding` dari `8 -> 14` interaction points (`synthetic=6`)
    - `AbandonedPalace` dari `8 -> 18` interaction points (`synthetic=10`)

Pekerjaan:

- restruktur final `Lobby` dari sisi layout, hierarchy panel, affordance mobile, visual hierarchy, dan readability brand
- restruktur final `Map` in-game dari sisi traversal, landmark, access logic, hiding affordance, dan art/layout pass akhir
- selaraskan bahasa visual antara lobby dan in-game agar identitas brand, kenyamanan baca, dan retensi terasa konsisten
- audit ulang overlap, tumpang tindih, dan affordance palsu sebelum publish

Done jika:

- `Lobby` dan `Map` in-game sudah melewati pass restruktur final tanpa membuka blocker E2E baru
- tidak ada tech debt layout besar yang sengaja ditinggalkan untuk sesudah publish

Catatan:

- ingatkan user secara eksplisit saat backlog sudah sampai tahap ini
- sudah sampai tahap ini; eksekusi boleh lanjut bertahap tanpa melompat ke retention/final discussion dulu

### 19. Final discussion: Reason to return (retention loop)

Status:

- **SELESAI**.
- blueprint retention sudah disusun di:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/RETENTION_LOOP_BLUEPRINT_2026-04-06.md`

Pekerjaan:

- rumuskan `tomorrow reason to return` yang konkret setelah user install dan enjoy
- desain `daily quest/streak` untuk extrinsic motivation
- desain `meta progression` (unlock tree/skill tree/progression lane)
- desain `social pressure loop` (leaderboard cadence, guild/clan foundation, social comparison)
- desain `content rotation` (daily challenge, weekly modifier, live event cadence)
- desain mekanik replayability khusus horror:
  - randomization yang tetap fair
  - mode speedrun/time-attack
- desain `achievement hunting` yang tidak sekadar grind
- desain `unlockable lore/story pieces` sebagai long-tail retention hook

Done jika:

- ada blueprint retention yang bisa dieksekusi bertahap tanpa merusak arsitektur runtime sekarang
- semua loop di atas punya owner system, cadence, reward source, dan anti-exploit baseline
- kita bahas ini di akhir sesuai prioritas user

## Update 2026-04-06 00:51 ICT

- `Phase 19 Final discussion` ditutup lewat blueprint retention tertulis:
  - daily quest / streak
  - meta progression
  - social pressure
  - content rotation
  - replayability horror
  - achievement hunting
  - lore unlock
- status:
  - **SELESAI (phase 19 complete)**.
  - **NEXT**: masuk publish review final dan eksekusi checklist manual yang tersisa.

### 20. Final polish tambahan (Windows FPV + Camera realism)

Status:

- **SELESAI**.

Pekerjaan:

- mode Windows FPV:
  - sediakan satu toggle/tombol/hotkey untuk melepas cursor mouse agar UI tetap bisa diklik tanpa friction
  - pastikan toggle ini tidak merusak input flow movement + camera look saat kembali lock
- head bobbing:
  - pulihkan implementasi head bobbing yang sempat ada tapi sekarang hilang
  - buat intensity adaptif agar tetap nyaman (tidak motion-sickness) lintas perangkat
- flashlight realism:
  - naikkan kualitas feel flashlight agar lebih realistis (beam behavior, transition, handling), tetap menjaga readability gameplay

Done jika:

- pemain Windows di FPV bisa switch lock/unlock cursor dengan cepat untuk interaksi UI
- head bobbing aktif kembali dan tervalidasi nyaman dipakai
- flashlight terasa lebih natural tanpa merusak visibilitas/hunt readability

## Update 2026-04-06 00:40 ICT

- `Phase 20 Final polish tambahan` resmi ditutup:
  - FPV sekarang punya state cursor mode yang lebih eksplisit (`Default`, `LockedFPV`, `UnlockedUI`).
  - head bob sekarang adaptif terhadap kecepatan gerak dan turun drastis saat cursor UI dilepas.
  - flashlight carry/viewmodel sekarang punya breath, look sway, carry offset, dan motion tuning yang lebih natural.
- validasi:
  - build source sukses:
    - `_tmp_phase20_completion_build.rbxlx`
- status:
  - **SELESAI (phase 20 complete)**.
  - **NEXT**: tinggal phase diskusi final yang memang deferred by design.

## Update 2026-04-03 23:59 ICT

- hiding non-safe-zone sekarang tidak lagi kosong:
  - `ClosetHidingMechanic` sudah diregister resmi ke `SystemRegistry`
  - runtime `HideSpotPrompt` sekarang terpasang otomatis pada `Room_ClosetA` dan `Room_ClosetB` di `HauntedHouse`
  - prompt toggle occupancy sekarang jujur:
    - saat pemain masuk hide: action text berubah ke `Keluar`
    - saat pemain keluar hide: action text kembali ke `Bersembunyi`
- `HidingSystem` tidak lagi merusak hide state `Closet/Locker` pada tick safe-zone
- auto-exit closet sekarang jalan tanpa bergantung pada publisher `GameplayTick` yang ternyata tidak ada di runtime:
  - `ClosetHidingMechanic` sekarang punya loop internal ringan untuk sync hide spot + occupancy
  - volume check closet sekarang memakai toleransi vertikal yang cocok untuk `HumanoidRootPart`, bukan mentah tinggi part lantai `1 stud`
- `StudioE2EControlSystem` sekarang punya action resmi:
  - `EnterHide`
  - `ExitHide`
  - ini dipertahankan sebagai harness validasi server-authoritative, bukan debug sekali pakai
- validasi live final yang sudah tertutup:
  - `HideSpotPrompt` muncul di `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Rooms.Room_ClosetA`
  - saat posisi pemain di dalam `ClosetA`:
    - `PasrahHideState = Hidden`
    - `PasrahHideSpotType = Closet`
    - `PasrahHideZoneId = Room_ClosetA`
    - prompt = `Keluar`
  - saat posisi pemain keluar dari volume closet:
    - `PasrahHideState = Exposed`
    - `PasrahHideSpotType = None`
    - `PasrahHideZoneId = ""`
    - prompt = `Bersembunyi`
- status jujur setelah slice ini:
  - baseline hiding non-safe-zone untuk `HauntedHouse` sudah playable
  - debt berikutnya bukan lagi “apakah closet hiding bekerja”, tetapi:
    - perluasan hiding spot final lintas map
    - aturan survive hunt yang lebih kaya dari hanya safe zone + closet baseline
- `GameplayTick` canonical juga sudah dipulihkan:
  - `GameplayLoopController` sekarang benar-benar mempublish tick runtime saat match aktif
  - validasi live memastikan `SafeZone_1` kembali auto-apply:
    - masuk zone -> `PasrahHideState = Hidden`, `PasrahHideSpotType = SafeZone`
    - keluar zone -> `PasrahHideState = Exposed`, `PasrahHideSpotType = None`
  - artinya loop survival dasar tidak lagi diam-diam bergantung pada publisher yang hilang
- hide spot lintas map sekarang mulai data-driven:
  - map data kini punya `hideSpotRooms` (`HauntedHouse`, `EmptyBuilding`, `StudioMMNineteen`, `AbandonedPalace`)
  - `ClosetHidingMechanic` membaca daftar itu lewat `MapConfigSystem` (fallback `Closet/Locker` tetap ada)
  - validasi live sekarang menutup bukti sampai lifecycle dasar:
    - `Workspace.ActiveMatches.Match_match_1.EmptyBuilding.EmptyBuilding.Rooms.Room_Storage` memiliki `HideSpotPrompt`
    - `EnterHide` via `StudioE2EControl` menghasilkan:
      - `PasrahHideState = Hidden`
      - `PasrahHideSpotType = Closet`
      - `PasrahHideZoneId = Room_Storage`
      - `HideSpotOccupied = true`
    - saat pemain dipindahkan keluar volume room:
      - `PasrahHideState = Exposed`
      - `PasrahHideSpotType = None`
      - `PasrahHideZoneId = ""`
      - `HideSpotOccupied = false`
  - `MatchCreated` juga sudah dijadikan trigger registrasi awal agar prompt tidak selalu menunggu fase lanjut
- blocker yang tersisa untuk slice ini sekarang turun level:
  - perluasan coverage hide spot ke lebih banyak room/map, bukan lagi pembuktian satu lifecycle enter/exit dasar
  - teachability survive hunt masih perlu ditingkatkan agar pemain paham kapan memakai `SafeZone`, kapan memakai room hide spot, dan kapan hanya putus `line-of-sight`

## Urutan Praktis

Urutan yang paling masuk akal dari titik sekarang:

1. P0.1 sampai P0.5
2. P1.6 sampai P1.9
3. P2.10 sampai P2.13
4. P3.14 sampai P3.17

## Hal yang Jangan Dilakukan Dulu

- jangan tambah ghost baru sebelum satu ghost vertical slice beres
- jangan hidupkan kembali `Rojo Two-Way Edit`
- jangan andalkan state Studio-only tanpa mirror ke repo
- jangan aktifkan monetization publik sebelum licensing dan commerce bridge benar-benar siap

## Update 2026-04-03 22:53 ICT

- blocker `Preparing -> MatchStarted` yang sempat mengganggu validasi hiding lintas map sekarang sudah tertutup:
  - `MatchSystem.Controller:OnPlayerQueued` tidak lagi memanggil `StartMatch()` secara sinkron di callback EventBus
  - `MatchService:StartMatch()` tidak lagi menggantung di jalur `task.wait(1.5)`; continuation start sekarang dijalankan via `task.delay`
  - `LobbySystem.Controller` juga sudah dihardening agar countdown host-start tidak lagi gagal diam-diam tanpa debug attr
- runtime patch match start juga sekarang lebih ringan:
  - `MapRuntimePatches.patchInteractionPoints()` tidak lagi menjalankan `PathfindingService:ComputeAsync()` besar-besaran pada setiap clone map
  - interaction point runtime kembali deterministic memakai posisi room + explicit override yang sudah ada
- `HidingSystem` sekarang punya prioritas yang benar saat room hide spot overlap dengan safe zone:
  - hide eksplisit `Closet/Locker` tetap dipertahankan
  - jika pemain keluar dari hide eksplisit tetapi masih berdiri di dalam safe zone, state kembali ke `SafeZone`
- validasi live yang sudah tertutup:
  - `EmptyBuilding`
    - `PasrahLastHostStartCommit = commit ok=true err=nil roomId=1`
    - `PasrahLastMatchStartTrace = match=match_1 players=1 teleported=1 phase=PreparationPhase map=EmptyBuilding mode=Classic`
    - `PasrahLastTeleportTrace` menunjukkan pipeline teleport lengkap sampai `teleported_counted`
    - `Room_Storage`:
      - `EnterHide` -> `PasrahHideState = Hidden`, `PasrahHideSpotType = Closet`, `PasrahHideZoneId = Room_Storage`, prompt = `Keluar`
      - `ExitHide` sambil tetap berada di storage -> `PasrahHideState = Hidden`, `PasrahHideSpotType = SafeZone`, `PasrahHideZoneId = SafeZone_2`, prompt = `Bersembunyi`
  - `HauntedHouse`
    - sanity regression pass sukses di `Room_ClosetA`
    - hasil tetap: `PasrahHideState = Hidden`, `PasrahHideSpotType = Closet`, `PasrahHideZoneId = Room_ClosetA`, prompt = `Keluar`
- status jujur setelah slice ini:
  - blocker fase match yang sebelumnya membuat validasi lintas map intermittent sudah tidak menjadi alasan utama lagi
  - fondasi runtime sekarang cukup stabil untuk lanjut ke slice berikutnya:
    - traversal/map polish
    - hiding/survival affordance lanjutan
    - UI/mobile polish dan content fill

## Update 2026-04-03 23:18 ICT

- traversal/interaksi map sekarang memakai fallback global berbasis pintu, bukan sekadar titik tengah room:
  - jika ada pintu bernama `Door_<RoomName>`, interaction point otomatis di-anchor dari pintu ke arah dalam room
  - explicit door override tetap dipakai untuk room yang butuh jarak khusus
  - hanya `HauntedHouse.Interact_HallwayMain` yang tetap fallback ke pusat room karena memang tidak punya pintu matching
- pendekatan ini mengganti override angka liar yang tidak lagi representatif terhadap layout room modern
- validasi tertutup:
  - build source sukses: `_tmp_map_patch_validation.rbxlx`
  - edit-mode clone validation menunjukkan coverage global:
    - `AbandonedPalace`: `8/8` interaction point ter-anchor pintu
    - `StudioMMNineteen`: `8/8` interaction point ter-anchor pintu
    - `EmptyBuilding`: `8/8` interaction point ter-anchor pintu
    - `HauntedHouse`: `7/8` interaction point ter-anchor pintu, `Interact_HallwayMain` tetap fallback room-center
  - contoh hasil patch:
    - `HauntedHouse`
      - `Interact_Kitchen = 1220.25, 2, -25`
      - `Interact_Bedroom1 = 1178.75, 2, 35`
      - `Interact_HallwayMain = 1200, 2, 0`
    - `EmptyBuilding`
      - `Interact_WorkspaceOpen = 800, 14, 13.75`
      - `Interact_OfficeB = 774.75, 2, 35`
      - `Interact_Bathroom1 = 826.25, 2, 35`
  - smoke test live:
    - `HostStartCommit = commit ok=true err=nil roomId=1`
    - `MatchStartTrace` kembali sukses pada `EmptyBuilding` dan `HauntedHouse`
    - runtime clone membaca posisi baru yang sama persis, termasuk:
      - `EmptyBuilding.Interact_WorkspaceOpen = 800, 14, 13.75`
      - `HauntedHouse.Interact_LivingRoom = 1183.75, 2, 0`
      - `HauntedHouse.Interact_HallwayMain = 1200, 2, 0`
- dampak:
  - interaction point lebih dekat ke akses masuk room
  - traversal visual lebih logis untuk map yang belum full redesign
  - jalur start match tetap aman setelah patch

## Update 2026-04-04 01:57 ICT

- `P2.12 Rapikan UI modular` naik satu tahap karena bypass single-open lobby sudah tertutup di owner pusat:
  - `UISystem:_closeConflictingWindows()` sekarang langsung menyinkronkan ulang auxiliary window, match window, refresh lobby/basic panel, dan rail layout setelah state conflict diubah
  - ini menutup jalur kebocoran saat `LobbyToggleButton` membuka lobby sementara auxiliary window seperti `ShopUI` masih terlihat
- validasi live yang sudah tertutup:
  - boot playtest baru: `LobbyUI = true`, panel besar lain `false`
  - `ShopButton` -> `ShopUI = true`, panel besar lain `false`
  - `ShopUI terbuka` lalu klik `LobbyToggleButton` -> `LobbyUI = true`, `ShopUI = false`
  - `OpenRoomBrowserButton` -> `RoomBrowserUI = true`, panel besar lain `false`
  - `MenuButton` lalu `MainMenuUI.ProfileButton` -> `ProfileUI = true`, `MainMenuUI = false`
- build source sukses:
  - `_tmp_ui_single_open_fix.rbxlx`
- status jujur setelah slice ini:
  - aturan single-open panel besar lobby sudah tervalidasi live untuk jalur utama dan jalur silang yang sempat bocor
  - `P2.12` masih `in progress` hanya untuk sisa polish compact/mobile, bukan lagi karena owner conflict dasar

## Update 2026-04-04 02:11 ICT

- hiding/survival affordance naik satu level lagi tanpa menambah spot palsu:
  - `ClosetHidingMechanic` sekarang memberi world-space marker runtime pada hide spot canonical
  - marker hanya menyala saat `HuntStarted`, lalu mati lagi pada `HuntEnded/MatchEnded`
  - ini melengkapi `HideSpotPrompt` yang sebelumnya ada tetapi terlalu pasif untuk mengajari pemain survive hunt
- marker runtime baru untuk hide spot berisi:
  - outline world-space pada volume room hide spot
  - billboard label dengan nama room (`ClosetA`, `Storage`, dst.)
  - subtitle `Bersembunyi saat hunt`
- blocker teknis yang sempat membuat marker tidak hidup juga sudah ditutup:
  - `ClosetHidingMechanic.Controller` sekarang subscribe ke `HuntStarted` dan `HuntEnded`
- validasi live tertutup:
  - `HauntedHouse` -> `Room_ClosetA`
    - match start canonical sukses
    - `ForceHunt` sukses (`ok=true | action=ForceHunt | result=match=match_1 forced`)
    - runtime instance memiliki `HideSpotRuntimeMarker`
    - `HideSpotRuntimeMarker.Outline.Visible = true`
    - `HideSpotRuntimeMarker.Billboard.Enabled = true`
    - `HideSpotPrompt.ActionText = Bersembunyi`
    - `HideSpotLabel = ClosetA`
- dampak:
  - pemain sekarang punya affordance visual nyata untuk hide spot saat hunt, bukan hanya safe zone marker atau petunjuk teks UI
  - debt survival berikutnya bergeser ke perluasan/review distribusi hide spot lintas map, bukan lagi “spot ada tapi tidak terbaca”

## Update 2026-04-04 02:19 ICT

- follow-up client untuk survival guidance juga tertutup:
  - `Main.lua` sekarang membaca `HideSpotLabel` runtime dari room aktif bila tersedia
  - objective/hint hunt tidak lagi harus menebak nama spot hanya dari `PasrahHideZoneId`
- validasi live di `HauntedHouse` setelah teleport dekat `Room_ClosetA` dan `ForceHunt`:
  - `HideSpotLabel = ClosetA`
  - `ObjectiveLabel = Ghost dekat (4st). Putus line-of-sight, rotasi lewat pintu, lalu masuk ClosetA 4st. Jika tertutup, menuju SafeZone 1 10st.`
  - `HeaderCard.SecondaryLabel` menampilkan teks yang sama
- dampak:
  - guidance hunt sekarang memakai label runtime yang sama dengan affordance world-space hide spot
  - client dan server lebih sinkron saat menyebut nama refuge ke pemain

## Update 2026-04-04 02:26 ICT

- distribusi hide spot lintas map sudah dinaikkan dari baseline 1 titik/map ke baseline yang lebih playable:
  - `EmptyBuilding.hideSpotRooms`: `Storage`, `ArchiveRoom`, `SecurityRoom`
  - `AbandonedPalace.hideSpotRooms`: `StorageWing`, `ServantRoomA`, `ServantRoomB`
  - `StudioMMNineteen.hideSpotRooms`: `StorageRoom`, `Office`
- validasi live canonical (bukan asumsi file) berhasil:
  - `EmptyBuilding`:
    - `PasrahLastMatchStartTrace = ... map=EmptyBuilding ...`
    - `Room_Storage`, `Room_ArchiveRoom`, `Room_SecurityRoom` masing-masing memiliki `HideSpotPrompt`
  - `AbandonedPalace`:
    - `PasrahLastMatchStartTrace = ... map=AbandonedPalace ...`
    - `Room_StorageWing`, `Room_ServantRoomA`, `Room_ServantRoomB` masing-masing memiliki `HideSpotPrompt`
  - `StudioMMNineteen`:
    - `PasrahLastMatchStartTrace = ... map=StudioMMNineteen ...`
    - `Room_StorageRoom` dan `Room_Office` masing-masing memiliki `HideSpotPrompt`
- catatan teknis penting dari validasi ini:
  - jalur room-browser canonical saat ini menggunakan payload table `LobbyEvent:FireServer({ action = ... })`
  - format lama `FireServer(\"Action\", payload)` tidak lagi bisa dipakai sebagai basis validasi runtime
- dampak:
  - pemain tidak lagi dipaksa mengandalkan satu spot hide tunggal di map besar/sedang
  - affordance survival lintas map naik tanpa menambah spot palsu atau override map art manual

## Update 2026-04-04 02:27 ICT

- polish label hide spot runtime juga sudah ditutup:
  - formatter server sekarang memecah `camelCase` dan angka pada nama room hide spot
  - contoh: `SecurityRoom -> Security Room`, `ArchiveRoom -> Archive Room`, `ServantRoomA -> Servant Room A`
- validasi live `EmptyBuilding` membuktikan atribut runtime:
  - `Room_SecurityRoom.HideSpotLabel = Security Room`
  - `Room_ArchiveRoom.HideSpotLabel = Archive Room`
- dampak:
  - objective/hint hunt jadi lebih natural dibaca pemain
  - konsistensi bahasa antara marker world-space dan teks UI meningkat

## Update 2026-04-04 02:33 ICT

- fairness akses hide spot kini naik lewat prompt distance adaptif per room:
  - `HideSpotPrompt.MaxActivationDistance` tidak lagi fixed
  - server sekarang menghitung jarak prompt dari dimensi room hide spot
  - range dibatasi aman di `8..16` stud agar tidak overpowered
- hasil validasi live:
  - `AbandonedPalace` (`Room_StorageWing`, `Room_ServantRoomA`, `Room_ServantRoomB` ukuran `24x16`) -> `HideSpotPromptDistance = 9`
  - `StudioMMNineteen` (`Room_StorageRoom`, `Room_Office` ukuran `18x14`) -> `HideSpotPromptDistance = 8`
- dampak:
  - room hide spot yang lebih besar tidak lagi terasa “mati” karena prompt terlalu ketat
  - room kecil tetap ketat agar hunt tidak trivial

## Update 2026-04-04 02:53 ICT

- hardening drift client untuk kasus audio dobel/countdown dobel:
  - `ClientMain` sekarang punya instance singleton (`ClientMain.shared()`)
  - `StarterPlayerScripts/ClientBootstrap.client.lua` sekarang memakai singleton itu, bukan selalu `new()`
  - ini mencegah init/start service client ganda saat ada jalur bootstrap duplikat di runtime
- cleanup runtime liar di Studio edit-time:
  - `StarterPlayer.StarterPlayerScripts.LocalScript` legacy (script test evidence `TEST EVIDENCE TRIGGER`) dihapus dari DataModel edit-time
  - script liar itu sebelumnya ikut ter-copy ke `Players.<Player>.PlayerScripts.LocalScript` dan menambah noise event palsu
- validasi live:
  - build source sukses: `_tmp_client_singleton_guard.rbxlx`
  - setelah restart playtest, `PlayerScripts.LocalScript` legacy tidak muncul lagi
  - smoke flow UI tetap jalan:
    - `OpenRoomBrowserButton` bisa membuka `RoomBrowserUI`
    - `CreateRoomButton` bisa masuk `RoomPanel`
    - flow lanjut ke match masih hidup (`InMatch=true`, `MatchId=match_1`)
- dampak:
  - sumber paling berisiko untuk audio/event dobel di client sudah ditutup di level arsitektur, bukan sekadar patch gejala

## Update 2026-04-04 02:57 ICT

- bug UX `MapSelector` host room browser ditutup dengan perbaikan layout responsif:
  - root cause: pada viewport desktop pendek, layout non-compact membuat area kontrol host (`Ready/Start/Leave`) menumpuk area selector mode/map
  - efeknya: `MapSelector` sulit/tidak bisa diinteraksi konsisten
- patch:
  - `UISystem:_applyRoomBrowserSizing()` sekarang memaksa mode compact juga untuk viewport pendek (`usableHeight <= 700`)
  - ini menjaga urutan vertikal panel room menjadi scroll-based, bukan overlap absolute
- validasi live:
  - `MapSelector` dan `ReadyButton` tidak lagi overlap (`MapSelector.Y=562`, `ReadyButton.Y=854` pada sesi validasi)
  - interaksi `MapSelector` dapat membuka `MapDropdown.Visible = true` setelah panel berada pada posisi scroll yang tepat
- dampak:
  - kontrol host room browser lebih stabil di resolusi desktop pendek/laptop
  - jalur pilih map tidak lagi terblokir oleh tombol action panel bawah

## Update 2026-04-04 02:58 ICT

- audit ulang lisensi/ownership audio aktif (batch ID dari user) selesai di Studio runtime:
  - `Woodstep_01`, `Heartbeat`, `EnvironmentalCreak_01`, `CountdownTick_01`, `GhostManifest_01`, `MetalStep_01`, `ConcreteStep_01`, `TeleportDrop_01`
  - seluruh ID terverifikasi via `MarketplaceService:GetProductInfo()` sebagai creator `ZyraaaVex` (`IsPublicDomain=false`)
- implikasi publish gate:
  - daftar ID di atas tetap aman sebagai asset account-owned untuk project aktif
  - blocker lisensi audio yang tersisa tetap `AmbientLoop_Main` (slot ambience kosong), bukan broken ID dari batch ini

## Update 2026-04-04 03:00 ICT

- blocker audio slot kosong ditutup:
  - `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
  - `AudioContent` sekarang diisi `rbxassetid://138884191945388` (account-owned `ZyraaaVex`)
  - `Volume` dituning konservatif ke `0.18` untuk baseline ambience agar tidak menabrak cue hunt
- validasi live:
  - `ReplicatedStorage.Assets.Audio.Ambient.AmbientLoop_Main.SoundId = rbxassetid://138884191945388`
  - properti runtime slot sudah terbaca sebagai `Looped=true` dan bukan placeholder kosong
- implikasi publish gate:
  - blocker lisensi audio bergeser dari “slot ambience kosong” menjadi pure polish keputusan ambience brand final

## Update 2026-04-04 03:02 ICT

- hardening audio transisi untuk laporan “double audio”:
  - `UI.Main`:
    - default dedupe `TeleportOverlay` dinaikkan dari `0.75s` -> `4s`
    - event transisi yang berdekatan tidak lagi mudah memicu cue teleport berlapis
  - `SoundSystem.Main`:
    - tambah dedupe one-shot kategori `HuntAudio` (`2.25s` per cue)
    - ini mencegah event hunt start duplikat memutar cue yang sama dua kali beruntun
- validasi:
  - build source sukses: `_tmp_audio_dedupe_guard.rbxlx`
  - smoke play start/stop berhasil tanpa error sintaks

## Update 2026-04-04 03:04 ICT

- verifikasi dedupe hunt audio sudah dilakukan dengan probe lokal terkontrol:
  - trigger `HuntAudio` cue yang sama dua kali dalam jeda `0.2s`
  - hasil runtime count: `first=1 second=1` (tidak naik menjadi 2)
- dampak:
  - guard `HuntAudio` dedupe `2.25s` terbukti menahan playback duplikat cepat untuk cue yang sama

## Update 2026-04-04 03:09 ICT

- blocker manual lisensi `Pocong` dipersiapkan dengan template arsip bukti siap-isi:
  - `reports/POCONG_LICENSE_ARCHIVE_CHECKLIST_2026-04-04.md`
- isi template sudah mencakup:
  - URL sumber final
  - author
  - jenis lisensi
  - path screenshot bukti
  - attribution text Roblox-friendly
- tujuan:
  - mempercepat penutupan gate compliance tanpa bolak-balik format saat final publish

## Update 2026-04-04 03:10 ICT

- fix startup blocker `ShopSystem` dipastikan masuk commit:
  - menghapus pembacaan callback `MarketplaceService.ProcessReceipt` (read) yang memang tidak diizinkan Roblox API
  - flow sekarang hanya melakukan assignment callback resmi (`set`) tanpa restore via read-back
- dampak:
  - error boot `ProcessReceipt is a callback member ... get is not available` tidak lagi relevan pada source terbaru

## Update 2026-04-04 03:12 ICT

- hardening determinisme ghost untuk Studio E2E:
  - `GhostSystem.Service.InitializeMatch()` sekarang memprioritaskan forced ghost runtime Studio sebelum `match.ghostType`
  - tujuan: ketika force ghost diaktifkan untuk test, hasil spawn tidak diam-diam tertimpa nilai lama di match object

## Update 2026-04-04 03:57 ICT

- blocker shop `insufficient_currency` untuk item termurah sekarang tertutup pada baseline runtime:
  - wallet awal session ditetapkan ke `MM=1200`, `PP=12`, `Robux=0`
  - config global sekarang eksplisit punya `Economy.StartingWallet`
- validasi live via MCP (play mode) setelah restart:
  - `eq_saltbag_reinforced` -> `PurchaseProcessed(success=true)`
  - `pp_cos_head_nightoracle` -> `PurchaseProcessed(success=true)`
  - repeat cepat item yang sama menghasilkan guard expected (`already_owned` / `purchase_cooldown`)
- catatan penting untuk fase berikutnya:
  - sempat terdeteksi drift source lokal vs script Studio pada file economy/config
  - setiap anomali runtime harus divalidasi dengan baca script target di Studio, bukan asumsi dari file lokal saja
- implikasi ke prioritas:
  - “shop ada tapi tidak ada yang dijual” sudah bukan blocker aktif untuk MM/PP
  - sisa blocker monetization tetap pada aktivasi `Robux` (Creator Hub IDs) dan sinkronisasi workflow Rojo yang disiplin

## Update 2026-04-04 04:05 ICT

- stabilisasi transisi countdown/teleport masuk ke baseline:
  - countdown UI kini pakai detik authoritative server (`countdownSecondsLeft`) sebagai prioritas.
  - fallback `countdownEndsAt` hanya dipakai saat detik authoritative tidak tersedia.
- cue teleport kini single-cue:
  - `MatchPreparing` tetap menampilkan overlay tapi tanpa audio.
  - `MatchStarted` memutar satu cue teleport dengan guard `forceAudio`.
- validasi live:
  - flow host-start sukses sampai `MatchStarted`.
  - `RoomPanel` tetap `Visible=false` saat masuk match.
  - `RuntimeCountdownTick` terdeteksi `5`x.
  - `RuntimeTeleportDrop` terdeteksi `1`x (no duplicate).

## Update 2026-04-04 04:33 ICT

- task flashlight FPV (asset jalur `516522664`) masuk tahap stabilisasi visual source:
  - local spotlight diturunkan agar tidak membakar warna tangan (`1.35/12/24`).
  - viewmodel sekarang punya mode `handsOnly` untuk R15 (upper/lower arm disembunyikan).
  - tone-map warna arm/hand ditambahkan supaya tangan tidak tampil seperti objek putih menyala.
- validasi teknis:
  - dua build lolos (`_tmp_flashlight_viewmodel_tune_build.rbxlx`, `_tmp_flashlight_hands_only_build.rbxlx`).
  - runtime config di Studio terbaca sesuai source via MCP `script_read`.
- housekeeping:
  - artefak model test `Workspace.516522664 Realistic Flashlight` dihapus agar warning audio sanitizer tidak mengotori log startup.
- status:
  - **SELESAI (teknis source)** untuk baseline “dua tangan visible + anti-overbright”.
  - **PENDING (polish art)** untuk tahap akhir: model tangan custom/animasi tangan sinematik bila ingin kualitas visual di atas baseline teknis saat ini.

## Update 2026-04-04 05:17 ICT

- konsolidasi owner reward match ditutup untuk mencegah kebocoran ekonomi:
  - `EconomySystem.Controller` tidak lagi subscribe `MatchEnded` (reward owner tunggal kembali ke `RewardCalculationSystem`).
- `RewardCalculationSystem` sekarang menutup jalur payload Studio fallback:
  - baca `playerResults` selain `playerOutcome`,
  - fallback `payload.player/userId` juga bisa di-upsert.
- PP reward resmi sekarang ikut jalur endgame reward owner:
  - `MatchRewardSummary` client membawa `ppReward`,
  - grant currency menulis `PP` langsung via `EconomySystem`.
- hardening Studio E2E:
  - `StudioE2EControlSystem` fallback `EndMatch` sekarang menyertakan `playerOutcome` + `playerResults`,
  - fallback hanya boleh jalan bila player benar-benar `InMatch` (guard anti-abuse test harness),
  - action `GetWallet` ditambahkan untuk verifikasi saldo deterministic saat playtest.
- validasi live via MCP:
  - baseline wallet: `MM=1200 PP=12 Robux=0`
  - 1x flow canonical `CreateRoom -> HostStart -> EndMatch` menghasilkan delta:
    - `MM +306`
    - `PP +2`
  - probe `EndMatch` fake saat `InMatch=false` ditolak (`end_match_failed`) dengan delta wallet `0`.
- catatan sinkronisasi:
  - patch juga diterapkan langsung ke script Studio karena saat validasi ditemukan drift runtime (source lokal belum otomatis ter-push ke DataModel).

## Update 2026-04-04 05:38 ICT

- `P2.12` (UI modular compact/mobile) naik lagi dengan harness validasi baru yang bisa dipakai saat Studio headless:
  - `UI.Main` sekarang mendukung override input profile via attribute:
    - `PasrahUIInputProfileOverride = mobile|pc|console`
  - layout compact bisa dipaksa via:
    - `PasrahUIForceCompact = true`
  - viewport test dapat dipaksa via:
    - `PasrahUIViewportOverrideX`
    - `PasrahUIViewportOverrideY`
- rail kanan sekarang lebih disiplin di mobile:
  - hanya tombol primer (`ROOMS`, `PASS`, `MENU`, `RANK`) yang dipertahankan
  - `Profile/Shop` float tidak ikut menumpuk di jalur mobile
- sizing compact/mobile dipoles ulang:
  - `RoomBrowserUI` margin mobile dipersempit dan canvas host-room ditambah safe-bottom agar control bawah tidak ketutup.
  - `RoyalPassUI` mobile sekarang bergerak ke near-fullscreen sheet (bukan panel kecil sempit) pada viewport override aktif.
- validasi live MCP (Studio, override `390x844` + `mobile` + `forceCompact=true`) menunjukkan:
  - `RoomBrowserUI.Panel.Size ~= 388x842`
  - `RoyalPassUI.MainPanel.Size ~= 382x832`
  - rail tombol kanan terurut atas-ke-bawah dengan tombol primer terlihat, sedangkan float `Profile/Shop` tidak terlihat.
- catatan:
  - tool `mouse click/screen capture` MCP sempat timeout, jadi validasi dilakukan via inspeksi runtime property (`AbsoluteSize/Position/Visible`) dan bukan screenshot visual.

## Update 2026-04-04 06:45 ICT

- blocker gameplay fairness yang dilaporkan user ditutup:
  - utility item tidak lagi unlimited di runtime (`Garam/Salib/Dupa` kini punya kuota per pemain per match).
  - UI feedback field kit kini memunculkan status habis stok (`tool_out_of_stock`) + sisa pakai.
- validasi live StudioE2E:
  - `Garam`: gagal di attempt 4 (`tool_out_of_stock`)
  - `Salib`: gagal di attempt 3 (`tool_out_of_stock`)
  - `Dupa`: gagal di attempt 3 (`tool_out_of_stock`)
- blocker visual ghost skala raksasa juga ditutup:
  - model `Pocong` dinormalisasi dari tinggi ekstrem (`23`) ke proporsional (`8.5`) di source + runtime.
  - offset visual runtime `Pocong` disesuaikan dari `10.5` menjadi `0.4`.
- catatan sinkronisasi:
  - pada sesi ini terdeteksi lagi drift local->Studio; patch runtime juga diterapkan via MCP agar test tidak membaca source lama.
  - workflow tetap: source of truth di repo, lalu validasi runtime wajib cross-check script Studio aktif.

## Update 2026-04-04 06:49 ICT

- hardening ghost roster sementara ditutup:
  - jika ghost type belum punya model dedicated di `ReplicatedStorage.Assets.Models.Ghosts`, runtime sekarang fallback ke template `Pocong`.
  - tujuan: mencegah visual jatuh ke placeholder box saat random ghost memilih tipe non-Pocong.
- validasi live:
  - forced ghost `Kuntilanak` memunculkan `Ghost_Kuntilanak` dengan mesh nyata (`VisualTemplateName=Pocong`, `PlaceholderVisual=false`).
- status:
  - **SELESAI (baseline runtime)** untuk “ghost selalu punya visual mesh”.
  - **PENDING (content quality)** tetap pada impor model dedicated per tipe ghost di fase konten akhir.

## Update 2026-04-04 06:52 ICT

- `P2.13 Polish audio dan visual` naik satu tahap:
  - jalur jumpscare kini event-driven end-to-end (`JumpscareTriggered -> JumpscareAudioTriggered -> client runtime`).
  - `StudioE2EControl` ditambah action `TriggerJumpscare` agar validasi audio tidak lagi manual/tebakan.
- asset audio source-controlled yang sebelumnya kosong sekarang terisi:
  - `AmbientLoop_Main`
  - `ButtonClick_01`
  - `Jumpscare_01`
- validasi live:
  - runtime menemukan `JumpscareAudioRuntime`
  - `SoundId=rbxassetid://101202336513383`
  - `IsPlaying=true` setelah trigger harness
- status jujur:
  - **SELESAI (slice jumpscare + empty-slot cleanup)**.
  - **PENDING** untuk pass artistik lanjutan (material/lighting, ambience brand final, VFX ambiance detail).

## Update 2026-04-05 16:42 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi cadence/runtime honesty:
  - `SoundSystem` sekarang punya `CUE_AUDIO_PROFILES` per kategori agar cue tidak semuanya berbunyi dengan intensitas/pitch yang seragam.
  - debug runtime pemain sekarang menyimpan nilai akhir setelah profile diterapkan:
    - `PasrahAudioLastVolume`
    - `PasrahAudioLastPlaybackSpeed`
- validasi live MCP:
  - `StudioE2EControl.TriggerJumpscare(match_1)` menghasilkan:
    - `PasrahAudioLastCategory = JumpscareAudio`
    - `PasrahAudioLastCue = jumpscare_stinger`
    - `PasrahAudioLastSoundId = rbxassetid://138329686293368`
    - `PasrahAudioLastVolume ~= 0.90`
    - `PasrahAudioLastPlaybackSpeed ~= 1.2296`
  - `StudioE2EControl.ForceHunt(match_1)` menghasilkan:
    - `PasrahAudioLastCategory = HuntAudio`
    - `PasrahAudioLastCue = hunt_start`
    - `PasrahAudioLastVolume ~= 0.884`
    - `PasrahAudioLastPlaybackSpeed ~= 1.122`
- status:
  - **SELESAI (runtime cue cadence baseline)** untuk `Jumpscare/Hunt`.
  - **PENDING** tetap pada ambience legal final dan kekayaan cue lingkungan/ghost lanjutan.

## Update 2026-04-05 17:02 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi framing visual map:
  - `VFXController` sekarang punya `SensoryMapDepthOfField` dengan profile per map.
  - tujuan pass ini bukan blur berat, tetapi pemisahan fokus ruang yang lebih terasa antara lobby dan map horror.
- validasi live MCP:
  - lobby boot:
    - `FarIntensity ~= 0.06`
    - `FocusDistance = 52`
    - `InFocusRadius = 34`
    - `NearIntensity = 0`
  - setelah `CreateRoom -> HostStart(HauntedHouse)`:
    - `FarIntensity ~= 0.14`
    - `FocusDistance = 18`
    - `InFocusRadius = 9`
    - `NearIntensity ~= 0.03`
- status:
  - **SELESAI (map depth-of-field baseline)**.
  - **PENDING** tetap pada ambience legal final, polish material map, dan enrichment cue lingkungan/ghost.

## Update 2026-04-05 17:11 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi pencahayaan atmosfer:
  - `VFXController` sekarang punya `SensoryMapSunRays` dengan profile per map.
  - lobby dibuat sedikit lebih hidup, sedangkan map horror malam dijaga tetap minim agar tidak absurd.
- validasi live MCP:
  - lobby boot:
    - `Intensity ~= 0.068`
    - `Spread ~= 0.88`
  - setelah `CreateRoom -> HostStart(HauntedHouse)`:
    - `Intensity ~= 0.012`
    - `Spread ~= 0.72`
- status:
  - **SELESAI (map sun rays baseline)**.
  - **PENDING** tetap pada ambience legal final, polish material map, dan enrichment cue lingkungan/ghost.

## Update 2026-04-05 17:19 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi tone pencahayaan:
  - profile lighting map sekarang juga mengatur `ColorShift_Top/Bottom`.
  - lobby diarahkan sedikit hangat, sedangkan `HauntedHouse` diarahkan biru-dingin agar tone ruang lebih terasa.
- validasi live MCP:
  - lobby boot:
    - `ColorShift_Top ~= (0.039, 0.031, 0.016)`
    - `ColorShift_Bottom ~= (0.024, 0.016, 0.008)`
  - setelah `CreateRoom -> HostStart(HauntedHouse)`:
    - `ColorShift_Top ~= (0, 0.024, 0.055)`
    - `ColorShift_Bottom ~= (0, 0.016, 0.039)`
- status:
  - **SELESAI (map color shift baseline)**.
  - **PENDING** tetap pada ambience legal final, polish material map, dan enrichment cue lingkungan/ghost.

## Update 2026-04-05 17:37 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi spatial feel:
  - `GhostAudio` dan `EnvironmentalAudio` tidak lagi selalu nempel ke kamera.
  - client sekarang bisa memilih sumber suara dari:
    - `position` payload eksplisit
    - `room_anchor` jika hanya `roomId` yang tersedia
    - `camera_fallback` jika data posisi belum ada
- `StudioE2EControl` ditambah action `TriggerAudioCue` agar tuning spatial tidak lagi menunggu event ghost acak.
- validasi live MCP:
  - `EnvironmentalAudio` dengan `position = (1215.25, 3.5, -25)`:
    - `PasrahAudioLastSpatialMode = position`
    - `PasrahAudioLastSourcePosition = 1215.25, 3.50, -25.00`
    - folder `Workspace.RuntimeAudioEmitters` terisi emitter runtime
  - `GhostAudio` dengan `roomId = Kitchen`:
    - `PasrahAudioLastSpatialMode = room_anchor`
    - `PasrahAudioLastSourcePosition = 1230.00, 0.50, -25.00`
- status:
  - **SELESAI (ghost/environment spatial audio baseline)**.
  - **PENDING** tetap pada ambience legal final dan enrichment cue yang benar-benar berbeda asset-nya.

## Update 2026-04-05 17:48 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi respons visual cue lingkungan:
  - `EnvironmentalAudioTriggered` sekarang juga bisa memicu transient VFX ringan.
  - profile yang sudah dipasang:
    - `DoorSlam`
    - `LightFlicker`
    - `SuddenWhisper`
    - `ShadowApparition`
    - `ObjectThrow`
    - `WindowKnock`
    - `TemperatureDrop`
- validasi live MCP:
  - `DoorSlam`:
    - `PasrahVFXLastProfile = doorslam`
    - `SensoryThreatGrading.Contrast ~= 0.1179`
    - `Brightness ~= -0.0126`
    - `Blur ~= 5.05`
  - `LightFlicker`:
    - `PasrahVFXLastProfile = lightflicker`
- status:
  - **SELESAI (environment cue VFX baseline)**.
  - **PENDING** tetap pada ambience legal final dan material polish map yang lebih artistik.

## Update 2026-04-05 17:55 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi respons visual cue ghost:
  - `GhostAudioTriggered` sekarang juga punya transient VFX ringan untuk:
    - `ghost_whisper`
    - `ghost_manifest`
    - `ghost_fake_footsteps`
    - `ghost_object_throw`
- validasi live MCP:
  - `TriggerAudioCue(GhostAudio, ghost_manifest, roomId=Kitchen)` menghasilkan:
    - `PasrahVFXLastEvent = GhostAudioTriggered`
    - `PasrahVFXLastProfile = ghostmanifest`
    - `PasrahAudioLastSpatialMode = room_anchor`
    - `SensoryThreatGrading.Contrast ~= 0.1025`
    - `Brightness ~= -0.0102`
    - `Blur ~= 6.15`
- status:
  - **SELESAI (ghost cue VFX baseline)**.
  - **PENDING** tetap pada ambience legal final dan material polish map yang lebih artistik.

## Update 2026-04-05 18:06 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi relevansi asset audio:
  - `WindowKnock` tidak lagi jatuh ke creak generik; sekarang memakai `Woodstep_01`.
  - `ObjectThrow` tidak lagi jatuh ke creak generik; sekarang memakai `ConcreteStep_01`.
  - `Jumpscare_01` dipindah ke stinger yang lebih cocok (`hard horror hit drum`).
- validasi live MCP:
  - `TriggerAudioCue(EnvironmentalAudio, WindowKnock)`:
    - `SoundId = rbxassetid://104336169985098`
  - `TriggerAudioCue(EnvironmentalAudio, ObjectThrow)`:
    - `SoundId = rbxassetid://79900103772577`
  - `TriggerJumpscare`:
    - `SoundId = rbxassetid://101202336513383`
- status:
  - **SELESAI (event-audio semantic baseline)**.
  - **PENDING** tetap pada ambience legal final dan kemungkinan asset tambahan yang benar-benar baru bila nanti kamu ingin mengganti library suara yang sekarang.

## Update 2026-04-05 18:15 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi reaksi map nyata:
  - `LightFlicker` sekarang tidak hanya memicu grading/VFX global.
  - lampu di sekitar sumber event benar-benar padam lalu menyala lagi singkat di runtime.
- validasi live MCP:
  - `TriggerAudioCue(EnvironmentalAudio, LightFlicker)` di area `LivingRoom`:
    - `PasrahVFXLastProfile = lightflicker`
    - `PasrahVFXLastLightCount = 3`
    - lampu contoh `Light_LivingRoom.PointLight`:
      - sebelum: `Enabled = true`, `Brightness = 1.6`
      - saat pulse: `Enabled = false`, `Brightness = 0.128`
      - setelah pulse: kembali `Enabled = true`, `Brightness = 1.6`
- status:
  - **SELESAI (light flicker room reaction baseline)**.
  - **PENDING** tetap pada ambience legal final dan material polish map yang lebih artistik.

## Update 2026-04-05 18:28 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi reaksi objek lokal:
  - `DoorSlam` sekarang memukul pintu aktual di folder `Doors`, bukan frame-frame sekitarnya.
  - `WindowKnock` sekarang mendorong panel jendela aktual di folder `Windows`, lalu kembali ke posisi semula.
- validasi live MCP:
  - `DoorSlam` pada `Door_LivingRoom`:
    - `PasrahVFXLastProfile = doorslam`
    - `PasrahVFXLastPropCount = 2`
    - `Door_LivingRoom` kembali ke `CFrame` semula setelah pulse
  - `WindowKnock` pada `Window_S_1_Mouth`:
    - `PasrahVFXLastProfile = windowknock`
    - `PasrahVFXLastPropCount = 2`
    - `windowMid.Z = 69.22` dari `69.40`, lalu kembali normal
- status:
  - **SELESAI (door/window local reaction baseline)**.
  - **PENDING** tetap pada ambience legal final dan material polish map yang lebih artistik.

## Update 2026-04-05 18:34 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi reaksi prop lokal:
  - `ObjectThrow` sekarang benar-benar menggeser prop di folder `Props` sekitar sumber event, lalu restore.
- validasi live MCP:
  - `TriggerAudioCue(EnvironmentalAudio, ObjectThrow)` pada area `Kitchen`:
    - `PasrahVFXLastProfile = objectthrow`
    - `PasrahVFXLastPropCount = 4`
    - prop yang terkonfirmasi bergeser:
      - `Prop_Room_Kitchen_Counter`
      - `Prop_Room_Kitchen_Fridge`
      - `Prop_Kitchen`
      - `Prop_Room_HallwayMain_CoatRack`
- status:
  - **SELESAI (object throw local reaction baseline)**.
  - **PENDING** tetap pada ambience legal final dan material polish map yang lebih artistik.

## Update 2026-04-05 18:43 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi event ruang khusus:
  - `RadioStatic` sekarang memukul prop elektronik terdekat di folder `Props`.
  - `ShadowApparition` sekarang spawn manifest visual transient di ruang, bukan cuma grading/audio.
- validasi live MCP:
  - `RadioStatic` pada `Prop_Room_LivingRoom_TV`:
    - `PasrahVFXLastProfile = radiostatic`
    - `PasrahVFXLastElectronicCount = 1`
    - TV kembali ke `CFrame` semula setelah pulse
  - `ShadowApparition`:
    - `PasrahVFXLastProfile = shadowapparition`
    - `RuntimeVFX.ShadowApparitionRuntime` muncul dengan `2` child part
- status:
  - **SELESAI (radio/shadow local reaction baseline)**.
  - **PENDING** tetap pada ambience legal final dan material polish map yang lebih artistik.

## Update 2026-04-05 19:12 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi material map runtime:
  - `MapRuntimePatches` sekarang juga memoles floors, walls, doors, windows, dan lights pada clone map aktif.
  - profile material/warna sudah terpasang untuk `HauntedHouse`, `EmptyBuilding`, `AbandonedPalace`, dan `StudioMMNineteen`.
- validasi MCP:
  - `HauntedHouse` clone runtime:
    - `Floor_1_Main -> WoodPlanks / 58,46,38`
    - `NorthWall -> WoodPlanks / 74,58,48`
    - `Door -> Wood / 88,60,40`
    - `Window -> Glass / 164,178,194 / t=0.42`
  - `EmptyBuilding` clone runtime:
    - `Floor_1_Main -> Concrete / 58,60,66`
    - `NorthWall -> Concrete / 78,82,90`
- status:
  - **SELESAI (map material polish runtime baseline)**.
  - **PENDING** tetap pada ambience loop custom/final bila nanti ingin layer loop brand khusus di atas cadence event yang sudah hidup.

## Update 2026-04-05 19:15 ICT

- `P2.13 Polish audio dan visual` naik lagi di sisi ambience investigasi:
  - `AudioSystem` sekarang punya cadence ambience per match yang hidup saat `InvestigationPhase`.
  - cadence memilih cue ruang per map, bukan memutar loop placeholder yang menipu.
- validasi MCP:
  - stub `HauntedHouse InvestigationPhase` menerbitkan pulse nyata:
    - `GhostAudioTriggered`
    - `cue = ghost_whisper`
    - `roomId = Attic`
    - `intensity = 0.28`
- status:
  - **SELESAI (ambient investigation cadence baseline)**.
  - **PENDING** hanya bila nanti ingin mengganti ke `ambient loop` custom/final yang benar-benar legal dan artistik, bukan karena jalur ambience saat ini kosong.

## Update 2026-04-05 20:06 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju di sisi readability survival:
  - `MatchUX` sekarang menampilkan `HuntStatusBadge` dan `HuntAssistLabel` yang berubah mengikuti state `hunt/tracked/hidden/sheltered`.
  - objective hunt kini lebih sinkron dengan status survive, bukan hanya paragraf generik.
  - overlay hunt ikut mengambil warna berdasar intensitas ancaman.
- validasi live MCP:
  - baseline hunt:
    - `badge=HUNT`
    - `assist=TARGET: CLOSET B 46ST`
    - `assistLine2=PINTU: E/X/TAP  •  JANGAN LARI LURUS  •  SIAP ROTASI`
  - smoke `hidden` untuk jalur HUD:
    - `badge=HIDDEN`
    - `assist=POSISI: CLOSETB`
    - `objective=Berlindung di ClosetB. Diam dan tunggu hunt selesai sebelum keluar.`
- status:
  - **SELESAI (hunt readability HUD baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut slice restruktur akses/traversal visual dan affordance in-map yang masih terasa basic.

## Update 2026-04-05 20:18 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` naik lagi di sisi affordance refuge:
  - source marker `HideSpotRuntimeMarker` dan `SafeZoneRuntimeMarker` sekarang sudah disiapkan dengan lapisan `Highlight` on-top.
  - ini tidak mengganti sistem marker lama; hanya memperkuat keterbacaan refuge saat hunt.
- validasi:
  - build source sukses:
    - `_tmp_refuge_marker_polish_build.rbxlx`
  - sesi Studio aktif masih drift server-side, jadi marker highlight belum bisa divalidasi live pada sesi itu.
- status:
  - **SOURCE READY (refuge marker highlight polish)**.
  - **PENDING LIVE RETEST** setelah sesi Studio server tersinkron lagi.

## Update 2026-04-05 20:34 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi traversal:
  - patch lantai dua kini mencoba carve semua segmen `Floor_2_*` yang overlap dengan tangga pusat, bukan hanya segmen utara.
  - runtime guide baru ditambahkan pada `CentralStaircase`:
    - `AKSES LANTAI 2`
    - `Naik lewat tangga pusat`
- validasi:
  - build source sukses:
    - `_tmp_traversal_guides_build.rbxlx`
  - asset/static audit menunjukkan `HauntedHouse`, `EmptyBuilding`, dan `StudioMMNineteen` memang punya struktur tangga yang sesuai untuk patch ini.
- status:
  - **SOURCE READY (second-floor robustness + traversal guide)**.
  - **PENDING LIVE RETEST** saat harness Studio server kembali stabil.

## Update 2026-04-05 20:36 ICT

- cleanup runtime support:
  - spam log `TPV ALLOWED (Lobby)` dari `CameraController` sekarang ditahan agar hanya muncul saat mode kamera benar-benar berubah.
- status:
  - **SELESAI (camera log noise guard)**.

## Update 2026-04-05 20:43 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` naik lagi di sisi affordance pintu:
  - prompt pintu sekarang memakai label tujuan yang lebih manusiawi, bukan `Pintu` generik.
  - runtime juga menyimpan `DoorRouteLabel` attribute untuk hook UX berikutnya bila dibutuhkan.
- validasi:
  - build source sukses:
    - `_tmp_door_prompt_labels_build.rbxlx`
  - contoh derivasi label:
    - `Door_Kitchen -> Pintu Kitchen`
    - `Door_Bedroom1 -> Pintu Bedroom 1`
- status:
  - **SELESAI (door prompt label baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut slice restruktur visual/lobby-map yang masih belum layak final.

## Update 2026-04-05 20:52 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju di sisi anchor visual lobby:
  - zona lobby aktif sekarang punya guide runtime terencana:
    - `Highlight`
    - `BillboardGui`
  - mencakup `SpawnPlaza`, `MatchmakingZone`, `ShopZone`, `PartyZone`, `FlexZone`, `DailyRewardZone`.
- validasi:
  - build source sukses:
    - `_tmp_lobby_zone_guides_build.rbxlx`
  - sesi Studio aktif masih drift server-side, jadi guide lobby belum bisa divalidasi live pada sesi itu.
- status:
  - **SOURCE READY (lobby zone guide runtime)**.
  - **PENDING LIVE RETEST** saat sesi Studio server sudah sinkron.

## Update 2026-04-05 21:01 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` naik lagi di sisi orientasi ruang:
  - interaction point sintetis sekarang punya `BillboardGui` kecil sebagai `Anchor ruang`.
  - label ruang diturunkan dari nama `Room_*`, jadi area yang sebelumnya hanya ada di data sekarang punya affordance visual minimal.
- validasi:
  - build source sukses:
    - `_tmp_interaction_anchor_guides_build.rbxlx`
- status:
  - **SELESAI (synthetic interaction anchor baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut slice restruktur visual/runtime yang masih terlalu basic.

## Update 2026-04-05 21:06 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` dirapikan lagi di sisi lobby reality scan:
  - `SUPPORTED_ZONES` sekarang hanya memuat zona yang benar-benar punya geometry aktif.
  - `TrainingZone` dan `LeaderboardZone` dihapus dari daftar karena tidak ada anchor nyata di `LobbySocialHub`.
- status:
  - **SELESAI (lobby zone reality alignment)**.
  - **NEXT** tetap lanjut restruktur visual/runtime yang masih terlalu basic.

## Update 2026-04-05 21:12 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` naik lagi di sisi konsistensi orientasi ruang:
  - guide ruang sekarang dipasang untuk interaction point existing maupun synthetic.
  - semua interaction point room-aware sekarang punya `InteractionGuideLabel`.
- validasi:
  - build source sukses:
    - `_tmp_room_guides_consistent_build.rbxlx`
- status:
  - **SELESAI (room guide consistency baseline)**.
  - **NEXT** tetap lanjut restruktur visual/runtime yang masih terlalu basic.

## Update 2026-04-05 21:24 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi refuge alignment:
  - safe zone runtime sekarang punya subtitle kontekstual berbasis room terdekat (`SafeZoneSubtitle`, `SafeZoneRoomLabel`, `RefugeRouteLabel`).
  - hide spot runtime sekarang menyimpan subtitle dan route label yang seragam dengan sistem refuge lain.
  - marker refuge membaca attribute runtime ini, sehingga bahasa visual refuge tidak lagi sepenuhnya hardcoded dan terpisah dari guide phase 18 lainnya.
- validasi:
  - build source sukses:
    - `_tmp_refuge_route_alignment_build.rbxlx`
- status:
  - **SELESAI (refuge route label baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut slice restruktur visual/runtime map-lobby yang masih basic.

## Update 2026-04-05 21:33 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` naik lagi di sisi sinkronisasi HUD:
  - hunt/refuge HUD sekarang membaca `routeLabel` refuge runtime, bukan hanya label generik hasil formatting nama part.
  - nearest safe zone dan hide spot menyimpan metadata label/subtitle/route yang siap dipakai di assist hunt.
- validasi:
  - build source sukses:
    - `_tmp_hunt_refuge_route_hud_build.rbxlx`
- status:
  - **SELESAI (hunt HUD refuge route sync baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 21:42 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi orientasi lobby:
  - zona lobby aktif sekarang tidak hanya punya guide di area, tetapi juga beacon kecil di pintu masuk bangunan aktif.
  - anchor yang dipakai mengikuti geometry nyata (`Door_*` / `Interact_*`) sehingga titik baca pemain lebih intuitif.
- validasi:
  - build source sukses:
    - `_tmp_lobby_entry_guides_build.rbxlx`
  - static scan `LobbySocialHub.model.json` mengonfirmasi anchor target memang ada.
- status:
  - **SELESAI (lobby entry guide baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 21:50 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi traversal map:
  - pintu runtime sekarang punya beacon ringan di world-space, bukan hanya label prompt saat didekati.
  - `DoorRouteLabel` kini benar-benar dipakai sebagai anchor visual tujuan ruang.
- validasi:
  - build source sukses:
    - `_tmp_door_route_guides_build.rbxlx`
- status:
  - **SELESAI (door route guide baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 21:57 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi konsistensi lobby:
  - event `LobbyZoneFocused` kini memakai badge/subtitle/accent yang selaras dengan guide dunia.
  - feedback label lobby tidak lagi terasa generik dibanding beacon zona/pintu masuk.
- validasi:
  - build source sukses:
    - `_tmp_lobby_zone_feedback_sync_build.rbxlx`
- status:
  - **SELESAI (lobby feedback sync baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 22:05 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi readability match:
  - HUD `Preparation/Investigation` sekarang membaca anchor navigasi runtime terdekat dari pintu atau interaction guide.
  - objective dan controls hint pada phase non-hunt tidak lagi sepenuhnya generik.
- validasi:
  - build source sukses:
    - `_tmp_match_navigation_readability_build.rbxlx`
- status:
  - **SELESAI (match navigation readability baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 22:12 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi affordance semantik:
  - subtitle beacon pintu dan interaction guide sekarang dibedakan menurut fungsi area, bukan lagi satu copy generik untuk semua ruang.
  - closet/refuge, transisi vertikal, dan area investigasi sekarang punya copy yang lebih jujur.
- validasi:
  - build source sukses:
    - `_tmp_semantic_route_guides_build.rbxlx`
- status:
  - **SELESAI (semantic route guide baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 22:19 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi panel lobby:
  - panel lobby utama sekarang menyimpan dan memakai focus zona terakhir, bukan hanya bergantung pada feedback label sementara.
  - badge/header/hint panel lobby kini bisa mengikuti konteks zona aktif.
- validasi:
  - build source sukses:
    - `_tmp_lobby_panel_zone_focus_build.rbxlx`
- status:
  - **SELESAI (lobby panel zone focus baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 22:26 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi readability investigasi:
  - objective dan controls hint `Preparation/Investigation` kini membedakan refuge route, akses vertikal, sweep evidence, dan area investigasi.
  - panel match non-hunt jadi lebih kontekstual terhadap fungsi area terdekat.
- validasi:
  - build source sukses:
    - `_tmp_semantic_investigation_hud_build.rbxlx`
- status:
  - **SELESAI (semantic investigation HUD baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 22:33 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi panel lobby:
  - pill dan hint panel lobby sekarang ikut memantulkan focus zona aktif, tidak hanya header dan feedback toast.
  - context zona terasa lebih persisten saat pemain belum masuk room.
- validasi:
  - build source sukses:
    - `_tmp_lobby_focus_pills_build.rbxlx`
- status:
  - **SELESAI (lobby focus pills baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 22:40 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi panel match:
  - accent visual `Preparation/Investigation` sekarang ikut menyesuaikan semantik route aktif, bukan hanya isi teks.
  - objective, hint bar, timer caption, dan footer non-hunt jadi lebih selaras dengan konteks area.
- validasi:
  - build source sukses:
    - `_tmp_match_semantic_accent_build.rbxlx`
- status:
  - **SELESAI (match semantic accent baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 22:47 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi beacon dunia:
  - warna `DoorRouteGuideRuntime` dan `InteractionGuideRuntime` sekarang ikut semantik route, tidak lagi satu palette untuk semua ruang.
  - refuge, vertikal, evidence sweep, dan investigasi area kini punya sinyal warna yang lebih cepat dibaca.
- validasi:
  - build source sukses:
    - `_tmp_semantic_world_guides_build.rbxlx`
- status:
  - **SELESAI (semantic world guide palette baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 22:54 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi jalur vertikal:
  - `CentralStaircase` sekarang punya metadata route runtime yang bisa dibaca client HUD, bukan hanya billboard lokal di world.
  - guide tangga pusat juga sudah memakai palette vertikal yang konsisten.
- validasi:
  - build source sukses:
    - `_tmp_traversal_metadata_sync_build.rbxlx`
- status:
  - **SELESAI (traversal metadata sync baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 23:01 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi pemilihan anchor:
  - HUD `Preparation` dan `Investigation` sekarang tidak lagi selalu mengambil anchor terdekat murni, tetapi memakai bias konteks fase.
  - hasilnya anchor yang dipilih lebih relevan terhadap tujuan fase aktif.
- validasi:
  - build source sukses:
    - `_tmp_phase_aware_navigation_build.rbxlx`
- status:
  - **SELESAI (phase-aware navigation anchor baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 23:08 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi runtime hygiene:
  - helper navigasi client sekarang memakai cache anchor per map runtime, tidak lagi scan struktur penuh pada tiap refresh panel.
  - subtitle pintu tetap dinamis, jadi efisiensi naik tanpa kehilangan state visual `Terbuka`.
- validasi:
  - build source sukses:
    - `_tmp_navigation_anchor_cache_build.rbxlx`
- status:
  - **SELESAI (navigation anchor cache baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 23:14 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi penyatuan refuge:
  - `SafeZone` dan `HideSpot` sekarang ikut masuk ke cache anchor navigasi client.
  - refuge tidak lagi berdiri sepenuhnya di sistem marker terpisah dari route ecosystem utama.
- validasi:
  - build source sukses:
    - `_tmp_refuge_anchor_cache_build.rbxlx`
- status:
  - **SELESAI (refuge anchor unification baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 23:24 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi konsistensi refuge:
  - `SafeZoneRuntimeMarker` dan `HideSpotRuntimeMarker` sekarang memakai palette refuge yang sama dengan route guide/hud.
  - bahasa visual refuge tidak lagi terpecah antara marker aman, hide spot, dan route beacon.
- validasi:
  - build source sukses:
    - `_tmp_refuge_marker_palette_build.rbxlx`
- status:
  - **SELESAI (refuge marker palette alignment baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 23:33 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi readability navigasi:
  - panel match sekarang menyebut target anchor aktif beserta jaraknya.
  - objective/hint `Preparation` dan `Investigation` tidak lagi hanya menyebut label ruang, tetapi juga estimasi kedekatan target.
- validasi:
  - build source sukses:
    - `_tmp_navigation_distance_readability_build.rbxlx`
- status:
  - **SELESAI (navigation distance readability baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 23:42 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi orientasi lobby:
  - panel lobby sekarang menampilkan jarak ke zona aktif/fokus.
  - konteks `LobbyZoneFocused` tidak lagi hanya badge + nama, tetapi juga estimasi kedekatan area.
- validasi:
  - build source sukses:
    - `_tmp_lobby_focus_distance_build.rbxlx`
- status:
  - **SELESAI (lobby focus distance baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-05 23:51 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi konsistensi pintu:
  - semantik route pintu sekarang dipisah dari state `Terbuka/Tertutup/Terkunci`.
  - HUD/navigasi client tetap bisa mengerti fungsi ruang pintu meski state pintunya berubah.
- validasi:
  - build source sukses:
    - `_tmp_door_semantic_state_split_build.rbxlx`
- status:
  - **SELESAI (door semantic state split baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-06 00:01 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi stabilitas orientasi lobby:
  - panel lobby sekarang punya fallback proximity ke zona terdekat.
  - jadi saat focus server belum terpicu, pemain tetap melihat konteks area lobby aktif yang paling dekat.
- validasi:
  - build source sukses:
    - `_tmp_lobby_zone_proximity_fallback_build.rbxlx`
- status:
  - **SELESAI (lobby zone proximity fallback baseline)**.
  - **NEXT** tetap di `P2.18`: lanjut restruktur visual/runtime lobby-map yang masih basic.

## Update 2026-04-06 00:07 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi affordance pintu:
  - objective dan controls hint match sekarang ikut menampilkan status operasional pintu saat anchor aktif.
  - konteks pintu tidak lagi berhenti di label semantik saja.
- validasi:
  - build source sukses:
    - `_tmp_door_state_hud_context_build.rbxlx`
- status:
  - **SELESAI (door state hud context baseline)**.
  - **NEXT**: tutup `Phase 18` dan lanjut ke phase backlog berikutnya.

## Update 2026-04-06 00:16 ICT

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` resmi ditutup:
  - panel lobby sekarang punya orientasi zona aktif + fallback proximity + emphasis tombol yang sesuai area.
  - panel match sekarang punya route/distance/state context yang konsisten dengan world guide, refuge, traversal, dan pintu.
  - palette refuge, beacon semantik, anchor cache, dan affordance HUD/lobby sekarang sudah berada dalam satu bahasa visual/runtime yang sama.
- validasi:
  - build source sukses:
    - `_tmp_phase18_completion_build.rbxlx`
- status:
  - **SELESAI (phase 18 complete)**.
  - **NEXT**: pindah ke phase backlog berikutnya, bukan lagi restruktur `Lobby + Map` besar.

## LAST NOTE - Creator Hub Verification

- `10576163165` belum boleh dipakai sebagai `marketplaceId` production.
- hasil audit saat ini menunjukkan angka itu tampak seperti `UserId/account id`, bukan `GamePassId/ProductId` Creator Hub yang terverifikasi.
- blocker publish Robux tetap sama sampai ID marketplace resmi dibuat di Creator Hub lalu diisi ke `src/shared/DataTypes/ShopMarketplaceConfig.lua`.
- catatan ini bukan blocker eksekusi roadmap harian; kerjakan paling akhir tepat sebelum publish/compliance final.

## LAST NOTE - Placeholder Entitlements Stay Disabled

- `class_dukun_unlock`, `class_detective_unlock`, dan `lifetime_bonus_pass` tetap harus `disabled` sampai ada implementasi final yang lolos audit fairness dan compliance Roblox.
- saat ini source hanya menunjukkan placeholder katalog/config/state, belum ada gameplay class live yang sah untuk diaktifkan.
- jangan mengisi `marketplaceId` production untuk tiga item ini lebih dulu daripada `MM/PP` pack yang memang sudah jelas klasifikasinya.

## LAST NOTE - Exterior Investigation Staging Flow

- spawn pertama masuk ke match harus berada di luar bangunan/target investigasi, bukan langsung di inti interior map.
- flow briefing investigasi harus lebih diegetic seperti `Phasmophobia`, tetapi tanpa van: pemain tiba di area depan rumah/map target.
- objective investigasi utama, daftar misi, dan pemilihan/pergantian tool harus dipindahkan ke surface dunia seperti papan briefing / investigation board, bukan bertumpu pada UI player sebagai surface utama.
- task ini terhubung langsung dengan rekonstruksi map berikutnya, karena membutuhkan area exterior staging yang jelas dan bisa diuji visual/audio secara live.

## Update 2026-04-06 09:35 ICT

- `Lobby UX visual` menerima pass world-space identity besar:
  - semua entrance utama (`PLAY / SHOP / PARTY / GARDEN / FLEX`) sekarang punya cue fisik yang konsisten
  - `North` sudah naik menjadi `contract / evidence staging bay` dengan foyer props, semantic props, dan desk plates
  - plaza tengah sekarang punya `Lobby Directory` + route runner antar-zona
- status:
  - **LANJUT / BELUM FINAL**.
  - shell bangunan dan interior final masih belum selesai, tetapi lobby sekarang sudah jauh lebih layak untuk visual QA manusia dibanding baseline sebelumnya.

## Update 2026-04-06 10:10 ICT

- wayfinding plaza diperbesar lagi dengan beacon vertikal per arah utama agar orientasi lobby tidak hanya bergantung pada façade entrance.
- status:
  - **LANJUT / BELUM FINAL**.
  - baseline world-space lobby sekarang sudah jauh lebih terbaca, tetapi final art/interior masih tersisa.

## Update 2026-04-06 11:25 ICT

- `Lobby UX visual` menerima pass `spatial mass` besar:
  - semua entrance utama sekarang punya `forecourt` nyata (pad + bench + planter)
  - `North` sekarang tampil sebagai `contract bay + entrance mass`, bukan hanya façade sign
  - `MainHub` sekarang punya planter sudut + wall section agar `Lobby Directory` benar-benar menjadi focal point plaza
- validasi:
  - build source sukses:
    - `_tmp_lobby_forecourt_and_hub_mass_build.rbxlx`
  - verifikasi live menembus:
    - `North ForecourtPad`
    - `Shop ForecourtPad`
    - `HubWallNorthWest`
    - `HubPlanterNorthWest`
    - `DirectoryPanel` yang diperbesar
- status:
  - **LANJUT / BELUM FINAL**.
  - lobby sekarang sudah jauh lebih terbaca sebagai ruang, tetapi interior bangunan dan asset final masih tersisa sebelum layak disebut selesai penuh.

## Update 2026-04-06 12:05 ICT

- `Lobby UX visual` maju lagi di sisi fungsi world-space semua sayap:
  - `SHOP / PARTY / GARDEN / FLEX` sekarang tidak lagi hanya façade + forecourt
  - masing-masing sudah punya `mini bay` berupa `ZoneCounter` dan `ZoneDisplay`
  - copy world-space sekarang mengarah lebih jelas ke fungsi:
    - `SHOP COUNTER / LOADOUT / COSMETIC`
    - `READY DESK / CREATE / INVITE`
    - `GARDEN DESK / DAILY / SOCIAL`
    - `FLEX DESK / SPOTLIGHT / NEWS`
- validasi:
  - build source sukses:
    - `_tmp_lobby_zone_bays_build.rbxlx`
  - runtime live tembus untuk semua `ZoneCounter` utama
- status:
  - **LANJUT / BELUM FINAL**.
  - lobby sekarang sudah jauh lebih mendekati `functional hub`, tetapi interior bangunan, asset final, dan interaksi dunia final masih tersisa.

## Update 2026-04-06 13:35 ICT

- `Lobby UX visual` menerima tiga pass besar lanjutan:
  - tambah object blueprint dunia:
    - `Table_Tools_1..6`
    - `EquipmentRack`
    - `PartyPlatform / PartyBoard / PartyTerminal`
    - `DailyRewardTerminal`
    - `FlexStage / AnnouncementBoard`
  - tambah `pseudo interior shell` untuk bangunan utama:
    - `InteriorFloor / BackWall / SideLeft / SideRight / Ceiling`
  - geser fresh spawn dan return-to-lobby ke luar forecourt supaya view awal tidak lagi lahir di dalam shell gelap
- validasi:
  - build source sukses:
    - `_tmp_lobby_zone_features_build.rbxlx`
    - `_tmp_lobby_pseudo_interiors_build.rbxlx`
    - `_tmp_lobby_spawn_forecourt_fix_build.rbxlx`
    - `_tmp_lobby_spawn_forecourt_final_build.rbxlx`
  - runtime live tembus untuk:
    - training tables utara
    - shop/party/garden/flex world objects
    - interior shell parts
    - fresh spawn baru `1610, 3.47, -90.25`
- status:
  - **LANJUT / BELUM FINAL**.
  - lobby sekarang sudah cukup jauh naik sebagai `functional world-space hub`, tetapi asset final dan interior kaya masih tersisa sebelum bisa dinyatakan selesai total.

## Update 2026-04-06

- `Lobby UX visual` menerima pass façade dan shell deterministik baru:
  - jalur `LobbyZoneEntryGuideRuntime` tidak lagi diandalkan untuk façade utama karena drift pada `North`
  - façade world-space semua sayap sekarang dibangun langsung dari `MainHubDecorRuntime`
  - `North / Shop / Party / Garden / Flex` sekarang minimal punya:
    - shell interior ringan
    - frontage / jamb / canopy
    - sign panel menempel ke façade
    - window + lamp langsung di façade
- spawn lobby dan return-to-lobby juga disetel ulang lagi agar jatuh di forecourt kompromi yang lebih cocok untuk baca `North`.
- validasi:
  - build source sukses:
    - `_tmp_lobby_facade_direct_build.rbxlx`
    - `_tmp_lobby_forecourt_readability_build.rbxlx`
    - `_tmp_lobby_spawn_offset_compromise_build.rbxlx`
  - verifikasi live:
    - `NorthBayEntrySignPanel`
    - `ShopBayEntrySignPanel`
    - `PartyBayEntrySignPanel`
    - `GardenBayEntrySignPanel`
    - `FlexBayEntrySignPanel`
    - `partyGuide = nil` sehingga façade aktif sekarang benar-benar datang dari décor runtime baru
- status:
  - **LANJUT / BELUM FINAL**.
  - baseline lobby sekarang sudah kuat sebagai `blockout world-space yang terbaca`, tetapi masih tersisa art pass, asset final, dan interaksi dunia final sebelum bisa saya sebut selesai penuh.

## Update 2026-04-06

- `Lobby UX visual` naik satu level lagi dari `readable blockout` ke `canonical world-space object pass`:
  - object yang dicari codebase sekarang ada nyata di runtime:
    - `MatchQueuePlatform`
    - `QueueTrigger`
    - `ShopCounter`
    - `Interact_Shop`
    - `PartyPlatform / PartyBoard / PartyTerminal`
    - `DailyRewardTerminal`
    - `FlexStage / AnnouncementBoard`
    - `Table_Tools_1..6`
  - prompt world-space dasar juga sudah dipasang pada object inti agar lobby lebih terasa sebagai ruang fungsi, bukan sekadar bentuk
- validasi:
  - build source sukses:
    - `_tmp_lobby_canonical_objects_build.rbxlx`
  - runtime live tembus:
    - `queueTouch = true`
    - semua object canonical di atas hadir di `MainHubDecorRuntime`
- status:
  - **LANJUT / BELUM FINAL**.
  - lobby sekarang sudah lebih dekat ke `functional hub yang bisa dihubungkan logic`, tetapi art pass, asset final, dan interaction flow final masih tersisa sebelum saya bisa menyebut lobby selesai penuh.

## Update 2026-04-06

- `Lobby UX visual` menerima pass `world prompt wiring`:
  - `ContractBoard / RoomBoard / QueueTrigger` sekarang punya jalur nyata ke `Room Browser`
  - `ShopCounter / Interact_Shop` sekarang benar-benar membuka `ShopUI`
  - `DailyRewardTerminal` sekarang mengirim `DailyRewardClaimRequest`
  - `ToolsBoard` dan `Table_Tools_*` sekarang memberi feedback lobby yang benar
  - board utara sekarang menarik data kontrak hidup, tidak lagi murni statis
- validasi:
  - build source sukses:
    - `_tmp_lobby_world_prompt_build.rbxlx`
    - `_tmp_lobby_world_prompt_fix_build.rbxlx`
  - verifikasi live:
    - `ContractBoard` prompt membuka `RoomBrowserUI`
    - `ShopCounter` prompt membuka `ShopUI`
    - subtitle `ContractBoard` berubah sesuai refresh board kontrak hidup
- status:
  - **LANJUT / BELUM FINAL**.
  - lobby sekarang sudah naik dari `functional blockout` ke `functional world-space hub` yang mulai benar-benar bereaksi terhadap prompt dunia, tetapi asset/interior/art pass final masih tersisa.

## Update 2026-04-06

- blocker `mouse/camera drift` di lobby direvert ke jalur default Roblox:
  - `CameraController.client.lua` kembali ke baseline sebelum `manual orbit / manual FPV` dipasang
  - `StarterPlayer.DevComputerCameraMovementMode` kembali ke `UserChoice`
  - batch `LobbySocialHub` yang sedang berjalan dibatalkan agar rollback ini bersih
- validasi:
  - build source sukses:
    - `_tmp_camera_default_restore_build.rbxlx`
  - runtime live:
    - `CameraType = Custom`
    - `CameraMode = Classic`
    - `MouseBehavior = Default`
- status:
  - **LANJUT / BELUM FINAL**.
  - lobby tetap belum final, tetapi jalur kamera custom yang memicu drift sudah dicabut dulu sebelum lanjut lagi.

## Update 2026-04-06

- blocker `default Roblox camera di lobby` kini benar-benar ditutup:
  - branch render-step lobby di `CameraController.client.lua` yang terus memanggil `setFpvLocked(false)` sudah dicabut
  - camera controller sekarang tidak lagi mengambil alih camera/mouse state lobby di luar `InMatch`
- validasi:
  - lobby idle:
    - `CameraType = Custom`
    - `CameraMode = Classic`
    - `MouseBehavior = Default`
  - saat tahan klik kanan di lobby:
    - `MouseBehavior = LockCurrentPosition`
    - perilaku ini sesuai jalur default Roblox third-person
- status:
  - **LANJUT / BELUM FINAL**.
  - blocker mouse lobby sudah tertutup, tetapi pekerjaan lobby keseluruhan masih belum final.

## Update 2026-04-06

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi di sisi lobby world-space:
  - board sekunder `Queue / Shop / Party / Flex / Daily` sekarang ikut refresh saat boot lobby, tidak lagi tertinggal statis
  - `North contract bay` sekarang lengkap lagi sebagai ruang staging:
    - desk kontrak
    - display case kiri/kanan
    - props semantik kontrak/room/tools
    - plate meja `MAP / MODE / START`
  - prompt dunia utama tetap sehat sesudah pass ini:
    - `ContractBoard -> RoomBrowserUI`
    - `ShopCounter -> ShopUI`
- validasi:
  - build source sukses:
    - `_tmp_lobby_board_refresh_fix_build.rbxlx`
    - `_tmp_lobby_contract_bay_restore_build.rbxlx`
  - verifikasi live:
    - `QueueSign`, `ShopCounter`, `PartyBoard`, `AnnouncementBoard` menampilkan copy dinamis baru
    - `DeskMapPlate`, `DeskModePlate`, `DeskStartPlate` hadir dan terisi data hidup
- status:
  - **LANJUT / BELUM FINAL**.
  - lobby sekarang naik dari `functional world-space hub` menjadi `functional hub dengan contract bay yang kembali utuh`, tetapi art pass premium, asset final non-primitive, dan interior kaya per bangunan masih tersisa sebelum bisa dinyatakan final.

## Update 2026-04-06

- `P2.18 Final pass perubahan dan restruktur LOBBY + MAP IN GAME` maju lagi pada framing spawn `North`:
  - jalur utara kini punya arch dunia, marquee `Contract Bay`, path inset, line neon, dan bollard lamp
  - tujuan pass ini adalah memecah frame spawn yang sebelumnya terlalu kosong dan langsung mengarahkan pemain ke `PLAY / Contract / Room / Tools`
- validasi:
  - build source sukses:
    - `_tmp_lobby_north_approach_build.rbxlx`
  - verifikasi live:
    - `NorthApproachPanel` tampil dengan copy `CONTRACT BAY`
    - arch dan bollard lamp hadir di runtime `MainHubDecorRuntime`
- status:
  - **LANJUT / BELUM FINAL**.
  - lobby sekarang lebih jelas dari spawn, tetapi final pass masih membutuhkan material/asset premium, interior kaya, dan art pass global sebelum bisa dinyatakan selesai.

