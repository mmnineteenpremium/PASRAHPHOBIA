# Visual Batch T11 Shop Mobile Layout Stability 2026-04-26

## Scope

- Continue visual-only lane after T10.
- Stabilize `ShopUI` mobile layout when footer/state strings are dense.
- Keep runtime and system behavior unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Shop mobile panel height tuning:
   - `ShopUI` minimum mobile panel height increased in device sizing lane.

2. Shop mobile content/footer spacing:
   - mobile footer for `ShopUI` now gets larger reserved area.
   - mobile `ContentFrame` height adjusted to avoid overlap with footer lines.

3. Shop mobile typography stability:
   - filter button text size tuned down slightly on mobile.
   - secondary/footer label text size tuned down slightly on mobile.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates final readability on real mobile devices.
- Owner executes manual 2-client smoke.
