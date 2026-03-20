local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local BASIC_GUI_NAMES = { "LobbyUI", "MatchUI", "ProfileUI", "ShopUI", "PASRA_UI", "SpectatorUI", "LeaderboardUI", "MainMenuUI" }
local MAPS = { "HauntedHouse", "AbandonedPalace", "EmptyBuilding", "StudioMMNineteen" }
local DIFFICULTIES = { "Mudah", "Lumayan", "Angker", "Uji Nyali" }

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
end

local function styleLabel(label, text, size)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(235, 240, 245)
	label.Font = Enum.Font.Gotham
	label.TextSize = size or 14
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
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
	self._roomBrowserVisible = false
	self._roomBrowserSuppressed = false
	self._roomBrowserInputBound = false
	self._roomBrowserMissingWidgetsLogged = false
	self._passwordJoinPendingRoomId = nil
	self._passwordJoinSubmitting = false
	self._kickNoticeVisible = false
	self._inviteDropdownOpen = false
	self._activeInviteId = nil
	self._uxReady = false
	self._deviceProfile = createDeviceProfile()
	self._uiStateManager = { state = "Lobby" }
	self._uxWidgets = {
		match = {},
		lobby = {},
	}

	for _, moduleName in ipairs(UI_MODULES) do
		self._uiState[moduleName] = { lastEvent = nil, visible = false }
	end

	self._matchResult = {
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
		warn("[UI ERROR] RoomBrowserController missing")
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
	elseif remoteName == "LobbyEvent" then
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
		end
		self:_handleLobbyUXEvent(eventName, payload or {})
		self:_refreshRoomBrowserView()
	elseif remoteName == "MatchEvent" then
		self._uiState.MatchUI.lastEvent = eventName
		self._uiState.MatchUI.visible = true
		self:_handleMatchUXEvent(eventName, payload or {})
		if eventName == "PlayerKilled" and payload and payload.localPlayerKilled == true then
			self._uiState.SpectatorUI.lastEvent = eventName
			self._uiState.SpectatorUI.visible = true
		elseif eventName == "MatchEnded" then
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
			self._roomBrowserSuppressed = false
			self:_setRoomBrowserVisible(false)
			self._uiState.PASRA_UI.lastEvent = eventName
			self._uiState.PASRA_UI.visible = true
			self._uiState.SpectatorUI.visible = false
			self._uiState.MatchUI.visible = false
		elseif eventName == "MatchStarted" then
			self._roomBrowserSuppressed = true
			self:_setRoomBrowserVisible(false)
			self._uiState.PASRA_UI.visible = false
			self._uiState.MatchUI.visible = true
			self._uiState.SpectatorUI.visible = false
		end
	elseif remoteName == "PurchaseEvent" then
		self._uiState.ShopUI.lastEvent = eventName
		self._uiState.ShopUI.visible = true
	elseif remoteName == "SanityEvent" then
		self._uiState.ProfileUI.lastEvent = eventName
		self._uiState.ProfileUI.visible = true
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
			gui.Enabled = state.visible == true
		end
	end
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

	local match = self._uxWidgets.match
	if match and match.MessageLabel and match.ObjectiveLabel then
		match.MessageLabel.TextSize = profile:GetTextSize() + 8
		match.ObjectiveLabel.TextSize = profile:GetTextSize()
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
		results.Active = false
		results.Selectable = false
		results.ZIndex = 1
		results.AnchorPoint = Vector2.new(0.5, 0.5)
		results.Position = UDim2.fromScale(0.5, 0.5)
		results.Size = UDim2.new(0.6, 0, 0, 260)
		results.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
		results.BackgroundTransparency = 0.15
		results.Visible = false
		results.Parent = matchLayer

		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, 10)
		list.Parent = results
	end

	self._uxWidgets.lobby.FeedbackLabel = lobbyFeedback
	self._uxWidgets.lobby.PlayButton = playButton
	self._uxWidgets.lobby.Gui = lobbyUXGui
	self._uxWidgets.lobby.Layer = lobbyLayer
	self._uxWidgets.match.MessageLabel = matchMessage
	self._uxWidgets.match.ObjectiveLabel = objective
	self._uxWidgets.match.HuntOverlay = overlay
	self._uxWidgets.match.ResultsPanel = results
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
		for _, child in ipairs(match.ResultsPanel:GetChildren()) do
			if child:IsA("TextLabel") then
				self:_trackUXInstance(child)
			end
		end
		self:_clearUXInstances()
	end
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
		local resultGhostType = (payload and payload.ghostType) or self._matchResult.ghostType or "Unknown"
		local resultPanel = match.ResultsPanel
		resultPanel.Visible = true

		local lines = {
			"HASIL INVESTIGASI",
			"Ghost Type: " .. tostring(resultGhostType),
		}

		for _, textLine in ipairs(lines) do
			local line = Instance.new("TextLabel")
			line.BackgroundTransparency = 1
			line.Size = UDim2.new(1, -20, 0, 28)
			line.Text = textLine
			line.Font = Enum.Font.GothamSemibold
			line.TextColor3 = Color3.fromRGB(240, 240, 240)
			line.TextScaled = false
			line.TextSize = math.max(16, self._deviceProfile:GetTextSize() - 1)
			line.Parent = resultPanel
			self:_trackUXInstance(line)
		end
	end
