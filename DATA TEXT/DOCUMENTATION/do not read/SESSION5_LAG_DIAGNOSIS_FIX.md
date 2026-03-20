# SESSION 5 - LAG DIAGNOSIS & FIX

## CONTEXT

Clean F5 reload done. RoomBrowser working. BUT game still lagging (reduced but still present).

**Symptoms:**
- Game feels sluggish
- Auto-refresh spam reduced but performance still not smooth
- Likely loop or repeated task somewhere

---

## YOUR MISSION

**Find and fix ALL sources of lag:**

1. **Find loops without delays**
2. **Find excessive RunService connections**
3. **Find repeated logging spam**
4. **Optimize or disable heavy systems**

---

## PHASE 1: DIAGNOSTIC SCAN

### STEP 1: Find Auto-Refresh Interval

**File:** `src/client/UI/Main.lua`

**Search for:** `_startRoomBrowserLoop`

**Expected to find:**
```lua
while self._roomBrowserLoopRunning do
    self:_refreshRoomBrowserView()
    task.wait(0.25)  -- or task.wait(1) if already fixed
end
```

**ACTION:**
- If `task.wait(0.25)` → Change to `task.wait(2)` (refresh every 2 seconds)
- If `task.wait(1)` → Change to `task.wait(2)`
- Document what you changed

---

### STEP 2: Find Excessive Logging

**Search ALL files for:**
```
"[TRACE]"
```

**These are debug logs spamming output every frame!**

**Files likely to have it:**
- `src/client/UI/Main.lua`

**ACTION:**
For each `[TRACE]` log found:

**Option A: Comment out (quick fix)**
```lua
-- print("[UISystem] [TRACE] refreshRoomPanel called, currentRoom:", currentRoom)
```

**Option B: Guard with debug flag (better)**
```lua
local DEBUG_TRACE = false  -- At top of file

-- Then in code:
if DEBUG_TRACE then
    print("[UISystem] [TRACE] refreshRoomPanel called, currentRoom:", currentRoom)
end
```

**Choose Option B if found in Main.lua**

Add this at top of Main.lua (around line 1-10):
```lua
-- Debug flags
local DEBUG_TRACE = false  -- Set to true to enable verbose logging
```

Then wrap ALL `[TRACE]` prints with:
```lua
if DEBUG_TRACE then
    print("[UISystem] [TRACE] ...")
end
```

---

### STEP 3: Find MatchSpawner Loop

**File:** Likely `src/server/MatchSpawner.lua` or similar

**Search for:**
```
"checking queue"
```

**Expected to find:**
```lua
while true do
    print("[MatchSpawner] checking queue")
    -- ... match creation logic ...
    task.wait(2)  -- or some interval
end
```

**From output log, this runs every ~2 seconds which is OK.**

**ACTION:**
- Verify interval is >= 2 seconds
- If < 2 seconds, increase to 2
- Document findings

---

### STEP 4: Find LocalScript Test

**File:** Likely `src/client/LocalScript.lua` (client-side)

**Search for:**
```
"TEST EVIDENCE TRIGGER"
```

**From output:**
```
09:41:41.668  TEST EVIDENCE TRIGGER  -  Client - LocalScript:5
```

**ACTION:**
- **DELETE** this file if it's a standalone test
- OR **DISABLE** with `do return end` at line 1

**File path likely:**
- `StarterPlayer/StarterPlayerScripts/LocalScript`
- OR `src/client/LocalScript.lua`

---

### STEP 5: Check LobbyEventTap Error

**From output:**
```
FireServer is not a valid member of RemoteEvent
Client - LobbyEventTap:58
```

**File:** `src/client/LobbyEventTap.client.lua`

**Line 58 likely has:**
```lua
lobbyRemote.FireServer(...)  -- WRONG! Missing colon
```

**ACTION:**
Change to:
```lua
lobbyRemote:FireServer(...)  -- CORRECT! Use colon
```

---

## PHASE 2: APPLY FIXES

### FIX 1: Reduce Auto-Refresh Interval

**File:** `src/client/UI/Main.lua`

