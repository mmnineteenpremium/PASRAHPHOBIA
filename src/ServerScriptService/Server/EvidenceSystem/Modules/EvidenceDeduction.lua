local EvidenceDeduction = {}
EvidenceDeduction.__index = EvidenceDeduction

local DEFAULT_GHOST_EVIDENCE_MAP = {
	Pocong = { "BukuTerkutuk", "SuhuMembeku", "JejakEnergi" },
	Kuntilanak = { "KotakArwah", "BolaArwah", "GerakanGaib" },
	Tuyul = { "JejakEnergi", "GerakanGaib", "KotakArwah" },
	Genderuwo = { "BukuTerkutuk", "KotakArwah", "SuhuMembeku" },
	["Wewe Gombel"] = { "BolaArwah", "GerakanGaib", "JejakEnergi" },
	Palasik = { "SuhuMembeku", "JejakEnergi", "KotakArwah" },
	Banaspati = { "BolaArwah", "JejakEnergi", "GerakanGaib" },
	["Sundel Bolong"] = { "BukuTerkutuk", "BolaArwah", "KotakArwah" },
	Leak = { "GerakanGaib", "JejakEnergi", "SuhuMembeku" },
	["Hantu Jeruk Purut"] = { "KotakArwah", "BolaArwah", "JejakEnergi" },
	["Hantu Cermin"] = { "BukuTerkutuk", "GerakanGaib", "SuhuMembeku" },
	["Arwah Penunggu"] = { "SuhuMembeku", "KotakArwah", "BukuTerkutuk" },
}

local function normalizeEvidence(evidenceType)
	if type(evidenceType) ~= "string" then
		return nil
	end
	return evidenceType:gsub("%s+", "")
end

local function copyEvidenceMap(source)
	local map = {}
	for ghostType, evidenceList in pairs(source) do
		local normalizedList = {}
		for _, evidenceType in ipairs(evidenceList) do
			local normalized = normalizeEvidence(evidenceType)
            if normalized then
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

