local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LobbyEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("LobbyEvent")

local Rooms = {}
local PlayerRoomMap = {}
local PendingRoomInvites = {}
local NextRoomInviteId = 1
local ROOM_INVITE_TIMEOUT = 5
local ROOM_INVITE_TIER_ORDER = {
	UNRANKED = 1,
	BRONZE = 2,
	SILVER = 3,
	GOLD = 4,
	PLATINUM = 5,
	DIAMOND = 6,
	MASTER = 7,
	GRANDMASTER = 8,
}

local function resolveMatchService()
	local registry = _G.SystemRegistry
	if type(registry) ~= "table" or type(registry.Get) ~= "function" then
		return nil
	end
	local matchSystem = registry:Get("MatchSystem")
	if type(matchSystem) ~= "table" then
		return nil
	end
	if type(matchSystem.JoinQueue) == "function" and type(matchSystem.TryCreateMatchFromQueue) == "function" and type(matchSystem.StartMatch) == "function" then
		return matchSystem
	end
	local service = matchSystem.Service
	if type(service) == "table" and type(service.JoinQueue) == "function" and type(service.TryCreateMatchFromQueue) == "function" and type(service.StartMatch) == "function" then
		return service
	end
	return nil
end

local function getRoomByPlayer(player)
	local roomId = PlayerRoomMap[player]
	if not roomId then
		return nil, nil
	end
	return Rooms[roomId], roomId
end

local function notifyRoom(room, payload)
	for plr in pairs(room.players) do
		LobbyEvent:FireClient(plr, payload)
	end
end

local function isAllReady(room)
	local hasAny = false
	local hasNonHost = false
	for member, data in pairs(room.players) do
		hasAny = true
		if member ~= room.host then
			hasNonHost = true
			if not (data and data.ready == true) then
				return false
			end
		end
	end
	if not hasAny then
		return false
	end
	if not hasNonHost then
		return true
	end
	return true
end

local function resolveTierTextFromPlayer(player)
	if not player then
		return "UNRANKED"
	end
	for _, attrName in ipairs({ "RankTier", "Tier", "RankedTier", "HostTier" }) do
		local value = player:GetAttribute(attrName)
		if value ~= nil and tostring(value) ~= "" then
			return string.upper(tostring(value))
		end
	end
	return "UNRANKED"
end

local function broadcastRoomState(room)
	local allReady = isAllReady(room)
	for plr in pairs(room.players) do
		local playerCount = 0
		for _ in pairs(room.players) do
			playerCount += 1
		end
		LobbyEvent:FireClient(plr, {
			eventName = "RoomStateUpdate",
			room = {
				roomId = room.roomId,
				hostName = room.host and room.host.Name or nil,
				playerCount = playerCount,
				maxPlayers = 4,
				mode = "Classic",
				difficulty = "Mudah",
			},
			allReady = allReady,
			isHost = (plr == room.host),
			isReady = room.players[plr] and room.players[plr].ready == true or false,
		})
	end
end

local function cancelCountdown(room, reason)
	if not room.isCountingDown then
		return
	end
	room.isCountingDown = false
	room.countdownToken = (room.countdownToken or 0) + 1
	notifyRoom(room, {
		eventName = "RoomMatchCountdownCancelled",
		reason = reason or "cancelled",
	})
end

local function removeFromRoom(player)
	local room, roomId = getRoomByPlayer(player)
	PlayerRoomMap[player] = nil
	if not room then
		return
	end

	room.players[player] = nil
	if room.isCountingDown then
		cancelCountdown(room, "player_left")
	end

	if room.host == player then
		for member in pairs(room.players) do
			room.host = member
			room.players[member].ready = true
			break
		end
	end

	if next(room.players) == nil then
		Rooms[roomId] = nil
		return
	end

	broadcastRoomState(room)
end

local function createRoom(hostPlayer)
	removeFromRoom(hostPlayer)

	local roomId = tostring(hostPlayer.UserId)
	local previous = Rooms[roomId]
	if previous then
		for member in pairs(previous.players) do
			PlayerRoomMap[member] = nil
		end
	end

	Rooms[roomId] = {
		roomId = roomId,
		host = hostPlayer,
		players = {
			[hostPlayer] = {
				ready = true,
			},
		},
		isCountingDown = false,
		countdownToken = 0,
	}

	PlayerRoomMap[hostPlayer] = roomId
	return Rooms[roomId]
