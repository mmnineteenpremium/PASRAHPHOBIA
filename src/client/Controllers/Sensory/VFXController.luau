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
	self._ghostBlur = ensureGhostBlur()
	self._atmosphere = ensureAtmosphere()
	self._currentSanity = 100
	self._sanityTween = nil
	self._ghostFlickerTween = nil
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
	elseif eventName == "MatchStarted" then
		local mapName = (payload and payload.mapName) or (payload and payload.mapType) or "Unknown"
		self:_applyMapAtmosphere(mapName)
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

function VFXController:_cancelGhostFlicker()
	if not self._ghostFlickerTween then
		return
	end
	for _, tween in pairs(self._ghostFlickerTween) do
		if type(tween.Cancel) == "function" then
			tween:Cancel()
		end
	end
	self._ghostFlickerTween = nil
end

function VFXController:_triggerGhostManifestFlicker()
	self:_cancelGhostFlicker()

	local blurTween = TweenService:Create(
		self._ghostBlur,
		TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Size = 20 }
	)

	local revertBlurTween = TweenService:Create(
		self._ghostBlur,
		TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{ Size = 0 }
	)

	local tintUp = TweenService:Create(
		self._sanityCorrection,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TintColor = Color3.fromRGB(170, 190, 255) }
	)

	local tintDown = TweenService:Create(
		self._sanityCorrection,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TintColor = STABLE_POST.Tint }
	)

	self._ghostFlickerTween = {
		blur = blurTween,
		revert = revertBlurTween,
		tintUp = tintUp,
		tintDown = tintDown,
	}

	blurTween.Completed:Connect(function()
		revertBlurTween:Play()
	end)
	tintUp.Completed:Connect(function()
		tintDown:Play()
	end)

	blurTween:Play()
	tintUp:Play()
end

function VFXController:_applyMapAtmosphere(mapName)
	local offset = MAP_ATMOSPHERE_OFFSETS[mapName] or 0.25
	if self._atmosphere then
		self._atmosphere.Offset = offset
	end
end

return setmetatable({}, VFXController)
