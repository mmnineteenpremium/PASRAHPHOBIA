local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local VFXController = {}
VFXController.__index = VFXController

local SANITY_THRESHOLDS = {
	critical = 30,
	stable = 70,
}

local STABLE_POST = {
	Saturation = -0.1,
	Contrast = 0.1,
	Tint = Color3.fromRGB(235, 240, 255),
}

local CRITICAL_POST = {
	Saturation = -0.7,
	Contrast = 0.4,
	Tint = Color3.fromRGB(180, 200, 235),
}

local NEUTRAL_THREAT_POST = {
	Brightness = 0,
	Contrast = 0,
	Saturation = 0,
	Tint = Color3.fromRGB(255, 255, 255),
	BlurSize = 0,
	AtmosphereDensityDelta = 0,
}

local HUNT_THREAT_POST = {
	Brightness = -0.03,
	Contrast = 0.18,
	Saturation = -0.22,
	Tint = Color3.fromRGB(210, 220, 235),
	BlurSize = 7,
	AtmosphereDensityDelta = 0.08,
}

local MANIFEST_SHOCK_POST = {
	Brightness = -0.02,
	Contrast = 0.24,
	Saturation = -0.42,
	Tint = Color3.fromRGB(170, 190, 255),
	BlurSize = 16,
	AtmosphereDensityDelta = 0.03,
	riseTime = 0.12,
	releaseTime = 0.28,
}

local JUMPSCARE_SHOCK_POST = {
	Brightness = -0.08,
	Contrast = 0.52,
	Saturation = -0.95,
	Tint = Color3.fromRGB(208, 224, 255),
	BlurSize = 26,
	AtmosphereDensityDelta = 0.06,
	riseTime = 0.08,
	releaseTime = 0.42,
}

local MAP_ATMOSPHERE_OFFSETS = {
	AbandonedPalace = 0.3,
	HauntedHouse = 0.25,
	StudioMMNineteen = 0.22,
}

local function ensureSanityColorCorrection()
	local effect = Lighting:FindFirstChild("SensorySanityGrading")
	if not effect then
		effect = Instance.new("ColorCorrectionEffect")
		effect.Name = "SensorySanityGrading"
		effect.Brightness = 0
		effect.Contrast = STABLE_POST.Contrast
		effect.Saturation = STABLE_POST.Saturation
		effect.TintColor = STABLE_POST.Tint
		effect.Parent = Lighting
	end
	return effect
end

local function ensureThreatColorCorrection()
	local effect = Lighting:FindFirstChild("SensoryThreatGrading")
	if not effect then
		effect = Instance.new("ColorCorrectionEffect")
		effect.Name = "SensoryThreatGrading"
		effect.Brightness = 0
		effect.Contrast = 0
		effect.Saturation = 0
		effect.TintColor = Color3.fromRGB(255, 255, 255)
		effect.Parent = Lighting
	end
	return effect
end

local function ensureGhostBlur()
	local blur = Lighting:FindFirstChild("SensoryGhostBlur")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "SensoryGhostBlur"
		blur.Size = 0
		blur.Parent = Lighting
	end
	return blur
end

local function ensureAtmosphere()
	local atmosphere = Lighting:FindFirstChild("HorrorAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "HorrorAtmosphere"
		atmosphere.Density = 0.4
		atmosphere.Offset = 0.25
		atmosphere.Color = Color3.fromRGB(150, 160, 180)
		atmosphere.Decay = Color3.fromRGB(100, 110, 130)
		atmosphere.Parent = Lighting
	end
	return atmosphere
end

function VFXController:Init(context)
	self._context = context or {}
	self._remotes = self._context.Remotes or {}
	self._connections = {}
	self._sanityCorrection = ensureSanityColorCorrection()
	self._threatCorrection = ensureThreatColorCorrection()
	self._ghostBlur = ensureGhostBlur()
	self._atmosphere = ensureAtmosphere()
	self._baseAtmosphereDensity = self._atmosphere and self._atmosphere.Density or 0.4
	self._baseAtmosphereOffset = self._atmosphere and self._atmosphere.Offset or 0.25
	self._currentSanity = 100
	self._huntActive = false
	self._sanityTween = nil
	self._threatTweens = nil
	self._transientTweens = nil
	self._transientEffectToken = 0
end

function VFXController:Start()
	local sanityEvent = self._remotes.SanityEvent
	if sanityEvent and sanityEvent.OnClientEvent then
		table.insert(self._connections, sanityEvent.OnClientEvent:Connect(function(payload)
			self:_handleSanityUpdate(payload)
		end))
	end

	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_handleMatchEvent(payload)
		end))
	end
