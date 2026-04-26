# Visual Batch T14 MainMenu Mobile Stack Density 2026-04-26

## Scope

- Continue visual-only lane after T13.
- Improve `MainMenuUI` mobile stack spacing and text readability.
- Keep systems/runtime behavior unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Compact mobile stack rhythm:
   - Added compact profile for small-height main menu mobile panel.
   - Row gap, button height, and footer spacing rebalanced for tighter but readable stacking.

2. Main menu action button readability:
   - Dedicated text-size tuning for `MainMenuUI` action buttons on mobile compact lane.
   - Per-button text sizing aligned for Room/Profile/Shop/Rank/Graphics actions.

3. Scope guard:
   - No system/feature/runtime logic changes.
   - Visual presentation only.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates compact main menu readability on real mobile device lane.
- Owner executes manual 2-client smoke.
