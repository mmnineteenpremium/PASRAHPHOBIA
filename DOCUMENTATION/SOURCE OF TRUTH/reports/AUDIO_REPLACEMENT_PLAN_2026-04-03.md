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

Slot canonical yang **masih kosong** di source aktif sekarang tinggal:

1. `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
2. `src/ReplicatedStorage/Assets/Audio/Ghost/GhostWhisper_01.model.json`
3. `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`

Slot canonical yang **sudah terisi lagi** dan sudah tervalidasi runtime:

1. `src/ReplicatedStorage/Assets/Audio/Environment/EnvironmentalCreak_01.model.json`
2. `src/ReplicatedStorage/Assets/Audio/Ghost/GhostManifest_01.model.json`
3. `src/ReplicatedStorage/Assets/Audio/Ghost/HuntStart_01.model.json`
4. `src/ReplicatedStorage/Assets/Audio/UI/CountdownTick_01.model.json`
5. `src/ReplicatedStorage/Assets/Audio/UI/TeleportDrop_01.model.json`
6. `src/ReplicatedStorage/Assets/Audio/Sensory/Heartbeat.model.json`
7. `src/ReplicatedStorage/Assets/Audio/Footsteps/Woodstep_01.model.json`
8. `src/ReplicatedStorage/Assets/Audio/Footsteps/ConcreteStep_01.model.json`
9. `src/ReplicatedStorage/Assets/Audio/Footsteps/MetalStep_01.model.json`

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
- validasi client live membuktikan cue berikut benar-benar membuat `Sound` runtime yang `IsPlaying = true`:
  - `EnvironmentalAudioRuntime -> rbxassetid://139204195403262`
  - `FearAudioRuntime -> rbxassetid://138884191945388`
  - `GhostAudioRuntime -> rbxassetid://83336813491039`
  - `HuntAudioRuntime -> rbxassetid://138329686293368`

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

## Candidate Queue

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
- Candidate:
  - pending
  - belum ada asset final yang dikunci untuk karakter klik UI brand `PASRAHPHOBIA`
  - jangan pakai asset sementara yang tidak punya provenance jelas hanya demi menutup slot

## Kenapa Belum Langsung Di-apply

Blocker saat ini bukan pemilihan sumber, tetapi **upload ke Roblox account**:

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

Dokumen ini dianggap selesai jika:

1. tiga slot kosong yang tersisa sudah punya Roblox asset ID final
2. source `.model.json` sudah terisi
3. playtest boot tidak lagi memakai slot canonical kosong pada jalur aktif
4. `ASSET_LICENSE_LEDGER_2026-04-03.md` tidak lagi menyimpan unresolved audio slot sebagai blocker publish
