local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")

local Service = {}
Service.__index = Service

local HIDE_PROMPT_NAME = "HideSpotPrompt"
local HIDE_PROMPT_DISTANCE = 8
local HIDE_PROMPT_HOLD_DURATION = 0
local HIDE_ROOM_VERTICAL_TOLERANCE = 6

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Publish) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
		return eventBus.Service
	end
	return nil
end

local function resolveMatchSystem(deps)
	local matchSystem = Services.Get(deps, "MatchSystem")
	if type(matchSystem) ~= "table" then
		return nil
	end
	if type(matchSystem.GetLiveMatch) == "function" then
		return matchSystem
	end
	if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
		return matchSystem.Service
	end
	return nil
end

local function toUserId(playerOrUserId)
	if type(playerOrUserId) == "number" then
		return playerOrUserId
	end
	if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		return playerOrUserId.UserId
	end
	return nil
end

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-_%.]+", ""):lower()
end

local function getLiveMatch(matchSystem, matchId)
	if type(matchSystem) ~= "table" or type(matchId) ~= "string" or matchId == "" then
		return nil
	end
	return matchSystem:GetLiveMatch(matchId)
end

local function getRuntimeMapModel(matchSystem, matchId)
	local liveMatch = getLiveMatch(matchSystem, matchId)
	if type(liveMatch) ~= "table" then
		return nil
	end

	local container = liveMatch.container
	if typeof(container) ~= "Instance" then
		return nil
	end

	for _, expectedName in ipairs({ liveMatch.mapId, liveMatch.map }) do
		if type(expectedName) == "string" and expectedName ~= "" then
			local exact = container:FindFirstChild(expectedName)
			if exact then
				return exact
			end
		end
	end

	for _, child in ipairs(container:GetChildren()) do
		if (child:IsA("Model") or child:IsA("Folder"))
			and not child.Name:match("^GhostPlaceholder_")
			and not child.Name:match("^Ghost_") then
			return child
		end
	end

	return nil
end

local function getCharacterRoot(player)
	local character = typeof(player) == "Instance" and player:IsA("Player") and player.Character or nil
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local function isPointInsidePart(part, worldPosition)
	if not part or not part:IsA("BasePart") or typeof(worldPosition) ~= "Vector3" then
		return false
	end

	local localPosition = part.CFrame:PointToObjectSpace(worldPosition)
	local half = part.Size * 0.5
	local verticalTolerance = math.max(half.Y, HIDE_ROOM_VERTICAL_TOLERANCE)
	return math.abs(localPosition.X) <= half.X
		and math.abs(localPosition.Y) <= verticalTolerance
		and math.abs(localPosition.Z) <= half.Z
end

local function isClosetRoom(part)
	if not part or not part:IsA("BasePart") then
		return false
	end

	local normalized = normalizeToken(part.Name:gsub("^Room_", ""))
	return normalized ~= nil and (normalized:match("^closet") ~= nil or normalized:match("^locker") ~= nil)
end

local function formatClosetLabel(part)
	local raw = tostring(part and part.Name or "Hide Spot"):gsub("^Room_", ""):gsub("_", " ")
	return raw:gsub("^%l", string.upper)
end

local function ensurePrompt(part)
	local prompt = part:FindFirstChild(HIDE_PROMPT_NAME)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.MaxActivationDistance = HIDE_PROMPT_DISTANCE
		prompt.HoldDuration = HIDE_PROMPT_HOLD_DURATION
		prompt.RequiresLineOfSight = false
		prompt.Style = Enum.ProximityPromptStyle.Default
		return prompt
	end

	if prompt then
		prompt:Destroy()
	end

	prompt = Instance.new("ProximityPrompt")
	prompt.Name = HIDE_PROMPT_NAME
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = HIDE_PROMPT_DISTANCE
	prompt.HoldDuration = HIDE_PROMPT_HOLD_DURATION
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = part
	return prompt
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._dependencies = {}
	self._runtimeHideSpotsByMatchId = {}
	self._running = false
	self._runtimeThread = nil
	return self
