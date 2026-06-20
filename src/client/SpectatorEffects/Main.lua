local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SpectatorEffects = {}
SpectatorEffects.__index = SpectatorEffects

local DISTORTION_PROBABILITIES = {
	fake = 0.60,
	uncertain = 0.30,
	real = 0.10,
}

local DISTORTION_EVENT_NAMES = {
	GhostManifest = true,
	GhostManifested = true,
	GhostSpawned = true,
	SpectatorDistortionGenerated = true,
	GhostDistortionPulse = true,
}

local UI_GRAPHICS_MODE_ATTR = "PasrahGraphicsMode"

local GRAPHICS_POST_PROFILES = {
	Performance = {
		blurScale = 0.45,
		colorScale = 0.72,
	},
	Balanced = {
		blurScale = 0.74,
		colorScale = 0.88,
	},
	Quality = {
		blurScale = 1,
		colorScale = 1,
	},
}

local function normalizeGraphicsMode(mode)
	local normalized = tostring(mode or ""):lower()
	if normalized == "performance" then
		return "Performance"
	end
	if normalized == "quality" then
		return "Quality"
	end
	return "Balanced"
end

local function resolveDefaultGraphicsMode()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.GamepadEnabled then
		return "Balanced"
	end
	return "Quality"
end

local warnedOverlayContracts = {}

local function warnMissingOverlayContract(name)
	local key = tostring(name or "?")
	if warnedOverlayContracts[key] then
		return
	end
	warnedOverlayContracts[key] = true
	warn("[SpectatorEffects] Authored SpectatorUI overlay contract mismatch: " .. key)
end

local function bindOverlayFrame(parent, name)
	local overlay = parent and parent:FindFirstChild(name)
	if overlay and overlay:IsA("Frame") then
		return overlay
	end
	warnMissingOverlayContract(name)
	return nil
end

local function findOverlayFrames(player)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil, nil
	end

	local fallbackUi = nil
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") and child.Name == "SpectatorUI" then
			local staticOverlay = child:FindFirstChild("StaticFlickerOverlay")
			local desaturationOverlay = child:FindFirstChild("ColorDesaturationOverlay")
			if staticOverlay or desaturationOverlay then
				return staticOverlay, desaturationOverlay
			end
			if fallbackUi == nil then
				fallbackUi = child
			end
		end
	end

	if not fallbackUi then
		return nil, nil
	end

	local spectatorUi = fallbackUi
	local staticOverlay = bindOverlayFrame(spectatorUi, "StaticFlickerOverlay")
	local desaturationOverlay = bindOverlayFrame(spectatorUi, "ColorDesaturationOverlay")
	return staticOverlay, desaturationOverlay
end

function SpectatorEffects:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._rng = Random.new()
	self._isSpectating = false
	self._nextPulseAt = 0
	self._lastOutcome = "none"
	self._lastReason = "Idle"
	self._staticOverlay = nil
	self._desaturationOverlay = nil
	self._graphicsMode = resolveDefaultGraphicsMode()
	self._graphicsProfile = GRAPHICS_POST_PROFILES[self._graphicsMode] or GRAPHICS_POST_PROFILES.Balanced

	self._blur = Lighting:FindFirstChild("SpectatorBlurEffect")
	if not self._blur then
		self._blur = Instance.new("BlurEffect")
		self._blur.Name = "SpectatorBlurEffect"
		self._blur.Size = 0
		self._blur.Enabled = false
		self._blur.Parent = Lighting
	end

	self._color = Lighting:FindFirstChild("SpectatorColorCorrection")
	if not self._color then
		self._color = Instance.new("ColorCorrectionEffect")
		self._color.Name = "SpectatorColorCorrection"
		self._color.Saturation = 0
		self._color.Contrast = 0
		self._color.TintColor = Color3.fromRGB(255, 255, 255)
		self._color.Enabled = false
		self._color.Parent = Lighting
	end

	self:_stampRuntimeState()
end

function SpectatorEffects:Start()
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		table.insert(self._connections, localPlayer:GetAttributeChangedSignal(UI_GRAPHICS_MODE_ATTR):Connect(function()
			self:_refreshGraphicsModeState()
		end))
	end

	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end

	local lobbyEvent = self._remotes.LobbyEvent
	if lobbyEvent and lobbyEvent.OnClientEvent then
		table.insert(self._connections, lobbyEvent.OnClientEvent:Connect(function(payload)
			self:_onLobbyEvent(payload)
		end))
	end

	table.insert(self._connections, RunService.Heartbeat:Connect(function()
		self:_onHeartbeat()
	end))
