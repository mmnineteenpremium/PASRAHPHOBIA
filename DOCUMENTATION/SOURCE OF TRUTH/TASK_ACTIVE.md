# TASK ACTIVE — RUNTIME STABILIZATION (OWNER LOCK)

Last updated: 2026-04-19 (Asia/Bangkok)  
Owner context: Miftah

## Objective

Pulihkan runtime game ke kondisi stabil seperti target owner:

- lobby spawn benar (`LobbySocialHub`)
- staging menyatu di depan map (bukan mainfloor staging terpisah)
- tools meja preparation bisa dipilih
- match mulai saat pintu depan dibuka
- wiring map lengkap dan tidak melayang
- parity PC + Android konsisten

## Scope Lock (Non-Negotiable)

- Jangan buat sistem baru.
- Jangan ubah arsitektur.
- Jangan duplikasi flow/runtime ownership.
- Jangan placeholder/asal isi asset ID.
- Jika mapping asset tidak pasti: stop dan eskalasi ke owner.

## Execution Policy

- Studio-first: semua perbaikan diprioritaskan di Roblox Studio runtime.
- Publish hanya jika diperlukan untuk validasi blocker yang tidak bisa direproduksi di Studio.
- Hindari orchestration berulang yang boros token tanpa output konkret.

## Active Problems To Fix

- Fog/profile tidak konsisten Studio vs publish pada map match.
- Trigger phase bisa maju terlalu cepat (door auto-open/hunt terlalu dini).
- Tool station preparation kadang terkunci padahal harus selectable.
- Ghost bisa keluar area investigasi ke staging.
- Flashlight PC/Android tidak parity (toggle, brightness, lag).
- UI pasca mati/return (result + room browser) tidak pulih konsisten.

## Ghost Visual Validation Rule (Owner Requirement)

Kondisi ghost tidak terlihat dianggap **valid** hanya jika state behavior memang non-manifest/hidden.  
Kondisi ghost tidak terlihat dianggap **bug** jika state aktif menuntut visual (manifest/hunt/event visual) tetapi model tidak render.

## Phase Plan (Current)

1. Stabilkan phase gate preparation -> investigation (door + lifecycle).
2. Pulihkan selectable tool station di staging.
3. Batasi chase ghost agar tidak spill ke staging.
4. Samakan VFX/atmosphere profile Studio vs publish.
5. Pulihkan flashlight parity PC + Android.
6. Pulihkan UI result + room browser setelah death/return.
7. Smoke test Studio (PC + Android), lalu publish hanya bila blocker publish-specific.

## Definition Of Done

- Spawn awal selalu di `LobbySocialHub`.
- Semua map match memuat staging di luar map sesuai desain owner.
- Match tidak mulai otomatis sebelum pintu advance dibuka sesuai trigger.
- Tool meja bisa dipilih pada PreparationPhase.
- Ghost tidak memburu keluar ke staging.
- Flashlight aktif konsisten di PC/Android.
- Result match dan room browser pulih benar setelah mati/keluar match.

## Owner Escalation Triggers

Eskalasi ke owner hanya untuk:

- asset ID ambigu/tidak ada di CSV
- keputusan visual yang mengubah identitas map/brand
- mismatch yang hanya muncul di publish cloud dan tidak bisa direproduksi di Studio

## Execution Log

### 2026-04-19 — Patch Batch A (Studio-first, no architecture change)

- `DoorRuntime`: cegah `PasrahPreparationAdvanceDoor` auto-advance saat source `DoorRuntimeAuto`; hybrid auto-open skip khusus preparation advance door.
- `MapRuntimePatches`: perbaiki token phase preparation (`PreparationPhase` + `Preparation`) agar breach state tidak false-positive.
- `GhostSystem/Service`: tambah safe-zone filter pada target hunt agar ghost tidak mengejar player yang sedang di area `SafeZones`.
- `Client/UI/Main`: `room browser suppression` pakai validasi lifecycle match aktif, bukan `MatchId` stale.
- `Shared/GameData/FlashlightConfig`: turunkan `remoteLight` intensity/range untuk parity PC/Android dan kurangi overbright/lag.
- `Client/Sensory/VFXController` + `AudioController`: map profile authority pakai `InMatch` atau `MatchId + active lifecycle`, untuk sinkronisasi lobby vs match profile.
- Smoke check Studio: play-run tanpa error skrip baru terdeteksi (masih ada warning asset sound 403 yang sudah known external permission issue).

