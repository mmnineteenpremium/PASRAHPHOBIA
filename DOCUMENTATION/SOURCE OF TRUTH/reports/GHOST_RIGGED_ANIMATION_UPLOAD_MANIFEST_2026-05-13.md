# Ghost Rigged Animation Upload Manifest 2026-05-13

Owner context: Miftah  
Active working branch: `brian-second-final`  
Active Studio account context: `briankotak` / second account  
Creator target: `PASRAHPHOBIA DEVELOPER & TEAM`  
Creator type/id: `Group` / `407883270`  
Status: side task, runtime not wired yet

## Decision Lock

- `zyraaavex` is paused for 3 days because of moderation appeal.
- Base rigged ghost models were uploaded with creator `PASRAHPHOBIA DEVELOPER & TEAM`.
- Continue animation upload under the team creator, not personal inventory.
- Do not wire runtime until animation IDs are complete and at least one ghost validates in Studio.
- Studio metadata check on `Kuntilanak_RIG_BASE_FIX` and `Banaspati_RIG_BASE_FIX` confirms creator `PASRAHPHOBIA DEVELOPER & TEAM`, `CreatorType=Group`, `CreatorTargetId=407883270`.

## API / Studio Upload Finding

Official Open Cloud Assets API supports `Animation`, but animation content upload format is `.rbxm` / `.rbxmx`, not raw `.fbx`. The current generated animation sources are FBX files, so they must first be converted/imported into Studio as KeyframeSequence/Animation data through Animation Editor or plugin import.

Implication:

- FBX animation files should not be sent directly to Open Cloud as animation assets.
- Safe path: `Animation Editor > Import From FBX Animation > publish/save animation`.
- Alternate automation path later: convert/save each imported KeyframeSequence as `.rbxm`, then Open Cloud can upload the `.rbxm` animation content.

## Automation Artifact

- Plan generator added: `scripts/build-ghost-animation-upload-plan.ps1`
- Upload wrapper added: `scripts/upload-ghost-animation-rbxm-assets.ps1`
- Result applier added: `scripts/apply-ghost-animation-upload-results.ps1`
- Plan template added: `DOCUMENTATION/SOURCE OF TRUTH/reports/GHOST_RIGGED_ANIMATION_UPLOAD_PLAN_TEMPLATE_2026-05-13.json`
- Default creator target is the team group: `PASRAHPHOBIA DEVELOPER & TEAM` / group id `407883270`.
- The wrapper intentionally rejects `.fbx` so animation sources cannot be uploaded through the wrong API path.
- Expected input after Studio/importer conversion:
  - plan JSON: `.codex/asset-imports/20260513-ghost-animation-rbxm/roblox-upload-plan.json`
  - converted files: `.codex/asset-imports/20260513-ghost-animation-rbxm/converted/**/*.rbxm` or `*.rbxmx`
  - output result: `.codex/asset-imports/20260513-ghost-animation-rbxm/roblox-upload-results.json`

Generate the 84-item upload plan from the local FBX source folders:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-ghost-animation-upload-plan.ps1
```

Dry-run command after converted files exist:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\upload-ghost-animation-rbxm-assets.ps1 -DryRun
```

Upload command after the dry run reports `dry_run_ready`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\upload-ghost-animation-rbxm-assets.ps1
```

After upload produces AnimationIds, write per-ghost `Animation` model JSON files into source:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\apply-ghost-animation-upload-results.ps1
```

## Runtime Wiring Audit

- Runtime reader: `src/client/GhostAnimationPipeline/Main.lua`
- Existing source contract before this side task: only global animation children under `ReplicatedStorage.Assets.Animations.Ghosts`.
- Prepared source contract after this side task:
  - global fallback remains supported: `Ghosts.GhostIdle`, `Ghosts.GhostHunt`, etc.
  - per-ghost override is supported when folders exist: `Ghosts.Kuntilanak.GhostIdle`, `Ghosts.Kuntilanak.GhostRoam`, etc.
  - variant ghost names such as `KuntilanakAggressive` can fall back to base folder `Kuntilanak`.
