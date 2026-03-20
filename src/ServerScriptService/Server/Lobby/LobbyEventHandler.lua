local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LobbyEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("LobbyEvent")

local Rooms = {}
local PlayerRoomMap = {}
local PlayerSelections = {}
local _standaloneMatchService = nil
local _seenRequestIdsByUserId = {}
local _fallbackActionWindowByUserId = {}
local REQUEST_DEDUPE_TTL_SECONDS = 15
local REQUEST_FALLBACK_ACTION_WINDOW_SECONDS = 0.25
local REQUEST_CRITICAL_ACTIONS = {
	CreateRoom = true,
	JoinRoom = true,
	LeaveRoom = true,
	QueueFromRoomBrowser = true,
	SetReady = true,
	HostStart = true,
	CancelHostStart = true,
	SetPassword = true,
	KickPlayer = true,
	InvitePlayerToRoom = true,
	InviteBroadcastToRoom = true,
	RespondRoomInvite = true,
}
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
local PendingRoomInvites = {}
local NextRoomInviteId = 1

local function resolveRegistry()
	local registry = _G.SystemRegistry
	if type(registry) == "table" then
		return registry
	end

	local serverScriptService = game:GetService("ServerScriptService")
	local serverFolder = serverScriptService:FindFirstChild("Server")
	local coreFolder = serverFolder and serverFolder:FindFirstChild("Core")
	local registryModule = coreFolder and coreFolder:FindFirstChild("SystemRegistry")
	if not registryModule then
		return nil
	end

	local ok, loaded = pcall(require, registryModule)
	if not ok or type(loaded) ~= "table" then
		return nil
	end

	if type(loaded.Start) == "function" then
		pcall(function()
			loaded:Start()
		end)
	end

	_G.SystemRegistry = loaded
	return loaded
end

local function resolveMatchService()
	local registry = resolveRegistry()
	if type(registry) ~= "table" or type(registry.Get) ~= "function" then
		registry = nil
	end

	if registry then
		local matchSystem = registry:Get("MatchSystem")
		if type(matchSystem) == "table" then
			if type(matchSystem.JoinQueue) == "function" and type(matchSystem.TryCreateMatchFromQueue) == "function" and type(matchSystem.StartMatch) == "function" then
				return matchSystem
			end
			local service = matchSystem.Service
			if type(service) == "table" and type(service.JoinQueue) == "function" and type(service.TryCreateMatchFromQueue) == "function" and type(service.StartMatch) == "function" then
				return service
			end
		end
	end

	-- Fallback: bootstrap might fail before registry exposes MatchSystem.
	-- Build a single standalone MatchSystem service instance to keep room flow alive.
	if _standaloneMatchService then
		return _standaloneMatchService
	end

	local serverScriptService = game:GetService("ServerScriptService")
	local serverFolder = serverScriptService:FindFirstChild("Server")
	local matchFolder = serverFolder and serverFolder:FindFirstChild("MatchSystem")
	local stateModule = matchFolder and matchFolder:FindFirstChild("State")
	local serviceModule = matchFolder and matchFolder:FindFirstChild("Service")
	if not stateModule or not serviceModule then
		return nil
	end

	local okState, stateFactory = pcall(require, stateModule)
	local okService, serviceFactory = pcall(require, serviceModule)
	if not okState or not okService then
		return nil
	end
	if type(stateFactory) ~= "table" or type(stateFactory.new) ~= "function" then
		return nil
	end
	if type(serviceFactory) ~= "table" or type(serviceFactory.new) ~= "function" then
		return nil
	end

	local deps = {}
	if type(registry) == "table" then
		deps.Services = registry
		deps.ServiceRegistry = registry
	end

	local state = stateFactory.new()
	local service = serviceFactory.new(state, deps)
	if type(service) ~= "table" then
		return nil
	end
	if type(service.Init) == "function" then
		pcall(function()
			service:Init()
		end)
	end
	if type(service.Start) == "function" then
		pcall(function()
			service:Start()
		end)
	end
	if type(service.JoinQueue) == "function" and type(service.TryCreateMatchFromQueue) == "function" and type(service.StartMatch) == "function" then
		_standaloneMatchService = service
		return _standaloneMatchService
	end
	return nil
end

local function ensureSelection(player)
	local selection = PlayerSelections[player]
	if type(selection) ~= "table" then
		selection = {
			mode = "Classic",
			difficulty = "Mudah",
		}
		PlayerSelections[player] = selection
	end
	return selection
end

