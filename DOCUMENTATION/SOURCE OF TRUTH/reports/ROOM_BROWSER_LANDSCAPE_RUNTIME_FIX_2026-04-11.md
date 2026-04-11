# Room Browser Landscape Runtime Fix - 2026-04-11

## Summary
- Fixed the client UI bootstrap failure and the remaining mobile landscape sizing defect in Room Browser.
- Verified in Roblox Studio play test with mobile override and landscape viewport simulation.

## Root Causes
1. `Client.UI.Main` exceeded the Luau local register limit.
   - Symptom: `Out of local registers when trying to allocate fadeGuiObject`.
   - Effect: `ClientBootstrap` disabled the `UI` system, so `RoomBrowserUI`, `LobbyUI`, and related screens never appeared in `PlayerGui`.
2. Room Browser sizing still carried portrait-biased minimum height rules.
   - Symptom: mobile landscape overlay rendered taller than the effective viewport and got clipped at the top/right in Studio simulation.

## Code Changes
- Added new module: `src/client/UI/UISupport.lua`
- Moved these top-level helpers out of `src/client/UI/Main.lua` to get below Luau's register limit:
  - `disconnectAll`
  - `destroyAll`
  - `fadeGuiObject`
  - `resolveSafeInsets`
  - `createDeviceProfile`
- Updated `Main.lua` call sites to use `UISupport.*`.
- Adjusted Room Browser landscape sizing logic:
  - removed portrait-biased minimum height behavior for mobile landscape
  - clamped Studio simulation viewport to the smaller of actual camera viewport and manual override so the visual test in Studio matches the visible test surface

## Studio Runtime Verification
Test conditions:
- `PasrahUIInputProfileOverride = mobile`
- `PasrahUIViewportOverrideX = 844`
- `PasrahUIViewportOverrideY = 390`
- `PasrahUIForceCompact = true`

Results:
- `PasrahClientBootstrapStage = started`
- `PlayerGui` now contains:
  - `LobbyUI`
  - `MainMenuUI`
  - `RoomBrowserUI`
  - other expected client screens
- Room Browser open-state runtime probe after clicking `LobbyUI.MainPanel.OpenRoomBrowserButton`:
  - `RoomBrowserUI.Enabled = true`
  - `Panel size = 733 x 371`
  - `Backdrop size = 733 x 371`
  - `QueueButton size = 361 x 40`
  - `CreateRoomButton size = 177 x 36`
- Input shield verification:
  - dragged inside `RoomList`
  - `CurrentCamera.CFrame` stayed unchanged before vs after drag
  - conclusion: UI interaction no longer leaked to camera movement in this Studio test

## Visual Result In Studio
- Room Browser now opens as a fixed landscape overlay that fills the visible Studio viewport.
- Left side shows preview content.
- Right side shows room list and action lane.
- `JOIN ROOM`, `Refresh`, and `BUAT ROOM` are visible inside the overlay without spilling outside the current Studio viewport.

## Status
- UI bootstrap blocker: PASS
- mobile landscape overlay sizing in Studio: PASS
- touch/camera leak regression check in Studio: PASS
- remaining publish blocker: real 2-client smoke on actual Roblox clients
