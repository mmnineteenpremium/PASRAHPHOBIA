# CLAUDE CODE CLI PROMPT — BUTTON VISIBILITY & HANDLER DEBUG
## Comprehensive Debugging for CreateRoom, SetReady, HostStart Buttons
## Date: 2026-03-17 | Owner: Miftah | Max Iterations: 20
## AGGRESSIVE DEBUG MODE: Find root cause and fix it

---

## PROBLEM STATEMENT

**Observed Behavior:**
- UI renders (room list, mode/difficulty selectors visible)
- Mode/Difficulty clicks fire server actions ✅
- JoinRoom, LeaveRoom buttons working ✅
- **BUT: CreateRoom, SetReady (SIAP), HostStart (MULAI) buttons NOT VISIBLE** ❌
- Server logs show ZERO fired actions for these buttons

**Root Cause Unknown:**
- Buttons may not be created
- Buttons may be created but hidden (Visible=false)
- Buttons may be outside screen bounds
- Event handlers may not be connected
- In-room panel visibility logic broken

---

## TASK: COMPREHENSIVE DEBUG & FIX

### PHASE 1: LOCATE & AUDIT BUTTON CREATION (READ-ONLY)

**File:** `src/client/UI/Main.lua`

**Search for and REPORT:**

1. **CreateRoom button**
   - Search: "createRoomBtn" or "CreateRoom"
   - Report: Line number where button created
   - Report: How is Visible property set? (initial state)
   - Report: Parent frame (should be in-room panel or main panel?)

2. **SetReady button** (label "SIAP")
   - Search: "readyBtn" or "SetReady" or "SIAP"
   - Report: Line number where button created
   - Report: Initial Visible state
   - Report: Parent frame
   - Report: Button color logic (should be green when ready, yellow when not)

3. **HostStart button** (label "MULAI")
   - Search: "startBtn" or "HostStart" or "MULAI"
   - Report: Line number where button created
   - Report: Initial Visible state
   - Report: Parent frame
   - Report: When should it be visible? (check conditional logic)

4. **In-room panel visibility**
   - Search: "roomPanel" or "RoomPanel"
   - Report: Line where roomPanel created
   - Report: Initial Visible state (should be false initially)
   - Report: When/where does it get set to Visible=true?

5. **Button handler connections**
   - Search: "createRoomBtn.Activated:Connect"
   - Search: "readyBtn.Activated:Connect"
   - Search: "startBtn.Activated:Connect"
   - Report: Are these handlers present? (YES/NO for each)

**Format Report as:**
```
BUTTON AUDIT RESULTS:
====================

CreateRoom Button:
- Location: Line X
- Initial Visible: [true/false/conditional]
- Parent: [frame name]
- Handler Connected: [YES/NO]

SetReady Button:
- Location: Line X
- Initial Visible: [true/false/conditional]
- Parent: [frame name]
- Color Logic: [exists/missing]
- Handler Connected: [YES/NO]

HostStart Button:
- Location: Line X
- Initial Visible: [true/false/conditional]
- Parent: [frame name]
- Show Condition: [code/missing]
- Handler Connected: [YES/NO]

In-Room Panel:
- Location: Line X
- Initial Visible: [true/false]
- Show Logic: [code snippet]

ROOT CAUSE HYPOTHESIS:
[Based on audit, what's most likely the issue?]
```

Do NOT edit. Read-only audit.

---

### PHASE 2: FIX IDENTIFIED ISSUES

**Based on audit results, apply fixes:**

**IF buttons not created:**
- Create them in _ensureRoomBrowserGui function
- Parent to in-room panel
- Set proper initial Visible=false

**IF buttons created but Visible=false:**
- Find where they're set to false
- Change to Visible=true (or conditional based on room state)

**IF buttons outside screen bounds:**
- Check Position/Size properties
- Ensure proper UDim2 positioning
- Position relative to parent frame (in-room panel)

