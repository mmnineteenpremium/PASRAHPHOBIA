# Visual Batch T35 RoomBrowser Preview Player Card Compact 2026-04-26

## Scope

- Continue visual-only lane after T34.
- Improve RoomBrowser `Room Preview` player card readability in compact and extra-compact lanes.
- Keep room preview/player data runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Preview player card density:
   - Added compact layout constants for card height, avatar preview size, text start offset, and text block bounds.
   - Applied tighter dimensions in extra-compact lane to prevent visual crowding.

2. Extra-compact text behavior:
   - Enabled truncation on player name and state labels in extra-compact lane.
   - Kept normal wrapping behavior on non-extra-compact lanes.

3. Preview player grid spacing:
   - Added compact-aware `CellPadding` tuning for `RoomPreviewPlayersLayout` in compact branches.
   - Maintains readable separation while avoiding excessive vertical waste on short viewports.

4. Scope guard:
   - visual-only changes; no room preview logic, player readiness state logic, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates preview player card readability in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
