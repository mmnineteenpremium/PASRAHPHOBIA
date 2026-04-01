local MatchQueue = {}
MatchQueue.__index = MatchQueue
MatchQueue.queuePlayers = MatchQueue.queuePlayers or {}

local DEFAULT_CONFIG = {
	MinPlayersPerMatch = 1,
	MaxPlayersPerMatch = 4,
	RankedScoreSpread = 400,
}

local function getNow(now)
	return now or os.clock()
end

local function toUserId(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player.UserId
	end
	return nil
end

local function cloneArray(source)
	local array = {}
	for index, value in ipairs(source or {}) do
		array[index] = value
	end
	return array
end

local function isQueueInstance(value)
	return type(value) == "table" and rawget(value, "_entries") ~= nil and rawget(value, "_entryByUserId") ~= nil
end

local function resolveStaticPlayer(self, player)
	if typeof(self) == "Instance" and self:IsA("Player") then
		return self
	end
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player
	end
	return nil
end

local function getQueueContainer()
	if type(MatchQueue.queuePlayers) ~= "table" then
		MatchQueue.queuePlayers = {}
	end
	return MatchQueue.queuePlayers
end

local function removeFromQueue(queue, player)
	local userId = toUserId(player)
	for index, queued in ipairs(queue) do
		if queued == player then
			table.remove(queue, index)
			return true
		end
		if userId and toUserId(queued) == userId then
			table.remove(queue, index)
			return true
		end
	end
	return false
end

local function resolveAverageRankScore(payload)
	local direct = tonumber(payload and (payload.averageRankScore or payload.rankScore or payload.rating or payload.rankedScore))
	if direct then
		return direct
	end

	local rankScoreList = payload and payload.playerRankScores
	if type(rankScoreList) ~= "table" or #rankScoreList == 0 then
		return nil
	end

	local total = 0
	local count = 0
	for _, value in ipairs(rankScoreList) do
		local numeric = tonumber(value)
		if numeric then
			total += numeric
			count += 1
		end
	end
	if count > 0 then
		return total / count
	end

	return nil
end

function MatchQueue.new(config)
	local self = setmetatable({}, MatchQueue)
	self._config = {}
	for key, value in pairs(DEFAULT_CONFIG) do
		self._config[key] = value
	end
	for key, value in pairs(config or {}) do
		self._config[key] = value
	end

	self._entries = {}
	self._entryByUserId = {}
	return self
end

function MatchQueue:Reset()
	table.clear(self._entries)
	table.clear(self._entryByUserId)
end

function MatchQueue:GetSize()
	return #self._entries
end

function MatchQueue:_buildEntry(player, payload)
	local members = {}
	local seen = {}

	local function addMember(member)
		local userId = toUserId(member)
		if not userId then
			return
		end
		if seen[userId] then
			return
		end
		seen[userId] = true
		table.insert(members, member)
	end

	addMember(player)
	for _, member in ipairs(payload and payload.partyMembers or {}) do
		addMember(member)
	end

	local mode = payload and (payload.mode or payload.gameMode) or "Classic"
	local averageRankScore = resolveAverageRankScore(payload)

	return {
		partyId = payload and payload.partyId or ("solo:" .. tostring(toUserId(player))),
		queueType = payload and payload.queueType or "normal",
		mode = mode,
		gameMode = mode,
		players = members,
		enqueuedAt = getNow(payload and payload.now),
		mapId = payload and payload.mapId or nil,
		difficulty = payload and payload.difficulty or nil,
		averageRankScore = averageRankScore,
	}
end

function MatchQueue:JoinQueue(player, payload)
	if not isQueueInstance(self) then
		local resolvedPlayer = resolveStaticPlayer(self, player)
		if not resolvedPlayer then
			return false, "invalid_player"
		end

		local queue = getQueueContainer()
		local userId = toUserId(resolvedPlayer)
		for _, queued in ipairs(queue) do
			if queued == resolvedPlayer or (userId and toUserId(queued) == userId) then
				return false, "already_queued"
			end
		end

		table.insert(queue, resolvedPlayer)
		return true
	end

	local userId = toUserId(player)
	if not userId then
		return false, "invalid_player"
	end
	if self._entryByUserId[userId] then
		return false, "already_queued"
	end

	local entry = self:_buildEntry(player, payload)
	for _, member in ipairs(entry.players) do
		local memberUserId = member.UserId
		if self._entryByUserId[memberUserId] then
			return false, "party_member_already_queued"
		end
	end

	table.insert(self._entries, entry)
	for _, member in ipairs(entry.players) do
		self._entryByUserId[member.UserId] = entry
	end
	return true, nil, entry
end

function MatchQueue:LeaveQueue(player)
	if not isQueueInstance(self) then
		local resolvedPlayer = resolveStaticPlayer(self, player)
		if not resolvedPlayer then
			return false, "invalid_player"
		end
		local queue = getQueueContainer()
		local removed = removeFromQueue(queue, resolvedPlayer)
		if not removed then
			return false, "not_queued"
		end
		return true
	end

	local userId = toUserId(player)
	if not userId then
		return false, "invalid_player"
	end

	local entry = self._entryByUserId[userId]
	if not entry then
		return false, "not_queued"
	end

	for index, value in ipairs(self._entries) do
		if value == entry then
			table.remove(self._entries, index)
			break
		end
	end

	for _, member in ipairs(entry.players) do
		self._entryByUserId[member.UserId] = nil
	end

	return true
end

function MatchQueue.GetQueuePlayers(queue)
	if isQueueInstance(queue) then
		local players = {}
		local seen = {}
		for _, entry in ipairs(queue._entries or {}) do
			for _, member in ipairs(entry.players or {}) do
				local userId = toUserId(member)
				if userId and not seen[userId] then
					seen[userId] = true
					table.insert(players, member)
				end
			end
		end
		return players
	end

	return cloneArray(getQueueContainer())
end

function MatchQueue.GetQueueSize(queue)
	if isQueueInstance(queue) then
		return #MatchQueue.GetQueuePlayers(queue)
	end
	return #getQueueContainer()
end

function MatchQueue:FindMatch()
	local minPlayers = self._config.MinPlayersPerMatch
	local maxPlayers = self._config.MaxPlayersPerMatch
	local rankedSpread = tonumber(self._config.RankedScoreSpread) or 400

	local pickedEntries = {}
	local totalPlayers = 0
	local selectedMode = nil
	local selectedDifficulty = nil
	local selectedQueueType = nil
	local rankedSeedRankScore = nil

	local function entryMatchesSelection(entry)
		local mode = entry.mode or entry.gameMode or "Classic"
		local queueType = entry.queueType or "normal"
		local difficulty = entry.difficulty
		local averageRankScore = tonumber(entry.averageRankScore)

		if selectedMode == nil then
			return true, mode, queueType, difficulty, averageRankScore
		end

		if mode ~= selectedMode then
			return false
		end

		if queueType ~= selectedQueueType then
			return false
		end

		if selectedMode == "Ranked" then
			if rankedSeedRankScore and averageRankScore and math.abs(averageRankScore - rankedSeedRankScore) > rankedSpread then
				return false
			end
		end

		return true, mode, queueType, difficulty, averageRankScore
	end

	for _, entry in ipairs(self._entries) do
		local canPick, mode, queueType, difficulty, averageRankScore = entryMatchesSelection(entry)
		if not canPick then
			continue
		end

		local entryPlayerCount = #entry.players
		if totalPlayers + entryPlayerCount <= maxPlayers then
			if selectedMode == nil then
				selectedMode = mode
				selectedQueueType = queueType
				if mode ~= "Classic" then
					rankedSeedRankScore = averageRankScore
				end
			elseif selectedMode == "Ranked" and rankedSeedRankScore == nil and averageRankScore then
				rankedSeedRankScore = averageRankScore
			end

			table.insert(pickedEntries, entry)
			totalPlayers += entryPlayerCount
		end
		if totalPlayers >= minPlayers then
			break
		end
	end

	if totalPlayers < minPlayers then
		return nil, "not_enough_players"
	end

	local matchPlayers = {}
	local partyIds = {}
	local chosenMap = nil
	local chosenDifficulty = nil
	local chosenMode = nil
	local chosenQueueType = nil
	local weightedRankScoreTotal = 0
	local weightedRankScoreCount = 0
	for _, entry in ipairs(pickedEntries) do
		table.insert(partyIds, entry.partyId)
		chosenMap = chosenMap or entry.mapId
		if chosenMode == "Classic" or (chosenMode == nil and (entry.mode or entry.gameMode or "Classic") == "Classic") then
			chosenDifficulty = nil
		end
		chosenMode = chosenMode or entry.mode or entry.gameMode
		chosenQueueType = chosenQueueType or entry.queueType

		local entryAverageRankScore = tonumber(entry.averageRankScore)
		if entryAverageRankScore then
			local weight = math.max(#entry.players, 1)
			weightedRankScoreTotal += entryAverageRankScore * weight
			weightedRankScoreCount += weight
		end

		for _, member in ipairs(entry.players) do
			table.insert(matchPlayers, member)
		end
	end

	local averageRankScore = nil
	if weightedRankScoreCount > 0 then
		averageRankScore = weightedRankScoreTotal / weightedRankScoreCount
	end

	for _, entry in ipairs(pickedEntries) do
		for _, member in ipairs(entry.players) do
			self._entryByUserId[member.UserId] = nil
		end
	end

	local remaining = {}
	for _, entry in ipairs(self._entries) do
		local isPicked = false
		for _, chosen in ipairs(pickedEntries) do
			if chosen == entry then
				isPicked = true
				break
			end
		end
		if not isPicked then
			table.insert(remaining, entry)
		end
	end
	self._entries = remaining

	return {
		players = cloneArray(matchPlayers),
		partyIds = partyIds,
		mapId = chosenMap,
		difficulty = chosenDifficulty or selectedDifficulty,
		mode = chosenMode or "Classic",
		gameMode = chosenMode or "Classic",
		queueType = chosenQueueType or "normal",
		averageRankScore = averageRankScore,
	}
end

return MatchQueue