end

function VFXController:Stop()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
	self._connections = {}
	self:_cancelTweenSet(self._transientTweens)
	self:_cancelTweenSet(self._threatTweens)
end

function VFXController:_handleSanityUpdate(payload)
	local sanity = tonumber((payload and payload.newSanity) or (payload and payload.sanity) or payload) or 100
	self._currentSanity = math.clamp(sanity, 0, 100)
	self:_tweenSanityPostProcessing()
end

function VFXController:_handleMatchEvent(payload)
	local eventName = payload and payload.eventName
	if not eventName then
		return
	end

	if eventName == "GhostManifest" then
		self:_triggerGhostManifestFlicker()
	elseif eventName == "GhostManifestEnd" then
		self:_applyThreatBaseline(0.2)
	elseif eventName == "HuntStarted" or eventName == "GhostHuntStarted" then
		self._huntActive = true
		self:_applyThreatBaseline(0.22)
	elseif eventName == "HuntEnded" or eventName == "GhostHuntEnded" then
		self._huntActive = false
		self:_applyThreatBaseline(0.35)
	elseif eventName == "JumpscareTriggered" then
		self:_triggerJumpscareShock(payload)
	elseif eventName == "MatchStarted" then
		local mapName = (payload and payload.mapName) or (payload and payload.mapType) or "Unknown"
		self:_applyMapAtmosphere(mapName)
		self._huntActive = false
		self:_applyThreatBaseline(0)
	elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
		self._huntActive = false
		self:_applyThreatBaseline(0.35)
	end
end

function VFXController:_tweenSanityPostProcessing()
	local clamped = self._currentSanity
	local normalized = math.clamp((clamped - SANITY_THRESHOLDS.critical) / (SANITY_THRESHOLDS.stable - SANITY_THRESHOLDS.critical), 0, 1)

	local targetSaturation = CRITICAL_POST.Saturation + (STABLE_POST.Saturation - CRITICAL_POST.Saturation) * normalized
	local targetContrast = CRITICAL_POST.Contrast + (STABLE_POST.Contrast - CRITICAL_POST.Contrast) * normalized
	local targetTint = CRITICAL_POST.Tint:Lerp(STABLE_POST.Tint, normalized)

	if self._sanityTween then
		self._sanityTween:Cancel()
	end

	self._sanityTween = TweenService:Create(
		self._sanityCorrection,
		TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			Saturation = targetSaturation,
			Contrast = targetContrast,
			TintColor = targetTint,
		}
	)
	self._sanityTween:Play()
end

function VFXController:_cancelTweenSet(tweens)
	if not tweens then
		return
	end
	for _, tween in pairs(tweens) do
		if type(tween.Cancel) == "function" then
			tween:Cancel()
		end
	end
end

function VFXController:_cancelTransientShock()
	self._transientEffectToken += 1
	self:_cancelTweenSet(self._transientTweens)
	self._transientTweens = nil
end

function VFXController:_currentThreatProfile()
	if self._huntActive then
		return HUNT_THREAT_POST
	end
	return NEUTRAL_THREAT_POST
end

