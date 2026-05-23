# Visual Batch T266 Preview Map Max Height Trim XIX 2026-04-30

## Scope

- Continue visual-only lane after the prior RoomBrowser micro-batch.
- Tighten RoomBrowser extra-compact map-preview height to release a little more lower-panel space.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- src/client/UI/Main.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md

## Change Summary

1. Map-preview max-height trim:
   - Extra-compact visual value adjusted slightly (130 -> 129).
   - Preserves map focus while freeing a small amount of vertical room for lower content.

2. Behavior stability:
   - Visual density improves without changing room preview data flow.
   - Existing text hierarchy and interaction semantics remain intact.

3. Scope guard:
   - visual-only changes; no room preview map data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- Full `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''` is executed after final T268 state.
- Expected manual blocker remains:
  - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates extra-compact map-preview hierarchy after the new max-height trim.
- Owner executes manual 2-client smoke.
