local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Service = {}
Service.__index = Service

local HIDE_PROMPT_NAME = "HideSpotPrompt"
local HIDE_PROMPT_DISTANCE = 8
local HIDE_PROMPT_HOLD_DURATION = 0
local HIDE_ROOM_VERTICAL_TOLERANCE = 6
local HIDE_SPOT_MARKER_FOLDER_NAME = "HideSpotRuntimeMarker"
local HIDE_SPOT_MARKER_OUTLINE_NAME = "Outline"
local HIDE_SPOT_MARKER_LABEL_NAME = "Billboard"
local HIDE_SPOT_MARKER_OUTLINE_COLOR = Color3.fromRGB(214, 184, 122)
local HIDE_SPOT_MARKER_PANEL_COLOR = Color3.fromRGB(28, 22, 14)
local HIDE_SPOT_MARKER_PANEL_STROKE = Color3.fromRGB(244, 206, 132)
local HIDE_SPOT_MARKER_TITLE_COLOR = Color3.fromRGB(255, 244, 224)
local HIDE_SPOT_MARKER_SUBTITLE_COLOR = Color3.fromRGB(229, 202, 152)
local HIDE_SPOT_MARKER_SUBTITLE_TEXT = "Bersembunyi saat hunt"
local HIDE_SPOT_MARKER_STUDS_OFFSET = 2.6

local function createMarkerTextLabel(name, font, textSize, textColor, text, height, position)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Position = position
	label.Size = UDim2.new(1, -18, 0, height)
	label.Font = font
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = textSize
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.82
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	return label
end

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

local function resolveMapConfigSystem(deps)
	local mapConfigSystem = Services.Get(deps, "MapConfigSystem")
	if type(mapConfigSystem) ~= "table" then
		return nil
	end
	if type(mapConfigSystem.GetMapConfig) == "function" then
		return mapConfigSystem
	end
	if type(mapConfigSystem.Service) == "table" and type(mapConfigSystem.Service.GetMapConfig) == "function" then
		return mapConfigSystem.Service
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

local function inferStudioMatchIdFromWorkspace()
	if not RunService:IsStudio() then
		return nil
	end

	local activeMatches = workspace:FindFirstChild("ActiveMatches")
	if not activeMatches then
		return nil
	end

	for _, child in ipairs(activeMatches:GetChildren()) do
		if child:IsA("Folder") and child.Name:match("^Match_") then
			local inferred = child.Name:gsub("^Match_", "")
			if inferred ~= "" then
				return inferred
			end
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

local function buildHideSpotLookup(mapConfig)
	local lookup = {}
	if type(mapConfig) ~= "table" then
		return lookup
	end

	for _, roomName in ipairs(mapConfig.hideSpotRooms or {}) do
		if type(roomName) == "string" and roomName ~= "" then
			local token = normalizeToken(roomName)
			if token then
				lookup[token] = true
			end
		end
	end

	return lookup
end

local function isConfiguredHideSpotRoom(part, lookup)
	if type(lookup) ~= "table" or next(lookup) == nil then
		return false
	end
	if not part or not part:IsA("BasePart") then
		return false
	end

	local roomToken = normalizeToken(part.Name:gsub("^Room_", ""))
	if roomToken and lookup[roomToken] == true then
		return true
	end

	local directToken = normalizeToken(part.Name)
	return directToken and lookup[directToken] == true or false
end

local function formatClosetLabel(part)
	local raw = tostring(part and part.Name or "Hide Spot"):gsub("^Room_", ""):gsub("_", " ")
	return raw:gsub("^%l", string.upper)
end

