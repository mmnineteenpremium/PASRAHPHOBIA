local EvidenceEngine = require(script.Parent.EvidenceEngine)
local EvidenceSpawner = require(script.Parent.EvidenceSpawner)
local EvidenceValidator = require(script.Parent.EvidenceValidator)
local EvidenceTracker = require(script.Parent.EvidenceTracker)
local EvidenceDeduction = require(script.Parent.EvidenceDeduction)
local EvidenceDataTypes = require(script.Parent.EvidenceDataTypes)
local EvidenceRandomizer = require(script.Parent.Parent.EvidenceRandomizer)
local Services = require(script.Parent.Parent.Parent.Core.Services)

local EvidenceService = {}
EvidenceService.__index = EvidenceService

local TOOL_TO_EVIDENCE = {
	BolaArwah = "BolaArwah",
	BukuTerkutuk = "BukuTerkutuk",
	GerakanGaib = "GerakanGaib",
	JejakEnergi = "JejakEnergi",
	KotakArwah = "KotakArwah",
	SuhuMembeku = "SuhuMembeku",
}

local EVIDENCE_ALIASES = {
	emflevel = "EMFLevel",
	emf5 = "EMFLevel",
	jejakenergi = "EMFLevel",
	spiritboxresponse = "SpiritBoxResponse",
	spiritbox = "SpiritBoxResponse",
	kotakarwah = "SpiritBoxResponse",
	freezingtemperature = "FreezingTemperature",
	freezingtemp = "FreezingTemperature",
	suhumembeku = "FreezingTemperature",
	uvmarks = "UVMarks",
	dots = "UVMarks",
	gerakangaib = "UVMarks",
	ghostwriting = "GhostWriting",
	writingbook = "GhostWriting",
	bukuterkutuk = "GhostWriting",
	ghostorb = "GhostOrb",
	bolaarwah = "GhostOrb",
}

local function normalizeGhostTypeKey(ghostType)
	if type(ghostType) ~= "string" then
		return nil
	end
	return ghostType:gsub("[%s_%-]+", ""):lower()
end

local function normalizeEvidenceType(evidenceType)
	if type(evidenceType) ~= "string" then
		return nil
	end
	local token = evidenceType:gsub("[%s_%-]+", ""):lower()
	return EVIDENCE_ALIASES[token] or evidenceType
end

local function normalizeEvidenceList(list)
	local out = {}
	local seen = {}
	for _, evidenceType in ipairs(list or {}) do
		local canonical = normalizeEvidenceType(evidenceType)
		if type(canonical) == "string" and canonical ~= "" and not seen[canonical] then
			seen[canonical] = true
			table.insert(out, canonical)
		end
	end
	table.sort(out)
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

local function resolveGhostService(deps)
	local ghostSystem = Services.Get(deps, "GhostSystem")
	if type(ghostSystem) ~= "table" then
		return nil
	end
	if type(ghostSystem.GetGhostState) == "function" then
		return ghostSystem
	end
	if type(ghostSystem.Service) == "table" and type(ghostSystem.Service.GetGhostState) == "function" then
		return ghostSystem.Service
	end
	return nil
end

local function resolveEvidenceConfigSystem(deps)
	local evidenceConfig = Services.Get(deps, "EvidenceConfigSystem")
	if type(evidenceConfig) ~= "table" then
		return nil
	end
	if type(evidenceConfig.GetEvidenceCombinations) == "function" then
		return evidenceConfig
	end
	if type(evidenceConfig.Service) == "table" and type(evidenceConfig.Service.GetEvidenceCombinations) == "function" then
		return evidenceConfig.Service
	end
	return nil
end

local function resolveEvidenceSync(deps)
	local evidenceSync = Services.Get(deps, "EvidenceSync")
	if type(evidenceSync) ~= "table" then
		return nil
	end
	if type(evidenceSync.PushUpdate) == "function" then
		return evidenceSync
	end
	if type(evidenceSync.Service) == "table" and type(evidenceSync.Service.PushUpdate) == "function" then
		return evidenceSync.Service
	end
	return nil
end

