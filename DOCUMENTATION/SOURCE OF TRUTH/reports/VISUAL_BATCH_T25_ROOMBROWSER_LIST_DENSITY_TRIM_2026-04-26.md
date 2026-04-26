# Visual Batch T25 RoomBrowser List Density Trim 2026-04-26

## Scope

- Continue visual-only lane after T24.
- Improve RoomBrowser extra-compact list readability and top tab density.
- Keep room browser/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Extra-compact tab strip tuning:
   - RoomBrowser mode tab height and gap reduced in extra-compact lane to free vertical space.

2. Room list extra-compact readability:
   - Room row wrapping disabled in extra-compact lane and truncation enabled (`AtEnd`) to prevent multi-line crowding.
   - Added row horizontal padding for cleaner scan rhythm.

3. Scope guard:
   - visual-only changes; no room browser logic, matchmaking logic, or runtime flow changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates RoomBrowser row readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
