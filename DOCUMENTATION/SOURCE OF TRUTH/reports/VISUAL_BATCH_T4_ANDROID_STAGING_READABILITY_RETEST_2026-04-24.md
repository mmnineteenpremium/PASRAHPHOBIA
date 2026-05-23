# Visual Batch T4 Android Staging Readability Retest 2026-04-24

## Scope

- Continue Android-only fix lane for `PANEL MATCH` readability issue at `STAGING`.
- Re-run publish + runtime retest after UI patch iterations.
- Capture updated Android visual evidence for final status of overlap issue.

## Runtime Environment

- Date: 2026-04-24 (Asia/Bangkok)
- Branch lane: `final-source-of-truth`
- Device:
  - Alias: `Samsung-N960`
  - Device ID: `266a038c0a017ece`
  - Model: `SM-N960U`
- Publish target:
  - `placeId=113010869463813`
  - `universeId=9802743087`

## Code Changes Applied (T4)

- `src/client/UI/Main.lua`
  - Added duplicate-child cleanup helper in `_ensureBasicUIs()` and dedupe cleanup for match/lobby header label names.
  - Switched several header label lookups to recursive `FindFirstChild(..., true)` to avoid re-creation when labels already moved into `HeaderCard`.
  - Disabled legacy `match.MessageLabel` usage for `Preparation` transition.
  - Disabled `match.ObjectiveLabel` display in `Preparation/Loading` path (legacy overlay surface).
  - Additional mobile readability attempts:
    - single-line enforcement (`TextWrapped=false`) for match header labels,
    - smaller mobile header text sizes,
    - temporary hide of header body text on mobile `Preparation/Loading` for isolation.

## Publish + Retest Execution

1. Build gate:
   - `scripts/release-preflight.ps1 -Json`
   - Result: `buildOk=true` for each retest round.
2. Open Cloud upload:
   - `scripts/Invoke-Rojo.ps1 upload --api_key ... --asset_id 113010869463813 --universe_id 9802743087 default.project.json`
   - Retries eventually succeeded (`exit code 0`), including final round with first-attempt success.
3. Android runtime flow (repeated rounds):
   - force-stop + deep-link start via adb:
     - `adb -s 266a038c0a017ece shell am start -a android.intent.action.VIEW -d "roblox://placeID=113010869463813" com.roblox.client`
   - flow sequence:
     - `OPEN ROOM BROWSER` -> select room -> `BUAT ROOM` -> `MULAI PERMAINAN` -> reach `STAGING`.

## Visual Evidence

- `.codex/evidence/mobile-smoke-2026-04-24/android_n960_lobby_retest_t4.png`
- `.codex/evidence/mobile-smoke-2026-04-24/android_n960_staging_overlap_retest_t4.png`
- `.codex/evidence/mobile-smoke-2026-04-24/android_n960_staging_overlap_resolved_t4c.png`

## Observations

- Android lobby remains reachable and room/start flow to `STAGING` remains operational.
- Earlier patch rounds in this session still reproduced body-text overlap/double-render at `STAGING`.
- Final Android-only mitigation switched touch runtime to suppress all `PANEL MATCH` header body labels (`PrimaryLabel` / `SecondaryLabel`) and force-hide any duplicate touch match header text surfaces at refresh time.
- After final publish + relaunch + rejoin retest, `PANEL MATCH` at `STAGING` no longer shows the duplicated body text on Android.
- Resulting Android presentation keeps the phase badge (`STAGING`) and summary rows visible while removing the problematic overlapping body copy on touch devices.

## Status

- Android runtime reachability: `PASS`
- Android room flow to `STAGING`: `PASS`
- Android `PANEL MATCH` readability at `STAGING`: `PASS (resolved via touch-only header body suppression)`
- Residual note: desktop/non-touch layout was not revalidated in this report; resolution in this lane is scoped to Android-only as requested.
