local GhostAI = require(script.Parent.GhostAICore)
local Services = require(script.Parent.Parent.Core.Services)

local GhostService = {}
GhostService.__index = GhostService

local DEFAULT_CONFIG = {
	MinTickIntervalSeconds = 0.2,
	MaxRuntimeEventsPerTick = 24,
	EventThrottle = {
		GhostInteraction = 0.2,
		GhostDecisionMade = 0.25,
		GhostStrategyChanged = 0.4,
		GhostAbilityTriggered = 0.25,
		GhostAbilityCooldown = 0.4,
		GhostAbilityCompleted = 0.2,
		GhostDeceptionTriggered = 0.25,
		GhostRoamed = 0.25,
		EvidenceTriggered = 0.2,
		GhostFakeEvidenceSpawned = 0.2,
	},
}

local function mergeConfig(base, override)
	local out = {}
	for key, value in pairs(base) do
		if type(value) == "table" then
			local nested = {}
			for nestedKey, nestedValue in pairs(value) do
				nested[nestedKey] = nestedValue
			end
			out[key] = nested
		else
			out[key] = value
		end
	end
	for key, value in pairs(override or {}) do
		if type(value) == "table" and type(out[key]) == "table" then
			for nestedKey, nestedValue in pairs(value) do
				out[key][nestedKey] = nestedValue
			end
		else
			out[key] = value
		end
	end
	return out
end

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
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

local function resolveEvidenceService(deps)
	local evidenceSystem = Services.Get(deps, "EvidenceSystem")
	if type(evidenceSystem) ~= "table" then
		return nil
	end
	if type(evidenceSystem.SpawnEvidence) == "function" then
		return evidenceSystem
	end
	if type(evidenceSystem.Service) == "table" and type(evidenceSystem.Service.SpawnEvidence) == "function" then
		return evidenceSystem.Service
	end
	return nil
end

function GhostService.new(state, deps)
	local self = setmetatable({}, GhostService)
	self._state = state
	self._deps = deps or {}
	self._config = mergeConfig(DEFAULT_CONFIG, self._deps.GhostServiceConfig)
	self._eventBus = resolveEventBus(self._deps)
	self._evidenceService = resolveEvidenceService(self._deps)
	self._ai = GhostAI.new(self._deps, self._deps.GhostConfig or {})
	self._lastTickAtByMatch = {}
	self._lastPublishedAtByMatch = {}
	self._activeGhosts = {}
	self._running = false
	return self
end

function GhostService:Init()
	self._state:Set("sessions", {})
end

function GhostService:Start()
	self._running = true
	task.spawn(function()
		local TICK_INTERVAL = 1.5
		while self._running do
			local now = os.clock()
			local sessions = self._state:Get("sessions") or {}
			for matchId, _ in pairs(sessions) do
				local lastTick = self._lastTickAtByMatch[matchId] or now
				local dt = now - lastTick
				if dt >= TICK_INTERVAL then
					self:TickGhost(matchId, {}, dt, now)
				end
			end
			task.wait(TICK_INTERVAL)
		end
	end)
end

function GhostService:Stop()
	self._running = false
	local sessions = self._state:Get("sessions") or {}
	for matchId in pairs(sessions) do
		self._ai:RemoveSession(matchId)
	end
	table.clear(self._lastTickAtByMatch)
	table.clear(self._lastPublishedAtByMatch)
	self._state:Set("sessions", {})
end

function GhostService:InitializeGhost(match)
	local ghostAI = require(script.Parent.GhostAI)
	ghostAI:Start(match)
end

function GhostService:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function GhostService:_publishThrottled(matchId, eventName, payload, now)
	local throttleSeconds = self._config.EventThrottle[eventName]
	if not throttleSeconds or throttleSeconds <= 0 then
		self:_publish(eventName, payload)
		return true
	end

	local perMatch = self._lastPublishedAtByMatch[matchId]
	if not perMatch then
		perMatch = {}
		self._lastPublishedAtByMatch[matchId] = perMatch
	end

	local eventTime = now or os.clock()
	local lastAt = perMatch[eventName] or 0
	if (eventTime - lastAt) < throttleSeconds then
		return false
	end

	perMatch[eventName] = eventTime
	self:_publish(eventName, payload)
	return true
