local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local AudioController = require(script.Parent.Parent.Controllers.Sensory.AudioController)
local FootstepController = require(script.Parent.Parent.Controllers.Sensory.FootstepController)
local VFXController = require(script.Parent.Parent.Controllers.Sensory.VFXController)
local HorrorHUD = require(script.Parent.Parent.UI.HUD.HorrorHUD)

local SoundSystem = {}
SoundSystem.__index = SoundSystem

local EVENT_TO_CATEGORY = {
	AmbientAudioTriggered = "AmbientAudio",
	EnvironmentalAudioTriggered = "EnvironmentalAudio",
	FearAudioTriggered = "FearAudio",
	GhostAudioTriggered = "GhostAudio",
	HuntAudioTriggered = "HuntAudio",
	JumpscareAudioTriggered = "JumpscareAudio",
}

local CATEGORY_TEMPLATE_PATHS = {
	AmbientAudio = { "Assets", "Audio", "Ambient", "AmbientLoop_Main" },
	EnvironmentalAudio = { "Assets", "Audio", "Environment", "EnvironmentalCreak_01" },
	FearAudio = { "Assets", "Audio", "Sensory", "Heartbeat" },
	HuntAudio = { "Assets", "Audio", "Ghost", "HuntStart_01" },
	JumpscareAudio = { "Assets", "Audio", "Jumpscare", "Jumpscare_01" },
}

local CATEGORY_BASE_VOLUME = {
	AmbientAudio = 0.35,
	EnvironmentalAudio = 0.75,
	FearAudio = 0.7,
	GhostAudio = 0.85,
	HuntAudio = 1.0,
	JumpscareAudio = 1.0,
}

local LOOPED_CATEGORIES = {
	AmbientAudio = true,
}

local ONESHOT_DEDUPE_WINDOW_SECONDS = {
	HuntAudio = 2.25,
	JumpscareAudio = 1.5,
}

local AUDIO_DEBUG_ATTRS = {
	category = "PasrahAudioLastCategory",
	template = "PasrahAudioLastTemplate",
	cue = "PasrahAudioLastCue",
	eventType = "PasrahAudioLastEventType",
	soundId = "PasrahAudioLastSoundId",
	volume = "PasrahAudioLastVolume",
	playbackSpeed = "PasrahAudioLastPlaybackSpeed",
	spatialMode = "PasrahAudioLastSpatialMode",
	sourcePosition = "PasrahAudioLastSourcePosition",
	playCount = "PasrahAudioPlayCount",
}

local CUE_AUDIO_PROFILES = {
	AmbientAudio = {
		ambient_investigation = { volumeScale = 0.9, playbackSpeed = 0.97 },
		post_hunt_calm = { volumeScale = 0.78, playbackSpeed = 0.94 },
	},
	EnvironmentalAudio = {
		env_doorslam = { volumeScale = 1.06, playbackSpeed = 0.92 },
		env_objectthrow = { volumeScale = 1.0, playbackSpeed = 0.96 },
		env_windowknock = { volumeScale = 0.86, playbackSpeed = 0.98 },
		env_lightflicker = { volumeScale = 0.72, playbackSpeed = 1.04 },
		env_radiostatic = { volumeScale = 0.68, playbackSpeed = 0.9 },
		env_shadowapparition = { volumeScale = 0.94, playbackSpeed = 0.9 },
		env_footstepsound = { volumeScale = 0.82, playbackSpeed = 1.03 },
		env_suddenwhisper = { volumeScale = 0.88, playbackSpeed = 0.92 },
		env_temperaturedrop = { volumeScale = 0.8, playbackSpeed = 0.88 },
	},
	GhostAudio = {
		ghost_whisper = { volumeScale = 0.84, playbackSpeed = 0.9 },
		ghost_fake_footsteps = { volumeScale = 0.74, playbackSpeed = 1.04 },
		ghost_manifest = { volumeScale = 0.98, playbackSpeed = 0.88 },
		ghost_object_throw = { volumeScale = 0.82, playbackSpeed = 0.95 },
	},
	HuntAudio = {
		hunt_start = { volumeScale = 1.04, playbackSpeed = 1.02 },
		hunt_phase_loop = { volumeScale = 0.96, playbackSpeed = 0.99 },
	},
	FearAudio = {
		fear_rise = { volumeScale = 0.86, playbackSpeed = 1.0 },
		fear_critical = { volumeScale = 1.0, playbackSpeed = 1.08 },
	},
	JumpscareAudio = {
		jumpscare_stinger = { volumeScale = 1.0, playbackSpeed = 1.06 },
	},
}

