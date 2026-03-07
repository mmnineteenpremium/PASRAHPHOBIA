local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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

local function findOverlayFrames(player)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil, nil
	end

	local spectatorUi = playerGui:FindFirstChild("SpectatorUI")
	if not spectatorUi then
		return nil, nil
	end

	local staticOverlay = spectatorUi:FindFirstChild("StaticFlickerOverlay")
	local desaturationOverlay = spectatorUi:FindFirstChild("ColorDesaturationOverlay")
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
end

function SpectatorEffects:Start()
	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end

	table.insert(self._connections, RunService.Heartbeat:Connect(function()
		self:_onHeartbeat()
	end))
end

function SpectatorEffects:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	if eventName == "PlayerKilled" and payload.localPlayerKilled == true then
		self:EnterSpectatorMode()
		return
	end

	if eventName == "PlayerRespawned" or eventName == "MatchEnded" then
		self:ExitSpectatorMode()
		return
	end

	if self._isSpectating and DISTORTION_EVENT_NAMES[eventName] then
		self:_triggerDistortion(eventName)
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
	self._nextPulseAt = os.clock() + self._rng:NextNumber(2, 5)
	self:_setOverlayState(false, false)
	self:_setPostEffects(2, -0.15, 0.05)
end

function SpectatorEffects:ExitSpectatorMode()
	self._isSpectating = false
	self._lastOutcome = "none"
	self:_setOverlayState(false, false)
	self:_setPostEffects(0, 0, 0)
	self._blur.Enabled = false
	self._color.Enabled = false
end

function SpectatorEffects:_setPostEffects(blurSize, saturation, contrast)
	self._blur.Enabled = blurSize > 0
	self._blur.Size = blurSize

	self._color.Enabled = saturation ~= 0 or contrast ~= 0
	self._color.Saturation = saturation
	self._color.Contrast = contrast
end

function SpectatorEffects:_setOverlayState(staticVisible, desaturatedVisible)
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local staticOverlay, desaturationOverlay = findOverlayFrames(player)
	if staticOverlay then
		staticOverlay.Visible = staticVisible
	end
	if desaturationOverlay then
		desaturationOverlay.Visible = desaturatedVisible
	end
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
			{ Size = 2 }
		)
		tween:Play()
		self:_setPostEffects(2, -0.15, 0.05)
	end)
end

function SpectatorEffects:GetState()
	return {
		isSpectating = self._isSpectating,
		lastOutcome = self._lastOutcome,
		probabilities = DISTORTION_PROBABILITIES,
	}
end

return setmetatable({}, SpectatorEffects)
