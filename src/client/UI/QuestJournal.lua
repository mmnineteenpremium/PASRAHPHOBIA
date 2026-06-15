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
	WEEKLY = "Belum ada weekly challenge aktif.",
}
local QUEST_BUTTON_TEXT_IMAGE_STATES = {
	OpenButton = { idle = "74146227961542", hover = "95903306810711", active = "98565884123985" },
	DAILYTab = { idle = "91316576845536", hover = "96825362275947", active = "82227324051324" },
	STORYTab = { idle = "137489635851687", hover = "98503217158561", active = "77447453584064" },
	WEEKLYTab = { idle = "136762040893669", hover = "127247448482612", active = "128898766382265" },
	CloseButton = { idle = "90895017189874", hover = "115151774523039", active = "127340669403158" },
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
local AUTHORED_OWNER_LAYOUT_LOCK = true

local QuestJournal = {}
QuestJournal.__index = QuestJournal

local missingQuestJournalTemplateWarnings = {}

local function getDirectChildOfClass(parent, childName, className)
	local child = parent and parent:FindFirstChild(childName)
	if child and child:IsA(className) then
		return child
	end
	return nil
end

local function getFirstChildOfClass(parent, className)
	return parent and parent:FindFirstChildOfClass(className) or nil
end

local function decodeQuestPayload(encoded)
	if type(encoded) ~= "string" or encoded == "" then
		return {
			active = {},
			completed = {},
			weekly = {
				active = {},
				completed = {},
			},
		}
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(encoded)
	end)
	if not ok or type(decoded) ~= "table" then
		return {
			active = {},
			completed = {},
			weekly = {
				active = {},
				completed = {},
			},
		}
	end

	decoded.active = type(decoded.active) == "table" and decoded.active or {}
	decoded.completed = type(decoded.completed) == "table" and decoded.completed or {}
	decoded.weekly = type(decoded.weekly) == "table" and decoded.weekly or {
		active = {},
		completed = {},
	}
	decoded.weekly.active = type(decoded.weekly.active) == "table" and decoded.weekly.active or {}
	decoded.weekly.completed = type(decoded.weekly.completed) == "table" and decoded.weekly.completed or {}
	return decoded
end

local function nowMillis()
	return DateTime.now().UnixTimestampMillis
end

local function formatDuration(seconds)
	local total = math.max(0, math.floor(tonumber(seconds) or 0))
	local days = math.floor(total / 86400)
	local hours = math.floor((total % 86400) / 3600)
	local minutes = math.floor((total % 3600) / 60)

	local parts = {}
	if days > 0 then
		table.insert(parts, string.format("%d hari", days))
	end
	if hours > 0 and #parts < 2 then
		table.insert(parts, string.format("%d jam", hours))
	end
	if minutes > 0 and #parts < 2 then
		table.insert(parts, string.format("%d menit", minutes))
	end
	if #parts == 0 then
		table.insert(parts, string.format("%d detik", total))
	end
	return table.concat(parts, " ")
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

local function shouldPreserveAuthoredOwnerLayout()
	return AUTHORED_OWNER_LAYOUT_LOCK == true
end

local function toButtonTextImageAsset(assetId)
	return string.format("rbxassetid://%s", tostring(assetId))
end
local BUTTON_TEXT_IMAGE_SCALE = {
	idle = 1,
	hover = 1.3,
	active = 1.2,
}
local function setButtonTextImageScale(image, stateName)
	if not image then
		return
	end
	local scale = image:FindFirstChild("BrandTextImageStateScale")
	if not (scale and scale:IsA("UIScale")) then
		scale = Instance.new("UIScale")
		scale.Name = "BrandTextImageStateScale"
		scale.Parent = image
	end
	scale.Scale = BUTTON_TEXT_IMAGE_SCALE[stateName or "idle"] or BUTTON_TEXT_IMAGE_SCALE.idle
end
local function setButtonTextImagePassthrough(image)
	if not (image and image:IsA("ImageButton")) then
		return
	end
	image.AutoButtonColor = false
	image.Active = false
	image.Selectable = false
	pcall(function()
		image.Interactable = false
	end)
