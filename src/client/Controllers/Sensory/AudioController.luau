local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local MAP_REVERB = {
	LobbySocialHub = Enum.ReverbType.Room,
	AbandonedPalace = Enum.ReverbType.StoneRoom,
	EmptyBuilding = Enum.ReverbType.Hallway,
	HauntedHouse = Enum.ReverbType.StoneCorridor,
	StudioMMNineteen = Enum.ReverbType.PaddedCell,
}

local PREPARATION_AMBIENT_PROFILE = {
	HauntedHouse = {
		Volume = 0.18,
		PlaybackSpeed = 0.94,
	},
	AbandonedPalace = {
		Volume = 0.24,
		PlaybackSpeed = 0.88,
	},
	EmptyBuilding = {
		Volume = 0.16,
		PlaybackSpeed = 1.0,
	},
	StudioMMNineteen = {
		Volume = 0.15,
		PlaybackSpeed = 0.98,
	},
}

local LOBBY_AMBIENT_SOUND_ID = "rbxassetid://113854211240490"
local LOBBY_AMBIENT_PROFILE = {
	Volume = 0.16,
	PlaybackSpeed = 0.98,
}

local RESULTS_BGM_SOUND_ID = "rbxassetid://95027410279438"
local RESULTS_BGM_PROFILE = {
	Volume = 0.2,
	PlaybackSpeed = 1.0,
	HoldSeconds = 6,
}

