local Service = {}
Service.__index = Service

local DEFAULT_COOLDOWNS = {
	AmbientAudio = 10,
	EnvironmentalAudio = 3,
	FearAudio = 4,
	GhostAudio = 4,
	HuntAudio = 2,
	JumpscareAudio = 2,
}

local INVESTIGATION_PHASES = {
	Investigation = true,
	InvestigationPhase = true,
}

local AMBIENT_EVENT_ROTATION = {
	hauntedhouse = {
		{ category = "GhostAudio", cue = "ghost_whisper", intensityMin = 0.2, intensityMax = 0.3 },
		{ category = "EnvironmentalAudio", eventType = "WindowKnock", cue = "env_windowknock", intensityMin = 0.22, intensityMax = 0.34 },
		{ category = "EnvironmentalAudio", eventType = "ObjectThrow", cue = "env_objectthrow", intensityMin = 0.2, intensityMax = 0.32 },
		{ category = "EnvironmentalAudio", eventType = "LightFlicker", cue = "env_lightflicker", intensityMin = 0.18, intensityMax = 0.28 },
		{ category = "EnvironmentalAudio", eventType = "TemperatureDrop", cue = "env_temperaturedrop", intensityMin = 0.18, intensityMax = 0.26 },
	},
	emptybuilding = {
		{ category = "EnvironmentalAudio", eventType = "RadioStatic", cue = "env_radiostatic", intensityMin = 0.16, intensityMax = 0.24 },
		{ category = "EnvironmentalAudio", eventType = "ObjectThrow", cue = "env_objectthrow", intensityMin = 0.18, intensityMax = 0.3 },
		{ category = "GhostAudio", cue = "ghost_fake_footsteps", intensityMin = 0.18, intensityMax = 0.28 },
		{ category = "EnvironmentalAudio", eventType = "LightFlicker", cue = "env_lightflicker", intensityMin = 0.16, intensityMax = 0.24 },
	},
	abandonedpalace = {
		{ category = "EnvironmentalAudio", eventType = "DoorSlam", cue = "env_doorslam", intensityMin = 0.24, intensityMax = 0.34 },
		{ category = "GhostAudio", cue = "ghost_manifest", intensityMin = 0.18, intensityMax = 0.28 },
		{ category = "EnvironmentalAudio", eventType = "ShadowApparition", cue = "env_shadowapparition", intensityMin = 0.18, intensityMax = 0.26 },
		{ category = "EnvironmentalAudio", eventType = "TemperatureDrop", cue = "env_temperaturedrop", intensityMin = 0.2, intensityMax = 0.28 },
	},
	studiommnineteen = {
		{ category = "EnvironmentalAudio", eventType = "RadioStatic", cue = "env_radiostatic", intensityMin = 0.14, intensityMax = 0.22 },
		{ category = "GhostAudio", cue = "ghost_fake_footsteps", intensityMin = 0.16, intensityMax = 0.24 },
		{ category = "EnvironmentalAudio", eventType = "ObjectThrow", cue = "env_objectthrow", intensityMin = 0.16, intensityMax = 0.24 },
	},
	default = {
		{ category = "GhostAudio", cue = "ghost_whisper", intensityMin = 0.18, intensityMax = 0.26 },
		{ category = "EnvironmentalAudio", eventType = "LightFlicker", cue = "env_lightflicker", intensityMin = 0.16, intensityMax = 0.22 },
		{ category = "EnvironmentalAudio", eventType = "WindowKnock", cue = "env_windowknock", intensityMin = 0.18, intensityMax = 0.24 },
	},
}

local function resolveEventBus(deps)
	local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

local function resolveMatchSystem(deps)
	local matchSystem = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("MatchSystem"))
		or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("MatchSystem"))
		or (deps and deps.MatchSystem or nil)
	if type(matchSystem) ~= "table" then
		return nil
	end
	if type(matchSystem.GetLiveMatch) == "function" then
		return matchSystem
	end
	if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
		return matchSystem.Service
	end
	return nil
end

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-%.]+", ""):lower()
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._matchSystem = resolveMatchSystem(self._deps)
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

function Service:_getLiveMatch(matchId)
	local matchSystem = self._matchSystem or resolveMatchSystem(self._deps)
	if type(matchSystem) ~= "table" or type(matchSystem.GetLiveMatch) ~= "function" then
		return nil
	end
	self._matchSystem = matchSystem
	return matchSystem:GetLiveMatch(matchId)
end

function Service:_resolveGhostType(matchId, payload)
	for _, key in ipairs({ "ghostType", "visualGhostType", "actualGhostType", "targetGhostType" }) do
		if type(payload) == "table" and type(payload[key]) == "string" and payload[key] ~= "" then
			return payload[key]
		end
	end

	local match = self:_getLiveMatch(matchId)
	if type(match) == "table" then
		if type(match.ghostType) == "string" and match.ghostType ~= "" then
			return match.ghostType
		end
		if typeof(match.ghost) == "Instance" then
			local attributeGhostType = match.ghost:GetAttribute("GhostType") or match.ghost:GetAttribute("VisualGhostType")
			if type(attributeGhostType) == "string" and attributeGhostType ~= "" then
				return attributeGhostType
			end
		end
	end

	return nil
