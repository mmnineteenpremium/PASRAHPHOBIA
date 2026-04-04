local GhostStateMachine = require(script.Parent.GhostStateMachine)
local GhostHuntController = require(script.Parent.GhostHuntController)
local GhostRoamingController = require(script.Parent.GhostRoamingController)
local GhostTargeting = require(script.Parent.GhostTargeting)
local GhostAggression = require(script.Parent.GhostAggression)
local GhostPersonalityEngine = require(script.Parent.GhostPersonalityEngine)
local GhostRoomPreference = require(script.Parent.GhostRoomPreference)
local GhostEvidenceController = require(script.Parent.GhostEvidenceController)
local GhostIntelligence = require(script.Parent.GhostIntelligence)
local GhostAbilityEngine = require(script.Parent.GhostAbilityEngine)

local GhostAI = {}
GhostAI.__index = GhostAI

local DEFAULT_CONFIG = {
	LoopInterval = 1.5,
	DefaultRoomIds = { "RoomA", "RoomB", "RoomC", "RoomD" },
	Aggression = {},
	Hunt = {},
	Roaming = {},
	RoomPreference = {},
	Evidence = {},
	InteractDuration = 5,
	InteractPulseInterval = 2.0,
	RetreatDuration = 6,
	ManifestDuration = 2.5,
	IdleMinDuration = 2.5,
	IdleMaxDuration = 5.5,
	RoamShiftInterval = 5,
	InvestigationNoiseThreshold = 0.5,
	ManifestAggressionThreshold = 45,
	ManifestChanceWhileRoaming = 0.1,
	ManifestChanceWhileInteracting = 0.2,
	DisturbedRetreatChance = 0.4,
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = deepCopy(nestedValue)
	end
	return copy
end

local function mergeConfig(baseConfig, overrideConfig)
	local merged = deepCopy(baseConfig)
	for key, value in pairs(overrideConfig or {}) do
		if type(value) == "table" and type(merged[key]) == "table" then
			merged[key] = mergeConfig(merged[key], value)
		else
			merged[key] = value
		end
	end
	return merged
end

local function getNow(now)
	return now or os.clock()
end

local function resolveGhostTypeData(deps, payload)
	if type(payload.ghostTypeData) == "table" then
		return payload.ghostTypeData
	end

	local ghostType = payload.ghostType
	if type(ghostType) ~= "string" then
		return nil
	end

	local ghostMaps = {
		deps.GhostTypes,
		deps.GhostTypeMap,
		deps.GhostData,
	}
	for _, ghostMap in ipairs(ghostMaps) do
		if type(ghostMap) == "table" and type(ghostMap[ghostType]) == "table" then
			return ghostMap[ghostType]
		end
	end
	return nil
end

function GhostAI.new(deps, config)
	local self = setmetatable({}, GhostAI)
	self._deps = deps or {}
	self._config = mergeConfig(DEFAULT_CONFIG, config or {})
	self._rng = self._deps.Random or Random.new()

	self._stateMachine = GhostStateMachine.new()
	self._aggression = GhostAggression.new(self._config.Aggression)
	self._targeting = GhostTargeting.new()
	self._roaming = GhostRoamingController.new(self._config.Roaming, self._rng)
	self._huntController = GhostHuntController.new(self._config.Hunt, self._rng)
	self._personalityEngine = GhostPersonalityEngine.new(self._config, self._rng)
	self._roomPreference = GhostRoomPreference.new(self._config.RoomPreference, self._rng)
	self._evidenceController = GhostEvidenceController.new(self._config.Evidence, self._rng)
	self._intelligence = GhostIntelligence.new(self._rng)
	self._abilityEngine = GhostAbilityEngine.new(self._config.Abilities or {}, self._rng)
	self._sessions = {}
	return self
end

function GhostAI:CreateSession(matchId, payload)
	local roomIds = payload.roomIds or self._config.DefaultRoomIds
	local roomContext = self._roomPreference:BuildRoomContext(payload.roomGraph)
	local ghostTypeData = resolveGhostTypeData(self._deps, payload)
	local personality = self._personalityEngine:Resolve(ghostTypeData, payload)
	local evidenceSet = payload.evidenceSet or (ghostTypeData and ghostTypeData.evidence)
	local favoriteRoomId = payload.favoriteRoomId
		or self._roomPreference:SelectFavoriteRoom(roomIds, payload.roomSpawnRules, personality)
		or self._roaming:ChooseFavoriteRoom(roomIds)

	local session = {
		matchId = matchId,
		ghostType = payload.ghostType or "UnknownGhost",
		ghostTypeData = ghostTypeData,
		roomIds = roomIds,
		roomAdjacency = roomContext.roomAdjacency,
		favoriteRoomId = favoriteRoomId,
		currentRoomId = favoriteRoomId,
		aggression = payload.initialAggression or 0,
		currentState = "Idle",
		stateEnteredAt = getNow(payload.now),
		nextThinkAt = 0,
		nextHuntAllowedAt = 0,
		hunt = {
			active = false,
			targetUserId = nil,
			startedAt = 0,
			endsAt = 0,
			lastEndedAt = 0,
			doorsLocked = false,
			exitsDisabled = false,
			navigationPath = nil,
		},
		personality = personality,
		evidenceSet = evidenceSet,
		difficulty = payload.difficulty,
		mode = payload.mode or "Classic",
		difficultyProfile = payload.difficultyProfile or {},
		nextEvidenceAllowedAt = 0,
		director = {
			tensionHighUntil = 0,
			forceManifestUntil = 0,
		},
		disturbed = false,
		stateData = {},
		_destroyed = false,
	}
	self._intelligence:InitializeSession(session)
	self._abilityEngine:InitializeSession(session)

	self._sessions[matchId] = session
	return session
end

function GhostAI:RemoveSession(matchId)
	local session = self._sessions[matchId]
	if session then
		session._destroyed = true
	end
	self._sessions[matchId] = nil
end

function GhostAI:GetSession(matchId)
	return self._sessions[matchId]
end

function GhostAI:ApplyDirectorEvent(matchId, eventName, payload)
	local session = self._sessions[matchId]
	if not session then
		return false
	end

	local now = getNow(payload and payload.now)
	if eventName == "TensionHigh" then
		local duration = (payload and payload.duration) or 10
		session.director.tensionHighUntil = math.max(session.director.tensionHighUntil or 0, now + duration)
		session.aggression = math.min(100, (session.aggression or 0) + ((payload and payload.aggressionBoost) or 8))
		return true
	end
	if eventName == "ForceManifest" then
		local duration = (payload and payload.duration) or 8
		session.director.forceManifestUntil = math.max(session.director.forceManifestUntil or 0, now + duration)
		return true
	end
	return false
end

function GhostAI:ForceManifest(matchId, now)
	local session = self._sessions[matchId]
	if not session then
		return false
	end
	session.director.forceManifestUntil = math.max(session.director.forceManifestUntil or 0, getNow(now) + 5)
	return true
end

function GhostAI:StartHunt(matchId, snapshot, now)
	local session = self._sessions[matchId]
	if not session then
		return false
	end
	if session.hunt.active then
		return false
	end

	local strategyEvent = self._intelligence:SelectHuntStrategy(session, snapshot or {}, getNow(now))
	local target = self._targeting:SelectTarget(session, snapshot or {}, session.hunt.strategy, self._rng)
	self._huntController:StartHunt(session, target, getNow(now))
	return true, strategyEvent
end

function GhostAI:EndHunt(matchId, now)
	local session = self._sessions[matchId]
	if not session or not session.hunt.active then
		return false
	end
	self._huntController:EndHunt(session, getNow(now))
	return true
end

function GhostAI:Tick(matchId, snapshot, dt, now)
	local session = self._sessions[matchId]
	if not session then
		return nil, "missing_session", {}
	end

	local currentTime = getNow(now)
	local deltaTime = dt or self._config.LoopInterval
	local safeSnapshot = snapshot or {}
	safeSnapshot.now = currentTime
	local previousHuntActive = session.hunt.active
	local previousState = session.currentState
	local runtimeEvents = {}

	if safeSnapshot.disturbed == true or safeSnapshot.cursedObjectUsed == true then
		session.disturbed = true
	end

	if self._roomPreference:ShouldChangeFavoriteRoom(session, safeSnapshot) then
		local previousFavorite = session.favoriteRoomId
		session.favoriteRoomId = self._roomPreference:ChooseNewFavoriteRoom(session)
		if session.favoriteRoomId ~= previousFavorite then
			table.insert(runtimeEvents, {
				type = "favorite_room_changed",
				previousRoomId = previousFavorite,
				currentRoomId = session.favoriteRoomId,
			})
		end
	end

	self._aggression:Update(session, safeSnapshot, deltaTime)

	if not session.hunt.active and self._huntController:CanStartHunt(session, safeSnapshot, currentTime, self._aggression) then
		local strategyEvent = self._intelligence:SelectHuntStrategy(session, safeSnapshot, currentTime)
		if strategyEvent then
			table.insert(runtimeEvents, strategyEvent)
		end
		local target = self._targeting:SelectTarget(session, safeSnapshot, session.hunt.strategy, self._rng)
		self._huntController:StartHunt(session, target, currentTime)
	end

	local huntStatus = self._huntController:Update(session, safeSnapshot, currentTime, self._targeting)

	local context = {
		now = currentTime,
		snapshot = safeSnapshot,
		rng = self._rng,
		config = self._config,
		roaming = self._roaming,
		targeting = self._targeting,
		huntController = self._huntController,
		difficultyProfile = session.difficultyProfile or {},
		stateMachine = self._stateMachine,
		emit = function(eventType, payload)
			table.insert(runtimeEvents, {
				type = eventType,
				payload = payload or {},
			})
		end,
	}

	if session.director.forceManifestUntil and currentTime <= session.director.forceManifestUntil and not session.hunt.active then
		self._stateMachine:TransitionTo(session, "Manifest", context)
	end

	for _, intelligenceEvent in ipairs(self._intelligence:Tick(session, safeSnapshot, currentTime, {
		roaming = self._roaming,
	}) or {}) do
		table.insert(runtimeEvents, intelligenceEvent)
	end

	for _, abilityEvent in ipairs(self._abilityEngine:Tick(session, safeSnapshot, currentTime, {
		roaming = self._roaming,
	}) or {}) do
		table.insert(runtimeEvents, abilityEvent)
	end

	self._stateMachine:Tick(session, context)

	local huntLifecycleEvent = nil
	if not previousHuntActive and session.hunt.active then
		huntLifecycleEvent = "started"
	elseif previousHuntActive and not session.hunt.active then
		huntLifecycleEvent = "ended"
	elseif huntStatus == "active" then
		huntLifecycleEvent = "active"
	end

	if previousState ~= session.currentState then
		table.insert(runtimeEvents, {
			type = "state_changed",
			previousState = previousState,
			currentState = session.currentState,
		})
	end

	local hideEvidenceUntil = session.stateData.hideEvidenceUntil or 0
	if currentTime > hideEvidenceUntil then
		local evidenceEvent = self._evidenceController:TryTrigger(session, safeSnapshot, currentTime)
		if evidenceEvent then
			table.insert(runtimeEvents, {
				type = "evidence_triggered",
				payload = evidenceEvent,
			})
		end
	end

	return session, huntLifecycleEvent, runtimeEvents
end

function GhostAI:TransitionState(matchId, stateName, now, snapshot)
	local session = self._sessions[matchId]
	if not session then
		return false
	end
	local currentTime = getNow(now)
	local context = {
		now = currentTime,
		snapshot = snapshot or {},
		rng = self._rng,
		config = self._config,
		roaming = self._roaming,
		targeting = self._targeting,
		huntController = self._huntController,
		difficultyProfile = session.difficultyProfile or {},
		stateMachine = self._stateMachine,
		emit = function() end,
	}
	self._stateMachine:TransitionTo(session, stateName, context)
	return true
end

function GhostAI:Start(match)
	local ghost = match and match.ghost
	local machine = GhostStateMachine.new(ghost)
	if ghost then
		ghost.stateMachine = machine
	end
	machine:Start()
end

return GhostAI
