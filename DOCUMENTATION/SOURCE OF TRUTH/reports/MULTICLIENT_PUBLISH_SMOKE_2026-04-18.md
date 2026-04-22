# Multiclient Publish Smoke 2026-04-18

## Goal

- Re-run fresh published smoke after ghost/tool source-of-truth lock.
- Validate:
  - PC RobloxPlayer boot
  - Android Roblox boot
  - lobby parity
  - room browser
  - room creation
  - transition to preparation staging

## Published Build Under Test

- PlaceId: `113010869463813`
- UniverseId: `9802743087`
- Publish lane: `default.project.json`

## Fresh Client Boot

- PC relaunched clean into:
  - `roblox://placeId=113010869463813`
- Android relaunched clean into:
  - `https://www.roblox.com/games/113010869463813`
  - then entered runtime via Roblox app play button

## Results

### 1. Cross-client lobby parity

- PC and Android now boot into the same published lobby state.
- This removes the earlier stale-session confusion and confirms the published runtime itself is the current problem.

### 2. Lobby visual state

- The published `LobbySocialHub` is still blockout/low-poly.
- The current published lobby visually matches the current source lane rather than the expected richer/finalized lobby.
- Coordinates are still in the expected lobby region around `x ~= 1600`.

### 3. Room Browser

- Android:
  - `Room Browser` is confirmed opening correctly.
  - Room list/preview panel renders.
  - `Buat Room` works.
- PC:
  - `Room Browser` has not yet been proven through current OS click automation.
  - Runtime itself is alive, but current automated click attempts did not visibly toggle the room browser panel.

### 4. Match start / preparation staging

- Android successfully:
  - created room
  - entered room panel
  - started match
  - reached preparation staging
- Staging text shown live:
  - `Review board luar sebelum`
  - `Preparation aktif di staging luar.`
  - `Review CONTRACT / OBJECTIVES / TOOLS di staging luar, lalu aktifkan BREACH di MAIN ENTRY.`

## Player Log Findings

- Fresh PC player log shows no obvious `LobbySocialHub` startup crash.
- This points away from a lobby service boot failure and toward the published/source lobby content itself.
- Fresh player log still shows unauthorized audio asset failures for:
  - `412892754`
  - `188608071`
  - `3225480278`
  - `510111269`
  - `1013366831`

## Evidence

- PC:
  - `.codex/evidence/pc_fresh_launch.png`
  - `.codex/evidence/pc_after_boot_wait.png`
  - `.codex/evidence/pc_room_browser_after_click.png`
  - `.codex/evidence/pc_after_android_create_room.png`
  - `.codex/evidence/pc_after_android_start.png`
- Android:
  - fresh published lobby screenshot
  - room browser screenshot
  - room-created screenshot
  - preparation staging screenshot

## Conclusion

- Match flow is not fully dead.
- Published runtime still has two primary gaps:
  - `LobbySocialHub` is still the wrong visual/source lane
  - PC-host room-browser interaction still needs direct verification
