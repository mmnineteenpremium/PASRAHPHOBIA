# Human Gameflow Test Report (Studio)
Date: 2026-04-22
Workspace: final-source-of-truth

## Scope
- Single-player manual flow per map from lobby:
  1. Open Room Browser
  2. Create room
  3. Select map
  4. Host start
  5. Validate Preparation/Staging active
  6. Select tool (PreparationFocusTool)
  7. Trigger breach/door to move phase

Notes:
- Map selection for non-default maps was sent through the same RoomBrowser remote action (`SelectMap`) after UI click automation for dropdown was unreliable in this tooling session.
- Screenshots include sidecar JSON metadata from `window-automation.ps1`.

## Result Summary
- HauntedHouse: PASS to InvestigationPhase
- StudioMMNineteen: PASS to InvestigationPhase
- AbandonedPalace: FAIL (returns to lobby with match result; playersDead=1 before reaching InvestigationPhase)
- EmptyBuilding: FAIL (returns to lobby with match result; playersDead=1 before reaching InvestigationPhase)

## Evidence Files
- HauntedHouse
  - HH_fix_01_start_clicked.png/.json
  - HH_fix_02_preparation_breach_enabled.png/.json
  - HH_fix_03_investigation_after_breach.png/.json
- StudioMMNineteen
  - SMN_01_map_selected.png/.json
  - SMN_02_preparation_breach_enabled.png/.json
  - SMN_03_investigation_after_breach.png/.json
- AbandonedPalace
  - AP_01_map_selected.png/.json
  - AP_02_preparation_breach_enabled.png/.json
  - AP_03_back_to_lobby_after_door.png/.json
- EmptyBuilding
  - EB_01_map_selected.png/.json
  - EB_02_preparation_breach_enabled.png/.json
  - EB_03_back_to_lobby_after_breach.png/.json

## Runtime Snapshots (key)
- AbandonedPalace failed run
  - InLobby=true
  - PasrahMatchResultPlayersDead=1
  - PasrahMatchResultDuration=59
  - PasrahMatchResultLastEvent=MatchEnded
- EmptyBuilding failed run
  - InLobby=true
  - PasrahMatchResultPlayersDead=1
  - PasrahMatchResultDuration=33
  - PasrahMatchResultLastEvent=MatchEnded

## Retest Update (2026-04-22, built place)
- Retest executed on `_tmp_release_preflight_build.rbxlx` (fresh Studio instance with latest source patch).
- Flow per map: `Lobby -> CreateRoom -> HostStart (countdown 5s) -> PreparationPhase -> by-door transition -> InvestigationPhase`.

### Retest Summary
- AbandonedPalace: PASS (`insideRooms=[]`, `doorOpen=true`, reached `InvestigationPhase`)
- EmptyBuilding: PASS (`insideRooms=[]`, `doorOpen=true`, reached `InvestigationPhase`)
- HauntedHouse: PASS (`insideRooms=[]`, `doorOpen=true`, reached `InvestigationPhase`)
- StudioMMNineteen: PASS (`insideRooms=[]`, `doorOpen=true`, reached `InvestigationPhase`)

### Key Runtime Assertions
- Host-start countdown observed range stayed `1..5` on all map runs.
- Preparation spawn no longer overlaps `Room_*` volumes for all tested maps.
- No 30-second host-start countdown path observed.
