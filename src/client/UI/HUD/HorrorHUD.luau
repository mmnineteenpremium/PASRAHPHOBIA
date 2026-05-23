local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local HorrorHUD = {}
HorrorHUD.__index = HorrorHUD

local VIGNETTE_STATE = {
	SAFE = "safe",
	LOW_SANITY = "low_sanity",
	HUNT = "hunt",
	COLD = "cold",
	DEAD_SPECTATOR = "dead_spectator",
}

local VIGNETTE_IMAGES = {
	[VIGNETTE_STATE.SAFE] = "rbxassetid://78541993518366",
	[VIGNETTE_STATE.LOW_SANITY] = "rbxassetid://101737615178874",
	[VIGNETTE_STATE.HUNT] = "rbxassetid://98582390134871",
	[VIGNETTE_STATE.COLD] = "rbxassetid://122263449302954",
	[VIGNETTE_STATE.DEAD_SPECTATOR] = "rbxassetid://106439084261344",
}

local STATE_VISUALS = {
	[VIGNETTE_STATE.SAFE] = {
		color = Color3.fromRGB(255, 255, 255),
		transparency = 0.7,
		transitionTime = 0.35,
	},
	[VIGNETTE_STATE.LOW_SANITY] = {
		color = Color3.fromRGB(255, 255, 255),
		transparency = 0.28,
		transitionTime = 0.24,
		pulseAmplitude = 0.08,
		pulseTime = 1.05,
	},
	[VIGNETTE_STATE.HUNT] = {
		color = Color3.fromRGB(255, 255, 255),
		transparency = 0.16,
		transitionTime = 0.18,
		pulseAmplitude = 0.09,
		pulseTime = 0.35,
	},
	[VIGNETTE_STATE.COLD] = {
		color = Color3.fromRGB(184, 220, 255),
		transparency = 0.3,
		transitionTime = 0.22,
		pulseAmplitude = 0.07,
		pulseTime = 1.2,
	},
	[VIGNETTE_STATE.DEAD_SPECTATOR] = {
		color = Color3.fromRGB(235, 235, 235),
		transparency = 0.12,
		transitionTime = 0.15,
		pulseAmplitude = 0.11,
		pulseTime = 0.24,
	},
}

local STATE_SFX = {
	[VIGNETTE_STATE.HUNT] = { soundId = "rbxassetid://121809340847034", volume = 0.3, playbackSpeed = 1.02, cooldown = 2.0 },
	[VIGNETTE_STATE.LOW_SANITY] = { soundId = "rbxassetid://82295031870325", volume = 0.2, playbackSpeed = 1.0, cooldown = 2.4 },
	[VIGNETTE_STATE.SAFE] = { soundId = "rbxassetid://126381630185088", volume = 0.14, playbackSpeed = 0.95, cooldown = 3.0 },
	[VIGNETTE_STATE.COLD] = { soundId = "rbxassetid://87937719989711", volume = 0.16, playbackSpeed = 0.96, cooldown = 2.0 },
	[VIGNETTE_STATE.DEAD_SPECTATOR] = { soundId = "rbxassetid://78211780453394", volume = 0.22, playbackSpeed = 0.88, cooldown = 2.6 },
}

local ACTIVE_MATCH_PHASES = {
	PreparationPhase = true,
	InvestigationPhase = true,
	HuntPhase = true,
	InGame = true,
	Escalation = true,
	Hunt = true,
}

local COLD_WINDOW_SECONDS = 5.75
local COLD_SIGNATURES = { "temperature", "temp", "suhu", "freeze", "frost", "cold", "thermo" }

local warnedContracts = {}

local function warnContract(message)
	if warnedContracts[message] then
		return
	end
	warnedContracts[message] = true
	warn(message)
end

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

local function normalizeToken(value)
	if type(value) ~= "string" then
		return ""
	end
	return string.lower(value)
end

local function isHuntToken(value)
	local token = normalizeToken(value)
	return token ~= "" and string.find(token, "hunt", 1, true) ~= nil
end

