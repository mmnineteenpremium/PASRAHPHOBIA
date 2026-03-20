local EvidenceEngine = {}
EvidenceEngine.__index = EvidenceEngine

local function nowOrClock(now)
	return now or os.clock()
end

local EVIDENCE_TYPES = {
	"BolaArwah",
	"BukuTerkutuk",
	"GerakanGaib",
	"JejakEnergi",
	"KotakArwah",
	"SuhuMembeku",
}

local function listContains(list, value)
	for _, entry in ipairs(list or {}) do
		if entry == value then
			return true
		end
	end
	return false
end

local function cloneList(list)
	local out = {}
	for _, value in ipairs(list or {}) do
		table.insert(out, value)
	end
	return out
end

local function normalizeDifficulty(difficulty)
	if type(difficulty) == "string" then
		local lowered = string.lower(difficulty)
		if lowered == "easy" then
			return "Easy"
		end
		if lowered == "hard" then
			return "Hard"
		end
		return "Normal"
	end

	local numeric = tonumber(difficulty)
	if numeric and numeric <= 2 then
		return "Easy"
	end
	if numeric and numeric >= 8 then
		return "Hard"
	end
	return "Normal"
end

local function resolveEvidenceCap(difficultyMode, explicitCap)
	if type(explicitCap) == "number" and explicitCap > 0 then
		return math.max(1, math.floor(explicitCap + 0.5))
	end
	if difficultyMode == "Easy" then
		return 4
	end
	if difficultyMode == "Hard" then
		return 2
	end
	return 3
end

function EvidenceEngine.new(deps)
	local self = setmetatable({}, EvidenceEngine)
	self._deps = deps or {}
	self._spawner = assert(self._deps.Spawner, "EvidenceEngine requires Spawner")
	self._validator = assert(self._deps.Validator, "EvidenceEngine requires Validator")
	self._tracker = assert(self._deps.Tracker, "EvidenceEngine requires Tracker")
	self._deduction = assert(self._deps.Deduction, "EvidenceEngine requires Deduction")
	self._rng = self._deps.Random or Random.new()
	self._sessions = {}
	return self
end

