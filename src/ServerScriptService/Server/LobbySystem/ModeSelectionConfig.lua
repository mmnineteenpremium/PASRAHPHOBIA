local DEFAULT_CONFIG = {
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
		local merged = deepCopy(DEFAULT_CONFIG)
		for key, value in pairs(loaded) do
			merged[key] = value
		end
		return merged
	end
	return deepCopy(DEFAULT_CONFIG)
end

function ModeSelectionConfig.NormalizeMode(config, modeName)
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
	local manual = payload and (payload.balancedDifficulty or payload.rankedDifficulty)
	if type(manual) == "string" then
		return ModeSelectionConfig.NormalizeDifficulty(config, manual)
	end

	local averageMMR = tonumber(payload and (payload.averageMMR or payload.mmr or payload.rating or payload.rankedMMR))
	if averageMMR then
		for _, band in ipairs(config and config.RankedDifficultyBands or {}) do
			local minMMR = tonumber(band.MinMMR) or 0
			local maxMMR = tonumber(band.MaxMMR) or minMMR
			if averageMMR >= minMMR and averageMMR <= maxMMR then
				return ModeSelectionConfig.NormalizeDifficulty(config, band.Difficulty)
			end
		end
	end

	return (config and config.DefaultRankedDifficulty) or "Lumayan"
end

function ModeSelectionConfig.GetModeList(config)
	local modes = {}
	for modeName in pairs(config and config.ModeDefinitions or {}) do
		table.insert(modes, modeName)
	end
	table.sort(modes)
	return modes
end

function ModeSelectionConfig.GetDifficultyList(config)
	local difficulties = {}
	for difficultyName in pairs(config and config.ClassicDifficulties or {}) do
		table.insert(difficulties, difficultyName)
	end
	table.sort(difficulties)
	return difficulties
end

return ModeSelectionConfig