end
local function isButtonTextImageObject(image)
	return image and (image:IsA("ImageLabel") or image:IsA("ImageButton"))
end
local function configureButtonTextImage(image, states, stateName)
	if not (image and states) then
		return
	end
	local idle = states.idle or states.active or states.hover
	local hover = states.hover or idle
	local active = states.active or hover
	image.Image = toButtonTextImageAsset(states[stateName] or idle)
	image.ImageTransparency = 0
	setButtonTextImageScale(image, stateName)
	if image:IsA("ImageButton") then
		image.HoverImage = toButtonTextImageAsset(hover)
		image.PressedImage = toButtonTextImageAsset(active)
		setButtonTextImagePassthrough(image)
	end
end

local function warnMissingQuestJournalTemplate(key, message)
	if missingQuestJournalTemplateWarnings[key] then
		return
	end
	missingQuestJournalTemplateWarnings[key] = true
	warn(message)
end

local function resolveQuestButtonImage(button)
	if not (button and button:IsA("GuiButton")) then
		return nil
	end
	local image = button:FindFirstChild("BrandTextImage")
	if image and image:IsA("ImageButton") then
		return image
	end
	if image and isButtonTextImageObject(image) then
		local replacement = Instance.new("ImageButton")
		replacement.Name = "BrandTextImage"
		replacement.BackgroundTransparency = 1
		replacement.ScaleType = Enum.ScaleType.Fit
		replacement.Size = image.Size
		replacement.Position = image.Position
		replacement.AnchorPoint = image.AnchorPoint
		replacement.ZIndex = image.ZIndex
		replacement.Visible = image.Visible
		setButtonTextImagePassthrough(replacement)
		image:Destroy()
		replacement.Parent = button
		return replacement
	end
	if not image then
		image = Instance.new("ImageButton")
		image.Name = "BrandTextImage"
		image.BackgroundTransparency = 1
		setButtonTextImagePassthrough(image)
		image.Parent = button
		return image
	end
	image = button:FindFirstChild("CloseIcon")
	if image and image:IsA("ImageLabel") then
		return image
	end
	warnMissingQuestJournalTemplate(
		"ButtonImage:" .. button.Name,
		string.format("[QuestJournal] Missing authored button image child on %s.", button.Name)
	)
	return nil
end

local function cloneGuiTemplate(template, cloneName, parent)
	if typeof(template) ~= "Instance" then
		return nil
	end
	local clone = template:Clone()
	clone.Name = cloneName or template.Name:gsub("Template$", "")
	clone.Parent = parent
	return clone
end

local function applyQuestButtonImageState(button, stateName)
	local states = QUEST_BUTTON_TEXT_IMAGE_STATES[button.Name]
	if not states then
		return
	end
	local image = resolveQuestButtonImage(button)
	if not image then
		return
	end
	image.BackgroundTransparency = 1
	image.Size = UDim2.new(1, -8, 1, -8)
	image.Position = UDim2.fromOffset(4, 4)
	image.ScaleType = Enum.ScaleType.Fit
	image.ZIndex = button.ZIndex + 1
	setButtonTextImagePassthrough(image)
	configureButtonTextImage(image, states, stateName)
	button.TextTransparency = 1
end

local function bindQuestButtonImage(button)
	if not QUEST_BUTTON_TEXT_IMAGE_STATES[button.Name] then
		return
	end
	applyQuestButtonImageState(button, "idle")
	local hovered = false
	button.MouseEnter:Connect(function()
		hovered = true
		applyQuestButtonImageState(button, "hover")
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		applyQuestButtonImageState(button, "idle")
	end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			applyQuestButtonImageState(button, "active")
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			applyQuestButtonImageState(button, hovered and "hover" or "idle")
		end
	end)
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
	if self:BuildUI() then
		self:Connect()
		self:RefreshFromAttributes()
	end
	return self
end

