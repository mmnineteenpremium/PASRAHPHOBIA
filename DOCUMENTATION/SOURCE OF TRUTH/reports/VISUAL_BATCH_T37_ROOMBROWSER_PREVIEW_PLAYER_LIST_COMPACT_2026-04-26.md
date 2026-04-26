# Visual Batch T37 RoomBrowser Preview Player List Compact 2026-04-26

## Scope

- Continue visual-only lane after T36.
- Improve RoomBrowser `Room Preview` player list readability and density in compact and extra-compact lanes.
- Keep room preview/player runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Player list density tuning:
   - Tuned `RoomPreviewPlayersList` scrollbar thickness per compact lane.
   - Added compact-aware `UIPadding` adjustment for top/bottom/left/right list insets.

2. Player list header tuning:
   - Tuned `RoomPreviewPlayersTitle` text size for extra-compact readability.
   - Added extra-compact truncation behavior so list header stays concise on short viewports.

3. Scope guard:
   - visual-only changes; no room preview data logic, player-state flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates player-list readability on compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