end

function SpectatorEffects:_syncGraphicsMode()
	local player = Players.LocalPlayer
	local rawMode = player and player:GetAttribute(UI_GRAPHICS_MODE_ATTR) or nil
	local mode = rawMode ~= nil and normalizeGraphicsMode(rawMode) or resolveDefaultGraphicsMode()
	self._graphicsMode = mode
	self._graphicsProfile = GRAPHICS_POST_PROFILES[mode] or GRAPHICS_POST_PROFILES.Balanced
	if player then
		player:SetAttribute("PasrahSpectatorGraphicsMode", mode)
	end
	return self._graphicsProfile
end

function SpectatorEffects:_scaleBlurSize(blurSize)
	local graphicsProfile = self._graphicsProfile or self:_syncGraphicsMode()
	return math.max(0, math.floor((tonumber(blurSize) or 0) * (graphicsProfile.blurScale or 1) + 0.5))
end

function SpectatorEffects:_scaleColorValue(value)
	local graphicsProfile = self._graphicsProfile or self:_syncGraphicsMode()
	return (tonumber(value) or 0) * (graphicsProfile.colorScale or 1)
end

function SpectatorEffects:_refreshGraphicsModeState()
	self:_syncGraphicsMode()
	if not self._isSpectating then
		self:_stampRuntimeState()
		return
	end
	if self._lastOutcome == "fake" then
		self:_setPostEffects(10, -0.35, 0.2)
	elseif self._lastOutcome == "uncertain" then
		self:_setPostEffects(6, -0.55, 0.12)
	elseif self._lastOutcome == "real" then
		self:_setPostEffects(3, -0.2, 0.08)
	else
		self:_setPostEffects(2, -0.15, 0.05)
	end
end

function SpectatorEffects:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	if eventName == "MatchStarted" then
		self._lastReason = "MatchStarted"
		self:ExitSpectatorMode()
		return
	end
	if eventName == "PlayerKilled" and payload.localPlayerKilled == true then
		self:EnterSpectatorMode()
		return
	end

	if (eventName == "PlayerRespawned" and payload and payload.localPlayerRespawned == true)
		or eventName == "MatchEnded"
		or eventName == "MatchCompleted"
		or eventName == "ReturnedToLobby" then
		self._lastReason = tostring(eventName or "ExitSpectatorMode")
		self:ExitSpectatorMode()
		return
	end

	if self._isSpectating and DISTORTION_EVENT_NAMES[eventName] then
		self:_triggerDistortion(eventName)
	end
end

function SpectatorEffects:_onLobbyEvent(payload)
	local eventName = payload and payload.eventName
	if eventName == "LobbyEntered" or eventName == "RoomBrowserRoomLeft" then
		self._lastReason = tostring(eventName)
		self:ExitSpectatorMode()
	end
end

function SpectatorEffects:_onHeartbeat()
	if not self._isSpectating then
		return
	end

	local now = os.clock()
	if now < self._nextPulseAt then
		return
	end

	self:_triggerDistortion("AtmospherePulse")
	self._nextPulseAt = now + self._rng:NextNumber(6, 14)
end

function SpectatorEffects:EnterSpectatorMode()
	self._isSpectating = true
	self._lastReason = "EnterSpectatorMode"
	self._nextPulseAt = os.clock() + self._rng:NextNumber(2, 5)
	self:_setOverlayState(false, false)
	self:_setPostEffects(2, -0.15, 0.05)
end

function SpectatorEffects:ExitSpectatorMode()
	self._isSpectating = false
	self._lastOutcome = "none"
	self._lastReason = "ExitSpectatorMode"
	self:_setOverlayState(false, false)
	self:_setPostEffects(0, 0, 0)
	self._blur.Enabled = false
	self._color.Enabled = false
	self:_stampRuntimeState()
end

function SpectatorEffects:_setPostEffects(blurSize, saturation, contrast)
	local scaledBlur = self:_scaleBlurSize(blurSize)
	local scaledSaturation = self:_scaleColorValue(saturation)
	local scaledContrast = self:_scaleColorValue(contrast)
	self._blur.Enabled = scaledBlur > 0
	self._blur.Size = scaledBlur

	self._color.Enabled = scaledSaturation ~= 0 or scaledContrast ~= 0
	self._color.Saturation = scaledSaturation
	self._color.Contrast = scaledContrast
	self:_stampRuntimeState()
end

