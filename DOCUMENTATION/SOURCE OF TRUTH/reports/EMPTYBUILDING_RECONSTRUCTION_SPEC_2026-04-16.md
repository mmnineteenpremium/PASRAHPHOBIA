# EmptyBuilding Reconstruction Spec 2026-04-16

## Scope

- Visual source of truth `EmptyBuilding` adalah imported `EmptyBuilding.rbxm`.
- Rekonstruksi dilakukan dengan mempertahankan logic dan architecture yang sudah ada, lalu memindahkan wiring lama ke map baru yang lebih readable.
- Constraint owner yang tetap berlaku:
  - tidak membuat system baru
  - tidak mengubah arsitektur
  - improvisasi hanya pada level isi map (props/structure) saat diperlukan untuk kewajaran layout

## Runtime Canonical Status

- Source live aktif:
  - `src/ReplicatedStorage/Maps/EmptyBuilding/EmptyBuilding.rbxm`
  - `src/ServerStorage/Maps/EmptyBuilding/EmptyBuilding.rbxm`
- Legacy source json sudah dinonaktifkan:
  - `EmptyBuilding.model.json.disabled` pada kedua root map.
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
  - `RuntimeDecor`
- Canonical runtime references:
  - `src/shared/GameData/Maps/EmptyBuilding.lua`
  - `src/ServerScriptService/Server/MatchSystem/EmptyBuildingRuntimeLayout.lua`
  - `src/ServerScriptService/Server/MatchSystem/EmptyBuildingMapScaffold.lua`
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
- Trigger mulai investigasi berpindah ke aksi membuka `Door_Lobby`.
- Prompt staging sintetis `BreachPrompt` untuk `EmptyBuilding` dinonaktifkan.

## Canonical Room Model

### Floor 1

- `Lobby`
- `SecurityRoom`
- `Storage`
- `ElectricalRoom`
- `OfficeA`
- `OfficeB`
- `Bathroom1`
- `StaircaseNorth`
- `StaircaseSouth`

### Floor 2

- `WorkspaceOpen`
- `MeetingRoom`
- `ServerRoom`
- `ArchiveRoom`
- `Bathroom2`

### Preserved Gameplay Semantics

- Hide spot rooms:
  - `Storage`
  - `ArchiveRoom`
  - `SecurityRoom`
- Ghost room candidates:
  - `ServerRoom`
  - `ArchiveRoom`
  - `Storage`
  - `MeetingRoom`
  - `ElectricalRoom`

## Runtime Object Coverage

| Family | Count | Canonical Requirement |
| --- | --- | --- |
| `Rooms` | `14` | room-by-room topology source |
| `InteractionPoints` | `14` | one per room |
| `Doors` | `14` | all core traversal doors |
| `Lights` | `14` | every room has light coverage |
| `Props` | `14` | every room has move/throw target coverage |
| `Electronics` | `6` | TV/radio/panel disturbances |
| `Windows` | `12` | window knock coverage |
| `EvidenceSpawnNodes` | `9` | active evidence topology |
| `GhostSpawns` | `5` | active ghost room distribution |
| `SpawnPoints` | `4` | preparation support |
| `SafeZones` | `2` | preparation support zones |
| `RuntimeDecor` | `4` | structural decor bundle |

Canonical rule:

- `LightFlicker`, `TV/Radio`, `ObjectMove/ObjectThrow`, and `WindowKnock` targets must always resolve to either:
  - imported visual asset on the map, or
  - generated runtime fallback asset

## Structural Improvisation (Approved)

To address map emptiness and floor-2 accessibility, runtime scaffold adds:

- `RuntimeDecor.NorthStairs` (usable staircase flight)
- `RuntimeDecor.SouthStairs` (usable staircase flight)
- `RuntimeDecor.ServiceLadder` (maintenance ladder access)
- `RuntimeDecor.FillerProps` (sensible office/storage fillers)

Improvisation scope is constrained to physical readability and traversal only; no new gameplay system is introduced.

## Status

- Wiring canonical `EmptyBuilding` sudah dilakukan.
- Countdown preparation sudah dinonaktifkan.
- Trigger phase sudah dipindah ke `Door_Lobby`.
- Structural decor untuk akses lantai 2 dan density ruangan sudah ditambahkan via scaffold.

## Owner-Approved Density + Wiring Syncback (2026-04-16)

- Interior density pass aktif pada source-of-truth runtime map:
  - `DecorFill`
  - `Partitions`
  - `AddedDoors`
  - `LiftLadder` (ladder-only, lift dekoratif dihapus)
  - `DecorPlus`
  - `DecorFloor2Plus`
  - `DecorBathroomPlus`
- Event-wiring no-missing-target dikunci:
  - `Lights`: semua proxy wired ke fallback generated `ceiling_light`
  - `Props`: semua proxy wired ke fallback generated `prop_box/prop_crate`
  - `Electronics`: semua proxy wired ke fallback generated `tv/radio`
  - `Windows`: semua proxy wired ke target fisik `WindowEventTargets` (`12`)
- Runtime parity source-of-truth telah disinkronkan:
  - `Workspace.EmptyBuilding_Review` -> `ServerStorage.Maps.EmptyBuilding.EmptyBuilding`
  - `Workspace.EmptyBuilding_Review` -> `ReplicatedStorage.Maps.EmptyBuilding.EmptyBuilding`

## Change Log

- `2026-04-16` replaced legacy visual source with imported `EmptyBuilding.rbxm` in `ReplicatedStorage` and `ServerStorage`
- `2026-04-16` disabled `EmptyBuilding.model.json` source in both map roots
- `2026-04-16` scaffolded canonical `Rooms`, `Doors`, `InteractionPoints`, `SpawnPoints`, `SafeZones`, `GhostSpawns`, `EvidenceSpawnNodes`, `Lights`, `Props`, `Electronics`, and `Windows`
- `2026-04-16` preserved canonical room topology to `14` rooms across `2` floors (`9 + 5`)
- `2026-04-16` disabled timer-based preparation countdown and moved investigation start to `Door_Lobby`
- `2026-04-16` added approved structural improv (`stairs/ladder/filler props`) via `RuntimeDecor` to ensure floor-2 access and sensible visual occupancy
- `2026-04-16` finalized owner-approved interior density set (`DecorFill`, `Partitions`, `AddedDoors`, `LiftLadder`, `DecorPlus`, `DecorFloor2Plus`, `DecorBathroomPlus`) on runtime source map
- `2026-04-16` finalized no-missing-target environmental wiring (`Lights/Props/Electronics/Windows`) and synced parity to both storage roots
