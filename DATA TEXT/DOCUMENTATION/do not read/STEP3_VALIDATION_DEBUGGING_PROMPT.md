# STEP 3 VALIDATION - COMPREHENSIVE DEBUGGING & TESTING PROMPT

## CONTEXT

Session 5 completed two critical UI fixes:
1. ✅ RoomBrowser toggle hardening (Main.lua)
2. ✅ LobbyEventTap queue spam gating (LobbyEventTap.client.lua)

**Current Phase:** Step 3 - Local server 2-player multiplayer test  
**Goal:** Validate entire RoomBrowser → Queue → Match flow with clean logs and working UI

---

## YOUR MISSION

Create comprehensive debugging infrastructure and validation test suite to verify:
1. RoomBrowser toggle works (open → close → reopen)
2. No queue spam in logs
3. Room creation/join flow works
4. Ready system works
5. Host start → countdown → match pipeline works
6. 2-player flow: both teleport to same map

---

## FILES IN SCOPE

**PRIMARY TARGETS:**
- `src/client/UI/Main.lua` (toggle verification)
- `src/client/LobbyEventTap.client.lua` (queue spam verification)
- `src/client/RoomBrowserController.lua` (state verification)

**SECONDARY (Create New):**
- `src/client/RoomBrowserDebugger.client.lua` (NEW - debugging utilities)
- `src/server/DevTestCommands.server.lua` (NEW - test automation commands)

**REFERENCE (Read-Only):**
- `src/server/LobbySystem/Service.lua` (server-side flow)
- `src/server/MatchSystem/MatchService.lua` (match creation)

---

## EXECUTION STEPS

### PHASE 1: CREATE DEBUGGING INFRASTRUCTURE

**FILE 1: `src/client/RoomBrowserDebugger.client.lua`**

Create client-side debugging utility with:

```lua
-- RoomBrowserDebugger.client.lua
-- Provides live UI state monitoring and test commands

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoomBrowserDebugger = {}

-- State tracking
local debugState = {
    toggleCount = 0,
    lastOpen = 0,
    lastClose = 0,
    queueBroadcasts = 0,
    queueBlocked = 0,
}

-- Command interface
function RoomBrowserDebugger:LogState(label)
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local roomBrowserUI = playerGui:FindFirstChild("RoomBrowserUI")
    
    print(string.format(
        "[RBDebug:%s] Exists:%s Enabled:%s Toggles:%d Open:%d Close:%d QueueOK:%d QueueBlock:%d",
        label,
        tostring(roomBrowserUI ~= nil),
        roomBrowserUI and tostring(roomBrowserUI.Enabled) or "N/A",
        debugState.toggleCount,
        debugState.lastOpen,
        debugState.lastClose,
        debugState.queueBroadcasts,
        debugState.queueBlocked
    ))
end

-- Hook into toggle events
function RoomBrowserDebugger:TrackToggle(action)
    debugState.toggleCount += 1
    if action == "open" then
        debugState.lastOpen = tick()
    elseif action == "close" then
        debugState.lastClose = tick()
    end
    self:LogState(action)
end

-- Hook into queue events
function RoomBrowserDebugger:TrackQueue(broadcast)
    if broadcast then
        debugState.queueBroadcasts += 1
    else
        debugState.queueBlocked += 1
    end
end

-- Auto-test sequence
function RoomBrowserDebugger:RunAutoTest()
    print("[RBDebug] ===== AUTO TEST START =====")
    
    -- Test 1: Toggle sequence
    print("[RBDebug] Test 1: Toggle sequence")
    self:LogState("initial")
    task.wait(1)
    
    -- Simulate open
    print("[RBDebug] Simulating OPEN...")
    self:TrackToggle("open")
    task.wait(2)
    
    -- Simulate close
    print("[RBDebug] Simulating CLOSE...")
    self:TrackToggle("close")
    task.wait(2)
    
    -- Simulate reopen
    print("[RBDebug] Simulating REOPEN...")
    self:TrackToggle("open")
    task.wait(2)
    
    print("[RBDebug] ===== AUTO TEST COMPLETE =====")
    self:LogState("final")
end

-- Expose globally for command bar
_G.RBDebug = RoomBrowserDebugger

return RoomBrowserDebugger
```

