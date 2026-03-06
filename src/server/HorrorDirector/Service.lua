local Service = {}
Service.__index = Service

local TensionSystem = require(script.Parent.TensionSystem.TensionSystem)
local PlayerStateMonitor = require(script.Parent.PlayerStateMonitor.PlayerStateMonitor)
local Services = require(script.Parent.Parent.Core.Services)

local DEFAULT_CONFIG = {
	MaxTension = 100,
	MinTension = 0,
	LoopIntervalSeconds = 4,
	TogetherTimeThreshold = 12,
	TogetherGainPerSecond = 0.8,
	DarkAreaGainPerSecond = 0.9,
	NearGhostRoomGainPerSecond = 1.1,
	LeaveGhostRoomDecayPerSecond = 0.5,
	SafeZoneDecayPerSecond = 0.75,
	EvidenceFoundBonus = 6,
	GhostRetreatDrop = 7,
	Thresholds = {
		Environment = 20,
		Interaction = 40,
		Manifest = 60,
		HuntPressure = 80,
	},
	Cooldowns = {
		Environment = 12,
		Interaction = 10,
		Manifest = 18,
		HuntPressure = 30,
	},
	HuntPressureBaseChance = 0.2,
	HuntPressureMaxChance = 0.9,
	TensionLevels = {
		{ name = "Calm", min = 0, max = 19 },
		{ name = "Uneasy", min = 20, max = 39 },
		{ name = "Disturbance", min = 40, max = 59 },
		{ name = "Manifestation", min = 60, max = 79 },
		{ name = "Hunt", min = 80, max = 100 },
	},
	StagnationSeconds = 35,
	MinTensionPublishDelta = 0.25,
	IdleLoopMultiplier = 2,
}