local SPATIAL_SOUND_CATEGORIES = {
	EnvironmentalAudio = true,
	GhostAudio = true,
}

local function resolveTemplate(root, pathSegments)
	local cursor = root
	for _, segment in ipairs(pathSegments or {}) do
		if not cursor then
			return nil
		end
		cursor = cursor:FindFirstChild(segment)
	end
	if cursor and cursor:IsA("Sound") and tostring(cursor.SoundId or "") ~= "" then
		return cursor
	end
	return nil
end

local function resolveAudioFolder(root)
	local assets = root and root:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("Audio")
end

local function normalizeCue(cue)
	return tostring(cue or ""):gsub("[%s_%-]+", "_"):lower()
end

local function stringifyVector3(value)
	if typeof(value) ~= "Vector3" then
		return ""
	end
	return string.format("%.2f, %.2f, %.2f", value.X, value.Y, value.Z)
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

local function resolveCueProfile(category, payload)
	local profiles = CUE_AUDIO_PROFILES[category]
	if type(profiles) ~= "table" then
		return nil
	end

	local cueToken = normalizeCue(payload and payload.cue)
	if cueToken ~= "" and profiles[cueToken] then
		return profiles[cueToken]
	end

	local eventToken = normalizeCue(payload and payload.eventType)
	if eventToken ~= "" then
		local prefixed = "env_" .. eventToken
		if profiles[prefixed] then
			return profiles[prefixed]
		end
		if profiles[eventToken] then
			return profiles[eventToken]
		end
	end

	return nil
end

local function findNamedBasePart(root, ...)
	if typeof(root) ~= "Instance" then
		return nil
	end

	local tokens = {}
	for _, value in ipairs({ ... }) do
		local token = tostring(value or ""):gsub("[%s_%-]+", ""):lower()
		if token ~= "" then
			tokens[token] = true
		end
	end

	if next(tokens) == nil then
		return nil
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local token = tostring(descendant.Name):gsub("[%s_%-]+", ""):lower()
			if tokens[token] then
				return descendant
			end
		end
	end

	return nil
end

local function resolveFolderTemplate(root, folderName, templateName)
	local audioFolder = resolveAudioFolder(root)
	local targetFolder = audioFolder and audioFolder:FindFirstChild(folderName)
	local template = targetFolder and targetFolder:FindFirstChild(templateName)
	if template and template:IsA("Sound") and tostring(template.SoundId or "") ~= "" then
		return template
	end
	return nil
end

local function resolveGhostTemplate(root, payload)
	local cueToken = normalizeCue((payload and payload.cue) or payload)
	if string.find(cueToken, "footstep", 1, true) then
		return resolveFootstepTemplate(root, payload)
	end
	if string.find(cueToken, "object", 1, true) or string.find(cueToken, "throw", 1, true) then
		return resolveFolderTemplate(root, "Environment", "EnvironmentalCreak_01")
	end
	local primaryName = "GhostManifest_01"
	if string.find(cueToken, "whisper", 1, true) then
		primaryName = "GhostWhisper_01"
	elseif string.find(cueToken, "manifest", 1, true) then
		primaryName = "GhostManifest_01"
	elseif string.find(cueToken, "interaction", 1, true) then
		primaryName = "GhostManifest_01"
	end

	local primary = resolveFolderTemplate(root, "Ghost", primaryName)
	if primary then
		return primary
	end

	return resolveFolderTemplate(root, "Ghost", "GhostManifest_01")