function EvidenceEngine:StartMatch(matchId, payload)
	local existing = self._sessions[matchId]
	if existing then
		return existing
	end

	local ghostType = payload and payload.ghostType or "UnknownGhost"
	local favoriteRoomId = payload and payload.favoriteRoomId or nil
	local difficulty = payload and payload.difficulty or payload and payload.difficultyMode or 5
	local difficultyMode = normalizeDifficulty(difficulty)
	local evidenceCap = resolveEvidenceCap(
		difficultyMode,
		payload and (payload.evidenceCap or (payload.difficultyProfile and payload.difficultyProfile.EvidenceRequired))
	)
	local ghostEvidence = self._deduction:GetEvidenceForGhost(ghostType) or {}
	local validationEvidence = cloneList(ghostEvidence)
	local supplementalEvidence = {}
	local evidencePool = cloneList(ghostEvidence)

	if difficultyMode == "Hard" and #ghostEvidence > 2 then
		local firstIndex = self._rng:NextInteger(1, #ghostEvidence)
		local secondIndex = firstIndex
		while secondIndex == firstIndex do
			secondIndex = self._rng:NextInteger(1, #ghostEvidence)
		end
		evidencePool = {
			ghostEvidence[firstIndex],
			ghostEvidence[secondIndex],
		}
		validationEvidence = cloneList(evidencePool)
	elseif difficultyMode == "Easy" then
		for _, evidenceType in ipairs(EVIDENCE_TYPES) do
			if not listContains(ghostEvidence, evidenceType) then
				table.insert(supplementalEvidence, evidenceType)
			end
		end
	end

	self._tracker:InitMatch(matchId)

	local session = {
		matchId = matchId,
		ghostType = ghostType,
		favoriteRoomId = favoriteRoomId,
		difficulty = difficulty,
		difficultyMode = difficultyMode,
		difficultyProfile = payload and payload.difficultyProfile or {},
		evidenceCap = evidenceCap,
		spawnedSignals = {},
		collectedEvidence = self._tracker:GetCollectedEvidence(matchId),
		possibleGhosts = self._deduction:GetPossibleGhosts({}),
		ghostEvidence = ghostEvidence,
		evidencePool = evidencePool,
		supplementalEvidence = supplementalEvidence,
		validationEvidence = validationEvidence,
		startedAt = nowOrClock(payload and payload.now),
	}

	self._sessions[matchId] = session
	return session
end

function EvidenceEngine:EndMatch(matchId)
	self._sessions[matchId] = nil
	self._tracker:ClearMatch(matchId)
end

function EvidenceEngine:Reset()
	for matchId in pairs(self._sessions) do
		self._tracker:ClearMatch(matchId)
	end
	self._sessions = {}
end

function EvidenceEngine:GetSession(matchId)
	return self._sessions[matchId]
end

function EvidenceEngine:SetGhostProfile(matchId, profile)
	local session = self._sessions[matchId]
	if not session then
		session = self:StartMatch(matchId, profile or {})
	end

	if profile and profile.ghostType then
		session.ghostType = profile.ghostType
	end
	if profile and profile.favoriteRoomId then
		session.favoriteRoomId = profile.favoriteRoomId
	end
	if profile and profile.difficulty then
		session.difficulty = profile.difficulty
	end
	if profile and profile.difficultyProfile then
		session.difficultyProfile = profile.difficultyProfile
	elseif profile and (profile.EvidenceClarity or profile.EvidenceClarityMultiplier) then
		session.difficultyProfile = session.difficultyProfile or {}
		session.difficultyProfile.EvidenceClarity = profile.EvidenceClarity
		session.difficultyProfile.EvidenceClarityMultiplier = profile.EvidenceClarityMultiplier
	end
	if profile and profile.difficultyMode then
		session.difficultyMode = normalizeDifficulty(profile.difficultyMode)
	end

	local resolvedMode = normalizeDifficulty(session.difficultyMode or session.difficulty)
	local ghostEvidence = self._deduction:GetEvidenceForGhost(session.ghostType) or {}
	local evidencePool = cloneList(ghostEvidence)
	local validationEvidence = cloneList(ghostEvidence)
	local supplementalEvidence = {}
	local evidenceCap = resolveEvidenceCap(
		resolvedMode,
		profile and (profile.evidenceCap or (profile.difficultyProfile and profile.difficultyProfile.EvidenceRequired))
	)

	if resolvedMode == "Hard" and #ghostEvidence > 2 then
		local firstIndex = self._rng:NextInteger(1, #ghostEvidence)
		local secondIndex = firstIndex
		while secondIndex == firstIndex do
			secondIndex = self._rng:NextInteger(1, #ghostEvidence)
		end
		evidencePool = {
			ghostEvidence[firstIndex],
			ghostEvidence[secondIndex],
		}
		validationEvidence = cloneList(evidencePool)
	elseif resolvedMode == "Easy" then
		for _, evidenceType in ipairs(EVIDENCE_TYPES) do
			if not listContains(ghostEvidence, evidenceType) then
				table.insert(supplementalEvidence, evidenceType)
			end
		end
	end

	session.difficultyMode = resolvedMode
	session.evidenceCap = evidenceCap
	session.ghostEvidence = ghostEvidence
	session.evidencePool = evidencePool
	session.supplementalEvidence = supplementalEvidence
	session.validationEvidence = validationEvidence

	return session
end

function EvidenceEngine:TrySpawnEvidence(matchId, payload, context)
	local session = self._sessions[matchId]
	if not session then
		session = self:StartMatch(matchId, payload or {})
	end

	local spawnContext = {
		rng = payload and payload.rng,
		activity = payload and payload.activity,
		evidenceType = payload and payload.evidenceType,
		roomId = payload and payload.roomId,
		source = payload and payload.source,
		trigger = payload and payload.trigger,
		now = payload and payload.now,
		ghostState = context and context.ghostState,
		ghostEvidence = session.evidencePool or self._deduction:GetEvidenceForGhost(session.ghostType),
		supplementalEvidence = session.supplementalEvidence,
		difficultyMode = session.difficultyMode,
		difficultyProfile = session.difficultyProfile,
		evidenceCap = session.evidenceCap,
		collectedEvidenceCount = #(session.collectedEvidence or {}),
	}

	local signal, reason = self._spawner:TrySpawn(session, spawnContext)
	return signal, reason
end

function EvidenceEngine:TryCollectEvidence(matchId, player, payload, context)
	local session = self._sessions[matchId]
	if not session then
		return false, "missing_match_session", nil
	end

	if #(session.collectedEvidence or {}) >= (session.evidenceCap or 3) then
		return false, "evidence_cap_reached", nil
	end

	local validated, reason = self._validator:Validate(session, payload, context or {})
	if not validated then
		return false, reason, nil
	end

	local evidenceType = payload.evidenceType:gsub("%s+", "")
	local wasAdded = self._tracker:AddEvidence(matchId, evidenceType)
	session.collectedEvidence = self._tracker:GetCollectedEvidence(matchId)
	session.possibleGhosts = self._deduction:GetPossibleGhosts(session.collectedEvidence)

	local signal = session.spawnedSignals[evidenceType]
	if signal then
		signal.isActive = false
		signal.collectedAt = nowOrClock(payload.now)
		signal.collectedBy = player and player.UserId or nil
	end

	return true, wasAdded and "collected" or "already_collected", {
		evidenceType = evidenceType,
		collectedEvidence = session.collectedEvidence,
		possibleGhosts = session.possibleGhosts,
	}
end

function EvidenceEngine:ValidateJournalGuess(matchId, payload)
	local session = self._sessions[matchId]
	if not session then
		return false, "missing_match_session", nil
	end

	local guessedGhostType = payload and payload.ghostType
	if type(guessedGhostType) ~= "string" or guessedGhostType == "" then
		return false, "invalid_ghost_guess", nil
	end

	local guessedEvidence = payload and payload.evidence or {}
	local guessedSet = {}
	local guessedCount = 0
	for _, evidenceType in ipairs(guessedEvidence) do
		if type(evidenceType) == "string" then
			local normalized = evidenceType:gsub("%s+", "")
			if not guessedSet[normalized] then
				guessedSet[normalized] = true
				guessedCount += 1
			end
		end
	end

	local expected = session.validationEvidence or self._deduction:GetEvidenceForGhost(session.ghostType) or {}
	local expectedSet = {}
	local expectedCount = 0
	for _, evidenceType in ipairs(expected) do
		if not expectedSet[evidenceType] then
			expectedSet[evidenceType] = true
			expectedCount += 1
		end
	end

	local evidenceMatches = guessedCount == expectedCount
	if evidenceMatches then
		for evidenceType in pairs(expectedSet) do
			if not guessedSet[evidenceType] then
				evidenceMatches = false
				break
			end
		end
	end

	local ghostMatches = guessedGhostType == session.ghostType
	local identified = ghostMatches and evidenceMatches

	return true, identified and "identified" or "mismatch", {
		matchId = matchId,
		guessedGhostType = guessedGhostType,
		actualGhostType = session.ghostType,
		ghostMatches = ghostMatches,
		evidenceMatches = evidenceMatches,
		identified = identified,
		expectedEvidence = expected,
		guessedEvidence = guessedEvidence,
		difficultyMode = session.difficultyMode,
	}
end

function EvidenceEngine:GetCollectedEvidence(matchId)
	return self._tracker:GetCollectedEvidence(matchId)
end

function EvidenceEngine:GetPossibleGhosts(matchId)
	local session = self._sessions[matchId]
	if not session then
		return {}
	end
	return session.possibleGhosts
end

return EvidenceEngine
