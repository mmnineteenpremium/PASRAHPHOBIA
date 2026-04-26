# Visual Batch T31 RoomBrowser Inline Kick Password Row Compact 2026-04-26

## Scope

- Continue visual-only lane after T30.
- Improve compact/extra-compact readability for RoomBrowser inline host-control rows (`SetPassword` + `Kick`).
- Keep host-control runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Inline host-control compaction:
   - Added compact constants for right action width, inline field offset, and inline field height in `_applyRoomBrowserSizing`.
   - Applied those constants to compact layout rows for `SetPassword` and `Kick` (wide-mobile and single-column compact lanes).

2. Extra-compact readability polish:
   - Shortened placeholder copy for `SetPasswordBox` and `KickNameBox` in extra-compact lane.
   - Kept typography hierarchy intact while reducing crowding risk.

3. Scope guard:
   - visual-only changes; no password submit, kick action, host-control authority, or runtime behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates inline host-control readability (`SetPassword` + `Kick`) in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
