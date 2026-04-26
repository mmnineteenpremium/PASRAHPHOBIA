# Visual Batch T34 RoomBrowser Invite Dropdown Compact 2026-04-26

## Scope

- Continue visual-only lane after T33.
- Improve RoomBrowser `InviteDropdown` readability and fit in compact/extra-compact viewports.
- Keep invite/matchmaking runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Wide compact invite tuning:
   - Added responsive invite dropdown height in wide compact lane (`extraCompactMobile` vs default compact).
   - Dropdown Y anchor now follows computed height so it stays visible in short viewports.

2. Single-column compact invite tuning:
   - Added compact invite button height, dropdown offset, and dropdown height variables.
   - Updated room canvas sizing to follow dynamic invite block total height.

3. Scope guard:
   - visual-only changes; no invite flow, matchmaking state, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates invite dropdown readability and clipping behavior on compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