function EvidenceService.new(state, deps)
	local self = setmetatable({}, EvidenceService)
	self._state = state
	self._deps = deps or {}
	self._dataTypes = EvidenceDataTypes.Resolve(self._deps)
	self._eventBus = resolveEventBus(self._deps)
	self._ghostService = resolveGhostService(self._deps)
	self._evidenceSync = resolveEvidenceSync(self._deps)
	self._evidenceConfigSystem = resolveEvidenceConfigSystem(self._deps)

	self._deduction = EvidenceDeduction.new(self._dataTypes.EvidenceGhostMap)
	self._tracker = EvidenceTracker.new()
	self._spawner = EvidenceSpawner.new({
		Random = self._deps.Random,
		EvidenceTypes = self._dataTypes.EvidenceTypes,
		EvidenceRules = self._dataTypes.EvidenceRules,
	})
	self._validator = EvidenceValidator.new({
		Deduction = self._deduction,
		EvidenceRules = self._dataTypes.EvidenceRules,
	})
	self._randomizer = EvidenceRandomizer.new({
		Random = self._deps.Random,
		EvidenceRandomizerConfig = self._deps.EvidenceRandomizerConfig,
	})
	self._engine = EvidenceEngine.new({
		Spawner = self._spawner,
		Validator = self._validator,
		Tracker = self._tracker,
		Deduction = self._deduction,
	})

	return self
end

function EvidenceService:_sync(matchId, eventType, payload)
	if self._evidenceSync then
		self._evidenceSync:PushUpdate(matchId, eventType, payload)
	end
end

function EvidenceService:Init()
	self._state:Set("evidenceMatches", {})
	self._randomizer:Reset()
end

function EvidenceService:Start()
	-- Runtime ticks are driven by controller events.
end

function EvidenceService:Stop()
	self._engine:Reset()
	self._randomizer:Reset()
	self._state:Set("evidenceMatches", {})
end

function EvidenceService:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function EvidenceService:_resolveEvidenceCombinations()
	if not self._evidenceConfigSystem then
		return {}
	end
	local combinations = self._evidenceConfigSystem:GetEvidenceCombinations()
	if type(combinations) ~= "table" then
		return {}
	end
	return combinations
end

function EvidenceService:_resolveCombinationForGhost(combinations, ghostType)
	if type(ghostType) ~= "string" then
		return nil
	end

	local direct = combinations[ghostType]
	if type(direct) == "table" then
		return normalizeEvidenceList(direct)
	end

	local normalizedGhostType = normalizeGhostTypeKey(ghostType)
	if not normalizedGhostType then
		return nil
	end

	for candidateGhostType, evidenceList in pairs(combinations) do
		if normalizeGhostTypeKey(candidateGhostType) == normalizedGhostType and type(evidenceList) == "table" then
			return normalizeEvidenceList(evidenceList)
		end
	end

	return nil
end

function EvidenceService:_resolveCombinationCandidates(combinations, collectedEvidence)
	local canonicalCollected = normalizeEvidenceList(collectedEvidence)
	local collectedSet = {}
	for _, evidenceType in ipairs(canonicalCollected) do
		collectedSet[evidenceType] = true
	end

	local candidateGhosts = {}
	local exactMatches = {}

	for ghostType, expectedEvidence in pairs(combinations) do
		local normalizedExpected = normalizeEvidenceList(expectedEvidence)
		local expectedSet = {}
		for _, evidenceType in ipairs(normalizedExpected) do
			expectedSet[evidenceType] = true
		end

		local possible = true
		for evidenceType in pairs(collectedSet) do
			if not expectedSet[evidenceType] then
				possible = false
				break
			end
		end
		if possible then
			table.insert(candidateGhosts, ghostType)
		end

		local exact = #normalizedExpected == #canonicalCollected
		if exact then
			for evidenceType in pairs(collectedSet) do
				if not expectedSet[evidenceType] then
					exact = false
					break
				end
			end
		end
		if exact then
			table.insert(exactMatches, ghostType)
		end
	end

	table.sort(candidateGhosts)
	table.sort(exactMatches)

	local resolvedGhostType = nil
	if #exactMatches == 1 then
		resolvedGhostType = exactMatches[1]
	end

	return canonicalCollected, candidateGhosts, resolvedGhostType
end

function EvidenceService:_publishCombinationResolution(player, matchId, now)
	local combinations = self:_resolveEvidenceCombinations()
	if next(combinations) == nil then
		return
	end

	local session = self._engine:GetSession(matchId)
	if not session then
		return
	end

	local canonicalCollected, candidateGhosts, resolvedGhostType =
		self:_resolveCombinationCandidates(combinations, session.collectedEvidence)

	self:_publish("EvidenceCombinationResolved", {
		player = player,
		userId = player and player.UserId or nil,
		matchId = matchId,
		collectedEvidence = canonicalCollected,
		possibleGhosts = candidateGhosts,
		resolvedGhostType = resolvedGhostType,
		now = now,
	})
	self:_publish("GhostCandidatesUpdated", {
		player = player,
		userId = player and player.UserId or nil,
		matchId = matchId,
		candidates = candidateGhosts,
		discoveredEvidence = canonicalCollected,
	})
