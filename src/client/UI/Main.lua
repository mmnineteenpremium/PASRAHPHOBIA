local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local UISystem = {}
UISystem.__index = UISystem

local RoomBrowserController = require(script.Parent.RoomBrowserController)

local UI_MODULES = {
	"JournalUI",
	"LobbyUI",
	"MatchUI",
	"ProfileUI",
	"ShopUI",
	"PASRA_UI",
	"SpectatorUI",
}

local REMOTE_NAMES = { "MatchEvent", "LobbyEvent", "EvidenceEvent", "PurchaseEvent", "SanityEvent" }
local ROOM_BROWSER_TOGGLE_KEY = Enum.KeyCode.M
local MATCH_PANEL_TOGGLE_KEY = Enum.KeyCode.K
local BASIC_GUI_NAMES = { "JournalUI", "LobbyUI", "MatchUI", "ProfileUI", "ShopUI", "PASRA_UI", "SpectatorUI", "LeaderboardUI", "MainMenuUI" }
local CONFLICT_BASIC_GUI_NAMES = { "MainMenuUI", "LeaderboardUI" }
local MAPS = { "HauntedHouse", "AbandonedPalace", "EmptyBuilding", "StudioMMNineteen" }
local LOBBY_ONLY_GUI_NAMES = {
	LobbyUI = true,
	ProfileUI = true,
	ShopUI = true,
	LeaderboardUI = true,
	MainMenuUI = true,
}
local AUXILIARY_UI_NAMES = { "JournalUI", "ProfileUI", "ShopUI", "PASRA_UI", "SpectatorUI" }
local AUXILIARY_WINDOW_TOGGLE_KEYS = {
	JournalUI = Enum.KeyCode.J,
	ProfileUI = Enum.KeyCode.P,
	ShopUI = Enum.KeyCode.B,
	PASRA_UI = Enum.KeyCode.U,
	SpectatorUI = Enum.KeyCode.V,
}
local AUXILIARY_WINDOW_CONFIG = {
	JournalUI = {
		title = "JURNAL",
		badgeText = "EVIDENCE",
		floatText = "JOURNAL",
		panelPosition = UDim2.fromOffset(16, 104),
		panelAnchorPoint = Vector2.new(0, 0),
		panelSize = Vector2.new(360, 396),
		floatPosition = UDim2.new(0, 18, 0.62, 0),
		badgeColor = Color3.fromRGB(56, 92, 128),
		footer = "Shortcut: J. Basic journal ini dibuat untuk test E2E deduction.",
	},
	ProfileUI = {
		title = "PROFILE",
		badgeText = "PLAYER",
		floatText = "PROFILE",
		panelPosition = UDim2.new(1, -372, 0, 16),
		panelAnchorPoint = Vector2.new(0, 0),
		panelSize = Vector2.new(340, 300),
		floatPosition = UDim2.new(1, -18, 0.3, 0),
		badgeColor = Color3.fromRGB(74, 96, 58),
		footer = "Ringkasan profil dasar ini memakai data runtime yang tersedia di client.",
	},
	ShopUI = {
		title = "SHOP",
		badgeText = "STORE",
		floatText = "SHOP",
		panelPosition = UDim2.new(1, -16, 1, -16),
		panelAnchorPoint = Vector2.new(1, 1),
		panelSize = Vector2.new(356, 424),
		floatPosition = UDim2.new(1, -18, 0.68, 0),
		badgeColor = Color3.fromRGB(124, 92, 48),
		footer = "Item shop basic ini bisa kirim request PurchaseEvent untuk test E2E.",
	},
	PASRA_UI = {
		title = "PASRA STATUS",
		badgeText = "SUMMARY",
		floatText = "PASRA",
		panelPosition = UDim2.new(0, 16, 1, -16),
		panelAnchorPoint = Vector2.new(0, 1),
		panelSize = Vector2.new(360, 300),
		floatPosition = UDim2.new(0, 18, 0.82, 0),
		badgeColor = Color3.fromRGB(58, 100, 88),
		footer = "Panel ini merangkum hasil match, reward, dan status runtime dasar.",
	},
	SpectatorUI = {
		title = "SPECTATOR",
		badgeText = "DEATH",
		floatText = "VIEW",
		panelPosition = UDim2.fromOffset(16, 16),
		panelAnchorPoint = Vector2.new(0, 0),
		panelSize = Vector2.new(360, 320),
		floatPosition = UDim2.new(0, 18, 0.42, 0),
		badgeColor = Color3.fromRGB(120, 52, 52),
		footer = "Info spectator basic. Tutup jika mengganggu, buka lagi dari tombol float.",
	},
}
local MATCH_PHASE = {
	LOBBY = "Lobby",
	PREPARING = "Preparing",
	LOADING = "Loading",
	BRIEFING = "Briefing",
	INGAME = "InGame",
	ESCALATION = "Escalation",
	HUNT = "Hunt",
	RESULT = "Result",
	END = "End",
}

local CLOSE_KEYBOARD_KEY = Enum.KeyCode.Escape
local CLOSE_GAMEPAD_KEY = Enum.KeyCode.ButtonB
local CLOSE_HINT_TEXT = "[Esc] / [B] / [X] untuk tutup"
local JOURNAL_TOOL_TYPE = "JejakEnergi"
local RESULTS_LOCK_SECONDS = 5
local TELEPORT_OVERLAY_GUI_NAME = "TeleportScreen"
local TELEPORT_OVERLAY_FRAME_NAME = "LoadingOverlay"
local TELEPORT_OVERLAY_HOLD_SECONDS = 5
local TELEPORT_OVERLAY_FADE_SECONDS = 0.35
local LOADING_TIPS = {
	"Gunakan [J] untuk buka Journal dan cek evidence yang sudah terkumpul.",
	"Gunakan [F] untuk menyalakan flashlight saat area mulai gelap.",
	"Ghost bisa memburu kamu. Putus line-of-sight dan cari ruang aman.",
	"Perhatikan timer dan objective agar flow investigasi tetap jelas.",
}

local function safeRequire(moduleScript)
	if not moduleScript then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok then
		return result
	end
	return nil
end

local function loadMapMetadata()
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	if not shared then
		return {}
	end
	local gameDataFolder = shared:FindFirstChild("GameData")
	if not gameDataFolder then
		return {}
	end
	local mapsFolder = gameDataFolder:FindFirstChild("Maps")
	if not mapsFolder then
		return {}
	end

	local out = {}
	for _, moduleScript in ipairs(mapsFolder:GetChildren()) do
		if moduleScript:IsA("ModuleScript") then
			local value = safeRequire(moduleScript)
			if type(value) == "table" then
				out[moduleScript.Name] = value
			end
		end
	end
	return out
end

local MAP_METADATA = loadMapMetadata()

local function logRoomClickConnected(buttonName)
	return buttonName
end

local function styleButton(button, text)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 14
	button.BorderSizePixel = 0
	button.BackgroundColor3 = Color3.fromRGB(46, 57, 73)
	button.AutoButtonColor = false
end

local function styleLabel(label, text, size)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(235, 240, 245)
	label.Font = Enum.Font.Gotham
	label.TextSize = size or 14
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
end

local function createDefaultMatchResult()
	return {
		ghostType = "Unknown",
		correctGuess = false,
		evidenceCollected = 0,
		playersSurvived = 0,
		playersDead = 0,
		matchDuration = 0,
		currencyReward = 0,
		xpReward = 0,
	}
end

local function formatMatchDuration(seconds)
	local totalSeconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local minutes = math.floor(totalSeconds / 60)
	local remainingSeconds = totalSeconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function formatCountdown(seconds)
	local numeric = math.max(0, math.ceil(tonumber(seconds) or 0))
	local minutes = math.floor(numeric / 60)
	local remainingSeconds = numeric % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function formatJoinedValues(values, fallback)
	if type(values) ~= "table" then
		return fallback or "-"
	end

	local parts = {}
	for _, value in ipairs(values) do
		if type(value) == "string" and value ~= "" then
			table.insert(parts, value)
		end
	end

	if #parts == 0 then
		return fallback or "-"
	end
	return table.concat(parts, ", ")
end

local function resolveMapMetadata(mapId)
	if type(mapId) ~= "string" or mapId == "" then
		return nil
	end
	return MAP_METADATA[mapId]
end

local function getMapDisplayName(mapId)
	local metadata = resolveMapMetadata(mapId)
	if type(metadata) == "table" and type(metadata.mapName) == "string" and metadata.mapName ~= "" then
		return metadata.mapName
	end
	if type(mapId) == "string" and mapId ~= "" then
		return mapId
	end
	return "Lokasi Tidak Diketahui"
end

local function formatMapSummary(mapId)
	local metadata = resolveMapMetadata(mapId)
	local displayName = getMapDisplayName(mapId)
	if type(metadata) ~= "table" then
		return displayName
	end

	local details = {}
	if type(metadata.mapSize) == "string" and metadata.mapSize ~= "" then
		table.insert(details, metadata.mapSize)
	end
	local dimensions = metadata.mapDimensions or {}
	local width = tonumber(dimensions.width)
	local depth = tonumber(dimensions.depth)
	if width and depth then
		table.insert(details, string.format("%dx%d", width, depth))
	end
	local floors = tonumber(dimensions.floors)
	if floors then
		table.insert(details, string.format("%d lantai", floors))
	end
	if type(metadata.mapCategory) == "string" and metadata.mapCategory ~= "" then
		table.insert(details, metadata.mapCategory)
	end

	if #details == 0 then
		return displayName
	end

	return string.format("%s\n%s", displayName, table.concat(details, " | "))
end

local function resolveMapDisplayName(payload)
	if type(payload) ~= "table" then
		return "Lokasi Tidak Diketahui"
	end
	return getMapDisplayName(payload.mapName or payload.mapId or payload.selectedMap or payload.map)
end

local function buildRoomBrowserRenderKey(state)
	if type(state) ~= "table" then
		return "invalid"
	end

	local roomTokens = {}
	for _, room in ipairs(state.rooms or {}) do
		table.insert(roomTokens, string.format(
			"%s:%s:%s:%s:%s:%s",
			tostring(room.roomId or "?"),
			tostring(room.mode or "?"),
			tostring(room.mapId or "?"),
			tostring(room.playerCount or "?"),
			room.inGame == true and "1" or "0",
			room.starting == true and "1" or "0"
		))
	end

	local currentRoom = state.currentRoom
	local currentRoomId = type(currentRoom) == "table" and currentRoom.roomId or currentRoom
	return table.concat({
		tostring(state.selectedMode or "Classic"),
		tostring(state.selectedMap or "-"),
		tostring(currentRoomId or "-"),
		tostring(state.isHost == true),
		tostring(state.isReady == true),
		tostring(state.allReady == true),
		tostring(state.matchStarting == true),
		tostring(state.countdownSecondsLeft or state.countdownTotal or "-"),
		table.concat(roomTokens, "|"),
	}, "::")
end

local function decoratePhasePayload(payload)
	if type(payload) ~= "table" then
		return nil
	end
	if payload._clientReceivedAt == nil then
		payload._clientReceivedAt = tick()
	end
	return payload
end

local function resolvePhaseFromPayload(eventName, payload)
	if eventName == "MatchPreparing" then
		return MATCH_PHASE.PREPARING
	end
	if eventName == "MatchStarted" then
		return MATCH_PHASE.LOADING
	end

	local phaseToken = tostring(
		(payload and payload.phase)
			or (payload and payload.phaseName)
			or (payload and payload.lifecyclePhase)
			or ""
	)
	local normalized = phaseToken:gsub("[%s_%-]+", ""):lower()

	if normalized == "lobby" then
		return MATCH_PHASE.LOBBY
	end
	if normalized == "preparing" or normalized == "preparationphase" then
		return MATCH_PHASE.PREPARING
	end
	if normalized == "loading" then
		return MATCH_PHASE.LOADING
	end
	if normalized == "briefing" then
		return MATCH_PHASE.BRIEFING
	end
	if normalized == "ingame" or normalized == "investigationphase" then
		return MATCH_PHASE.INGAME
	end
	if normalized == "escalation" then
		return MATCH_PHASE.ESCALATION
	end
	if normalized == "hunt" or normalized == "huntphase" then
		return MATCH_PHASE.HUNT
	end
	if normalized == "result" or normalized == "endgamephase" then
		return MATCH_PHASE.RESULT
	end
	if normalized == "end" then
		return MATCH_PHASE.END
	end

	return nil
end

local function createSummaryRow(parent, rowName, labelText)
	local row = Instance.new("Frame")
	row.Name = rowName
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	row.BackgroundTransparency = 0.08
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Position = UDim2.fromOffset(10, 0)
	label.Size = UDim2.new(0.52, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(176, 190, 212)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.new(1, -10, 0, 0)
	value.Size = UDim2.new(0.45, 0, 1, 0)
	value.BackgroundTransparency = 1
	value.Text = "-"
	value.TextColor3 = Color3.fromRGB(240, 244, 248)
	value.Font = Enum.Font.GothamSemibold
	value.TextSize = 12
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = row

	return value
end

local function createActionRow(parent, rowName, defaultTitle, defaultMeta, buttonText)
	local row = Instance.new("Frame")
	row.Name = rowName
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	row.BackgroundTransparency = 0.06
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(10, 6)
	title.Size = UDim2.new(1, -112, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = defaultTitle or "ITEM"
	title.TextColor3 = Color3.fromRGB(240, 244, 248)
	title.Font = Enum.Font.GothamSemibold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = row

	local meta = Instance.new("TextLabel")
	meta.Name = "Meta"
	meta.Position = UDim2.fromOffset(10, 28)
	meta.Size = UDim2.new(1, -112, 0, 18)
	meta.BackgroundTransparency = 1
	meta.Text = defaultMeta or "-"
	meta.TextColor3 = Color3.fromRGB(176, 190, 212)
	meta.Font = Enum.Font.Gotham
	meta.TextSize = 11
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.TextWrapped = true
	meta.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "ActionButton"
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -10, 0.5, 0)
	button.Size = UDim2.fromOffset(86, 32)
	styleButton(button, buttonText or "AKSI")
	button.BackgroundColor3 = Color3.fromRGB(60, 88, 128)
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	return {
		Root = row,
		Title = title,
		Meta = meta,
		Button = button,
	}
end

local function bulletList(list, emptyText)
	if type(list) ~= "table" or #list == 0 then
		return emptyText or "- Tidak ada"
	end

	local lines = {}
	for _, item in ipairs(list) do
		table.insert(lines, "- " .. tostring(item))
	end
	return table.concat(lines, "\n")
end

local function titleCaseToken(token)
	local raw = tostring(token or "-"):gsub("_", " ")
	if raw == "" then
		return "-"
	end
	return string.upper(string.sub(raw, 1, 1)) .. string.sub(raw, 2)
end

local function loadShopCatalog()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if not shared then
		return {}
	end
	local dataTypes = shared:FindFirstChild("DataTypes")
	if not dataTypes then
		return {}
	end
	local moduleScript = dataTypes:FindFirstChild("ShopCatalog")
	if not moduleScript then
		return {}
	end
	local ok, result = pcall(require, moduleScript)
	if ok and type(result) == "table" then
		return result
	end
	return {}
end

local function findPlayerByUserId(userId)
	local target = tonumber(userId)
	if not target then
		return nil
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.UserId == target then
			return plr
		end
	end
	return nil
end

local function stripScripts(root)
	for _, child in ipairs(root:GetDescendants()) do
		if child:IsA("BaseScript") then
			child:Destroy()
		end
	end
end

local function buildPreviewCharacterModel(userId)
	local livePlayer = findPlayerByUserId(userId)
	if livePlayer and livePlayer.Character then
		local okClone, clone = pcall(function()
			return livePlayer.Character:Clone()
		end)
		if okClone and clone then
			stripScripts(clone)
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			return clone
		end
	end

	local numeric = tonumber(userId)
	if numeric then
		local okModel, model = pcall(function()
			return Players:CreateHumanoidModelFromUserId(numeric)
		end)
		if okModel and model then
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			return model
		end
	end

	return nil
end

local function renderCharacterPreview(viewportFrame, userId)
	for _, child in ipairs(viewportFrame:GetChildren()) do
		child:Destroy()
	end

	local cam = Instance.new("Camera")
	cam.Name = "PreviewCamera"
	cam.Parent = viewportFrame
	viewportFrame.CurrentCamera = cam

	local model = buildPreviewCharacterModel(userId)
	if not model then
		local fallback = Instance.new("Part")
		fallback.Anchored = true
		fallback.CanCollide = false
		fallback.Size = Vector3.new(1.8, 2.8, 1)
		fallback.Color = Color3.fromRGB(95, 95, 95)
		fallback.Parent = viewportFrame
		cam.CFrame = CFrame.new(Vector3.new(0, 1.3, 4), Vector3.new(0, 1.3, 0))
		return
	end

	model.Parent = viewportFrame
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not root then
		return
	end
	model.PrimaryPart = root
	model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
	local extents = model:GetExtentsSize()
	local focusY = math.max(extents.Y * 0.45, 1.4)
	local distance = math.max(extents.X, extents.Y, extents.Z) * 1.8
	cam.CFrame = CFrame.new(Vector3.new(0, focusY, distance), Vector3.new(0, focusY, 0))
end

local function connectButtonPress(button, callback)
	if not button or type(callback) ~= "function" then
		return
	end
	local lastPressAt = 0
	local function invoke()
		local now = os.clock()
		if (now - lastPressAt) < 0.2 then
			return
		end
		lastPressAt = now
		if button:IsA("TextButton") then
			local originalColor = button.BackgroundColor3
			local pressedColor = originalColor:Lerp(Color3.new(0, 0, 0), 0.2)
			button.BackgroundColor3 = pressedColor
			task.delay(0.12, function()
				if button and button.Parent then
					button.BackgroundColor3 = originalColor
				end
			end)
		end
		callback()
	end
	button.Activated:Connect(invoke)
end

local function makeFloatingButtonDraggable(button)
	if not button or button:GetAttribute("DragBound") == true then
		return
	end
	button:SetAttribute("DragBound", true)

	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function updateDrag(input)
		if not dragging or not dragStart or not startPos then
			return
		end
		local delta = input.Position - dragStart
		button.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = button.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)
end

local function disconnectAll(connections)
	for _, connection in ipairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(connections)
end

local function destroyAll(instances)
	for _, instance in ipairs(instances) do
		if instance and instance.Parent then
			instance:Destroy()
		end
	end
	table.clear(instances)
end

local function fadeGuiObject(guiObject, transparency, duration)
	if not guiObject then
		return
	end
	local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if guiObject:IsA("Frame") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
		TweenService:Create(guiObject, tweenInfo, { BackgroundTransparency = transparency }):Play()
	elseif guiObject:IsA("TextLabel") then
		TweenService:Create(guiObject, tweenInfo, { TextTransparency = transparency }):Play()
	elseif guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
		TweenService:Create(guiObject, tweenInfo, { ImageTransparency = transparency }):Play()
	end
end

local function resolveSafeInsets()
	local ok, insetA, insetB = pcall(function()
		return GuiService:GetSafeZoneInsets()
	end)
	if ok then
		if typeof(insetA) == "Vector2" and typeof(insetB) == "Vector2" then
			return insetA, insetB
		end
		if typeof(insetA) == "Rect" then
			return Vector2.new(insetA.Min.X, insetA.Min.Y), Vector2.new(insetA.Max.X, insetA.Max.Y)
		end
	end
	return Vector2.new(0, 0), Vector2.new(0, 0)
end

local function createDeviceProfile()
	local profile = {
		isMobile = false,
		isPC = true,
		isConsole = false,
		_inputType = "PC",
	}

	function profile:Refresh(lastInputType)
		local inputName = lastInputType and tostring(lastInputType) or ""
		local usingTouch = inputName == tostring(Enum.UserInputType.Touch)
		local usingGamepad = string.find(inputName, "Gamepad", 1, true) ~= nil
		local usingKeyboardMouse = inputName == tostring(Enum.UserInputType.MouseButton1)
			or inputName == tostring(Enum.UserInputType.MouseMovement)
			or inputName == tostring(Enum.UserInputType.Keyboard)

		self.isMobile = UserInputService.TouchEnabled and (usingTouch or (not usingGamepad and not usingKeyboardMouse))
		self.isConsole = UserInputService.GamepadEnabled and (usingGamepad or (not UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled))
		self.isPC = UserInputService.KeyboardEnabled and not self.isMobile and not self.isConsole

		if self.isMobile then
			self._inputType = "Mobile"
		elseif self.isConsole then
			self._inputType = "Console"
		else
			self._inputType = "PC"
		end
	end

	function profile:GetTextSize()
		if self._inputType == "Mobile" then
			return 22
		end
		if self._inputType == "Console" then
			return 24
		end
		return 18
	end

	function profile:GetButtonSize()
		if self._inputType == "Mobile" then
			return Vector2.new(220, 80)
		end
		if self._inputType == "Console" then
			return Vector2.new(260, 72)
		end
		return Vector2.new(180, 42)
	end

	function profile:GetInputType()
		return self._inputType
	end

	profile:Refresh(UserInputService:GetLastInputType())
	return profile
end

function UISystem:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._uxConnections = {}
	self._uxInstances = {}
	self._uiState = {}
	self._roomBrowser = RoomBrowserController.new(self._remotes and self._remotes.LobbyEvent or nil)
	self._roomBrowserController = self._roomBrowser
	self._lobbyConnection = nil
	self._roomBrowserGui = nil
	self._roomBrowserFloatGui = nil
	self._roomBrowserWidgets = nil
	self._roomBrowserLoopRunning = false
	self._roomBrowserRenderKey = nil
	self._roomBrowserVisible = false
	self._roomBrowserSuppressed = false
	self._roomBrowserInputBound = false
	self._auxiliaryInputBound = false
	self._windowCloseInputBound = false
	self._lobbyPanelCollapsed = true
	self._roomBrowserMissingWidgetsLogged = false
	self._roomBrowserModeView = "Selected"
	self._passwordJoinPendingRoomId = nil
	self._passwordJoinSubmitting = false
	self._kickNoticeVisible = false
	self._inviteDropdownOpen = false
	self._roomModeDropdownOpen = false
	self._roomMapDropdownOpen = false
	self._activeInviteId = nil
	self._uxReady = false
	self._deviceProfile = createDeviceProfile()
	self._uiStateManager = { state = "Lobby" }
	self._matchPhase = MATCH_PHASE.LOBBY
	self._phaseStartTime = 0
	self._phaseDuration = nil
	self._phasePayload = nil
	self._pendingInGamePayload = nil
	self._phaseTimerRunning = false
	self._loadingTransitionRunning = false
	self._loadingStartTime = 0
	self._hasPostTeleportLoaded = false
	self._postTeleportFlowRunning = false
	self._awaitingPostTeleportFlow = false
	self._teleportOverlayToken = 0
	self._teleportOverlayTween = nil
	self._matchWindowDismissed = false
	self._matchControlsHintText = "[J] Journal   [F] Flashlight   [K] Panel Match   [B] Shop   [Esc] Tutup UI"
	self._uxWidgets = {
		match = {},
		lobby = {},
		basicWindows = {},
		windows = {},
	}
	self._windowDismissed = {
		JournalUI = true,
		ProfileUI = true,
		ShopUI = true,
		PASRA_UI = false,
		SpectatorUI = false,
	}
	self._journalState = {
		lastEvent = "Idle",
		matchId = nil,
		discoveredEvidence = {},
		confirmedEvidence = {},
		candidates = {},
		toolType = JOURNAL_TOOL_TYPE,
		toolStatus = "Tool belum dipakai.",
		toolReason = "Buka panel Evidence lalu tekan SCAN untuk uji E2E.",
		toolSuccess = nil,
		toolLastUsedAt = 0,
	}
	self._profileState = {
		lastEvent = "Idle",
		sanity = 100,
		status = "safe",
		level = 1,
		rank = "Bayi III",
		victories = 0,
		totalGames = 0,
		favoriteTool = "-",
		featuredFlex = nil,
	}
	self._shopState = {
		lastEvent = "Idle",
		catalog = loadShopCatalog(),
		lastPurchase = nil,
		lastMessage = "Pilih item untuk test remote PurchaseEvent.",
	}
	self._spectatorState = {
		lastEvent = "Idle",
		title = "Belum spectate.",
		subtitle = "Panel ini akan aktif saat local player mati atau mode spectator berjalan.",
		mode = "none",
	}
	self._pasraState = {
		lastEvent = "Idle",
		status = "Belum ada hasil match.",
		subtitle = "Panel ini akan terisi saat match selesai.",
	}
	self._shopRequestSeq = 0

	for _, moduleName in ipairs(UI_MODULES) do
		self._uiState[moduleName] = { lastEvent = nil, visible = false }
	end
	self._uiState.LobbyUI.visible = true

	self._matchResult = createDefaultMatchResult()
end

function UISystem:Start()
	for _, remoteName in ipairs(REMOTE_NAMES) do
		if remoteName == "LobbyEvent" then
			continue
		end
		local remote = self._remotes[remoteName]
		if remote and remote.OnClientEvent then
			table.insert(self._connections, remote.OnClientEvent:Connect(function(payload)
				self:_onServerEvent(remoteName, payload)
			end))
		end
	end
	self:_connectLobbyEventRouting()

	if self._roomBrowser then
		self._roomBrowser:Start()
	end

	self:_ensureBasicUIs()
	self:_ensureRoomBrowserGui()
	self:_bindRoomBrowserMatchVisibility()
	self:_refreshRoomBrowserView()
	self:_startRoomBrowserLoop()
	self:_bindRoomBrowserToggleInput()
	self:_bindAuxiliaryToggleInput()
	self:_bindMatchPanelToggleInput()
	self:_bindWindowCloseInput()
	self:_bindPostTeleportLoading()
	self:_startPhaseTimer()
	self:_setPhase(MATCH_PHASE.LOBBY)

	local player = Players.LocalPlayer
	if player and player:GetAttribute("LobbyPanelCollapsed") ~= nil then
		self._lobbyPanelCollapsed = player:GetAttribute("LobbyPanelCollapsed") == true
	end
	self:_syncLobbyPanelVisibility()

	task.defer(function()
		local playerGui = self:_getPlayerGui()
		if not playerGui then
			return
		end

		local lobbyReady = playerGui:WaitForChild("LobbyUI", 10)
		if not lobbyReady then
			return
		end

		if self:_ensureUXLayers() then
			self:_bindInputProfileUpdates()
			self._uxReady = true
		end
	end)
end

function UISystem:_connectLobbyEventRouting()
	if not self._roomBrowserController then
		return
	end
	if self._lobbyConnection then
		return
	end

	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
	local lobbyEvent = remoteFolder:WaitForChild("LobbyEvent")
	self._lobbyConnection = lobbyEvent.OnClientEvent:Connect(function(payload)
		if not payload then
			return
		end

		self._roomBrowserController:HandleLobbyEvent(payload)
		self:_onServerEvent("LobbyEvent", payload)
	end)
end

function UISystem:_onServerEvent(remoteName, payload)
	local eventName = payload and payload.eventName or "UnknownEvent"

	if remoteName == "EvidenceEvent" then
		self._uiState.JournalUI.lastEvent = eventName
		self._uiState.JournalUI.visible = true
		self._windowDismissed.JournalUI = false
		self:_closeConflictingWindows("JournalUI")
		self._journalState.lastEvent = eventName
		self._journalState.matchId = payload and payload.matchId or self._journalState.matchId
		if eventName == "UIEvidenceUpdated" then
			self._journalState.discoveredEvidence = payload and payload.discoveredEvidence or self._journalState.discoveredEvidence
			self._journalState.confirmedEvidence = payload and payload.confirmedEvidence or self._journalState.confirmedEvidence
		elseif eventName == "JournalUpdated" then
			local journalData = payload and payload.journalData or {}
			self._journalState.discoveredEvidence = journalData.discoveredEvidence or self._journalState.discoveredEvidence
			self._journalState.confirmedEvidence = journalData.confirmedEvidence or self._journalState.confirmedEvidence
			self._journalState.candidates = journalData.ghostCandidates or self._journalState.candidates
		elseif eventName == "UIGhostPredictionUpdated" then
			self._journalState.candidates = payload and (payload.candidates or payload.possibleGhosts) or self._journalState.candidates
		end
	elseif remoteName == "LobbyEvent" then
		if eventName == "RoomBrowserRoomLeft" or eventName == "LobbyEntered" then
			if self._matchPhase ~= MATCH_PHASE.LOBBY then
				self:_forceCloseAllPanelsForTeleport()
				self:_showTeleportOverlay(TELEPORT_OVERLAY_HOLD_SECONDS)
			end
			self:_setPhase(MATCH_PHASE.LOBBY)
			self._matchResult = createDefaultMatchResult()
			self._uiState.MatchUI.visible = false
			self._uiState.JournalUI.visible = false
			self._uiState.PASRA_UI.visible = false
			self._uiState.SpectatorUI.visible = false
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel("Lobby")
		end
		self._uiState.LobbyUI.lastEvent = eventName
		self._uiState.LobbyUI.visible = true
		if eventName == "RoomBrowserRoomJoined" then
			self._passwordJoinPendingRoomId = nil
			self._passwordJoinSubmitting = false
			if self._roomBrowserWidgets and self._roomBrowserWidgets.PasswordModal then
				self._roomBrowserWidgets.PasswordModal.Visible = false
			end
		elseif eventName == "RoomBrowserRoomJoinFailed" then
			self._passwordJoinSubmitting = false
			if self._roomBrowserWidgets and self._roomBrowserWidgets.PasswordModal and self._passwordJoinPendingRoomId ~= nil then
				self._roomBrowserWidgets.PasswordModal.Visible = true
			end
			if payload and payload.reason == "room_full" and self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
				self._kickNoticeVisible = true
				self._roomBrowserWidgets.KickNoticeText.Text = "ROOM PENUH"
				self._roomBrowserWidgets.KickNoticeModal.Visible = true
			elseif payload and payload.reason == "room_in_game" and self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
				self._kickNoticeVisible = true
				self._roomBrowserWidgets.KickNoticeText.Text = "PERMAINAN SEDANG BERLANGSUNG"
				self._roomBrowserWidgets.KickNoticeModal.Visible = true
			end
		elseif eventName == "RoomBrowserRoomLeft" and payload and payload.reason == "kicked" then
			self._kickNoticeVisible = true
			if self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
				self._roomBrowserWidgets.KickNoticeText.Text = "ANDA TELAH DI KICK"
				self._roomBrowserWidgets.KickNoticeModal.Visible = true
			end
		elseif eventName == "RoomInviteReceived" then
			self:_showRoomInvitePopup(payload)
		elseif eventName == "LobbyFlexSpotlightUpdated" then
			local spotlight = payload and payload.spotlight or {}
			self._uiState.ProfileUI.lastEvent = eventName
			self._profileState.lastEvent = eventName
			self._profileState.featuredFlex = {
				displayName = spotlight.displayName or spotlight.playerName or "Player",
				rank = spotlight.rankTier or "Bayi III",
				level = tonumber(spotlight.playerLevel) or 1,
				winRate = tonumber(spotlight.winRate) or 0,
				totalMatches = tonumber(spotlight.totalMatches) or 0,
				totalWins = tonumber(spotlight.totalWins) or 0,
				showcaseSummary = spotlight.showcaseSummary or "-",
				featuredNames = spotlight.featuredNames or {},
				gallery = spotlight.flexGallery or {},
				activeVisitorCount = tonumber(payload and payload.activeVisitorCount) or 0,
			}
		elseif eventName == "LobbyFlexSpotlightCleared" then
			self._uiState.ProfileUI.lastEvent = eventName
			self._profileState.lastEvent = eventName
			self._profileState.featuredFlex = nil
		end
		self:_handleLobbyUXEvent(eventName, payload or {})
		local okRefresh, refreshErr = pcall(function()
			self:_refreshRoomBrowserView()
		end)
		if not okRefresh then
			local now = os.clock()
			if not self._lastRoomBrowserRefreshErrorAt or (now - self._lastRoomBrowserRefreshErrorAt) > 1 then
				self._lastRoomBrowserRefreshErrorAt = now
				warn("[UISystem] RoomBrowser refresh failed:", tostring(refreshErr))
			end
		end
	elseif remoteName == "MatchEvent" then
		self:_routeMatchPhaseEvent(eventName, payload or {})
		self._uiState.MatchUI.lastEvent = eventName
		local keepResultsVisible = (self._resultsCloseUnlockAt or 0) > tick() and self:_isMatchResultsPhase()
		self._uiState.MatchUI.visible = keepResultsVisible or (eventName ~= "ReturnedToLobby" and eventName ~= "RoomBrowserRoomLeft")
		self:_handleMatchUXEvent(eventName, payload or {})
		if eventName == "PlayerKilled" and payload and payload.localPlayerKilled == true then
			self._uiState.SpectatorUI.lastEvent = eventName
			self._uiState.SpectatorUI.visible = true
			self._spectatorState.lastEvent = eventName
			self._spectatorState.mode = "dead"
			self._spectatorState.title = "PLAYER DEAD - SPECTATOR"
			self._spectatorState.subtitle = "Kematian menipumu, yang kamu lihat belum tentu benar."
			self._windowDismissed.SpectatorUI = false
			self:_closeConflictingWindows("SpectatorUI")
		elseif eventName == "PlayerKilled" then
			self._spectatorState.lastEvent = eventName
			self._spectatorState.mode = "warning"
			self._spectatorState.title = "TEAMMATE DOWN"
			self._spectatorState.subtitle = "Jangan terlalu percaya orang mati. Gunakan instingmu."
			self._uiState.SpectatorUI.visible = true
			self._windowDismissed.SpectatorUI = false
			self:_closeConflictingWindows("SpectatorUI")
			task.delay(5, function()
				if self._spectatorState.mode == "warning" then
					self._uiState.SpectatorUI.visible = false
					self:_applyVisibility()
				end
			end)
		elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
			if payload and type(payload) == "table" then
				self._matchResult = {
					ghostType = payload.ghostType or "Unknown",
					correctGuess = payload.correctGuess == true,
					evidenceCollected = payload.evidenceCollected or 0,
					playersSurvived = payload.playersSurvived or 0,
					playersDead = payload.playersDead or 0,
					matchDuration = payload.matchDuration or 0,
					currencyReward = payload.currencyReward or 0,
					xpReward = payload.xpReward or 0,
				}
			end
			self._profileState.totalGames = (tonumber(self._profileState.totalGames) or 0) + 1
			self._roomBrowserSuppressed = false
			self:_setRoomBrowserVisible(false)
			self._uiState.PASRA_UI.lastEvent = eventName
			self._uiState.PASRA_UI.visible = true
			self._uiState.SpectatorUI.visible = false
			self._uiState.MatchUI.visible = true
			self._pasraState.lastEvent = eventName
			self._pasraState.status = payload and payload.missionFailed == true and "Misi berakhir dengan gagal." or "Misi selesai. Hasil dan reward siap dibaca."
			self._pasraState.subtitle = "Panel PASRA tetap tersedia, tetapi hasil utama sekarang diprioritaskan di MATCH agar tidak overlap."
			self._windowDismissed.PASRA_UI = true
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel("Results", payload)
			self:_renderResultsPanel(payload)
		elseif eventName == "MatchRewardSummary" then
			if payload and type(payload) == "table" then
				self._matchResult.currencyReward = payload.currencyReward or self._matchResult.currencyReward
				self._matchResult.xpReward = payload.xpReward or self._matchResult.xpReward
			end
			self._uiState.PASRA_UI.lastEvent = eventName
			self._uiState.PASRA_UI.visible = true
			self._uiState.SpectatorUI.visible = false
			self._uiState.MatchUI.visible = true
			self._pasraState.lastEvent = eventName
			self._pasraState.status = "Reward summary diterima dari server."
			self._pasraState.subtitle = string.format(
				"MM %s | XP %s",
				tostring(math.floor(tonumber(self._matchResult.currencyReward or 0) or 0)),
				tostring(math.floor(tonumber(self._matchResult.xpReward or 0) or 0))
			)
			self._windowDismissed.PASRA_UI = true
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel("Results", payload)
			self:_renderResultsPanel(payload)
		elseif eventName == "MatchStarted" then
			self._matchResult = createDefaultMatchResult()
			self._roomBrowserSuppressed = true
			self:_setRoomBrowserVisible(false)
			self._uiState.PASRA_UI.visible = false
			self._uiState.MatchUI.visible = true
			self._uiState.SpectatorUI.visible = false
			self._uiState.JournalUI.visible = true
			self._uiState.ProfileUI.visible = false
			self._uiState.ShopUI.visible = false
			self._windowDismissed.JournalUI = true
			self._windowDismissed.ProfileUI = true
			self._windowDismissed.ShopUI = true
			self._journalState.lastEvent = eventName
			self._journalState.discoveredEvidence = {}
			self._journalState.confirmedEvidence = {}
			self._journalState.candidates = {}
			self._pasraState.lastEvent = eventName
			self._pasraState.status = "Match aktif."
			self._pasraState.subtitle = "Menunggu hasil akhir dan reward."
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel("Preparation", payload)
		elseif eventName == "ReturnedToLobby" or eventName == "RoomBrowserRoomLeft" then
			local keepResultsVisible = (self._resultsCloseUnlockAt or 0) > tick() and self:_isMatchResultsPhase()
			self._uiState.MatchUI.visible = keepResultsVisible
			self._uiState.JournalUI.visible = false
			self._uiState.PASRA_UI.visible = false
			self._uiState.SpectatorUI.visible = false
			self._spectatorState.mode = "none"
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel(keepResultsVisible and "Results" or "Lobby", payload)
		end
	elseif remoteName == "PurchaseEvent" then
		self._uiState.ShopUI.lastEvent = eventName
		self._uiState.ShopUI.visible = true
		self:_closeConflictingWindows("ShopUI")
		self._shopState.lastEvent = eventName
		if eventName == "PurchaseProcessed" then
			self._shopState.lastPurchase = {
				itemId = payload and payload.itemId or "-",
				success = payload and payload.success == true,
				reason = payload and payload.reason or nil,
				requestId = payload and payload.requestId or nil,
			}
			self._shopState.lastMessage = payload and payload.success == true
				and "Pembelian berhasil diproses."
				or ("Pembelian gagal: " .. titleCaseToken(payload and payload.reason or "unknown"))
		end
		self._windowDismissed.ShopUI = false
	elseif remoteName == "SanityEvent" then
		self._uiState.ProfileUI.lastEvent = eventName
		self._profileState.lastEvent = eventName
		self._profileState.sanity = tonumber((payload and payload.newSanity) or (payload and payload.sanity) or payload) or self._profileState.sanity
		if self._profileState.sanity <= 10 then
			self._profileState.status = "hunt_risk"
		elseif self._profileState.sanity <= 30 then
			self._profileState.status = "high_paranormal_activity"
		elseif self._profileState.sanity <= 50 then
			self._profileState.status = "unstable"
		else
			self._profileState.status = "safe"
		end
	end

	self:_applyVisibility()
