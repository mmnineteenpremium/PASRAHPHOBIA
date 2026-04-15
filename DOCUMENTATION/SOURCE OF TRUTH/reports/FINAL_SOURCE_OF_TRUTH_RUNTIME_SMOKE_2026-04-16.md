# Final Source Of Truth Runtime Smoke 2026-04-16

## Trigger

Owner requested a full live Studio smoke on branch `final-source-of-truth` with Rojo connected, with explicit focus on:

- bootstrap stability
- falling loop / spawn prep
- room browser `buat room -> start`
- countdown and phase transition
- audio continuity
- results and return-to-lobby
- mobile-first landscape surfaces for human visual smoke

## Root Cause

### 1. Falling loop and dead room flow

- bootstrap failed in `SocialCommerceSystem` because runtime could not resolve `Service`
- source file existed as `src/ServerScriptService/Server/SocialCommerceSystem/Service.Lua`
- Rojo runtime did not expose that module as expected, so `SystemRegistry` aborted before lobby ownership finished
- impact:
  - player spawned into `Freefall`
  - room browser flow looked partially alive on client but server-side room lifecycle was effectively broken

### 2. Results audio cut back to lobby too early

- `ResultsPanel` could remain visible after `ReturnedToLobby`
- previous `AudioController` only keyed results BGM from hold-state timing
- impact:
  - results surface was visible
  - lobby ambient resumed too early
  - `bgm_gameover` never owned the result window consistently

### 3. Quest surface ignored Studio mobile override lane

- `QuestJournal` and `QuestTracker` only trusted raw `UserInputService.TouchEnabled`
- canonical Studio smoke for mobile uses:
  - `ReplicatedStorage.PasrahUIInputProfileOverride = mobile`
  - `PasrahUIViewportOverrideX/Y`
  - `PasrahUIForceCompact`
- impact:
  - room browser followed mobile-wide canonical behavior
  - quest surfaces stayed in desktop-like sizing/text during the same smoke lane

## Code Changes

### Bootstrap / lobby recovery

- normalized source file name:
  - `src/ServerScriptService/Server/SocialCommerceSystem/Service.Lua`
  - to `src/ServerScriptService/Server/SocialCommerceSystem/Service.lua`
- hardened module resolution in:
  - `src/ServerScriptService/Server/SocialCommerceSystem/Main.lua`
  - added case-insensitive module child fallback

### Results audio ownership

- updated:
  - `src/client/Controllers/Sensory/AudioController.luau`
- behavior now:
  - `ResultsBGM` stays active while `ResultsPanel.Visible = true`
  - `LobbyAmbient` is suppressed while results surface is still visible
  - debug attrs now clearly show:
    - `PasrahResultsBgmActive`
    - `PasrahResultsBgmSoundId`
    - `PasrahLobbyAmbientSuppressedByResults`

### Mobile quest surface alignment

- updated:
  - `src/client/UI/QuestJournal.lua`
  - `src/client/UI/QuestTracker.lua`
- behavior now:
  - quest surfaces honor:
    - `PasrahUIInputProfileOverride`
    - `PasrahUIViewportOverrideX`
    - `PasrahUIViewportOverrideY`
    - `PasrahUIForceCompact`
  - `QuestJournal` open CTA changes to `MISSION` on mobile override
  - journal/tracker sizing now compresses into the same mobile-wide Studio lane used by room browser smoke

## Studio Runtime Verification

Environment:

- Studio file:
  - `PASRAHPHOBIA.rbxlx`
- branch:
  - `final-source-of-truth`
- Rojo:
  - connected during runtime smoke

### A. Bootstrap and spawn

Initial failing state before fix:

- `state = Freefall`
- `floor = Air`
- bootstrap stopped on `SocialCommerceSystem`

Passing state after fix:

- `state = Running`
- `floor = Concrete`
- spawn landed in lobby at `1610, 3.47, -10`
- console showed:
  - `All systems started`
  - `Boot completed`
  - `LobbyPlayerManager [Init] Spawn scan OK`

### B. Room browser flow

Verified live:

- `Open Room Browser`: PASS
- `BUAT ROOM`: PASS
- host room panel visible:
  - `RoomTitle = RUANG #1`
- host start button path:
  - `MULAI PERMAINAN`
  - then `BATALKAN COUNTDOWN`
- match advanced:
  - `PreparationPhase`
  - then `InvestigationPhase`

### C. Audio

Verified live:

- lobby:
  - `LobbyAmbient` playing
- preparation:
  - `LobbyAmbient` fades out
  - `PreparationAmbient` plays
- results:
  - `ResultsPanelVisible = true`
  - `ResultsBGM` playing at `0.20`
  - `LobbyAmbientSuppressedByResults = true`

### D. Mobile-wide canonical override

Applied:

- `PasrahUIInputProfileOverride = mobile`
- `PasrahUIViewportOverrideX = 844`
- `PasrahUIViewportOverrideY = 390`
- `PasrahUIForceCompact = true`

Verified live:

- room browser:
  - panel `844 x 390`
  - `QuickJoinClassic = false`
  - `QuickJoinRanked = false`
- quest journal:
  - open text `MISSION`
  - open button `120 x 38`
  - panel `760 x 372`
- quest tracker:
  - `248 x 198`

## Status

- bootstrap stability: `PASS`
- falling loop: `PASS`
- lobby spawn authority: `PASS`
- room browser create/start flow: `PASS`
- countdown to preparation/investigation: `PASS`
- results surface: `PASS`
- return to lobby: `PASS`
- results BGM ownership: `PASS`
- mobile-wide room browser smoke: `PASS`
- mobile-wide quest surface smoke: `PASS`
- real multi-client publish smoke on this branch: `PENDING`

## Extended Single-Player Smoke

Follow-up live smoke on the same branch also verified:

- manual mobile-first room flow remained stable after restart:
  - `OPEN ROOM BROWSER`
  - `BUAT ROOM`
  - `MULAI PERMAINAN`
  - staging countdown
  - investigation entry
- hunt surface is visible in-match:
  - `HUNT` overlay appears
  - safe-zone guidance appears on screen
- sensory cues are alive:
  - `env_lightflicker`
  - `env_objectthrow`
  - `ghost_whisper`
- Pocong evidence chain is readable for a human player:
  - `SCAN -> EMF 5 / MEDOK LOCK`
  - `THERMO -> -5C / SUHU LOCK`
  - `WRITING -> WRITE / INK LOCK`

### Follow-up fixes applied during extended smoke

- `src/client/UI/Main.lua`
  - fixed `WritingScratch` cue so cursed-writing confirmation now plays a runtime UI sound again
  - fixed field-kit response extraction so nested `result.evidenceType` is only merged into HUD state when the tool response is actually valid or `already_collected`
  - prevented false evidence lock surfaces caused by transient failure reasons such as `tool_pending_delay`

### Extended smoke status

- hunt visibility: `PASS`
- ghost whisper cue: `PASS`
- light flicker cue: `PASS`
- object disturbance cue: `PASS`
- writing scratch cue: `PASS`
- false thermo evidence lock after payload fix: `PASS`

## Conclusion

`final-source-of-truth` is no longer blocked by the bootstrap/falling-loop/runtime regressions found at the start of this smoke cycle.

The branch now passes the single-client live Studio smoke gates that matter for human visual verification:

- stable lobby arrival
- intended room creation lane
- countdown and phase transitions
- results visibility
- results audio continuity
- mobile-wide UI readability for both room browser and quest surfaces