end

function Service:Init()
	self._dependencies = {
		GhostSystem = Services.Get(self._deps, "GhostSystem"),
		InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
		MatchSystem = resolveMatchSystem(self._deps),
		EconomySystem = Services.Get(self._deps, "EconomySystem"),
		ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
	}
end

function Service:Start()
	self._running = true
	if self._runtimeThread == nil then
		self._runtimeThread = task.spawn(function()
			while self._running do
				local activeMatchId = self._state:Get("activeMatchId")
				if type(activeMatchId) == "string" and activeMatchId ~= "" then
					self:_ensureHideSpotsRegistered(activeMatchId)
					self:_syncHiddenOccupants(activeMatchId)
				end
				task.wait(0.25)
			end
			self._runtimeThread = nil
		end)
	end
end

function Service:Stop()
	self._running = false
	for matchId in pairs(self._runtimeHideSpotsByMatchId) do
		self:_cleanupHideSpots(matchId)
	end
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_getOccupancy()
	return self._state:Get("closetOccupancy") or {}
end

function Service:_setOccupancy(occupancy)
	self._state:Set("closetOccupancy", occupancy or {})
end

function Service:_updatePromptState(record)
	if type(record) ~= "table" then
		return
	end

	local prompt = record.prompt
	if not (prompt and prompt.Parent) then
		return
	end

	local occupancy = self:_getOccupancy()
	local occupantUserId = occupancy[record.id]
	local occupied = occupantUserId ~= nil

	prompt.ObjectText = record.label
	prompt.Enabled = true
	prompt.ActionText = occupied and "Keluar" or "Bersembunyi"

	record.part:SetAttribute("HideSpotId", record.id)
	record.part:SetAttribute("HideSpotType", "Closet")
	record.part:SetAttribute("HideSpotOccupied", occupied)
end

function Service:_syncPromptStates(matchId)
	local state = self._runtimeHideSpotsByMatchId[matchId]
	if type(state) ~= "table" then
		return
	end

	for _, record in pairs(state.records or {}) do
		self:_updatePromptState(record)
	end
end

function Service:_cleanupHideSpots(matchId)
	local state = self._runtimeHideSpotsByMatchId[matchId]
	if type(state) ~= "table" then
		return
	end

	for _, record in pairs(state.records or {}) do
		if record.connection then
			record.connection:Disconnect()
		end
		if record.prompt and record.prompt.Parent then
			record.prompt:Destroy()
		end
		if record.part and record.part.Parent then
			record.part:SetAttribute("HideSpotId", nil)
			record.part:SetAttribute("HideSpotType", nil)
			record.part:SetAttribute("HideSpotOccupied", nil)
		end
	end

	self._runtimeHideSpotsByMatchId[matchId] = nil
end

function Service:_registerHideSpots(matchId)
	if type(matchId) ~= "string" or matchId == "" then
		return
	end

	self:_cleanupHideSpots(matchId)

	local mapModel = getRuntimeMapModel(self._dependencies.MatchSystem, matchId)
	local roomsFolder = mapModel and mapModel:FindFirstChild("Rooms", true)
	if not roomsFolder then
		return
	end

	local records = {}
	for _, room in ipairs(roomsFolder:GetChildren()) do
		if room:IsA("BasePart") and isClosetRoom(room) then
			local record = {
				id = room.Name,
				label = formatClosetLabel(room),
				part = room,
				prompt = ensurePrompt(room),
			}

			record.connection = record.prompt.Triggered:Connect(function(player)
				local userId = toUserId(player)
				if not userId then
					return
				end

				local occupancy = self:_getOccupancy()
				local occupantUserId = occupancy[record.id]
				if occupantUserId and occupantUserId ~= userId then
					return
				end

				if occupantUserId == userId then
					self:_publish("PlayerExitHide", {
						player = player,
						userId = userId,
						closetId = record.id,
						zoneId = record.id,
						spotType = "Closet",
					})
				else
					self:_publish("PlayerAttemptHide", {
						player = player,
						userId = userId,
						closetId = record.id,
						zoneId = record.id,
						spotType = "Closet",
						movementLevel = 0,
						noiseLevel = 0,
					})
				end
			end)

			records[record.id] = record
			self:_updatePromptState(record)
		end
	end

	self._runtimeHideSpotsByMatchId[matchId] = {
		records = records,
	}
