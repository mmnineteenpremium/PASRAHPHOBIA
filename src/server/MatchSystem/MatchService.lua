local MatchQueue = require(script.Parent.MatchQueue)
local MatchBuilder = require(script.Parent.MatchBuilder)
local MatchLifecycle = require(script.Parent.MatchLifecycle)
local MatchTeleport = require(script.Parent.MatchTeleport)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchService = {}
MatchService.__index = MatchService

local function resolveEventBus(deps)
	local eventBus = deps.EventBus
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Publish) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
		return eventBus.Service
	end
	return nil
end

local function getNow(now)
	return now or os.clock()
end

local function resolveMatchRemote()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		return nil
	end
	local remote = remoteEvents:FindFirstChild("MatchEvent")
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

function MatchService.new(state, deps)
	local self = setmetatable({}, MatchService)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)

	self._queue = MatchQueue.new(self._deps.MatchQueueConfig)
	self._builder = MatchBuilder.new(self._deps, self._deps.MatchBuilderConfig)
	self._lifecycle = MatchLifecycle.new(self._deps, self._deps.MatchLifecycleConfig)
	self._teleport = MatchTeleport.new(self._deps, self._deps.MatchTeleportConfig)
	self._matchRemote = resolveMatchRemote()
	return self
end

function MatchService:Init()
	self._state:Set("matches", {})
	self._state:Set("contractsByPartyId", {})
end

function MatchService:Start()
	-- Runtime is event-driven.
end

function MatchService:Stop()
	self._queue:Reset()
	self._state:Set("matches", {})
	self._state:Set("contractsByPartyId", {})
end

function MatchService:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function MatchService:_fireMatchEventToPlayers(players, payload)
	local remote = self._matchRemote
	if not remote then
		remote = resolveMatchRemote()
		self._matchRemote = remote
	end
	if not remote or type(payload) ~= "table" then
		return
	end
	for _, player in ipairs(players or {}) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			remote:FireClient(player, payload)
		end
	end
end

function MatchService:_matches()
	return self._state:Get("matches") or {}
end

function MatchService:_setMatches(matches)
	self._state:Set("matches", matches)
end

function MatchService:SetContractForParty(partyId, contractId)
	local contracts = self._state:Get("contractsByPartyId") or {}
	contracts[partyId] = contractId
	self._state:Set("contractsByPartyId", contracts)
end

function MatchService:JoinQueue(player, payload)
	local ok, reason, entry = self._queue:JoinQueue(player, payload)
	if not ok then
		return false, reason
	end

	self:_publish("PlayerQueued", {
		player = player,
		partyId = entry.partyId,
		queueType = entry.queueType,
	})
	return true
end

function MatchService:LeaveQueue(player)
	return self._queue:LeaveQueue(player)
end

function MatchService:TryCreateMatchFromQueue(payload)
	local found, reason = self._queue:FindMatch()
	if not found then
		return nil, reason
	end

	local contracts = self._state:Get("contractsByPartyId") or {}
	local selectedContractId = nil
	for _, partyId in ipairs(found.partyIds or {}) do
		if contracts[partyId] then
			selectedContractId = contracts[partyId]
			break
		end
	end

	local match = self:CreateMatch({
		players = found.players,
		partyIds = found.partyIds,
		mapId = found.mapId,
		difficulty = found.difficulty,
		gameMode = payload and payload.gameMode or "Standard",
		contractId = selectedContractId,
		now = payload and payload.now or nil,
	})
	return match
end

function MatchService:CreateMatch(payload)
	local match = self._builder:Build(payload or {})
	local matches = self:_matches()
	matches[match.matchId] = match
	self:_setMatches(matches)

	self:_publish("MatchCreated", {
		matchId = match.matchId,
		players = match.players,
		map = match.mapId,
		mapId = match.mapId,
		difficulty = match.difficulty,
		ghostSeed = match.ghostSeed,
		gameMode = match.gameMode,
		partyIds = match.partyIds,
	})

	return match:ToPayload()
end

function MatchService:StartMatch(matchId)
	local matches = self:_matches()
	local match = matches[matchId]
	if not match then
		return nil, "missing_match"
	end

	local now = getNow()
	self._lifecycle:Begin(match, now)

	self:_fireMatchEventToPlayers(match.players, {
		eventName = "MatchPreparing",
		countdown = 2,
	})
	task.wait(1.5)

	local teleportedPlayers = self._teleport:TeleportPlayers(match)
	self:_fireMatchEventToPlayers(teleportedPlayers, {
		eventName = "MatchStarted",
	})

	for _, player in ipairs(teleportedPlayers) do
		self:_publish("PlayerTeleported", {
			player = player,
			matchId = match.matchId,
			mapId = match.mapId,
		})
	end

	self:_publish("MatchStarted", {
		matchId = match.matchId,
		players = match.players,
		map = match.mapId,
		mapId = match.mapId,
		difficulty = match.difficulty,
		phase = match.phase,
		ghostSeed = match.ghostSeed,
	})

	return match:ToPayload()
end

function MatchService:AdvanceMatchPhase(matchId, nextPhase)
	local matches = self:_matches()
	local match = matches[matchId]
	if not match then
		return nil, "missing_match"
	end

	local phase, reason = self._lifecycle:Advance(match, nextPhase, getNow())
	if not phase then
		return nil, reason
	end

	return match:ToPayload()
end

function MatchService:EndMatch(matchId, results)
	local matches = self:_matches()
	local match = matches[matchId]
	if not match then
		return nil, "missing_match"
	end

	self._lifecycle:Finish(match, results or {}, getNow())
	local returnedPlayers = self._teleport:ReturnPlayersToLobby(match)
	for _, player in ipairs(returnedPlayers) do
		self:_publish("PlayerTeleported", {
			player = player,
			matchId = match.matchId,
			mapId = "Lobby",
		})
	end

	self:_publish("MatchEnded", {
		matchId = match.matchId,
		results = match.results or {},
	})

	local payload = match:ToPayload()
	matches[matchId] = nil
	self:_setMatches(matches)
	return payload
end

function MatchService:GetMatch(matchId)
	local match = self:_matches()[matchId]
	if not match then
		return nil
	end
	return match:ToPayload()
end

return MatchService
