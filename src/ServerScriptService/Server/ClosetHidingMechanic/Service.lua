local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Service = {}
Service.__index = Service

local HIDE_PROMPT_NAME = "HideSpotPrompt"
local HIDE_PROMPT_DISTANCE_MIN = 8
local HIDE_PROMPT_DISTANCE_MAX = 16
local HIDE_PROMPT_DISTANCE_SCALE = 0.45
local HIDE_PROMPT_HOLD_DURATION = 0
local HIDE_ROOM_VERTICAL_TOLERANCE = 6
local HIDE_PROXY_NAME_PREFIX = "HideSpotProxy_"
local HIDE_PROXY_OUTWARD_OFFSET = 4
local HIDE_PROXY_HEIGHT_OFFSET = 3.5
local HIDE_PROXY_POSITION_OVERRIDES = {
	hauntedhouse = {},
}
local HIDE_SPOT_MARKER_FOLDER_NAME = "HideSpotRuntimeMarker"
local HIDE_SPOT_MARKER_OUTLINE_NAME = "Outline"
local HIDE_SPOT_MARKER_LABEL_NAME = "Billboard"
local HIDE_SPOT_MARKER_HIGHLIGHT_NAME = "Highlight"
local HIDE_SPOT_MARKER_OUTLINE_COLOR = Color3.fromRGB(188, 232, 204)
local HIDE_SPOT_MARKER_PANEL_COLOR = Color3.fromRGB(12, 20, 16)
local HIDE_SPOT_MARKER_PANEL_STROKE = Color3.fromRGB(132, 186, 154)
local HIDE_SPOT_MARKER_TITLE_COLOR = Color3.fromRGB(244, 250, 246)
local HIDE_SPOT_MARKER_SUBTITLE_COLOR = Color3.fromRGB(184, 222, 196)
local HIDE_SPOT_MARKER_SUBTITLE_TEXT = "Bersembunyi saat hunt"
local HIDE_SPOT_MARKER_STUDS_OFFSET = 2.6
local HIDE_SPOT_WORLD_MARKERS_ENABLED = false
local HIDE_SPOT_MARKER_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldMarkers", "HideSpotMarkerBillboardTemplate" }
local HIDE_SPOT_HIGHLIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldHighlightTemplate" }
local HIDE_SPOT_OUTLINE_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldBoxOutlineTemplate" }

local function resolveChildPath(root, path)
	local node = root
	for _, segment in ipairs(path) do
		if typeof(node) ~= "Instance" then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local function cloneHideSpotMarkerTemplate()
	local template = resolveChildPath(ReplicatedStorage, HIDE_SPOT_MARKER_TEMPLATE_PATH)
	if template and template:IsA("BillboardGui") then
		local clone = template:Clone()
		clone.Name = HIDE_SPOT_MARKER_LABEL_NAME
		return clone
	end
	return nil
end

local function cloneHideSpotHighlightTemplate()
	local template = resolveChildPath(ReplicatedStorage, HIDE_SPOT_HIGHLIGHT_TEMPLATE_PATH)
	if template and template:IsA("Highlight") then
		local clone = template:Clone()
		clone.Name = HIDE_SPOT_MARKER_HIGHLIGHT_NAME
		return clone
	end
	return nil
end

local function cloneHideSpotOutlineTemplate()
	local template = resolveChildPath(ReplicatedStorage, HIDE_SPOT_OUTLINE_TEMPLATE_PATH)
	if template and template:IsA("BoxHandleAdornment") then
		local clone = template:Clone()
		clone.Name = HIDE_SPOT_MARKER_OUTLINE_NAME
		return clone
	end
	return nil
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
	raw = raw
		:gsub("(%l)(%u)", "%1 %2")
		:gsub("(%a)(%d)", "%1 %2")
		:gsub("(%d)(%a)", "%1 %2")
		:gsub("%s+", " ")
		:match("^%s*(.-)%s*$") or "Hide Spot"
	if raw == "" then
		return "Hide Spot"
	end
	return raw:gsub("^%l", string.upper)
end

local function resolvePromptDistance(part)
	if not part or not part:IsA("BasePart") then
		return HIDE_PROMPT_DISTANCE_MIN
	end
	local span = (part.Size.X + part.Size.Z) * 0.5
	local resolved = math.floor((span * HIDE_PROMPT_DISTANCE_SCALE) + 0.5)
	return math.clamp(resolved, HIDE_PROMPT_DISTANCE_MIN, HIDE_PROMPT_DISTANCE_MAX)
