# RoyalPass Tier Render Fix - 2026-05-23

## Bug

RoyalPass panel could open only after the previous bootstrap fix was present in Studio, but the active `PASRAHPHOBIA.rbxlx` session still had a stale `Main.lua` slice for RoyalPass tier rendering. The source branch already had the authored HeroCard contract, but Studio needed a retry sync for the client script and active `StarterGui.RoyalPassUI` shell.

## Step 2 Source Verification

- `src/client/UI/Main.lua` auxiliary authored bootstrap has `gui.Enabled = true` at line 8082.
- `src/client/UI/Main.lua` DayCard creation uses `ROYAL_PASS_TOTAL_TIERS = 60`; both DayCard loops are now 60-tier loops at lines 7658 and 13968.
- `src/StarterGui/RoyalPassUI.model.json` HeroCard contains `ProgressTrack`, `ProgressFill`, `ProgressCaption`, and `PremiumActionButton`.

Rojo check:

- `.\.aftman\bin\rojo.exe sourcemap default.project.json`: PASS.

## Studio Sync

Active Studio instance: `PASRAHPHOBIA.rbxlx`

Synced/verified:

- `StarterPlayer.StarterPlayerScripts.Client.UI.Main` has the bootstrap `Enabled=true` logic, the 60-tier constants, and both DayCard loops using `ROYAL_PASS_TOTAL_TIERS`.
- `StarterGui.RoyalPassUI.MainPanel.ContentFrame.RoyalPassDeck.HeroCard` has `ProgressTrack`, `ProgressFill`, `ProgressCaption`, and `PremiumActionButton`.

## Play Test Results

1. Bootstrap: `PlayerGui.RoyalPassUI.Enabled=true` at Play start: PASS.
2. Click `LobbyUI.MainPanel.RoyalPassButton`; `RoyalPassUI.MainPanel.Visible=true`: PASS.
3. HeroCard visible with `ProgressTrack` and `PremiumActionButton`: PASS.
4. `TrackScroller` has DayCards: PASS, 60 cards formed.
5. DayCard first cards show tier/day number text: PASS (`DAY 01`, `DAY 02`, `DAY 03` observed).
6. Scroll to end shows about 60 cards: PASS, `cardCount=60`, canvas scrolled near end.
7. MissionTab click changes view: PASS, first card title changed to `DAILY QUEST 01`.

Milestone smoke:

- Cards 5, 10, 20, 30, and 60 had thicker milestone stroke in Studio runtime.

Output Studio:

- No RoyalPass runtime error observed during this Play Test.
- Existing unrelated warnings: `Failed to apply StyleRule property 'CornerRadius' from '>> .RoundedCorner8 ::UICorner': Unable to cast string to UDim`.

## Studio Save

`PASRAHPHOBIA.rbxlx` LastWriteTime after final save:

`2026-05-23 23:32:07 +07:00`
