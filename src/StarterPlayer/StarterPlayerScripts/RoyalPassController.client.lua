local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function createRoyalPassUI()
	local existing = playerGui:FindFirstChild("RoyalPassUI")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RoyalPassUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.fromScale(0.5, 0.5)
	mainFrame.Size = UDim2.fromScale(0.6, 0.75)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 16)
	uiCorner.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = "ROYAL PASS - SEASON 1"
	titleLabel.Parent = mainFrame

	local levelDisplay = Instance.new("TextLabel")
	levelDisplay.Name = "LevelDisplay"
	levelDisplay.Size = UDim2.new(1, 0, 0, 30)
	levelDisplay.Position = UDim2.new(0, 0, 0, 46)
	levelDisplay.BackgroundTransparency = 1
	levelDisplay.Font = Enum.Font.Gotham
	levelDisplay.TextSize = 20
	levelDisplay.TextColor3 = Color3.fromRGB(200, 200, 255)
	levelDisplay.Text = "Level: 1/100"
	levelDisplay.Parent = mainFrame

	local xpBar = Instance.new("Frame")
	xpBar.Name = "XPBar"
	xpBar.Size = UDim2.new(0.9, 0, 0, 20)
	xpBar.Position = UDim2.new(0.05, 0, 0, 86)
	xpBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	xpBar.BorderSizePixel = 0
	xpBar.Parent = mainFrame

	local xpFill = Instance.new("Frame")
	xpFill.Name = "XPFill"
	xpFill.Size = UDim2.new(0, 0, 1, 0)
	xpFill.BackgroundColor3 = Color3.fromRGB(120, 255, 200)
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpBar

	local xpGradient = Instance.new("UIGradient")
	xpGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(116, 233, 199)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(53, 193, 255)),
	})
	xpGradient.Parent = xpFill

	local rewardGrid = Instance.new("ScrollingFrame")
	rewardGrid.Name = "RewardGrid"
	rewardGrid.Size = UDim2.new(0.95, 0, 0.7, -140)
	rewardGrid.Position = UDim2.new(0.025, 0, 0, 116)
	rewardGrid.BackgroundTransparency = 1
	rewardGrid.BorderSizePixel = 0
	rewardGrid.ScrollBarThickness = 6
	rewardGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rewardGrid.Parent = mainFrame

	local claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0.4, 0, 0, 38)
	claimButton.Position = UDim2.new(0.05, 0, 1, -60)
	claimButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
	claimButton.BorderSizePixel = 0
	claimButton.Font = Enum.Font.GothamBold
	claimButton.TextSize = 18
	claimButton.Text = "CLAIM REWARDS"
	claimButton.Parent = mainFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 32, 0, 32)
	closeButton.Position = UDim2.new(1, -42, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 18
	closeButton.Text = "X"
	closeButton.Parent = mainFrame

	return {
		screen = screenGui,
		mainFrame = mainFrame,
		levelDisplay = levelDisplay,
		xpBar = xpBar,
		xpFill = xpFill,
		rewardGrid = rewardGrid,
		claimButton = claimButton,
		closeButton = closeButton,
	}
end

local ui = createRoyalPassUI()
local mainFrame = ui.mainFrame
mainFrame.Visible = false

local function toggleRoyalPass()
	mainFrame.Visible = not mainFrame.Visible
end

local function ensureRewardLayout(grid)
	local layout = grid:FindFirstChildOfClass("UIGridLayout")
	if layout then
		layout:Destroy()
	end
	layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 80, 0, 100)
	layout.CellPadding = UDim2.new(0, 10, 0, 10)
	layout.Parent = grid
	return layout
end

local function updateRoyalPassUI(data)
	ui.levelDisplay.Text = string.format("Level: %d/100", data.level)
	local xpProgress = (data.xp % 1000) / 1000
	ui.xpFill.Size = UDim2.new(xpProgress, 0, 1, 0)

	for _, child in ipairs(ui.rewardGrid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for level = 1, 100 do
		local rewardSlot = Instance.new("Frame")
		rewardSlot.Name = "Slot" .. level
		rewardSlot.Size = UDim2.new(0, 80, 0, 100)
		rewardSlot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		rewardSlot.BorderSizePixel = 0

		local levelLabel = Instance.new("TextLabel")
		levelLabel.Text = tostring(level)
		levelLabel.Font = Enum.Font.GothamSemibold
		levelLabel.TextSize = 16
		levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Size = UDim2.new(1, 0, 0.2, 0)
		levelLabel.Parent = rewardSlot

		local freeReward = Instance.new("TextLabel")
		freeReward.Text = (level % 5 == 0) and "🎁 Free" or "-"
		freeReward.Font = Enum.Font.Gotham
		freeReward.TextSize = 14
		freeReward.TextColor3 = Color3.fromRGB(200, 200, 200)
		freeReward.BackgroundTransparency = 1
		freeReward.Position = UDim2.new(0, 0, 0.2, 0)
		freeReward.Size = UDim2.new(1, 0, 0.4, 0)
		freeReward.Parent = rewardSlot

		local premiumReward = Instance.new("TextLabel")
		premiumReward.Text = data.premiumActive and "💎 Premium" or "🔒"
		premiumReward.Font = Enum.Font.Gotham
		premiumReward.TextSize = 14
		premiumReward.TextColor3 = Color3.fromRGB(255, 215, 0)
		premiumReward.BackgroundTransparency = 1
		premiumReward.Position = UDim2.new(0, 0, 0.6, 0)
		premiumReward.Size = UDim2.new(1, 0, 0.4, 0)
		premiumReward.Parent = rewardSlot

		if table.find(data.claimedRewards, level) then
			rewardSlot.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		elseif level <= data.level then
			rewardSlot.BackgroundColor3 = Color3.fromRGB(200, 200, 0)
		else
			rewardSlot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		end

		rewardSlot.Parent = ui.rewardGrid
	end

	ensureRewardLayout(ui.rewardGrid)
end

ui.claimButton.MouseButton1Click:Connect(function()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	local claimEvent = remoteEvents:FindFirstChild("ClaimRoyalPass")
	if claimEvent then
		claimEvent:FireServer()
	end
end)

ui.closeButton.MouseButton1Click:Connect(function()
	toggleRoyalPass()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.P then
		toggleRoyalPass()
	end
end)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local royalPassUpdateEvent = remoteEvents:WaitForChild("RoyalPassUpdate")
local getRoyalPassFunction = remoteEvents:WaitForChild("GetRoyalPass")

royalPassUpdateEvent.OnClientEvent:Connect(function(data)
	updateRoyalPassUI(data)
end)

if getRoyalPassFunction then
	local ok, data = pcall(function()
		return getRoyalPassFunction:InvokeServer()
	end)
	if ok and data then
		updateRoyalPassUI(data)
	end
end

print("[RoyalPassController] Initialized")