function SpectatorEffects:_setOverlayState(staticVisible, desaturatedVisible)
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local staticOverlay, desaturationOverlay = findOverlayFrames(player)
	self._staticOverlay = staticOverlay
	self._desaturationOverlay = desaturationOverlay
	if staticOverlay then
		staticOverlay.Visible = staticVisible
	end
	if desaturationOverlay then
		desaturationOverlay.Visible = desaturatedVisible
	end
	self:_stampRuntimeState()
end

function SpectatorEffects:_rollOutcome()
	local roll = self._rng:NextNumber()
	if roll <= DISTORTION_PROBABILITIES.fake then
		return "fake"
	end
	if roll <= DISTORTION_PROBABILITIES.fake + DISTORTION_PROBABILITIES.uncertain then
		return "uncertain"
	end
	return "real"
end

function SpectatorEffects:_triggerDistortion(_reason)
	local outcome = self:_rollOutcome()
	self._lastOutcome = outcome
	self._lastReason = tostring(_reason or "Unknown")

	if outcome == "fake" then
		self:_setOverlayState(true, false)
		self:_setPostEffects(10, -0.35, 0.2)
	elseif outcome == "uncertain" then
		self:_setOverlayState(true, true)
		self:_setPostEffects(6, -0.55, 0.12)
	else
		self:_setOverlayState(false, true)
		self:_setPostEffects(3, -0.2, 0.08)
	end

	task.delay(0.45, function()
		if not self._isSpectating then
			return
		end

		self:_setOverlayState(false, false)
		local tween = TweenService:Create(
			self._blur,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = self:_scaleBlurSize(2) }
		)
		tween:Play()
		self:_setPostEffects(2, -0.15, 0.05)
	end)
end

function SpectatorEffects:_stampEffectInstance(instance, channel)
	if typeof(instance) ~= "Instance" then
		return
	end

	instance:SetAttribute("PasrahSpectatorFXOwner", "SpectatorEffects")
	instance:SetAttribute("PasrahSpectatorFXChannel", tostring(channel or instance.Name))
	instance:SetAttribute("PasrahSpectatorFXActive", self._isSpectating == true)
	instance:SetAttribute("PasrahSpectatorFXLastOutcome", self._lastOutcome ~= "none" and self._lastOutcome or nil)
	instance:SetAttribute("PasrahSpectatorFXLastReason", self._lastReason ~= "Idle" and self._lastReason or nil)

	if instance == self._blur then
		instance:SetAttribute("PasrahSpectatorFXEnabled", self._blur.Enabled == true)
		instance:SetAttribute("PasrahSpectatorFXIntensity", tonumber(self._blur.Size) or 0)
	elseif instance == self._color then
		instance:SetAttribute("PasrahSpectatorFXEnabled", self._color.Enabled == true)
		instance:SetAttribute("PasrahSpectatorFXSaturation", tonumber(self._color.Saturation) or 0)
		instance:SetAttribute("PasrahSpectatorFXContrast", tonumber(self._color.Contrast) or 0)
	elseif instance:IsA("GuiObject") then
		instance:SetAttribute("PasrahSpectatorFXVisible", instance.Visible == true)
	end
end

function SpectatorEffects:_stampRuntimeState()
	local player = Players.LocalPlayer
	if player then
		player:SetAttribute("PasrahSpectatorFXOwner", "SpectatorEffects")
		player:SetAttribute("PasrahSpectatorFXActive", self._isSpectating == true)
		player:SetAttribute("PasrahSpectatorFXOutcome", self._lastOutcome ~= "none" and self._lastOutcome or nil)
		player:SetAttribute("PasrahSpectatorFXReason", self._lastReason ~= "Idle" and self._lastReason or nil)
		player:SetAttribute("PasrahSpectatorFXStaticVisible", self._staticOverlay and self._staticOverlay.Visible == true or false)
		player:SetAttribute("PasrahSpectatorFXDesaturatedVisible", self._desaturationOverlay and self._desaturationOverlay.Visible == true or false)
		player:SetAttribute("PasrahSpectatorFXNextPulseAt", self._isSpectating and self._nextPulseAt or nil)
	end

	self:_stampEffectInstance(self._blur, "Blur")
	self:_stampEffectInstance(self._color, "ColorCorrection")
	self:_stampEffectInstance(self._staticOverlay, "StaticOverlay")
	self:_stampEffectInstance(self._desaturationOverlay, "DesaturationOverlay")
end

function SpectatorEffects:GetState()
	return {
		isSpectating = self._isSpectating,
		lastOutcome = self._lastOutcome,
		probabilities = DISTORTION_PROBABILITIES,
	}
end

return setmetatable({}, SpectatorEffects)
