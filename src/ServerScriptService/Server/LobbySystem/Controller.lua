local Controller = {}
Controller.__index = Controller

local Services = require(script.Parent.Parent.Core.Services)

local LOBBY_REMOTE_NAME = "LobbyEvent"
local HOST_START_COUNTDOWN_SECONDS = 5
local REQUEST_DEDUPE_TTL_SECONDS = 15
local REQUEST_FALLBACK_ACTION_WINDOW_SECONDS = 0.25

local REQUEST_CRITICAL_ACTIONS = {
	CreateRoom = true,
	JoinRoom = true,
	LeaveRoom = true,
	QueueFromRoomBrowser = true,
	StartMatchmaking = true,
	QueueFromTrigger = true,
	SetReady = true,
	HostStart = true,
	CancelHostStart = true,
	SetPassword = true,
	KickPlayer = true,
}

local ACTION_HANDLERS = {
	RequestRoomBrowserSnapshot = "OnRequestRoomBrowserSnapshot",
	OpenRoomBrowser = "OnRequestRoomBrowserSnapshot",
	RequestRoomList = "OnRequestRoomList",
	SelectMode = "OnSelectMode",
	SelectMap = "OnSelectMap",
	SelectRoomMode = "OnSelectMode",
	SelectDifficulty = "OnSelectDifficulty",
	SelectClassicDifficulty = "OnSelectDifficulty",
	JoinRoom = "OnJoinRoom",
	LeaveRoom = "OnLeaveRoom",
	StartMatchmaking = "OnQueueFromRoomBrowser",
	QueueFromRoomBrowser = "OnQueueFromRoomBrowser",
	QueueFromTrigger = "OnQueueFromRoomBrowser",
	SetReady = "OnSetReady",
	HostStart = "OnHostStart",
	CancelHostStart = "OnCancelHostStart",
	KickPlayer = "OnKickPlayer",
	SetPassword = "OnSetPassword",
	CreateRoom = "OnCreateRoom",
}

local function appendTraceValue(parts, key, value)
	if value == nil then
		return
	end
	if type(value) == "table" then
		return
	end
	table.insert(parts, string.format("%s=%s", key, tostring(value)))
end

local function summarizeTraceData(data)
	if type(data) ~= "table" then
		return ""
	end

	local parts = {}
	for _, key in ipairs({
		"requestId",
		"action",
		"eventName",
		"roomId",
		"mapId",
		"mode",
		"difficulty",
		"ok",
		"err",
		"reason",
		"countdownSeconds",
		"secondsLeft",
		"isReady",
	}) do
		appendTraceValue(parts, key, data[key])
	end

	local selection = data.selection
	if type(selection) == "table" then
		appendTraceValue(parts, "selection.mode", selection.mode)
		appendTraceValue(parts, "selection.difficulty", selection.difficulty)
		appendTraceValue(parts, "selection.mapId", selection.mapId)
	end

	local snapshot = data.snapshot
	if type(snapshot) == "table" then
		appendTraceValue(parts, "snapshot.selectedMode", snapshot.selectedMode)
		appendTraceValue(parts, "snapshot.selectedDifficulty", snapshot.selectedDifficulty)
		appendTraceValue(parts, "snapshot.selectedMap", snapshot.selectedMap)
		if type(snapshot.rooms) == "table" then
			appendTraceValue(parts, "snapshot.rooms", #snapshot.rooms)
		end
	end

	local room = data.room
	if type(room) == "table" then
		appendTraceValue(parts, "room.roomId", room.roomId or room.id)
		appendTraceValue(parts, "room.mode", room.mode)
		appendTraceValue(parts, "room.mapId", room.mapId)
		appendTraceValue(parts, "room.playerCount", room.playerCount)
	end

	local queue = data.queue
	if type(queue) == "table" then
		appendTraceValue(parts, "queue.mode", queue.mode or queue.gameMode)
		appendTraceValue(parts, "queue.difficulty", queue.difficulty)
		appendTraceValue(parts, "queue.mapId", queue.mapId)
	end

	if #parts == 0 then
		return ""
	end
	return " [" .. table.concat(parts, ", ") .. "]"
end

local function resolvePlayersService(deps)
	if deps and deps.Players then
		return deps.Players
	end
	return game:GetService("Players")
end

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Subscribe) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then
		return eventBus.Service
	end
	return nil
end