end

local function resolveJumpscareTemplate(root, payload)
	local cueToken = normalizeCue((payload and payload.cue) or payload)
	if string.find(cueToken, "manifest", 1, true) then
		return resolveFolderTemplate(root, "Ghost", "GhostManifest_01")
	end
	local template = resolveFolderTemplate(root, "Jumpscare", "Jumpscare_01")
	if template then
		return template
	end
	return resolveFolderTemplate(root, "Ghost", "HuntStart_01")
end

local function resolveFootstepTemplate(root, payload)
	local cueToken = normalizeCue(
		(payload and payload.surfaceMaterial)
			or (payload and payload.material)
			or (payload and payload.floorMaterial)
			or (payload and payload.eventType)
			or (payload and payload.cue)
	)
	local templateName = "ConcreteStep_01"
	if string.find(cueToken, "wood", 1, true) then
		templateName = "Woodstep_01"
	elseif string.find(cueToken, "metal", 1, true) or string.find(cueToken, "diamondplate", 1, true) then
		templateName = "MetalStep_01"
	end
	return resolveFolderTemplate(root, "Footsteps", templateName)
		or resolveFolderTemplate(root, "Footsteps", "ConcreteStep_01")
end

local function resolveEnvironmentalTemplate(root, payload)
	local cueToken = normalizeCue((payload and payload.eventType) or (payload and payload.cue))

	if string.find(cueToken, "footstep", 1, true) then
		return resolveFootstepTemplate(root, payload)
	end
	if string.find(cueToken, "whisper", 1, true) then
		return resolveFolderTemplate(root, "Ghost", "GhostWhisper_01") or resolveGhostTemplate(root, cueToken)
	end
	if string.find(cueToken, "shadow", 1, true)
		or string.find(cueToken, "apparition", 1, true)
		or string.find(cueToken, "manifest", 1, true)
		or string.find(cueToken, "temperature", 1, true) then
		return resolveFolderTemplate(root, "Ghost", "GhostManifest_01") or resolveGhostTemplate(root, cueToken)
	end

	return resolveFolderTemplate(root, "Environment", "EnvironmentalCreak_01")
end

function SoundSystem:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._lastAudioByCategory = {}
	self._lastOneShotAtByKey = {}
	self._managedControllers = {}
	self._activeSounds = {}
	self._activeSpatialEmitters = {}
	self._audioTemplates = {}
	self._audioRoot = ReplicatedStorage
	self._player = Players.LocalPlayer
	if self._player then
		self._player:SetAttribute(AUDIO_DEBUG_ATTRS.category, "")
		self._player:SetAttribute(AUDIO_DEBUG_ATTRS.template, "")
		self._player:SetAttribute(AUDIO_DEBUG_ATTRS.cue, "")
		self._player:SetAttribute(AUDIO_DEBUG_ATTRS.eventType, "")
		self._player:SetAttribute(AUDIO_DEBUG_ATTRS.soundId, "")
		self._player:SetAttribute(AUDIO_DEBUG_ATTRS.spatialMode, "")
		self._player:SetAttribute(AUDIO_DEBUG_ATTRS.sourcePosition, "")
		self._player:SetAttribute(AUDIO_DEBUG_ATTRS.playCount, 0)
	end
	self:_registerSensoryController("AudioController", AudioController, context)
	self:_registerSensoryController("FootstepController", FootstepController, context)
	self:_registerSensoryController("VFXController", VFXController, context)
	self:_registerSensoryController("HorrorHUD", HorrorHUD, context)
end

