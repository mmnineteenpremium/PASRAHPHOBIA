# Visual Batch T28 RoomBrowser Password Modal Compact 2026-04-26

## Scope

- Continue visual-only lane after T27.
- Improve RoomBrowser `PasswordModal` readability for compact and extra-compact mobile viewports.
- Keep join/password/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Password modal compact lanes:
   - Added explicit `compact` and `extra-compact` viewport profiles for `PasswordCard`.
   - Card dimensions now adapt without changing modal behavior.

2. Password modal hierarchy/readability:
   - Tuned title/input/button sizing and spacing for short-height viewports.
   - Tuned button row rhythm (`JOIN ROOM`, `BATAL`) so controls remain legible and balanced in tighter layouts.

3. Scope guard:
   - visual-only changes; no room join flow, password validation, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates `PasswordModal` readability in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
