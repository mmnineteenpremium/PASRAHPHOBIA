# CLAUDE CODE CLI PROMPT — TRACE CURRENTROOM UPDATE FLOW
## Instrument code with debug logs to identify break point
## Owner: Miftah | Date: 2026-03-17 | Mode: EXECUTE & TEST

---

## OBJECTIVE

Add strategic debug logs to trace **currentRoom update flow** when player joins room.

Identify EXACTLY where chain breaks:
- Does _onRoomJoined callback fire?
- Does LobbyEvent get received?
- Does HandleLobbyEvent execute?
- Does currentRoom actually get set?
- Does refreshRoomPanel show panel?

---

## FILE TO MODIFY

**src/client/UI/Main.lua**

---

## INSTRUMENTATION POINTS

### Point 1: _onRoomJoined Callback (Line 848-850)

**CURRENT CODE (lines 848-850):**
```lua
self._roomBrowser._onRoomJoined = function(roomId)
  currentRoom = roomId
end
```

**ADD DEBUG LOG:**
```lua
self._roomBrowser._onRoomJoined = function(roomId)
  uiDebug("[TRACE] _onRoomJoined fired with roomId: " .. tostring(roomId))
  currentRoom = roomId
  uiDebug("[TRACE] currentRoom now set to: " .. tostring(currentRoom))
end
```

---

### Point 2: LobbyEvent Subscription (Lines 87-92)

**FIND:** The OnClientEvent:Connect block in Start() function

**CURRENT CODE (lines 87-92, approximately):**
```lua
remote.OnClientEvent:Connect(function(action, payload)
  ...
end)
```

**ADD DEBUG LOG at start of handler:**
```lua
remote.OnClientEvent:Connect(function(action, payload)
  uiDebug("[TRACE] LobbyEvent received: action=" .. tostring(action))
  ...
end)
```

---

### Point 3: HandleLobbyEvent Call (Lines 117-118)

**CURRENT CODE (lines 117-118, approximately):**
```lua
self._roomBrowser:HandleLobbyEvent(payload)
```

**ADD DEBUG LOGS:**
```lua
uiDebug("[TRACE] Calling HandleLobbyEvent with payload type: " .. type(payload))
self._roomBrowser:HandleLobbyEvent(payload)
uiDebug("[TRACE] HandleLobbyEvent completed")
```

---

### Point 4: State Updates in _refreshRoomBrowserView (Lines 923-926, 934-936)

**FIND:** Lines where currentRoom is set from state

**CURRENT CODE (lines 923-926):**
```lua
if state.currentRoom and state.currentRoom.roomId then
  currentRoom = state.currentRoom.roomId
end
```

**ADD DEBUG LOG:**
```lua
if state.currentRoom and state.currentRoom.roomId then
  uiDebug("[TRACE] Setting currentRoom from state.currentRoom: " .. tostring(state.currentRoom.roomId))
  currentRoom = state.currentRoom.roomId
else
  uiDebug("[TRACE] state.currentRoom is: " .. tostring(state.currentRoom))
end
```

**CURRENT CODE (lines 934-936):**
```lua
if state.lastRoomId and state.RoomBrowserRoomJoined then
  currentRoom = state.lastRoomId
end
```

**ADD DEBUG LOG:**
```lua
if state.lastRoomId and state.RoomBrowserRoomJoined then
  uiDebug("[TRACE] Setting currentRoom from state.lastRoomId: " .. tostring(state.lastRoomId))
  currentRoom = state.lastRoomId
else
  uiDebug("[TRACE] state.lastRoomId: " .. tostring(state.lastRoomId) .. ", RoomBrowserRoomJoined: " .. tostring(state.RoomBrowserRoomJoined))
end
```

---

### Point 5: refreshRoomPanel Entry (Line 708-710)

**CURRENT CODE (lines 708-710):**
```lua
local function refreshRoomPanel(rooms)
  if not currentRoom then
    roomPanel.Visible = false
    return
```