end

function Service:_ensureHideSpotsRegistered(matchId)
	if type(matchId) ~= "string" or matchId == "" then
		return
	end

	local state = self._runtimeHideSpotsByMatchId[matchId]
	if type(state) ~= "table" or next(state.records or {}) == nil then
		self:_registerHideSpots(matchId)
	end
end

function Service:_syncHiddenOccupants(matchId)
	if type(matchId) ~= "string" or matchId == "" then
		return
	end

	local state = self._runtimeHideSpotsByMatchId[matchId]
	if type(state) ~= "table" then
		return
	end

	local occupancy = self:_getOccupancy()
	local exits = {}
	for closetId, userId in pairs(occupancy) do
		local record = state.records and state.records[closetId] or nil
		local player = Players:GetPlayerByUserId(tonumber(userId) or 0)
		local root = getCharacterRoot(player)
		if not record or not record.part or not root or not isPointInsidePart(record.part, root.Position) then
			table.insert(exits, {
				player = player,
				userId = userId,
				closetId = closetId,
			})
		end
	end

	for _, payload in ipairs(exits) do
		self:_publish("PlayerExitHide", {
			player = payload.player,
			userId = payload.userId,
			closetId = payload.closetId,
			zoneId = payload.closetId,
			spotType = "Closet",
		})
	end
end

function Service:HandleEvent(eventName, payload)
	if eventName == "MatchStarted" then
		self._state:Set("activeMatchId", payload and payload.matchId)
	elseif eventName == "MatchEnded" then
		self._state:Set("activeMatchId", nil)
	elseif eventName == "PlayerTeleported" and payload and payload.matchId then
		self._state:Set("activeMatchId", payload.matchId)
	end

	if eventName == "MatchStarted" then
		self:_setOccupancy({})
		self:_registerHideSpots(payload and payload.matchId)
	elseif eventName == "PlayerTeleported" then
		self:_ensureHideSpotsRegistered(payload and payload.matchId)
	elseif eventName == "PlayerAttemptHide" then
		if payload and payload.spotType ~= "Closet" and payload.spotType ~= "Locker" then
			return
		end
		local userId = toUserId(payload and (payload.player or payload.userId))
		if userId then
			local occupancy = self:_getOccupancy()
			local closetId = payload.closetId or ("closet_" .. tostring(userId))
			occupancy[closetId] = userId
			self:_setOccupancy(occupancy)
			self:_syncPromptStates(self._state:Get("activeMatchId"))
			self:_publish("ClosetHideEntered", {
				userId = userId,
				player = payload.player,
				closetId = closetId,
				matchId = self._state:Get("activeMatchId"),
			})
		end
	elseif eventName == "PlayerExitHide" then
		local userId = toUserId(payload and (payload.player or payload.userId))
		local occupancy = self:_getOccupancy()
		if userId then
			for closetId, occupantId in pairs(occupancy) do
				if occupantId == userId then
					occupancy[closetId] = nil
					self:_publish("ClosetHideExited", {
						userId = userId,
						player = payload.player,
						closetId = closetId,
						matchId = self._state:Get("activeMatchId"),
					})
				end
			end
			self:_setOccupancy(occupancy)
			self:_syncPromptStates(self._state:Get("activeMatchId"))
		end
	elseif eventName == "MatchEnded" then
		self:_cleanupHideSpots(payload and payload.matchId)
		self:_setOccupancy({})
	end
end

return Service
