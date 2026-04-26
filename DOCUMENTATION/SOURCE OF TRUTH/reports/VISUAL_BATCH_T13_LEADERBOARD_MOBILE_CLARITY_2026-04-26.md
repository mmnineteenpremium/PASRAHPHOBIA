# Visual Batch T13 Leaderboard Mobile Clarity 2026-04-26

## Scope

- Continue visual-only lane after T12.
- Improve `LeaderboardUI` mobile readability and spacing stability.
- Keep runtime and gameplay/economy systems unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Mobile typography alignment for leaderboard panel:
   - `PrimaryLabel`, `SecondaryLabel`, and `FooterLabel` text sizing tuned specifically for `LeaderboardUI` on mobile.

2. Mobile content/footer spacing stability:
   - `LeaderboardUI` content frame height and top offset adjusted to reduce crowding.
   - action row (bottom buttons) shifted upward with slightly slimmer button height.
   - footer area enlarged and moved upward for clearer multi-line snapshot copy.

3. Scope guard:
   - no new systems, no gameplay logic changes, no economy/progression logic changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates final leaderboard readability on real mobile device lane.
- Owner executes manual 2-client smoke.
