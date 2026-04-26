# Visual Batch T95 RoomList Bottom-Gap Trim IV 2026-04-26

## Scope

- Continue visual-only lane after T94.
- Keep RoomBrowser compact/extra-compact visual density progression stable.
- Keep room preview and room-flow runtime logic unchanged.

## Files Changed

- src/client/UI/Main.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md

## Change Summary

1. Visual density micro-tuning:
   - bottom-gap transisi room-list ke action lane extra-compact dipadatkan tipis lanjutan.
   - continuity list-to-action makin rapat tanpa mengubah flow.

2. Scope guard:
   - visual-only changes; no room preview/map/player runtime behavior changes.

## Verification

- scripts/release-preflight.ps1 -Json
  - uildOk=true
  - canonicalMirrorOk=true
  - manual blocker remains:
    - smoke test 2 client nyata: owner task manual (eksekusi user)

## Pending

- Owner validates compact/extra-compact readability for this batch.
- Owner executes manual 2-client smoke.
