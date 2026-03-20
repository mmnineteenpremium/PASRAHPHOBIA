local ModeDifficultyConfig = {}

ModeDifficultyConfig.DefaultMode = "Classic"
ModeDifficultyConfig.DefaultClassicDifficulty = "Mudah"
ModeDifficultyConfig.DefaultRankedDifficulty = "Lumayan"

ModeDifficultyConfig.ModeDefinitions = {
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
		DifficultyMode = "Hard",
		RewardMultiplier = 1.7,
	},
}

ModeDifficultyConfig.RankedDifficultyBands = {
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
}

ModeDifficultyConfig.Aliases = {
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
}

return ModeDifficultyConfig
