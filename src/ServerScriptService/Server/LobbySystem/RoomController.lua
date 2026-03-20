local RoomService = require(script.Parent.RoomService)
local RoomRegistry = require(script.Parent.RoomRegistry)

local RoomController = {}
RoomController.__index = RoomController

local LOBBY_REMOTE_NAME = "LobbyEvent"

local ACTION_HANDLERS = {
	CreateRoom = "OnCreateRoom",
	JoinRoom = "OnJoinRoom",
	LeaveRoom = "OnLeaveRoom",
	SetReady = "OnSetReady",
	SetRoomMode = "OnSetRoomMode",
	SetRoomMap = "OnSetRoomMap",
	KickPlayer = "OnKickPlayer",
	StartMatch = "OnStartMatch",
	GetRooms = "OnGetRooms",
}

function RoomController.new(deps)
	local self = setmetatable({}, RoomController)
	self._deps = deps or {}
	self._service = RoomService.new(self._deps)
	self._lobbyRemote = nil
	self._remoteConnection = nil
	return self
end

function RoomController:Init()
	self._lobbyRemote = self:_resolveLobbyRemote()
	self:_connectLobbyRemote()
end

function RoomController:RegisterEventHandlers()
	self:_connectLobbyRemote()
end

function RoomController:UnregisterEventHandlers()
	self:_disconnectLobbyRemote()
end

function RoomController:_resolveLobbyRemote()
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local remoteFolder = replicatedStorage:WaitForChild("RemoteEvents")
	local remote = remoteFolder:WaitForChild(LOBBY_REMOTE_NAME)

	if not remote:IsA("RemoteEvent") then
		error("LobbyEvent must be a RemoteEvent")
	end

	return remote
end

function RoomController:_connectLobbyRemote()
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

function RoomController:_disconnectLobbyRemote()
	if self._remoteConnection then
		self._remoteConnection:Disconnect()
		self._remoteConnection = nil
	end
end

function RoomController:_send(player, payload)
	if self._lobbyRemote and player then
		self._lobbyRemote:FireClient(player, payload)
	end
end

function RoomController:BroadcastRoomList()
	local rooms = RoomRegistry.GetRooms()
	if not self._lobbyRemote then
		self._lobbyRemote = self:_resolveLobbyRemote()
	end
	if not self._lobbyRemote then
		return
	end
	self._lobbyRemote:FireAllClients({
		action = "RoomListUpdate",
		rooms = rooms,
	})
end

function RoomController:SendRoomUpdate(player)
	self:_send(player, {
		action = "RoomListUpdate",
		rooms = RoomRegistry.GetRooms(),
	})
end

function RoomController:OnLobbyRemoteRequest(player, request)
	if type(request) ~= "table" then
		return
	end

	local action = request.action
	local handlerName = ACTION_HANDLERS[action]
	if not handlerName then
		return
	end

	local handler = self[handlerName]
	if type(handler) ~= "function" then
		return
	end

	handler(self, player, request)
end

function RoomController:OnCreateRoom(player)
	local room = self._service:CreateRoom()
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "CreateRoom",
		ok = room ~= nil,
		room = room,
	})
	self:BroadcastRoomList()
end

function RoomController:OnJoinRoom(player, request)
	local ok, reason = self._service:JoinRoom(player, request.roomId)
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "JoinRoom",
		ok = ok,
		reason = reason,
		roomId = request.roomId,
	})
	self:SendRoomUpdate(player)
	self:BroadcastRoomList()
end

function RoomController:OnLeaveRoom(player)
	local ok, reason = self._service:LeaveRoom(player)
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "LeaveRoom",
		ok = ok,
		reason = reason,
	})
	self:BroadcastRoomList()
end

function RoomController:OnSetReady(player, request)
	local ok, reason = self._service:SetPlayerReady(player, request.roomId, request.ready)
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "SetReady",
		ok = ok,
		reason = reason,
		roomId = request.roomId,
	})
	self:BroadcastRoomList()
end

function RoomController:OnSetRoomMode(player, request)
	local ok, reason = self._service:SetRoomMode(player, request.roomId, request.mode)
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "SetRoomMode",
		ok = ok,
		reason = reason,
		roomId = request.roomId,
		mode = request.mode,
	})
	self:BroadcastRoomList()
end

function RoomController:OnSetRoomMap(player, request)
	local ok, reason = self._service:SetRoomMap(player, request.roomId, request.mapName)
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "SetRoomMap",
		ok = ok,
		reason = reason,
		roomId = request.roomId,
		mapName = request.mapName,
	})
	self:BroadcastRoomList()
end

function RoomController:OnKickPlayer(player, request)
	local ok, reason = self._service:KickPlayer(player, request.roomId, request.targetPlayer)
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "KickPlayer",
		ok = ok,
		reason = reason,
		roomId = request.roomId,
	})
	self:BroadcastRoomList()
end

function RoomController:OnStartMatch(player, request)
	local ok, reason = self._service:StartMatchManual(player, request.roomId)
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "StartMatch",
		ok = ok,
		reason = reason,
		roomId = request.roomId,
	})
	self:BroadcastRoomList()
end

function RoomController:OnGetRooms(player)
	self:_send(player, {
		eventName = "RoomActionResult",
		action = "GetRooms",
		ok = true,
		rooms = RoomRegistry.GetRooms(),
	})
end

return RoomController
