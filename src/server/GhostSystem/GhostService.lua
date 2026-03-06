local GhostAI = require(script.Parent.GhostAI)

local GhostService = {}
GhostService.__index = GhostService

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

local function resolveEvidenceService(deps)
	local evidenceSystem = deps.EvidenceSystem
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
	self._eventBus = resolveEventBus(self._deps)
	self._evidenceService = resolveEvidenceService(self._deps)
	self._ai = GhostAI.new(self._deps, self._deps.GhostConfig or {})
	return self
end

function GhostService:Init()
	self._state:Set("sessions", {})
end

function GhostService:Start()
	-- Runtime loop should be orchestrated by higher-level scheduler.
end

function GhostService:Stop()
	local sessions = self._state:Get("sessions") or {}
	for matchId in pairs(sessions) do
		self._ai:RemoveSession(matchId)
	end
	self._state:Set("sessions", {})
end

function GhostService:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function GhostService:SpawnGhost(matchId, payload)
	local session = self._ai:CreateSession(matchId, payload or {})
	local sessions = self._state:Get("sessions") or {}
	sessions[matchId] = session
	self._state:Set("sessions", sessions)

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
	local sessionBefore = self._ai:GetSession(matchId)
	local previousRoomId = sessionBefore and sessionBefore.currentRoomId or nil

	local session, huntEvent, runtimeEvents = self._ai:Tick(matchId, snapshot, dt, now)
	if not session then
		return nil
	end

	if previousRoomId ~= nil and previousRoomId ~= session.currentRoomId then
		self:_publish("GhostRoamed", {
			matchId = matchId,
			room = session.currentRoomId,
		})
	end

	if huntEvent == "started" then
		self:_publish("HuntStarted", { matchId = matchId })
	elseif huntEvent == "ended" then
		self:_publish("HuntEnded", { matchId = matchId })
	end

	for _, runtimeEvent in ipairs(runtimeEvents or {}) do
		if runtimeEvent.type == "state_changed" then
			self:_publish("GhostStateChanged", {
				matchId = matchId,
				previousState = runtimeEvent.previousState,
				currentState = runtimeEvent.currentState,
			})
		elseif runtimeEvent.type == "interaction" then
			local payload = runtimeEvent.payload or {}
			self:_publish("GhostInteraction", {
				matchId = matchId,
				room = payload.roomId or session.currentRoomId,
				interactionType = payload.interactionType or "Environmental",
				intensity = payload.intensity or 1,
				now = now,
			})
		elseif runtimeEvent.type == "evidence_triggered" then
			local payload = runtimeEvent.payload or {}
			self:_publish("EvidenceTriggered", {
				matchId = matchId,
				evidenceType = payload.evidenceType,
				room = payload.roomId,
				chance = payload.chance,
				isFake = payload.isFake == true,
			})
			if payload.isFake == true then
				self:_publish("GhostFakeEvidenceSpawned", {
					matchId = matchId,
					evidenceType = payload.evidenceType,
					room = payload.roomId,
					chance = payload.chance,
				})
			elseif self._evidenceService and payload.evidenceType then
				self._evidenceService:SpawnEvidence(matchId, {
					source = "ghost_ai",
					evidenceType = payload.evidenceType,
					roomId = payload.roomId,
					activity = payload.chance or 0,
					now = now,
				})
			end
		elseif runtimeEvent.type == "personality_selected" then
			self:_publish("GhostPersonalitySelected", {
				matchId = matchId,
				personalityType = runtimeEvent.personalityType,
			})
		elseif runtimeEvent.type == "decision_made" then
			self:_publish("GhostDecisionMade", {
				matchId = matchId,
				decision = runtimeEvent.decision,
				now = runtimeEvent.now,
			})
		elseif runtimeEvent.type == "deception_triggered" then
			self:_publish("GhostDeceptionTriggered", {
				matchId = matchId,
				deceptionType = runtimeEvent.deceptionType,
				reason = runtimeEvent.reason,
				now = runtimeEvent.now,
			})
			if runtimeEvent.reason == "investigation_reaction" then
				self:_publish("GhostDecisionMade", {
					matchId = matchId,
					decision = runtimeEvent.deceptionType,
					now = runtimeEvent.now,
				})
			end
			if runtimeEvent.deceptionType == "fake_ghost_sound" then
				self:_publish("GhostInteraction", {
					matchId = matchId,
					room = session.currentRoomId,
					interactionType = "FakeGhostSound",
					intensity = 0.75,
					now = runtimeEvent.now,
				})
			elseif runtimeEvent.deceptionType == "fake_footsteps" then
				self:_publish("GhostInteraction", {
					matchId = matchId,
					room = session.currentRoomId,
					interactionType = "FakeFootsteps",
					intensity = 0.7,
					now = runtimeEvent.now,
				})
			elseif runtimeEvent.deceptionType == "fake_manifestation" then
				self:_publish("GhostInteraction", {
					matchId = matchId,
					room = session.currentRoomId,
					interactionType = "FakeManifestation",
					intensity = 0.85,
					now = runtimeEvent.now,
				})
			end
		elseif runtimeEvent.type == "strategy_changed" then
			self:_publish("GhostStrategyChanged", {
				matchId = matchId,
				strategyCategory = runtimeEvent.strategyCategory,
				previousStrategy = runtimeEvent.previousStrategy,
				currentStrategy = runtimeEvent.currentStrategy,
				now = runtimeEvent.now,
			})
		elseif runtimeEvent.type == "ability_triggered" then
			self:_publish("GhostAbilityTriggered", {
				matchId = matchId,
				abilityType = runtimeEvent.abilityType,
				category = runtimeEvent.category,
				cooldown = runtimeEvent.cooldown,
				duration = runtimeEvent.duration,
				now = runtimeEvent.now,
			})
		elseif runtimeEvent.type == "ability_cooldown" then
			self:_publish("GhostAbilityCooldown", {
				matchId = matchId,
				abilityType = runtimeEvent.abilityType,
				cooldownEndsAt = runtimeEvent.cooldownEndsAt,
				now = runtimeEvent.now,
			})
		elseif runtimeEvent.type == "ability_completed" then
			self:_publish("GhostAbilityCompleted", {
				matchId = matchId,
				abilityType = runtimeEvent.abilityType,
				now = runtimeEvent.now,
			})
		elseif runtimeEvent.type == "favorite_room_changed" then
			self:_publish("GhostDecisionMade", {
				matchId = matchId,
				decision = "change_favorite_room",
				previousRoomId = runtimeEvent.previousRoomId,
				currentRoomId = runtimeEvent.currentRoomId,
			})
		end
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
end

function GhostService:ApplyDirectorEvent(matchId, eventName, payload)
	return self._ai:ApplyDirectorEvent(matchId, eventName, payload)
end

function GhostService:ForceManifest(matchId, now)
	return self._ai:ForceManifest(matchId, now)
end

return GhostService
