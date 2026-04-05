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
	Brightness = -0.01,
	Contrast = 0.14,
	Saturation = -0.14,
	Tint = Color3.fromRGB(210, 220, 235),
	BlurSize = 3,
	AtmosphereDensityDelta = 0.03,
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

local ENVIRONMENTAL_SHOCK_PROFILES = {
	doorslam = {
		Brightness = -0.015,
		Contrast = 0.14,
		Saturation = -0.08,
		Tint = Color3.fromRGB(224, 232, 248),
		BlurSize = 6,
		AtmosphereDensityDelta = 0.018,
		riseTime = 0.06,
		releaseTime = 0.2,
	},
	lightflicker = {
		Brightness = -0.04,
		Contrast = 0.05,
		Saturation = -0.02,
		Tint = Color3.fromRGB(255, 248, 232),
		BlurSize = 1,
		AtmosphereDensityDelta = 0.008,
		riseTime = 0.03,
		releaseTime = 0.12,
	},
	suddenwhisper = {
		Brightness = -0.01,
		Contrast = 0.12,
		Saturation = -0.18,
		Tint = Color3.fromRGB(192, 210, 248),
		BlurSize = 8,
		AtmosphereDensityDelta = 0.02,
		riseTime = 0.08,
		releaseTime = 0.22,
	},
	shadowapparition = {
		Brightness = -0.02,
		Contrast = 0.18,
		Saturation = -0.24,
		Tint = Color3.fromRGB(180, 198, 242),
		BlurSize = 10,
		AtmosphereDensityDelta = 0.028,
		riseTime = 0.07,
		releaseTime = 0.24,
	},
	objectthrow = {
		Brightness = -0.012,
		Contrast = 0.1,
		Saturation = -0.06,
		Tint = Color3.fromRGB(236, 238, 244),
		BlurSize = 4,
		AtmosphereDensityDelta = 0.012,
		riseTime = 0.05,
		releaseTime = 0.18,
	},
	windowknock = {
		Brightness = -0.008,
		Contrast = 0.08,
		Saturation = -0.08,
		Tint = Color3.fromRGB(226, 234, 244),
		BlurSize = 3,
		AtmosphereDensityDelta = 0.01,
		riseTime = 0.05,
		releaseTime = 0.18,
	},
	radiostatic = {
		Brightness = -0.018,
		Contrast = 0.06,
		Saturation = -0.22,
		Tint = Color3.fromRGB(208, 222, 238),
		BlurSize = 3,
		AtmosphereDensityDelta = 0.012,
		riseTime = 0.04,
		releaseTime = 0.14,
	},
	temperaturedrop = {
		Brightness = -0.012,
		Contrast = 0.1,
		Saturation = -0.12,
		Tint = Color3.fromRGB(206, 222, 248),
		BlurSize = 5,
		AtmosphereDensityDelta = 0.018,
		riseTime = 0.07,
		releaseTime = 0.26,
	},
}

