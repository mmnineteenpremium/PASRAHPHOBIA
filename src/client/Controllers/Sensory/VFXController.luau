local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
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

local DEFAULT_MAP_ATMOSPHERE = {
	Density = 0.38,
	Offset = 0.22,
	Color = Color3.fromRGB(148, 158, 176),
	Decay = Color3.fromRGB(96, 106, 124),
	Glare = 0.16,
	Haze = 1.85,
}

local DEFAULT_MAP_LIGHTING = {
	ClockTime = 14.2,
	Brightness = 2.1,
	ExposureCompensation = -0.08,
	Ambient = Color3.fromRGB(108, 116, 132),
	OutdoorAmbient = Color3.fromRGB(122, 128, 144),
	EnvironmentDiffuseScale = 0.26,
	EnvironmentSpecularScale = 0.18,
}

local DEFAULT_MAP_GRADE = {
	Brightness = 0,
	Contrast = 0.02,
	Saturation = -0.04,
	TintColor = Color3.fromRGB(248, 248, 252),
}

local DEFAULT_MAP_BLOOM = {
	Intensity = 0.14,
	Size = 18,
	Threshold = 1.12,
}

local MAP_ATMOSPHERE_PROFILES = {
	LobbySocialHub = {
		Density = 0.24,
		Offset = 0.1,
		Color = Color3.fromRGB(186, 194, 208),
		Decay = Color3.fromRGB(138, 146, 160),
		Glare = 0.08,
		Haze = 1.2,
	},
	AbandonedPalace = {
		Density = 0.5,
		Offset = 0.34,
		Color = Color3.fromRGB(170, 152, 136),
		Decay = Color3.fromRGB(112, 94, 82),
		Glare = 0.22,
		Haze = 2.35,
	},
	HauntedHouse = {
		Density = 0.44,
		Offset = 0.27,
		Color = Color3.fromRGB(146, 156, 178),
		Decay = Color3.fromRGB(88, 96, 118),
		Glare = 0.14,
		Haze = 2.1,
	},
	EmptyBuilding = {
		Density = 0.32,
		Offset = 0.14,
		Color = Color3.fromRGB(176, 182, 194),
		Decay = Color3.fromRGB(122, 128, 142),
		Glare = 0.09,
		Haze = 1.45,
	},
	StudioMMNineteen = {
		Density = 0.36,
		Offset = 0.2,
		Color = Color3.fromRGB(160, 168, 184),
		Decay = Color3.fromRGB(104, 112, 128),
		Glare = 0.12,
		Haze = 1.7,
	},
}

local MAP_LIGHTING_PROFILES = {
	LobbySocialHub = {
		ClockTime = 14.6,
		Brightness = 2.25,
		ExposureCompensation = 0,
		Ambient = Color3.fromRGB(128, 136, 150),
		OutdoorAmbient = Color3.fromRGB(146, 152, 166),
		EnvironmentDiffuseScale = 0.34,
		EnvironmentSpecularScale = 0.22,
	},
	AbandonedPalace = {
		ClockTime = 19.2,
		Brightness = 1.65,
		ExposureCompensation = -0.34,
		Ambient = Color3.fromRGB(88, 76, 70),
		OutdoorAmbient = Color3.fromRGB(104, 90, 82),
		EnvironmentDiffuseScale = 0.18,
		EnvironmentSpecularScale = 0.08,
	},
	HauntedHouse = {
		ClockTime = 1.35,
		Brightness = 1.72,
		ExposureCompensation = -0.28,
		Ambient = Color3.fromRGB(82, 92, 108),
		OutdoorAmbient = Color3.fromRGB(96, 106, 122),
		EnvironmentDiffuseScale = 0.2,
		EnvironmentSpecularScale = 0.1,
	},
	EmptyBuilding = {
		ClockTime = 16.8,
		Brightness = 1.95,
		ExposureCompensation = -0.16,
		Ambient = Color3.fromRGB(118, 122, 134),
		OutdoorAmbient = Color3.fromRGB(132, 136, 148),
		EnvironmentDiffuseScale = 0.24,
		EnvironmentSpecularScale = 0.14,
	},
	StudioMMNineteen = {
		ClockTime = 18.1,
		Brightness = 1.82,
		ExposureCompensation = -0.22,
		Ambient = Color3.fromRGB(98, 104, 116),
		OutdoorAmbient = Color3.fromRGB(112, 118, 130),
		EnvironmentDiffuseScale = 0.22,
		EnvironmentSpecularScale = 0.12,
	},
}

