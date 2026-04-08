# Roblox Inventory Sync Ledger 2026-04-08

## Tujuan

Dokumen ini mengunci mapping parsial antara:

- raw source lokal di `asset mentah/`
- asset upload akun Roblox yang sudah benar-benar terbaca di Studio

Dokumen ini **bukan** berarti semua raw asset sudah selesai di-upload.
Ledger ini hanya mencatat apa yang **sudah confirmed sinkron** saat ini.

## Constraint Tetap

- `asset mentah/` adalah raw source/reference, bukan runtime asset langsung.
- audio runtime harus memakai `rbxassetid://...`, bukan path lokal.
- raw asset tidak boleh di-upload, dihapus, di-rename, atau direorganize tanpa instruksi user.
- workflow tetap:
  - modify existing only
  - no duplicate systems
  - one domain = one owner

## Context Scan Yang Dipakai

- identity cloud canonical:
  - `PlaceId = 113010869463813`
  - `GameId = 9802743087`
  - `CreatorId = 10576163165`
- `Toolbox -> Inventory -> My Audio`
  - terbaca langsung di Studio window `PASRAHPHOBIA.rbxlx`
- `Toolbox -> Inventory -> My Models`
  - terbaca langsung di Studio window publish `PASRAHPHOBIA`

## Confirmed Audio Sync

### Exact name match + asset id locked

1. `scroll_001`
   - local source:
     - `asset mentah/asset all/sources/kenney_interface-sounds/Audio/scroll_001.ogg`
   - runtime asset:
     - `rbxassetid://73589904561594`
   - status:
     - `confirmed`

2. `bookFlip3`
   - local source:
     - `asset mentah/asset all/sources/kenney_rpg-audio/Audio/bookFlip3.ogg`
   - runtime asset:
     - `rbxassetid://97915135753208`
   - status:
     - `confirmed`

3. `doorClose_1`
   - local source:
     - `asset mentah/asset all/sources/kenney_rpg-audio/Audio/doorClose_1.ogg`
   - runtime asset:
     - `rbxassetid://78764817933410`
   - status:
     - `confirmed`

4. `thermometer_reading`
   - local source:
     - `asset mentah/asset all/SFX/Evidence Tools/thermometer_reading.wav`
   - runtime asset:
     - `rbxassetid://87230026682789`
   - status:
     - `confirmed`

5. `ghost_whisper_3`
   - local source:
     - `asset mentah/asset all/SFX/Ghost & Environment/ghost_whisper_3.wav`
   - runtime asset:
     - `rbxassetid://98105844059537`
   - status:
     - `confirmed`

6. `ui_error`
   - local source:
     - `asset mentah/asset all/SFX/UI/ui_error.wav`
   - runtime asset:
     - `rbxassetid://70594579947868`
   - status:
     - `confirmed`

7. `maximize_001`
   - local source:
     - `asset mentah/asset all/sources/kenney_interface-sounds/Audio/maximize_001.ogg`
   - runtime asset:
     - `rbxassetid://115397007938540`
   - status:
     - `confirmed`

8. `error_005`
   - local source:
     - `asset mentah/asset all/sources/kenney_interface-sounds/Audio/error_005.ogg`
   - runtime asset:
     - `rbxassetid://115835838848259`
   - status:
     - `confirmed`

### Exact name match visible in Studio, asset id not locked yet

1. `impactPunch_medium_002`
   - local source:
     - `asset mentah/asset all/sources/kenney_impact-sounds/Audio/impactPunch_medium_002.ogg`
   - status:
     - `name-confirmed`
     - `assetid-pending`

2. `switch15`
   - local source:
     - `asset mentah/asset all/sources/kenney_ui-audio/Audio/switch15.ogg`
   - status:
     - `name-confirmed`
     - `assetid-pending`

## Confirmed Model Sync

1. `pocong PASRAHPHIA`
   - local owner:
     - `src/ReplicatedStorage/Assets/Models/Ghosts/Pocong.model.json`
   - runtime asset:
     - `rbxassetid://123151303766691`
   - status:
     - `confirmed`

2. `genderuwo`
   - local owner:
     - `src/ReplicatedStorage/Assets/Models/Ghosts/Genderuwo.rbxm`
   - runtime asset:
     - `rbxassetid://117009327297852`
   - status:
     - `confirmed`

3. `kuntilanak_Iv Pole Walking`
   - closest local owner:
     - `src/ReplicatedStorage/Assets/Models/Ghosts/Kuntilanak.rbxm`
   - runtime asset:
     - `rbxassetid://93357688576883`
   - status:
     - `confirmed`

## Terlihat Di Inventory Tapi Belum Masuk Mapping Runtime

### My Audio

- `impactPunch_medium_002`
- `switch15`

### My Models

- `Time Played Leaderbo...`
- `Realistic Flashlight`
- `StarterPlayer`
- `0341c93314aeb9f...`
- `Scene`
- `dark+armored+knight...`

Catatan:

- item pada section ini bisa jadi valid upload akun, tetapi belum saya petakan ke owner runtime repo
- jangan dipakai otomatis hanya karena terlihat di inventory

## Kesimpulan Operasional

- saat ini yang **baru confirmed sinkron** antara lokal dan inventory upload memang **baru segini**
- itu normal karena upload dilakukan bertahap dan dibatasi kuota bulanan
- kalau nanti ada raw asset baru yang relevan, workflow yang benar tetap:
  1. cek raw asset lokal sebagai referensi/nama canonical
  2. cari exact match di `Toolbox -> Inventory`
  3. kunci `rbxassetid://...`
  4. pakai asset id itu di owner runtime yang sudah ada