local function hasColdSignature(value)
	local token = normalizeToken(value)
	if token == "" then
		return false
	end
	for _, signature in ipairs(COLD_SIGNATURES) do
		if string.find(token, signature, 1, true) then
			return true
		end
	end
	return false
end

local function isTemperatureDropPayload(payload)
	if type(payload) ~= "table" then
		return false
	end
	local tempValue = tonumber(payload.temperatureC)
	if tempValue and tempValue <= -5 then
		return true
	end
	return hasColdSignature(payload.eventType)
		or hasColdSignature(payload.cue)
		or hasColdSignature(payload.reason)
end

local function bindVignetteGui(playerGui)
	local gui = playerGui and playerGui:FindFirstChild("SensoryHorrorHUD")
	if not (gui and gui:IsA("ScreenGui")) then
		warnContract("[HorrorHUD] Missing authored SensoryHorrorHUD ScreenGui; check StarterGui shell contract.")
		return nil, nil, nil
	end

	local vignette = gui:FindFirstChild("Vignette")
	if not (vignette and vignette:IsA("ImageLabel")) then
		warnContract("[HorrorHUD] Authored SensoryHorrorHUD contract mismatch: Vignette ImageLabel required.")
		return nil, nil, nil
	end

	vignette.BackgroundTransparency = 1
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.Position = UDim2.fromScale(0, 0)
	vignette.ImageColor3 = Color3.fromRGB(255, 255, 255)
	vignette.ImageTransparency = 1
	vignette.ZIndex = math.max(vignette.ZIndex, 120)
	vignette.Image = VIGNETTE_IMAGES[VIGNETTE_STATE.SAFE]

	local coldInfo = gui:FindFirstChild("ColdInfo")
	if coldInfo and coldInfo:IsA("GuiObject") then
		coldInfo.Visible = false
	end

	gui.Enabled = false
	return gui, vignette, coldInfo
end

local function stampHorrorHUDInstance(instance, channel, phase, sanity, inMatch, lastEvent, sanitySource, sanityFresh, state, huntActive, spectatorActive, coldActive)
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
	instance:SetAttribute("PasrahHUDVignetteState", tostring(state or VIGNETTE_STATE.SAFE))
	instance:SetAttribute("PasrahHUDHuntActive", huntActive == true)
	instance:SetAttribute("PasrahHUDSpectatorActive", spectatorActive == true)
	instance:SetAttribute("PasrahHUDColdActive", coldActive == true)
end

function HorrorHUD:Init(context)
	self._context = context or {}
	self._remotes = self._context.Remotes or {}
	self._player = Players.LocalPlayer
	self._connections = {}
	self._vignetteTween = nil
	self._pulseTween = nil
	self._pulseToken = 0
	self._lobbyFadeTween = nil
	self._currentSanity = 100
	self._lastEventName = nil
	self._hasSanityReading = false
	self._lastSanityAt = nil
	self._activeState = nil
	self._huntActive = false
	self._huntAttrActive = false
	self._huntEventActive = false
	self._isSpectatorActive = false
	self._spectatorAttrActive = false
	self._spectatorEventActive = false
	self._coldUntil = nil
	self._coldToken = 0
	self._stateCueSound = nil
	self._lastSfxState = nil
	self._lastSfxAt = 0
end

