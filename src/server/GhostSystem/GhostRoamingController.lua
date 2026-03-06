local GhostRoamingController = {}
GhostRoamingController.__index = GhostRoamingController

local function weightedChoice(items, rng)
	local totalWeight = 0
	for _, entry in ipairs(items) do
		totalWeight += entry.weight
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = rng:NextNumber() * totalWeight
	local cumulative = 0
	for _, entry in ipairs(items) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.value
		end
	end

	return items[#items].value
end

function GhostRoamingController.new(config, rng)
	local self = setmetatable({}, GhostRoamingController)
	self._config = {
		FavoriteRoomWeight = config.FavoriteRoomWeight or 3.5,
		DefaultRoomWeight = config.DefaultRoomWeight or 1,
		CurrentRoomPenalty = config.CurrentRoomPenalty or 0.5,
		ActivityWeightScale = config.ActivityWeightScale or 0.5,
	}
	self._rng = rng
	return self
end

function GhostRoamingController:ChooseFavoriteRoom(roomIds)
	if type(roomIds) ~= "table" or #roomIds == 0 then
		return nil
	end
	return roomIds[self._rng:NextInteger(1, #roomIds)]
end

function GhostRoamingController:SelectNextRoom(session, snapshot)
	local roomIds = session.roomIds or {}
	if #roomIds == 0 then
		return nil
	end

	local weightedRooms = {}
	local roomActivity = snapshot.roomActivity or {}
	local roamBias = (session.personality and session.personality.roamBias) or 1.0
	local nearbySet = {}
	if type(session.roomAdjacency) == "table" and type(session.currentRoomId) == "string" then
		for roomId, connected in pairs(session.roomAdjacency[session.currentRoomId] or {}) do
			if connected then
				nearbySet[roomId] = true
			end
		end
	end

	for _, roomId in ipairs(roomIds) do
		local weight = self._config.DefaultRoomWeight
		if roomId == session.favoriteRoomId then
			weight += self._config.FavoriteRoomWeight
		end
		if roomId == session.currentRoomId then
			weight *= self._config.CurrentRoomPenalty
		end

		local activity = roomActivity[roomId] or 0
		weight += activity * self._config.ActivityWeightScale
		if nearbySet[roomId] then
			weight += 0.6
		end
		weight *= roamBias

		table.insert(weightedRooms, {
			value = roomId,
			weight = math.max(0.05, weight),
		})
	end

	return weightedChoice(weightedRooms, self._rng)
end

return GhostRoamingController
