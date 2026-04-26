# Visual Batch T120 Map-Mood Width Micro Trim XI 2026-04-26

## Scope

- Continue visual-only lane after T119.
- Improve RoomBrowser extra-compact map-preview mood-chip horizontal density.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Mood-chip width micro trim:
   - Extra-compact map-preview mood width reduced slightly (`113 -> 112`).
   - Reclaims horizontal space for map strip readability.

2. Behavior stability:
   - Existing truncation behavior remains unchanged.
   - Visual rhythm tightens without affecting data flow.

3. Scope guard:
   - visual-only changes; no room preview map data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates map-preview mood-chip readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
