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
[LobbyEventTap] Skipping non-queue action: SelectMode
[LobbyEventTap] Skipping non-queue action: SelectDifficulty
```

**PASS/FAIL:** ______

---

## Test 3: Room Creation Flow
**Player 1 Actions:**
1. [ ] Open RoomBrowser
2. [ ] Click "Buat Room" button
3. [ ] Verify: Room panel appears on right
4. [ ] Verify: Log shows `CreateRoom` round-trip
5. [ ] Verify: Room appears in room list

**Expected Logs:**
```
[LobbySystem] CreateRoom action
[RoomManager] Room created
[LobbyEvent] RoomStateUpdate broadcasted
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
[LobbySystem] JoinRoom action
[RoomManager] Player joined room
[LobbyEvent] RoomStateUpdate broadcasted
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
3. [ ] Verify: Countdown overlay appears
4. [ ] Verify: Both players teleport to HauntedHouse
5. [ ] Verify: Match pipeline logs appear

**Expected Logs:**
```
[LobbySystem] HostStart action
[MatchBuilder] Match created
[MatchLifecycle] Starting match
[MatchTeleport] Teleported players to HauntedHouse
```

**PASS/FAIL:** ______

---

## Test 7: Automated Test (Optional)
**Command Bar:**
```
_G.DevTest:Run2PlayerTest()
```

**Verify:** Entire flow runs automatically and completes successfully

**PASS/FAIL:** ______

---

## FINAL VALIDATION
**Overall Result:** PASS / FAIL  
**Issues Found:** [List any issues]  
**Next Steps:** [Phase 6 or fix issues]
