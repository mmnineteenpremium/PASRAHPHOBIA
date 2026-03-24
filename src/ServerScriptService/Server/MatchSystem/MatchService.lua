local MatchQueue = require(script.Parent.MatchQueue)
local MatchBuilder = require(script.Parent.MatchBuilder)
local MatchLifecycle = require(script.Parent.MatchLifecycle)
local MatchTeleport = require(script.Parent.MatchTeleport)
local Services = require(script.Parent.Parent.Core.Services)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchService = {}
MatchService.__index = MatchService

local DEFAULT_MODE_CONFIG = {
	DefaultMode = "Classic",
	DefaultClassicDifficulty = "Mudah",
	DefaultRankedDifficulty = "Lumayan",
	ModeDefinitions = {
		Classic = {
			Name = "Classic",
			AllowDifficultySelection = true,
			QueueType = "classic",
		},
		Ranked = {
			Name = "Ranked",
			AllowDifficultySelection = false,
			QueueType = "ranked",
		},
	},
	ClassicDifficulties = {
		Mudah = {
			Name = "Mudah",
			EvidenceCount = 4,
			GhostAggression = 0.85,
			HuntFrequency = 0.8,
			EvidenceClarity = 1.2,
			SanityDrain = 0.8,
			DifficultyMode = "Easy",
		},
		Lumayan = {
			Name = "Lumayan",
			EvidenceCount = 3,
			GhostAggression = 1.0,
			HuntFrequency = 1.0,
			EvidenceClarity = 1.0,
			SanityDrain = 1.0,
			DifficultyMode = "Normal",
		},
		Angker = {
			Name = "Angker",
			EvidenceCount = 3,
			GhostAggression = 1.4,
			HuntFrequency = 1.3,
			EvidenceClarity = 0.8,
			SanityDrain = 1.2,
			DifficultyMode = "Hard",
		},
		["Uji Nyali"] = {
			Name = "Uji Nyali",
			EvidenceCount = 2,
			GhostAggression = 1.65,
			HuntFrequency = 1.5,
			EvidenceClarity = 0.65,
			SanityDrain = 1.4,
			DifficultyMode = "Hard",
		},
	},
	RankedDifficultyBands = {
		{
			MinMMR = 0,
			MaxMMR = 799,
			Difficulty = "Mudah",
		},
		{
			MinMMR = 800,
			MaxMMR = 1399,
			Difficulty = "Lumayan",
		},
		{
			MinMMR = 1400,
			MaxMMR = 2099,
			Difficulty = "Angker",
		},
		{
			MinMMR = 2100,
			MaxMMR = 999999,
			Difficulty = "Uji Nyali",
		},
	},
	Aliases = {
		classic = "Classic",
		ranked = "Ranked",
		mudah = "Mudah",
		lumayan = "Lumayan",
		angker = "Angker",
		ujinyali = "Uji Nyali",
		easy = "Mudah",
		normal = "Lumayan",
		hard = "Angker",
		nightmare = "Uji Nyali",
	},
}

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

local function resolveEventMapRotationSystem(deps)
	local rotationSystem = Services.Get(deps, "EventMapRotationSystem")
	if type(rotationSystem) ~= "table" then
		return nil
	end
	if type(rotationSystem.GetRandomMap) == "function" then
		return rotationSystem
	end
	if type(rotationSystem.Service) == "table" and type(rotationSystem.Service.GetRandomMap) == "function" then
		return rotationSystem.Service
	end
	return nil
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, nested in pairs(value) do
		out[key] = deepCopy(nested)
	end
	return out
end

local function safeRequire(moduleScript)
	if not moduleScript then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok then
		return result
	end
	return nil
end

local function resolveSharedGameDataModule(moduleName)
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
	if not shared then
		return nil
	end
	local gameDataFolder = shared:FindFirstChild("GameData")
	if not gameDataFolder then
		return nil
	end
	return gameDataFolder:FindFirstChild(moduleName)
end

