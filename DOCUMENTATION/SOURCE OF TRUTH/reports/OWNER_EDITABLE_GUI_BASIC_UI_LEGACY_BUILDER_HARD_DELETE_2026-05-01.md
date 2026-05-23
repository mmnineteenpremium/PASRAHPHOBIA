# OWNER-EDITABLE GUI BASIC UI LEGACY BUILDER HARD DELETE

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI
Batch: T286

## Goal

Remove the unreachable generic `BASIC_GUI_NAMES` builder so authored `StarterGui` shells remain the only source for the main player-facing UI surfaces.

## Scope

- `src/client/UI/Main.lua`
- `_ensureBasicUIs()`

## Execution

- Deleted the fallback branch that created generic `ScreenGui`, `MainPanel`, auxiliary panels, match panel, menu panel, leaderboard panel, and float buttons after authored bind branches.
- Kept the authored bind branches for:
  - `LobbyUI`
  - `MainMenuUI`
  - `LeaderboardUI`
  - `MatchUI`
  - `JournalUI`
  - `ProfileUI`
  - `ShopUI`
  - `RoyalPassUI`
  - `PASRA_UI`
  - `SpectatorUI`
- Added an explicit warning for any future unsupported `BASIC_GUI_NAMES` entry.

## Result

- `Main.lua` no longer has a generic runtime `ScreenGui/MainPanel` builder for the migrated main UI surfaces.
- The remaining `Instance.new("ScreenGui")` hits are runtime-only/transient:
  - `QuestPopupGui` in `QuestTracker.lua`
  - `SensoryHorrorHUD` in `HorrorHUD.luau`

## Verification

- `pwsh -NoLogo -File scripts/release-preflight.ps1 -Json`
  - `buildOk: true`
  - `canonicalMirrorOk: true`
  - `missingReports: []`
