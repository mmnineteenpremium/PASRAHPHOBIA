# Brian Second Final Cleanup Audit - 2026-05-19

Scope: `brian-second-final` worktree only. This is a pre-delete audit; do not hard delete from this list until the current Studio/runtime path is saved and the owner approves the cleanup batch.

## Keep As Runtime/Source Owner

- `PASRAHPHOBIA.rbxlx` - active Studio place.
- `src/` - current Rojo/source runtime tree.
- `DOCUMENTATION/SOURCE OF TRUTH/` - canonical docs and task history.
- `scripts/` - project wrappers and upload/audit helpers.
- `Packages/` and `.aftman/` - tooling dependencies.

## High-Confidence Cleanup Candidates

These are likely build artifacts, evidence dumps, or temporary outputs, not runtime owners:

- Root `_tmp_*.rbxlx` files: `_tmp_release_preflight_build.rbxlx`, `_tmp_saveback_verify_build.rbxlx`, `_tmp_publish_pc_smoke_check.rbxlx`, `_tmp_check.rbxlx`, `_tmp_staging_smoke_build.rbxlx`, `_tmp_restore_probe.rbxlx`, `_tmp_pasrah_build.rbxlx`, `_tmp_preflight_build.rbxlx`.
- Root generated copies: `PASRAHPHOBIA.syncback-sanitized.rbxlx`, `PASRAHPHOBIA.rojo.rbxlx`, `PASRAHPHOBIA_lobby_backup.rbxl`.
- Loading sprite raw extraction: `ezgif-1f207771deb23970-png-split/` and `ezgif-1f207771deb23970-png-split.zip`.
- One-off local screenshots/videos: `studio_full_screenshot*.png`, `Glitch-RoomBrowserUI.mp4`, `Roblox-2026-05-01T20_10_*.mp4`, `duprojo.png`, `rojostudio.png`.

## Requires Manual Review Before Delete

- `.codex/` is about 23.5 GB and contains mixed evidence, imports, previous test captures, and possible asset conversion outputs. Do not wipe the whole folder blindly.
- `src/**.model.json.disabled` duplicate map exports exist in `ServerStorage`, `ReplicatedStorage`, and `Workspace`; they are probably disabled archive copies, but deleting them should wait until map source ownership is confirmed.
- `artifacts/` contains test evidence. Safe to archive later, but not needed for runtime.

## Current Finding

The code path for house lights is already present: `EnvironmentalObjectRuntime` creates `LightSwitchPrompt`, and `HauntedHouseRuntimeLayout` defines `Light_*` objects. The fix should focus on wiring/UX access from the normal door flow, not creating a second light system.

