# Visual Batch T121 Map-Title Width Reclaim IX 2026-04-26

## Scope

- Continue visual-only lane after T120.
- Improve RoomBrowser map-preview title horizontal headroom in compact/extra-compact lanes.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Map-title width reclaim micro trim:
   - Map-preview title horizontal bounds expanded slightly (`previewWidth - 36 -> previewWidth - 34`).
   - Improves title headroom while keeping existing visual hierarchy.

2. Behavior stability:
   - Title text sizing remains unchanged.
   - Visual-only adjustment; no interaction or data-path changes.

3. Scope guard:
   - visual-only changes; no room preview map data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates map-title clipping/readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