end

LobbyEvent.OnServerEvent:Connect(function(player, request)
	if type(request) ~= "table" then
		return
	end

	local action = request.action

	if action == "CreateRoom" then
		local room = createRoom(player)
		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserRoomJoined",
			roomId = room.roomId,
		})
		broadcastRoomState(room)
		return
	end

	if action == "JoinRoom" then
		local room = Rooms[tostring(request.roomId or "")]
		if not room then
			LobbyEvent:FireClient(player, {
				eventName = "RoomBrowserRoomJoinFailed",
				reason = "room_not_found",
			})
			return
		end

		removeFromRoom(player)
		room.players[player] = { ready = false }
		PlayerRoomMap[player] = room.roomId

		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserRoomJoined",
			roomId = room.roomId,
		})
		broadcastRoomState(room)
		return
	end

	if action == "LeaveRoom" then
		removeFromRoom(player)
		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserRoomLeft",
		})
		return
	end

	if action == "SetReady" then
		local room = getRoomByPlayer(player)
		if not room or not room.players[player] then
			return
		end

		room.players[player].ready = request.isReady == true
		broadcastRoomState(room)
		return
	end

	if action == "InvitePlayerToRoom" then
		local room = getRoomByPlayer(player)
		if not room or room.host ~= player then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "not_host" })
			return
		end
		local targetUserId = tonumber(request and (request.targetUserId or request.target))
		local target = targetUserId and Players:GetPlayerByUserId(targetUserId) or nil
		if not target or target == player then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "target_not_found" })
			return
		end
		if getRoomByPlayer(target) ~= nil then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "target_already_in_room" })
			return
		end
		local inviteId = tostring(NextRoomInviteId)
		NextRoomInviteId += 1
		PendingRoomInvites[inviteId] = {
			inviteId = inviteId,
			roomId = room.roomId,
			fromUserId = player.UserId,
			fromName = player.DisplayName or player.Name,
			toUserId = target.UserId,
			expiresAt = os.clock() + ROOM_INVITE_TIMEOUT,
		}
		LobbyEvent:FireClient(target, {
			eventName = "RoomInviteReceived",
			inviteId = inviteId,
			roomId = room.roomId,
			fromUserId = player.UserId,
			fromName = player.DisplayName or player.Name,
			mode = request and request.mode or "Classic",
			expiresIn = ROOM_INVITE_TIMEOUT,
		})
		LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = true, toUserId = target.UserId, toName = target.DisplayName or target.Name })
		return
	end

	if action == "InviteBroadcastToRoom" then
		local room = getRoomByPlayer(player)
		if not room or room.host ~= player then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "not_host" })
			return
		end
		local invitedCount = 0
		local rankedMode = ((request and request.mode) == "Ranked") or (room.mode == "Ranked")
		local hostTier = resolveTierTextFromPlayer(player)
		local hostTierIndex = ROOM_INVITE_TIER_ORDER[hostTier] or 1
		for _, target in ipairs(Players:GetPlayers()) do
			if target ~= player and getRoomByPlayer(target) == nil then
				local allow = true
				if rankedMode then
					local targetTier = resolveTierTextFromPlayer(target)
					local targetTierIndex = ROOM_INVITE_TIER_ORDER[targetTier] or 1
					allow = math.abs(targetTierIndex - hostTierIndex) <= 1
				end
				if allow then
					local inviteId = tostring(NextRoomInviteId)
					NextRoomInviteId += 1
					PendingRoomInvites[inviteId] = {
						inviteId = inviteId,
						roomId = room.roomId,
						fromUserId = player.UserId,
						fromName = player.DisplayName or player.Name,
						toUserId = target.UserId,
						expiresAt = os.clock() + ROOM_INVITE_TIMEOUT,
					}
					LobbyEvent:FireClient(target, {
						eventName = "RoomInviteReceived",
						inviteId = inviteId,
						roomId = room.roomId,
						fromUserId = player.UserId,
						fromName = player.DisplayName or player.Name,
						mode = room.mode or "Classic",
						expiresIn = ROOM_INVITE_TIMEOUT,
						broadcast = true,
					})
					invitedCount += 1
				end
			end
		end
		LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = invitedCount > 0, broadcast = true, invitedCount = invitedCount, err = invitedCount > 0 and nil or "no_valid_targets" })
		return
	end

	if action == "RespondRoomInvite" then
		local inviteId = tostring(request and request.inviteId or "")
		local accept = request and request.accept == true
		local pending = PendingRoomInvites[inviteId]
		if not pending then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = false, err = "invite_not_found" })
			return
		end
		if pending.toUserId ~= player.UserId or pending.expiresAt <= os.clock() then
			PendingRoomInvites[inviteId] = nil
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = false, err = "invite_expired" })
			return
		end
		PendingRoomInvites[inviteId] = nil
		local inviter = Players:GetPlayerByUserId(pending.fromUserId)
		if not accept then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = true, accepted = false })
			if inviter then
				LobbyEvent:FireClient(inviter, { eventName = "RoomInviteDeclined", byUserId = player.UserId, byName = player.DisplayName or player.Name })
			end
			return
		end
		local room = Rooms[tostring(pending.roomId)]
		if not room then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = false, err = "room_not_found" })
			return
		end
		removeFromRoom(player)
		room.players[player] = { ready = false }
		PlayerRoomMap[player] = room.roomId
		LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = true, accepted = true, roomId = room.roomId })
		LobbyEvent:FireClient(player, { eventName = "RoomBrowserRoomJoined", roomId = room.roomId })
		if inviter then
			LobbyEvent:FireClient(inviter, { eventName = "RoomInviteAccepted", byUserId = player.UserId, byName = player.DisplayName or player.Name, roomId = room.roomId })
		end
		broadcastRoomState(room)
		return
	end

	if action == "HostStart" then
		local room, roomId = getRoomByPlayer(player)
		if not room or player ~= room.host then
			return
		end

		if not isAllReady(room) then
			return
		end

		room.isCountingDown = true
		room.countdownToken = (room.countdownToken or 0) + 1
		local token = room.countdownToken
		local countdown = 5

		notifyRoom(room, {
			eventName = "RoomMatchStarting",
			countdownSeconds = countdown,
		})

		task.spawn(function()
			for i = countdown, 1, -1 do
				local liveRoom = Rooms[roomId]
				if not liveRoom or not liveRoom.isCountingDown or liveRoom.countdownToken ~= token then
					return
				end

				notifyRoom(liveRoom, {
					eventName = "RoomMatchCountdown",
					secondsLeft = i,
				})
				task.wait(1)
			end

			local liveRoom = Rooms[roomId]
			if not liveRoom or not liveRoom.isCountingDown or liveRoom.countdownToken ~= token then
				return
			end

			liveRoom.isCountingDown = false
			liveRoom.countdownToken = liveRoom.countdownToken + 1
			local matchService = resolveMatchService()
			if not matchService then
				notifyRoom(liveRoom, {
					eventName = "RoomMatchCountdownCancelled",
					reason = "missing_match_system",
				})
				return
			end

			local partyMembers = {}
			for plr in pairs(liveRoom.players) do
				if plr ~= player then
					table.insert(partyMembers, plr)
				end
			end

			local queuePayload = {
				partyId = "room:" .. tostring(roomId),
				queueType = ((request and request.mode) == "Ranked") and "ranked" or "classic",
				partyMembers = partyMembers,
				mapId = request and request.mapId or nil,
				mode = request and request.mode or "Classic",
				gameMode = request and request.mode or "Classic",
				difficulty = request and request.difficulty or "Mudah",
			}

			local ok, reason = matchService:JoinQueue(player, queuePayload)
			if not ok then
				notifyRoom(liveRoom, {
					eventName = "RoomMatchCountdownCancelled",
					reason = reason or "queue_failed",
				})
				return
			end

			local match, buildReason = matchService:TryCreateMatchFromQueue(queuePayload)
			if not match or not match.matchId then
				notifyRoom(liveRoom, {
					eventName = "RoomMatchCountdownCancelled",
					reason = buildReason or "match_build_failed",
				})
				return
			end

			matchService:StartMatch(match.matchId)
			notifyRoom(liveRoom, {
				eventName = "RoomMatchCountdownCompleted",
				roomId = roomId,
			})
		end)
		return
	end

	if action == "CancelHostStart" then
		local room = getRoomByPlayer(player)
		if not room or player ~= room.host then
			return
		end
		cancelCountdown(room, "host_cancelled")
		return
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removeFromRoom(player)
end)

return true
