# Visual Batch T26 RoomBrowser Invite List Extra Compact 2026-04-26

## Scope

- Continue visual-only lane after T25.
- Improve RoomBrowser `InviteDropdown` readability in extra-compact mobile lane.
- Keep room browser/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Invite list compact lane:
   - Added explicit `extraCompactRoomBrowser` handling in invite list rebuild flow.
   - Invite rows and broadcast row now use smaller height/text in extra-compact lane.

2. Invite list scan/readability:
   - Truncation enabled for invite rows in extra-compact lane to prevent horizontal spill.
   - Invite list scrollbar and row spacing compacted for short-height viewports.

3. Scope guard:
   - visual-only changes; no invite/matchmaking/runtime behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates invite dropdown readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
