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
local MATCH_LIFECYCLE_PHASE_ATTR = "MatchLifecyclePhase"
local LEGACY_MATCH_PHASE_ATTR = "MatchPhase"
local UI_INPUT_PROFILE_OVERRIDE_ATTR = "PasrahUIInputProfileOverride"
local UI_FORCE_COMPACT_ATTR = "PasrahUIForceCompact"
local UI_VIEWPORT_OVERRIDE_X_ATTR = "PasrahUIViewportOverrideX"
local UI_VIEWPORT_OVERRIDE_Y_ATTR = "PasrahUIViewportOverrideY"

local MAX_VISIBLE = 3
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
local TRACKER_BUTTON_TEXT_IMAGE_STATES = {
	CollapseButton = { idle = "90895017189874", hover = "115151774523039", active = "127340669403158" },
	ReopenButton = { idle = "103489183789899", hover = "99269259836629", active = "110126978866737" },
}
local QUEST_PANEL_TWEEN_INFO = TweenInfo.new(0.68, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local QUEST_POPUP_IN_TWEEN_INFO = TweenInfo.new(0.72, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUEST_POPUP_OUT_TWEEN_INFO = TweenInfo.new(0.52, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local QUEST_POPUP_OUT_HIDE_DELAY = 0.58
local QUEST_POPUP_VISIBLE_POSITION = UDim2.new(0.5, 0, 0, 18)
local QUEST_POPUP_HIDDEN_SCALE = 0.96

local QuestTracker = {}
QuestTracker.__index = QuestTracker

local missingQuestTrackerTemplateWarnings = {}

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

local function warnMissingQuestTrackerTemplate(key, message)
	if missingQuestTrackerTemplateWarnings[key] then
		return
	end
	missingQuestTrackerTemplateWarnings[key] = true
	warn(message)
end

local function resolveTrackerButtonImage(button)
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
	warnMissingQuestTrackerTemplate(
		"ButtonImage:" .. button.Name,
		string.format("[QuestTracker] Missing authored button image child on %s.", button.Name)
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

local function setGuiTreeVisible(root, visible)
	if not root then
		return
	end
	local targetVisible = visible == true
	if root:IsA("GuiObject") then
		root.Visible = targetVisible
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.Visible = targetVisible
		end
	end
end

local function applyTrackerButtonImageState(button, stateName)
	local states = TRACKER_BUTTON_TEXT_IMAGE_STATES[button.Name]
	if not states then
		return
	end
	local image = resolveTrackerButtonImage(button)
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

local function bindTrackerButtonImage(button)
	if not TRACKER_BUTTON_TEXT_IMAGE_STATES[button.Name] then
		return
	end
	applyTrackerButtonImageState(button, "idle")
	local hovered = false
	button.MouseEnter:Connect(function()
		hovered = true
		applyTrackerButtonImageState(button, "hover")
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		applyTrackerButtonImageState(button, "idle")
	end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			applyTrackerButtonImageState(button, "active")
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			applyTrackerButtonImageState(button, hovered and "hover" or "idle")
		end
	end)
end

local function animateQuestPanel(panel, immediate)
	if not panel or not panel:IsA("GuiObject") then
		return
	end

	local scale = panel:FindFirstChild("QuestPanelMotionScale")
	if not (scale and scale:IsA("UIScale")) then
		scale = Instance.new("UIScale")
		scale.Name = "QuestPanelMotionScale"
		scale.Parent = panel
	end

	if immediate then
		scale.Scale = 1
		return
	end

	scale.Scale = 0.985
	TweenService:Create(scale, QUEST_PANEL_TWEEN_INFO, { Scale = 1 }):Play()
end

local function animateQuestPopup(panel, visible, immediate)
	if not panel or not panel:IsA("GuiObject") then
		return
	end

	local scale = panel:FindFirstChild("QuestPopupMotionScale")
	if not (scale and scale:IsA("UIScale")) then
		scale = Instance.new("UIScale")
		scale.Name = "QuestPopupMotionScale"
		scale.Parent = panel
	end

	if visible then
		panel.Position = QUEST_POPUP_VISIBLE_POSITION
		panel.Visible = true
		if immediate then
			scale.Scale = 1
			return
		end
		scale.Scale = QUEST_POPUP_HIDDEN_SCALE
		TweenService:Create(scale, QUEST_POPUP_IN_TWEEN_INFO, { Scale = 1 }):Play()
	else
		if immediate then
			scale.Scale = QUEST_POPUP_HIDDEN_SCALE
			return
		end
		TweenService:Create(scale, QUEST_POPUP_OUT_TWEEN_INFO, { Scale = QUEST_POPUP_HIDDEN_SCALE }):Play()
	end
end

function QuestTracker.new(playerGui)
	local self = setmetatable({}, QuestTracker)
	self.playerGui = playerGui
	self.player = Players.LocalPlayer
	self._connections = {}
	self._lastCompletedAt = tonumber(self.player:GetAttribute(QUEST_LAST_COMPLETED_AT_ATTR)) or 0
	self._collapsed = isTouchLayout()
	self._manualExpandedDuringMatch = false
	if self:BuildUI() then
		self:Connect()
		self:RefreshFromAttributes()
	end
	return self
end

function QuestTracker:BuildUI()
	local screenGui = self.playerGui:FindFirstChild("QuestTrackerGui") or self.playerGui:WaitForChild("QuestTrackerGui", 5)
	local popupGui = self.playerGui:FindFirstChild("QuestPopupGui") or self.playerGui:WaitForChild("QuestPopupGui", 5)
	if not screenGui or not screenGui:IsA("ScreenGui") then
		warn("[QuestTracker] Missing authored QuestTrackerGui ScreenGui; check StarterGui shell contract.")
		return false
	end
	if not popupGui or not popupGui:IsA("ScreenGui") then
		warn("[QuestTracker] Missing authored QuestPopupGui ScreenGui; check StarterGui shell contract.")
		return false
	end

	local container = getDirectChildOfClass(screenGui, "QuestContainer", "Frame")
	local sizeConstraint = getFirstChildOfClass(container, "UISizeConstraint")
	if container and not sizeConstraint then
		sizeConstraint = Instance.new("UISizeConstraint")
		sizeConstraint.Name = "RuntimeSizeConstraint"
		sizeConstraint.MinSize = Vector2.new(220, 96)
		sizeConstraint.MaxSize = Vector2.new(420, 460)
		sizeConstraint:SetAttribute("PasrahRuntimeShellRepair", true)
		sizeConstraint.Parent = container
	end
	local layout = getFirstChildOfClass(container, "UIListLayout")
	local header = getDirectChildOfClass(container, "Header", "TextLabel")
	local collapseButton = getDirectChildOfClass(container, "CollapseButton", "TextButton")
	local reopenButton = getDirectChildOfClass(screenGui, "ReopenButton", "TextButton")
	local templates = getDirectChildOfClass(screenGui, "Templates", "Frame")
	local questCardTemplate = getDirectChildOfClass(templates, "QuestCardTemplate", "Frame")
	local questEmptyStateTemplate = getDirectChildOfClass(templates, "QuestEmptyStateTemplate", "TextLabel")
	local popupPanel = getDirectChildOfClass(popupGui, "Panel", "Frame")
	local popupLabel = getDirectChildOfClass(popupPanel, "Label", "TextLabel")
	if not (
		container
		and sizeConstraint
		and layout
		and header
		and collapseButton
		and reopenButton
		and templates
		and questCardTemplate
		and questEmptyStateTemplate
		and popupPanel
		and popupLabel
	) then
		warn("[QuestTracker] Authored QuestTrackerGui contract mismatch; preserve canonical widget names.")
		return false
	end

	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.Padding = UDim.new(0, 6)

	collapseButton.MouseButton1Click:Connect(function()
		self:SetCollapsed(true, false)
	end)

	reopenButton.MouseButton1Click:Connect(function()
		self:SetCollapsed(false, true)
	end)

	self._screenGui = screenGui
	self._container = container
	self._sizeConstraint = sizeConstraint
	self._header = header
	self._collapseButton = collapseButton
	self._reopenButton = reopenButton
	self._questCardTemplate = questCardTemplate
	self._questEmptyStateTemplate = questEmptyStateTemplate
	self._popupGui = popupGui
	self._popupPanel = popupPanel
	self._popupLabel = popupLabel
	self._popupGui.Enabled = false
	self._popupPanel.Visible = false
	self._popupPanel.Position = QUEST_POPUP_VISIBLE_POSITION
	if templates then
		templates.Visible = false
		setGuiTreeVisible(templates, false)
	end
	if questCardTemplate then
		setGuiTreeVisible(questCardTemplate, false)
	end
	if questEmptyStateTemplate then
		setGuiTreeVisible(questEmptyStateTemplate, false)
	end
	bindTrackerButtonImage(collapseButton)
	bindTrackerButtonImage(reopenButton)
	self._container.ClipsDescendants = true
	self:ApplyLayout()
	return true
end

function QuestTracker:_getMatchPhaseToken()
	local lifecyclePhase = tostring(self.player:GetAttribute(MATCH_LIFECYCLE_PHASE_ATTR) or "")
	if lifecyclePhase ~= "" then
		return lifecyclePhase
	end
	return tostring(self.player:GetAttribute(LEGACY_MATCH_PHASE_ATTR) or "")
end

function QuestTracker:ApplyLayout()
	local touchLayout = isTouchLayout()
	local viewport = getViewportOverrideSize()
	local compactLayout = ReplicatedStorage:GetAttribute(UI_FORCE_COMPACT_ATTR) == true
		or touchLayout
		or viewport.X <= 900
		or viewport.Y <= 520
	local preserveAuthoredDesktopLayout = shouldPreserveAuthoredOwnerLayout() or (not touchLayout and not compactLayout)

	if preserveAuthoredDesktopLayout then
		if self._container and self._container.Visible == true then
			animateQuestPanel(self._container, false)
		end
		self:_syncVisibility()
		return
	end

	self._container.Position = UDim2.new(1, compactLayout and -12 or -18, 1, touchLayout and -16 or (compactLayout and -12 or -18))
	self._container.Size = UDim2.fromOffset(
		touchLayout and math.min(232, math.max(210, viewport.X - 32)) or 280,
		touchLayout and (compactLayout and 182 or 194) or 228
	)
	self._sizeConstraint.MinSize = Vector2.new(204, touchLayout and 156 or 180)
	self._sizeConstraint.MaxSize = Vector2.new(touchLayout and 248 or 300, touchLayout and 206 or 260)
	self._header.TextSize = touchLayout and 12 or 13
	self._reopenButton.Position = UDim2.new(1, compactLayout and -12 or -18, 1, touchLayout and -16 or (compactLayout and -12 or -18))
	self._reopenButton.Size = UDim2.fromOffset(touchLayout and 96 or 116, touchLayout and 32 or 36)
	if self._container.Visible == true then
		animateQuestPanel(self._container, false)
	end
	self:_syncVisibility()
end

function QuestTracker:_isActiveMatchPhase()
	local phase = self:_getMatchPhaseToken()
	return ACTIVE_MATCH_PHASES[phase] == true
end

function QuestTracker:SetCollapsed(collapsed, markManualOpen)
	self._collapsed = collapsed == true
	if markManualOpen == true then
		self._manualExpandedDuringMatch = true
	elseif self._collapsed then
		self._manualExpandedDuringMatch = false
	end
	self:_syncVisibility()
end

function QuestTracker:_syncVisibility()
	local touchLayout = isTouchLayout()
	local activeMatchMobile = touchLayout and self:_isActiveMatchPhase()
	if touchLayout then
		if activeMatchMobile and self._manualExpandedDuringMatch ~= true then
			self._collapsed = true
		elseif not activeMatchMobile then
			self._manualExpandedDuringMatch = false
		end
	elseif not activeMatchMobile then
		self._manualExpandedDuringMatch = false
	end

	self._container.Visible = not self._collapsed
	self._reopenButton.Visible = self._collapsed
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

	local card = cloneGuiTemplate(self._questCardTemplate, "QuestCard", self._container)
	if not (card and card:IsA("Frame")) then
		warnMissingQuestTrackerTemplate(
			"QuestCardTemplate",
			"[QuestTracker] Missing authored template: Templates.QuestCardTemplate"
		)
		return nil
	end
	card.LayoutOrder = order
	setGuiTreeVisible(card, true)
	card.AutomaticSize = Enum.AutomaticSize.None
	card.AnchorPoint = Vector2.new(0, 0)
	card.Position = UDim2.new(0, 0, 0, 0)
	card.Size = UDim2.new(1, 0, 0, 58)
	card.ClipsDescendants = true

	local stripe = getDirectChildOfClass(card, "Accent", "Frame")
	local title = getDirectChildOfClass(card, "Title", "TextLabel")
	local bar = getDirectChildOfClass(card, "ProgressBar", "Frame")
	local fill = bar and getDirectChildOfClass(bar, "ProgressFill", "Frame")
	local progress = getDirectChildOfClass(card, "ProgressText", "TextLabel")
	if not (stripe and title and bar and fill and progress) then
		warnMissingQuestTrackerTemplate(
			"QuestCardTemplate:Children",
			"[QuestTracker] Authored QuestCardTemplate missing required children."
		)
		card:Destroy()
		return nil
	end

	stripe.BackgroundColor3 = Color3.fromRGB(116, 196, 255)
	stripe.Position = UDim2.new(0, 0, 0, 0)
	title.Text = tostring(mission.title or "Mission")
	title.AutomaticSize = Enum.AutomaticSize.None
	title.AnchorPoint = Vector2.new(0, 0)
	title.Position = UDim2.new(0, 10, 0, 4)
	title.Size = UDim2.new(1, -18, 0, 20)
	title.TextWrapped = false
	title.TextTruncate = Enum.TextTruncate.AtEnd
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(116, 196, 255)
	progress.Text = string.format("%d / %d", progressValue, requiredValue)
	progress.AutomaticSize = Enum.AutomaticSize.None
	progress.AnchorPoint = Vector2.new(0, 0)
	progress.Position = UDim2.new(0, 10, 0, 40)
	progress.Size = UDim2.new(1, -18, 0, 14)
	progress.TextWrapped = false
	progress.TextTruncate = Enum.TextTruncate.AtEnd
	return card
end

function QuestTracker:_createEmptyState(text, order)
	local placeholder = cloneGuiTemplate(self._questEmptyStateTemplate, "QuestEmptyState", self._container)
	if not (placeholder and placeholder:IsA("TextLabel")) then
		warnMissingQuestTrackerTemplate(
			"QuestEmptyStateTemplate",
			"[QuestTracker] Missing authored template: Templates.QuestEmptyStateTemplate"
		)
		return nil
	end
	setGuiTreeVisible(placeholder, true)
	placeholder.LayoutOrder = order or 0
	placeholder.Text = tostring(text)
	return placeholder
end

function QuestTracker:RefreshFromAttributes()
	local payload = decodeQuestPayload(self.player:GetAttribute(QUEST_DATA_ATTR))
	local active = payload.active or {}

	self:_clearCards()
	if #active == 0 then
		self:_createEmptyState("Tidak ada misi aktif.", 1)
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
	if self.player:GetAttribute("InMatch") == true then
		self:_hideCompletionPopup()
		return
	end

	local title = tostring(self.player:GetAttribute(QUEST_LAST_COMPLETED_TITLE_ATTR) or "Mission")
	local xp = math.floor(tonumber(self.player:GetAttribute(QUEST_LAST_COMPLETED_XP_ATTR)) or 0)
	local questId = tostring(self.player:GetAttribute(QUEST_LAST_COMPLETED_ID_ATTR) or "")

	if not (self._popupGui and self._popupPanel and self._popupLabel) then
		warnMissingQuestTrackerTemplate(
			"QuestPopupGui",
			"[QuestTracker] Missing authored QuestPopupGui contract during completion popup."
		)
		return
	end

	self._popupNonce = (self._popupNonce or 0) + 1
	local popupNonce = self._popupNonce
	self._popupGui.Enabled = true
	animateQuestPopup(self._popupPanel, true, false)
	self._popupLabel.Text = string.format(
		"Mission selesai!\n%s%s  (+%d XP)",
		title,
		questId ~= "" and ("  •  " .. questId) or "",
		xp
	)

	task.delay(3.2, function()
		if self._popupNonce ~= popupNonce or not self._popupPanel.Parent then
			return
		end
		animateQuestPopup(self._popupPanel, false, false)
		task.delay(QUEST_POPUP_OUT_HIDE_DELAY, function()
			if self._popupNonce == popupNonce and self._popupGui.Parent then
				self._popupPanel.Visible = false
				self._popupGui.Enabled = false
			end
		end)
	end)
end

function QuestTracker:_hideCompletionPopup()
	self._popupNonce = (self._popupNonce or 0) + 1
	if self._popupPanel then
		if self._popupPanel.Visible == true then
			animateQuestPopup(self._popupPanel, false, false)
			task.delay(QUEST_POPUP_OUT_HIDE_DELAY, function()
				if self._popupPanel and self._popupGui then
					self._popupPanel.Visible = false
					self._popupGui.Enabled = false
				end
			end)
		else
			self._popupPanel.Visible = false
		end
	end
	if self._popupGui then
		self._popupGui.Enabled = false
	end
end

function QuestTracker:Connect()
	table.insert(self._connections, self.player:GetAttributeChangedSignal(QUEST_DATA_ATTR):Connect(function()
		self:RefreshFromAttributes()
	end))

	table.insert(self._connections, self.player:GetAttributeChangedSignal(QUEST_LAST_COMPLETED_AT_ATTR):Connect(function()
		self:_showCompletionPopup()
	end))
	table.insert(self._connections, self.player:GetAttributeChangedSignal("InMatch"):Connect(function()
		if self.player:GetAttribute("InMatch") == true then
			self:_hideCompletionPopup()
		end
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
end

return QuestTracker
