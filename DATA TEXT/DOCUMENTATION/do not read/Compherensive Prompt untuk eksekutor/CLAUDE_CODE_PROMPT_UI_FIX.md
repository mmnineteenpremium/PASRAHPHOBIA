# CLAUDE CODE CLI PROMPT — UI GENERATION & FIX
## For: PASRAHPHOBIA RoomBrowser UI Issue
## Date: 2026-03-17
---

## CONTEXT

You are working on PASRAHPHOBIA, a Roblox horror investigation game.

**Project Structure:**
- Language: Luau (Roblox)
- Architecture: Server-Authoritative, modular backend
- Boot Status: ✅ Clean (88ms, 0 failed)
- Sync Tool: Rojo (live sync enabled)

**Current Problem:**
- Step 2: Match Flow Test is ACTIVE
- Server-side room navigation is WORKING (JOIN/LEAVE verified)
- **CLIENT-SIDE UI IS BLOCKED** — "RUANG INVESTIGASI" panel not appearing
- Root cause: RoomBrowserDebugUI still active + UISystem/Main.lua._ensureRoomBrowserGui() likely returning early

**What Exists Already:**
- ✅ RoomManager (server): host tracking, ready system, kick, password, inGame
- ✅ LobbySystem.Service: SetReady, HostStartMatch, KickPlayer, SetRoomPassword
- ✅ RoomBrowserController (client): CreateRoom, SetReady, HostStart, KickPlayer, SetPassword
- ✅ LobbyEventTap (server): wired and firing actions correctly

**What's Missing/Broken:**
- ❌ UISystem/Main.lua._ensureRoomBrowserGui() — either missing or not destroying old GUI
- ❌ RoomBrowserDebugUI — still active, possibly blocking new UI

---

## TASK

### Part 1: Audit Existing UI Files
Search and report on these files:
1. `src/StarterGui/RoomBrowserDebugUI.client.lua` (if exists)
2. `src/StarterGui/UISystem/` (folder and Main.lua if exists)
3. `src/client/UI/RoomBrowserController.lua`

Report:
- Full path of each file
- First 50 lines of content (to verify status)
- Whether file contains "_ensureRoomBrowserGui" or similar

Do NOT edit anything in this step. Read-only.

### Part 2: Create/Fix UISystem/Main.lua

**Location:** `src/StarterGui/UISystem/Main.lua`

**Requirements:**
- Implement UISystem module with initialization and GUI management
- Function `_ensureRoomBrowserGui()` MUST:
  1. Check if `self._roomBrowserGui` exists → if yes, DESTROY it first
  2. Create new ScreenGui named "RoomBrowserGui"
  3. Build room list widget (10 fixed rows initially, then dynamic via _refreshRoomBrowserView)
  4. Build in-room panel with title "RUANG INVESTIGASI"
  5. Add buttons: CreateRoom, SetReady (label: "SIAP"), HostStart (label: "MULAI"), LeaveRoom
  6. Add countdown overlay (initially hidden, shown on HostStart)
  7. Add map selector dropdown
  8. Enable and show the GUI to player
- Function `_refreshRoomBrowserView(roomList)`:
  1. Update room list dynamically
  2. Refresh player count, room status, ready count
  3. Show in-room panel if player is in a room

**Implementation Details:**