local function sanitizeRemoteValue(value, depth)
	depth = depth or 0
	if depth > 6 then
		return nil
	end

	local valueType = typeof(value)
	if valueType == "Instance" or valueType == "RBXScriptConnection" or valueType == "RBXScriptSignal" then
		return nil
	end

	if type(value) == "table" then
		local out = {}
		for key, nestedValue in pairs(value) do
			local sanitizedKey = sanitizeRemoteValue(key, depth + 1)
			if type(sanitizedKey) == "string" or type(sanitizedKey) == "number" then
				local sanitizedValue = sanitizeRemoteValue(nestedValue, depth + 1)
				if sanitizedValue ~= nil then
					out[sanitizedKey] = sanitizedValue
				end
			end
		end
		return out
	end

	if type(value) == "function" or type(value) == "userdata" or type(value) == "thread" then
		return nil
	end

	return value
end

function Controller.new(state, service, deps)
	local self = setmetatable({}, Controller)
	self._state = state
	self._service = service
	self._deps = deps or {}
	self._players = resolvePlayersService(self._deps)
	self._eventBus = resolveEventBus(self._deps)
	self._subscriptions = {}
	self._lobbyRemote = nil
	self._remoteConnection = nil
	self._connections = {}
	self._roomCountdownById = {}
	self._seenRequestIdsByUserId = {}
	self._fallbackActionWindowByUserId = {}
	self._handlersRegistered = false
	return self
end

function Controller:Init()
	self._state:Set("controllerInitialized", true)
	self._lobbyRemote = self:_resolveLobbyRemote()
	self:_connectLobbyRemote()
end

function Controller:_resolveLobbyRemote()
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local remoteFolder = replicatedStorage:WaitForChild("RemoteEvents")
	local remote = remoteFolder:WaitForChild(LOBBY_REMOTE_NAME)
	if not remote:IsA("RemoteEvent") then
		error("LobbyEvent must be a RemoteEvent")
	end
	return remote
end

function Controller:RegisterEventHandlers()
	if self._handlersRegistered then
		return
	end

	self._state:Set("handlersRegistered", true)
	self:_connectLobbyRemote()

	if self._players then
		table.insert(self._connections, self._players.PlayerAdded:Connect(function(player)
			self._service:OnPlayerJoin(player)
		end))
		table.insert(self._connections, self._players.PlayerRemoving:Connect(function(player)
			self._service:OnPlayerLeave(player)
		end))

		for _, player in ipairs(self._players:GetPlayers()) do
			self._service:OnPlayerJoin(player)
		end
	end

	if self._eventBus then
		self:_subscribe("MatchStarted", function(payload)
			self._service:OnMatchStarted(payload and payload.matchId)
		end)
		self:_subscribe("MatchEnded", function(payload)
			self._service:OnMatchEnded(payload and payload.matchId)
		end)
		self:_subscribe("LobbyFlexSpotlightUpdated", function(payload)
			self:_relayLobbyRuntimeEvent(payload)
		end)
		self:_subscribe("LobbyFlexSpotlightCleared", function(payload)
			self:_relayLobbyRuntimeEvent(payload)
		end)
	end

	self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
	self._state:Set("handlersRegistered", false)
	self._handlersRegistered = false
	self:_disconnectLobbyRemote()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self._eventBus then
		for _, subscription in ipairs(self._subscriptions) do
			self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
		end
	end
	table.clear(self._subscriptions)
	table.clear(self._roomCountdownById)
end

function Controller:_subscribe(eventName, callback)
	if not self._eventBus then
		return
	end
	self._eventBus:Subscribe(eventName, callback)
	table.insert(self._subscriptions, {
		eventName = eventName,
		callback = callback,
	})
end

function Controller:_connectLobbyRemote()
	if self._remoteConnection then
		return
	end

	if not self._lobbyRemote then
		self._lobbyRemote = self:_resolveLobbyRemote()
	end
	if not self._lobbyRemote then
		return
	end

	self._remoteConnection = self._lobbyRemote.OnServerEvent:Connect(function(player, request)
		self:OnLobbyRemoteRequest(player, request)
	end)
end

function Controller:_isDuplicateRequest(player, request)
	local userId = player and player.UserId
	if type(userId) ~= "number" then
		return false
	end

	local now = os.clock()
	local requestId = request and request.requestId
	if type(requestId) == "string" and requestId ~= "" then
		local seenById = self._seenRequestIdsByUserId[userId]
		if not seenById then
			seenById = {}
			self._seenRequestIdsByUserId[userId] = seenById
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
	local window = self._fallbackActionWindowByUserId[userId]
	if not window then
		window = {}
		self._fallbackActionWindowByUserId[userId] = window
	end
	local previousAt = window[action]
	if previousAt and (now - previousAt) < REQUEST_FALLBACK_ACTION_WINDOW_SECONDS then
		return true
	end
	window[action] = now
	return false