function SoundSystem:_resolveActiveMatchContainer(matchId)
	local activeMatches = Workspace:FindFirstChild("ActiveMatches")
	if not activeMatches then
		return nil
	end

	local resolvedMatchId = type(matchId) == "string" and matchId or nil
	if not resolvedMatchId or resolvedMatchId == "" then
		if self._player then
			resolvedMatchId = self._player:GetAttribute("PasrahMatchId")
				or self._player:GetAttribute("MatchId")
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

function SoundSystem:_resolveRoomAnchor(matchId, roomId)
	if type(roomId) ~= "string" or roomId == "" then
		return nil
	end

	local container = self:_resolveActiveMatchContainer(matchId)
	if not container then
		return nil
	end

	local roomsRoot = container:FindFirstChild("Rooms", true) or container
	return findNamedBasePart(roomsRoot, roomId, "Room_" .. roomId)
		or findNamedBasePart(container, roomId, "Room_" .. roomId)
end

function SoundSystem:_ensureRuntimeAudioEmitterFolder()
	local folder = Workspace:FindFirstChild("RuntimeAudioEmitters")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RuntimeAudioEmitters"
		folder.Parent = Workspace
	end
	return folder
end

function SoundSystem:_createSpatialEmitter(position, category)
	if typeof(position) ~= "Vector3" then
		return nil
	end

	local part = Instance.new("Part")
	part.Name = tostring(category or "Audio") .. "Emitter"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(position)
	part.Parent = self:_ensureRuntimeAudioEmitterFolder()
	return part
end

function SoundSystem:_resolvePlaybackTarget(category, payload)
	if SPATIAL_SOUND_CATEGORIES[category] ~= true then
		return {
			parent = self:_getParentForCategory(category),
			spatialMode = "camera",
			sourcePosition = "",
			emitterPart = nil,
		}
	end

	local position = coerceVector3(payload and payload.position)
	if position then
		local emitterPart = self:_createSpatialEmitter(position, category)
		if emitterPart then
			return {
				parent = emitterPart,
				spatialMode = "position",
				sourcePosition = stringifyVector3(position),
				emitterPart = emitterPart,
			}
		end
	end

	local roomAnchor = self:_resolveRoomAnchor(payload and payload.matchId, payload and payload.roomId)
	if roomAnchor then
		return {
			parent = roomAnchor,
			spatialMode = "room_anchor",
			sourcePosition = stringifyVector3(roomAnchor.Position),
			emitterPart = nil,
		}
	end

	return {
		parent = self:_getParentForCategory(category),
		spatialMode = "camera_fallback",
		sourcePosition = "",
		emitterPart = nil,
	}
end

function SoundSystem:Stop()
	for _, controller in ipairs(self._managedControllers) do
		if type(controller.Stop) == "function" then
			controller:Stop()
		end
	end
	self:_stopAllAudio()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
end

function SoundSystem:_registerSensoryController(name, module, context)
	if not context or not context.Registry then
		return
	end
	if context.Registry:Has(name) then
		return
	end
	context.Registry:Register(name, module)
	table.insert(self._managedControllers, module)
	if type(module.Init) == "function" then
		module:Init(context)
	end
end

function SoundSystem:Start()
	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end
	for _, controller in ipairs(self._managedControllers) do
		if type(controller.Start) == "function" then
			controller:Start(self._context)
		end
	end
end

function SoundSystem:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	local category = eventName and EVENT_TO_CATEGORY[eventName] or nil
	if category then
		self:_onAudioEvent(payload)
		return
	end

	if eventName == "MatchEnded" or eventName == "MatchCompleted" then
		self:_stopAllAudio()
	end
end

function SoundSystem:_onAudioEvent(payload)
	local eventName = payload and payload.eventName
	local category = EVENT_TO_CATEGORY[eventName]
	if not category then
		return
	end
	self._lastAudioByCategory[category] = payload
	self:_playCategoryAudio(category, payload)
end