function QuestJournal:BuildUI()
	local screenGui = self.playerGui:FindFirstChild("QuestJournalGui") or self.playerGui:WaitForChild("QuestJournalGui", 5)
	if not screenGui or not screenGui:IsA("ScreenGui") then
		warn("[QuestJournal] Missing authored QuestJournalGui ScreenGui; check StarterGui shell contract.")
		return false
	end

	local openButton = getDirectChildOfClass(screenGui, "OpenButton", "TextButton")
	local overlay = getDirectChildOfClass(screenGui, "Overlay", "Frame")
	local panel = getDirectChildOfClass(screenGui, "Panel", "Frame")
	local panelSizeConstraint = getFirstChildOfClass(panel, "UISizeConstraint")
	local header = getDirectChildOfClass(panel, "Header", "TextLabel")
	local closeButton = getDirectChildOfClass(panel, "CloseButton", "TextButton")
	local subtitle = getDirectChildOfClass(panel, "Subtitle", "TextLabel")
	local tabBar = getDirectChildOfClass(panel, "TabBar", "Frame")
	local content = getDirectChildOfClass(panel, "Content", "ScrollingFrame")
	local contentLayout = getFirstChildOfClass(content, "UIListLayout")
	local templates = getDirectChildOfClass(panel, "Templates", "Frame")
	local storyTab = getDirectChildOfClass(tabBar, "STORYTab", "TextButton")
	local dailyTab = getDirectChildOfClass(tabBar, "DAILYTab", "TextButton")
	local weeklyTab = getDirectChildOfClass(tabBar, "WEEKLYTab", "TextButton")
	local sectionLabelTemplate = getDirectChildOfClass(templates, "SectionLabelTemplate", "TextLabel")
	local placeholderTemplate = getDirectChildOfClass(templates, "PlaceholderTemplate", "TextLabel")
	local activeMissionCardTemplate = getDirectChildOfClass(templates, "ActiveMissionCardTemplate", "Frame")
	local completedMissionCardTemplate = getDirectChildOfClass(templates, "CompletedMissionCardTemplate", "Frame")
	if not (
		openButton
		and overlay
		and panel
		and panelSizeConstraint
		and header
		and closeButton
		and subtitle
		and tabBar
		and content
		and contentLayout
		and templates
		and storyTab
		and dailyTab
		and weeklyTab
		and sectionLabelTemplate
		and placeholderTemplate
		and activeMissionCardTemplate
		and completedMissionCardTemplate
	) then
		warn("[QuestJournal] Authored QuestJournalGui contract mismatch; preserve canonical widget names.")
		return false
	end

	self._tabButtons = {
		STORY = storyTab,
		DAILY = dailyTab,
		WEEKLY = weeklyTab,
	}
	bindQuestButtonImage(openButton)
	bindQuestButtonImage(closeButton)
	bindQuestButtonImage(dailyTab)
	bindQuestButtonImage(storyTab)
	bindQuestButtonImage(weeklyTab)
	for tabName, button in pairs(self._tabButtons) do
		button.MouseButton1Click:Connect(function()
			self:SetTab(tabName)
		end)
	end

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
	self._sectionLabelTemplate = sectionLabelTemplate
	self._placeholderTemplate = placeholderTemplate
	self._activeMissionCardTemplate = activeMissionCardTemplate
	self._completedMissionCardTemplate = completedMissionCardTemplate
	self:ApplyLayout()
	self:SetTab("DAILY")
	return true
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
	local preserveAuthoredDesktopLayout = shouldPreserveAuthoredOwnerLayout() or (not touchLayout and not compactLayout)

	self._openButton.Text = touchLayout and "MISSION" or "MISSIONS [Q]"
	if not preserveAuthoredDesktopLayout then
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
	end
	self:_syncVisibility()
end

function QuestJournal:_isActiveMatchPhase()
	local phase = self:_getMatchPhaseToken()
	return ACTIVE_MATCH_PHASES[phase] == true
end

function QuestJournal:_syncVisibility()
	local activeMatchMobile = isTouchLayout() and self:_isActiveMatchPhase()
	self._openButton.Visible = true
	if activeMatchMobile and not shouldPreserveAuthoredOwnerLayout() then
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

