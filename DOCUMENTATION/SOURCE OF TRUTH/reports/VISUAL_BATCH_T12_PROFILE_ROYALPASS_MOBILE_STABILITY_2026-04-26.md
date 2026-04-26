# Visual Batch T12 Profile RoyalPass Mobile Stability 2026-04-26

## Scope

- Continue visual-only lane after T11.
- Stabilize mobile layout readability for `ProfileUI` and `RoyalPassUI`.
- Keep runtime behavior and gameplay/economy logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Mobile footer spacing per panel:
   - `ProfileUI` and `RoyalPassUI` now reserve larger footer area on mobile.
   - Footer offset/height tuned so footer lines do not collide with content in compact viewport.

2. Mobile content area stability:
   - `ProfileUI` and `RoyalPassUI` `ContentFrame` mobile size/position adjusted.
   - Scrollbar thickness raised to keep touch readability consistent with recent Shop tuning.

3. Mobile typography tuning:
   - `ProfileUI` mobile secondary/footer labels reduced slightly.
   - `RoyalPassUI` mobile secondary/footer labels tuned to reduce overflow risk.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates final mobile readability in real-device lane.
- Owner executes manual 2-client smoke.