### 2026-04-19 — Patch Batch B (Host-start countdown + preparation gate hardening)

- `LobbySystem/Service` + `LobbySystem/Controller`: set `HOST_START_COUNTDOWN_SECONDS = 5` agar host-start tetap 5 detik (jalur countdown 30 detik tidak dipakai).
- `MatchSystem/MapRuntimePatches`: `resolvePreparationBreachOpen` diperketat hanya untuk phase live eksplisit (`Investigation/Hunt/Endgame`) dari match + lifecycle player, supaya token transisi/unknown tidak memicu breach terlalu dini dan tidak mengunci tool station saat Preparation.

### 2026-04-19 — Patch Batch C (Ghost anti-spill guard, staging safe-zone hard clamp)

- `GhostSystem/Service`: tambah helper `keepGhostOutsideSafeZones` untuk menahan target + step movement visual ghost agar tidak masuk volume `SafeZones` saat sync runtime.
- `GhostSystem/Service`: clamp diterapkan di `_syncGhostVisual` untuk `targetPosition` dan `resolvedPosition`, sehingga fallback room target tidak mendorong ghost spill ke staging.
- Validasi teknis: `scripts/release-preflight.ps1 -Json` sukses (`buildOk: true`, tidak ada missing report, mapping blocker 0; manual blocker tersisa hanya smoke test 2 client nyata).

### 2026-04-19 — Patch Batch D (Flashlight remote aim parity PC + Android)

- `FlashlightSyncSystem/Service`: parameter smoothing remote aim tidak lagi hardcoded; sekarang baca dari `FlashlightConfig.remoteLight` (`aimUpdateMinInterval`, `aimSmoothSpeed`, `aimMaxAlpha`) dengan guard clamp.
- `Shared/GameData/FlashlightConfig`: tambah tuning parity (`aimUpdateMinInterval = 1/45`, `aimSmoothSpeed = 8`, `aimMaxAlpha = 0.45`) untuk mengurangi delay aim remote antar-client.
- Validasi teknis: `scripts/release-preflight.ps1 -Json` sukses (`buildOk: true`; manual blocker tersisa smoke test 2 client nyata).

### 2026-04-19 — Patch Batch E (UI recovery after death/return hardening)

- `Client/UI/Main`: pada event `ReturnedToLobby` / `RoomBrowserRoomLeft`, room browser kini di-unsuppress secara eksplisit, state room browser di-reset, lalu visibility disinkron ulang agar tidak nyangkut tersembunyi karena race event/attribute.
- `Client/UI/Main`: binding suppression room browser ditambah listener attribute `MatchLifecyclePhase` dan `MatchId` selain `InMatch`, supaya recovery UI lebih responsif saat lifecycle berubah.
- Validasi teknis: `scripts/release-preflight.ps1 -Json` sukses (`buildOk: true`; manual blocker tersisa smoke test 2 client nyata).

### 2026-04-19 — Patch Batch F (VFX/Audio map-profile authority parity hardening)

- `Client/Controllers/Sensory/VFXController`: tambah helper authority match-state (`isAuthoritativeInMatch`) berbasis `InMatch` atau `MatchId + lifecycle active`; dipakai pada resolve map profile dan preparation visual gating.
- `Client/Controllers/Sensory/VFXController`: tambah listener `MatchId` change agar sinkronisasi profile/fog tidak telat saat transisi.
- `Client/Controllers/Sensory/AudioController`: samakan authority logic untuk map reverb + ambient gating (`preparation/lobby`) agar tidak bergantung ke `InMatch` saja.
- `Client/Controllers/Sensory/AudioController`: tambah listener `MatchId` change untuk refresh heartbeat/reverb/ambient/results BGM saat lifecycle transisi.
- Validasi teknis: `scripts/release-preflight.ps1 -Json` sukses (`buildOk: true`; manual blocker tersisa smoke test 2 client nyata).