local MAP_GRADE_PROFILES = {
	LobbySocialHub = {
		Brightness = 0.01,
		Contrast = 0.04,
		Saturation = -0.02,
		TintColor = Color3.fromRGB(248, 246, 240),
	},
	AbandonedPalace = {
		Brightness = -0.02,
		Contrast = 0.08,
		Saturation = -0.12,
		TintColor = Color3.fromRGB(236, 220, 204),
	},
	HauntedHouse = {
		Brightness = -0.01,
		Contrast = 0.1,
		Saturation = -0.16,
		TintColor = Color3.fromRGB(220, 232, 250),
	},
	EmptyBuilding = {
		Brightness = 0,
		Contrast = 0.06,
		Saturation = -0.1,
		TintColor = Color3.fromRGB(238, 240, 246),
	},
	StudioMMNineteen = {
		Brightness = -0.01,
		Contrast = 0.07,
		Saturation = -0.08,
		TintColor = Color3.fromRGB(232, 238, 248),
	},
}

local MAP_BLOOM_PROFILES = {
	LobbySocialHub = {
		Intensity = 0.18,
		Size = 20,
		Threshold = 1.18,
	},
	AbandonedPalace = {
		Intensity = 0.08,
		Size = 14,
		Threshold = 1.42,
	},
	HauntedHouse = {
		Intensity = 0.07,
		Size = 12,
		Threshold = 1.48,
	},
	EmptyBuilding = {
		Intensity = 0.1,
		Size = 16,
		Threshold = 1.34,
	},
	StudioMMNineteen = {
		Intensity = 0.09,
		Size = 15,
		Threshold = 1.38,
	},
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

local function ensureMapColorCorrection()
	local effect = Lighting:FindFirstChild("SensoryMapGrading")
	if not effect then
		effect = Instance.new("ColorCorrectionEffect")
		effect.Name = "SensoryMapGrading"
		effect.Brightness = DEFAULT_MAP_GRADE.Brightness
		effect.Contrast = DEFAULT_MAP_GRADE.Contrast
		effect.Saturation = DEFAULT_MAP_GRADE.Saturation
		effect.TintColor = DEFAULT_MAP_GRADE.TintColor
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

local function ensureMapBloom()
	local bloom = Lighting:FindFirstChild("SensoryMapBloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "SensoryMapBloom"
		bloom.Intensity = DEFAULT_MAP_BLOOM.Intensity
		bloom.Size = DEFAULT_MAP_BLOOM.Size
		bloom.Threshold = DEFAULT_MAP_BLOOM.Threshold
		bloom.Parent = Lighting
	end
	return bloom
end

local function ensureAtmosphere()
	local atmosphere = Lighting:FindFirstChild("HorrorAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "HorrorAtmosphere"
		atmosphere.Density = DEFAULT_MAP_ATMOSPHERE.Density
		atmosphere.Offset = DEFAULT_MAP_ATMOSPHERE.Offset
		atmosphere.Color = DEFAULT_MAP_ATMOSPHERE.Color
		atmosphere.Decay = DEFAULT_MAP_ATMOSPHERE.Decay
		atmosphere.Glare = DEFAULT_MAP_ATMOSPHERE.Glare
		atmosphere.Haze = DEFAULT_MAP_ATMOSPHERE.Haze
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
	self._mapCorrection = ensureMapColorCorrection()
	self._ghostBlur = ensureGhostBlur()
	self._mapBloom = ensureMapBloom()
	self._atmosphere = ensureAtmosphere()
	self._baseAtmosphereDensity = self._atmosphere and self._atmosphere.Density or DEFAULT_MAP_ATMOSPHERE.Density
	self._baseAtmosphereOffset = self._atmosphere and self._atmosphere.Offset or DEFAULT_MAP_ATMOSPHERE.Offset
	self._baseAtmosphereColor = self._atmosphere and self._atmosphere.Color or DEFAULT_MAP_ATMOSPHERE.Color
	self._baseAtmosphereDecay = self._atmosphere and self._atmosphere.Decay or DEFAULT_MAP_ATMOSPHERE.Decay
	self._baseAtmosphereGlare = self._atmosphere and self._atmosphere.Glare or DEFAULT_MAP_ATMOSPHERE.Glare
	self._baseAtmosphereHaze = self._atmosphere and self._atmosphere.Haze or DEFAULT_MAP_ATMOSPHERE.Haze
	self._baseLightingClockTime = Lighting.ClockTime
	self._baseLightingBrightness = Lighting.Brightness
	self._baseLightingExposure = Lighting.ExposureCompensation
	self._baseLightingAmbient = Lighting.Ambient
	self._baseLightingOutdoorAmbient = Lighting.OutdoorAmbient
	self._baseLightingDiffuseScale = Lighting.EnvironmentDiffuseScale
	self._baseLightingSpecularScale = Lighting.EnvironmentSpecularScale
	self._baseMapGradeBrightness = self._mapCorrection and self._mapCorrection.Brightness or DEFAULT_MAP_GRADE.Brightness
	self._baseMapGradeContrast = self._mapCorrection and self._mapCorrection.Contrast or DEFAULT_MAP_GRADE.Contrast
	self._baseMapGradeSaturation = self._mapCorrection and self._mapCorrection.Saturation or DEFAULT_MAP_GRADE.Saturation
	self._baseMapGradeTint = self._mapCorrection and self._mapCorrection.TintColor or DEFAULT_MAP_GRADE.TintColor
	self._baseMapBloomIntensity = self._mapBloom and self._mapBloom.Intensity or DEFAULT_MAP_BLOOM.Intensity
	self._baseMapBloomSize = self._mapBloom and self._mapBloom.Size or DEFAULT_MAP_BLOOM.Size
	self._baseMapBloomThreshold = self._mapBloom and self._mapBloom.Threshold or DEFAULT_MAP_BLOOM.Threshold
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

	local localPlayer = Players.LocalPlayer
	if localPlayer and localPlayer:GetAttribute("InMatch") == true then
		self:_applyMapVisualProfile(tostring(localPlayer:GetAttribute("MapName") or "HauntedHouse"))
	else
		self:_applyMapVisualProfile("LobbySocialHub")
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
		local mapName = (payload and payload.mapName) or (payload and payload.mapType) or (payload and payload.mapId) or "Unknown"
		self:_applyMapVisualProfile(mapName)
		self._huntActive = false
		self:_applyThreatBaseline(0)
	elseif eventName == "PhaseChanged" then
		local phaseName = tostring((payload and payload.phase) or (payload and payload.phaseName) or (payload and payload.matchPhase) or "")
		local mapName = (payload and payload.mapName) or (payload and payload.mapType) or (payload and payload.mapId) or (payload and payload.map) or nil
		if type(mapName) == "string" and mapName ~= "" then
			self:_applyMapVisualProfile(mapName == "Lobby" and "LobbySocialHub" or mapName)
		elseif phaseName == "Lobby" then
			self:_applyMapVisualProfile("LobbySocialHub")
		end
	elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
		self._huntActive = false
		self:_applyMapVisualProfile("LobbySocialHub")
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
	local profile = MAP_ATMOSPHERE_PROFILES[mapName] or DEFAULT_MAP_ATMOSPHERE
	if self._atmosphere then
		self._baseAtmosphereDensity = profile.Density or DEFAULT_MAP_ATMOSPHERE.Density
		self._baseAtmosphereOffset = profile.Offset or DEFAULT_MAP_ATMOSPHERE.Offset
		self._baseAtmosphereColor = profile.Color or DEFAULT_MAP_ATMOSPHERE.Color
		self._baseAtmosphereDecay = profile.Decay or DEFAULT_MAP_ATMOSPHERE.Decay
		self._baseAtmosphereGlare = profile.Glare or DEFAULT_MAP_ATMOSPHERE.Glare
		self._baseAtmosphereHaze = profile.Haze or DEFAULT_MAP_ATMOSPHERE.Haze
		self._atmosphere.Density = self._baseAtmosphereDensity
		self._atmosphere.Offset = self._baseAtmosphereOffset
		self._atmosphere.Color = self._baseAtmosphereColor
		self._atmosphere.Decay = self._baseAtmosphereDecay
		self._atmosphere.Glare = self._baseAtmosphereGlare
		self._atmosphere.Haze = self._baseAtmosphereHaze
	end
end

function VFXController:_applyMapLighting(mapName)
	local profile = MAP_LIGHTING_PROFILES[mapName] or DEFAULT_MAP_LIGHTING
	Lighting.ClockTime = profile.ClockTime or self._baseLightingClockTime or DEFAULT_MAP_LIGHTING.ClockTime
	Lighting.Brightness = profile.Brightness or self._baseLightingBrightness or DEFAULT_MAP_LIGHTING.Brightness
	Lighting.ExposureCompensation = profile.ExposureCompensation or self._baseLightingExposure or DEFAULT_MAP_LIGHTING.ExposureCompensation
	Lighting.Ambient = profile.Ambient or self._baseLightingAmbient or DEFAULT_MAP_LIGHTING.Ambient
	Lighting.OutdoorAmbient = profile.OutdoorAmbient or self._baseLightingOutdoorAmbient or DEFAULT_MAP_LIGHTING.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = profile.EnvironmentDiffuseScale or self._baseLightingDiffuseScale or DEFAULT_MAP_LIGHTING.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = profile.EnvironmentSpecularScale or self._baseLightingSpecularScale or DEFAULT_MAP_LIGHTING.EnvironmentSpecularScale
end

function VFXController:_applyMapGrade(mapName)
	local profile = MAP_GRADE_PROFILES[mapName] or DEFAULT_MAP_GRADE
	if self._mapCorrection then
		self._baseMapGradeBrightness = profile.Brightness or DEFAULT_MAP_GRADE.Brightness
		self._baseMapGradeContrast = profile.Contrast or DEFAULT_MAP_GRADE.Contrast
		self._baseMapGradeSaturation = profile.Saturation or DEFAULT_MAP_GRADE.Saturation
		self._baseMapGradeTint = profile.TintColor or DEFAULT_MAP_GRADE.TintColor
		self._mapCorrection.Brightness = self._baseMapGradeBrightness
		self._mapCorrection.Contrast = self._baseMapGradeContrast
		self._mapCorrection.Saturation = self._baseMapGradeSaturation
		self._mapCorrection.TintColor = self._baseMapGradeTint
	end
end

function VFXController:_applyMapBloom(mapName)
	local profile = MAP_BLOOM_PROFILES[mapName] or DEFAULT_MAP_BLOOM
	if self._mapBloom then
		self._baseMapBloomIntensity = profile.Intensity or DEFAULT_MAP_BLOOM.Intensity
		self._baseMapBloomSize = profile.Size or DEFAULT_MAP_BLOOM.Size
		self._baseMapBloomThreshold = profile.Threshold or DEFAULT_MAP_BLOOM.Threshold
		self._mapBloom.Intensity = self._baseMapBloomIntensity
		self._mapBloom.Size = self._baseMapBloomSize
		self._mapBloom.Threshold = self._baseMapBloomThreshold
	end
end

function VFXController:_applyMapVisualProfile(mapName)
	self:_applyMapAtmosphere(mapName)
	self:_applyMapLighting(mapName)
	self:_applyMapGrade(mapName)
	self:_applyMapBloom(mapName)
end

return setmetatable({}, VFXController)