- `GhostRoamed` can now request `GhostRoam`; if the per-ghost/global `GhostRoam` asset is absent, it falls back to `GhostIdle`.
- Validation completed: Rojo sourcemap and Rojo build passed after the runtime reader update.
- Upload wrapper dry-run executed against the generated 84-item plan; current result is `missing_file=84` because converted `.rbxm/.rbxmx` files have not been exported yet.
- Source preflight audit added: `scripts/audit-ghost-animation-sources.ps1`.
- Source preflight result after repair: 84 plan items, 84 source FBX files found, 0 errors, 0 warnings.
- Dry-run upload after source repair still reports `missing_file=84`, which is expected until Studio/importer conversion produces `.rbxm/.rbxmx` files under `.codex/asset-imports/20260513-ghost-animation-rbxm/converted`.

## Source Preflight Repair

Automated audit found one bad generated clip before upload/conversion:

- `Genderuwo.GhostCooldown` / `Genderuwo_Vanish_RIG_BASE_FIX` had `target_bone_count=38` and `fbx_action=HandyHandsRig|Scene`, meaning the exported clip was accidentally from the Handy Hands rig.
- The correct `Genderuwo_Vanish_RIG_BASE_FIX.blend1` backup contained `Armature` with 54 bones and the correct Genderuwo mesh.
- The wrong `.blend` and `.fbx` were backed up, `.blend1` was restored to `.blend`, and the FBX was re-exported from Blender 5.1.
- The repaired FBX imports back into Blender as `Armature|Scene` with 54 bones.
- `Genderuwo_RIG_BASE_FIX_animation_report.json` was updated to match the repaired clip metadata.

Metadata cleanup also filled missing report details for `SilumanUlar`:

- All seven `SilumanUlar` generated `.blend` clips contain `SilumanUlar_Rig` with 119 bones and `node_0` with 4646 vertices / 119 vertex groups.
- `SilumanUlar_RIG_BASE_FIX_animation_report.json` now records `expected_bones=119` and per-clip mesh/bone metadata.

Current Studio staging for manual Animation Editor conversion:

- `Workspace.GhostAnimationImportStaging.Kuntilanak_BaseRig_AnimationImport`
- `Workspace.GhostAnimationImportStaging.SilumanUlar_BaseRig_AnimationImport`
- `Workspace.GhostAnimationImportStaging.Genderuwo_BaseRig_AnimationImport`

Use these three first for the conversion smoke. Start with `Kuntilanak` or `SilumanUlar`, then use `Genderuwo` to confirm the repaired `Vanish` clip.

## Animation Editor Skinning Blocker

Studio execution on 2026-05-13 found that the `Kuntilanak` and `Genderuwo` package assets are not valid animation bases even though they can be forced to open in Animation Editor:

- Clones `Kuntilanak_BoneRehydrated_AnimationImport` and `Genderuwo_BoneRehydrated_AnimationImport` were created by rebuilding `Bone` instances from `InitialPoses` plus the local FBX hierarchy.
- Animation Editor then accepted both clone rigs, which proves the original error was missing rig objects.
- The clone approach is not valid for final conversion because `node_0.HasSkinnedMesh=false`; adding `Bone` instances in Studio does not recreate mesh skin weights/bind data.
- Importing `Genderuwo_Idle_RIG_BASE_FIX.fbx` onto the rehydrated rig produced oversized `Bone.Transform` values and the mesh remained effectively static.
- Normalizing the test FBX armature object scale to `1,1,1` did not fix the Studio result, so the blocker is the uploaded package mesh being static, not only FBX scale.

Action lock:

