local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local REMOTE_FOLDER_NAME = "RemoteEvents"
local CHECKIN_REMOTE_NAME = "DailyCheckinRequest"
local MISSION_CLAIM_REMOTE_NAME = "DailyMissionClaimRequest"
local GACHA_PULL_REMOTE_NAME = "GachaPullRequest"
local REQUEST_COOLDOWN_SECONDS = 0.35

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

local function resolveSecurityService(deps)
	local security = Services.Get(deps, "SecuritySystem")
	if type(security) ~= "table" then
		return nil
	end
	if type(security.ValidateRemoteRequest) == "function" then
		return security
	end
	if type(security.Service) == "table" and type(security.Service.ValidateRemoteRequest) == "function" then
		return security.Service
	end
	return nil
end

local function toUserId(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player.UserId
	end
	return nil
end

local function resolveRemote(remoteName)
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
	if not folder then
		return nil
	end
	local remote = folder:FindFirstChild(remoteName)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

local function resolveMissionId(request)
	if type(request) == "string" then
		return request
	end
	if type(request) ~= "table" then
		return nil
	end
	if type(request.missionId) == "string" then
		return request.missionId
	end
	if type(request.payload) == "table" and type(request.payload.missionId) == "string" then
		return request.payload.missionId
	end
	return nil
end

function Controller.new(state, service, deps)
	local self = setmetatable({}, Controller)
	self._state = state
	self._service = service
	self._deps = deps or {}
	self._eventBus = nil
	self._security = nil
	self._subscriptions = {}
	self._connections = {}
	self._remoteConnections = {}
	self._registered = false
	self._lastRequestAtByUserId = {}
	return self
end

function Controller:Create()
	self._eventBus = resolveEventBus(self._deps)
	self._security = resolveSecurityService(self._deps)
end

function Controller:Init()
	-- Runtime wiring happens in Start.
end

function Controller:Start()
	print(">>> DailyEngagement Controller:Start() ENTERED <<<")
	print(">>> START line 1")
	print(">>> START line 2")
	print(">>> START line 3, calling RegisterEventHandlers now")
	self:RegisterEventHandlers()
	print(">>> START line 4 returned from RegisterEventHandlers")
	self:_connectPlayerSignals()
	print(">>> START line 5 returned from _connectPlayerSignals")
	self:_connectRemotes()
	print(">>> START line 6 returned from _connectRemotes")
	print(">>> DailyEngagement Controller:Start() COMPLETE <<<")
end

function Controller:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	for _, connection in ipairs(self._remoteConnections) do
		connection:Disconnect()
	end
	table.clear(self._remoteConnections)

	self:UnregisterEventHandlers()
	table.clear(self._lastRequestAtByUserId)
end

function Controller:RegisterEventHandlers()
	print("[REG-0] RegisterEventHandlers ENTERED")
	print("[REG-1] eventBus=", self._eventBus ~= nil, " registered=", self._registered)
	if not self._eventBus then
		print("[REG-2] eventBus is nil - returning early")
		return
	end
	if self._registered then
		print("[REG-3] already registered - skipping")
		return
	end

	print("[REG-4] about to subscribe PlayerEnteredLobby")
	self:_subscribe("PlayerEnteredLobby", function(payload)
		print("[REG-EVENT] PlayerEnteredLobby fired! player:", payload and payload.player and payload.player.Name)
		if payload and payload.player then
			self._service:OnPlayerEnteredLobby(payload.player)
		end
	end)

	-- Sync all players already in the game when subscription is registered
	for _, player in ipairs(Players:GetPlayers()) do
		print("[REG-5] syncing existing player:", player.Name)
		self._service:OnPlayerEnteredLobby(player)
	end

	self:_subscribe("PlayerJoinedLobby", function(payload)
		if payload and payload.player then
			self._service:OnPlayerEnteredLobby(payload.player)
		end
	end)

	self:_subscribe("DailyRewardClaimRequest", function(payload)
		if payload and payload.player then
			self._service:OnDailyRewardClaimRequest(payload)
		end
	end)

	self:_subscribe("MatchStarted", function(payload)
		self._service:OnMatchStarted(payload)
	end)

	self:_subscribe("MatchEnded", function(payload)
		self._service:OnMatchEnded(payload)
	end)

	self:_subscribe("EvidenceCollected", function(payload)
		self._service:OnEvidenceCollected(payload)
	end)

	self:_subscribe("GhostIdentified", function(payload)
		self._service:OnGhostIdentified(payload)
	end)

	self:_subscribe("PlayerEscapedHunt", function(payload)
		self._service:OnHuntSurvived(payload)
	end)

	self:_subscribe("PlayerHid", function(payload)
		self._service:OnHideSuccess(payload)
	end)

	self:_subscribe("ClosetHideEntered", function(payload)
		self._service:OnHideSuccess(payload)
	end)

	self:_subscribe("ToolActivated", function(payload)
		self._service:OnToolUsed(payload)
	end)

	self:_subscribe("InvestigationToolUsed", function(payload)
		self._service:OnToolUsed(payload)
	end)

	self:_subscribe("FlashlightToggled", function(payload)
		self._service:OnToolUsed(payload)
	end)

	self._registered = true
end

function Controller:UnregisterEventHandlers()
	if not self._eventBus or not self._registered then
		return
	end

	for _, subscription in ipairs(self._subscriptions) do
		self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
	end
	table.clear(self._subscriptions)
	self._registered = false
end

function Controller:_subscribe(eventName, callback)
	self._eventBus:Subscribe(eventName, callback)
	table.insert(self._subscriptions, {
		eventName = eventName,
		callback = callback,
	})
end

function Controller:_connectPlayerSignals()
	print("[DEBUG-CTRL-1] _connectPlayerSignals called, existing players:", #Players:GetPlayers())
	table.insert(self._connections, Players.PlayerAdded:Connect(function(player)
		print("[DEBUG-CTRL-2] Players.PlayerAdded fired for: " .. player.Name)
		self._service:OnPlayerAdded(player)
	end))
	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
		self._service:OnPlayerRemoving(player)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		print("[DEBUG-CTRL-3] Pre-seed: calling OnPlayerAdded for: " .. player.Name)
		self._service:OnPlayerAdded(player)
	end
end

function Controller:_connectRemotes()
	self:_connectRemote(CHECKIN_REMOTE_NAME, function(player, request)
		self:OnCheckinRemote(player, request)
	end)
	self:_connectRemote(MISSION_CLAIM_REMOTE_NAME, function(player, request)
		self:OnMissionClaimRemote(player, request)
	end)
	self:_connectRemote(GACHA_PULL_REMOTE_NAME, function(player, request)
		self:OnGachaPullRemote(player, request)
	end)
end

function Controller:_connectRemote(remoteName, callback)
	local remote = resolveRemote(remoteName)
	if not remote then
		return
	end
	table.insert(self._remoteConnections, remote.OnServerEvent:Connect(callback))
end

function Controller:_send(remoteName, player, payload)
	local remote = resolveRemote(remoteName)
	if remote and player then
		remote:FireClient(player, payload)
	end
end

function Controller:_validateRemoteRequest(player, remoteName, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local userId = toUserId(player)
	if not userId then
		return false, "invalid_player"
	end

	local now = os.clock()
	local cooldownKey = tostring(userId) .. ":" .. remoteName
	local last = self._lastRequestAtByUserId[cooldownKey] or 0
	if (now - last) < REQUEST_COOLDOWN_SECONDS then
		return false, "cooldown"
	end
	self._lastRequestAtByUserId[cooldownKey] = now

	if self._security then
		local ok, reason = self._security:ValidateRemoteRequest(player, remoteName, request, {
			system = "DailyEngagementSystem",
		})
		if not ok then
			return false, reason or "blocked_by_security"
		end
	end

	return true
end

function Controller:OnCheckinRemote(player, request)
	local requestId = type(request) == "table" and request.requestId or nil
	local valid, reason = self:_validateRemoteRequest(player, CHECKIN_REMOTE_NAME, request)
	if not valid then
		self:_send(CHECKIN_REMOTE_NAME, player, {
			eventName = "DailyCheckinProcessed",
			requestId = requestId,
			success = false,
			reason = reason,
		})
		return
	end

	local ok, result = self._service:HandleCheckin(player)
	self:_send(CHECKIN_REMOTE_NAME, player, {
		eventName = "DailyCheckinProcessed",
		requestId = requestId,
		success = ok == true,
		reason = ok == true and nil or result,
		result = ok == true and result or nil,
		snapshot = self._service:BuildClientSnapshot(player),
	})
end

function Controller:OnMissionClaimRemote(player, request)
	local requestId = type(request) == "table" and request.requestId or nil
	local valid, reason = self:_validateRemoteRequest(player, MISSION_CLAIM_REMOTE_NAME, request)
	if not valid then
		self:_send(MISSION_CLAIM_REMOTE_NAME, player, {
			eventName = "DailyMissionClaimProcessed",
			requestId = requestId,
			success = false,
			reason = reason,
		})
		return
	end

	local missionId = resolveMissionId(request)
	if type(missionId) ~= "string" or missionId == "" then
		self:_send(MISSION_CLAIM_REMOTE_NAME, player, {
			eventName = "DailyMissionClaimProcessed",
			requestId = requestId,
			success = false,
			reason = "invalid_mission_id",
		})
		return
	end

	local ok, result = self._service:ClaimMissionReward(player, missionId)
	self:_send(MISSION_CLAIM_REMOTE_NAME, player, {
		eventName = "DailyMissionClaimProcessed",
		requestId = requestId,
		success = ok == true,
		reason = ok == true and nil or result,
		mission = ok == true and result or nil,
		snapshot = self._service:BuildClientSnapshot(player),
	})
end

function Controller:OnGachaPullRemote(player, request)
	local requestId = type(request) == "table" and request.requestId or nil
	local valid, reason = self:_validateRemoteRequest(player, GACHA_PULL_REMOTE_NAME, request)
	if not valid then
		self:_send(GACHA_PULL_REMOTE_NAME, player, {
			eventName = "GachaPullProcessed",
			requestId = requestId,
			success = false,
			reason = reason,
		})
		return
	end

	local pullCount = type(request) == "table" and tonumber(request.pullCount or request.count) or 1
	local paymentType = type(request) == "table" and (request.paymentType or request.currency) or nil
	local ok, result = self._service:PullGacha(player, pullCount, paymentType)
	self:_send(GACHA_PULL_REMOTE_NAME, player, {
		eventName = "GachaPullProcessed",
		requestId = requestId,
		success = ok == true,
		reason = ok == true and nil or result,
		results = ok == true and result or nil,
		snapshot = self._service:BuildClientSnapshot(player),
	})
end

return Controller
