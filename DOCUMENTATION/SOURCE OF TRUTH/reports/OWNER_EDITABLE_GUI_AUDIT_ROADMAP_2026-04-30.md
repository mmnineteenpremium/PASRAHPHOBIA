# Owner-Editable GUI Audit + Roadmap 2026-04-30

## Purpose

- Define which player-facing visual surfaces can realistically be migrated into owner-editable authored GUI.
- Keep existing logic, wiring, remote flow, and state ownership intact.
- Prevent dual-lane GUI runtime duplication by hard-deleting legacy builders once a surface is migrated.

## Current Architecture Audit

Current blocker:

- repo currently has no `src/StarterGui`, so there is no authored GUI canvas that the owner can edit directly as the visual source-of-truth.

Runtime-authored player GUI surfaces:

1. `src/client/UI/Main.lua`
   - `LobbyUI`, `MatchUI`, `ProfileUI`, `ShopUI`, `RoyalPassUI`, `PASRA_UI`, `SpectatorUI`, `LeaderboardUI`, `MainMenuUI`
   - `RoomBrowserUI`, `RoomBrowserFloatUI`
   - `MatchLoadingUI`
   - `TeleportScreen`
   - `LobbyUXGui`
   - `MatchUXGui`
2. `src/client/UI/QuestTracker.lua`
   - `QuestTrackerGui`
3. `src/client/UI/QuestJournal.lua`
   - `QuestJournalGui`
4. `src/client/UI/SanityHUD.lua`
   - `SanityHUDGui`
5. `src/client/CameraController.client.lua`
   - `FPVCursorToggleUI`
6. `src/client/FlashlightController.client.lua`
   - `FlashlightToggleUI`

Wiring ownership that must remain intact:

1. `src/client/Core/ClientBootstrap.lua`
   - registers the `UI` system and keeps lifecycle `Init/Start` ownership in the existing client registry.
2. `src/client/UI/Main.lua`
   - owns `_uxWidgets`, `_roomBrowserWidgets`, `_uiState`, visibility policy, dedupe policy, and remote-driven rendering.
3. `src/client/UI/QuestUIController.lua`
   - owns `QuestTracker` + `QuestJournal` startup.
4. `src/client/UI/OverlayController.lua`
   - owns `SanityHUD` startup.

## Classification

### Wave A: Low Risk, High Owner Leverage

- `LobbyUI`
- `RoomBrowserUI`
- `MainMenuUI`
- `LeaderboardUI`
- `MatchLoadingUI`
- `TeleportScreen`
- `QuestTrackerGui`
- `QuestJournalGui`
- `SanityHUDGui`
- `FPVCursorToggleUI`
- `FlashlightToggleUI`

Why first:

- mostly panel-based or overlay-based shells
- owner gets immediate direct visual control
- lower risk to runtime logic because these surfaces are easier to bind by stable instance names

### Wave B: Medium Risk, Data-Heavy Panels

- `ProfileUI`
- `ShopUI`
- `RoyalPassUI`
- `PASRA_UI`
- `SpectatorUI`

Why second:

- more dynamic rows/cards/filters/snapshot-driven content
- still realistic to convert into authored shells if the widget contract is preserved

### Wave C: Higher Risk Runtime-Dense Surfaces

- `MatchUI`
- `LobbyUXGui`
- `MatchUXGui`

Why later:

- denser runtime state, guided overlays, result state, countdown, field-kit controls, hunt state, and training panels
- higher chance of breaking behavior if migrated too early

### Explicitly Out of Scope for First GUI Migration

- world-space `BillboardGui` / `SurfaceGui` in:
  - `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - `src/client/ToolVisualController.client.lua`
- these are runtime/world-bound visuals, not normal owner-edit `StarterGui` surfaces

## Migration Rules

1. Do not create a second active visual system for the same surface.
2. Keep the same logical owner and remote/data flow.
3. Keep canonical widget names stable so existing binding code can attach to the authored shell.
4. Once a surface is successfully bound to authored GUI, delete the old runtime builder path for that surface.
5. Do not leave hidden legacy builders that another AI could re-enable later.
6. If a surface must stay runtime-only, document the reason explicitly.

## Recommended Implementation Shape

1. Create authored GUI shells in project hierarchy for the selected wave.
2. Update code so it binds to existing authored instances first.
3. When bind is stable, delete the `Instance.new(...)` builder path for that surface.
4. Keep render/update functions, event routing, and state ownership in the current modules.

This is a visual-shell migration, not a new UI system.

## Owner Editing Workflow

1. Agent migrates a surface into authored GUI without changing behavior.
2. Owner edits layout visually in Studio:
   - drag
   - move
   - resize
   - align
   - adjust spacing/typography
3. Agent preserves wiring, cleans legacy code, and validates no duplicate visible path remains.
4. Result is saved back to `PASRAHPHOBIA.rbxlx`, mirrored to source, then published.

## Verification Rules

1. PC-specific visual bugs must be tested in PC lane, not Studio mobile preview override.
2. Mobile-specific layout bugs must be tested in the correct mobile lane.
3. Save-back to `PASRAHPHOBIA.rbxlx` must be verified explicitly before claiming the local file is updated.
4. Studio must be closed again after test/publish to avoid multi-instance confusion.

## Publish Closure

Per wave:

1. migrate authored shell
2. owner visual edit
3. legacy runtime builder deletion
4. save-back verification
5. publish to canonical place
6. close Studio

## Decision For Miftah

Owner-facing implication:

- this migration is worth doing because it converts visual work from code-only tweaking into direct visual editing in Studio.
- the safest route is not “rewrite all UI now”, but staged migration by wave.
- RoomBrowser and Lobby should be first because they provide the largest immediate owner control with the least wiring risk.
