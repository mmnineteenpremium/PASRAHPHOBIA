# Multiclient Publish Smoke 2026-04-19

## Goal

- Re-run a fully fresh published smoke after closing all Roblox windows first.
- Validate lobby-panel parity between PC and Android.
- Eliminate the `LOBBY` vs `SpawnPlaza/SP` badge drift.

## Published Build Under Test

- PlaceId: `113010869463813`
- UniverseId: `9802743087`
- Published version: `526`

## Source Patch Applied Before Publish

- `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - added `SpawnPlaza` entry to `LOBBY_ZONE_ENTRY_COPY`
  - effect: server-published `LobbyZoneFocused` payload now sends friendly badge `LOBBY` instead of raw `SpawnPlaza`

## Fresh Boot Procedure

- closed Roblox Studio
- closed Roblox PC client
- terminated Android Roblox app
- rebuilt from source
- published fresh
- reopened PC player from `roblox://placeId=113010869463813`
- reopened Android from Roblox app game detail page and pressed play

## Results

### 1. PC published lobby

- fresh PC screenshot now shows:
  - `LOBBY PANEL`
  - badge `LOBBY`
  - glyph `LO`
  - `OPEN ROOM BROWSER`
  - `DAILY MISSIONS`
- evidence:
  - `.codex/evidence/published_pc_20260419_v526.png`

### 2. Android published lobby

- Android activity confirms game entered native runtime:
  - `com.roblox.client/.ActivityNativeMain`
- earlier `SpawnPlaza / SP` badge drift is no longer left to server/client race for `SpawnPlaza`; source now normalizes that lane to `LOBBY`
- mobile surface screenshot remains unreliable on this lane because the MCP screenshot sometimes captures stale overlay/page content while the active activity is already `ActivityNativeMain`

### 3. Room Browser follow-up

- OS automation on PC still did not visibly toggle `Room Browser` from the published client during this slice.
- evidence:
  - `.codex/evidence/published_pc_room_browser_20260419_v526.png`
  - `.codex/evidence/published_pc_room_browser_key_20260419_v526.png`

## Evidence

- PC:
  - `.codex/evidence/published_pc_20260419_v526.png`
  - `.codex/evidence/published_pc_room_browser_20260419_v526.png`
  - `.codex/evidence/published_pc_room_browser_key_20260419_v526.png`
- Android:
  - ADB focus / resumed activity:
    - `com.roblox.client/.ActivityNativeMain`

## Conclusion

- The concrete lobby-panel drift that produced `LOBBY` on one client and `SpawnPlaza/SP` on another is fixed in source and republished in version `526`.
- PC published lobby now reflects the normalized badge copy.
- Android enters Roblox native runtime, but visual verification through MCP screenshots is still partially unreliable on this device lane.
- Next bounded check should continue from published `Room Browser -> create room -> staging` with PC-host validation.

## Local Studio Follow-up

- A separate local Studio blocker was found in `Client.UI.Main`:
  - `Out of local registers when trying to allocate connectButtonPress: exceeded limit 200`
- Source fix reduced top-level local bindings and restored:
  - `LobbyUI`
  - `RoomBrowserUI`
- Lobby lighting stack was also reduced locally:
  - `Atmosphere` count in lobby runtime dropped from `2` to `1`
  - lobby `Brightness` dropped from `2.25` to `1.82`
  - counts stayed stable over `15s`, so idle lobby did not show effect growth after the fix
- Local evidence:
  - `.codex/evidence/lobby_lighting_after_vfx_tone_20260419.png`

## Follow-up - LobbySocialHub cleanup publish

### Source cleanup applied

- removed overlapping legacy center shell from `LobbySocialHub`:
  - `Wall_MainHubPlaza_North`
  - `Wall_MainHubPlaza_South`
  - `Wall_MainHubPlaza_East`
  - `Wall_MainHubPlaza_West`
  - `Roof_MainHubPlaza`
- rotated all four lobby `SpawnPoints.PlayerSpawn_*` to face the `Directory/Queue` approach
- retained `MainHubDecorRuntime` donor in source

### Fresh boot procedure

- closed Roblox Studio
- closed Roblox PC client
- terminated Android Roblox app
- rebuilt from source
- published fresh
- reopened PC player from `roblox://placeId=113010869463813`
- reopened Android from Roblox app detail page and pressed play

### Fresh published results

#### PC

- initial published spawn no longer faced a blank boxed wall
- published camera now opens toward `Lobby Directory / Queue` composition
- `LOBBY PANEL` still visible and normalized
- settled screenshot also shows right-side `DAILY MISSIONS`
- evidence:
  - `.codex/evidence/published_pc_player_post_lobby_cleanup_20260419.png`
  - `.codex/evidence/published_pc_player_post_lobby_cleanup_settled_20260419.png`

#### Android

- initial published spawn now matches the same open lobby center area as PC
- `MISSION` and `TRACKER` side buttons visible
- `Open Room Browser` succeeded and displayed `RUANG INVESTIGASI`
- evidence:
  - `.codex/evidence/published_android_lobby_post_cleanup_20260419.png`

#### Room Browser follow-up

- Android room browser opened successfully after the lobby cleanup publish
- PC OS-level click automation still did not visibly toggle room browser in this slice
- evidence:
  - `.codex/evidence/published_pc_room_browser_retry_20260419.png`

### Conclusion

- The lobby no longer boots into the central boxed-wall state on either PC or Android.
- Fresh published parity for the lobby spawn orientation is now materially improved across both clients.
- Remaining uncertainty is limited to PC automation opening `Room Browser`; the Android lane confirms the room browser path itself still works after the cleanup.