local PREPARATION_AMBIENT_TWEEN_IN = TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local PREPARATION_AMBIENT_TWEEN_OUT = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local LOBBY_AMBIENT_TWEEN_IN = TweenInfo.new(0.72, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local LOBBY_AMBIENT_TWEEN_OUT = TweenInfo.new(0.48, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local RESULTS_BGM_TWEEN_IN = TweenInfo.new(0.42, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local RESULTS_BGM_TWEEN_OUT = TweenInfo.new(0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local HEARTBEAT_SPEED_RANGE = {
	min = 1.0,
	max = 1.8,
}

local AudioController = {}
AudioController.__index = AudioController

local function normalizePhaseToken(payload)
	local token = tostring(
		(payload and payload.matchPhase)
			or (payload and payload.lifecyclePhase)
			or (payload and payload.phase)
			or (payload and payload.phaseName)
			or ""
	)
	return token:gsub("[%s_%-_]+", ""):lower()
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

local function lookupHeartbeatSound()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local audioFolder = assets and assets:FindFirstChild("Audio")
	local sensoryFolder = audioFolder and audioFolder:FindFirstChild("Sensory")
	if sensoryFolder then
		local heartbeat = sensoryFolder:FindFirstChild("Heartbeat")
		if heartbeat and heartbeat:IsA("Sound") then
			return heartbeat:Clone()
		end
	end
	local fallback = Instance.new("Sound")
	fallback.Name = "Heartbeat"
	return fallback
end

local function lookupPreparationAmbientSound()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local audioFolder = assets and assets:FindFirstChild("Audio")
	local ambientFolder = audioFolder and audioFolder:FindFirstChild("Ambient")
	if ambientFolder then
		local ambientLoop = ambientFolder:FindFirstChild("AmbientLoop_Main")
		if ambientLoop and ambientLoop:IsA("Sound") then
			local clone = ambientLoop:Clone()
			if tostring(clone.SoundId or "") ~= "" then
				clone.Name = "PreparationAmbient"
				return clone
			end
		end
	end

	local environmentFolder = audioFolder and audioFolder:FindFirstChild("Environment")
	if environmentFolder then
		local environmentalBed = environmentFolder:FindFirstChild("EnvironmentalCreak_01")
		if environmentalBed and environmentalBed:IsA("Sound") then
			local clone = environmentalBed:Clone()
			clone.Name = "PreparationAmbient"
			return clone
		end
	end
	local fallback = Instance.new("Sound")
	fallback.Name = "PreparationAmbient"
	return fallback
end

local function lookupLobbyAmbientSound()
	local sound = Instance.new("Sound")
	sound.Name = "LobbyAmbient"
	sound.SoundId = LOBBY_AMBIENT_SOUND_ID
	return sound
end

local function lookupResultsBgmSound()
	local sound = Instance.new("Sound")
	sound.Name = "ResultsBGM"
	sound.SoundId = RESULTS_BGM_SOUND_ID
	return sound
end

local function stampManagedAudioIdentity(sound, owner, category, cue, eventType)
	if typeof(sound) ~= "Instance" or not sound:IsA("Sound") then
		return
	end
	sound:SetAttribute("PasrahAudioOwner", tostring(owner or "AudioController"))
	sound:SetAttribute("PasrahAudioCategory", tostring(category or ""))
	sound:SetAttribute("PasrahAudioCue", tostring(cue or ""))
	sound:SetAttribute("PasrahAudioEventType", tostring(eventType or ""))
	sound:SetAttribute("PasrahAudioTemplate", sound.Name)
	sound:SetAttribute("PasrahAudioSoundId", tostring(sound.SoundId or ""))
	sound:SetAttribute("PasrahAudioLooped", sound.Looped == true)
end

function AudioController:Init(context)
	self._context = context or {}
	self._remotes = self._context.Remotes or {}
	self._connections = {}
	self._player = Players.LocalPlayer
	self._currentSanity = 100
	self._ghostHuntActive = false
	self._preparationAmbientTargetVolume = 0
	self._preparationAmbientTween = nil
	self._lobbyAmbientTargetVolume = 0
	self._lobbyAmbientTween = nil
	self._resultsBgmTargetVolume = 0
	self._resultsBgmTween = nil
	self._resultsBgmHoldActive = false
	self._resultsBgmHoldToken = 0

	self._heartbeatSound = lookupHeartbeatSound()
	self._heartbeatSound.Looped = true
	self._heartbeatSound.Volume = 0
	stampManagedAudioIdentity(self._heartbeatSound, "AudioController", "FearAudio", "heartbeat_rise", "HeartbeatLoop")
	self._heartbeatSound:SetAttribute("MissingSourceAsset", self._heartbeatSound.SoundId == "")

	self._preparationAmbientSound = lookupPreparationAmbientSound()
	self._preparationAmbientSound.Looped = true
	self._preparationAmbientSound.Volume = 0
	stampManagedAudioIdentity(self._preparationAmbientSound, "AudioController", "AmbientAudio", "ambient_investigation", "PreparationAmbientLoop")
	self._preparationAmbientSound:SetAttribute("MissingSourceAsset", self._preparationAmbientSound.SoundId == "")

	self._lobbyAmbientSound = lookupLobbyAmbientSound()
	self._lobbyAmbientSound.Looped = true
	self._lobbyAmbientSound.Volume = 0
	self._lobbyAmbientSound.PlaybackSpeed = LOBBY_AMBIENT_PROFILE.PlaybackSpeed
	stampManagedAudioIdentity(self._lobbyAmbientSound, "AudioController", "AmbientAudio", "bgm_lobby_ambient", "LobbyAmbientLoop")
	self._lobbyAmbientSound:SetAttribute("MissingSourceAsset", self._lobbyAmbientSound.SoundId == "")

	self._resultsBgmSound = lookupResultsBgmSound()
	self._resultsBgmSound.Looped = true
	self._resultsBgmSound.Volume = 0
	self._resultsBgmSound.PlaybackSpeed = RESULTS_BGM_PROFILE.PlaybackSpeed
	stampManagedAudioIdentity(self._resultsBgmSound, "AudioController", "ResultsAudio", "bgm_gameover", "ResultsBGMLoop")
	self._resultsBgmSound:SetAttribute("MissingSourceAsset", self._resultsBgmSound.SoundId == "")

	self._heartbeatSound.Parent = SoundService
	self._preparationAmbientSound.Parent = SoundService
	self._lobbyAmbientSound.Parent = SoundService
	self._resultsBgmSound.Parent = SoundService
end

function AudioController:Start()
	local sanityEvent = self._remotes.SanityEvent
	if sanityEvent and sanityEvent.OnClientEvent then
		table.insert(self._connections, sanityEvent.OnClientEvent:Connect(function(payload)
			self:_onSanityEvent(payload)
		end))
	end

	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end

	local localPlayer = self._player or Players.LocalPlayer
	if localPlayer then
		table.insert(self._connections, localPlayer:GetAttributeChangedSignal("InMatch"):Connect(function()
			if localPlayer:GetAttribute("InMatch") == true then
				self:_clearResultsBgmHold()
			end
			self:_syncMapReverbFromPlayerState()
			self:_updatePreparationAmbient()
			self:_updateLobbyAmbient()
			self:_updateResultsBgm()
		end))
		table.insert(self._connections, localPlayer:GetAttributeChangedSignal("MatchMapId"):Connect(function()
			self:_syncMapReverbFromPlayerState()
			self:_updatePreparationAmbient()
			self:_updateLobbyAmbient()
		end))
		table.insert(self._connections, localPlayer:GetAttributeChangedSignal("MapName"):Connect(function()
			self:_syncMapReverbFromPlayerState()
			self:_updatePreparationAmbient()
			self:_updateLobbyAmbient()
		end))
		table.insert(self._connections, localPlayer:GetAttributeChangedSignal("MatchLifecyclePhase"):Connect(function()
			self:_updatePreparationAmbient()
			self:_updateLobbyAmbient()
			self:_updateResultsBgm()
		end))
	end

	self:_syncMapReverbFromPlayerState()
	self:_updatePreparationAmbient()
	self:_updateLobbyAmbient()
	self:_updateResultsBgm()
end

function AudioController:Stop()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
	self._connections = {}

	if self._preparationAmbientTween then
		self._preparationAmbientTween:Cancel()
		self._preparationAmbientTween = nil
	end
	if self._lobbyAmbientTween then
		self._lobbyAmbientTween:Cancel()
		self._lobbyAmbientTween = nil
	end
	if self._resultsBgmTween then
		self._resultsBgmTween:Cancel()
		self._resultsBgmTween = nil
	end

	if self._heartbeatSound and self._heartbeatSound.Parent then
		self._heartbeatSound:Stop()
	end
	if self._preparationAmbientSound and self._preparationAmbientSound.Parent then
		self._preparationAmbientSound:Stop()
	end
	if self._lobbyAmbientSound and self._lobbyAmbientSound.Parent then
		self._lobbyAmbientSound:Stop()
	end
	if self._resultsBgmSound and self._resultsBgmSound.Parent then
		self._resultsBgmSound:Stop()
	end

	local localPlayer = self._player or Players.LocalPlayer
	if localPlayer then
		localPlayer:SetAttribute("PasrahHeartbeatActive", nil)
		localPlayer:SetAttribute("PasrahHeartbeatSoundId", nil)
		localPlayer:SetAttribute("PasrahHeartbeatPlaybackSpeed", nil)
		localPlayer:SetAttribute("PasrahHeartbeatReason", nil)
		localPlayer:SetAttribute("PasrahPreparationAmbientActive", nil)
		localPlayer:SetAttribute("PasrahPreparationAmbientSoundId", nil)
		localPlayer:SetAttribute("PasrahPreparationAmbientMap", nil)
		localPlayer:SetAttribute("PasrahPreparationAmbientPlaybackSpeed", nil)
		localPlayer:SetAttribute("PasrahLobbyAmbientActive", nil)
		localPlayer:SetAttribute("PasrahLobbyAmbientSoundId", nil)
		localPlayer:SetAttribute("PasrahLobbyAmbientMap", nil)
		localPlayer:SetAttribute("PasrahResultsBgmActive", nil)
		localPlayer:SetAttribute("PasrahResultsBgmSoundId", nil)
	end
end

function AudioController:_tweenPreparationAmbient(targetVolume, tweenInfo, stopAfterFade)
	if not self._preparationAmbientSound then
		return
	end

	if self._preparationAmbientTween then
		self._preparationAmbientTween:Cancel()
		self._preparationAmbientTween = nil
	end

	self._preparationAmbientTargetVolume = targetVolume
	local tween = TweenService:Create(self._preparationAmbientSound, tweenInfo or PREPARATION_AMBIENT_TWEEN_IN, {
		Volume = targetVolume,
	})
	self._preparationAmbientTween = tween
	tween.Completed:Connect(function(playbackState)
		if self._preparationAmbientTween == tween then
			self._preparationAmbientTween = nil
		end
		if stopAfterFade and playbackState == Enum.PlaybackState.Completed then
			if self._preparationAmbientSound and self._preparationAmbientSound.Volume <= 0.001 then
				self._preparationAmbientSound:Stop()
			end
		end
	end)
	tween:Play()
end

function AudioController:_tweenLobbyAmbient(targetVolume, tweenInfo, stopAfterFade)
	if not self._lobbyAmbientSound then
		return
	end

	if self._lobbyAmbientTween then
		self._lobbyAmbientTween:Cancel()
		self._lobbyAmbientTween = nil
	end

	self._lobbyAmbientTargetVolume = targetVolume
	local tween = TweenService:Create(self._lobbyAmbientSound, tweenInfo or LOBBY_AMBIENT_TWEEN_IN, {
		Volume = targetVolume,
	})
	self._lobbyAmbientTween = tween
	tween.Completed:Connect(function(playbackState)
		if self._lobbyAmbientTween == tween then
			self._lobbyAmbientTween = nil
		end
		if stopAfterFade and playbackState == Enum.PlaybackState.Completed then
			if self._lobbyAmbientSound and self._lobbyAmbientSound.Volume <= 0.001 then
				self._lobbyAmbientSound:Stop()
			end
		end
	end)
	tween:Play()
end

function AudioController:_tweenResultsBgm(targetVolume, tweenInfo, stopAfterFade)
	if not self._resultsBgmSound then
		return
	end

	if self._resultsBgmTween then
		self._resultsBgmTween:Cancel()
		self._resultsBgmTween = nil
	end

	self._resultsBgmTargetVolume = targetVolume
	local tween = TweenService:Create(self._resultsBgmSound, tweenInfo or RESULTS_BGM_TWEEN_IN, {
		Volume = targetVolume,
	})
	self._resultsBgmTween = tween
	tween.Completed:Connect(function(playbackState)
		if self._resultsBgmTween == tween then
			self._resultsBgmTween = nil
		end
		if stopAfterFade and playbackState == Enum.PlaybackState.Completed then
			if self._resultsBgmSound and self._resultsBgmSound.Volume <= 0.001 then
				self._resultsBgmSound:Stop()
			end
		end
	end)
	tween:Play()
end

function AudioController:_applyMapReverb(mapName)
	local desired = MAP_REVERB[mapName] or Enum.ReverbType.Room
	if SoundService.AmbientReverb ~= desired then
		SoundService.AmbientReverb = desired
	end
	local localPlayer = self._player or Players.LocalPlayer
	if localPlayer then
		localPlayer:SetAttribute("PasrahAudioMapProfile", tostring(mapName or ""))
		localPlayer:SetAttribute("PasrahAudioReverb", tostring(desired))
	end
end

function AudioController:_resolveAuthoritativeMapProfile()
	local localPlayer = self._player or Players.LocalPlayer
	if not localPlayer or localPlayer:GetAttribute("InMatch") ~= true then
		return "LobbySocialHub"
	end

	local mapName = normalizeMapProfileName(localPlayer:GetAttribute("MatchMapId"))
		or normalizeMapProfileName(localPlayer:GetAttribute("MapName"))
	return mapName or "HauntedHouse"
end

function AudioController:_syncMapReverbFromPlayerState()
	self:_applyMapReverb(self:_resolveAuthoritativeMapProfile())
end

function AudioController:_clearResultsBgmHold()
	self._resultsBgmHoldToken += 1
	self._resultsBgmHoldActive = false
	self:_updateResultsBgm()
	self:_updateLobbyAmbient()
end

function AudioController:_armResultsBgmHold(seconds)
	self._resultsBgmHoldToken += 1
	local holdToken = self._resultsBgmHoldToken
	self._resultsBgmHoldActive = true
	self:_updateResultsBgm()
	self:_updateLobbyAmbient()
	task.delay(seconds or RESULTS_BGM_PROFILE.HoldSeconds, function()
		if self._resultsBgmHoldToken ~= holdToken then
			return
		end
		self._resultsBgmHoldActive = false
		self:_updateResultsBgm()
		self:_updateLobbyAmbient()
	end)
end

function AudioController:_onSanityEvent(payload)
	local sanity = tonumber((payload and payload.newSanity) or (payload and payload.sanity) or payload) or 100
	self._currentSanity = math.clamp(sanity, 0, 100)
	self:_updateHeartbeat()
end

function AudioController:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	if not eventName then
		return
	end

	if eventName == "MatchStarted" then
		self:_clearResultsBgmHold()
		local mapName = normalizeMapProfileName((payload and payload.mapName) or (payload and payload.mapId) or (payload and payload.map) or payload.mapType)
		self:_applyMapReverb(mapName or self:_resolveAuthoritativeMapProfile())
	elseif eventName == "PhaseChanged" then
		local phaseToken = normalizePhaseToken(payload)
		if phaseToken ~= "result" and phaseToken ~= "end" then
			self:_clearResultsBgmHold()
		end
		local mapName = normalizeMapProfileName((payload and payload.mapName) or (payload and payload.mapId) or (payload and payload.map) or payload.mapType)
		if mapName then
			self:_applyMapReverb(mapName)
		elseif phaseToken == "lobby" then
			self:_applyMapReverb("LobbySocialHub")
		else
			self:_syncMapReverbFromPlayerState()
		end
		if phaseToken == "hunt" or phaseToken == "huntphase" then
			self._ghostHuntActive = true
			self:_updateHeartbeat()
		elseif phaseToken == "investigation" or phaseToken == "investigationphase"
			or phaseToken == "preparation" or phaseToken == "preparationphase"
			or phaseToken == "endgame" or phaseToken == "endgamephase"
			or phaseToken == "result" or phaseToken == "end" then
			self._ghostHuntActive = false
			self:_updateHeartbeat()
		end
	elseif eventName == "HuntStarted" or eventName == "GhostHuntStarted" then
		self._ghostHuntActive = true
		self:_updateHeartbeat()
	elseif eventName == "HuntEnded" or eventName == "GhostHuntEnded" then
		self._ghostHuntActive = false
		self:_updateHeartbeat()
	elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
		self._ghostHuntActive = false
		self:_syncMapReverbFromPlayerState()
		self:_updateHeartbeat()
		self:_armResultsBgmHold(RESULTS_BGM_PROFILE.HoldSeconds)
	elseif eventName == "ReturnedToLobby" or eventName == "LobbyEntered" then
		self:_clearResultsBgmHold()
	end

	self:_updatePreparationAmbient()
	self:_updateLobbyAmbient()
	self:_updateResultsBgm()
end

function AudioController:_updateHeartbeat()
	if not self._heartbeatSound then
		return
	end
	local localPlayer = self._player or Players.LocalPlayer
	if self._heartbeatSound.SoundId == "" then
		if localPlayer then
			localPlayer:SetAttribute("PasrahHeartbeatActive", nil)
			localPlayer:SetAttribute("PasrahHeartbeatSoundId", nil)
			localPlayer:SetAttribute("PasrahHeartbeatPlaybackSpeed", nil)
			localPlayer:SetAttribute("PasrahHeartbeatReason", nil)
		end
		return
	end

	local needsHeartbeat = self._ghostHuntActive or self._currentSanity < 40
	local heartbeatReason = nil
	if self._ghostHuntActive then
		heartbeatReason = "HUNT"
	elseif self._currentSanity < 40 then
		heartbeatReason = "SANITY_LOW"
	end
	if needsHeartbeat then
		local intensity = math.clamp(1 - (self._currentSanity / 40), 0, 1)
		self._heartbeatSound.Volume = math.max(0.2, intensity)
		self._heartbeatSound.PlaybackSpeed = math.clamp(
			HEARTBEAT_SPEED_RANGE.min + intensity * (HEARTBEAT_SPEED_RANGE.max - HEARTBEAT_SPEED_RANGE.min),
			HEARTBEAT_SPEED_RANGE.min,
			HEARTBEAT_SPEED_RANGE.max
		)
		if not self._heartbeatSound.IsPlaying then
			self._heartbeatSound:Play()
		end
		self._heartbeatSound:SetAttribute("PasrahHeartbeatReason", heartbeatReason)
		if localPlayer then
			localPlayer:SetAttribute("PasrahHeartbeatActive", true)
			localPlayer:SetAttribute("PasrahHeartbeatSoundId", tostring(self._heartbeatSound.SoundId or ""))
			localPlayer:SetAttribute("PasrahHeartbeatPlaybackSpeed", self._heartbeatSound.PlaybackSpeed)
			localPlayer:SetAttribute("PasrahHeartbeatReason", heartbeatReason)
		end
	else
		if self._heartbeatSound.IsPlaying then
			self._heartbeatSound:Stop()
		end
		self._heartbeatSound:SetAttribute("PasrahHeartbeatReason", nil)
		if localPlayer then
			localPlayer:SetAttribute("PasrahHeartbeatActive", nil)
			localPlayer:SetAttribute("PasrahHeartbeatSoundId", nil)
			localPlayer:SetAttribute("PasrahHeartbeatPlaybackSpeed", nil)
			localPlayer:SetAttribute("PasrahHeartbeatReason", nil)
		end
	end
end

function AudioController:_updatePreparationAmbient()
	if not self._preparationAmbientSound or self._preparationAmbientSound.SoundId == "" then
		return
	end

	local localPlayer = self._player or Players.LocalPlayer
	local inMatch = localPlayer and localPlayer:GetAttribute("InMatch") == true
	local lifecyclePhase = tostring(localPlayer and localPlayer:GetAttribute("MatchLifecyclePhase") or "")
	local mapProfile = self:_resolveAuthoritativeMapProfile()
	local profile = PREPARATION_AMBIENT_PROFILE[mapProfile] or PREPARATION_AMBIENT_PROFILE.HauntedHouse
	local shouldPlay = inMatch and lifecyclePhase == "PreparationPhase"

	if localPlayer then
		localPlayer:SetAttribute("PasrahPreparationAmbientActive", shouldPlay and true or nil)
		localPlayer:SetAttribute("PasrahPreparationAmbientSoundId", shouldPlay and tostring(self._preparationAmbientSound.SoundId or "") or nil)
		localPlayer:SetAttribute("PasrahPreparationAmbientMap", shouldPlay and tostring(mapProfile or "") or nil)
		localPlayer:SetAttribute("PasrahPreparationAmbientPlaybackSpeed", shouldPlay and profile.PlaybackSpeed or nil)
	end

	if shouldPlay then
		self._preparationAmbientSound.PlaybackSpeed = profile.PlaybackSpeed
		self._preparationAmbientSound:SetAttribute("PasrahAudioMapProfile", tostring(mapProfile or ""))
		if not self._preparationAmbientSound.IsPlaying then
			self._preparationAmbientSound.Volume = 0
			self._preparationAmbientSound:Play()
		end
		if math.abs(self._preparationAmbientTargetVolume - profile.Volume) > 0.001 or not self._preparationAmbientTween then
			self:_tweenPreparationAmbient(profile.Volume, PREPARATION_AMBIENT_TWEEN_IN, false)
		end
	else
		self._preparationAmbientSound:SetAttribute("PasrahAudioMapProfile", nil)
		if self._preparationAmbientSound.IsPlaying or self._preparationAmbientSound.Volume > 0.001 then
			self:_tweenPreparationAmbient(0, PREPARATION_AMBIENT_TWEEN_OUT, true)
		end
	end
end

function AudioController:_isResultsSurfaceVisible()
	local localPlayer = self._player or Players.LocalPlayer
	local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return false
	end

	local resultsPanel = playerGui:FindFirstChild("ResultsPanel", true)
	return resultsPanel ~= nil and resultsPanel:IsA("GuiObject") and resultsPanel.Visible == true
end

function AudioController:_updateLobbyAmbient()
	if not self._lobbyAmbientSound or self._lobbyAmbientSound.SoundId == "" then
		return
	end

	local localPlayer = self._player or Players.LocalPlayer
	local inMatch = localPlayer and localPlayer:GetAttribute("InMatch") == true
	local mapProfile = self:_resolveAuthoritativeMapProfile()
	local resultsSurfaceVisible = self:_isResultsSurfaceVisible()
	local shouldPlay = (not inMatch)
		and mapProfile == "LobbySocialHub"
		and self._resultsBgmHoldActive ~= true
		and resultsSurfaceVisible ~= true

	if localPlayer then
		localPlayer:SetAttribute("PasrahLobbyAmbientActive", shouldPlay and true or nil)
		localPlayer:SetAttribute("PasrahLobbyAmbientSoundId", shouldPlay and tostring(self._lobbyAmbientSound.SoundId or "") or nil)
		localPlayer:SetAttribute("PasrahLobbyAmbientMap", shouldPlay and tostring(mapProfile or "") or nil)
		localPlayer:SetAttribute("PasrahLobbyAmbientSuppressedByResults", resultsSurfaceVisible and true or nil)
	end

	if shouldPlay then
		self._lobbyAmbientSound.PlaybackSpeed = LOBBY_AMBIENT_PROFILE.PlaybackSpeed
		self._lobbyAmbientSound:SetAttribute("PasrahAudioMapProfile", tostring(mapProfile or ""))
		if not self._lobbyAmbientSound.IsPlaying then
			self._lobbyAmbientSound.Volume = 0
			self._lobbyAmbientSound:Play()
		end
		if math.abs(self._lobbyAmbientTargetVolume - LOBBY_AMBIENT_PROFILE.Volume) > 0.001 or not self._lobbyAmbientTween then
			self:_tweenLobbyAmbient(LOBBY_AMBIENT_PROFILE.Volume, LOBBY_AMBIENT_TWEEN_IN, false)
		end
	else
		self._lobbyAmbientSound:SetAttribute("PasrahAudioMapProfile", nil)
		if self._lobbyAmbientSound.IsPlaying or self._lobbyAmbientSound.Volume > 0.001 then
			self:_tweenLobbyAmbient(0, LOBBY_AMBIENT_TWEEN_OUT, true)
		end
	end
end

function AudioController:_updateResultsBgm()
	if not self._resultsBgmSound then
		return
	end

	local localPlayer = self._player or Players.LocalPlayer
	if self._resultsBgmSound.SoundId == "" then
		if localPlayer then
			localPlayer:SetAttribute("PasrahResultsBgmActive", nil)
			localPlayer:SetAttribute("PasrahResultsBgmSoundId", nil)
		end
		return
	end

	local shouldPlay = self._resultsBgmHoldActive == true or self:_isResultsSurfaceVisible()
	if localPlayer then
		localPlayer:SetAttribute("PasrahResultsBgmActive", shouldPlay and true or nil)
		localPlayer:SetAttribute("PasrahResultsBgmSoundId", shouldPlay and tostring(self._resultsBgmSound.SoundId or "") or nil)
	end

	if shouldPlay then
		self._resultsBgmSound.PlaybackSpeed = RESULTS_BGM_PROFILE.PlaybackSpeed
		if not self._resultsBgmSound.IsPlaying then
			self._resultsBgmSound.Volume = 0
			self._resultsBgmSound:Play()
		end
		if math.abs(self._resultsBgmTargetVolume - RESULTS_BGM_PROFILE.Volume) > 0.001 or not self._resultsBgmTween then
			self:_tweenResultsBgm(RESULTS_BGM_PROFILE.Volume, RESULTS_BGM_TWEEN_IN, false)
		end
	else
		if self._resultsBgmSound.IsPlaying or self._resultsBgmSound.Volume > 0.001 then
			self:_tweenResultsBgm(0, RESULTS_BGM_TWEEN_OUT, true)
		end
	end
end

return setmetatable({}, AudioController)
