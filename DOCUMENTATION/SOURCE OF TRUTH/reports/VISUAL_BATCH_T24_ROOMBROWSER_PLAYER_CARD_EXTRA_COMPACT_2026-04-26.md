# Visual Batch T24 RoomBrowser Player Card Extra Compact 2026-04-26

## Scope

- Continue visual-only lane after T23.
- Improve RoomBrowser player-card readability in extra-compact mobile lane.
- Keep room browser/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Player-card extra-compact lane:
   - Added `extraCompactPreview` behavior for room preview player cards.
   - Card height and preview viewport size tuned to fit short-height mobile layout.

2. Player-card typography compacting:
   - Name/state labels now use smaller text in extra-compact lane to reduce clipping risk.

3. Scope guard:
   - visual-only changes; no room browser logic, matchmaking logic, or runtime flow changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates room-preview player-card readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
