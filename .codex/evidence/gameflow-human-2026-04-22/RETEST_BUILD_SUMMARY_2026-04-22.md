# Retest Build Summary
Date: 2026-04-22
Place: _tmp_release_preflight_build.rbxlx

## Scope
- Single-client flow per map:
  - Lobby -> CreateRoom -> HostStart -> PreparationPhase -> by-door trigger -> InvestigationPhase
- Verified host-start countdown remained 5 seconds (observed range 1..5)
- Verified preparation spawn did not overlap `Room_*` volumes

## Results
- AbandonedPalace: PASS
  - countdownRange: 1..5
  - insideRooms: []
  - doorOpen: true
  - reachedInvestigation: true
- EmptyBuilding: PASS
  - countdownRange: 1..5
  - insideRooms: []
  - doorOpen: true
  - reachedInvestigation: true
- HauntedHouse: PASS
  - countdownRange: 1..5
  - insideRooms: []
  - doorOpen: true
  - reachedInvestigation: true
- StudioMMNineteen: PASS
  - countdownRange: 1..5
  - insideRooms: []
  - doorOpen: true
  - reachedInvestigation: true

## Notes
- Retest executed on fresh Studio instance attached to build output to ensure latest source patch was loaded.
- End-match was forced by player death after door transition to return cleanly to lobby for next map cycle.