local function loadModeDifficultyConfig(deps)
	if type(deps) == "table" and type(deps.ModeDifficultyConfig) == "table" then
		return deepCopy(deps.ModeDifficultyConfig)
	end

	local sharedModule = resolveSharedGameDataModule("ModeDifficultyConfig")
	local loaded = safeRequire(sharedModule)
	if type(loaded) == "table" then
		return loaded
	end
	return deepCopy(DEFAULT_MODE_CONFIG)
end

local function preloadModeDefinitions()
	local sharedModule = resolveSharedGameDataModule("ModeDifficultyConfig")
	local loaded = safeRequire(sharedModule)
	if type(loaded) == "table" and type(loaded.ModeDefinitions) == "table" then
		return loaded.ModeDefinitions
	end
	return DEFAULT_MODE_CONFIG.ModeDefinitions
end

local PRELOADED_MODE_DEFINITIONS = preloadModeDefinitions()
MatchService._queue = MatchService._queue or {}
MatchService.ModeDefinitions = PRELOADED_MODE_DEFINITIONS

local function ensureQueueAndDefinitions(self)
	if not self._modeConfig then
		self._modeConfig = deepCopy(DEFAULT_MODE_CONFIG)
	end
	if not self._queue or type(self._queue.JoinQueue) ~= "function" then
		self._queue = MatchQueue.new(self._deps and self._deps.MatchQueueConfig)
	end
	if not self.ModeDefinitions then
		self.ModeDefinitions = self._modeConfig.ModeDefinitions
	end
end

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-_]+", ""):lower()
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

local function resolveMatchRemote()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		return nil
	end
	local remote = remoteFolder:FindFirstChild("MatchEvent")
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

function MatchService.new(deps)
	local self = setmetatable({}, MatchService)
	self._deps = deps or {}
	self._state = {
		_data = {},
		Get = function(state, key)
			return state._data[key]
		end,
		Set = function(state, key, value)
			state._data[key] = value
		end,
	}
	self._eventBus = resolveEventBus(self._deps)
	self._difficultyConfigSystem = resolveDifficultyConfigSystem(self._deps)
	self._eventMapRotationSystem = resolveEventMapRotationSystem(self._deps)
	self._modeConfig = loadModeDifficultyConfig(self._deps)

	if type(self._modeConfig) ~= "table" then
		self._modeConfig = {}
	end
	local modeConfig = self._modeConfig
	modeConfig.ModeDefinitions = modeConfig.ModeDefinitions or DEFAULT_MODE_CONFIG.ModeDefinitions
	modeConfig.ClassicDifficulties = modeConfig.ClassicDifficulties or DEFAULT_MODE_CONFIG.ClassicDifficulties
	modeConfig.RankedDifficultyBands = modeConfig.RankedDifficultyBands or DEFAULT_MODE_CONFIG.RankedDifficultyBands
	modeConfig.Aliases = modeConfig.Aliases or DEFAULT_MODE_CONFIG.Aliases

	self._queue = MatchQueue.new(self._deps.MatchQueueConfig)
	self._builder = MatchBuilder.new(self._deps, self._deps.MatchBuilderConfig)
	self._lifecycle = MatchLifecycle.new(self._deps, self._deps.MatchLifecycleConfig)
	self._teleport = MatchTeleport.new(self._deps, self._deps.MatchTeleportConfig)
	self._matchRemote = resolveMatchRemote()
	ensureQueueAndDefinitions(self)
	return self
end

function MatchService:_resolveMode(modeName)
	local config = self._modeConfig or DEFAULT_MODE_CONFIG
	local modeDefs = config.ModeDefinitions or DEFAULT_MODE_CONFIG.ModeDefinitions
	local aliases = config.Aliases or DEFAULT_MODE_CONFIG.Aliases

	local canonical = modeName
	if type(canonical) == "string" and aliases[canonical] then
		canonical = aliases[canonical]
	end
	if type(canonical) ~= "string" then
		canonical = config.DefaultMode or DEFAULT_MODE_CONFIG.DefaultMode
	end

	local modeDef = modeDefs[canonical]
	if not modeDef then
		error("Invalid mode: " .. tostring(canonical))
	end

	return canonical
end

