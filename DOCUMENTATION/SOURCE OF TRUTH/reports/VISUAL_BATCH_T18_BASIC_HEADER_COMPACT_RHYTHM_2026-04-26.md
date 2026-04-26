# Visual Batch T18 Basic Header Compact Rhythm 2026-04-26

## Scope

- Continue visual-only lane after T17.
- Improve compact mobile header rhythm for `MainMenuUI` and `LeaderboardUI` basic panels.
- Keep runtime and system logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Basic panel compact header profile:
   - Added compact header threshold for mobile basic windows (`MainMenuUI`/`LeaderboardUI`).
   - `Title`, `CloseButton`, and `StatusBadge` size/text are reduced in compact height lanes for cleaner top-bar rhythm.

2. Action button text tuning:
   - `LeaderboardUI` mobile action buttons now have dedicated compact text sizing (in addition to previous MainMenu lane tuning).

3. Scope guard:
   - visual-only presentation changes; no gameplay/runtime/economy logic changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates compact header readability on real device lane.
- Owner executes manual 2-client smoke.
