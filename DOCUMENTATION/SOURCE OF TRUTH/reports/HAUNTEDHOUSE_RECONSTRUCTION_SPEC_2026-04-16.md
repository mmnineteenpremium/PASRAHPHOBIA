# HauntedHouse Reconstruction Spec 2026-04-16

## Scope

- Visual source of truth `HauntedHouse` adalah imported `HauntedHouse.rbxm`.
- Rekonstruksi dilakukan dengan mempertahankan logic dan architecture yang sudah ada, lalu memindahkan wiring lama ke map baru yang lebih readable.
- Constraint owner yang tetap berlaku:
  - tidak membuat system baru
  - tidak mengubah arsitektur
  - tidak improvisasi liar tanpa persetujuan

## Runtime Canonical Status

- Source live aktif:
  - `src/ReplicatedStorage/Maps/HauntedHouse/HauntedHouse.rbxm`
  - `src/ServerStorage/Maps/HauntedHouse/HauntedHouse.rbxm`
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
  - `src/shared/GameData/Maps/HauntedHouse.lua`
  - `src/ServerScriptService/Server/MatchSystem/HauntedHouseRuntimeLayout.lua`
  - `src/ServerScriptService/Server/MatchSystem/HauntedHouseMapScaffold.lua`
  - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - `src/ServerScriptService/Server/MatchSystem/EnvironmentalObjectRuntime.lua`

## Match Flow Canonical

- Preparation phase spawn berada di luar rumah melalui `PlayerSpawn_1..4`.
- `SafeZone_1` dan `SafeZone_2` juga berada di area staging luar rumah.
- Countdown preparation berbasis timer dinonaktifkan:
  - `MatchService` memakai `PreparationPhase = -1`
  - `GamePhaseSystem` memakai `PreparationPhase = -1`
  - `GameConfig` memakai `preparationSeconds = 0`
- Trigger mulai investigasi berpindah ke aksi membuka `Door_FrontEntry`.
- Prompt staging sintetis `BreachPrompt` untuk `HauntedHouse` dinonaktifkan.

## Canonical Room Model

### Floor 1

- `Foyer`
- `DiningRoom`
- `Bathroom1`
- `StairHall`
- `LaundryRoom`
- `Bathroom2`
- `Kitchen`
- `Pantry`
- `LivingRoom`
- `Garage`

### Floor 2

- `HallwayMain`
- `Bathroom3`
- `Bedroom1`
- `ClosetA`
- `Bedroom2`
- `LinenCloset`
- `Bedroom3`
- `ClosetB`
- `Bathroom4`
- `BonusRoom`

### Preserved Gameplay Semantics

- Hide spot rooms:
  - `ClosetA`
  - `ClosetB`
- Ghost room candidates:
  - `LivingRoom`
  - `Kitchen`
  - `Garage`
  - `Bedroom1`
  - `Bedroom2`
  - `Bedroom3`
  - `BonusRoom`

## Runtime Object Coverage

