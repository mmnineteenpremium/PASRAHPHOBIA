local RoomManager = {}
RoomManager.__index = RoomManager

local DEFAULT_MAX_PLAYERS = 4

local function findPlayerIndex(players, target)
    for index, player in ipairs(players) do
        if player == target then
            return index
        end
    end
    return nil
end

local function removePlayer(players, target)
    local index = findPlayerIndex(players, target)
    if index then
        table.remove(players, index)
        return true
    end
    return false
end

function RoomManager.new()
    local self = setmetatable({}, RoomManager)
    self._nextRoomId = 1
    self._roomsById = {}
    self._roomByUserId = {}
    return self
end

function RoomManager:_allPlayersReady(room)
    if not room or #room.players == 0 then
        return false
    end
    -- Host does not need to mark ready in multiplayer; only non-host members must be ready.
    local hasNonHostMember = false
    for _, player in ipairs(room.players) do
        if player ~= room.host then
            hasNonHostMember = true
            if room.readyByUserId[player.UserId] ~= true then
                return false
            end
        end
    end
    if not hasNonHostMember then
        return true
    end
    return true
end

function RoomManager:_refreshReadyState(room)
    if room.state == "Countdown" or room.state == "InGame" then
        return
    end
    if self:_allPlayersReady(room) then
        room.state = "ALL_READY"
    else
        room.state = "Waiting"
    end
end

function RoomManager:GetRoomByPlayer(player)
    if not player then
        return nil
    end
    local roomId = self._roomByUserId[player.UserId]
    if not roomId then
        return nil
    end
    return self._roomsById[roomId]
end

function RoomManager:GetRoomById(roomId)
    return self._roomsById[roomId]
end

function RoomManager:GetRooms()
    local rooms = {}
    for _, room in pairs(self._roomsById) do
        table.insert(rooms, room)
    end
    table.sort(rooms, function(a, b)
        return a.roomId < b.roomId
    end)
    return rooms
end

function RoomManager:SerializeRoom(room)
    if not room then
        return nil
    end

    local players = {}
    for _, player in ipairs(room.players) do
        table.insert(players, {
            userId = player.UserId,
            name = player.Name,
            ready = room.readyByUserId[player.UserId] == true,
            isHost = room.host == player,
        })
    end

    return {
        roomId = room.roomId,
        hostUserId = room.host and room.host.UserId or nil,
        hostName = room.host and room.host.Name or nil,
        players = players,
        playerCount = #room.players,
        maxPlayers = room.maxPlayers,
        mode = room.mode,
        state = room.state,
        starting = room.state == "Countdown",
        inGame = room.state == "InGame",
        hasPassword = false,
        mapId = room.mapId,
        difficulty = room.difficulty,
    }
end

function RoomManager:CreateRoom(hostPlayer, options)
    if not hostPlayer then
        return nil, "invalid_player"
    end

    local existingRoom = self:GetRoomByPlayer(hostPlayer)
    if existingRoom then
        return existingRoom
    end

    local roomId = self._nextRoomId
    self._nextRoomId += 1

    local room = {
        roomId = roomId,
        host = hostPlayer,
        players = { hostPlayer },
        readyByUserId = {
            [hostPlayer.UserId] = true,
        },
        maxPlayers = options and options.maxPlayers or DEFAULT_MAX_PLAYERS,
        mode = options and options.mode or "Classic",
        state = "Waiting",
        mapId = options and options.mapId or nil,
        difficulty = options and options.difficulty or nil,
        countdownToken = 0,
    }

    self._roomsById[roomId] = room
    self._roomByUserId[hostPlayer.UserId] = roomId
    self:_refreshReadyState(room)
    return room
end

function RoomManager:JoinRoom(player, roomId)
    if not player then
        return nil, "invalid_player"
    end
    local room = self._roomsById[roomId]
    if not room then
        return nil, "room_not_found"
    end
    if room.state == "Countdown" or room.state == "InGame" then
        return nil, "room_unavailable"
    end
    if #room.players >= room.maxPlayers then
        return nil, "room_full"
    end

    local currentRoom = self:GetRoomByPlayer(player)
    if currentRoom then
        if currentRoom.roomId == room.roomId then
            return room
        end
        return nil, "already_in_room"
    end

    table.insert(room.players, player)
    room.readyByUserId[player.UserId] = false
    self._roomByUserId[player.UserId] = room.roomId
    self:_refreshReadyState(room)
    return room
end

function RoomManager:LeaveRoom(player)
    local room = self:GetRoomByPlayer(player)
    if not room then
        return nil, "not_in_room"
    end

    local wasHost = room.host == player
    local wasCountdown = room.state == "Countdown"

    removePlayer(room.players, player)
    room.readyByUserId[player.UserId] = nil
    self._roomByUserId[player.UserId] = nil

    if #room.players == 0 then
        self._roomsById[room.roomId] = nil
        return nil
    end

    if wasHost then
        room.host = room.players[1]
        room.readyByUserId[room.host.UserId] = true
    end

    if wasCountdown then
        room.countdownToken += 1
        room.state = "Waiting"
    end

    self:_refreshReadyState(room)
    return room
end

function RoomManager:SetReady(player, isReady)
    local room = self:GetRoomByPlayer(player)
    if not room then
        return nil, "not_in_room"
    end
    if room.state == "Countdown" or room.state == "InGame" then
        return nil, "room_locked"
    end

    local nextReady = isReady
    if nextReady == nil then
        nextReady = room.readyByUserId[player.UserId] ~= true
    end

    room.readyByUserId[player.UserId] = nextReady == true
    self:_refreshReadyState(room)
    return room
end

function RoomManager:GetReadyState(room, player)
    if not room or not player then
        return false
    end
    return room.readyByUserId[player.UserId] == true
end

function RoomManager:AreAllReady(room)
    return self:_allPlayersReady(room)
end

function RoomManager:CanStartMatch(player)
    local room = self:GetRoomByPlayer(player)
    if not room then
        return false, "not_in_room"
    end
    if room.host ~= player then
        return false, "not_host"
    end
    if room.state == "Countdown" then
        return false, "already_countdown"
    end
    if room.state == "InGame" then
        return false, "already_ingame"
    end
    if not self:_allPlayersReady(room) then
        return false, "players_not_ready"
    end
    return true, nil, room
end

function RoomManager:BeginCountdown(player)
    local ok, reason, room = self:CanStartMatch(player)
    if not ok then
        return nil, reason
    end

    room.countdownToken += 1
    room.state = "Countdown"
    return room
end

function RoomManager:CancelCountdown(player)
    local room = self:GetRoomByPlayer(player)
    if not room then
        return nil, "not_in_room"
    end
    if room.host ~= player then
        return nil, "not_host"
    end
    if room.state ~= "Countdown" then
        return nil, "not_in_countdown"
    end

    room.countdownToken += 1
    room.state = "Waiting"
    self:_refreshReadyState(room)
    return room
end

function RoomManager:MarkInGame(room, mapId, difficulty, mode)
    if not room then
        return
    end
    room.state = "InGame"
    room.mapId = mapId or room.mapId
    room.difficulty = difficulty or room.difficulty
    room.mode = mode or room.mode
end

return RoomManager
