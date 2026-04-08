# Audio Replacement Plan 2026-04-03

## Tujuan

Dokumen ini menutup gap antara:

- slot audio runtime yang sudah kosong secara jujur di source
- kebutuhan publish komersial yang menuntut asset final legal

Targetnya bukan sekadar "cari sound", tetapi:

1. tentukan slot mana yang benar-benar aktif
2. tentukan kandidat source legal yang cocok
3. siapkan jalur apply ke repo setelah asset di-upload ke Roblox account aktif

## Status Saat Ini

Slot canonical yang **sudah terisi dan sinkron dengan inventory Roblox aktif**:

1. `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
   - runtime canonical sekarang memakai `rbxassetid://140704980462451`
   - source inventory:
     - `Midnight Litany of Drones (Ancient Ritual Ambient)`
   - status:
     - blocker ambience kosong sudah tertutup
     - asset ini memang inventory-only; tidak punya exact-name raw match di lokal, tetapi sudah valid sebagai upload akun aktif

2. `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`
   - runtime canonical `UISystem` sekarang memakai `rbxassetid://85056627192723`
   - source inventory:
     - `click5`
   - status:
     - blocker runtime sudah tertutup
     - sudah sinkron ke inventory upload akun aktif

Slot canonical yang **sudah terisi lagi** dan sudah tervalidasi runtime:

1. `src/ReplicatedStorage/Assets/Audio/Environment/EnvironmentalCreak_01.model.json`
2. `src/ReplicatedStorage/Assets/Audio/Ghost/GhostManifest_01.model.json`
3. `src/ReplicatedStorage/Assets/Audio/Ghost/GhostWhisper_01.model.json`
4. `src/ReplicatedStorage/Assets/Audio/Ghost/HuntStart_01.model.json`
5. `src/ReplicatedStorage/Assets/Audio/UI/CountdownTick_01.model.json`
6. `src/ReplicatedStorage/Assets/Audio/UI/TeleportDrop_01.model.json`
7. `src/ReplicatedStorage/Assets/Audio/Sensory/Heartbeat.model.json`
8. `src/ReplicatedStorage/Assets/Audio/Footsteps/Woodstep_01.model.json`
9. `src/ReplicatedStorage/Assets/Audio/Footsteps/ConcreteStep_01.model.json`
10. `src/ReplicatedStorage/Assets/Audio/Footsteps/MetalStep_01.model.json`

Catatan penting:

- audio yang tadi terasa `broken` ternyata bukan terutama karena asset Roblox invalid
- akar masalah runtime yang nyata adalah:
  - slot canonical dulu berisi placeholder/broken ID lama
  - event audio server belum di-relay ke `MatchEvent` client
  - `client/SoundSystem` hanya menyimpan payload dan belum memutar `Sound` runtime
- pada `2026-04-03` jalur playback modern sudah ditutup untuk:
  - `EnvironmentalAudio`
  - `FearAudio`
  - `GhostAudio`
  - `HuntAudio`
- validasi client live sebelumnya membuktikan kategori runtime modern memang hidup; source canonical terbaru sekarang dipetakan ke asset upload akun aktif berikut:
  - `AmbientLoop_Main -> rbxassetid://140704980462451`
  - `EnvironmentalCreak_01 -> rbxassetid://111282528409948`
  - `GhostWhisper_01 -> rbxassetid://98105844059537`
  - `ButtonClick_01 -> rbxassetid://85056627192723`
  - `CountdownTick_01 -> rbxassetid://81830522846878`
  - `TeleportDrop_01 -> rbxassetid://82086363159443`

## Asset Yang Sudah Tervalidasi

1. `Heartbeat`
   - `rbxassetid://138884191945388`
   - hasil `MarketplaceService:GetProductInfo()`:
     - creator `ZyraaaVex`
     - `AssetTypeId = 3`
   - status:
     - diperlakukan sebagai asset internal/account-owned

2. `Jumpscare_01`
   - `rbxassetid://138186576`
   - hasil `MarketplaceService:GetProductInfo()`:
     - creator `samthemagicman`
     - `IsPublicDomain = true`
   - status:
     - aman dipertahankan

3. Ghost animation pack aktif
   - `507771019`, `507776043`, `507766388`, `507767714`, `507777826`
   - hasil `MarketplaceService:GetProductInfo()` menunjukkan creator `Roblox`
   - status:
     - legal/runtime clear
     - masih placeholder artistik, bukan final ghost animation pack

## Update 2026-04-08

