# Visual Batch T33 RoomBrowser Action Stack Compact 2026-04-26

## Scope

- Continue visual-only lane after T32.
- Improve compact and extra-compact readability for RoomBrowser bottom action stack.
- Keep matchmaking and room-action runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Compact action stack rhythm:
   - Added compact variables for queue/button heights and row spacing in compact single-column lane.
   - Applied tighter spacing/heights for extra-compact while keeping default compact rhythm intact.

2. Wide-compact action stack trim:
   - Added extra-compact-aware action row height, join row height, and row gap in wide-compact lane.
   - Keeps action block fitting in short-height viewport without clipping.

3. Typography tuning:
   - Reduced extra-compact text size for queue/quick/refresh/create buttons to maintain label clarity in tighter bounds.

4. Scope guard:
   - visual-only changes; no room action behavior, matchmaking flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates action-stack readability on compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