local GHOST_AUDIO_SHOCK_PROFILES = {
	ghostwhisper = {
		Brightness = -0.012,
		Contrast = 0.14,
		Saturation = -0.2,
		Tint = Color3.fromRGB(188, 210, 252),
		BlurSize = 9,
		AtmosphereDensityDelta = 0.022,
		riseTime = 0.07,
		releaseTime = 0.22,
	},
	ghostmanifest = {
		Brightness = -0.02,
		Contrast = 0.2,
		Saturation = -0.3,
		Tint = Color3.fromRGB(172, 196, 248),
		BlurSize = 12,
		AtmosphereDensityDelta = 0.03,
		riseTime = 0.06,
		releaseTime = 0.24,
	},
	ghostfakefootsteps = {
		Brightness = -0.006,
		Contrast = 0.08,
		Saturation = -0.08,
		Tint = Color3.fromRGB(226, 234, 246),
		BlurSize = 4,
		AtmosphereDensityDelta = 0.01,
		riseTime = 0.05,
		releaseTime = 0.18,
	},
	ghostobjectthrow = {
		Brightness = -0.01,
		Contrast = 0.1,
		Saturation = -0.1,
		Tint = Color3.fromRGB(214, 226, 242),
		BlurSize = 5,
		AtmosphereDensityDelta = 0.014,
		riseTime = 0.05,
		releaseTime = 0.18,
	},
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
	ColorShift_Top = Color3.fromRGB(0, 0, 0),
	ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
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

local DEFAULT_MAP_DOF = {
	FarIntensity = 0.08,
	FocusDistance = 40,
	InFocusRadius = 24,
	NearIntensity = 0,
}

local DEFAULT_MAP_SUNRAYS = {
	Intensity = 0.03,
	Spread = 0.82,
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
		Density = 0.34,
		Offset = 0.18,
		Color = Color3.fromRGB(162, 170, 188),
		Decay = Color3.fromRGB(112, 118, 136),
		Glare = 0.1,
		Haze = 1.55,
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
		ColorShift_Top = Color3.fromRGB(10, 8, 4),
		ColorShift_Bottom = Color3.fromRGB(6, 4, 2),
	},
	AbandonedPalace = {
		ClockTime = 19.2,
		Brightness = 1.65,
		ExposureCompensation = -0.34,
		Ambient = Color3.fromRGB(88, 76, 70),
		OutdoorAmbient = Color3.fromRGB(104, 90, 82),
		EnvironmentDiffuseScale = 0.18,
		EnvironmentSpecularScale = 0.08,
		ColorShift_Top = Color3.fromRGB(18, 8, 2),
		ColorShift_Bottom = Color3.fromRGB(10, 4, 0),
	},
	HauntedHouse = {
		ClockTime = 1.35,
		Brightness = 2.02,
		ExposureCompensation = -0.08,
		Ambient = Color3.fromRGB(104, 114, 130),
		OutdoorAmbient = Color3.fromRGB(118, 126, 142),
		EnvironmentDiffuseScale = 0.3,
		EnvironmentSpecularScale = 0.14,
		ColorShift_Top = Color3.fromRGB(2, 8, 14),
		ColorShift_Bottom = Color3.fromRGB(2, 6, 10),
	},
	EmptyBuilding = {
		ClockTime = 16.8,
		Brightness = 1.95,
		ExposureCompensation = -0.16,
		Ambient = Color3.fromRGB(118, 122, 134),
		OutdoorAmbient = Color3.fromRGB(132, 136, 148),
		EnvironmentDiffuseScale = 0.24,
		EnvironmentSpecularScale = 0.14,
		ColorShift_Top = Color3.fromRGB(4, 6, 10),
		ColorShift_Bottom = Color3.fromRGB(2, 4, 8),
	},
	StudioMMNineteen = {
		ClockTime = 18.1,
		Brightness = 1.82,
		ExposureCompensation = -0.22,
		Ambient = Color3.fromRGB(98, 104, 116),
		OutdoorAmbient = Color3.fromRGB(112, 118, 130),
		EnvironmentDiffuseScale = 0.22,
		EnvironmentSpecularScale = 0.12,
		ColorShift_Top = Color3.fromRGB(6, 6, 12),
		ColorShift_Bottom = Color3.fromRGB(4, 4, 8),
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
		Brightness = 0.03,
		Contrast = 0.08,
		Saturation = -0.08,
		TintColor = Color3.fromRGB(228, 236, 248),
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
		Intensity = 0.05,
		Size = 12,
		Threshold = 1.02,
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

local MAP_DOF_PROFILES = {
	LobbySocialHub = {
		FarIntensity = 0.06,
		FocusDistance = 52,
		InFocusRadius = 34,
		NearIntensity = 0,
	},
	AbandonedPalace = {
		FarIntensity = 0.16,
		FocusDistance = 22,
		InFocusRadius = 10,
		NearIntensity = 0.04,
	},
	HauntedHouse = {
		FarIntensity = 0.08,
		FocusDistance = 26,
		InFocusRadius = 18,
		NearIntensity = 0.01,
	},
	EmptyBuilding = {
		FarIntensity = 0.1,
		FocusDistance = 28,
		InFocusRadius = 16,
		NearIntensity = 0.02,
	},
	StudioMMNineteen = {
		FarIntensity = 0.11,
		FocusDistance = 24,
		InFocusRadius = 14,
		NearIntensity = 0.02,
	},
}

local MAP_SUNRAYS_PROFILES = {
	LobbySocialHub = {
		Intensity = 0.068,
		Spread = 0.88,
	},
	AbandonedPalace = {
		Intensity = 0.018,
		Spread = 0.76,
	},
	HauntedHouse = {
		Intensity = 0.012,
		Spread = 0.72,
	},
	EmptyBuilding = {
		Intensity = 0.034,
		Spread = 0.8,
	},
	StudioMMNineteen = {
		Intensity = 0.026,
		Spread = 0.78,
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

local function ensureMapDepthOfField()
	local effect = Lighting:FindFirstChild("SensoryMapDepthOfField")
	if not effect then
		effect = Instance.new("DepthOfFieldEffect")
		effect.Name = "SensoryMapDepthOfField"
		effect.FarIntensity = DEFAULT_MAP_DOF.FarIntensity
		effect.FocusDistance = DEFAULT_MAP_DOF.FocusDistance
		effect.InFocusRadius = DEFAULT_MAP_DOF.InFocusRadius
		effect.NearIntensity = DEFAULT_MAP_DOF.NearIntensity
		effect.Parent = Lighting
	end
	return effect
end

local function ensureMapSunRays()
	local effect = Lighting:FindFirstChild("SensoryMapSunRays")
	if not effect then
		effect = Instance.new("SunRaysEffect")
		effect.Name = "SensoryMapSunRays"
		effect.Intensity = DEFAULT_MAP_SUNRAYS.Intensity
		effect.Spread = DEFAULT_MAP_SUNRAYS.Spread
		effect.Parent = Lighting
	end
	return effect
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

local function normalizeCueToken(value)
	return tostring(value or ""):gsub("[%s_%-_]+", ""):lower()
end

local function coerceVector3(value)
	if typeof(value) == "Vector3" then
		return value
	end
	if type(value) == "table" then
		local x = tonumber(value.x or value.X)
		local y = tonumber(value.y or value.Y)
		local z = tonumber(value.z or value.Z)
		if x and y and z then
			return Vector3.new(x, y, z)
		end
	end
	return nil
end

local function normalizeMapProfileName(mapName)
	if type(mapName) ~= "string" then
		return nil
	end
	local normalized = tostring(mapName)
	if normalized == "" then
		return nil
	end
	if normalized == "Lobby" then
		return "LobbySocialHub"
	end
	return normalized
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
	self._mapDepthOfField = ensureMapDepthOfField()
	self._mapSunRays = ensureMapSunRays()
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
	self._baseLightingColorShiftTop = Lighting.ColorShift_Top
	self._baseLightingColorShiftBottom = Lighting.ColorShift_Bottom
	self._baseMapGradeBrightness = self._mapCorrection and self._mapCorrection.Brightness or DEFAULT_MAP_GRADE.Brightness
	self._baseMapGradeContrast = self._mapCorrection and self._mapCorrection.Contrast or DEFAULT_MAP_GRADE.Contrast
	self._baseMapGradeSaturation = self._mapCorrection and self._mapCorrection.Saturation or DEFAULT_MAP_GRADE.Saturation
	self._baseMapGradeTint = self._mapCorrection and self._mapCorrection.TintColor or DEFAULT_MAP_GRADE.TintColor
	self._baseMapBloomIntensity = self._mapBloom and self._mapBloom.Intensity or DEFAULT_MAP_BLOOM.Intensity
	self._baseMapBloomSize = self._mapBloom and self._mapBloom.Size or DEFAULT_MAP_BLOOM.Size
	self._baseMapBloomThreshold = self._mapBloom and self._mapBloom.Threshold or DEFAULT_MAP_BLOOM.Threshold
	self._baseMapDOFFarIntensity = self._mapDepthOfField and self._mapDepthOfField.FarIntensity or DEFAULT_MAP_DOF.FarIntensity
	self._baseMapDOFFocusDistance = self._mapDepthOfField and self._mapDepthOfField.FocusDistance or DEFAULT_MAP_DOF.FocusDistance
	self._baseMapDOFInFocusRadius = self._mapDepthOfField and self._mapDepthOfField.InFocusRadius or DEFAULT_MAP_DOF.InFocusRadius
	self._baseMapDOFNearIntensity = self._mapDepthOfField and self._mapDepthOfField.NearIntensity or DEFAULT_MAP_DOF.NearIntensity
	self._baseMapSunRaysIntensity = self._mapSunRays and self._mapSunRays.Intensity or DEFAULT_MAP_SUNRAYS.Intensity
	self._baseMapSunRaysSpread = self._mapSunRays and self._mapSunRays.Spread or DEFAULT_MAP_SUNRAYS.Spread
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
	if localPlayer then
		table.insert(self._connections, localPlayer:GetAttributeChangedSignal("InMatch"):Connect(function()
			self:_syncMapVisualProfileFromPlayerState()
		end))
		table.insert(self._connections, localPlayer:GetAttributeChangedSignal("MatchMapId"):Connect(function()
			self:_syncMapVisualProfileFromPlayerState()
		end))
		table.insert(self._connections, localPlayer:GetAttributeChangedSignal("MapName"):Connect(function()
			self:_syncMapVisualProfileFromPlayerState()
		end))
	end
	self:_syncMapVisualProfileFromPlayerState()
end

function VFXController:_recordVFXDebug(eventName, profileName)
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end
	localPlayer:SetAttribute("PasrahVFXLastEvent", tostring(eventName or ""))
	localPlayer:SetAttribute("PasrahVFXLastProfile", tostring(profileName or ""))
	localPlayer:SetAttribute("PasrahVFXLastAt", os.clock())
end

function VFXController:_resolveActiveMatchContainer(matchId)
	local activeMatches = Workspace:FindFirstChild("ActiveMatches")
	if not activeMatches then
		return nil
	end

	local resolvedMatchId = type(matchId) == "string" and matchId or nil
	if not resolvedMatchId or resolvedMatchId == "" then
		local localPlayer = Players.LocalPlayer
		if localPlayer then
			resolvedMatchId = localPlayer:GetAttribute("PasrahMatchId")
				or localPlayer:GetAttribute("MatchId")
		end
	end

	if type(resolvedMatchId) == "string" and resolvedMatchId ~= "" then
		local named = activeMatches:FindFirstChild("Match_" .. resolvedMatchId)
		if named then
			return named
		end
	end

	return activeMatches:GetChildren()[1]
end

function VFXController:_resolveRoomAnchor(matchId, roomId)
	if type(roomId) ~= "string" or roomId == "" then
		return nil
	end

	local container = self:_resolveActiveMatchContainer(matchId)
	if not container then
		return nil
	end

	local targetToken = normalizeCueToken(roomId)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local token = normalizeCueToken(descendant.Name)
			if token == targetToken or token == normalizeCueToken("Room_" .. roomId) then
				return descendant
			end
		end
	end

	return nil
end

function VFXController:_resolveEventPosition(payload)
	local position = coerceVector3(payload and payload.position)
	if position then
		return position
	end

	local roomAnchor = self:_resolveRoomAnchor(payload and payload.matchId, payload and payload.roomId)
	if roomAnchor then
		return roomAnchor.Position
	end

	return nil
end

function VFXController:_pulseNearbyLights(centerPosition, radius, profileName)
	if typeof(centerPosition) ~= "Vector3" then
		return 0
	end

	local container = self:_resolveActiveMatchContainer()
	if not container then
		return 0
	end

	local affected = 0
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			local parentPart = descendant.Parent
			local lightPosition = parentPart and parentPart:IsA("BasePart") and parentPart.Position or nil
			if lightPosition and (lightPosition - centerPosition).Magnitude <= (radius or 28) then
				affected += 1
				local originalBrightness = descendant.Brightness
				local originalEnabled = descendant.Enabled
				descendant.Enabled = true
				descendant.Brightness = math.max(0.05, originalBrightness * 0.08)
				task.delay(0.04, function()
					if descendant.Parent then
						descendant.Enabled = false
					end
				end)
				task.delay(0.09, function()
					if descendant.Parent then
						descendant.Enabled = true
						descendant.Brightness = math.max(0.05, originalBrightness * 1.35)
					end
				end)
				task.delay(0.18, function()
					if descendant.Parent then
						descendant.Enabled = originalEnabled
						descendant.Brightness = originalBrightness
					end
				end)
			end
		end
	end

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		localPlayer:SetAttribute("PasrahVFXLastLightCount", affected)
	end
	return affected
end

function VFXController:_pulseNearbyProps(centerPosition, radius, tokenSet, transformFactory, attrName, requiredAncestorToken)
	if typeof(centerPosition) ~= "Vector3" then
		return 0
	end

	local container = self:_resolveActiveMatchContainer()
	if not container then
		return 0
	end

	local affected = 0
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local nameToken = normalizeCueToken(descendant.Name)
			local matched = false
			for _, token in ipairs(tokenSet or {}) do
				if string.find(nameToken, normalizeCueToken(token), 1, true) then
					matched = true
					break
				end
			end
			local ancestorMatched = requiredAncestorToken == nil
			if matched and ancestorMatched == false then
				local cursor = descendant.Parent
				while cursor do
					if normalizeCueToken(cursor.Name) == normalizeCueToken(requiredAncestorToken) then
						ancestorMatched = true
						break
					end
					cursor = cursor.Parent
				end
			end
			if matched and ancestorMatched and (descendant.Position - centerPosition).Magnitude <= (radius or 20) then
				affected += 1
				local originalCFrame = descendant.CFrame
				local bounce = transformFactory and transformFactory(descendant) or CFrame.new()
				descendant.CFrame = originalCFrame * bounce
				task.delay(0.09, function()
					if descendant.Parent then
						descendant.CFrame = originalCFrame
					end
				end)
			end
		end
	end

	local localPlayer = Players.LocalPlayer
	if localPlayer and type(attrName) == "string" and attrName ~= "" then
		localPlayer:SetAttribute(attrName, affected)
	end
	return affected
end

function VFXController:_ensureRuntimeVFXFolder()
	local folder = Workspace:FindFirstChild("RuntimeVFX")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RuntimeVFX"
		folder.Parent = Workspace
	end
	return folder
end

function VFXController:_spawnShadowApparition(centerPosition)
	if typeof(centerPosition) ~= "Vector3" then
		return false
	end

	local model = Instance.new("Model")
	model.Name = "ShadowApparitionRuntime"
	model.Parent = self:_ensureRuntimeVFXFolder()

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Anchored = true
	torso.CanCollide = false
	torso.CanQuery = false
	torso.CanTouch = false
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = Color3.fromRGB(18, 20, 26)
	torso.Transparency = 1
	torso.Size = Vector3.new(1.8, 3.6, 0.7)
	torso.CFrame = CFrame.new(centerPosition + Vector3.new(0, 1.8, 0))
	model.PrimaryPart = torso
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.CanCollide = false
	head.CanQuery = false
	head.CanTouch = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = torso.Color
	head.Transparency = 1
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.15, 1.15, 1.15)
	head.CFrame = torso.CFrame * CFrame.new(0, 2.25, 0)
	head.Parent = model

	local targetTransparency = 0.24
	local fadeInTorso = TweenService:Create(torso, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = targetTransparency,
	})
	local fadeInHead = TweenService:Create(head, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = targetTransparency + 0.04,
	})
	fadeInTorso:Play()
	fadeInHead:Play()

	task.delay(0.16, function()
		if torso.Parent then
			TweenService:Create(torso, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Transparency = 1,
				CFrame = torso.CFrame * CFrame.new(0, 0.18, 0),
			}):Play()
		end
		if head.Parent then
			TweenService:Create(head, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Transparency = 1,
				CFrame = head.CFrame * CFrame.new(0, 0.22, 0),
			}):Play()
		end
	end)

	Debris:AddItem(model, 0.7)
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		localPlayer:SetAttribute("PasrahVFXLastShadowPosition", tostring(centerPosition))
	end
	return true
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
	elseif eventName == "EnvironmentalAudioTriggered" then
		self:_triggerEnvironmentalShock(payload)
	elseif eventName == "GhostAudioTriggered" then
		self:_triggerGhostAudioShock(payload)
	elseif eventName == "MatchStarted" then
		local mapName = normalizeMapProfileName((payload and payload.mapName) or (payload and payload.mapType) or (payload and payload.mapId))
		self:_applyMapVisualProfile(mapName or self:_resolveAuthoritativeMapProfile())
		self._huntActive = false
		self:_applyThreatBaseline(0)
	elseif eventName == "PhaseChanged" then
		local phaseName = tostring((payload and payload.phase) or (payload and payload.phaseName) or (payload and payload.matchPhase) or "")
		local mapName = normalizeMapProfileName((payload and payload.mapName) or (payload and payload.mapType) or (payload and payload.mapId) or (payload and payload.map))
		if mapName then
			self:_applyMapVisualProfile(mapName)
		elseif phaseName == "Lobby" then
			self:_applyMapVisualProfile("LobbySocialHub")
		else
			self:_syncMapVisualProfileFromPlayerState()
		end
	elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
		self._huntActive = false
		self:_syncMapVisualProfileFromPlayerState()
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