end

function Controller:_disconnectLobbyRemote()
	if self._remoteConnection then
		self._remoteConnection:Disconnect()
		self._remoteConnection = nil
	end
end

function Controller:_send(player, payload)
	if self._lobbyRemote and player then
		self._lobbyRemote:FireClient(player, payload)
	end
end

function Controller:_resolveLobbyRecipients(payload)
	if type(payload) == "table" and type(payload.recipients) == "table" then
		local recipients = {}
		for _, player in ipairs(payload.recipients) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				table.insert(recipients, player)
			end
		end
		if #recipients > 0 then
			return recipients
		end
	end

	if self._players then
		return self._players:GetPlayers()
	end
	return {}
end

function Controller:_relayLobbyRuntimeEvent(payload)
	if type(payload) ~= "table" then
		return
	end

	local clientPayload = sanitizeRemoteValue(payload)
	if type(clientPayload) ~= "table" or type(clientPayload.eventName) ~= "string" then
		return
	end
	clientPayload.recipients = nil

	for _, player in ipairs(self:_resolveLobbyRecipients(payload)) do
		self:_send(player, clientPayload)
	end
end

function Controller:_broadcastToRoom(room, payload)
	if not room then
		return
	end
	for _, member in ipairs(room.players or {}) do
		self:_send(member, payload)
	end
end

function Controller:_broadcastRoomListToAll()
	if not self._players then
		return
	end
	local payload = {
		eventName = "RoomBrowserRoomList",
		rooms = self._service:GetRoomList(),
	}
	for _, player in ipairs(self._players:GetPlayers()) do
		self:_send(player, payload)
	end
end

function Controller:_cancelRoomCountdown(roomId)
	local countdown = self._roomCountdownById[roomId]
	if not countdown then
		return false
	end
	countdown.cancelled = true
	self._roomCountdownById[roomId] = nil
	return true
end

function Controller:OnLobbyRemoteRequest(player, request)
	if type(request) ~= "table" then
		self:_send(player, {
			eventName = "RoomBrowserError",
			reason = "invalid_request",
		})
		return
	end
	if self:_isDuplicateRequest(player, request) then
		return
	end

	local action = request.action
	local handlerName = ACTION_HANDLERS[action]
	local handler = handlerName and self[handlerName]
	if type(handler) ~= "function" then
		self:_send(player, {
			eventName = "RoomBrowserError",
			action = action,
			reason = "unsupported_action",
		})
		return
	end

	handler(self, player, request)
end

function Controller:OnRequestRoomBrowserSnapshot(player, request)
	local snapshot = self._service:GetRoomBrowserSnapshot(player, request)
	self:_send(player, {
		eventName = "RoomBrowserSnapshot",
		snapshot = snapshot,
	})
end

function Controller:OnRequestRoomList(player)
	self:_send(player, {
		eventName = "RoomBrowserRoomList",
		rooms = self._service:GetRoomList(),
	})
end

function Controller:OnSelectMode(player, request)
	local ok, reason, selection = self._service:SetModeSelection(player, request.mode, request)
	if not ok then
		self:_send(player, {
			eventName = "RoomBrowserSelectionRejected",
			reason = reason,
		})
		return
	end
	self:_send(player, {
		eventName = "RoomBrowserSelectionConfirmed",
		selection = selection,
	})
	self:OnRequestRoomBrowserSnapshot(player, request)
end

function Controller:OnSelectMap(player, request)
	local ok, reason, selection = self._service:SetMapSelection(player, request.mapId)
	if not ok then
		self:_send(player, {
			eventName = "RoomBrowserSelectionRejected",
			reason = reason,
		})
		return
	end
	self:_send(player, {
		eventName = "RoomBrowserSelectionConfirmed",
		selection = selection,
	})
	self:OnRequestRoomBrowserSnapshot(player, request)

	local room = self._service._roomManager and self._service._roomManager:GetRoomByPlayer(player) or nil
	if room then
		self:_broadcastRoomState(room)
	end
	self:_broadcastRoomListToAll()
end

function Controller:OnSelectDifficulty(player, request)
	local ok, reason, selection = self._service:SetDifficultySelection(player, request.difficulty)
	if not ok then
		self:_send(player, {
			eventName = "RoomBrowserSelectionRejected",
			reason = reason,
		})
		return
	end
	self:_send(player, {
		eventName = "RoomBrowserSelectionConfirmed",
		selection = selection,
	})
	self:OnRequestRoomBrowserSnapshot(player, request)
