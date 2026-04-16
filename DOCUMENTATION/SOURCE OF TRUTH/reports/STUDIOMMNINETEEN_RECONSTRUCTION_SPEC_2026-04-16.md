# StudioMMNineteen Reconstruction Spec 2026-04-16

## Scope

- Visual source of truth `StudioMMNineteen` adalah imported `StudioMMNineteen.rbxm`.
- Rekonstruksi dilakukan dengan mempertahankan logic dan architecture yang sudah ada, lalu memindahkan wiring lama ke map baru yang lebih readable.
- Constraint owner yang tetap berlaku:
  - tidak membuat system baru
  - tidak mengubah arsitektur
  - tidak improvisasi liar tanpa persetujuan

## Runtime Canonical Status

- Source live aktif:
  - `src/ReplicatedStorage/Maps/StudioMMNineteen/StudioMMNineteen.rbxm`
  - `src/ServerStorage/Maps/StudioMMNineteen/StudioMMNineteen.rbxm`
- Embedded script dari free model sudah dibuang saat import.
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
  - `src/shared/GameData/Maps/StudioMMNineteen.lua`
  - `src/ServerScriptService/Server/MatchSystem/StudioMMNineteenRuntimeLayout.lua`
  - `src/ServerScriptService/Server/MatchSystem/StudioMMNineteenMapScaffold.lua`
  - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - `src/ServerScriptService/Server/MatchSystem/EnvironmentalObjectRuntime.lua`

## Match Flow Canonical

- Preparation phase spawn berada di luar rumah melalui `PlayerSpawn_1..4`.
- `SafeZone_1` dan `SafeZone_2` berada di area staging luar rumah.
- Countdown preparation berbasis timer dinonaktifkan:
  - `MatchService` memakai `PreparationPhase = -1`
  - `GamePhaseSystem` memakai `PreparationPhase = -1`
  - `GameConfig` memakai `preparationSeconds = 0`
- Trigger mulai investigasi berpindah ke aksi membuka `Door_FrontEntry`.
- Prompt staging sintetis `BreachPrompt` untuk `StudioMMNineteen` dinonaktifkan.

## Canonical Room Model

### Floor 1

- `FrontPorch`
- `LivingRoom`
- `LaundryRoom`
- `StairHallL1`

### Floor 2

- `Kitchen`
- `DiningArea`
- `Bathroom`
- `StairHallL2`

### Floor 3

- `UpperHall`
- `Bedroom1`
- `Bedroom2`
- `StairHallL3`

### Preserved Gameplay Semantics

- Hide spot rooms:
  - `LaundryRoom`
  - `StairHallL3`
- Ghost room candidates:
  - `LivingRoom`
  - `Kitchen`
  - `Bathroom`
  - `Bedroom1`
  - `Bedroom2`

## Runtime Object Coverage

| Family | Count | Canonical Requirement |
| --- | --- | --- |
| `Rooms` | `12` | room-by-room topology source |
| `InteractionPoints` | `12` | one per room |
| `Doors` | `10` | front door plus main interior traversal |
| `Lights` | `12` | every room has light coverage |
| `Props` | `12` | every room has move/throw target coverage |
| `Electronics` | `6` | selected rooms support TV/radio/self-activate events |
| `Windows` | `6` | window knock coverage |
| `EvidenceSpawnNodes` | `12` | active evidence topology |
| `GhostSpawns` | `6` | active ghost room distribution |
| `SpawnPoints` | `4` | preparation outside house |
| `SafeZones` | `2` | preparation support zones |

Canonical rule:

- `LightFlicker`, `TV/Radio`, `ObjectMove/ObjectThrow`, and `WindowKnock` targets must always resolve to either:
  - imported visual asset on the map, or
  - generated runtime fallback asset

At the time of this update, runtime coverage audit returned no missing target definitions.

## Room-By-Room Use

| Room | Floor | Intended Use | Event Coverage |
| --- | --- | --- | --- |
| `FrontPorch` | `1` | preparation lane and investigation trigger | front door, light, prop, evidence |
| `LivingRoom` | `1` | primary social room | door, light, prop, TV, window, evidence, ghost spawn |
| `LaundryRoom` | `1` | service room and hide spot | door, light, prop, panel, window, evidence, ghost spawn |
| `StairHallL1` | `1` | lower circulation | door, light, prop, evidence |
| `Kitchen` | `2` | mid-floor evidence room | door, light, prop, radio, evidence, ghost spawn |
| `DiningArea` | `2` | transition room | door, light, prop, evidence |
| `Bathroom` | `2` | high-noise scare room | door, light, prop, panel, window, evidence, ghost spawn |
| `StairHallL2` | `2` | vertical connector | door, light, prop, evidence |
| `UpperHall` | `3` | upper circulation | door, light, prop, evidence |
| `Bedroom1` | `3` | upper evidence room | door, light, prop, TV, window, evidence, ghost spawn |
| `Bedroom2` | `3` | upper evidence room | door, light, prop, radio, window, evidence, ghost spawn |
| `StairHallL3` | `3` | upper connector / hide fallback | door, light, prop, evidence |

## Status

- Wiring canonical `StudioMMNineteen` sudah dilakukan.
- Countdown preparation sudah dinonaktifkan.
- Trigger phase sudah dipindah ke pintu depan.

## Change Log

- `2026-04-16` replaced legacy visual source with imported `StudioMMNineteen.rbxm` in `ReplicatedStorage` and `ServerStorage`
- `2026-04-16` removed embedded scripts from the imported model to prevent foreign systems from entering runtime
- `2026-04-16` scaffolded canonical `Rooms`, `Doors`, `InteractionPoints`, `SpawnPoints`, `SafeZones`, `GhostSpawns`, `EvidenceSpawnNodes`, `Lights`, `Props`, `Electronics`, and `Windows`
- `2026-04-16` defined canonical room topology to `12` rooms across `3` floors (`4 + 4 + 4`)
- `2026-04-16` moved preparation staging outside the house and preserved compatibility names `PlayerSpawn_1..4`
- `2026-04-16` disabled timer-based preparation countdown and moved investigation start to `Door_FrontEntry`
- `2026-04-16` ensured environmental event coverage has no missing target definitions by resolving to imported assets or generated runtime fallbacks
