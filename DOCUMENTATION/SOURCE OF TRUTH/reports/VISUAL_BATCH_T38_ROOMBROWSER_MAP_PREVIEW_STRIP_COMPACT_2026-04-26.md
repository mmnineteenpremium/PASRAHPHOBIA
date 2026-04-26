# Visual Batch T38 RoomBrowser Map Preview Strip Compact 2026-04-26

## Scope

- Continue visual-only lane after T37.
- Improve RoomBrowser map preview strip readability (`Mood`, `Stats`, `Footer`) in compact and extra-compact lanes.
- Keep map preview runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Compact strip bounds:
   - Tuned mood chip width in compact branches for extra-compact viewport constraints.
   - Tuned footer height and typography in compact branches to reduce crowding.

2. Extra-compact truncation:
   - Added truncation behavior for preview strip labels (`Mood`, `Stats`, `Footer`) in extra-compact lane.
   - Applied same truncation behavior to image-strip equivalents (`MoodChip`, `Stats`, `Footer`).

3. Scope guard:
   - visual-only changes; no map preview data logic, room state logic, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates map preview strip readability in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
