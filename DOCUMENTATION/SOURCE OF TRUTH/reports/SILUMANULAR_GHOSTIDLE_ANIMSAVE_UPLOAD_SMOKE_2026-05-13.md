# SilumanUlar GhostIdle AnimSave Upload Smoke - 2026-05-13

Branch: `brian-second-final`  
Scope: one extracted saved clip only, not bulk upload

## Result

`SilumanUlar.GhostIdle` completed the extract/upload/apply pipeline.

| Field | Value |
|---|---|
| Base rig asset ID | `87361945667344` |
| Saved clip source | `PASRAHPHOBIA.rbxlx` / `ServerStorage.RBX_ANIMSAVES.SilumanUlar_BASE-RIG-FIX.SilumanUlar_Idle_RIG_BASE_FIX_Scene` |
| Extracted file | `.codex/asset-imports/20260513-ghost-animation-rbxm/extracted-animsaves/SilumanUlar_Idle_RIG_BASE_FIX_Scene.rbxmx` |
| Converted upload file | `.codex/asset-imports/20260513-ghost-animation-rbxm/converted/SilumanUlar/SilumanUlar_GhostIdle.rbxmx` |
| Uploaded AnimationId | `96845915731729` |
| Source JSON written | `src/ReplicatedStorage/Assets/Animations/Ghosts/SilumanUlar/GhostIdle.model.json` |
| Runtime loop flag | `Looped=true` |

## Validation

- Extractor found the saved `KeyframeSequence` in the saved `.rbxlx` and wrote valid `.rbxmx`.
- Extracted clip metadata: 80 keyframes, time range `0` to `3.29166675`.
- Upload dry run result: `dry_run_ready`.
- Open Cloud upload result: `uploaded`, asset ID `96845915731729`, moderation `Approved`.
- Active Studio was mirrored with `ReplicatedStorage.Assets.Animations.Ghosts.SilumanUlar.GhostIdle`.
- Studio verification sees `AnimationId=rbxassetid://96845915731729` and `Looped=true`.
- Rojo validation passed after apply: `sourcemap` and `build default.project.json --output .codex/tmp/preflight-build-after-siluman-idle.rbxlx`.

## Remaining Work

- Only `Kuntilanak.GhostIdle` and `SilumanUlar.GhostIdle` are fully uploaded/applied.
- Current upload dry-run state: 2 ready, 82 missing converted `.rbxmx` files.
- Continue by producing the remaining `.rbxmx` conversions, then upload/apply in bounded batches.
