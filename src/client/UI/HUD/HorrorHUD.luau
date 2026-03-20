local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local VIGNETTE_IMAGE = "rbxassetid://YOUR_VIGNETTE_TEXTURE_ID"
local VIGNETTE_TWEEN_TIME = 0.45

local HorrorHUD = {}
HorrorHUD.__index = HorrorHUD

local function findLobbyUI(playerGui)
	if not playerGui then
		return nil
	end
	return playerGui:FindFirstChild("LobbyUI")
end

local function createVignetteGui(playerGui)
	local existing = playerGui:FindFirstChild("SensoryHorrorHUD")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SensoryHorrorHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local intensityFrame = Instance.new("ImageLabel")
	intensityFrame.Name = "Vignette"
	intensityFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	intensityFrame.Position = UDim2.fromScale(0.5, 0.5)
	intensityFrame.Size = UDim2.fromScale(1.2, 1.2)
	intensityFrame.BackgroundTransparency = 1
	intensityFrame.BorderSizePixel = 0
	intensityFrame.Image = VIGNETTE_IMAGE
	intensityFrame.ImageColor3 = Color3.fromRGB(0, 0, 0)
	intensityFrame.ImageTransparency = 1
	intensityFrame.Parent = screenGui

	return screenGui
end

function HorrorHUD:Init(context)
	self._context = context or {}
	self._remotes = self._context.Remotes or {}
	self._player = Players.LocalPlayer
	self._connections = {}
	self._vignetteTween = nil
	self._lobbyFadeTween = nil
	self._currentSanity = 100
end

function HorrorHUD:Start()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	self._playerGui = playerGui
	self._vignetteGui = createVignetteGui(playerGui)
	self._vignetteImage = self._vignetteGui:FindFirstChild("Vignette")
	self:_ensureLobbyCanvasGroup()

	self._playerGui.ChildAdded:Connect(function(child)
		if child.Name == "LobbyUI" then
			self:_ensureLobbyCanvasGroup()
		end
	end)

	local sanityEvent = self._remotes.SanityEvent
	if sanityEvent and sanityEvent.OnClientEvent then
		table.insert(self._connections, sanityEvent.OnClientEvent:Connect(function(payload)
			self:_handleSanity(payload)
		end))
	end

	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_handleMatchEvent(payload)
		end))
	end
end

function HorrorHUD:Stop()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
	self._connections = {}
end

function HorrorHUD:_getPlayerGui()
	if not self._player then
		return nil
	end
	return self._player:FindFirstChildOfClass("PlayerGui") or self._player:WaitForChild("PlayerGui", 5)
end

function HorrorHUD:_handleSanity(payload)
	local sanity = tonumber((payload and payload.newSanity) or (payload and payload.sanity) or payload) or 100
	self._currentSanity = math.clamp(sanity, 0, 100)
	self:_tweenVignette()
end

function HorrorHUD:_tweenVignette()
	if not self._vignetteImage then
		return
	end

	local normalized = math.clamp(self._currentSanity / 100, 0, 1)
	local targetTransparency = math.clamp(0.15 + (1 - normalized) * 0.7, 0.15, 0.9)

	if self._vignetteTween then
		self._vignetteTween:Cancel()
	end

	self._vignetteTween = TweenService:Create(
		self._vignetteImage,
		TweenInfo.new(VIGNETTE_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ ImageTransparency = targetTransparency }
	)
	self._vignetteTween:Play()
end

function HorrorHUD:_ensureLobbyCanvasGroup()
	local playerGui = self._playerGui or self:_getPlayerGui()
	if not playerGui then
		return
	end

	local lobbyGui = findLobbyUI(playerGui)
	if not lobbyGui then
		return
	end

	local canvasGroup = lobbyGui:FindFirstChild("SensoryLobbyCanvasGroup")
	if not canvasGroup then
		canvasGroup = Instance.new("CanvasGroup")
		canvasGroup.Name = "SensoryLobbyCanvasGroup"
		canvasGroup.GroupTransparency = 0
		canvasGroup.Parent = lobbyGui
	end

	self._lobbyCanvasGroup = canvasGroup
end

function HorrorHUD:_handleMatchEvent(payload)
	local eventName = payload and payload.eventName
	if not eventName then
		return
	end

	if eventName == "MatchStarted" then
		self:_fadeLobby(1)
	elseif eventName == "MatchEnded" then
		self:_fadeLobby(0)
	end
end

function HorrorHUD:_fadeLobby(target)
	if not self._lobbyCanvasGroup then
		self:_ensureLobbyCanvasGroup()
	end
	if not self._lobbyCanvasGroup then
		return
	end

	if self._lobbyFadeTween then
		self._lobbyFadeTween:Cancel()
	end

	self._lobbyFadeTween = TweenService:Create(
		self._lobbyCanvasGroup,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = target }
	)
	self._lobbyFadeTween:Play()
end

return setmetatable({}, HorrorHUD)
