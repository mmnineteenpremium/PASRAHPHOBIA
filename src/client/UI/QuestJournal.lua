local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local QUEST_DATA_ATTR = "PasrahQuestData"
local QUEST_UPDATED_AT_ATTR = "PasrahQuestDataUpdatedAt"
local MATCH_LIFECYCLE_PHASE_ATTR = "MatchLifecyclePhase"
local LEGACY_MATCH_PHASE_ATTR = "MatchPhase"
local JOURNAL_TOGGLE_KEY = Enum.KeyCode.Q
local UI_INPUT_PROFILE_OVERRIDE_ATTR = "PasrahUIInputProfileOverride"
local UI_FORCE_COMPACT_ATTR = "PasrahUIForceCompact"
local UI_VIEWPORT_OVERRIDE_X_ATTR = "PasrahUIViewportOverrideX"
local UI_VIEWPORT_OVERRIDE_Y_ATTR = "PasrahUIViewportOverrideY"

local TAB_ORDER = { "STORY", "DAILY", "WEEKLY" }
local TAB_LABELS = {
	STORY = "Story",
	DAILY = "Daily",
	WEEKLY = "Weekly",
}
local TAB_COLORS = {
	STORY = Color3.fromRGB(190, 122, 255),
	DAILY = Color3.fromRGB(116, 196, 255),
	WEEKLY = Color3.fromRGB(255, 182, 92),
}
local TAB_EMPTY_MESSAGES = {
	STORY = "Story mission belum diaktifkan di runtime branch ini.",
	DAILY = "Belum ada misi aktif hari ini.",
	WEEKLY = "Weekly challenge belum diaktifkan di runtime branch ini.",
}
local ACTIVE_MATCH_PHASES = {
	PreparationPhase = true,
	InvestigationPhase = true,
	HuntPhase = true,
	Preparing = true,
	Briefing = true,
	InGame = true,
	Escalation = true,
	Hunt = true,
}

local QuestJournal = {}
QuestJournal.__index = QuestJournal

local function decodeQuestPayload(encoded)
	if type(encoded) ~= "string" or encoded == "" then
		return {
			active = {},
			completed = {},
		}
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(encoded)
	end)
	if not ok or type(decoded) ~= "table" then
		return {
			active = {},
			completed = {},
		}
	end

	decoded.active = type(decoded.active) == "table" and decoded.active or {}
	decoded.completed = type(decoded.completed) == "table" and decoded.completed or {}
	return decoded
end

local function nowMillis()
	return DateTime.now().UnixTimestampMillis
end

local function clearContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function resolveInputOverride()
	local override = ReplicatedStorage:GetAttribute(UI_INPUT_PROFILE_OVERRIDE_ATTR)
	if type(override) ~= "string" then
		local localPlayer = Players.LocalPlayer
		override = localPlayer and localPlayer:GetAttribute(UI_INPUT_PROFILE_OVERRIDE_ATTR) or nil
	end
	if type(override) ~= "string" then
		return nil
	end
	override = string.lower(override)
	if override == "mobile" or override == "desktop" or override == "console" then
		return override
	end
	return nil
end

local function getViewportOverrideSize()
	local currentCamera = Workspace.CurrentCamera
	local viewport = currentCamera and currentCamera.ViewportSize or Vector2.new(1280, 720)
	local overrideX = tonumber(ReplicatedStorage:GetAttribute(UI_VIEWPORT_OVERRIDE_X_ATTR))
	local overrideY = tonumber(ReplicatedStorage:GetAttribute(UI_VIEWPORT_OVERRIDE_Y_ATTR))
	if overrideX and overrideY and overrideX > 0 and overrideY > 0 then
		viewport = Vector2.new(
			math.min(viewport.X, math.floor(overrideX)),
			math.min(viewport.Y, math.floor(overrideY))
		)
	end
	return viewport
end

