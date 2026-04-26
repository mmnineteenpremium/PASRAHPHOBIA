# Visual Batch T43 RoomBrowser Status Header Compact Trim 2026-04-26

## Scope

- Continue visual-only lane after T42.
- Improve RoomBrowser status-header readability behavior for extra-compact mobile viewports.
- Keep room select/join runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Status line compact sizing:
   - Extra-compact status header height reduced slightly.
   - Extra-compact status text size reduced slightly to preserve top-header rhythm.

2. Overflow guard:
   - Extra-compact status line now uses truncation behavior for long messages.
   - Prevents visual overflow in narrow mobile widths.

3. Scope guard:
   - visual-only changes; no room selection behavior, join flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates status-header readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