### 2026-04-19 — Patch Batch G (Studio smoke validation snapshot)

- Roblox Studio MCP: play mode smoke dijalankan pada `PASRAHPHOBIA.rbxlx`; startup snapshot menunjukkan profile awal `LobbySocialHub` untuk `PasrahVFXMapProfile` + `PasrahAudioMapProfile`.
- Simulasi transisi lifecycle lokal (race condition style): `InMatch=nil`, `MatchId=SMOKE_TEST`, `MatchLifecyclePhase=PreparationPhase`, `MatchMapId=HauntedHouse` -> profile VFX/Audio ter-resolve ke `HauntedHouse`; lanjut `InvestigationPhase` tetap `HauntedHouse`; reset lobby kembali `LobbySocialHub`.
- Console output runtime dari sesi smoke ini tidak menampilkan error baru.
- Status blocker validasi tetap: smoke test 2 client nyata belum dijalankan.

### 2026-04-19 — Patch Batch H (Publish smoke 2-client nyata PC + Android)

- Publish ulang lane aktif dijalankan dengan `scripts/Invoke-Rojo.ps1 upload --api_key $env:ROBLOX_OPEN_CLOUD_API_KEY --asset_id 113010869463813 --universe_id 9802743087 default.project.json` (exit code `0`).
- Smoke `2 client nyata` dijalankan pada publish lane:
  - PC RobloxPlayer boot ke lobby berhasil.
  - Android (`Samsung-N960`, device `266a038c0a017ece`) boot ke lobby berhasil.
  - Android `OPEN ROOM BROWSER` -> `BUAT ROOM` -> host start (`MULAI PERMAINAN`) berhasil dan transisi ke overlay in-match/loading berhasil.
- Verifikasi countdown host-start:
  - konfigurasi source tetap `HOST_START_COUNTDOWN_SECONDS = 5` (controller + service lobby),
  - pada smoke publish ini tidak ada indikasi jalur countdown host-start `30` detik.
- Catatan lane/environment:
  - lane `both` tidak siap karena `iPhone-14-Pro-Max` tidak tersedia di sesi ini.
  - automation klik/keypress PC untuk membuka Room Browser masih tidak stabil (known OS automation gap).
- Laporan lengkap + evidence:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/MULTICLIENT_PUBLISH_SMOKE_2026-04-19.md`

### 2026-04-19 — Patch Batch I (PC extended-display, PID-locked Windows click validation)

- Validasi khusus setup dual-monitor extended dijalankan untuk menutup asumsi salah jendela:
  - `DISPLAY1` extended (`X=-844, Y=-1440, 3440x1440`)
  - `DISPLAY2` primary (`X=0, Y=0, 1536x864`)
  - `RobloxPlayerBeta` test window terkunci di `WindowPid=44888` pada `DISPLAY2`.
- Semua klik disalurkan dengan target eksplisit `-WindowPid 44888` (bukan title pattern), termasuk:
  - area `OPEN ROOM BROWSER`
  - ikon menu Roblox kiri-atas
  - tombol close `DAILY MISSIONS`
  - plus lane input tambahan (`{ESC}`, `SendInput`, `PostMessage`).
- Hasil: tidak ada perubahan state visual PC di semua metode input sintetis; Room Browser tetap tidak terbuka dari automation Windows.
- Kesimpulan batch ini:
  - issue bukan karena salah monitor/salah window selection,
  - gap tersisa berada pada acceptance input sintetis oleh Roblox Player di mesin/sesi ini.
- Detail evidence dicatat di:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/MULTICLIENT_PUBLISH_SMOKE_2026-04-19.md`

