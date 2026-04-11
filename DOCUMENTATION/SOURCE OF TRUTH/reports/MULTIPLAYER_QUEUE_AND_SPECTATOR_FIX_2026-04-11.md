# Multiplayer Queue And Spectator Fix - 2026-04-11

## Summary
- Fixed two server-side blockers found during the first real iPhone multiplayer run:
  - the lobby `Queue Hub` prompt opened the queue path directly instead of behaving like a room-browser entry point
  - spectator handling could be entered more than once across overlapping systems
- Verified the patched scripts are present in the cloud-attached Studio session for the canonical published place:
  - `PlaceId = 113010869463813`
  - `GameId = 9802743087`
- This closes the code-side root causes. Final device retest is still required before the multiplayer publish gate can be marked PASS.

## Trigger
Owner reported these real-device symptoms after publish:

1. no usable `Create Room` flow; entering lobby could jump straight to `Prepare Matching`
2. two players synced during prepare/tools/hunt, but did not behave correctly as a clean room-driven multiplayer flow
3. when one player died, spectator mode did not settle correctly and could fall into a death-loop/falling-loop pattern

UI mismatch from the device screenshot was noted, but it was explicitly deprioritized as a non-blocker for this pass.

## Root Causes

### 1. Queue Hub prompt was wired to queue immediately
- File: `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
- Previous world prompt behavior:
  - prompt text said `Join Queue`
  - pressing the prompt called `lobbyController:OnQueueFromRoomBrowser(...)`
- Effect:
  - device flow could bypass the intended `create room -> join room -> ready -> host start` lane
  - this matched the real-device symptom where the game appeared to jump directly into `Prepare Matching`

### 2. Spectator mode had overlapping entry paths
- Files:
  - `src/ServerScriptService/Server/SpectatorModeSystem/Service.lua`
  - `src/ServerScriptService/Server/SpectatorSystem/Controller.lua`
  - `src/ServerScriptService/Server/SpectatorSystem/SpectatorService.lua`
- Problem:
  - `SpectatorModeSystem` already emitted `SpectatorModeStarted`
  - old `SpectatorSystem.Controller` still called `EnterSpectator(...)` directly on `PlayerKilled`
  - `SpectatorSystem` did not mirror `SpectatorModeEnded`
- Effect:
  - spectator session could be entered twice or left in an inconsistent state
  - this was a credible root cause for the death-loop / spectator-desync symptom on device

## Code Changes

### Queue Hub
- File: `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
- Changes:
  - changed prompt action text from `Join Queue` to `Open Room Browser`
  - changed `QueueTrigger` callback from:
    - `OnQueueFromRoomBrowser(...)`
  - to:
    - `OnRequestRoomBrowserSnapshot(...)`
  - updated the published world-event text to direct players toward room-browser actions instead of queue activation

### Spectator Deduplication
- File: `src/ServerScriptService/Server/SpectatorModeSystem/Service.lua`
- Changes:
  - `_registerSpectator(...)` now returns early if the spectator is already active for the same match/user
  - `_removeSpectator(...)` now only publishes `SpectatorModeEnded` if the spectator was actually active

### Old Spectator Path Cleanup
- File: `src/ServerScriptService/Server/SpectatorSystem/Controller.lua`
- Changes:
  - removed the direct `self._service:EnterSpectator(player, matchId, payload)` call from `OnPlayerKilled(...)`
  - retained ghost activity processing

### Spectator Exit Mirroring
- File: `src/ServerScriptService/Server/SpectatorSystem/SpectatorService.lua`
- Changes:
  - subscribed to `SpectatorModeEnded` and now calls `ExitSpectator(...)`
  - added idempotence inside `EnterSpectator(...)` so an existing spectator session is reused instead of rebuilt

## Live Studio Verification
- Studio state remained in edit mode after verification; no play test was left running.
- Verified directly against the cloud-attached Studio scripts:
  - `LobbyService` line `2499` now contains:
    - `Open Room Browser`
  - `LobbyService` lines `5031-5045` now call:
    - `OnRequestRoomBrowserSnapshot(...)`
  - `SpectatorSystem.Controller` no longer calls `EnterSpectator(...)` inside `OnPlayerKilled(...)`
  - `SpectatorSystem.SpectatorService` now subscribes to `SpectatorModeEnded`

## Interpretation
- The server-side flow is now aligned with the intended multiplayer lane:
  - `open room browser`
  - `create room`
  - `join room`
  - `ready`
  - `host start`
- The old spectator double-entry path has been neutralized.
- Remaining uncertainty is no longer in the patched source itself. It is now in the real-device retest outcome.

## Status
- queue-flow blocker in source: PASS
- spectator duplicate-entry blocker in source: PASS
- cloud Studio sync verification: PASS
- note:
  - this report captured the code-side fix before the retest was executed
  - the final real `2`-client multiplayer gate was later closed as `PASS` in:
    - `DOCUMENTATION/SOURCE OF TRUTH/reports/QA_MULTIPLAYER_RESULT_2026-04-09_PREP.md`