**Find:**
```lua
function UISystem:_startRoomBrowserLoop()
    if self._roomBrowserLoopRunning then return end
    self._roomBrowserLoopRunning = true
    task.spawn(function()
        while self._roomBrowserLoopRunning do
            self:_refreshRoomBrowserView()
            task.wait(?)  -- Find current value
        end
    end)
end
```

**Change to:**
```lua
function UISystem:_startRoomBrowserLoop()
    if self._roomBrowserLoopRunning then return end
    self._roomBrowserLoopRunning = true
    task.spawn(function()
        while self._roomBrowserLoopRunning do
            self:_refreshRoomBrowserView()
            task.wait(2)  -- Changed to 2 seconds (was 0.25 or 1)
        end
    end)
end
```

---

### FIX 2: Disable TRACE Logging

**File:** `src/client/UI/Main.lua`

**Add at top (after local declarations, around line 1-10):**
```lua
-- Debug configuration
local DEBUG_TRACE = false  -- Set to true only when debugging UI issues
```

**Then find ALL lines with:**
```lua
print("[UISystem] [TRACE] ...")
```

**Wrap each with:**
```lua
if DEBUG_TRACE then
    print("[UISystem] [TRACE] ...")
end
```

**Example:**
```lua
-- BEFORE:
print("[UISystem] [TRACE] refreshRoomPanel called, currentRoom:", currentRoom)

-- AFTER:
if DEBUG_TRACE then
    print("[UISystem] [TRACE] refreshRoomPanel called, currentRoom:", currentRoom)
end
```

**Do this for EVERY [TRACE] log in the file.**

---

### FIX 3: Fix LobbyEventTap Syntax

**File:** `src/client/LobbyEventTap.client.lua`

**Find line 58 (or nearby):**
```lua
lobbyRemote.FireServer(request)  -- WRONG
```

**Change to:**
```lua
lobbyRemote:FireServer(request)  -- CORRECT
```

---

### FIX 4: Delete/Disable Test Script

**File:** `src/client/LocalScript.lua` (or StarterPlayerScripts/LocalScript)

**Option A: DELETE completely**

**Option B: DISABLE**
```lua
do return end  -- DISABLED - test script

-- rest of file...
```

---

## PHASE 3: VERIFICATION CHECKLIST

After applying fixes, verify:

**✅ Auto-refresh interval:** 2 seconds (was 0.25 or 1)
**✅ TRACE logging:** Disabled (guarded by DEBUG_TRACE = false)
**✅ LobbyEventTap:** Fixed syntax (colon instead of dot)
**✅ Test scripts:** Deleted or disabled

---

## OUTPUT REQUIRED

**Report in this format:**

```
SESSION 5 LAG FIXES - EXECUTION REPORT

DIAGNOSTICS:
1. Auto-refresh interval found: [0.25s / 1s / 2s / OTHER]
2. TRACE logs found: [COUNT] instances
3. MatchSpawner interval: [X] seconds
4. Test script found: [YES/NO] at [PATH]
5. LobbyEventTap syntax: [CORRECT / FIXED]

CHANGES MADE:
1. src/client/UI/Main.lua
   - Line ~990: task.wait(?) → task.wait(2)
   - Added DEBUG_TRACE flag at top
   - Wrapped [X] TRACE logs with DEBUG_TRACE guard

2. src/client/LobbyEventTap.client.lua
   - Line 58: Fixed FireServer syntax

3. src/client/LocalScript.lua
   - [DELETED / DISABLED]

FILES MODIFIED:
- src/client/UI/Main.lua
- src/client/LobbyEventTap.client.lua
- [Any others]

FILES DELETED:
- [List any deleted test files]
```

---

## EXPECTED RESULT

**After F5 reload:**

**✅ Output clean** - no TRACE spam  
**✅ Performance smooth** - no lag  
**✅ Auto-refresh** - every 2 seconds (not noticeable)  
**✅ No errors** - FireServer syntax fixed  

---

## CRITICAL RULES

**DON'T:**
- Delete core system files
- Remove actual functionality
- Break existing features

**DO:**
- Reduce refresh rates
- Disable verbose logging
- Fix syntax errors
- Remove test files

**MAX ITERATIONS:** 1

This is optimization task. Find, fix, done.

---

## BEGIN EXECUTION

Scan files, apply fixes, report results.

**GO! 🚀**