function QuestJournal:_createSectionLabel(text, color, order)
	local label = cloneGuiTemplate(self._sectionLabelTemplate, "QuestSectionLabel", self._content)
	if not (label and label:IsA("TextLabel")) then
		warnMissingQuestJournalTemplate(
			"SectionLabelTemplate",
			"[QuestJournal] Missing authored template: Templates.SectionLabelTemplate"
		)
		return nil
	end
	label.AutomaticSize = Enum.AutomaticSize.None
	label.Size = UDim2.new(1, 0, 0, 18)
	label.LayoutOrder = order or 0
	label.Text = tostring(text)
	label.TextColor3 = color
	return label
end

function QuestJournal:_createPlaceholder(text, order)
	local placeholder = cloneGuiTemplate(self._placeholderTemplate, "QuestPlaceholder", self._content)
	if not (placeholder and placeholder:IsA("TextLabel")) then
		warnMissingQuestJournalTemplate(
			"PlaceholderTemplate",
			"[QuestJournal] Missing authored template: Templates.PlaceholderTemplate"
		)
		return nil
	end
	placeholder.AutomaticSize = Enum.AutomaticSize.None
	placeholder.Size = UDim2.new(1, 0, 0, 42)
	placeholder.LayoutOrder = order or 0
	placeholder.Text = tostring(text)
	return placeholder
end

function QuestJournal:_createMissionCard(mission, isCompleted, order)
	local template = isCompleted and self._completedMissionCardTemplate or self._activeMissionCardTemplate
	local cardName = isCompleted and "CompletedMissionCard" or "ActiveMissionCard"
	local card = cloneGuiTemplate(template, cardName, self._content)
	if not (card and card:IsA("Frame")) then
		warnMissingQuestJournalTemplate(
			cardName,
			string.format("[QuestJournal] Missing authored template: Templates.%sTemplate", cardName)
		)
		return nil
	end
	card.AutomaticSize = Enum.AutomaticSize.None
	card.Size = UDim2.new(1, 0, 0, isCompleted and 96 or 108)
	card.LayoutOrder = order or 0

	local stripe = getDirectChildOfClass(card, "Accent", "Frame")
	local title = getDirectChildOfClass(card, "Title", "TextLabel")
	local reward = getDirectChildOfClass(card, "RewardPill", "TextLabel")
	local description = getDirectChildOfClass(card, "Description", "TextLabel")
	if not (stripe and title and reward and description) then
		warnMissingQuestJournalTemplate(
			cardName .. ":Core",
			string.format("[QuestJournal] Authored %s missing required children.", cardName)
		)
		card:Destroy()
		return nil
	end

	stripe.BackgroundColor3 = isCompleted and Color3.fromRGB(255, 196, 94) or TAB_COLORS[self._activeTab]
	title.Text = tostring(mission.title or "Quest")
	reward.Text = string.format("+%d XP", math.floor(tonumber(mission.rewards and mission.rewards.xp) or 0))
	description.Text = tostring(mission.description or "")

	local objective = mission.objectives and mission.objectives[1]
	local objectiveId = objective and objective.id or mission.id
	local progressValue = tonumber(mission.progress and mission.progress[objectiveId]) or 0
	local requiredValue = math.max(1, tonumber(objective and objective.required) or 1)
	local ratio = math.clamp(progressValue / requiredValue, 0, 1)

	if isCompleted then
		local status = getDirectChildOfClass(card, "Status", "TextLabel")
		if not status then
			warnMissingQuestJournalTemplate(
				cardName .. ":Status",
				"[QuestJournal] Authored CompletedMissionCardTemplate missing child: Status"
			)
			card:Destroy()
			return nil
		end
		status.Text = "Selesai hari ini"
		return card
	end

	local bar = getDirectChildOfClass(card, "ProgressBar", "Frame")
	local fill = bar and getDirectChildOfClass(bar, "ProgressFill", "Frame")
	local progress = getDirectChildOfClass(card, "ProgressText", "TextLabel")
	if not (bar and fill and progress) then
		warnMissingQuestJournalTemplate(
			cardName .. ":Progress",
			"[QuestJournal] Authored ActiveMissionCardTemplate missing progress children."
		)
		card:Destroy()
		return nil
	end
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = TAB_COLORS[self._activeTab]
	progress.Text = string.format("%d / %d", progressValue, requiredValue)
	return card
