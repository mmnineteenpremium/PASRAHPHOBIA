local RoomBrowserController = {}
RoomBrowserController.__index = RoomBrowserController

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LOBBY_REMOTE_NAME = "LobbyEvent"

function RoomBrowserController.new(lobbyRemote)
	local self = setmetatable({}, RoomBrowserController)
	self._lobbyRemote = lobbyRemote
	self._requestSeq = 0
	self._lastActionSentAt = {}
	self._state = {
		modes = {},
		classicDifficulties = {},
		selectedMode = "Classic",
		selectedDifficulty = "Mudah",
		selectedMap = "HauntedHouse",
		rooms = {},
		lastEvent = nil,
		lastError = nil,
		queue = nil,
		matchStarting = false,
		countdownSecondsLeft = nil,
		countdownTotal = nil,
		currentRoom = nil,
		lastRoomId = nil,
		isHost = false,
		isReady = false,
		allReady = false,
		pendingRoomTransition = false,
	}
	return self
end

local CLIENT_CRITICAL_ACTIONS = {
	CreateRoom = true,
	JoinRoom = true,
	LeaveRoom = true,
	QueueFromRoomBrowser = true,
	SetReady = true,
	HostStart = true,
	CancelHostStart = true,
	SetPassword = true,
}

function RoomBrowserController:_nextRequestId(action)
	self._requestSeq += 1
	return string.format("%d:%d:%s", game.Players.LocalPlayer and game.Players.LocalPlayer.UserId or 0, self._requestSeq, tostring(action))
end

function RoomBrowserController:_setPendingRoomTransition(value)
	self._state.pendingRoomTransition = value == true
end

function RoomBrowserController:_resolveLobbyRemote()
	if self._lobbyRemote and self._lobbyRemote.Parent then
		return self._lobbyRemote
	end

	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
	end
	if not remoteFolder then
		return nil
	end

	local remote = remoteFolder:FindFirstChild(LOBBY_REMOTE_NAME)
	if not remote then
		remote = remoteFolder:WaitForChild(LOBBY_REMOTE_NAME)
	end
	if remote and remote:IsA("RemoteEvent") then
		self._lobbyRemote = remote
		return remote
	end
	return nil
end

function RoomBrowserController:Start()
	self:_resolveLobbyRemote()
	self:RequestSnapshot()
	self:RequestRoomList()
end

function RoomBrowserController:_send(action, payload)
	local remote = self:_resolveLobbyRemote()
	if not remote then
		self._state.lastError = "lobby_remote_not_ready"
		return false
	end
	local now = os.clock()
	if CLIENT_CRITICAL_ACTIONS[action] then
		local previous = self._lastActionSentAt[action]
		if previous and (now - previous) < 0.2 then
			return false
		end
		self._lastActionSentAt[action] = now
	end
	local request = payload or {}
	request.action = action
	request.requestId = request.requestId or self:_nextRequestId(action)
	request.clientSentAt = request.clientSentAt or now
	-- TODO: REMOVE AFTER VALIDATION
	print("[ROOM TRACE][CLIENT->SERVER]", action)
	remote:FireServer(request)
	return true
end

function RoomBrowserController:RequestSnapshot()
	self:_send("RequestRoomBrowserSnapshot")
end

function RoomBrowserController:RequestRoomList()
	self:_send("RequestRoomList")
end

function RoomBrowserController:SelectMode(mode)
	if mode == "Ranked" or mode == "Classic" then
		self._state.selectedMode = mode
	end
	if mode == "Ranked" then
		self._state.selectedDifficulty = "AUTO"
	end
	self:_send("SelectMode", {
		mode = mode,
	})
end

function RoomBrowserController:SelectDifficulty(difficulty)
	if self._state.selectedMode ~= "Ranked" and type(difficulty) == "string" and difficulty ~= "" then
		self._state.selectedDifficulty = difficulty
	end
	self:_send("SelectDifficulty", {
		difficulty = difficulty,
	})
end

function RoomBrowserController:SelectMap(mapId)
	if type(mapId) == "string" and mapId ~= "" then
		self._state.selectedMap = mapId
	end
	self:_send("SelectMap", {
		mapId = mapId,
	})
end

function RoomBrowserController:JoinRoom(roomId, password)
	self:_setPendingRoomTransition(true)
	self:_send("JoinRoom", {
		roomId = roomId,
		password = password,
	})
end

function RoomBrowserController:LeaveRoom()
	self:_send("LeaveRoom")
end

function RoomBrowserController:QueueSelected()
	self:_send("QueueFromRoomBrowser")
end

function RoomBrowserController:SetReady(isReady)
	self:_send("SetReady", { isReady = isReady })
end

function RoomBrowserController:HostStart(mapId, difficulty, mode)
	self:_send("HostStart", {
		mapId = mapId,
		difficulty = difficulty,
		mode = mode,
	})
end

function RoomBrowserController:CancelHostStart()
	self:_send("CancelHostStart")
end

function RoomBrowserController:KickPlayer(targetUserId)
	self:_send("KickPlayer", { targetUserId = targetUserId })
end

function RoomBrowserController:SetPassword(password)
	self:_send("SetPassword", { password = password })
end

function RoomBrowserController:CreateRoom()
	self:_setPendingRoomTransition(true)
	self:_send("CreateRoom")
end

