# CLAUDE CODE CLI PROMPT — BUTTON VISIBILITY & HANDLER DEBUG
## WITH COMPREHENSIVE SESSION CONTEXT
## Owner: Miftah | Date: 2026-03-17 | Mode: AGGRESSIVE DEBUG | Max iterations: 20

---

## CONTEXT SUMMARY (SESSION 4-5 FINDINGS)

### Files Under Investigation

**File B: src/client/UI/Main.lua** (992 lines, ACTIVE)
- Required by ClientBootstrap ✅
- Event subscriptions present ✅
- Button handlers defined ✅
- Refresh loop present ✅
- **BUT: Buttons NOT FIRING to server** ❌

**File A: src/StarterGui/UISystem/Main.lua** (374 lines, DISABLED)
- Intentionally disabled per design decision
- Keep as fallback (do NOT delete)
- Not active in system

### Known Issues

```
Server Actions NOT FIRING:
├─ CreateRoom ❌
├─ SetReady ❌
├─ HostStart ❌
├─ KickPlayer ❌
└─ SetPassword ❌

Server Actions FIRING:
├─ SelectMode ✅
├─ SelectDifficulty ✅
├─ RequestRoomBrowserSnapshot ✅
├─ RequestRoomList ✅
├─ JoinRoom ✅
└─ LeaveRoom ✅

OBSERVATION:
Mode/Difficulty selection works → buttons visible + firing
Room creation/management doesn't → buttons hidden OR handlers broken
```

### Hypothesis

```
Buttons exist in code (verified by audit).
Buttons created and wired (verified by audit).

Possible root causes:
A) Button visibility logic broken
   → Buttons created but Visible=false
   → Or positioned outside screen bounds

B) In-room panel not showing
   → Buttons parented to panel that never visible
   → Panel visibility condition broken

C) Refresh loop not updating button visibility
   → Loop not running, or condition wrong

D) Handler connections incomplete
   → Activated:Connect exists but event not firing
   → Or handler not sending to server correctly

E) State management stuck
   → Buttons think they shouldn't show based on wrong state
```

---

## TASK: COMPREHENSIVE BUTTON DEBUG

### PHASE 1: BUTTON EXISTENCE & VISIBILITY AUDIT (READ-ONLY)

**File:** src/client/UI/Main.lua

#### Search 1: CreateRoom Button

```
Search for:
- "createRoomBtn" or "CreateRoom" or "create.*button"
- First occurrence line number
- Is it inside _ensureRoomBrowserGui()?
- Show code context (10 lines around creation)

Report:
- Button name used in code
- Line where created
- Parent frame (what frame is it parented to?)
- Initial Visible state (true/false/variable)
- Size and Position (UDim2)
```

#### Search 2: SetReady Button (SIAP)

```
Search for:
- "readyBtn" or "SetReady" or "SIAP" or "ready.*button"
- First occurrence line number
- Is it inside _ensureRoomBrowserGui()?
- Show code context (10 lines around creation)

Report:
- Button name used in code
- Line where created
- Parent frame
- Initial Visible state
- Size and Position
- Is there color logic (green=ready, yellow=not)?
```

#### Search 3: HostStart Button (MULAI)

```
Search for:
- "startBtn" or "HostStart" or "MULAI" or "host.*start"
- First occurrence line number
- Is it inside _ensureRoomBrowserGui()?
- Show code context (10 lines around creation)

Report:
- Button name used in code
- Line where created
- Parent frame
- Initial Visible state
- Size and Position
- Visibility condition (when should it show?)
```

#### Search 4: In-Room Panel

```
Search for:
- "roomPanel" or "RoomPanel" or "InRoomPanel" or "in.*room.*panel"
- First occurrence line number
- Show code context (10 lines around creation)

Report:
- Panel name used in code
- Line where created
- Parent frame
- Initial Visible state (should be false initially)
- CRITICAL: Where/when does it get set to Visible=true?
  (search for "roomPanel.Visible = true")
```

#### Search 5: Button Parent Frames

```
For CreateRoom, SetReady, HostStart buttons:

Report parent frame hierarchy:
Example:
  CreateRoom parent: mainPanel (line 400)
  SetReady parent: inRoomPanel (line 500)
  HostStart parent: inRoomPanel (line 510)

CRITICAL: Are parents being created BEFORE buttons?
Or parent might be nil when button tries to parent to it?
```

---

### PHASE 2: VISIBILITY LOGIC AUDIT

#### Search 6: _refreshRoomBrowserView Function

```
Find: function UISystem:_refreshRoomBrowserView(self)
Or: _refreshRoomBrowserView = function(self)

Report:
- Start line number
- End line number
- Total lines in function

Inside function, search for:
- "roomPanel.Visible" assignments
- "createRoomBtn.Visible" assignments
- "readyBtn.Visible" assignments
- "startBtn.Visible" assignments

For EACH assignment, report:
- Line number
- Full code: what condition sets it?
  Example: if currentRoom then roomPanel.Visible = true end

CRITICAL:
- What variable controls visibility?
- How is currentRoom determined?
- Is the condition sound?
```

#### Search 7: _startRoomBrowserLoop Function