- Do not publish animation clips from the rehydrated clones.
- Reimport/reupload the affected base rig packages from source FBX so Studio reports `HasSkinnedMesh=true` on the MeshPart.
- After each corrected base rig upload, reload by asset ID in Studio and verify both `Bone` count and `HasSkinnedMesh=true` before Animation Editor conversion.

Latest base rig skinned audit:

| Ghost | Base Rig Model Asset ID | HasSkinnedMesh | Bone Count Visible | Animation Conversion Status |
|---|---:|---|---:|---|
| `Banaspati` | `125985418520274` | yes | 1 | usable candidate; still validate clip import |
| `Genderuwo` | `98880262062359` | no | 0 | reimport base rig required |
| `HantuTanah` | `139296725422008` | no | 0 | reimport base rig required |
| `Jerangkong` | `115554451751983` | yes | 10 | usable candidate; still validate clip import |
| `Kuntilanak` | `85391462330878` | no | 0 | reimport base rig required |
| `Leak` | `123810909037540` | no | 0 | reimport base rig required |
| `Palasik` | `91886890215469` | no | 0 | reimport base rig required |
| `Pocong` | `111363343569502` | no | 0 | reimport base rig required |
| `SilumanUlar` | `87361945667344` | yes | 119 | best next conversion candidate |
| `SundelBolong` | `89326336764042` | yes | 48 | usable candidate; still validate clip import |
| `Tuyul` | `127455958486834` | no | 0 | reimport base rig required |
| `WeweGombel` | `137426068299766` | no | 0 | reimport base rig required |

## Re-Export Candidates For Failed Base Rigs

Because the failed uploaded package assets are static, skinned base candidates were exported from the skinned `Manifest` `.blend` files instead of the old root base FBX files.

Export artifacts:

- Job plan: `.codex/asset-imports/20260513-ghost-base-reexport/manifest-export-jobs.json`
- Blender export log: `.codex/asset-imports/20260513-ghost-base-reexport/manifest-export-log.txt`
- Import-back audit: `.codex/asset-imports/20260513-ghost-base-reexport/reexport-fbx-audit.json`
- Clean import-back audit: `.codex/asset-imports/20260513-ghost-base-reexport/reexport-fbx-audit.clean.json`
- Clean bounds audit: `.codex/asset-imports/20260513-ghost-base-reexport/reexport-fbx-bounds-audit.clean.json`
- Export script: `.codex/tmp/export_skinned_base_from_manifest.py`
- Audit script: `.codex/tmp/audit_fbx_skinning.py`
- Reimport checklist: `DOCUMENTATION/SOURCE OF TRUTH/reports/GHOST_BASE_REEXPORT_REIMPORT_CHECKLIST_2026-05-13.md`
- Pocong normalized candidate: `.codex/asset-imports/20260513-ghost-base-reexport/normalized-base/Pocong/Pocong_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx`
- Open Cloud base model upload plan/wrapper: `scripts/build-ghost-base-model-upload-plan.ps1` and `scripts/upload-ghost-base-model-fbx-assets.ps1`
- Final normalized reupload audit: `DOCUMENTATION/SOURCE OF TRUTH/reports/GHOST_BASE_NORMALIZED_REUPLOAD_AUDIT_2026-05-13.md`
- Ready-to-play smoke: `DOCUMENTATION/SOURCE OF TRUTH/reports/READY_TO_PLAY_GHOST_BASE_SMOKE_2026-05-13.md`
- Pocong animation normalized export: `DOCUMENTATION/SOURCE OF TRUTH/reports/POCONG_ANIMATION_NORMALIZED_EXPORT_2026-05-13.md`
- Kuntilanak GhostIdle upload smoke: `DOCUMENTATION/SOURCE OF TRUTH/reports/KUNTILANAK_GHOSTIDLE_ANIMATION_UPLOAD_SMOKE_2026-05-13.md`

Final normalized reupload asset IDs:

