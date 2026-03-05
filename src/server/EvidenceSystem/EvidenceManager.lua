local EvidenceManager = {}

EvidenceManager.activeEvidence = {}

function EvidenceManager.addEvidence(type)
	table.insert(EvidenceManager.activeEvidence, type)
	print("Evidence generated:", type)
end

function EvidenceManager.getEvidence()
	return EvidenceManager.activeEvidence
end

return EvidenceManager
