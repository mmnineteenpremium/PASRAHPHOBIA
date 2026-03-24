local RoomManager = {}
RoomManager.__index = RoomManager

local ROOM_COUNT = 10
local MAX_PLAYERS = 4

function RoomManager.new()
	local self = setmetatable({}, RoomManager)
	self.rooms = {}

	for i = 1, ROOM_COUNT do
		self.rooms[i] = {
			id = i,
			players = {},
			maxPlayers = MAX_PLAYERS,
			status = "waiting",
			host = nil,
			readyPlayers = {},
			inGame = false,
			starting = false,
			password = nil,
		}
	end

	return self
end

function RoomManager:GetHost(roomId)
	local room = self.rooms[roomId]
	if not room then
		return nil
	end
	return room.host
end

function RoomManager:IsHost(player, roomId)
	local room = self.rooms[roomId]
	if not room then
		return false
	end
	return room.host == player
end

function RoomManager:JoinRoom(player, roomId, password)
	local room = self.rooms[roomId]
	if not room then
		return false, "room_not_found"
	end

	if room.inGame or room.starting then
		return false, "room_in_game"
	end

	if #room.players >= room.maxPlayers then
		return false, "room_full"
	end

	if room.password and room.password ~= password then
		return false, "wrong_password"
	end

	for _, member in ipairs(room.players) do
		if member == player then
			return false, "already_in_room"
		end
	end

	table.insert(room.players, player)
	if #room.players == 1 then
		room.host = player
	end
	if room.host == player then
		room.readyPlayers[player] = true
	else
		room.readyPlayers[player] = nil
	end

	return true
end

function RoomManager:LeaveRoom(player)
	for _, room in pairs(self.rooms) do
		for index, member in ipairs(room.players) do
			if member == player then
				table.remove(room.players, index)
				room.readyPlayers[player] = nil

				if room.host == player then
					room.host = room.players[1] or nil
					if room.starting then
						room.starting = false
						room.inGame = false
					end
				end

				if #room.players == 0 then
					room.status = "waiting"
					room.inGame = false
					room.starting = false
					room.readyPlayers = {}
					room.host = nil
				end

				return true
			end
		end
	end

	return false
end

function RoomManager:SetReady(player, isReady)
	local room = self:GetRoomByPlayer(player)
	if not room then
		return false, "not_in_room"
	end
	if room.inGame then
		return false, "room_in_game"
	end

	if room.host == player then
		room.readyPlayers[player] = true
	else
		room.readyPlayers[player] = isReady and true or nil
	end

	local allReady = #room.players > 0
	for _, member in ipairs(room.players) do
		if not room.readyPlayers[member] then
			allReady = false
			break
		end
	end

	room.status = allReady and "all_ready" or "waiting"
	return true, allReady
end

function RoomManager:IsAllReady(roomId)
	local room = self.rooms[roomId]
	if not room or #room.players == 0 then
		return false
	end

	for _, member in ipairs(room.players) do
		if not room.readyPlayers[member] then
			return false
		end
	end

	return true
end

function RoomManager:KickPlayer(host, targetPlayer)
	local room = self:GetRoomByPlayer(host)
	if not room then
		return false, "not_in_room"
	end
	if room.host ~= host then
		return false, "not_host"
	end
	if host == targetPlayer then
		return false, "cannot_kick_self"
	end

	for index, member in ipairs(room.players) do
		if member == targetPlayer then
			table.remove(room.players, index)
			room.readyPlayers[targetPlayer] = nil
			return true
		end
	end

	return false, "player_not_in_room"
end

function RoomManager:SetPassword(host, password)
	local room = self:GetRoomByPlayer(host)
	if not room then
		return false, "not_in_room"
	end
	if room.host ~= host then
		return false, "not_host"
	end

	room.password = (password and password ~= "") and password or nil
	return true
end

function RoomManager:SetInGame(roomId, value, preserveReady)
	local room = self.rooms[roomId]
	if not room then
		return false
	end

	room.inGame = value
	if value then
		room.starting = true
		room.status = "starting"
	else
		room.starting = false
		room.status = "waiting"
		if not preserveReady then
			room.readyPlayers = {}
		end
	end

	return true
end

function RoomManager:GetRooms()
	return self.rooms
end

function RoomManager:GetRoomById(roomId)
	return self.rooms[roomId]
end

function RoomManager:GetRoomByPlayer(player)
	for _, room in pairs(self.rooms) do
		for _, member in ipairs(room.players) do
			if member == player then
				return room
			end
		end
	end
	return nil
end

return RoomManager
