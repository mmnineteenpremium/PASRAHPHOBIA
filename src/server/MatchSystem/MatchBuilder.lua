local MatchInstance = require(script.Parent.MatchInstance)

local MatchBuilder = {}
MatchBuilder.__index = MatchBuilder

local DEFAULT_CONFIG = {
	DefaultMapPool = { "AbandonedPalace" },
	DefaultDifficulty = "Normal",
	DefaultGameMode = "Standard",
}

function MatchBuilder.new(deps, config)
	local self = setmetatable({}, MatchBuilder)
	self._deps = deps or {}
	self._rng = self._deps.Random or Random.new()
	self._config = {}
	self._nextMatchId = 1

	for key, value in pairs(DEFAULT_CONFIG) do
		self._config[key] = value
	end
	for key, value in pairs(config or {}) do
		self._config[key] = value
	end

	return self
end

function MatchBuilder:_nextId()
	local id = self._nextMatchId
	self._nextMatchId += 1
	return "match_" .. tostring(id)
end

function MatchBuilder:_chooseMap(payload)
	if payload and payload.mapId then
		return payload.mapId
	end
	local pool = self._config.DefaultMapPool
	local index = self._rng:NextInteger(1, #pool)
	return pool[index]
end

function MatchBuilder:Build(payload)
	local matchId = payload and payload.matchId or self:_nextId()
	local mapId = self:_chooseMap(payload)
	local ghostSeed = self._rng:NextInteger(1, 2 ^ 30)

	return MatchInstance.new({
		matchId = matchId,
		state = "Waiting",
		phase = "Lobby",
		players = payload and payload.players or {},
		partyIds = payload and payload.partyIds or {},
		mapId = mapId,
		mapReference = payload and payload.mapReference or nil,
		difficulty = payload and payload.difficulty or self._config.DefaultDifficulty,
		difficultyProfile = payload and payload.difficultyProfile or nil,
		gameMode = payload and payload.gameMode or self._config.DefaultGameMode,
		ghostSeed = payload and payload.ghostSeed or ghostSeed,
		createdAt = payload and payload.now or nil,
	})
end

return MatchBuilder