end

local function resolveClosetDoor(mapModel, room)
	if not (mapModel and room and room:IsA("BasePart")) then
		return nil
	end

	local suffix = tostring(room.Name):gsub("^Room_", "")
	local expected = mapModel:FindFirstChild("Door_" .. suffix, true)
	if expected and expected:IsA("BasePart") then
		return expected
	end

	return nil
end

local function ensureHideSpotPart(mapId, mapModel, room)
	if not (room and room:IsA("BasePart")) then
		return nil, nil
	end

	if not isClosetRoom(room) then
		return room, nil
	end

	local roomsFolder = room.Parent
	local door = resolveClosetDoor(mapModel, room)
	if not (roomsFolder and door) then
		return room, nil
	end

	local proxyName = HIDE_PROXY_NAME_PREFIX .. tostring(room.Name):gsub("^Room_", "")
	local proxy = roomsFolder:FindFirstChild(proxyName)
	if proxy and not proxy:IsA("BasePart") then
		proxy:Destroy()
		proxy = nil
	end
	if not proxy then
		proxy = Instance.new("Part")
		proxy.Name = proxyName
		proxy.Parent = roomsFolder
	end

	local targetPosition = nil
	local mapToken = normalizeToken(mapId)
	local override = mapToken and HIDE_PROXY_POSITION_OVERRIDES[mapToken] and HIDE_PROXY_POSITION_OVERRIDES[mapToken][room.Name] or nil
	if type(override) == "table" then
		local anchorName = type(override.roomName) == "string" and override.roomName or nil
		local anchorRoom = anchorName and mapModel and mapModel:FindFirstChild(anchorName, true)
		local offset = typeof(override.offset) == "Vector3" and override.offset or nil
		if anchorRoom and anchorRoom:IsA("BasePart") and offset then
			targetPosition = anchorRoom.Position + offset
		end
	end

	local proxySize = Vector3.new(6, 8, 8)
	if not targetPosition then
		local outward = Vector3.new(door.Position.X - room.Position.X, 0, door.Position.Z - room.Position.Z)
		if outward.Magnitude <= 1e-4 then
			return room, nil
		end
		outward = outward.Unit

		local doorSpan = math.max(door.Size.X, door.Size.Z)
		proxySize = if math.abs(outward.X) > math.abs(outward.Z)
			then Vector3.new(6, 8, math.max(6, doorSpan + 4))
			else Vector3.new(math.max(6, doorSpan + 4), 8, 6)
		targetPosition = Vector3.new(
			door.Position.X + (outward.X * HIDE_PROXY_OUTWARD_OFFSET),
			room.Position.Y + HIDE_PROXY_HEIGHT_OFFSET,
			door.Position.Z + (outward.Z * HIDE_PROXY_OUTWARD_OFFSET)
		)
	end

	proxy.Anchored = true
	proxy.CanCollide = false
	proxy.CanTouch = false
	proxy.CanQuery = true
	proxy.CastShadow = false
	proxy.Material = Enum.Material.ForceField
	proxy.Transparency = 1
	proxy.Size = proxySize
	proxy.CFrame = CFrame.new(targetPosition)
	proxy:SetAttribute("HideSpotRuntimeProxy", true)
	proxy:SetAttribute("HideSpotSourceRoom", room.Name)

	return proxy, proxy
end