**FILE 2: `src/server/DevTestCommands.server.lua`**

Create server-side test automation:

```lua
-- DevTestCommands.server.lua
-- Automated testing commands for development

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then return end

local SystemRegistry = require(
    ServerScriptService:WaitForChild("Server")
    :WaitForChild("Core")
    :WaitForChild("SystemRegistry")
)

local DevTestCommands = {}

-- Test 1: Auto-create room for player
function DevTestCommands:AutoCreateRoom(player)
    print(string.format("[DevTest] Creating room for %s", player.Name))
    
    local lobbyService = SystemRegistry:GetService("LobbySystem")
    if not lobbyService then
        warn("[DevTest] LobbySystem not found")
        return false
    end
    
    -- Simulate CreateRoom action
    local ok, reason = lobbyService:QueueFromRoomBrowser(player, {
        action = "CreateRoom"
    })
    
    print(string.format("[DevTest] CreateRoom result: %s, %s", tostring(ok), tostring(reason)))
    return ok
end

-- Test 2: Auto-ready player
function DevTestCommands:AutoReady(player)
    print(string.format("[DevTest] Setting %s to ready", player.Name))
    
    local lobbyService = SystemRegistry:GetService("LobbySystem")
    if not lobbyService then
        warn("[DevTest] LobbySystem not found")
        return false
    end
    
    local ok, reason = lobbyService:QueueFromRoomBrowser(player, {
        action = "SetReady",
        isReady = true
    })
    
    print(string.format("[DevTest] SetReady result: %s, %s", tostring(ok), tostring(reason)))
    return ok
end

-- Test 3: Auto-start match (host only)
function DevTestCommands:AutoStartMatch(player)
    print(string.format("[DevTest] Starting match for host %s", player.Name))
    
    local lobbyService = SystemRegistry:GetService("LobbySystem")
    if not lobbyService then
        warn("[DevTest] LobbySystem not found")
        return false
    end
    
    local ok, reason = lobbyService:QueueFromRoomBrowser(player, {
        action = "HostStart",
        mapId = "HauntedHouse",
        difficulty = "Mudah",
        mode = "Classic"
    })
    
    print(string.format("[DevTest] HostStart result: %s, %s", tostring(ok), tostring(reason)))
    return ok
end

-- Full 2-player test sequence
function DevTestCommands:Run2PlayerTest()
    print("[DevTest] ===== 2-PLAYER TEST SEQUENCE START =====")
    
    task.spawn(function()
        -- Wait for 2 players
        repeat
            task.wait(1)
        until #Players:GetPlayers() >= 2
        
        local player1 = Players:GetPlayers()[1]
        local player2 = Players:GetPlayers()[2]
        
        print(string.format("[DevTest] Player1: %s | Player2: %s", player1.Name, player2.Name))
        
        -- Step 1: Player1 creates room
        task.wait(3)
        print("[DevTest] Step 1: Player1 creates room")
        self:AutoCreateRoom(player1)
        
        -- Step 2: Player2 joins room
        task.wait(2)
        print("[DevTest] Step 2: Player2 should join via UI (manual)")
        
        -- Step 3: Both ready
        task.wait(5)
        print("[DevTest] Step 3: Setting both players ready")
        self:AutoReady(player1)
        task.wait(1)
        self:AutoReady(player2)
        
        -- Step 4: Host starts match
        task.wait(3)
        print("[DevTest] Step 4: Host starting match")
        self:AutoStartMatch(player1)
        
        print("[DevTest] ===== 2-PLAYER TEST SEQUENCE COMPLETE =====")
        print("[DevTest] Check logs for match creation and teleport")
    end)
end

-- Expose globally for command bar
_G.DevTest = DevTestCommands

print("[DevTest] Commands loaded. Use _G.DevTest:Run2PlayerTest() to start")

return DevTestCommands
```

---

### PHASE 2: INTEGRATE DEBUGGER WITH EXISTING SYSTEMS

**MODIFY: `src/client/UI/Main.lua`**

Add debugger hooks to toggle handlers:

```lua
-- At top of file (after other requires)
local RoomBrowserDebugger = require(script.Parent.Parent.RoomBrowserDebugger)

-- In Open button handler (around line 267):
addButton("OpenRoomBrowser", "Open Room Browser", y, function()
    uiDebug("OpenRoomBrowser clicked")
    RoomBrowserDebugger:TrackToggle("open")  -- ADD THIS
    self:_ensureRoomBrowserGui()
    self:_setRoomBrowserVisible(true)
    -- ... rest of handler
end)

-- In Close button handler (around line 414):
closeButton.Activated:Connect(function()
    RoomBrowserDebugger:TrackToggle("close")  -- ADD THIS
    self:_setRoomBrowserVisible(false)
end)
```

**MODIFY: `src/client/LobbyEventTap.client.lua`**

Add debugger hooks to queue broadcast logic:

```lua
-- At top of file
local RoomBrowserDebugger = require(script.Parent.Parent.StarterGui.RoomBrowserDebugger)

-- In broadcast gating logic (where QUEUE_ACTIONS check happens):
if not QUEUE_ACTIONS[action] then
    RoomBrowserDebugger:TrackQueue(false)  -- ADD THIS
    print(string.format("[LobbyEventTap] Skipping non-queue action: %s", action))
    return
end

if playerAlreadyQueued then
    RoomBrowserDebugger:TrackQueue(false)  -- ADD THIS
    print("[LobbyEventTap] Already queued - skipping broadcast")
    return
end

-- Before successful broadcast:
RoomBrowserDebugger:TrackQueue(true)  -- ADD THIS
```

---

### PHASE 3: CREATE VALIDATION CHECKLIST

**FILE 3: `TEST_CHECKLIST.md`** (in project root)

```markdown
# STEP 3 VALIDATION CHECKLIST

## Pre-Test Setup
- [ ] Rojo connected and synced
- [ ] Studio in Local Server mode (2+ player slots)
- [ ] Output window visible
- [ ] Both player slots spawned in LobbySocialHub

## Test 1: RoomBrowser Toggle
**Player 1 Actions:**
1. [ ] Click "Open Room Browser" button in LobbyUI
2. [ ] Verify: RoomBrowserUI appears centered
3. [ ] Verify: Log shows `[RBDebug:open]` with state
4. [ ] Click Close button (X)
5. [ ] Verify: RoomBrowserUI hidden
6. [ ] Verify: Log shows `[RBDebug:close]` with state
7. [ ] Click "Open Room Browser" again
8. [ ] Verify: RoomBrowserUI reappears
9. [ ] Verify: Log shows `[RBDebug:open]` with state

**Expected Logs:**
```
[RBDebug:open] Exists:true Enabled:true Toggles:1 ...
[RBDebug:close] Exists:true Enabled:false Toggles:2 ...
[RBDebug:open] Exists:true Enabled:true Toggles:3 ...
```

**PASS/FAIL:** ______

---

## Test 2: Queue Broadcast Gating
**Player 1 Actions:**
1. [ ] Open RoomBrowser
2. [ ] Click "Classic" mode button
3. [ ] Click "Mudah" difficulty button
4. [ ] Click "Refresh" button
5. [ ] Verify: NO `[QueueCall]` logs appear
6. [ ] Verify: Logs show `[LobbyEventTap] Skipping non-queue action`

**Expected Logs:**
```
[LobbyEventTap] Action: SelectMode | Broadcast: false
[LobbyEventTap] Skipping non-queue action: SelectMode
[LobbyEventTap] Action: SelectDifficulty | Broadcast: false
[LobbyEventTap] Skipping non-queue action: SelectDifficulty
```

**NO spam:** `already_queued`, `[QueueCall]` repeated

**PASS/FAIL:** ______

---

## Test 3: Room Creation Flow
**Player 1 Actions:**
1. [ ] Open RoomBrowser
2. [ ] Click "Buat Room" button
3. [ ] Verify: Room panel appears on right
4. [ ] Verify: Log shows `[LobbySystem] CreateRoom`
5. [ ] Verify: Room appears in room list

**Expected Logs:**
```
[LobbySystem] CreateRoom action for Player1
[RoomManager] Room created: #1
[LobbyEvent] RoomStateUpdate sent to Player1
```

**PASS/FAIL:** ______

---

## Test 4: Room Join Flow
**Player 2 Actions:**
1. [ ] Open RoomBrowser
2. [ ] Click room row in room list
3. [ ] Verify: Room panel appears
4. [ ] Verify: Player1 shown as Host
5. [ ] Verify: Player2 shown in player list

**Expected Logs:**
```
[LobbySystem] JoinRoom action for Player2
[RoomManager] Player2 joined room #1
[LobbyEvent] RoomStateUpdate sent to all in room
```

**PASS/FAIL:** ______

---

## Test 5: Ready System
**Both Players:**
1. [ ] Player1 clicks "SIAP" button
2. [ ] Verify: Button text changes to "BATALKAN SIAP"
3. [ ] Player2 clicks "SIAP" button
4. [ ] Verify: Player1 sees "MULAI PERMAINAN" button appear

**Expected Logs:**
```
[LobbySystem] SetReady: Player1 = true
[LobbySystem] SetReady: Player2 = true
[RoomManager] All ready: 2/2
```

**PASS/FAIL:** ______

---

## Test 6: Match Start Flow
**Player 1 (Host) Actions:**
1. [ ] Verify: "MULAI PERMAINAN" button visible (both ready)
2. [ ] Click "MULAI PERMAINAN"
3. [ ] Verify: Countdown overlay appears (5...4...3...2...1)
4. [ ] Verify: Both players teleport to HauntedHouse
5. [ ] Verify: Match pipeline logs appear

**Expected Logs:**
```
[LobbySystem] HostStart action from Player1
[RoomManager] Starting match for room #1
[MatchQueue] Players added to queue
[MatchBuilder] Match created: matchId_XXX
[MatchLifecycle] Starting match
[MatchTeleport] Teleporting 2 players to HauntedHouse
```

**PASS/FAIL:** ______

---

## Test 7: Automated Test (Optional)
**Command Bar:**
```lua
_G.DevTest:Run2PlayerTest()
```

**Verify:** Entire flow runs automatically and completes successfully

**PASS/FAIL:** ______

---

## FINAL VALIDATION

**Overall Result:** PASS / FAIL  
**Issues Found:** [List any issues]  
**Next Steps:** [Phase 6 or fix issues]
```

