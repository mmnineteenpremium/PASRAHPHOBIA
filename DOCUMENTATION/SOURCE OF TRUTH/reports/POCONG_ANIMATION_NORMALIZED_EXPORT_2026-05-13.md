# Pocong Animation Normalized Export - 2026-05-13

Branch: `brian-second-final`  
Status: complete, non-destructive

## Reason

The cross-audit of 84 ghost animation FBX files found no bone/action/keyframe errors. The only warning was `object_scale_extreme` on all seven `Pocong` animation clips, matching the earlier base rig scale issue.

## Output

Seven normalized animation FBX files were exported without overwriting the original source files:

`C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-animation-rbxm\normalized-animation-fbx\Pocong`

Files:

- `Pocong_Attack_RIG_BASE_FIX_NORMALIZED.fbx`
- `Pocong_HuntStride_RIG_BASE_FIX_NORMALIZED.fbx`
- `Pocong_Idle_RIG_BASE_FIX_NORMALIZED.fbx`
- `Pocong_Jumpscare_RIG_BASE_FIX_NORMALIZED.fbx`
- `Pocong_Manifest_RIG_BASE_FIX_NORMALIZED.fbx`
- `Pocong_Vanish_RIG_BASE_FIX_NORMALIZED.fbx`
- `Pocong_WalkPatrol_RIG_BASE_FIX_NORMALIZED.fbx`

## Audit

Blender import-back audit confirms every normalized Pocong clip has:

- 16 bones
- armature scale `1,1,1`
- mesh scale `1,1,1`
- one action

Audit file:

`.codex/asset-imports/20260513-ghost-animation-rbxm/pocong-normalized-animation-audit.json`

## Plan Integration

`scripts/build-ghost-animation-upload-plan.ps1` now detects normalized animation overrides. Current plan state:

- 84 total animation plan items
- 77 use original generated animation FBX files
- 7 `Pocong` items use `normalized-animation-fbx`
- `scripts/audit-ghost-animation-sources.ps1` preflight result: `0 errors`, `0 warnings`

Animation upload remains blocked only by the expected conversion step from FBX to `.rbxm/.rbxmx`.
