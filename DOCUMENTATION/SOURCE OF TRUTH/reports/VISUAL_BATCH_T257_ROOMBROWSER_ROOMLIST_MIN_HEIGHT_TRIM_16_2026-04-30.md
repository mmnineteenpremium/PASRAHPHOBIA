# Visual Batch T257 RoomList Min Height Trim XVI 2026-04-30

## Scope

- Continue visual-only lane after the prior RoomBrowser micro-batch.
- Relax RoomBrowser extra-compact minimum room-list height slightly for lower-stack flexibility.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- src/client/UI/Main.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md

## Change Summary

1. Room-list min-height trim:
   - Extra-compact visual value adjusted slightly (145 -> 144).
   - Increases lower-layout flexibility while preserving room-list readability.

2. Behavior stability:
   - Visual density improves without changing room preview data flow.
   - Existing text hierarchy and interaction semantics remain intact.

3. Scope guard:
   - visual-only changes; no room preview map data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- Full `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''` is executed after final T258 state.
- Expected manual blocker remains:
  - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates room-list scan comfort after the lower minimum-height trim.
- Owner executes manual 2-client smoke.
