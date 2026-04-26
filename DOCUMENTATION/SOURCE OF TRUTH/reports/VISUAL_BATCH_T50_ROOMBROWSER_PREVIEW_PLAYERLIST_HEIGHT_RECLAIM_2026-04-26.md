# Visual Batch T50 RoomBrowser Preview PlayerList Height Reclaim 2026-04-26

## Scope

- Continue visual-only lane after T49.
- Improve RoomBrowser extra-compact player-list viewport usage in the preview column.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Top-gap continuation trim:
   - Extra-compact preview players-list top gap reduced slightly again.
   - Tightens section rhythm below map preview.

2. Bottom inset trim:
   - Extra-compact preview players-list bottom inset reduced slightly.
   - Reclaims a small amount of visible list height.

3. Scope guard:
   - visual-only changes; no room preview data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates preview player-list readability and density in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
