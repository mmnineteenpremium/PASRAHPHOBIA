local EvidenceSpawner = {}
EvidenceSpawner.__index = EvidenceSpawner

local DEFAULT_EVIDENCE_TYPES = {
	"BolaArwah",
	"BukuTerkutuk",
	"GerakanGaib",
	"JejakEnergi",
	"KotakArwah",
	"SuhuMembeku",
}

local DEFAULT_RULES = {
	BaseSpawnChance = 0.2,
	ProgressBonusScale = 0.25,
	AggressionBonusCap = 0.2,
	ActivityBonusCap = 0.2,
	MinSpawnChance = 0.05,
	MaxSpawnChance = 0.95,
}

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function listContains(list, value)
	for _, entry in ipairs(list) do
		if entry == value then
			return true
		end
	end
	return false
end

local function resolveEvidenceTypes(candidate)
	if type(candidate) ~= "table" then
		return DEFAULT_EVIDENCE_TYPES
	end
	if #candidate > 0 then
		return candidate
	end
	local list = {}
	for _, value in pairs(candidate) do
		if type(value) == "string" then
			table.insert(list, value)
		end
	end
	if #list > 0 then
		return list
	end
	return DEFAULT_EVIDENCE_TYPES
end

function EvidenceSpawner.new(deps)
	local self = setmetatable({}, EvidenceSpawner)
	self._deps = deps or {}
	self._rng = self._deps.Random or Random.new()
	self._evidenceTypes = resolveEvidenceTypes(self._deps.EvidenceTypes)
	self._rules = {}
	for key, value in pairs(DEFAULT_RULES) do
		self._rules[key] = value
	end
	if type(self._deps.EvidenceRules) == "table" then
		for key, value in pairs(self._deps.EvidenceRules) do
			if type(value) == "number" then
				self._rules[key] = value
			end
		end
	end
	return self
end

function EvidenceSpawner:_computeSpawnChance(session, context)
	local progress = #session.collectedEvidence / 3
	local aggression = (context.ghostState and context.ghostState.aggression) or 0
	local activity = context.activity or 0
	local difficulty = tonumber(session.difficulty) or 5
	local trigger = context.trigger or context.source

	local baseChance = self._rules.BaseSpawnChance
	local progressBonus = progress * self._rules.ProgressBonusScale
	local aggressionBonus = math.min(self._rules.AggressionBonusCap, aggression / 500)
	local activityBonus = math.min(self._rules.ActivityBonusCap, activity * 0.05)
	local difficultyModifier = clamp(1.2 - (difficulty * 0.06), 0.45, 1.2)
	local triggerBonus = 0
	if trigger == "ghost_interaction" then
		triggerBonus = 0.15
	elseif trigger == "near_tool" then
		triggerBonus = 0.2
	elseif trigger == "manifest" or trigger == "ghost_manifest" then
		triggerBonus = 0.25
	end

	local chance = (baseChance + progressBonus + aggressionBonus + activityBonus + triggerBonus) * difficultyModifier
	return clamp(chance, self._rules.MinSpawnChance, self._rules.MaxSpawnChance)
end

function EvidenceSpawner:_selectEvidenceType(session, context)
	local preferredEvidence = context.ghostEvidence
	local candidates = {}

	if (context.collectedEvidenceCount or #session.collectedEvidence or 0) >= (context.evidenceCap or session.evidenceCap or 3) then
		return nil
	end

	if type(preferredEvidence) == "table" and #preferredEvidence > 0 then
		for _, evidenceType in ipairs(preferredEvidence) do
			if not listContains(session.collectedEvidence, evidenceType) then
				table.insert(candidates, evidenceType)
			end
		end
	end

	if #candidates == 0 and context.difficultyMode == "Easy" then
		for _, evidenceType in ipairs(context.supplementalEvidence or {}) do
			if not listContains(session.collectedEvidence, evidenceType) then
				table.insert(candidates, evidenceType)
			end
		end
	end

	if #candidates == 0 and (type(preferredEvidence) ~= "table" or #preferredEvidence == 0) then
		for _, evidenceType in ipairs(self._evidenceTypes) do
			if not listContains(session.collectedEvidence, evidenceType) then
				table.insert(candidates, evidenceType)
			end
		end
	end

	if #candidates == 0 then
		return nil
	end

	return candidates[self._rng:NextInteger(1, #candidates)]
end

function EvidenceSpawner:_selectRoom(session, context)
	if context.roomId then
		return context.roomId
	end

	local ghostState = context.ghostState or {}
	local favoriteRoomId = ghostState.favoriteRoomId or session.favoriteRoomId
	local currentRoomId = ghostState.currentRoomId
	local roll = self._rng:NextNumber()

	if favoriteRoomId and roll <= 0.65 then
		return favoriteRoomId
	end

	if currentRoomId and roll <= 0.85 then
		return currentRoomId
	end

	if favoriteRoomId then
		return favoriteRoomId
	end

	return currentRoomId or "UnknownRoom"
end

function EvidenceSpawner:TrySpawn(session, context)
	local spawnChance = self:_computeSpawnChance(session, context)
	if self._rng:NextNumber() > spawnChance then
		return nil, "spawn_roll_failed"
	end

	local evidenceType = context.evidenceType or self:_selectEvidenceType(session, context)
	if not evidenceType then
		return nil, "no_candidate_evidence"
	end

	local roomId = self:_selectRoom(session, context)
	local now = context.now or os.clock()
	local signal = {
		evidenceType = evidenceType,
		roomId = roomId,
		spawnedAt = now,
		isActive = true,
		source = context.source or "spawn_loop",
		trigger = context.trigger or context.source or "unknown",
	}
	if context.difficultyMode == "Easy" and type(context.supplementalEvidence) == "table" then
		signal.isSupplemental = listContains(context.supplementalEvidence, evidenceType)
	end

	session.spawnedSignals[evidenceType] = signal
	return signal
end

return EvidenceSpawner
