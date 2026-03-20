local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
	MaxFear = 100,
	MinFear = 0,
	BaseFearDecayPerSecond = 0.35,
	ProximityScale = 24,
	DarknessScale = 18,
	DisturbanceScale = 14,
	LowSanityScale = 28,
	HuntFearBonus = 16,
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

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function mergeConfig(base, override)
	local merged = {}
	for key, value in pairs(base) do
		merged[key] = value
	end
	for key, value in pairs(override or {}) do
		merged[key] = value
	end
	return merged
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._config = mergeConfig(DEFAULT_CONFIG, self._deps.FearConfig)
	self._eventBus = resolveEventBus(self._deps)
	return self
end

function Service:Init()
	self._state:Set("sessions", {})
end

function Service:Start()
	-- Driven by event callbacks.
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
		fearLevel = 0,
		lastUpdatedAt = os.clock(),
		disturbanceLevel = 0,
		huntActive = false,
		averageSanity = 100,
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

function Service:GetFearLevel(matchId)
	local session = self:_sessions()[matchId]
	return session and session.fearLevel or 0
end

function Service:_emitFearSignals(session, oldFear, reason)
	if oldFear == session.fearLevel then
		return
	end

	self:_publish("FearLevelChanged", {
		matchId = session.matchId,
		fearLevel = session.fearLevel,
		oldFearLevel = oldFear,
		reason = reason,
	})
	self:_publish("FearScreenTensionTriggered", {
		matchId = session.matchId,
		intensity = session.fearLevel / 100,
		reason = reason,
	})

	local aggressionPulse = math.max(0, session.fearLevel - 35) * 0.05
	if aggressionPulse > 0 then
		self:_publish("IncreaseAggression", {
			matchId = session.matchId,
			amount = aggressionPulse,
			source = "FearEngine",
		})
	end

	local evidencePressure = 1 + (session.fearLevel / 200)
	self:_publish("FearEvidencePressure", {
		matchId = session.matchId,
		multiplier = evidencePressure,
	})
end

function Service:Evaluate(matchId, factors, now, reason)
	local session = self:_getOrCreateSession(matchId)
	local currentTime = now or os.clock()
	local dt = factors and factors.dt
	if type(dt) ~= "number" or dt <= 0 then
		dt = math.max(0.25, currentTime - (session.lastUpdatedAt or currentTime))
	end
	session.lastUpdatedAt = currentTime

	local proximity = clamp((factors and factors.ghostProximity) or 0, 0, 1)
	local darkness = clamp((factors and factors.darknessLevel) or 0, 0, 1)
	local disturbances = clamp((factors and factors.environmentDisturbances) or session.disturbanceLevel or 0, 0, 1)
	local sanity = clamp((factors and factors.averageSanity) or session.averageSanity or 100, 0, 100)
	session.averageSanity = sanity
	session.disturbanceLevel = disturbances

	local lowSanityFactor = 1 - (sanity / 100)
	local gain = (proximity * self._config.ProximityScale)
		+ (darkness * self._config.DarknessScale)
		+ (disturbances * self._config.DisturbanceScale)
		+ (lowSanityFactor * self._config.LowSanityScale)
	if session.huntActive then
		gain += self._config.HuntFearBonus
	end

	local decay = self._config.BaseFearDecayPerSecond * dt
	local oldFear = session.fearLevel
	local nextFear = oldFear + (gain * dt) - decay
	session.fearLevel = clamp(nextFear, self._config.MinFear, self._config.MaxFear)

	self:_emitFearSignals(session, oldFear, reason or "evaluation")
	return session.fearLevel
end

function Service:OnSanityChanged(matchId, payload)
	local sanity = payload and payload.averageSanity
	if type(sanity) ~= "number" then
		sanity = payload and payload.newSanity or 100
	end
	return self:Evaluate(matchId, {
		averageSanity = sanity,
		ghostProximity = payload and payload.ghostProximity or 0,
		darknessLevel = payload and payload.darknessLevel or 0,
		environmentDisturbances = payload and payload.disturbanceLevel or 0,
	}, payload and payload.now, "sanity_changed")
end

function Service:OnEnvironmentEvent(matchId, payload)
	local boost = 0.25
	if payload and (payload.eventType == "ShadowMovement" or payload.eventType == "DoorSlam") then
		boost = 0.45
	end
	return self:Evaluate(matchId, {
		environmentDisturbances = boost,
	}, payload and payload.now, "environment_event")
end

function Service:OnGhostInteraction(matchId, payload)
	local proximity = payload and payload.proximity or 0.7
	local disturbance = payload and payload.intensity and math.min(1, payload.intensity / 3) or 0.6
	return self:Evaluate(matchId, {
		ghostProximity = proximity,
		environmentDisturbances = disturbance,
	}, payload and payload.now, "ghost_interaction")
end

function Service:OnHuntStarted(matchId, payload)
	local session = self:_getOrCreateSession(matchId)
	session.huntActive = true
	return self:Evaluate(matchId, {
		ghostProximity = 1,
		environmentDisturbances = 1,
	}, payload and payload.now, "hunt_started")
end

function Service:OnHuntEnded(matchId, payload)
	local session = self:_getOrCreateSession(matchId)
	session.huntActive = false
	return self:Evaluate(matchId, {
		environmentDisturbances = 0.2,
	}, payload and payload.now, "hunt_ended")
end

return Service
