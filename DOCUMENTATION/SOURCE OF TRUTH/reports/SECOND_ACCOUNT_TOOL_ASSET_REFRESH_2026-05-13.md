# Second Account Tool Asset Refresh - 2026-05-13

Owner context: Miftah  
Branch/workspace: `brian-second-final`  
Studio account/session: `briankotak`  
Universe: `10138560838`

## Result

The old investigation-tool mesh permission blocker is resolved for the active Studio session and source branch.

The 8 inaccessible mesh IDs were:

| Tool | Old mesh ID |
|---|---:|
| KotakArwah | 99948530753242 |
| GerakanGaib | 103978310572809 |
| Dupa | 132658963178691 |
| Salib | 137973898872421 |
| Garam | 86541720573721 |
| BukuTerkutuk | 110340483573539 |
| BolaArwah | 80180718732937 |
| JejakEnergi | 134433508176285 |

## New Model Mapping

Runtime now uses second-account/team model assets from `asset mentah/ROBLOX CREATOR HUB/[SECOND ACCOUNT]/[ASSETID]`:

| Runtime tool | Model asset ID |
|---|---:|
| JejakEnergi | 123956446527287 |
| KotakArwah | 104500063540712 |
| SuhuMembeku | 118317264835866 |
| BukuTerkutuk | 73992115763537 |
| BolaArwah | 118000842920544 |
| GerakanGaib | 79255896387943 |
| Garam | 97825875959661 |
| PilSanity | 107015657670353 |
| Salib | 137421533182817 |
| Dupa | 102771624922639 |
| Flashlight | 92864868080920 |

## Source Changes

- `src/shared/GameData/ToolVisualConfig.lua` now points investigation tools to second-account/team model asset IDs.
- `src/ReplicatedStorage/Assets/Models/Tools/Salib.model.json`, `Garam.model.json`, and `Dupa.model.json` were updated where source is JSON-backed.
- `src/ServerScriptService/Server/ToolVisualAssetSystem/Main.lua` was added. It refreshes `ReplicatedStorage.Assets.Models.Tools` from `ToolVisualConfig.inventoryModelAssetId` through `InsertService:LoadAsset()` during server start.
- Tool placement/preview paths were hardened to carry the configured inventory model asset ID where existing runtime code clones tool models.

## Studio Changes

Active Studio `PASRAHPHOBIA` was refreshed in edit mode:

- `ReplicatedStorage.Assets.Models.Tools`
- `Workspace.Checklist Visualtemplates.FPVHandAndToolPreview.ToolHoldPreviews`

Each refreshed model has `PasrahSecondAccountModelAssetId` matching the table above.

## Verification

- `scripts/Invoke-Rojo.ps1 sourcemap`: pass.
- `scripts/Invoke-Rojo.ps1 build default.project.json --output .codex/tmp/preflight-build-after-second-account-tool-assets.rbxlx`: pass.
- Studio Play Test: pass.
- Runtime attribute check: `ReplicatedStorage.PasrahToolVisualAssetRefreshCount = 11`.
- Log scan found `ToolVisualAssetSystem Init` and `ToolVisualAssetSystem Start`; no `not authorized`, `Failed to grant`, `Failed to refresh`, or old tool mesh IDs were found in the target log scan.

## Ghost Additional Asset Note

`ghost-assetid.md` and `meshparts-assetid.md` include additional/static second-account ghost model references. They were not wired over the current runtime ghost rigs because the game now depends on normalized skinned base rig asset IDs plus uploaded per-ghost animation assets. Replacing those with static refs would risk breaking `HasSkinnedMesh=true` and the ghost animation pipeline.

Additional/static ghost references captured for later art use:

| Ghost reference | Model asset ID |
|---|---:|
| banaspati | 97456316811319 |
| GENDERUWO | 105918624352583 |
| GENDERUWO-AGGRESSIVE | 134276874050331 |
| HANTU-TANAH | 132583256352195 |
| HANTU-TANAH alternate | 76939381729897 |
| JERANGKONG | 111398758078419 |
| KUNTILANAK | 108806984965269 |
| KUNTILANAK-AGGRESSIVE | 120578702101148 |
| LEAK | 125138857536215 |
| PALASIK | 123882636000788 |
| POCONG | 78523657576858 |
| SILUMAN-ULAR | 137287114113323 |
| SUNDELBOLONG | 131700767022518 |
| SUNDELBOLONG-AGGRESSIVE | 70983571304250 |
| tuyul | 102084111362264 |
| tuyul alternate | 136953492966030 |
| wewegombel | 119826289571885 |
| wewegombel alternate | 129502819674334 |

Related meshpart-only references:

| Ghost meshpart reference | Meshpart asset ID |
|---|---:|
| HANTU-TANAH | 127919543217717 |
| SILUMAN-ULAR | 86494635690615 |
