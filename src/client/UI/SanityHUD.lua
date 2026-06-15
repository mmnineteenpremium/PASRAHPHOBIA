local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local SANITY_ATTRS = { "PasrahSanityValue", "Sanity" }
local MATCH_ATTR = "InMatch"

local SanityHUD = {}
SanityHUD.__index = SanityHUD

local function getDirectChildOfClass(parent, childName, className)
	local child = parent and parent:FindFirstChild(childName)
	if child and child:IsA(className) then
		return child
	end
	return nil
end

local function getPlayerSanity(player)
	for _, attrName in ipairs(SANITY_ATTRS) do
		local value = tonumber(player:GetAttribute(attrName))
		if value ~= nil then
			return math.clamp(math.floor(value), 0, 100)
		end
	end
	return 100
end

local function ensureFallbackSanityHUDGui(playerGui)
	if not playerGui then
		return nil
	end
	local screenGui = playerGui:FindFirstChild("SanityHUDGui")
	if not (screenGui and screenGui:IsA("ScreenGui")) then
		if screenGui then
			screenGui:Destroy()
		end
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "SanityHUDGui"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = playerGui
	end

	local container = getDirectChildOfClass(screenGui, "Container", "Frame")
	if not container then
		container = Instance.new("Frame")
		container.Name = "Container"
		container.AnchorPoint = Vector2.new(0, 1)
		container.Position = UDim2.new(0, 24, 1, -96)
		container.Size = UDim2.fromOffset(214, 54)
		container.BackgroundColor3 = Color3.fromRGB(12, 15, 20)
		container.BackgroundTransparency = 0.12
		container.BorderSizePixel = 0
		container.Parent = screenGui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = container
	end
	local label = getDirectChildOfClass(container, "Label", "TextLabel")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromOffset(12, 6)
		label.Size = UDim2.fromOffset(98, 18)
		label.Font = Enum.Font.GothamBold
		label.Text = "SANITY"
		label.TextColor3 = Color3.fromRGB(230, 235, 242)
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container
	end
	local valueLabel = getDirectChildOfClass(container, "ValueLabel", "TextLabel")
	if not valueLabel then
		valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "ValueLabel"
		valueLabel.BackgroundTransparency = 1
		valueLabel.Position = UDim2.new(1, -60, 0, 6)
		valueLabel.Size = UDim2.fromOffset(48, 18)
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.Text = "100"
		valueLabel.TextColor3 = Color3.fromRGB(230, 235, 242)
		valueLabel.TextSize = 13
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = container
	end
	local bar = getDirectChildOfClass(container, "Bar", "Frame")
	if not bar then
		bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.Position = UDim2.fromOffset(12, 31)
		bar.Size = UDim2.new(1, -24, 0, 10)
		bar.BackgroundColor3 = Color3.fromRGB(36, 42, 54)
		bar.BorderSizePixel = 0
		bar.Parent = container
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = bar
	end
	local fill = getDirectChildOfClass(bar, "Fill", "Frame")
	if not fill then
		fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(124, 88, 220)
		fill.BorderSizePixel = 0
		fill.Parent = bar
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = fill
	end
	local vignette = getDirectChildOfClass(screenGui, "SanityVignette", "Frame")
	if not vignette then
		vignette = Instance.new("Frame")
		vignette.Name = "SanityVignette"
		vignette.Size = UDim2.fromScale(1, 1)
		vignette.BackgroundColor3 = Color3.fromRGB(120, 18, 34)
		vignette.BackgroundTransparency = 1
		vignette.BorderSizePixel = 0
		vignette.ZIndex = 0
		vignette.Parent = screenGui
	end
	return screenGui
end

function SanityHUD.new(playerGui)
	local self = setmetatable({}, SanityHUD)
	self.playerGui = playerGui
	self.player = Players.LocalPlayer
	self._connections = {}
	self._sanity = getPlayerSanity(self.player)
	self._vignetteTween = nil
	if self:BuildUI() then
		self:Connect()
		self:Refresh()
	end
	return self
end

function SanityHUD:BuildUI()
	local screenGui = self.playerGui:FindFirstChild("SanityHUDGui") or self.playerGui:WaitForChild("SanityHUDGui", 5)
	if not screenGui or not screenGui:IsA("ScreenGui") then
		warn("[SanityHUD] Missing authored SanityHUDGui ScreenGui; check StarterGui shell contract.")
		screenGui = ensureFallbackSanityHUDGui(self.playerGui)
	end
	local container = getDirectChildOfClass(screenGui, "Container", "Frame")
	local label = getDirectChildOfClass(container, "Label", "TextLabel")
	local bar = getDirectChildOfClass(container, "Bar", "Frame")
	local fill = getDirectChildOfClass(bar, "Fill", "Frame")
	local valueLabel = getDirectChildOfClass(container, "ValueLabel", "TextLabel")
	local vignette = getDirectChildOfClass(screenGui, "SanityVignette", "Frame")
	if not (container and label and bar and fill and valueLabel and vignette) then
		warn("[SanityHUD] Authored SanityHUDGui contract mismatch; preserve canonical widget names.")
		screenGui = ensureFallbackSanityHUDGui(self.playerGui)
		container = getDirectChildOfClass(screenGui, "Container", "Frame")
		label = getDirectChildOfClass(container, "Label", "TextLabel")
		bar = getDirectChildOfClass(container, "Bar", "Frame")
		fill = getDirectChildOfClass(bar, "Fill", "Frame")
		valueLabel = getDirectChildOfClass(container, "ValueLabel", "TextLabel")
		vignette = getDirectChildOfClass(screenGui, "SanityVignette", "Frame")
		if not (container and label and bar and fill and valueLabel and vignette) then
			return false
		end
	end

	self._screenGui = screenGui
	self._fill = fill
	self._valueLabel = valueLabel
	self._vignette = vignette
	return true
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
		TweenInfo.new(0.68, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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
			TweenInfo.new(0.52, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		):Play()
	end
end

function SanityHUD:Refresh()
	if not self._screenGui then
		return
	end
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