Batch canonicalization terbaru sudah memakai asset upload akun aktif yang ditemukan di inventory Roblox. Slot yang tadinya kosong/fallback sekarang sudah terisi sebagai berikut:

- `AmbientLoop_Main` -> `rbxassetid://140704980462451` (`Midnight Litany of Drones (Ancient Ritual Ambient)`)
- `EnvironmentalCreak_01` -> `rbxassetid://111282528409948` (`door_creak_3`)
- `GhostWhisper_01` -> `rbxassetid://98105844059537` (`ghost_whisper_3`)
- `ButtonClick_01` -> `rbxassetid://85056627192723` (`click5`)
- `CountdownTick_01` -> `rbxassetid://81830522846878` (`tick_001`)
- `TeleportDrop_01` -> `rbxassetid://82086363159443` (`drop_002`)

Tambahan canonical owner yang juga sudah diselaraskan ke inventory upload akun aktif:

- `DoorRuntime` / `MapRuntimePatches`
  - open -> `rbxassetid://83005562781593` (`doorOpen_2`)
  - close -> `rbxassetid://78764817933410` (`doorClose_1`)
- `FlashlightConfig.sound.soundId` -> `rbxassetid://140513388846872` (`switch15`)

Artinya blocker upload untuk batch audio canonical ini sudah tertutup untuk slot-slot yang memang sudah tersedia di inventory. Queue di bawah sekarang tinggal berfungsi sebagai catatan historis dan opsi art-pass masa depan, bukan blocker aktif.

## Candidate Queue Historis / Opsional

Semua kandidat di bawah dipilih karena lisensinya jelas dari halaman sumber dan cocok untuk role slot-nya. Mereka **belum otomatis ada di Roblox**; perlu download + upload ke account aktif dulu.

### 1. AmbientLoop_Main

- Role:
  - loop ambience gelap untuk background investigation
- Candidate:
  - `mysterious synth drone loop` by `burning-mir`
  - Source: <https://freesound.org/people/burning-mir/sounds/223447/>
  - License:
    - Public Domain / CC0
- Notes:
  - cocok dipotong atau di-loop sebagai ambience low-pressure
  - target volume source tetap rendah karena slot ini sudah di-tune `Volume = 0.25`
  - status sekarang:
    - **sudah tidak blocker**
    - canonical source aktif memakai `rbxassetid://140704980462451`

### 2. EnvironmentalCreak_01

- Role:
  - accent environment pendek, bukan ambience utama
- Candidate:
  - `Creaky Metal Door and Spooky Wind` by `Breviceps`
  - Source: <https://freesound.org/people/Breviceps/sounds/683012/>
  - License:
    - Creative Commons 0
- Notes:
  - cocok dipotong jadi 1-2 varian creak pendek
  - tidak perlu loop
  - status sekarang:
    - **sudah tidak blocker**
    - canonical source aktif memakai `rbxassetid://111282528409948`

### 3. GhostManifest_01

- Role:
  - cue manifest pendek saat ghost mulai terlihat/terasa
- Candidate:
  - `Creepy Whoosh Subtle` by `SoundEffectsForAll`
  - Source: <https://freesound.org/people/SoundEffectsForAll/sounds/840812/>
  - License:
    - Creative Commons 0
- Notes:
  - cocok untuk cue manifestation yang halus / transisi muncul
  - karakter suaranya lebih dekat ke `manifest` daripada `whisper`

### 4. GhostWhisper_01

- Role:
  - whisper paranormal pendek pada event ghost
- Candidate:
  - `Ghost Whispers` by `Litruv`
  - Source: <https://freesound.org/s/175944/>
  - License:
    - Creative Commons 0
- Notes:
  - dipilih karena explicit disebut `Ghost Whispers`
  - perlu trim agar tidak terlalu panjang untuk trigger pendek
  - status sekarang:
    - **sudah tidak blocker**
    - canonical source aktif memakai `rbxassetid://98105844059537`

### 5. HuntStart_01

- Role:
  - cue naik/tegang saat hunt dimulai
- Candidate:
  - `Simple Riser` by `SoundEffectsForAll`
  - Source: <https://freesound.org/people/SoundEffectsForAll/sounds/840719/>
  - License:
    - Creative Commons 0
- Notes:
  - cocok untuk cue start hunt yang pendek dan langsung membangun tensi
  - tetap bisa diganti nanti jika ingin karakter yang lebih brutal saat art pass audio final

### 6. ButtonClick_01

- Role:
  - klik tombol UI utama
  - dipakai untuk micro-feedback pada lobby, room browser, shop, dan panel auxiliary
