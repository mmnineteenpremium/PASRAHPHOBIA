local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

if not RunService:IsStudio() then
	return {}
end

local SystemRegistry = require(
	ServerScriptService:WaitForChild("Server")
		:WaitForChild("Core")
		:WaitForChild("SystemRegistry")
)

local DevTestCommands = {}

local function resolveLobbyService()
	local service = SystemRegistry:GetService("LobbySystem")
	if service then
		return service
	end
	return SystemRegistry:Get("LobbySystem")
end

function DevTestCommands:AutoCreateRoom(player)
	local lobbyService = resolveLobbyService()
	if not lobbyService then
		return false
	end

	local ok, reason = lobbyService:QueueFromRoomBrowser(player, {
		action = "CreateRoom",
	})

	return ok
end

function DevTestCommands:AutoReady(player)
	local lobbyService = resolveLobbyService()
	if not lobbyService then
		return false
	end

	local ok, reason = lobbyService:QueueFromRoomBrowser(player, {
		action = "SetReady",
		isReady = true,
	})

	return ok
end

function DevTestCommands:AutoStartMatch(player)
	local lobbyService = resolveLobbyService()
	if not lobbyService then
		return false
	end

	local ok, reason = lobbyService:QueueFromRoomBrowser(player, {
		action = "HostStart",
		mapId = "HauntedHouse",
		difficulty = "Mudah",
		mode = "Classic",
	})

	return ok
end

function DevTestCommands:Run2PlayerTest()
	task.spawn(function()
		repeat
			task.wait(1)
		until #Players:GetPlayers() >= 2

		local players = Players:GetPlayers()
		local player1 = players[1]
		local player2 = players[2]

		task.wait(3)
		self:AutoCreateRoom(player1)

		task.wait(2)
		task.wait(5)
		self:AutoReady(player1)
		task.wait(1)
		self:AutoReady(player2)

		task.wait(3)
		self:AutoStartMatch(player1)
	end)
end

_G.DevTest = DevTestCommands

return DevTestCommands