end

function Controller:OnJoinRoom(player, request)
	local previousRoom = self._service._roomManager and self._service._roomManager:GetRoomByPlayer(player) or nil
	local ok, reason = self._service:JoinRoom(player, request.roomId, request.password)
	if not ok then
		self:_send(player, {
			eventName = "RoomBrowserRoomJoinFailed",
			reason = reason,
		})
		return
	end

	self:_send(player, {
		eventName = "RoomBrowserRoomJoined",
		roomId = tonumber(request.roomId),
	})

	local joinedRoom = self._service._roomManager and self._service._roomManager:GetRoomByPlayer(player) or nil
	if previousRoom and previousRoom ~= joinedRoom then
		self:_broadcastRoomState(previousRoom)
	end
	if joinedRoom then
		self:_broadcastRoomState(joinedRoom)
	end

	self:_broadcastRoomListToAll()
end

function Controller:OnLeaveRoom(player)
	local room = self._service._roomManager and self._service._roomManager:GetRoomByPlayer(player) or nil
	if room and room.starting then
		self:_cancelRoomCountdown(room.id)
		if self._service._roomManager then
			self._service._roomManager:SetInGame(room.id, false, true)
		end
	end

	local ok, reason = self._service:LeaveRoom(player)
	if not ok then
		self:_send(player, {
			eventName = "RoomBrowserRoomLeaveFailed",
			reason = reason,
		})
		return
	end

	self:_send(player, {
		eventName = "RoomBrowserRoomLeft",
	})

	if room then
		self:_broadcastRoomState(room)
	end
	self:_broadcastRoomListToAll()
end

function Controller:OnQueueFromRoomBrowser(player, request)
	local ok, reason, queuePayload = self._service:QueueFromRoomBrowser(player, request)
	if not ok then
		self:_send(player, {
			eventName = "RoomBrowserQueueFailed",
			reason = reason,
		})
		return
	end
	self:_send(player, {
		eventName = "RoomBrowserQueueStarted",
		queue = queuePayload,
	})
end

function Controller:_broadcastRoomState(room)
	if not room then
		return
	end

	local rooms = self._service:GetRoomList()
	local roomData = nil
	for _, listedRoom in ipairs(rooms) do
		if listedRoom.roomId == room.id then
			roomData = listedRoom
			break
		end
	end
	if not roomData then
		return
	end

	local countdown = self._roomCountdownById[room.id]
	for _, member in ipairs(room.players or {}) do
		self:_send(member, {
			eventName = "RoomStateUpdate",
			room = roomData,
			isHost = room.host == member,
			isReady = room.readyPlayers[member] or false,
			allReady = self._service._roomManager:IsAllReady(room.id),
			countdownSecondsLeft = countdown and countdown.secondsLeft or nil,
		})
	end
end

function Controller:OnSetReady(player, request)
	local isReady = request.isReady ~= false
	local ok, err = self._service:SetReady(player, isReady)
	self:_send(player, {
		eventName = "RoomReadyResult",
		ok = ok,
		err = err,
	})

	local room = self._service._roomManager and self._service._roomManager:GetRoomByPlayer(player) or nil
	if room then
		self:_broadcastRoomState(room)
	end
	self:_broadcastRoomListToAll()
end

