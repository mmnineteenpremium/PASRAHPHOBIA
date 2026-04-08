local MatchQueue = require(script.Parent.MatchQueue)
local MatchBuilder = require(script.Parent.MatchBuilder)
local MatchLifecycle = require(script.Parent.MatchLifecycle)
local MatchTeleport = require(script.Parent.MatchTeleport)
local Services = require(script.Parent.Parent.Core.Services)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MatchService = {}
MatchService.__index = MatchService

local DEFAULT_MODE_CONFIG = {
	DefaultMode = "Classic",
	DefaultClassicDifficulty = "Mudah",
	DefaultRankedDifficulty = "Lumayan",
	ModeDefinitions = {
		Classic = {
			Name = "Classic",
			AllowDifficultySelection = false,
			PublicDifficultyLabel = "AUTO",
			QueueType = "classic",
		},
		Ranked = {
			Name = "Ranked",
			AllowDifficultySelection = false,
			PublicDifficultyLabel = "AUTO",
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
			DifficultyMode = "Nightmare",
		},
	},
	RankedDifficultyBands = {
		{
			MinRankScore = 0,
			MaxRankScore = 799,
			Difficulty = "Mudah",
		},
		{
			MinRankScore = 800,
			MaxRankScore = 1399,
			Difficulty = "Lumayan",
		},
		{
			MinRankScore = 1400,
			MaxRankScore = 2099,
			Difficulty = "Angker",
		},
		{
			MinRankScore = 2100,
			MaxRankScore = 999999,
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
		auto = "Mudah",
		easy = "Mudah",
		normal = "Lumayan",
		hard = "Angker",
		nightmare = "Uji Nyali",
	},
}

local DEFAULT_PHASE_DURATIONS = {
	PreparationPhase = 30,
	InvestigationPhase = 480,
	HuntPhase = 60,
	EndgamePhase = 30,
}

local CLIENT_PHASE_BY_MATCH_PHASE = {
	Lobby = "Lobby",
	PreparationPhase = "Preparation",
	InvestigationPhase = "Investigation",
	HuntPhase = "Hunt",
	EndgamePhase = "Endgame",
}

local function resolveGhostSystem(deps)
	local ghostSystem = nil
	if type(deps) == "table" then
		local services = deps.Services or deps.ServiceRegistry
		if type(services) == "table" then
			local get = services.Get or services.GetService
			if type(get) == "function" then
				ghostSystem = get(services, "GhostSystem")
			end
		end
		if not ghostSystem and type(deps.GhostSystem) == "table" then
			ghostSystem = deps.GhostSystem
		end
	end
	if type(ghostSystem) ~= "table" then
		return nil
	end
	return ghostSystem
end

local function coerceVector3(value)
	if typeof(value) == "Vector3" then
		return value
	end
	if type(value) == "table" then
		local x = tonumber(value.x or value.X)
		local y = tonumber(value.y or value.Y)
		local z = tonumber(value.z or value.Z)
		if x and y and z then
			return Vector3.new(x, y, z)
		end
	end
	return nil
end

local function resolveSharedGameDataModule(moduleName)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	if not shared then
		return nil
	end
	local gameData = shared:FindFirstChild("GameData")
	if not gameData then
		return nil
	end
	local moduleScript = gameData:FindFirstChild(moduleName)
	if moduleScript and moduleScript:IsA("ModuleScript") then
		return moduleScript
	end
	return nil
end

local function safeRequireModule(moduleScript)
	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

local function resolveGhostTargetBounds(ghostType)
	if type(ghostType) ~= "string" or ghostType == "" then
		return nil
	end
	local tuning = safeRequireModule(resolveSharedGameDataModule("GhostVisualTuning"))
	local ghosts = type(tuning) == "table" and tuning.ghosts or nil
	local config = type(ghosts) == "table" and ghosts[ghostType] or nil
	if type(config) ~= "table" then
		return nil
	end
	return coerceVector3(config.targetBounds) or coerceVector3(config.meshSize)
end

local function resolveStudioGhostSessionState(ghostState, runtimeState)
	local runtimeToken = type(runtimeState) == "string" and runtimeState or nil
	local stateToken = type(ghostState) == "table" and tostring(ghostState.state or "") or nil
	if runtimeToken and runtimeToken ~= "" and type(ghostState) == "table" and ghostState.huntActive == true then
		return runtimeToken
	end
	if stateToken and stateToken ~= "" then
		return stateToken
	end
	if runtimeToken and runtimeToken ~= "" then
		return runtimeToken
	end
	return nil
end

local STUDIO_GHOST_PLAYER_ATTRS = {
	"PasrahGhostMatchId",
	"PasrahGhostType",
	"PasrahGhostModelName",
	"PasrahGhostModelPath",
	"PasrahGhostVisualTemplate",
	"PasrahGhostRuntimeState",
	"PasrahGhostMeshSize",
	"PasrahGhostPosition",
	"PasrahGhostHasModel",
	"PasrahGhostPlaceholder",
	"PasrahGhostSessionState",
	"PasrahGhostCurrentRoomId",
	"PasrahGhostHuntActive",
	"PasrahGhostTargetBounds",
	"PasrahGhostExtents",
	"PasrahGhostScale",
}

local function clearStudioGhostPlayerSnapshot(players)
	if not RunService:IsStudio() or type(players) ~= "table" then
		return
	end
	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			for _, attrName in ipairs(STUDIO_GHOST_PLAYER_ATTRS) do
				player:SetAttribute(attrName, nil)
			end
		end
	end
end

local function setStudioGhostPlayerSnapshot(players, matchId, match, ghostState)
	if not RunService:IsStudio() or type(players) ~= "table" then
		return
	end

	local ghostModel = type(match) == "table" and match.ghost or nil
	local meshPart = ghostModel and ghostModel:FindFirstChildWhichIsA("MeshPart", true) or nil
	local modelPath = typeof(ghostModel) == "Instance" and ghostModel:GetFullName() or nil
	local modelName = typeof(ghostModel) == "Instance" and ghostModel.Name or nil
	local ghostType = type(match) == "table" and tostring(match.ghostType or "") or nil
	local visualTemplateName = typeof(ghostModel) == "Instance" and ghostModel:GetAttribute("VisualTemplateName") or nil
	local runtimeState = typeof(ghostModel) == "Instance" and ghostModel:GetAttribute("RuntimeGhostState") or nil
	local ghostPosition = (ghostModel and ghostModel:IsA("Model")) and tostring(ghostModel:GetPivot().Position) or nil
	local meshSize = (meshPart and meshPart:IsA("MeshPart")) and tostring(meshPart.Size) or nil
	local placeholder = typeof(ghostModel) == "Instance" and ghostModel:GetAttribute("PlaceholderVisual") == true or false
	local ghostExtents = nil
	local ghostScale = nil
	if ghostModel and ghostModel:IsA("Model") then
		local okExtents, extents = pcall(function()
			return ghostModel:GetExtentsSize()
		end)
		if okExtents and typeof(extents) == "Vector3" then
			ghostExtents = tostring(extents)
		end
		local okScale, scale = pcall(function()
			return ghostModel:GetScale()
		end)
		if okScale and type(scale) == "number" then
			ghostScale = scale
		end
	end
	local targetBounds = resolveGhostTargetBounds(ghostType)

	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			player:SetAttribute("PasrahGhostMatchId", type(matchId) == "string" and matchId or tostring(matchId or ""))
			player:SetAttribute("PasrahGhostType", ghostType ~= "" and ghostType or nil)
			player:SetAttribute("PasrahGhostModelName", modelName)
			player:SetAttribute("PasrahGhostModelPath", modelPath)
			player:SetAttribute("PasrahGhostVisualTemplate", visualTemplateName)
			player:SetAttribute("PasrahGhostRuntimeState", runtimeState)
			player:SetAttribute("PasrahGhostMeshSize", meshSize)
			player:SetAttribute("PasrahGhostPosition", ghostPosition)
			player:SetAttribute("PasrahGhostHasModel", typeof(ghostModel) == "Instance")
			player:SetAttribute("PasrahGhostPlaceholder", placeholder)
			player:SetAttribute("PasrahGhostSessionState", resolveStudioGhostSessionState(ghostState, runtimeState))
			player:SetAttribute("PasrahGhostCurrentRoomId", type(ghostState) == "table" and ghostState.currentRoomId or nil)
			player:SetAttribute("PasrahGhostHuntActive", type(ghostState) == "table" and ghostState.huntActive == true or false)
			player:SetAttribute("PasrahGhostTargetBounds", typeof(targetBounds) == "Vector3" and tostring(targetBounds) or nil)
			player:SetAttribute("PasrahGhostExtents", ghostExtents)
			player:SetAttribute("PasrahGhostScale", ghostScale)
		end
	end
end

local OBJECTIVE_TEXT_BY_PHASE = {
	PreparationPhase = "Masuk ke lokasi dan siapkan tim.",
	InvestigationPhase = "Investigasi lokasi, kumpulkan evidence, lalu tebak ghost sebelum waktu habis.",
	HuntPhase = "Bertahan hidup, kunci bukti terakhir, dan siapkan tebakan ghost.",
	EndgamePhase = "Misi ditutup. Tunggu hasil investigasi dan reward.",
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

local function resolveProfileSystem(deps)
	local profile = Services.Get(deps, "ProfileSystem")
	if type(profile) ~= "table" then
		return nil
	end
	if type(profile.GetPlayerLevel) == "function" then
		return profile
	end
	if type(profile.Service) == "table" and type(profile.Service.GetPlayerLevel) == "function" then
		return profile.Service
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

local function safeCall(target, methodName, ...)
	if type(target) ~= "table" then
		return nil
	end
	local method = target[methodName]
	if type(method) ~= "function" then
		return nil
	end
	local ok, result = pcall(method, target, ...)
	if not ok then
		return nil
	end
	return result
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

local function loadMapDatabase()
	local sharedModule = resolveSharedGameDataModule("MapConfig")
	local loaded = safeRequire(sharedModule)
	if type(loaded) == "table" then
		return loaded
	end
	return {}
end

local function preloadModeDefinitions()
	local sharedModule = resolveSharedGameDataModule("ModeDifficultyConfig")
	local loaded = safeRequire(sharedModule)
	if type(loaded) == "table" and type(loaded.ModeDefinitions) == "table" then
		return loaded.ModeDefinitions
	end
	return DEFAULT_MODE_CONFIG.ModeDefinitions
end

local function matchHasPlayer(match, player)
	if type(match) ~= "table" or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	for _, candidate in ipairs(match.players or {}) do
		if candidate == player then
			return true
		end
	end
	return false
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

local function mergePayload(basePayload, overrides)
	local merged = {}
	for key, value in pairs(basePayload or {}) do
		merged[key] = value
	end
	for key, value in pairs(overrides or {}) do
		if merged[key] == nil then
			merged[key] = value
		end
	end
	return merged
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

local function setStudioMatchStartTrace(summary)
	if not RunService:IsStudio() then
		return
	end
	ReplicatedStorage:SetAttribute("PasrahLastMatchStartTrace", summary)
end

local function setStudioMatchStartStage(summary)
	if not RunService:IsStudio() then
		return
	end
	ReplicatedStorage:SetAttribute("PasrahLastMatchStartStage", summary)
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
	self._profileSystem = resolveProfileSystem(self._deps)
	self._modeConfig = loadModeDifficultyConfig(self._deps)
	self._mapDatabase = loadMapDatabase()
	self._phaseDurations = (((self._deps or {}).GamePhaseConfig or (self._deps or {}).GamePhaseSystemConfig or {}).phaseDurations)
		or DEFAULT_PHASE_DURATIONS

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
	if type(config) == "table" and type(config.NormalizeMode) == "function" then
		return config.NormalizeMode(modeName)
	end
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

function MatchService:_resolveAverageRankScore(payload)
	local direct = tonumber(payload and (payload.averageRankScore or payload.rankScore or payload.rating or payload.rankedScore))
	if direct then
		return direct
	end

	local rankScoreList = payload and payload.playerRankScores
	if type(rankScoreList) == "table" and #rankScoreList > 0 then
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
	end

	return nil
end

function MatchService:_resolveAveragePlayerLevel(payload)
	local direct = tonumber(payload and (payload.averagePlayerLevel or payload.avgPlayerLevel or payload.playerLevel))
	if direct then
		return math.max(direct, 1)
	end

	local levelList = payload and payload.playerLevels
	if type(levelList) == "table" and #levelList > 0 then
		local total = 0
		local count = 0
		for _, value in ipairs(levelList) do
			local numeric = tonumber(value)
			if numeric then
				total += numeric
				count += 1
			end
		end
		if count > 0 then
			return math.max(total / count, 1)
		end
	end

	local profileSystem = self._profileSystem or resolveProfileSystem(self._deps)
	local players = payload and payload.players
	if type(players) == "table" and #players > 0 and profileSystem then
		local total = 0
		local count = 0
		for _, playerOrUserId in ipairs(players) do
			local level = safeCall(profileSystem, "GetPlayerLevel", playerOrUserId)
			if level == nil then
				local profile = safeCall(profileSystem, "GetPlayerProfile", playerOrUserId)
				level = type(profile) == "table" and (profile.playerLevel or (profile.progression and profile.progression.level)) or nil
			end
			level = tonumber(level)
			if level then
				total += level
				count += 1
			end
		end
		if count > 0 then
			return math.max(total / count, 1)
		end
	end

	return 1
end

function MatchService:_resolvePartySize(payload)
	local direct = tonumber(payload and (payload.partySize or payload.playerCount))
	if direct then
		return math.max(1, math.floor(direct))
	end

	local players = payload and payload.players
	if type(players) == "table" and #players > 0 then
		return #players
	end

	return 1
end

function MatchService:_resolveClassicDifficulty(payload, requestedDifficulty)
	local config = self._modeConfig or DEFAULT_MODE_CONFIG
	local incoming = type(payload) == "table" and payload or {}
	local resolvedPayload = {}
	for key, value in pairs(incoming) do
		resolvedPayload[key] = value
	end
	resolvedPayload.averagePlayerLevel = resolvedPayload.averagePlayerLevel or self:_resolveAveragePlayerLevel(resolvedPayload)
	resolvedPayload.partySize = resolvedPayload.partySize or self:_resolvePartySize(resolvedPayload)
	resolvedPayload.difficulty = requestedDifficulty

	if type(config) == "table" and type(config.ResolveClassicDifficulty) == "function" then
		return config.ResolveClassicDifficulty(resolvedPayload)
	end

	if resolvedPayload.forceClassicDifficulty == true and type(requestedDifficulty) == "string" and requestedDifficulty ~= "" then
		if type(config.NormalizeDifficulty) == "function" then
			return config.NormalizeDifficulty(requestedDifficulty)
		end
		local difficulties = config.ClassicDifficulties or DEFAULT_MODE_CONFIG.ClassicDifficulties
		if difficulties[requestedDifficulty] then
			return requestedDifficulty
		end
	end

	return config.DefaultClassicDifficulty or DEFAULT_MODE_CONFIG.DefaultClassicDifficulty
end

function MatchService:_resolveRankedDifficulty(payload)
	local config = self._modeConfig or DEFAULT_MODE_CONFIG
	if type(config) == "table" and type(config.ResolveRankedDifficulty) == "function" then
		return config.ResolveRankedDifficulty(payload)
	end
	local rankedDifficulty = payload and (payload.balancedDifficulty or payload.rankedDifficulty)
	if type(rankedDifficulty) == "string" then
		return self:_resolveClassicDifficulty({
			forceClassicDifficulty = true,
		}, rankedDifficulty)
	end

	local averageRankScore = self:_resolveAverageRankScore(payload)
	if type(averageRankScore) == "number" then
		for _, band in ipairs(self._modeConfig.RankedDifficultyBands or {}) do
			local minRankScore = tonumber(band.MinRankScore) or 0
			local maxRankScore = tonumber(band.MaxRankScore) or minRankScore
			if averageRankScore >= minRankScore and averageRankScore <= maxRankScore then
				return self:_resolveClassicDifficulty({
					forceClassicDifficulty = true,
				}, band.Difficulty)
			end
		end
	end

	return self._modeConfig.DefaultRankedDifficulty or self:_resolveClassicDifficulty(nil, nil)
end

function MatchService:_resolveDifficultyName(modeName, requestedDifficulty, payload)
	if modeName == "Ranked" then
		return self:_resolveRankedDifficulty(payload)
	end
	return self:_resolveClassicDifficulty(payload, requestedDifficulty)
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
	local canonicalDifficulty = self:_resolveDifficultyName(modeName, difficultyName, payload)
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
	base.RankScore = self:_resolveAverageRankScore(payload)

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

function MatchService:_getMapDefinition(mapId)
	if type(mapId) ~= "string" or mapId == "" then
		return nil
	end
	local database = self._mapDatabase or {}
	local direct = database[mapId]
	if type(direct) == "table" then
		return direct
	end
	local normalized = normalizeToken(mapId)
	for key, value in pairs(database) do
		if normalizeToken(key) == normalized and type(value) == "table" then
			return value
		end
	end
	return nil
end

function MatchService:_hydrateMatchMapData(match)
	if type(match) ~= "table" then
		return nil
	end
	local mapDef = self:_getMapDefinition(match.mapId or match.map)
	if type(mapDef) ~= "table" then
		return nil
	end

	if type(match.roomIds) ~= "table" or #match.roomIds == 0 then
		match.roomIds = deepCopy(mapDef.rooms or {})
	end
	if type(match.ghostRoomCandidates) ~= "table" or #match.ghostRoomCandidates == 0 then
		match.ghostRoomCandidates = deepCopy(mapDef.ghostRoomCandidates or {})
	end
	if type(match.evidenceSpawnPoints) ~= "table" or #match.evidenceSpawnPoints == 0 then
		match.evidenceSpawnPoints = deepCopy(mapDef.evidenceSpawnPoints or {})
	end
	match.mapDefinition = mapDef
	return mapDef
end

function MatchService:_getPhaseDuration(phaseName)
	local duration = self._phaseDurations and self._phaseDurations[phaseName]
	if type(duration) == "number" and duration >= 0 then
		return duration
	end
	return nil
end

function MatchService:_buildPhasePayload(match, phaseName, startedAt)
	local durationSeconds = self:_getPhaseDuration(phaseName)
	local phaseStartedAt = startedAt or getNow()
	local endsAt = durationSeconds and (phaseStartedAt + durationSeconds) or nil
	local mapDef = self:_hydrateMatchMapData(match)

	return {
		eventName = "PhaseChanged",
		matchId = match.matchId,
		matchPhase = phaseName,
		phase = CLIENT_PHASE_BY_MATCH_PHASE[phaseName] or phaseName,
		phaseName = CLIENT_PHASE_BY_MATCH_PHASE[phaseName] or phaseName,
		lifecyclePhase = phaseName,
		phaseStartedAt = phaseStartedAt,
		durationSeconds = durationSeconds,
		phaseEndsAt = endsAt,
		objectiveText = OBJECTIVE_TEXT_BY_PHASE[phaseName],
		mapId = match.mapId,
		map = match.map or match.mapId,
		mode = match.mode,
		gameMode = match.gameMode,
		difficulty = match.difficulty,
		preparationWorldBoard = match.preparationWorldBoard == true and phaseName == "PreparationPhase",
		roomIds = deepCopy(match.roomIds or {}),
		ghostRoomCandidates = deepCopy(match.ghostRoomCandidates or {}),
		evidenceSpawnPoints = deepCopy(match.evidenceSpawnPoints or {}),
		mapFloorCount = mapDef and mapDef.mapDimensions and mapDef.mapDimensions.floors or nil,
	}
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
			"averageRankScore",
			"playerRankScores",
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
	setStudioMatchStartStage(string.format("match=%s stage=begin", tostring(matchId)))
	self._lifecycle:Begin(match, now)
	self:_hydrateMatchMapData(match)
	match.mode = self:_resolveMode(match.mode or match.gameMode)
	match.gameMode = match.mode
	match.difficulty = self:_resolveDifficultyName(match.mode, match.difficulty, match)
	match.difficultyProfile = match.difficultyProfile or self:_resolveDifficultyProfile(match.mode, match.difficulty, match)
	local authoritativeMatchId = tostring(match.matchId or matchId)
	match.requestAdvancePhase = function(sourcePlayer, nextPhase)
		if type(match) ~= "table" or tostring(match.phase or "") ~= "PreparationPhase" then
			return nil, "preparation_closed"
		end
		if sourcePlayer ~= nil and not matchHasPlayer(match, sourcePlayer) then
			return nil, "player_not_in_match"
		end
		return self:AdvanceMatchPhase(matchId, nextPhase or "InvestigationPhase")
	end
	match.requestForceManifest = function(sourcePlayer)
		if type(match) ~= "table" then
			return nil, "invalid_match"
		end
		if sourcePlayer ~= nil and not matchHasPlayer(match, sourcePlayer) then
			return nil, "player_not_in_match"
		end
		local phaseToken = tostring(match.phase or "")
		if phaseToken ~= "InvestigationPhase" and phaseToken ~= "HuntPhase" then
			return nil, "manifest_closed"
		end
		local now = getNow()
		local ghostSystem = resolveGhostSystem(self._deps)
		local forced = false
		if ghostSystem and type(ghostSystem.ForceManifest) == "function" then
			forced = ghostSystem:ForceManifest(match, now) == true
			if type(ghostSystem.TickGhost) == "function" then
				ghostSystem:TickGhost(match, match.snapshot or {}, 0.2, now)
			end
		end
		if not forced then
			self:_publish("ForceManifest", {
				matchId = authoritativeMatchId,
				source = "MatchPreparationProbe",
				reason = "studio_probe",
				now = now,
			})
		end
		local ghostState = ghostSystem and type(ghostSystem.GetGhostState) == "function" and ghostSystem:GetGhostState(authoritativeMatchId) or nil
		setStudioGhostPlayerSnapshot(match.players, authoritativeMatchId, match, ghostState)
		return forced or true
	end

	for _, player in ipairs(match.players or {}) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			player:SetAttribute("InMatch", true)
			player:SetAttribute("MatchId", authoritativeMatchId)
			player:SetAttribute("MatchMode", tostring(match.mode or match.gameMode or "Classic"))
			player:SetAttribute("MatchDifficulty", tostring(match.difficulty or "Mudah"))
			player:SetAttribute("MatchMapId", tostring(match.mapId or match.map or ""))
			player:SetAttribute("MatchLifecyclePhase", tostring(match.phase or "PreparationPhase"))
			player:SetAttribute("PreparationFocusTool", nil)
		end
	end

	self:_fireMatchEventToPlayers(match.players, {
		eventName = "MatchPreparing",
		countdown = 2,
	})
	setStudioMatchStartStage(string.format("match=%s stage=preparing_sent", tostring(matchId)))

	task.delay(1.5, function()
		local ok, err = pcall(function()
			local currentMatch = self:_matches()[matchId]
			if currentMatch ~= match then
				setStudioMatchStartStage(string.format("match=%s stage=deferred_cancelled", tostring(matchId)))
				setStudioMatchStartTrace(string.format("match=%s cancelled=match_missing_or_replaced", tostring(matchId)))
				return
			end

			setStudioMatchStartStage(string.format("match=%s stage=preparing_wait_complete", tostring(matchId)))

			setStudioMatchStartStage(string.format("match=%s stage=teleport_begin", tostring(matchId)))
			local teleportOk, teleportedPlayersOrErr = pcall(function()
				return self._teleport:TeleportPlayers(match)
			end)
			if not teleportOk then
				local teleportErr = tostring(teleportedPlayersOrErr)
				setStudioMatchStartStage(string.format("match=%s stage=teleport_error err=%s", tostring(matchId), teleportErr))
				setStudioMatchStartTrace(string.format("match=%s error=teleport_failed err=%s", tostring(matchId), teleportErr))
				return
			end

			currentMatch = self:_matches()[matchId]
			if currentMatch ~= match then
				setStudioMatchStartStage(string.format("match=%s stage=post_teleport_cancelled", tostring(matchId)))
				setStudioMatchStartTrace(string.format("match=%s cancelled=match_missing_or_replaced_after_teleport", tostring(matchId)))
				return
			end

			local phaseNow = getNow()
			local teleportedPlayers = teleportedPlayersOrErr
			setStudioMatchStartTrace(string.format(
				"match=%s players=%d teleported=%d phase=%s map=%s mode=%s",
				tostring(match.matchId),
				#(match.players or {}),
				#(teleportedPlayers or {}),
				tostring(match.phase),
				tostring(match.mapId),
				tostring(match.mode)
			))
			self:_fireMatchEventToPlayers(teleportedPlayers, {
				eventName = "MatchStarted",
				phase = CLIENT_PHASE_BY_MATCH_PHASE[match.phase] or match.phase,
				lifecyclePhase = match.phase,
				phaseStartedAt = phaseNow,
				durationSeconds = self:_getPhaseDuration(match.phase),
				preparationWorldBoard = match.preparationWorldBoard == true and match.phase == "PreparationPhase",
			})
			self:_fireMatchEventToPlayers(teleportedPlayers, self:_buildPhasePayload(match, match.phase, phaseNow))
			setStudioMatchStartStage(string.format("match=%s stage=match_started_sent", tostring(matchId)))

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
				roomIds = deepCopy(match.roomIds or {}),
				ghostRoomCandidates = deepCopy(match.ghostRoomCandidates or {}),
				evidenceSpawnPoints = deepCopy(match.evidenceSpawnPoints or {}),
				ghostSeed = match.ghostSeed,
			})

			local ghostSystem = resolveGhostSystem(self._deps)
			if ghostSystem and type(ghostSystem.InitializeMatch) == "function" then
				pcall(function()
					ghostSystem:InitializeMatch(match)
				end)
			end
			local runtimeGhostSystem = ghostSystem or resolveGhostSystem(self._deps)
			local ghostState = runtimeGhostSystem and type(runtimeGhostSystem.GetGhostState) == "function"
				and runtimeGhostSystem:GetGhostState(authoritativeMatchId)
				or nil
			setStudioGhostPlayerSnapshot(match.players, authoritativeMatchId, match, ghostState)

			if match.difficultyProfile then
				self:_publish("MatchDifficultyResolved", {
					matchId = match.matchId,
					mode = match.mode,
					difficulty = match.difficulty,
					difficultyProfile = match.difficultyProfile,
				})
			end
		end)
		if not ok then
			local startErr = tostring(err)
			setStudioMatchStartStage(string.format("match=%s stage=deferred_error err=%s", tostring(matchId), startErr))
			setStudioMatchStartTrace(string.format("match=%s error=deferred_start_failed err=%s", tostring(matchId), startErr))
		end
	end)

	return match:ToPayload()
