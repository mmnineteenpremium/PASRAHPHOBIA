local EvidenceValidator = {}
EvidenceValidator.__index = EvidenceValidator

local DEFAULT_TOOL_EVIDENCE_MAP = {
	camera = "To'un",
	thermometer = "Suhu",
	spiritbox = "Suara",
	emf = "MEDOK",
	writingbook = "BukuTerkutuk",
	motionsensor = "Pengganggu",
}

local EVIDENCE_ALIASES = {
	medok = "MEDOK",
	jejakenergi = "MEDOK",
	suhu = "Suhu",
	suhumembeku = "Suhu",
	bukuterkutuk = "BukuTerkutuk",
	toun = "To'un",
	bolaarwah = "To'un",
	suara = "Suara",
	kotakarwah = "Suara",
	pengganggu = "Pengganggu",
	motionsensor = "Pengganggu",
	gerakangaib = "Pengganggu",
}

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end

	return value
		:lower()
		:gsub("[%s_%-]+", "")
		:gsub("[^%w]", "")
end

local function normalizeEvidenceType(evidenceType)
	if type(evidenceType) ~= "string" then
		return nil
	end
	local token = evidenceType
		:lower()
		:gsub("[%s_%-]+", "")
		:gsub("[^%w]", "")
	return EVIDENCE_ALIASES[token] or evidenceType
end

local function resolveToolEvidenceType(payload, toolEvidenceMap)
	local directType = payload and payload.toolEvidenceType
	if type(directType) == "string" then
		return normalizeEvidenceType(directType)
	end

	local normalizedTool = normalizeToken(payload and payload.toolType)
	if not normalizedTool then
		return nil
	end

	return toolEvidenceMap[normalizedTool]
end

function EvidenceValidator.new(deps)
	local self = setmetatable({}, EvidenceValidator)
	self._deps = deps or {}
	self._deduction = self._deps.Deduction
	self._toolEvidenceMap = {}
	for token, evidenceType in pairs(DEFAULT_TOOL_EVIDENCE_MAP) do
		self._toolEvidenceMap[token] = evidenceType
	end
	for evidenceType, rule in pairs(self._deps.EvidenceRules or {}) do
		if type(rule) == "table" and type(rule.tool) == "string" then
			local normalizedTool = normalizeToken(rule.tool)
			if normalizedTool then
				self._toolEvidenceMap[normalizedTool] = normalizeEvidenceType(evidenceType)
			end
		end
	end
	return self
end

function EvidenceValidator:Validate(session, payload, context)
	local requestedEvidence = normalizeEvidenceType(payload and payload.evidenceType)
	if not requestedEvidence then
		return false, "invalid_evidence_type"
	end

	local signal = session.spawnedSignals[requestedEvidence]
	if not signal or signal.isActive ~= true then
		return false, "evidence_not_spawned"
	end

	local ghostState = context and context.ghostState or {}
	local ghostType = session.ghostType
	if
		self._deduction
		and signal.isSupplemental ~= true
		and not self._deduction:CanGhostProduceEvidence(ghostType, requestedEvidence)
	then
		return false, "ghost_cannot_emit_evidence"
	end

	local playerRoomId = payload and payload.roomId
	local ghostRoomId = ghostState.currentRoomId or ghostState.favoriteRoomId or session.favoriteRoomId
	if playerRoomId and signal.roomId and playerRoomId ~= signal.roomId and playerRoomId ~= ghostRoomId then
		return false, "wrong_room"
	end

	local toolEvidenceType = resolveToolEvidenceType(payload or {}, self._toolEvidenceMap)
	if toolEvidenceType and toolEvidenceType ~= requestedEvidence then
		return false, "tool_mismatch"
	end

	local distanceToGhost = payload and payload.distanceToGhost
	if type(distanceToGhost) == "number" and distanceToGhost > 60 then
		return false, "ghost_too_far"
	end

	return true, "validated"
end

return EvidenceValidator
