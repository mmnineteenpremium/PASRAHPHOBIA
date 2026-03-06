local MatchQueue = {}
MatchQueue.__index = MatchQueue

local DEFAULT_CONFIG = {
	MinPlayersPerMatch = 4,
	MaxPlayersPerMatch = 4,
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

	return {
		partyId = payload and payload.partyId or ("solo:" .. tostring(toUserId(player))),
		queueType = payload and payload.queueType or "normal",
		players = members,
		enqueuedAt = getNow(payload and payload.now),
		mapId = payload and payload.mapId or nil,
		difficulty = payload and payload.difficulty or nil,
	}
end

function MatchQueue:JoinQueue(player, payload)
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

function MatchQueue:FindMatch()
	local minPlayers = self._config.MinPlayersPerMatch
	local maxPlayers = self._config.MaxPlayersPerMatch

	local pickedEntries = {}
	local totalPlayers = 0

	for _, entry in ipairs(self._entries) do
		local entryPlayerCount = #entry.players
		if totalPlayers + entryPlayerCount <= maxPlayers then
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
	for _, entry in ipairs(pickedEntries) do
		table.insert(partyIds, entry.partyId)
		chosenMap = chosenMap or entry.mapId
		chosenDifficulty = chosenDifficulty or entry.difficulty
		for _, member in ipairs(entry.players) do
			table.insert(matchPlayers, member)
		end
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
		difficulty = chosenDifficulty,
	}
end

return MatchQueue
