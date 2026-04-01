local DEFAULT_CONFIG = {
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

local ModeSelectionConfig = {}

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

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-_]+", ""):lower()
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

local function resolveSharedModule(moduleName)
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

function ModeSelectionConfig.Load()
	local sharedModule = resolveSharedModule("ModeDifficultyConfig")
	local loaded = safeRequire(sharedModule)
	if type(loaded) == "table" then
		if type(loaded.CloneConfig) == "function" then
			return loaded.CloneConfig()
		end
		local merged = deepCopy(DEFAULT_CONFIG)
		for key, value in pairs(loaded) do
			merged[key] = value
		end
		return merged
	end
	return deepCopy(DEFAULT_CONFIG)
end

function ModeSelectionConfig.NormalizeMode(config, modeName)
	if type(config) == "table" and type(config.NormalizeMode) == "function" then
		return config.NormalizeMode(modeName)
	end
	local modeDefinitions = config and config.ModeDefinitions or {}
	if type(modeName) == "string" and modeDefinitions[modeName] then
		return modeName
	end
	local aliases = config and config.Aliases or {}
	local aliased = aliases[normalizeToken(modeName or "")]
	if type(aliased) == "string" and modeDefinitions[aliased] then
		return aliased
	end
	return (config and config.DefaultMode) or "Classic"
end

function ModeSelectionConfig.NormalizeDifficulty(config, difficultyName)
	if type(config) == "table" and type(config.NormalizeDifficulty) == "function" then
		return config.NormalizeDifficulty(difficultyName)
	end
	local difficulties = config and config.ClassicDifficulties or {}
	if type(difficultyName) == "string" and difficulties[difficultyName] then
		return difficultyName
	end
	local aliases = config and config.Aliases or {}
	local aliased = aliases[normalizeToken(difficultyName or "")]
	if type(aliased) == "string" and difficulties[aliased] then
		return aliased
	end
	return (config and config.DefaultClassicDifficulty) or "Mudah"
end

function ModeSelectionConfig.ResolveRankedDifficulty(config, payload)
	if type(config) == "table" and type(config.ResolveRankedDifficulty) == "function" then
		return config.ResolveRankedDifficulty(payload)
	end
	local manual = payload and (payload.balancedDifficulty or payload.rankedDifficulty)
	if type(manual) == "string" then
		return ModeSelectionConfig.NormalizeDifficulty(config, manual)
	end

	local averageRankScore = tonumber(payload and (payload.averageRankScore or payload.rankScore or payload.rating or payload.rankedScore))
	if averageRankScore then
		for _, band in ipairs(config and config.RankedDifficultyBands or {}) do
			local minRankScore = tonumber(band.MinRankScore) or 0
			local maxRankScore = tonumber(band.MaxRankScore) or minRankScore
			if averageRankScore >= minRankScore and averageRankScore <= maxRankScore then
				return ModeSelectionConfig.NormalizeDifficulty(config, band.Difficulty)
			end
		end
	end

	return (config and config.DefaultRankedDifficulty) or "Lumayan"
end

function ModeSelectionConfig.ResolveClassicDifficulty(config, payload)
	if type(config) == "table" and type(config.ResolveClassicDifficulty) == "function" then
		return config.ResolveClassicDifficulty(payload)
	end

	if payload and payload.forceClassicDifficulty == true then
		local requested = payload.classicDifficulty or payload.balancedDifficulty or payload.difficulty
		if type(requested) == "string" and requested ~= "" then
			return ModeSelectionConfig.NormalizeDifficulty(config, requested)
		end
	end

	local partySize = tonumber(payload and (payload.partySize or payload.playerCount))
	if partySize == nil and type(payload and payload.players) == "table" then
		partySize = #payload.players
	end
	partySize = math.clamp(math.floor(tonumber(partySize) or 1), 1, 4)

	local averagePlayerLevel = tonumber(payload and (payload.averagePlayerLevel or payload.avgPlayerLevel or payload.playerLevel)) or 1
	averagePlayerLevel = math.max(1, averagePlayerLevel)
	local partyWeights = config and config.ClassicPartySizeWeights or {}
	local partyWeight = tonumber(partyWeights[partySize]) or 0
	local score = (averagePlayerLevel / 18) + partyWeight

	for _, band in ipairs(config and config.ClassicAutoBalanceBands or {}) do
		local maxScore = tonumber(band.MaxScore) or 0
		if score <= maxScore then
			return ModeSelectionConfig.NormalizeDifficulty(config, band.Difficulty)
		end
	end

	return (config and config.DefaultClassicDifficulty) or "Mudah"
end

function ModeSelectionConfig.AllowDifficultySelection(config, modeName)
	local mode = ModeSelectionConfig.NormalizeMode(config, modeName)
	local modeDefinition = config and config.ModeDefinitions and config.ModeDefinitions[mode] or nil
	return modeDefinition and modeDefinition.AllowDifficultySelection == true or false
end

function ModeSelectionConfig.ResolveDisplayedDifficulty(config, modeName, difficultyName)
	if type(config) == "table" and type(config.ResolveDisplayedDifficulty) == "function" then
		return config.ResolveDisplayedDifficulty(modeName, difficultyName)
	end

	local mode = ModeSelectionConfig.NormalizeMode(config, modeName)
	local modeDefinition = config and config.ModeDefinitions and config.ModeDefinitions[mode] or nil
	if modeDefinition and modeDefinition.AllowDifficultySelection == false then
		return modeDefinition.PublicDifficultyLabel or "AUTO"
	end
	return ModeSelectionConfig.NormalizeDifficulty(config, difficultyName)
end

function ModeSelectionConfig.GetModeList(config)
	if type(config) == "table" and type(config.GetModeList) == "function" then
		return config.GetModeList()
	end
	local modes = {}
	for modeName in pairs(config and config.ModeDefinitions or {}) do
		table.insert(modes, modeName)
	end
	table.sort(modes)
	return modes
end

function ModeSelectionConfig.GetDifficultyList(config)
	if type(config) == "table" and type(config.GetDifficultyList) == "function" then
		return config.GetDifficultyList()
	end
	local difficulties = {}
	for difficultyName in pairs(config and config.ClassicDifficulties or {}) do
		table.insert(difficulties, difficultyName)
	end
	table.sort(difficulties)
	return difficulties
end

function ModeSelectionConfig.GetPublicDifficultyList(config, modeName)
	if type(config) == "table" and type(config.GetPublicDifficultyList) == "function" then
		return config.GetPublicDifficultyList(modeName)
	end

	if not ModeSelectionConfig.AllowDifficultySelection(config, modeName) then
		local mode = ModeSelectionConfig.NormalizeMode(config, modeName)
		local modeDefinition = config and config.ModeDefinitions and config.ModeDefinitions[mode] or nil
		return {
			modeDefinition and modeDefinition.PublicDifficultyLabel or "AUTO",
		}
	end

	return ModeSelectionConfig.GetDifficultyList(config)
end

return ModeSelectionConfig