```lua
local UISystem = {}
UISystem.__index = UISystem

function UISystem.new()
    local self = setmetatable({}, UISystem)
    self._player = game.Players.LocalPlayer
    self._playerGui = self._player:WaitForChild("PlayerGui")
    self._roomBrowserGui = nil
    self._lobbyRemote = game:GetService("ReplicatedStorage")
        :WaitForChild("RemoteEvents")
        :WaitForChild("LobbyEvent")
    return self
end

function UISystem:Init()
    print("[UISystem] Init")
    self:_ensureRoomBrowserGui()
end

function UISystem:_ensureRoomBrowserGui()
    -- DESTROY old GUI if it exists
    if self._roomBrowserGui then
        self._roomBrowserGui:Destroy()
        self._roomBrowserGui = nil
    end

    -- Create new ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RoomBrowserGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = self._playerGui

    -- Add room list frame (left side)
    local roomListFrame = Instance.new("Frame")
    roomListFrame.Name = "RoomListFrame"
    roomListFrame.Size = UDim2.new(0.6, 0, 1, 0)
    roomListFrame.Position = UDim2.new(0, 0, 0, 0)
    roomListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    roomListFrame.BorderSizePixel = 0
    roomListFrame.Parent = screenGui

    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "RUANG INVESTIGASI"
    titleLabel.TextSize = 24
    titleLabel.BorderSizePixel = 0
    titleLabel.Parent = roomListFrame

    -- Add room list scrolling frame
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "RoomListScrollFrame"
    listFrame.Size = UDim2.new(1, 0, 1, -50)
    listFrame.Position = UDim2.new(0, 0, 0, 50)
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 12
    listFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
    listFrame.Parent = roomListFrame

    -- Store reference
    self._roomBrowserGui = screenGui
    self._roomListFrame = listFrame
    self._titleLabel = titleLabel

    print("[UISystem] _ensureRoomBrowserGui created successfully")
end

function UISystem:_refreshRoomBrowserView(roomList)
    if not self._roomListFrame then return end
    
    -- Clear existing room items
    for _, child in ipairs(self._roomListFrame:GetChildren()) do
        child:Destroy()
    end

    -- Create room items
    if roomList then
        for i, room in ipairs(roomList) do
            local roomButton = Instance.new("TextButton")
            roomButton.Name = "RoomButton_" .. room.roomId
            roomButton.Size = UDim2.new(1, 0, 0, 60)
            roomButton.Position = UDim2.new(0, 0, 0, (i-1) * 60)
            roomButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            roomButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            roomButton.Text = room.hostName .. " (" .. room.readyCount .. "/" .. room.maxPlayers .. ")"
            roomButton.TextSize = 14
            roomButton.BorderSizePixel = 1
            roomButton.BorderColor3 = Color3.fromRGB(80, 80, 100)
            roomButton.Parent = self._roomListFrame

            -- Update CanvasSize
            self._roomListFrame.CanvasSize = UDim2.new(1, 0, 0, i * 60)
        end
    end

    print("[UISystem] _refreshRoomBrowserView updated")
end

function UISystem:Start()
    print("[UISystem] Start")
end

function UISystem:Shutdown()
    print("[UISystem] Shutdown")
    if self._roomBrowserGui then
        self._roomBrowserGui:Destroy()
        self._roomBrowserGui = nil
    end
end

return UISystem
```

### Part 3: Disable/Remove RoomBrowserDebugUI (if blocking)

Check if `src/StarterGui/RoomBrowserDebugUI.client.lua` is:
1. Still active as a Script/LocalScript in Studio
2. If yes: comment out the initialization or set `enabled = false`
3. Report action taken

---

## EXECUTION ORDER

1. **Read audit results** → identify which files exist and their state
2. **Create/Update UISystem/Main.lua** → at `src/StarterGui/UISystem/Main.lua`
3. **Disable RoomBrowserDebugUI** → if it's blocking
4. **Verify**: 
   - File created/updated ✅
   - No syntax errors ✅
   - Rojo sync ready (no output yet needed)

---

## VALIDATION CHECKLIST

After execution, confirm:

- [ ] UISystem/Main.lua created at correct path
- [ ] _ensureRoomBrowserGui() function present and destroys old GUI
- [ ] _refreshRoomBrowserView() function present
- [ ] No Luau syntax errors
- [ ] File ready for Rojo sync
- [ ] RoomBrowserDebugUI audited and status reported

---

## NOTES

- Do NOT test or call functions — just create the file
- Do NOT modify reports.md or other docs — focus on source only
- Do NOT rebuild LobbySystem, RoomManager, or RoomBrowserController — those are DONE
- Full file creation only — no partial patches
- Use `task.wait()` not `wait()` per project rules

---

## Next Step (for Miftah)

After Claude Code CLI executes this:
1. Press F5 in Studio (Rojo will sync the new file)
2. Check if "RUANG INVESTIGASI" panel appears
3. Report screenshot to verify fix worked

---

**END OF PROMPT**
