--!strict

-- =========================================
-- PASRAHPHOBIA - Server Bootstrap
-- =========================================

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

if _G.__PASRAH_LOBBY_BRIDGE_CONNECTED ~= true then
	_G.__PASRAH_LOBBY_BRIDGE_CONNECTED = true
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
	local lobbyEvent = remoteFolder:WaitForChild("LobbyEvent")
	local serverFolder = ServerScriptService:WaitForChild("Server")
	local serverBootstrapModule = serverFolder:WaitForChild("ServerBootstrap")
	local lobbyFolder = serverFolder:FindFirstChild("Lobby")

	local function ensureRegistry()
		if _G.SystemRegistry then
			return _G.SystemRegistry
		end

		local okBootstrap, serverBootstrap = pcall(require, serverBootstrapModule)
		if okBootstrap and type(serverBootstrap) == "table" and type(serverBootstrap.Start) == "function" then
			serverBootstrap.Start()
		end

		return _G.SystemRegistry
	end

	lobbyEvent.OnServerEvent:Connect(function(player, request)
		if _G.__PASRAH_LOBBY_FALLBACK_LOADED == true then
			return
		end

		local registry = ensureRegistry()
		local lobbySystem = registry and type(registry.Get) == "function" and registry:Get("LobbySystem") or nil
		local controller = lobbySystem and lobbySystem.Controller or nil

		-- Primary connection is active: do not duplicate processing.
		if controller and controller._remoteConnection and controller._remoteConnection.Connected then
			return
		end

		-- TODO: REMOVE AFTER VALIDATION
		print("[ROOM TRACE][BOOT BRIDGE RECEIVED]", request and request.action, "from", player.Name)

		if controller and type(controller.OnLobbyRemoteRequest) == "function" then
			local ok, err = pcall(function()
				controller:OnLobbyRemoteRequest(player, request)
			end)
			if not ok then
				-- TODO: REMOVE AFTER VALIDATION
				warn("[ROOM TRACE][BOOT BRIDGE ERROR]", tostring(err))
			end
		else
			-- TODO: REMOVE AFTER VALIDATION
			warn("[ROOM TRACE][BOOT BRIDGE] LobbySystem controller unavailable")
			if lobbyFolder and _G.__PASRAH_LOBBY_FALLBACK_LOADING ~= true then
				_G.__PASRAH_LOBBY_FALLBACK_LOADING = true
				local handlerModule = lobbyFolder:FindFirstChild("LobbyEventHandler")
				if handlerModule then
					local ok, err = pcall(require, handlerModule)
					if ok then
						_G.__PASRAH_LOBBY_FALLBACK_LOADED = true
						-- TODO: REMOVE AFTER VALIDATION
						print("[ROOM TRACE][BOOT BRIDGE] Fallback LobbyEventHandler loaded")
					else
						-- TODO: REMOVE AFTER VALIDATION
						warn("[ROOM TRACE][BOOT BRIDGE] Fallback load failed:", tostring(err))
					end
				else
					-- TODO: REMOVE AFTER VALIDATION
					warn("[ROOM TRACE][BOOT BRIDGE] Fallback module missing")
				end
			end
		end
	end)
end
