# OWNER-EDITABLE GUI ROOMBROWSER FLOAT COUNTDOWN PRESERVATION

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI
Batch: T283

## Goal

Stop the remaining active RoomBrowser layout refresh from overriding authored float/countdown widget geometry.

## Scope

- `src/client/UI/Main.lua`
- Authored RoomBrowser widgets:
  - `RoomBrowserFloatUI`
  - `CountdownLabel`
  - `CancelCountdown`

## Execution

- Added authored-owner layout preservation guards around the active RoomBrowser float/countdown sizing branch.

## Result

- RoomBrowser authored float/countdown widgets no longer snap back to compact runtime geometry while the owner-layout lock is active.
- Remaining RoomBrowser runtime layout work is now primarily dynamic row/card content.

## Verification

- `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
  - `buildOk: true`
  - `missingReports: []`
