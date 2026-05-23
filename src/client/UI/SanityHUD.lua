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
		return false
	end

	local container = getDirectChildOfClass(screenGui, "Container", "Frame")
	local label = getDirectChildOfClass(container, "Label", "TextLabel")
	local bar = getDirectChildOfClass(container, "Bar", "Frame")
	local fill = getDirectChildOfClass(bar, "Fill", "Frame")
	local valueLabel = getDirectChildOfClass(container, "ValueLabel", "TextLabel")
	local vignette = getDirectChildOfClass(screenGui, "SanityVignette", "Frame")
	if not (container and label and bar and fill and valueLabel and vignette) then
		warn("[SanityHUD] Authored SanityHUDGui contract mismatch; preserve canonical widget names.")
		return false
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
