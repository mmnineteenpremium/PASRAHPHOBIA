--!strict

-- =========================================
-- PASRAHPHOBIA - Server Bootstrap
-- =========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- =========================================
-- API Check
-- =========================================

local function apiEnabled(): boolean
	local success, result = pcall(function()
		return RunService:IsStudio()
	end)
	return success and result
end

if not apiEnabled() then
	warn("[Bootstrap] API Services are disabled! Enable them in Game Settings -> Security.")
else
	print("[Bootstrap] API Services are enabled - ready for DataStore & Marketplace.")
end

print("[Bootstrap] PASRAHPHOBIA skeleton loaded.")

-- =========================================
-- Module Wiring
-- =========================================

local ServerScriptService = game:GetService("ServerScriptService")

local ModulesFolder = ServerScriptService:WaitForChild("Modules")

local MapLoader = require(ModulesFolder:WaitForChild("MapLoader"))
local SpawnPointsSetup = require(ServerScriptService:WaitForChild("SpawnPointsSetup"))
print("SpawnPointsSetup value:", SpawnPointsSetup)
print("SpawnPointsSetup.Setup:", SpawnPointsSetup and SpawnPointsSetup.Setup)

-- =========================================
-- Deterministic Map Load
-- =========================================

local ACTIVE_MAP = "AbandonedPalace"

local function initializeMap()
	print("[Bootstrap] Initializing map:", ACTIVE_MAP)

	local mapModel = MapLoader.Load(ACTIVE_MAP)
 
	assert(mapModel, "Failed to load map: " .. ACTIVE_MAP)

	local playerSpawns, ghostSpawns = SpawnPointsSetup.Setup(mapModel)

	print("[Bootstrap] Player spawns:", #playerSpawns)
	print("[Bootstrap] Ghost spawns:", #ghostSpawns)

	print("[Bootstrap] Map initialization complete.")
end

initializeMap()

-- =========================================
-- RemoteEvent Wiring
-- =========================================

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local function getRemote(name: string)
	local remote = RemoteEvents:FindFirstChild(name)
	assert(remote and remote:IsA("RemoteEvent"), "Missing RemoteEvent: " .. name)
	return remote
end

local LobbyEvent = getRemote("LobbyEvent")

LobbyEvent.OnServerEvent:Connect(function(player)
	print("[LobbyEvent] Fired by:", player.Name)
end)