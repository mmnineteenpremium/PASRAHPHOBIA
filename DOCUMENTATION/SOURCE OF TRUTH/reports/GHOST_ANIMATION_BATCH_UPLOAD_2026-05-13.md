# Ghost Animation Batch Upload - 2026-05-13

Branch: `brian-second-final`  
Creator target: `PASRAHPHOBIA DEVELOPER & TEAM` / group id `407883270`

## Result

The full 12 ghost animation set is now converted, uploaded, applied to source, and mirrored in the active Studio place.

| Metric | Result |
|---|---:|
| Ghosts | 12 |
| Runtime keys per ghost | 7 |
| Converted `.rbxmx` files | 84 |
| Uploaded animation assets | 84 |
| Source per-ghost `Animation` JSON files | 84 |
| Studio mirrored per-ghost animation objects | 84 |
| Rojo build status | pass |

Runtime keys:

- Looping: `GhostIdle`, `GhostRoam`, `GhostHunt`
- Non-looping: `GhostManifest`, `GhostAttack`, `GhostJumpscare`, `GhostCooldown`

## Conversion

Added converter scripts:

- `scripts/blender_fbx_animation_to_rbxmx.py`
- `scripts/convert-ghost-animation-fbx-to-rbxmx.ps1`
- `scripts/convert-ghost-animation-plan-to-rbxmx.ps1`

Golden validation used `Kuntilanak.GhostIdle`:

- Generated output matched the manual Animation Editor `.rbxmx` structure.
- 80/80 keyframes matched.
- 0 missing/extra pose paths.
- Max CFrame diff: about `1.431e-06`.
- Mean CFrame diff: about `1.613e-07`.

Batch conversion result:

- `conversion-results.all-missing.json`: 82 converted, 2 skipped existing.
- Converted root: `.codex/asset-imports/20260513-ghost-animation-rbxm/converted`

## Upload Artifacts

Combined uploaded asset lists:

- `.codex/asset-imports/20260513-ghost-animation-rbxm/ghost-animation-uploaded-assetids.all-84.json`
- `.codex/asset-imports/20260513-ghost-animation-rbxm/ghost-animation-uploaded-assetids.all-84.csv`

Individual result files are retained beside the upload plan under:

- `.codex/asset-imports/20260513-ghost-animation-rbxm/`

## Validation

- Source audit: 84 per-ghost `Animation` JSON files, 0 missing AnimationIds.
- No UTF-8 BOM in animation `.model.json` files.
- Active Studio mirror audit: each of 12 ghosts has 7 runtime keys, with 3 looped and 4 non-looped entries.
- `AnimationClipProvider:GetAnimationClipAsync` loaded representative uploaded clips for `Banaspati`, `Pocong`, `WeweGombel`, `Kuntilanak`, and `SilumanUlar`.
- Runtime targeting hardening was applied to `src/client/GhostAnimationPipeline/Main.lua` and mirrored into the active Studio instance. The client now resolves the ghost model by `GhostType`, `VisualGhostType`, `VisualTemplateName`, or model name. When a ghost type is known it no longer falls back to arbitrary Workspace `AnimationController` or `Humanoid`; it retries until the matching ghost rig exists and only creates a fallback `GhostAnimationController` inside that matched ghost rig. `Init()` also resets the active animator, repeated non-looping actions can replay after their previous track stops, and `GetState()` now exposes `activeAnimatorPath`, `activeTrackAnimationId`, `activeTrackPlaying`, and `lastPlayError`.
- Attribute fallback was added for runtime match state. `GhostAnimationPipeline` listens to local player attributes including `PasrahGhostRenderManifesting`, `PasrahGhostRuntimeState`, `PasrahGhostSessionState`, `PasrahGhostHuntActive`, and `PasrahGhostType`; this covers the case where server state attributes replicate before or without a client `MatchEvent` animation payload.
- Targeting smoke passed after removing old `Workspace.ActiveMatches.Match_smoke_*` artifacts from the active Studio scene: a fake player humanoid placed before a `Ghost_Kuntilanak` rig did not receive ghost animation playback.
- Real-rig smoke passed for `Kuntilanak`, `Pocong`, and `SilumanUlar`: each loaded from its team model asset, reported 1 skinned mesh part, loaded `GhostIdle`, and played the uploaded animation clip.
- Full pipeline smoke passed for `Kuntilanak`: `GhostAnimationPipeline:Play("GhostIdle", "Kuntilanak")` selected `rbxassetid://110913223261685`, produced `ghostTracks=1`, and left `playerTracks=0`.
- Studio Play Test E2E passed using a temporary local smoke script and the existing `StudioE2EControl` remote:
  - place identity: `PlaceId=89787959603872`, `UniverseId=10138560838`
  - forced ghost: `Kuntilanak`
  - solo match: `match_1`, `HauntedHouse`, `InvestigationPhase`
  - runtime ghost: `Workspace.ActiveMatches.Match_match_1.Ghost_Kuntilanak`
  - active animator: `Workspace.ActiveMatches.Match_match_1.Ghost_Kuntilanak.Kuntilanak_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.AnimationController.Animator`
  - pipeline state: `activeAnimation=GhostManifest`, `activeGhostType=Kuntilanak`, `activeTrackPlaying=true`, `perGhostTrackCount=84`
  - playing ghost track: `rbxassetid://77086566115618`
  - player ghost-animation tracks: `0`
  - temporary smoke script/attributes were removed after stopping Play.
- Residual non-ghost access warning remains for 8 investigation-tool mesh assets under `ReplicatedStorage.Assets.Models.Tools` and `Workspace.Checklist Visualtemplates.FPVHandAndToolPreview.ToolHoldPreviews`: `99948530753242`, `103978310572809`, `132658963178691`, `137973898872421`, `86541720573721`, `110340483573539`, `80180718732937`, and `134433508176285`. Open Cloud permission grant to Universe `10138560838` returned `CannotManageAsset` for all 8, so this must be fixed by the asset-owning account/group or by reuploading/replacing those tool meshes under the team owner. This did not block the ghost animation E2E pass.
- Active Studio Play Tests were started/stopped during validation; the visible repeated console noise was from the built-in `AnimationClipEditor` plugin window, not from PASRAHPHOBIA project scripts.
- Rojo validation passed:
  - `scripts/Invoke-Rojo.ps1 sourcemap`
  - `scripts/Invoke-Rojo.ps1 build default.project.json --output .codex/tmp/preflight-build-after-all-ghost-animations.rbxlx`
  - `scripts/Invoke-Rojo.ps1 build default.project.json --output .codex/tmp/preflight-build-after-runtime-ghost-animation-targeting.rbxlx`
  - `scripts/Invoke-Rojo.ps1 build default.project.json --output .codex/tmp/preflight-build-after-runtime-ghost-animation-attribute-fallback.rbxlx`
  - `scripts/Invoke-Rojo.ps1 build default.project.json --output .codex/tmp/preflight-build-after-ghost-animation-targeted-animator.rbxlx`

## Notes

- `Kuntilanak.GhostIdle` kept the manually saved golden `.rbxmx` uploaded as `110913223261685`.
- `SilumanUlar.GhostIdle` kept the extracted saved clip uploaded as `96845915731729`.
- The remaining 82 clips were generated from audited FBX sources using the converter, then uploaded and applied.
