local SpectatorCommunication = {}
SpectatorCommunication.__index = SpectatorCommunication

function SpectatorCommunication.new(state, deps, config)
	local self = setmetatable({}, SpectatorCommunication)
	self._state = state
	self._deps = deps or {}
	self._config = config or {}
	return self
end

function SpectatorCommunication:EnsureSession(matchId)
	local communicationByMatch = self._state:Get("communicationByMatch") or {}
	local session = communicationByMatch[matchId]
	if session then
		return session
	end

	session = {
		voicePolicyByUserId = {},
		lastOutcomeByUserId = {},
	}
	communicationByMatch[matchId] = session
	self._state:Set("communicationByMatch", communicationByMatch)
	return session
end

function SpectatorCommunication:RemoveSession(matchId)
	local communicationByMatch = self._state:Get("communicationByMatch") or {}
	communicationByMatch[matchId] = nil
	self._state:Set("communicationByMatch", communicationByMatch)
end

function SpectatorCommunication:RegisterSpectator(matchId, spectatorUserId)
	local session = self:EnsureSession(matchId)
	session.voicePolicyByUserId[spectatorUserId] = {
		canSpeakToAlive = true,
		isBlocked = false,
	}
end

function SpectatorCommunication:UnregisterSpectator(matchId, spectatorUserId)
	local session = self:EnsureSession(matchId)
	session.voicePolicyByUserId[spectatorUserId] = nil
	session.lastOutcomeByUserId[spectatorUserId] = nil
end

function SpectatorCommunication:RecordVisionOutcome(matchId, spectatorUserId, outcome)
	local session = self:EnsureSession(matchId)
	session.lastOutcomeByUserId[spectatorUserId] = outcome
end

function SpectatorCommunication:CanTransmitVoice(matchId, spectatorUserId)
	local session = self:EnsureSession(matchId)
	local policy = session.voicePolicyByUserId[spectatorUserId]
	if not policy then
		return false
	end
	return policy.canSpeakToAlive == true and policy.isBlocked ~= true
end

function SpectatorCommunication:GetCommunicationContext(matchId, spectatorUserId)
	local session = self:EnsureSession(matchId)
	local outcome = session.lastOutcomeByUserId[spectatorUserId]
	local canTransmit = self:CanTransmitVoice(matchId, spectatorUserId)

	return {
		canTransmitVoice = canTransmit,
		-- Spectators can mislead through distorted vision. Voice is always allowed.
		distortionHint = outcome or "unknown",
		isLikelyMisleading = outcome == "fake" or outcome == "uncertain",
	}
end

return SpectatorCommunication
