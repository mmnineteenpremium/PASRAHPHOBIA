# CLAUDE CODE CLI PROMPT — DELETE LEGACY FILE
## Remove RoomBrowserDebugUI.client.lua (causing interference)
## Owner: Miftah | Date: 2026-03-17 | Mode: EXECUTE & VERIFY

---

## FILE TO DELETE

**src/StarterPlayer/StarterPlayerScripts/RoomBrowserDebugUI.client.lua**

This file is:
- Legacy implementation (pre-dating current File B UISystem)
- Still executing despite ENABLE_LEGACY=false flag
- Interfering with File B's UI rendering
- No longer needed (all functionality in File B)

---

## VERIFICATION BEFORE DELETE

**Search for any references to RoomBrowserDebugUI in codebase:**

1. Check if any other file requires/imports RoomBrowserDebugUI
   - Search: "RoomBrowserDebugUI"
   - In all Lua files

2. Report: Are there any dependencies?
   - If YES: DO NOT DELETE, report findings
   - If NO: Safe to proceed with deletion

---

## DELETE PROCEDURE

If verification shows NO dependencies:

1. Delete file: `src/StarterPlayer/StarterPlayerScripts/RoomBrowserDebugUI.client.lua`
   - Use: filesystem delete operation
   - Confirm: File removal

2. Verify deletion:
   - Check file no longer exists
   - Report: "File deleted successfully"

---

## POST-DELETE TEST

After deletion:

1. F5 reload Studio
2. Check output console
3. Look for:
   - ❌ NO "[RBUI] started" log (old file gone)
   - ✅ File B UI should now be sole renderer
4. Player can now see File B buttons clearly

---

## SUCCESS CRITERIA

After deletion + F5 reload:

```
OLD (broken):
05:16:50.521  [RBUI] started  -  Client - RoomBrowserDebugUI:10

NEW (clean):
[No [RBUI] log]
[File B UI renders cleanly]
```

---

## SAFETY NOTES

- This file is NOT required by bootstrap chain
- This file is NOT referenced elsewhere in codebase  
- This file is legacy/deprecated
- Deletion will NOT break any core systems

---

## EXECUTE

1. ✅ Verify no dependencies (search for references)
2. ✅ Delete file
3. ✅ Confirm deletion
4. ✅ Report success

**GO!** 🗑️
