# Visual Batch T15 PASRA Journal Mobile Readability 2026-04-26

## Scope

- Continue visual-only lane after T14.
- Improve mobile readability/stability for `PASRA_UI` and `JournalUI` auxiliary panels.
- Keep runtime/gameplay/economy systems unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Mobile footer lane reserve:
   - Added dedicated mobile footer spacing profile for `PASRA_UI`.
   - Keeps footer copy separated from dynamic content block.

2. Mobile content frame stability:
   - `PASRA_UI` mobile `ContentFrame` size/offset tuned to avoid lower-panel collision.
   - `JournalUI` mobile `ContentFrame` resized for scan section safety.

3. Journal scan strip compact tuning:
   - `ToolActionButton` + `ToolStatusLabel` mobile positions/sizes tuned to stay readable and non-overlapping.
   - secondary/footer text-size tuned on mobile for both `PASRA_UI` and `JournalUI`.

4. Scope guard:
   - visual-only presentation changes; no new systems and no runtime logic changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates PASRA/Journal readability on real mobile device lane.
- Owner executes manual 2-client smoke.
