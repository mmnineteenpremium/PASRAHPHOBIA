# Kuntilanak GhostIdle Animation Upload Smoke - 2026-05-13

Branch: `brian-second-final`  
Scope: one clip only, not bulk upload

## Result

`Kuntilanak.GhostIdle` completed the full conversion/upload/apply pipeline.

| Field | Value |
|---|---|
| Base rig asset ID | `111714179492317` |
| Source FBX | `Kuntilanak_Idle_RIG_BASE_FIX.fbx` |
| Normalized FBX used | `.codex/asset-imports/20260513-ghost-animation-rbxm/normalized-animation-fbx/Kuntilanak/Kuntilanak_Idle_RIG_BASE_FIX_NORMALIZED.fbx` |
| Converted file | `.codex/asset-imports/20260513-ghost-animation-rbxm/converted/Kuntilanak/Kuntilanak_GhostIdle.rbxmx` |
| Uploaded AnimationId | `110913223261685` |
| Source JSON written | `src/ReplicatedStorage/Assets/Animations/Ghosts/Kuntilanak/GhostIdle.model.json` |
| Runtime loop flag | `Looped=true` |

## Studio Validation

- Normalized base rig loaded from asset `111714179492317`.
- Studio audit before import: `HasSkinnedMesh=true`, 54 bones, Animator present.
- Raw animation FBX imported with correct deformation but scale/timeline issues.
- Normalized/trimmed FBX imported with correct target scale and smooth idle loop back to first pose.
- Saved from Animation Editor to `.rbxmx`.

## Upload Validation

- Smoke dry-run result: `dry_run_ready`.
- Open Cloud upload result: `uploaded`, asset ID `110913223261685`.
- `apply-ghost-animation-upload-results.ps1` wrote the per-ghost animation model JSON.
- Active Studio was mirrored with `ReplicatedStorage.Assets.Animations.Ghosts.Kuntilanak.GhostIdle`.
- Source JSON was rewritten as UTF-8 without BOM, and the apply wrapper now writes no-BOM JSON for future clips.
- Rojo validation passed after apply: `sourcemap` and `build default.project.json --output .codex/tmp/preflight-build-after-kuntilanak-idle.rbxlx`.

## Remaining Work

Bulk animation upload should now follow this proven lane:

1. Convert remaining FBX clips to `.rbxmx` through Animation Editor or an equivalent verified converter.
2. Reuse normalized animation FBX overrides when importer scale/timeline is wrong.
3. Run `scripts/upload-ghost-animation-rbxm-assets.ps1 -DryRun`.
4. Upload after every plan item is `dry_run_ready`.
5. Run `scripts/apply-ghost-animation-upload-results.ps1`.