end

function UISystem:_getPlayerGui()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
end

function UISystem:_applyVisibility()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end
	for _, guiName in ipairs(BASIC_GUI_NAMES) do
		local gui = playerGui:FindFirstChild(guiName)
		local state = self._uiState[guiName]
		if gui and state then
			local shouldEnable = state.visible == true
			if LOBBY_ONLY_GUI_NAMES[guiName] == true then
				shouldEnable = shouldEnable and self._matchPhase == MATCH_PHASE.LOBBY
			end
			gui.Enabled = shouldEnable
		end
	end
	self:_syncMatchWindowVisibility()
	self:_syncAuxiliaryWindowVisibility()
	self:_syncLobbyAuxiliaryWindowVisibility()
	self:_syncLobbyPanelVisibility()
	self:_refreshAuxiliaryPanels()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
end

function UISystem:SetState(state)
	self._uiStateManager.state = state
end

function UISystem:GetState()
	return self._uiStateManager.state
end

function UISystem:GetTextSize()
	return self._deviceProfile:GetTextSize()
end

function UISystem:GetButtonSize()
	return self._deviceProfile:GetButtonSize()
end

function UISystem:GetInputType()
	return self._deviceProfile:GetInputType()
end

function UISystem:_getBasicWindowState(guiName)
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil, nil, nil
	end

	local gui = playerGui:FindFirstChild(guiName)
	if not gui or not gui:IsA("ScreenGui") then
		return nil, nil, nil
	end

	local panel = gui:FindFirstChild("MainPanel")
	local floatButtonName = nil
	if guiName == "LeaderboardUI" then
		floatButtonName = "LeaderboardFloatButton"
	elseif guiName == "MainMenuUI" then
		floatButtonName = "MainMenuFloatButton"
	end

	local floatButton = floatButtonName and gui:FindFirstChild(floatButtonName) or nil
	return gui, panel, floatButton
end

function UISystem:_setBasicWindowPanelVisible(guiName, visible)
	local gui, panel, floatButton = self:_getBasicWindowState(guiName)
	if not gui then
		return false
	end

	local shouldShow = visible == true
	if panel and panel:IsA("GuiObject") then
		panel.Visible = shouldShow
	end
	if floatButton and floatButton:IsA("GuiObject") then
		floatButton.Visible = self._matchPhase == MATCH_PHASE.LOBBY and not shouldShow
	end
	return true
end

function UISystem:_closeConflictingWindows(activeWindowName)
	local activeName = tostring(activeWindowName or "")

	if activeName ~= "RoomBrowser" then
		self._roomBrowserVisible = false
	end

	if activeName ~= "MatchUI" then
		self._matchWindowDismissed = true
	end

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		if guiName ~= activeName then
			self._windowDismissed[guiName] = true
		end
	end

	for _, guiName in ipairs(CONFLICT_BASIC_GUI_NAMES) do
		if guiName ~= activeName then
			self:_setBasicWindowPanelVisible(guiName, false)
		end
	end

	self:_updateRoomBrowserVisibility()
end

function UISystem:_closeTopmostWindow()
	if self._roomBrowserVisible == true then
		self:_setRoomBrowserVisible(false)
		return true
	end

	if self._uiState.MatchUI and self._uiState.MatchUI.visible == true and self._matchWindowDismissed ~= true then
		self:_setMatchWindowDismissed(true)
		return true
	end

	for _, guiName in ipairs(CONFLICT_BASIC_GUI_NAMES) do
		local _, panel = self:_getBasicWindowState(guiName)
		if panel and panel.Visible == true then
			self:_setBasicWindowVisible(guiName, false)
			return true
		end
	end

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		local widgets = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows[guiName]
		if widgets and widgets.Panel and widgets.Panel.Visible == true then
			self:_setAuxiliaryWindowDismissed(guiName, true)
			self:_applyVisibility()
			return true
		end
	end

	return false
end

function UISystem:_isMatchPanelOpen()
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if match and match.BasicPanel and match.BasicPanel.Visible == true then
		return true
	end

	return self._uiState.MatchUI and self._uiState.MatchUI.visible == true and self._matchWindowDismissed ~= true
end

function UISystem:_forceCloseAllPanelsForTeleport()
	self._roomBrowserVisible = false

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		if self._uiState[guiName] then
			self._uiState[guiName].visible = false
		end
		self._windowDismissed[guiName] = true
	end

	self._matchWindowDismissed = true

	for _, guiName in ipairs(CONFLICT_BASIC_GUI_NAMES) do
		self:_setBasicWindowPanelVisible(guiName, false)
	end

	self:_updateRoomBrowserVisibility()
	self:_syncMatchWindowVisibility()
	self:_syncAuxiliaryWindowVisibility()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
end

function UISystem:_setBasicWindowVisible(guiName, visible)
	local shouldShow = visible == true
	if shouldShow then
		self:_closeConflictingWindows(guiName)
	end

	if not self:_setBasicWindowPanelVisible(guiName, shouldShow) then
		return
	end
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
	self:_syncAuxiliaryWindowVisibility()
	self:_syncMatchWindowVisibility()
	self:_updateRoomBrowserVisibility()
end

function UISystem:_toggleBasicWindow(guiName)
	local _, panel = self:_getBasicWindowState(guiName)
	if not panel or not panel:IsA("GuiObject") then
		return
	end
	self:_setBasicWindowVisible(guiName, not panel.Visible)
end

function UISystem:_syncAuxiliaryWindowVisibility()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		local widgets = self._uxWidgets
			and self._uxWidgets.windows
			and self._uxWidgets.windows[guiName]
		local gui = playerGui:FindFirstChild(guiName)
		if widgets and gui and gui:IsA("ScreenGui") then
			local screenEnabled = gui.Enabled == true
			local dismissed = self._windowDismissed[guiName] == true
			if widgets.Panel then
				widgets.Panel.Visible = screenEnabled and not dismissed
			end
			if widgets.FloatButton then
				widgets.FloatButton.Visible = screenEnabled and dismissed
			end
		end
	end
end

function UISystem:_setAuxiliaryWindowDismissed(guiName, dismissed)
	self._windowDismissed[guiName] = dismissed == true
	self:_syncAuxiliaryWindowVisibility()
end

function UISystem:_openAuxiliaryWindow(guiName)
	if not self._uiState[guiName] then
		return
	end
	if LOBBY_ONLY_GUI_NAMES[guiName] == true and guiName ~= "ShopUI" and self._matchPhase ~= MATCH_PHASE.LOBBY then
		return
	end
	self:_closeConflictingWindows(guiName)
	self._uiState[guiName].visible = true
	self:_setAuxiliaryWindowDismissed(guiName, false)
	self:_applyVisibility()
end

function UISystem:_toggleAuxiliaryWindow(guiName)
	if not self._uiState[guiName] then
		return
	end
	if self._uiState[guiName].visible ~= true then
		self:_openAuxiliaryWindow(guiName)
		return
	end
	self:_setAuxiliaryWindowDismissed(guiName, not (self._windowDismissed[guiName] == true))
	self:_applyVisibility()
end

function UISystem:_syncLobbyAuxiliaryWindowVisibility()
	local lobbyVisible = self._matchPhase == MATCH_PHASE.LOBBY
		and self._uiState.LobbyUI
		and self._uiState.LobbyUI.visible == true

	for _, guiName in ipairs({ "MainMenuUI", "LeaderboardUI" }) do
		local gui, panel, floatButton = self:_getBasicWindowState(guiName)
		if gui then
			gui.Enabled = lobbyVisible
			if not lobbyVisible then
				if panel and panel:IsA("GuiObject") then
					panel.Visible = false
				end
				if floatButton and floatButton:IsA("GuiObject") then
					floatButton.Visible = false
				end
			elseif floatButton and floatButton:IsA("GuiObject") then
				floatButton.Visible = not (panel and panel.Visible == true)
			end
		end
	end
end

function UISystem:_syncLobbyPanelVisibility()
	local lobby = self._uxWidgets and self._uxWidgets.lobby or nil
	if not lobby then
		return
	end

	local collapsed = self._lobbyPanelCollapsed == true
	if lobby.BasicPanel then
		lobby.BasicPanel.Visible = not collapsed
	end
	if lobby.ToggleButton then
		lobby.ToggleButton.Text = collapsed and ">" or "<"
	end
end

function UISystem:_setLobbyPanelCollapsed(collapsed)
	self._lobbyPanelCollapsed = collapsed == true
	local player = Players.LocalPlayer
	if player then
		player:SetAttribute("LobbyPanelCollapsed", self._lobbyPanelCollapsed)
	end
	self:_syncLobbyPanelVisibility()
	self:_refreshBasicLobbyPanel()
end

function UISystem:_toggleLobbyPanelCollapsed()
	self:_setLobbyPanelCollapsed(not (self._lobbyPanelCollapsed == true))
end

function UISystem:_getEvidenceToolsService()
	local registry = self._context and self._context.Registry or nil
	if not registry or type(registry.Get) ~= "function" then
		return nil
	end
	return registry:Get("EvidenceTools")
end

function UISystem:_triggerJournalToolScan()
	local tools = self:_getEvidenceToolsService()
	local state = self._journalState or {}
	state.toolType = JOURNAL_TOOL_TYPE
	state.toolLastUsedAt = os.clock()

	if not tools or type(tools.UseTool) ~= "function" then
		state.toolStatus = "Tool client tidak siap."
		state.toolReason = "EvidenceTools belum terdaftar di registry client."
		state.toolSuccess = false
		self._journalState = state
		self:_refreshJournalPanel()
		return
	end

	local okCall, success, reason, response = pcall(function()
		return tools:UseTool(JOURNAL_TOOL_TYPE)
	end)
	if not okCall then
		state.toolStatus = "Scan gagal."
		state.toolReason = tostring(success)
		state.toolSuccess = false
	else
		state.toolSuccess = success == true
		state.toolStatus = success == true and "Scan berhasil dikirim." or "Scan ditolak."
		state.toolReason = titleCaseToken(reason or (response and response.reason) or "unknown")
	end

	self._journalState = state
	self._uiState.JournalUI.visible = true
	self._windowDismissed.JournalUI = false
	self:_closeConflictingWindows("JournalUI")
	self:_applyVisibility()
end

function UISystem:_refreshBasicWindows()
	self:_refreshMainMenuPanel()
	self:_refreshLeaderboardPanel()
end

function UISystem:_isMatchResultsPhase()
	return self._matchPhase == MATCH_PHASE.RESULT or self._matchPhase == MATCH_PHASE.END
end

function UISystem:_syncMatchWindowVisibility()
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if not match then
		return
	end

	local screenEnabled = (match.BasicGui and match.BasicGui.Enabled == true)
		or (self._uiState.MatchUI and self._uiState.MatchUI.visible == true)
	local showWindow = screenEnabled and not self._matchWindowDismissed
	local showResults = showWindow and self:_isMatchResultsPhase()

	if match.BasicPanel then
		match.BasicPanel.Visible = showWindow
	end
	if match.BasicFloatButton then
		match.BasicFloatButton.Visible = screenEnabled and self._matchWindowDismissed
	end
	if match.ResultsPanel then
		match.ResultsPanel.Visible = showResults
	end
	if self:_isMatchResultsPhase() and match.Gui then
		match.Gui.Enabled = screenEnabled
	end
	if self:_isMatchResultsPhase() and match.Layer then
		match.Layer.Visible = showResults
	end
end

function UISystem:_setMatchWindowDismissed(dismissed)
	if dismissed ~= true then
		self:_closeConflictingWindows("MatchUI")
	end
	self._matchWindowDismissed = dismissed == true
	self:_syncMatchWindowVisibility()
	self:_syncAuxiliaryWindowVisibility()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
	self:_updateRoomBrowserVisibility()
end

function UISystem:_setSummaryValue(label, value)
	if not label then
		return
	end
	label.Text = tostring(value or "-")
end

function UISystem:_updateMatchSummaryRows(rowWidgets)
	if type(rowWidgets) ~= "table" then
		return
	end

	local result = self._matchResult or createDefaultMatchResult()
	local hasResults = result.ghostType ~= "Unknown"
		or tonumber(result.matchDuration or 0) > 0
		or tonumber(result.evidenceCollected or 0) > 0
		or tonumber(result.playersSurvived or 0) > 0
		or tonumber(result.playersDead or 0) > 0

	self:_setSummaryValue(rowWidgets.status, hasResults and (result.correctGuess and "BERHASIL" or "GAGAL") or "-")
	self:_setSummaryValue(rowWidgets.ghostType, hasResults and tostring(result.ghostType or "Unknown") or "-")
	self:_setSummaryValue(rowWidgets.correctGuess, hasResults and (result.correctGuess and "BENAR" or "SALAH") or "-")
	self:_setSummaryValue(rowWidgets.evidenceCollected, hasResults and tostring(tonumber(result.evidenceCollected or 0) or 0) or "-")
	self:_setSummaryValue(rowWidgets.playersSurvived, hasResults and tostring(tonumber(result.playersSurvived or 0) or 0) or "-")
	self:_setSummaryValue(rowWidgets.playersDead, hasResults and tostring(tonumber(result.playersDead or 0) or 0) or "-")
	self:_setSummaryValue(rowWidgets.matchDuration, hasResults and formatMatchDuration(result.matchDuration) or "-")
	self:_setSummaryValue(rowWidgets.currencyReward, hasResults and tostring(math.floor(tonumber(result.currencyReward or 0) or 0)) or "-")
	self:_setSummaryValue(rowWidgets.xpReward, hasResults and tostring(math.floor(tonumber(result.xpReward or 0) or 0)) or "-")
end

function UISystem:_refreshBasicMatchPanel(viewState, payload)
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if not match or not match.BasicPanel then
		return
	end

	viewState = viewState or (
		self._matchPhase == MATCH_PHASE.PREPARING and "Preparation"
		or self._matchPhase == MATCH_PHASE.LOADING and "Loading"
		or self._matchPhase == MATCH_PHASE.BRIEFING and "Preparation"
		or self._matchPhase == MATCH_PHASE.INGAME and "Investigation"
		or self._matchPhase == MATCH_PHASE.ESCALATION and "Investigation"
		or self._matchPhase == MATCH_PHASE.HUNT and "Hunt"
		or self:_isMatchResultsPhase() and "Results"
		or "Lobby"
	)
	payload = payload or self._phasePayload

	local badgeText = "STATUS MATCH"
	local badgeColor = Color3.fromRGB(62, 80, 104)
	local primaryText = "Menunggu event match."
	local secondaryText = "Panel ini bisa ditutup jika menghalangi pandangan."
	local footerText = CLOSE_HINT_TEXT .. ". Tombol MATCH akan muncul di tepi layar."
	local timerVisible = false
	local timerText = "00:00"
	if self._phaseDuration then
		local remaining = math.max(0, self._phaseDuration - (tick() - (self._phaseStartTime or tick())))
		timerVisible = true
		timerText = formatCountdown(remaining)
	end

	if viewState == "Preparation" or viewState == "Loading" then
		badgeText = "PERSIAPAN"
		badgeColor = Color3.fromRGB(70, 96, 132)
		primaryText = "Masuk ke lokasi..."
		secondaryText = timerVisible
			and ("Loading dan briefing aktif. Waktu fase: " .. timerText .. ".")
			or "Tunggu loading selesai, lalu mulai cari evidence."
	elseif viewState == "Investigation" then
		badgeText = "INVESTIGASI"
		badgeColor = Color3.fromRGB(58, 112, 90)
		primaryText = "Investigasi aktif."
		secondaryText = timerVisible
			and ("Sisa waktu investigasi: " .. timerText .. ". Cari evidence, cek jurnal, dan tentukan ghost.")
			or "Cari evidence, cek jurnal, dan tentukan ghost yang benar."
		footerText = CLOSE_HINT_TEXT .. ". Gunakan tombol EVIDENCE [J] untuk scan tool dan buka jurnal."
	elseif viewState == "Hunt" then
		badgeText = "HUNT"
		badgeColor = Color3.fromRGB(132, 56, 56)
		primaryText = "Ghost sedang memburu."
		secondaryText = timerVisible
			and ("Sisa waktu hunt: " .. timerText .. ". Utamakan bertahan hidup.")
			or "Utamakan bertahan hidup. Panel ini bisa ditutup agar pandangan lebih lega."
	elseif viewState == "Results" then
		local missionFailed = payload and (
			payload.success == false
			or payload.failed == true
			or payload.missionFailed == true
			or payload.correctGuess == false
		)
		if missionFailed == nil then
			local result = self._matchResult or createDefaultMatchResult()
			missionFailed = result.ghostType ~= "Unknown" and result.correctGuess ~= true
		end
		badgeText = missionFailed and "MISI GAGAL" or "MISI SELESAI"
		badgeColor = missionFailed and Color3.fromRGB(132, 56, 56) or Color3.fromRGB(56, 118, 82)
		primaryText = "Hasil investigasi sudah tersedia."
		secondaryText = "Ringkasan lengkap ada di bawah. Hadiah akan terisi saat server mengirim reward final."
		footerText = "Hasil akan tetap terlihat sampai kembali ke lobby. Anda tetap bisa menutup panel jika perlu."
	elseif viewState == "Lobby" then
		badgeText = "LOBBY"
		badgeColor = Color3.fromRGB(62, 80, 104)
		primaryText = "Belum ada match aktif."
		secondaryText = "Panel akan terisi otomatis saat match dimulai."
	end

	if match.BasicTitle then
		match.BasicTitle.Text = "PANEL MATCH"
	end
	if match.BasicStateBadge then
		match.BasicStateBadge.Text = badgeText
		match.BasicStateBadge.BackgroundColor3 = badgeColor
	end
	if match.BasicPrimaryLabel then
		match.BasicPrimaryLabel.Text = primaryText
	end
	if match.BasicSecondaryLabel then
		match.BasicSecondaryLabel.Text = secondaryText
	end
	if match.BasicFooterLabel then
		match.BasicFooterLabel.Text = footerText
	end
	if match.TimerLabel then
		match.TimerLabel.Visible = timerVisible and viewState ~= "Lobby" and not self:_isMatchResultsPhase()
		match.TimerLabel.Text = timerVisible and timerText or ""
	end
	if match.TimerCaption then
		match.TimerCaption.Visible = match.TimerLabel and match.TimerLabel.Visible
		match.TimerCaption.Text = viewState == "Hunt" and "HUNT TIMER" or "PHASE TIMER"
	end
	if match.EvidenceQuickButton then
		match.EvidenceQuickButton.Visible = self._matchPhase ~= MATCH_PHASE.LOBBY and not self:_isMatchResultsPhase()
		match.EvidenceQuickButton.Text = self._windowDismissed.JournalUI == true and "EVIDENCE [J]" or "TUTUP EVIDENCE [J]"
	end
	if match.ControlsHintBar then
		match.ControlsHintBar.Visible = self._matchPhase ~= MATCH_PHASE.LOBBY and not self:_isMatchResultsPhase()
	end
	if match.ControlsHintLabel then
		match.ControlsHintLabel.Visible = self._matchPhase ~= MATCH_PHASE.LOBBY and not self:_isMatchResultsPhase()
		match.ControlsHintLabel.Text = self._matchControlsHintText
	end
	self:_updateMatchSummaryRows(match.BasicSummaryRows)
	self:_syncMatchWindowVisibility()
end

function UISystem:_renderResultsPanel(payload)
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if not match or not match.ResultsPanel then
		return
	end

	local missionFailed = payload and (
		payload.success == false
		or payload.failed == true
		or payload.missionFailed == true
		or payload.correctGuess == false
	)
	if missionFailed == nil then
		local result = self._matchResult or createDefaultMatchResult()
		missionFailed = result.ghostType ~= "Unknown" and result.correctGuess ~= true
	end

	if match.ResultsStatus then
		match.ResultsStatus.Text = missionFailed and "MISSION FAILED" or "MISSION COMPLETE"
		match.ResultsStatus.BackgroundColor3 = missionFailed and Color3.fromRGB(120, 48, 48) or Color3.fromRGB(50, 104, 72)
	end
	if match.ResultsSubtitle then
		match.ResultsSubtitle.Text = "Ghost: " .. tostring((self._matchResult and self._matchResult.ghostType) or "Unknown")
	end
	local remainingLock = math.max(0, math.ceil((self._resultsCloseUnlockAt or 0) - tick()))
	local closeUnlocked = remainingLock <= 0
	if match.ResultsCloseButton then
		match.ResultsCloseButton.Visible = closeUnlocked
		match.ResultsCloseButton.Active = closeUnlocked
		match.ResultsCloseButton.Selectable = closeUnlocked
		match.ResultsCloseButton.AutoButtonColor = closeUnlocked
	end
	if match.ResultsLockHint then
		match.ResultsLockHint.Visible = not closeUnlocked
		match.ResultsLockHint.Text = closeUnlocked
			and ""
			or string.format("Lanjut tersedia dalam %ds", remainingLock)
	end
	if match.ResultsFooter then
		match.ResultsFooter.Text = closeUnlocked
			and "Tekan tombol lanjut untuk kembali ke lobby flow. Ringkasan ini dipertahankan untuk E2E."
			or "Hasil match fullscreen dikunci 5 detik agar semua pemain sempat membaca hasil."
	end
	self:_updateMatchSummaryRows(match.ResultsSummaryRows)
	self:_syncMatchWindowVisibility()
end

function UISystem:_startResultsCloseLock(payload)
	self._resultsCloseUnlockAt = tick() + RESULTS_LOCK_SECONDS
	local unlockAt = self._resultsCloseUnlockAt
	task.spawn(function()
		while self._resultsCloseUnlockAt == unlockAt and tick() < unlockAt do
			self:_renderResultsPanel(payload)
			task.wait(0.1)
		end
		if self._resultsCloseUnlockAt == unlockAt then
			self:_renderResultsPanel(payload)
		end
	end)
end