end

function Service:_isInvestigationPhase(match)
	local phase = type(match) == "table" and match.phase or nil
	return INVESTIGATION_PHASES[phase] == true
end

function Service:_chooseAmbientRoom(match)
	if type(match) ~= "table" then
		return nil
	end
	local roomIds = match.roomIds
	if type(roomIds) == "table" and #roomIds > 0 then
		return roomIds[self._rng:NextInteger(1, #roomIds)]
	end
	local candidates = match.ghostRoomCandidates
	if type(candidates) == "table" and #candidates > 0 then
		return candidates[self._rng:NextInteger(1, #candidates)]
	end
	return nil
end

function Service:_chooseAmbientEvent(match)
	local mapToken = normalizeToken(type(match) == "table" and (match.mapId or match.mapName) or nil) or "default"
	local candidates = AMBIENT_EVENT_ROTATION[mapToken] or AMBIENT_EVENT_ROTATION.default
	if type(candidates) ~= "table" or #candidates == 0 then
		return nil
	end
	return candidates[self._rng:NextInteger(1, #candidates)]
end

function Service:_nextAmbientDelay(match)
	local mapToken = normalizeToken(type(match) == "table" and (match.mapId or match.mapName) or nil)
	if mapToken == "hauntedhouse" then
		return self._rng:NextNumber(12, 18)
	elseif mapToken == "abandonedpalace" then
		return self._rng:NextNumber(13, 19)
	elseif mapToken == "emptybuilding" then
		return self._rng:NextNumber(11, 16)
	end
	return self._rng:NextNumber(12, 17)
end

function Service:_emitAmbientCadence(matchId, session)
	if type(matchId) ~= "string" or type(session) ~= "table" then
		return
	end
	local liveMatch = self:_getLiveMatch(matchId)
	if not self:_isInvestigationPhase(liveMatch) then
		return
	end

	local eventProfile = self:_chooseAmbientEvent(liveMatch)
	if type(eventProfile) ~= "table" then
		return
	end

	local intensityMin = tonumber(eventProfile.intensityMin) or 0.18
	local intensityMax = tonumber(eventProfile.intensityMax) or math.max(intensityMin, 0.24)
	local payload = {
		roomId = self:_chooseAmbientRoom(liveMatch),
		cue = eventProfile.cue,
		eventType = eventProfile.eventType,
		intensity = self._rng:NextNumber(intensityMin, math.max(intensityMin, intensityMax)),
		now = os.clock(),
	}

	if eventProfile.category == "GhostAudio" then
		self:TriggerGhostAudio(matchId, payload)
	else
		self:TriggerEnvironmentalAudio(matchId, payload)
	end
	session.lastAmbientPulseAt = payload.now
	session.lastAmbientCue = payload.cue
end

function Service:_scheduleAmbientCadence(matchId, session, delaySeconds)
	if type(matchId) ~= "string" or type(session) ~= "table" then
		return
	end
	local generation = session.ambientCadenceGeneration or 0
	local waitSeconds = tonumber(delaySeconds) or 0
	task.delay(waitSeconds, function()
		local currentSessions = self:_sessions()
		local currentSession = currentSessions[matchId]
		if currentSession ~= session then
			return
		end
		if (currentSession.ambientCadenceGeneration or 0) ~= generation then
			return
		end

		local liveMatch = self:_getLiveMatch(matchId)
		if not liveMatch then
			return
		end

		if self:_isInvestigationPhase(liveMatch) then
			self:_emitAmbientCadence(matchId, currentSession)
		end

		self:_scheduleAmbientCadence(matchId, currentSession, self:_nextAmbientDelay(liveMatch))
	end)
end

function Service:StartMatch(matchId)
	local session = self:_getOrCreateSession(matchId)
	session.ambientCadenceGeneration = (session.ambientCadenceGeneration or 0) + 1
	self:_scheduleAmbientCadence(matchId, session, self._rng:NextNumber(5, 8))
	return session
end

function Service:EndMatch(matchId)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if type(session) == "table" then
		session.ambientCadenceGeneration = (session.ambientCadenceGeneration or 0) + 1
	end
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
		ghostType = self:_resolveGhostType(matchId, payload),
		roomId = payload and payload.roomId,
		intensity = payload and payload.intensity or 0.65,
	})
	return true
end

function Service:TriggerJumpscareAudio(matchId, payload)
	if not self:_canPlay(matchId, "JumpscareAudio", payload and payload.now) then
		return false
	end
	self:_publish("JumpscareAudioTriggered", {
		matchId = matchId,
		category = "JumpscareAudio",
		cue = payload and payload.cue or "jumpscare_stinger",
		ghostType = self:_resolveGhostType(matchId, payload),
		roomId = payload and payload.roomId,
		intensity = payload and payload.intensity or 1.0,
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
		ghostType = self:_resolveGhostType(matchId, payload),
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
