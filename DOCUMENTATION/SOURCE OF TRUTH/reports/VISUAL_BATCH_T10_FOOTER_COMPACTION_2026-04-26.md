# Visual Batch T10 Footer Compaction 2026-04-26

## Scope

- Continue visual-only lane after T9.
- Reduce footer density on mobile for `Quick Menu` and `ShopUI`.
- Keep desktop detail copy unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Quick menu mobile footer compaction:
   - mobile footer now prioritizes canonical daily/gacha/hidden summary + build signature.
   - attribution line on mobile is represented in compact pointer form instead of full long paragraph.
   - desktop footer keeps full detail lane.

2. Shop mobile footer compaction:
   - all filter footers (`All`, `MM`, `PP`, `Robux`, `Owned`) now use shorter mobile wording.
   - key semantics remain the same:
     - in-game currency constraint
     - ranked fairness
     - classic-only restriction
     - hidden gems cap lane
     - gacha snapshot lane
   - desktop footer keeps full explanatory copy.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates final mobile readability on real devices.
- Owner executes manual 2-client smoke.