local function ensureHideSpotMarker(record)
	if type(record) ~= "table" then
		return
	end

	local part = record.part
	if not part or part.Parent == nil then
		return
	end

	local markerFolder = record.markerFolder
	if typeof(markerFolder) ~= "Instance" or markerFolder.Parent ~= part then
		markerFolder = part:FindFirstChild(HIDE_SPOT_MARKER_FOLDER_NAME)
		if not (markerFolder and markerFolder:IsA("Folder")) then
			if markerFolder then
				markerFolder:Destroy()
			end
			markerFolder = Instance.new("Folder")
			markerFolder.Name = HIDE_SPOT_MARKER_FOLDER_NAME
			markerFolder.Parent = part
		end
		record.markerFolder = markerFolder
	end

	local outline = markerFolder:FindFirstChild(HIDE_SPOT_MARKER_OUTLINE_NAME)
	if not (outline and outline:IsA("BoxHandleAdornment")) then
		if outline then
			outline:Destroy()
		end
		outline = Instance.new("BoxHandleAdornment")
		outline.Name = HIDE_SPOT_MARKER_OUTLINE_NAME
		outline.Parent = markerFolder
	end
	outline.Adornee = part
	outline.AlwaysOnTop = true
	outline.Color3 = HIDE_SPOT_MARKER_OUTLINE_COLOR
	outline.Size = part.Size + Vector3.new(0.18, 0.18, 0.18)
	outline.Transparency = 0.32
	outline.ZIndex = 6
	outline.Visible = false
	record.markerOutline = outline

	local labelGui = markerFolder:FindFirstChild(HIDE_SPOT_MARKER_LABEL_NAME)
	if not (labelGui and labelGui:IsA("BillboardGui")) then
		if labelGui then
			labelGui:Destroy()
		end
		labelGui = Instance.new("BillboardGui")
		labelGui.Name = HIDE_SPOT_MARKER_LABEL_NAME
		labelGui.Parent = markerFolder
	end
	labelGui.Active = false
	labelGui.Adornee = part
	labelGui.AlwaysOnTop = true
	labelGui.Brightness = 2
	labelGui.ClipsDescendants = false
	labelGui.Enabled = false
	labelGui.LightInfluence = 0
	labelGui.MaxDistance = 80
	labelGui.ResetOnSpawn = false
	labelGui.Size = UDim2.fromOffset(196, 48)
	labelGui.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y * 0.5 + HIDE_SPOT_MARKER_STUDS_OFFSET, 0)
	record.markerBillboard = labelGui

	local panel = labelGui:FindFirstChild("Panel")
	if not (panel and panel:IsA("Frame")) then
		if panel then
			panel:Destroy()
		end
		panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.Parent = labelGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = panel

		local stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = HIDE_SPOT_MARKER_PANEL_STROKE
		stroke.Transparency = 0.14
		stroke.Thickness = 1.4
		stroke.Parent = panel

		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.AnchorPoint = Vector2.new(0, 0.5)
		accent.BackgroundColor3 = HIDE_SPOT_MARKER_PANEL_STROKE
		accent.BorderSizePixel = 0
		accent.Position = UDim2.new(0, 10, 0.5, 0)
		accent.Size = UDim2.fromOffset(3, 28)
		accent.Parent = panel

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(1, 0)
		accentCorner.Parent = accent

		createMarkerTextLabel(
			"Title",
			Enum.Font.GothamBold,
			13,
			HIDE_SPOT_MARKER_TITLE_COLOR,
			record.label or "Hide Spot",
			18,
			UDim2.new(0, 20, 0, 6)
		).Parent = panel

		createMarkerTextLabel(
			"Subtitle",
			Enum.Font.GothamMedium,
			11,
			HIDE_SPOT_MARKER_SUBTITLE_COLOR,
			HIDE_SPOT_MARKER_SUBTITLE_TEXT,
			16,
			UDim2.new(0, 20, 0, 22)
		).Parent = panel
	end

	panel.BackgroundColor3 = HIDE_SPOT_MARKER_PANEL_COLOR
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromScale(1, 1)

	local title = panel:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = record.label or "Hide Spot"
	end
	local subtitle = panel:FindFirstChild("Subtitle")
	if subtitle and subtitle:IsA("TextLabel") then
		subtitle.Text = HIDE_SPOT_MARKER_SUBTITLE_TEXT
	end
	record.markerPanel = panel
end

local function cleanupHideSpotMarker(record)
	if type(record) ~= "table" then
		return
	end

	local markerFolder = record.markerFolder
	if typeof(markerFolder) == "Instance" and markerFolder.Parent ~= nil then
		markerFolder:Destroy()
	end
	record.markerFolder = nil
	record.markerOutline = nil
	record.markerBillboard = nil
	record.markerPanel = nil
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
	self._hideSpotVisualByMatchId = {}
	self._running = false
	self._runtimeThread = nil
	return self
