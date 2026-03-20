local RoomRegistry = require(script.Parent.RoomRegistry)

local RoomService = {}
RoomService.__index = RoomService

local SUPPORTED_MODES = {
	Classic = true,
	Ranked = true,
}

local ALLOWED_MAPS = {
	AbandonedPalace = true,
	StudioMMNineteen = true,
	EmptyBuilding = true,
	HauntedHouse = true,
}

local function resolveMatchService(deps)
	if type(deps) ~= "table" then
		return nil
	end
	if type(deps.MatchService) == "table" then
		return deps.MatchService
	end
	if type(deps.MatchSystem) == "table" then
		if type(deps.MatchSystem.StartRoomMatch) == "function" then
			return deps.MatchSystem
		end
		if type(deps.MatchSystem.Service) == "table" and type(deps.MatchSystem.Service.StartRoomMatch) == "function" then
			return deps.MatchSystem.Service
		end
	end
	if type(deps.Services) == "table" and type(deps.Services.Get) == "function" then
		local match = deps.Services:Get("MatchSystem") or deps.Services:Get("MatchService")
		if type(match) == "table" then
			if type(match.StartRoomMatch) == "function" then
				return match
			end
			if type(match.Service) == "table" and type(match.Service.StartRoomMatch) == "function" then
				return match.Service
			end
		end
	end
	return nil
end

local function findRoomByPlayer(player)
	local rooms = RoomRegistry.GetRooms()
	for _, room in pairs(rooms) do
		for _, member in ipairs(room.players or {}) do
			if member == player then
				return room
			end
		end
	end
	return nil
end

local function listContains(list, player)
	for _, member in ipairs(list or {}) do
		if member == player then
			return true
		end
	end
	return false
end

local function removeFromList(list, player)
	for index, member in ipairs(list or {}) do
		if member == player then
			table.remove(list, index)
			return true
		end
	end
	return false
end

local function updateOpenState(room)
	if room.state == "IN_MATCH" or room.state == "STARTING" then
		return
	end
	if #room.players >= room.maxPlayers then
		room.state = "FULL"
	else
		room.state = "OPEN"
	end
end

local function isHost(room, player)
	return room and room.hostPlayer == player
end

function RoomService.new(deps)
	local self = setmetatable({}, RoomService)
	self._deps = deps or {}
	self._matchService = resolveMatchService(self._deps)
	return self
end

function RoomService:CreateRoom()
	return RoomRegistry.CreateRoom()
end

function RoomService:JoinRoom(player, roomId)
	return RoomRegistry.JoinRoom(player, roomId)
end

function RoomService:LeaveRoom(player)
	return RoomRegistry.LeaveRoom(player)
end

function RoomService:SetRoomMode(player, roomId, mode)
	local rooms = RoomRegistry.GetRooms()
	local room = rooms[roomId]
	if not room then
		return false, "missing_room"
	end
	if not isHost(room, player) then
		return false, "not_room_host"
	end
	if not SUPPORTED_MODES[mode] then
		return false, "unsupported_mode"
	end
	room.mode = mode
	print("[Room] Mode changed", mode)
	return true
end

function RoomService:SetRoomMap(player, roomId, mapName)
	local rooms = RoomRegistry.GetRooms()
	local room = rooms[roomId]
	if not room then
		return false, "missing_room"
	end
	if not isHost(room, player) then
		return false, "not_room_host"
	end
	if not ALLOWED_MAPS[mapName] then
		return false, "invalid_map"
	end
	room.selectedMap = mapName
	return true
end

function RoomService:KickPlayer(host, roomId, targetPlayer)
	local rooms = RoomRegistry.GetRooms()
	local room = rooms[roomId]
	if not room then
		return false, "missing_room"
	end
	if not isHost(room, host) then
		return false, "not_room_host"
	end
	removeFromList(room.players, targetPlayer)
	removeFromList(room.readyPlayers, targetPlayer)

	if room.hostPlayer == targetPlayer then
		room.hostPlayer = room.players[1]
	end

	updateOpenState(room)
	return true
end

function RoomService:SetPlayerReady(player, roomId, ready)
	local rooms = RoomRegistry.GetRooms()
	local room = rooms[roomId] or findRoomByPlayer(player)
	if not room then
		return false, "missing_room"
	end
	if room.state == "IN_MATCH" then
		return false, "room_in_match"
	end

	if ready == true then
		if not listContains(room.readyPlayers, player) then
			table.insert(room.readyPlayers, player)
		end
	else
		removeFromList(room.readyPlayers, player)
	end

	print("[RoomReady] Player ready state changed", player.Name)

	if #room.players > 0 and #room.readyPlayers == #room.players then
		room.state = "READY"
		room.state = "STARTING"
		task.spawn(function()
			for seconds = 5, 1, -1 do
				print("[Room] Match starting in " .. tostring(seconds) .. "...")
				task.wait(1)
			end
			if room.state ~= "STARTING" then
				return
			end
			self:StartMatch(room.players)
		end)
	else
		if room.state == "READY" or room.state == "STARTING" then
			updateOpenState(room)
		end
	end

	return true
end

function RoomService:SetReady(player)
	local room = findRoomByPlayer(player)
	if not room then
		return false, "not_in_room"
	end
	return self:SetPlayerReady(player, room.id, true)
end

function RoomService:StartMatch(playersOrRoomId)
	local players = nil
	local room = nil

	if type(playersOrRoomId) == "table" then
		players = playersOrRoomId
		room = players[1] and findRoomByPlayer(players[1]) or nil
	else
		local rooms = RoomRegistry.GetRooms()
		room = rooms[playersOrRoomId]
		players = room and room.players or nil
	end

	if not players then
		return false, "missing_room"
	end
	if not self._matchService then
		self._matchService = resolveMatchService(self._deps)
	end
	if not self._matchService or type(self._matchService.StartRoomMatch) ~= "function" then
		return false, "missing_match_service"
	end

	if room then
		room.state = "IN_MATCH"
	end

	return self._matchService:StartRoomMatch(players)
end

function RoomService:StartMatchManual(host, roomId)
	local rooms = RoomRegistry.GetRooms()
	local room = rooms[roomId]
	if not room then
		return false, "missing_room"
	end
	if not isHost(room, host) then
		return false, "not_room_host"
	end
	if #room.players < 1 then
		return false, "not_enough_players"
	end
	return self:StartMatch(room.players)
end

return RoomService