function VFXController:_triggerEnvironmentalShock(payload)
	local eventToken = normalizeCueToken((payload and payload.eventType) or (payload and payload.cue))
	local profile = ENVIRONMENTAL_SHOCK_PROFILES[eventToken]
	if not profile then
		return
	end

	local cloned = {}
	for key, value in pairs(profile) do
		cloned[key] = value
	end
	local intensity = math.clamp(tonumber(payload and payload.intensity) or 1, 0.45, 1.3)
	cloned.BlurSize = math.max(0, math.floor(((cloned.BlurSize or 0) * intensity) + 0.5))
	cloned.Contrast = (cloned.Contrast or 0) * intensity
	cloned.Brightness = (cloned.Brightness or 0) * math.clamp(intensity, 0.8, 1.15)
	cloned.AtmosphereDensityDelta = (cloned.AtmosphereDensityDelta or 0) * math.clamp(intensity, 0.85, 1.2)
	self:_recordVFXDebug("EnvironmentalAudioTriggered", eventToken)
	if eventToken == "lightflicker" then
		self:_pulseNearbyLights(self:_resolveEventPosition(payload), 30, eventToken)
	elseif eventToken == "doorslam" then
		self:_pulseNearbyProps(
			self:_resolveEventPosition(payload),
			24,
			{ "door" },
			function(descendant)
				local sign = descendant.Position.X >= 0 and 1 or -1
				return CFrame.Angles(0, math.rad(11 * sign), 0)
			end,
			"PasrahVFXLastPropCount",
			"Doors"
		)
	elseif eventToken == "windowknock" then
		self:_pulseNearbyProps(
			self:_resolveEventPosition(payload),
			26,
			{ "window" },
			function(descendant)
				local sign = descendant.Position.Z >= 0 and -1 or 1
				return CFrame.new(0, 0, 0.18 * sign)
			end,
			"PasrahVFXLastPropCount",
			"Windows"
		)
	elseif eventToken == "objectthrow" then
		self:_pulseNearbyProps(
			self:_resolveEventPosition(payload),
			28,
			{ "prop" },
			function(descendant)
				local signX = descendant.Position.X >= 0 and 1 or -1
				local signZ = descendant.Position.Z >= 0 and -1 or 1
				return CFrame.new(0.35 * signX, 0.08, 0.22 * signZ) * CFrame.Angles(0, math.rad(6 * signX), math.rad(3 * signZ))
			end,
			"PasrahVFXLastPropCount",
			"Props"
		)
	elseif eventToken == "radiostatic" then
		self:_pulseNearbyProps(
			self:_resolveEventPosition(payload),
			24,
			{ "tv", "radio", "phone" },
			function(descendant)
				local signX = descendant.Position.X >= 0 and 1 or -1
				return CFrame.new(0.08 * signX, 0, 0) * CFrame.Angles(0, math.rad(2 * signX), 0)
			end,
			"PasrahVFXLastElectronicCount",
			"Props"
		)
	elseif eventToken == "shadowapparition" then
		self:_spawnShadowApparition(self:_resolveEventPosition(payload) or Vector3.new())
	end
	self:_playTransientShock(cloned)
