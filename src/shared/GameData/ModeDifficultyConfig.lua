local ModeDifficultyConfig = {}

ModeDifficultyConfig.DefaultMode = "Classic"
ModeDifficultyConfig.DefaultClassicDifficulty = "Mudah"
ModeDifficultyConfig.DefaultRankedDifficulty = "Lumayan"

ModeDifficultyConfig.ModeDefinitions = {
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
}

ModeDifficultyConfig.ClassicDifficulties = {
	Mudah = {
		Name = "Mudah",
		EvidenceCount = 4,
		GhostAggression = 0.85,
		HuntFrequency = 0.8,
		EvidenceClarity = 1.2,
		SanityDrain = 0.8,
		DifficultyMode = "Easy",
		RewardMultiplier = 1.0,
	},
	Lumayan = {
		Name = "Lumayan",
		EvidenceCount = 3,
		GhostAggression = 1.0,
		HuntFrequency = 1.0,
		EvidenceClarity = 1.0,
		SanityDrain = 1.0,
		DifficultyMode = "Normal",
		RewardMultiplier = 1.2,
	},
	Angker = {
		Name = "Angker",
		EvidenceCount = 3,
		GhostAggression = 1.4,
		HuntFrequency = 1.3,
		EvidenceClarity = 0.8,
		SanityDrain = 1.2,
		DifficultyMode = "Hard",
		RewardMultiplier = 1.45,
	},
	["Uji Nyali"] = {
		Name = "Uji Nyali",
		EvidenceCount = 2,
		GhostAggression = 1.65,
		HuntFrequency = 1.5,
		EvidenceClarity = 0.65,
		SanityDrain = 1.4,
		DifficultyMode = "Nightmare",
		RewardMultiplier = 1.7,
	},
}

ModeDifficultyConfig.RankedDifficultyBands = {
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
}

ModeDifficultyConfig.ClassicPartySizeWeights = {
	[1] = 0.0,
	[2] = 0.35,
	[3] = 0.7,
	[4] = 1.0,
}

ModeDifficultyConfig.ClassicAutoBalanceBands = {
	{
		MaxScore = 1.35,
		Difficulty = "Mudah",
	},
	{
		MaxScore = 2.35,
		Difficulty = "Lumayan",
	},
	{
		MaxScore = 3.3,
		Difficulty = "Angker",
	},
	{
		MaxScore = 999999,
		Difficulty = "Uji Nyali",
	},
}

ModeDifficultyConfig.Aliases = {
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
}

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

function ModeDifficultyConfig.CloneConfig()
	return deepCopy(ModeDifficultyConfig)
end

function ModeDifficultyConfig.NormalizeToken(value)
	return normalizeToken(value)
end

function ModeDifficultyConfig.NormalizeMode(modeName)
	local modeDefinitions = ModeDifficultyConfig.ModeDefinitions or {}
	if type(modeName) == "string" and modeDefinitions[modeName] then
		return modeName
	end

	local aliases = ModeDifficultyConfig.Aliases or {}
	local aliased = aliases[normalizeToken(modeName or "")]
	if type(aliased) == "string" and modeDefinitions[aliased] then
		return aliased
	end

	return ModeDifficultyConfig.DefaultMode or "Classic"
end

function ModeDifficultyConfig.NormalizeDifficulty(difficultyName)
	local difficulties = ModeDifficultyConfig.ClassicDifficulties or {}
	if type(difficultyName) == "string" and difficulties[difficultyName] then
		return difficultyName
	end

	local aliases = ModeDifficultyConfig.Aliases or {}
	local aliased = aliases[normalizeToken(difficultyName or "")]
	if type(aliased) == "string" and difficulties[aliased] then
		return aliased
	end

	return ModeDifficultyConfig.DefaultClassicDifficulty or "Mudah"
end

function ModeDifficultyConfig.ResolveRankedDifficulty(payload)
	local manual = payload and (payload.balancedDifficulty or payload.rankedDifficulty)
	if type(manual) == "string" then
		return ModeDifficultyConfig.NormalizeDifficulty(manual)
	end

	local averageRankScore = tonumber(payload and (payload.averageRankScore or payload.rankScore or payload.rating or payload.rankedScore))
	if averageRankScore then
		for _, band in ipairs(ModeDifficultyConfig.RankedDifficultyBands or {}) do
			local minRankScore = tonumber(band.MinRankScore) or 0
			local maxRankScore = tonumber(band.MaxRankScore) or minRankScore
			if averageRankScore >= minRankScore and averageRankScore <= maxRankScore then
				return ModeDifficultyConfig.NormalizeDifficulty(band.Difficulty)
			end
		end
	end

	return ModeDifficultyConfig.DefaultRankedDifficulty or "Lumayan"
end

function ModeDifficultyConfig.ResolveClassicDifficulty(payload)
	if payload and payload.forceClassicDifficulty == true then
		local requested = payload.classicDifficulty or payload.balancedDifficulty or payload.difficulty
		if type(requested) == "string" and requested ~= "" then
			return ModeDifficultyConfig.NormalizeDifficulty(requested)
		end
	end

	local partySize = tonumber(payload and (payload.partySize or payload.playerCount))
	if partySize == nil and type(payload and payload.players) == "table" then
		partySize = #payload.players
	end
	partySize = math.clamp(math.floor(tonumber(partySize) or 1), 1, 4)

	local averagePlayerLevel = tonumber(payload and (payload.averagePlayerLevel or payload.avgPlayerLevel or payload.playerLevel)) or 1
	averagePlayerLevel = math.max(1, averagePlayerLevel)

	local levelScore = averagePlayerLevel / 18
	local partySizeWeight = (ModeDifficultyConfig.ClassicPartySizeWeights or {})[partySize] or 0
	local balanceScore = levelScore + partySizeWeight

	for _, band in ipairs(ModeDifficultyConfig.ClassicAutoBalanceBands or {}) do
		if balanceScore <= (tonumber(band.MaxScore) or 0) then
			return ModeDifficultyConfig.NormalizeDifficulty(band.Difficulty)
		end
	end

	return ModeDifficultyConfig.DefaultClassicDifficulty or "Mudah"
end

function ModeDifficultyConfig.ResolveDisplayedDifficulty(modeName, difficultyName)
	local mode = ModeDifficultyConfig.NormalizeMode(modeName)
	local modeDefinition = (ModeDifficultyConfig.ModeDefinitions or {})[mode] or {}
	if modeDefinition.AllowDifficultySelection == false then
		return modeDefinition.PublicDifficultyLabel or "AUTO"
	end
	return ModeDifficultyConfig.NormalizeDifficulty(difficultyName)
end

function ModeDifficultyConfig.GetModeList()
	local modes = {}
	for modeName in pairs(ModeDifficultyConfig.ModeDefinitions or {}) do
		table.insert(modes, modeName)
	end
	table.sort(modes)
	return modes
end

function ModeDifficultyConfig.GetDifficultyList()
	local difficulties = {}
	for difficultyName in pairs(ModeDifficultyConfig.ClassicDifficulties or {}) do
		table.insert(difficulties, difficultyName)
	end
	table.sort(difficulties)
	return difficulties
end

function ModeDifficultyConfig.GetPublicDifficultyList(modeName)
	local mode = ModeDifficultyConfig.NormalizeMode(modeName)
	local modeDefinition = (ModeDifficultyConfig.ModeDefinitions or {})[mode] or {}
	if modeDefinition.AllowDifficultySelection == false then
		return {
			modeDefinition.PublicDifficultyLabel or "AUTO",
		}
	end
	return ModeDifficultyConfig.GetDifficultyList()
end

return ModeDifficultyConfig
