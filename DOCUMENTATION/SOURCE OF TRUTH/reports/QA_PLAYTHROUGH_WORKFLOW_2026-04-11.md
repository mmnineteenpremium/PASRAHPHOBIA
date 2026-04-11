# QA Playthrough Workflow 2026-04-11

## Scope

Single-player live Studio playthrough to understand the **actual player workflow**, first-impression clarity, and early-session friction as experienced moment to moment.

This is not a system-only review. It is a player-experience read.

Environment:

- canonical cloud-attached Studio session
- `PlaceId = 113010869463813`
- Studio test started and then returned to `STOP TEST`

## Explicit Runtime Durations

From source:

- `PreparationPhase = 30s`
- `InvestigationPhase = 480s`
- `HuntPhase = 60s`
- `EndgamePhase = 30s`

Reference:

- `src/ServerScriptService/Server/MatchSystem/MatchService.lua`
  - `DEFAULT_PHASE_DURATIONS`

Observed room-start behavior:

- from Room Browser as solo host, pressing the host action leads to a visible room-start countdown of `5`
- after that, the match transitions into the map flow

## Actual Workflow As Experienced

### 1. Boot To Lobby

Observed:

- player enters lobby and immediately sees a left-side `LOBBY PANEL`
- visible actions:
  - `OPEN ROOM BROWSER`
  - `PROFILE`
  - `SHOP`
  - `ROYAL PASS`
  - `MENU`
  - `RANK`
- world signage also points toward `PLAY / CONTRACT`

What the player is effectively told to do:

1. open Room Browser
2. create or join room
3. start the match

### 2. Room Browser

Observed:

- `RUANG INVESTIGASI` opens as the main room flow surface
- host can create room from the browser
- after room creation, host-side room panel appears with:
  - map preview
  - room member panel
  - host action button

Important actual behavior:

- as solo host, the host action becomes the primary flow button
- the text behavior is:
  - `MULAI PERMAINAN`
  - then `BATALKAN COUNTDOWN`
- this means the host flow is effectively:
  1. create room
  2. press the main host action
  3. countdown begins automatically

### 3. Countdown To Match

Observed:

- a visible `5` second room-start countdown appears
- player is no longer deciding; the flow is now committed forward

### 4. Staging / Preparation

Observed:

- player teleports into staging
- match panel appears with preparation guidance
- visible instruction:
  - review board / contract / tools
  - breach / main entry guidance

What the player is expected to do:

1. orient in the staging space
2. read objective/contract/tool context
3. move through the intended entry flow

### 5. Investigation

Observed:

- player enters `InvestigationPhase`
- objective banner gives room-anchor instruction such as:
  - `Gunakan anchor Livingroom`
  - `Sweep area terdekat`
- field kit becomes active
- journal and evidence UI can also appear at the same time
- bottom bar shows shortcuts for:
  - field kit
  - journal
  - flashlight

What the game is asking the player to do:

1. move toward target room / anchor
2. sweep the area
3. use field tools to collect or confirm evidence
4. remember refuge route for hunt survival

## First 30 Seconds: What Is Confusing

### 1. The player sees too many equally-important buttons at boot

The left lobby panel presents many actions at once:

- Room Browser
- Profile
- Shop
- Royal Pass
- Menu
- Rank

The correct next action is there, but the hierarchy is weak. A new player can read this as a menu hub, not as a clear “start playing here” funnel.

### 2. The room-start semantics are not instantly obvious

From player perspective, the host flow is not naturally explained as:

- create room
- then use the same primary host button to start / ready / cancel countdown

The text changes are functional, but mentally it still feels like:

- “am I readying?”
- “am I starting?”
- “is this countdown for everyone or just me?”

### 3. Staging spawn framing is rough

On first arrival in staging, the camera/view can be too close to props/boards.

That creates a bad first read:

- the player is already inside the level
- but the first visual is not the room, route, or objective
- the first visual is obstruction / clipping / partial signage

### 4. Investigation onboarding is too dense too fast

Once in investigation, the player can get:

- objective banner
- journal
- evidence panel
- field kit
- shortcut hints

all stacked very early.

The player receives information, but not in a clean order.

## What Feels Not Polished

### 1. Camera and spawn framing

- spawn can face too close to geometry
- the player can end up reading a wall instead of reading the room
- first-person readability suffers immediately

### 2. HUD layering

- journal + field kit + objective guidance can overlap the player’s actual need:
  - “where am I?”
  - “where should I go right now?”
- the UI is informative, but not calm

### 3. World readability versus UI readability

- the UI says useful things
- the world itself does not always visually support that instruction strongly enough
- the player depends too much on text rather than environmental legibility

### 4. Visual finish of the actual space

The playable space still reads as function-first rather than final:

- dark/simple surfaces
- placeholder feeling in room read
- low richness in visual guidance landmarks

This is consistent with the broader owner notes:

- SFX
- VFX
- garden / flex / zones
- terrain
- map relayout
- overall visual finish

## What Would Make A Player Quit Early

### 1. “I do not understand what the game wants from me”

If the player gets:

- too many buttons in lobby
- unclear host/start semantics
- spawn into cluttered staging
- then investigation HUD overload

the player can leave before the actual horror loop becomes enjoyable.

### 2. “I am inside the game but I am staring at walls and panels”

This is critical.

If the player’s early investigation experience is:

- wall in face
- tool UI open
- journal open
- instruction text still on screen

then the game feels harder to read than it should.

That is a fast rage-quit vector.

### 3. “The game feels unfinished”

Even if the systems work, a player can still bounce because:

- room visuals do not yet sell the fantasy fully
- onboarding flow feels stitched together rather than authored
- sensory payoff in the first minute is not yet premium enough

### 4. “The flow asks me to care before it earns the mood”

The player is asked to:

- read
- manage tools
- understand room anchors
- remember refuge

very early.

If atmosphere, clarity, and movement comfort are not already strong, this feels like work, not tension.

## QA Summary

### Workflow In One Line

`Boot lobby -> open room browser -> create room -> host action -> 5s room countdown -> staging/preparation -> investigation sweep -> hunt survive -> endgame/results -> lobby`

### Durations In One Line

If allowed to run at default configured durations:

- room-start countdown: observed `5s`
- preparation: `30s`
- investigation: `480s`
- hunt: `60s`
- endgame: `30s`

Total in-match runtime after room start is roughly:

- `~10 minutes 5 seconds`

excluding time spent in lobby before room start.

### Most Important UX Conclusion

The game loop is understandable **after** a technical reader decodes it, but the first minute still asks too much from a fresh player.

The biggest early-exit risks are:

1. weak action hierarchy in lobby
2. host/start semantics not instantly obvious
3. staging spawn framing
4. investigation HUD overload versus room readability
5. overall visual/game-feel not yet premium enough to compensate
