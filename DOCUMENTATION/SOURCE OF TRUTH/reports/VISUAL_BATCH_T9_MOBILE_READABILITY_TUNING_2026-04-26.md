# Visual Batch T9 Mobile Readability Tuning 2026-04-26

## Scope

- Continue visual-only lane after T8.
- Improve readability on mobile/compact viewports for panels that now carry richer micro-state text.
- Keep runtime behavior and architecture unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Lobby panel copy compaction (mobile):
   - wallet/daily/hidden/gacha lines now use shorter mobile wording.
   - daily zone (`DailyRewardZone`) now uses compact quest/check-in/gacha formatting on mobile.

2. Quick menu copy compaction (mobile):
   - secondary and footer summary lines now use compact mobile wording to reduce overflow risk.
   - room-active secondary line also compacted for mobile.

3. Shop copy compaction (mobile):
   - secondary line now uses shorter mobile text (`Hidden + Gacha` compact).
   - gacha lane footer text shortened on mobile while preserving same snapshot meaning.

4. Device sizing tweaks:
   - lobby hint area height increased for compact/mobile lanes.
   - compact lobby header primary/secondary heights and text sizes tuned down for denser readable fit.
   - mobile `MainMenuUI` primary/secondary/footer text sizes tuned for long micro-state strings.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates final readability on real devices.
- Owner executes manual 2-client smoke.
