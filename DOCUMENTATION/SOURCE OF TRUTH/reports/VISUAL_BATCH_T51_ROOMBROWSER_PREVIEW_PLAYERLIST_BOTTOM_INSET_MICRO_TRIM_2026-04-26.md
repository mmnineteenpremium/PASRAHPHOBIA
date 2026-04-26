# Visual Batch T51 RoomBrowser Preview PlayerList Bottom Inset Micro Trim 2026-04-26

## Scope

- Continue visual-only lane after T50.
- Improve RoomBrowser extra-compact preview player-list viewport efficiency with a micro bottom-inset trim.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Bottom inset micro trim:
   - Extra-compact preview players-list bottom inset reduced slightly (`38 -> 37`).
   - Reclaims a small amount of visible list height in short mobile viewports.

2. Hierarchy guard:
   - Title and list top anchor behavior preserved.
   - Change limited to list viewport density only.

3. Scope guard:
   - visual-only changes; no room preview data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates preview player-list readability in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