end

function EvidenceService:_validateCombinationJournalGuess(matchId, payload)
	local combinations = self:_resolveEvidenceCombinations()
	if next(combinations) == nil then
		return nil
	end

	local session = self._engine:GetSession(matchId)
	if not session then
		return nil
	end

	local expectedEvidence = self:_resolveCombinationForGhost(combinations, session.ghostType)
	if type(expectedEvidence) ~= "table" then
		return nil
	end

	local guessedGhostType = payload and payload.ghostType or ""
	local guessedEvidence = normalizeEvidenceList(payload and payload.evidence or {})
	local guessedEvidenceSet = {}
	for _, evidenceType in ipairs(guessedEvidence) do
		guessedEvidenceSet[evidenceType] = true
	end

	local expectedEvidenceSet = {}
	for _, evidenceType in ipairs(expectedEvidence) do
		expectedEvidenceSet[evidenceType] = true
	end

	local evidenceMatches = #guessedEvidence == #expectedEvidence
	if evidenceMatches then
		for evidenceType in pairs(expectedEvidenceSet) do
			if not guessedEvidenceSet[evidenceType] then
				evidenceMatches = false
				break
			end
		end
	end

	local ghostMatches = normalizeGhostTypeKey(guessedGhostType) == normalizeGhostTypeKey(session.ghostType)
	local identified = ghostMatches and evidenceMatches

	return {
		matchId = matchId,
		guessedGhostType = guessedGhostType,
		actualGhostType = session.ghostType,
		ghostMatches = ghostMatches,
		evidenceMatches = evidenceMatches,
		identified = identified,
		expectedEvidence = expectedEvidence,
		guessedEvidence = guessedEvidence,
		difficultyMode = session.difficultyMode,
	}
end

function EvidenceService:_getGhostState(matchId)
	if not self._ghostService then
		return nil
	end
	return self._ghostService:GetGhostState(matchId)
end

function EvidenceService:StartMatch(matchId, payload)
	local session = self._engine:StartMatch(matchId, payload)
	self._randomizer:StartMatch(matchId)
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = session
	self._state:Set("evidenceMatches", matches)
	return session
end

function EvidenceService:EndMatch(matchId)
	self._engine:EndMatch(matchId)
	self._randomizer:EndMatch(matchId)
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = nil
	self._state:Set("evidenceMatches", matches)
end

function EvidenceService:SetGhostProfile(matchId, payload)
	local session = self._engine:SetGhostProfile(matchId, payload)
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = session
	self._state:Set("evidenceMatches", matches)
	return session
end

function EvidenceService:SpawnEvidence(matchId, payload)
	local function doSpawn(requestPayload)
		local ghostState = self:_getGhostState(matchId)
		local signal, reason = self._engine:TrySpawnEvidence(matchId, requestPayload, {
			ghostState = ghostState,
		})
		if signal then
			self:_sync(matchId, "EvidenceSpawned", {
				evidenceType = signal.evidenceType,
				location = signal.roomId,
				trigger = signal.trigger,
			})
			self:_publish("EvidenceSpawned", {
				matchId = matchId,
				evidenceType = signal.evidenceType,
				location = signal.roomId,
				trigger = signal.trigger,
				source = signal.source,
			})
		end
		return signal, reason
	end

	return self._randomizer:Spawn(matchId, payload or {}, doSpawn, function(eventName, eventPayload)
		self:_publish(eventName, eventPayload)
	end)
end

