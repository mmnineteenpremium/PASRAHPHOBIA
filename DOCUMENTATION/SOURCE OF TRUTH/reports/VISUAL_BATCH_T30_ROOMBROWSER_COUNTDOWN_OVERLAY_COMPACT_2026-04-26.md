# Visual Batch T30 RoomBrowser Countdown Overlay Compact 2026-04-26

## Scope

- Continue visual-only lane after T29.
- Improve RoomBrowser `CountdownOverlay` readability for compact and extra-compact mobile viewports.
- Keep countdown start/cancel/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Countdown overlay compact hierarchy:
   - Tuned `CountdownLabel` text size, visual bounds, and vertical position for compact/extra-compact lane.
   - Preserved existing overlay behavior and room state flow.

2. Cancel countdown action readability:
   - Tuned `CancelCountdown` button size, vertical position, and text size for short-height screens.
   - Improved action prominence without introducing new UI logic.

3. Scope guard:
   - visual-only changes; no countdown timing, host-start flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates `CountdownOverlay` readability in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
