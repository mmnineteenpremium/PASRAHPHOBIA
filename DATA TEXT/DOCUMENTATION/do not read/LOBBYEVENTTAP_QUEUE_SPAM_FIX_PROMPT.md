# LOBBYEVENTTAP QUEUE SPAM FIX - EXECUTION PROMPT

## CONTEXT

Session 5 completed RoomBrowser toggle hardening. Next blocker: LobbyEventTap aggressive queue broadcasting causes `already_queued` spam and constant state refresh, making UI feel broken.

**Root Cause Identified:** Server-side `LobbyEventTap.server.lua` calls `QueueFromRoomBrowser` for ALL actions instead of only action = "queue". Client-side gating needed.

---

## YOUR MISSION

Fix LobbyEventTap queue broadcast spam by adding client-side action gating. Only trigger queue flow when player explicitly requests queue, not on every room browser action.

---

## FILES IN SCOPE

**PRIMARY TARGET:**
- `src/client/LobbyEventTap.client.lua` (upload required - not yet available)

**REFERENCE (Read-Only):**
- `src/server/LobbyEventTap.server.lua` (server-side - shows current broken behavior)
- `src/client/RoomBrowserController.lua` (shows all possible actions)

---

## EXECUTION STEPS

### STEP 1: Audit Current Broadcast Logic
Read `LobbyEventTap.client.lua` and identify:
- How queue broadcasts are triggered
- What conditions gate the broadcast
- If player state is checked before broadcasting

### STEP 2: Identify Queue Actions
From `RoomBrowserController.lua`, valid queue-triggering actions are:
- `"QueueFromRoomBrowser"` (line 86)
- `"queue"` (legacy - if exists)

All other actions should NOT trigger queue broadcast:
- `"RequestRoomBrowserSnapshot"`
- `"RequestRoomList"`
- `"SelectMode"`
- `"SelectDifficulty"`
- `"JoinRoom"`
- `"LeaveRoom"`
- `"SetReady"`
- `"HostStart"`
- `"KickPlayer"`
- `"SetPassword"`
- `"CreateRoom"`

### STEP 3: Add Action Whitelist
Modify `LobbyEventTap.client.lua`:
```lua
local QUEUE_ACTIONS = {
    ["QueueFromRoomBrowser"] = true,
    ["queue"] = true,  -- legacy support if needed
}

-- Before broadcasting queue event:
if not QUEUE_ACTIONS[action] then
    -- Skip queue broadcast for non-queue actions
    return
end
```

### STEP 4: Add Player State Check
Add guard to prevent queue spam when already queued:
```lua
local playerAlreadyQueued = false  -- track local state

-- Before broadcasting:
if playerAlreadyQueued then
    print("[LobbyEventTap] Already queued - skipping broadcast")
    return
end

-- After successful queue:
playerAlreadyQueued = true

-- On match start or queue leave:
playerAlreadyQueued = false
```

### STEP 5: Add Diagnostic Logging
Add logging to show gating decisions:
```lua
print(string.format("[LobbyEventTap] Action: %s | Queued: %s | Broadcast: %s", 
    action, tostring(playerAlreadyQueued), tostring(shouldBroadcast)))
```

---

## OUTPUT

### DELIVERABLE 1: Fixed LobbyEventTap.client.lua
Modified file with:
- Action whitelist (QUEUE_ACTIONS)
- Player state tracking (playerAlreadyQueued flag)
- Broadcast gating logic
- Diagnostic logging

### DELIVERABLE 2: Verification Notes
Document:
- What was changed (line numbers)
- Why it was changed (root cause)
- Expected behavior after fix

---

## EXPECTED BEHAVIOR AFTER FIX

**BEFORE (Broken):**
```
User clicks SelectMode → LobbyEventTap broadcasts queue → Server: already_queued
User clicks JoinRoom → LobbyEventTap broadcasts queue → Server: already_queued
User clicks SetReady → LobbyEventTap broadcasts queue → Server: already_queued
(Repeat for every action = spam)
```

**AFTER (Fixed):**
```
User clicks SelectMode → LobbyEventTap: not a queue action, skip broadcast ✅
User clicks JoinRoom → LobbyEventTap: not a queue action, skip broadcast ✅
User clicks Queue button → LobbyEventTap: queue action + not queued = broadcast ✅
Server: queue successful → Client: playerAlreadyQueued = true
User clicks Queue button again → LobbyEventTap: already queued, skip ✅
```

---

## AFTER EXECUTION

Update reports.md:
```markdown
## 2026-03-17 (Session 5 Continued)

### Completed
- LobbyEventTap queue spam fix: COMPLETED
- Action whitelist added: QueueFromRoomBrowser only
- Player state tracking: playerAlreadyQueued flag
- Diagnostic logging: broadcast decisions visible

### Issues Resolved
| Issue | Status | Resolution |
| ----- | ------ | ---------- |
| LobbyEventTap aggressive queue | FIXED | Added QUEUE_ACTIONS whitelist + state guard |
| already_queued spam | FIXED | playerAlreadyQueued flag prevents repeat broadcasts |

### Files Modified
- src/client/LobbyEventTap.client.lua: Action gating + state tracking

### Next Action
- Test in Studio: verify no queue spam in logs
- Proceed to Step 3: 2-player validation
```

Append to existing reports.md (DO NOT overwrite).

---

## CRITICAL RULES

**DO:**
✅ Add action whitelist (surgical change)
✅ Add player state flag (simple boolean)
✅ Add logging for debugging
✅ Preserve all existing functionality
✅ Keep changes minimal and focused

**DO NOT:**
❌ Modify server-side files
❌ Change RoomBrowserController
❌ Modify Main.lua (already fixed)
❌ Introduce new systems
❌ Break existing room browser flow

**MAX ITERATIONS:** 2 (3rd = RCA mandatory - return to architect)

---

## BEGIN EXECUTION

**STATUS:** AWAITING FILE UPLOAD

**Required:** `src/client/LobbyEventTap.client.lua`

Once file is uploaded, execute fix with above specifications.

**GO! 🚀**
