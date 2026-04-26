# Visual Batch T52 RoomBrowser Preview PlayerList Top Gap Micro Trim 2026-04-26

## Scope

- Continue visual-only lane after T51.
- Improve RoomBrowser extra-compact preview player-list top-gap density by a micro step.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Top-gap micro trim:
   - Extra-compact preview players-list top gap reduced slightly (`25 -> 24`).
   - Tightens vertical rhythm below the map preview block.

2. Hierarchy guard:
   - Preview players-title anchor remains unchanged.
   - Keeps label hierarchy stable while improving list density.

3. Scope guard:
   - visual-only changes; no room preview data flow, player-state logic, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates preview player-list readability and spacing in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
