# OWNER-EDITABLE GUI FLOAT RAIL PRESERVATION

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI
Batch: T281

## Goal

Stop runtime float-rail positioning from overriding authored float-button placement.

## Scope

- `src/client/UI/Main.lua`

## Execution

- Updated `_layoutLobbyFloatRail()` to return early while the authored-owner layout lock is active for:
  - `RoomBrowserFloatUI`
  - `MainMenuUI`
  - `LeaderboardUI`
  - `ProfileUI`
  - `ShopUI`
  - `RoyalPassUI`

## Result

- Authored float-button placement is now preserved during refresh and visibility sync.
- Owner edits to float-button positions are no longer forced back into a runtime rail stack.

## Verification

- `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
  - `buildOk: true`
  - `missingReports: []`