function MatchService:_resolveClassicDifficulty(difficultyName)
	local config = self._modeConfig or DEFAULT_MODE_CONFIG
	local difficulties = config.ClassicDifficulties or DEFAULT_MODE_CONFIG.ClassicDifficulties
	if type(difficultyName) == "string" and difficulties[difficultyName] then
		return difficultyName
	end

	local aliases = config.Aliases or DEFAULT_MODE_CONFIG.Aliases
	local aliased = aliases[normalizeToken(difficultyName or "")]
	if type(aliased) == "string" and difficulties[aliased] then
		return aliased
	end

	return config.DefaultClassicDifficulty or DEFAULT_MODE_CONFIG.DefaultClassicDifficulty
end

function MatchService:_resolveAverageMMR(payload)
	local direct = tonumber(payload and (payload.averageMMR or payload.mmr or payload.rating or payload.rankedMMR))
	if direct then
		return direct
	end

	local mmrList = payload and payload.playerMMRs
	if type(mmrList) == "table" and #mmrList > 0 then
		local total = 0
		local count = 0
		for _, value in ipairs(mmrList) do
			local numeric = tonumber(value)
			if numeric then
				total += numeric
				count += 1
			end
		end
		if count > 0 then
			return total / count
		end
	end

	return nil
end

function MatchService:_resolveRankedDifficulty(payload)
	local rankedDifficulty = payload and (payload.balancedDifficulty or payload.rankedDifficulty)
	if type(rankedDifficulty) == "string" then
		return self:_resolveClassicDifficulty(rankedDifficulty)
	end

	local averageMMR = self:_resolveAverageMMR(payload)
	if type(averageMMR) == "number" then
		for _, band in ipairs(self._modeConfig.RankedDifficultyBands or {}) do
			local minMMR = tonumber(band.MinMMR) or 0
			local maxMMR = tonumber(band.MaxMMR) or minMMR
			if averageMMR >= minMMR and averageMMR <= maxMMR then
				return self:_resolveClassicDifficulty(band.Difficulty)
			end
		end
	end

	return self._modeConfig.DefaultRankedDifficulty or self:_resolveClassicDifficulty(nil)
end

function MatchService:_resolveDifficultyName(modeName, requestedDifficulty, payload)
	if modeName == "Ranked" then
		return self:_resolveRankedDifficulty(payload)
	end
	return self:_resolveClassicDifficulty(requestedDifficulty)
end

function MatchService:_resolveLegacyDifficultyProfile(difficultyName, fallbackDifficultyMode)
	if not self._difficultyConfigSystem then
		return nil
	end

	local profile = self._difficultyConfigSystem:GetDifficultyConfig(difficultyName)
	if profile then
		return profile
	end
	if type(fallbackDifficultyMode) == "string" then
		profile = self._difficultyConfigSystem:GetDifficultyConfig(fallbackDifficultyMode)
		if profile then
			return profile
		end
	end
	return self._difficultyConfigSystem:GetDifficultyConfig("Easy")
end

function MatchService:_resolveDifficultyProfile(modeName, difficultyName, payload)
	local canonicalDifficulty = self:_resolveClassicDifficulty(difficultyName)
	local base = deepCopy((self._modeConfig.ClassicDifficulties or {})[canonicalDifficulty] or {})
	base.Name = canonicalDifficulty
	base.Mode = modeName
	base.EvidenceRequired = tonumber(base.EvidenceRequired or base.EvidenceCount or 3) or 3
	base.EvidenceCount = base.EvidenceRequired
	base.GhostAggressionMultiplier = tonumber(base.GhostAggression or base.GhostAggressionMultiplier or 1.0) or 1.0
	base.HuntFrequencyMultiplier = tonumber(base.HuntFrequency or base.HuntFrequencyMultiplier or 1.0) or 1.0
	base.EvidenceClarityMultiplier = tonumber(base.EvidenceClarity or base.EvidenceClarityMultiplier or 1.0) or 1.0
	base.SanityDrainMultiplier = tonumber(base.SanityDrain or base.SanityDrainMultiplier or 1.0) or 1.0
	base.GhostAggression = base.GhostAggressionMultiplier
	base.HuntFrequency = base.HuntFrequencyMultiplier
	base.EvidenceClarity = base.EvidenceClarityMultiplier
	base.SanityDrain = base.SanityDrainMultiplier
	base.DifficultyMode = base.DifficultyMode or "Normal"
	base.difficultyMode = base.DifficultyMode
	base.Ranked = modeName == "Ranked"
	base.MMR = self:_resolveAverageMMR(payload)

	local legacy = self:_resolveLegacyDifficultyProfile(canonicalDifficulty, base.DifficultyMode)
	if type(legacy) ~= "table" then
		return base
	end

	local merged = deepCopy(legacy)
	for key, value in pairs(base) do
		merged[key] = value
	end
	return merged
