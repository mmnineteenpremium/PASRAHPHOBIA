# Visual Batch T7 Hidden Gems Daily Lane 2026-04-26

## Scope

- Continue visual-only lane after T6.
- Improve daily-lane clarity for `DailyRewardZone` and related buttons/copy.
- Improve hidden gems cap presentation (`maks 3 PP coin per hari`) using existing runtime snapshot data only.
- No new gameplay/economy/system architecture introduced.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Hidden gems visual helpers (snapshot-only):
   - added parsing helper from `ppBreakdown` entries to read hidden gems progress when available.
   - fallback remains static cap messaging when no hidden gems entry is present.

2. Results + summary readability:
   - results footer now includes compact hidden gems progress lane (`Hidden x/3`) alongside RP XP and daily progress.
   - `PASRA_UI` now renders hidden gems line from snapshot parser instead of static text.

3. Shop wallet and cap micro-state:
   - `ShopUI` secondary text now includes compact hidden gems state.
   - all filter footer variants now append unified hidden gems cap/progress messaging.

4. DailyReward lobby alignment:
   - `DailyRewardZone` title/hint/subtitle updated to explicit daily check-in/spin context.
   - lobby royal pass button text/tone now follows daily context when focus is on `DailyRewardZone`.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Final visual pass for remaining canonical panels outside the updated lanes.
- Owner executes manual 2-client smoke.
