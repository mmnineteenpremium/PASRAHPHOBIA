local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local QUEST_DATA_ATTR = "PasrahQuestData"
local QUEST_LAST_COMPLETED_ID_ATTR = "PasrahQuestLastCompletedId"
local QUEST_LAST_COMPLETED_TITLE_ATTR = "PasrahQuestLastCompletedTitle"
local QUEST_LAST_COMPLETED_XP_ATTR = "PasrahQuestLastCompletedXP"
local QUEST_LAST_COMPLETED_AT_ATTR = "PasrahQuestLastCompletedAt"
local UI_INPUT_PROFILE_OVERRIDE_ATTR = "PasrahUIInputProfileOverride"
local UI_FORCE_COMPACT_ATTR = "PasrahUIForceCompact"
local UI_VIEWPORT_OVERRIDE_X_ATTR = "PasrahUIViewportOverrideX"
local UI_VIEWPORT_OVERRIDE_Y_ATTR = "PasrahUIViewportOverrideY"

local MAX_VISIBLE = 3

local QuestTracker = {}
QuestTracker.__index = QuestTracker

local function decodeQuestPayload(encoded)
	if type(encoded) ~= "string" or encoded == "" then
		return { active = {} }
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(encoded)
	end)
	if not ok or type(decoded) ~= "table" then
		return { active = {} }
	end

	decoded.active = type(decoded.active) == "table" and decoded.active or {}
	return decoded
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

function QuestTracker.new(playerGui)
	local self = setmetatable({}, QuestTracker)
	self.playerGui = playerGui
	self.player = Players.LocalPlayer
	self._connections = {}
	self._lastCompletedAt = tonumber(self.player:GetAttribute(QUEST_LAST_COMPLETED_AT_ATTR)) or 0
	self:BuildUI()
	self:Connect()
	self:RefreshFromAttributes()
	return self
end

function QuestTracker:BuildUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestTrackerGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 4
	screenGui.Parent = self.playerGui

	local container = Instance.new("Frame")
	container.Name = "QuestContainer"
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = UDim2.new(1, -18, 1, -18)
	container.Size = UDim2.fromOffset(isTouchLayout() and 238 or 280, isTouchLayout() and 214 or 228)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(210, 180)
	sizeConstraint.MaxSize = Vector2.new(300, 260)
	sizeConstraint.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Parent = container

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 22)
	header.LayoutOrder = 0
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.Text = "  DAILY MISSIONS"
	header.TextColor3 = Color3.fromRGB(255, 210, 92)
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = container

	self._screenGui = screenGui
	self._container = container
	self._sizeConstraint = sizeConstraint
	self._header = header
	self:ApplyLayout()
end

function QuestTracker:ApplyLayout()
	local touchLayout = isTouchLayout()
	local viewport = getViewportOverrideSize()
	local compactLayout = ReplicatedStorage:GetAttribute(UI_FORCE_COMPACT_ATTR) == true
		or touchLayout
		or viewport.X <= 900
		or viewport.Y <= 520

	self._container.Position = UDim2.new(1, compactLayout and -12 or -18, 1, compactLayout and -12 or -18)
	self._container.Size = UDim2.fromOffset(
		touchLayout and math.min(248, math.max(214, viewport.X - 28)) or 280,
		touchLayout and (compactLayout and 198 or 214) or 228
	)
	self._sizeConstraint.MinSize = Vector2.new(210, touchLayout and 164 or 180)
	self._sizeConstraint.MaxSize = Vector2.new(touchLayout and 280 or 300, touchLayout and 230 or 260)
	self._header.TextSize = touchLayout and 12 or 13
end

function QuestTracker:_clearCards()
	for _, child in ipairs(self._container:GetChildren()) do
		if child.Name == "QuestCard" or child.Name == "QuestEmptyState" then
			child:Destroy()
		end
	end
end

