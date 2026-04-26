# Visual Batch T44 RoomBrowser Tab Strip Vertical Compact 2026-04-26

## Scope

- Continue visual-only lane after T43.
- Improve RoomBrowser extra-compact tab-strip spacing and vertical rhythm.
- Keep mode selection and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Tab-strip vertical placement:
   - Extra-compact tab control row moved slightly upward.
   - Improves breathing room for content below in short viewports.

2. Tab horizontal gap trim:
   - Extra-compact tab gap reduced slightly.
   - Keeps mode controls visually compact while preserving readability.

3. Scope guard:
   - visual-only changes; no mode selection behavior, room flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates tab-strip readability and spacing in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
