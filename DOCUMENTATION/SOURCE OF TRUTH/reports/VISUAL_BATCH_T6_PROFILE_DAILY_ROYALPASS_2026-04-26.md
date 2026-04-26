# Visual Batch T6 Profile Daily RoyalPass 2026-04-26

## Scope

- Continue visual-only lane after T5.
- Keep runtime/system architecture unchanged.
- Tighten visual hierarchy and naming consistency for canonical Profile + RoyalPass lanes.
- Ensure wording alignment for daily loops (`Daily Quest`, `Daily Check-In`, `Daily Spin`) and inventory/gacha context.

## Reference Source

- `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\asset-ui-ux-gui\acuan-visual-ui-ux-gui-pasrahphobia-ui.html`
- `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\pasrahphobia-ui.html`

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Visual wording normalization:
   - thermometer labels switched to `SUHU ARC` and `SUHU NULL`.
   - lobby daily feedback wording switched from `Daily reward` to `Daily check-in`.

2. New daily button tone:
   - added `BUTTON_TONES.daily` for clear daily-lane CTA contrast.

3. Profile panel canonical hierarchy:
   - `ProfileUI` now shows snapshot-only visual states for:
     - Rank/EXP context
     - Daily Quest
     - Daily Check-In day
     - Daily Spin state
     - Gacha/inventory state
   - added explicit PP cap messaging in profile visual lane: `PP cap 3/hari`.
   - updated profile footer text to state canonical visual tracker scope.

4. RoyalPass panel daily alignment:
   - tab labels changed to:
     - `DAILY CHECK-IN`
     - `DAILY QUEST`
   - hero/rows/track hint/card labels aligned to daily wording.
   - row tone for daily check-in uses daily tone lane.
   - all updates remain snapshot rendering only, without introducing new progression logic.

5. Maintainability cleanup:
   - fixed indentation drift inside `BUTTON_TONES` and `_refreshRoyalPassPanel` blocks to reduce future merge drift.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Continue final visual pass for remaining canonical panels not yet fully polished against HTML references.
- Owner executes manual 2-client smoke in real device lane.
