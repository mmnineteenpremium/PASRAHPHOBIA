local GhostRoomPreference = {}
GhostRoomPreference.__index = GhostRoomPreference

local function weightedChoice(weightedEntries, rng)
	local total = 0
	for _, entry in ipairs(weightedEntries) do
		total += entry.weight
	end
	if total <= 0 then
		return nil
	end

	local roll = rng:NextNumber() * total
	local cumulative = 0
	for _, entry in ipairs(weightedEntries) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.value
		end
	end
	return weightedEntries[#weightedEntries].value
end

local function buildAdjacency(roomGraph)
	local adjacency = {}
	if type(roomGraph) ~= "table" then
		return adjacency
	end

	for roomId, neighbors in pairs(roomGraph) do
		if type(neighbors) == "table" then
			adjacency[roomId] = adjacency[roomId] or {}
			for _, neighborId in ipairs(neighbors) do
				adjacency[roomId][neighborId] = true
			end
		end
	end

	if type(roomGraph.edges) == "table" then
		for _, edge in ipairs(roomGraph.edges) do
			local fromRoom = edge.from or edge.a
			local toRoom = edge.to or edge.b
			if fromRoom and toRoom then
				adjacency[fromRoom] = adjacency[fromRoom] or {}
				adjacency[toRoom] = adjacency[toRoom] or {}
				adjacency[fromRoom][toRoom] = true
				adjacency[toRoom][fromRoom] = true
			end
		end
	end

	return adjacency
end

function GhostRoomPreference.new(config, rng)
	local self = setmetatable({}, GhostRoomPreference)
	self._config = {
		SpawnRuleWeightScale = config.SpawnRuleWeightScale or 1.5,
		FavoriteStickiness = config.FavoriteStickiness or 2.5,
		NearFavoriteWeight = config.NearFavoriteWeight or 1.3,
		DisturbedChangeChance = config.DisturbedChangeChance or 0.6,
	}
	self._rng = rng
	return self
end

function GhostRoomPreference:SelectFavoriteRoom(roomIds, roomSpawnRules, personality)
	if type(roomIds) ~= "table" or #roomIds == 0 then
		return nil
	end

	local weighted = {}
	local spawnBias = roomSpawnRules or {}
	local favoriteBias = (personality and personality.favoriteRoomBias) or 1.0

	for _, roomId in ipairs(roomIds) do
		local rule = spawnBias[roomId]
		local roomWeight = 1.0
		if type(rule) == "table" then
			roomWeight = rule.weight or rule.spawnWeight or 1.0
		elseif type(rule) == "number" then
			roomWeight = rule
		end
		table.insert(weighted, {
			value = roomId,
			weight = math.max(0.05, roomWeight * self._config.SpawnRuleWeightScale * favoriteBias),
		})
	end

	return weightedChoice(weighted, self._rng)
end

function GhostRoomPreference:GetNearbyRooms(session)
	local adjacency = session.roomAdjacency or {}
	local currentRoom = session.currentRoomId
	local neighbors = adjacency[currentRoom]
	if type(neighbors) ~= "table" then
		return {}
	end

	local list = {}
	for roomId, isConnected in pairs(neighbors) do
		if isConnected then
			table.insert(list, roomId)
		end
	end
	return list
end

function GhostRoomPreference:BuildRoomContext(roomGraph)
	return {
		roomAdjacency = buildAdjacency(roomGraph),
	}
end

function GhostRoomPreference:ShouldChangeFavoriteRoom(session, snapshot)
	if snapshot.disturbed ~= true and snapshot.favoriteRoomDisturbed ~= true then
		return false
	end
	return self._rng:NextNumber() <= self._config.DisturbedChangeChance
end

function GhostRoomPreference:ChooseNewFavoriteRoom(session)
	local roomIds = session.roomIds or {}
	if #roomIds <= 1 then
		return session.favoriteRoomId
	end

	local candidates = {}
	local nearbyRooms = self:GetNearbyRooms(session)
	local nearbySet = {}
	for _, roomId in ipairs(nearbyRooms) do
		nearbySet[roomId] = true
	end

	for _, roomId in ipairs(roomIds) do
		if roomId ~= session.favoriteRoomId then
			local weight = 1.0
			if nearbySet[roomId] then
				weight = weight + self._config.NearFavoriteWeight
			end
			table.insert(candidates, {
				value = roomId,
				weight = weight,
			})
		end
	end

	return weightedChoice(candidates, self._rng) or session.favoriteRoomId
end

return GhostRoomPreference