### 2026-04-21 — Patch Batch J (PC focus flicker + spawn stabilization)

- `Client/CameraController.client.lua`:
  - tambah state `windowFocused` via `UserInputService.WindowFocused/WindowFocusReleased`.
  - jalur mismatch mouse mode pada render-step diubah menjadi re-apply ringan (`applyFpvMouseMode` + `ensureCameraAuthority`) tanpa memanggil `setFpvLocked(true)` berulang.
  - `setFpvLocked` dibuat idempotent saat status lock sudah aktif, sehingga reset `_fpvJustActivated` tidak berulang setiap frame.
  - target: menurunkan flicker/visual duplicate saat kursor keluar-masuk jendela Roblox Player.
- `Server/MatchSystem/MatchTeleport.lua`:
  - `getCharacterRoot` kini memprioritaskan `HumanoidRootPart` sebelum `PrimaryPart`.
  - kandidat `PreparationSpawn` diprioritaskan node eksplisit (`PreparationSpawn_*` atau attribute `PasrahPreparationSpawn`) agar tidak memilih geometry acak.
  - fallback spawn dipaksa upright dengan `buildUprightFacingCFrame(...)` (tidak mewarisi rotasi part fallback yang bisa terbalik).
  - tambah post-teleport upright enforcement + state recovery humanoid (`GettingUp` -> `Running`) untuk meredam spawn kepala di bawah.
  - tambah dedupe teleport per `UserId` agar player duplikat di daftar match tidak diteleport ganda.
  - perpanjang freeze/server ownership pasca-teleport untuk meredam falling loop awal pada client streaming.
- Validasi teknis:
  - `scripts/release-preflight.ps1 -Json` sukses (`buildOk: true`; manual blocker tetap: smoke test 2 client nyata belum dijalankan).

### 2026-04-21 — Patch Batch K (Single-window policy + client perf hardening)

- `Client/UI/Main`:
  - tambah `single-window strict policy` (`_enforceSingleWindowPolicy`) agar panel aktif maksimal satu (`RoomBrowser/Match/Auxiliary/MainMenu/Leaderboard/Lobby`).
  - tambah dedupe `ScreenGui` by-name (`_dedupeScreenGuiByName`) untuk mencegah window duplicate/tumpang tindih dari instance bernama sama.
- `Client/MovementController.client.lua`:
  - refactor reference lifecycle karakter (`CharacterAdded` + `CharacterRemoving` + `resolveLiveCharacterRefs`) agar `Humanoid`/`HumanoidRootPart` tidak stale setelah respawn.
  - loop `RenderStepped` sekarang guard aman untuk `nil`/character invalid, sehingga risiko nil-crash berkurang.
- `Client/FlashlightController.client.lua`:
  - pindah dari loop `RenderStepped` permanen ke connection lifecycle (`syncAimLoop`): koneksi dibuat hanya saat flashlight aktif + player in-match, diputus saat tidak perlu.
  - kirim aim vector hanya saat berubah (`dot delta threshold`) + keepalive periodik, bukan spam payload identik 20Hz saat kamera diam.
  - dedupe `FlashlightToggleUI` by-name + cleanup koneksi `InputChanged` saat tombol dihancurkan.
- `Client/CameraResolver.lua`:
  - buat shared resolver untuk `CurrentCamera` dengan timeout; dipakai di `CameraController` dan `FlashlightController` untuk menghapus duplikasi `resolveCamera()` dan mencegah infinite wait loop.
- `Client/CameraController.client.lua`:
  - runtime stamping attr (`stampFpvRuntime`/`stampCursorToggleRuntime` dan attr motion) diubah ke `set-if-changed` untuk menekan replication spam.
  - refresh camera realign diberi token cancel agar coroutine lama cepat berhenti saat trigger baru masuk.
- Validasi teknis:
  - `scripts/release-preflight.ps1 -Json` sukses (`buildOk: true`; manual blocker tetap: smoke test 2 client nyata belum dijalankan).