end

function QuestJournal:_renderMissionGroup(labelText, emptyText, missions, isCompleted, color, layoutOrder)
	self:_createSectionLabel(labelText, color, layoutOrder)
	layoutOrder += 1

	if #missions == 0 then
		self:_createPlaceholder(emptyText, layoutOrder)
		layoutOrder += 1
		return layoutOrder
	end

	for _, mission in ipairs(missions) do
		self:_createMissionCard(mission, isCompleted, layoutOrder)
		layoutOrder += 1
	end

	return layoutOrder
end

function QuestJournal:Render()
	clearContainer(self._content)
	local layoutOrder = 1

	local updatedAt = tonumber(self.player:GetAttribute(QUEST_UPDATED_AT_ATTR))
	local snapshot = self._data or {}
	local weekly = snapshot.weekly or {}
	if updatedAt then
		self._subtitle.Text = ("Quest sync • %ds lalu"):format(math.max(0, math.floor((nowMillis() - updatedAt) / 1000)))
	else
		self._subtitle.Text = "Quest sync pending..."
	end

	if self._activeTab == "WEEKLY" then
		local nextResetAt = tonumber(weekly.nextResetAt) or 0
		local resetSeconds = tonumber(weekly.resetSeconds) or 604800
		local nowSeconds = Workspace:GetServerTimeNow()
		local remaining = nextResetAt > 0 and (nextResetAt - nowSeconds) or resetSeconds
		self._subtitle.Text = string.format("Reset mingguan • %s lagi", formatDuration(remaining))

		local activeWeekly = weekly.active or {}
		local completedWeekly = weekly.completed or {}

		layoutOrder = self:_renderMissionGroup(
			"ACTIVE WEEKLY CHALLENGES",
			TAB_EMPTY_MESSAGES.WEEKLY,
			activeWeekly,
			false,
			Color3.fromRGB(255, 182, 92),
			layoutOrder
		)
		layoutOrder = self:_renderMissionGroup(
			"COMPLETED THIS CYCLE",
			"Belum ada weekly challenge yang selesai.",
			completedWeekly,
			true,
			Color3.fromRGB(255, 196, 94),
			layoutOrder
		)
		return
	end

	if self._activeTab == "STORY" then
		local storyData = snapshot.story or {}
		layoutOrder = self:_renderMissionGroup(
			"ACTIVE STORY MISSIONS",
			TAB_EMPTY_MESSAGES.STORY,
			storyData.active or {},
			false,
			Color3.fromRGB(190, 122, 255),
			layoutOrder
		)
		layoutOrder = self:_renderMissionGroup(
			"COMPLETED STORY",
			"Belum ada story mission yang selesai.",
			storyData.completed or {},
			true,
			Color3.fromRGB(190, 122, 255),
			layoutOrder
		)
		self._subtitle.Text = "Story Mission"
		return
	end

	if self._activeTab ~= "DAILY" then
		self:_createPlaceholder(TAB_EMPTY_MESSAGES[self._activeTab] or "Konten belum tersedia.", layoutOrder)
		return
	end

	local active = self._data.active or {}
	local completed = self._data.completed or {}

	layoutOrder = self:_renderMissionGroup(
		"ACTIVE DAILY MISSIONS",
		TAB_EMPTY_MESSAGES.DAILY,
		active,
		false,
		Color3.fromRGB(116, 196, 255),
		layoutOrder
	)
	self:_renderMissionGroup(
		"COMPLETED TODAY",
		"Belum ada misi yang selesai.",
		completed,
		true,
		Color3.fromRGB(255, 196, 94),
		layoutOrder
	)
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
