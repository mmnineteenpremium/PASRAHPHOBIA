# Visual Batch T49 RoomBrowser Preview PlayerList Top Gap Trim 2026-04-26

## Scope

- Continue visual-only lane after T48.
- Improve RoomBrowser extra-compact vertical spacing between map preview and preview player list.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Preview player-list top-gap trim:
   - Added extra-compact-specific `previewPlayersTopGap`.
   - Player-list anchor moves slightly upward in extra-compact lane.

2. Hierarchy preservation:
   - `Room Preview Players` title anchor remains unchanged.
   - Keeps section label hierarchy stable while improving list area efficiency.

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