local function isDuplicateRequest(player, request)
	local userId = player and player.UserId
	if type(userId) ~= "number" then
		return false
	end

	local now = os.clock()
	local requestId = request and request.requestId
	if type(requestId) == "string" and requestId ~= "" then
		local seenById = _seenRequestIdsByUserId[userId]
		if not seenById then
			seenById = {}
			_seenRequestIdsByUserId[userId] = seenById
		end
		for id, timestamp in pairs(seenById) do
			if (now - timestamp) > REQUEST_DEDUPE_TTL_SECONDS then
				seenById[id] = nil
			end
		end
		if seenById[requestId] then
			return true
		end
		seenById[requestId] = now
		return false
	end

	local action = request and request.action
	if REQUEST_CRITICAL_ACTIONS[action] ~= true then
		return false
	end

	local window = _fallbackActionWindowByUserId[userId]
	if not window then
		window = {}
		_fallbackActionWindowByUserId[userId] = window
	end
	local previousAt = window[action]
	if previousAt and (now - previousAt) < REQUEST_FALLBACK_ACTION_WINDOW_SECONDS then
		return true
	end
	window[action] = now
	return false
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

local function buildLobbyPlayersPayload()
	local payload = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		table.insert(payload, {
			userId = plr.UserId,
			name = plr.Name,
			displayName = plr.DisplayName,
			tier = resolveTierTextFromPlayer(plr),
		})
	end
	return payload
end

local function broadcastRoomState(room)
	local allReady = isAllReady(room)
	local roomPlayers = {}
	for member, data in pairs(room.players) do
		table.insert(roomPlayers, {
			userId = member.UserId,
			name = member.Name,
			displayName = member.DisplayName,
			isHost = (member == room.host),
			isReady = data and data.ready == true or false,
		})
	end
	table.sort(roomPlayers, function(a, b)
		return tostring(a.name) < tostring(b.name)
	end)
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
				maxPlayers = room.maxPlayers or 4,
				mode = room.mode or "Classic",
				difficulty = room.difficulty or "Mudah",
				mapId = room.mapId or "HauntedHouse",
				players = roomPlayers,
			},
			allReady = allReady,
			isHost = (plr == room.host),
			isReady = room.players[plr] and room.players[plr].ready == true or false,
		})
	end
end

local function buildRoomSummary(room)
	local playerCount = 0
	local readyCount = 0
	local players = {}
	for member, data in pairs(room.players) do
		playerCount += 1
		local isReady = data and data.ready == true or false
		if isReady then
			readyCount += 1
		end
		table.insert(players, {
			userId = member.UserId,
			name = member.Name,
			displayName = member.DisplayName,
			isHost = (member == room.host),
			isReady = isReady,
		})
	end
	table.sort(players, function(a, b)
		return tostring(a.name) < tostring(b.name)
	end)
	return {
		roomId = tonumber(room.roomId) or room.roomId,
		playerCount = playerCount,
		maxPlayers = room.maxPlayers or 4,
		status = room.inGame and "ingame" or (room.isCountingDown and "starting" or "waiting"),
		inGame = room.inGame == true,
		starting = room.isCountingDown == true,
		hostName = room.host and room.host.Name or nil,
		hostUserId = room.host and room.host.UserId or nil,
		hasPassword = room.password ~= nil,
		readyCount = readyCount,
		mode = room.mode or "Classic",
		difficulty = room.difficulty or "Mudah",
		mapId = room.mapId or "HauntedHouse",
		players = players,
	}
end

local function buildRoomList()
	local list = {}
	for _, room in pairs(Rooms) do
		table.insert(list, buildRoomSummary(room))
	end
	table.sort(list, function(a, b)
		return tostring(a.roomId) < tostring(b.roomId)
	end)
	return list
end

local function sendRoomList(player)
	LobbyEvent:FireClient(player, {
		eventName = "RoomBrowserRoomList",
		rooms = buildRoomList(),
		lobbyPlayers = buildLobbyPlayersPayload(),
	})
end

local function broadcastRoomListToAll()
	local payload = {
		eventName = "RoomBrowserRoomList",
		rooms = buildRoomList(),
		lobbyPlayers = buildLobbyPlayersPayload(),
	}
	for _, plr in ipairs(Players:GetPlayers()) do
		LobbyEvent:FireClient(plr, payload)
	end
end