local function isTouchLayout()
	local override = resolveInputOverride()
	if override == "mobile" then
		return true
	end
	if override == "desktop" or override == "console" then
		return false
	end
	local viewport = getViewportOverrideSize()
	if UserInputService.TouchEnabled == true
		and viewport.X > viewport.Y
		and viewport.X <= 900
		and viewport.Y <= 430
	then
		return true
	end
	return UserInputService.TouchEnabled == true and UserInputService.KeyboardEnabled ~= true
end

function QuestJournal.new(playerGui)
	local self = setmetatable({}, QuestJournal)
	self.playerGui = playerGui
	self.player = Players.LocalPlayer
	self._connections = {}
	self._open = false
	self._activeTab = "DAILY"
	self._data = {
		active = {},
		completed = {},
	}
	self:BuildUI()
	self:Connect()
	self:RefreshFromAttributes()
	return self
end

function QuestJournal:BuildUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestJournalGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 5
	screenGui.Parent = self.playerGui

	local openButton = Instance.new("TextButton")
	openButton.Name = "OpenButton"
	openButton.AnchorPoint = Vector2.new(1, 0)
	openButton.Position = UDim2.new(1, -16, 0, 82)
	openButton.Size = UDim2.fromOffset(144, 34)
	openButton.BackgroundColor3 = Color3.fromRGB(35, 46, 68)
	openButton.BorderSizePixel = 0
	openButton.Font = Enum.Font.GothamBold
	openButton.Text = "MISSIONS [Q]"
	openButton.TextColor3 = Color3.fromRGB(244, 244, 250)
	openButton.TextSize = 12
	openButton.Parent = screenGui

	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(0, 10)
	openCorner.Parent = openButton

	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Active = true
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.32
	overlay.Visible = false
	overlay.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.78, 0, 0.8, 0)
	panel.Active = true
	panel.BackgroundColor3 = Color3.fromRGB(15, 17, 27)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 16)
	panelCorner.Parent = panel

	local panelSizeConstraint = Instance.new("UISizeConstraint")
	panelSizeConstraint.MinSize = Vector2.new(320, 320)
	panelSizeConstraint.MaxSize = Vector2.new(860, 640)
	panelSizeConstraint.Parent = panel

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundColor3 = Color3.fromRGB(23, 27, 40)
	header.BorderSizePixel = 0
	header.Font = Enum.Font.GothamBold
	header.Text = "  QUEST JOURNAL"
	header.TextColor3 = Color3.fromRGB(244, 244, 250)
	header.TextSize = 24
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = panel

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 16)
	headerCorner.Parent = header

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.fromOffset(38, 38)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -10, 0, 8)
	closeButton.BackgroundColor3 = Color3.fromRGB(152, 44, 44)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 16
	closeButton.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -24, 0, 18)
	subtitle.Position = UDim2.fromOffset(12, 60)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Quest sync pending..."
	subtitle.TextColor3 = Color3.fromRGB(168, 174, 193)
	subtitle.TextSize = 12
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = panel

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -24, 0, 38)
	tabBar.Position = UDim2.fromOffset(12, 88)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabBar

	self._tabButtons = {}
	for _, tabName in ipairs(TAB_ORDER) do
		local button = Instance.new("TextButton")
		button.Name = tabName .. "Tab"
		button.Size = UDim2.new(0.33, -4, 1, 0)
		button.BackgroundColor3 = Color3.fromRGB(27, 32, 46)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamSemibold
		button.Text = TAB_LABELS[tabName]
		button.TextColor3 = Color3.fromRGB(210, 214, 224)
		button.TextSize = 14
		button.Parent = tabBar

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		button.MouseButton1Click:Connect(function()
			self:SetTab(tabName)
		end)

		self._tabButtons[tabName] = button
	end

	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -24, 1, -136)
	content.Position = UDim2.fromOffset(12, 132)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 4
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.Parent = panel

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 10)
	contentLayout.Parent = content

	openButton.MouseButton1Click:Connect(function()
		self:Toggle()
	end)

	closeButton.MouseButton1Click:Connect(function()
		self:Close()
	end)

	self._screenGui = screenGui
	self._openButton = openButton
	self._overlay = overlay
	self._panel = panel
	self._panelSizeConstraint = panelSizeConstraint
	self._header = header
	self._closeButton = closeButton
	self._tabBar = tabBar
	self._subtitle = subtitle
	self._content = content
	self:ApplyLayout()
	self:SetTab("DAILY")