end

function MatchService:AdvanceMatchPhase(matchId, nextPhase)
	local matches = self:_matches()
	local match = matches[matchId]
	if not match then
		return nil, "missing_match"
	end

	local now = getNow()
	local phase, reason = self._lifecycle:Advance(match, nextPhase, now)
	if not phase then
		return nil, reason
	end

	for _, player in ipairs(match.players or {}) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			player:SetAttribute("MatchLifecyclePhase", tostring(phase))
		end
	end
	local ghostSystem = resolveGhostSystem(self._deps)
	local ghostState = ghostSystem and type(ghostSystem.GetGhostState) == "function" and ghostSystem:GetGhostState(matchId) or nil
	setStudioGhostPlayerSnapshot(match.players, matchId, match, ghostState)

	self:_fireMatchEventToPlayers(match.players, self:_buildPhasePayload(match, phase, now))

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
			player:SetAttribute("MatchMode", nil)
			player:SetAttribute("MatchDifficulty", nil)
			player:SetAttribute("MatchMapId", nil)
			player:SetAttribute("MatchLifecyclePhase", nil)
			player:SetAttribute("PreparationFocusTool", nil)
		end
		self:_publish("PlayerTeleported", {
			player = player,
			matchId = match.matchId,
			mapId = "Lobby",
		})
	end
	clearStudioGhostPlayerSnapshot(lobbyPlayers)

	local payload = mergePayload(match:ToPayload(), safeResults)
	payload.source = "MatchSystem"
	self:_publish("MatchEnded", payload)
	self:_fireMatchEventToPlayers(lobbyPlayers, mergePayload(payload, {
		eventName = "MatchEnded",
	}))
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

function MatchService:GetLiveMatch(matchId)
	return self:_matches()[matchId]
end

return MatchService