end

function UISystem:_handleMatchUXEvent(eventName, payload)
	if self._uxReady ~= true then
		return
	end
	if eventName == "MatchStarted" then
		self:TransitionTo("Preparation", payload)
		return
	end
	if eventName == "PhaseChanged" then
		local phaseName = payload and (payload.phase or payload.newPhase or payload.state)
		if phaseName == "Preparation" then
			self:TransitionTo("Preparation", payload)
		elseif phaseName == "Investigation" then
			self:TransitionTo("Investigation", payload)
		elseif phaseName == "Hunt" then
			self:TransitionTo("Hunt", payload)
		elseif phaseName == "Results" then
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
	if eventName == "MatchEnded" then
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
		if not gui:FindFirstChild("MainPanel") then
			local panel = Instance.new("Frame")
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
	end

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

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.fromOffset(340, 26)
	title.Text = "RUANG INVESTIGASI"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.Parent = panel

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
	classicBtn.Size = UDim2.fromOffset(200, 30)
	styleButton(classicBtn, "Classic")
	classicBtn.Parent = panel

	local rankedBtn = Instance.new("TextButton")
	rankedBtn.Name = "RankedButton"
	rankedBtn.Position = UDim2.fromOffset(224, 72)
	rankedBtn.Size = UDim2.fromOffset(200, 30)
	styleButton(rankedBtn, "Ranked")
	rankedBtn.Parent = panel

	local diffWrap = Instance.new("Frame")
	diffWrap.Name = "DifficultyWrap"
	diffWrap.BackgroundTransparency = 1
	diffWrap.Position = UDim2.fromOffset(16, 110)
	diffWrap.Size = UDim2.fromOffset(408, 32)
	diffWrap.Parent = panel

	local difficultyButtons = {}
	for i, difficultyName in ipairs(DIFFICULTIES) do
		local btn = Instance.new("TextButton")
		btn.Name = difficultyName
		btn.Size = UDim2.fromOffset(98, 28)
		btn.Position = UDim2.fromOffset((i - 1) * 102, 0)
		styleButton(btn, difficultyName)
		btn.Parent = diffWrap
		difficultyButtons[difficultyName] = btn
	end

	local roomList = Instance.new("ScrollingFrame")
	roomList.Name = "RoomList"
	roomList.Position = UDim2.fromOffset(16, 150)
	roomList.Size = UDim2.fromOffset(408, 250)
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
	refreshBtn.Position = UDim2.fromOffset(224, 408)
	refreshBtn.Size = UDim2.fromOffset(96, 30)
	styleButton(refreshBtn, "Refresh")
	refreshBtn.Parent = panel

	local createRoomBtn = Instance.new("TextButton")
	createRoomBtn.Name = "CreateRoomButton"
	createRoomBtn.Position = UDim2.fromOffset(328, 408)
	createRoomBtn.Size = UDim2.fromOffset(96, 30)
	styleButton(createRoomBtn, "Buat Room")
	createRoomBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 140)
	createRoomBtn.Parent = panel

	local queueBtn = Instance.new("TextButton")
	queueBtn.Name = "QueueButton"
	queueBtn.Position = UDim2.fromOffset(16, 446)
	queueBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(queueBtn, "JOIN")
	queueBtn.BackgroundColor3 = Color3.fromRGB(46, 112, 168)
	queueBtn.Parent = panel

	local quickClassicBtn = Instance.new("TextButton")
	quickClassicBtn.Name = "QuickJoinClassicButton"
	quickClassicBtn.Position = UDim2.fromOffset(149, 446)
	quickClassicBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(quickClassicBtn, "QUICK CLASSIC")
	quickClassicBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 84)
	quickClassicBtn.Parent = panel

	local quickRankedBtn = Instance.new("TextButton")
	quickRankedBtn.Name = "QuickJoinRankedButton"
	quickRankedBtn.Position = UDim2.fromOffset(282, 446)
	quickRankedBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(quickRankedBtn, "QUICK RANKED")
	quickRankedBtn.BackgroundColor3 = Color3.fromRGB(108, 78, 132)
	quickRankedBtn.Parent = panel

	local roomPanel = Instance.new("Frame")
	roomPanel.Name = "RoomPanel"
	roomPanel.Position = UDim2.fromOffset(16, 86)
	roomPanel.Size = UDim2.fromOffset(888, 458)
	roomPanel.BackgroundColor3 = Color3.fromRGB(26, 32, 42)
	roomPanel.BackgroundTransparency = 0.5
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

	local mapSelector = Instance.new("TextButton")
	mapSelector.Name = "MapSelector"
	mapSelector.Position = UDim2.fromOffset(14, 148)
	mapSelector.Size = UDim2.fromOffset(380, 30)
	styleButton(mapSelector, MAPS[1])
	mapSelector.Parent = roomPanel

	local mapPreview = Instance.new("Frame")
	mapPreview.Name = "MapPreview"
	mapPreview.Position = UDim2.fromOffset(14, 114)
	mapPreview.Size = UDim2.fromOffset(380, 30)
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
	mapPreviewTitle.Position = UDim2.fromOffset(8, 2)
	mapPreviewTitle.Size = UDim2.new(1, -16, 0, 12)
	mapPreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewTitle.Font = Enum.Font.GothamSemibold
	mapPreviewTitle.TextSize = 9
	mapPreviewTitle.TextColor3 = Color3.fromRGB(190, 205, 225)
	mapPreviewTitle.Text = "PREVIEW"
	mapPreviewTitle.Parent = mapPreview

	local mapPreviewLabel = Instance.new("TextLabel")
	mapPreviewLabel.Name = "Label"
	mapPreviewLabel.BackgroundTransparency = 1
	mapPreviewLabel.Position = UDim2.fromOffset(8, 12)
	mapPreviewLabel.Size = UDim2.new(1, -16, 0, 14)
	mapPreviewLabel.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewLabel.Font = Enum.Font.GothamBold
	mapPreviewLabel.TextSize = 11
	mapPreviewLabel.TextColor3 = Color3.fromRGB(235, 240, 245)
	mapPreviewLabel.Text = "MAP PLACEHOLDER: " .. tostring(MAPS[1])
	mapPreviewLabel.Parent = mapPreview

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
	readyBtn.Position = UDim2.fromOffset(14, 224)
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
	inviteBtn.Position = UDim2.fromOffset(14, 336)
	inviteBtn.Size = UDim2.fromOffset(380, 30)
	styleButton(inviteBtn, "INVITE PLAYER")
	inviteBtn.TextSize = 12
	inviteBtn.BackgroundColor3 = Color3.fromRGB(52, 92, 128)
	inviteBtn.Visible = false
	inviteBtn.Parent = roomPanel

	local inviteDropdown = Instance.new("Frame")
	inviteDropdown.Name = "InviteDropdown"
	inviteDropdown.Position = UDim2.fromOffset(14, 370)
	inviteDropdown.Size = UDim2.fromOffset(380, 80)
	inviteDropdown.BackgroundColor3 = Color3.fromRGB(26, 33, 43)
	inviteDropdown.BorderSizePixel = 0
	inviteDropdown.Visible = false
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
	invitePopup.Position = UDim2.fromScale(0.5, 0.06)
	invitePopup.Size = UDim2.fromOffset(420, 72)
	invitePopup.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
	invitePopup.BorderSizePixel = 0
	invitePopup.ZIndex = 12
	invitePopup.Visible = false
	invitePopup.Parent = gui
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
	invitePopupText.Position = UDim2.fromOffset(10, 8)
	invitePopupText.Size = UDim2.fromOffset(300, 56)
	invitePopupText.TextXAlignment = Enum.TextXAlignment.Left
	invitePopupText.TextYAlignment = Enum.TextYAlignment.Center
	invitePopupText.Font = Enum.Font.GothamSemibold
	invitePopupText.TextSize = 12
	invitePopupText.TextWrapped = true
	invitePopupText.TextColor3 = Color3.fromRGB(235, 240, 245)
	invitePopupText.Text = "Invite"
	invitePopupText.ZIndex = 13
	invitePopupText.Parent = invitePopup

	local inviteAcceptBtn = Instance.new("TextButton")
	inviteAcceptBtn.Name = "AcceptButton"
	inviteAcceptBtn.Position = UDim2.fromOffset(316, 10)
	inviteAcceptBtn.Size = UDim2.fromOffset(94, 22)
	styleButton(inviteAcceptBtn, "TERIMA")
	inviteAcceptBtn.TextSize = 11
	inviteAcceptBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 70)
	inviteAcceptBtn.ZIndex = 13
	inviteAcceptBtn.Parent = invitePopup

	local inviteDeclineBtn = Instance.new("TextButton")
	inviteDeclineBtn.Name = "DeclineButton"
	inviteDeclineBtn.Position = UDim2.fromOffset(316, 40)
	inviteDeclineBtn.Size = UDim2.fromOffset(94, 22)
	styleButton(inviteDeclineBtn, "TOLAK")
	inviteDeclineBtn.TextSize = 11
	inviteDeclineBtn.BackgroundColor3 = Color3.fromRGB(120, 46, 46)
	inviteDeclineBtn.ZIndex = 13
	inviteDeclineBtn.Parent = invitePopup

	local mapIndex = 1
	local currentRoomId = nil
	local selectedRoomId = nil
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

	local function updateMapPreview()
		local modeText = "Classic"
		if self._roomBrowser then
			local snapshotState = self._roomBrowser:GetState()
			modeText = (snapshotState and snapshotState.selectedMode) or "Classic"
		end
		if modeText == "Ranked" then
			mapPreview.BackgroundColor3 = Color3.fromRGB(46, 32, 62)
			mapPreviewStroke.Color = Color3.fromRGB(140, 102, 196)
			mapPreviewTitle.Text = "RANKED PREVIEW"
			mapPreviewLabel.Text = "RANKED PLACEHOLDER: TIER SCENE"
		else
			mapPreview.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
			mapPreviewStroke.Color = Color3.fromRGB(75, 92, 120)
			mapPreviewTitle.Text = "MAP PREVIEW"
			mapPreviewLabel.Text = "MAP PLACEHOLDER: " .. tostring(MAPS[mapIndex])
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
			end)
			self:_setSelectableStyle(row)
			row.Parent = roomList
		end
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
		self:RoomBrowserSelectMode("Classic")
		task.delay(0.1, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(rankedBtn, function()
		self:RoomBrowserSelectMode("Ranked")
		task.delay(0.1, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	for difficultyName, btn in pairs(difficultyButtons) do
		connectButtonPress(btn, function()
			self:RoomBrowserSelectDifficulty(difficultyName)
			task.delay(0.1, function()
				if self._roomBrowser then
					self._roomBrowser:RequestSnapshot()
				end
			end)
		end)
	end

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

	connectButtonPress(mapSelector, function()
		mapIndex = (mapIndex % #MAPS) + 1
		mapSelector.Text = MAPS[mapIndex]
		if self._roomBrowser then
			self._roomBrowser:SelectMap(MAPS[mapIndex])
		end
		updateMapPreview()
	end)

	connectButtonPress(setPwdBtn, function()
		self:RoomBrowserSetPassword(setPwdBox.Text)
	end)

	connectButtonPress(readyBtn, function()
		local state = self:GetRoomBrowserState() or {}
		if state.currentRoom and state.currentRoom.roomId then
			self:RoomBrowserSetReady(not (state.isReady == true))
		end
	end)
	logRoomClickConnected("ReadyButton")

	connectButtonPress(startBtn, function()
		local state = self:GetRoomBrowserState() or {}
		if state.isHost == true then
			local difficulty = state.selectedMode == "Ranked" and nil or state.selectedDifficulty
			self:RoomBrowserHostStart(MAPS[mapIndex], difficulty, state.selectedMode)
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
		rankedBtn,
		refreshBtn,
		createRoomBtn,
		queueBtn,
		quickClassicBtn,
		quickRankedBtn,
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
		Status = statusLabel,
		ClassicButton = classicBtn,
		RankedButton = rankedBtn,
		DifficultyButtons = difficultyButtons,
		DifficultyWrap = diffWrap,
		RoomList = roomList,
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
	self._roomBrowserVisible = visible == true
	self:_updateRoomBrowserVisibility()
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
	local selectedDifficulty = state.selectedDifficulty or "Mudah"
	local rooms = state.rooms or {}
	local queueInfo = state.queue

	if state.currentRoom and state.currentRoom.roomId then
		self._roomBrowserWidgets.SetCurrentRoom(state.currentRoom.roomId)
	elseif state.pendingRoomTransition ~= true then
		self._roomBrowserWidgets.SetCurrentRoom(nil)
	end

	local statusText = string.format("Mode: %s | Difficulty: %s | Room: %d", selectedMode, selectedDifficulty, #rooms)
	if selectedMode == "Ranked" then
		statusText = string.format("Mode: %s | Difficulty: AUTO (Level/Tier) | Room: %d", selectedMode, #rooms)
	end
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

	self:_setButtonSelected(self._roomBrowserWidgets.ClassicButton, selectedMode == "Classic")
	self:_setButtonSelected(self._roomBrowserWidgets.RankedButton, selectedMode == "Ranked")
	for _, btn in pairs(self._roomBrowserWidgets.DifficultyButtons) do
		btn.Active = selectedMode ~= "Ranked"
		btn.AutoButtonColor = selectedMode ~= "Ranked"
	end
	for difficultyName, btn in pairs(self._roomBrowserWidgets.DifficultyButtons) do
		self:_setButtonSelected(btn, selectedDifficulty == difficultyName)
	end

	self._roomBrowserWidgets.RenderRoomList(rooms)
	if self._roomBrowserWidgets.MapPreview and self._roomBrowserWidgets.MapPreviewTitle and self._roomBrowserWidgets.MapPreviewLabel then
		if selectedMode == "Ranked" then
			self._roomBrowserWidgets.MapPreview.BackgroundColor3 = Color3.fromRGB(46, 32, 62)
			self._roomBrowserWidgets.MapPreviewTitle.Text = "RANKED PREVIEW"
			self._roomBrowserWidgets.MapPreviewLabel.Text = "RANKED PLACEHOLDER: TIER SCENE"
		else
			self._roomBrowserWidgets.MapPreview.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
			self._roomBrowserWidgets.MapPreviewTitle.Text = "MAP PREVIEW"
			self._roomBrowserWidgets.MapPreviewLabel.Text = "MAP PLACEHOLDER: " .. tostring(self._roomBrowserWidgets.MapSelector.Text)
		end
	end

	local panel = self._roomBrowserWidgets.RoomPanel
	local roomData = nil
	if currentRoom then
		for _, room in ipairs(rooms) do
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
	local canChangeMode = (not showRoomPanel) or (state.isHost == true)
	self._roomBrowserWidgets.ClassicButton.Visible = canChangeMode
	self._roomBrowserWidgets.RankedButton.Visible = canChangeMode
	self._roomBrowserWidgets.DifficultyWrap.Visible = canChangeMode and (selectedMode ~= "Ranked")
	self._roomBrowserWidgets.RoomList.Visible = not showRoomPanel
	self._roomBrowserWidgets.JoinPassword.Visible = false
	self._roomBrowserWidgets.RefreshButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.CreateRoomButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QueueButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QuickJoinClassicButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QuickJoinRankedButton.Visible = not showRoomPanel
	if self._passwordJoinPendingRoomId == nil then
		self._roomBrowserWidgets.PasswordModal.Visible = false
	end

	if showRoomPanel then
		self._roomBrowserWidgets.RoomTitle.Text = "RUANG #" .. tostring(roomData.roomId or currentRoom)
		self._roomBrowserWidgets.RoomHost.Text = "Host: " .. tostring(roomData.hostName or "-")
		local roomMapId = roomData.mapId or self._roomBrowserWidgets.MapSelector.Text
		self._roomBrowserWidgets.MapSelector.Text = roomMapId
		for idx, mapName in ipairs(MAPS) do
			if mapName == roomMapId then
				mapIndex = idx
				break
			end
		end
		for _, child in ipairs(self._roomBrowserWidgets.PlayersList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local localUserId = Players.LocalPlayer and Players.LocalPlayer.UserId or nil
		for _, info in ipairs(roomData.players or {}) do
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
		if #(roomData.players or {}) == 0 then
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
		self._roomBrowserWidgets.ReadyButton.Text = isReady and "BATALKAN SIAP" or "SIAP"
		self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = isReady and Color3.fromRGB(80, 80, 40) or Color3.fromRGB(40, 120, 60)
		local playerCount = roomData.playerCount
		if playerCount == nil and type(roomData.players) == "table" then
			playerCount = #roomData.players
		end
		local allReadyComputed = state.allReady == true
		if state.isHost == true and type(roomData.players) == "table" then
			allReadyComputed = true
			for _, info in ipairs(roomData.players) do
				if not info.isHost and info.isReady ~= true then
					allReadyComputed = false
					break
				end
			end
		end
		local canStart = state.isHost == true and allReadyComputed and state.matchStarting ~= true and (playerCount or 0) > 0
		self._roomBrowserWidgets.StartButton.Visible = canStart
		self._roomBrowserWidgets.CancelStartButton.Visible = state.isHost == true and state.matchStarting == true
		self._roomBrowserWidgets.MapSelector.Visible = state.isHost == true and (roomData.mode or selectedMode or "Classic") ~= "Ranked"
		self._roomBrowserWidgets.SetPasswordBox.Visible = state.isHost == true
		self._roomBrowserWidgets.SetPasswordButton.Visible = state.isHost == true
		local inviteEnabled = state.isHost == true and state.matchStarting ~= true
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

function UISystem:RoomBrowserSelectDifficulty(difficultyName)
	if self._roomBrowser then
		self._roomBrowser:SelectDifficulty(difficultyName)
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