```
Find: function _startRoomBrowserLoop(self)
Or: _startRoomBrowserLoop = function(self)

Report:
- Start line number
- End line number
- Frequency: how often does it run? (every 0.25s?)

Inside function:
- Does it call _refreshRoomBrowserView()?
- How many times per loop?
- Is there a wait/delay between calls?

CRITICAL: Is this loop actually running?
(Check for errors/early returns that might break it)
```

---

### PHASE 3: HANDLER WIRING AUDIT

#### Search 8: Button Handlers

For EACH button (CreateRoom, SetReady, HostStart):

```
Find:
- "[buttonName].Activated:Connect(function()"

Report:
- Line number
- Full code block (from :Connect to end of function)
- What does handler do?
  - Does it call self._roomBrowser:CreateRoom()?
  - Does it call self._roomBrowser:SetReady()?
  - Does it call self._roomBrowser:HostStart()?

CRITICAL:
- Is handler syntax correct?
- Is self._roomBrowser guaranteed to exist?
- Is handler called AFTER button created?
- Or is button created AFTER handler attempted to wire?
```

#### Search 9: _roomBrowser Initialization

```
Find: self._roomBrowser = 
Or: _roomBrowser creation/initialization

Report:
- Line number
- What is _roomBrowser?
- Is it a RoomBrowserController instance?
- When is it created relative to buttons?

CRITICAL:
- If _roomBrowser created AFTER buttons try to wire handlers
  → Handlers might fail silently
- If _roomBrowser is nil at handler time
  → Handlers exist but can't send messages
```

---

### PHASE 4: STATE FLOW AUDIT

#### Search 10: currentRoom Variable

```
Find: where currentRoom is set/updated

Report:
- Line numbers where currentRoom assigned
- How is it determined? (from self._roomBrowser.GetRoom()?)
- Is it updated in _refreshRoomBrowserView()?
- Is it updated when player joins/leaves room?

CRITICAL:
- If currentRoom always nil
  → roomPanel visibility condition never true
  → Buttons never show
```

#### Search 11: isHost Variable

```
Find: where isHost is set/updated

Report:
- Line numbers where isHost assigned
- How is it determined?
- Is HostStart button visibility based on isHost?

CRITICAL:
- If isHost always false
  → HostStart button never visible
  → Even if logic correct
```

---

### PHASE 5: EVENT FLOW AUDIT

#### Search 12: Server Event Subscription

```
Find: :OnClientEvent:Connect(function(action, payload)

Report:
- Line number
- Which RemoteEvents does it subscribe to?
- Does _onServerEvent get called on room changes?
- Does it update _roomBrowser state?

CRITICAL:
- If server events not received
  → State never updates
  → Visibility conditions never triggered
```

---

### PHASE 6: SYNTHESIS & ROOT CAUSE IDENTIFICATION

Based on all findings above, provide:

```
BUTTON VISIBILITY FINDINGS:
===========================

CreateRoom Button:
- Created: Line X, parent [frame], initial Visible: [T/F]
- Visibility controlled by: [code]
- Handler wired: YES/NO
- Issue identified: [describe]

SetReady Button:
- Created: Line X, parent [frame], initial Visible: [T/F]
- Visibility controlled by: [code]
- Handler wired: YES/NO
- Issue identified: [describe]

HostStart Button:
- Created: Line X, parent [frame], initial Visible: [T/F]
- Visibility controlled by: [code]
- Handler wired: YES/NO
- Issue identified: [describe]

In-Room Panel:
- Created: Line X, parent [frame], initial Visible: [T/F]
- Shown when: [code condition]
- Issue identified: [describe]

───

ROOT CAUSE HYPOTHESIS:
Problem is likely at: [identify exact break point]
Mechanism: [explain why buttons not visible/firing]
Evidence: [quote relevant code lines]

RECOMMENDATION:
Fix priority: [list in order]
1. [First fix needed]
2. [Second fix needed]
3. [etc]
```

---

## CRITICAL RULES

**DO NOT:**
- Edit code yet (audit only)
- Assume button logic is correct
- Skip checking parent frame creation order
- Miss state variable initialization
- Assume handlers always wire correctly

**DO:**
- Report line-by-line findings
- Check creation order (does parent exist before button?)
- Verify state variables exist before used
- Check handler syntax carefully
- Test assumptions with code evidence

---

## SUCCESS CRITERIA

After this audit, we should know EXACTLY:

```
✓ Is CreateRoom button created?
✓ Is it visible?
✓ Is handler connected?
✓ Is in-room panel showing?
✓ Is refresh loop running?
✓ What variable/condition stops buttons from showing?
✓ Exact line number of root cause
✓ Proposed fix for root cause
```

---

## EXECUTION FLOW

1. Audit phase (read-only, fact-gathering)
2. Report findings in structured format
3. Identify root cause
4. Recommend fixes (don't apply yet)
5. Wait for Miftah approval before fixing

---

**THIS IS DETECTIVE WORK. BE THOROUGH.** 🔍

We only get 20 iterations max.
Make each iteration count.
No shortcuts.

---

**READY TO DEBUG.** 🚀