end

function QuestJournal:_getMatchPhaseToken()
	local lifecyclePhase = tostring(self.player:GetAttribute(MATCH_LIFECYCLE_PHASE_ATTR) or "")
	if lifecyclePhase ~= "" then
		return lifecyclePhase
	end
	return tostring(self.player:GetAttribute(LEGACY_MATCH_PHASE_ATTR) or "")
end

function QuestJournal:ApplyLayout()
	local touchLayout = isTouchLayout()
	local viewport = getViewportOverrideSize()
	local compactLayout = ReplicatedStorage:GetAttribute(UI_FORCE_COMPACT_ATTR) == true
		or touchLayout
		or viewport.X <= 900
		or viewport.Y <= 520

	self._openButton.Text = touchLayout and "MISSION" or "MISSIONS [Q]"
	self._openButton.TextSize = touchLayout and 13 or 12
	self._openButton.Size = UDim2.fromOffset(touchLayout and 116 or 144, touchLayout and 36 or 34)
	self._openButton.Position = UDim2.new(1, -14, 0, compactLayout and 72 or 92)

	self._header.TextSize = touchLayout and 18 or 24
	self._closeButton.Size = UDim2.fromOffset(touchLayout and 34 or 38, touchLayout and 34 or 38)
	self._closeButton.Position = UDim2.new(1, touchLayout and -8 or -10, 0, touchLayout and 6 or 8)

	local maxWidth = touchLayout and math.max(320, math.min(760, viewport.X - 24)) or 860
	local maxHeight = touchLayout and math.max(240, math.min(440, viewport.Y - 18)) or 640
	self._panelSizeConstraint.MinSize = Vector2.new(touchLayout and 300 or 320, touchLayout and 220 or 320)
	self._panelSizeConstraint.MaxSize = Vector2.new(maxWidth, maxHeight)
	self._panel.Size = UDim2.new(compactLayout and 0.94 or 0.78, 0, compactLayout and 0.9 or 0.8, 0)

	self._tabBar.Position = UDim2.fromOffset(12, touchLayout and 82 or 88)
	self._content.Position = UDim2.fromOffset(12, touchLayout and 124 or 132)
	self._content.Size = UDim2.new(1, -24, 1, touchLayout and -128 or -136)
	self:_syncVisibility()
end

function QuestJournal:_isActiveMatchPhase()
	local phase = self:_getMatchPhaseToken()
	return ACTIVE_MATCH_PHASES[phase] == true
end

function QuestJournal:_syncVisibility()
	local activeMatchMobile = isTouchLayout() and self:_isActiveMatchPhase()
	self._openButton.Visible = true
	if activeMatchMobile then
		self._openButton.Text = "MISSION"
		self._openButton.TextSize = 12
		self._openButton.Size = UDim2.fromOffset(100, 32)
		self._openButton.Position = UDim2.new(1, -14, 0, 68)
	end
end

function QuestJournal:SetTab(tabName)
	self._activeTab = tabName
	for name, button in pairs(self._tabButtons) do
		if name == tabName then
			button.BackgroundColor3 = TAB_COLORS[name]
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			button.BackgroundColor3 = Color3.fromRGB(27, 32, 46)
			button.TextColor3 = Color3.fromRGB(210, 214, 224)
		end
	end
	if self._open then
		self:Render()
	end
end

