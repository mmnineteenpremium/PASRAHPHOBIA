# Visual Batch T72 Map-Footer Height Micro Trim III 2026-04-26
## Scope
- Continue visual-only lane after T71.
- Keep RoomBrowser compact/extra-compact visual density progression stable.
- Keep room preview and room-flow runtime logic unchanged.
## Files Changed
- src/client/UI/Main.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md
## Change Summary
1. Visual density micro-tuning:
   - tinggi footer Map Preview lane extra-compact dipadatkan tipis lanjutan untuk ritme vertikal yang lebih ringkas.
   - text-size footer tetap dipertahankan agar readability aman.
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