### 2026-04-21 — Patch Batch L (Preparation spawn source fix + RoomBrowser flex fullscreen + teleport overlay clear)

- `Server/MatchSystem/MatchTeleport.lua`:
  - tambah deteksi spawn preparation eksplisit (`PreparationSpawn_*`, `PlayerSpawn_*`, `PasrahPreparationSpawn`) lintas `PreparationSpawnArea`, `PreparationStagingRuntime`, dan fallback terfilter dari `SpawnPoints` saat staging runtime ada.
  - `getSpawnCandidates` sekarang memprioritaskan source `PreparationStagingRuntime`, plus sort deterministic untuk fallback `SpawnPoints`.
  - `match.preparationWorldBoard` sekarang diset dari runtime staging aktual (`hasPreparationStagingRuntime(mapClone)`), bukan asumsi statis.
  - hardening teleport karakter: orientasi spawn dipaksa upright + recovery humanoid (`GettingUp` -> `Running`) + re-apply upright bertahap untuk meredam spawn kepala terbalik/falling loop.
- `Server/MatchSystem/MapRuntimePatches.lua`:
  - `MapRuntimePatches.Apply` memastikan `patchPreparationStaging(mapId, mapClone, matchContext)` aktif di jalur patch map.
- `Client/UI/Main.lua`:
  - `buildRoomBrowserRenderKey` tidak lagi mengikutkan countdown detik (update countdown tetap via overlay khusus) untuk mengurangi refresh visual berkedip.
  - sizing RoomBrowser diubah agar benar-benar fleksibel terhadap viewport aktual (clamp ke ukuran viewport, tidak overflow), sekaligus menghindari jitter inset saat fokus window berubah.
  - cleanup binding scale panel RoomBrowser yang redundant (tidak perlu listener viewport khusus untuk scale=1).
  - fase `Preparation` dengan world staging sekarang memaksa `TeleportScreen` hide saat loading screen dimatikan agar overlay loading tidak nyangkut.
  - sinkron lifecycle authoritative (`InGame/Hunt/Result`) kini defensif: stop loop loading + hide teleport overlay jika state UI tertinggal.
- Smoke test Studio (self-test) setelah patch:
  - host-start -> masuk `PreparationPhase` sukses.
  - spawn valid di staging luar (`insideRooms=[]`), orientasi karakter normal (`upY=1`).
  - `MatchLoadingUI` dan `TeleportScreen` tidak tersangkut (`Enabled=false`) pada preparation worldboard.
  - instance UI tidak duplikat (`RoomBrowserUI=1`, `RoomBrowserFloatUI=1`, `MatchLoadingUI=1`, `TeleportScreen=1`).
  - panel RoomBrowser ter-clamp ke viewport (`panelHeight <= viewportHeight`) pada window pendek.

### 2026-04-21 — Patch Batch M (Full phase test run to end-match + event evidence)

- Studio playtest run penuh dieksekusi sampai `EndMatch` dengan urutan fase terobservasi:
  - `Lobby` -> `PreparationPhase` -> `InvestigationPhase` -> (`HuntStarted` event terpicu) -> `EndMatch` (`InMatch=false`).
- Tool selection pada `PreparationPhase`:
  - runtime prompt tool tidak terpicu via automation input di sesi ini, fallback `StudioE2EControl:SetPreparationFocusTool(EMF)` dipakai untuk melanjutkan flow test.
- Door trigger validation (`Preparation -> Investigation`):
  - prompt pintu advance terdeteksi benar di `Workspace.ActiveMatches.Match_match_1.HauntedHouse.HauntedHouse.Doors.Door_FrontEntry`.
  - automation input prompt/keypress tidak memicu `DoorIsOpen` dan tidak mentransisikan fase pada sesi Studio ini.
  - fallback `StudioE2EControl:AdvancePhase(InvestigationPhase)` dipakai agar test dapat lanjut sampai end-match.
