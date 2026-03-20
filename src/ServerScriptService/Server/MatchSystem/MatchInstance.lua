local MatchTeleport = require(script.Parent.MatchTeleport)

local MatchInstance = {}
MatchInstance.__index = MatchInstance

local DEFAULT_STATE = "Waiting"

local function getNow(now)
	return now or os.clock()
end

local function buildPlayerState(players)
	local byUserId = {}
	for _, player in ipairs(players or {}) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			byUserId[player.UserId] = {
				player = player,
				alive = true,
				sanity = 100,
				role = "Investigator",
			}
		end
	end
	return byUserId
end

function MatchInstance.new(payload)
	local players = payload.players or {}
	local self = setmetatable({}, MatchInstance)
	self.id = payload.id or payload.matchId
	self.matchId = payload.matchId or payload.id
	self.state = payload.state or DEFAULT_STATE
	self.phase = payload.phase or "Lobby"
	self.players = players
	self.playersByUserId = buildPlayerState(players)
	self.partyIds = payload.partyIds or {}
	self.map = payload.map or payload.mapId or "AbandonedPalace"
	self.mapId = payload.mapId or self.map
	self.mapReference = payload.mapReference
	self.difficulty = payload.difficulty or "Mudah"
	self.difficultyProfile = payload.difficultyProfile
	self.ghostSeed = payload.ghostSeed or 0
	self.mode = payload.mode or payload.gameMode or "Classic"
	self.gameMode = payload.gameMode or payload.mode or "Classic"
	self.createdAt = getNow(payload.createdAt)
	self.startedAt = nil
	self.endedAt = nil
	self.results = nil
	self.history = {}
	return self
end

function MatchInstance:SetState(nextState, now)
	self.state = nextState
	table.insert(self.history, {
		type = "state",
		value = nextState,
		at = getNow(now),
	})
end

function MatchInstance:SetPhase(nextPhase, now)
	self.phase = nextPhase
	table.insert(self.history, {
		type = "phase",
		value = nextPhase,
		at = getNow(now),
	})
end

function MatchInstance:MarkStarted(now)
	self.startedAt = getNow(now)
	self:SetState("InProgress", now)
end

function MatchInstance:MarkEnded(results, now)
	self.endedAt = getNow(now)
	self.results = results or {}
	self:SetState("Completed", now)
end

function MatchInstance:ToPayload()
	return {
		id = self.id,
		matchId = self.matchId,
		state = self.state,
		phase = self.phase,
		players = self.players,
		partyIds = self.partyIds,
		map = self.map,
		mapId = self.mapId,
		mapReference = self.mapReference,
		difficulty = self.difficulty,
		difficultyProfile = self.difficultyProfile,
		ghostSeed = self.ghostSeed,
		mode = self.mode,
		gameMode = self.gameMode,
		createdAt = self.createdAt,
		startedAt = self.startedAt,
		endedAt = self.endedAt,
		results = self.results,
	}
end

function MatchInstance:Start()
	MatchTeleport:TeleportPlayers(self.players, self.map or self.mapId)
end

return MatchInstance
