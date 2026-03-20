# CLAUDE CODE CLI PROMPT — CONFLICT ANALYSIS: FILE A vs FILE B
## Can both files coexist without interfering?
## Owner: Miftah | Date: 2026-03-17 | Mode: RISK ASSESSMENT ONLY
## Focus: Potential collisions, race conditions, namespace conflicts

---

## CONTEXT

**File A:** src/StarterGui/UISystem/Main.lua (374 lines, 12,676 bytes)
**File B:** src/client/UI/Main.lua (992 lines, 31,718 bytes)

Both files have UISystem class with similar function names (_ensureRoomBrowserGui, _refreshRoomBrowserView, etc).

**QUESTION:** If both files exist in the codebase, will they interfere with each other?

---

## TASK: ANALYZE CONFLICT POTENTIAL

### PHASE 1: NAMESPACE COLLISION CHECK

**Search in BOTH files for:**

#### 1. Global variable usage
   - File A: List any global variables created (check for `_G.`, global assignments, or module-level vars)
   - File B: List any global variables created
   - Compare: Do they use same variable names? 
   - Report: Conflict risk YES/NO

#### 2. Instance naming in GUI creation
   - File A: Search for ScreenGui/Frame creation with specific names
     - What names does it use? (e.g., "RoomBrowserGui", "RoomBrowserPanel", etc)
     - List them
   
   - File B: Search for ScreenGui/Frame creation with specific names
     - What names does it use?
     - List them
   
   - Compare: Do they try to create GUI with SAME names?
   - If yes: Report what happens when both try to create instance with same name

#### 3. Remote Event subscriptions
   - File A: Which RemoteEvents does it subscribe to?
     - Search for :OnClientEvent:Connect
     - Search for :FireServer calls
     - List all RemoteEvent names
   
   - File B: Which RemoteEvents does it subscribe to?
     - Search for :OnClientEvent:Connect
     - Search for :FireServer calls
     - List all RemoteEvent names
   
   - Compare: Do they listen to same RemoteEvent?
   - If yes: What happens if both handlers run for same event?

#### 4. Frame/Button parenting hierarchy
   - File A: Where does _ensureRoomBrowserGui() create buttons?
     - What's the parent frame? (local variable name)
     - Does it reference fixed path or dynamic?
   
   - File B: Where does _ensureRoomBrowserGui() create buttons?
     - What's the parent frame?
     - Does it reference fixed path or dynamic?
   
   - Compare: If both try to parent buttons to same frame, what happens?

---

### PHASE 2: RUNTIME CONFLICT SCENARIOS

**If BOTH File A and File B are loaded simultaneously and both Init() called:**

#### Scenario 1: Startup sequence
Report:
```
Timeline of initialization:
1. File A:new() called (if it is)
2. File A:Init() called (if it is)
3. File B:new() called
4. File B:Init() called

At each step:
- Do they both try to create same instances?
- Do they both call _ensureRoomBrowserGui()?
- What is the interference point?
```

#### Scenario 2: GUI creation conflict
Report:
```
File A tries: create ScreenGui named "RoomBrowserGui"
File B tries: create ScreenGui named "RoomBrowserGui"

Question: 
- Does Roblox allow duplicate-named instances in same parent?
- If File A creates first, can File B create with same name?
- What happens to File B's reference if name already exists?
- Risk of one file getting wrong instance: YES/NO?
```

#### Scenario 3: Event handler duplication
Report:
```
File A button handlers (if any):
- Are there button.Activated:Connect blocks?
- What buttons are they connected to?

File B button handlers:
- Are there button.Activated:Connect blocks?
- What buttons are they connected to?

If both connect to SAME button:
- Will handlers fire in sequence?
- Will they fight over shared state?
- Can this cause double-actions?
```

#### Scenario 4: Refresh loop collision
Report:
```
File A:
- Does it have any loop running? (while loop, task.spawn, etc)
- What's the frequency?

File B:
- _startRoomBrowserLoop exists?
- Frequency: every 0.25s
- What does it update?

If both run:
- Do they update same GUI state?
- Can they cause flickering/race conditions?
```