- Bukti event in-match (payload `MatchEvent`) terobservasi:
  - `EnvironmentalAudioTriggered` `eventType=LightFlicker` (light event) x1.
  - `EnvironmentalAudioTriggered` `eventType=ObjectThrow` (prop event) x1.
  - `GhostManifest` x1.
  - `JumpscareTriggered` x2.
  - `HuntStarted` x1.
- Ringkasan hasil run:
  - `totalEvents=45`, `counters={light=1, prop=1, ghost=1, jumpscare=2, hunt=1}`.
  - status akhir: `InMatch=false`, lifecycle client tetap merekam token `InvestigationPhase` sesudah `EndMatch` fallback.
- Catatan blocker yang masih terbuka:
  - interaksi prompt pintu preparation belum bisa dipicu reliably oleh automation input pada sesi Studio saat ini (sudah dicoba via `VirtualUser`, keyboard/mouse automation, dan playtest subagent).

### 2026-04-21 — Patch Batch N (Door-trigger deep probe, strict no-skip reattempt)

- Verifikasi terarah khusus trigger pintu preparation (`Door_FrontEntry`) menunjukkan jalur by-door memang bisa terjadi:
  - saat prompt `Pintu Depan / Buka Pintu` terlihat di viewport dan input `VirtualUser` diberikan setelah pre-click sekitar projected world-point pintu, lifecycle berubah `PreparationPhase -> InvestigationPhase` dan `DoorIsOpen=true`.
- Reattempt single-run ketat (semua fase berantai tanpa fallback `AdvancePhase`) masih belum stabil:
  - host start + preparation + pilih tool berhasil,
  - tetapi navigasi automation ke posisi pintu tidak selalu mencapai jarak interaksi secara konsisten (`door_move ok=false` pada run ketat), sehingga trigger pintu gagal pada run itu.
- Kesimpulan operasional saat ini:
  - evidence end-to-end phase + event (`light/prop/ghost/jumpscare` + hunt + end match) sudah ada,
  - evidence trigger pintu by-door juga ada pada run terpisah,
  - namun single-pass run yang menggabungkan keduanya masih flaky karena keterbatasan reliability movement/input automation Studio di sesi ini.

### 2026-04-21 — Patch Batch O (Blocker isolation, no-AdvancePhase validation, runtime UI anti-flicker sync)

- Root cause blocker yang ditemukan pada jalur `Preparation -> Investigation`:
  - player sudah dapat `PreparationFocusTool=EMF`, tetapi pada sebagian run jarak karakter yang realistis di depan pintu berada di kisaran `~6.5 - 7.3 studs` dan proximity gate tidak selalu terdeteksi stabil.
  - indikator runtime sempat menunjukkan `PasrahPrepAdvanceHasFocus=true` namun `PasrahPrepAdvanceNearby=false`, membuat phase tidak maju meski pemain sudah di pintu.
- Patch source diterapkan:
  - `Server/MatchSystem/DoorRuntime.lua`
    - `PREPARATION_ADVANCE_RADIUS_FALLBACK` dinaikkan ke `8.5`.
    - tambah resolver kandidat player preparation (`resolvePreparationAdvancePlayers`) agar deteksi proximity tidak bergantung list participant yang bisa stale.
  - `Server/AudioSystem/Service.lua`
    - tambah `ObjectThrow` ke rotasi ambient `hauntedhouse` untuk menutup gap event prop yang tidak muncul konsisten.
- Sinkron hardening UI anti-flicker pada script runtime Studio (`StarterPlayerScripts.Client.UI.Main`) agar test session saat ini memakai guard terbaru:
  - dedupe strict `ScreenGui` penting (`RoomBrowserUI/RoomBrowserFloatUI/MatchLoadingUI/TeleportScreen/...`) supaya jendela tidak tumpang tindih.
  - stabilkan `buildRoomBrowserRenderKey` (sort room list + tanpa countdown per-second) untuk mengurangi refresh jitter.
  - `_syncRoomBrowserSuppressionFromMatchContext` dibuat idempotent (tidak re-toggle 10x/detik saat state tidak berubah).
  - `_setRoomBrowserVisible` ditambah cooldown + idempotent guard agar tidak memicu flicker reveal berulang.
