local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MAP_REVERB = {
	AbandonedPalace = Enum.ReverbType.StoneRoom,
	HauntedHouse = Enum.ReverbType.StoneCorridor,
	StudioMMNineteen = Enum.ReverbType.PaddedCell,
}

local HEARTBEAT_SPEED_RANGE = {
	min = 1.0,
	max = 1.8,
}

local AudioController = {}
AudioController.__index = AudioController

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
	fallback.SoundId = "rbxassetid://YOUR_HEARTBEAT_ID"
	return fallback
end

function AudioController:Init(context)
	self._context = context or {}
	self._remotes = self._context.Remotes or {}
	self._connections = {}
	self._player = Players.LocalPlayer
	self._currentSanity = 100
	self._ghostHuntActive = false
	self._heartbeatSound = lookupHeartbeatSound()
	self._heartbeatSound.Looped = true
	self._heartbeatSound.Volume = 0
	local camera = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")
	self._heartbeatSound.Parent = camera or Workspace
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
end

function AudioController:Stop()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
	self._connections = {}

	if self._heartbeatSound and self._heartbeatSound.Parent then
		self._heartbeatSound:Stop()
	end
end

function AudioController:_applyMapReverb(mapName)
	local desired = MAP_REVERB[mapName] or Enum.ReverbType.Room
	if SoundService.AmbientReverb ~= desired then
		SoundService.AmbientReverb = desired
	end
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
		local mapName = (payload and payload.mapName) or (payload and payload.map) or payload.mapType or "Unknown"
		self:_applyMapReverb(mapName)
	elseif eventName == "HuntStarted" or eventName == "GhostHuntStarted" then
		self._ghostHuntActive = true
		self:_updateHeartbeat()
	elseif eventName == "HuntEnded" or eventName == "GhostHuntEnded" then
		self._ghostHuntActive = false
		self:_updateHeartbeat()
	end
end

function AudioController:_updateHeartbeat()
	if not self._heartbeatSound then
		return
	end

	local needsHeartbeat = self._ghostHuntActive or self._currentSanity < 40
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
	else
		if self._heartbeatSound.IsPlaying then
			self._heartbeatSound:Stop()
		end
	end
end

return setmetatable({}, AudioController)
