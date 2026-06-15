local GhostTargeting = {}
GhostTargeting.__index = GhostTargeting

local function getDistanceScore(distance)
	local normalized = math.max(1, distance or 999)
	return 1 / normalized
end

local function getNoiseScore(playerData)
	if playerData.noiseLevel ~= nil then
		return playerData.noiseLevel
	end
	return playerData.isNoisy and 1 or 0
end

local function getSanityScore(playerData)
	local sanity = math.clamp(playerData.sanity or 100, 0, 100)
	return (100 - sanity) / 100
end

function GhostTargeting.new()
	return setmetatable({}, GhostTargeting)
end

local function pickRandomAlive(players, rng)
	local alive = {}
	for _, playerData in ipairs(players) do
		if playerData.isAlive ~= false and playerData.isHidden ~= true then
			table.insert(alive, playerData)
		end
	end
	if #alive == 0 then
		return nil
	end
	return alive[rng:NextInteger(1, #alive)]
end

function GhostTargeting:SelectTarget(_, snapshot, strategy, rng)
	local players = snapshot.players
	if type(players) ~= "table" then
		return nil
	end

	if strategy == "random_target" and rng then
		return pickRandomAlive(players, rng)
	end

	local bestPlayer = nil
	local bestScore = -math.huge

	for _, playerData in ipairs(players) do
		-- Hidden players in closets are not valid targets
		if playerData.isAlive ~= false and playerData.isHidden ~= true then
			local totalScore = 0
			if strategy == "nearest_player" then
				totalScore = getDistanceScore(playerData.distanceToGhost)
			elseif strategy == "lowest_sanity_player" then
				totalScore = getSanityScore(playerData)
			elseif strategy == "isolated_player" then
				local teammateFactor = (playerData.nearbyTeammates or 0) <= 0 and 1 or 0
				totalScore = (teammateFactor * 1.4) + (getDistanceScore(playerData.distanceToGhost) * 0.4)
			else
				local distanceScore = getDistanceScore(playerData.distanceToGhost)
				local noiseScore = getNoiseScore(playerData)
				local sanityScore = getSanityScore(playerData)
				local visibilityScore = playerData.isVisible and 0.75 or 0
				-- Running players (high movement) attract the ghost's attention significantly
				local movementLevel = tonumber(playerData.movementLevel) or 0
				local runningScore = (movementLevel >= 0.6) and 2.5 or 0
				-- Sprinting with noise makes ghost prioritise this player even more
				local sprintNoiseBonus = (movementLevel >= 0.6 and noiseScore > 0) and (noiseScore * 0.8) or 0
				totalScore = (distanceScore * 1.8) + (noiseScore * 1.25) + (sanityScore * 0.9) + visibilityScore + runningScore + sprintNoiseBonus
			end
			if totalScore > bestScore then
				bestScore = totalScore
				bestPlayer = playerData
			end
		end
	end

	return bestPlayer
end

return GhostTargeting
