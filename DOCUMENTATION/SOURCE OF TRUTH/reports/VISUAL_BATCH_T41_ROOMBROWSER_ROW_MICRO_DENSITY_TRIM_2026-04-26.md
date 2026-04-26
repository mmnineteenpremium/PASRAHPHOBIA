# Visual Batch T41 RoomBrowser Row Micro Density Trim 2026-04-26

## Scope

- Continue visual-only lane after T40.
- Improve RoomBrowser room-list row density for extra-compact mobile viewport behavior.
- Keep room select/join runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Row height trim:
   - Extra-compact room-list row height reduced slightly.
   - Preserves list readability while showing more rooms per viewport.

2. Row padding trim:
   - Extra-compact row padding `top/bottom/right` reduced slightly.
   - Tightens visual rhythm for faster room scanning.

3. Scope guard:
   - visual-only changes; no room selection behavior, join flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates room-list row readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
