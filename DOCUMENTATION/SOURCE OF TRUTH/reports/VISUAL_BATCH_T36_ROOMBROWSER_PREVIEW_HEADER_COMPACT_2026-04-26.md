# Visual Batch T36 RoomBrowser Preview Header Compact 2026-04-26

## Scope

- Continue visual-only lane after T35.
- Improve RoomBrowser `Room Preview` header readability (`Title` + `Info`) in compact and extra-compact lanes.
- Keep room preview runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Compact info-row bounds:
   - Tuned `RoomPreviewInfo` bounds in compact branches, with smaller height in extra-compact lane.
   - Keeps summary row from dominating map preview space on short viewports.

2. Header typography behavior:
   - Added compact-aware text sizing for `RoomPreviewTitle` and `RoomPreviewInfo`.
   - Added extra-compact truncation behavior for title/info and disabled wrapping for info in that lane.

3. Scope guard:
   - visual-only changes; no room selection flow, preview data source, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates room preview header readability on compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