end

function Service:Init()
	self._dependencies = {
		GhostSystem = Services.Get(self._deps, "GhostSystem"),
		InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
		MatchSystem = resolveMatchSystem(self._deps),
		MapConfigSystem = resolveMapConfigSystem(self._deps),
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
				if (type(activeMatchId) ~= "string" or activeMatchId == "") and RunService:IsStudio() then
					activeMatchId = inferStudioMatchIdFromWorkspace()
					if type(activeMatchId) == "string" and activeMatchId ~= "" then
						self._state:Set("activeMatchId", activeMatchId)
					end
				end
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
	record.part:SetAttribute("HideSpotLabel", record.label)
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

function Service:_setHideSpotVisualState(matchId, isVisible)
	local visible = isVisible == true
	self._hideSpotVisualByMatchId[matchId] = visible

	local state = self._runtimeHideSpotsByMatchId[matchId]
	if type(state) ~= "table" then
		return
	end

	for _, record in pairs(state.records or {}) do
		ensureHideSpotMarker(record)
		if record.markerOutline then
			record.markerOutline.Visible = visible
		end
		if record.markerBillboard then
			record.markerBillboard.Enabled = visible
		end
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
		cleanupHideSpotMarker(record)
		if record.part and record.part.Parent then
			record.part:SetAttribute("HideSpotId", nil)
			record.part:SetAttribute("HideSpotType", nil)
			record.part:SetAttribute("HideSpotOccupied", nil)
			record.part:SetAttribute("HideSpotLabel", nil)
		end
	end

	self._runtimeHideSpotsByMatchId[matchId] = nil
	self._hideSpotVisualByMatchId[matchId] = nil
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

	local liveMatch = getLiveMatch(self._dependencies.MatchSystem, matchId)
	local mapId = type(liveMatch) == "table" and (liveMatch.mapId or liveMatch.map) or nil
	if type(self._dependencies.MapConfigSystem) ~= "table" then
		self._dependencies.MapConfigSystem = resolveMapConfigSystem(self._deps)
	end
	local mapConfig = nil
	if type(self._dependencies.MapConfigSystem) == "table" and type(mapId) == "string" and mapId ~= "" then
		mapConfig = self._dependencies.MapConfigSystem:GetMapConfig(mapId)
	end
	local hideSpotLookup = buildHideSpotLookup(mapConfig)

	local records = {}
	for _, room in ipairs(roomsFolder:GetChildren()) do
		if room:IsA("BasePart") and (isConfiguredHideSpotRoom(room, hideSpotLookup) or isClosetRoom(room)) then
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
	self:_setHideSpotVisualState(matchId, self._hideSpotVisualByMatchId[matchId] == true)
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
	if eventName == "MatchCreated" then
		self._state:Set("activeMatchId", payload and payload.matchId)
	elseif eventName == "MatchStarted" then
		self._state:Set("activeMatchId", payload and payload.matchId)
	elseif eventName == "MatchEnded" then
		self._state:Set("activeMatchId", nil)
	elseif eventName == "PlayerTeleported" and payload and payload.matchId then
		self._state:Set("activeMatchId", payload.matchId)
	end

	if eventName == "MatchCreated" then
		self:_setOccupancy({})
		self:_ensureHideSpotsRegistered(payload and payload.matchId)
	elseif eventName == "MatchStarted" then
		self:_setOccupancy({})
		self:_registerHideSpots(payload and payload.matchId)
		self:_setHideSpotVisualState(payload and payload.matchId, false)
	elseif eventName == "PlayerTeleported" then
		self:_ensureHideSpotsRegistered(payload and payload.matchId)
	elseif eventName == "HuntStarted" then
		local matchId = payload and payload.matchId or self._state:Get("activeMatchId")
		self:_setHideSpotVisualState(matchId, true)
	elseif eventName == "HuntEnded" then
		local matchId = payload and payload.matchId or self._state:Get("activeMatchId")
		self:_setHideSpotVisualState(matchId, false)
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
		self:_setHideSpotVisualState(payload and payload.matchId, false)
		self:_cleanupHideSpots(payload and payload.matchId)
		self:_setOccupancy({})
	end
end

return Service
