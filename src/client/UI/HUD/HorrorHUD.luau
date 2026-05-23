local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local VIGNETTE_IMAGE = nil
local VIGNETTE_TWEEN_TIME = 0.45

local HorrorHUD = {}
HorrorHUD.__index = HorrorHUD

local ACTIVE_MATCH_PHASES = {
	PreparationPhase = true,
	InvestigationPhase = true,
	HuntPhase = true,
	InGame = true,
	Escalation = true,
	Hunt = true,
}

local function findLobbyUI(playerGui)
	if not playerGui then
		return nil
	end
	return playerGui:FindFirstChild("LobbyUI")
end

local function isPlayerInMatch(player)
	if not player then
		return false
	end
	return player:GetAttribute("InMatch") == true
		or tostring(player:GetAttribute("MatchId") or "") ~= ""
end

local function isActiveMatchPhase(player)
	if not player then
		return false
	end
	local lifecyclePhase = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	if lifecyclePhase ~= "" then
		return ACTIVE_MATCH_PHASES[lifecyclePhase] == true
	end
	return ACTIVE_MATCH_PHASES[tostring(player:GetAttribute("MatchPhase") or "")] == true
end

local function hasConfiguredVignetteImage()
	return type(VIGNETTE_IMAGE) == "string"
		and VIGNETTE_IMAGE ~= ""
		and string.match(VIGNETTE_IMAGE, "^rbxassetid://%d+$") ~= nil
end

local warnedContracts = {}

local function warnContract(message)
	if warnedContracts[message] then
		return
	end
	warnedContracts[message] = true
	warn(message)
end

local function bindVignetteGui(playerGui)
	local gui = playerGui and playerGui:FindFirstChild("SensoryHorrorHUD")
	if not (gui and gui:IsA("ScreenGui")) then
		warnContract("[HorrorHUD] Missing authored SensoryHorrorHUD ScreenGui; check StarterGui shell contract.")
		return nil
	end

	local vignette = gui:FindFirstChild("Vignette")
	if hasConfiguredVignetteImage() then
		if not (vignette and vignette:IsA("ImageLabel")) then
			warnContract("[HorrorHUD] Authored SensoryHorrorHUD contract mismatch: Vignette ImageLabel required for image mode.")
			return nil
		end
		vignette.Image = VIGNETTE_IMAGE
		vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
		vignette.ImageTransparency = 1
	else
		if not (vignette and vignette:IsA("CanvasGroup")) then
			warnContract("[HorrorHUD] Authored SensoryHorrorHUD contract mismatch: Vignette CanvasGroup required.")
			return nil
		end
		vignette.GroupTransparency = 1
	end

	gui.Enabled = false
	return gui
end

local function stampHorrorHUDInstance(instance, channel, phase, sanity, inMatch, lastEvent, sanitySource, sanityFresh)
	if typeof(instance) ~= "Instance" then
		return
	end
	instance:SetAttribute("PasrahHUDOwner", "HorrorHUD")
	instance:SetAttribute("PasrahHUDChannel", tostring(channel or instance.Name))
	instance:SetAttribute("PasrahHUDPhase", type(phase) == "string" and phase ~= "" and phase or nil)
	instance:SetAttribute("PasrahHUDSanity", tonumber(sanity))
	instance:SetAttribute("PasrahHUDInMatch", inMatch == true)
	instance:SetAttribute("PasrahHUDEvent", type(lastEvent) == "string" and lastEvent ~= "" and lastEvent or nil)
	instance:SetAttribute("PasrahHUDSanitySource", type(sanitySource) == "string" and sanitySource ~= "" and sanitySource or nil)
	instance:SetAttribute("PasrahHUDSanityFresh", sanityFresh == true)
end

function HorrorHUD:Init(context)
	self._context = context or {}
	self._remotes = self._context.Remotes or {}
	self._player = Players.LocalPlayer
	self._connections = {}
	self._vignetteTween = nil
	self._lobbyFadeTween = nil
	self._currentSanity = 100
	self._lastEventName = nil
	self._hasSanityReading = false
	self._lastSanityAt = nil
end

