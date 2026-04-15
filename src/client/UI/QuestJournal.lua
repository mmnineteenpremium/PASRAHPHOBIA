local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local QUEST_DATA_ATTR = "PasrahQuestData"
local QUEST_UPDATED_AT_ATTR = "PasrahQuestDataUpdatedAt"
local JOURNAL_TOGGLE_KEY = Enum.KeyCode.Q

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

local function clearList(container)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

function QuestJournal.new(playerGui)
	local self = setmetatable({}, QuestJournal)
	self.playerGui = playerGui
	self.player = Players.LocalPlayer
	self._connections = {}
	self._open = false
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
	screenGui.Enabled = false
	screenGui.Parent = self.playerGui

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(700, 520)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(15, 16, 26)
	panel.BorderSizePixel = 0
	panel.Parent = overlay

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 16)
	panelCorner.Parent = panel

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundColor3 = Color3.fromRGB(24, 27, 41)
	header.BorderSizePixel = 0
	header.Font = Enum.Font.GothamBold
	header.Text = "  MISSION JOURNAL"
	header.TextColor3 = Color3.fromRGB(244, 244, 250)
	header.TextSize = 24
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = panel

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 16)
	headerCorner.Parent = header

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(38, 38)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -10, 0, 8)
	closeButton.BackgroundColor3 = Color3.fromRGB(154, 41, 41)
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
	subtitle.Size = UDim2.new(1, -24, 0, 20)
	subtitle.Position = UDim2.fromOffset(12, 60)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Daily mission sync pending..."
	subtitle.TextColor3 = Color3.fromRGB(168, 174, 193)
	subtitle.TextSize = 12
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = panel

	local activeLabel = Instance.new("TextLabel")
	activeLabel.Size = UDim2.new(1, -24, 0, 24)
	activeLabel.Position = UDim2.fromOffset(12, 92)
	activeLabel.BackgroundTransparency = 1
	activeLabel.Font = Enum.Font.GothamSemibold
	activeLabel.Text = "ACTIVE DAILY MISSIONS"
	activeLabel.TextColor3 = Color3.fromRGB(116, 196, 255)
	activeLabel.TextSize = 14
	activeLabel.TextXAlignment = Enum.TextXAlignment.Left
	activeLabel.Parent = panel

	local activeList = Instance.new("ScrollingFrame")
	activeList.Name = "ActiveList"
	activeList.Size = UDim2.new(1, -24, 0, 250)
	activeList.Position = UDim2.fromOffset(12, 122)
	activeList.BackgroundTransparency = 1
	activeList.BorderSizePixel = 0
	activeList.ScrollBarThickness = 4
	activeList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	activeList.CanvasSize = UDim2.new()
	activeList.Parent = panel

	local activeLayout = Instance.new("UIListLayout")
	activeLayout.Padding = UDim.new(0, 8)
	activeLayout.Parent = activeList

	local completedLabel = Instance.new("TextLabel")
	completedLabel.Size = UDim2.new(1, -24, 0, 24)
	completedLabel.Position = UDim2.fromOffset(12, 386)
	completedLabel.BackgroundTransparency = 1
	completedLabel.Font = Enum.Font.GothamSemibold
	completedLabel.Text = "COMPLETED TODAY"
	completedLabel.TextColor3 = Color3.fromRGB(255, 196, 94)
	completedLabel.TextSize = 14
	completedLabel.TextXAlignment = Enum.TextXAlignment.Left
	completedLabel.Parent = panel

	local completedList = Instance.new("ScrollingFrame")
	completedList.Name = "CompletedList"
	completedList.Size = UDim2.new(1, -24, 1, -422)
	completedList.Position = UDim2.fromOffset(12, 416)
	completedList.BackgroundTransparency = 1
	completedList.BorderSizePixel = 0
	completedList.ScrollBarThickness = 4
	completedList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	completedList.CanvasSize = UDim2.new()
	completedList.Parent = panel

	local completedLayout = Instance.new("UIListLayout")
	completedLayout.Padding = UDim.new(0, 8)
	completedLayout.Parent = completedList

	closeButton.MouseButton1Click:Connect(function()
		self:Close()
	end)

	self._screenGui = screenGui
	self._subtitle = subtitle
	self._activeList = activeList
	self._completedList = completedList