**ADD DEBUG LOG:**
```lua
local function refreshRoomPanel(rooms)
  uiDebug("[TRACE] refreshRoomPanel called, currentRoom: " .. tostring(currentRoom))
  if not currentRoom then
    uiDebug("[TRACE] currentRoom is nil, hiding roomPanel")
    roomPanel.Visible = false
    return
```

---

### Point 6: refreshRoomPanel Success (Line 725)

**CURRENT CODE (line 725):**
```lua
roomPanel.Visible = true
```

**ADD DEBUG LOG BEFORE:**
```lua
uiDebug("[TRACE] Found room data, showing roomPanel")
roomPanel.Visible = true
uiDebug("[TRACE] roomPanel.Visible now: " .. tostring(roomPanel.Visible))
```

---

## TESTING PROCEDURE

After instrumentation:

1. **Start Studio with Roblox game**
2. **Open Output window** (View → Output)
3. **Have Player1 ready**
4. **Have Player2 ready to join**

### Test Scenario:

```
STEP 1: Player1 in lobby
  → Open room list (SelectMode, SelectDifficulty)
  → Observe console (should see RequestRoomList logs)

STEP 2: Player1 clicks CreateRoom
  → Observe: Does [TRACE] CreateRoom clicked appear?
  → Observe: Does handleLobbyEvent show room created?

STEP 3: Player1 joins room
  → Observe: Does _onRoomJoined fire with roomId?
  → Observe: Does currentRoom get set?
  → Observe: Does refreshRoomPanel see currentRoom?
  → Observe: Does roomPanel.Visible become true?

STEP 4: Check if buttons visible
  → If roomPanel visible → buttons should show
  → If not visible → chain broke somewhere
```

---

## EXPECTED LOG OUTPUT

If working correctly:

```
[TRACE] RequestRoomList action received
[TRACE] LobbyEvent received: action=RoomList
[TRACE] Calling HandleLobbyEvent with payload type: table
[TRACE] HandleLobbyEvent completed

[TRACE] refreshRoomPanel called, currentRoom: nil
[TRACE] currentRoom is nil, hiding roomPanel

[TRACE] _onRoomJoined fired with roomId: 5
[TRACE] currentRoom now set to: 5

[TRACE] refreshRoomPanel called, currentRoom: 5
[TRACE] Found room data, showing roomPanel
[TRACE] roomPanel.Visible now: true
```

If chain breaks:

```
[TRACE] refreshRoomPanel called, currentRoom: nil
[TRACE] currentRoom is nil, hiding roomPanel

[TRACE] LobbyEvent received: action=RoomJoined
[TRACE] Calling HandleLobbyEvent...
[TRACE] HandleLobbyEvent completed

❌ NO _onRoomJoined log!
❌ refreshRoomPanel still shows currentRoom: nil
❌ roomPanel stays hidden
```

---

## WHAT TO REPORT AFTER TEST

```
FINDINGS:

1. Which logs appear vs missing?
   [List what you see in console]

2. At what point does chain break?
   [Identify exact log where flow stops]

3. What is currentRoom value?
   [Nil? Set to number? Wrong value?]

4. Does refreshRoomPanel show roomPanel?
   [YES = buttons should show]
   [NO = roomPanel hidden, buttons invisible]

5. Console error messages?
   [Any red errors that explain issue?]

ROOT CAUSE FROM LOGS:
[Based on which traces appear/missing, identify the break]
```

---

## CRITICAL NOTES

- **Do NOT change behavior** (only add logs)
- **Use uiDebug()** (already defined in file, safe to use)
- **Do NOT delete existing code** (only insert logs)
- **Keep log format consistent** (all start with `[TRACE]`)
- **Run test immediately** (join room, check console output)

---

## EXECUTION STEPS

1. ✅ Add debug logs to all 6 points above
2. ✅ Save file
3. ✅ F5 reload studio
4. ✅ Player1: create room
5. ✅ Player1: join room
6. ✅ Watch Output console
7. ✅ Report which logs appear/missing
8. ✅ Identify exact break point

---

**EXECUTE NOW. Report console output immediately.** 🔍

This will show us EXACTLY where currentRoom update fails.