function QuestTracker:_createCard(mission, order)
	local objective = mission.objectives and mission.objectives[1]
	local objectiveId = objective and objective.id or mission.id
	local progressValue = tonumber(mission.progress and mission.progress[objectiveId]) or 0
	local requiredValue = math.max(1, tonumber(objective and objective.required) or 1)
	local ratio = math.clamp(progressValue / requiredValue, 0, 1)

	local card = Instance.new("Frame")
	card.Name = "QuestCard"
	card.Size = UDim2.new(1, 0, 0, 58)
	card.LayoutOrder = order
	card.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.Parent = self._container

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 4, 1, 0)
	stripe.BackgroundColor3 = Color3.fromRGB(116, 196, 255)
	stripe.BorderSizePixel = 0
	stripe.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -18, 0, 20)
	title.Position = UDim2.fromOffset(10, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamSemibold
	title.Text = tostring(mission.title or "Mission")
	title.TextColor3 = Color3.fromRGB(244, 244, 250)
	title.TextSize = 13
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -18, 0, 8)
	bar.Position = UDim2.fromOffset(10, 28)
	bar.BackgroundColor3 = Color3.fromRGB(44, 48, 62)
	bar.BorderSizePixel = 0
	bar.Parent = card

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(116, 196, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local progress = Instance.new("TextLabel")
	progress.Size = UDim2.new(1, -18, 0, 14)
	progress.Position = UDim2.fromOffset(10, 40)
	progress.BackgroundTransparency = 1
	progress.Font = Enum.Font.Gotham
	progress.Text = string.format("%d / %d", progressValue, requiredValue)
	progress.TextColor3 = Color3.fromRGB(188, 194, 210)
	progress.TextSize = 11
	progress.TextXAlignment = Enum.TextXAlignment.Right
	progress.Parent = card
end

function QuestTracker:RefreshFromAttributes()
	local payload = decodeQuestPayload(self.player:GetAttribute(QUEST_DATA_ATTR))
	local active = payload.active or {}

	self:_clearCards()
	if #active == 0 then
		local placeholder = Instance.new("TextLabel")
		placeholder.Name = "QuestEmptyState"
		placeholder.Size = UDim2.new(1, 0, 0, 42)
		placeholder.LayoutOrder = 1
		placeholder.BackgroundTransparency = 1
		placeholder.Font = Enum.Font.Gotham
		placeholder.Text = "Tidak ada misi aktif."
		placeholder.TextColor3 = Color3.fromRGB(142, 147, 164)
		placeholder.TextSize = 12
		placeholder.Parent = self._container
		return
	end

	local visibleCount = 0
	for _, mission in ipairs(active) do
		visibleCount += 1
		if visibleCount > MAX_VISIBLE then
			break
		end
		self:_createCard(mission, visibleCount)
	end
end

function QuestTracker:_showCompletionPopup()
	local completedAt = tonumber(self.player:GetAttribute(QUEST_LAST_COMPLETED_AT_ATTR)) or 0
	if completedAt <= 0 or completedAt == self._lastCompletedAt then
		return
	end
	self._lastCompletedAt = completedAt

	local title = tostring(self.player:GetAttribute(QUEST_LAST_COMPLETED_TITLE_ATTR) or "Mission")
	local xp = math.floor(tonumber(self.player:GetAttribute(QUEST_LAST_COMPLETED_XP_ATTR)) or 0)
	local questId = tostring(self.player:GetAttribute(QUEST_LAST_COMPLETED_ID_ATTR) or "")

	local existing = self.playerGui:FindFirstChild("QuestPopupGui")
	if existing then
		existing:Destroy()
	end

	local popup = Instance.new("ScreenGui")
	popup.Name = "QuestPopupGui"
	popup.ResetOnSpawn = false
	popup.IgnoreGuiInset = false
	popup.DisplayOrder = 6
	popup.Parent = self.playerGui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(isTouchLayout() and 300 or 340, 84)
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, -96)
	panel.BackgroundColor3 = Color3.fromRGB(22, 47, 28)
	panel.BorderSizePixel = 0
	panel.Parent = popup

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -18, 1, 0)
	label.Position = UDim2.fromOffset(10, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamSemibold
	label.Text = string.format("Mission selesai!\n%s%s  (+%d XP)", title, questId ~= "" and ("  •  " .. questId) or "", xp)
	label.TextColor3 = Color3.fromRGB(128, 244, 135)
	label.TextSize = 15
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = panel

	TweenService:Create(
		panel,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 18) }
	):Play()

	task.delay(3.2, function()
		if not panel.Parent then
			return
		end
		TweenService:Create(
			panel,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -96) }
		):Play()
		task.delay(0.3, function()
			if popup.Parent then
				popup:Destroy()
			end
		end)
	end)
end

function QuestTracker:Connect()
	table.insert(self._connections, self.player:GetAttributeChangedSignal(QUEST_DATA_ATTR):Connect(function()
		self:RefreshFromAttributes()
	end))

	table.insert(self._connections, self.player:GetAttributeChangedSignal(QUEST_LAST_COMPLETED_AT_ATTR):Connect(function()
		self:_showCompletionPopup()
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

	local currentCamera = Workspace.CurrentCamera
	if currentCamera then
		table.insert(self._connections, currentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:ApplyLayout()
		end))
	end
end

return QuestTracker
