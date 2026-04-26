# Visual Batch T17 Mobile Header Control Consistency 2026-04-26

## Scope

- Continue visual-only lane after T16.
- Improve mobile consistency for header controls across auxiliary/basic panels.
- Keep systems/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Auxiliary mobile header rhythm:
   - `PrimaryLabel` and `SecondaryLabel` on mobile aligned to a more consistent vertical rhythm.
   - `StatusBadge` mobile size/position/text-size normalized for compact readability.

2. Mobile control touch/readability:
   - `CloseButton` mobile size/text tuned for clearer tap target.
   - `FloatButton` mobile text size tuned across auxiliary + basic windows.

3. Scope guard:
   - visual-only presentation changes; no gameplay/economy/runtime system changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates mobile header/control readability on real device lane.
- Owner executes manual 2-client smoke.