function Controller:OnHostStart(player, request)
	local ok, err, startInfo = self._service:BeginHostStart(player)
	self:_send(player, {
		eventName = "HostStartResult",
		ok = ok,
		err = err,
		countdownSeconds = startInfo and startInfo.countdownSeconds or HOST_START_COUNTDOWN_SECONDS,
	})
	if not ok then
		return
	end

	local roomId = startInfo.roomId
	local room = self._service._roomManager and self._service._roomManager:GetRoomById(roomId) or nil
	if not room then
		return
	end

	self:_cancelRoomCountdown(roomId)
	local countdownSeconds = tonumber(startInfo.countdownSeconds) or HOST_START_COUNTDOWN_SECONDS
	self._roomCountdownById[roomId] = {
		cancelled = false,
		secondsLeft = countdownSeconds,
		hostUserId = player.UserId,
	}

	self:_broadcastToRoom(room, {
		eventName = "RoomMatchStarting",
		roomId = roomId,
		countdownSeconds = countdownSeconds,
	})
	self:_broadcastRoomState(room)
	self:_broadcastRoomListToAll()

	task.spawn(function()
		for seconds = countdownSeconds, 1, -1 do
			local countdown = self._roomCountdownById[roomId]
			if not countdown or countdown.cancelled then
				return
			end

			countdown.secondsLeft = seconds
			self:_broadcastToRoom(room, {
				eventName = "RoomMatchCountdown",
				roomId = roomId,
				secondsLeft = seconds,
				totalSeconds = countdownSeconds,
			})
			self:_broadcastRoomState(room)
			task.wait(1)
		end

		local countdown = self._roomCountdownById[roomId]
		if not countdown or countdown.cancelled then
			return
		end
		self._roomCountdownById[roomId] = nil

		local commitOk, commitErr = self._service:CommitHostStart(player, request)
		if not commitOk then
			local liveRoom = self._service._roomManager and self._service._roomManager:GetRoomById(roomId) or room
			self:_broadcastToRoom(liveRoom, {
				eventName = "RoomMatchCountdownCancelled",
				roomId = roomId,
				reason = commitErr or "start_failed",
			})
			if liveRoom then
				self:_broadcastRoomState(liveRoom)
			end
			self:_broadcastRoomListToAll()
			self:_send(player, {
				eventName = "HostStartResult",
				ok = false,
				err = commitErr or "start_failed",
			})
			return
		end

		local liveRoom = self._service._roomManager and self._service._roomManager:GetRoomById(roomId) or room
		self:_broadcastToRoom(liveRoom, {
			eventName = "RoomMatchCountdownCompleted",
			roomId = roomId,
		})
		if liveRoom then
			self:_broadcastRoomState(liveRoom)
		end
		self:_broadcastRoomListToAll()
	end)
end

function Controller:OnCancelHostStart(player)
	local room = self._service._roomManager and self._service._roomManager:GetRoomByPlayer(player) or nil
	local ok, err = self._service:CancelHostStart(player)
	self:_send(player, {
		eventName = "CancelHostStartResult",
		ok = ok,
		err = err,
	})

	if not ok then
		return
	end

	if room then
		self:_cancelRoomCountdown(room.id)
		self:_broadcastToRoom(room, {
			eventName = "RoomMatchCountdownCancelled",
			roomId = room.id,
			reason = "host_cancelled",
		})
		self:_broadcastRoomState(room)
	end
	self:_broadcastRoomListToAll()
end

function Controller:OnKickPlayer(player, request)
	local kickedPlayer = nil
	local targetUserId = tonumber(request and request.targetUserId)
	if targetUserId and self._players then
		for _, candidate in ipairs(self._players:GetPlayers()) do
			if candidate.UserId == targetUserId then
				kickedPlayer = candidate
				break
			end
		end
	end

	local ok, err = self._service:KickPlayer(player, request.targetUserId)
	self:_send(player, {
		eventName = "KickPlayerResult",
		ok = ok,
		err = err,
	})
	if ok and kickedPlayer then
		self:_send(kickedPlayer, {
			eventName = "RoomBrowserRoomLeft",
			reason = "kicked",
		})
	end

	local room = self._service._roomManager and self._service._roomManager:GetRoomByPlayer(player) or nil
	if room then
		self:_broadcastRoomState(room)
	end
	self:_broadcastRoomListToAll()
end

function Controller:OnSetPassword(player, request)
	local ok, err = self._service:SetRoomPassword(player, request.password)
	self:_send(player, {
		eventName = "SetPasswordResult",
		ok = ok,
		err = err,
	})

	local room = self._service._roomManager and self._service._roomManager:GetRoomByPlayer(player) or nil
	if room then
		self:_broadcastRoomState(room)
	end
	self:_broadcastRoomListToAll()
end

function Controller:OnCreateRoom(player)
	if not self._service._roomManager then
		self:_send(player, {
			eventName = "CreateRoomResult",
			ok = false,
			err = "room_manager_unavailable",
		})
		return
	end

	local roomMap = self._service._roomManager:GetRooms()
	local targetRoom = nil
	for _, room in pairs(roomMap) do
		if #room.players == 0 and not room.inGame and not room.starting then
			targetRoom = room
			break
		end
	end

	if not targetRoom then
		self:_send(player, {
			eventName = "CreateRoomResult",
			ok = false,
			err = "no_rooms_available",
		})
		return
	end

	local ok, err = self._service:JoinRoom(player, targetRoom.id)
	self:_send(player, {
		eventName = "CreateRoomResult",
		ok = ok,
		err = err,
		roomId = targetRoom.id,
	})

	if ok then
		local room = self._service._roomManager:GetRoomById(targetRoom.id)
		if room then
			self:_broadcastRoomState(room)
		end
	end
	self:_broadcastRoomListToAll()
end

return Controller

