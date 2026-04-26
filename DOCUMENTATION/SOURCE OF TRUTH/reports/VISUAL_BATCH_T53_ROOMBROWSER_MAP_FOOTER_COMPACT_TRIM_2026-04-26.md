# Visual Batch T53 RoomBrowser Map Footer Compact Trim 2026-04-26

## Scope

- Continue visual-only lane after T52.
- Improve RoomBrowser extra-compact map-preview footer vertical compactness.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Map footer bounds trim:
   - Extra-compact map-preview footer height reduced slightly (`40 -> 38`).
   - Reduces vertical pressure in the preview block.

2. Typography stability:
   - Footer text size and truncation behavior unchanged.
   - Keeps readability while tightening section rhythm.

3. Scope guard:
   - visual-only changes; no room preview map data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates map-preview footer readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
