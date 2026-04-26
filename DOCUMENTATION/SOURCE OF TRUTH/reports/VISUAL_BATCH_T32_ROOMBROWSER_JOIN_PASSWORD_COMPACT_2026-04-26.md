# Visual Batch T32 RoomBrowser Join Password Compact 2026-04-26

## Scope

- Continue visual-only lane after T31.
- Improve RoomBrowser `JoinPassword` readability and spacing in compact and extra-compact viewports.
- Keep join-room/password runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Join-password compact sizing:
   - Tuned `JoinPassword` field height in compact layout branches (wide compact, single-column compact, and compact desktop lane).
   - Height now better matches the tightened action stack rhythm in short-height viewports.

2. Extra-compact text clarity:
   - Added extra-compact placeholder shortening for `JoinPassword` (`PWD Join (4 digit)`).
   - Prevents placeholder crowding without changing interaction behavior.

3. Scope guard:
   - visual-only changes; no room join flow, password validation, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates `JoinPassword` readability in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