end

function MatchService:_sanitizeQueuePayload(payload)
	local incoming = payload or {}
	local mode = self:_resolveMode(incoming.mode or incoming.gameMode)
	local difficulty = self:_resolveDifficultyName(mode, incoming.difficulty, incoming)
	local sanitized = {}
	for key, value in pairs(incoming) do
		sanitized[key] = value
	end
	sanitized.mode = mode
	sanitized.gameMode = mode
	sanitized.difficulty = difficulty
	sanitized.queueType = sanitized.queueType
		or ((self._modeConfig.ModeDefinitions or {})[mode] and (self._modeConfig.ModeDefinitions or {})[mode].QueueType)
		or string.lower(mode)
	return sanitized
end

function MatchService:Init()
	if self._initialized then
		return
	end

	self._initialized = true

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
	ensureQueueAndDefinitions(self)
	print("[MatchQueue] join", player.Name)
	print("[MatchQueue] partyId", payload and payload.partyId)
	local queuePayload = self:_sanitizeQueuePayload(payload)
	local ok, reason, entry = self._queue:JoinQueue(player, queuePayload)
	if not ok then
		return false, reason
	end

	self:_publish("PlayerQueued", {
		player = player,
		partyId = entry.partyId,
		queueType = entry.queueType,
		mode = entry.mode or entry.gameMode,
		gameMode = entry.gameMode or entry.mode,
		difficulty = entry.difficulty,
	})
	return true
end

function MatchService:LeaveQueue(player)
	return self._queue:LeaveQueue(player)
end

function MatchService:TryCreateMatchFromQueue(payload)
	ensureQueueAndDefinitions(self)
	print("[MatchService] Attempting match creation")
	local queueMatch, reason = self._queue:FindMatch()
	if not queueMatch then
		return nil, reason or "not_enough_players"
	end

	local createPayload = {}
	for key, value in pairs(queueMatch) do
		createPayload[key] = value
	end

	if type(payload) == "table" then
		local overrideKeys = {
			"mapId",
			"mode",
			"gameMode",
			"difficulty",
			"difficultyProfile",
			"averageMMR",
			"playerMMRs",
			"rankedDifficulty",
			"now",
		}
		for _, key in ipairs(overrideKeys) do
			if payload[key] ~= nil then
				createPayload[key] = payload[key]
			end
		end
	end

	local match = self:CreateMatch(createPayload)
	if not match then
		return nil, "match_build_failed"
	end

	return match
end

function MatchService:DevForceMatch(players)
	ensureQueueAndDefinitions(self)
	if not self._queue or type(self._queue.JoinQueue) ~= "function" then
		self._queue = MatchQueue.new(self._deps and self._deps.MatchQueueConfig)
	end

	local payload = {
		Mode = "Classic",
		DifficultyMode = "Easy",
		Map = "HauntedHouse",
	}

	local queuedPlayers = players or {}
	for _, player in ipairs(queuedPlayers) do
		self:JoinQueue(player, {
			partyId = "dev:" .. tostring(player.UserId),
			queueType = "classic",
			mode = "Classic",
			gameMode = "Classic",
			difficulty = "Mudah",
			mapId = payload.Map,
		})
	end

	local match, reason = self:TryCreateMatchFromQueue()
	if not match then
		return nil, reason
	end
	return self:StartMatch(match.matchId)