- Validasi no-bypass phase gate:
  - run `CreateRoom -> HostStart` tetap countdown `5` detik (`countdownRange=1..5`).
  - `PreparationFocusTool` terisi (`EMF`) via flow runtime preparation.
  - pintu front entry membuka lewat trigger pintu/proximity (`DoorIsOpen=true`) dan phase berpindah ke `InvestigationPhase` tanpa `AdvancePhase`.
- Observasi event pada run investigasi aktif:
  - `light`, `ghost`, `jumpscare`, dan `hunt` sudah terobservasi pada run terpisah.
  - `prop` (`ObjectThrow`) masih belum muncul pada runtime Studio aktif di sesi ini meski source sudah dipatch; perlu sesi verifikasi berikutnya setelah runtime server sinkron penuh ke source terbaru.

### 2026-04-22 — Patch Batch P (Strict anti-inside-room preparation spawn)

- `Server/MatchSystem/MapRuntimePatches.lua`:
  - tambah resolver `resolvePreparationStagingPlacement(...)` untuk mencari posisi staging preparation yang **tidak overlap** volume `Room_*`.
  - jika spawn lane awal masih di dalam room, staging didorong bertahap (`room escape`) hingga spawn lane keluar dari room-volume.
  - debug attr `PreparationStagingRuntimeDebug` ditambah suffix escape (`room_escape_steps`) untuk audit runtime.
- `Server/MatchSystem/MatchTeleport.lua`:
  - tambah guard `isPositionInsideAnyRoom(...)`.
  - hard-reject preparation spawn candidate yang masih berada di room-volume (`preparation_spawn_inside_room:*`), tanpa fallback ke spawn interior map.
  - log warning eksplisit untuk kandidat spawn yang ditolak agar mismatch cepat terdeteksi.
- Validasi teknis:
  - `scripts/release-preflight.ps1 -Json` sukses (`buildOk: true`).

### 2026-04-22 — Patch Batch Q (All-map gameflow retest on latest build)

- Retest dijalankan pada Studio instance baru dengan place hasil build terbaru:
  - `_tmp_release_preflight_build.rbxlx`
- Flow yang divalidasi per map:
  - `Lobby -> CreateRoom -> HostStart (5 detik) -> PreparationPhase -> by-door trigger -> InvestigationPhase`.
- Hasil:
  - `HauntedHouse`: PASS (`insideRooms=[]`, `doorOpen=true`, `InvestigationPhase` tercapai).
  - `StudioMMNineteen`: PASS (`insideRooms=[]`, `doorOpen=true`, `InvestigationPhase` tercapai).
  - `AbandonedPalace`: PASS (`insideRooms=[]`, `doorOpen=true`, `InvestigationPhase` tercapai).
  - `EmptyBuilding`: PASS (`insideRooms=[]`, `doorOpen=true`, `InvestigationPhase` tercapai).
- Countdown host-start:
  - terobservasi tetap `1..5` pada semua run, tidak ada jalur countdown `30` detik.
- Evidence update:
  - `.codex/evidence/gameflow-human-2026-04-22/REPORT.md` (section `Retest Update (2026-04-22, built place)`).

### 2026-04-22 — Patch Batch R (Publish lane for 2-client manual validation)

- Publish lane dijalankan untuk membuka jalur test manual 2 client:
  - `powershell -ExecutionPolicy Bypass -File scripts\Invoke-Rojo.ps1 upload --api_key $env:ROBLOX_OPEN_CLOUD_API_KEY --asset_id 113010869463813 --universe_id 9802743087 default.project.json`
- Hasil publish:
  - exit code `0`
  - timestamp lokal: `2026-04-22 22:06:34 +07:00`
