# CLAUDE CODE CLI PROMPT — COMPLETE SESSION 3 UI TASKS
## Comprehensive Prompt for Full UI Renovation + Testing
## Date: 2026-03-17 | Owner: Miftah | Tech Lead: Claude | Executor: Claude Code
## SAFETY MODE: Anti-Duplication, Anti-Tech-Debt enabled

---

## CRITICAL CONTEXT

**Owner's Warning:**
- DANGER: Do not rebuild completed systems
- DANGER: Do not create duplicate code
- DANGER: Do not introduce tech debt

**Our Approach:**
1. AUDIT existing code structure
2. IDENTIFY what's MISSING vs what's COMPLETE
3. IMPLEMENT ONLY missing pieces
4. VERIFY no duplication introduced

---

## SESSION 3 GOALS (To be completed this session)

**Goal 1:** _ensureRoomBrowserGui renovation
- [ ] Title displays "RUANG INVESTIGASI" (not "Mode Classic | Difficulty...")
- [ ] In-room panel visible when player in room (title "RUANG #X")
- [ ] Countdown overlay (5 second countdown, initially hidden)
- [ ] Map selector dropdown (visible when host, not in Ranked)
- [ ] Ready button ("SIAP") with color change (green=ready, yellow=not ready)
- [ ] Host Start button (visible only when host + all ready)
- [ ] Leave Room button in in-room panel
- [ ] CreateRoom button in main panel

**Goal 2:** Button event handlers
- [ ] CreateRoom → fires CreateRoom action + refresh after 300ms
- [ ] SetReady → toggles ready state + fires to server
- [ ] HostStart → fires HostStart + triggers countdown
- [ ] LeaveRoom → leaves + clears in-room state + refreshes
- [ ] Map selector cycle → updates selectedMap state
- [ ] Countdown cancel → stops countdown

**Goal 3:** _refreshRoomBrowserView updates
- [ ] Update status label (Mode | Difficulty | Room count)
- [ ] Refresh room list dynamically
- [ ] Update in-room panel with current room data
- [ ] Show/hide in-room panel based on player state
- [ ] Handle matchStarting flag → trigger countdown

---

## TASK BREAKDOWN

### PART 1: AUDIT EXISTING CODE (READ-ONLY)

**File:** `src/client/UI/Main.lua`

**Search for and REPORT ON:**

1. **_ensureRoomBrowserGui function (lines ~324+)**
   - Does it have countdown overlay? (YES/NO)
   - Does it have map selector? (YES/NO)
   - Does it set title to "RUANG INVESTIGASI"? (YES/NO)
   - What GUI elements are created? (list them)
   - How is in-room panel styled? (report styling code)

2. **Button event handlers (search for .Activated:Connect)**
   - CreateRoom button wired? (YES/NO) 
   - SetReady button wired? (YES/NO)
   - HostStart button wired? (YES/NO)
   - Map selector wired? (YES/NO)
   - Countdown cancel button exists? (YES/NO)

3. **_refreshRoomBrowserView function (lines ~854+)**
   - Does it update status label? (YES/NO)
   - Does it refresh room list? (YES/NO)
   - Does it handle in-room panel visibility? (YES/NO)
   - Does it handle matchStarting countdown? (YES/NO)

**Report Format:**
```
AUDIT RESULTS:
=============

_ensureRoomBrowserGui():
- Countdown overlay: [YES/NO]
- Map selector: [YES/NO]
- RUANG INVESTIGASI title: [YES/NO]
- In-room panel exists: [YES/NO]
- Lines X-Y contain the function

Button Handlers:
- CreateRoom: [WIRED/MISSING]
- SetReady: [WIRED/MISSING]
- HostStart: [WIRED/MISSING]
- Map selector: [WIRED/MISSING]
- Countdown cancel: [EXISTS/MISSING]

_refreshRoomBrowserView():
- Status update: [YES/NO]
- Room list refresh: [YES/NO]
- In-room panel logic: [YES/NO]
- Match starting countdown: [YES/NO]

MISSING PIECES IDENTIFIED:
[List what needs to be added]
```

Do NOT edit anything. Report only.

---

### PART 2: IMPLEMENT MISSING PIECES

**Based on audit results, IMPLEMENT MISSING FEATURES:**

**IF countdown overlay missing:**
- Add countdown overlay frame (5s counter display)
- Position: center of screen
- Initially: hidden (Visible = false)
- Countdown label: large text (24pt+)
- Cancel button: visible only when host can cancel

**IF map selector missing:**
- Add map selector dropdown/button
- Maps available: {"HauntedHouse", "AbandonedPalace", "EmptyBuilding", "StudioMMNineteen"}
- Cycle through maps on button press
- Show current map in button text
- Only show when: (isHost == true) AND (selectedMode != "Ranked")

**IF title not "RUANG INVESTIGASI":**
- Find where main title is set
- Change to "RUANG INVESTIGASI"
- Keep styling (size, color, font)

