# Ghost Runtime New Asset Wiring 2026-05-13

Owner context: Miftah  
Branch: `brian-second-final`  
Studio account context: `briankotak`  
Creator target: `PASRAHPHOBIA DEVELOPER & TEAM`  
Universe permission target: `10138560838`

## Change

Runtime ghost visual resolution now prefers the latest team-owned base rig asset IDs before falling back to legacy source templates.

2026-05-13 normalized reupload update: eight formerly static base rig IDs were superseded by normalized Open Cloud reuploads that pass Studio `HasSkinnedMesh=true` audit. See `GHOST_BASE_NORMALIZED_REUPLOAD_AUDIT_2026-05-13.md` for the reupload and scale audit details.

Files changed:

- `src/shared/GameData/GhostVisualTuning.lua`
- `src/ServerScriptService/Server/GhostSystem/Service.lua`

## Runtime Behavior

`GhostSystem.Service` now:

1. Reads the configured ghost `inventoryModelAssetId`.
2. Uses `InsertService:LoadAsset(assetId)` to load the latest team-owned rigged model at runtime.
3. Caches the loaded model template by asset ID for the current server session.
4. Clones the loaded template into the match container.
5. Falls back to legacy `ReplicatedStorage.Assets.Models.Ghosts` templates only if the asset ID load fails.
6. Falls back to placeholder only if both latest asset load and legacy template fail.

Spawned ghost models are stamped with:

- `PasrahGhostInventoryModelAssetId`
- `PasrahLoadedFromAssetId`
- `VisualGhostType`
- `GhostType`

## Latest Base Rig Asset IDs

| Ghost | Asset ID |
|---|---:|
| `Banaspati` | `125985418520274` |
| `Genderuwo` | `116514308503184` |
| `HantuTanah` | `97068595212213` |
| `Jerangkong` | `115554451751983` |
| `Kuntilanak` | `111714179492317` |
| `Leak` | `98855032697085` |
| `Palasik` | `78260225419720` |
| `Pocong` | `135270375666027` |
| `SilumanUlar` | `87361945667344` |
| `SundelBolong` | `89326336764042` |
| `Tuyul` | `128588579954533` |
| `WeweGombel` | `101666948803556` |

Aggressive/angry visual variants currently reuse the base rig asset for their base ghost.

## Validation

Source validation:

- Rojo sourcemap: pass
- Rojo build: pass
- Stale active asset IDs removed from `GhostVisualTuning.lua`
- Legacy Pocong forced `meshSize`/`meshOffset` removed from `GhostVisualTuning.lua`

Studio validation:

- `ReplicatedStorage.Shared.GameData.GhostVisualTuning` mirrored to active Studio.
- `ServerScriptService.Server.GhostSystem.Service` mirrored to active Studio.
- `require(GhostSystem.Service)` pass.
- `require(GhostVisualTuning)` pass.
- Runtime initializer smoke created and destroyed temporary match containers for all 12 ghost types.
- All 12 returned non-placeholder ghosts with `PasrahLoadedFromAssetId` matching the latest asset ID.

Smoke result summary:

| Ghost | Runtime Loaded Asset ID | Placeholder |
|---|---:|---|
| `Banaspati` | `125985418520274` | false |
| `Genderuwo` | `116514308503184` | false |
| `HantuTanah` | `97068595212213` | false |
| `Jerangkong` | `115554451751983` | false |
| `Kuntilanak` | `111714179492317` | false |
| `Leak` | `98855032697085` | false |
| `Palasik` | `78260225419720` | false |
| `Pocong` | `135270375666027` | false |
| `SilumanUlar` | `87361945667344` | false |
| `SundelBolong` | `89326336764042` | false |
| `Tuyul` | `128588579954533` | false |
| `WeweGombel` | `101666948803556` | false |

## Remaining

- Full match Play Test still needs to validate scale/orientation inside real map flow.
- Ghost animation upload/wiring remains separate and still waits for converted/published AnimationIds.

## Brian Branch Persistence Addendum

After reopening `PASRAHPHOBIA.rbxlx`, Studio still had the old embedded `GhostVisualTuning` and `GhostSystem.Service` sources. The branch file was patched directly on disk for only those two ModuleScripts, then reopened successfully in Studio.

Fresh Studio validation after the disk patch:

- Active file: `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\brian-second-final\PASRAHPHOBIA.rbxlx`
- `GhostVisualTuning` in the reopened `.rbxlx` contains the 12 latest team-owned base rig asset IDs.
- `GhostSystem.Service` in the reopened `.rbxlx` contains `InsertService:LoadAsset` runtime loading and `PasrahLoadedFromAssetId` stamping.
- `InsertService:LoadAsset()` succeeded for all 12 latest ghost model asset IDs.
- `Service:InitializeMatch()` spawned all 12 ghosts as non-placeholder models with `PasrahLoadedFromAssetId` matching the expected latest asset ID.
- Rojo sourcemap validation passed after the persistence fix.

Known note: the `.rbxlx` still contains old `PackageIdSerialize` references for embedded legacy fallback package models. Runtime now attempts the latest team asset IDs first, so those legacy package references are not used while asset permissions remain valid.