local function sendSnapshot(player)
	local selection = ensureSelection(player)
	local room = getRoomByPlayer(player)
	LobbyEvent:FireClient(player, {
		eventName = "RoomBrowserSnapshot",
		snapshot = {
			modes = { "Classic", "Ranked" },
			classicDifficulties = { "Mudah", "Lumayan", "Angker", "Uji Nyali" },
			selectedMode = selection.mode or "Classic",
			selectedDifficulty = selection.difficulty or "Mudah",
			rooms = buildRoomList(),
			currentRoom = room and buildRoomSummary(room) or nil,
			lobbyPlayers = buildLobbyPlayersPayload(),
		},
	})
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

	local taken = {}
	for existingRoomId in pairs(Rooms) do
		local numericId = tonumber(existingRoomId)
		if numericId then
			taken[numericId] = true
		end
	end
	local nextId = 1
	while taken[nextId] do
		nextId += 1
	end
	local roomId = tostring(nextId)
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
		inGame = false,
		countdownToken = 0,
		password = nil,
		maxPlayers = 4,
		mapId = "HauntedHouse",
	}

	PlayerRoomMap[hostPlayer] = roomId
	return Rooms[roomId]
end

LobbyEvent.OnServerEvent:Connect(function(player, request)
	if type(request) ~= "table" then
		return
	end
	if isDuplicateRequest(player, request) then
		return
	end

	local action = request.action

	if action == "RequestRoomList" then
		sendRoomList(player)
		return
	end

	if action == "RequestRoomBrowserSnapshot" or action == "OpenRoomBrowser" then
		sendSnapshot(player)
		return
	end

	if action == "SelectMode" then
		local selection = ensureSelection(player)
		local mode = request and request.mode
		if mode ~= "Ranked" and mode ~= "Classic" then
			mode = "Classic"
		end
		selection.mode = mode
		if mode == "Ranked" then
			selection.difficulty = "AUTO"
		elseif selection.difficulty == "AUTO" then
			selection.difficulty = "Mudah"
		end

		local room = getRoomByPlayer(player)
		if room and room.host == player then
			room.mode = selection.mode
			if selection.mode ~= "Ranked" then
				room.difficulty = selection.difficulty
			end
			broadcastRoomState(room)
			broadcastRoomListToAll()
		end

		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserSelectionConfirmed",
			selection = {
				mode = selection.mode,
				difficulty = selection.difficulty,
			},
		})
		sendSnapshot(player)
		return
	end

	if action == "SelectDifficulty" then
		local selection = ensureSelection(player)
		local difficulty = request and request.difficulty
		local validDifficulty = {
			Mudah = true,
			Lumayan = true,
			Angker = true,
			["Uji Nyali"] = true,
		}

		if selection.mode == "Ranked" then
			LobbyEvent:FireClient(player, {
				eventName = "RoomBrowserSelectionRejected",
				reason = "ranked_difficulty_is_balanced",
			})
			sendSnapshot(player)
			return
		end

		if validDifficulty[difficulty] ~= true then
			difficulty = "Mudah"
		end
		selection.difficulty = difficulty

		local room = getRoomByPlayer(player)
		if room and room.host == player then
			room.difficulty = selection.difficulty
			broadcastRoomState(room)
			broadcastRoomListToAll()
		end

		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserSelectionConfirmed",
			selection = {
				mode = selection.mode,
				difficulty = selection.difficulty,
			},
		})
		sendSnapshot(player)
		return
	end

	if action == "SelectMap" then
		local room = getRoomByPlayer(player)
		if not room or room.host ~= player then
			LobbyEvent:FireClient(player, {
				eventName = "RoomBrowserSelectionRejected",
				reason = "not_host",
			})
			return
		end
		local mapId = request and request.mapId
		if type(mapId) ~= "string" or mapId == "" then
			mapId = "HauntedHouse"
		end
		room.mapId = mapId
		broadcastRoomState(room)
		broadcastRoomListToAll()
		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserSelectionConfirmed",
			selection = {
				mode = room.mode or "Classic",
				difficulty = room.difficulty or "Mudah",
				mapId = room.mapId,
			},
		})
		return
	end

	if action == "CreateRoom" then
		local room = createRoom(player)
		local selection = ensureSelection(player)
		room.mode = selection.mode or "Classic"
		room.difficulty = selection.mode == "Ranked" and "AUTO" or (selection.difficulty or "Mudah")
		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserRoomJoined",
			roomId = room.roomId,
		})
		broadcastRoomState(room)
		broadcastRoomListToAll()
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
		if room.isCountingDown == true or room.inGame == true then
			LobbyEvent:FireClient(player, {
				eventName = "RoomBrowserRoomJoinFailed",
				reason = "room_in_game",
			})
			return
		end
		local currentCount = 0
		for _ in pairs(room.players) do
			currentCount += 1
		end
		if currentCount >= (room.maxPlayers or 4) then
			LobbyEvent:FireClient(player, {
				eventName = "RoomBrowserRoomJoinFailed",
				reason = "room_full",
			})
			return
		end
		if room.password ~= nil then
			local incoming = request and request.password
			if type(incoming) == "string" then
				incoming = incoming:gsub("%s+", "")
			end
			if type(incoming) ~= "string" or incoming ~= room.password then
				LobbyEvent:FireClient(player, {
					eventName = "RoomBrowserRoomJoinFailed",
					reason = "wrong_password",
				})
				return
			end
		end

		removeFromRoom(player)
		room.players[player] = { ready = false }
		PlayerRoomMap[player] = room.roomId

		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserRoomJoined",
			roomId = room.roomId,
		})
		broadcastRoomState(room)
		broadcastRoomListToAll()
		return
	end

	if action == "SetPassword" then
		local room = getRoomByPlayer(player)
		if not room or room.host ~= player then
			LobbyEvent:FireClient(player, {
				eventName = "SetPasswordResult",
				ok = false,
				err = "not_host",
			})
			return
		end

		local raw = request and request.password
		local normalized = nil
		if type(raw) == "string" then
			normalized = raw:gsub("%s+", "")
			if normalized == "" then
				normalized = nil
			elseif not normalized:match("^%d%d%d%d$") then
				LobbyEvent:FireClient(player, {
					eventName = "SetPasswordResult",
					ok = false,
					err = "password_must_be_4_digits",
				})
				return
			end
		end

		room.password = normalized
		LobbyEvent:FireClient(player, {
			eventName = "SetPasswordResult",
			ok = true,
		})
		broadcastRoomState(room)
		broadcastRoomListToAll()
		return
	end

	if action == "KickPlayer" then
		local room = getRoomByPlayer(player)
		if not room or room.host ~= player then
			LobbyEvent:FireClient(player, {
				eventName = "KickPlayerResult",
				ok = false,
				err = "not_host",
			})
			return
		end

		local targetUserId = tonumber(request and request.targetUserId)
		if not targetUserId then
			LobbyEvent:FireClient(player, {
				eventName = "KickPlayerResult",
				ok = false,
				err = "invalid_target",
			})
			return
		end

		local targetPlayer = nil
		for member in pairs(room.players) do
			if member.UserId == targetUserId then
				targetPlayer = member
				break
			end
		end
		if not targetPlayer then
			LobbyEvent:FireClient(player, {
				eventName = "KickPlayerResult",
				ok = false,
				err = "player_not_in_room",
			})
			return
		end
		if targetPlayer == player then
			LobbyEvent:FireClient(player, {
				eventName = "KickPlayerResult",
				ok = false,
				err = "cannot_kick_self",
			})
			return
		end

		room.players[targetPlayer] = nil
		PlayerRoomMap[targetPlayer] = nil
		LobbyEvent:FireClient(targetPlayer, {
			eventName = "RoomBrowserRoomLeft",
			reason = "kicked",
		})
		LobbyEvent:FireClient(player, {
			eventName = "KickPlayerResult",
			ok = true,
		})
		broadcastRoomState(room)
		broadcastRoomListToAll()
		return
	end

	if action == "InvitePlayerToRoom" then
		local room = getRoomByPlayer(player)
		if not room or room.host ~= player then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "not_host" })
			return
		end
		local targetUserId = tonumber(request and (request.targetUserId or request.target))
		if not targetUserId then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "invalid_target" })
			return
		end
		local target = Players:GetPlayerByUserId(targetUserId)
		if not target then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "target_not_found" })
			return
		end
		if target == player then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "cannot_invite_self" })
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
			mode = room.mode or "Classic",
			mapId = room.mapId or "HauntedHouse",
			difficulty = room.difficulty or "Mudah",
			expiresIn = ROOM_INVITE_TIMEOUT,
		})
		LobbyEvent:FireClient(player, {
			eventName = "RoomInviteSendResult",
			ok = true,
			inviteId = inviteId,
			toUserId = target.UserId,
			toName = target.DisplayName or target.Name,
		})
		task.delay(ROOM_INVITE_TIMEOUT + 0.1, function()
			local pending = PendingRoomInvites[inviteId]
			if pending and pending.expiresAt <= os.clock() then
				PendingRoomInvites[inviteId] = nil
				local inviter = Players:GetPlayerByUserId(pending.fromUserId)
				if inviter then
					LobbyEvent:FireClient(inviter, { eventName = "RoomInviteExpired", inviteId = inviteId, roomId = pending.roomId })
				end
			end
		end)
		return
	end

	if action == "InviteBroadcastToRoom" then
		local room = getRoomByPlayer(player)
		if not room or room.host ~= player then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteSendResult", ok = false, err = "not_host" })
			return
		end
		local invitedCount = 0
		local rankedMode = string.lower(tostring(room.mode or "Classic")) == "ranked"
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
						mapId = room.mapId or "HauntedHouse",
						difficulty = room.difficulty or "Mudah",
						expiresIn = ROOM_INVITE_TIMEOUT,
						broadcast = true,
					})
					invitedCount += 1
				end
			end
		end
		LobbyEvent:FireClient(player, {
			eventName = "RoomInviteSendResult",
			ok = invitedCount > 0,
			broadcast = true,
			invitedCount = invitedCount,
			err = invitedCount > 0 and nil or "no_valid_targets",
		})
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
		if pending.toUserId ~= player.UserId then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = false, err = "invite_not_for_player" })
			return
		end
		if pending.expiresAt <= os.clock() then
			PendingRoomInvites[inviteId] = nil
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = false, err = "invite_expired" })
			return
		end
		PendingRoomInvites[inviteId] = nil
		local inviter = Players:GetPlayerByUserId(pending.fromUserId)
		if not accept then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = true, accepted = false })
			if inviter then
				LobbyEvent:FireClient(inviter, { eventName = "RoomInviteDeclined", inviteId = inviteId, byUserId = player.UserId, byName = player.DisplayName or player.Name })
			end
			return
		end
		local room = Rooms[tostring(pending.roomId)]
		if not room or room.inGame == true or room.isCountingDown == true then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = false, err = "room_unavailable" })
			return
		end
		local currentCount = 0
		for _ in pairs(room.players) do
			currentCount += 1
		end
		if currentCount >= (room.maxPlayers or 4) then
			LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = false, err = "room_full" })
			return
		end
		removeFromRoom(player)
		room.players[player] = { ready = false }
		PlayerRoomMap[player] = room.roomId
		LobbyEvent:FireClient(player, { eventName = "RoomInviteResponseResult", ok = true, accepted = true, roomId = room.roomId })
		LobbyEvent:FireClient(player, { eventName = "RoomBrowserRoomJoined", roomId = room.roomId })
		if inviter then
			LobbyEvent:FireClient(inviter, { eventName = "RoomInviteAccepted", inviteId = inviteId, byUserId = player.UserId, byName = player.DisplayName or player.Name, roomId = room.roomId })
		end
		broadcastRoomState(room)
		broadcastRoomListToAll()
		return
	end

	if action == "LeaveRoom" then
		removeFromRoom(player)
		LobbyEvent:FireClient(player, {
			eventName = "RoomBrowserRoomLeft",
		})
		broadcastRoomListToAll()
		return
	end

	if action == "SetReady" then
		local room = getRoomByPlayer(player)
		if not room or not room.players[player] then
			return
		end

		room.players[player].ready = request.isReady == true
		broadcastRoomState(room)
		broadcastRoomListToAll()
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
		local activeCount = 0
		for _ in pairs(room.players) do
			activeCount += 1
		end
		if activeCount > (room.maxPlayers or 4) then
			notifyRoom(room, {
				eventName = "RoomMatchCountdownCancelled",
				reason = "room_over_capacity",
			})
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
			liveRoom.inGame = true
			liveRoom.countdownToken = liveRoom.countdownToken + 1
			local matchService = resolveMatchService()
			if not matchService then
				liveRoom.inGame = false
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
				queueType = ((liveRoom.mode or request and request.mode) == "Ranked") and "ranked" or "classic",
				partyMembers = partyMembers,
				mapId = (request and request.mapId) or liveRoom.mapId or "HauntedHouse",
				mode = liveRoom.mode or request and request.mode or "Classic",
				gameMode = liveRoom.mode or request and request.mode or "Classic",
				difficulty = liveRoom.difficulty or request and request.difficulty or "Mudah",
			}

			local ok, reason = matchService:JoinQueue(player, queuePayload)
			if not ok then
				liveRoom.inGame = false
				notifyRoom(liveRoom, {
					eventName = "RoomMatchCountdownCancelled",
					reason = reason or "queue_failed",
				})
				return
			end

			local match, buildReason = matchService:TryCreateMatchFromQueue(queuePayload)
			if not match or not match.matchId then
				liveRoom.inGame = false
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
			broadcastRoomListToAll()
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
	PlayerSelections[player] = nil
end)

return true
