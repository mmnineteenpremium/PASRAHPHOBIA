# Owner Editable GUI Safe Default And Play-Test Repair - 2026-05-01

## Scope

- Repair runtime visibility/wiring after owner Play Test reported all authored GUI frames opening together and UI buttons not behaving.
- Preserve the owner-editable `StarterGui` migration: no new UI system, no duplicate legacy shell, no change to match/gameplay logic.

## Changes

- Set all authored root `ScreenGui` model JSON files in `src/StarterGui` to default `Enabled=false`.
- Repaired `src/client/UI/Main.lua` compile failure by replacing invalid `goto`/label skip guards with Luau `continue`.
- Updated Room Browser visibility so `_updateRoomBrowserVisibility()` toggles authored `Backdrop.Visible` together with root `ScreenGui.Enabled` and `Panel.Visible`.

## Validation

- `pwsh -NoLogo -File scripts/release-preflight.ps1 -Json`
  - `buildOk: true`
  - `canonicalMirrorOk: true`
  - `missingReports: []`
- Studio opened directly on `PASRAHPHOBIA.rbxlx`, not stale temp/session file.
- Play Test run 1 found the blocking `Client.UI.Main:13252` syntax error and confirmed why wiring was disabled.
- Play Test run 2 confirmed `PasrahClientBootstrapStage=started`, `LobbyUI` visible, and non-lobby panels not effectively visible.
- Play Test run 3 confirmed clicking `LobbyUI.MainPanel.OpenRoomBrowserButton` opens `RoomBrowserUI` with `Backdrop.Visible=true` and `Panel.Visible=true`.
- Runtime log after repair contains no `Failed to require UI`, `System disabled: UI`, or `Client.UI.Main` error.

## Notes

- Some `ScreenGui` instances may be `Enabled=true` at runtime while their panels remain hidden; the validation uses effective visible descendants, not only root `Enabled`.
- Dynamic Room Browser rows and runtime data widgets remain runtime-generated inside the authored shell by design.