function UISystem:_refreshBasicLobbyPanel()
	local lobby = self._uxWidgets and self._uxWidgets.lobby or nil
	if not lobby or not lobby.BasicPanel then
		return
	end

	local state = self:GetRoomBrowserState() or {}
	local rooms = type(state.rooms) == "table" and state.rooms or {}
	local currentRoom = type(state.currentRoom) == "table" and state.currentRoom or nil
	local badgeText = "LOBBY"
	local badgeColor = Color3.fromRGB(54, 116, 82)
	local primaryText = "Buka Room Browser, Profile, Shop, Menu, atau Rank untuk lanjut test E2E."
	local selectedMode = tostring(state.selectedMode or "Classic")
	local selectedMap = tostring(state.selectedMap or MAPS[1] or "HauntedHouse")
	local secondaryText = string.format("Mode %s | Map %s | %d room aktif", selectedMode, selectedMap, #rooms)
	local hintText = "Shortcut: tekan M untuk buka atau tutup Room Browser."

	if currentRoom and currentRoom.roomId then
		local playerCount = type(currentRoom.players) == "table" and #currentRoom.players or 0
		local roomMode = tostring(currentRoom.mode or selectedMode)
		local roomMap = tostring(currentRoom.mapId or selectedMap)
		badgeText = state.matchStarting == true and "COUNTDOWN" or "DALAM ROOM"
		badgeColor = state.matchStarting == true and Color3.fromRGB(126, 84, 48) or Color3.fromRGB(62, 96, 132)
		primaryText = string.format("Room #%s siap. Lanjutkan kontrol host atau ready dari Room Browser.", tostring(currentRoom.roomId))
		secondaryText = string.format("%s | %s | %d pemain", roomMode, roomMap, playerCount)
		if state.matchStarting == true then
			local countdown = state.countdownSecondsLeft or state.countdownTotal
			hintText = countdown and ("Countdown aktif: " .. formatCountdown(countdown)) or "Countdown aktif..."
		end
	elseif state.lastError then
		badgeText = "PERLU CEK"
		badgeColor = Color3.fromRGB(118, 74, 48)
		hintText = "Status terakhir: " .. tostring(state.lastError)
	end

	if lobby.BasicTitle then
		lobby.BasicTitle.Text = "LOBBY PANEL"
	end
	if lobby.BasicStatusBadge then
		lobby.BasicStatusBadge.Text = badgeText
		lobby.BasicStatusBadge.BackgroundColor3 = badgeColor
	end
	if lobby.BasicPrimaryLabel then
		lobby.BasicPrimaryLabel.Text = primaryText
	end
	if lobby.BasicSecondaryLabel then
		lobby.BasicSecondaryLabel.Text = secondaryText
	end
	if lobby.BasicHintLabel then
		lobby.BasicHintLabel.Text = hintText
	end
	if lobby.BasicOpenRoomBrowserButton then
		lobby.BasicOpenRoomBrowserButton.Text = self._roomBrowserVisible and "TUTUP ROOM BROWSER" or "OPEN ROOM BROWSER"
		lobby.BasicOpenRoomBrowserButton.BackgroundColor3 = self._roomBrowserVisible
			and Color3.fromRGB(66, 104, 144)
			or Color3.fromRGB(46, 78, 114)
	end
	if lobby.BasicProfileButton then
		local profileOpen = self._uiState.ProfileUI and self._uiState.ProfileUI.visible == true and self._windowDismissed.ProfileUI ~= true
		lobby.BasicProfileButton.Text = profileOpen and "TUTUP PROFILE" or "PROFILE"
	end
	if lobby.BasicShopButton then
		local shopOpen = self._uiState.ShopUI and self._uiState.ShopUI.visible == true and self._windowDismissed.ShopUI ~= true
		lobby.BasicShopButton.Text = shopOpen and "TUTUP SHOP" or "SHOP"
	end
	if lobby.BasicMenuButton then
		local _, menuPanel = self:_getBasicWindowState("MainMenuUI")
		local menuOpen = menuPanel and menuPanel.Visible == true
		lobby.BasicMenuButton.Text = menuOpen and "TUTUP MENU" or "MENU"
	end
	if lobby.BasicRankButton then
		local _, rankPanel = self:_getBasicWindowState("LeaderboardUI")
		local rankOpen = rankPanel and rankPanel.Visible == true
		lobby.BasicRankButton.Text = rankOpen and "TUTUP RANK" or "RANK"
	end
end

function UISystem:_refreshMainMenuPanel()
	local window = self._uxWidgets and self._uxWidgets.basicWindows and self._uxWidgets.basicWindows.MainMenuUI
	if not window then
		return
	end

	local state = self:GetRoomBrowserState() or {}
	local rooms = type(state.rooms) == "table" and state.rooms or {}
	local currentRoom = type(state.currentRoom) == "table" and state.currentRoom or nil
	local selectedMode = tostring(state.selectedMode or "Classic")
	local selectedMap = tostring(state.selectedMap or MAPS[1] or "HauntedHouse")
	local statusText = "QUICK ACCESS"
	local badgeColor = Color3.fromRGB(60, 92, 132)
	local primaryText = "Panel navigasi cepat untuk test lobby flow tanpa mengandalkan hotkey."
	local secondaryText = string.format("Mode %s | Map %s | %d room aktif", selectedMode, selectedMap, #rooms)

	if currentRoom and currentRoom.roomId then
		local playerCount = type(currentRoom.players) == "table" and #currentRoom.players or 0
		statusText = state.matchStarting == true and "COUNTDOWN" or "ROOM ACTIVE"
		badgeColor = state.matchStarting == true and Color3.fromRGB(126, 84, 48) or Color3.fromRGB(54, 110, 86)
		primaryText = string.format("Room #%s aktif. Semua akses dasar lobby ada di panel ini.", tostring(currentRoom.roomId))
		secondaryText = string.format(
			"%s | %s | %d pemain",
			tostring(currentRoom.mode or selectedMode),
			tostring(currentRoom.mapId or selectedMap),
			playerCount
		)
	end

	if window.Title then
		window.Title.Text = "QUICK MENU"
	end
	if window.StatusBadge then
		window.StatusBadge.Text = statusText
		window.StatusBadge.BackgroundColor3 = badgeColor
	end
	if window.PrimaryLabel then
		window.PrimaryLabel.Text = primaryText
	end
	if window.SecondaryLabel then
		window.SecondaryLabel.Text = secondaryText
	end
	if window.FooterLabel then
		window.FooterLabel.Text = "Tombol di bawah benar-benar menggerakkan UI terkait. X untuk minimize ke float MENU."
	end

	local profileOpen = self._uiState.ProfileUI and self._uiState.ProfileUI.visible == true and self._windowDismissed.ProfileUI ~= true
	local shopOpen = self._uiState.ShopUI and self._uiState.ShopUI.visible == true and self._windowDismissed.ShopUI ~= true
	local _, rankPanel = self:_getBasicWindowState("LeaderboardUI")
	local rankOpen = rankPanel and rankPanel.Visible == true

	if window.RoomBrowserButton then
		window.RoomBrowserButton.Text = self._roomBrowserVisible and "TUTUP ROOM BROWSER" or "OPEN ROOM BROWSER"
		window.RoomBrowserButton.BackgroundColor3 = self._roomBrowserVisible
			and Color3.fromRGB(66, 104, 144)
			or Color3.fromRGB(46, 78, 114)
	end
	if window.ProfileButton then
		window.ProfileButton.Text = profileOpen and "TUTUP PROFILE" or "OPEN PROFILE"
		window.ProfileButton.BackgroundColor3 = profileOpen
			and Color3.fromRGB(78, 112, 82)
			or Color3.fromRGB(58, 84, 62)
	end
	if window.ShopButton then
		window.ShopButton.Text = shopOpen and "TUTUP SHOP" or "OPEN SHOP"
		window.ShopButton.BackgroundColor3 = shopOpen
			and Color3.fromRGB(126, 94, 56)
			or Color3.fromRGB(104, 78, 48)
	end
	if window.RankButton then
		window.RankButton.Text = rankOpen and "TUTUP RANK BOARD" or "OPEN RANK BOARD"
		window.RankButton.BackgroundColor3 = rankOpen
			and Color3.fromRGB(98, 104, 62)
			or Color3.fromRGB(78, 84, 50)
	end
end

function UISystem:_refreshLeaderboardPanel()
	local window = self._uxWidgets and self._uxWidgets.basicWindows and self._uxWidgets.basicWindows.LeaderboardUI
	if not window then
		return
	end

	local player = Players.LocalPlayer
	local playerName = player and (player.DisplayName or player.Name) or "Player"
	local profile = self._profileState or {}
	local level = math.max(1, math.floor(tonumber(profile.level or 1) or 1))
	local totalGames = math.max(0, math.floor(tonumber(profile.totalGames or 0) or 0))
	local sanity = math.max(0, math.floor(tonumber(profile.sanity or 100) or 100))
	local rankName = tostring(profile.rank or "Bayi III")
	local victories = math.max(0, math.floor(tonumber(profile.victories or 0) or 0))
	local leaderboardLabel = string.match(string.lower(rankName), "^sang ahli")
		and string.format("Sang Ahli x%d", victories)
		or rankName
	local state = self:GetRoomBrowserState() or {}
	local rooms = type(state.rooms) == "table" and state.rooms or {}
	local currentRoom = type(state.currentRoom) == "table" and state.currentRoom or nil
	local badgeText = "LOCAL SNAPSHOT"
	local badgeColor = Color3.fromRGB(92, 104, 60)
	local secondaryText = string.format("Rank %s | Match %d | Snapshot Lokal", leaderboardLabel, totalGames)
	local roomLine = string.format("Room Browser %s | %d room terlihat", self._roomBrowserVisible and "terbuka" or "tertutup", #rooms)

	if currentRoom and currentRoom.roomId then
		local roomMode = tostring(currentRoom.mode or state.selectedMode or "Classic")
		local playerCount = type(currentRoom.players) == "table" and #currentRoom.players or 0
		badgeText = string.upper(roomMode) .. " ROOM"
		badgeColor = string.lower(roomMode) == "ranked"
			and Color3.fromRGB(132, 96, 52)
			or Color3.fromRGB(60, 96, 132)
		roomLine = string.format(
			"Room #%s | %s | %d pemain",
			tostring(currentRoom.roomId),
			tostring(currentRoom.mapId or state.selectedMap or MAPS[1] or "HauntedHouse"),
			playerCount
		)
	end

	if window.Title then
		window.Title.Text = "RANK BOARD"
	end
	if window.StatusBadge then
		window.StatusBadge.Text = badgeText
		window.StatusBadge.BackgroundColor3 = badgeColor
	end
	if window.PrimaryLabel then
		window.PrimaryLabel.Text = string.format("%s | %s", playerName, leaderboardLabel)
	end
	if window.SecondaryLabel then
		window.SecondaryLabel.Text = secondaryText
	end
	if window.ContentText then
		window.ContentText.Text = table.concat({
			"PERSONAL SNAPSHOT",
			string.format("- Rank Saat Ini: %s", leaderboardLabel),
			string.format("- Rank Tier Raw: %s", rankName),
			string.format("- Level: %d", level),
			string.format("- Total Match: %d", totalGames),
			string.format("- Sanity: %d", sanity),
			string.format("- Victory Counter Lokal: %d", victories),
			"",
			"SERVER BOARD",
			"1. Leaderboard kanonik memakai progres rank, dan Sang Ahli memakai victory counter.",
			"2. Slot leaderboard server belum di-stream ke panel basic ini.",
			"3. Snapshot ini sengaja tidak lagi memakai formula preview palsu.",
			"",
			roomLine,
		}, "\n")
	end
	if window.FooterLabel then
		window.FooterLabel.Text = "Panel rank ini tetap basic: hanya snapshot lokal, tanpa skor leaderboard buatan."
	end

	local _, menuPanel = self:_getBasicWindowState("MainMenuUI")
	local menuOpen = menuPanel and menuPanel.Visible == true
	local profileOpen = self._uiState.ProfileUI and self._uiState.ProfileUI.visible == true and self._windowDismissed.ProfileUI ~= true
	if window.ProfileButton then
		window.ProfileButton.Text = profileOpen and "TUTUP PROFILE" or "PROFILE"
		window.ProfileButton.BackgroundColor3 = profileOpen
			and Color3.fromRGB(78, 112, 82)
			or Color3.fromRGB(58, 84, 62)
	end
	if window.RoomBrowserButton then
		window.RoomBrowserButton.Text = self._roomBrowserVisible and "TUTUP ROOMS" or "OPEN ROOMS"
		window.RoomBrowserButton.BackgroundColor3 = self._roomBrowserVisible
			and Color3.fromRGB(66, 104, 144)
			or Color3.fromRGB(46, 78, 114)
	end
	if window.MenuButton then
		window.MenuButton.Text = menuOpen and "TUTUP MENU" or "OPEN MENU"
		window.MenuButton.BackgroundColor3 = menuOpen
			and Color3.fromRGB(86, 96, 120)
			or Color3.fromRGB(58, 66, 84)
	end
end

function UISystem:_refreshAuxiliaryPanels()
	self:_refreshJournalPanel()
	self:_refreshProfilePanel()
	self:_refreshShopPanel()
	self:_refreshPasraPanel()
	self:_refreshSpectatorPanel()
	self:_syncAuxiliaryWindowVisibility()
end

function UISystem:_refreshWindowText(guiName, statusText, primaryText, secondaryText, contentText, footerText, badgeColor)
	local window = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows[guiName]
	if not window then
		return
	end

	if window.StatusBadge then
		window.StatusBadge.Text = statusText
		if badgeColor then
			window.StatusBadge.BackgroundColor3 = badgeColor
		end
	end
	if window.PrimaryLabel then
		window.PrimaryLabel.Text = primaryText
	end
	if window.SecondaryLabel then
		window.SecondaryLabel.Text = secondaryText
	end
	if window.ContentText then
		window.ContentText.Text = contentText
		window.ContentText.Visible = contentText ~= nil
	end
	if window.FooterLabel and footerText then
		window.FooterLabel.Text = footerText
	end
end

function UISystem:_refreshJournalPanel()
	local state = self._journalState or {}
	local discovered = state.discoveredEvidence or {}
	local confirmed = state.confirmedEvidence or {}
	local candidates = state.candidates or {}
	local statusText = #confirmed > 0 and "CONFIRMED" or (#discovered > 0 and "EVIDENCE" or "JOURNAL")
	local badgeColor = #confirmed > 0 and Color3.fromRGB(58, 116, 90) or Color3.fromRGB(56, 92, 128)
	local primaryText = #discovered > 0
		and string.format("%d evidence tercatat. Gunakan ini untuk deduction cepat.", #discovered)
		or "Belum ada evidence tercatat."
	local secondaryText = string.format(
		"Confirmed %d | Kandidat %d | Event %s",
		#confirmed,
		#candidates,
		tostring(state.lastEvent or "Idle")
	)
	local contentText = table.concat({
		"Discovered Evidence",
		bulletList(discovered, "- Belum ada"),
		"",
		"Confirmed Evidence",
		bulletList(confirmed, "- Belum ada"),
		"",
		"Ghost Candidates",
		bulletList(candidates, "- Belum ada"),
		"",
		"Tool E2E",
		string.format("- Tool: %s", tostring(state.toolType or JOURNAL_TOOL_TYPE)),
		string.format("- Status: %s", tostring(state.toolStatus or "Belum dipakai")),
		string.format("- Detail: %s", tostring(state.toolReason or "-")),
	}, "\n")
	self:_refreshWindowText(
		"JournalUI",
		statusText,
		primaryText,
		secondaryText,
		contentText,
		"Shortcut: J. Tekan SCAN JEJAK untuk uji 1 evidence tool end-to-end. " .. CLOSE_HINT_TEXT .. ".",
		badgeColor
	)

	local window = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows.JournalUI
	if window and window.ToolStatusLabel then
		local statusLine = string.format(
			"SCAN STATUS\n%s\n%s",
			tostring(state.toolStatus or "Belum dipakai"),
			tostring(state.toolReason or "-")
		)
		window.ToolStatusLabel.Text = statusLine
	end
	if window and window.ToolActionButton then
		window.ToolActionButton.Text = "SCAN JEJAK"
	end
end

function UISystem:_refreshProfilePanel()
	local player = Players.LocalPlayer
	local profile = self._profileState or {}
	local playerName = player and (player.DisplayName or player.Name) or "Player"
	local sanity = math.floor(tonumber(profile.sanity or 100) or 100)
	local statusToken = tostring(profile.status or "safe")
	local badgeText = string.upper(statusToken:gsub("_", " "))
	local badgeColor = Color3.fromRGB(74, 96, 58)
	if statusToken == "hunt_risk" then
		badgeColor = Color3.fromRGB(124, 56, 56)
	elseif statusToken == "high_paranormal_activity" then
		badgeColor = Color3.fromRGB(126, 84, 48)
	elseif statusToken == "unstable" then
		badgeColor = Color3.fromRGB(82, 94, 126)
	end

	local contentLines = {
		string.format("Player: %s", playerName),
		string.format("UserId: %s", tostring(player and player.UserId or "-")),
		string.format("Level: %s", tostring(profile.level or 1)),
		string.format("Rank: %s", tostring(profile.rank or "Bayi III")),
		string.format("Sanity: %d", sanity),
		string.format("Total Match: %s", tostring(profile.totalGames or 0)),
		string.format("Favorite Tool: %s", tostring(profile.favoriteTool or "-")),
		string.format("Input: %s", tostring(self:GetInputType())),
		string.format("Last Event: %s", tostring(profile.lastEvent or "Idle")),
	}

	local featuredFlex = profile.featuredFlex
	if type(featuredFlex) == "table" then
		table.insert(contentLines, string.format("Flex Spotlight: %s", tostring(featuredFlex.displayName or "Player")))
		table.insert(contentLines, string.format("Spotlight Rank: %s | Lv %s", tostring(featuredFlex.rank or "Bayi III"), tostring(featuredFlex.level or 1)))
		table.insert(contentLines, string.format("Spotlight WR: %s%% | Match: %s", tostring(featuredFlex.winRate or 0), tostring(featuredFlex.totalMatches or 0)))
		table.insert(contentLines, string.format("Spotlight Show: %s", tostring(featuredFlex.showcaseSummary or formatJoinedValues(featuredFlex.featuredNames, "-"))))
		table.insert(contentLines, string.format("Flex Visitors: %s", tostring(featuredFlex.activeVisitorCount or 0)))
	end

	local contentText = table.concat(contentLines, "\n")

	self:_refreshWindowText(
		"ProfileUI",
		badgeText,
		string.format("%s | Lv %s", playerName, tostring(profile.level or 1)),
		string.format("Rank %s | Sanity %d", tostring(profile.rank or "Bayi III"), sanity),
		contentText,
		"Profile basic ini menampilkan data client yang tersedia tanpa asumsi server tambahan.",
		badgeColor
	)
end

function UISystem:_requestShopPurchase(itemId)
	local remote = self._remotes and self._remotes.PurchaseEvent or nil
	if not remote or not itemId then
		return
	end

	local player = Players.LocalPlayer
	self._shopRequestSeq += 1
	local requestId = string.format(
		"shop:%s:%d",
		tostring(player and player.UserId or 0),
		self._shopRequestSeq
	)
	self._shopState.lastMessage = "Mengirim request pembelian untuk " .. tostring(itemId) .. "..."
	self._shopState.lastPurchase = {
		itemId = itemId,
		success = nil,
		reason = "pending",
		requestId = requestId,
	}
	remote:FireServer({
		action = "PurchaseItem",
		itemId = itemId,
		requestId = requestId,
	})
	self:_openAuxiliaryWindow("ShopUI")
end

function UISystem:_refreshShopPanel()
	local window = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows.ShopUI
	if not window then
		return
	end

	local lastPurchase = self._shopState.lastPurchase
	local statusText = "STORE"
	local badgeColor = Color3.fromRGB(124, 92, 48)
	local secondaryText = self._shopState.lastMessage or "Pilih item untuk test shop."
	if lastPurchase and lastPurchase.success == true then
		statusText = "PURCHASE OK"
		badgeColor = Color3.fromRGB(58, 116, 90)
		secondaryText = string.format("Pembelian %s berhasil.", tostring(lastPurchase.itemId or "-"))
	elseif lastPurchase and lastPurchase.success == false then
		statusText = "PURCHASE FAIL"
		badgeColor = Color3.fromRGB(124, 56, 56)
		secondaryText = string.format(
			"%s gagal: %s",
			tostring(lastPurchase.itemId or "-"),
			titleCaseToken(lastPurchase.reason or "unknown")
		)
	elseif lastPurchase and lastPurchase.reason == "pending" then
		statusText = "PROCESSING"
		badgeColor = Color3.fromRGB(82, 94, 126)
	end

	self:_refreshWindowText(
		"ShopUI",
		statusText,
		"Shop basic siap untuk test PurchaseEvent.",
		secondaryText,
		nil,
		"Klik BELI untuk kirim request pembelian basic. Response akan tampil di badge dan subtitle.",
		badgeColor
	)

	if window.ItemRows and type(window.ItemRows) == "table" then
		for index, row in ipairs(window.ItemRows) do
			local item = self._shopState.catalog[index]
			if row.Root then
				row.Root.Visible = item ~= nil
			end
			if item then
				row.Title.Text = tostring(item.name or item.id or ("Item " .. tostring(index)))
				row.Meta.Text = string.format(
					"%s | %s | %s MM",
					tostring(item.category or "Item"),
					tostring(item.rarityLabel or item.rarity or "R1"),
					tostring(item.price or 0)
				)
				row.Button.Text = "BELI"
				row.Button.BackgroundColor3 = Color3.fromRGB(60, 88, 128)
			end
		end
	end
end

function UISystem:_refreshPasraPanel()
	local result = self._matchResult or createDefaultMatchResult()
	local statusText = result.correctGuess and "SUCCESS" or "RESULT"
	local badgeColor = result.correctGuess and Color3.fromRGB(58, 116, 90) or Color3.fromRGB(58, 100, 88)
	local primaryText = self._pasraState.status or "Belum ada hasil match."
	local secondaryText = self._pasraState.subtitle or "Panel ini akan terisi saat match selesai."
	local contentText = table.concat({
		string.format("Ghost: %s", tostring(result.ghostType or "Unknown")),
		string.format("Tebakan: %s", result.correctGuess and "BENAR" or "BELUM / SALAH"),
		string.format("Evidence: %s", tostring(result.evidenceCollected or 0)),
		string.format("Pemain Selamat: %s", tostring(result.playersSurvived or 0)),
		string.format("Pemain Mati: %s", tostring(result.playersDead or 0)),
		string.format("Durasi: %s", formatMatchDuration(result.matchDuration)),
		string.format("Hadiah MM: %s", tostring(math.floor(tonumber(result.currencyReward or 0) or 0))),
		string.format("Hadiah XP: %s", tostring(math.floor(tonumber(result.xpReward or 0) or 0))),
		string.format("Last Event: %s", tostring(self._pasraState.lastEvent or "Idle")),
	}, "\n")
	self:_refreshWindowText(
		"PASRA_UI",
		statusText,
		primaryText,
		secondaryText,
		contentText,
		"Summary hasil ini basic, visual, dan cukup untuk test E2E return flow.",
		badgeColor
	)
end

function UISystem:_refreshSpectatorPanel()
	local spectator = self._spectatorState or {}
	local badgeText = spectator.mode == "dead" and "DEAD" or "NOTICE"
	local badgeColor = spectator.mode == "dead"
		and Color3.fromRGB(120, 52, 52)
		or Color3.fromRGB(94, 74, 48)
	local contentText = table.concat({
		tostring(spectator.subtitle or "-"),
		"",
		"Distortion Odds",
		"- Fake: 60%",
		"- Uncertain: 30%",
		"- Real: 10%",
		"",
		"Gunakan float VIEW untuk buka ulang panel ini jika ditutup.",
	}, "\n")
	self:_refreshWindowText(
		"SpectatorUI",
		badgeText,
		tostring(spectator.title or "Belum spectate."),
		string.format("Mode %s | Event %s", tostring(spectator.mode or "none"), tostring(spectator.lastEvent or "Idle")),
		contentText,
		"Pesan spectator basic ini mengikuti requirement visual death/spectator.",
		badgeColor
	)
end

function UISystem:_trackUXInstance(instance)
	table.insert(self._uxInstances, instance)
	return instance
end

function UISystem:_clearUXInstances()
	destroyAll(self._uxInstances)
	local matchWidgets = self._uxWidgets.match
	if matchWidgets and matchWidgets.PulseConnection then
		matchWidgets.PulseConnection:Disconnect()
		matchWidgets.PulseConnection = nil
	end
	if matchWidgets and matchWidgets.PulseTween then
		matchWidgets.PulseTween:Cancel()
		matchWidgets.PulseTween = nil
	end
end

function UISystem:_setSelectableStyle(guiObject)
	if not guiObject then
		return
	end
	guiObject.Selectable = true
	local stroke = Instance.new("UIStroke")
	stroke.Name = "SelectionStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 0
	stroke.Color = Color3.fromRGB(255, 220, 120)
	stroke.Parent = guiObject

	table.insert(self._uxConnections, guiObject.SelectionGained:Connect(function()
		stroke.Thickness = 3
	end))
	table.insert(self._uxConnections, guiObject.SelectionLost:Connect(function()
		stroke.Thickness = 0
	end))
end

function UISystem:_applyDeviceSizing()
	local profile = self._deviceProfile
	if not profile then
		return
	end
	local lobby = self._uxWidgets.lobby
	if lobby and lobby.PlayButton and lobby.FeedbackLabel then
		local buttonSize = profile:GetButtonSize()
		lobby.PlayButton.Size = UDim2.fromOffset(buttonSize.X, buttonSize.Y)
		lobby.PlayButton.TextSize = profile:GetTextSize()
		lobby.FeedbackLabel.TextSize = math.max(16, profile:GetTextSize() - 2)
	end
	if lobby and lobby.BasicOpenRoomBrowserButton and lobby.BasicPrimaryLabel then
		lobby.BasicOpenRoomBrowserButton.TextSize = math.max(14, profile:GetTextSize() - 2)
		if lobby.BasicProfileButton then
			lobby.BasicProfileButton.TextSize = math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicShopButton then
			lobby.BasicShopButton.TextSize = math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicMenuButton then
			lobby.BasicMenuButton.TextSize = math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicRankButton then
			lobby.BasicRankButton.TextSize = math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicPrimaryLabel then
			lobby.BasicPrimaryLabel.TextSize = math.max(15, profile:GetTextSize() - 2)
		end
		if lobby.BasicSecondaryLabel then
			lobby.BasicSecondaryLabel.TextSize = math.max(12, profile:GetTextSize() - 5)
		end
		if lobby.BasicHintLabel then
			lobby.BasicHintLabel.TextSize = math.max(11, profile:GetTextSize() - 6)
		end
		if lobby.BasicStatusBadge then
			lobby.BasicStatusBadge.TextSize = math.max(11, profile:GetTextSize() - 7)
		end
	end

	local match = self._uxWidgets.match
	if match and match.MessageLabel and match.ObjectiveLabel then
		match.MessageLabel.TextSize = profile:GetTextSize() + 8
		match.ObjectiveLabel.TextSize = profile:GetTextSize()
	end
	if match and match.BasicPrimaryLabel and match.BasicSecondaryLabel then
		match.BasicPrimaryLabel.TextSize = math.max(16, profile:GetTextSize())
		match.BasicSecondaryLabel.TextSize = math.max(13, profile:GetTextSize() - 2)
		if match.BasicFooterLabel then
			match.BasicFooterLabel.TextSize = math.max(12, profile:GetTextSize() - 3)
		end
		if match.BasicStateBadge then
			match.BasicStateBadge.TextSize = math.max(11, profile:GetTextSize() - 4)
		end
		if match.BasicFloatButton then
			match.BasicFloatButton.TextSize = profile.isConsole and 14 or 12
		end
	end
	if match and match.ResultsTitle and match.ResultsStatus then
		match.ResultsTitle.TextSize = math.max(22, profile:GetTextSize() + 6)
		match.ResultsStatus.TextSize = math.max(12, profile:GetTextSize() - 3)
		if match.ResultsSubtitle then
			match.ResultsSubtitle.TextSize = math.max(15, profile:GetTextSize() - 1)
		end
		if match.ResultsFooter then
			match.ResultsFooter.TextSize = math.max(13, profile:GetTextSize() - 2)
		end
	end
	if self._uxWidgets and self._uxWidgets.windows then
		for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
			local window = self._uxWidgets.windows[guiName]
			if window then
				if window.PrimaryLabel then
					window.PrimaryLabel.TextSize = math.max(15, profile:GetTextSize() - 1)
				end
				if window.SecondaryLabel then
					window.SecondaryLabel.TextSize = math.max(12, profile:GetTextSize() - 5)
				end
				if window.ContentText then
					window.ContentText.TextSize = math.max(12, profile:GetTextSize() - 5)
				end
				if window.FooterLabel then
					window.FooterLabel.TextSize = math.max(11, profile:GetTextSize() - 6)
				end
				if window.StatusBadge then
					window.StatusBadge.TextSize = math.max(11, profile:GetTextSize() - 7)
				end
				if window.FloatButton then
					window.FloatButton.TextSize = profile.isConsole and 14 or 12
				end
				if window.ItemRows then
					for _, row in ipairs(window.ItemRows) do
						if row.Title then
							row.Title.TextSize = math.max(12, profile:GetTextSize() - 6)
						end
						if row.Meta then
							row.Meta.TextSize = math.max(10, profile:GetTextSize() - 8)
						end
						if row.Button then
							row.Button.TextSize = math.max(12, profile:GetTextSize() - 6)
						end
					end
				end
			end
		end
	end
	if self._uxWidgets and self._uxWidgets.basicWindows then
		for _, window in pairs(self._uxWidgets.basicWindows) do
			if window.PrimaryLabel then
				window.PrimaryLabel.TextSize = math.max(15, profile:GetTextSize() - 1)
			end
			if window.SecondaryLabel then
				window.SecondaryLabel.TextSize = math.max(12, profile:GetTextSize() - 5)
			end
			if window.ContentText then
				window.ContentText.TextSize = math.max(12, profile:GetTextSize() - 5)
			end
			if window.FooterLabel then
				window.FooterLabel.TextSize = math.max(11, profile:GetTextSize() - 6)
			end
			if window.StatusBadge then
				window.StatusBadge.TextSize = math.max(11, profile:GetTextSize() - 7)
			end
			if window.FloatButton then
				window.FloatButton.TextSize = profile.isConsole and 14 or 12
			end
			if window.ActionButtons then
				for _, button in ipairs(window.ActionButtons) do
					if button then
						button.TextSize = math.max(12, profile:GetTextSize() - 5)
					end
				end
			end
		end
	end

	local widgets = self._roomBrowserWidgets
	if widgets and widgets.FloatButton then
		local sizePx = 64
		if profile.isMobile then
			sizePx = 72
		elseif profile.isConsole then
			sizePx = 78
		end
		local _, bottomRightInset = resolveSafeInsets()
		widgets.FloatButton.Size = UDim2.fromOffset(sizePx, sizePx)
		widgets.FloatButton.Position = UDim2.new(1, -(20 + bottomRightInset.X), 0.5, 0)
		widgets.FloatButton.TextSize = profile.isConsole and 14 or 12
	end
	if widgets and widgets.RoomPreviewPlayersList then
		local layout = widgets.RoomPreviewPlayersList:FindFirstChildOfClass("UIGridLayout")
		if layout then
			if profile.isMobile then
				layout.FillDirectionMaxCells = 1
				layout.CellSize = UDim2.fromOffset(442, 78)
			else
				layout.FillDirectionMaxCells = 2
				layout.CellSize = UDim2.fromOffset(220, 78)
			end
		end
	end
end

function UISystem:_runPostTeleportLoadingFlow()
	if self._postTeleportFlowRunning then
		return
	end
	if self._hasPostTeleportLoaded then
		return
	end

	local player = Players.LocalPlayer
	if not player or player:GetAttribute("InMatch") ~= true then
		return
	end
	if self._matchPhase == MATCH_PHASE.INGAME then
		self._hasPostTeleportLoaded = true
		self._awaitingPostTeleportFlow = false
		return
	end

	self._postTeleportFlowRunning = true
	task.spawn(function()
		self:_setPhase(MATCH_PHASE.LOADING)
		task.wait(2)

		local currentPlayer = Players.LocalPlayer
		if not currentPlayer or currentPlayer:GetAttribute("InMatch") ~= true then
			self._postTeleportFlowRunning = false
			return
		end

		self:_setPhase(MATCH_PHASE.BRIEFING)
		task.wait(3)

		currentPlayer = Players.LocalPlayer
		if currentPlayer and currentPlayer:GetAttribute("InMatch") == true then
			self:_setPhase(MATCH_PHASE.INGAME, self._pendingInGamePayload)
			self._pendingInGamePayload = nil
			self._hasPostTeleportLoaded = true
			self._awaitingPostTeleportFlow = false
		end

		self._postTeleportFlowRunning = false
	end)
end

function UISystem:_bindPostTeleportLoading()
	local player = Players.LocalPlayer
	if not player then
		return
	end

	table.insert(self._connections, player.CharacterAdded:Connect(function()
		if self._awaitingPostTeleportFlow or self._hasPostTeleportLoaded ~= true then
			self:_runPostTeleportLoadingFlow()
		end
	end))
end

function UISystem:_setPhase(newPhase, payload)
	payload = decoratePhasePayload(payload)
	local phaseChanged = self._matchPhase ~= newPhase
	self._matchPhase = newPhase
	self._phasePayload = payload
	self._phaseStartTime = (payload and payload._clientReceivedAt) or tick()
	self._phaseDuration = (payload and (payload.durationSeconds or payload.duration)) or nil
	if newPhase == MATCH_PHASE.LOADING then
		self._loadingStartTime = tick()
	end
	local localPlayer = Players.LocalPlayer
	if phaseChanged and localPlayer then
		localPlayer:SetAttribute("MatchPhase", newPhase)
	end

	self:_renderPhase(newPhase, payload)
end

function UISystem:_ensureLoadingScreen()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil
	end

	local existing = playerGui:FindFirstChild("MatchLoadingUI")
	if existing and existing:IsA("ScreenGui") then
		return existing
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "MatchLoadingUI"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 500
	screen.Enabled = false

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(6, 9, 14)
	bg.BackgroundTransparency = 0.14
	bg.BorderSizePixel = 0
	bg.Parent = screen

	local shade = Instance.new("Frame")
	shade.Name = "Shade"
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.38
	shade.BorderSizePixel = 0
	shade.Parent = bg

	local status = Instance.new("TextLabel")
	status.Name = "StatusLabel"
	status.AnchorPoint = Vector2.new(0.5, 0)
	status.Position = UDim2.fromScale(0.5, 0.14)
	status.Size = UDim2.fromOffset(280, 28)
	status.BackgroundTransparency = 1
	status.Text = "BERMAIN"
	status.TextColor3 = Color3.fromRGB(185, 198, 214)
	status.Font = Enum.Font.GothamSemibold
	status.TextSize = 18
	status.Parent = bg

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.22)
	title.Size = UDim2.fromOffset(760, 64)
	title.BackgroundTransparency = 1
	title.Text = "Masuk ke lokasi..."
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 38
	title.Parent = bg

	local mapName = Instance.new("TextLabel")
	mapName.Name = "MapNameLabel"
	mapName.AnchorPoint = Vector2.new(0.5, 0)
	mapName.Position = UDim2.fromScale(0.5, 0.33)
	mapName.Size = UDim2.fromOffset(760, 34)
	mapName.BackgroundTransparency = 1
	mapName.Text = "Lokasi: -"
	mapName.TextColor3 = Color3.fromRGB(202, 214, 228)
	mapName.Font = Enum.Font.GothamSemibold
	mapName.TextSize = 20
	mapName.Parent = bg

	local tip = Instance.new("TextLabel")
	tip.Name = "TipLabel"
	tip.AnchorPoint = Vector2.new(0.5, 0)
	tip.Position = UDim2.fromScale(0.5, 0.46)
	tip.Size = UDim2.fromOffset(860, 72)
	tip.BackgroundTransparency = 1
	tip.TextWrapped = true
	tip.Text = LOADING_TIPS[1]
	tip.TextColor3 = Color3.fromRGB(221, 229, 239)
	tip.Font = Enum.Font.Gotham
	tip.TextSize = 18
	tip.Parent = bg

	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "ProgressTrack"
	progressTrack.AnchorPoint = Vector2.new(0.5, 0)
	progressTrack.Position = UDim2.fromScale(0.5, 0.66)
	progressTrack.Size = UDim2.fromOffset(520, 16)
	progressTrack.BackgroundColor3 = Color3.fromRGB(34, 42, 56)
	progressTrack.BorderSizePixel = 0
	progressTrack.Parent = bg

	local progressTrackCorner = Instance.new("UICorner")
	progressTrackCorner.CornerRadius = UDim.new(0, 999)
	progressTrackCorner.Parent = progressTrack

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.fromScale(0.08, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(84, 142, 114)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressTrack

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 999)
	progressFillCorner.Parent = progressFill

	local footer = Instance.new("TextLabel")
	footer.Name = "FooterLabel"
	footer.AnchorPoint = Vector2.new(0.5, 0)
	footer.Position = UDim2.fromScale(0.5, 0.72)
	footer.Size = UDim2.fromOffset(620, 28)
	footer.BackgroundTransparency = 1
	footer.Text = "Sinkronisasi match sedang berjalan..."
	footer.TextColor3 = Color3.fromRGB(168, 182, 202)
	footer.Font = Enum.Font.Gotham
	footer.TextSize = 15
	footer.Parent = bg

	screen.Parent = playerGui
	return screen
end

function UISystem:_ensureTeleportOverlay()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil, nil
	end

	local screen = playerGui:FindFirstChild(TELEPORT_OVERLAY_GUI_NAME)
	if screen and not screen:IsA("ScreenGui") then
		screen:Destroy()
		screen = nil
	end
	if not screen then
		screen = Instance.new("ScreenGui")
		screen.Name = TELEPORT_OVERLAY_GUI_NAME
		screen.IgnoreGuiInset = true
		screen.ResetOnSpawn = false
		screen.DisplayOrder = 10000
		screen.Enabled = false
		screen.Parent = playerGui
	end

	local overlay = screen:FindFirstChild(TELEPORT_OVERLAY_FRAME_NAME)
	if overlay and not overlay:IsA("Frame") then
		overlay:Destroy()
		overlay = nil
	end
	if not overlay then
		overlay = Instance.new("Frame")
		overlay.Name = TELEPORT_OVERLAY_FRAME_NAME
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.BorderSizePixel = 0
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 0
		overlay.Active = false
		overlay.Selectable = false
		overlay.Parent = screen
	end

	return screen, overlay
end

function UISystem:_showTeleportOverlay(durationSeconds)
	local screen, overlay = self:_ensureTeleportOverlay()
	if not screen or not overlay then
		return
	end

	self._teleportOverlayToken = (self._teleportOverlayToken or 0) + 1
	local token = self._teleportOverlayToken

	if self._teleportOverlayTween then
		self._teleportOverlayTween:Cancel()
		self._teleportOverlayTween = nil
	end

	overlay.BackgroundTransparency = 0
	screen.Enabled = true

	task.spawn(function()
		task.wait(math.max(0, tonumber(durationSeconds) or TELEPORT_OVERLAY_HOLD_SECONDS))
		if self._teleportOverlayToken ~= token then
			return
		end

		local tween = TweenService:Create(
			overlay,
			TweenInfo.new(TELEPORT_OVERLAY_FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		self._teleportOverlayTween = tween
		tween:Play()
		tween.Completed:Connect(function()
			if self._teleportOverlayToken ~= token then
				return
			end
			self._teleportOverlayTween = nil
			screen.Enabled = false
			overlay.BackgroundTransparency = 0
		end)
	end)
end

function UISystem:_setLoadingScreenContent(titleText, payload, progress, footerText)
	local screen = self:_ensureLoadingScreen()
	if not screen then
		return
	end

	local bg = screen:FindFirstChild("Background")
	if not bg or not bg:IsA("Frame") then
		return
	end

	local title = bg:FindFirstChild("TitleLabel")
	local status = bg:FindFirstChild("StatusLabel")
	local mapName = bg:FindFirstChild("MapNameLabel")
	local tip = bg:FindFirstChild("TipLabel")
	local progressTrack = bg:FindFirstChild("ProgressTrack")
	local footer = bg:FindFirstChild("FooterLabel")
	if title and title:IsA("TextLabel") then
		title.Text = titleText or "Masuk ke lokasi..."
	end
	if status and status:IsA("TextLabel") then
		status.Text = "BERMAIN"
	end
	if mapName and mapName:IsA("TextLabel") then
		mapName.Text = "Lokasi: " .. resolveMapDisplayName(payload)
	end
	if tip and tip:IsA("TextLabel") then
		local index = self._loadingTipIndex or 1
		tip.Text = LOADING_TIPS[index] or LOADING_TIPS[1]
	end
	if footer and footer:IsA("TextLabel") then
		footer.Text = footerText or "Sinkronisasi match sedang berjalan..."
	end
	if progressTrack and progressTrack:IsA("Frame") then
		local fill = progressTrack:FindFirstChild("ProgressFill")
		if fill and fill:IsA("Frame") then
			fill.Size = UDim2.fromScale(math.clamp(progress or 0.08, 0.08, 1), 1)
		end
	end
end

function UISystem:_startLoadingScreenLoop(payload)
	if self._loadingLoopRunning then
		return
	end

	local screen = self:_ensureLoadingScreen()
	if not screen then
		return
	end

	self._loadingLoopRunning = true
	self._loadingTipIndex = 1
	self._loadingStartTime = tick()
	screen.Enabled = true

	task.spawn(function()
		local startTime = tick()
		local tipSwapAt = startTime
		while self._loadingLoopRunning do
			local elapsed = tick() - startTime
			if tick() >= tipSwapAt + 1.8 then
				self._loadingTipIndex = (self._loadingTipIndex % #LOADING_TIPS) + 1
				tipSwapAt = tick()
			end

			local progress = 0.12 + math.min(elapsed / 3.2, 0.78)
			self:_setLoadingScreenContent("Masuk ke lokasi...", payload, progress, "Sinkronisasi match sedang berjalan...")
			task.wait(0.08)
		end
	end)
end

function UISystem:_stopLoadingScreenLoop()
	self._loadingLoopRunning = false
	self:_setLoadingScreenContent("Memulai investigasi...", self._phasePayload, 1, "Selesai dimuat.")
	task.wait(0.12)
	local screen = self:_ensureLoadingScreen()
	if screen then
		screen.Enabled = false
	end
end

function UISystem:_renderPhase(phase, payload)
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	local lobbyUI = playerGui:FindFirstChild("LobbyUI")
	local roomUI = playerGui:FindFirstChild("RoomBrowserUI")
	local hud = playerGui:FindFirstChild("HorrorHUD")
	local loadingUI = playerGui:FindFirstChild("MatchLoadingUI")
	local matchUX = self._uxWidgets and self._uxWidgets.match or nil

	if not lobbyUI then
		return
	end

	-- Reset transient overlays before rendering a new phase.
	if loadingUI and loadingUI:IsA("ScreenGui") and phase ~= MATCH_PHASE.PREPARING and phase ~= MATCH_PHASE.LOADING and phase ~= MATCH_PHASE.INGAME then
		self:_stopLoadingScreenLoop()
	end
	if roomUI then
		local loadingLabel = roomUI:FindFirstChild("LoadingLabel")
		if loadingLabel and loadingLabel:IsA("TextLabel") then
			loadingLabel.Visible = false
		end
		local objectiveLabel = roomUI:FindFirstChild("ObjectiveLabel")
		if objectiveLabel and objectiveLabel:IsA("TextLabel") then
			objectiveLabel.Visible = false
		end
		local resultLabel = roomUI:FindFirstChild("ResultLabel")
		if resultLabel and resultLabel:IsA("TextLabel") then
			resultLabel.Visible = false
		end
	end
	if hud then
		local warning = hud:FindFirstChild("Warning")
		if warning then
			warning.Visible = false
		end
	end
	if matchUX and matchUX.MessageLabel and phase ~= MATCH_PHASE.PREPARING and phase ~= MATCH_PHASE.LOADING and phase ~= MATCH_PHASE.INGAME then
		matchUX.MessageLabel.Visible = false
		matchUX.MessageLabel.Text = ""
	end

	if not roomUI then
		return
	end

	if phase == MATCH_PHASE.LOBBY then
		lobbyUI.Enabled = true
		roomUI.Enabled = false
		if hud then
			hud.Enabled = false
			local warning = hud:FindFirstChild("Warning")
			if warning then
				warning.Visible = false
			end
		end
		self:_refreshBasicMatchPanel("Lobby", payload)
		return
	end

	if phase == MATCH_PHASE.PREPARING then
		lobbyUI.Enabled = false
		roomUI.Enabled = true
		if hud then
			hud.Enabled = false
		end
		if loadingUI and loadingUI:IsA("ScreenGui") then
			self:_startLoadingScreenLoop(payload)
			self:_setLoadingScreenContent("Preparing Investigation...", payload, 0.18, "Mempersiapkan sesi investigasi...")
		end
		if matchUX and matchUX.MessageLabel then
			matchUX.MessageLabel.Text = "Bermain"
			matchUX.MessageLabel.Visible = true
		end
		self:_refreshBasicMatchPanel("Preparation", payload)
		return
	end

	if phase == MATCH_PHASE.LOADING then
		lobbyUI.Enabled = false
		roomUI.Enabled = true
		if hud then
			hud.Enabled = false
		end
		if loadingUI and loadingUI:IsA("ScreenGui") then
			self:_startLoadingScreenLoop(payload)
			self:_setLoadingScreenContent("Masuk ke lokasi...", payload, 0.42, "Teleport pemain dan asset match sedang disiapkan...")
		end
		if matchUX and matchUX.MessageLabel then
			matchUX.MessageLabel.Text = "Bermain"
			matchUX.MessageLabel.Visible = true
		end

		local label = roomUI:FindFirstChild("LoadingLabel")
		if label and label:IsA("TextLabel") then
			label.Visible = true
			label.Text = "Masuk ke lokasi..."
		end
		self:_refreshBasicMatchPanel("Loading", payload)
		return
	end

	if phase == MATCH_PHASE.BRIEFING then
		lobbyUI.Enabled = false
		roomUI.Enabled = true
		if hud then
			hud.Enabled = false
		end
		if loadingUI and loadingUI:IsA("ScreenGui") then
			self:_startLoadingScreenLoop(payload)
			self:_setLoadingScreenContent("Briefing Investigasi", payload, 0.82, "Pelajari objective dan tips sebelum masuk.")
		end

		local label = roomUI:FindFirstChild("ObjectiveLabel")
		if label and label:IsA("TextLabel") then
			label.Visible = true
			label.Text = "Investigate the location\nFind evidence\nIdentify the ghost"
		end
		return
	end

	if phase == MATCH_PHASE.INGAME then
		local MIN_LOADING_TIME = 1.5
		local MAX_LOADING_WAIT = 2
		local elapsed = tick() - (self._loadingStartTime or 0)
		local waitTime = math.clamp(MIN_LOADING_TIME - elapsed, 0, MAX_LOADING_WAIT)
		if waitTime > 0 then
			task.wait(waitTime)
		end

		self:_stopLoadingScreenLoop()
		if matchUX and matchUX.MessageLabel then
			matchUX.MessageLabel.Visible = false
			matchUX.MessageLabel.Text = ""
		end

		lobbyUI.Enabled = false
		roomUI.Enabled = false

		if matchUX and matchUX.Gui then
			matchUX.Gui.Enabled = false
		end
		if matchUX and matchUX.Layer then
			matchUX.Layer.Visible = false
		end
		if self._uxReady == true then
			self:TransitionTo("Investigation", payload)
		end

		if hud then
			hud.Enabled = true
			local objective = hud:FindFirstChild("Objective")
			if objective and objective:IsA("TextLabel") then
				objective.Text = "Investigate the location\nFind evidence\nIdentify the ghost"
			end
			local warning = hud:FindFirstChild("Warning")
			if warning then
				warning.Visible = false
			end
		end
		self:_refreshBasicMatchPanel("Investigation", payload)
		return
	end

	if phase == MATCH_PHASE.ESCALATION then
		if hud then
			hud.Enabled = true
			local vignette = hud:FindFirstChild("Vignette")
			if vignette and vignette:IsA("ImageLabel") then
				vignette.ImageTransparency = 0.3
			end
		end
		self:_refreshBasicMatchPanel("Investigation", payload)
		return
	end

	if phase == MATCH_PHASE.HUNT then
		if hud then
			hud.Enabled = true
			local warning = hud:FindFirstChild("Warning")
			if warning and warning:IsA("TextLabel") then
				warning.Visible = true
				warning.Text = "HUNT"
			end

			local heartbeat = hud:FindFirstChild("Heartbeat")
			if heartbeat and heartbeat:IsA("Sound") and not heartbeat.IsPlaying then
				heartbeat:Play()
			end
		end
		self:_refreshBasicMatchPanel("Hunt", payload)
		return
	end

	if phase == MATCH_PHASE.RESULT or phase == MATCH_PHASE.END then
		if hud then
			hud.Enabled = false
			local warning = hud:FindFirstChild("Warning")
			if warning then
				warning.Visible = false
			end
			local heartbeat = hud:FindFirstChild("Heartbeat")
			if heartbeat and heartbeat:IsA("Sound") and heartbeat.IsPlaying then
				heartbeat:Stop()
			end
		end

		roomUI.Enabled = true
		local result = roomUI:FindFirstChild("ResultLabel")
		if result and result:IsA("TextLabel") then
			result.Visible = true
			local failed = payload and payload.missionFailed == true
			result.Text = failed and "MISSION FAILED" or "MISSION COMPLETE"
		end
		self:_refreshBasicMatchPanel("Results", payload)
	end
end

function UISystem:_routeMatchPhaseEvent(eventName, payload)
	payload = decoratePhasePayload(payload)
	if eventName == "MatchPreparing" then
		self:_forceCloseAllPanelsForTeleport()
		self:_showTeleportOverlay(TELEPORT_OVERLAY_HOLD_SECONDS)
		self._hasPostTeleportLoaded = false
		self._awaitingPostTeleportFlow = true
		self:_setPhase(MATCH_PHASE.PREPARING, payload)
	elseif eventName == "MatchStarted" then
		self._hasPostTeleportLoaded = false
		self._awaitingPostTeleportFlow = true
		self:_runPostTeleportLoadingFlow()
	elseif eventName == "PhaseChanged" then
		local resolvedPhase = resolvePhaseFromPayload(eventName, payload)
		if resolvedPhase == MATCH_PHASE.INGAME and (self._awaitingPostTeleportFlow or self._postTeleportFlowRunning) then
			self._pendingInGamePayload = payload
			return
		end
		if resolvedPhase then
			self:_setPhase(resolvedPhase, payload)
		end
	elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
		self._hasPostTeleportLoaded = false
		self._awaitingPostTeleportFlow = false
		local missionFailed = payload and (
			payload.success == false
			or payload.failed == true
			or payload.missionFailed == true
			or payload.correctGuess == false
		)
		self:_setPhase(MATCH_PHASE.RESULT, { duration = 5, missionFailed = missionFailed == true })
	elseif eventName == "RoomBrowserRoomLeft" or eventName == "ReturnedToLobby" then
		self:_forceCloseAllPanelsForTeleport()
		self:_showTeleportOverlay(TELEPORT_OVERLAY_HOLD_SECONDS)
		self._hasPostTeleportLoaded = false
		self._awaitingPostTeleportFlow = false
		if (self._resultsCloseUnlockAt or 0) > tick() and self:_isMatchResultsPhase() then
			local unlockAt = self._resultsCloseUnlockAt
			task.delay(math.max(unlockAt - tick(), 0), function()
				if self._resultsCloseUnlockAt == unlockAt and self:_isMatchResultsPhase() then
					self:_setPhase(MATCH_PHASE.LOBBY)
				end
			end)
			return
		end
		self:_setPhase(MATCH_PHASE.LOBBY)
	end
end

function UISystem:_startPhaseTimer()
	if self._phaseTimerRunning then
		return
	end

	self._phaseTimerRunning = true
	task.spawn(function()
		while self._phaseTimerRunning do
			task.wait(0.1)
			self:_refreshBasicMatchPanel()
			if not self._phaseDuration then
				continue
			end

			local elapsed = tick() - self._phaseStartTime
			if elapsed < self._phaseDuration then
				continue
			end

			if self._matchPhase == MATCH_PHASE.BRIEFING then
				self:_setPhase(MATCH_PHASE.INGAME)
			elseif self._matchPhase == MATCH_PHASE.HUNT then
				-- Server should end hunt; this only prevents repeated fallback transitions.
				self._phaseDuration = nil
			else
				self._phaseDuration = nil
			end
		end
	end)
end

function UISystem:_bindRoomBrowserMatchVisibility()
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local function syncFromAttribute()
		local inMatch = player:GetAttribute("InMatch") == true
		self._roomBrowserSuppressed = inMatch
		if inMatch then
			self._roomBrowserVisible = false
		end
		self:_updateRoomBrowserVisibility()
	end

	table.insert(self._connections, player:GetAttributeChangedSignal("InMatch"):Connect(syncFromAttribute))
	syncFromAttribute()
end

function UISystem:_bindInputProfileUpdates()
	self._deviceProfile:Refresh(UserInputService:GetLastInputType())
	self:_applyDeviceSizing()

	table.insert(self._uxConnections, UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
		self._deviceProfile:Refresh(lastInputType)
		self:_applyDeviceSizing()
	end))
end

function UISystem:_ensureUXLayers()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return false
	end

	local lobbyReady = playerGui:WaitForChild("LobbyUI", 10)
	if not lobbyReady then
		return false
	end

	local container = playerGui:FindFirstChild("UXLayer")
	if not container then
		container = Instance.new("Folder")
		container.Name = "UXLayer"
		container.Parent = playerGui
	end

	local topLeftInset, bottomRightInset = resolveSafeInsets()

	local function ensureSafeLayer(parentInstance, name)
		local layer = parentInstance:FindFirstChild(name)
		if not layer then
			layer = Instance.new("Frame")
			layer.Name = name
			layer.Visible = false
			layer.Active = false
			layer.Selectable = false
			layer.ZIndex = 1
			layer.BackgroundTransparency = 1
			layer.Size = UDim2.fromScale(1, 1)
			layer.Parent = parentInstance

			local padding = Instance.new("UIPadding")
			padding.Name = "SafePadding"
			padding.PaddingTop = UDim.new(0, topLeftInset.Y)
			padding.PaddingLeft = UDim.new(0, topLeftInset.X)
			padding.PaddingBottom = UDim.new(0, bottomRightInset.Y)
			padding.PaddingRight = UDim.new(0, bottomRightInset.X)
			padding.Parent = layer
		end
		return layer
	end

	local lobbyUXGui = container:FindFirstChild("LobbyUXGui")
	if not lobbyUXGui then
		lobbyUXGui = Instance.new("ScreenGui")
		lobbyUXGui.Name = "LobbyUXGui"
		lobbyUXGui.ResetOnSpawn = false
		lobbyUXGui.DisplayOrder = 1
		lobbyUXGui.IgnoreGuiInset = false
		lobbyUXGui.Enabled = false
		lobbyUXGui.Parent = container
	end

	local matchUXGui = container:FindFirstChild("MatchUXGui")
	if not matchUXGui then
		matchUXGui = Instance.new("ScreenGui")
		matchUXGui.Name = "MatchUXGui"
		matchUXGui.ResetOnSpawn = false
		matchUXGui.DisplayOrder = 1
		matchUXGui.IgnoreGuiInset = false
		matchUXGui.Enabled = false
		matchUXGui.Parent = container
	end

	local lobbyLayer = ensureSafeLayer(lobbyUXGui, "LobbyUXLayer")
	local matchLayer = ensureSafeLayer(matchUXGui, "MatchUXLayer")

	local lobbyFeedback = lobbyLayer:FindFirstChild("FeedbackLabel")
	if not lobbyFeedback then
		lobbyFeedback = Instance.new("TextLabel")
		lobbyFeedback.Name = "FeedbackLabel"
		lobbyFeedback.Visible = false
		lobbyFeedback.Active = false
		lobbyFeedback.Selectable = false
		lobbyFeedback.ZIndex = 1
		lobbyFeedback.BackgroundTransparency = 1
		lobbyFeedback.AnchorPoint = Vector2.new(0.5, 0)
		lobbyFeedback.Position = UDim2.fromScale(0.5, 0.06)
		lobbyFeedback.Size = UDim2.new(0.9, 0, 0, 60)
		lobbyFeedback.Font = Enum.Font.Gotham
		lobbyFeedback.TextColor3 = Color3.fromRGB(240, 244, 248)
		lobbyFeedback.TextWrapped = true
		lobbyFeedback.Text = "Lobby siap."
		lobbyFeedback.Parent = lobbyLayer
	end

	local playButton = lobbyLayer:FindFirstChild("PlayButton")
	if not playButton then
		playButton = Instance.new("TextButton")
		playButton.Name = "PlayButton"
		playButton.Visible = false
		playButton.Active = false
		playButton.Selectable = false
		playButton.ZIndex = 1
		playButton.AnchorPoint = Vector2.new(0.5, 1)
		playButton.Position = UDim2.fromScale(0.5, 0.92)
		playButton.BackgroundColor3 = Color3.fromRGB(45, 98, 72)
		playButton.TextColor3 = Color3.fromRGB(245, 245, 245)
		playButton.Font = Enum.Font.GothamBold
		playButton.Text = "PLAY"
		playButton.AutoButtonColor = true
		playButton.Parent = lobbyLayer
		self:_setSelectableStyle(playButton)

	end

	local matchMessage = matchLayer:FindFirstChild("StateMessage")
	if not matchMessage then
		matchMessage = Instance.new("TextLabel")
		matchMessage.Name = "StateMessage"
		matchMessage.BackgroundTransparency = 1
		matchMessage.Active = false
		matchMessage.Selectable = false
		matchMessage.ZIndex = 1
		matchMessage.AnchorPoint = Vector2.new(0.5, 0.5)
		matchMessage.Position = UDim2.fromScale(0.5, 0.5)
		matchMessage.Size = UDim2.new(0.8, 0, 0, 64)
		matchMessage.Font = Enum.Font.GothamBold
		matchMessage.TextColor3 = Color3.fromRGB(245, 245, 245)
		matchMessage.TextScaled = false
		matchMessage.Visible = false
		matchMessage.Parent = matchLayer
	end

	local objective = matchLayer:FindFirstChild("ObjectiveLabel")
	if not objective then
		objective = Instance.new("TextLabel")
		objective.Name = "ObjectiveLabel"
		objective.Active = false
		objective.Selectable = false
		objective.ZIndex = 1
		objective.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
		objective.BackgroundTransparency = 0.2
		objective.Position = UDim2.fromOffset(24, 24)
		objective.Size = UDim2.fromOffset(360, 54)
		objective.Font = Enum.Font.GothamSemibold
		objective.TextColor3 = Color3.fromRGB(235, 240, 245)
		objective.TextXAlignment = Enum.TextXAlignment.Left
		objective.TextWrapped = true
		objective.Visible = false
		objective.Parent = matchLayer
	end

	local overlay = matchLayer:FindFirstChild("HuntOverlay")
	if not overlay then
		overlay = Instance.new("Frame")
		overlay.Name = "HuntOverlay"
		overlay.Active = false
		overlay.Selectable = false
		overlay.ZIndex = 1
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.6
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.Visible = false
		overlay.Parent = matchLayer
	end

	local results = matchLayer:FindFirstChild("ResultsPanel")
	if not results then
		results = Instance.new("Frame")
		results.Name = "ResultsPanel"
		results.Active = true
		results.Selectable = true
		results.ZIndex = 3
		results.AnchorPoint = Vector2.new(0, 0)
		results.Position = UDim2.fromScale(0, 0)
		results.Size = UDim2.fromScale(1, 1)
		results.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
		results.BackgroundTransparency = 0.08
		results.Visible = false
		results.Parent = matchLayer

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = Color3.fromRGB(82, 96, 120)
		stroke.Parent = results
	end

	local resultsCard = results:FindFirstChild("ResultsCard")
	if not resultsCard then
		resultsCard = Instance.new("Frame")
		resultsCard.Name = "ResultsCard"
		resultsCard.AnchorPoint = Vector2.new(0.5, 0.5)
		resultsCard.Position = UDim2.fromScale(0.5, 0.52)
		resultsCard.Size = UDim2.new(0.74, 0, 0, 438)
		resultsCard.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
		resultsCard.BackgroundTransparency = 0.02
		resultsCard.BorderSizePixel = 0
		resultsCard.Parent = results

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 16)
		cardCorner.Parent = resultsCard

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Thickness = 1
		cardStroke.Color = Color3.fromRGB(82, 96, 120)
		cardStroke.Parent = resultsCard
	end

	local resultsTitle = resultsCard:FindFirstChild("ResultsTitle")
	if not resultsTitle then
		resultsTitle = Instance.new("TextLabel")
		resultsTitle.Name = "ResultsTitle"
		resultsTitle.Position = UDim2.fromOffset(20, 18)
		resultsTitle.Size = UDim2.new(1, -168, 0, 36)
		resultsTitle.BackgroundTransparency = 1
		resultsTitle.Text = "HASIL INVESTIGASI"
		resultsTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
		resultsTitle.TextXAlignment = Enum.TextXAlignment.Left
		resultsTitle.Font = Enum.Font.GothamBlack
		resultsTitle.TextSize = 28
		resultsTitle.Parent = resultsCard
	end

	local resultsStatus = resultsCard:FindFirstChild("ResultsStatus")
	if not resultsStatus then
		resultsStatus = Instance.new("TextLabel")
		resultsStatus.Name = "ResultsStatus"
		resultsStatus.Position = UDim2.fromOffset(20, 58)
		resultsStatus.Size = UDim2.fromOffset(132, 26)
		resultsStatus.BackgroundColor3 = Color3.fromRGB(50, 104, 72)
		resultsStatus.TextColor3 = Color3.fromRGB(245, 245, 245)
		resultsStatus.Text = "MISSION COMPLETE"
		resultsStatus.Font = Enum.Font.GothamBold
		resultsStatus.TextSize = 12
		resultsStatus.Parent = resultsCard

		local statusCorner = Instance.new("UICorner")
		statusCorner.CornerRadius = UDim.new(0, 999)
		statusCorner.Parent = resultsStatus
	end

	local resultsClose = resultsCard:FindFirstChild("ResultsCloseButton")
	if not resultsClose then
		resultsClose = Instance.new("TextButton")
		resultsClose.Name = "ResultsCloseButton"
		resultsClose.AnchorPoint = Vector2.new(1, 0)
		resultsClose.Position = UDim2.new(1, -20, 0, 18)
		resultsClose.Size = UDim2.fromOffset(112, 30)
		styleButton(resultsClose, "TUTUP HASIL")
		resultsClose.BackgroundColor3 = Color3.fromRGB(48, 60, 78)
		resultsClose.Parent = resultsCard
		self:_setSelectableStyle(resultsClose)
	end

	local resultsSubtitle = resultsCard:FindFirstChild("ResultsSubtitle")
	if not resultsSubtitle then
		resultsSubtitle = Instance.new("TextLabel")
		resultsSubtitle.Name = "ResultsSubtitle"
		resultsSubtitle.Position = UDim2.fromOffset(164, 58)
		resultsSubtitle.Size = UDim2.new(1, -184, 0, 26)
		resultsSubtitle.BackgroundTransparency = 1
		resultsSubtitle.Text = "Ghost: Unknown"
		resultsSubtitle.TextColor3 = Color3.fromRGB(196, 210, 228)
		resultsSubtitle.TextXAlignment = Enum.TextXAlignment.Left
		resultsSubtitle.Font = Enum.Font.GothamSemibold
		resultsSubtitle.TextSize = 16
		resultsSubtitle.Parent = resultsCard
	end

	local resultsSummary = resultsCard:FindFirstChild("ResultsSummary")
	if resultsSummary and not resultsSummary:IsA("ScrollingFrame") then
		resultsSummary:Destroy()
		resultsSummary = nil
	end
	if not resultsSummary then
		resultsSummary = Instance.new("ScrollingFrame")
		resultsSummary.Name = "ResultsSummary"
		resultsSummary.Position = UDim2.fromOffset(20, 96)
		resultsSummary.Size = UDim2.new(1, -40, 0, 244)
		resultsSummary.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
		resultsSummary.BackgroundTransparency = 0.06
		resultsSummary.BorderSizePixel = 0
		resultsSummary.ScrollBarThickness = 5
		resultsSummary.AutomaticCanvasSize = Enum.AutomaticSize.Y
		resultsSummary.CanvasSize = UDim2.fromOffset(0, 0)
		resultsSummary.ScrollingDirection = Enum.ScrollingDirection.Y
		resultsSummary.ElasticBehavior = Enum.ElasticBehavior.Never
		resultsSummary.ClipsDescendants = true
		resultsSummary.Parent = resultsCard

		local summaryCorner = Instance.new("UICorner")
		summaryCorner.CornerRadius = UDim.new(0, 10)
		summaryCorner.Parent = resultsSummary

		local summaryPadding = Instance.new("UIPadding")
		summaryPadding.PaddingTop = UDim.new(0, 10)
		summaryPadding.PaddingBottom = UDim.new(0, 10)
		summaryPadding.PaddingLeft = UDim.new(0, 10)
		summaryPadding.PaddingRight = UDim.new(0, 10)
		summaryPadding.Parent = resultsSummary

		local summaryLayout = Instance.new("UIListLayout")
		summaryLayout.FillDirection = Enum.FillDirection.Vertical
		summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
		summaryLayout.Padding = UDim.new(0, 6)
		summaryLayout.Parent = resultsSummary
	end

	local resultsFooter = resultsCard:FindFirstChild("ResultsFooter")
	if not resultsFooter then
		resultsFooter = Instance.new("TextLabel")
		resultsFooter.Name = "ResultsFooter"
		resultsFooter.Position = UDim2.fromOffset(20, 348)
		resultsFooter.Size = UDim2.new(1, -40, 0, 40)
		resultsFooter.BackgroundTransparency = 1
		resultsFooter.Text = "Ringkasan ini dibuat untuk test E2E. Tutup jika perlu melihat area sekitar."
		resultsFooter.TextColor3 = Color3.fromRGB(168, 182, 202)
		resultsFooter.TextWrapped = true
		resultsFooter.TextXAlignment = Enum.TextXAlignment.Left
		resultsFooter.TextYAlignment = Enum.TextYAlignment.Top
		resultsFooter.Font = Enum.Font.Gotham
		resultsFooter.TextSize = 13
		resultsFooter.Parent = resultsCard
	end

	local resultsLockHint = resultsCard:FindFirstChild("ResultsLockHint")
	if not resultsLockHint then
		resultsLockHint = Instance.new("TextLabel")
		resultsLockHint.Name = "ResultsLockHint"
		resultsLockHint.AnchorPoint = Vector2.new(0.5, 1)
		resultsLockHint.Position = UDim2.new(0.5, 0, 1, -18)
		resultsLockHint.Size = UDim2.new(1, -40, 0, 20)
		resultsLockHint.BackgroundTransparency = 1
		resultsLockHint.Text = "Hasil match dikunci beberapa detik..."
		resultsLockHint.TextColor3 = Color3.fromRGB(196, 210, 228)
		resultsLockHint.Font = Enum.Font.GothamSemibold
		resultsLockHint.TextSize = 13
		resultsLockHint.Parent = resultsCard
	end

	local function ensureResultSummaryValue(rowName, labelText)
		local row = resultsSummary:FindFirstChild(rowName)
		if row and row:IsA("Frame") then
			local value = row:FindFirstChild("Value")
			if value and value:IsA("TextLabel") then
				return value
			end
		end
		return createSummaryRow(resultsSummary, rowName, labelText)
	end

	local resultsSummaryRows = {
		status = ensureResultSummaryValue("StatusRow", "Status Misi"),
		ghostType = ensureResultSummaryValue("GhostRow", "Ghost"),
		correctGuess = ensureResultSummaryValue("GuessRow", "Tebakan"),
		evidenceCollected = ensureResultSummaryValue("EvidenceRow", "Evidence"),
		playersSurvived = ensureResultSummaryValue("SurvivedRow", "Pemain Selamat"),
		playersDead = ensureResultSummaryValue("DeadRow", "Pemain Mati"),
		matchDuration = ensureResultSummaryValue("DurationRow", "Durasi"),
		currencyReward = ensureResultSummaryValue("RewardRow", "Hadiah MM"),
		xpReward = ensureResultSummaryValue("XpRow", "Hadiah XP"),
	}

	if resultsClose:GetAttribute("Bound") ~= true then
		resultsClose:SetAttribute("Bound", true)
		connectButtonPress(resultsClose, function()
			if (self._resultsCloseUnlockAt or 0) > tick() then
				return
			end
			self:_setMatchWindowDismissed(true)
		end)
	end

	self._uxWidgets.lobby.FeedbackLabel = lobbyFeedback
	self._uxWidgets.lobby.PlayButton = playButton
	self._uxWidgets.lobby.Gui = lobbyUXGui
	self._uxWidgets.lobby.Layer = lobbyLayer
	self._uxWidgets.match.MessageLabel = matchMessage
	self._uxWidgets.match.ObjectiveLabel = objective
	self._uxWidgets.match.HuntOverlay = overlay
	self._uxWidgets.match.ResultsPanel = results
	self._uxWidgets.match.ResultsCard = resultsCard
	self._uxWidgets.match.ResultsTitle = resultsTitle
	self._uxWidgets.match.ResultsStatus = resultsStatus
	self._uxWidgets.match.ResultsSubtitle = resultsSubtitle
	self._uxWidgets.match.ResultsSummaryRows = resultsSummaryRows
	self._uxWidgets.match.ResultsFooter = resultsFooter
	self._uxWidgets.match.ResultsLockHint = resultsLockHint
	self._uxWidgets.match.ResultsCloseButton = resultsClose
	self._uxWidgets.match.Gui = matchUXGui
	self._uxWidgets.match.Layer = matchLayer

	self:_applyDeviceSizing()
	return true
end

function UISystem:_clearMatchUX()
	local match = self._uxWidgets.match
	if not match then
		return
	end

	if match.PulseConnection then
		match.PulseConnection:Disconnect()
		match.PulseConnection = nil
	end
	if match.PulseTween then
		match.PulseTween:Cancel()
		match.PulseTween = nil
	end

	if match.MessageLabel then
		match.MessageLabel.Visible = false
		match.MessageLabel.Text = ""
	end
	if match.ObjectiveLabel then
		match.ObjectiveLabel.Visible = false
		match.ObjectiveLabel.Text = ""
	end
	if match.HuntOverlay then
		match.HuntOverlay.Visible = false
		match.HuntOverlay.BackgroundTransparency = 0.6
	end
	if match.ResultsPanel then
		match.ResultsPanel.Visible = false
	end
	self:_clearUXInstances()
end

function UISystem:_startHuntPulse()
	local match = self._uxWidgets.match
	if not match or not match.HuntOverlay then
		return
	end

	local overlay = match.HuntOverlay
	overlay.Visible = true

	local function pulseTo(transparencyTarget)
		if self:GetState() ~= "Hunt" then
			return
		end
		match.PulseTween = TweenService:Create(overlay, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = transparencyTarget,
		})
		match.PulseTween:Play()

		match.PulseConnection = match.PulseTween.Completed:Connect(function()
			if match.PulseConnection then
				match.PulseConnection:Disconnect()
				match.PulseConnection = nil
			end
			pulseTo(transparencyTarget <= 0.45 and 0.72 or 0.45)
		end)
	end

	pulseTo(0.45)
end

function UISystem:TransitionTo(state, payload)
	if self._uxReady ~= true then
		return
	end
	self:SetState(state)
	self:_clearMatchUX()

	local match = self._uxWidgets.match
	if not match then
		return
	end

	if match.Gui then
		match.Gui.Enabled = (state == "Preparation" or state == "Hunt" or state == "Results")
	end
	if match.Layer then
		match.Layer.Visible = (state == "Preparation" or state == "Hunt" or state == "Results")
	end

	if state == "Preparation" then
		match.MessageLabel.Text = "Masuk ke lokasi..."
		match.MessageLabel.Visible = true
		fadeGuiObject(match.MessageLabel, 0, 0.2)
	elseif state == "Investigation" then
		match.ObjectiveLabel.Text = ""
		match.ObjectiveLabel.Visible = false
	elseif state == "Hunt" then
		self:_startHuntPulse()
	elseif state == "Results" then
		self:_startResultsCloseLock(payload)
		self:_renderResultsPanel(payload)
	end
	self:_refreshBasicMatchPanel(state, payload)
end

function UISystem:_handleMatchUXEvent(eventName, payload)
	if self._uxReady ~= true then
		return
	end
	if eventName == "MatchStarted" then
		return
	end
	if eventName == "PhaseChanged" then
		local resolvedPhase = resolvePhaseFromPayload(eventName, payload)
		if resolvedPhase == MATCH_PHASE.PREPARING or resolvedPhase == MATCH_PHASE.LOADING or resolvedPhase == MATCH_PHASE.BRIEFING then
			self:TransitionTo("Preparation", payload)
		elseif resolvedPhase == MATCH_PHASE.INGAME or resolvedPhase == MATCH_PHASE.ESCALATION then
			self:TransitionTo("Investigation", payload)
		elseif resolvedPhase == MATCH_PHASE.HUNT then
			self:TransitionTo("Hunt", payload)
		elseif resolvedPhase == MATCH_PHASE.RESULT or resolvedPhase == MATCH_PHASE.END then
			self:TransitionTo("Results", payload)
		end
		return
	end
	if eventName == "HuntStarted" or eventName == "GhostHuntStarted" then
		self:TransitionTo("Hunt", payload)
		return
	end
	if eventName == "HuntEnded" or eventName == "GhostHuntEnded" then
		self:TransitionTo("Investigation", payload)
		return
	end
	if eventName == "MatchEnded" or eventName == "MatchCompleted" then
		if payload and type(payload) == "table" then
			self._matchResult.ghostType = payload.ghostType or self._matchResult.ghostType
		end
		self:TransitionTo("Results", payload)
	end
end

function UISystem:_handleLobbyUXEvent(eventName, payload)
	if self._uxReady ~= true then
		return
	end
	local lobby = self._uxWidgets.lobby
	if not lobby or not lobby.FeedbackLabel then
		return
	end

	if eventName == "RoomUpdated" or eventName == "RoomStateUpdate" then
		local roomId = payload and payload.room and payload.room.roomId or payload and payload.roomId
		if roomId then
			lobby.FeedbackLabel.Text = "Room diperbarui: #" .. tostring(roomId)
		else
			lobby.FeedbackLabel.Text = "Room diperbarui."
		end
	elseif eventName == "RoomInviteSendResult" then
		if payload and payload.ok then
			local total = tonumber(payload.invitedCount or 0) or 0
			if payload.broadcast == true then
				lobby.FeedbackLabel.Text = "Broadcast invite terkirim (" .. tostring(total) .. ")"
			else
				lobby.FeedbackLabel.Text = "Invite terkirim."
			end
		else
			lobby.FeedbackLabel.Text = "Invite gagal: " .. tostring(payload and (payload.err or payload.reason) or "-")
		end
	elseif eventName == "RoomInviteAccepted" then
		lobby.FeedbackLabel.Text = tostring(payload and payload.byName or "Player") .. " menerima invite."
	elseif eventName == "RoomInviteDeclined" then
		lobby.FeedbackLabel.Text = tostring(payload and payload.byName or "Player") .. " menolak invite."
	elseif eventName == "RoomInviteExpired" then
		lobby.FeedbackLabel.Text = "Invite kadaluarsa."
	elseif eventName == "MatchStarting" or eventName == "RoomMatchStarting" then
		lobby.FeedbackLabel.Text = "Match akan dimulai..."
	elseif eventName == "LobbyFlexSpotlightUpdated" then
		local spotlight = payload and payload.spotlight or {}
		local spotlightName = spotlight.displayName or spotlight.playerName or "Player"
		local spotlightShow = spotlight.showcaseSummary or formatJoinedValues(spotlight.featuredNames, "koleksi lobby")
		lobby.FeedbackLabel.Text = string.format("Flex aktif: %s menampilkan %s", tostring(spotlightName), tostring(spotlightShow))
	elseif eventName == "LobbyFlexSpotlightCleared" then
		lobby.FeedbackLabel.Text = "Flex zone kembali idle."
	else
		lobby.FeedbackLabel.Text = "Lobby event: " .. tostring(eventName)
	end

	lobby.FeedbackLabel.Visible = false
	if lobby.PlayButton then
		lobby.PlayButton.Visible = false
	end
end

function UISystem:_hideRoomInvitePopup()
	if self._roomBrowserWidgets and self._roomBrowserWidgets.InvitePopup then
		self._roomBrowserWidgets.InvitePopup.Visible = false
	end
	self._activeInviteId = nil
end

function UISystem:_showRoomInvitePopup(payload)
	if type(payload) ~= "table" or not self._roomBrowserWidgets then
		return
	end
	local popup = self._roomBrowserWidgets.InvitePopup
	local textLabel = self._roomBrowserWidgets.InvitePopupText
	if not popup or not textLabel then
		return
	end
	local inviteId = tostring(payload.inviteId or "")
	if inviteId == "" then
		return
	end
	self._activeInviteId = inviteId
	local inviterName = tostring(payload.fromDisplayName or payload.fromName or "Host")
	local roomId = tostring(payload.roomId or "?")
	local modeText = tostring(payload.mode or "Classic")
	textLabel.Text = string.format("%s mengundang kamu ke Room #%s (%s)", inviterName, roomId, modeText)
	popup.Visible = true
	task.delay(5, function()
		if self._activeInviteId == inviteId then
			self:RoomBrowserRespondRoomInvite(inviteId, false)
			self:_hideRoomInvitePopup()
		end
	end)
end

function UISystem:_ensureBasicUIs()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	for _, guiName in ipairs(BASIC_GUI_NAMES) do
		local gui = playerGui:FindFirstChild(guiName)
		if not gui then
			gui = Instance.new("ScreenGui")
			gui.Name = guiName
			gui.ResetOnSpawn = false
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			gui.Parent = playerGui
		end
		local panel = gui:FindFirstChild("MainPanel")
		if not panel then
			panel = Instance.new("Frame")
			panel.Name = "MainPanel"
			panel.AnchorPoint = Vector2.new(1, 0)
			panel.Position = UDim2.new(1, -16, 0, 16)
			panel.Size = UDim2.fromOffset(260, 320)
			panel.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
			panel.BorderSizePixel = 0
			panel.Parent = gui

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = panel

			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.Position = UDim2.fromOffset(12, 10)
			title.Size = UDim2.fromOffset(236, 22)
			styleLabel(title, guiName, 16)
			title.Font = Enum.Font.GothamBold
			title.Parent = panel
		end

		if guiName == "LobbyUI" then
			panel.AnchorPoint = Vector2.new(0, 0)
			panel.Position = UDim2.fromOffset(16, 16)
			panel.Size = UDim2.fromOffset(340, 320)
			panel.BackgroundColor3 = Color3.fromRGB(18, 26, 34)
			panel.BackgroundTransparency = 0.08

			local title = panel:FindFirstChild("Title")
			if title and title:IsA("TextLabel") then
				title.Text = "LOBBY PANEL"
				title.TextColor3 = Color3.fromRGB(238, 243, 248)
				title.Size = UDim2.new(1, -24, 0, 24)
			end

			local statusBadge = panel:FindFirstChild("StatusBadge")
			if not statusBadge then
				statusBadge = Instance.new("TextLabel")
				statusBadge.Name = "StatusBadge"
				statusBadge.Position = UDim2.fromOffset(12, 42)
				statusBadge.Size = UDim2.fromOffset(108, 24)
				statusBadge.BackgroundColor3 = Color3.fromRGB(54, 116, 82)
				statusBadge.TextColor3 = Color3.fromRGB(245, 245, 245)
				statusBadge.Font = Enum.Font.GothamBold
				statusBadge.TextSize = 12
				statusBadge.Text = "LOBBY"
				statusBadge.Parent = panel

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 999)
				badgeCorner.Parent = statusBadge
			end

			local primaryLabel = panel:FindFirstChild("PrimaryLabel")
			if not primaryLabel then
				primaryLabel = Instance.new("TextLabel")
				primaryLabel.Name = "PrimaryLabel"
				primaryLabel.Position = UDim2.fromOffset(12, 76)
				primaryLabel.Size = UDim2.new(1, -24, 0, 40)
				primaryLabel.BackgroundTransparency = 1
				primaryLabel.Font = Enum.Font.GothamBold
				primaryLabel.TextSize = 16
				primaryLabel.TextColor3 = Color3.fromRGB(242, 246, 250)
				primaryLabel.TextWrapped = true
				primaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				primaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				primaryLabel.Text = "Buka Room Browser untuk mulai test flow lobby."
				primaryLabel.Parent = panel
			end

			local secondaryLabel = panel:FindFirstChild("SecondaryLabel")
			if not secondaryLabel then
				secondaryLabel = Instance.new("TextLabel")
				secondaryLabel.Name = "SecondaryLabel"
				secondaryLabel.Position = UDim2.fromOffset(12, 120)
				secondaryLabel.Size = UDim2.new(1, -24, 0, 32)
				secondaryLabel.BackgroundTransparency = 1
				secondaryLabel.Font = Enum.Font.Gotham
				secondaryLabel.TextSize = 13
				secondaryLabel.TextColor3 = Color3.fromRGB(182, 196, 216)
				secondaryLabel.TextWrapped = true
				secondaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				secondaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				secondaryLabel.Text = "Mode Classic | Map HauntedHouse | 0 room aktif"
				secondaryLabel.Parent = panel
			end

			local openRoomBrowserButton = panel:FindFirstChild("OpenRoomBrowserButton")
			if not openRoomBrowserButton then
				openRoomBrowserButton = Instance.new("TextButton")
				openRoomBrowserButton.Name = "OpenRoomBrowserButton"
				openRoomBrowserButton.Position = UDim2.fromOffset(12, 162)
				openRoomBrowserButton.Size = UDim2.new(1, -24, 0, 42)
				styleButton(openRoomBrowserButton, "OPEN ROOM BROWSER")
				openRoomBrowserButton.BackgroundColor3 = Color3.fromRGB(46, 78, 114)
				openRoomBrowserButton.Parent = panel
				self:_setSelectableStyle(openRoomBrowserButton)
			end

			local menuButton = panel:FindFirstChild("MenuButton")
			if not menuButton then
				menuButton = Instance.new("TextButton")
				menuButton.Name = "MenuButton"
				menuButton.Position = UDim2.fromOffset(12, 258)
				menuButton.Size = UDim2.fromOffset(152, 36)
				styleButton(menuButton, "MENU")
				menuButton.BackgroundColor3 = Color3.fromRGB(58, 66, 84)
				menuButton.Parent = panel
				self:_setSelectableStyle(menuButton)
			end

			local rankButton = panel:FindFirstChild("RankButton")
			if not rankButton then
				rankButton = Instance.new("TextButton")
				rankButton.Name = "RankButton"
				rankButton.Position = UDim2.fromOffset(176, 258)
				rankButton.Size = UDim2.fromOffset(152, 36)
				styleButton(rankButton, "RANK")
				rankButton.BackgroundColor3 = Color3.fromRGB(74, 82, 58)
				rankButton.Parent = panel
				self:_setSelectableStyle(rankButton)
			end

			local profileButton = panel:FindFirstChild("ProfileButton")
			if not profileButton then
				profileButton = Instance.new("TextButton")
				profileButton.Name = "ProfileButton"
				profileButton.Position = UDim2.fromOffset(12, 212)
				profileButton.Size = UDim2.fromOffset(152, 36)
				styleButton(profileButton, "PROFILE")
				profileButton.BackgroundColor3 = Color3.fromRGB(62, 88, 66)
				profileButton.Parent = panel
				self:_setSelectableStyle(profileButton)
			end

			local shopButton = panel:FindFirstChild("ShopButton")
			if not shopButton then
				shopButton = Instance.new("TextButton")
				shopButton.Name = "ShopButton"
				shopButton.Position = UDim2.fromOffset(176, 212)
				shopButton.Size = UDim2.fromOffset(152, 36)
				styleButton(shopButton, "SHOP")
				shopButton.BackgroundColor3 = Color3.fromRGB(108, 82, 48)
				shopButton.Parent = panel
				self:_setSelectableStyle(shopButton)
			end

			local hintLabel = panel:FindFirstChild("HintLabel")
			if not hintLabel then
				hintLabel = Instance.new("TextLabel")
				hintLabel.Name = "HintLabel"
				hintLabel.Position = UDim2.fromOffset(12, 300)
				hintLabel.Size = UDim2.new(1, -24, 0, 16)
				hintLabel.BackgroundTransparency = 1
				hintLabel.Font = Enum.Font.Gotham
				hintLabel.TextSize = 11
				hintLabel.TextColor3 = Color3.fromRGB(156, 170, 192)
				hintLabel.TextWrapped = true
				hintLabel.TextXAlignment = Enum.TextXAlignment.Left
				hintLabel.Text = "Shortcut: tekan M untuk Room Browser."
				hintLabel.Parent = panel
			end

			local toggleBtn = gui:FindFirstChild("LobbyToggleButton")
			if not toggleBtn then
				toggleBtn = Instance.new("TextButton")
				toggleBtn.Name = "LobbyToggleButton"
				toggleBtn.AnchorPoint = Vector2.new(1, 0)
				toggleBtn.Position = UDim2.fromOffset(12, 120)
				toggleBtn.Size = UDim2.fromOffset(28, 78)
				styleButton(toggleBtn, ">")
				toggleBtn.BackgroundColor3 = Color3.fromRGB(44, 60, 82)
				toggleBtn.Parent = gui

				local toggleCorner = Instance.new("UICorner")
				toggleCorner.CornerRadius = UDim.new(0, 10)
				toggleCorner.Parent = toggleBtn

				self:_setSelectableStyle(toggleBtn)
			end

			if openRoomBrowserButton:GetAttribute("Bound") ~= true then
				openRoomBrowserButton:SetAttribute("Bound", true)
				connectButtonPress(openRoomBrowserButton, function()
					self:_toggleRoomBrowserVisible()
					self:_refreshBasicLobbyPanel()
				end)
			end
			if menuButton:GetAttribute("Bound") ~= true then
				menuButton:SetAttribute("Bound", true)
				connectButtonPress(menuButton, function()
					self:_toggleBasicWindow("MainMenuUI")
				end)
			end
			if profileButton:GetAttribute("Bound") ~= true then
				profileButton:SetAttribute("Bound", true)
				connectButtonPress(profileButton, function()
					self:_toggleAuxiliaryWindow("ProfileUI")
				end)
			end
			if shopButton:GetAttribute("Bound") ~= true then
				shopButton:SetAttribute("Bound", true)
				connectButtonPress(shopButton, function()
					self:_toggleAuxiliaryWindow("ShopUI")
				end)
			end
			if rankButton:GetAttribute("Bound") ~= true then
				rankButton:SetAttribute("Bound", true)
				connectButtonPress(rankButton, function()
					self:_toggleBasicWindow("LeaderboardUI")
				end)
			end
			if toggleBtn:GetAttribute("Bound") ~= true then
				toggleBtn:SetAttribute("Bound", true)
				connectButtonPress(toggleBtn, function()
					self:_toggleLobbyPanelCollapsed()
				end)
			end

			self._uxWidgets.lobby.BasicGui = gui
			self._uxWidgets.lobby.BasicPanel = panel
			self._uxWidgets.lobby.BasicTitle = title
			self._uxWidgets.lobby.BasicStatusBadge = statusBadge
			self._uxWidgets.lobby.BasicPrimaryLabel = primaryLabel
			self._uxWidgets.lobby.BasicSecondaryLabel = secondaryLabel
			self._uxWidgets.lobby.BasicHintLabel = hintLabel
			self._uxWidgets.lobby.BasicOpenRoomBrowserButton = openRoomBrowserButton
			self._uxWidgets.lobby.BasicProfileButton = profileButton
			self._uxWidgets.lobby.BasicShopButton = shopButton
			self._uxWidgets.lobby.BasicMenuButton = menuButton
			self._uxWidgets.lobby.BasicRankButton = rankButton
			self._uxWidgets.lobby.ToggleButton = toggleBtn
		end

		local auxiliaryConfig = AUXILIARY_WINDOW_CONFIG[guiName]
		if auxiliaryConfig then
			panel.AnchorPoint = auxiliaryConfig.panelAnchorPoint
			panel.Position = auxiliaryConfig.panelPosition
			panel.Size = UDim2.fromOffset(auxiliaryConfig.panelSize.X, auxiliaryConfig.panelSize.Y)
			panel.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
			panel.BackgroundTransparency = 0.08

			local title = panel:FindFirstChild("Title")
			if title and title:IsA("TextLabel") then
				title.Text = auxiliaryConfig.title
				title.TextColor3 = Color3.fromRGB(238, 243, 248)
				title.Size = UDim2.new(1, -54, 0, 24)
			end

			local closeBtn = panel:FindFirstChild("CloseButton")
			if not closeBtn then
				closeBtn = Instance.new("TextButton")
				closeBtn.Name = "CloseButton"
				closeBtn.AnchorPoint = Vector2.new(1, 0)
				closeBtn.Position = UDim2.new(1, -10, 0, 8)
				closeBtn.Size = UDim2.fromOffset(28, 28)
				styleButton(closeBtn, "X")
				closeBtn.BackgroundColor3 = Color3.fromRGB(92, 42, 42)
				closeBtn.Parent = panel

				local closeCorner = Instance.new("UICorner")
				closeCorner.CornerRadius = UDim.new(1, 0)
				closeCorner.Parent = closeBtn

				self:_setSelectableStyle(closeBtn)
			end

			local statusBadge = panel:FindFirstChild("StatusBadge")
			if not statusBadge then
				statusBadge = Instance.new("TextLabel")
				statusBadge.Name = "StatusBadge"
				statusBadge.Position = UDim2.fromOffset(12, 42)
				statusBadge.Size = UDim2.fromOffset(128, 24)
				statusBadge.BackgroundColor3 = auxiliaryConfig.badgeColor
				statusBadge.TextColor3 = Color3.fromRGB(245, 245, 245)
				statusBadge.Font = Enum.Font.GothamBold
				statusBadge.TextSize = 12
				statusBadge.Text = auxiliaryConfig.badgeText
				statusBadge.Parent = panel

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 999)
				badgeCorner.Parent = statusBadge
			end

			local primaryLabel = panel:FindFirstChild("PrimaryLabel")
			if not primaryLabel then
				primaryLabel = Instance.new("TextLabel")
				primaryLabel.Name = "PrimaryLabel"
				primaryLabel.Position = UDim2.fromOffset(12, 76)
				primaryLabel.Size = UDim2.new(1, -24, 0, 38)
				primaryLabel.BackgroundTransparency = 1
				primaryLabel.Font = Enum.Font.GothamBold
				primaryLabel.TextSize = 16
				primaryLabel.TextColor3 = Color3.fromRGB(242, 246, 250)
				primaryLabel.TextWrapped = true
				primaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				primaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				primaryLabel.Text = auxiliaryConfig.title
				primaryLabel.Parent = panel
			end

			local secondaryLabel = panel:FindFirstChild("SecondaryLabel")
			if not secondaryLabel then
				secondaryLabel = Instance.new("TextLabel")
				secondaryLabel.Name = "SecondaryLabel"
				secondaryLabel.Position = UDim2.fromOffset(12, 118)
				secondaryLabel.Size = UDim2.new(1, -24, 0, 34)
				secondaryLabel.BackgroundTransparency = 1
				secondaryLabel.Font = Enum.Font.Gotham
				secondaryLabel.TextSize = 13
				secondaryLabel.TextColor3 = Color3.fromRGB(182, 196, 216)
				secondaryLabel.TextWrapped = true
				secondaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				secondaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				secondaryLabel.Text = auxiliaryConfig.footer
				secondaryLabel.Parent = panel
			end

			local contentFrame = panel:FindFirstChild("ContentFrame")
			if contentFrame and not contentFrame:IsA("ScrollingFrame") then
				contentFrame:Destroy()
				contentFrame = nil
			end
			if not contentFrame then
				contentFrame = Instance.new("ScrollingFrame")
				contentFrame.Name = "ContentFrame"
				contentFrame.Position = UDim2.fromOffset(12, 156)
				contentFrame.Size = UDim2.new(1, -24, 1, -214)
				contentFrame.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
				contentFrame.BackgroundTransparency = 0.06
				contentFrame.BorderSizePixel = 0
				contentFrame.ScrollBarThickness = 5
				contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
				contentFrame.CanvasSize = UDim2.fromOffset(0, 0)
				contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
				contentFrame.ElasticBehavior = Enum.ElasticBehavior.Never
				contentFrame.Parent = panel

				local contentCorner = Instance.new("UICorner")
				contentCorner.CornerRadius = UDim.new(0, 10)
				contentCorner.Parent = contentFrame

				local contentPadding = Instance.new("UIPadding")
				contentPadding.PaddingTop = UDim.new(0, 10)
				contentPadding.PaddingBottom = UDim.new(0, 10)
				contentPadding.PaddingLeft = UDim.new(0, 10)
				contentPadding.PaddingRight = UDim.new(0, 10)
				contentPadding.Parent = contentFrame
			end

			local contentText = contentFrame:FindFirstChild("ContentText")
			if not contentText then
				contentText = Instance.new("TextLabel")
				contentText.Name = "ContentText"
				contentText.Size = UDim2.new(1, -4, 0, 0)
				contentText.BackgroundTransparency = 1
				contentText.AutomaticSize = Enum.AutomaticSize.Y
				contentText.Font = Enum.Font.Gotham
				contentText.TextSize = 12
				contentText.TextColor3 = Color3.fromRGB(226, 234, 244)
				contentText.TextWrapped = true
				contentText.TextXAlignment = Enum.TextXAlignment.Left
				contentText.TextYAlignment = Enum.TextYAlignment.Top
				contentText.Text = ""
				contentText.Parent = contentFrame
			end

			local footerLabel = panel:FindFirstChild("FooterLabel")
			if not footerLabel then
				footerLabel = Instance.new("TextLabel")
				footerLabel.Name = "FooterLabel"
				footerLabel.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 48)
				footerLabel.Size = UDim2.new(1, -24, 0, 36)
				footerLabel.BackgroundTransparency = 1
				footerLabel.Font = Enum.Font.Gotham
				footerLabel.TextSize = 11
				footerLabel.TextColor3 = Color3.fromRGB(162, 176, 198)
				footerLabel.TextWrapped = true
				footerLabel.TextXAlignment = Enum.TextXAlignment.Left
				footerLabel.TextYAlignment = Enum.TextYAlignment.Top
				footerLabel.Text = auxiliaryConfig.footer
				footerLabel.Parent = panel
			else
				footerLabel.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 48)
				footerLabel.Size = UDim2.new(1, -24, 0, 36)
			end

			local toolActionButton = nil
			local toolStatusLabel = nil
			if guiName == "JournalUI" then
				contentFrame.Position = UDim2.fromOffset(12, 156)
				contentFrame.Size = UDim2.new(1, -24, 1, -268)

				toolActionButton = panel:FindFirstChild("ToolActionButton")
				if not toolActionButton then
					toolActionButton = Instance.new("TextButton")
					toolActionButton.Name = "ToolActionButton"
					toolActionButton.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 106)
					toolActionButton.Size = UDim2.fromOffset(148, 38)
					styleButton(toolActionButton, "SCAN JEJAK")
					toolActionButton.BackgroundColor3 = Color3.fromRGB(56, 92, 128)
					toolActionButton.Parent = panel

					local toolCorner = Instance.new("UICorner")
					toolCorner.CornerRadius = UDim.new(0, 8)
					toolCorner.Parent = toolActionButton

					self:_setSelectableStyle(toolActionButton)
				end

				toolStatusLabel = panel:FindFirstChild("ToolStatusLabel")
				if not toolStatusLabel then
					toolStatusLabel = Instance.new("TextLabel")
					toolStatusLabel.Name = "ToolStatusLabel"
					toolStatusLabel.Position = UDim2.fromOffset(172, auxiliaryConfig.panelSize.Y - 110)
					toolStatusLabel.Size = UDim2.new(1, -184, 0, 46)
					toolStatusLabel.BackgroundTransparency = 1
					toolStatusLabel.Font = Enum.Font.Gotham
					toolStatusLabel.TextSize = 11
					toolStatusLabel.TextColor3 = Color3.fromRGB(178, 192, 214)
					toolStatusLabel.TextWrapped = true
					toolStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
					toolStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
					toolStatusLabel.Text = "SCAN STATUS"
					toolStatusLabel.Parent = panel
				end

				footerLabel.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 54)
				footerLabel.Size = UDim2.new(1, -24, 0, 40)
			end

			local floatName = guiName .. "FloatButton"
			local floatBtn = gui:FindFirstChild(floatName)
			if not floatBtn then
				floatBtn = Instance.new("TextButton")
				floatBtn.Name = floatName
				floatBtn.AnchorPoint = Vector2.new(0.5, 0.5)
				floatBtn.Position = auxiliaryConfig.floatPosition
				floatBtn.Size = UDim2.fromOffset(62, 62)
				floatBtn.BackgroundColor3 = Color3.fromRGB(34, 46, 62)
				floatBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
				floatBtn.Font = Enum.Font.GothamBold
				floatBtn.TextSize = 12
				floatBtn.TextWrapped = true
				floatBtn.Text = auxiliaryConfig.floatText
				floatBtn.Visible = false
				floatBtn.Parent = gui

				local floatCorner = Instance.new("UICorner")
				floatCorner.CornerRadius = UDim.new(1, 0)
				floatCorner.Parent = floatBtn

				local floatStroke = Instance.new("UIStroke")
				floatStroke.Thickness = 2
				floatStroke.Color = auxiliaryConfig.badgeColor
				floatStroke.Parent = floatBtn

				self:_setSelectableStyle(floatBtn)
			end
			makeFloatingButtonDraggable(floatBtn)

			local itemRows = nil
			if guiName == "ShopUI" then
				contentText.Visible = false
				local itemList = contentFrame:FindFirstChild("ItemList")
				if itemList and not itemList:IsA("Frame") then
					itemList:Destroy()
					itemList = nil
				end
				if not itemList then
					itemList = Instance.new("Frame")
					itemList.Name = "ItemList"
					itemList.Size = UDim2.new(1, -4, 0, 0)
					itemList.BackgroundTransparency = 1
					itemList.AutomaticSize = Enum.AutomaticSize.Y
					itemList.Parent = contentFrame

					local itemLayout = Instance.new("UIListLayout")
					itemLayout.FillDirection = Enum.FillDirection.Vertical
					itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
					itemLayout.Padding = UDim.new(0, 6)
					itemLayout.Parent = itemList
				end
				itemRows = {}
				local displayCount = math.min(#self._shopState.catalog, 10)
				for index = 1, displayCount do
					local existing = itemList:FindFirstChild("ItemRow" .. tostring(index))
					if existing then
						existing:Destroy()
					end
					local row = createActionRow(itemList, "ItemRow" .. tostring(index), "ITEM", "-", "BELI")
					self:_setSelectableStyle(row.Button)
					local item = self._shopState.catalog[index]
					if item then
						row.Title.Text = tostring(item.name or item.id or ("Item " .. tostring(index)))
						row.Meta.Text = string.format(
							"%s | %s | %s MM",
							tostring(item.category or "Item"),
							tostring(item.rarityLabel or item.rarity or "R1"),
							tostring(item.price or 0)
						)
					end
					if row.Button:GetAttribute("Bound") ~= true then
						row.Button:SetAttribute("Bound", true)
						connectButtonPress(row.Button, function()
							local catalogItem = self._shopState.catalog[index]
							if catalogItem then
								self:_requestShopPurchase(catalogItem.id)
							end
						end)
					end
					table.insert(itemRows, row)
				end
			end

			if closeBtn:GetAttribute("Bound") ~= true then
				closeBtn:SetAttribute("Bound", true)
				connectButtonPress(closeBtn, function()
					self:_setAuxiliaryWindowDismissed(guiName, true)
				end)
			end
			if floatBtn:GetAttribute("Bound") ~= true then
				floatBtn:SetAttribute("Bound", true)
				connectButtonPress(floatBtn, function()
					self:_setAuxiliaryWindowDismissed(guiName, false)
				end)
			end
			if toolActionButton and toolActionButton:GetAttribute("Bound") ~= true then
				toolActionButton:SetAttribute("Bound", true)
				connectButtonPress(toolActionButton, function()
					self:_triggerJournalToolScan()
				end)
			end

			self._uxWidgets.windows[guiName] = {
				Gui = gui,
				Panel = panel,
				Title = title,
				StatusBadge = statusBadge,
				PrimaryLabel = primaryLabel,
				SecondaryLabel = secondaryLabel,
				ContentFrame = contentFrame,
				ContentText = contentText,
				FooterLabel = footerLabel,
				FloatButton = floatBtn,
				CloseButton = closeBtn,
				ItemRows = itemRows,
				ToolActionButton = toolActionButton,
				ToolStatusLabel = toolStatusLabel,
			}
		end

		if guiName == "MatchUI" then
			panel.Size = UDim2.fromOffset(340, 454)
			panel.Position = UDim2.new(1, -16, 0, 16)
			panel.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
			panel.BackgroundTransparency = 0.1

			local title = panel:FindFirstChild("Title")
			if title and title:IsA("TextLabel") then
				title.Text = "PANEL MATCH"
				title.TextColor3 = Color3.fromRGB(235, 240, 245)
				title.Size = UDim2.new(1, -54, 0, 24)
			end

			local closeBtn = panel:FindFirstChild("CloseButton")
			if not closeBtn then
				closeBtn = Instance.new("TextButton")
				closeBtn.Name = "CloseButton"
				closeBtn.AnchorPoint = Vector2.new(1, 0)
				closeBtn.Position = UDim2.new(1, -10, 0, 8)
				closeBtn.Size = UDim2.fromOffset(28, 28)
				styleButton(closeBtn, "X")
				closeBtn.BackgroundColor3 = Color3.fromRGB(92, 42, 42)
				closeBtn.Parent = panel

				local closeCorner = Instance.new("UICorner")
				closeCorner.CornerRadius = UDim.new(1, 0)
				closeCorner.Parent = closeBtn

				self:_setSelectableStyle(closeBtn)
			end

			local stateBadge = panel:FindFirstChild("StateBadge")
			if not stateBadge then
				stateBadge = Instance.new("TextLabel")
				stateBadge.Name = "StateBadge"
				stateBadge.Position = UDim2.fromOffset(12, 42)
				stateBadge.Size = UDim2.fromOffset(136, 24)
				stateBadge.BackgroundColor3 = Color3.fromRGB(62, 80, 104)
				stateBadge.TextColor3 = Color3.fromRGB(245, 245, 245)
				stateBadge.Font = Enum.Font.GothamBold
				stateBadge.TextSize = 12
				stateBadge.Text = "STATUS MATCH"
				stateBadge.Parent = panel

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 999)
				badgeCorner.Parent = stateBadge
			end

			local primaryLabel = panel:FindFirstChild("PrimaryLabel")
			if not primaryLabel then
				primaryLabel = Instance.new("TextLabel")
				primaryLabel.Name = "PrimaryLabel"
				primaryLabel.Position = UDim2.fromOffset(12, 76)
				primaryLabel.Size = UDim2.new(1, -24, 0, 34)
				primaryLabel.BackgroundTransparency = 1
				primaryLabel.Font = Enum.Font.GothamBold
				primaryLabel.TextSize = 18
				primaryLabel.TextColor3 = Color3.fromRGB(242, 246, 250)
				primaryLabel.TextWrapped = true
				primaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				primaryLabel.Text = "Menunggu event match."
				primaryLabel.Parent = panel
			end

			local secondaryLabel = panel:FindFirstChild("SecondaryLabel")
			if not secondaryLabel then
				secondaryLabel = Instance.new("TextLabel")
				secondaryLabel.Name = "SecondaryLabel"
				secondaryLabel.Position = UDim2.fromOffset(12, 114)
				secondaryLabel.Size = UDim2.new(1, -24, 0, 48)
				secondaryLabel.BackgroundTransparency = 1
				secondaryLabel.Font = Enum.Font.Gotham
				secondaryLabel.TextSize = 14
				secondaryLabel.TextColor3 = Color3.fromRGB(182, 196, 216)
				secondaryLabel.TextWrapped = true
				secondaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				secondaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				secondaryLabel.Text = "Panel ini bisa ditutup jika menghalangi pandangan."
				secondaryLabel.Parent = panel
			end

			local summaryFrame = panel:FindFirstChild("SummaryFrame")
			if summaryFrame and not summaryFrame:IsA("ScrollingFrame") then
				summaryFrame:Destroy()
				summaryFrame = nil
			end
			if not summaryFrame then
				summaryFrame = Instance.new("ScrollingFrame")
				summaryFrame.Name = "SummaryFrame"
				summaryFrame.Position = UDim2.fromOffset(12, 168)
				summaryFrame.Size = UDim2.new(1, -24, 0, 220)
				summaryFrame.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
				summaryFrame.BackgroundTransparency = 0.06
				summaryFrame.BorderSizePixel = 0
				summaryFrame.ScrollBarThickness = 5
				summaryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
				summaryFrame.CanvasSize = UDim2.fromOffset(0, 0)
				summaryFrame.ScrollingDirection = Enum.ScrollingDirection.Y
				summaryFrame.ElasticBehavior = Enum.ElasticBehavior.Never
				summaryFrame.ClipsDescendants = true
				summaryFrame.Parent = panel

				local summaryCorner = Instance.new("UICorner")
				summaryCorner.CornerRadius = UDim.new(0, 10)
				summaryCorner.Parent = summaryFrame

				local summaryPadding = Instance.new("UIPadding")
				summaryPadding.PaddingTop = UDim.new(0, 10)
				summaryPadding.PaddingBottom = UDim.new(0, 10)
				summaryPadding.PaddingLeft = UDim.new(0, 10)
				summaryPadding.PaddingRight = UDim.new(0, 10)
				summaryPadding.Parent = summaryFrame

				local summaryLayout = Instance.new("UIListLayout")
				summaryLayout.FillDirection = Enum.FillDirection.Vertical
				summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
				summaryLayout.Padding = UDim.new(0, 6)
				summaryLayout.Parent = summaryFrame
			end

			local hideBtn = panel:FindFirstChild("HideButton")
			if not hideBtn then
				hideBtn = Instance.new("TextButton")
				hideBtn.Name = "HideButton"
				hideBtn.Position = UDim2.fromOffset(12, 396)
				hideBtn.Size = UDim2.fromOffset(144, 40)
				styleButton(hideBtn, "SEMBUNYIKAN")
				hideBtn.BackgroundColor3 = Color3.fromRGB(44, 58, 76)
				hideBtn.Parent = panel
				self:_setSelectableStyle(hideBtn)
			end

			local footerLabel = panel:FindFirstChild("FooterLabel")
			if not footerLabel then
				footerLabel = Instance.new("TextLabel")
				footerLabel.Name = "FooterLabel"
				footerLabel.Position = UDim2.fromOffset(166, 396)
				footerLabel.Size = UDim2.new(1, -178, 0, 40)
				footerLabel.BackgroundTransparency = 1
				footerLabel.Font = Enum.Font.Gotham
				footerLabel.TextSize = 12
				footerLabel.TextColor3 = Color3.fromRGB(162, 176, 198)
				footerLabel.TextWrapped = true
				footerLabel.TextXAlignment = Enum.TextXAlignment.Left
				footerLabel.TextYAlignment = Enum.TextYAlignment.Top
				footerLabel.Text = CLOSE_HINT_TEXT
				footerLabel.Parent = panel
			end

			local timerLabel = gui:FindFirstChild("MatchTimerLabel")
			if not timerLabel then
				timerLabel = Instance.new("TextLabel")
				timerLabel.Name = "MatchTimerLabel"
				timerLabel.AnchorPoint = Vector2.new(0.5, 0)
				timerLabel.Position = UDim2.new(0.5, 0, 0, 18)
				timerLabel.Size = UDim2.fromOffset(126, 40)
				timerLabel.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
				timerLabel.BackgroundTransparency = 0.1
				timerLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
				timerLabel.Font = Enum.Font.GothamBold
				timerLabel.TextSize = 24
				timerLabel.Text = "00:00"
				timerLabel.Visible = false
				timerLabel.Parent = gui

				local timerCorner = Instance.new("UICorner")
				timerCorner.CornerRadius = UDim.new(0, 12)
				timerCorner.Parent = timerLabel
			end

			local timerCaption = gui:FindFirstChild("MatchTimerCaption")
			if not timerCaption then
				timerCaption = Instance.new("TextLabel")
				timerCaption.Name = "MatchTimerCaption"
				timerCaption.AnchorPoint = Vector2.new(0.5, 0)
				timerCaption.Position = UDim2.new(0.5, 0, 0, 60)
				timerCaption.Size = UDim2.fromOffset(170, 18)
				timerCaption.BackgroundTransparency = 1
				timerCaption.TextColor3 = Color3.fromRGB(190, 204, 224)
				timerCaption.Font = Enum.Font.GothamSemibold
				timerCaption.TextSize = 11
				timerCaption.Text = "PHASE TIMER"
				timerCaption.Visible = false
				timerCaption.Parent = gui
			end

			local evidenceQuickButton = gui:FindFirstChild("EvidenceQuickButton")
			if not evidenceQuickButton then
				evidenceQuickButton = Instance.new("TextButton")
				evidenceQuickButton.Name = "EvidenceQuickButton"
				evidenceQuickButton.AnchorPoint = Vector2.new(1, 1)
				evidenceQuickButton.Position = UDim2.new(1, -18, 1, -18)
				evidenceQuickButton.Size = UDim2.fromOffset(142, 48)
				styleButton(evidenceQuickButton, "EVIDENCE [J]")
				evidenceQuickButton.BackgroundColor3 = Color3.fromRGB(52, 82, 118)
				evidenceQuickButton.Visible = false
				evidenceQuickButton.Parent = gui

				local evidenceCorner = Instance.new("UICorner")
				evidenceCorner.CornerRadius = UDim.new(0, 10)
				evidenceCorner.Parent = evidenceQuickButton

				self:_setSelectableStyle(evidenceQuickButton)
			end

			local controlsHintBar = gui:FindFirstChild("ControlsHintBar")
			if not controlsHintBar then
				controlsHintBar = Instance.new("Frame")
				controlsHintBar.Name = "ControlsHintBar"
				controlsHintBar.AnchorPoint = Vector2.new(0.5, 1)
				controlsHintBar.Position = UDim2.new(0.5, 0, 1, -14)
				controlsHintBar.Size = UDim2.fromOffset(620, 34)
				controlsHintBar.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
				controlsHintBar.BackgroundTransparency = 0.12
				controlsHintBar.Visible = false
				controlsHintBar.Parent = gui

				local hintCorner = Instance.new("UICorner")
				hintCorner.CornerRadius = UDim.new(0, 10)
				hintCorner.Parent = controlsHintBar
			end

			local controlsHintLabel = controlsHintBar:FindFirstChild("Label")
			if not controlsHintLabel then
				controlsHintLabel = Instance.new("TextLabel")
				controlsHintLabel.Name = "Label"
				controlsHintLabel.Position = UDim2.fromOffset(10, 0)
				controlsHintLabel.Size = UDim2.new(1, -20, 1, 0)
				controlsHintLabel.BackgroundTransparency = 1
				controlsHintLabel.Font = Enum.Font.GothamSemibold
				controlsHintLabel.TextSize = 12
				controlsHintLabel.TextColor3 = Color3.fromRGB(224, 232, 242)
				controlsHintLabel.TextXAlignment = Enum.TextXAlignment.Center
				controlsHintLabel.Text = self._matchControlsHintText
				controlsHintLabel.Parent = controlsHintBar
			end

			local floatBtn = gui:FindFirstChild("MatchFloatButton")
			if not floatBtn then
				floatBtn = Instance.new("TextButton")
				floatBtn.Name = "MatchFloatButton"
				floatBtn.AnchorPoint = Vector2.new(1, 0.5)
				floatBtn.Position = UDim2.new(1, -18, 0.58, 0)
				floatBtn.Size = UDim2.fromOffset(62, 62)
				floatBtn.BackgroundColor3 = Color3.fromRGB(34, 46, 62)
				floatBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
				floatBtn.Font = Enum.Font.GothamBold
				floatBtn.TextSize = 12
				floatBtn.TextWrapped = true
				floatBtn.Text = "MATCH"
				floatBtn.Visible = false
				floatBtn.Parent = gui

				local floatCorner = Instance.new("UICorner")
				floatCorner.CornerRadius = UDim.new(1, 0)
				floatCorner.Parent = floatBtn

				local floatStroke = Instance.new("UIStroke")
				floatStroke.Thickness = 2
				floatStroke.Color = Color3.fromRGB(98, 122, 154)
				floatStroke.Parent = floatBtn

				self:_setSelectableStyle(floatBtn)
			end
			makeFloatingButtonDraggable(floatBtn)

			local function ensureSummaryValue(rowName, labelText)
				local row = summaryFrame:FindFirstChild(rowName)
				if row and row:IsA("Frame") then
					local value = row:FindFirstChild("Value")
					if value and value:IsA("TextLabel") then
						return value
					end
				end
				return createSummaryRow(summaryFrame, rowName, labelText)
			end

			local summaryRows = {
				status = ensureSummaryValue("StatusRow", "Status Misi"),
				ghostType = ensureSummaryValue("GhostRow", "Ghost"),
				correctGuess = ensureSummaryValue("GuessRow", "Tebakan"),
				evidenceCollected = ensureSummaryValue("EvidenceRow", "Evidence"),
				playersSurvived = ensureSummaryValue("SurvivedRow", "Pemain Selamat"),
				playersDead = ensureSummaryValue("DeadRow", "Pemain Mati"),
				matchDuration = ensureSummaryValue("DurationRow", "Durasi"),
				currencyReward = ensureSummaryValue("RewardRow", "Hadiah MM"),
				xpReward = ensureSummaryValue("XpRow", "Hadiah XP"),
			}

			if closeBtn:GetAttribute("Bound") ~= true then
				closeBtn:SetAttribute("Bound", true)
				connectButtonPress(closeBtn, function()
					self:_setMatchWindowDismissed(true)
				end)
			end
			if hideBtn:GetAttribute("Bound") ~= true then
				hideBtn:SetAttribute("Bound", true)
				connectButtonPress(hideBtn, function()
					self:_setMatchWindowDismissed(true)
				end)
			end
			if floatBtn:GetAttribute("Bound") ~= true then
				floatBtn:SetAttribute("Bound", true)
				connectButtonPress(floatBtn, function()
					self:_setMatchWindowDismissed(false)
				end)
			end
			if evidenceQuickButton:GetAttribute("Bound") ~= true then
				evidenceQuickButton:SetAttribute("Bound", true)
				connectButtonPress(evidenceQuickButton, function()
					self:_toggleAuxiliaryWindow("JournalUI")
				end)
			end

			self._uxWidgets.match.BasicGui = gui
			self._uxWidgets.match.BasicPanel = panel
			self._uxWidgets.match.BasicTitle = title
			self._uxWidgets.match.BasicStateBadge = stateBadge
			self._uxWidgets.match.BasicPrimaryLabel = primaryLabel
			self._uxWidgets.match.BasicSecondaryLabel = secondaryLabel
			self._uxWidgets.match.BasicFooterLabel = footerLabel
			self._uxWidgets.match.TimerLabel = timerLabel
			self._uxWidgets.match.TimerCaption = timerCaption
			self._uxWidgets.match.EvidenceQuickButton = evidenceQuickButton
			self._uxWidgets.match.ControlsHintBar = controlsHintBar
			self._uxWidgets.match.ControlsHintLabel = controlsHintLabel
			self._uxWidgets.match.BasicSummaryRows = summaryRows
			self._uxWidgets.match.BasicFloatButton = floatBtn
			self._uxWidgets.match.BasicCloseButton = closeBtn
			self._uxWidgets.match.BasicHideButton = hideBtn
		end

		if guiName == "MainMenuUI" or guiName == "LeaderboardUI" then
			local config = guiName == "LeaderboardUI"
				and {
					title = "RANK BOARD",
					panelAnchorPoint = Vector2.new(0.5, 1),
					panelPosition = UDim2.new(0.5, 0, 1, -16),
					panelSize = Vector2.new(340, 348),
					panelColor = Color3.fromRGB(18, 25, 34),
					badgeColor = Color3.fromRGB(92, 104, 60),
					floatPosition = UDim2.new(1, -18, 0.58, 0),
					floatText = "RANK",
				}
				or {
					title = "QUICK MENU",
					panelAnchorPoint = Vector2.new(0.5, 0),
					panelPosition = UDim2.new(0.5, 0, 0, 16),
					panelSize = Vector2.new(340, 318),
					panelColor = Color3.fromRGB(18, 26, 34),
					badgeColor = Color3.fromRGB(60, 92, 132),
					floatPosition = UDim2.new(1, -18, 0.44, 0),
					floatText = "MENU",
				}
			panel.AnchorPoint = config.panelAnchorPoint
			panel.Position = config.panelPosition
			panel.Size = UDim2.fromOffset(config.panelSize.X, config.panelSize.Y)
			panel.BackgroundColor3 = config.panelColor
			panel.BackgroundTransparency = 0.08

			local title = panel:FindFirstChild("Title")
			if title and title:IsA("TextLabel") then
				title.Text = config.title
				title.Size = UDim2.new(1, -56, 0, 24)
				title.TextColor3 = Color3.fromRGB(238, 243, 248)
				title.Font = Enum.Font.GothamBold
			end

			local statusBadge = panel:FindFirstChild("StatusBadge")
			if not statusBadge then
				statusBadge = Instance.new("TextLabel")
				statusBadge.Name = "StatusBadge"
				statusBadge.Position = UDim2.fromOffset(12, 42)
				statusBadge.Size = UDim2.fromOffset(126, 24)
				statusBadge.BackgroundColor3 = config.badgeColor
				statusBadge.TextColor3 = Color3.fromRGB(245, 245, 245)
				statusBadge.Font = Enum.Font.GothamBold
				statusBadge.TextSize = 12
				statusBadge.Text = guiName == "LeaderboardUI" and "LOCAL SNAPSHOT" or "QUICK ACCESS"
				statusBadge.Parent = panel

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 999)
				badgeCorner.Parent = statusBadge
			end

			local primaryLabel = panel:FindFirstChild("PrimaryLabel")
			if not primaryLabel then
				primaryLabel = Instance.new("TextLabel")
				primaryLabel.Name = "PrimaryLabel"
				primaryLabel.Position = UDim2.fromOffset(12, 76)
				primaryLabel.Size = UDim2.new(1, -24, 0, 38)
				primaryLabel.BackgroundTransparency = 1
				primaryLabel.Font = Enum.Font.GothamBold
				primaryLabel.TextSize = 16
				primaryLabel.TextColor3 = Color3.fromRGB(242, 246, 250)
				primaryLabel.TextWrapped = true
				primaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				primaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				primaryLabel.Parent = panel
			end

			local secondaryLabel = panel:FindFirstChild("SecondaryLabel")
			if not secondaryLabel then
				secondaryLabel = Instance.new("TextLabel")
				secondaryLabel.Name = "SecondaryLabel"
				secondaryLabel.Position = UDim2.fromOffset(12, 118)
				secondaryLabel.Size = UDim2.new(1, -24, 0, 32)
				secondaryLabel.BackgroundTransparency = 1
				secondaryLabel.Font = Enum.Font.Gotham
				secondaryLabel.TextSize = 13
				secondaryLabel.TextColor3 = Color3.fromRGB(182, 196, 216)
				secondaryLabel.TextWrapped = true
				secondaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				secondaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				secondaryLabel.Parent = panel
			end

			local closeBtn = panel:FindFirstChild("CloseButton")
			if not closeBtn then
				closeBtn = Instance.new("TextButton")
				closeBtn.Name = "CloseButton"
				closeBtn.AnchorPoint = Vector2.new(1, 0)
				closeBtn.Position = UDim2.new(1, -8, 0, 8)
				closeBtn.Size = UDim2.fromOffset(24, 24)
				closeBtn.BackgroundColor3 = Color3.fromRGB(68, 36, 36)
				closeBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
				closeBtn.Font = Enum.Font.GothamBold
				closeBtn.TextSize = 14
				closeBtn.Text = "[X]"
				closeBtn.Parent = panel
			end
			closeBtn.Text = "[X]"
			local closeCorner = closeBtn:FindFirstChildOfClass("UICorner")
			if not closeCorner then
				closeCorner = Instance.new("UICorner")
				closeCorner.Parent = closeBtn
			end
			closeCorner.CornerRadius = UDim.new(1, 0)

			local floatName = guiName == "LeaderboardUI" and "LeaderboardFloatButton" or "MainMenuFloatButton"
			local fallbackFloatName = guiName == "LeaderboardUI" and "MainMenuFloatButton" or "LeaderboardFloatButton"
			local floatBtn = gui:FindFirstChild(floatName) or gui:FindFirstChild(fallbackFloatName)
			if not floatBtn then
				floatBtn = Instance.new("TextButton")
				floatBtn.Name = floatName
				floatBtn.AnchorPoint = Vector2.new(1, 0.5)
				floatBtn.Position = config.floatPosition
				floatBtn.Size = UDim2.fromOffset(54, 54)
				floatBtn.BackgroundColor3 = Color3.fromRGB(44, 55, 74)
				floatBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
				floatBtn.Font = Enum.Font.GothamBold
				floatBtn.TextSize = 12
				floatBtn.TextWrapped = true
				floatBtn.Text = config.floatText
				floatBtn.Visible = false
				floatBtn.Parent = gui

				local floatCorner = Instance.new("UICorner")
				floatCorner.CornerRadius = UDim.new(1, 0)
				floatCorner.Parent = floatBtn

				local floatStroke = Instance.new("UIStroke")
				floatStroke.Thickness = 2
				floatStroke.Color = Color3.fromRGB(115, 132, 160)
				floatStroke.Parent = floatBtn

				self:_setSelectableStyle(floatBtn)
			end
			floatBtn.Name = floatName
			floatBtn.Position = config.floatPosition
			floatBtn.Text = config.floatText

			local footerLabel = panel:FindFirstChild("FooterLabel")
			if not footerLabel then
				footerLabel = Instance.new("TextLabel")
				footerLabel.Name = "FooterLabel"
				footerLabel.BackgroundTransparency = 1
				footerLabel.Font = Enum.Font.Gotham
				footerLabel.TextSize = 11
				footerLabel.TextColor3 = Color3.fromRGB(162, 176, 198)
				footerLabel.TextWrapped = true
				footerLabel.TextXAlignment = Enum.TextXAlignment.Left
				footerLabel.TextYAlignment = Enum.TextYAlignment.Top
				footerLabel.Parent = panel
			end

			local actionButtons = {}
			local roomBrowserButton = nil
			local profileButton = nil
			local shopButton = nil
			local rankButton = nil
			local contentFrame = nil
			local contentText = nil
			local menuButton = nil

			if guiName == "MainMenuUI" then
				local buttonWidth = 152
				local buttonHeight = 52
				local buttonDefinitions = {
					{
						name = "RoomBrowserButton",
						text = "OPEN ROOM BROWSER",
						position = UDim2.fromOffset(12, 162),
						color = Color3.fromRGB(46, 78, 114),
					},
					{
						name = "ProfileButton",
						text = "OPEN PROFILE",
						position = UDim2.fromOffset(176, 162),
						color = Color3.fromRGB(58, 84, 62),
					},
					{
						name = "ShopButton",
						text = "OPEN SHOP",
						position = UDim2.fromOffset(12, 222),
						color = Color3.fromRGB(104, 78, 48),
					},
					{
						name = "RankButton",
						text = "OPEN RANK BOARD",
						position = UDim2.fromOffset(176, 222),
						color = Color3.fromRGB(78, 84, 50),
					},
				}

				for _, definition in ipairs(buttonDefinitions) do
					local button = panel:FindFirstChild(definition.name)
					if not button then
						button = Instance.new("TextButton")
						button.Name = definition.name
						button.Position = definition.position
						button.Size = UDim2.fromOffset(buttonWidth, buttonHeight)
						styleButton(button, definition.text)
						button.BackgroundColor3 = definition.color
						button.TextWrapped = true
						button.Parent = panel

						local buttonCorner = Instance.new("UICorner")
						buttonCorner.CornerRadius = UDim.new(0, 10)
						buttonCorner.Parent = button

						self:_setSelectableStyle(button)
					else
						button.Position = definition.position
						button.Size = UDim2.fromOffset(buttonWidth, buttonHeight)
						button.BackgroundColor3 = definition.color
						button.TextWrapped = true
					end

					if definition.name == "RoomBrowserButton" then
						roomBrowserButton = button
					elseif definition.name == "ProfileButton" then
						profileButton = button
					elseif definition.name == "ShopButton" then
						shopButton = button
					elseif definition.name == "RankButton" then
						rankButton = button
					end
					table.insert(actionButtons, button)
				end

				footerLabel.Position = UDim2.fromOffset(12, 284)
				footerLabel.Size = UDim2.new(1, -24, 0, 24)
			else
				contentFrame = panel:FindFirstChild("ContentFrame")
				if contentFrame and not contentFrame:IsA("ScrollingFrame") then
					contentFrame:Destroy()
					contentFrame = nil
				end
				if not contentFrame then
					contentFrame = Instance.new("ScrollingFrame")
					contentFrame.Name = "ContentFrame"
					contentFrame.Position = UDim2.fromOffset(12, 154)
					contentFrame.Size = UDim2.new(1, -24, 0, 112)
					contentFrame.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
					contentFrame.BackgroundTransparency = 0.06
					contentFrame.BorderSizePixel = 0
					contentFrame.ScrollBarThickness = 5
					contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
					contentFrame.CanvasSize = UDim2.fromOffset(0, 0)
					contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
					contentFrame.ElasticBehavior = Enum.ElasticBehavior.Never
					contentFrame.Parent = panel

					local contentCorner = Instance.new("UICorner")
					contentCorner.CornerRadius = UDim.new(0, 10)
					contentCorner.Parent = contentFrame

					local contentPadding = Instance.new("UIPadding")
					contentPadding.PaddingTop = UDim.new(0, 10)
					contentPadding.PaddingBottom = UDim.new(0, 10)
					contentPadding.PaddingLeft = UDim.new(0, 10)
					contentPadding.PaddingRight = UDim.new(0, 10)
					contentPadding.Parent = contentFrame
				end

				contentText = contentFrame:FindFirstChild("ContentText")
				if not contentText then
					contentText = Instance.new("TextLabel")
					contentText.Name = "ContentText"
					contentText.Size = UDim2.new(1, -4, 0, 0)
					contentText.BackgroundTransparency = 1
					contentText.AutomaticSize = Enum.AutomaticSize.Y
					contentText.Font = Enum.Font.Gotham
					contentText.TextSize = 12
					contentText.TextColor3 = Color3.fromRGB(226, 234, 244)
					contentText.TextWrapped = true
					contentText.TextXAlignment = Enum.TextXAlignment.Left
					contentText.TextYAlignment = Enum.TextYAlignment.Top
					contentText.Parent = contentFrame
				end

				local profileAction = panel:FindFirstChild("ProfileButton")
				if not profileAction then
					profileAction = Instance.new("TextButton")
					profileAction.Name = "ProfileButton"
					profileAction.Position = UDim2.fromOffset(12, 276)
					profileAction.Size = UDim2.fromOffset(98, 36)
					styleButton(profileAction, "PROFILE")
					profileAction.BackgroundColor3 = Color3.fromRGB(58, 84, 62)
					profileAction.Parent = panel

					local buttonCorner = Instance.new("UICorner")
					buttonCorner.CornerRadius = UDim.new(0, 10)
					buttonCorner.Parent = profileAction

					self:_setSelectableStyle(profileAction)
				end
				profileButton = profileAction

				local roomAction = panel:FindFirstChild("RoomBrowserButton")
				if not roomAction then
					roomAction = Instance.new("TextButton")
					roomAction.Name = "RoomBrowserButton"
					roomAction.Position = UDim2.fromOffset(120, 276)
					roomAction.Size = UDim2.fromOffset(98, 36)
					styleButton(roomAction, "OPEN ROOMS")
					roomAction.BackgroundColor3 = Color3.fromRGB(46, 78, 114)
					roomAction.Parent = panel

					local buttonCorner = Instance.new("UICorner")
					buttonCorner.CornerRadius = UDim.new(0, 10)
					buttonCorner.Parent = roomAction

					self:_setSelectableStyle(roomAction)
				end
				roomBrowserButton = roomAction

				local menuAction = panel:FindFirstChild("MenuButton")
				if not menuAction then
					menuAction = Instance.new("TextButton")
					menuAction.Name = "MenuButton"
					menuAction.Position = UDim2.fromOffset(228, 276)
					menuAction.Size = UDim2.fromOffset(98, 36)
					styleButton(menuAction, "OPEN MENU")
					menuAction.BackgroundColor3 = Color3.fromRGB(58, 66, 84)
					menuAction.Parent = panel

					local buttonCorner = Instance.new("UICorner")
					buttonCorner.CornerRadius = UDim.new(0, 10)
					buttonCorner.Parent = menuAction

					self:_setSelectableStyle(menuAction)
				end
				menuButton = menuAction
				actionButtons = { profileButton, roomBrowserButton, menuButton }

				footerLabel.Position = UDim2.fromOffset(12, 318)
				footerLabel.Size = UDim2.new(1, -24, 0, 22)
			end

			local initAttribute = guiName == "LeaderboardUI" and "LeaderboardInitDone" or "MainMenuInitDone"
			if gui:GetAttribute(initAttribute) ~= true then
				gui:SetAttribute(initAttribute, true)
				panel.Visible = false
				floatBtn.Visible = true
			end

			floatBtn.Visible = panel.Visible ~= true
			makeFloatingButtonDraggable(floatBtn)

			if closeBtn:GetAttribute("Bound") ~= true then
				closeBtn:SetAttribute("Bound", true)
				connectButtonPress(closeBtn, function()
					self:_setBasicWindowVisible(guiName, false)
				end)
			end

			if floatBtn:GetAttribute("Bound") ~= true then
				floatBtn:SetAttribute("Bound", true)
				connectButtonPress(floatBtn, function()
					self:_setBasicWindowVisible(guiName, true)
				end)
			end

			if roomBrowserButton and roomBrowserButton:GetAttribute("Bound") ~= true then
				roomBrowserButton:SetAttribute("Bound", true)
				connectButtonPress(roomBrowserButton, function()
					self:_toggleRoomBrowserVisible()
				end)
			end
			if profileButton and profileButton:GetAttribute("Bound") ~= true then
				profileButton:SetAttribute("Bound", true)
				connectButtonPress(profileButton, function()
					self:_toggleAuxiliaryWindow("ProfileUI")
				end)
			end
			if shopButton and shopButton:GetAttribute("Bound") ~= true then
				shopButton:SetAttribute("Bound", true)
				connectButtonPress(shopButton, function()
					self:_toggleAuxiliaryWindow("ShopUI")
				end)
			end
			if rankButton and rankButton:GetAttribute("Bound") ~= true then
				rankButton:SetAttribute("Bound", true)
				connectButtonPress(rankButton, function()
					self:_toggleBasicWindow("LeaderboardUI")
				end)
			end
			if menuButton and menuButton:GetAttribute("Bound") ~= true then
				menuButton:SetAttribute("Bound", true)
				connectButtonPress(menuButton, function()
					self:_toggleBasicWindow("MainMenuUI")
				end)
			end

			self._uxWidgets.basicWindows[guiName] = {
				Gui = gui,
				Panel = panel,
				Title = title,
				StatusBadge = statusBadge,
				PrimaryLabel = primaryLabel,
				SecondaryLabel = secondaryLabel,
				ContentFrame = contentFrame,
				ContentText = contentText,
				FooterLabel = footerLabel,
				FloatButton = floatBtn,
				CloseButton = closeBtn,
				ActionButtons = actionButtons,
				RoomBrowserButton = roomBrowserButton,
				ProfileButton = profileButton,
				ShopButton = shopButton,
				RankButton = rankButton,
				MenuButton = menuButton,
			}
		end
	end

	self:_refreshBasicLobbyPanel()
	self:_refreshBasicMatchPanel("Lobby")
	self:_applyVisibility()
