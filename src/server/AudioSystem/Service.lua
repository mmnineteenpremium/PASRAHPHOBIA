local Service = {}
Service.__index = Service

local DEFAULT_COOLDOWNS = {
	AmbientAudio = 10,
	EnvironmentalAudio = 3,
	FearAudio = 4,
	GhostAudio = 4,
	HuntAudio = 2,
}

local function resolveEventBus(deps)
	local eventBus = deps.EventBus
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Publish) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
		return eventBus.Service
	end
	return nil
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._rng = self._deps.Random or Random.new()
	self._cooldowns = self._deps.AudioCooldowns or DEFAULT_COOLDOWNS
	return self
end

function Service:Init()
	self._state:Set("sessions", {})
end

function Service:Start()
	-- Event-driven audio orchestration only.
end

function Service:Stop()
	self._state:Set("sessions", {})
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_sessions()
	return self._state:Get("sessions") or {}
end

function Service:_setSessions(sessions)
	self._state:Set("sessions", sessions)
end

function Service:_getOrCreateSession(matchId)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if session then
		return session
	end
	session = {
		matchId = matchId,
		nextAllowedAt = {},
	}
	sessions[matchId] = session
	self:_setSessions(sessions)
	return session
end

function Service:StartMatch(matchId)
	return self:_getOrCreateSession(matchId)
end

function Service:EndMatch(matchId)
	local sessions = self:_sessions()
	sessions[matchId] = nil
	self:_setSessions(sessions)
end

function Service:_canPlay(matchId, category, now)
	local session = self:_getOrCreateSession(matchId)
	local currentTime = now or os.clock()
	local nextAt = session.nextAllowedAt[category] or 0
	if currentTime < nextAt then
		return false
	end
	session.nextAllowedAt[category] = currentTime + (self._cooldowns[category] or 1)
	return true
end

function Service:TriggerAmbientAudio(matchId, payload)
	if not self:_canPlay(matchId, "AmbientAudio", payload and payload.now) then
		return false
	end
	self:_publish("AmbientAudioTriggered", {
		matchId = matchId,
		category = "AmbientAudio",
		cue = payload and payload.cue or "ambient_tension_loop",
		roomId = payload and payload.roomId,
		intensity = payload and payload.intensity or 0.5,
	})
	return true
end

function Service:TriggerGhostAudio(matchId, payload)
	if not self:_canPlay(matchId, "GhostAudio", payload and payload.now) then
		return false
	end
	self:_publish("GhostAudioTriggered", {
		matchId = matchId,
		category = "GhostAudio",
		cue = payload and payload.cue or "ghost_whisper",
		roomId = payload and payload.roomId,
		intensity = payload and payload.intensity or 0.65,
	})
	return true
end

function Service:TriggerHuntAudio(matchId, payload)
	if not self:_canPlay(matchId, "HuntAudio", payload and payload.now) then
		return false
	end
	self:_publish("HuntAudioTriggered", {
		matchId = matchId,
		category = "HuntAudio",
		cue = payload and payload.cue or "hunt_stinger",
		intensity = payload and payload.intensity or 1.0,
	})
	return true
end

function Service:TriggerFearAudio(matchId, payload)
	if not self:_canPlay(matchId, "FearAudio", payload and payload.now) then
		return false
	end
	self:_publish("FearAudioTriggered", {
		matchId = matchId,
		category = "FearAudio",
		cue = payload and payload.cue or "heartbeat_rise",
		intensity = payload and payload.intensity or 0.6,
	})
	return true
end

function Service:TriggerEnvironmentalAudio(matchId, payload)
	if not self:_canPlay(matchId, "EnvironmentalAudio", payload and payload.now) then
		return false
	end
	self:_publish("EnvironmentalAudioTriggered", {
		matchId = matchId,
		category = "EnvironmentalAudio",
		cue = payload and payload.cue or "environment_disturbance",
		eventType = payload and payload.eventType,
		roomId = payload and payload.roomId,
		intensity = payload and payload.intensity or 0.7,
	})
	return true
end

return Service
