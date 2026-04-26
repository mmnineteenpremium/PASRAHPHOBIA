# Visual Batch T40 RoomBrowser List Density Polish 2026-04-26

## Scope

- Continue visual-only lane after T39.
- Improve RoomBrowser room-list density for extra-compact mobile viewport behavior.
- Keep room select/join runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Room-list scrollbar density tuning:
   - `RoomList.ScrollBarThickness` now has an explicit extra-compact value.
   - Helps preserve horizontal room for list row content in short viewports.

2. Row spacing and silhouette polish:
   - `RoomListLayout.Padding` now tightens in extra-compact lane.
   - Row corner radius now trims slightly in extra-compact lane for a denser visual rhythm.

3. Scope guard:
   - visual-only changes; no room selection behavior, join flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates room-list density/readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
