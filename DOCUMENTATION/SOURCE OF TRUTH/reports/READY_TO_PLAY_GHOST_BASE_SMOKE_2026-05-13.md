# Ready To Play Ghost Base Smoke - 2026-05-13

Branch: `brian-second-final`  
Studio file: `PASRAHPHOBIA.rbxlx`  
Status: playable local smoke pass with residual visual asset warning

## Completed

- Eight formerly static ghost base rigs were normalized, reuploaded to the team group, and wired in `GhostVisualTuning`.
- Studio `InsertService:LoadAsset` audit passed for all eight normalized reuploads with `HasSkinnedMesh=true`.
- Runtime `GhostSystem.Service:InitializeMatch` smoke passed for all checked ghost keys and variants.
- `scripts/build-ghost-animation-upload-plan.ps1` now points animation conversion work to the normalized base rig asset IDs.
- Animation plan generation produces 84 items and excludes repaired backup files such as `*.wrong-handyhands.*.fbx`.
- `scripts/upload-ghost-animation-rbxm-assets.ps1 -DryRun` correctly reports `missing_file=84` because converted `.rbxm/.rbxmx` animation files do not exist yet.
- Rojo source build passed:
  - `powershell -ExecutionPolicy Bypass -File scripts\Invoke-Rojo.ps1 build default.project.json --output .codex/tmp/preflight-build.rbxlx`

## Studio Play Smoke

Single-client Play Test result:

- Player loaded: `briankotak`
- PlayerGui loaded expected UI shells including `LobbyUI`, `RoomBrowserUI`, `MatchUI`, `SanityHUDGui`, `QuestTrackerGui`, `OwnerSettingsLauncher`, and `PASRAHPHOBIA_BottomNavbar_Static`.
- `GhostVisualTuning` in runtime resolves the eight normalized asset IDs:
  - `Genderuwo`: `116514308503184`
  - `HantuTanah`: `97068595212213`
  - `Kuntilanak`: `111714179492317`
  - `Leak`: `98855032697085`
  - `Palasik`: `78260225419720`
  - `Pocong`: `135270375666027`
  - `Tuyul`: `128588579954533`
  - `WeweGombel`: `101666948803556`
- No `ClientBootstrap`, `Ghost`, `Animation`, `attempt to index`, or `MusicPlayer` warning/error remained after the guard patch.

## Residual Warning

One non-fatal visual asset delivery error remains:

- `MeshContentProvider failed to process https://assetdelivery.roblox.com/v1/asset?id=127919543217717 because 'could not fetch'`
- Local asset note identifies it as `HANTU-TANAH - 127919543217717 - meshpart` in `asset mentah\ROBLOX CREATOR HUB\[SECOND ACCOUNT]\[ASSETID]\meshparts-assetid.md`.

This did not block UI bootstrap or ghost base rig runtime smoke. Treat it as a visual asset dependency to recheck after publish/account permission stabilization.

## Animation Gate

Per-ghost animation upload is not complete yet. Roblox Open Cloud supports animation upload as `.rbxm/.rbxmx` only; raw `.fbx` clips still require Studio/Animation Editor conversion or a verified converter before upload.

Animation FBX source status after follow-up audit:

- 84/84 clips pass source preflight.
- Pocong's seven object-scale warnings were resolved by non-destructive normalized exports under `.codex/asset-imports/20260513-ghost-animation-rbxm/normalized-animation-fbx/Pocong`.
- The upload plan now references those normalized Pocong override files.

Game remains playable using the existing global fallback animation assets:

- `GhostIdle`: `507766388`
- `GhostHunt`: `507767714`
- `GhostManifest`: `507771019`
- `GhostAttack`: `507777826`
- `GhostJumpscare`: `507776043`

## Next Action

Before bulk animation upload, validate one normalized ghost in Animation Editor:

1. Load `Kuntilanak` or `Genderuwo` normalized base rig by asset ID.
2. Import one FBX clip, preferably `Idle`.
3. Confirm the mesh deforms correctly on the normalized skinned base.
4. Save/export/publish that animation path, then repeat or automate conversion for all 84 clips.
