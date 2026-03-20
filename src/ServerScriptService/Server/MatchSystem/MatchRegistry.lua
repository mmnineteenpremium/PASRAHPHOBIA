local MatchRegistry = {}

local activeMatches = {}

function MatchRegistry.Add(match)
	if not match or not match.id then
		return
	end
	activeMatches[match.id] = match
end

function MatchRegistry.Remove(matchId)
	activeMatches[matchId] = nil
end

function MatchRegistry.Get(matchId)
	return activeMatches[matchId]
end

function MatchRegistry.GetAll()
	return activeMatches
end

return MatchRegistry