function SoundSystem:GetLastAudio(category)
	return self._lastAudioByCategory[category]
end

function SoundSystem:_getParentForCategory(category)
	if category == "AmbientAudio" then
		return SoundService
	end
	return Workspace.CurrentCamera or SoundService
end

function SoundSystem:_getTemplateForCategory(category, payload)
	if category == "GhostAudio" then
		return resolveGhostTemplate(self._audioRoot, payload)
	end
	if category == "EnvironmentalAudio" then
		return resolveEnvironmentalTemplate(self._audioRoot, payload)
	end
	if category == "JumpscareAudio" then
		return resolveJumpscareTemplate(self._audioRoot, payload)
	end

	local cached = self._audioTemplates[category]
	if cached and cached.Parent then
		return cached
	end

	local pathSegments = CATEGORY_TEMPLATE_PATHS[category]
	local template = resolveTemplate(self._audioRoot, pathSegments)
	if template then
		self._audioTemplates[category] = template
	end
	return template
end

function SoundSystem:_recordAudioDebug(category, template, payload)
	if not self._player then
		return
	end

	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.category, tostring(category or ""))
	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.template, tostring(template and template.Name or ""))
	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.cue, tostring(payload and payload.cue or ""))
	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.eventType, tostring(payload and payload.eventType or ""))
	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.soundId, tostring(template and template.SoundId or ""))
	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.volume, tonumber(template and template.Volume) or 0)
	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.playbackSpeed, tonumber(template and template.PlaybackSpeed) or 1)
	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.spatialMode, tostring(template and template:GetAttribute("PasrahSpatialMode") or ""))
	self._player:SetAttribute(AUDIO_DEBUG_ATTRS.sourcePosition, tostring(template and template:GetAttribute("PasrahAudioSourcePosition") or ""))
	self._player:SetAttribute(
		AUDIO_DEBUG_ATTRS.playCount,
		(tonumber(self._player:GetAttribute(AUDIO_DEBUG_ATTRS.playCount)) or 0) + 1
	)
end

function SoundSystem:_applySoundProfile(sound, category, payload)
	local intensity = math.clamp(tonumber(payload and payload.intensity) or 1, 0.15, 1.5)
	local baseVolume = CATEGORY_BASE_VOLUME[category] or 0.7
	local templateVolume = tonumber(sound.Volume) or baseVolume
	local cueProfile = resolveCueProfile(category, payload)
	sound.Volume = math.clamp(templateVolume * intensity * (tonumber(cueProfile and cueProfile.volumeScale) or 1), 0, 1)
	sound:SetAttribute("PasrahAudioCategory", category)
	sound:SetAttribute("PasrahAudioCue", tostring(payload and payload.cue or ""))

	if category == "FearAudio" then
		sound.PlaybackSpeed = math.clamp(0.92 + intensity * 0.4, 0.92, 1.45)
	elseif category == "HuntAudio" then
		sound.PlaybackSpeed = math.clamp(0.96 + intensity * 0.14, 0.96, 1.18)
	elseif category == "JumpscareAudio" then
		sound.PlaybackSpeed = math.clamp(0.98 + intensity * 0.18, 0.98, 1.24)
	elseif category == "GhostAudio" then
		sound.PlaybackSpeed = math.clamp(0.98 + intensity * 0.1, 0.95, 1.18)
	else
		sound.PlaybackSpeed = math.clamp(0.98 + intensity * 0.06, 0.92, 1.1)
	end
	if cueProfile and tonumber(cueProfile.playbackSpeed) then
		sound.PlaybackSpeed = math.clamp(sound.PlaybackSpeed * tonumber(cueProfile.playbackSpeed), 0.82, 1.28)
	end
	if SPATIAL_SOUND_CATEGORIES[category] == true then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 8
		sound.RollOffMaxDistance = category == "GhostAudio" and 55 or 48
		sound.EmitterSize = category == "GhostAudio" and 7 or 5
	end