| Ghost | Normalized Base Rig Asset ID | Status |
|---|---:|---|
| `Genderuwo` | `116514308503184` | Studio `HasSkinnedMesh=true`; runtime smoke pass |
| `HantuTanah` | `97068595212213` | Studio `HasSkinnedMesh=true`; runtime smoke pass |
| `Kuntilanak` | `111714179492317` | Studio `HasSkinnedMesh=true`; runtime smoke pass |
| `Leak` | `98855032697085` | Studio `HasSkinnedMesh=true`; runtime smoke pass |
| `Palasik` | `78260225419720` | Studio `HasSkinnedMesh=true`; runtime smoke pass |
| `Pocong` | `135270375666027` | Studio `HasSkinnedMesh=true`; runtime smoke pass |
| `Tuyul` | `128588579954533` | Studio `HasSkinnedMesh=true`; runtime smoke pass |
| `WeweGombel` | `101666948803556` | Studio `HasSkinnedMesh=true`; runtime smoke pass |

| Ghost | Candidate FBX | Bones | Vertex Groups | Weighted Vertices | Note |
|---|---|---:|---:|---:|---|
| `Genderuwo` | `.codex/asset-imports/20260513-ghost-base-reexport/skinned-base/Genderuwo/Genderuwo_RIG_BASE_REEXPORT_SKINNED.fbx` | 54 | 54 | 4649 | Studio reimport candidate |
| `HantuTanah` | `.codex/asset-imports/20260513-ghost-base-reexport/skinned-base/HantuTanah/HantuTanah_RIG_BASE_REEXPORT_SKINNED.fbx` | 54 | 54 | 4630 | Studio reimport candidate |
| `Kuntilanak` | `.codex/asset-imports/20260513-ghost-base-reexport/skinned-base/Kuntilanak/Kuntilanak_RIG_BASE_REEXPORT_SKINNED.fbx` | 54 | 54 | 4647 | Studio reimport candidate |
| `Leak` | `.codex/asset-imports/20260513-ghost-base-reexport/skinned-base/Leak/Leak_RIG_BASE_REEXPORT_SKINNED.fbx` | 54 | 51 | 8486 | Studio reimport candidate |
| `Palasik` | `.codex/asset-imports/20260513-ghost-base-reexport/skinned-base/Palasik/Palasik_RIG_BASE_REEXPORT_SKINNED.fbx` | 11 | 11 | 9276 | Studio reimport candidate |
| `Pocong` | `.codex/asset-imports/20260513-ghost-base-reexport/normalized-base/Pocong/Pocong_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 16 | 16 | 4643 | normalized scale candidate; mesh/armature scale `1,1,1` |
| `Tuyul` | `.codex/asset-imports/20260513-ghost-base-reexport/skinned-base/Tuyul/Tuyul_RIG_BASE_REEXPORT_SKINNED.fbx` | 54 | 54 | 4640 | Studio reimport candidate |
| `WeweGombel` | `.codex/asset-imports/20260513-ghost-base-reexport/skinned-base/WeweGombel/WeweGombel_RIG_BASE_REEXPORT_SKINNED.fbx` | 54 | 53 | 4626 | preview scale carefully; source mesh scale is small |

Studio import settings for these candidate base rigs:

- Use 3D Importer / Avatar importer path that preserves rigged mesh data.
- `World Forward = Front`, `World Up = Top`, `Scale Unit = Stud`.
- Import as package when publishing the base rig.
- Do not publish until the imported MeshPart reports `HasSkinnedMesh=true`.
- If importer preview shows a static single MeshPart with no bones, reject that import and retry from the candidate FBX above.

## Runtime Base Rig Wiring Update

Base rig visual runtime wiring is now implemented separately from animation upload:

- Report: `DOCUMENTATION/SOURCE OF TRUTH/reports/GHOST_RUNTIME_NEW_ASSET_WIRING_2026-05-13.md`
- `src/shared/GameData/GhostVisualTuning.lua` now points to the latest 12 base rig asset IDs.
- `src/ServerScriptService/Server/GhostSystem/Service.lua` now prefers `InsertService:LoadAsset(assetId)` before legacy source templates.
- Active Studio was mirrored.
- Studio initializer smoke passed for all 12 ghost types with `PasrahLoadedFromAssetId` matching the latest asset IDs.

## Base Rig Model Asset IDs

| Ghost | Base Rig Model Asset ID | Runtime Status |
|---|---:|---|
| `Banaspati` | `125985418520274` | wired; runtime smoke pass |
| `Genderuwo` | `116514308503184` | normalized reupload wired; runtime smoke pass |
| `HantuTanah` | `97068595212213` | normalized reupload wired; runtime smoke pass |
| `Jerangkong` | `115554451751983` | wired; runtime smoke pass |
| `Kuntilanak` | `111714179492317` | normalized reupload wired; runtime smoke pass |
| `Leak` | `98855032697085` | normalized reupload wired; runtime smoke pass |
| `Palasik` | `78260225419720` | normalized reupload wired; runtime smoke pass |
| `Pocong` | `135270375666027` | normalized reupload wired; runtime smoke pass |
| `SilumanUlar` | `87361945667344` | wired; runtime smoke pass |
| `SundelBolong` | `89326336764042` | wired; runtime smoke pass |
| `Tuyul` | `128588579954533` | normalized reupload wired; runtime smoke pass |
| `WeweGombel` | `101666948803556` | normalized reupload wired; runtime smoke pass |

## Base Rig Load Audit

Historical note: the table below records the pre-normalized upload audit that exposed the static `HasSkinnedMesh=false` blocker. The normalized reupload IDs above supersede the failed rows.

Audit method: `InsertService:LoadAsset(assetId)` in the open `PASRAHPHOBIA.rbxlx` Studio instance, then count descendant classes. This does not prove Animation Editor import compatibility by itself; it only confirms the model asset can be loaded and what rig data is visible in Studio.

| Ghost | MeshPart | Bone | InitialPose CFrameValue | AnimationController | Bounds | Note |
|---|---:|---:|---:|---:|---|---|
| `Banaspati` | 1 | 1 | 9 | 1 | `1.38, 1.69, 1.77` | needs Animation Editor validation |
| `Genderuwo` | 1 | 0 | 168 | 1 | `6.41, 6.69, 2.31` | needs Animation Editor validation |
| `HantuTanah` | 1 | 0 | 168 | 1 | `5.96, 6.76, 2.56` | needs Animation Editor validation |
| `Jerangkong` | 1 | 10 | 36 | 1 | `1.38, 2.26, 0.71` | needs Animation Editor validation |
| `Kuntilanak` | 1 | 0 | 168 | 1 | `2.15, 1.80, 0.70` | inserted into `Workspace.GhostAnimationImportStaging.Kuntilanak_BaseRig_Test` |
| `Leak` | 1 | 0 | 168 | 1 | `4.35, 6.66, 4.80` | needs Animation Editor validation |
| `Palasik` | 1 | 0 | 39 | 1 | `4.71, 8.34, 2.48` | needs Animation Editor validation |
| `Pocong` | 1 | 0 | 54 | 1 | `6.48, 23.74, 4.03` | needs scale/orientation validation |
| `SilumanUlar` | 1 | 119 | 363 | 1 | `11.20, 23.09, 7.94` | best first non-humanoid bone-rich validation candidate |
| `SundelBolong` | 1 | 48 | 150 | 1 | `1.80, 0.99, 1.90` | needs Animation Editor validation |
| `Tuyul` | 1 | 0 | 168 | 1 | `6.95, 6.84, 2.10` | needs Animation Editor validation |
| `WeweGombel` | 1 | 0 | 168 | 1 | `4.69, 2.38, 7.02` | needs scale/orientation validation |

## Animation Alias Contract

| Source Clip Token | Runtime Key | Use |
|---|---|---|
| `Idle` | `GhostIdle` | idle/rest |
| `WalkPatrol` | `GhostRoam` | roaming/patrol |
| `HuntStride` | `GhostHunt` | hunting |
| `Manifest` | `GhostManifest` | manifestation |
| `Attack` | `GhostAttack` | attack |
| `Jumpscare` | `GhostJumpscare` | jumpscare |
| `Vanish` | `GhostCooldown` | cooldown/despawn/manifest end |

## Animation Upload Tracker

All source folders are under:

`C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\GHOST\ALL_GHOSTS_FINAL`

| Ghost | Idle | WalkPatrol | HuntStride | Manifest | Attack | Jumpscare | Vanish | Status |
|---|---|---|---|---|---|---|---|---|
| `Banaspati` | `Banaspati_Idle_INPLACE.fbx` | `Banaspati_WalkPatrol_INPLACE.fbx` | `Banaspati_HuntStride_INPLACE.fbx` | `Banaspati_Manifest_INPLACE.fbx` | `Banaspati_Attack_INPLACE.fbx` | `Banaspati_Jumpscare_INPLACE.fbx` | `Banaspati_Vanish_INPLACE.fbx` | pending AnimationIds |
| `Genderuwo` | `Genderuwo_Idle_RIG_BASE_FIX.fbx` | `Genderuwo_WalkPatrol_RIG_BASE_FIX.fbx` | `Genderuwo_HuntStride_RIG_BASE_FIX.fbx` | `Genderuwo_Manifest_RIG_BASE_FIX.fbx` | `Genderuwo_Attack_RIG_BASE_FIX.fbx` | `Genderuwo_Jumpscare_RIG_BASE_FIX.fbx` | `Genderuwo_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `HantuTanah` | `HantuTanah_Idle_RIG_BASE_FIX.fbx` | `HantuTanah_WalkPatrol_RIG_BASE_FIX.fbx` | `HantuTanah_HuntStride_RIG_BASE_FIX.fbx` | `HantuTanah_Manifest_RIG_BASE_FIX.fbx` | `HantuTanah_Attack_RIG_BASE_FIX.fbx` | `HantuTanah_Jumpscare_RIG_BASE_FIX.fbx` | `HantuTanah_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `Jerangkong` | `Jerangkong_Idle_RIG_BASE_FIX.fbx` | `Jerangkong_WalkPatrol_RIG_BASE_FIX.fbx` | `Jerangkong_HuntStride_RIG_BASE_FIX.fbx` | `Jerangkong_Manifest_RIG_BASE_FIX.fbx` | `Jerangkong_Attack_RIG_BASE_FIX.fbx` | `Jerangkong_Jumpscare_RIG_BASE_FIX.fbx` | `Jerangkong_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `Kuntilanak` | `Kuntilanak_Idle_RIG_BASE_FIX.fbx` | `Kuntilanak_WalkPatrol_RIG_BASE_FIX.fbx` | `Kuntilanak_HuntStride_RIG_BASE_FIX.fbx` | `Kuntilanak_Manifest_RIG_BASE_FIX.fbx` | `Kuntilanak_Attack_RIG_BASE_FIX.fbx` | `Kuntilanak_Jumpscare_RIG_BASE_FIX.fbx` | `Kuntilanak_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `Leak` | `Leak_Idle_RIG_BASE_FIX.fbx` | `Leak_WalkPatrol_RIG_BASE_FIX.fbx` | `Leak_HuntStride_RIG_BASE_FIX.fbx` | `Leak_Manifest_RIG_BASE_FIX.fbx` | `Leak_Attack_RIG_BASE_FIX.fbx` | `Leak_Jumpscare_RIG_BASE_FIX.fbx` | `Leak_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `Palasik` | `Palasik_Idle_RIG_BASE_FIX.fbx` | `Palasik_WalkPatrol_RIG_BASE_FIX.fbx` | `Palasik_HuntStride_RIG_BASE_FIX.fbx` | `Palasik_Manifest_RIG_BASE_FIX.fbx` | `Palasik_Attack_RIG_BASE_FIX.fbx` | `Palasik_Jumpscare_RIG_BASE_FIX.fbx` | `Palasik_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `Pocong` | `Pocong_Idle_RIG_BASE_FIX.fbx` | `Pocong_WalkPatrol_RIG_BASE_FIX.fbx` | `Pocong_HuntStride_RIG_BASE_FIX.fbx` | `Pocong_Manifest_RIG_BASE_FIX.fbx` | `Pocong_Attack_RIG_BASE_FIX.fbx` | `Pocong_Jumpscare_RIG_BASE_FIX.fbx` | `Pocong_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `SilumanUlar` | `SilumanUlar_Idle_RIG_BASE_FIX.fbx` | `SilumanUlar_WalkPatrol_RIG_BASE_FIX.fbx` | `SilumanUlar_HuntStride_RIG_BASE_FIX.fbx` | `SilumanUlar_Manifest_RIG_BASE_FIX.fbx` | `SilumanUlar_Attack_RIG_BASE_FIX.fbx` | `SilumanUlar_Jumpscare_RIG_BASE_FIX.fbx` | `SilumanUlar_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `SundelBolong` | `SundelBolong_Idle_RIG_BASE_FIX.fbx` | `SundelBolong_WalkPatrol_RIG_BASE_FIX.fbx` | `SundelBolong_HuntStride_RIG_BASE_FIX.fbx` | `SundelBolong_Manifest_RIG_BASE_FIX.fbx` | `SundelBolong_Attack_RIG_BASE_FIX.fbx` | `SundelBolong_Jumpscare_RIG_BASE_FIX.fbx` | `SundelBolong_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `Tuyul` | `Tuyul_Idle_RIG_BASE_FIX.fbx` | `Tuyul_WalkPatrol_RIG_BASE_FIX.fbx` | `Tuyul_HuntStride_RIG_BASE_FIX.fbx` | `Tuyul_Manifest_RIG_BASE_FIX.fbx` | `Tuyul_Attack_RIG_BASE_FIX.fbx` | `Tuyul_Jumpscare_RIG_BASE_FIX.fbx` | `Tuyul_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |
| `WeweGombel` | `WeweGombel_Idle_RIG_BASE_FIX.fbx` | `WeweGombel_WalkPatrol_RIG_BASE_FIX.fbx` | `WeweGombel_HuntStride_RIG_BASE_FIX.fbx` | `WeweGombel_Manifest_RIG_BASE_FIX.fbx` | `WeweGombel_Attack_RIG_BASE_FIX.fbx` | `WeweGombel_Jumpscare_RIG_BASE_FIX.fbx` | `WeweGombel_Vanish_RIG_BASE_FIX.fbx` | pending AnimationIds |

## Minimal Validation Slice

Before uploading all 84 animation assets:

1. Insert one base rig model from its asset ID into Workspace.
2. Use Animation Editor on that rig.
3. Import `Idle`, `WalkPatrol`, and `HuntStride` from `_generated_animations`.
4. Preview on the base rig.
5. Publish those three to `PASRAHPHOBIA DEVELOPER & TEAM`.
6. Record the resulting AnimationIds here or in a follow-up manifest.

Use `Kuntilanak` or `SilumanUlar` first because visual errors are easy to read.

## Human Blockers

- Browser/Studio login confirmation, 2FA, moderation warning dialogs, and publish confirmation dialogs may require human handling.
- If Studio refuses to publish animation to the team creator from the second account, verify group role permissions: `Use` is not enough for publishing/configuring assets; the account needs edit/create-configure permissions for development items.
