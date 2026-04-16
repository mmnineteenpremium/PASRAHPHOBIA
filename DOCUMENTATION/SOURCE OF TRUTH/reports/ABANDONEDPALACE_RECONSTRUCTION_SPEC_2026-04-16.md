# AbandonedPalace Reconstruction Spec 2026-04-16

## Scope

- Visual source of truth `AbandonedPalace` adalah imported `AbandonedPalace.rbxm`.
- Rekonstruksi dilakukan dengan mempertahankan logic dan architecture yang sudah ada, lalu memindahkan wiring lama ke map baru yang lebih readable.
- Constraint owner yang tetap berlaku:
  - tidak membuat system baru
  - tidak mengubah arsitektur
  - tidak improvisasi liar tanpa persetujuan

## Runtime Canonical Status

- Source live aktif:
  - `src/ReplicatedStorage/Maps/AbandonedPalace/AbandonedPalace.rbxm`
  - `src/ServerStorage/Maps/AbandonedPalace/AbandonedPalace.rbxm`
- Legacy source json sudah dinonaktifkan:
  - `AbandonedPalace.model.json.disabled` pada kedua root map.
- Runtime scaffold canonical sekarang membangun folder dan marker berikut pada clone map:
  - `Rooms`
  - `InteractionPoints`
  - `SpawnPoints`
  - `SafeZones`
  - `GhostSpawns`
  - `EvidenceSpawnNodes`
  - `Doors`
  - `Lights`
  - `Props`
  - `Electronics`
  - `Windows`
- Canonical runtime references:
  - `src/shared/GameData/Maps/AbandonedPalace.lua`
  - `src/ServerScriptService/Server/MatchSystem/AbandonedPalaceRuntimeLayout.lua`
  - `src/ServerScriptService/Server/MatchSystem/AbandonedPalaceMapScaffold.lua`
  - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - `src/ServerScriptService/Server/MatchSystem/EnvironmentalObjectRuntime.lua`

## Match Flow Canonical

- Preparation phase spawn berada di area entry melalui `PlayerSpawn_1..4`.
- `SafeZone_1` dan `SafeZone_2` aktif untuk staging awal.
- Countdown preparation berbasis timer dinonaktifkan:
  - `MatchService` memakai `PreparationPhase = -1`
  - `GamePhaseSystem` memakai `PreparationPhase = -1`
  - `GameConfig` memakai `preparationSeconds = 0`
- Trigger mulai investigasi berpindah ke aksi membuka `Door_GrandHall`.
- Prompt staging sintetis `BreachPrompt` untuk `AbandonedPalace` dinonaktifkan.

## Canonical Room Model

### Floor 1

- `GrandHall`
- `RoyalCorridor`
- `DiningHall`
- `Library`
- `GuestRoomA`
- `GuestRoomB`
- `GuestRoomC`
- `ServantRoomA`
- `ServantRoomB`
- `ServantRoomC`
- `Basement`
- `Courtyard`
- `Armory`
- `Chapel`
- `Ballroom`
- `Observatory`
- `StorageWing`
- `CeremonyRoom`

### Preserved Gameplay Semantics

- Hide spot rooms:
  - `StorageWing`
  - `ServantRoomA`
  - `ServantRoomB`
- Ghost room candidates:
  - `Library`
  - `GuestRoomA`
  - `DiningHall`
  - `Basement`
  - `RoyalCorridor`

## Runtime Object Coverage

| Family | Count | Canonical Requirement |
| --- | --- | --- |
| `Rooms` | `18` | room-by-room topology source |
| `InteractionPoints` | `18` | one per room |
| `Doors` | `18` | all core traversal doors |
| `Lights` | `18` | every room has light coverage |
| `Props` | `18` | every room has move/throw target coverage |
| `Electronics` | `6` | TV/radio/panel disturbances |
| `Windows` | `6` | window knock coverage |
| `EvidenceSpawnNodes` | `14` | active evidence topology |
| `GhostSpawns` | `5` | active ghost room distribution |
| `SpawnPoints` | `4` | preparation support |
| `SafeZones` | `2` | preparation support zones |

Canonical rule:

- `LightFlicker`, `TV/Radio`, `ObjectMove/ObjectThrow`, and `WindowKnock` targets must always resolve to either:
  - imported visual asset on the map, or
  - generated runtime fallback asset

## Status

- Wiring canonical `AbandonedPalace` sudah dilakukan.
- Countdown preparation sudah dinonaktifkan.
- Trigger phase sudah dipindah ke `Door_GrandHall`.

## Change Log

- `2026-04-16` replaced legacy visual source with imported `AbandonedPalace.rbxm` in `ReplicatedStorage` and `ServerStorage`
- `2026-04-16` disabled `AbandonedPalace.model.json` source in both map roots
- `2026-04-16` scaffolded canonical `Rooms`, `Doors`, `InteractionPoints`, `SpawnPoints`, `SafeZones`, `GhostSpawns`, `EvidenceSpawnNodes`, `Lights`, `Props`, `Electronics`, and `Windows`
- `2026-04-16` preserved canonical room topology to `18` rooms on `1` floor
- `2026-04-16` disabled timer-based preparation countdown and moved investigation start to `Door_GrandHall`