---

## OUTPUT

### DELIVERABLE 1: New Debug Files
- `src/client/RoomBrowserDebugger.client.lua` (state monitoring)
- `src/server/DevTestCommands.server.lua` (test automation)
- `TEST_CHECKLIST.md` (validation guide)

### DELIVERABLE 2: Modified Files
- `src/client/UI/Main.lua` (debugger hooks added)
- `src/client/LobbyEventTap.client.lua` (debugger hooks added)

### DELIVERABLE 3: Validation Report
After Miftah runs tests, document:
- Which tests passed
- Which tests failed
- Exact logs captured
- Issues identified

---

## AFTER EXECUTION

Update reports.md:
```markdown
## 2026-03-17 (Session 5 - Debugging Phase)

### Completed
- RoomBrowserDebugger created: state monitoring + auto-test
- DevTestCommands created: 2-player automation
- Debug hooks integrated: Main.lua + LobbyEventTap
- TEST_CHECKLIST created: 7 validation tests

### Files Created
- src/client/RoomBrowserDebugger.client.lua
- src/server/DevTestCommands.server.lua
- TEST_CHECKLIST.md

### Files Modified
- src/client/UI/Main.lua: Debugger hooks at toggle points
- src/client/LobbyEventTap.client.lua: Queue tracking hooks

### Next Action
- Run TEST_CHECKLIST in Studio
- Document pass/fail results
- Fix any failures before Phase 6
```

---

## CRITICAL RULES

**DO:**
✅ Create comprehensive debugging infrastructure
✅ Add non-intrusive hooks (logging only)
✅ Provide clear test checklist
✅ Enable automated testing
✅ Make validation reproducible

**DO NOT:**
❌ Modify core logic (only add logging)
❌ Change existing behavior
❌ Break any working systems
❌ Add performance overhead

**MAX ITERATIONS:** 2 (3rd = RCA mandatory)

---

## BEGIN EXECUTION

Create debugging infrastructure and validation framework to enable comprehensive Step 3 testing.

**GO! 🚀**