#### Scenario 5: RoomBrowser state conflicts
Report:
```
File A state variables:
- self._roomBrowserGui
- self._roomBrowser
- others?

File B state variables:
- self._roomBrowserGui
- self._roomBrowser
- others?

If both manage same instance:
- Which file's state is "source of truth"?
- Can they overwrite each other's state?
- Example: if File A sets button to Visible=false, then File B sets to Visible=true, who wins?
```

---

### PHASE 3: INTEGRATION INTERFERENCE

#### Check 1: File A being present (but unused) blocks File B
```
File A exists in src/StarterGui/UISystem/Main.lua but is NOT required by any file.
File B exists and IS required by ClientBootstrap.lua

Question:
- Does File A's existence in StarterGui affect File B's ability to create ScreenGui?
- Can both coexist in StarterGui and src/client?
- Is there a priority/loading order issue?
```

#### Check 2: File B's require() prevents File A from running
```
File B is required by ClientBootstrap.
File A has no require chain visible.

Question:
- Is File A ever instantiated/called?
- If not instantiated, is it just sitting there?
- Does dead code cause harm?
```

#### Check 3: Cleanup logic conflicts
```
File A cleanup logic (in Init or Shutdown):
- Search for destroy() calls
- What instances does it destroy? (line number + what's destroyed)

File B cleanup logic:
- Search for destroy() calls
- What instances does it destroy?

If File A runs cleanup first:
- Destroys "RoomBrowserGui", "RoomBrowserDebugUI"
- Then File B tries to access destroyed instances?
- Risk: File B can't find parent frame to attach buttons?
```

---

### PHASE 4: WORST-CASE SCENARIOS & RISK ASSESSMENT

```
CONFLICT RISK ASSESSMENT:
========================

Scenario 1: Both _ensureRoomBrowserGui() run
- Risk level: [CRITICAL/HIGH/MEDIUM/LOW]
- Mechanism: [explain what happens]
- Impact on gameplay: [describe result]

Scenario 2: Both subscribe to RemoteEvents
- Risk level: [CRITICAL/HIGH/MEDIUM/LOW]
- Mechanism: [explain what happens]
- Impact on gameplay: [describe result]

Scenario 3: Button handlers from both files
- Risk level: [CRITICAL/HIGH/MEDIUM/LOW]
- Mechanism: [explain what happens]
- Impact on gameplay: [describe result]

Scenario 4: File A cleanup + File B operation
- Risk level: [CRITICAL/HIGH/MEDIUM/LOW]
- Mechanism: [explain what happens]
- Impact on gameplay: [describe result]

Scenario 5: Refresh loop collision
- Risk level: [CRITICAL/HIGH/MEDIUM/LOW]
- Mechanism: [explain what happens]
- Impact on gameplay: [describe result]

───

OVERALL CONFLICT POTENTIAL: [CRITICAL/HIGH/MEDIUM/LOW]

EXPLANATION: [Why this risk level?]

───

CRITICAL FINDINGS (if any):
- [Finding 1]
- [Finding 2]
- [etc]

───

RECOMMENDED IMMEDIATE ACTION:
[Based on risk analysis, recommend ONE of:]
  A. DELETE File A immediately (high conflict risk)
  B. DISABLE File A (comment out or remove from folder)
  C. They can COEXIST SAFELY (low conflict risk)
  D. REQUIRES REFACTOR (both need modification)

JUSTIFICATION: [Why this action?]
```

---

## CRITICAL RULES

**DO NOT ASSUME:**
- "unused = harmless" (dead code can still interfere)
- "different folders = no conflict" (both can create same GUI)
- "File B required = File A never runs" (file system doesn't prevent loading)
- "small risk" (test everything methodically)

**DO:**
- Trace EVERY potential collision point
- Report actual code evidence
- Explain MECHANISM of conflict (not just "yes conflict exists")
- Prioritize safety over assumptions

---

**THIS IS DETECTIVE WORK, NOT CONCLUSION-DRAWING**

Report what code reveals, not what seems logical.

---

**END PROMPT — AWAITING AUDIT RESULTS**
