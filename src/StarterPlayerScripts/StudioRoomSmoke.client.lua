local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AUTO_ATTR = "PasrahAutoRoomSmoke"
local TRACE_ATTR = "PasrahRoomTrace"
local ENABLE_WAIT_SECONDS = 8
local LOOP_INTERVAL_SECONDS = 0.75
local SNAPSHOT_REFRESH_SECONDS = 1.5
local REQUEST_TIMEOUT_SECONDS = 5
local DESIRED_MODE = "Classic"
local DESIRED_MAP = "HauntedHouse"

if not RunService:IsStudio() then
	return
end

local localPlayer = Players.LocalPlayer
if not localPlayer then
	return
end

if localPlayer.Name ~= "Player1" and localPlayer.Name ~= "Player2" then
	return
end

local function waitForAutomationFlag()
	local deadline = os.clock() + ENABLE_WAIT_SECONDS
	while os.clock() <= deadline do
		if ReplicatedStorage:GetAttribute(AUTO_ATTR) == true then
			return true
		end
		task.wait(0.2)
	end
	return ReplicatedStorage:GetAttribute(AUTO_ATTR) == true
end

if not waitForAutomationFlag() then
	return
end

local function setSmokeStatus(status, detail)
	pcall(function()
		localPlayer:SetAttribute("PasrahStudioRoomSmokeStatus", tostring(status))
		localPlayer:SetAttribute("PasrahStudioRoomSmokeDetail", tostring(detail or ""))
	end)
end

local function trace(message)
	local prefix = string.format("[StudioRoomSmoke][%s]", localPlayer.Name)
	warn(string.format("%s %s", prefix, tostring(message)))
	setSmokeStatus("trace", message)
end

local clientModule = script.Parent:WaitForChild("Client", 15)
if not clientModule then
	trace("Client module unavailable")
	return
end

local uiModule = clientModule:WaitForChild("UI", 15)
local roomBrowserModule = uiModule and uiModule:WaitForChild("RoomBrowserController", 15)
if not roomBrowserModule then
	trace("RoomBrowserController unavailable")
	return
end

local RoomBrowserController = require(roomBrowserModule)
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
local lobbyRemote = remoteFolder and remoteFolder:WaitForChild("LobbyEvent", 15)
if not lobbyRemote then
	trace("LobbyEvent unavailable")
	return
end

if ReplicatedStorage:GetAttribute(TRACE_ATTR) ~= true then
	pcall(function()
		ReplicatedStorage:SetAttribute(TRACE_ATTR, true)
	end)
end

local controller = RoomBrowserController.new(lobbyRemote)
local isHostClient = localPlayer.Name == "Player1"
local createRequestedAt = nil
local joinRequestedAt = nil
local lastRefreshAt = 0
local readySent = false
local hostStartSent = false

local function roomIdOf(room)
	if type(room) ~= "table" then
		return nil
	end
	return room.roomId or room.id
end

local function playerCountOf(room)
	if type(room) ~= "table" then
		return 0
	end
	local numeric = tonumber(room.playerCount)
	if numeric and numeric > 0 then
		return numeric
	end
	if type(room.players) == "table" then
		return #room.players
	end
	return 0
end

local function refreshSnapshot(now)
	now = now or os.clock()
	if (now - lastRefreshAt) < SNAPSHOT_REFRESH_SECONDS then
		return
	end
	lastRefreshAt = now
	controller:RequestSnapshot()
	controller:RequestRoomList()
end

local function pickJoinableRoom(rooms)
	for _, room in ipairs(rooms or {}) do
		local roomId = roomIdOf(room)
		if roomId and playerCountOf(room) >= 1 and room.inGame ~= true and room.starting ~= true then
			return room
		end
	end
	return nil
end

lobbyRemote.OnClientEvent:Connect(function(payload)
	controller:HandleLobbyEvent(payload)
	local eventName = payload and payload.eventName or "unknown"
	setSmokeStatus("event", eventName)
end)

controller:Start()
refreshSnapshot()
setSmokeStatus("running", isHostClient and "host" or "joiner")
trace(isHostClient and "host automation armed" or "joiner automation armed")

task.spawn(function()
	while true do
		local now = os.clock()
		local state = controller:GetState() or {}
		local room = state.currentRoom
		local roomId = roomIdOf(room)
		local playerCount = playerCountOf(room)

		if state.lastError then
			trace("state error: " .. tostring(state.lastError))
			if isHostClient and (state.lastError == "no_rooms_available" or state.lastError == "room_manager_unavailable") then
				createRequestedAt = nil
			elseif not isHostClient and (string.find(tostring(state.lastError), "room", 1, true) or string.find(tostring(state.lastError), "join", 1, true)) then
				joinRequestedAt = nil
				readySent = false
			end
		end

		if isHostClient then
			if not roomId then
				refreshSnapshot(now)
				if not createRequestedAt or (now - createRequestedAt) > REQUEST_TIMEOUT_SECONDS then
					controller:SelectMode(DESIRED_MODE)
					controller:SelectMap(DESIRED_MAP)
					controller:CreateRoom()
					createRequestedAt = now
					hostStartSent = false
					trace("create room requested")
				end
			else
				if playerCount < 2 then
					refreshSnapshot(now)
				end
				if playerCount >= 2 and state.allReady == true and state.matchStarting ~= true and not hostStartSent then
					controller:HostStart(room.mapId or DESIRED_MAP, nil, room.mode or state.selectedMode or DESIRED_MODE)
					hostStartSent = true
					trace("host start requested for room " .. tostring(roomId))
				end
			end
		else
			if not roomId then
				refreshSnapshot(now)
				local targetRoom = pickJoinableRoom(state.rooms)
				if targetRoom and (not joinRequestedAt or (now - joinRequestedAt) > REQUEST_TIMEOUT_SECONDS) then
					controller:JoinRoom(roomIdOf(targetRoom), nil)
					joinRequestedAt = now
					readySent = false
					trace("join room requested for room " .. tostring(roomIdOf(targetRoom)))
				end
			elseif state.isReady ~= true and not readySent then
				controller:SetReady(true)
				readySent = true
				trace("ready requested for room " .. tostring(roomId))
			end
		end

		if state.matchStarting == true or state.countdownSecondsLeft ~= nil then
			trace("countdown active")
			setSmokeStatus("countdown", tostring(state.countdownSecondsLeft or "started"))
			return
		end

		task.wait(LOOP_INTERVAL_SECONDS)
	end
end)