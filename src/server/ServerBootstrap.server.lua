print("=== PASRAHPHOBIA SERVER BOOT START ===")
print("[BOOT] Server bootstrap started")

local Core = script.Parent:WaitForChild("Core")
local SystemRegistry = require(Core:WaitForChild("SystemRegistry"))

SystemRegistry:Initialize()
SystemRegistry:Start()

print("=== PASRAHPHOBIA SERVER BOOT COMPLETE ===")
print("[BOOT] PASRAHPOBIA READY")