end

function VFXController:_triggerGhostAudioShock(payload)
	local cueToken = normalizeCueToken((payload and payload.cue) or (payload and payload.eventType))
	local profile = GHOST_AUDIO_SHOCK_PROFILES[cueToken]
	if not profile then
		return
	end

	local cloned = {}
	for key, value in pairs(profile) do
		cloned[key] = value
	end
	local intensity = math.clamp(tonumber(payload and payload.intensity) or 1, 0.45, 1.35)
	cloned.BlurSize = math.max(0, math.floor(((cloned.BlurSize or 0) * intensity) + 0.5))
	cloned.Contrast = (cloned.Contrast or 0) * intensity
	cloned.Brightness = (cloned.Brightness or 0) * math.clamp(intensity, 0.8, 1.2)
	cloned.AtmosphereDensityDelta = (cloned.AtmosphereDensityDelta or 0) * math.clamp(intensity, 0.85, 1.2)
	self:_recordVFXDebug("GhostAudioTriggered", cueToken)
	self:_playTransientShock(cloned)
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
	Lighting.ColorShift_Top = profile.ColorShift_Top or self._baseLightingColorShiftTop or DEFAULT_MAP_LIGHTING.ColorShift_Top
	Lighting.ColorShift_Bottom = profile.ColorShift_Bottom or self._baseLightingColorShiftBottom or DEFAULT_MAP_LIGHTING.ColorShift_Bottom
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

