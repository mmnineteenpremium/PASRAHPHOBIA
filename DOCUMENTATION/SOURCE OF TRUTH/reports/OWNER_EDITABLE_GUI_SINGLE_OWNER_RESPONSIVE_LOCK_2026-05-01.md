# OWNER-EDITABLE GUI SINGLE-OWNER RESPONSIVE LOCK

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI / no new gameplay system
Batch: T279

## Goal

Remove the remaining desktop-vs-mobile layout authority split after full `StarterGui` migration so one owner edit on the authored shell becomes the canonical layout source across devices.

## Problem

- Authored GUI shells already existed in `StarterGui`, but `_applyDeviceSizing()` still pushed device-specific positions and sizes into many of those shells.
- This caused owner edits to appear only on one lane:
  - some panels preserved authored layout mainly on PC,
  - some other panels still followed runtime mobile overrides.

## Execution

- Added an explicit authored-owner layout lock table in `src/client/UI/Main.lua`.
- Updated `_applyDeviceSizing()` so authored shells now preserve owner-authored layout for:
  - `LobbyUI`
  - `RoomBrowserUI`
  - `MatchUI`
  - `MainMenuUI`
  - `LeaderboardUI`
  - `JournalUI`
  - `ProfileUI`
  - `ShopUI`
  - `RoyalPassUI`
  - `PASRA_UI`
  - `SpectatorUI`
  - `LobbyUXGui`
  - `MatchUXGui`
- Runtime still handles:
  - visibility state
  - input binding
  - runtime-generated rows/cards/widgets inside the authored shell

## Result

- The active layout authority is no longer split into `desktop authored + mobile runtime geometry`.
- The active lane is now `single canonical authored shell` for the migrated player-facing GUI set.
- Owner-side Studio edits now target the real shell authority rather than fighting panel geometry overrides in runtime.

## Verification

- `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
  - `buildOk: true`
  - `missingReports: []`
  - manual blocker unchanged: `smoke test 2 client nyata`

## Remaining Notes

- This batch does not remove runtime-generated inner content such as shop rows, summary rows, or field-kit buttons.
- This batch intentionally avoids new systems and only changes visual authority ownership.
