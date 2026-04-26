# Visual Batch T42 RoomBrowser Horizontal Space Reclaim 2026-04-26

## Scope

- Continue visual-only lane after T41.
- Improve RoomBrowser extra-compact room-list horizontal readability and density.
- Keep room select/join runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Row horizontal inset trim:
   - Extra-compact room-list row width inset reduced (`-8` to `-6`).
   - Reclaims text space on short/narrow mobile lanes.

2. Internal horizontal padding trim:
   - Extra-compact row left/right padding reduced slightly.
   - Keeps row content denser while preserving readability.

3. List gap trim:
   - Extra-compact list row gap reduced slightly in sizing pass.
   - Improves visible room count and scan continuity.

4. Scope guard:
   - visual-only changes; no room selection behavior, join flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates room-list horizontal readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
