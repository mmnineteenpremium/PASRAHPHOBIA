local RoomRegistry = {}

local rooms = {}
local nextRoomIndex = 1
local DEFAULT_MAX_PLAYERS = 4

local function formatRoomId(index)
	return string.format("Room%02d", index)
end

local function findRoomByPlayer(player)
	for _, room in pairs(rooms) do
		for _, member in ipairs(room.players or {}) do
			if member == player then
				return room
			end
		end
	end
	return nil
end

local function removePlayerFromList(list, player)
	for index, member in ipairs(list or {}) do
		if member == player then
			table.remove(list, index)
			return true
		end
	end
	return false
end

function RoomRegistry.CreateRoom()
	local roomId = formatRoomId(nextRoomIndex)
	nextRoomIndex += 1

	local room = {
		id = roomId,
		players = {},
		readyPlayers = {},
		hostPlayer = nil,
		maxPlayers = DEFAULT_MAX_PLAYERS,
		mode = "Classic",
		selectedMap = nil,
		state = "OPEN",
	}

	rooms[roomId] = room
	return room
end

function RoomRegistry.JoinRoom(player, roomId)
	local room = rooms[roomId]
	if not room then
		return false, "missing_room"
	end

	if room.state == "IN_MATCH" then
		return false, "room_in_match"
	end

	local existing = findRoomByPlayer(player)
	if existing and existing.id ~= roomId then
		RoomRegistry.LeaveRoom(player)
	elseif existing and existing.id == roomId then
		return true
	end

	if #room.players >= room.maxPlayers then
		room.state = "FULL"
		return false, "room_full"
	end

	table.insert(room.players, player)

	if not room.hostPlayer then
		room.hostPlayer = player
	end

	if #room.players >= room.maxPlayers then
		room.state = "FULL"
	else
		room.state = "OPEN"
	end

	return true
end

function RoomRegistry.LeaveRoom(player)
	local room = findRoomByPlayer(player)
	if not room then
		return false, "not_in_room"
	end

	removePlayerFromList(room.players, player)
	removePlayerFromList(room.readyPlayers, player)

	if room.hostPlayer == player then
		room.hostPlayer = room.players[1]
	end

	if #room.players == 0 then
		room.state = "OPEN"
		room.readyPlayers = {}
	elseif #room.players < room.maxPlayers and room.state ~= "IN_MATCH" then
		room.state = "OPEN"
	end

	return true
end

function RoomRegistry.GetRooms()
	return rooms
end

return RoomRegistry
