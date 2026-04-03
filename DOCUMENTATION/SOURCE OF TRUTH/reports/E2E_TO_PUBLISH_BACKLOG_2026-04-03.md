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

Pekerjaan:

- audit semua LocalScript legacy di `src/client`
- putuskan mana yang dipertahankan, dimigrasi, atau dimatikan
- pastikan hanya satu jalur HUD, audio, sanity, evidence, dan tool UI

Done jika:

- client boot tidak lagi memuat owner ganda untuk surface utama

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
  - `MatchUI` hunt sekarang membaca state survive live:
    - `HIDDEN`
    - `SHELTERED`
    - `TRACKED`
    - `CRITICAL`
  - blocker sisa untuk slice ini pindah ke helper test Studio yang belum konsisten memaksa phase visual `Hunt`

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
  - `DoorTraversalMode = PromptManual`
  - `Door_DiningRoom.CanCollide = true`
  - `Door_DiningRoom.CanTouch = true`
  - `Door_DiningRoom.DoorIsOpen = false`
  - `Door_DiningRoom.DoorTraversalPolicy = PromptManual`
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
- validasi trigger `E` via automation tool masih belum bisa saya kunci end-to-end:
  - prompt memang muncul live di layar
  - tetapi state part hasil input otomatis belum cukup konsisten untuk saya tandai `done`
  - jadi policy pintu baru sudah aktif, namun verifikasi manual satu kali di Studio masih diperlukan untuk menutup task interaksi pintu sepenuhnya
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
- policy pintu `PromptManual` sekarang menjadi baseline traversal runtime yang source-controlled; desain final hybrid radius/manual tetap deferred
- follow-up deferred yang wajib masuk phase berikutnya:
  - pintu harus diputuskan finalnya antara radius, prompt manual, atau hybrid yang tetap logis lintas platform
  - audit tangga, akses lantai 2, dan jalur traversal map harus ditutup agar layout tidak terasa palsu saat investigasi/hunt
  - hiding spot dan aturan selamat dari hunt masih perlu didefinisikan secara eksplisit
  - prototipe `SafeZone`/shelter berbasis `HidingSystem` sudah masuk ke source, tetapi validasi live server-side masih blocked:
    - player attr `PasrahHideState` belum terbukti terisi di runtime
    - probe Studio-only terbaru membuktikan source edit-time sudah memuat:
      - `ServerScriptService.Server.HidingSystem`
      - `ServerScriptService.Server.PlayerHealthSystem`
      - readiness marker `PasrahHidingReady` dan `PasrahHuntPressureReady`
    - namun saat playtest marker runtime itu tetap `nil`, jadi blocker terbaru ada di aktivasi startup/runtime system, bukan di definisi `SafeZone` source
    - `StudioE2EControl` sekarang sudah source-controlled di `ReplicatedStorage.RemoteEvents`, tetapi listener server/ack masih tidak muncul di runtime terbaru
    - jadi survival loop hunt belum boleh dianggap selesai walau UI objective/hunt guidance sudah mulai disiapkan

Pekerjaan:

- pilih satu map utama
- audit extraction zone, spawn, blocker, collision, dan art pass minimum
- redesign interaksi pintu menjadi hybrid radius/manual yang tetap aman untuk roaming ghost
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

Pekerjaan:

- tool visual
- icon
- placement
- UI state

### 12. Rapikan UI modular

Status:

- in progress
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
- polish lanjutan `RoyalPassUI` juga sudah membuat track 30 hari muncul lebih cepat di viewport aktif:
  - tab `30 DAY REWARD` dan `30 DAY MISSION` sekarang terlihat di atas scroller track
  - screenshot validasi `ScreenCapture_RoyalPass_30Day_Taller` menunjukkan kartu hari awal langsung terlihat tanpa scroll panjang
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
- terapkan aturan single-open untuk panel besar agar lobby/pass/shop/rank tidak terasa tumpang tindih
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

Pekerjaan:

- validasi di lingkungan non-mock
- audit schema player data
- failover dan migration plan

Done jika:

- data session penting tersimpan dan pulih dengan benar

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
- blocker tersisa:
  - belum ada item source-controlled yang benar-benar punya `gamePassId/productId` nyata
  - jadi jalur Robux production belum bisa ditutup end-to-end tanpa input manual dari Creator Hub

Pekerjaan:

- sambungkan Robux purchase flow nyata
- pastikan economy tidak hanya konseptual
- audit entitlement dan reward grant

Done jika:

- pembelian Roblox benar-benar bekerja end-to-end

### 16. Licensing dan attribution

Status:

- in progress
- ledger awal sudah dibuat di `reports/ASSET_LICENSE_LEDGER_2026-04-03.md`
- validasi live `MarketplaceService:GetProductInfo()` sekarang sudah menutup sebagian asset aktif:
  - `Heartbeat` terverifikasi account-owned (`Creator = ZyraaaVex`)
  - `Jumpscare_01` terverifikasi `IsPublicDomain = true`
  - pack animasi aktif terverifikasi sebagai animasi default `Roblox`
- blocker yang masih nyata sekarang menyempit ke:
  - `Pocong` masih `user-asserted` sampai bukti lisensinya diarsipkan
  - satu slot audio canonical masih `replace/remove` (`AmbientLoop_Main`)
  - `ButtonClick` runtime sudah tertutup via fallback built-in, tetapi belum punya signature click brand final
  - upload asset final ke Roblox account masih perlu langkah manual
- replacement queue dan helper apply sekarang sudah siap:
  - `reports/AUDIO_REPLACEMENT_PLAN_2026-04-03.md`
  - `scripts/set-audio-asset-ids.ps1`
 - validasi live `MarketplaceService:GetProductInfo()` dan client playback sekarang juga sudah menutup beberapa asset aktif:
   - `EnvironmentalCreak_01`
   - `GhostManifest_01`
   - `HuntStart_01`
   - `CountdownTick_01`
   - footstep set `Wood/Concrete/Metal`

Pekerjaan:

- audit seluruh asset eksternal
- catat lisensi dan atribusi
- gantikan asset yang tidak aman untuk komersial

Done jika:

- tidak ada asset komersial yang status lisensinya meragukan

### 17. QA dan perf gate

Pekerjaan:

- memory baseline
- network sanity
- server log cleanliness
- multi-player test

Done jika:

- pass gate minimum sebelum publish

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

