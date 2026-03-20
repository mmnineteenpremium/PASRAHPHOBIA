local GhostAggression = {}
GhostAggression.__index = GhostAggression

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function getAverageSanity(snapshot)
	if snapshot.averageSanity ~= nil then
		return snapshot.averageSanity
	end

	local players = snapshot.players
	if type(players) ~= "table" or #players == 0 then
		return 100
	end

	local total = 0
	local count = 0
	for _, playerData in ipairs(players) do
		if playerData.isAlive ~= false then
			total += playerData.sanity or 100
			count += 1
		end
	end

	if count == 0 then
		return 100
	end

	return total / count
end

local function getNearFavoriteRoomCount(session, snapshot)
	if snapshot.nearFavoriteRoomCount ~= nil then
		return snapshot.nearFavoriteRoomCount
	end

	local players = snapshot.players
	if type(players) ~= "table" then
		return 0
	end

	local count = 0
	for _, playerData in ipairs(players) do
		if playerData.isAlive ~= false and playerData.roomId == session.favoriteRoomId then
			count += 1
		end
	end
	return count
end

local function getProfileMultiplier(session, key, fallback)
	local profile = session and session.difficultyProfile
	if type(profile) ~= "table" then
		return fallback
	end
	local value = tonumber(profile[key])
	if value then
		return value
	end
	return fallback
end

function GhostAggression.new(config)
	local self = setmetatable({}, GhostAggression)
	self._config = {
		Min = config.Min or 0,
		Max = config.Max or 100,
		BaseGainPerSecond = config.BaseGainPerSecond or 0.25,
		LowSanityThreshold = config.LowSanityThreshold or 40,
		LowSanityBonusPerSecond = config.LowSanityBonusPerSecond or 0.45,
		NearbyPlayerBonusPerSecond = config.NearbyPlayerBonusPerSecond or 0.3,
		DecayPerSecond = config.DecayPerSecond or 0.1,
		HuntAggressionThreshold = config.HuntAggressionThreshold or 70,
		HuntSanityThreshold = config.HuntSanityThreshold or 40,
		HuntBaseChance = config.HuntBaseChance or 0.15,
		HuntAggressionScale = config.HuntAggressionScale or 0.005,
		HuntLowSanityBonus = config.HuntLowSanityBonus or 0.2,
	}
	return self
end

function GhostAggression:Update(session, snapshot, dt)
	local averageSanity = getAverageSanity(snapshot)
	local nearFavoriteRoomCount = getNearFavoriteRoomCount(session, snapshot)
	local growth = self._config.BaseGainPerSecond
	local personality = session.personality or {}

	if averageSanity <= self._config.LowSanityThreshold then
		growth += self._config.LowSanityBonusPerSecond
	end

	if nearFavoriteRoomCount > 0 then
		growth += self._config.NearbyPlayerBonusPerSecond * nearFavoriteRoomCount
	else
		growth -= self._config.DecayPerSecond
	end

	if session.director and session.director.tensionHighUntil and snapshot.now and snapshot.now <= session.director.tensionHighUntil then
		growth += 0.25
	end

	growth *= (personality.aggressionGainScale or 1.0)
	growth *= getProfileMultiplier(session, "GhostAggressionMultiplier", getProfileMultiplier(session, "GhostAggression", 1.0))

	local nextValue = (session.aggression or 0) + (growth * dt)
	session.aggression = clamp(nextValue, self._config.Min, self._config.Max)
	return session.aggression
end

function GhostAggression:CanAttemptHunt(session, snapshot)
	local averageSanity = getAverageSanity(snapshot)
	local threshold = getProfileMultiplier(session, "HuntFrequency", self._config.HuntAggressionThreshold)
	return (session.aggression or 0) > threshold
		and averageSanity < 40
end

function GhostAggression:ComputeHuntChance(session, snapshot)
	local averageSanity = getAverageSanity(snapshot)
	local aggression = session.aggression or 0
	local chance = self._config.HuntBaseChance
	local personality = session.personality or {}

	chance += math.max(0, aggression - self._config.HuntAggressionThreshold) * self._config.HuntAggressionScale
	if averageSanity <= self._config.HuntSanityThreshold then
		chance += self._config.HuntLowSanityBonus
	end
	chance *= (personality.huntFrequency or 1.0)
	chance *= getProfileMultiplier(session, "HuntFrequencyMultiplier", getProfileMultiplier(session, "HuntFrequency", 1.0))

	return clamp(chance, 0, 0.95)
end

return GhostAggression
