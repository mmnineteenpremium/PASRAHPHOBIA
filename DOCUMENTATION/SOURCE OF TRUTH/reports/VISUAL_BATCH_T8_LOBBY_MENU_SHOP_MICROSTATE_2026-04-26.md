# Visual Batch T8 Lobby Menu Shop Microstate 2026-04-26

## Scope

- Continue visual-only lane after T7.
- Finish wallet MM/PP micro-state presentation for lobby/menu lanes.
- Tighten daily lane readability on lobby focus.
- Extend gacha/detail presentation in `ShopUI` without adding systems.

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`
- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Change Summary

1. Lobby panel micro-state:
   - added runtime snapshot visual summary for:
     - wallet MM/PP
     - daily quest/check-in
     - hidden gems compact lane
     - gacha snapshot (`owned/equipped`)
   - when zone focus is `DailyRewardZone`, secondary/hint now explicitly carries daily lane context.

2. Quick menu micro-state:
   - secondary text now includes wallet and hidden gems compact state.
   - footer now includes canonical daily + gacha + hidden gems snapshot line.
   - added main menu stamp attributes for wallet/daily/gacha/hidden lane values.

3. Shop gacha detail lane:
   - `ShopUI` secondary text now includes hidden gems compact and gacha snapshot state.
   - filter footers now include gacha detail (`owned/equipped`) + hidden gems lane in one consistent copy style.
   - shop runtime stamp now includes hidden gems progress/cap + gacha/equipped attributes.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Final readability polish pass lintas device (mobile vs desktop) for canonical panels.
- Owner executes manual 2-client smoke.
