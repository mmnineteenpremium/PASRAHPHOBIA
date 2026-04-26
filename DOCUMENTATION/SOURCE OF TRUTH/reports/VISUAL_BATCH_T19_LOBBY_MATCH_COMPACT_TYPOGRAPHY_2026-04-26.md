# Visual Batch T19 Lobby Match Compact Typography 2026-04-26

## Scope

- Continue visual-only lane after T18.
- Improve compact mobile readability for `LobbyUI` and `MatchUI` basic panel typography.
- Keep runtime/system behavior unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Lobby compact typography:
   - In compact landscape/mobile lanes, lobby action button text sizing is reduced for better fit.
   - Lobby status badge text sizing is tuned for compact readability.

2. Match compact typography:
   - `BasicHideButton`, `BasicCloseButton`, and `BasicFooterLabel` text sizes are tuned in compact match lanes.
   - Keeps bottom action/footer area readable with less visual crowding.

3. Scope guard:
   - visual-only changes; no gameplay/runtime/economy logic changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates lobby/match compact readability on real mobile device lane.
- Owner executes manual 2-client smoke.
