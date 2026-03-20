local EvidenceTracker = {}
EvidenceTracker.__index = EvidenceTracker

function EvidenceTracker.new()
	local self = setmetatable({}, EvidenceTracker)
	self._matches = {}
	return self
end

function EvidenceTracker:InitMatch(matchId)
	self._matches[matchId] = {
		collectedSet = {},
		collectedOrder = {},
	}
end

function EvidenceTracker:ClearMatch(matchId)
	self._matches[matchId] = nil
end

function EvidenceTracker:_getOrCreate(matchId)
	local state = self._matches[matchId]
	if not state then
		self:InitMatch(matchId)
		state = self._matches[matchId]
	end
	return state
end

function EvidenceTracker:AddEvidence(matchId, evidenceType)
	local state = self:_getOrCreate(matchId)
	if state.collectedSet[evidenceType] then
		return false
	end

	state.collectedSet[evidenceType] = true
	table.insert(state.collectedOrder, evidenceType)
	return true
end

function EvidenceTracker:HasEvidence(matchId, evidenceType)
	local state = self._matches[matchId]
	return state ~= nil and state.collectedSet[evidenceType] == true
end

function EvidenceTracker:GetCollectedEvidence(matchId)
	local state = self._matches[matchId]
	if not state then
		return {}
	end

	local copy = table.create(#state.collectedOrder)
	for index, evidenceType in ipairs(state.collectedOrder) do
		copy[index] = evidenceType
	end
	return copy
end

return EvidenceTracker