local function ensureHideSpotMarker(record)
	if type(record) ~= "table" then
		return
	end

	local part = record.part
	if not part or part.Parent == nil then
		return
	end
	if HIDE_SPOT_WORLD_MARKERS_ENABLED ~= true then
		local markerFolder = record.markerFolder
		if typeof(markerFolder) ~= "Instance" then
			markerFolder = part:FindFirstChild(HIDE_SPOT_MARKER_FOLDER_NAME)
		end
		if typeof(markerFolder) == "Instance" and markerFolder.Parent ~= nil then
			markerFolder:Destroy()
		end
		record.markerFolder = nil
		record.markerOutline = nil
		record.markerHighlight = nil
		record.markerBillboard = nil
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
		outline = cloneHideSpotOutlineTemplate()
		if not outline then
			warn("[ClosetHidingMechanic] Missing authored visual template: WorldEffects.WorldBoxOutlineTemplate")
			return
		end
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

	local highlight = markerFolder:FindFirstChild(HIDE_SPOT_MARKER_HIGHLIGHT_NAME)
	if not (highlight and highlight:IsA("Highlight")) then
		if highlight then
			highlight:Destroy()
		end
		highlight = cloneHideSpotHighlightTemplate()
		if not highlight then
			warn("[ClosetHidingMechanic] Missing authored visual template: WorldEffects.WorldHighlightTemplate")
			return
		end
		highlight.Name = HIDE_SPOT_MARKER_HIGHLIGHT_NAME
		highlight.Parent = markerFolder
	end
	highlight.Adornee = part
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = HIDE_SPOT_MARKER_PANEL_STROKE
	highlight.FillTransparency = 0.88
	highlight.OutlineColor = HIDE_SPOT_MARKER_OUTLINE_COLOR
	highlight.OutlineTransparency = 0.22
	highlight.Enabled = false
	record.markerHighlight = highlight

	local labelGui = markerFolder:FindFirstChild(HIDE_SPOT_MARKER_LABEL_NAME)
	if not (labelGui and labelGui:IsA("BillboardGui")) then
		if labelGui then
			labelGui:Destroy()
		end
		labelGui = cloneHideSpotMarkerTemplate()
		if not labelGui then
			warn("[ClosetHidingMechanic] Missing authored visual template: WorldMarkers.HideSpotMarkerBillboardTemplate")
			return
		end
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
		warn("[ClosetHidingMechanic] HideSpotMarkerBillboardTemplate missing required child: Panel")
		return
	end

	panel.BackgroundColor3 = HIDE_SPOT_MARKER_PANEL_COLOR
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromScale(1, 1)

	local title = panel:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = tostring(part:GetAttribute("HideSpotLabel") or record.label or "Hide Spot")
	end
	local subtitle = panel:FindFirstChild("Subtitle")
	if subtitle and subtitle:IsA("TextLabel") then
		subtitle.Text = tostring(part:GetAttribute("HideSpotSubtitle") or HIDE_SPOT_MARKER_SUBTITLE_TEXT)
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
	local activationDistance = resolvePromptDistance(part)
	local prompt = part:FindFirstChild(HIDE_PROMPT_NAME)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.MaxActivationDistance = activationDistance
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
	prompt.MaxActivationDistance = activationDistance
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
	record.part:SetAttribute("HideSpotSubtitle", "Masuk lalu diam saat hunt")
	record.part:SetAttribute("RefugeRouteLabel", record.label)
	record.part:SetAttribute("HideSpotPromptDistance", resolvePromptDistance(record.part))
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
			record.markerOutline.Visible = HIDE_SPOT_WORLD_MARKERS_ENABLED == true and visible
		end
		if record.markerHighlight then
			record.markerHighlight.Enabled = HIDE_SPOT_WORLD_MARKERS_ENABLED == true and visible
		end
		if record.markerBillboard then
			record.markerBillboard.Enabled = HIDE_SPOT_WORLD_MARKERS_ENABLED == true and visible
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
		if record.prompt and record.prompt.Parent and record.prompt.Parent ~= record.runtimeProxy then
			record.prompt:Destroy()
		end
		cleanupHideSpotMarker(record)
		if record.runtimeProxy and record.runtimeProxy.Parent then
			record.runtimeProxy:Destroy()
		elseif record.part and record.part.Parent then
			record.part:SetAttribute("HideSpotId", nil)
			record.part:SetAttribute("HideSpotType", nil)
			record.part:SetAttribute("HideSpotOccupied", nil)
			record.part:SetAttribute("HideSpotLabel", nil)
			record.part:SetAttribute("HideSpotSubtitle", nil)
			record.part:SetAttribute("RefugeRouteLabel", nil)
			record.part:SetAttribute("HideSpotPromptDistance", nil)
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
			local hidePart, runtimeProxy = ensureHideSpotPart(mapId, mapModel, room)
			local record = {
				id = room.Name,
				label = formatClosetLabel(room),
				part = hidePart or room,
				sourceRoom = room,
				runtimeProxy = runtimeProxy,
				prompt = ensurePrompt(hidePart or room),
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
