# Visual Batch T20 RoomBrowser Extra Compact Mobile 2026-04-26

## Scope

- Continue visual-only lane after T19.
- Improve RoomBrowser readability for extra-short mobile viewport lane.
- Keep runtime/system logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Extra-compact RoomBrowser profile:
   - Added `roomBrowserExtraCompact` lane for mobile non-wide panels with short height.
   - Header controls (`title/status/close`) tuned down for cleaner top area.

2. Tab/action typography compacting:
   - Mode tabs and action controls (join/queue/refresh/create/quick buttons) receive compact text sizing in extra-compact lane.

3. Room list density tuning:
   - Room row height and text-size reduced in extra-compact lane.
   - Row wrapping behavior stays enabled to preserve state readability.

4. Scope guard:
   - visual-only changes; no room browser logic, matchmaking logic, or runtime flow changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates RoomBrowser extra-compact readability on real mobile lane.
- Owner executes manual 2-client smoke.
