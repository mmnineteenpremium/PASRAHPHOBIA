local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local SANITY_ATTRS = { "PasrahSanityValue", "Sanity" }
local MATCH_ATTR = "InMatch"

local SanityHUD = {}
SanityHUD.__index = SanityHUD

local function getPlayerSanity(player)
	for _, attrName in ipairs(SANITY_ATTRS) do
		local value = tonumber(player:GetAttribute(attrName))
		if value ~= nil then
			return math.clamp(math.floor(value), 0, 100)
		end
	end
	return 100
end

function SanityHUD.new(playerGui)
	local self = setmetatable({}, SanityHUD)
	self.playerGui = playerGui
	self.player = Players.LocalPlayer
	self._connections = {}
	self._sanity = getPlayerSanity(self.player)
	self._vignetteTween = nil
	self:BuildUI()
	self:Connect()
	self:Refresh()
	return self
end

function SanityHUD:BuildUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SanityHUDGui"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = self.playerGui

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(210, 32)
	container.Position = UDim2.new(0, 18, 0, 116)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(68, 32)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamSemibold
	label.Text = " SANITY"
	label.TextColor3 = Color3.fromRGB(191, 174, 246)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromOffset(112, 10)
	bar.Position = UDim2.fromOffset(68, 11)
	bar.BackgroundColor3 = Color3.fromRGB(39, 40, 56)
	bar.BorderSizePixel = 0
	bar.Parent = container

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 5)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(124, 88, 220)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = fill

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.fromOffset(30, 32)
	valueLabel.Position = UDim2.new(1, -30, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = "100"
	valueLabel.TextColor3 = Color3.fromRGB(230, 223, 255)
	valueLabel.TextSize = 12
	valueLabel.Parent = container

	local vignette = Instance.new("Frame")
	vignette.Name = "SanityVignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(64, 10, 86)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 4
	vignette.Parent = screenGui

	self._screenGui = screenGui
	self._fill = fill
	self._valueLabel = valueLabel
	self._vignette = vignette
end

function SanityHUD:_cancelVignetteTween()
	if self._vignetteTween then
		self._vignetteTween:Cancel()
		self._vignetteTween = nil
	end
end

function SanityHUD:_applySanityVisuals()
	local ratio = math.clamp(self._sanity / 100, 0, 1)
	TweenService:Create(
		self._fill,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(ratio, 0, 1, 0) }
	):Play()

	self._valueLabel.Text = tostring(self._sanity)
	self._fill.BackgroundColor3 = self._sanity > 60 and Color3.fromRGB(124, 88, 220)
		or self._sanity > 30 and Color3.fromRGB(224, 180, 68)
		or Color3.fromRGB(214, 72, 110)

	if self._sanity < 30 then
		self:_cancelVignetteTween()
		self._vignetteTween = TweenService:Create(
			self._vignette,
			TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundTransparency = 0.72 }
		)
		self._vignetteTween:Play()
	else
		self:_cancelVignetteTween()
		TweenService:Create(
			self._vignette,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		):Play()
	end
end

function SanityHUD:Refresh()
	self._sanity = getPlayerSanity(self.player)
	self._screenGui.Enabled = self.player:GetAttribute(MATCH_ATTR) == true
	self:_applySanityVisuals()
end

function SanityHUD:Connect()
	for _, attrName in ipairs(SANITY_ATTRS) do
		table.insert(self._connections, self.player:GetAttributeChangedSignal(attrName):Connect(function()
			self:Refresh()
		end))
	end

	table.insert(self._connections, self.player:GetAttributeChangedSignal(MATCH_ATTR):Connect(function()
		self:Refresh()
	end))
end

return SanityHUD
