# PASRAHPHOBIA Progress Report

## Session Append — 2026-03-20

### Room Browser + Lobby Routing
- Fixed server receive path for `LobbyEvent` and stabilized bridge/fallback flow.
- Added payload format compatibility (`request.action` table format).
- Added anti-duplicate request guard (`requestId` + server dedupe window) to reduce double trigger risk.

### Room Flow
- Create/Join/Leave/Ready/HostStart/Cancel flow is active.
- Countdown flow works and reaches match start path.
- Teleport pipeline confirmed using `ServerStorage.Maps`.

### UI/UX Room Browser
- Added floating toggle button (`RUANG INVESTIGASI`) and default hidden on spawn.
- Auto-hide Room Browser UI during match (`InMatch` / `MatchStarted`).
- Added mode behavior:
  - `Ranked` uses auto difficulty (level/tier based).
  - `Classic` keeps full difficulty selection.
- Added room member list rendering inside room panel.
- Added quick actions:
  - `JOIN` (selected room).
  - `QUICK CLASSIC` (most populated classic room).
  - `QUICK RANKED` (most populated ranked room).
- Added placeholder preview block:
  - map placeholder (classic).
  - ranked placeholder.

### Password + Kick
- Password enforcement active on server fallback join path.
- `SetPassword` enabled for host (4-digit validation).
- Join protected room now uses password popup flow.
- Added host kick capability:
  - server handling for `KickPlayer`.
  - per-player inline `KICK` button in room player list (host only).
- Added kicked player feedback popup: `ANDA TELAH DI KICK`.

### Current Notes
- Room listing cross-client now updates after create/join/leave/ready.
- Selection reset issue (Ranked/Classic flipping back) fixed by persisting fallback selections server-side.

## Session Append — 2026-03-20 (Patch: In-Game Room Visibility + PC Cursor)

### Public Room List During Match
- Changed fallback room lifecycle so room is **not removed** from public list after `HostStart` succeeds.
- Room state remains visible as `IN GAME` (red) for other clients.
- Join remains blocked by server when `room.isCountingDown == true` or `room.inGame == true`.

### Join Block UX
- Added explicit popup for in-progress match join attempt:
  - `PERMAINAN SEDANG BERLANGSUNG`
- Applied both on:
  - server reject event (`RoomBrowserRoomJoinFailed` with `room_in_game`)
  - client-side early guard when selected room is `IN GAME`/`COUNTDOWN`.

### PC Camera/Cursor Fix (FPV -> Lobby)
- Updated camera mode transition handling:
  - Match FPV: lock center + hide icon.
  - Lobby TPV: restore default mouse behavior + show icon.
- This prevents cursor staying locked at screen center after returning from match.

### Files Updated
- `src/ServerScriptService/Server/Lobby/LobbyEventHandler.lua`
- `src/client/UI/Main.lua`
- `src/client/CameraController.client.lua`
