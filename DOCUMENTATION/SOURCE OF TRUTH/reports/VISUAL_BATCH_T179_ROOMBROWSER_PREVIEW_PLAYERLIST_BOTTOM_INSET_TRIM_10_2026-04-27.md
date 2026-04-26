# Visual Batch T179 Preview Playerlist Bottom Inset Trim X 2026-04-27

## Scope

- Continue visual-only lane after the prior RoomBrowser micro-batch.
- Reclaim extra-compact player-list bottom space inside RoomBrowser preview.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- src/client/UI/Main.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md

## Change Summary

1. Player-list bottom-inset trim:
   - Extra-compact visual value adjusted slightly (36 -> 35).
   - Adds a touch more room for player cards without changing section hierarchy.

2. Behavior stability:
   - Visual density improves without changing room preview data flow.
   - Existing text hierarchy and interaction semantics remain intact.

3. Scope guard:
   - visual-only changes; no room preview map data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- Batch generated inside deferred-final-preflight continuation run.
- Full `scripts/release-preflight.ps1 -Json` is executed once after final T200 state.
- Expected manual blocker remains:
  - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates player-card clearance near the lower panel edge in extra-compact mobile lane.
- Owner executes manual 2-client smoke.