function VFXController:_applyMapDepthOfField(mapName)
	local profile = MAP_DOF_PROFILES[mapName] or DEFAULT_MAP_DOF
	if self._mapDepthOfField then
		self._baseMapDOFFarIntensity = profile.FarIntensity or DEFAULT_MAP_DOF.FarIntensity
		self._baseMapDOFFocusDistance = profile.FocusDistance or DEFAULT_MAP_DOF.FocusDistance
		self._baseMapDOFInFocusRadius = profile.InFocusRadius or DEFAULT_MAP_DOF.InFocusRadius
		self._baseMapDOFNearIntensity = profile.NearIntensity or DEFAULT_MAP_DOF.NearIntensity
		self._mapDepthOfField.FarIntensity = self._baseMapDOFFarIntensity
		self._mapDepthOfField.FocusDistance = self._baseMapDOFFocusDistance
		self._mapDepthOfField.InFocusRadius = self._baseMapDOFInFocusRadius
		self._mapDepthOfField.NearIntensity = self._baseMapDOFNearIntensity
	end
end

function VFXController:_applyMapSunRays(mapName)
	local profile = MAP_SUNRAYS_PROFILES[mapName] or DEFAULT_MAP_SUNRAYS
	if self._mapSunRays then
		self._baseMapSunRaysIntensity = profile.Intensity or DEFAULT_MAP_SUNRAYS.Intensity
		self._baseMapSunRaysSpread = profile.Spread or DEFAULT_MAP_SUNRAYS.Spread
		self._mapSunRays.Intensity = self._baseMapSunRaysIntensity
		self._mapSunRays.Spread = self._baseMapSunRaysSpread
	end
