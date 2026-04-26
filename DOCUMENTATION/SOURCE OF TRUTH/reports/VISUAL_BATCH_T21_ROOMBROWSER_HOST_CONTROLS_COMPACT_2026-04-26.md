# Visual Batch T21 RoomBrowser Host Controls Compact 2026-04-26

## Scope

- Continue visual-only lane after T20.
- Improve host-room control readability in RoomBrowser extra-compact mobile lane.
- Keep room browser behavior/runtime logic unchanged.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Host-room control typography baseline:
   - Added text-size tuning for host-room fields/buttons (`mode/map/password/invite/ready/start/cancel/leave`) based on extra-compact lane.
   - Room title/host/players labels also tuned to avoid dense text blocks.

2. Dropdown/list density:
   - Mode and map option typography reduced in extra-compact lane.
   - Player list card height in compact host-room lane reduced to fit better on short viewports.

3. Scope guard:
   - visual-only changes; no room browser logic, matchmaking logic, or runtime flow changes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner validates host-room controls readability on extra-compact mobile lane.
- Owner executes manual 2-client smoke.
