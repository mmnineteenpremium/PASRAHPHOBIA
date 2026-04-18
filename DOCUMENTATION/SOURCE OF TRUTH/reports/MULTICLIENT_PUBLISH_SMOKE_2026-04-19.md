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