end

function GhostService:SpawnGhost(matchId, payload)
    local sessions = self._state:Get("sessions") or {}
    if self._activeGhosts[matchId] or sessions[matchId] then
        warn("[GhostSystem] Ghost already exists for " .. tostring(matchId))
        return sessions[matchId]
    end
	local session = self._ai:CreateSession(matchId, payload or {})
	sessions[matchId] = session
	self._state:Set("sessions", sessions)
	self._activeGhosts[matchId] = true

	self:_publish("GhostSpawned", {
		matchId = matchId,
		ghostType = session.ghostType,
		favoriteRoomId = session.favoriteRoomId,
		personality = session.personality,
		personalityTraits = session.personality and session.personality.traits or {},
	})
	self:_publish("GhostPersonalitySelected", {
		matchId = matchId,
		ghostType = session.ghostType,
		personalityType = session.personality and session.personality.type or "Default",
		traits = session.personality and session.personality.traits or {},
	})

	return session
end

function GhostService:TickGhost(matchId, snapshot, dt, now)
    local t0 = tick()
	local currentNow = now or os.clock()
	local lastTickAt = self._lastTickAtByMatch[matchId] or 0
	if (currentNow - lastTickAt) < (self._config.MinTickIntervalSeconds or 0) then
		return nil, "throttled_tick"
	end
	self._lastTickAtByMatch[matchId] = currentNow

	local sessionBefore = self._ai:GetSession(matchId)
	local previousRoomId = sessionBefore and sessionBefore.currentRoomId or nil

	local session, huntEvent, runtimeEvents = self._ai:Tick(matchId, snapshot, dt, currentNow)
	if not session then
		return nil
	end

	if previousRoomId ~= nil and previousRoomId ~= session.currentRoomId then
		self:_publishThrottled(matchId, "GhostRoamed", {
			matchId = matchId,
			room = session.currentRoomId,
		}, currentNow)
	end

	if huntEvent == "started" then
		self:_publish("HuntStarted", { matchId = matchId })
	elseif huntEvent == "ended" then
		self:_publish("HuntEnded", { matchId = matchId })
	end

	local processedEvents = 0
	local maxRuntimeEvents = self._config.MaxRuntimeEventsPerTick or 0
	for _, runtimeEvent in ipairs(runtimeEvents or {}) do
		processedEvents += 1
		if maxRuntimeEvents > 0 and processedEvents > maxRuntimeEvents then
			warn(string.format("[GhostService] Dropped runtime events for match '%s' after %d events in one tick", tostring(matchId), maxRuntimeEvents))
			break
		end

		if runtimeEvent.type == "state_changed" then
			self:_publish("GhostStateChanged", {
				matchId = matchId,
				previousState = runtimeEvent.previousState,
				currentState = runtimeEvent.currentState,
			})
		elseif runtimeEvent.type == "interaction" then
			local payload = runtimeEvent.payload or {}
			self:_publishThrottled(matchId, "GhostInteraction", {
				matchId = matchId,
				room = payload.roomId or session.currentRoomId,
				interactionType = payload.interactionType or "Environmental",
				intensity = payload.intensity or 1,
				now = currentNow,
			}, currentNow)
		elseif runtimeEvent.type == "evidence_triggered" then
			local payload = runtimeEvent.payload or {}
			self:_publishThrottled(matchId, "EvidenceTriggered", {
				matchId = matchId,
				evidenceType = payload.evidenceType,
				room = payload.roomId,
				chance = payload.chance,
				isFake = payload.isFake == true,
			}, currentNow)
			if payload.isFake == true then
				self:_publishThrottled(matchId, "GhostFakeEvidenceSpawned", {
					matchId = matchId,
					evidenceType = payload.evidenceType,
					room = payload.roomId,
					chance = payload.chance,
				}, currentNow)
			elseif self._evidenceService and payload.evidenceType then
				self._evidenceService:SpawnEvidence(matchId, {
					source = "ghost_ai",
					evidenceType = payload.evidenceType,
					roomId = payload.roomId,
					activity = payload.chance or 0,
					now = currentNow,
				})
			end
		elseif runtimeEvent.type == "personality_selected" then
			self:_publish("GhostPersonalitySelected", {
				matchId = matchId,
				personalityType = runtimeEvent.personalityType,
			})
		elseif runtimeEvent.type == "decision_made" then
			self:_publishThrottled(matchId, "GhostDecisionMade", {
				matchId = matchId,
				decision = runtimeEvent.decision,
				now = runtimeEvent.now,
			}, currentNow)
		elseif runtimeEvent.type == "deception_triggered" then
			self:_publishThrottled(matchId, "GhostDeceptionTriggered", {
				matchId = matchId,
				deceptionType = runtimeEvent.deceptionType,
				reason = runtimeEvent.reason,
				now = runtimeEvent.now,
			}, currentNow)
			if runtimeEvent.reason == "investigation_reaction" then
				self:_publishThrottled(matchId, "GhostDecisionMade", {
					matchId = matchId,
					decision = runtimeEvent.deceptionType,
					now = runtimeEvent.now,
				}, currentNow)
			end
			if runtimeEvent.deceptionType == "fake_ghost_sound" then
				self:_publishThrottled(matchId, "GhostInteraction", {
					matchId = matchId,
					room = session.currentRoomId,
					interactionType = "FakeGhostSound",
					intensity = 0.75,
					now = runtimeEvent.now,
				}, currentNow)
			elseif runtimeEvent.deceptionType == "fake_footsteps" then
				self:_publishThrottled(matchId, "GhostInteraction", {
					matchId = matchId,
					room = session.currentRoomId,
					interactionType = "FakeFootsteps",
					intensity = 0.7,
					now = runtimeEvent.now,
				}, currentNow)
			elseif runtimeEvent.deceptionType == "fake_manifestation" then
				self:_publishThrottled(matchId, "GhostInteraction", {
					matchId = matchId,
					room = session.currentRoomId,
					interactionType = "FakeManifestation",
					intensity = 0.85,
					now = runtimeEvent.now,
				}, currentNow)
			end
		elseif runtimeEvent.type == "strategy_changed" then
			self:_publishThrottled(matchId, "GhostStrategyChanged", {
				matchId = matchId,
				strategyCategory = runtimeEvent.strategyCategory,
				previousStrategy = runtimeEvent.previousStrategy,
				currentStrategy = runtimeEvent.currentStrategy,
				now = runtimeEvent.now,
			}, currentNow)
		elseif runtimeEvent.type == "ability_triggered" then
			self:_publishThrottled(matchId, "GhostAbilityTriggered", {
				matchId = matchId,
				abilityType = runtimeEvent.abilityType,
				category = runtimeEvent.category,
				cooldown = runtimeEvent.cooldown,
				duration = runtimeEvent.duration,
				now = runtimeEvent.now,
			}, currentNow)
		elseif runtimeEvent.type == "ability_cooldown" then
			self:_publishThrottled(matchId, "GhostAbilityCooldown", {
				matchId = matchId,
				abilityType = runtimeEvent.abilityType,
				cooldownEndsAt = runtimeEvent.cooldownEndsAt,
				now = runtimeEvent.now,
			}, currentNow)
		elseif runtimeEvent.type == "ability_completed" then
			self:_publishThrottled(matchId, "GhostAbilityCompleted", {
				matchId = matchId,
				abilityType = runtimeEvent.abilityType,
				now = runtimeEvent.now,
			}, currentNow)
		elseif runtimeEvent.type == "favorite_room_changed" then
			self:_publishThrottled(matchId, "GhostDecisionMade", {
				matchId = matchId,
				decision = "change_favorite_room",
				previousRoomId = runtimeEvent.previousRoomId,
				currentRoomId = runtimeEvent.currentRoomId,
			}, currentNow)
		end
	end

	local elapsed = tick() - t0
	if elapsed > 0.1 then
		warn("[PERF] GhostService:TickGhost exceeded 100ms: " .. elapsed)
	end
	return session