function EvidenceService:ProcessToolUse(player, matchId, payload)
	if not matchId then
		return false, "missing_match_id", nil
	end
	if type(payload) ~= "table" then
		return false, "invalid_payload", nil
	end

	local toolType = payload.toolType
	local evidenceType = TOOL_TO_EVIDENCE[toolType]
	if not evidenceType then
		return false, "invalid_tool_type", nil
	end

	local requestPayload = payload.payload or {}
	local now = requestPayload.now or os.clock()
	local activity = tonumber(requestPayload.activity) or 1
	local distanceToGhost = tonumber(requestPayload.distanceToGhost)

	local signal, spawnReason = self:SpawnEvidence(matchId, {
		source = "client_tool_use",
		trigger = "near_tool",
		activity = activity,
		evidenceType = evidenceType,
		roomId = requestPayload.roomId,
		now = now,
	})

	if spawnReason == "throttled" then
		return false, "tool_throttled", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
		}
	end
	if spawnReason == "delayed" then
		return false, "tool_pending_delay", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
		}
	end
	if spawnReason == "fake_spawned" then
		return false, "fake_evidence_generated", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
			isFake = true,
		}
	end
	if not signal then
		return false, spawnReason or "spawn_failed", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
		}
	end

	local ok, collectReason, collectResult = self:CollectEvidence(player, matchId, {
		evidenceType = evidenceType,
		toolType = toolType,
		toolEvidenceType = evidenceType,
		roomId = requestPayload.roomId,
		nearGhostRoom = requestPayload.nearGhostRoom == true,
		toolNearGhostRoom = requestPayload.nearGhostRoom == true,
		distanceToGhost = distanceToGhost,
		now = now,
	})

	if not ok then
		return false, collectReason or "collect_failed", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
		}
	end

	return true, collectReason or "collected", {
		toolType = toolType,
		evidenceType = evidenceType,
		matchId = matchId,
		result = collectResult,
	}
end

function EvidenceService:UpdateDirectorTension(matchId, tension)
	self._randomizer:UpdateTension(matchId, tension)
end

function EvidenceService:UpdateGhostPersonality(matchId, personality)
	self._randomizer:UpdateGhostPersonality(matchId, personality)
end

function EvidenceService:UpdateSpectatorVision(matchId, payload)
	self._randomizer:OnSpectatorVisionUpdated(matchId, payload)
end

function EvidenceService:CollectEvidence(player, matchId, payload)
	local ghostState = self:_getGhostState(matchId)
	local ok, reason, result = self._engine:TryCollectEvidence(matchId, player, payload, {
		ghostState = ghostState,
	})

	if ok and result then
		self:_sync(matchId, "EvidenceDetected", {
			evidenceType = result.evidenceType,
			player = player,
		})
		self:_publish("EvidenceDetected", {
			player = player,
			matchId = matchId,
			evidenceType = result.evidenceType,
			toolType = payload and payload.toolType,
			playerPosition = payload and payload.playerPosition,
			ghostProximity = payload and (payload.ghostProximity or payload.distanceToGhost),
			environmentalConditions = payload and payload.environmentalConditions,
			now = payload and payload.now,
		})
		self:_publish("EvidenceValidated", {
			player = player,
			matchId = matchId,
			evidenceType = result.evidenceType,
			validated = true,
			now = payload and payload.now,
		})
		self:_publish("EvidenceCollected", {
			player = player,
			matchId = matchId,
			evidenceType = result.evidenceType,
		})
		self:_publishCombinationResolution(player, matchId, payload and payload.now)
	else
		self:_publish("EvidenceValidated", {
			player = player,
			matchId = matchId,
			evidenceType = payload and payload.evidenceType,
			validated = false,
			reason = reason,
			now = payload and payload.now,
		})
	end

	return ok, reason, result
end

function EvidenceService:ValidateJournalGuess(player, matchId, payload)
	local ok, reason, result = self._engine:ValidateJournalGuess(matchId, payload or {})
	if not ok then
		return false, reason, result
	end

	local combinationResult = self:_validateCombinationJournalGuess(matchId, payload or {})
	if combinationResult then
		result = combinationResult
		reason = combinationResult.identified and "identified" or "mismatch"
	end

	self:_publish("EvidenceValidated", {
		player = player,
		matchId = matchId,
		validated = result and result.evidenceMatches == true,
		ghostMatches = result and result.ghostMatches == true,
		identified = result and result.identified == true,
		reason = reason,
		now = payload and payload.now,
	})
	self:_sync(matchId, "EvidenceValidated", {
		validated = result and result.evidenceMatches == true,
		identified = result and result.identified == true,
	})

	if result and result.identified then
		self:_publish("GhostIdentified", {
			player = player,
			matchId = matchId,
			ghostType = result.actualGhostType,
			guessedGhostType = result.guessedGhostType,
			evidence = result.expectedEvidence,
			now = payload and payload.now,
		})
	end

	return true, reason, result
end

function EvidenceService:GetCollectedEvidence(matchId)
	return self._engine:GetCollectedEvidence(matchId)
end

function EvidenceService:GetPossibleGhosts(matchId)
	return self._engine:GetPossibleGhosts(matchId)
end

return EvidenceService
