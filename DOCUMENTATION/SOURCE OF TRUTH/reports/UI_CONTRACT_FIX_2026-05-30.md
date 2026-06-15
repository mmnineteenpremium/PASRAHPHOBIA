# UI Contract Fix Report - 2026-05-30

## Scope
- `RoomBrowserUI`
- `ShopUI`
- `RoyalPassUI`

## Root Cause
- `RoomBrowserUI` action buttons were rendered below `RoomPanel`.
- `RoomPanel.ZIndex = 12` while the action buttons were still at `ZIndex = 2` and `CloseButton` at `ZIndex = 8`.
- Result: clicks landed on the scrolling frame layer, not on the buttons, so `Activated` never fired.
- `ShopUI` used `ImageLabel` for item preview, which could not host the viewport contract required by `Main.lua`.
- `LobbyUI` binding raced startup: the GUI could exist in `PlayerGui` before all authored button contracts were ready, so `connectButtonPress(...)` never attached and every child button stayed unbound.

## Fix Applied
- Raised the RoomBrowser action buttons above `RoomPanel`:
  - `CloseButton`
  - `ClassicButton`
  - `AllModesButton`
  - `RankedButton`
  - `RefreshButton`
  - `CreateRoomButton`
  - `QueueButton`
  - `QuickJoinClassicButton`
  - `QuickJoinRankedButton`
- Converted `ShopUI.MainPanel.ContentFrame.ItemList.ItemRowTemplate.Preview.PreviewImage` to `ViewportFrame`.
- Disabled preview input on Shop preview:
  - `Active = false`
  - `Selectable = false`
  - `Interactable = false`
- Kept RoyalPass authored preview contract on `ViewportFrame CosmeticPreview`.
- Added a retry gate for authored `LobbyUI` binding so setup re-runs until the toggle and header buttons are actually wired.

## Verification
- Live Studio now reports:
  - `RoomPanel = 12`
  - `CreateRoomButton = 13`
  - `Shop PreviewImage = ViewportFrame`
- `ShopPreviewSupport.render(...)` is present and require-able.
- No parent/child renames were needed for these fixes.
- `LobbyUI` now retries binding instead of depending on a single startup pass.

## Guardrail
- Do not change parent/child structure or pattern naming unless the matching code contract is updated in the same change.
- Visual-only changes are safe when they do not alter contract:
  - `Size`
  - `Position`
  - `AssetId`
  - `Text`
  - `Color`
  - `LayoutOrder`
  - `ZIndex` only if stacking is intentionally managed
- If a container class changes, update the local `*.model.json` and the Lua binding together.