**IF in-room panel never shows:**
- Find in-room panel visibility logic
- Ensure _refreshRoomBrowserView sets roomPanel.Visible = true when player in room
- Check condition: `if currentRoom then roomPanel.Visible = true end`

**IF handlers not connected:**
- Wire handlers:
```lua
createRoomBtn.Activated:Connect(function()
    if self._roomBrowser then
        self._roomBrowser:CreateRoom()
        task.delay(0.3, function()
            if self._roomBrowser then 
                self._roomBrowser:RequestRoomList() 
            end
        end)
    end
end)

readyBtn.Activated:Connect(function()
    isReady = not isReady
    if self._roomBrowser then 
        self._roomBrowser:SetReady(isReady) 
    end
end)

startBtn.Activated:Connect(function()
    if not isHost then return end
    if self._roomBrowser then
        self._roomBrowser:HostStart(selectedMap, nil, nil)
        startCountdown(true)
    end
end)
```

---

### PHASE 3: ENSURE VISIBILITY REFRESH LOGIC

**In _refreshRoomBrowserView function, ensure:**

```lua
-- Show/hide in-room panel based on currentRoom state
if currentRoom then
    roomPanel.Visible = true
    -- Update panel content
    roomTitle.Text = 'RUANG #' .. tostring(currentRoom)
    -- Show/hide buttons based on state
    readyBtn.Visible = true
    createRoomBtn.Visible = false  -- hide when in room
    startBtn.Visible = isHost and (readyCount == playerCount) and playerCount > 0
else
    roomPanel.Visible = false
    createRoomBtn.Visible = true  -- show only when NOT in room
    readyBtn.Visible = false
    startBtn.Visible = false
end
```

---

### PHASE 4: VALIDATE & REPORT

After fixes:

**Syntax Check:**
- [ ] No Lua syntax errors
- [ ] No undefined variables
- [ ] Proper scoping (self._, local vars, closures)

**Logic Check:**
- [ ] Buttons created in correct parent frame
- [ ] Visibility logic sound (buttons show/hide based on room state)
- [ ] Event handlers properly wired
- [ ] _refreshRoomBrowserView updates button visibility each frame

**Report Back:**
- Exact changes made (line numbers + code)
- Which root cause was identified
- Which fixes applied
- Any additional issues found

---

## VALIDATION FOR SUCCESS

**After executing this prompt, Miftah should see in next F5:**

1. **In-room panel appears** when player clicks "JoinRoom"
2. **CreateRoom button visible** in main panel (when NOT in room)
3. **SIAP (SetReady) button visible** when in room
4. **MULAI (HostStart) button visible** when host + all ready
5. **Server logs show:**
   ```
   [LobbyController] SERVER RECEIVED ... SetReady action
   [LobbyController] SERVER RECEIVED ... HostStart action
   [LobbyController] SERVER RECEIVED ... CreateRoom action
   ```

---

## CRITICAL SAFETY RULES

**DO NOT:**
- Rebuild entire _ensureRoomBrowserGui (too risky)
- Rebuild _refreshRoomBrowserView completely
- Create new UI files or frameworks
- Change button styling unless necessary for visibility

**DO:**
- Fix visibility logic only
- Connect missing handlers
- Ensure parent frame is correct
- Update refresh logic to show/hide based on state

---

## EXECUTION STRATEGY

**Step 1:** Audit (report findings, wait for understanding)
**Step 2:** Identify root cause hypothesis
**Step 3:** Apply targeted fixes
**Step 4:** Validate syntax + logic
**Step 5:** Report exact changes

**Iterative:** If first fix doesn't work, audit again with updated focus.

---

## MAX 20 ITERATIONS GUIDANCE

**Expected flow:**
- Iterations 1-2: Audit + identify issue
- Iterations 3-8: Apply fixes (multiple rounds likely)
- Iterations 9-15: Validate + refinement
- Iterations 16-20: Final polish + edge cases

If reaching iteration 18+, summarize what worked and what still needs manual review.

---

**READY TO DEBUG. LET'S FIND THE BUTTONS!** 🔍🚀