function HorrorHUD:Start()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	self._playerGui = playerGui
	self:_ensureLobbyCanvasGroup()
	self:_syncHudPresence()

	table.insert(self._connections, self._playerGui.ChildAdded:Connect(function(child)
		if child.Name == "LobbyUI" then
			self:_ensureLobbyCanvasGroup()
		end
	end))

	table.insert(self._connections, self._player:GetAttributeChangedSignal("InMatch"):Connect(function()
		self:_syncHudPresence()
	end))
	table.insert(self._connections, self._player:GetAttributeChangedSignal("MatchId"):Connect(function()
		self:_syncHudPresence()
	end))
	table.insert(self._connections, self._player:GetAttributeChangedSignal("MatchPhase"):Connect(function()
		self:_syncHudPresence()
	end))
	table.insert(self._connections, self._player:GetAttributeChangedSignal("MatchLifecyclePhase"):Connect(function()
		self:_syncHudPresence()
	end))

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

function HorrorHUD:_ensureVignetteGui()
	local playerGui = self._playerGui or self:_getPlayerGui()
	if not playerGui then
		return nil
	end

	self._playerGui = playerGui
	self._vignetteGui = bindVignetteGui(playerGui)
	self._vignetteImage = self._vignetteGui and self._vignetteGui:FindFirstChild("Vignette") or nil
	self:_stampRuntimeIdentity()
	return self._vignetteGui
end

function HorrorHUD:_stampRuntimeIdentity()
	local phase = tostring(
		(self._player and self._player:GetAttribute("MatchLifecyclePhase"))
			or (self._player and self._player:GetAttribute("MatchPhase"))
			or ""
	)
	local inMatch = isPlayerInMatch(self._player)
	local sanity = self._hasSanityReading and self._currentSanity or nil
	local sanitySource = self._hasSanityReading and "SanityEvent" or nil
	local sanityFresh = type(self._lastSanityAt) == "number" and (os.clock() - self._lastSanityAt) <= 1.5
	stampHorrorHUDInstance(self._vignetteGui, "SensoryHorrorHUD", phase, sanity, inMatch, self._lastEventName, sanitySource, sanityFresh)
	stampHorrorHUDInstance(self._vignetteImage, "Vignette", phase, sanity, inMatch, self._lastEventName, sanitySource, sanityFresh)
	stampHorrorHUDInstance(self._lobbyCanvasGroup, "LobbyCanvas", phase, sanity, inMatch, self._lastEventName, sanitySource, sanityFresh)
end

function HorrorHUD:_syncHudPresence()
	if not isPlayerInMatch(self._player) then
		if self._vignetteGui and self._vignetteGui.Parent then
			self._vignetteGui.Enabled = false
		end
		self._vignetteGui = nil
		self._vignetteImage = nil
		return
	end

	local gui = self:_ensureVignetteGui()
	if gui then
		gui.Enabled = isActiveMatchPhase(self._player)
	end
	self:_stampRuntimeIdentity()
end

function HorrorHUD:_handleSanity(payload)
	if not isPlayerInMatch(self._player) then
		return
	end
	if not self._vignetteGui or not self._vignetteGui.Parent then
		self:_syncHudPresence()
	end
	local sanity = tonumber((payload and payload.newSanity) or (payload and payload.sanity) or payload) or 100
	self._currentSanity = math.clamp(sanity, 0, 100)
	self._hasSanityReading = true
	self._lastSanityAt = os.clock()
	self:_tweenVignette()
	self:_stampRuntimeIdentity()
end

function HorrorHUD:_tweenVignette()
	if not self._vignetteImage then
		return
	end

	local normalized = math.clamp(self._currentSanity / 100, 0, 1)
	local targetTransparency = math.clamp(0.85 - (1 - normalized) * 0.7, 0.15, 0.85)

	if self._vignetteTween then
		self._vignetteTween:Cancel()
	end

	self._vignetteTween = TweenService:Create(
		self._vignetteImage,
		TweenInfo.new(VIGNETTE_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		self._vignetteImage:IsA("ImageLabel")
			and { ImageTransparency = targetTransparency }
			or { GroupTransparency = targetTransparency }
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
	if not (canvasGroup and canvasGroup:IsA("CanvasGroup")) then
		warnContract("[HorrorHUD] Missing authored LobbyUI.SensoryLobbyCanvasGroup; lobby fade skipped.")
		return
	end

	self._lobbyCanvasGroup = canvasGroup
	self:_stampRuntimeIdentity()
end

function HorrorHUD:_handleMatchEvent(payload)
	local eventName = payload and payload.eventName
	if not eventName then
		return
	end
	self._lastEventName = tostring(eventName)

	if eventName == "MatchStarted" then
		self:_fadeLobby(1)
	elseif eventName == "MatchEnded" then
		self:_fadeLobby(0)
	end
	self:_syncHudPresence()
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
	self:_stampRuntimeIdentity()
end

return setmetatable({}, HorrorHUD)
