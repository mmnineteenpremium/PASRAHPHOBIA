# EMERGENCY FIX - BROKEN CLIENT PATHS

## CRITICAL ERRORS DETECTED

```
1. LobbyEventTap:47 - FireServer not valid
2. Main.lua:6 - Invalid require argument
3. Client bootstrap chain: BROKEN
```

## YOUR MISSION

**Fix file paths and require statements immediately.**

---

## ISSUE 1: LobbyEventTap.client.lua

**Error:** `FireServer is not a valid member of RemoteEvent`  
**Location:** Line 47

**FIND & FIX:**

Search file: `src/client/LobbyEventTap.client.lua`

**WRONG CODE (likely):**
```lua
-- Line 47 area - probably has:
lobbyRemote.FireServer(...)  -- WRONG! Missing colon
```

**CORRECT CODE:**
```lua
lobbyRemote:FireServer(...)  -- CORRECT! Use colon
```

**OR if path issue:**
```lua
-- Check if lobbyRemote is actually a RemoteEvent
-- Should be:
local lobbyRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("LobbyEvent")

-- NOT:
local lobbyRemote = ReplicatedStorage.RemoteEvents.LobbyEvent  -- Might not exist yet
```

---

## ISSUE 2: UI/Main.lua Require Path

**Error:** `Attempted to call require with invalid argument(s)`  
**Location:** Line 6

**FIND & FIX:**

Search file: `src/client/UI/Main.lua`

**Line 6 likely has:**
```lua
local RoomBrowserDebugger = require(script.Parent.Parent.RoomBrowserDebugger)
```

**PROBLEM:** Path incorrect!

**CHECK FILE STRUCTURE:**
```
src/client/
├── UI/
│   └── Main.lua  ← You are here
└── RoomBrowserDebugger.client.lua  ← Target

Correct path from Main.lua:
script.Parent.Parent.RoomBrowserDebugger
              ↑      ↑
            Client   RoomBrowserDebugger
```

**VERIFY & FIX:**
```lua
-- Option 1: If RoomBrowserDebugger is in src/client/
local RoomBrowserDebugger = require(script.Parent.Parent:WaitForChild("RoomBrowserDebugger"))

-- Option 2: If it's in different location, use absolute path:
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RoomBrowserDebugger = player.PlayerScripts.Client:WaitForChild("RoomBrowserDebugger")
local RoomBrowserDebugger = require(RoomBrowserDebugger)

-- Option 3: Safest - check if exists first:
local debuggerModule = script.Parent.Parent:FindFirstChild("RoomBrowserDebugger")
local RoomBrowserDebugger = debuggerModule and require(debuggerModule) or nil

-- Then guard usage:
if RoomBrowserDebugger then
    RoomBrowserDebugger:TrackToggle("open")
end
```

---

## ISSUE 3: Client Bootstrap Chain

**All client-side modules failed to load.**

**ROOT CAUSE:** Main.lua line 6 breaks → entire chain fails

**FIX PRIORITY:**
1. Fix Main.lua:6 require path
2. Fix LobbyEventTap:47 FireServer
3. Restart to verify chain loads

---

## EXECUTION STEPS

### STEP 1: Find Actual File Locations

```bash
# In project root, search for files:
# Windows PowerShell:
Get-ChildItem -Recurse -Filter "*RoomBrowserDebugger*"
Get-ChildItem -Recurse -Filter "LobbyEventTap.client.lua"
Get-ChildItem -Recurse -Filter "Main.lua" | Where-Object {$_.Directory.Name -eq "UI"}
```

### STEP 2: Fix LobbyEventTap.client.lua

**Find line 47:**
```lua
-- BEFORE (broken):
lobbyRemote.FireServer(request)

-- AFTER (fixed):
lobbyRemote:FireServer(request)
```

**OR if it's a WaitForChild issue:**
```lua
-- BEFORE:
local lobbyRemote = remoteFolder:FindFirstChild("LobbyEvent")

-- AFTER:
local lobbyRemote = remoteFolder:WaitForChild("LobbyEvent", 10)
if not lobbyRemote then
    warn("[LobbyEventTap] LobbyEvent remote not found!")
    return
end
```

### STEP 3: Fix UI/Main.lua Line 6

**Current broken line:**
```lua
local RoomBrowserDebugger = require(script.Parent.Parent.RoomBrowserDebugger)
```

**Fixed with safety:**
```lua
-- Safe require with fallback
local RoomBrowserDebugger
local debuggerPath = script.Parent.Parent:FindFirstChild("RoomBrowserDebugger")
if debuggerPath then
    local success, result = pcall(require, debuggerPath)
    if success then
        RoomBrowserDebugger = result
        print("[UISystem] RoomBrowserDebugger loaded")
    else
        warn("[UISystem] RoomBrowserDebugger require failed:", result)
    end
else
    warn("[UISystem] RoomBrowserDebugger module not found at script.Parent.Parent")
end

-- Guard all usage later in file:
-- BEFORE:
RoomBrowserDebugger:TrackToggle("open")

-- AFTER:
if RoomBrowserDebugger then
    RoomBrowserDebugger:TrackToggle("open")
end
```

### STEP 4: Verify LobbyEventTap Path

**Check require statement in LobbyEventTap.client.lua:**

**If it tries to require RoomBrowserDebugger:**
```lua
-- Likely broken:
local RoomBrowserDebugger = require(script.Parent.Parent.StarterGui.RoomBrowserDebugger)

-- Should be (depends on actual structure):
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local client = playerScripts:WaitForChild("Client")
local debugger = client:WaitForChild("RoomBrowserDebugger")
local RoomBrowserDebugger = require(debugger)
```

---

## QUICK FIX STRATEGY

**If you can't find exact paths, make requires OPTIONAL:**

### Fix Main.lua (Line 6):
```lua
local RoomBrowserDebugger
pcall(function()
    RoomBrowserDebugger = require(script.Parent.Parent.RoomBrowserDebugger)
end)
```

### Fix LobbyEventTap (Line 47):
```lua
-- Change dot to colon
lobbyRemote:FireServer(request)
```

### Guard all RoomBrowserDebugger usage:
```lua
-- Find all lines like:
RoomBrowserDebugger:TrackToggle("open")

-- Wrap with:
if RoomBrowserDebugger then
    RoomBrowserDebugger:TrackToggle("open")
end
```

---

## OUTPUT

Report:
1. What you changed in LobbyEventTap.client.lua
2. What you changed in UI/Main.lua
3. File structure confirmation (where files actually are)

---

## AFTER EXECUTION

Miftah should:
1. F5 reload Studio
2. Check Output for bootstrap errors
3. Verify client loads without errors
4. Test RoomBrowser toggle again

---

## MAX ITERATIONS: 1

This is emergency fix. Get client loading first. Optimization later.

**GO! 🚀**