function HorrorHUD:Start()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	self._playerGui = playerGui
	self:_syncHuntFlagsFromAttributes()
	self:_syncSpectatorFromAttributes()
	self:_ensureLobbyCanvasGroup()
	self:_syncHudPresence()

	table.insert(self._connections, self._playerGui.ChildAdded:Connect(function(child)
		if child.Name == "LobbyUI" then
			self:_ensureLobbyCanvasGroup()
		elseif child.Name == "SensoryHorrorHUD" then
			self:_syncHudPresence()
		end
	end))

	table.insert(self._connections, self._player:GetAttributeChangedSignal("InMatch"):Connect(function()
		self:_syncHudPresence()
	end))
	table.insert(self._connections, self._player:GetAttributeChangedSignal("MatchId"):Connect(function()
		self:_syncHudPresence()
	end))
	table.insert(self._connections, self._player:GetAttributeChangedSignal("MatchPhase"):Connect(function()
		self:_syncHuntFlagsFromAttributes()
		self:_syncHudPresence()
	end))
	table.insert(self._connections, self._player:GetAttributeChangedSignal("MatchLifecyclePhase"):Connect(function()
		self:_syncHuntFlagsFromAttributes()
		self:_syncHudPresence()
	end))
	table.insert(self._connections, self._player:GetAttributeChangedSignal("PasrahSpectatorClientActive"):Connect(function()
		self:_syncSpectatorFromAttributes()
		self:_updateVignetteVisual(false)
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

	task.defer(function()
		self:_preloadVignetteAssets()
	end)
end

function HorrorHUD:Stop()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
	self._connections = {}

	if self._vignetteTween then
		self._vignetteTween:Cancel()
		self._vignetteTween = nil
	end
	if self._pulseTween then
		self._pulseTween:Cancel()
		self._pulseTween = nil
	end
	if self._lobbyFadeTween then
		self._lobbyFadeTween:Cancel()
		self._lobbyFadeTween = nil
	end
	if self._stateCueSound and self._stateCueSound.IsPlaying then
		self._stateCueSound:Stop()
	end
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
	self._vignetteGui, self._vignetteImage, self._coldInfo = bindVignetteGui(playerGui)
	self:_ensureStateCueSound()
	self:_stampRuntimeIdentity()
	return self._vignetteGui
end

function HorrorHUD:_ensureStateCueSound()
	if self._stateCueSound and self._stateCueSound.Parent then
		return self._stateCueSound
	end
	local sound = Instance.new("Sound")
	sound.Name = "PasrahHUDStateCue"
	sound.Volume = 0.2
	sound.PlaybackSpeed = 1
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Parent = SoundService
	self._stateCueSound = sound
	return sound
end

function HorrorHUD:_preloadVignetteAssets()
	local preloadList = {}
	local seen = {}
	for _, imageId in pairs(VIGNETTE_IMAGES) do
		if type(imageId) == "string" and imageId ~= "" and not seen[imageId] then
			seen[imageId] = true
			table.insert(preloadList, imageId)
		end
	end
	for _, profile in pairs(STATE_SFX) do
		local soundId = profile and profile.soundId or nil
		if type(soundId) == "string" and soundId ~= "" and not seen[soundId] then
			seen[soundId] = true
			table.insert(preloadList, soundId)
		end
	end
	if #preloadList == 0 then
		return
	end
	pcall(function()
		ContentProvider:PreloadAsync(preloadList)
	end)
end

function HorrorHUD:_syncSpectatorFromAttributes()
	if not self._player then
		return
	end
	local attrValue = self._player:GetAttribute("PasrahSpectatorClientActive")
	self._spectatorAttrActive = attrValue == true
	self:_recomputeSpectatorState()
end

function HorrorHUD:_syncHuntFlagsFromAttributes()
	if not self._player then
		return
	end
	local lifecyclePhase = self._player:GetAttribute("MatchLifecyclePhase")
	local matchPhase = self._player:GetAttribute("MatchPhase")
	self._huntAttrActive = isHuntToken(lifecyclePhase) or isHuntToken(matchPhase)
	self:_recomputeHuntState()
end

function HorrorHUD:_recomputeHuntState()
	self._huntActive = self._huntEventActive == true or self._huntAttrActive == true
end

function HorrorHUD:_recomputeSpectatorState()
	self._isSpectatorActive = self._spectatorEventActive == true or self._spectatorAttrActive == true
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
	local state = self._activeState or VIGNETTE_STATE.SAFE
	local coldActive = type(self._coldUntil) == "number" and os.clock() < self._coldUntil

	stampHorrorHUDInstance(
		self._vignetteGui,
		"SensoryHorrorHUD",
		phase,
		sanity,
		inMatch,
		self._lastEventName,
		sanitySource,
		sanityFresh,
		state,
		self._huntActive,
		self._isSpectatorActive,
		coldActive
	)
	stampHorrorHUDInstance(
		self._vignetteImage,
		"Vignette",
		phase,
		sanity,
		inMatch,
		self._lastEventName,
		sanitySource,
		sanityFresh,
		state,
		self._huntActive,
		self._isSpectatorActive,
		coldActive
	)
	stampHorrorHUDInstance(
		self._coldInfo,
		"ColdInfo",
		phase,
		sanity,
		inMatch,
		self._lastEventName,
		sanitySource,
		sanityFresh,
		state,
		self._huntActive,
		self._isSpectatorActive,
		coldActive
	)
	stampHorrorHUDInstance(
		self._lobbyCanvasGroup,
		"LobbyCanvas",
		phase,
		sanity,
		inMatch,
		self._lastEventName,
		sanitySource,
		sanityFresh,
		state,
		self._huntActive,
		self._isSpectatorActive,
		coldActive
	)
end

function HorrorHUD:_syncHudPresence()
	if not isPlayerInMatch(self._player) then
		if self._vignetteGui and self._vignetteGui.Parent then
			self._vignetteGui.Enabled = false
		end
		self._vignetteGui = nil
		self._vignetteImage = nil
		self._coldInfo = nil
		self._activeState = nil
		self._huntActive = false
		self._huntAttrActive = false
		self._huntEventActive = false
		self._isSpectatorActive = false
		self._spectatorAttrActive = false
		self._spectatorEventActive = false
		self._coldUntil = nil
		self._lastSfxState = nil
		if self._stateCueSound and self._stateCueSound.IsPlaying then
			self._stateCueSound:Stop()
		end
		return
	end

	local gui = self:_ensureVignetteGui()
	if gui then
		gui.Enabled = isActiveMatchPhase(self._player)
	end

	if gui and gui.Enabled then
		self:_syncHuntFlagsFromAttributes()
		self:_syncSpectatorFromAttributes()
		self:_updateVignetteVisual(false)
	else
		self:_stampRuntimeIdentity()
	end
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
	self:_updateVignetteVisual(false)
end

function HorrorHUD:_armColdWindow(durationSeconds)
	local duration = tonumber(durationSeconds) or COLD_WINDOW_SECONDS
	local now = os.clock()
	local nextEnd = now + math.max(duration, 1)
	self._coldUntil = math.max(self._coldUntil or 0, nextEnd)

	self._coldToken += 1
	local token = self._coldToken
	task.delay(duration + 0.1, function()
		if token ~= self._coldToken then
			return
		end
		if type(self._coldUntil) == "number" and os.clock() >= self._coldUntil then
			self._coldUntil = nil
			self:_updateVignetteVisual(false)
		end
	end)
end

function HorrorHUD:_resolveVignetteState()
	if self._isSpectatorActive == true then
		return VIGNETTE_STATE.DEAD_SPECTATOR
	end
	if self._huntActive == true then
		return VIGNETTE_STATE.HUNT
	end
	if type(self._coldUntil) == "number" and os.clock() < self._coldUntil then
		return VIGNETTE_STATE.COLD
	end
	if self._currentSanity <= 30 then
		return VIGNETTE_STATE.LOW_SANITY
	end
	return VIGNETTE_STATE.SAFE
end

function HorrorHUD:_applyStateVisual(state)
	if not self._vignetteImage then
		return
	end

	local style = STATE_VISUALS[state] or STATE_VISUALS[VIGNETTE_STATE.SAFE]
	local imageId = VIGNETTE_IMAGES[state] or VIGNETTE_IMAGES[VIGNETTE_STATE.SAFE]
	if self._vignetteImage.Image ~= imageId then
		self._vignetteImage.Image = imageId
	end
	self._vignetteImage.ImageColor3 = style.color

	if self._coldInfo and self._coldInfo:IsA("GuiObject") then
		self._coldInfo.Visible = state == VIGNETTE_STATE.COLD
	end

	if self._vignetteTween then
		self._vignetteTween:Cancel()
		self._vignetteTween = nil
	end
	if self._pulseTween then
		self._pulseTween:Cancel()
		self._pulseTween = nil
	end
	self._pulseToken += 1

	local baseTransparency = math.clamp(style.transparency, 0.02, 0.98)
	self._vignetteTween = TweenService:Create(
		self._vignetteImage,
		TweenInfo.new(style.transitionTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ ImageTransparency = baseTransparency }
	)
	self._vignetteTween:Play()

	if style.pulseAmplitude and style.pulseTime then
		local currentToken = self._pulseToken
		task.delay(style.transitionTime + 0.02, function()
			if currentToken ~= self._pulseToken then
				return
			end
			if not self._vignetteImage or not self._vignetteImage.Parent then
				return
			end
			if self._activeState ~= state then
				return
			end
			local pulseTarget = math.clamp(baseTransparency + style.pulseAmplitude, 0.02, 0.98)
			self._pulseTween = TweenService:Create(
				self._vignetteImage,
				TweenInfo.new(style.pulseTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ ImageTransparency = pulseTarget }
			)
			self._pulseTween:Play()
		end)
	end
end

function HorrorHUD:_playStateSfx(state, force)
	local profile = STATE_SFX[state]
	if not profile then
		return
	end

	local now = os.clock()
	local cooldown = tonumber(profile.cooldown) or 1.5
	if force ~= true then
		if self._lastSfxState == state then
			return
		end
		if now - (self._lastSfxAt or 0) < cooldown then
			return
		end
	end

	local cueSound = self:_ensureStateCueSound()
	if not cueSound then
		return
	end

	if cueSound.IsPlaying then
		cueSound:Stop()
	end
	cueSound.SoundId = profile.soundId
	cueSound.Volume = tonumber(profile.volume) or 0.2
	cueSound.PlaybackSpeed = tonumber(profile.playbackSpeed) or 1
	cueSound.TimePosition = 0
	cueSound:Play()

	self._lastSfxState = state
	self._lastSfxAt = now
end

function HorrorHUD:_updateVignetteVisual(forceSfx)
	if not self._vignetteImage or not self._vignetteImage.Parent then
		return
	end

	local targetState = self:_resolveVignetteState()
	local changed = targetState ~= self._activeState
	self._activeState = targetState

	if changed or forceSfx == true then
		self:_applyStateVisual(targetState)
		self:_playStateSfx(targetState, forceSfx == true)
	end

	self:_stampRuntimeIdentity()
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
		self._huntEventActive = false
		self._spectatorEventActive = false
		self._coldUntil = nil
		self:_recomputeHuntState()
		self:_recomputeSpectatorState()
		self:_fadeLobby(1)
	elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
		self._huntEventActive = false
		self._spectatorEventActive = false
		self._coldUntil = nil
		self:_recomputeHuntState()
		self:_recomputeSpectatorState()
		self:_fadeLobby(0)
	elseif eventName == "ReturnedToLobby" then
		self._huntEventActive = false
		self._spectatorEventActive = false
		self._coldUntil = nil
		self:_recomputeHuntState()
		self:_recomputeSpectatorState()
	elseif eventName == "HuntStarted" or eventName == "GhostHuntStarted" then
		self._huntEventActive = true
		self:_recomputeHuntState()
	elseif eventName == "HuntEnded" or eventName == "GhostHuntEnded" then
		self._huntEventActive = false
		self:_recomputeHuntState()
	elseif eventName == "PhaseChanged" then
		local phaseName = tostring((payload and payload.phase) or (payload and payload.phaseName) or (payload and payload.matchPhase) or "")
		if phaseName ~= "" then
			self._huntAttrActive = isHuntToken(phaseName)
			self:_recomputeHuntState()
		else
			self:_syncHuntFlagsFromAttributes()
		end
	elseif eventName == "PlayerKilled" and payload and payload.localPlayerKilled == true then
		self._spectatorEventActive = true
		self:_recomputeSpectatorState()
	elseif eventName == "PlayerRespawned" and payload and payload.localPlayerRespawned == true then
		self._spectatorEventActive = false
		self:_recomputeSpectatorState()
	end

	if eventName == "EnvironmentalAudioTriggered" and isTemperatureDropPayload(payload) then
		self:_armColdWindow(payload and (payload.windowSeconds or payload.duration or payload.lingerSeconds))
	elseif eventName == "EvidenceToolResult" and isTemperatureDropPayload(payload) then
		self:_armColdWindow(payload and (payload.windowSeconds or payload.duration or 6))
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