function QuestJournal:_createSectionLabel(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamSemibold
	label.Text = tostring(text)
	label.TextColor3 = color
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = self._content
end

function QuestJournal:_createPlaceholder(text)
	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(1, 0, 0, 48)
	placeholder.BackgroundTransparency = 1
	placeholder.Font = Enum.Font.Gotham
	placeholder.Text = tostring(text)
	placeholder.TextColor3 = Color3.fromRGB(142, 147, 164)
	placeholder.TextSize = 13
	placeholder.TextWrapped = true
	placeholder.TextXAlignment = Enum.TextXAlignment.Left
	placeholder.Parent = self._content
end

function QuestJournal:_createMissionCard(mission, isCompleted)
	local cardHeight = isCompleted and 78 or 98
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, cardHeight)
	card.BackgroundColor3 = isCompleted and Color3.fromRGB(23, 26, 34) or Color3.fromRGB(27, 31, 46)
	card.BorderSizePixel = 0
	card.Parent = self._content

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 5, 1, 0)
	stripe.BackgroundColor3 = isCompleted and Color3.fromRGB(255, 196, 94) or TAB_COLORS[self._activeTab]
	stripe.BorderSizePixel = 0
	stripe.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -140, 0, 22)
	title.Position = UDim2.fromOffset(14, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamSemibold
	title.Text = tostring(mission.title or "Quest")
	title.TextColor3 = isCompleted and Color3.fromRGB(222, 224, 232) or Color3.fromRGB(244, 244, 250)
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = card

	local reward = Instance.new("TextLabel")
	reward.Size = UDim2.fromOffset(118, 24)
	reward.AnchorPoint = Vector2.new(1, 0)
	reward.Position = UDim2.new(1, -10, 0, 8)
	reward.BackgroundColor3 = isCompleted and Color3.fromRGB(64, 56, 28) or Color3.fromRGB(54, 44, 18)
	reward.BorderSizePixel = 0
	reward.Font = Enum.Font.GothamBold
	reward.Text = string.format("+%d XP", math.floor(tonumber(mission.rewards and mission.rewards.xp) or 0))
	reward.TextColor3 = Color3.fromRGB(255, 222, 126)
	reward.TextSize = 12
	reward.Parent = card

	local rewardCorner = Instance.new("UICorner")
	rewardCorner.CornerRadius = UDim.new(0, 6)
	rewardCorner.Parent = reward

	local description = Instance.new("TextLabel")
	description.Size = UDim2.new(1, -24, 0, 18)
	description.Position = UDim2.fromOffset(14, 34)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.Text = tostring(mission.description or "")
	description.TextColor3 = Color3.fromRGB(170, 176, 194)
	description.TextSize = 12
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextTruncate = Enum.TextTruncate.AtEnd
	description.Parent = card

	if isCompleted then
		local status = Instance.new("TextLabel")
		status.Size = UDim2.new(1, -24, 0, 16)
		status.Position = UDim2.fromOffset(14, 56)
		status.BackgroundTransparency = 1
		status.Font = Enum.Font.GothamSemibold
		status.Text = "Selesai hari ini"
		status.TextColor3 = Color3.fromRGB(150, 218, 126)
		status.TextSize = 12
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.Parent = card
		return
	end

	local objective = mission.objectives and mission.objectives[1]
	local objectiveId = objective and objective.id or mission.id
	local progressValue = tonumber(mission.progress and mission.progress[objectiveId]) or 0
	local requiredValue = math.max(1, tonumber(objective and objective.required) or 1)
	local ratio = math.clamp(progressValue / requiredValue, 0, 1)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 10)
	bar.Position = UDim2.fromOffset(14, 60)
	bar.BackgroundColor3 = Color3.fromRGB(44, 48, 62)
	bar.BorderSizePixel = 0
	bar.Parent = card

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 5)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = TAB_COLORS[self._activeTab]
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = fill

	local progress = Instance.new("TextLabel")
	progress.Size = UDim2.new(1, -24, 0, 14)
	progress.Position = UDim2.fromOffset(14, 74)
	progress.BackgroundTransparency = 1
	progress.Font = Enum.Font.Gotham
	progress.Text = string.format("%d / %d", progressValue, requiredValue)
	progress.TextColor3 = Color3.fromRGB(193, 197, 210)
	progress.TextSize = 11
	progress.TextXAlignment = Enum.TextXAlignment.Right
	progress.Parent = card