end

function GhostService:StartHunt(matchId, snapshot, now)
	local started, strategyEvent = self._ai:StartHunt(matchId, snapshot or {}, now)
	if started then
		self:_publish("HuntStarted", { matchId = matchId })
	end
	if strategyEvent then
		self:_publish("GhostStrategyChanged", {
			matchId = matchId,
			strategyCategory = strategyEvent.strategyCategory,
			previousStrategy = strategyEvent.previousStrategy,
			currentStrategy = strategyEvent.currentStrategy,
			now = strategyEvent.now,
		})
	end
	return started
end

function GhostService:TransitionGhostState(matchId, stateName, now, snapshot)
	return self._ai:TransitionState(matchId, stateName, now, snapshot)
end

function GhostService:EndHunt(matchId, now)
	local ended = self._ai:EndHunt(matchId, now)
	if ended then
		self:_publish("HuntEnded", { matchId = matchId })
	end
	return ended
end

function GhostService:GetGhostState(matchId)
	local session = self._ai:GetSession(matchId)
	if not session then
		return nil
	end

	return {
		matchId = session.matchId,
		state = session.currentState,
		currentRoomId = session.currentRoomId,
		favoriteRoomId = session.favoriteRoomId,
		aggression = session.aggression,
		huntActive = session.hunt.active,
		huntTargetUserId = session.hunt.targetUserId,
		doorsLocked = session.hunt.doorsLocked,
		exitsDisabled = session.hunt.exitsDisabled,
		navigationPath = session.hunt.navigationPath,
		personality = session.personality,
		abilities = session.abilities and session.abilities.registered or nil,
	}
