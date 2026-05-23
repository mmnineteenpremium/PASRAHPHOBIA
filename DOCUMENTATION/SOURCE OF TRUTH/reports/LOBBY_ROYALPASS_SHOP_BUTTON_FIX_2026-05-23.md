# Lobby RoyalPass + Shop Button Fix - 2026-05-23

## Root Cause

`RoyalPassUI` and `ShopUI` were authored correctly as edit-safe UI shells, but the runtime bootstrap path could keep auxiliary `ScreenGui.Enabled` false. Because those ScreenGuis were disabled before the lobby button flow tried to display their panels, `RoyalPassButton` and `ShopButton` could bind successfully while still never producing visible panels.

## Fix

- `src/client/UI/Main.lua:6615` now treats every `AUXILIARY_UI_NAMES` ScreenGui as enabled at runtime bootstrap/apply time.
- `src/client/UI/Main.lua:6619` preserves lobby-only gating for non-auxiliary lobby windows while allowing auxiliary windows to stay enabled so their panels can be opened by state.
- `src/client/UI/Main.lua:6973` now gates auxiliary `MainPanel.Visible` from `_uiState[guiName].visible`, so enabled ScreenGuis do not automatically show their panels.
- `src/client/UI/Main.lua:8037` now sets authored auxiliary ScreenGuis to `Enabled=true` during runtime bootstrap while keeping `MainPanel.Visible=false`.

No authored StarterGui geometry, position, size, image, or JSON visibility defaults were edited in source.

## Play Test Results

Studio active file: `PASRAHPHOBIA.rbxlx`

1. Bootstrap `PlayerGui.RoyalPassUI.Enabled=true` and `PlayerGui.ShopUI.Enabled=true`: PASS.
2. Click `LobbyUI.MainPanel.RoyalPassButton`, `RoyalPassUI.MainPanel` appears and is effectively visible: PASS.
3. `RoyalPassUI` shows `RewardTab` and `MissionTab` with non-blank `BrandTextImage` IDs: PASS.
   - RewardTab image: `rbxassetid://91316576845536`
   - MissionTab image: `rbxassetid://91316576845536`
4. Click `RoyalPassUI.MainPanel.CloseButton`, panel closes: PASS.
5. Click `LobbyUI.MainPanel.ShopButton`, `ShopUI.MainPanel` appears: PASS.
6. `ShopUI` shows filter bar and item list: PASS.
   - Visible item rows detected: 31.
7. Click `ShopUI.MainPanel.CloseButton`, panel closes: PASS.

## Studio Save

`PASRAHPHOBIA.rbxlx` LastWriteTime after final save:

`2026-05-23 22:46:38 +07:00`

## Output Notes

No RoyalPass/Shop button blocker error appeared in Output during this Play Test. Existing unrelated Output entries included Studio style `CornerRadius` cast warnings, one thumbnail-size warning, and an AutoRecovery save-in-progress warning.