end

function QuestJournal:Render()
	clearContainer(self._content)

	local updatedAt = tonumber(self.player:GetAttribute(QUEST_UPDATED_AT_ATTR))
	if updatedAt then
		self._subtitle.Text = ("Quest sync • %ds lalu"):format(math.max(0, math.floor((nowMillis() - updatedAt) / 1000)))
	else
		self._subtitle.Text = "Quest sync pending..."
	end

	if self._activeTab ~= "DAILY" then
		self:_createPlaceholder(TAB_EMPTY_MESSAGES[self._activeTab] or "Konten belum tersedia.")
		return
	end

	local active = self._data.active or {}
	local completed = self._data.completed or {}

	self:_createSectionLabel("ACTIVE DAILY MISSIONS", Color3.fromRGB(116, 196, 255))
	if #active == 0 then
		self:_createPlaceholder(TAB_EMPTY_MESSAGES.DAILY)
	else
		for _, mission in ipairs(active) do
			self:_createMissionCard(mission, false)
		end
	end

	self:_createSectionLabel("COMPLETED TODAY", Color3.fromRGB(255, 196, 94))
	if #completed == 0 then
		self:_createPlaceholder("Belum ada misi yang selesai.")
	else
		for _, mission in ipairs(completed) do
			self:_createMissionCard(mission, true)
		end
	end
end

function QuestJournal:RefreshFromAttributes()
	self._data = decodeQuestPayload(self.player:GetAttribute(QUEST_DATA_ATTR))
	if self._open then
		self:Render()
	end
end

function QuestJournal:Connect()
	table.insert(self._connections, self.player:GetAttributeChangedSignal(QUEST_DATA_ATTR):Connect(function()
		self:RefreshFromAttributes()
	end))

	for _, attributeName in ipairs({
		UI_INPUT_PROFILE_OVERRIDE_ATTR,
		UI_FORCE_COMPACT_ATTR,
		UI_VIEWPORT_OVERRIDE_X_ATTR,
		UI_VIEWPORT_OVERRIDE_Y_ATTR,
	}) do
		table.insert(self._connections, ReplicatedStorage:GetAttributeChangedSignal(attributeName):Connect(function()
			self:ApplyLayout()
		end))
	end

	table.insert(self._connections, self.player:GetAttributeChangedSignal(UI_INPUT_PROFILE_OVERRIDE_ATTR):Connect(function()
		self:ApplyLayout()
	end))

	for _, attributeName in ipairs({ MATCH_LIFECYCLE_PHASE_ATTR, LEGACY_MATCH_PHASE_ATTR }) do
		table.insert(self._connections, self.player:GetAttributeChangedSignal(attributeName):Connect(function()
			self:ApplyLayout()
		end))
	end

	local currentCamera = Workspace.CurrentCamera
	if currentCamera then
		table.insert(self._connections, currentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:ApplyLayout()
		end))
	end

	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == JOURNAL_TOGGLE_KEY then
			self:Toggle()
		end
	end))
end

function QuestJournal:Open()
	self._open = true
	self._overlay.Visible = true
	self._panel.Visible = true
	self:Render()
end

function QuestJournal:Close()
	self._open = false
	self._overlay.Visible = false
	self._panel.Visible = false
end

function QuestJournal:Toggle()
	if self._open then
		self:Close()
	else
		self:Open()
	end
end

return QuestJournal