local ENVIRONMENT_EVENTS = {
	"LightFlicker",
	"ObjectMovement",
	"DoorSlam",
	"RadioNoise",
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

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function mergeConfig(baseConfig, overrideConfig)
	local merged = {}
	for key, value in pairs(baseConfig) do
		if type(value) == "table" then
			merged[key] = mergeConfig(value, {})
		else
			merged[key] = value
		end
	end
	for key, value in pairs(overrideConfig or {}) do
		if type(value) == "table" and type(merged[key]) == "table" then
			merged[key] = mergeConfig(merged[key], value)
		else
			merged[key] = value
		end
	end
	return merged
end

local function normalizedPhase(phaseName)
	local map = {
		Investigation = true,
		InvestigationPhase = true,
		Hunt = true,
		HuntPhase = true,
	}
	return map[phaseName] == true
end

local function pickEnvironmentEvent(rng)
	return ENVIRONMENT_EVENTS[rng:NextInteger(1, #ENVIRONMENT_EVENTS)]
end

local function getAlivePlayers(snapshot)
	local players = snapshot and snapshot.players
	if type(players) ~= "table" then
		return {}
	end

	local alive = {}
	for _, playerData in ipairs(players) do
		if playerData.isAlive ~= false then
			table.insert(alive, playerData)
		end
	end
	return alive
end

local function countByRoom(players)
	local counts = {}
	for _, playerData in ipairs(players) do
		local roomId = playerData.roomId
		if roomId then
			counts[roomId] = (counts[roomId] or 0) + 1
		end
	end
	return counts
end

local function largestGroupSize(players)
	local byRoom = countByRoom(players)
	local maxCount = 0
	for _, c in pairs(byRoom) do
		if c > maxCount then
			maxCount = c
		end
	end
	return maxCount
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._config = mergeConfig(DEFAULT_CONFIG, self._deps.HorrorDirectorConfig or {})
	self._tensionSystem = TensionSystem.new({
		min = self._config.MinTension,
		max = self._config.MaxTension,
	})
	self._stateMonitor = PlayerStateMonitor.new()
	self._aggression = Services.Get(self._deps, "AggressionSystem")
	if type(self._aggression) == "table" and type(self._aggression.Service) == "table" then
		self._aggression = self._aggression.Service
	end
	self._rng = self._deps.Random or Random.new()
	self._loopRunning = false
	self._loopToken = 0
	self._loopThread = nil
	return self
end

function Service:Init()
	self._state:Set("sessions", {})
end

function Service:Start()
	self:_startDirectorLoop()
end

function Service:Stop()
	self:_stopDirectorLoop()
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

function Service:_getOrCreateSession(matchId, now)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if session then
		return session
	end

	session = {
		matchId = matchId,
		tension = 0,
		tensionLevel = "Calm",
		lastUpdateAt = now or os.clock(),
		lastEvidenceAt = now or os.clock(),
		lastEventAt = now or os.clock(),
		lastStagnationAt = now or os.clock(),
		togetherSeconds = 0,
		nearGhostRoomRatio = 0,
		huntActive = false,
		ghostRoomId = nil,
		lastSnapshot = {},
		lastThresholdAt = {
			Environment = 0,
			Interaction = 0,
			Manifest = 0,
			HuntPressure = 0,
		},
	}
	sessions[matchId] = session
	self:_setSessions(sessions)
	return session
end

function Service:_startDirectorLoop()
	if self._loopRunning then
		return
	end
	self._loopRunning = true
	self._loopToken += 1
	local token = self._loopToken
	self._loopThread = task.spawn(function()
		while self._loopRunning and token == self._loopToken do
			local now = os.clock()
			local sessions = self:_sessions()
			local hasSessions = next(sessions) ~= nil
			for matchId, session in pairs(sessions) do
				if session and type(session) == "table" then
					local elapsed = now - (session.lastUpdateAt or now)
					if elapsed >= (self._config.LoopIntervalSeconds * 0.9) then
						local snapshot = session.lastSnapshot or {}
						snapshot.now = now
						snapshot.dt = math.max(self._config.LoopIntervalSeconds, elapsed)
						self:EvaluateTension(matchId, snapshot, now)
					end
					self:_preventStagnation(matchId, session, now)
				end
			end
			if hasSessions then
				task.wait(self._config.LoopIntervalSeconds)
			else
				task.wait(self._config.LoopIntervalSeconds * self._config.IdleLoopMultiplier)
			end
		end
	end)
end

function Service:_stopDirectorLoop()
	self._loopRunning = false
	self._loopToken += 1
	if self._loopThread then
		task.cancel(self._loopThread)
		self._loopThread = nil
	end
end

function Service:_resolveTensionLevel(tension)
	for _, entry in ipairs(self._config.TensionLevels or {}) do
		if tension >= entry.min and tension <= entry.max then
			return entry.name
		end
	end
	return "Calm"
end

function Service:_publishTensionChange(matchId, session, previousTension, reason)
	local newLevel = self:_resolveTensionLevel(session.tension)
	local previousLevel = session.tensionLevel or self:_resolveTensionLevel(previousTension)
	local changed = previousLevel ~= newLevel
	local tensionDelta = math.abs(session.tension - previousTension)
	if not changed and tensionDelta < self._config.MinTensionPublishDelta then
		return
	end
	session.tensionLevel = newLevel
	self:_publish("DirectorTensionChanged", {
		matchId = matchId,
		tension = session.tension,
		previousTension = previousTension,
		level = newLevel,
		previousLevel = previousLevel,
		reason = reason,
	})
	if changed then
		self:_publish("DirectorEventTriggered", {
			matchId = matchId,
			eventType = "TensionLevelChanged",
			tension = session.tension,
			level = newLevel,
			previousLevel = previousLevel,
			reason = reason,
		})
	end
end

function Service:_increaseAggression(matchId, amount, reason, metadata)
	if self._aggression and type(self._aggression.IncreaseAggression) == "function" then
		self._aggression:IncreaseAggression(matchId, amount, reason, metadata)
	end
end

function Service:_preventStagnation(matchId, session, now)
	local stagnationSeconds = now - (session.lastEvidenceAt or now)
	if stagnationSeconds < self._config.StagnationSeconds then
		return
	end
	if (now - (session.lastStagnationAt or 0)) < self._config.StagnationSeconds then
		return
	end

	local before = session.tension
	session.tension = self._tensionSystem:ApplyDelta(session.tension, 4)
	session.lastStagnationAt = now

	self:_publish("DirectorEventTriggered", {
		matchId = matchId,
		eventType = "AntiStagnationGhostActivity",
		reason = "no_evidence_progress",
		tension = session.tension,
		stagnationSeconds = stagnationSeconds,
	})
	self:_publish("ForceRoam", {
		matchId = matchId,
		reason = "anti_stagnation",
		now = now,
		duration = 8,
	})
	self:_publishTensionChange(matchId, session, before, "stagnation_control")
	self:_increaseAggression(matchId, 1.5, "director_stagnation", {
		stagnationSeconds = stagnationSeconds,
	})
end

function Service:StartMatch(matchId, payload)
	if not matchId then
		return nil, "invalid_arguments"
	end
	local session = self:_getOrCreateSession(matchId, payload and payload.now)
	session.ghostRoomId = payload and payload.favoriteRoomId or session.ghostRoomId
	session.lastSnapshot = payload and payload.snapshot or session.lastSnapshot
	return session
end

function Service:EndMatch(matchId)
	local sessions = self:_sessions()
	sessions[matchId] = nil
	self:_setSessions(sessions)
end

function Service:SetGhostRoom(matchId, roomId)
	local session = self:_getOrCreateSession(matchId, os.clock())
	session.ghostRoomId = roomId or session.ghostRoomId
end

function Service:RecordEvidenceCollected(matchId, payload)
	local session = self:_getOrCreateSession(matchId, payload and payload.now)
	local before = session.tension
	session.tension = self._tensionSystem:ApplyDelta(session.tension, self._config.EvidenceFoundBonus)
	session.lastEvidenceAt = payload and payload.now or os.clock()

	local delta = session.tension - before
	if delta > 0 then
		self:_publish("TensionIncreased", {
			matchId = matchId,
			tension = session.tension,
			delta = delta,
			reason = "evidence_collected",
			evidenceType = payload and payload.evidenceType,
		})
	end
	self:_publishTensionChange(matchId, session, before, "evidence_collected")

	self:ScheduleEvent(matchId, "evidence_collected", payload and payload.now)
	return session.tension
end

function Service:RecordGhostStateChanged(matchId, payload)
	local session = self:_getOrCreateSession(matchId, payload and payload.now)
	local currentState = payload and payload.currentState
	if currentState == "Retreat" then
		local before = session.tension
		session.tension = self._tensionSystem:ApplyDelta(session.tension, -self._config.GhostRetreatDrop)
		self:_publishTensionChange(matchId, session, before, "ghost_retreat")
	end
end

function Service:RecordHuntStarted(matchId)
	local session = self:_getOrCreateSession(matchId, os.clock())
	session.huntActive = true
end

function Service:RecordHuntEnded(matchId)
	local session = self:_getOrCreateSession(matchId, os.clock())
	session.huntActive = false
end

function Service:RecordPlayerStateSnapshot(matchId, snapshot, now)
	if not matchId then
		return nil
	end
	local session = self:_getOrCreateSession(matchId, now or os.clock())
	session.lastSnapshot = snapshot or session.lastSnapshot or {}
	return self:EvaluateTension(matchId, session.lastSnapshot, now)
end

function Service:RecordPlayerSanityChanged(matchId, payload)
	if not matchId then
		return nil
	end
	local session = self:_getOrCreateSession(matchId, payload and payload.now)
	local sanity = payload and payload.newSanity
	if type(sanity) == "number" and sanity <= 35 then
		local before = session.tension
		session.tension = self._tensionSystem:ApplyDelta(session.tension, 1.5)
		local delta = session.tension - before
		if delta > 0 then
			self:_publish("TensionIncreased", {
				matchId = matchId,
				tension = session.tension,
				delta = delta,
				reason = "low_sanity",
			})
		end
		self:_publishTensionChange(matchId, session, before, "low_sanity")
		self:_increaseAggression(matchId, 1.0, "director_low_sanity", {
			sanity = sanity,
		})

		if self._aggression and type(self._aggression.GetAggressionLevel) == "function" then
			local info = self._aggression:GetAggressionLevel(matchId)
			local aggressionValue = type(info) == "table" and info.aggression or 0
			if aggressionValue >= 55 then
				self:_publish("GhostFakeEvidenceRequested", {
					matchId = matchId,
					reason = "low_sanity_high_aggression",
					sanity = sanity,
					aggression = aggressionValue,
				})
			end
		end
	end
	return session.tension
end

function Service:_scoreSnapshot(session, snapshot, dt)
	local alivePlayers = getAlivePlayers(snapshot)
	local playerCount = #alivePlayers
	if playerCount == 0 then
		return -self._config.SafeZoneDecayPerSecond * dt
	end

	local delta = 0
	local roomCounts = countByRoom(alivePlayers)
	local largestGroup = 0
	for _, count in pairs(roomCounts) do
		if count > largestGroup then
			largestGroup = count
		end
	end

	local groupedRatio = largestGroup / playerCount
	local groupedLongEnough = false
	if groupedRatio >= 0.75 and playerCount >= 2 then
		session.togetherSeconds += dt
		groupedLongEnough = session.togetherSeconds >= self._config.TogetherTimeThreshold
	else
		session.togetherSeconds = math.max(0, session.togetherSeconds - dt * 1.5)
	end
	if groupedLongEnough then
		delta += self._config.TogetherGainPerSecond * dt
	end

	local inDarkCount = 0
	local nearGhostRoomCount = 0
	local inSafeZoneCount = 0
	for _, playerData in ipairs(alivePlayers) do
		local inDark = playerData.inDarkArea == true or ((playerData.lightLevel or 1) <= 0.25)
		local inSafe = playerData.inSafeZone == true
		local nearGhost = playerData.isNearGhostRoom == true
			or (session.ghostRoomId and playerData.roomId == session.ghostRoomId)

		if inDark then
			inDarkCount += 1
		end
		if nearGhost then
			nearGhostRoomCount += 1
		end
		if inSafe then
			inSafeZoneCount += 1
		end
	end

	local darkRatio = inDarkCount / math.max(1, playerCount)
	session.nearGhostRoomRatio = nearGhostRoomCount / math.max(1, playerCount)
	delta += darkRatio * self._config.DarkAreaGainPerSecond * dt
	delta += session.nearGhostRoomRatio * self._config.NearGhostRoomGainPerSecond * dt

	if session.nearGhostRoomRatio <= 0.25 then
		delta -= self._config.LeaveGhostRoomDecayPerSecond * dt
	end
	if inSafeZoneCount > 0 then
		local safeRatio = inSafeZoneCount / math.max(1, playerCount)
		delta -= safeRatio * self._config.SafeZoneDecayPerSecond * dt
	end

	return delta
end

function Service:EvaluateTension(matchId, snapshot, now)
	if not matchId then
		return nil, "invalid_arguments"
	end
	local phaseName = snapshot and snapshot.phaseName
	if phaseName and not normalizedPhase(phaseName) then
		return nil, "non_gameplay_phase"
	end

	local currentTime = now or snapshot and snapshot.now or os.clock()
	local session = self:_getOrCreateSession(matchId, currentTime)
	session.lastSnapshot = snapshot or session.lastSnapshot or {}
	local monitorState = self._stateMonitor:Evaluate(snapshot)
	local dt = snapshot and snapshot.dt
	if type(dt) ~= "number" or dt <= 0 then
		dt = math.max(0.25, currentTime - (session.lastUpdateAt or currentTime))
	end

	local before = session.tension
	local delta = self:_scoreSnapshot(session, snapshot or {}, dt)
	if monitorState.longSilence then
		delta += 1.25 * dt
	end
	if monitorState.failedInvestigation then
		delta += 1.1 * dt
	end
	if monitorState.lowSanity then
		delta += 0.6 * dt
	end
	session.tension = clamp(before + delta, self._config.MinTension, self._config.MaxTension)
	session.lastUpdateAt = currentTime

	local increased = session.tension - before
	if increased > 0 then
		self:_publish("TensionIncreased", {
			matchId = matchId,
			tension = session.tension,
			delta = increased,
			reason = "snapshot_evaluation",
		})
	end
	if monitorState.isolated then
		self:_publish("DirectorEventTriggered", {
			matchId = matchId,
			eventType = "IsolationPressure",
			reason = "player_isolated",
			tension = session.tension,
		})
	end
	self:_publishTensionChange(matchId, session, before, "snapshot_evaluation")
	self:_increaseAggression(matchId, math.max(increased, 0) * 0.05, "director_tension_rise", {
		tension = session.tension,
	})
	self:_maybeTriggerGroupDistraction(matchId, session, snapshot, currentTime)

	self:ScheduleEvent(matchId, "evaluation", currentTime)
	return session.tension
end

function Service:_maybeTriggerGroupDistraction(matchId, session, snapshot, now)
	local players = getAlivePlayers(snapshot)
	if #players < 2 then
		return
	end
	local largestGroup = largestGroupSize(players)
	if largestGroup < 2 then
		return
	end
	if session.togetherSeconds < self._config.TogetherTimeThreshold then
		return
	end
	if (now - (session.lastEventAt or 0)) < 15 then
		return
	end

	session.lastEventAt = now
	self:_publish("DirectorEventTriggered", {
		matchId = matchId,
		eventType = "GroupDistraction",
		reason = "players_grouped",
		tension = session.tension,
		groupSize = largestGroup,
	})
	self:_publish("EnvironmentEventTriggered", {
		matchId = matchId,
		eventType = "DistractionEvent",
		tension = session.tension,
		reason = "players_grouped",
		groupSize = largestGroup,
	})
	self:_increaseAggression(matchId, 0.8, "director_grouped_players", {
		groupSize = largestGroup,
	})
end

function Service:_tryThreshold(matchId, session, thresholdName, reason, now, callback)
	local threshold = self._config.Thresholds[thresholdName]
	local cooldown = self._config.Cooldowns[thresholdName] or 0
	local lastAt = session.lastThresholdAt[thresholdName] or 0
	if session.tension < threshold then
		return false
	end
	if (now - lastAt) < cooldown then
		return false
	end

	session.lastThresholdAt[thresholdName] = now
	callback()
	return true
end

function Service:ScheduleEvent(matchId, reason, now)
	local session = self:_getOrCreateSession(matchId, now or os.clock())
	local currentTime = now or os.clock()

	self:_tryThreshold(matchId, session, "Environment", reason, currentTime, function()
		local environmentEvent = pickEnvironmentEvent(self._rng)
		session.lastEventAt = currentTime
		self:_publish("EnvironmentEventTriggered", {
			matchId = matchId,
			eventType = environmentEvent,
			tension = session.tension,
			reason = reason,
		})
		self:_publish("DirectorEventTriggered", {
			matchId = matchId,
			eventType = environmentEvent,
			tension = session.tension,
			reason = reason,
		})
	end)

	self:_tryThreshold(matchId, session, "Interaction", reason, currentTime, function()
		session.lastEventAt = currentTime
		self:_publish("ForceRoam", {
			matchId = matchId,
			reason = reason,
			tension = session.tension,
			duration = 6,
		})
		self:_publish("EnvironmentEventTriggered", {
			matchId = matchId,
			eventType = "GhostInteractionPressure",
			tension = session.tension,
			reason = reason,
		})
		self:_publish("DirectorEventTriggered", {
			matchId = matchId,
			eventType = "GhostInteractionPressure",
			tension = session.tension,
			reason = reason,
		})
	end)

	self:_tryThreshold(matchId, session, "Manifest", reason, currentTime, function()
		session.lastEventAt = currentTime
		self:_publish("GhostManifest", {
			matchId = matchId,
			tension = session.tension,
			reason = reason,
		})
		self:_publish("ForceManifest", {
			matchId = matchId,
			duration = 8,
			reason = reason,
			now = currentTime,
		})
		self:_publish("DirectorEventTriggered", {
			matchId = matchId,
			eventType = "Manifestation",
			tension = session.tension,
			reason = reason,
		})
	end)

	self:_tryThreshold(matchId, session, "HuntPressure", reason, currentTime, function()
		if session.huntActive then
			return
		end
		local huntChance = self:AdjustHuntProbability(matchId)
		if self._rng:NextNumber() <= huntChance then
			session.lastEventAt = currentTime
			self:_publish("DirectorTriggeredHunt", {
				matchId = matchId,
				tension = session.tension,
				huntChance = huntChance,
				reason = reason,
			})
			self:_publish("ForceHunt", {
				matchId = matchId,
				reason = reason,
				now = currentTime,
			})
			self:_publish("DirectorHuntTriggered", {
				matchId = matchId,
				tension = session.tension,
				huntChance = huntChance,
				reason = reason,
			})
			self:_publish("DirectorEventTriggered", {
				matchId = matchId,
				eventType = "Hunt",
				tension = session.tension,
				reason = reason,
			})
		end
	end)

	return session.tension
end

function Service:AdjustHuntProbability(matchId)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if not session then
		return 0
	end

	local threshold = self._config.Thresholds.HuntPressure
	local normalized = clamp((session.tension - threshold) / math.max(1, self._config.MaxTension - threshold), 0, 1)
	local chance = self._config.HuntPressureBaseChance
		+ (normalized * (self._config.HuntPressureMaxChance - self._config.HuntPressureBaseChance))
	return clamp(chance, 0, self._config.HuntPressureMaxChance)
end

return Service

