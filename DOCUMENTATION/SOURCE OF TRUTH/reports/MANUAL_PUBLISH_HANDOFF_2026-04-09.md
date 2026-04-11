# Manual Publish Handoff 2026-04-09

## Purpose

This file compresses the current manual publish state after the latest Stage 1 gate refresh. It is the operational handoff for the remaining non-automated lanes.

## Current Technical Baseline

- date: `2026-04-09 22:01:57 +07:00`
- branch: `source-of-truth-w-rojo-7.6.1-mcp-server-enable`
- commit: `270a8a6`
- local preflight:
  - `Build ok: True`
  - `Missing reports: 0`
  - `Robux items: 10`
  - `Safe items missing ID: 0`
  - `Safe items disabled: 0`
  - `Hold items enabled: 0`
- commerce refresh (`2026-04-10 13:38:59 +07:00`):
  - `audit-marketplace-mapping` now reports:
    - `Safe items missing marketplaceId: 0`
    - `Safe items still disabled: 0`
    - `Hold items accidentally enabled: 0`
    - `Unclassified items: 0`
  - `6` safe DeveloperProducts now use real Creator Hub IDs and are enabled
  - `4` hold GamePass items now use real IDs and remain disabled by policy
- latest automatic gate:
  - `GetQAGateReadiness => overall=pass_with_manual_multiplayer solo=true memoryOk=true fpsOk=true logOk=true`
  - `GetQAGateSnapshot => activeMatches=0 totalMemoryMb=2211.40 physicsFps=60.00 warnings=0 errors=0 logSample=clean`
  - `GetPublishReadiness => overall=fail qaSolo=true multiplayer=manual_check_required persistence=mock persistenceReady=false commerceReady=true robuxVisible=0 robuxMissingId=10`
  - `GetShopReadiness => total=31 MM=14 PP=7 Robux=10 disabled=10 robuxMissingId=10`
  - `GetPersistenceMode => mode=mock hasDataStore=false allowStudioDataStore=false trackedPlayers=1 schemaVersion=2`

## Mobile-First Guardrail

- new high-risk requirement recorded on `2026-04-09`:
  - experience is mobile-first
  - UI must stay flexible on mobile landscape screens
  - visual quality must be adjustable in-game
  - landscape orientation must be enforced on open
  - PC / console support remains required
- current implementation state:
  - source-controlled orientation lock now points to `LandscapeSensor`
  - live Studio runtime was re-verified to report `Enum.ScreenOrientation.LandscapeSensor`
  - `MainMenuUI` now has a real client-side visual quality cycle (`RINGAN` / `SEIMBANG` / `DETAIL`)
  - `Performance` mode lowers atmosphere cost, cuts bloom / sun rays / DOF / blur-heavy spectator+sensory effects, softens local shadow cost, and swaps heavy 3D UI previews to flat fallback cards instead of fake no-op toggles
  - `Balanced` now keeps the horror read while still trimming the most expensive post-processing lane for mobile hardware
  - the follow-through live smoke also caught and repaired a `Main.lua` UI bootstrap parse error before handoff, so the graphics path is no longer blocked by a disabled client UI system
  - mobile menu layout math was widened to keep the extra quality control inside a short landscape viewport path (`844x390` override lane)
- remaining manual proof:
  - real-device smoke on phone/tablet should still confirm readability, touch comfort, and quality toggle feel on actual hardware before public publish

## Batch 1 - Creator Hub Mapping

- audit command:
  - `pwsh ./scripts/audit-marketplace-mapping.ps1`
- current result:
  - `10` Robux catalog items classified
  - `6` safe currency items now have real `marketplaceId` and are enabled
  - `4` policy-hold GamePass items now have real `marketplaceId` and remain disabled
  - `0` hold items are accidentally enabled
  - `0` unclassified items remain
- hold items that must stay disabled:
  - `royalpass_premium_track`
  - `class_dukun_unlock`
  - `class_detective_unlock`
  - `lifetime_bonus_pass`
- next action:
  - lane closed for mapping; proceed to multiplayer/persistence/legal lanes

## Batch 2 - Multiplayer Lane

- prepared sheet:
  - `QA_MULTIPLAYER_RESULT_2026-04-09_PREP.md`
- current truth:
  - automatic gate is already clean for solo runtime
  - final real `2`-client core flow is `PASS` by owner-confirmed session
  - forced-reset / respawn guard edge-case was later reopened and patched on `2026-04-11`
- stop condition:
  - lane only closes again after the forced-reset retest passes

## Batch 3 - Persistence Lane

- prepared sheet:
  - `PERSISTENCE_RESULT_2026-04-09_PREP.md`
- current truth:
  - persistence is still `mock` in Studio
  - publish must stay `NO-GO` until a non-mock target proves load/save/reconnect correctness
- stop condition:
  - do not mark this lane `PASS` from Studio mock

## Batch 4 - Legal / Licensing Lane

- `Pocong` provenance is no longer the blocker:
  - author: `alterego.visual`
  - license: `CC BY 4.0`
  - attribution catalog is source-controlled in `src/shared/DataTypes/AssetAttributionCatalog.lua`
  - attribution is wired into active UI in `src/client/UI/Main.lua`
- active canonical audio ledger is already documented as `verified`
- remaining legal/manual review is now:
  - confirm the credits / attribution surface remains visible in the final experience layout
  - decide whether the `LegacyDisabled` asset set should be archived, documented further, or removed before final public publish
  - collect optional screenshot evidence pack if a stricter audit bundle is desired

## Batch 5 - Ordered Next Actions

1. Rerun the forced-reset / respawn guard check on `2` real clients.
2. Keep `QA_MULTIPLAYER_RESULT_2026-04-09_PREP.md` as the recorded PASS sheet for the core flow, plus `RESPAWN_GUARD_AND_FORCED_RESET_FIX_2026-04-11.md` for the reopened edge-case lane.
3. Keep persistence and legal reports as the canonical PASS evidence bundle.
4. Use the final checklist for the publish decision only after the edge-case retest is closed.

## Go / No-Go

- `REOPENED` for the technical/platform lane because:
  - multiplayer core result is `PASS`
  - forced-reset / respawn guard retest is still pending
  - persistence result is `PASS`
  - legal review is `PASS`
- `NO-GO` for full public launch while owner/brand quality work is still open
- see:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/OWNER_BRAND_RELEASE_POSITION_2026-04-11.md`
