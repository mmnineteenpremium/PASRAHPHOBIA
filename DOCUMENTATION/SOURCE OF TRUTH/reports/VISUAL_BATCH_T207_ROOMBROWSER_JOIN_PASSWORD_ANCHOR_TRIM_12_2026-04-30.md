# Visual Batch T207 Join Password Anchor Trim XII 2026-04-30

## Scope

- Continue visual-only lane after the prior RoomBrowser micro-batch.
- Tighten the extra-compact join-password field anchoring above RoomBrowser actions.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- src/client/UI/Main.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md

## Change Summary

1. Join-password anchor trim:
   - Extra-compact visual value adjusted slightly (40 -> 39).
   - Compacts the lower action stack while preserving touch ergonomics.

2. Behavior stability:
   - Visual density improves without changing room preview data flow.
   - Existing text hierarchy and interaction semantics remain intact.

3. Scope guard:
   - visual-only changes; no room preview map data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- Full `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''` is executed after final T208 state.
- Expected manual blocker remains:
  - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates join-password field spacing above the action stack in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
