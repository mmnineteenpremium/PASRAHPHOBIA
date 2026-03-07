local MatchQueue = require(script.Parent.MatchQueue)
local MatchBuilder = require(script.Parent.MatchBuilder)
local MatchLifecycle = require(script.Parent.MatchLifecycle)
local MatchTeleport = require(script.Parent.MatchTeleport)
local Services = require(script.Parent.Parent.Core.Services)

local MatchService = {}
MatchService.__index = MatchService

local function resolveEventBus(deps)
	local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

local function resolveDifficultyConfigSystem(deps)
	local difficultySystem = Services.Get(deps, "DifficultyConfigSystem")
	if type(difficultySystem) ~= "table" then
		return nil
	end
	if type(difficultySystem.GetDifficultyConfig) == "function" then
		return difficultySystem
	end
	if type(difficultySystem.Service) == "table" and type(difficultySystem.Service.GetDifficultyConfig) == "function" then
		return difficultySystem.Service
	end
	return nil
end

local function getNow(now)
	return now or os.clock()
end

local function toUserId(playerOrUserId)
	if type(playerOrUserId) == "number" then
		return playerOrUserId
	end
	if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		return playerOrUserId.UserId
	end
	return nil
end

function MatchService.new(state, deps)
	local self = setmetatable({}, MatchService)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._difficultyConfigSystem = resolveDifficultyConfigSystem(self._deps)

	self._queue = MatchQueue.new(self._deps.MatchQueueConfig)
	self._builder = MatchBuilder.new(self._deps, self._deps.MatchBuilderConfig)
	self._lifecycle = MatchLifecycle.new(self._deps, self._deps.MatchLifecycleConfig)
	self._teleport = MatchTeleport.new(self._deps, self._deps.MatchTeleportConfig)
	return self
end

function MatchService:_resolveDifficultyProfile(difficultyName)
	if not self._difficultyConfigSystem then
		return nil
	end
	local profile = self._difficultyConfigSystem:GetDifficultyConfig(difficultyName)
	if profile then
		return profile
	end
	return self._difficultyConfigSystem:GetDifficultyConfig("Easy")
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
	match.difficultyProfile = self:_resolveDifficultyProfile(match.difficulty)
	local matches = self:_matches()
	matches[match.matchId] = match
	self:_setMatches(matches)

	self:_publish("MatchCreated", {
		matchId = match.matchId,
		players = match.players,
		map = match.mapId,
		mapId = match.mapId,
		difficulty = match.difficulty,
		difficultyProfile = match.difficultyProfile,
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
	match.difficultyProfile = match.difficultyProfile or self:_resolveDifficultyProfile(match.difficulty)

	local teleportedPlayers = self._teleport:TeleportPlayers(match)
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
		difficultyProfile = match.difficultyProfile,
		phase = match.phase,
		ghostSeed = match.ghostSeed,
	})

	if match.difficultyProfile then
		self:_publish("MatchDifficultyResolved", {
			matchId = match.matchId,
			difficulty = match.difficulty,
			difficultyProfile = match.difficultyProfile,
		})
	end

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

function MatchService:_buildOutcomeSummary(match, results)
	local outcome = results.playerOutcome or {}
	local playersSurvived = 0
	local playersDead = 0
	local playersExtracted = 0

	for userId, playerState in pairs(match.playersByUserId or {}) do
		local key = tostring(userId)
		local existing = outcome[key] or {}
		local alive = playerState.alive ~= false
		local extracted = playerState.extracted == true
		outcome[key] = {
			player = playerState.player,
			userId = userId,
			survived = alive,
			died = not alive,
			extracted = extracted,
			deathReason = playerState.deathReason,
		}

		if alive then
			playersSurvived += 1
		else
			playersDead += 1
		end
		if extracted then
			playersExtracted += 1
		end

		for keyName, value in pairs(existing) do
			if outcome[key][keyName] == nil then
				outcome[key][keyName] = value
			end
		end
	end

	results.playerOutcome = outcome
	results.playersSurvived = results.playersSurvived or playersSurvived
	results.playersDead = results.playersDead or playersDead
	results.playersExtracted = results.playersExtracted or playersExtracted
	results.matchDuration = results.matchDuration or math.max(0, math.floor((getNow() - (match.startedAt or match.createdAt or getNow()))))
	return results
end

function MatchService:MarkPlayerDeath(matchId, userId, reason, payload)
	local matches = self:_matches()
	local match = matches[matchId]
	local numericUserId = toUserId(userId)
	if not match or not numericUserId then
		return nil, "missing_match_or_user"
	end

	local playerState = match.playersByUserId and match.playersByUserId[numericUserId]
	if not playerState or playerState.alive == false then
		return match:ToPayload()
	end

	playerState.alive = false
	playerState.deathReason = reason or "ghost_attack"
	playerState.diedAt = getNow(payload and payload.now)

	self:_publish("MatchPlayerDied", {
		matchId = matchId,
		userId = numericUserId,
		player = playerState.player,
		reason = playerState.deathReason,
		source = "MatchSystem",
	})

	local aliveCount = 0
	for _, state in pairs(match.playersByUserId or {}) do
		if state.alive ~= false then
			aliveCount += 1
		end
	end

	if aliveCount <= 0 then
		return self:EndMatch(matchId, {
			reason = "team_eliminated",
			teamEliminated = true,
		})
	end

	return match:ToPayload()
end

function MatchService:MarkPlayerExtracted(matchId, userId, payload)
	local matches = self:_matches()
	local match = matches[matchId]
	local numericUserId = toUserId(userId)
	if not match or not numericUserId then
		return nil, "missing_match_or_user"
	end

	local playerState = match.playersByUserId and match.playersByUserId[numericUserId]
	if not playerState then
		return match:ToPayload()
	end

	playerState.extracted = true
	playerState.extractedAt = getNow(payload and payload.now)

	self:_publish("MatchPlayerExtracted", {
		matchId = matchId,
		userId = numericUserId,
		player = playerState.player,
		source = "MatchSystem",
	})

	local aliveCount = 0
	local aliveExtractedCount = 0
	for _, state in pairs(match.playersByUserId or {}) do
		if state.alive ~= false then
			aliveCount += 1
			if state.extracted == true then
				aliveExtractedCount += 1
			end
		end
	end

	if aliveCount > 0 and aliveExtractedCount >= aliveCount then
		return self:EndMatch(matchId, {
			reason = "extraction_complete",
			extractionCompleted = true,
		})
	end

	return match:ToPayload()
end

function MatchService:EndMatch(matchId, results)
	local matches = self:_matches()
	local match = matches[matchId]
	if not match then
		return nil, "missing_match"
	end

	local safeResults = results or {}
	if type(safeResults.results) == "table" then
		for key, value in pairs(safeResults.results) do
			if safeResults[key] == nil then
				safeResults[key] = value
			end
		end
		safeResults.results = nil
	end
	safeResults = self:_buildOutcomeSummary(match, safeResults)

	self._lifecycle:Finish(match, safeResults, getNow())
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
		players = match.players,
		mapId = match.mapId,
		difficulty = match.difficulty,
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