- Current runtime fallback:
  - `rbxassetid://85056627192723`
  - source inventory:
    - `click5`
- Status:
  - blocker runtime sudah tertutup
  - cue brand baseline sudah hidup dengan asset upload akun aktif; penggantian selanjutnya opsional
- Candidate final:
  - optional
  - hanya diperlukan jika ingin mengganti signature click sekarang dengan versi brand lain

## Kenapa Belum Langsung Di-apply

Bagian ini sekarang hanya berlaku untuk asset raw baru yang **belum** ada di inventory upload Roblox.

Untuk batch 2026-04-08, apply sudah bisa dilakukan karena asset yang dipakai memang sudah ada di inventory akun aktif dan `rbxassetid://...`-nya sudah berhasil dicocokkan dengan nama lokal.

Blocker ke depan tetap sama untuk raw asset baru:

- workflow MCP yang aktif bisa inspect/edit Studio, tetapi tidak punya tool upload audio ke inventory account
- repo lokal juga tidak punya jalur otomatis untuk membuat asset audio Roblox tanpa credential/upload step

Artinya, langkah manual yang masih dibutuhkan hanyalah:

1. download source audio
2. trim jika perlu
3. upload ke account Roblox aktif
4. ambil asset ID hasil upload

Setelah empat langkah itu selesai, apply ke source bisa dibatch lewat script helper.

## Apply Path

Gunakan helper:

- `scripts/set-audio-asset-ids.ps1`

Contoh:

```powershell
pwsh -NoLogo -File .\scripts\set-audio-asset-ids.ps1 `
  -AmbientLoopMainId 1234567890 `
  -EnvironmentalCreakId 1234567891 `
  -GhostManifestId 1234567892 `
  -GhostWhisperId 1234567893 `
  -HuntStartId 1234567894
```

Script itu akan menulis `AudioContent = "rbxassetid://..."` langsung ke lima file source canonical.

Untuk slot UI click, tambahkan:

```powershell
pwsh -NoLogo -File .\scripts\set-audio-asset-ids.ps1 `
  -UIButtonClickId 1234567895
```

## Exit Criteria

Dokumen ini dianggap tercapai untuk batch canonical saat ini jika:

1. slot canonical yang tadinya kosong/fallback sudah terisi asset ID inventory aktif
2. source `.model.json` aktif membaca ID baru tersebut
3. owner script aktif (`DoorRuntime`, `MapRuntimePatches`, `FlashlightConfig`) ikut terselaraskan
4. `ASSET_LICENSE_LEDGER_2026-04-03.md` dan ledger inventory sudah sinkron dengan status baru

## Update 2026-04-08 22:49 ICT

Batch `expanded inventory audio cue coverage` menutup penggunaan runtime berikut:

- `zap2` (`rbxassetid://96038914699044`) -> cue `env_lightflicker`
- `zap1` (`rbxassetid://82526759214554`) -> cue `env_radiostatic`
- `creaky-door-open` (`rbxassetid://139204195403262`) -> cue `env_shadowapparition`
- `ghost_footstep_2` (`rbxassetid://95974189526179`) -> cue `env_footstepsound`
- `ghost_whisper_2` (`rbxassetid://110779846516591`) -> cue `env_suddenwhisper`
- `thermometer_reading` (`rbxassetid://87230026682789`) -> cue `env_temperaturedrop`
- `hard-horror-hit-drum` (`rbxassetid://101202336513383`) -> cue `hunt_start`
- `horror-deep-drum-heartbeat` (`rbxassetid://138329686293368`) -> cue `hunt_phase_loop`

Owner runtime aktif:

- `src/client/SoundSystem/Main.lua`

Kesimpulan:

- cue ambient/hunt yang sebelumnya masih jatuh ke template generik sekarang memakai asset upload yang lebih sesuai secara fungsi, tetap lewat owner audio existing dan tanpa local raw path.

## Update 2026-04-08 22:55 ICT

Batch `legacy audio cue alias coverage` menutup alias runtime berikut:

- `hunt_stinger` -> `hard-horror-hit-drum` (`rbxassetid://101202336513383`)
- `heartbeat_rise` -> `single-heart-beat` (`rbxassetid://138884191945388`)
- `ambient_tension_loop` -> `Midnight Litany of Drones (Ancient Ritual Ambient)` (`rbxassetid://140704980462451`)

Owner runtime aktif:

- `src/client/SoundSystem/Main.lua`

Kesimpulan:

- cue default/legacy sekarang tetap masuk ke asset upload inventory yang sudah terkunci, tanpa mengganti producer event lama dan tanpa membuat sistem audio baru.

