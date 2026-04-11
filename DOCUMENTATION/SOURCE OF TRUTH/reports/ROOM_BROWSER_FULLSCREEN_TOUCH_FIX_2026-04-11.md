# Room Browser Fullscreen Touch Shield Fix - 2026-04-11

## Summary
- Fixed the mobile Room Browser interaction model after real-device feedback showed the UI still behaved like a floating desktop panel.
- Real blocker confirmed: touch gestures on Room Browser still leaked to camera movement.

## Changes
- File changed: `src/client/UI/Main.lua`
- Added a full-screen Room Browser backdrop layer:
  - `Backdrop` now covers the whole screen and is `Active=true`
- Moved the Room Browser panel under the backdrop and made the panel itself `Active=true`
- Made key interactive containers explicitly absorb touch input:
  - `RoomList`
  - `RoomPreviewPanel`
  - `RoomPreviewMap`
  - `RoomPreviewPlayersList`
  - `PlayersList`
  - password modal/card
  - kick notice modal/card
  - `MapPreview`
- For mobile sizing, Room Browser now uses the full safe-area viewport instead of a floating card with outer margins.
- Drag bar is hidden on mobile so the browser behaves like a fixed landscape overlay, not a draggable desktop panel.
- Root panel transparency on mobile now stays lightly translucent in both browser view and in-room view.

## Verification
- Local build still passes `release-preflight.ps1`.
- Active cloud-attached Studio script already reflects the fix.

## Expected Outcome
- Room Browser on iPhone should now feel like a full-screen mobile overlay.
- Touches and swipes inside the Room Browser should no longer leak into camera movement.

## Remaining Validation
- Requires one more real-device retest on the two iPhones after publishing from the current cloud-attached Studio session.