end

function UISystem:_ensureRoomBrowserGui()
	local playerGui = self:_getPlayerGui()
	local player = Players.LocalPlayer
	if not playerGui or not player then
		return
	end

	if self._roomBrowserGui and self._roomBrowserGui.Parent == playerGui and self._roomBrowserWidgets and self._roomBrowserFloatGui and self._roomBrowserFloatGui.Parent == playerGui then
		return
	end

	if self._roomBrowserGui and self._roomBrowserGui.Parent ~= playerGui then
		self._roomBrowserGui = nil
		self._roomBrowserWidgets = nil
	end
	if self._roomBrowserFloatGui and self._roomBrowserFloatGui.Parent ~= playerGui then
		self._roomBrowserFloatGui = nil
	end

	local existingPrimary = playerGui:FindFirstChild("RoomBrowserUI")
	if existingPrimary and self._roomBrowserGui and existingPrimary ~= self._roomBrowserGui then
		existingPrimary:Destroy()
	elseif existingPrimary and not self._roomBrowserGui then
		existingPrimary:Destroy()
	end

	local lobbyUi = playerGui:FindFirstChild("LobbyUI")
	if not lobbyUi then
		lobbyUi = playerGui:WaitForChild("LobbyUI", 10)
	end
	if not lobbyUi then
		return
	end

	for _, guiName in ipairs({ "RoomBrowserUI", "RoomBrowserDebugUI", "RoomBrowserFloatUI" }) do
		local existing = playerGui:FindFirstChild(guiName)
		if existing then
			existing:Destroy()
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "RoomBrowserUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 200
	gui.IgnoreGuiInset = true
	gui.Enabled = self._roomBrowserVisible
	gui.Parent = playerGui

	local floatGui = Instance.new("ScreenGui")
	floatGui.Name = "RoomBrowserFloatUI"
	floatGui.ResetOnSpawn = false
	floatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	floatGui.DisplayOrder = 201
	floatGui.IgnoreGuiInset = true
	floatGui.Enabled = true
	floatGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(920, 560)
	panel.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	panel.BackgroundTransparency = 0.5
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local panelScale = Instance.new("UIScale")
	panelScale.Parent = panel

	local function updateRoomBrowserPanelScale()
		local viewport = Vector2.new(1920, 1080)
		local camera = Workspace.CurrentCamera
		if camera and typeof(camera.ViewportSize) == "Vector2" then
			viewport = camera.ViewportSize
		end
		local scaleX = (viewport.X - 24) / 920
		local scaleY = (viewport.Y - 24) / 560
		panelScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.55, 1)
	end
	updateRoomBrowserPanelScale()
	if Workspace.CurrentCamera then
		table.insert(self._connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateRoomBrowserPanelScale))
	end

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(0, 8)
	title.Size = UDim2.new(1, -48, 0, 30)
	title.Text = "RUANG INVESTIGASI"
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 25
	title.TextColor3 = Color3.fromRGB(210, 68, 68)
	title.ZIndex = 3
	title.Parent = panel
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 1.4
	titleStroke.Color = Color3.fromRGB(35, 8, 8)
	titleStroke.Parent = title

	local titleGlow = Instance.new("TextLabel")
	titleGlow.Name = "TitleGlow"
	titleGlow.BackgroundTransparency = 1
	titleGlow.Position = UDim2.fromOffset(1, 10)
	titleGlow.Size = title.Size
	titleGlow.Text = title.Text
	titleGlow.TextXAlignment = Enum.TextXAlignment.Center
	titleGlow.Font = title.Font
	titleGlow.TextSize = 25
	titleGlow.TextColor3 = Color3.fromRGB(92, 22, 22)
	titleGlow.TextTransparency = 0.35
	titleGlow.ZIndex = 2
	titleGlow.Parent = panel

	local dragBar = Instance.new("Frame")
	dragBar.Name = "DragBar"
	dragBar.BackgroundTransparency = 1
	dragBar.Position = UDim2.fromOffset(0, 0)
	dragBar.Size = UDim2.new(1, 0, 0, 42)
	dragBar.Active = true
	dragBar.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Position = UDim2.fromOffset(852, 8)
	closeBtn.Size = UDim2.fromOffset(34, 28)
	styleButton(closeBtn, "X")
	closeBtn.Parent = panel

	local floatButton = Instance.new("TextButton")
	floatButton.Name = "RoomBrowserFloatButton"
	floatButton.AnchorPoint = Vector2.new(1, 0.5)
	floatButton.Position = UDim2.new(1, -20, 0.5, 0)
	floatButton.Size = UDim2.fromOffset(64, 64)
	floatButton.BackgroundColor3 = Color3.fromRGB(38, 47, 62)
	floatButton.TextColor3 = Color3.fromRGB(245, 245, 245)
	floatButton.Font = Enum.Font.GothamBold
	floatButton.TextSize = 12
	floatButton.TextScaled = true
	floatButton.TextWrapped = true
	floatButton.Text = "RUANG\nINVESTIGASI"
	floatButton.ZIndex = 20
	floatButton.Parent = floatGui

	local floatCorner = Instance.new("UICorner")
	floatCorner.CornerRadius = UDim.new(1, 0)
	floatCorner.Parent = floatButton

	local floatStroke = Instance.new("UIStroke")
	floatStroke.Thickness = 2
	floatStroke.Color = Color3.fromRGB(95, 118, 150)
	floatStroke.Parent = floatButton
	makeFloatingButtonDraggable(floatButton)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(16, 44)
	statusLabel.Size = UDim2.fromOffset(840, 22)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 12
	statusLabel.TextColor3 = Color3.fromRGB(160, 175, 200)
	statusLabel.Text = "Memuat..."
	statusLabel.Parent = panel

	local classicBtn = Instance.new("TextButton")
	classicBtn.Name = "ClassicButton"
	classicBtn.Position = UDim2.fromOffset(16, 72)
	classicBtn.Size = UDim2.fromOffset(132, 30)
	styleButton(classicBtn, "Classic")
	classicBtn.Parent = panel

	local allModesBtn = Instance.new("TextButton")
	allModesBtn.Name = "AllModesButton"
	allModesBtn.Position = UDim2.fromOffset(154, 72)
	allModesBtn.Size = UDim2.fromOffset(132, 30)
	styleButton(allModesBtn, "SEMUA MODE")
	allModesBtn.Parent = panel

	local rankedBtn = Instance.new("TextButton")
	rankedBtn.Name = "RankedButton"
	rankedBtn.Position = UDim2.fromOffset(292, 72)
	rankedBtn.Size = UDim2.fromOffset(132, 30)
	styleButton(rankedBtn, "Ranked")
	rankedBtn.Parent = panel

	local roomList = Instance.new("ScrollingFrame")
	roomList.Name = "RoomList"
	roomList.Position = UDim2.fromOffset(16, 110)
	roomList.Size = UDim2.fromOffset(392, 250)
	roomList.BackgroundColor3 = Color3.fromRGB(26, 32, 42)
	roomList.BorderSizePixel = 0
	roomList.ScrollBarThickness = 4
	roomList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	roomList.CanvasSize = UDim2.fromOffset(0, 0)
	roomList.Parent = panel

	local roomListCorner = Instance.new("UICorner")
	roomListCorner.CornerRadius = UDim.new(0, 8)
	roomListCorner.Parent = roomList

	local roomListLayout = Instance.new("UIListLayout")
	roomListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	roomListLayout.Padding = UDim.new(0, 4)
	roomListLayout.Parent = roomList

	local roomListPadding = Instance.new("UIPadding")
	roomListPadding.PaddingTop = UDim.new(0, 6)
	roomListPadding.PaddingBottom = UDim.new(0, 6)
	roomListPadding.PaddingLeft = UDim.new(0, 6)
	roomListPadding.PaddingRight = UDim.new(0, 6)
	roomListPadding.Parent = roomList

	local roomPreviewPanel = Instance.new("Frame")
	roomPreviewPanel.Name = "RoomPreviewPanel"
	roomPreviewPanel.Position = UDim2.fromOffset(424, 110)
	roomPreviewPanel.Size = UDim2.fromOffset(480, 384)
	roomPreviewPanel.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	roomPreviewPanel.BorderSizePixel = 0
	roomPreviewPanel.Parent = panel
	local roomPreviewCorner = Instance.new("UICorner")
	roomPreviewCorner.CornerRadius = UDim.new(0, 10)
	roomPreviewCorner.Parent = roomPreviewPanel
	local roomPreviewStroke = Instance.new("UIStroke")
	roomPreviewStroke.Thickness = 1
	roomPreviewStroke.Color = Color3.fromRGB(76, 95, 122)
	roomPreviewStroke.Parent = roomPreviewPanel

	local roomPreviewTitle = Instance.new("TextLabel")
	roomPreviewTitle.Name = "Title"
	roomPreviewTitle.BackgroundTransparency = 1
	roomPreviewTitle.Position = UDim2.fromOffset(12, 10)
	roomPreviewTitle.Size = UDim2.fromOffset(456, 24)
	roomPreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewTitle.Font = Enum.Font.GothamBold
	roomPreviewTitle.TextSize = 15
	roomPreviewTitle.TextColor3 = Color3.fromRGB(240, 245, 250)
	roomPreviewTitle.Text = "PREVIEW ROOM"
	roomPreviewTitle.Parent = roomPreviewPanel

	local roomPreviewInfo = Instance.new("TextLabel")
	roomPreviewInfo.Name = "Info"
	roomPreviewInfo.BackgroundTransparency = 1
	roomPreviewInfo.Position = UDim2.fromOffset(12, 34)
	roomPreviewInfo.Size = UDim2.fromOffset(456, 18)
	roomPreviewInfo.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewInfo.Font = Enum.Font.Gotham
	roomPreviewInfo.TextSize = 11
	roomPreviewInfo.TextColor3 = Color3.fromRGB(178, 194, 214)
	roomPreviewInfo.Text = "Klik room di daftar untuk lihat detail."
	roomPreviewInfo.Parent = roomPreviewPanel

	local roomPreviewMap = Instance.new("Frame")
	roomPreviewMap.Name = "MapPlaceholder"
	roomPreviewMap.Position = UDim2.fromOffset(12, 58)
	roomPreviewMap.Size = UDim2.fromOffset(456, 112)
	roomPreviewMap.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
	roomPreviewMap.BorderSizePixel = 0
	roomPreviewMap.Parent = roomPreviewPanel
	local roomPreviewMapCorner = Instance.new("UICorner")
	roomPreviewMapCorner.CornerRadius = UDim.new(0, 8)
	roomPreviewMapCorner.Parent = roomPreviewMap
	local roomPreviewMapStroke = Instance.new("UIStroke")
	roomPreviewMapStroke.Thickness = 1
	roomPreviewMapStroke.Color = Color3.fromRGB(72, 90, 116)
	roomPreviewMapStroke.Parent = roomPreviewMap

	local roomPreviewMapTitle = Instance.new("TextLabel")
	roomPreviewMapTitle.Name = "MapTitle"
	roomPreviewMapTitle.BackgroundTransparency = 1
	roomPreviewMapTitle.Position = UDim2.fromOffset(10, 8)
	roomPreviewMapTitle.Size = UDim2.fromOffset(436, 16)
	roomPreviewMapTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewMapTitle.Font = Enum.Font.GothamSemibold
	roomPreviewMapTitle.TextSize = 11
	roomPreviewMapTitle.TextColor3 = Color3.fromRGB(196, 210, 228)
	roomPreviewMapTitle.Text = "MAP ROOM"
	roomPreviewMapTitle.Parent = roomPreviewMap

	local roomPreviewMapLabel = Instance.new("TextLabel")
	roomPreviewMapLabel.Name = "MapLabel"
	roomPreviewMapLabel.BackgroundTransparency = 1
	roomPreviewMapLabel.Position = UDim2.fromOffset(10, 30)
	roomPreviewMapLabel.Size = UDim2.fromOffset(436, 74)
	roomPreviewMapLabel.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewMapLabel.TextYAlignment = Enum.TextYAlignment.Top
	roomPreviewMapLabel.Font = Enum.Font.GothamBold
	roomPreviewMapLabel.TextSize = 13
	roomPreviewMapLabel.TextWrapped = true
	roomPreviewMapLabel.TextColor3 = Color3.fromRGB(236, 242, 250)
	roomPreviewMapLabel.Text = "Pilih room untuk lihat detail map."
	roomPreviewMapLabel.Parent = roomPreviewMap

	local roomPreviewPlayersTitle = Instance.new("TextLabel")
	roomPreviewPlayersTitle.Name = "PlayersTitle"
	roomPreviewPlayersTitle.BackgroundTransparency = 1
	roomPreviewPlayersTitle.Position = UDim2.fromOffset(12, 176)
	roomPreviewPlayersTitle.Size = UDim2.fromOffset(456, 16)
	roomPreviewPlayersTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewPlayersTitle.Font = Enum.Font.GothamSemibold
	roomPreviewPlayersTitle.TextSize = 11
	roomPreviewPlayersTitle.TextColor3 = Color3.fromRGB(198, 214, 232)
	roomPreviewPlayersTitle.Text = "PLAYER DALAM ROOM"
	roomPreviewPlayersTitle.Parent = roomPreviewPanel

	local roomPreviewPlayersList = Instance.new("ScrollingFrame")
	roomPreviewPlayersList.Name = "PlayersList"
	roomPreviewPlayersList.Position = UDim2.fromOffset(12, 196)
	roomPreviewPlayersList.Size = UDim2.fromOffset(456, 176)
	roomPreviewPlayersList.BackgroundColor3 = Color3.fromRGB(19, 25, 34)
	roomPreviewPlayersList.BorderSizePixel = 0
	roomPreviewPlayersList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	roomPreviewPlayersList.CanvasSize = UDim2.fromOffset(0, 0)
	roomPreviewPlayersList.ScrollBarThickness = 4
	roomPreviewPlayersList.Parent = roomPreviewPanel
	local roomPreviewPlayersCorner = Instance.new("UICorner")
	roomPreviewPlayersCorner.CornerRadius = UDim.new(0, 8)
	roomPreviewPlayersCorner.Parent = roomPreviewPlayersList
	local roomPreviewPlayersPadding = Instance.new("UIPadding")
	roomPreviewPlayersPadding.PaddingTop = UDim.new(0, 6)
	roomPreviewPlayersPadding.PaddingBottom = UDim.new(0, 6)
	roomPreviewPlayersPadding.PaddingLeft = UDim.new(0, 6)
	roomPreviewPlayersPadding.PaddingRight = UDim.new(0, 6)
	roomPreviewPlayersPadding.Parent = roomPreviewPlayersList
	local roomPreviewPlayersLayout = Instance.new("UIGridLayout")
	roomPreviewPlayersLayout.CellSize = UDim2.fromOffset(220, 78)
	roomPreviewPlayersLayout.CellPadding = UDim2.fromOffset(8, 8)
	roomPreviewPlayersLayout.FillDirectionMaxCells = 2
	roomPreviewPlayersLayout.SortOrder = Enum.SortOrder.LayoutOrder
	roomPreviewPlayersLayout.Parent = roomPreviewPlayersList

	local joinPwdBox = Instance.new("TextBox")
	joinPwdBox.Name = "JoinPassword"
	joinPwdBox.Position = UDim2.fromOffset(16, 408)
	joinPwdBox.Size = UDim2.fromOffset(198, 30)
	joinPwdBox.PlaceholderText = "Password Join (4 digit)"
	joinPwdBox.Text = ""
	joinPwdBox.ClearTextOnFocus = false
	joinPwdBox.TextColor3 = Color3.fromRGB(235, 240, 245)
	joinPwdBox.Font = Enum.Font.Gotham
	joinPwdBox.TextSize = 12
	joinPwdBox.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
	joinPwdBox.BorderSizePixel = 0
	joinPwdBox.Visible = false
	joinPwdBox.Parent = panel

	local joinPwdCorner = Instance.new("UICorner")
	joinPwdCorner.CornerRadius = UDim.new(0, 6)
	joinPwdCorner.Parent = joinPwdBox

	local passwordModal = Instance.new("Frame")
	passwordModal.Name = "PasswordModal"
	passwordModal.Size = UDim2.fromScale(1, 1)
	passwordModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	passwordModal.BackgroundTransparency = 0.35
	passwordModal.ZIndex = 25
	passwordModal.Visible = false
	passwordModal.Parent = gui

	local passwordCard = Instance.new("Frame")
	passwordCard.Name = "PasswordCard"
	passwordCard.AnchorPoint = Vector2.new(0.5, 0.5)
	passwordCard.Position = UDim2.fromScale(0.5, 0.5)
	passwordCard.Size = UDim2.fromOffset(320, 180)
	passwordCard.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	passwordCard.BorderSizePixel = 0
	passwordCard.ZIndex = 26
	passwordCard.Parent = passwordModal
	local passwordCardCorner = Instance.new("UICorner")
	passwordCardCorner.CornerRadius = UDim.new(0, 10)
	passwordCardCorner.Parent = passwordCard

	local passwordTitle = Instance.new("TextLabel")
	passwordTitle.BackgroundTransparency = 1
	passwordTitle.Position = UDim2.fromOffset(12, 10)
	passwordTitle.Size = UDim2.fromOffset(296, 24)
	passwordTitle.Text = "Masukkan Password Room"
	passwordTitle.TextXAlignment = Enum.TextXAlignment.Left
	passwordTitle.Font = Enum.Font.GothamBold
	passwordTitle.TextSize = 16
	passwordTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	passwordTitle.ZIndex = 27
	passwordTitle.Parent = passwordCard

	local passwordInput = Instance.new("TextBox")
	passwordInput.Name = "PasswordInput"
	passwordInput.Position = UDim2.fromOffset(12, 52)
	passwordInput.Size = UDim2.fromOffset(296, 36)
	passwordInput.PlaceholderText = "4 digit password"
	passwordInput.Text = ""
	passwordInput.ClearTextOnFocus = false
	passwordInput.Font = Enum.Font.Gotham
	passwordInput.TextSize = 14
	passwordInput.TextColor3 = Color3.fromRGB(235, 240, 245)
	passwordInput.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
	passwordInput.BorderSizePixel = 0
	passwordInput.ZIndex = 27
	passwordInput.Parent = passwordCard
	local passwordInputCorner = Instance.new("UICorner")
	passwordInputCorner.CornerRadius = UDim.new(0, 8)
	passwordInputCorner.Parent = passwordInput

	local passwordJoinBtn = Instance.new("TextButton")
	passwordJoinBtn.Name = "JoinButton"
	passwordJoinBtn.Position = UDim2.fromOffset(12, 102)
	passwordJoinBtn.Size = UDim2.fromOffset(144, 34)
	styleButton(passwordJoinBtn, "JOIN ROOM")
	passwordJoinBtn.BackgroundColor3 = Color3.fromRGB(46, 112, 168)
	passwordJoinBtn.ZIndex = 27
	passwordJoinBtn.Parent = passwordCard

	local passwordCancelBtn = Instance.new("TextButton")
	passwordCancelBtn.Name = "CancelButton"
	passwordCancelBtn.Position = UDim2.fromOffset(164, 102)
	passwordCancelBtn.Size = UDim2.fromOffset(144, 34)
	styleButton(passwordCancelBtn, "BATAL")
	passwordCancelBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
	passwordCancelBtn.ZIndex = 27
	passwordCancelBtn.Parent = passwordCard

	local kickNoticeModal = Instance.new("Frame")
	kickNoticeModal.Name = "KickNoticeModal"
	kickNoticeModal.Size = UDim2.fromScale(1, 1)
	kickNoticeModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	kickNoticeModal.BackgroundTransparency = 0.35
	kickNoticeModal.ZIndex = 28
	kickNoticeModal.Visible = false
	kickNoticeModal.Parent = gui

	local kickNoticeCard = Instance.new("Frame")
	kickNoticeCard.AnchorPoint = Vector2.new(0.5, 0.5)
	kickNoticeCard.Position = UDim2.fromScale(0.5, 0.5)
	kickNoticeCard.Size = UDim2.fromOffset(320, 140)
	kickNoticeCard.BackgroundColor3 = Color3.fromRGB(24, 20, 20)
	kickNoticeCard.BorderSizePixel = 0
	kickNoticeCard.ZIndex = 29
	kickNoticeCard.Parent = kickNoticeModal
	local kickNoticeCorner = Instance.new("UICorner")
	kickNoticeCorner.CornerRadius = UDim.new(0, 10)
	kickNoticeCorner.Parent = kickNoticeCard

	local kickNoticeText = Instance.new("TextLabel")
	kickNoticeText.BackgroundTransparency = 1
	kickNoticeText.Position = UDim2.fromOffset(12, 20)
	kickNoticeText.Size = UDim2.fromOffset(296, 50)
	kickNoticeText.Text = "ANDA TELAH DI KICK"
	kickNoticeText.TextColor3 = Color3.fromRGB(255, 180, 180)
	kickNoticeText.Font = Enum.Font.GothamBold
	kickNoticeText.TextSize = 20
	kickNoticeText.TextWrapped = true
	kickNoticeText.ZIndex = 30
	kickNoticeText.Parent = kickNoticeCard

	local kickNoticeOk = Instance.new("TextButton")
	kickNoticeOk.Position = UDim2.fromOffset(88, 86)
	kickNoticeOk.Size = UDim2.fromOffset(144, 34)
	styleButton(kickNoticeOk, "OK")
	kickNoticeOk.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	kickNoticeOk.ZIndex = 30
	kickNoticeOk.Parent = kickNoticeCard

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Name = "RefreshButton"
	refreshBtn.Position = UDim2.fromOffset(149, 456)
	refreshBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(refreshBtn, "Refresh")
	refreshBtn.Parent = panel

	local createRoomBtn = Instance.new("TextButton")
	createRoomBtn.Name = "CreateRoomButton"
	createRoomBtn.Position = UDim2.fromOffset(282, 456)
	createRoomBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(createRoomBtn, "Buat Room")
	createRoomBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 140)
	createRoomBtn.Parent = panel

	local queueBtn = Instance.new("TextButton")
	queueBtn.Name = "QueueButton"
	queueBtn.Position = UDim2.fromOffset(16, 506)
	queueBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(queueBtn, "JOIN")
	queueBtn.BackgroundColor3 = Color3.fromRGB(46, 112, 168)
	queueBtn.Parent = panel

	local quickClassicBtn = Instance.new("TextButton")
	quickClassicBtn.Name = "QuickJoinClassicButton"
	quickClassicBtn.Position = UDim2.fromOffset(149, 506)
	quickClassicBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(quickClassicBtn, "QUICK CLASSIC")
	quickClassicBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 84)
	quickClassicBtn.Parent = panel

	local quickRankedBtn = Instance.new("TextButton")
	quickRankedBtn.Name = "QuickJoinRankedButton"
	quickRankedBtn.Position = UDim2.fromOffset(282, 506)
	quickRankedBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(quickRankedBtn, "QUICK RANKED")
	quickRankedBtn.BackgroundColor3 = Color3.fromRGB(108, 78, 132)
	quickRankedBtn.Parent = panel

	local roomPanel = Instance.new("Frame")
	roomPanel.Name = "RoomPanel"
	roomPanel.Position = UDim2.fromOffset(0, 0)
	roomPanel.Size = UDim2.fromScale(1, 1)
	roomPanel.BackgroundColor3 = Color3.fromRGB(26, 32, 42)
	roomPanel.BackgroundTransparency = 0
	roomPanel.BorderSizePixel = 0
	roomPanel.Visible = false
	roomPanel.Parent = panel

	local roomPanelCorner = Instance.new("UICorner")
	roomPanelCorner.CornerRadius = UDim.new(0, 12)
	roomPanelCorner.Parent = roomPanel

	local roomTitle = Instance.new("TextLabel")
	roomTitle.Name = "RoomTitle"
	roomTitle.BackgroundTransparency = 1
	roomTitle.Position = UDim2.fromOffset(14, 12)
	roomTitle.Size = UDim2.fromOffset(420, 22)
	roomTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomTitle.Font = Enum.Font.GothamBold
	roomTitle.TextSize = 17
	roomTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	roomTitle.Text = "RUANG"
	roomTitle.Parent = roomPanel

	local roomHost = Instance.new("TextLabel")
	roomHost.Name = "HostLabel"
	roomHost.BackgroundTransparency = 1
	roomHost.Position = UDim2.fromOffset(14, 36)
	roomHost.Size = UDim2.fromOffset(420, 18)
	roomHost.TextXAlignment = Enum.TextXAlignment.Left
	roomHost.Font = Enum.Font.Gotham
	roomHost.TextSize = 12
	roomHost.TextColor3 = Color3.fromRGB(160, 175, 200)
	roomHost.Text = "Host: -"
	roomHost.Parent = roomPanel

	local playersLabel = Instance.new("TextLabel")
	playersLabel.Name = "PlayersLabel"
	playersLabel.BackgroundTransparency = 1
	playersLabel.Position = UDim2.fromOffset(454, 12)
	playersLabel.Size = UDim2.fromOffset(420, 16)
	playersLabel.TextXAlignment = Enum.TextXAlignment.Left
	playersLabel.Font = Enum.Font.GothamSemibold
	playersLabel.TextSize = 12
	playersLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
	playersLabel.Text = "Anggota Ruangan"
	playersLabel.Parent = roomPanel

	local playersList = Instance.new("ScrollingFrame")
	playersList.Name = "PlayersList"
	playersList.BackgroundColor3 = Color3.fromRGB(21, 27, 36)
	playersList.BorderSizePixel = 0
	playersList.Position = UDim2.fromOffset(454, 34)
	playersList.Size = UDim2.fromOffset(420, 408)
	playersList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playersList.CanvasSize = UDim2.fromOffset(0, 0)
	playersList.ScrollBarThickness = 4
	playersList.Parent = roomPanel
	local playersListCorner = Instance.new("UICorner")
	playersListCorner.CornerRadius = UDim.new(0, 8)
	playersListCorner.Parent = playersList
	local playersListPadding = Instance.new("UIPadding")
	playersListPadding.PaddingTop = UDim.new(0, 4)
	playersListPadding.PaddingBottom = UDim.new(0, 4)
	playersListPadding.PaddingLeft = UDim.new(0, 6)
	playersListPadding.PaddingRight = UDim.new(0, 6)
	playersListPadding.Parent = playersList
	local playersListLayout = Instance.new("UIGridLayout")
	playersListLayout.CellSize = UDim2.fromOffset(202, 132)
	playersListLayout.CellPadding = UDim2.fromOffset(8, 8)
	playersListLayout.FillDirectionMaxCells = 2
	playersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playersListLayout.Parent = playersList

	local modeSelector = Instance.new("TextButton")
	modeSelector.Name = "ModeSelector"
	modeSelector.Position = UDim2.fromOffset(14, 348)
	modeSelector.Size = UDim2.fromOffset(380, 30)
	styleButton(modeSelector, "MODE: CLASSIC")
	modeSelector.Parent = roomPanel

	local modeDropdown = Instance.new("Frame")
	modeDropdown.Name = "ModeDropdown"
	modeDropdown.Position = UDim2.fromOffset(14, 382)
	modeDropdown.Size = UDim2.fromOffset(380, 72)
	modeDropdown.BackgroundColor3 = Color3.fromRGB(26, 33, 43)
	modeDropdown.BorderSizePixel = 0
	modeDropdown.Visible = false
	modeDropdown.Active = true
	modeDropdown.ZIndex = 24
	modeDropdown.Parent = roomPanel
	local modeDropdownCorner = Instance.new("UICorner")
	modeDropdownCorner.CornerRadius = UDim.new(0, 8)
	modeDropdownCorner.Parent = modeDropdown
	local modeDropdownStroke = Instance.new("UIStroke")
	modeDropdownStroke.Thickness = 1
	modeDropdownStroke.Color = Color3.fromRGB(78, 100, 128)
	modeDropdownStroke.Parent = modeDropdown

	local modeClassicBtn = Instance.new("TextButton")
	modeClassicBtn.Name = "ClassicOption"
	modeClassicBtn.Position = UDim2.fromOffset(8, 8)
	modeClassicBtn.Size = UDim2.fromOffset(364, 26)
	styleButton(modeClassicBtn, "CLASSIC")
	modeClassicBtn.ZIndex = 25
	modeClassicBtn.Parent = modeDropdown
	local modeClassicCorner = Instance.new("UICorner")
	modeClassicCorner.CornerRadius = UDim.new(0, 6)
	modeClassicCorner.Parent = modeClassicBtn

	local modeRankedBtn = Instance.new("TextButton")
	modeRankedBtn.Name = "RankedOption"
	modeRankedBtn.Position = UDim2.fromOffset(8, 38)
	modeRankedBtn.Size = UDim2.fromOffset(364, 26)
	styleButton(modeRankedBtn, "RANKED")
	modeRankedBtn.ZIndex = 25
	modeRankedBtn.Parent = modeDropdown
	local modeRankedCorner = Instance.new("UICorner")
	modeRankedCorner.CornerRadius = UDim.new(0, 6)
	modeRankedCorner.Parent = modeRankedBtn

	local mapSelector = Instance.new("TextButton")
	mapSelector.Name = "MapSelector"
	mapSelector.Position = UDim2.fromOffset(14, 422)
	mapSelector.Size = UDim2.fromOffset(380, 30)
	styleButton(mapSelector, "MAP: " .. tostring(MAPS[1]))
	mapSelector.Parent = roomPanel

	local mapDropdown = Instance.new("Frame")
	mapDropdown.Name = "MapDropdown"
	mapDropdown.Position = UDim2.fromOffset(14, 446)
	mapDropdown.Size = UDim2.fromOffset(380, 112)
	mapDropdown.BackgroundColor3 = Color3.fromRGB(26, 33, 43)
	mapDropdown.BorderSizePixel = 0
	mapDropdown.Visible = false
	mapDropdown.Active = true
	mapDropdown.ZIndex = 24
	mapDropdown.Parent = roomPanel
	local mapDropdownCorner = Instance.new("UICorner")
	mapDropdownCorner.CornerRadius = UDim.new(0, 8)
	mapDropdownCorner.Parent = mapDropdown
	local mapDropdownStroke = Instance.new("UIStroke")
	mapDropdownStroke.Thickness = 1
	mapDropdownStroke.Color = Color3.fromRGB(78, 100, 128)
	mapDropdownStroke.Parent = mapDropdown

	local mapOptionButtons = {}
	for idx, mapName in ipairs(MAPS) do
		local option = Instance.new("TextButton")
		option.Name = "MapOption_" .. tostring(idx)
		option.Position = UDim2.fromOffset(8, 8 + (idx - 1) * 26)
		option.Size = UDim2.fromOffset(364, 22)
		styleButton(option, mapName)
		option.TextSize = 12
		option.ZIndex = 25
		option.Parent = mapDropdown
		local optionCorner = Instance.new("UICorner")
		optionCorner.CornerRadius = UDim.new(0, 6)
		optionCorner.Parent = option
		mapOptionButtons[idx] = option
	end

	local rankedTierLabel = Instance.new("TextLabel")
	rankedTierLabel.Name = "RankedTierLabel"
	rankedTierLabel.BackgroundColor3 = Color3.fromRGB(31, 35, 48)
	rankedTierLabel.BorderSizePixel = 0
	rankedTierLabel.Position = UDim2.fromOffset(14, 422)
	rankedTierLabel.Size = UDim2.fromOffset(380, 30)
	rankedTierLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankedTierLabel.Font = Enum.Font.GothamSemibold
	rankedTierLabel.TextSize = 12
	rankedTierLabel.TextColor3 = Color3.fromRGB(215, 224, 236)
	rankedTierLabel.Text = "TIER HOST: UNRANKED"
	rankedTierLabel.Visible = false
	rankedTierLabel.Parent = roomPanel
	local rankedTierCorner = Instance.new("UICorner")
	rankedTierCorner.CornerRadius = UDim.new(0, 6)
	rankedTierCorner.Parent = rankedTierLabel

	local mapPreview = Instance.new("Frame")
	mapPreview.Name = "MapPreview"
	mapPreview.Position = UDim2.fromOffset(14, 72)
	mapPreview.Size = UDim2.fromOffset(380, 208)
	mapPreview.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	mapPreview.BorderSizePixel = 0
	mapPreview.Parent = roomPanel
	local mapPreviewCorner = Instance.new("UICorner")
	mapPreviewCorner.CornerRadius = UDim.new(0, 8)
	mapPreviewCorner.Parent = mapPreview
	local mapPreviewStroke = Instance.new("UIStroke")
	mapPreviewStroke.Thickness = 1
	mapPreviewStroke.Color = Color3.fromRGB(75, 92, 120)
	mapPreviewStroke.Parent = mapPreview

	local mapPreviewTitle = Instance.new("TextLabel")
	mapPreviewTitle.Name = "Title"
	mapPreviewTitle.BackgroundTransparency = 1
	mapPreviewTitle.Position = UDim2.fromOffset(10, 8)
	mapPreviewTitle.Size = UDim2.new(1, -20, 0, 14)
	mapPreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewTitle.Font = Enum.Font.GothamSemibold
	mapPreviewTitle.TextSize = 10
	mapPreviewTitle.TextColor3 = Color3.fromRGB(190, 205, 225)
	mapPreviewTitle.Text = "PREVIEW"
	mapPreviewTitle.Parent = mapPreview

	local mapPreviewLabel = Instance.new("TextLabel")
	mapPreviewLabel.Name = "Label"
	mapPreviewLabel.BackgroundTransparency = 1
	mapPreviewLabel.Position = UDim2.fromOffset(10, 26)
	mapPreviewLabel.Size = UDim2.new(1, -20, 0, 16)
	mapPreviewLabel.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewLabel.TextYAlignment = Enum.TextYAlignment.Top
	mapPreviewLabel.Font = Enum.Font.GothamBold
	mapPreviewLabel.TextSize = 12
	mapPreviewLabel.TextWrapped = true
	mapPreviewLabel.TextColor3 = Color3.fromRGB(235, 240, 245)
	mapPreviewLabel.Text = formatMapSummary(MAPS[1])
	mapPreviewLabel.Parent = mapPreview

	local mapPreviewImage = Instance.new("Frame")
	mapPreviewImage.Name = "MapImagePlaceholder"
	mapPreviewImage.AnchorPoint = Vector2.new(0.5, 0)
	mapPreviewImage.Position = UDim2.new(0.5, 0, 0, 46)
	mapPreviewImage.Size = UDim2.fromOffset(200, 150)
	mapPreviewImage.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	mapPreviewImage.BorderSizePixel = 0
	mapPreviewImage.Parent = mapPreview
	local mapPreviewImageCorner = Instance.new("UICorner")
	mapPreviewImageCorner.CornerRadius = UDim.new(0, 6)
	mapPreviewImageCorner.Parent = mapPreviewImage
	local mapPreviewImageStroke = Instance.new("UIStroke")
	mapPreviewImageStroke.Thickness = 1
	mapPreviewImageStroke.Color = Color3.fromRGB(83, 101, 128)
	mapPreviewImageStroke.Parent = mapPreviewImage
	local mapPreviewImageLabel = Instance.new("TextLabel")
	mapPreviewImageLabel.Name = "ImageLabel"
	mapPreviewImageLabel.BackgroundTransparency = 1
	mapPreviewImageLabel.Size = UDim2.fromScale(1, 1)
	mapPreviewImageLabel.Font = Enum.Font.GothamBold
	mapPreviewImageLabel.TextSize = 12
	mapPreviewImageLabel.TextColor3 = Color3.fromRGB(210, 220, 236)
	mapPreviewImageLabel.TextWrapped = true
	mapPreviewImageLabel.Text = "4:3\nMAP IMAGE"
	mapPreviewImageLabel.Parent = mapPreviewImage

	local setPwdBox = Instance.new("TextBox")
	setPwdBox.Name = "SetPasswordBox"
	setPwdBox.Position = UDim2.fromOffset(14, 184)
	setPwdBox.Size = UDim2.fromOffset(256, 32)
	setPwdBox.PlaceholderText = "Set Password (4 digit)"
	setPwdBox.Text = ""
	setPwdBox.ClearTextOnFocus = false
	setPwdBox.TextColor3 = Color3.fromRGB(235, 240, 245)
	setPwdBox.Font = Enum.Font.Gotham
	setPwdBox.TextSize = 12
	setPwdBox.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
	setPwdBox.BorderSizePixel = 0
	setPwdBox.Parent = roomPanel

	local setPwdCorner = Instance.new("UICorner")
	setPwdCorner.CornerRadius = UDim.new(0, 6)
	setPwdCorner.Parent = setPwdBox

	local setPwdBtn = Instance.new("TextButton")
	setPwdBtn.Name = "SetPasswordButton"
	setPwdBtn.Position = UDim2.fromOffset(278, 184)
	setPwdBtn.Size = UDim2.fromOffset(116, 32)
	styleButton(setPwdBtn, "Set PWD")
	setPwdBtn.TextSize = 12
	setPwdBtn.Parent = roomPanel

	local readyBtn = Instance.new("TextButton")
	readyBtn.Name = "ReadyButton"
	readyBtn.Position = UDim2.fromOffset(14, 264)
	readyBtn.Size = UDim2.fromOffset(380, 36)
	styleButton(readyBtn, "READY")
	readyBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
	readyBtn.Parent = roomPanel

	local startBtn = Instance.new("TextButton")
	startBtn.Name = "StartButton"
	startBtn.Position = UDim2.fromOffset(14, 264)
	startBtn.Size = UDim2.fromOffset(380, 36)
	styleButton(startBtn, "MULAI PERMAINAN")
	startBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
	startBtn.Visible = false
	startBtn.Parent = roomPanel

	local cancelStartBtn = Instance.new("TextButton")
	cancelStartBtn.Name = "CancelStartButton"
	cancelStartBtn.Position = UDim2.fromOffset(14, 272)
	cancelStartBtn.Size = UDim2.fromOffset(380, 28)
	styleButton(cancelStartBtn, "BATALKAN COUNTDOWN")
	cancelStartBtn.TextSize = 12
	cancelStartBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	cancelStartBtn.Visible = false
	cancelStartBtn.Parent = roomPanel

	local leaveRoomBtn = Instance.new("TextButton")
	leaveRoomBtn.Name = "LeaveRoomButton"
	leaveRoomBtn.Position = UDim2.fromOffset(14, 302)
	leaveRoomBtn.Size = UDim2.fromOffset(380, 30)
	styleButton(leaveRoomBtn, "Keluar Room")
	leaveRoomBtn.TextSize = 12
	leaveRoomBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	leaveRoomBtn.Parent = roomPanel

	local inviteBtn = Instance.new("TextButton")
	inviteBtn.Name = "InviteButton"
	inviteBtn.Position = UDim2.fromOffset(454, 446)
	inviteBtn.Size = UDim2.fromOffset(420, 30)
	styleButton(inviteBtn, "INVITE PLAYER")
	inviteBtn.TextSize = 12
	inviteBtn.BackgroundColor3 = Color3.fromRGB(52, 92, 128)
	inviteBtn.Visible = false
	inviteBtn.Parent = roomPanel

	local inviteDropdown = Instance.new("Frame")
	inviteDropdown.Name = "InviteDropdown"
	inviteDropdown.Position = UDim2.fromOffset(454, 220)
	inviteDropdown.Size = UDim2.fromOffset(420, 220)
	inviteDropdown.BackgroundColor3 = Color3.fromRGB(26, 33, 43)
	inviteDropdown.BorderSizePixel = 0
	inviteDropdown.Visible = false
	inviteDropdown.Active = true
	inviteDropdown.ZIndex = 24
	inviteDropdown.Parent = roomPanel
	local inviteDropdownCorner = Instance.new("UICorner")
	inviteDropdownCorner.CornerRadius = UDim.new(0, 8)
	inviteDropdownCorner.Parent = inviteDropdown
	local inviteDropdownStroke = Instance.new("UIStroke")
	inviteDropdownStroke.Thickness = 1
	inviteDropdownStroke.Color = Color3.fromRGB(78, 100, 128)
	inviteDropdownStroke.Parent = inviteDropdown

	local inviteList = Instance.new("ScrollingFrame")
	inviteList.Name = "InviteList"
	inviteList.Size = UDim2.new(1, -8, 1, -8)
	inviteList.Position = UDim2.fromOffset(4, 4)
	inviteList.BackgroundTransparency = 1
	inviteList.BorderSizePixel = 0
	inviteList.ScrollBarThickness = 4
	inviteList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	inviteList.CanvasSize = UDim2.fromOffset(0, 0)
	inviteList.ZIndex = 25
	inviteList.Parent = inviteDropdown
	local inviteListLayout = Instance.new("UIListLayout")
	inviteListLayout.Padding = UDim.new(0, 4)
	inviteListLayout.Parent = inviteList

	local kickNameBox = Instance.new("TextBox")
	kickNameBox.Name = "KickNameBox"
	kickNameBox.Position = UDim2.fromOffset(14, 272)
	kickNameBox.Size = UDim2.fromOffset(256, 28)
	kickNameBox.PlaceholderText = "Nama pemain untuk di-kick"
	kickNameBox.Text = ""
	kickNameBox.ClearTextOnFocus = false
	kickNameBox.TextColor3 = Color3.fromRGB(235, 240, 245)
	kickNameBox.Font = Enum.Font.Gotham
	kickNameBox.TextSize = 12
	kickNameBox.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
	kickNameBox.BorderSizePixel = 0
	kickNameBox.Visible = false
	kickNameBox.Parent = roomPanel
	local kickNameCorner = Instance.new("UICorner")
	kickNameCorner.CornerRadius = UDim.new(0, 6)
	kickNameCorner.Parent = kickNameBox

	local kickBtn = Instance.new("TextButton")
	kickBtn.Name = "KickButton"
	kickBtn.Position = UDim2.fromOffset(278, 272)
	kickBtn.Size = UDim2.fromOffset(116, 28)
	styleButton(kickBtn, "KICK")
	kickBtn.TextSize = 12
	kickBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	kickBtn.Visible = false
	kickBtn.Parent = roomPanel

	local countdownOverlay = Instance.new("Frame")
	countdownOverlay.Name = "CountdownOverlay"
	countdownOverlay.Size = UDim2.fromScale(1, 1)
	countdownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	countdownOverlay.BackgroundTransparency = 0.4
	countdownOverlay.ZIndex = 10
	countdownOverlay.Visible = false
	countdownOverlay.Parent = gui

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	countdownLabel.Position = UDim2.fromScale(0.5, 0.45)
	countdownLabel.Size = UDim2.fromOffset(400, 120)
	countdownLabel.Text = "5"
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.TextSize = 96
	countdownLabel.TextColor3 = Color3.fromRGB(255, 80, 60)
	countdownLabel.ZIndex = 11
	countdownLabel.Parent = countdownOverlay

	local cancelCountdownBtn = Instance.new("TextButton")
	cancelCountdownBtn.Name = "CancelCountdown"
	cancelCountdownBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	cancelCountdownBtn.Position = UDim2.fromScale(0.5, 0.70)
	cancelCountdownBtn.Size = UDim2.fromOffset(220, 38)
	styleButton(cancelCountdownBtn, "BATALKAN")
	cancelCountdownBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	cancelCountdownBtn.ZIndex = 11
	cancelCountdownBtn.Visible = false
	cancelCountdownBtn.Parent = countdownOverlay

	local invitePopup = Instance.new("Frame")
	invitePopup.Name = "InvitePopup"
	invitePopup.AnchorPoint = Vector2.new(0.5, 0)
	invitePopup.Position = UDim2.new(0.5, 0, 0, 18)
	invitePopup.Size = UDim2.fromOffset(408, 66)
	invitePopup.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
	invitePopup.BorderSizePixel = 0
	invitePopup.ZIndex = 12
	invitePopup.Visible = false
	invitePopup.Parent = gui
	local invitePopupScale = Instance.new("UIScale")
	invitePopupScale.Parent = invitePopup
	local invitePopupCorner = Instance.new("UICorner")
	invitePopupCorner.CornerRadius = UDim.new(0, 8)
	invitePopupCorner.Parent = invitePopup
	local invitePopupStroke = Instance.new("UIStroke")
	invitePopupStroke.Thickness = 1
	invitePopupStroke.Color = Color3.fromRGB(86, 128, 170)
	invitePopupStroke.Parent = invitePopup

	local invitePopupText = Instance.new("TextLabel")
	invitePopupText.Name = "Text"
	invitePopupText.BackgroundTransparency = 1
	invitePopupText.Position = UDim2.fromOffset(10, 7)
	invitePopupText.Size = UDim2.fromOffset(286, 50)
	invitePopupText.TextXAlignment = Enum.TextXAlignment.Left
	invitePopupText.TextYAlignment = Enum.TextYAlignment.Center
	invitePopupText.Font = Enum.Font.GothamSemibold
	invitePopupText.TextSize = 11
	invitePopupText.TextWrapped = true
	invitePopupText.TextColor3 = Color3.fromRGB(235, 240, 245)
	invitePopupText.Text = "Invite"
	invitePopupText.ZIndex = 13
	invitePopupText.Parent = invitePopup

	local inviteAcceptBtn = Instance.new("TextButton")
	inviteAcceptBtn.Name = "AcceptButton"
	inviteAcceptBtn.Position = UDim2.fromOffset(302, 9)
	inviteAcceptBtn.Size = UDim2.fromOffset(96, 22)
	styleButton(inviteAcceptBtn, "TERIMA")
	inviteAcceptBtn.TextSize = 11
	inviteAcceptBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 70)
	inviteAcceptBtn.ZIndex = 13
	inviteAcceptBtn.Parent = invitePopup

	local inviteDeclineBtn = Instance.new("TextButton")
	inviteDeclineBtn.Name = "DeclineButton"
	inviteDeclineBtn.Position = UDim2.fromOffset(302, 35)
	inviteDeclineBtn.Size = UDim2.fromOffset(96, 22)
	styleButton(inviteDeclineBtn, "TOLAK")
	inviteDeclineBtn.TextSize = 11
	inviteDeclineBtn.BackgroundColor3 = Color3.fromRGB(120, 46, 46)
	inviteDeclineBtn.ZIndex = 13
	inviteDeclineBtn.Parent = invitePopup

	local function updateInvitePopupLayout()
		local topLeftInset, _ = resolveSafeInsets()
		local viewport = Vector2.new(1920, 1080)
		local camera = Workspace.CurrentCamera
		if camera and typeof(camera.ViewportSize) == "Vector2" then
			viewport = camera.ViewportSize
		end
		local scaleX = (viewport.X - 24) / 408
		local scaleY = (viewport.Y - (topLeftInset.Y + 24)) / 66
		invitePopupScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.68, 1)
		invitePopup.Position = UDim2.new(0.5, 0, 0, 10 + topLeftInset.Y)
	end
	updateInvitePopupLayout()
	if Workspace.CurrentCamera then
		table.insert(self._connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateInvitePopupLayout))
	end

	local mapIndex = 1
	local currentRoomId = nil
	local selectedRoomId = nil
	local selectedPreviewRenderKey = nil
	local pendingPasswordRoomId = nil
	local dragging = false
	local dragStart = nil
	local panelStart = nil
	local dragInput = nil

	local function roomRowText(room)
		if room.inGame then
			return string.format("  Room %d | %s | %d/%d | IN GAME", room.roomId, room.hostName or "?", room.playerCount or 0, room.maxPlayers or 4)
		end
		if room.starting then
			return string.format("  Room %d | %s | %d/%d | COUNTDOWN", room.roomId, room.hostName or "?", room.playerCount or 0, room.maxPlayers or 4)
		end
		if (room.playerCount or 0) == 0 then
			return string.format("  Room %d | Kosong", room.roomId)
		end
		local lock = room.hasPassword and "[PWD] " or ""
		return string.format(
			"  %sRoom %d | Host: %s | %d/%d | %s | %s",
			lock,
			room.roomId,
			room.hostName or "?",
			room.playerCount or 0,
			room.maxPlayers or 4,
			room.mode or "Classic",
			room.difficulty or "-"
		)
	end

	local function resolveLocalTierText()
		local localPlayer = Players.LocalPlayer
		if not localPlayer then
			return "UNRANKED"
		end
		for _, attrName in ipairs({ "RankTier", "Tier", "RankedTier", "HostTier" }) do
			local value = localPlayer:GetAttribute(attrName)
			if value ~= nil and tostring(value) ~= "" then
				return string.upper(tostring(value))
			end
		end
		return "UNRANKED"
	end

	local function syncMapIndex(mapId)
		if type(mapId) ~= "string" or mapId == "" then
			return MAPS[mapIndex]
		end
		for idx, mapName in ipairs(MAPS) do
			if mapName == mapId then
				mapIndex = idx
				break
			end
		end
		return mapId
	end

	local function resolveEffectiveMapId(state, room)
		if type(room) == "table" and type(room.mapId) == "string" and room.mapId ~= "" then
			return syncMapIndex(room.mapId)
		end
		if type(state) == "table" and type(state.selectedMap) == "string" and state.selectedMap ~= "" then
			return syncMapIndex(state.selectedMap)
		end
		return syncMapIndex(MAPS[mapIndex])
	end

	local function updateMapPreview(modeText, mapName)
		modeText = modeText or "Classic"
		mapName = mapName or resolveEffectiveMapId(self:GetRoomBrowserState(), nil) or MAPS[mapIndex]
		if modeText == "Ranked" then
			mapPreview.BackgroundColor3 = Color3.fromRGB(46, 32, 62)
			mapPreviewStroke.Color = Color3.fromRGB(140, 102, 196)
			mapPreviewTitle.Text = "RANKED PREVIEW"
			mapPreviewLabel.Text = "TIER HOST: " .. resolveLocalTierText()
			mapPreviewImageLabel.Text = "4:3\nRANKED ARENA"
		else
			mapPreview.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
			mapPreviewStroke.Color = Color3.fromRGB(75, 92, 120)
			mapPreviewTitle.Text = "MAP PREVIEW"
			mapPreviewLabel.Text = formatMapSummary(mapName)
			mapPreviewImageLabel.Text = "4:3\n" .. getMapDisplayName(mapName)
		end
	end

	local function renderRoomSelectionPreview(rooms)
		if not roomPreviewPanel or not roomPreviewTitle or not roomPreviewInfo or not roomPreviewMapLabel or not roomPreviewPlayersList then
			return
		end
		local selectedRoom = nil
		if selectedRoomId ~= nil then
			for _, room in ipairs(rooms or {}) do
				if tostring(room.roomId) == tostring(selectedRoomId) then
					selectedRoom = room
					break
				end
			end
		end

		local nextRenderKey = "none"
		if selectedRoom then
			local modeText = tostring(selectedRoom.mode or "Classic")
			local mapId = tostring(selectedRoom.mapId or "UnknownMap")
			local roomState = selectedRoom.inGame and "ingame" or (selectedRoom.starting and "starting" or "idle")
			local players = type(selectedRoom.players) == "table" and selectedRoom.players or {}
			local playerParts = {}
			for _, info in ipairs(players) do
				table.insert(playerParts, string.format("%s:%s:%s", tostring(info.userId), info.isReady and "1" or "0", info.isHost and "1" or "0"))
			end
			nextRenderKey = string.format(
				"%s|%s|%s|%s|%s|%s",
				tostring(selectedRoom.roomId),
				tostring(selectedRoom.hostName or "-"),
				modeText,
				mapId,
				roomState,
				table.concat(playerParts, ",")
			)
		end
		if selectedPreviewRenderKey == nextRenderKey then
			return
		end
		selectedPreviewRenderKey = nextRenderKey

		for _, child in ipairs(roomPreviewPlayersList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end

		if not selectedRoom then
			roomPreviewTitle.Text = "PREVIEW ROOM"
			roomPreviewInfo.Text = "Klik room di daftar untuk lihat detail."
			roomPreviewMapLabel.Text = "Belum ada room dipilih."
			roomPreviewMap.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
			roomPreviewMapStroke.Color = Color3.fromRGB(72, 90, 116)
			local empty = Instance.new("TextLabel")
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, -12, 1, 0)
			empty.TextXAlignment = Enum.TextXAlignment.Center
			empty.TextYAlignment = Enum.TextYAlignment.Center
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 12
			empty.TextColor3 = Color3.fromRGB(182, 198, 216)
			empty.Text = "Belum ada room dipilih."
			empty.Parent = roomPreviewPlayersList
			return
		end

		local modeText = tostring(selectedRoom.mode or "Classic")
		local mapId = tostring(selectedRoom.mapId or "UnknownMap")
		local playerCount = selectedRoom.playerCount
		if playerCount == nil and type(selectedRoom.players) == "table" then
			playerCount = #selectedRoom.players
		end
		playerCount = playerCount or 0
		local maxPlayers = selectedRoom.maxPlayers or 4
		local roomState = selectedRoom.inGame and "IN GAME" or (selectedRoom.starting and "COUNTDOWN" or "MENUNGGU")

		roomPreviewTitle.Text = string.format("PREVIEW ROOM #%s", tostring(selectedRoom.roomId or "?"))
		roomPreviewInfo.Text = string.format(
			"Host: %s | Mode: %s | Player: %d/%d | Status: %s",
			tostring(selectedRoom.hostName or "-"),
			modeText,
			playerCount,
			maxPlayers,
			roomState
		)
		roomPreviewMapLabel.Text = formatMapSummary(mapId)
		if modeText == "Ranked" then
			roomPreviewMap.BackgroundColor3 = Color3.fromRGB(36, 28, 52)
			roomPreviewMapStroke.Color = Color3.fromRGB(124, 96, 170)
		else
			roomPreviewMap.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
			roomPreviewMapStroke.Color = Color3.fromRGB(72, 90, 116)
		end

		local players = type(selectedRoom.players) == "table" and selectedRoom.players or {}
		if #players == 0 then
			local empty = Instance.new("TextLabel")
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, -12, 1, 0)
			empty.TextXAlignment = Enum.TextXAlignment.Center
			empty.TextYAlignment = Enum.TextYAlignment.Center
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 12
			empty.TextColor3 = Color3.fromRGB(182, 198, 216)
			empty.Text = "Data pemain belum tersedia."
			empty.Parent = roomPreviewPlayersList
			return
		end

		for _, info in ipairs(players) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
			card.BorderSizePixel = 0
			card.Size = UDim2.fromOffset(220, 78)
			card.Parent = roomPreviewPlayersList
			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 8)
			cardCorner.Parent = card
			local cardStroke = Instance.new("UIStroke")
			cardStroke.Thickness = info.isReady and 2 or 1
			cardStroke.Color = info.isReady and Color3.fromRGB(82, 179, 108) or Color3.fromRGB(74, 88, 112)
			cardStroke.Parent = card

			local preview = Instance.new("ViewportFrame")
			preview.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
			preview.BorderSizePixel = 0
			preview.Position = UDim2.fromOffset(6, 6)
			preview.Size = UDim2.fromOffset(54, 66)
			preview.Parent = card
			local previewCorner = Instance.new("UICorner")
			previewCorner.CornerRadius = UDim.new(0, 6)
			previewCorner.Parent = preview
			renderCharacterPreview(preview, info.userId)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.fromOffset(66, 7)
			nameLabel.Size = UDim2.fromOffset(146, 32)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextYAlignment = Enum.TextYAlignment.Top
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 10
			nameLabel.TextWrapped = true
			nameLabel.TextColor3 = Color3.fromRGB(236, 240, 245)
			local roleTag = info.isHost and "[HOST]" or "[MEMBER]"
			nameLabel.Text = string.format("%s %s", roleTag, tostring(info.displayName or info.name or "?"))
			nameLabel.Parent = card

			local stateLabel = Instance.new("TextLabel")
			stateLabel.BackgroundTransparency = 1
			stateLabel.Position = UDim2.fromOffset(66, 44)
			stateLabel.Size = UDim2.fromOffset(146, 20)
			stateLabel.TextXAlignment = Enum.TextXAlignment.Left
			stateLabel.Font = Enum.Font.GothamSemibold
			stateLabel.TextSize = 10
			stateLabel.TextColor3 = info.isReady and Color3.fromRGB(120, 220, 145) or Color3.fromRGB(255, 195, 120)
			stateLabel.Text = info.isReady and "READY" or "NOT READY"
			stateLabel.Parent = card
		end
	end

	local function renderRoomList(rooms)
		local roomIdSet = {}
		for _, room in ipairs(rooms or {}) do
			roomIdSet[tostring(room.roomId)] = true
		end
		if selectedRoomId and not roomIdSet[tostring(selectedRoomId)] then
			selectedRoomId = nil
		end

		for _, child in ipairs(roomList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, room in ipairs(rooms or {}) do
			local row = Instance.new("TextButton")
			row.Name = "Room_" .. tostring(room.roomId)
			row.Size = UDim2.new(1, -8, 0, 36)
			row.LayoutOrder = room.roomId
			row.BorderSizePixel = 0
			row.Font = Enum.Font.Gotham
			row.TextSize = 13
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Text = roomRowText(room)
			row:SetAttribute("RoomId", room.roomId)
			row:SetAttribute("InGame", room.inGame == true)
			row:SetAttribute("Starting", room.starting == true)
			row:SetAttribute("HasPassword", room.hasPassword == true)
			if row:GetAttribute("InGame") then
				row.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
				row.TextColor3 = Color3.fromRGB(180, 80, 80)
				row.AutoButtonColor = false
			elseif row:GetAttribute("Starting") then
				row.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
				row.TextColor3 = Color3.fromRGB(255, 200, 120)
				row.AutoButtonColor = false
			else
				row.BackgroundColor3 = Color3.fromRGB(38, 47, 62)
				row.TextColor3 = Color3.fromRGB(235, 240, 245)
			end
			if tostring(room.roomId) == tostring(selectedRoomId) then
				row.BackgroundColor3 = Color3.fromRGB(63, 92, 138)
			end
			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 6)
			rowCorner.Parent = row

			connectButtonPress(row, function()
				selectedRoomId = row:GetAttribute("RoomId")
				if row:GetAttribute("InGame") then
					statusLabel.Text = string.format("Room #%s sedang berlangsung.", tostring(selectedRoomId))
				elseif row:GetAttribute("Starting") then
					statusLabel.Text = string.format("Room #%s sedang countdown.", tostring(selectedRoomId))
				else
					statusLabel.Text = string.format("Room #%s dipilih. Klik JOIN untuk masuk.", tostring(selectedRoomId))
				end
				renderRoomSelectionPreview(rooms)
			end)
			self:_setSelectableStyle(row)
			row.Parent = roomList
		end
		renderRoomSelectionPreview(rooms)
	end
	logRoomClickConnected("JoinRoomButton(RoomRowActivated)")

	local function rebuildInviteList()
		for _, child in ipairs(inviteList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local state = self:GetRoomBrowserState() or {}
		local currentRoom = state.currentRoom or {}
		local inRoomByUserId = {}
		for _, info in ipairs(currentRoom.players or {}) do
			if info.userId ~= nil then
				inRoomByUserId[tostring(info.userId)] = true
			end
		end

		local inviteAllRow = Instance.new("TextButton")
		inviteAllRow.Name = "InviteAll"
		inviteAllRow.Size = UDim2.new(1, -4, 0, 24)
		inviteAllRow.BackgroundColor3 = Color3.fromRGB(58, 98, 136)
		inviteAllRow.BorderSizePixel = 0
		inviteAllRow.Font = Enum.Font.GothamBold
		inviteAllRow.TextSize = 12
		inviteAllRow.TextColor3 = Color3.fromRGB(245, 245, 245)
		inviteAllRow.Text = "INVITE ALL (BROADCAST)"
		inviteAllRow.ZIndex = 26
		inviteAllRow.Parent = inviteList
		local inviteAllCorner = Instance.new("UICorner")
		inviteAllCorner.CornerRadius = UDim.new(0, 6)
		inviteAllCorner.Parent = inviteAllRow
		connectButtonPress(inviteAllRow, function()
			self:RoomBrowserInviteBroadcastToRoom()
			statusLabel.Text = "Broadcast invite dikirim."
		end)
		self:_setSelectableStyle(inviteAllRow)

		for _, lobbyPlayer in ipairs(state.lobbyPlayers or {}) do
			local userId = lobbyPlayer.userId
			if userId ~= nil and not inRoomByUserId[tostring(userId)] then
				local nameText = tostring(lobbyPlayer.displayName or lobbyPlayer.name or ("User " .. tostring(userId)))
				local row = Instance.new("TextButton")
				row.Name = "Invite_" .. tostring(userId)
				row.Size = UDim2.new(1, -4, 0, 24)
				row.BackgroundColor3 = Color3.fromRGB(40, 52, 68)
				row.BorderSizePixel = 0
				row.Font = Enum.Font.Gotham
				row.TextSize = 12
				row.TextColor3 = Color3.fromRGB(230, 235, 245)
				row.TextXAlignment = Enum.TextXAlignment.Left
				row.Text = "  " .. nameText
				row.ZIndex = 26
				row.Parent = inviteList
				local rowCorner = Instance.new("UICorner")
				rowCorner.CornerRadius = UDim.new(0, 6)
				rowCorner.Parent = row
				connectButtonPress(row, function()
					self:RoomBrowserInvitePlayerToRoom(userId)
					statusLabel.Text = string.format("Invite terkirim ke %s.", nameText)
				end)
				self:_setSelectableStyle(row)
			end
		end
	end

	connectButtonPress(classicBtn, function()
		self._roomBrowserModeView = "Selected"
		self:RoomBrowserSelectMode("Classic")
		task.delay(0.1, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(allModesBtn, function()
		self._roomBrowserModeView = "All"
		if self._roomBrowser then
			self._roomBrowser:RequestSnapshot()
			self._roomBrowser:RequestRoomList()
		end
	end)

	connectButtonPress(rankedBtn, function()
		self._roomBrowserModeView = "Selected"
		self:RoomBrowserSelectMode("Ranked")
		task.delay(0.1, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(refreshBtn, function()
		if self._roomBrowser then
			self._roomBrowser:RequestSnapshot()
			self._roomBrowser:RequestRoomList()
		end
	end)

	connectButtonPress(createRoomBtn, function()
		self:RoomBrowserCreateRoom()
		if self._roomBrowser then
			task.delay(0.1, function()
				self._roomBrowser:RequestSnapshot()
				self._roomBrowser:RequestRoomList()
			end)
		end
	end)
	logRoomClickConnected("CreateRoomButton")

	connectButtonPress(queueBtn, function()
		local state = self:GetRoomBrowserState() or {}
		local rooms = state.rooms or {}
		local selectedRoom = nil
		for _, room in ipairs(rooms) do
			if tostring(room.roomId) == tostring(selectedRoomId) then
				selectedRoom = room
				break
			end
		end
		if not selectedRoom then
			statusLabel.Text = "Pilih room dulu, lalu klik JOIN."
			return
		end
		if selectedRoom.inGame or selectedRoom.starting then
			statusLabel.Text = "Room sedang berjalan/countdown."
			if self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
				self._kickNoticeVisible = true
				self._roomBrowserWidgets.KickNoticeText.Text = "PERMAINAN SEDANG BERLANGSUNG"
				self._roomBrowserWidgets.KickNoticeModal.Visible = true
			end
			return
		end
		if selectedRoom.hasPassword then
			pendingPasswordRoomId = selectedRoom.roomId
			self._passwordJoinPendingRoomId = selectedRoom.roomId
			self._passwordJoinSubmitting = false
			passwordInput.Text = ""
			passwordModal.Visible = true
			statusLabel.Text = "Room butuh password."
			return
		end
		pendingPasswordRoomId = nil
		self._passwordJoinPendingRoomId = nil
		self._passwordJoinSubmitting = false
		self:RoomBrowserJoinRoom(selectedRoom.roomId, nil)
	end)

	connectButtonPress(passwordJoinBtn, function()
		if not pendingPasswordRoomId then
			passwordModal.Visible = false
			return
		end
		local value = tostring(passwordInput.Text or ""):gsub("%s+", "")
		if value == "" then
			statusLabel.Text = "Password belum diisi."
			return
		end
		self._passwordJoinSubmitting = true
		passwordModal.Visible = false
		self:RoomBrowserJoinRoom(pendingPasswordRoomId, value)
		pendingPasswordRoomId = nil
	end)

	connectButtonPress(passwordCancelBtn, function()
		passwordModal.Visible = false
		pendingPasswordRoomId = nil
		self._passwordJoinPendingRoomId = nil
		self._passwordJoinSubmitting = false
	end)

	connectButtonPress(kickNoticeOk, function()
		if self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
			self._roomBrowserWidgets.KickNoticeModal.Visible = false
		end
		self._kickNoticeVisible = false
	end)

	connectButtonPress(quickClassicBtn, function()
		local state = self:GetRoomBrowserState() or {}
		local rooms = state.rooms or {}
		local bestRoom = nil
		for _, room in ipairs(rooms) do
			local modeName = tostring(room.mode or "Classic")
			if modeName:lower() == "classic" and room.inGame ~= true and room.starting ~= true and (room.playerCount or 0) < (room.maxPlayers or 4) and room.hasPassword ~= true then
				if not bestRoom then
					bestRoom = room
				else
					local currentCount = room.playerCount or 0
					local bestCount = bestRoom.playerCount or 0
					if currentCount > bestCount or (currentCount == bestCount and tonumber(room.roomId) < tonumber(bestRoom.roomId)) then
						bestRoom = room
					end
				end
			end
		end
		if not bestRoom then
			statusLabel.Text = "Tidak ada room Classic publik yang bisa di-quick join."
			return
		end
		selectedRoomId = bestRoom.roomId
		self:RoomBrowserJoinRoom(bestRoom.roomId, nil)
	end)

	connectButtonPress(quickRankedBtn, function()
		local state = self:GetRoomBrowserState() or {}
		local rooms = state.rooms or {}
		local bestRoom = nil
		for _, room in ipairs(rooms) do
			local modeName = tostring(room.mode or "")
			if modeName:lower() == "ranked" and room.inGame ~= true and room.starting ~= true and (room.playerCount or 0) < (room.maxPlayers or 4) and room.hasPassword ~= true then
				if not bestRoom then
					bestRoom = room
				else
					local currentCount = room.playerCount or 0
					local bestCount = bestRoom.playerCount or 0
					if currentCount > bestCount or (currentCount == bestCount and tonumber(room.roomId) < tonumber(bestRoom.roomId)) then
						bestRoom = room
					end
				end
			end
		end
		if not bestRoom then
			statusLabel.Text = "Tidak ada room Ranked publik yang bisa di-quick join."
			return
		end
		selectedRoomId = bestRoom.roomId
		self:RoomBrowserJoinRoom(bestRoom.roomId, nil)
	end)

	connectButtonPress(modeSelector, function()
		self._inviteDropdownOpen = false
		inviteDropdown.Visible = false
		self._roomModeDropdownOpen = not self._roomModeDropdownOpen
		self._roomMapDropdownOpen = false
		modeDropdown.Visible = self._roomModeDropdownOpen
		mapDropdown.Visible = false
	end)

	connectButtonPress(modeClassicBtn, function()
		self._roomModeDropdownOpen = false
		modeDropdown.Visible = false
		self._roomMapDropdownOpen = false
		mapDropdown.Visible = false
		self:RoomBrowserSelectMode("Classic")
		task.delay(0.08, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(modeRankedBtn, function()
		self._roomModeDropdownOpen = false
		modeDropdown.Visible = false
		self._roomMapDropdownOpen = false
		mapDropdown.Visible = false
		self:RoomBrowserSelectMode("Ranked")
		task.delay(0.08, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(mapSelector, function()
		self._inviteDropdownOpen = false
		inviteDropdown.Visible = false
		self._roomMapDropdownOpen = not self._roomMapDropdownOpen
		self._roomModeDropdownOpen = false
		modeDropdown.Visible = false
		mapDropdown.Visible = self._roomMapDropdownOpen
	end)

	for idx, btn in ipairs(mapOptionButtons) do
		connectButtonPress(btn, function()
			local selectedMapId = syncMapIndex(MAPS[idx])
			mapSelector.Text = "MAP: " .. tostring(selectedMapId)
			self._roomMapDropdownOpen = false
			mapDropdown.Visible = false
			if self._roomBrowser then
				self._roomBrowser:SelectMap(selectedMapId)
			end
			updateMapPreview("Classic", selectedMapId)
		end)
	end

	connectButtonPress(setPwdBtn, function()
		self:RoomBrowserSetPassword(setPwdBox.Text)
	end)

	connectButtonPress(readyBtn, function()
		local state = self:GetRoomBrowserState() or {}
		local room = state.currentRoom
		if not (room and room.roomId) then
			return
		end
		local players = type(room.players) == "table" and room.players or {}
		if #players == 0 then
			for _, listedRoom in ipairs(state.rooms or {}) do
				if tostring(listedRoom.roomId) == tostring(room.roomId) and type(listedRoom.players) == "table" then
					players = listedRoom.players
					break
				end
			end
		end
		local playerCount = room.playerCount
		if playerCount == nil then
			playerCount = #players
		end
		playerCount = tonumber(playerCount) or 0
		if playerCount <= 0 then
			statusLabel.Text = "Sinkronisasi room belum lengkap. Tunggu snapshot lalu coba lagi."
			return
		end
		local allReadyComputed = state.allReady == true
		if state.isHost == true and state.allReady == nil and #players > 0 then
			allReadyComputed = true
			for _, info in ipairs(players) do
				if not info.isHost and info.isReady ~= true then
					allReadyComputed = false
					break
				end
			end
		end

		if state.isHost == true then
			if state.matchStarting == true then
				self:RoomBrowserCancelHostStart()
				return
			end
			if playerCount == 1 or allReadyComputed == true then
				local roomMode = room.mode or state.selectedMode
				self:RoomBrowserHostStart(resolveEffectiveMapId(state, room), nil, roomMode)
			end
			return
		end
		self:RoomBrowserSetReady(not (state.isReady == true))
	end)
	logRoomClickConnected("ReadyButton")

	connectButtonPress(startBtn, function()
		local state = self:GetRoomBrowserState() or {}
		if state.isHost == true then
			self:RoomBrowserHostStart(resolveEffectiveMapId(state, state.currentRoom), nil, state.selectedMode)
		end
	end)
	logRoomClickConnected("StartButton")

	connectButtonPress(cancelStartBtn, function()
		self:RoomBrowserCancelHostStart()
	end)

	connectButtonPress(cancelCountdownBtn, function()
		self:RoomBrowserCancelHostStart()
	end)

	connectButtonPress(leaveRoomBtn, function()
		self:RoomBrowserLeaveRoom()
	end)

	connectButtonPress(inviteBtn, function()
		self._roomModeDropdownOpen = false
		modeDropdown.Visible = false
		self._roomMapDropdownOpen = false
		mapDropdown.Visible = false
		self._inviteDropdownOpen = not self._inviteDropdownOpen
		inviteDropdown.Visible = self._inviteDropdownOpen
		if self._inviteDropdownOpen then
			rebuildInviteList()
		end
	end)

	connectButtonPress(inviteAcceptBtn, function()
		local inviteId = self._activeInviteId
		if inviteId then
			self:RoomBrowserRespondRoomInvite(inviteId, true)
		end
		self:_hideRoomInvitePopup()
	end)

	connectButtonPress(inviteDeclineBtn, function()
		local inviteId = self._activeInviteId
		if inviteId then
			self:RoomBrowserRespondRoomInvite(inviteId, false)
		end
		self:_hideRoomInvitePopup()
	end)

	connectButtonPress(kickBtn, function()
		local state = self:GetRoomBrowserState() or {}
		if state.isHost ~= true then
			statusLabel.Text = "Hanya host yang bisa kick player."
			return
		end
		local targetToken = tostring(kickNameBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if targetToken == "" then
			statusLabel.Text = "Isi nama pemain yang ingin di-kick."
			return
		end
		local targetLower = targetToken:lower()
		local targetUserId = nil
		for _, info in ipairs((state.currentRoom and state.currentRoom.players) or {}) do
			local n1 = tostring(info.name or ""):lower()
			local n2 = tostring(info.displayName or ""):lower()
			if n1 == targetLower or n2 == targetLower then
				targetUserId = info.userId
				break
			end
		end
		if not targetUserId then
			statusLabel.Text = "Nama pemain tidak ditemukan di room."
			return
		end
		if self._roomBrowser then
			self._roomBrowser:KickPlayer(targetUserId)
		end
	end)

	local selectableButtons = {
		classicBtn,
		allModesBtn,
		rankedBtn,
		refreshBtn,
		createRoomBtn,
		queueBtn,
		quickClassicBtn,
		quickRankedBtn,
		modeSelector,
		modeClassicBtn,
		modeRankedBtn,
		mapSelector,
		setPwdBtn,
		inviteBtn,
		inviteAcceptBtn,
		inviteDeclineBtn,
		readyBtn,
		startBtn,
		cancelStartBtn,
		cancelCountdownBtn,
		leaveRoomBtn,
		closeBtn,
		floatButton,
	}
	for _, button in ipairs(selectableButtons) do
		self:_setSelectableStyle(button)
	end
	for _, optionButton in ipairs(mapOptionButtons) do
		self:_setSelectableStyle(optionButton)
	end

	connectButtonPress(closeBtn, function()
		self:_setRoomBrowserVisible(false)
	end)
	connectButtonPress(floatButton, function()
		self:_toggleRoomBrowserVisible()
	end)

	local function updateDrag(input)
		local delta = input.Position - dragStart
		panel.Position = UDim2.new(
			panelStart.X.Scale,
			panelStart.X.Offset + delta.X,
			panelStart.Y.Scale,
			panelStart.Y.Offset + delta.Y
		)
	end

	dragBar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragInput = input
		dragStart = input.Position
		panelStart = panel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragInput = nil
			end
		end)
	end)

	dragBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			updateDrag(input)
		end
	end))

	self._roomBrowserGui = gui
	self._roomBrowserFloatGui = floatGui
	self._roomBrowserWidgets = {
		RootPanel = panel,
		HeaderTitle = title,
		HeaderTitleGlow = titleGlow,
		Status = statusLabel,
		ClassicButton = classicBtn,
		AllModesButton = allModesBtn,
		RankedButton = rankedBtn,
		RoomList = roomList,
		RoomPreviewPanel = roomPreviewPanel,
		RoomPreviewTitle = roomPreviewTitle,
		RoomPreviewInfo = roomPreviewInfo,
		RoomPreviewMap = roomPreviewMap,
		RoomPreviewMapLabel = roomPreviewMapLabel,
		RoomPreviewPlayersList = roomPreviewPlayersList,
		JoinPassword = joinPwdBox,
		RefreshButton = refreshBtn,
		CreateRoomButton = createRoomBtn,
		QueueButton = queueBtn,
		QuickJoinClassicButton = quickClassicBtn,
		QuickJoinRankedButton = quickRankedBtn,
		RoomPanel = roomPanel,
		RoomTitle = roomTitle,
		RoomHost = roomHost,
		PlayersList = playersList,
		KickNameBox = kickNameBox,
		KickButton = kickBtn,
		ReadyButton = readyBtn,
		StartButton = startBtn,
		CancelStartButton = cancelStartBtn,
		ModeSelector = modeSelector,
		ModeDropdown = modeDropdown,
		MapDropdown = mapDropdown,
		RankedTierLabel = rankedTierLabel,
		MapSelector = mapSelector,
		MapPreview = mapPreview,
		MapPreviewTitle = mapPreviewTitle,
		MapPreviewLabel = mapPreviewLabel,
		SetPasswordBox = setPwdBox,
		SetPasswordButton = setPwdBtn,
		InviteButton = inviteBtn,
		InviteDropdown = inviteDropdown,
		RebuildInviteList = rebuildInviteList,
		InvitePopup = invitePopup,
		InvitePopupText = invitePopupText,
		CountdownOverlay = countdownOverlay,
		CountdownLabel = countdownLabel,
		CancelCountdown = cancelCountdownBtn,
		PasswordModal = passwordModal,
		PasswordInput = passwordInput,
		KickNoticeModal = kickNoticeModal,
		KickNoticeText = kickNoticeText,
		FloatButton = floatButton,
		RenderRoomList = renderRoomList,
		UpdateMapPreview = updateMapPreview,
		SetCurrentRoom = function(roomId)
			currentRoomId = roomId
		end,
		GetCurrentRoom = function()
			return currentRoomId
		end,
	}
	updateMapPreview()
	self:_applyDeviceSizing()
	self:_updateRoomBrowserVisibility()
end

function UISystem:_setButtonSelected(button, selected)
	if not button then
		return
	end
	button.BackgroundColor3 = selected and Color3.fromRGB(88, 121, 173) or Color3.fromRGB(46, 57, 73)
end

function UISystem:_updateRoomBrowserVisibility()
	local suppressed = self._roomBrowserSuppressed == true
	if self._roomBrowserGui then
		self._roomBrowserGui.Enabled = (not suppressed) and self._roomBrowserVisible
	end
	if self._roomBrowserFloatGui then
		self._roomBrowserFloatGui.Enabled = (not suppressed) and (not self._roomBrowserVisible)
	end
end

function UISystem:_setRoomBrowserVisible(visible)
	if self._roomBrowserSuppressed == true and visible == true then
		return
	end
	if visible == true then
		self:_closeConflictingWindows("RoomBrowser")
	end
	self._roomBrowserVisible = visible == true
	self:_updateRoomBrowserVisibility()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
end

function UISystem:_toggleRoomBrowserVisible()
	if self._roomBrowserSuppressed == true then
		return
	end
	self:_setRoomBrowserVisible(not self._roomBrowserVisible)
end

function UISystem:_bindRoomBrowserToggleInput()
	if self._roomBrowserInputBound then
		return
	end
	self._roomBrowserInputBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local isKeyboardToggle = input.KeyCode == ROOM_BROWSER_TOGGLE_KEY
		local isGamepadToggle = input.KeyCode == Enum.KeyCode.ButtonY
		if not isKeyboardToggle and not isGamepadToggle then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		self:_toggleRoomBrowserVisible()
	end))
end

function UISystem:_bindAuxiliaryToggleInput()
	if self._auxiliaryInputBound then
		return
	end
	self._auxiliaryInputBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		for guiName, keyCode in pairs(AUXILIARY_WINDOW_TOGGLE_KEYS) do
			if input.KeyCode == keyCode then
				if gameProcessed and self._matchPhase == MATCH_PHASE.LOBBY then
					return
				end
				self:_toggleAuxiliaryWindow(guiName)
				break
			end
		end
	end))
end

function UISystem:_bindMatchPanelToggleInput()
	if self._matchPanelToggleBound then
		return
	end
	self._matchPanelToggleBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode ~= MATCH_PANEL_TOGGLE_KEY then
			return
		end
		if self._uiState.MatchUI then
			self._uiState.MatchUI.visible = true
		end
		self:_setMatchWindowDismissed(not (self._matchWindowDismissed == true))
		self:_applyVisibility()
	end))