end

function VFXController:_applyMapVisualProfile(mapName)
	local resolvedMapName = normalizeMapProfileName(mapName) or "LobbySocialHub"
	self._activeMapProfileName = resolvedMapName
	self:_applyMapAtmosphere(resolvedMapName)
	self:_applyMapLighting(resolvedMapName)
	self:_applyMapGrade(resolvedMapName)
	self:_applyMapBloom(resolvedMapName)
	self:_applyMapDepthOfField(resolvedMapName)
	self:_applyMapSunRays(resolvedMapName)
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		localPlayer:SetAttribute("PasrahVFXMapProfile", resolvedMapName)
	end
end

function VFXController:_resolveAuthoritativeMapProfile()
	local localPlayer = Players.LocalPlayer
	if not localPlayer or localPlayer:GetAttribute("InMatch") ~= true then
		return "LobbySocialHub"
	end

	local mapName = normalizeMapProfileName(localPlayer:GetAttribute("MatchMapId"))
		or normalizeMapProfileName(localPlayer:GetAttribute("MapName"))
	return mapName or self._activeMapProfileName or "HauntedHouse"
end

function VFXController:_syncMapVisualProfileFromPlayerState()
	self:_applyMapVisualProfile(self:_resolveAuthoritativeMapProfile())
end

return setmetatable({}, VFXController)
