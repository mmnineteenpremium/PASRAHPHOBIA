local SpectatorSystem = {}
SpectatorSystem.__index = SpectatorSystem

local PROBABILITIES = {
	fake = 0.60,
	uncertain = 0.30,
	real = 0.10,
}

function SpectatorSystem:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._isSpectating = false
	self._cameraTarget = nil
	self._distortionState = "none"
end

function SpectatorSystem:Start()
	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end
end

function SpectatorSystem:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	if eventName == "PlayerKilled" and payload.localPlayerKilled == true then
		self:EnterSpectatorMode(payload)
	elseif eventName == "PlayerRespawned" and payload.localPlayerRespawned == true then
		self:ExitSpectatorMode()
	elseif eventName == "MatchEnded" then
		self:ExitSpectatorMode()
	end
end

function SpectatorSystem:EnterSpectatorMode(payload)
	self._isSpectating = true
	self._cameraTarget = payload and payload.targetPlayer
	self._distortionState = "active"

	local renderer = self._context.Registry:Get("GhostRenderer")
	if renderer and renderer.SetSpectatorMode then
		renderer:SetSpectatorMode(true)
	end
end

function SpectatorSystem:ExitSpectatorMode()
	self._isSpectating = false
	self._cameraTarget = nil
	self._distortionState = "none"

	local renderer = self._context.Registry:Get("GhostRenderer")
	if renderer and renderer.SetSpectatorMode then
		renderer:SetSpectatorMode(false)
	end
end

function SpectatorSystem:GetGhostProbability()
	return PROBABILITIES
end

function SpectatorSystem:GetState()
	return {
		isSpectating = self._isSpectating,
		cameraTarget = self._cameraTarget,
		distortionState = self._distortionState,
		probability = PROBABILITIES,
	}
end

return setmetatable({}, SpectatorSystem)
