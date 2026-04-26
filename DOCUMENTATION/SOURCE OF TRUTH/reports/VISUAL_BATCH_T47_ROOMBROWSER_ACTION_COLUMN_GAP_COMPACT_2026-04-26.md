# Visual Batch T47 RoomBrowser Action Column Gap Compact 2026-04-26

## Scope

- Continue visual-only lane after T46.
- Improve RoomBrowser extra-compact action-lane paired-button horizontal rhythm.
- Keep mode selection and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Paired-button gap trim:
   - Added explicit extra-compact action-column gap for paired action buttons.
   - Tightens horizontal rhythm in short/narrow mobile lanes.

2. Width recompute consistency:
   - Paired button widths (`Refresh/Create`, `Quick Classic/Quick Ranked`) now derive from the same gap variable.
   - Keeps columns balanced while preserving readability.

3. Scope guard:
   - visual-only changes; no mode selection behavior, room flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates action-lane paired-button readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
