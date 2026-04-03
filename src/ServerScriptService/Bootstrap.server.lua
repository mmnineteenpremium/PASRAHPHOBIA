--!strict

-- =========================================
-- PASRAHPHOBIA - Server Bootstrap
-- =========================================

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local function hasStudioE2EReady(): boolean
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		return false
	end

	local remote = remoteFolder:FindFirstChild("StudioE2EControl")
	return remote ~= nil and ReplicatedStorage:GetAttribute("PasrahStudioE2EReady") == true
end

local function ensureStudioE2EFallback(serverFolder)
	if not isStudioRuntime() or hasStudioE2EReady() then
		return
	end

	local existing = _G.__PASRAH_STUDIO_E2E_BOOTSTRAP_INSTANCE
	if type(existing) == "table" and type(existing.Start) == "function" then
		existing:Start()
		if hasStudioE2EReady() then
			print("[Bootstrap] StudioE2EControlSystem restarted via bootstrap fallback")
			return
		end
	end

	local systemContainer = serverFolder:FindFirstChild("StudioE2EControlSystem")
	local systemModule = systemContainer and systemContainer:FindFirstChild("Main")
	if not (systemModule and systemModule:IsA("ModuleScript")) then
		warn("[Bootstrap] StudioE2E bootstrap fallback skipped: missing module")
		return
	end

	local loaded = require(systemModule)
	local instance = loaded
	if type(loaded) == "table" and type(loaded.new) == "function" then
		local registry = rawget(_G, "SystemRegistry")
		instance = loaded.new({
			Services = registry,
			ServiceRegistry = registry,
		})
	end

	if type(instance) ~= "table" then
		warn("[Bootstrap] StudioE2E bootstrap fallback failed: invalid instance")
		return
	end

	if type(instance.Init) == "function" then
		instance:Init()
	end
	if type(instance.Start) == "function" then
		instance:Start()
	end

	_G.__PASRAH_STUDIO_E2E_BOOTSTRAP_INSTANCE = instance
	if hasStudioE2EReady() then
		print("[Bootstrap] StudioE2EControlSystem started via bootstrap fallback")
	else
		warn("[Bootstrap] StudioE2E bootstrap fallback did not expose remote")
	end
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
	ensureStudioE2EFallback(serverFolder)
end
