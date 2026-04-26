# Visual Batch T22 RoomBrowser Preview Countdown Compact 2026-04-26

## Scope

- Continue visual-only lane after T21.
- Improve RoomBrowser extra-compact readability in map preview + countdown/float controls.
- Keep room browser/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Map preview extra-compact tuning:
   - Typography for preview title/label/chip/stats/footer is reduced in extra-compact lane.
   - Preview image height and main glyph text size are tuned for short viewport fit.

2. Countdown/float controls:
   - RoomBrowser float button text-size tuned down in extra-compact lane.
   - Countdown label size and cancel button footprint reduced for compact overlay readability.

3. Scope guard:
   - visual-only changes; no room browser logic, matchmaking logic, or runtime flow changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates map preview/countdown readability on extra-compact mobile lane.
- Owner executes manual 2-client smoke.
