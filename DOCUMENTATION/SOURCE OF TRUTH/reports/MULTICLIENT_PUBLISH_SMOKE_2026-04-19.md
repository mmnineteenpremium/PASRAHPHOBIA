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

## Follow-up - trace-free publish and lobby glow reduction

### Scope

- removed temporary room-browser trace forcing from source
- preserved the mobile room-browser spacing / `ZIndex` fix
- reduced lobby decor point-light intensity and guide billboard brightness
- republished again from a fully closed Studio + PC + Android state

### Fresh published results

#### PC

- `LOBBY PANEL` stays normalized as `LOBBY / LO`
- center lobby glow is lower than the prior publish
- evidence:
  - `.codex/evidence/pc_fresh_after_trace_cleanup_20260419.png`
  - `.codex/evidence/pc_lobby_after_lighting_patch_20260419_c.png`

#### Android

- `LOBBY PANEL` stays normalized as `LOBBY / LO`
- `MISSION` and `TRACKER` side buttons are visible on fresh spawn
- center lobby glow is lower than the prior publish

### Conclusion

- The current published lobby is cleaner from a systems / presentation perspective:
  - no forced room trace instrumentation
  - mobile room-browser fix preserved
  - lower lobby glow on both clients
- The remaining unresolved slice is no longer UI mismatch, but the underlying `LobbySocialHub` content still being visually sparse because the current authoritative donor itself is sparse.

## Follow-up - Batch B-G runtime smoke (2026-04-19, PC + Android)

### Environment gate

- `scripts/resolve-mobile-mcp-stack.ps1 -Strict` failed because the script still expects legacy emulator aliases (`Samsung-NOTE10`, `S22-ultra`) not present in this lane.
- `scripts/require-mobile-lane.ps1 -Lane both` failed due missing `iPhone-14-Pro-Max`.
- `scripts/require-mobile-lane.ps1 -Lane android` passed (`Samsung-N960` / `266a038c0a017ece` ready).

### Publish under test

- command:
  - `powershell -ExecutionPolicy Bypass -File scripts\Invoke-Rojo.ps1 upload --api_key $env:ROBLOX_OPEN_CLOUD_API_KEY --asset_id 113010869463813 --universe_id 9802743087 default.project.json`
- result: exit code `0`.

### 2-client fresh boot

- PC launched via:
  - `roblox://placeId=113010869463813`
- Android launched via ADB deep link:
  - `roblox://placeId=113010869463813`
- both clients reached published lobby.

### Android host flow

- `OPEN ROOM BROWSER`: success (`RUANG INVESTIGASI` rendered).
- `BUAT ROOM`: success (host room panel rendered, `MULAI PERMAINAN` visible).
- host start trigger (`MULAI PERMAINAN`) moved runtime into in-match loading/match panel overlay (`Masuk ke lokasi...`, map target `Haunted House`).

### Host-start countdown verification

- source lock remains:
  - `HOST_START_COUNTDOWN_SECONDS = 5` in lobby controller/service paths.
- no `30s` host-start countdown lane was observed in this smoke pass.
- countdown numeral (`5..1`) was not captured as a stable on-screen frame in this automation slice because transition moved quickly to loading overlay.

### PC follow-up

- PC OS-level click/keypress automation still did not visibly toggle Room Browser in this slice (known automation limitation lane).

### Evidence

- `.codex/evidence/pc_publish_smoke_20260419_lobby_boot.png`
- `.codex/evidence/android_publish_smoke_20260419_lobby_boot.png`
- `.codex/evidence/android_publish_smoke_20260419_room_created.png`
- `.codex/evidence/android_publish_smoke_20260419_after_host_start_loading.png`
- `.codex/evidence/pc_publish_smoke_20260419_after_android_start.png`
- `.codex/evidence/pc_publish_smoke_20260419_room_browser_toggle.png`
- `.codex/evidence/pc_publish_smoke_20260419_after_open_room_click.png`
- `.codex/evidence/android_publish_smoke_20260419_countdown.mp4`
- `.codex/evidence/android_publish_smoke_20260419_countdown_pass2.mp4`

### Conclusion

- manual blocker `smoke test 2 client nyata` for `PC + Android` was executed on the latest publish lane.
- iOS lane was not executable in this session due missing `iPhone-14-Pro-Max`.

## Follow-up - PC extended-display window-click validation (2026-04-19)

### Goal

- Run the PC Room Browser click flow with strict window targeting on extended dual-monitor setup.
- Ensure click is sent to the actual Roblox Player window, not Roblox Studio or other windows.

### Monitor topology

- `DISPLAY1` (extended): `X=-844, Y=-1440, Width=3440, Height=1440`
- `DISPLAY2` (primary): `X=0, Y=0, Width=1536, Height=864`
- Active Roblox Player window under test:
  - process: `RobloxPlayerBeta`
  - `WindowPid=44888`
  - resolved display: `DISPLAY2` (primary)
  - client bounds during test: `Left=84, Top=107, Width=801, Height=600`

### Method

- forced all actions by explicit `WindowPid=44888` (no title-pattern fallback):
  - capture baseline
  - click on `OPEN ROOM BROWSER` button area
  - click on top-left Roblox menu icon
  - click on `DAILY MISSIONS` close button
  - keyboard injection (`{ESC}`)
- additional click lanes tested:
  - message-based click (`PostMessage WM_LBUTTONDOWN/UP`) directly to HWND
  - `SendInput` left-click after setting cursor to exact client->screen coordinates

### Result

- no visual state change was observed on PC for all synthetic input methods above.
- `OPEN ROOM BROWSER` remained closed in every after-capture frame.
- because the window PID, foreground focus, display target, and coordinates were all verified, this slice is **not** caused by wrong monitor/window selection.

### Evidence

- `.codex/evidence/pc_extdisplay_pid44888_before_click.png`
- `.codex/evidence/pc_extdisplay_pid44888_after_click1.png`
- `.codex/evidence/pc_extdisplay_pid44888_after_multiclick.png`
- `.codex/evidence/pc_extdisplay_pid44888_after_topmenu_click.png`
- `.codex/evidence/pc_extdisplay_pid44888_after_daily_x_click.png`
- `.codex/evidence/pc_extdisplay_pid44888_after_sendinput_click.png`
- `.codex/evidence/pc_extdisplay_pid44888_after_postmessage_click.png`
- `.codex/evidence/pc_extdisplay_pid44888_after_esc.png`

### Conclusion

- PC automation gap remains specific to synthetic input acceptance in Roblox Player on this machine/session.
- Android lane remains valid for Room Browser create/start validation.
