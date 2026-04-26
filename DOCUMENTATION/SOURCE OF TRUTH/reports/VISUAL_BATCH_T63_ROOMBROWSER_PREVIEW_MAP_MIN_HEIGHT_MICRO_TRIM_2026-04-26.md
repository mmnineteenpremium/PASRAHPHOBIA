# Visual Batch T63 Preview-Map Min-Height Micro Trim 2026-04-26
## Scope
- Continue visual-only lane after T62.
- Keep RoomBrowser compact/extra-compact visual density progression stable.
- Keep room preview and room-flow runtime logic unchanged.
## Files Changed
- src/client/UI/Main.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md
## Change Summary
1. Visual density micro-tuning:
   - minimum tinggi Map Preview dipadatkan tipis lanjutan untuk lane extra-compact.
   - membuka sedikit ruang vertikal ekstra untuk section bawah preview.
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