function RoomBrowserController:HandleLobbyEvent(payload)
	local eventName = payload and payload.eventName
	self._state.lastEvent = eventName

	if eventName == "RoomBrowserSnapshot" then
		local snapshot = payload.snapshot or {}
		self._state.modes = snapshot.modes or self._state.modes
		self._state.classicDifficulties = snapshot.classicDifficulties or self._state.classicDifficulties
		self._state.selectedMode = snapshot.selectedMode or self._state.selectedMode
		self._state.selectedDifficulty = snapshot.selectedDifficulty or self._state.selectedDifficulty
		self._state.rooms = snapshot.rooms or self._state.rooms
		if snapshot.currentRoom ~= nil then
			self._state.currentRoom = snapshot.currentRoom
		end
		self._state.lastError = nil
	elseif eventName == "RoomBrowserRoomList" then
		self._state.rooms = payload.rooms or {}
	elseif eventName == "RoomBrowserSelectionConfirmed" then
		local selection = payload.selection or {}
		self._state.selectedMode = selection.mode or self._state.selectedMode
		self._state.selectedDifficulty = selection.difficulty or self._state.selectedDifficulty
		self._state.selectedMap = selection.mapId or self._state.selectedMap
		self._state.lastError = nil
	elseif eventName == "RoomBrowserRoomJoined" then
		self:_setPendingRoomTransition(false)
		self._state.lastRoomId = payload.roomId
		self._state.currentRoom = {
			roomId = payload.roomId,
		}
		self._state.queue = nil
		self._state.lastError = nil
	elseif eventName == "RoomBrowserRoomLeft" then
		self:_setPendingRoomTransition(false)
		self._state.currentRoom = nil
		self._state.lastRoomId = nil
		self._state.isHost = false
		self._state.isReady = false
		self._state.allReady = false
		self._state.matchStarting = false
		self._state.countdownSecondsLeft = nil
		self._state.countdownTotal = nil
		self._state.lastError = nil
	elseif eventName == "RoomBrowserRoomJoinFailed" then
		self:_setPendingRoomTransition(false)
		self._state.lastError = payload and (payload.reason or eventName) or eventName
	elseif eventName == "RoomBrowserQueueStarted" then
		self._state.queue = payload.queue
		self._state.lastError = nil
	elseif eventName == "RoomBrowserQueueFailed" then
		self._state.queue = nil
		self._state.lastError = payload.reason or eventName
	elseif eventName == "RoomReadyResult" or eventName == "HostStartResult" or eventName == "KickPlayerResult" or eventName == "CreateRoomResult" or eventName == "SetPasswordResult" or eventName == "CancelHostStartResult" then
		local okResult = payload and payload.ok
		if okResult == false then
			self:_setPendingRoomTransition(false)
			self._state.lastError = payload.err or payload.reason or eventName
		else
			if eventName == "CreateRoomResult" and payload and payload.roomId then
				self:_setPendingRoomTransition(false)
				self._state.lastRoomId = payload.roomId
				self._state.currentRoom = {
					roomId = payload.roomId,
				}
				self._state.queue = nil
			end
			self._state.lastError = nil
		end
	elseif eventName == "RoomMatchStarting" then
		self._state.matchStarting = true
		self._state.countdownTotal = payload.countdownSeconds or self._state.countdownTotal or 5
		self._state.countdownSecondsLeft = payload.countdownSeconds or self._state.countdownSecondsLeft
	elseif eventName == "RoomMatchCountdown" then
		self._state.matchStarting = true
		self._state.countdownSecondsLeft = payload.secondsLeft
		self._state.countdownTotal = payload.totalSeconds or self._state.countdownTotal
	elseif eventName == "RoomMatchCountdownCancelled" then
		self._state.matchStarting = false
		self._state.countdownSecondsLeft = nil
		self._state.countdownTotal = nil
		self._state.lastError = payload.reason == "host_cancelled" and nil or payload.reason
	elseif eventName == "RoomMatchCountdownCompleted" then
		self._state.matchStarting = false
		self._state.countdownSecondsLeft = nil
		self._state.countdownTotal = nil
	elseif eventName == "RoomStateUpdate" then
		self:_setPendingRoomTransition(false)
		local roomData = payload.room
		if type(roomData) == "table" and roomData.roomId ~= nil then
			self._state.currentRoom = roomData
			self._state.selectedMap = roomData.mapId or self._state.selectedMap
		elseif payload.roomId ~= nil then
			self._state.currentRoom = self._state.currentRoom or {}
			self._state.currentRoom.roomId = payload.roomId
			self._state.currentRoom.mapId = payload.mapId or self._state.currentRoom.mapId
			self._state.selectedMap = self._state.currentRoom.mapId or self._state.selectedMap
		else
			self._state.currentRoom = self._state.currentRoom
		end
		if payload.isHost ~= nil then
			self._state.isHost = payload.isHost == true
		end
		if payload.isReady ~= nil then
			self._state.isReady = payload.isReady == true
		end
		if payload.allReady ~= nil then
			self._state.allReady = payload.allReady == true
		end
		self._state.countdownSecondsLeft = payload.countdownSecondsLeft
		if payload.countdownSecondsLeft ~= nil then
			self._state.matchStarting = true
			self._state.countdownTotal = self._state.countdownTotal or payload.countdownSecondsLeft
		elseif self._state.matchStarting ~= true then
			self._state.countdownTotal = nil
		end
		self._state.lastError = nil
	elseif eventName and string.find(eventName, "Failed", 1, true) then
		self:_setPendingRoomTransition(false)
		self._state.lastError = payload.reason or eventName
	elseif eventName == "RoomBrowserError" or eventName == "RoomBrowserSelectionRejected" then
		self._state.lastError = payload.reason or eventName
	end

end

function RoomBrowserController:GetState()
	return self._state
end

return RoomBrowserController