end

function QuestJournal:_createMissionCard(parent, mission, isCompleted)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, isCompleted and 76 or 92)
	card.BackgroundColor3 = isCompleted and Color3.fromRGB(24, 26, 32) or Color3.fromRGB(26, 30, 44)
	card.BorderSizePixel = 0
	card.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 5, 1, 0)
	stripe.BackgroundColor3 = isCompleted and Color3.fromRGB(255, 196, 94) or Color3.fromRGB(116, 196, 255)
	stripe.BorderSizePixel = 0
	stripe.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -140, 0, 22)
	title.Position = UDim2.fromOffset(14, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamSemibold
	title.Text = tostring(mission.title or "Mission")
	title.TextColor3 = isCompleted and Color3.fromRGB(210, 210, 214) or Color3.fromRGB(244, 244, 250)
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local reward = Instance.new("TextLabel")
	reward.Size = UDim2.fromOffset(116, 24)
	reward.AnchorPoint = Vector2.new(1, 0)
	reward.Position = UDim2.new(1, -10, 0, 8)
	reward.BackgroundColor3 = Color3.fromRGB(64, 52, 18)
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
		status.Size = UDim2.new(1, -24, 0, 18)
		status.Position = UDim2.fromOffset(14, 54)
		status.BackgroundTransparency = 1
		status.Font = Enum.Font.GothamSemibold
		status.Text = "Selesai hari ini"
		status.TextColor3 = Color3.fromRGB(146, 220, 132)
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
	bar.BackgroundColor3 = Color3.fromRGB(43, 47, 64)
	bar.BorderSizePixel = 0
	bar.Parent = card

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 5)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(116, 196, 255)
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
	clearList(self._activeList)
	clearList(self._completedList)

	local active = self._data.active or {}
	local completed = self._data.completed or {}
	local updatedAt = tonumber(self.player:GetAttribute(QUEST_UPDATED_AT_ATTR))

	if updatedAt then
		self._subtitle.Text = ("Daily mission sync • %ds lalu"):format(math.max(0, math.floor((nowMillis() - updatedAt) / 1000)))
	else
		self._subtitle.Text = "Daily mission sync pending..."
	end

	if #active == 0 then
		local placeholder = Instance.new("TextLabel")
		placeholder.Size = UDim2.new(1, 0, 0, 44)
		placeholder.BackgroundTransparency = 1
		placeholder.Font = Enum.Font.Gotham
		placeholder.Text = "Belum ada misi aktif."
		placeholder.TextColor3 = Color3.fromRGB(136, 142, 159)
		placeholder.TextSize = 13
		placeholder.Parent = self._activeList
	else
		for _, mission in ipairs(active) do
			self:_createMissionCard(self._activeList, mission, false)
		end
	end

	if #completed == 0 then
		local placeholder = Instance.new("TextLabel")
		placeholder.Size = UDim2.new(1, 0, 0, 32)
		placeholder.BackgroundTransparency = 1
		placeholder.Font = Enum.Font.Gotham
		placeholder.Text = "Belum ada misi yang selesai."
		placeholder.TextColor3 = Color3.fromRGB(136, 142, 159)
		placeholder.TextSize = 13
		placeholder.Parent = self._completedList
	else
		for _, mission in ipairs(completed) do
			self:_createMissionCard(self._completedList, mission, true)
		end
	end
end

function QuestJournal:RefreshFromAttributes()
	self._data = decodeQuestPayload(self.player and self.player:GetAttribute(QUEST_DATA_ATTR))
	if self._open then
		self:Render()
	end
end

function QuestJournal:Connect()
	table.insert(self._connections, self.player:GetAttributeChangedSignal(QUEST_DATA_ATTR):Connect(function()
		self:RefreshFromAttributes()
	end))

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
	self._screenGui.Enabled = true
	self:Render()
end

function QuestJournal:Close()
	self._open = false
	self._screenGui.Enabled = false
end

function QuestJournal:Toggle()
	if self._open then
		self:Close()
	else
		self:Open()
	end
end

return QuestJournal
