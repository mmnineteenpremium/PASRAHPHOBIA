# Visual Batch T29 RoomBrowser Kick Notice Compact 2026-04-26

## Scope

- Continue visual-only lane after T28.
- Improve RoomBrowser `KickNoticeModal` readability for compact and extra-compact mobile viewports.
- Keep kick handling/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Kick notice compact lanes:
   - Added explicit `compact` and `extra-compact` viewport profiles for `KickNoticeCard`.
   - Card size now adapts for short-height screens without behavior changes.

2. Kick notice hierarchy/readability:
   - Tuned warning text block position/size/text-size to keep message prominence in tighter layouts.
   - Tuned `OK` button position/size/text-size so action remains clear and centered.

3. Scope guard:
   - visual-only changes; no kick detection flow, room state, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates `KickNoticeModal` readability in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.