| Family | Count | Canonical Requirement |
| --- | --- | --- |
| `Rooms` | `20` | room-by-room topology source |
| `InteractionPoints` | `20` | one per room |
| `Doors` | `18` | front door plus main interior traversal |
| `Lights` | `20` | every room has light coverage |
| `Props` | `20` | every room has move/throw target coverage |
| `Electronics` | `7` | selected rooms support TV/radio/self-activate events |
| `Windows` | `6` | window knock coverage |
| `EvidenceSpawnNodes` | `14` | active evidence topology |
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
| `Foyer` | `1` | front entry and investigation trigger lane | front door, light, prop, window, evidence |
| `DiningRoom` | `1` | social room near entry | door, light, prop, window, evidence |
| `Bathroom1` | `1` | small scare room | door, light, prop, evidence |
| `StairHall` | `1` | vertical connector | light, prop, electronic panel |
| `LaundryRoom` | `1` | service room | door, light, prop, evidence |
| `Bathroom2` | `1` | secondary bathroom | door, light, prop, evidence |
| `Kitchen` | `1` | evidence and radio scare room | light, prop, radio, evidence, ghost spawn |
| `Pantry` | `1` | compact storage scare room | sliding door, light, prop |
| `LivingRoom` | `1` | primary family room | doors, light, prop, TV, window, evidence, ghost spawn |
| `Garage` | `1` | storage / utility scare room | door, light, prop, panel, evidence, ghost spawn |
| `HallwayMain` | `2` | upstairs circulation backbone | light, prop, evidence adjacency |
| `Bathroom3` | `2` | upper bathroom | door, light, prop, evidence |
| `Bedroom1` | `2` | major ghost candidate room | door, light, prop, TV, window, evidence, ghost spawn |
| `ClosetA` | `2` | hide spot room | sliding door, light, prop |
| `Bedroom2` | `2` | quieter ghost candidate room | door, light, prop, evidence, ghost spawn adjacency |
| `LinenCloset` | `2` | compact storage scare room | sliding door, light, prop |
| `Bedroom3` | `2` | major ghost candidate room | door, light, prop, TV, window, evidence, ghost spawn |
| `ClosetB` | `2` | hide spot room | sliding door, light, prop |
| `Bathroom4` | `2` | upper bathroom | door, light, prop, evidence |
| `BonusRoom` | `2` | large flex scare room | door, light, prop, TV, window, evidence, ghost spawn |

## Implementation Notes

- Rekonstruksi tidak lagi memakai placeholder room lama seperti `Attic` dan `Basement`.
- Topologi legacy dipertahankan melalui fungsi gameplay, bukan dengan memaksa koordinat placeholder lama.
- Runtime canonical sekarang memakai `RoomId` dan `Floor` langsung pada proxy room.
- Closet hiding `HauntedHouse` tidak lagi dipaksa ke override proxy lama; room baru `ClosetA` dan `ClosetB` menjadi basis hide spot aktif.
- Front entry canonical saat ini adalah `Door_FrontEntry`, yang menarget `Decorative Exterior Door` pada fasad depan.

## Status

- Wiring canonical `HauntedHouse` sudah dilakukan.
- Countdown preparation sudah dinonaktifkan.
- Trigger phase sudah dipindah ke pintu depan asli.
- Preview live di Studio dibangun sebagai `Workspace.HauntedHouse_WiringPreview`.

## Change Log

- `2026-04-16` replaced legacy visual source with imported `HauntedHouse.rbxm` in `ReplicatedStorage` and `ServerStorage`
- `2026-04-16` removed embedded scripts from the imported model to prevent foreign systems from entering runtime
- `2026-04-16` scaffolded canonical `Rooms`, `Doors`, `InteractionPoints`, `SpawnPoints`, `SafeZones`, `GhostSpawns`, `EvidenceSpawnNodes`, `Lights`, `Props`, `Electronics`, and `Windows`
- `2026-04-16` expanded canonical room topology to `20` rooms across `2` floors (`10 + 10`)
- `2026-04-16` moved preparation staging outside the house and preserved compatibility names `PlayerSpawn_1..4`
- `2026-04-16` disabled timer-based preparation countdown and moved investigation start to `Door_FrontEntry`
- `2026-04-16` ensured environmental event coverage has no missing target definitions by resolving to imported assets or generated runtime fallbacks
- `2026-04-16` synced owner edits from `Workspace.HauntedHouse_Review` into active source roots (`ServerStorage` + `ReplicatedStorage`) with backup `HauntedHouse_PRESYNC_FROM_REVIEW_FINAL_20260416_083207`
- `2026-04-16` removed `Runtime.OutdoorBaseplateRuntime.OutdoorMainFloor` for `HauntedHouse` by owner request (HauntedHouse uses native map base only)
- `2026-04-16` rebuilt boundary to house+staging-only footprint, then tightened collider walls to prevent out-of-map exit and death exploits
- `2026-04-16` realigned realistic boundary trees directly on all four boundary sides (`North/South/West/East`) as visual+collision blocker
