local EvidenceProbability = {}

function EvidenceProbability.roll(chance)
	local roll = math.random()
	return roll <= chance
end

return EvidenceProbability
