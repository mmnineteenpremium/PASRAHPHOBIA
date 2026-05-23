# OWNER-EDITABLE GUI RUNTIME BINDING RESET REPAIR

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI
Batch: T287

## Problem

After the authored GUI migration, Play Test could inherit edit-mode `Visible` / `Enabled` / saved binding attributes from authored instances. That made panels appear together and could make buttons look present while their runtime click wiring was skipped.

## Scope

- `src/client/UI/Main.lua`
- `src/client/FlashlightController.client.lua`

## Execution

- Replaced persistent `Bound` button guards with runtime-memory button binding guards.
- Replaced persistent drag guards with runtime-memory drag guards.
- Replaced `MainMenuInitDone` / `LeaderboardInitDone` attribute initialization with runtime-only bootstrap tracking.
- Added runtime bootstrap visibility reset for authored auxiliary, match, and RoomBrowser shells.

## Result

- Studio edit-mode visibility can still be used for manual editing, but Play Test no longer treats saved attributes as live wiring state.
- Runtime logic rebinds buttons every play session correctly.
- Authored layout position/size remains owner-editable; runtime only resets visibility/state at bootstrap.

## Verification

- `pwsh -NoLogo -File scripts/release-preflight.ps1 -Json`
  - `buildOk: true`
  - `canonicalMirrorOk: true`
  - `missingReports: []`
- `rg` checks:
  - no `GetAttribute("Bound")` in `Main.lua` / `FlashlightController.client.lua`
  - no `SetAttribute("Bound", true)` in `Main.lua` / `FlashlightController.client.lua`
