# Visual Batch T230 Map-Title Width Reclaim XXI 2026-04-30

## Scope

- Continue visual-only lane after the prior RoomBrowser micro-batch.
- Improve RoomBrowser extra-compact map-preview title horizontal headroom.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- src/client/UI/Main.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md

## Change Summary

1. Title width reclaim:
   - Extra-compact visual value adjusted slightly (previewWidth - 12 -> previewWidth - 10).
   - Reclaims horizontal room for map-title readability.

2. Behavior stability:
   - Visual density improves without changing room preview data flow.
   - Existing text hierarchy and interaction semantics remain intact.

3. Scope guard:
   - visual-only changes; no room preview map data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- Full `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''` is executed after final T233 state.
- Expected manual blocker remains:
  - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates map-preview title readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