**IF in-room panel styling incomplete:**
- Title format: "RUANG #" .. roomId
- Host label: "Host: " .. hostName
- Show player list (if not already)
- Ready button color: green if isReady, yellow if not
- Start button: visible only if isHost AND readyCount == playerCount AND playerCount > 0

**IF button handlers missing:**
Create these handlers (attach to existing buttons or create new ones):

CreateRoom:
```lua
createRoomBtn.Activated:Connect(function()
    if self._roomBrowser then
        self._roomBrowser:CreateRoom()
        task.delay(0.3, function()
            if self._roomBrowser then self._roomBrowser:RequestRoomList() end
        end)
    end
end)
```

SetReady:
```lua
readyBtn.Activated:Connect(function()
    isReady = not isReady
    if self._roomBrowser then self._roomBrowser:SetReady(isReady) end
end)
```

HostStart:
```lua
startBtn.Activated:Connect(function()
    if not isHost then return end
    if self._roomBrowser then
        self._roomBrowser:HostStart(selectedMap, nil, nil)
        startCountdown(true)  -- trigger 5s countdown
    end
end)
```

Map Selector:
```lua
mapSelector.Activated:Connect(function()
    if not isHost then return end
    mapIndex = (mapIndex % #MAPS) + 1
    selectedMap = MAPS[mapIndex]
    mapSelector.Text = selectedMap
end)
```

Countdown Cancel:
```lua
cancelCountdownBtn.Activated:Connect(function()
    stopCountdown()  -- hide overlay, stop timer
end)
```

**IF _refreshRoomBrowserView incomplete:**
Ensure it:
1. Updates status label with: "Mode: X | Difficulty: Y | Z Room Aktif"
2. Updates mode button selection color
3. Updates difficulty button colors
4. Refreshes room list (call RefreshRoomList widget function)
5. Refreshes in-room panel (call RefreshRoomPanel widget function)
6. Handles matchStarting flag to trigger countdown

---

### PART 3: VALIDATION

After implementing:

- [ ] No syntax errors
- [ ] No references to deleted code
- [ ] No duplication with existing buttons
- [ ] All button handlers properly scoped (self._roomBrowser, isHost, isReady, etc.)
- [ ] Countdown logic uses task.spawn() not wait()
- [ ] Map selector uses existing MAPS table
- [ ] File ready for Rojo sync

---

## CRITICAL SAFETY GUARDS

**DO NOT:**
- Rebuild entire _ensureRoomBrowserGui from scratch (it exists and mostly works)
- Rebuild _refreshRoomBrowserView from scratch (it exists)
- Create new RoomBrowserController methods (it's complete)
- Modify any LobbySystem/RoomManager code (they're done)
- Create duplicate UI files

**DO:**
- Fill in MISSING countdown overlay code
- Fill in MISSING map selector code  
- Fix title if not "RUANG INVESTIGASI"
- Complete missing button handlers
- Ensure _refreshRoomBrowserView covers all widget updates
- Use existing widget functions (RefreshRoomList, RefreshRoomPanel, StartCountdown, StopCountdown)

---

## EXECUTION ORDER

1. **AUDIT ONLY** (lines ~324-843) — identify what's missing
2. **Report findings** — wait for confirmation or auto-proceed
3. **Implement missing pieces** — fill gaps, don't rebuild
4. **Validate** — syntax + no duplication + safety checks
5. **Report changes** — exact line numbers and what was added/modified

---

## EXPECTED OUTPUT AFTER SESSION 3 COMPLETION

**What should work after this prompt:**
- [ ] "RUANG INVESTIGASI" title visible at top of room browser
- [ ] Mode selector buttons (Classic/Ranked) with color highlight
- [ ] Difficulty buttons with color highlight
- [ ] Room list shows 10+ rooms dynamically
- [ ] In-room panel shows "RUANG #X | Host: Name | Players: X/4"
- [ ] Ready button toggles color and fires SetReady action
- [ ] Host Start button visible (when host + all ready)
- [ ] Map selector visible when host (not Ranked)
- [ ] Countdown overlay hidden initially
- [ ] When host clicks Start → countdown appears (5,4,3,2,1) → auto-hides
- [ ] Cancel button stops countdown
- [ ] Leave Room button works + clears panel

---

## NEXT SESSION CHECKLIST (After this completes)

- [ ] Verify all buttons fire correct server actions (check logs)
- [ ] Test 2-player match start → verify both teleport same map
- [ ] Fix LobbyEventTap aggressive queue (non-critical, Phase 7)
- [ ] Update CLAUDE.md with status
- [ ] Move to Phase 7 playtest + polish

---

## FILE LOCATION REMINDER

**Primary file:** `src/client/UI/Main.lua`
**Do not touch:** 
- `src/client/UI/RoomBrowserController.lua` (complete)
- `src/client/Core/ClientBootstrap.lua` (complete)
- Any ServerScriptService files (complete)

---

**READY TO EXECUTE. LET'S GO!** 🚀