end

function GhostService:DespawnGhost(matchId)
	self._ai:RemoveSession(matchId)
	local sessions = self._state:Get("sessions") or {}
	sessions[matchId] = nil
	self._state:Set("sessions", sessions)
	self._lastTickAtByMatch[matchId] = nil
	self._lastPublishedAtByMatch[matchId] = nil
	self._activeGhosts[matchId] = nil
end

function GhostService:ApplyDirectorEvent(matchId, eventName, payload)
	return self._ai:ApplyDirectorEvent(matchId, eventName, payload)
end

function GhostService:ForceManifest(matchId, now)
	return self._ai:ForceManifest(matchId, now)
end

function GhostService:DevTestGhost(matchId)
	local testMatchId = matchId or "DEV_TEST_MATCH"

	-- Spawn a test ghost session if none exists
	local existing = self._ai:GetSession(testMatchId)
	if not existing then
		self:SpawnGhost(testMatchId, {
			ghostType = "Pocong",
			personalityType = "Aggressive",
			roomIds = { "RoomA", "RoomB", "RoomC", "RoomD" },
			initialAggression = 60,
			difficultyProfile = {
				GhostAggression = 1.5,
				HuntFrequency = 1.5,
			},
		})
	end

	-- Simulate 10 ticks with low sanity snapshot
	local now = os.clock()
	for i = 1, 10 do
		local snapshot = {
			averageSanity = 20,
			players = {
				{
					userId = 1,
					isAlive = true,
					sanity = 20,
					roomId = "RoomA",
					distanceToGhost = 10,
					isVisible = true,
					noiseLevel = 0.8,
					nearbyTeammates = 0,
				},
			},
			playerNearGhost = true,
			playerNearFavoriteRoom = true,
			nearFavoriteRoomCount = 1,
			roomActivity = { RoomA = 0.8 },
		}
		local tickNow = now + (i * 1.5)
		self:TickGhost(testMatchId, snapshot, 1.5, tickNow)
	end
end

return GhostService
