# Visual Batch T48 RoomBrowser Join Password Anchor Trim 2026-04-26

## Scope

- Continue visual-only lane after T47.
- Improve RoomBrowser extra-compact grouping between join-password input and primary action row.
- Keep mode selection and room-flow runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Join-password anchor trim:
   - Extra-compact `JoinPassword` vertical offset tightened relative to `Queue` row.
   - Improves perceived grouping of input and primary action.

2. Scope and stability:
   - Field height remains unchanged; only positional spacing adjusted.
   - Keeps action hierarchy clearer in short mobile viewports.

3. Scope guard:
   - visual-only changes; no mode selection behavior, room flow, password-validation, or runtime-authority behavior changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates join-password to action-row grouping in extra-compact mobile lane.
- Owner executes manual 2-client smoke.
