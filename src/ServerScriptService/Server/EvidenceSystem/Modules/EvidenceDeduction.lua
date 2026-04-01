local EvidenceDeduction = {}
EvidenceDeduction.__index = EvidenceDeduction

local DEFAULT_GHOST_EVIDENCE_MAP = {
	Pocong = { "MEDOK", "Suhu", "BukuTerkutuk" },
	Kuntilanak = { "Suara", "To'un", "Pengganggu" },
	Tuyul = { "To'un", "Suara", "BukuTerkutuk" },
	Genderuwo = { "MEDOK", "Pengganggu", "Suhu" },
	Leak = { "Suara", "MEDOK", "Pengganggu" },
	Banaspati = { "Suhu", "To'un", "MEDOK" },
	Jerangkong = { "BukuTerkutuk", "Pengganggu", "To'un" },
	WeweGombel = { "Suara", "Suhu", "BukuTerkutuk" },
	Palasik = { "To'un", "Pengganggu", "Suara" },
	SilumanUlar = { "MEDOK", "Suhu", "To'un" },
	SundelBolong = { "BukuTerkutuk", "To'un", "Suara" },
	HantuTanah = { "Suhu", "MEDOK", "Pengganggu" },
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

local function normalizeEvidence(evidenceType)
	if type(evidenceType) ~= "string" then
		return nil
	end
	local token = evidenceType
		:gsub("[%s_%-]+", "")
		:gsub("[^%w]", "")
		:lower()
	return EVIDENCE_ALIASES[token] or evidenceType
end

local function copyEvidenceMap(source)
	local map = {}
	for ghostType, evidenceList in pairs(source) do
		local normalizedList = {}
		local seen = {}
		for _, evidenceType in ipairs(evidenceList) do
			local normalized = normalizeEvidence(evidenceType)
			if normalized and not seen[normalized] then
				seen[normalized] = true
				table.insert(normalizedList, normalized)
			end
		end
		map[ghostType] = normalizedList
	end
	return map
end

local function listToSet(evidenceList)
	local set = {}
	for _, evidenceType in ipairs(evidenceList) do
		set[evidenceType] = true
	end
	return set
end

function EvidenceDeduction.new(ghostEvidenceMap)
	local self = setmetatable({}, EvidenceDeduction)
	self._ghostEvidenceMap = copyEvidenceMap(ghostEvidenceMap or DEFAULT_GHOST_EVIDENCE_MAP)
	self._evidenceSets = {}
	for ghostType, evidenceList in pairs(self._ghostEvidenceMap) do
		self._evidenceSets[ghostType] = listToSet(evidenceList)
	end
	return self
end

function EvidenceDeduction:GetEvidenceMap()
	return self._ghostEvidenceMap
end

function EvidenceDeduction:GetEvidenceForGhost(ghostType)
	local list = self._ghostEvidenceMap[ghostType]
	if not list then
		return nil
	end

	local copy = table.create(#list)
	for index, evidenceType in ipairs(list) do
		copy[index] = evidenceType
	end
	return copy
end

function EvidenceDeduction:GetPossibleGhosts(collectedEvidence)
	local collectedSet = {}
	for _, evidenceType in ipairs(collectedEvidence or {}) do
		local normalized = normalizeEvidence(evidenceType)
		if normalized then
			collectedSet[normalized] = true
		end
	end

	local possibleGhosts = {}
	for ghostType, evidenceSet in pairs(self._evidenceSets) do
		local isPossible = true
		for evidenceType in pairs(collectedSet) do
			if not evidenceSet[evidenceType] then
				isPossible = false
				break
			end
		end

		if isPossible then
			table.insert(possibleGhosts, ghostType)
		end
	end

	table.sort(possibleGhosts)
	return possibleGhosts
end

function EvidenceDeduction:CanGhostProduceEvidence(ghostType, evidenceType)
	local normalized = normalizeEvidence(evidenceType)
	if not normalized then
		return false
	end

	local evidenceSet = self._evidenceSets[ghostType]
	if not evidenceSet then
		-- Unknown ghost profile should not hard-block investigation flow.
		return true
	end

	return evidenceSet[normalized] == true
end

return EvidenceDeduction