end

function UISystem:_bindWindowCloseInput()
	if self._windowCloseInputBound then
		return
	end
	self._windowCloseInputBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if input.KeyCode ~= CLOSE_KEYBOARD_KEY and input.KeyCode ~= CLOSE_GAMEPAD_KEY then
			return
		end
		if input.KeyCode == CLOSE_KEYBOARD_KEY and self:_isMatchPanelOpen() then
			self:_setMatchWindowDismissed(true)
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		self:_closeTopmostWindow()
	end))
end

function UISystem:_refreshRoomBrowserView()
	if not self._roomBrowserGui or not self._roomBrowserGui.Parent then
		self._roomBrowserGui = nil
		self._roomBrowserWidgets = nil
		self:_ensureRoomBrowserGui()
	end

	if not self._roomBrowserWidgets then
		if self._roomBrowserMissingWidgetsLogged ~= true then
			self._roomBrowserMissingWidgetsLogged = true
		end
		return
	end
	self._roomBrowserMissingWidgetsLogged = false

	local state = self:GetRoomBrowserState() or {}
	local selectedMode = state.selectedMode or "Classic"
	local rooms = state.rooms or {}
	local viewMode = self._roomBrowserModeView or "Selected"
	local roomsForDisplay = rooms
	if viewMode == "Selected" then
		roomsForDisplay = {}
		for _, room in ipairs(rooms) do
			local modeName = tostring(room.mode or "Classic")
			if modeName == selectedMode then
				table.insert(roomsForDisplay, room)
			end
		end
	end
	local queueInfo = state.queue

	if state.currentRoom and state.currentRoom.roomId then
		self._roomBrowserWidgets.SetCurrentRoom(state.currentRoom.roomId)
	elseif state.pendingRoomTransition ~= true then
		self._roomBrowserWidgets.SetCurrentRoom(nil)
	end

	local statusModeText = selectedMode
	if viewMode == "All" then
		statusModeText = "SEMUA MODE"
	end
	local statusText = string.format("Mode: %s | Room: %d", statusModeText, #roomsForDisplay)
	local currentRoom = self._roomBrowserWidgets.GetCurrentRoom and self._roomBrowserWidgets.GetCurrentRoom() or nil
	if currentRoom then
		statusText = statusText .. " | InRoom: " .. tostring(currentRoom)
	end
	if state.matchStarting == true then
		statusText = statusText .. " | COUNTDOWN: " .. tostring(state.countdownSecondsLeft or state.countdownTotal or "...")
	end
	if state.lastError then
		statusText = statusText .. " | ERR: " .. tostring(state.lastError)
	elseif queueInfo then
		statusText = statusText .. " | Queue: " .. tostring(queueInfo.queueType or queueInfo.mode or "started")
	end
	self._roomBrowserWidgets.Status.Text = statusText

	self:_setButtonSelected(self._roomBrowserWidgets.AllModesButton, viewMode == "All")
	self:_setButtonSelected(self._roomBrowserWidgets.ClassicButton, viewMode ~= "All" and selectedMode == "Classic")
	self:_setButtonSelected(self._roomBrowserWidgets.RankedButton, viewMode ~= "All" and selectedMode == "Ranked")

	self._roomBrowserWidgets.RenderRoomList(roomsForDisplay)

	local panel = self._roomBrowserWidgets.RoomPanel
	local roomData = nil
	if currentRoom then
		for _, room in ipairs(roomsForDisplay) do
			if room.roomId == currentRoom then
				roomData = room
				break
			end
		end
		if not roomData and state.currentRoom and state.currentRoom.roomId == currentRoom then
			roomData = state.currentRoom
		end
	end

	local showRoomPanel = roomData ~= nil
	panel.Visible = showRoomPanel
	if self._roomBrowserWidgets.RootPanel then
		self._roomBrowserWidgets.RootPanel.BackgroundTransparency = showRoomPanel and 1 or 0.5
	end
	if self._roomBrowserWidgets.HeaderTitle then
		self._roomBrowserWidgets.HeaderTitle.Visible = not showRoomPanel
	end
	if self._roomBrowserWidgets.HeaderTitleGlow then
		self._roomBrowserWidgets.HeaderTitleGlow.Visible = not showRoomPanel
	end
	self._roomBrowserWidgets.Status.Visible = not showRoomPanel
	local canChangeMode = (not showRoomPanel) or (state.isHost == true)
	self._roomBrowserWidgets.ClassicButton.Visible = canChangeMode
	self._roomBrowserWidgets.AllModesButton.Visible = canChangeMode
	self._roomBrowserWidgets.RankedButton.Visible = canChangeMode
	self._roomBrowserWidgets.RoomList.Visible = not showRoomPanel
	self._roomBrowserWidgets.RoomPreviewPanel.Visible = not showRoomPanel
	self._roomBrowserWidgets.JoinPassword.Visible = false
	self._roomBrowserWidgets.RefreshButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.CreateRoomButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QueueButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QuickJoinClassicButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QuickJoinRankedButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.ModeSelector.Visible = false
	self._roomBrowserWidgets.RankedTierLabel.Visible = false
	self._roomBrowserWidgets.ModeDropdown.Visible = false
	self._roomBrowserWidgets.MapDropdown.Visible = false
	if self._passwordJoinPendingRoomId == nil then
		self._roomBrowserWidgets.PasswordModal.Visible = false
	end

	if showRoomPanel then
		if state.isHost ~= true then
			self._roomModeDropdownOpen = false
			self._roomMapDropdownOpen = false
		end
		local localUserId = Players.LocalPlayer and Players.LocalPlayer.UserId or nil
		local localName = Players.LocalPlayer and Players.LocalPlayer.Name or nil
		local hostCanControl = state.isHost == true
			or (roomData.hostUserId ~= nil and roomData.hostUserId == localUserId)
			or (localName ~= nil and tostring(roomData.hostName or "") == tostring(localName))
		local roomPlayersData = type(roomData.players) == "table" and roomData.players or nil
		if (not roomPlayersData or #roomPlayersData == 0) and type(state.currentRoom) == "table" and type(state.currentRoom.players) == "table" then
			roomPlayersData = state.currentRoom.players
		end
		if (not roomPlayersData or #roomPlayersData == 0) then
			for _, listedRoom in ipairs(state.rooms or {}) do
				if tostring(listedRoom.roomId) == tostring(currentRoom) and type(listedRoom.players) == "table" then
					roomPlayersData = listedRoom.players
					break
				end
			end
		end
		roomPlayersData = roomPlayersData or {}

		self._roomBrowserWidgets.RoomTitle.Text = "RUANG #" .. tostring(roomData.roomId or currentRoom)
		self._roomBrowserWidgets.RoomHost.Text = "Host: " .. tostring(roomData.hostName or ((roomPlayersData[1] and (roomPlayersData[1].displayName or roomPlayersData[1].name)) or "-"))
		local roomMode = tostring(roomData.mode or selectedMode or "Classic")
		local roomMapId = (type(roomData.mapId) == "string" and roomData.mapId ~= "" and roomData.mapId)
			or (type(state.selectedMap) == "string" and state.selectedMap ~= "" and state.selectedMap)
			or MAPS[1]
		if roomMode == "Ranked" then
			self._roomMapDropdownOpen = false
		end
		self._roomBrowserWidgets.ModeSelector.Text = "MODE: " .. string.upper(roomMode)
		self._roomBrowserWidgets.MapSelector.Text = "MAP: " .. tostring(roomMapId)
		if roomMode == "Ranked" and hostCanControl then
			local tierText = "UNRANKED"
			local localPlayer = Players.LocalPlayer
			if localPlayer then
				for _, attrName in ipairs({ "RankTier", "Tier", "RankedTier", "HostTier" }) do
					local value = localPlayer:GetAttribute(attrName)
					if value ~= nil and tostring(value) ~= "" then
						tierText = string.upper(tostring(value))
						break
					end
				end
			end
			self._roomBrowserWidgets.RankedTierLabel.Text = "TIER HOST: " .. tierText
			self._roomBrowserWidgets.RankedTierLabel.Visible = true
		end
		self._roomBrowserWidgets.ModeSelector.Visible = hostCanControl
		self._roomBrowserWidgets.MapSelector.Visible = hostCanControl and roomMode ~= "Ranked"
		self._roomBrowserWidgets.ModeDropdown.Visible = hostCanControl and self._roomModeDropdownOpen == true
		self._roomBrowserWidgets.MapDropdown.Visible = hostCanControl and roomMode ~= "Ranked" and self._roomMapDropdownOpen == true
		if self._roomBrowserWidgets.UpdateMapPreview then
			self._roomBrowserWidgets.UpdateMapPreview(roomMode, roomMapId)
		end
		for _, child in ipairs(self._roomBrowserWidgets.PlayersList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for _, info in ipairs(roomPlayersData) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
			card.BorderSizePixel = 0
			card.Size = UDim2.fromOffset(202, 132)
			card.Parent = self._roomBrowserWidgets.PlayersList
			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 8)
			cardCorner.Parent = card
			local cardStroke = Instance.new("UIStroke")
			cardStroke.Thickness = info.isReady and 2 or 1
			cardStroke.Color = info.isReady and Color3.fromRGB(82, 179, 108) or Color3.fromRGB(74, 88, 112)
			cardStroke.Parent = card

			local preview = Instance.new("ViewportFrame")
			preview.Name = "Preview"
			preview.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
			preview.BorderSizePixel = 0
			preview.Position = UDim2.fromOffset(6, 8)
			preview.Size = UDim2.fromOffset(84, 116)
			preview.Parent = card
			local previewCorner = Instance.new("UICorner")
			previewCorner.CornerRadius = UDim.new(0, 6)
			previewCorner.Parent = preview
			renderCharacterPreview(preview, info.userId)

			local displayNameLabel = Instance.new("TextLabel")
			displayNameLabel.BackgroundTransparency = 1
			displayNameLabel.Position = UDim2.fromOffset(96, 8)
			displayNameLabel.Size = UDim2.fromOffset(100, 30)
			displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			displayNameLabel.Font = Enum.Font.GothamBold
			displayNameLabel.TextSize = 10
			displayNameLabel.TextColor3 = Color3.fromRGB(236, 240, 245)
			displayNameLabel.TextWrapped = true
			local roleTag = info.isHost and "[HOST]" or "[MEMBER]"
			displayNameLabel.Text = string.format("%s %s", roleTag, tostring(info.displayName or info.name or "?"))
			displayNameLabel.Parent = card

			local readyLabel = Instance.new("TextLabel")
			readyLabel.BackgroundTransparency = 1
			readyLabel.Position = UDim2.fromOffset(96, 40)
			readyLabel.Size = UDim2.fromOffset(100, 14)
			readyLabel.TextXAlignment = Enum.TextXAlignment.Left
			readyLabel.Font = Enum.Font.GothamSemibold
			readyLabel.TextSize = 10
			readyLabel.TextColor3 = info.isReady and Color3.fromRGB(120, 220, 145) or Color3.fromRGB(255, 195, 120)
			readyLabel.Text = info.isReady and "READY" or "NOT READY"
			readyLabel.Parent = card

			local canKickThis = state.isHost == true and info.userId ~= localUserId and state.matchStarting ~= true
			local kickInline = Instance.new("TextButton")
			kickInline.BackgroundColor3 = Color3.fromRGB(130, 44, 44)
			kickInline.BorderSizePixel = 0
			kickInline.Size = UDim2.fromOffset(18, 18)
			kickInline.Position = UDim2.new(1, -22, 0, 4)
			kickInline.Font = Enum.Font.GothamBlack
			kickInline.TextSize = 12
			kickInline.TextColor3 = Color3.fromRGB(245, 245, 245)
			kickInline.Text = "X"
			kickInline.Visible = canKickThis
			kickInline.Parent = card
			local kickCorner = Instance.new("UICorner")
			kickCorner.CornerRadius = UDim.new(1, 0)
			kickCorner.Parent = kickInline
			if canKickThis then
				connectButtonPress(kickInline, function()
					if self._roomBrowser then
						self._roomBrowser:KickPlayer(info.userId)
					end
				end)
			end
		end
		if #roomPlayersData == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Size = UDim2.new(1, -12, 1, 0)
			emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
			emptyLabel.TextYAlignment = Enum.TextYAlignment.Center
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.TextSize = 12
			emptyLabel.TextColor3 = Color3.fromRGB(220, 230, 240)
			emptyLabel.Text = "Belum ada data anggota ruangan"
			emptyLabel.Parent = self._roomBrowserWidgets.PlayersList
		end
		local isReady = state.isReady == true
		local playerCount = roomData.playerCount
		if playerCount == nil then
			playerCount = #roomPlayersData
		end
		local allReadyComputed = state.allReady == true
		if state.isHost == true and state.allReady == nil and #roomPlayersData > 0 then
			allReadyComputed = true
			for _, info in ipairs(roomPlayersData) do
				if not info.isHost and info.isReady ~= true then
					allReadyComputed = false
					break
				end
			end
		end

		if state.isHost == true then
			if state.matchStarting == true then
				self._roomBrowserWidgets.ReadyButton.Text = "BATALKAN COUNTDOWN"
				self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
				self._roomBrowserWidgets.ReadyButton.Active = true
				self._roomBrowserWidgets.ReadyButton.AutoButtonColor = true
			elseif (playerCount or 0) <= 1 then
				self._roomBrowserWidgets.ReadyButton.Text = "MULAI PERMAINAN"
				self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
				self._roomBrowserWidgets.ReadyButton.Active = true
				self._roomBrowserWidgets.ReadyButton.AutoButtonColor = true
			elseif allReadyComputed == true then
				self._roomBrowserWidgets.ReadyButton.Text = "MULAI PERMAINAN"
				self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
				self._roomBrowserWidgets.ReadyButton.Active = true
				self._roomBrowserWidgets.ReadyButton.AutoButtonColor = true
			else
				self._roomBrowserWidgets.ReadyButton.Text = "BELUM SIAP SEMUA"
				self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = Color3.fromRGB(82, 82, 82)
				self._roomBrowserWidgets.ReadyButton.Active = false
				self._roomBrowserWidgets.ReadyButton.AutoButtonColor = false
			end
		else
			self._roomBrowserWidgets.ReadyButton.Text = isReady and "BATALKAN" or "SIAP"
			self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = isReady and Color3.fromRGB(80, 80, 40) or Color3.fromRGB(40, 120, 60)
			self._roomBrowserWidgets.ReadyButton.Active = true
			self._roomBrowserWidgets.ReadyButton.AutoButtonColor = true
		end

		self._roomBrowserWidgets.StartButton.Visible = false
		self._roomBrowserWidgets.CancelStartButton.Visible = false
		self._roomBrowserWidgets.SetPasswordBox.Visible = false
		self._roomBrowserWidgets.SetPasswordButton.Visible = false
		local inviteEnabled = hostCanControl and state.matchStarting ~= true
		self._roomBrowserWidgets.InviteButton.Visible = inviteEnabled
		if inviteEnabled then
			self._roomBrowserWidgets.InviteDropdown.Visible = self._inviteDropdownOpen == true
			if self._inviteDropdownOpen == true and self._roomBrowserWidgets.RebuildInviteList then
				self._roomBrowserWidgets.RebuildInviteList()
			end
		else
			self._inviteDropdownOpen = false
			self._roomBrowserWidgets.InviteDropdown.Visible = false
		end
		self._roomBrowserWidgets.KickNameBox.Visible = false
		self._roomBrowserWidgets.KickButton.Visible = false
	else
		for _, child in ipairs(self._roomBrowserWidgets.PlayersList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		self._roomModeDropdownOpen = false
		self._roomMapDropdownOpen = false
		self._roomBrowserWidgets.ModeDropdown.Visible = false
		self._roomBrowserWidgets.MapDropdown.Visible = false
		self._roomBrowserWidgets.ModeSelector.Visible = false
		self._roomBrowserWidgets.MapSelector.Visible = false
		self._roomBrowserWidgets.RankedTierLabel.Visible = false
		self._inviteDropdownOpen = false
		if self._roomBrowserWidgets.InviteButton then
			self._roomBrowserWidgets.InviteButton.Visible = false
		end
		if self._roomBrowserWidgets.InviteDropdown then
			self._roomBrowserWidgets.InviteDropdown.Visible = false
		end
		self._roomBrowserWidgets.KickNameBox.Visible = false
		self._roomBrowserWidgets.KickButton.Visible = false
	end

	local showCountdown = state.matchStarting == true
	self._roomBrowserWidgets.CountdownOverlay.Visible = showCountdown
	if showCountdown then
		self._roomBrowserWidgets.CountdownLabel.Text = tostring(state.countdownSecondsLeft or state.countdownTotal or 5)
		self._roomBrowserWidgets.CancelCountdown.Visible = state.isHost == true
	else
		self._roomBrowserWidgets.CancelCountdown.Visible = false
	end
	self:_updateRoomBrowserVisibility()
	self:_refreshBasicLobbyPanel()
end

function UISystem:_startRoomBrowserLoop()
	if self._roomBrowserLoopRunning then
		return
	end
	self._roomBrowserLoopRunning = true
	task.spawn(function()
		while self._roomBrowserLoopRunning do
			if self._roomBrowserController then
				local state = self._roomBrowserController:GetState()
				if state then
					self:_renderRoomUI(state)
				end
			end
			task.wait(0.1)
		end
	end)
end

function UISystem:_renderRoomUI(state)
	if type(state) ~= "table" then
		return
	end
	local renderKey = buildRoomBrowserRenderKey(state)
	if renderKey == self._roomBrowserRenderKey then
		return
	end
	self._roomBrowserRenderKey = renderKey
	self:_refreshRoomBrowserView()
end

function UISystem:_renderCountdown(state)
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local roomUI = playerGui:FindFirstChild("RoomBrowserUI")
	if not roomUI then
		return
	end

	local label = roomUI:FindFirstChild("CountdownLabel")
	if not label or not label:IsA("TextLabel") then
		return
	end

	if state and state.countdownSecondsLeft then
		label.Visible = true
		label.Text = "COUNTDOWN: " .. tostring(state.countdownSecondsLeft)
	else
		label.Visible = false
	end
end

function UISystem:_renderRoomPlayers(state)
	return state
end

function UISystem:Stop()
	self._phaseTimerRunning = false
	self._roomBrowserLoopRunning = false
	if self._lobbyConnection then
		self._lobbyConnection:Disconnect()
		self._lobbyConnection = nil
	end
	disconnectAll(self._uxConnections)
	disconnectAll(self._connections)
	self:_clearMatchUX()
	self:_clearUXInstances()
end

function UISystem:GetUIState(moduleName)
	return self._uiState[moduleName]
end

function UISystem:GetMatchResult()
	return self._matchResult
end

function UISystem:GetRoomBrowserState()
	if not self._roomBrowser then
		return nil
	end
	return self._roomBrowser:GetState()
end

function UISystem:RoomBrowserSelectMode(modeName)
	if self._roomBrowser then
		self._roomBrowser:SelectMode(modeName)
	end
end

function UISystem:RoomBrowserJoinRoom(roomId, password)
	if self._roomBrowser then
		self._roomBrowser:JoinRoom(roomId, password)
	end
end

function UISystem:RoomBrowserQueueSelected()
	if self._roomBrowser then
		self._roomBrowser:QueueSelected()
	end
end

function UISystem:RoomBrowserSetReady(isReady)
	if self._roomBrowser then
		self._roomBrowser:SetReady(isReady)
	end
end

function UISystem:RoomBrowserHostStart(mapId, difficulty, mode)
	if self._roomBrowser then
		self._roomBrowser:HostStart(mapId, difficulty, mode)
	end
end

function UISystem:RoomBrowserCancelHostStart()
	if self._roomBrowser then
		self._roomBrowser:CancelHostStart()
	end
end

function UISystem:RoomBrowserSetPassword(password)
	if self._roomBrowser then
		self._roomBrowser:SetPassword(password)
	end
end

function UISystem:RoomBrowserCreateRoom()
	if self._roomBrowser then
		self._roomBrowser:CreateRoom()
	end
end

function UISystem:RoomBrowserLeaveRoom()
	if self._roomBrowser then
		self._roomBrowser:LeaveRoom()
	end
end

function UISystem:RoomBrowserInvitePlayerToRoom(targetNameOrUserId)
	if self._roomBrowser then
		self._roomBrowser:InvitePlayerToRoom(targetNameOrUserId)
	end
end

function UISystem:RoomBrowserInviteBroadcastToRoom()
	if self._roomBrowser then
		self._roomBrowser:InviteBroadcastToRoom()
	end
end

function UISystem:RoomBrowserRespondRoomInvite(inviteId, accept)
	if self._roomBrowser then
		self._roomBrowser:RespondRoomInvite(inviteId, accept)
	end
end

return setmetatable({}, UISystem)
