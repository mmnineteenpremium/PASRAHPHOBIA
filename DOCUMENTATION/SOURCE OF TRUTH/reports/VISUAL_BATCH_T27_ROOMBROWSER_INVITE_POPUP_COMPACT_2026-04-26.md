# Visual Batch T27 RoomBrowser Invite Popup Compact 2026-04-26

## Scope

- Continue visual-only lane after T26.
- Improve RoomBrowser `InvitePopup` readability in compact and extra-compact mobile viewports.
- Keep invite flow/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Invite popup compact lanes:
   - Added explicit `compact` and `extra-compact` layout profiles for `InvitePopup` in `updateInvitePopupLayout()`.
   - Popup size now adapts per viewport while keeping existing safe-inset positioning behavior.

2. Invite popup hierarchy/readability:
   - Tuned text area position/size and text size to reduce crowding on short-height screens.
   - Tuned `TERIMA/TOLAK` button positions, sizes, and text size for tighter vertical rhythm.

3. Scope guard:
   - visual-only changes; no invite acceptance logic, matchmaking flow, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates `InvitePopup` readability in compact and extra-compact mobile lanes.
- Owner executes manual 2-client smoke.