function VFXController:_applyThreatBaseline(duration)
	self:_cancelTransientShock()
	self:_cancelTweenSet(self._threatTweens)

	local profile = self:_currentThreatProfile()
	local tweenDuration = duration or 0.25
	if tweenDuration <= 0 then
		self._ghostBlur.Size = profile.BlurSize
		self._threatCorrection.Brightness = profile.Brightness
		self._threatCorrection.Contrast = profile.Contrast
		self._threatCorrection.Saturation = profile.Saturation
		self._threatCorrection.TintColor = profile.Tint
		if self._atmosphere then
			self._atmosphere.Density = self._baseAtmosphereDensity + (profile.AtmosphereDensityDelta or 0)
			self._atmosphere.Offset = self._baseAtmosphereOffset
		end
		return
	end

	local blurTween = TweenService:Create(
		self._ghostBlur,
		TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Size = profile.BlurSize }
	)
	local threatTween = TweenService:Create(
		self._threatCorrection,
		TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			Brightness = profile.Brightness,
			Contrast = profile.Contrast,
			Saturation = profile.Saturation,
			TintColor = profile.Tint,
		}
	)

	self._threatTweens = {
		blur = blurTween,
		threat = threatTween,
	}

	if self._atmosphere then
		self._threatTweens.atmosphere = TweenService:Create(
			self._atmosphere,
			TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				Density = self._baseAtmosphereDensity + (profile.AtmosphereDensityDelta or 0),
				Offset = self._baseAtmosphereOffset,
			}
		)
	end

	for _, tween in pairs(self._threatTweens) do
		tween:Play()
	end
end

function VFXController:_playTransientShock(profile)
	self:_cancelTransientShock()

	local token = self._transientEffectToken
	local riseTime = profile.riseTime or 0.1
	local releaseTime = profile.releaseTime or 0.3
	local activeThreat = self:_currentThreatProfile()
	local atmosphereDensity = self._baseAtmosphereDensity
		+ (activeThreat.AtmosphereDensityDelta or 0)
		+ (profile.AtmosphereDensityDelta or 0)

	local blurTween = TweenService:Create(
		self._ghostBlur,
		TweenInfo.new(riseTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = profile.BlurSize or 0 }
	)
	local threatTween = TweenService:Create(
		self._threatCorrection,
		TweenInfo.new(riseTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Brightness = profile.Brightness or 0,
			Contrast = profile.Contrast or 0,
			Saturation = profile.Saturation or 0,
			TintColor = profile.Tint or Color3.fromRGB(255, 255, 255),
		}
	)

	self._transientTweens = {
		blur = blurTween,
		threat = threatTween,
	}
	if self._atmosphere then
		self._transientTweens.atmosphere = TweenService:Create(
			self._atmosphere,
			TweenInfo.new(riseTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Density = atmosphereDensity }
		)
	end

	threatTween.Completed:Connect(function()
		if token ~= self._transientEffectToken then
			return
		end
		self:_applyThreatBaseline(releaseTime)
	end)

	for _, tween in pairs(self._transientTweens) do
		tween:Play()
	end
end

function VFXController:_triggerGhostManifestFlicker()
	self:_playTransientShock(MANIFEST_SHOCK_POST)
end

function VFXController:_triggerJumpscareShock(payload)
	local profile = {}
	for key, value in pairs(JUMPSCARE_SHOCK_POST) do
		profile[key] = value
	end
	local intensity = math.clamp(tonumber(payload and payload.intensity) or 1, 0.4, 1.5)
	profile.BlurSize = math.floor((profile.BlurSize or 0) * intensity + 0.5)
	profile.Contrast = (profile.Contrast or 0) * intensity
	profile.Brightness = (profile.Brightness or 0) * math.clamp(intensity, 0.75, 1.2)
	profile.AtmosphereDensityDelta = (profile.AtmosphereDensityDelta or 0) * math.clamp(intensity, 0.8, 1.25)
	self:_playTransientShock(profile)
end

function VFXController:_applyMapAtmosphere(mapName)
	local offset = MAP_ATMOSPHERE_OFFSETS[mapName] or 0.25
	if self._atmosphere then
		self._baseAtmosphereOffset = offset
		self._atmosphere.Offset = offset
	end
end

return setmetatable({}, VFXController)