end

function MatchService:StartRoomMatch(players)
	local match = self:CreateMatch({
		players = players or {},
	})
	if not match then
		return nil, "match_build_failed"
	end
	return self:StartMatch(match.matchId)
end

function MatchService:CreateMatch(payload)
	local resolvedPayload = payload or {}
	if resolvedPayload.mapId == nil and self._eventMapRotationSystem then
		local mapId = self._eventMapRotationSystem:GetRandomMap()
		if type(mapId) == "string" and mapId ~= "" then
			local copiedPayload = {}
			for key, value in pairs(resolvedPayload) do
				copiedPayload[key] = value
			end
			copiedPayload.mapId = mapId
			resolvedPayload = copiedPayload
		end
	end

	local mode = self:_resolveMode(resolvedPayload.mode or resolvedPayload.gameMode)
	local difficulty = self:_resolveDifficultyName(mode, resolvedPayload.difficulty, resolvedPayload)
	local difficultyProfile = resolvedPayload.difficultyProfile
		or self:_resolveDifficultyProfile(mode, difficulty, resolvedPayload)

	local copiedPayload = {}
	for key, value in pairs(resolvedPayload) do
		copiedPayload[key] = value
	end
	copiedPayload.mode = mode
	copiedPayload.gameMode = mode
	copiedPayload.difficulty = difficulty
	copiedPayload.difficultyProfile = difficultyProfile

	local match = self._builder:Build(copiedPayload)
	match.mode = mode
	match.gameMode = mode
	match.difficulty = difficulty
	match.difficultyProfile = difficultyProfile
	local matches = self:_matches()
	matches[match.matchId] = match
	self:_setMatches(matches)

	self:_publish("MatchCreated", {
		matchId = match.matchId,
		players = match.players,
		map = match.mapId,
		mapId = match.mapId,
		mode = match.mode,
		gameMode = match.gameMode,
		difficulty = match.difficulty,
		difficultyProfile = match.difficultyProfile,
		ghostSeed = match.ghostSeed,
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
	match.mode = self:_resolveMode(match.mode or match.gameMode)
	match.gameMode = match.mode
	match.difficulty = self:_resolveDifficultyName(match.mode, match.difficulty, match)
	match.difficultyProfile = match.difficultyProfile or self:_resolveDifficultyProfile(match.mode, match.difficulty, match)
	local authoritativeMatchId = tostring(match.matchId or matchId)

	for _, player in ipairs(match.players or {}) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			player:SetAttribute("InMatch", true)
			player:SetAttribute("MatchId", authoritativeMatchId)
		end
	end

	self:_fireMatchEventToPlayers(match.players, {
		eventName = "MatchPreparing",
		countdown = 2,
	})
	print("[SERVER MATCH FLOW] Preparing sent")
	task.wait(1.5)

	local teleportedPlayers = self._teleport:TeleportPlayers(match)
	self:_fireMatchEventToPlayers(teleportedPlayers, {
		eventName = "MatchStarted",
	})
	print("[SERVER MATCH FLOW] Started sent")

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
		mode = match.mode,
		gameMode = match.gameMode,
		difficulty = match.difficulty,
		difficultyProfile = match.difficultyProfile,
		phase = match.phase,
		ghostSeed = match.ghostSeed,
	})

	if match.difficultyProfile then
		self:_publish("MatchDifficultyResolved", {
			matchId = match.matchId,
			mode = match.mode,
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

	local returnedPlayers = self._lifecycle:EndMatch(match, safeResults)
	local lobbyPlayers = {}
	for _, player in ipairs(returnedPlayers or {}) do
		table.insert(lobbyPlayers, player)
	end
	if #lobbyPlayers == 0 then
		for _, player in ipairs(match.players or {}) do
			table.insert(lobbyPlayers, player)
		end
	end

	for _, player in ipairs(lobbyPlayers) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			player:SetAttribute("InMatch", false)
			player:SetAttribute("MatchId", nil)
		end
		self:_publish("PlayerTeleported", {
			player = player,
			matchId = match.matchId,
			mapId = "Lobby",
		})
	end

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

