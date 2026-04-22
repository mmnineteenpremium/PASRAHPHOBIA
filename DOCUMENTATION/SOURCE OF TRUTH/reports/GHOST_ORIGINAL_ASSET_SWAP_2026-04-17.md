# Ghost Original Asset Swap 2026-04-17

## Scope
- Replace old ghost visual references that still pointed to previous single-mesh IDs.
- Keep architecture unchanged and only remap assets.

## Live Studio Replacement
- `ReplicatedStorage.Assets.Models.Ghosts.Pocong` replaced from `Workspace.POCONGG_roblox`
  - mesh id: `rbxassetid://99082725039705`
- `ReplicatedStorage.Assets.Models.Ghosts.Kuntilanak` replaced from `Workspace.KUNTI SET_roblox`
  - mesh id: `rbxassetid://76089809053285`
- `KuntilanakAggressive` kept on current uploaded mesh:
  - mesh id: `rbxassetid://71105873671727`

## Source-of-truth Config Updates
- Updated `src/ReplicatedStorage/Assets/GhostVisualProfiles/Pocong.lua`
  - `meshPartName` -> `node_0`
  - `meshId` -> `rbxassetid://99082725039705`
  - PBR map slots cleared to empty strings to avoid stale texture map references.
- Updated `src/shared/GameData/GhostVisualTuning.lua`
  - `Pocong.inventoryModelAssetId` -> `rbxassetid://99082725039705`
  - `Kuntilanak.inventoryModelAssetId` -> `rbxassetid://76089809053285`
  - `KuntilanakAggressive.inventoryModelAssetId` -> `rbxassetid://71105873671727`

## Result
- Old Pocong/Kuntilanak single-mesh ID references are no longer used in runtime tuning/profile files.
- Wiring layer can continue from this baseline using the newly uploaded original ghost assets.

## Wiring Update 2026-04-17 (Custom Rig + Variant Naming)
- Updated server ghost visual resolver in `src/ServerScriptService/Server/GhostSystem/Service.lua`.
- Runtime now resolves ghost rig/model by naming pattern, including variant suffixes:
  - `Aggressive`
  - `Agressive`
  - `Angry`
- Added base-type fallback mapping so visual tuning still applies when model name carries variant/prefix (for example `Ghost_KuntilanakAggressive`).
- Added runtime promotion path: when ghost enters aggressive/hunt conditions, service can swap to aggressive mesh variant if model exists in `ReplicatedStorage.Assets.Models.Ghosts`.
- No architecture/system replacement introduced; only wiring enhancement in existing GhostSystem visual path.
