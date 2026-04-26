# Visual Batch T16 Spectator Mobile Stability 2026-04-26

## Scope

- Continue visual-only lane after T15.
- Improve `SpectatorUI` mobile readability and spacing stability.
- Keep runtime and system logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Mobile footer reserve for spectator panel:
   - Added dedicated footer reserve profile for `SpectatorUI` in auxiliary sizing lane.

2. Mobile content frame rebalance:
   - `SpectatorUI` mobile `ContentFrame` position/size tuned to reduce overlap with footer lane.

3. Mobile typography tuning:
   - `SpectatorUI` secondary/footer text sizes reduced slightly for compact viewport readability.

4. Scope guard:
   - visual-only changes; no new systems and no gameplay/runtime logic changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates spectator panel readability on real mobile device lane.
- Owner executes manual 2-client smoke.
