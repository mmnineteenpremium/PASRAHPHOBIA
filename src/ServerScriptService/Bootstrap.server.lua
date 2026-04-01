--!strict

-- =========================================
-- PASRAHPHOBIA - Server Bootstrap
-- =========================================

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- =========================================
-- API Check
-- =========================================

local function isStudioRuntime(): boolean
	local success, result = pcall(function()
		return RunService:IsStudio()
	end)
	return success and result == true
end

if isStudioRuntime() then
	print("[Bootstrap] Studio runtime detected.")
else
	print("[Bootstrap] Live runtime detected - ready for DataStore & Marketplace.")
end

print("[Bootstrap] PASRAHPHOBIA skeleton loaded.")

print("[Bootstrap] Map loading skipped - maps load via MatchBuilder")
print("[Bootstrap] Server ready for lobby operations")

if _G.__PASRAH_SERVER_BOOT_DONE ~= true then
	_G.__PASRAH_SERVER_BOOT_DONE = true
	local serverFolder = ServerScriptService:WaitForChild("Server")
	local serverBootstrapModule = serverFolder:WaitForChild("ServerBootstrap")
	local serverBootstrap = require(serverBootstrapModule)
	if type(serverBootstrap) == "table" and type(serverBootstrap.Start) == "function" then
		serverBootstrap.Start()
	end
end
