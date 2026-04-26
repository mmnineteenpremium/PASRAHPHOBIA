# Visual Batch T39 RoomBrowser Room List Row Compact 2026-04-26

## Scope

- Continue visual-only lane after T38.
- Improve RoomBrowser room-list row readability in compact and extra-compact lanes.
- Keep room select/join runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Room-list row density tuning:
   - Added per-row `UIPadding` with compact/extra-compact-aware values.
   - Reduced edge crowding so room information is easier to scan.

2. Compact multiline readability:
   - Tuned row text vertical alignment to `Top` in compact/wide multiline lanes.
   - Keeps host/status lines visually stable in taller rows.

3. Scope guard:
   - visual-only changes; no room selection behavior, join flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates room-list row readability in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
