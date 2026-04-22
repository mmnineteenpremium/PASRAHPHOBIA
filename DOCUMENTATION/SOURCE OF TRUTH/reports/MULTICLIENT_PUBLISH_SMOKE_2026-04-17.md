# Multiclient Publish Smoke 2026-04-17

## Goal
- Run one publish cycle, then smoke test 2 live clients:
  - PC RobloxPlayer as room host side
  - Android (SM-N960U) as joiner side

## Publish
- Studio state before publish: disconnected/closed (no active studio attached through MCP).
- Publish command executed:
  - `powershell -ExecutionPolicy Bypass -File scripts\Invoke-Rojo.ps1 upload --api_key <env> --asset_id 113010869463813 --universe_id 9802743087 default.project.json`
- Result: command completed with exit code `0`.

## 2-Client Boot Proof
- PC launched:
  - `Start-Process "roblox://placeId=113010869463813"`
  - RobloxPlayer process observed with window title `Roblox`.
- Android launched:
  - `adb shell am start -a android.intent.action.VIEW -d "roblox://placeId=113010869463813"`
  - foreground verified:
    - `mCurrentFocus=... com.roblox.client/com.roblox.client.ActivityNativeMain`

## Evidence Files
- PC in-lobby capture:
  - `.codex/evidence/pc_client_after_publish.png`
  - `.codex/evidence/pc_client_after_publish.json`
- Android in-lobby capture:
  - `.codex/evidence/android_client_after_publish.png`

## Host/Join Room Attempt
- Action attempted on both clients:
  - click/tap `OPEN ROOM BROWSER` from lobby panel.
- Result:
  - no visible room-browser panel transition on both PC and Android in this smoke run.

## Blocker
- Required host/join validation could not be completed because `OPEN ROOM BROWSER` did not transition to expected room-browser state during automated click/tap.
- Next lane is logic/UI debug on room-browser trigger path before repeating host/join validation.

## Re-Run 2026-04-17 16:51 ICT
- Publish cycle repeated from branch `final-source-of-truth`.
- Commands:
  - `powershell -ExecutionPolicy Bypass -File scripts\Invoke-Rojo.ps1 sourcemap default.project.json`
  - `powershell -ExecutionPolicy Bypass -File scripts\Invoke-Rojo.ps1 upload --api_key <env> --asset_id 113010869463813 --universe_id 9802743087 default.project.json`
- Result: upload exit code `0`.

## Re-Run 2-Client Smoke
- PC client relaunched and confirmed running:
  - `RobloxPlayerBeta` with window title `Roblox`.
- Android client relaunched and confirmed foreground:
  - `mCurrentFocus=... com.roblox.client/com.roblox.client.ActivityNativeMain`.
- New evidence:
  - `.codex/evidence/pc_publish_test_20260417_165137.png`
  - `.codex/evidence/pc_after_room_browser_tap_20260417_165204.png`
  - Android live screenshot captured after tap attempt.

## Re-Run Result
- Both clients successfully boot to lobby after publish.
- Tap on `OPEN ROOM BROWSER` (Android coordinate input) still did not show visible room-browser transition in screenshot state.
