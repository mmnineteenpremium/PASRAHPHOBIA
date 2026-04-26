# Visual Batch T23 Results HUD Compact Mobile 2026-04-26

## Scope

- Continue visual-only lane after T22.
- Improve compact mobile readability for results/HUD lane (`Results`, `Timer`, `Evidence Quick`, `Hint Bar`).
- Keep gameplay/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Compact mobile HUD profile:
   - Added `compactMobileHud` sizing lane for short-height mobile viewports.

2. Results typography tuning:
   - `ResultsTitle/Status/Subtitle/Footer` text sizing reduced in compact lane to reduce overflow risk.

3. Timer + quick actions tuning:
   - `TimerLabel` and `TimerCaption` size/text tuned for compact lane.
   - `EvidenceQuickButton` size/text and `ControlsHintBar`/`ControlsHintLabel` compacted for better lower-screen balance.

4. Scope guard:
   - visual-only changes; no progression/economy/gameplay/runtime logic changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates results/HUD readability on short-height mobile lane.
- Owner executes manual 2-client smoke.