end

function SoundSystem:_stopActiveSound(category)
	local sound = self._activeSounds[category]
	if sound and sound.Parent then
		sound:Stop()
		sound:Destroy()
	end
	self._activeSounds[category] = nil
	local emitterPart = self._activeSpatialEmitters[category]
	if emitterPart and emitterPart.Parent then
		emitterPart:Destroy()
	end
	self._activeSpatialEmitters[category] = nil
end

function SoundSystem:_stopAllAudio()
	for category in pairs(self._activeSounds) do
		self:_stopActiveSound(category)
	end
end

function SoundSystem:_playLoopedCategory(category, template, payload)
	local active = self._activeSounds[category]
	if active and active.Parent and active.SoundId == template.SoundId then
		self:_applySoundProfile(active, category, payload)
		self:_recordAudioDebug(category, active, payload)
		if not active.IsPlaying then
			active:Play()
		end
		return
	end

	self:_stopActiveSound(category)

	local playbackTarget = self:_resolvePlaybackTarget(category, payload)
	local runtimeSound = template:Clone()
	runtimeSound.Name = category .. "Runtime"
	runtimeSound.Looped = true
	runtimeSound.Parent = playbackTarget.parent
	runtimeSound:SetAttribute("PasrahSpatialMode", playbackTarget.spatialMode)
	runtimeSound:SetAttribute("PasrahAudioSourcePosition", playbackTarget.sourcePosition)
	self:_applySoundProfile(runtimeSound, category, payload)
	self:_recordAudioDebug(category, runtimeSound, payload)
	runtimeSound:Play()
	self._activeSounds[category] = runtimeSound
	self._activeSpatialEmitters[category] = playbackTarget.emitterPart
end

function SoundSystem:_playOneShotCategory(category, template, payload)
	local dedupeWindow = ONESHOT_DEDUPE_WINDOW_SECONDS[category]
	if dedupeWindow and dedupeWindow > 0 then
		local cueToken = tostring(payload and payload.cue or template.SoundId or "")
		local dedupeKey = string.format("%s::%s", tostring(category), cueToken)
		local now = tick()
		local lastAt = self._lastOneShotAtByKey[dedupeKey]
		if lastAt and (now - lastAt) < dedupeWindow then
			return
		end
		self._lastOneShotAtByKey[dedupeKey] = now
	end

	local runtimeSound = template:Clone()
	runtimeSound.Name = category .. "Runtime"
	runtimeSound.Looped = false
	local playbackTarget = self:_resolvePlaybackTarget(category, payload)
	runtimeSound.Parent = playbackTarget.parent
	runtimeSound:SetAttribute("PasrahSpatialMode", playbackTarget.spatialMode)
	runtimeSound:SetAttribute("PasrahAudioSourcePosition", playbackTarget.sourcePosition)
	self:_applySoundProfile(runtimeSound, category, payload)
	self:_recordAudioDebug(category, runtimeSound, payload)
	runtimeSound.Ended:Connect(function()
		if runtimeSound.Parent then
			runtimeSound:Destroy()
		end
		if playbackTarget.emitterPart and playbackTarget.emitterPart.Parent then
			playbackTarget.emitterPart:Destroy()
		end
	end)
	runtimeSound:Play()
	if playbackTarget.emitterPart then
		Debris:AddItem(playbackTarget.emitterPart, math.max(runtimeSound.TimeLength + 1, 6))
	end
	Debris:AddItem(runtimeSound, math.max(runtimeSound.TimeLength + 1, 6))
end

function SoundSystem:_playCategoryAudio(category, payload)
	local template = self:_getTemplateForCategory(category, payload)
	if not template then
		return
	end
	if LOOPED_CATEGORIES[category] then
		self:_playLoopedCategory(category, template, payload)
		return
	end
	self:_playOneShotCategory(category, template, payload)
end

return setmetatable({}, SoundSystem)
