local Generator = {}
Generator.__index = Generator

local DEFAULT_GHOST_POOL = {
	"Pocong",
	"Kuntilanak",
	"Genderuwo",
	"Tuyul",
	"Leak",
	"Banaspati",
	"Jerangkong",
	"WeweGombel",
	"Palasik",
	"SilumanUlar",
	"SundelBolong",
	"HantuTanah",
}

local DEFAULT_TOOL_POOL = { "camera", "thermometer", "spiritbox", "emf", "writingbook", "motionsensor" }

local OBJECTIVE_TEMPLATES = {
	{
		objectiveType = "IdentifyGhostType",
		description = "Identify ghost type",
		target = 1,
	},
	{
		objectiveType = "CollectEvidence",
		description = "Collect evidence",
		target = 2,
	},
	{
		objectiveType = "SurviveHunt",
		description = "Survive hunt",
		target = 1,
	},
	{
		objectiveType = "FindGhostRoom",
		description = "Find ghost room",
		target = 1,
	},
	{
		objectiveType = "UseSpecificTool",
		description = "Use specific tool",
		target = 1,
	},
}

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

local function loadModeDifficultyConfig()
	local loaded = safeRequire(resolveSharedGameDataModule("ModeDifficultyConfig"))
	if type(loaded) == "table" then
		return loaded
	end
	return nil
end

local function loadMapDatabase()
	local loaded = safeRequire(resolveSharedGameDataModule("MapConfig"))
	if type(loaded) == "table" then
		return loaded
	end
	return {}
end

local SHARED_MODE_CONFIG = loadModeDifficultyConfig()
local SHARED_MAP_DATABASE = loadMapDatabase()

local function buildDefaultMapPool()
	local ordered = {}
	for mapId, definition in pairs(SHARED_MAP_DATABASE) do
		if type(definition) == "table" and tostring(definition.mapCategory or "") ~= "Lobby" then
			table.insert(ordered, mapId)
		end
	end
	table.sort(ordered)
	if #ordered > 0 then
		return ordered
	end
	return {
		"HauntedHouse",
		"AbandonedPalace",
		"EmptyBuilding",
		"StudioMMNineteen",
	}
end

local function buildDefaultDifficultyPool()
	if type(SHARED_MODE_CONFIG) == "table" then
		if type(SHARED_MODE_CONFIG.GetDifficultyList) == "function" then
			local list = SHARED_MODE_CONFIG.GetDifficultyList()
			if type(list) == "table" and #list > 0 then
				return list
			end
		end

		local list = {}
		for difficultyName in pairs(SHARED_MODE_CONFIG.ClassicDifficulties or {}) do
			table.insert(list, difficultyName)
		end
		table.sort(list)
		if #list > 0 then
			return list
		end
	end

	return { "Mudah", "Lumayan", "Angker", "Uji Nyali" }
end

local DEFAULT_MAP_POOL = buildDefaultMapPool()
local DEFAULT_DIFFICULTY_POOL = buildDefaultDifficultyPool()

local function chooseRandom(list, rng)
	if type(list) ~= "table" or #list == 0 then
		return nil
	end
	return list[rng:NextInteger(1, #list)]
end

local function shallowCopy(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

local function resolvePool(candidate, fallback)
	if type(candidate) == "table" and #candidate > 0 then
		return candidate
	end
	return fallback
end

local function normalizeDifficultyName(difficulty)
	if type(SHARED_MODE_CONFIG) == "table" and type(SHARED_MODE_CONFIG.NormalizeDifficulty) == "function" then
		return SHARED_MODE_CONFIG.NormalizeDifficulty(difficulty)
	end
	if type(difficulty) == "string" and difficulty ~= "" then
		return difficulty
	end
	return "Lumayan"
end

local function resolveRewardProfile(difficulty)
	local canonicalDifficulty = normalizeDifficultyName(difficulty)
	local difficultyData = type(SHARED_MODE_CONFIG) == "table" and SHARED_MODE_CONFIG.ClassicDifficulties or nil
	local profile = type(difficultyData) == "table" and difficultyData[canonicalDifficulty] or nil
	return canonicalDifficulty, profile
end

function Generator.new(deps, config, rng)
	local self = setmetatable({}, Generator)
	self._deps = deps or {}
	self._config = config or {}
	self._rng = rng or Random.new()
	return self
end

function Generator:_mapPool(payload)
	return resolvePool((payload and payload.mapPool) or self._deps.MapPool or self._config.MapPool, DEFAULT_MAP_POOL)
end

function Generator:_ghostPool(payload)
	if type(self._deps.GhostTypes) == "table" then
		local list = {}
		for ghostType in pairs(self._deps.GhostTypes) do
			table.insert(list, ghostType)
		end
		table.sort(list)
		if #list > 0 then
			return list
		end
	end
	return resolvePool((payload and payload.ghostPool) or self._config.GhostPool, DEFAULT_GHOST_POOL)
end

function Generator:_difficultyPool(payload)
	return resolvePool((payload and payload.difficultyPool) or self._config.DifficultyPool, DEFAULT_DIFFICULTY_POOL)
end

function Generator:_generateObjectives()
	local selected = {}
	local used = {}

	while #selected < 3 do
		local template = chooseRandom(OBJECTIVE_TEMPLATES, self._rng)
		if template and not used[template.objectiveType] then
			used[template.objectiveType] = true
			local objective = shallowCopy(template)
			if objective.objectiveType == "UseSpecificTool" then
				objective.toolType = chooseRandom(DEFAULT_TOOL_POOL, self._rng)
				objective.description = string.format("Use specific tool (%s)", objective.toolType)
			end
			table.insert(selected, objective)
		end
	end

	return selected
end

function Generator:_buildReward(difficulty)
	local canonicalDifficulty, profile = resolveRewardProfile(difficulty)
	local rewardMultiplier = tonumber(profile and profile.RewardMultiplier) or 1.0
	local rankProgress = canonicalDifficulty == "Uji Nyali" and 1 or 0

	return {
		currency = "MM",
		amount = math.max(250, math.floor(450 * rewardMultiplier)),
		experience = math.max(40, math.floor(60 * rewardMultiplier)),
		rankProgress = rankProgress,
		cosmeticDropChance = math.min(0.12, 0.03 + math.max(rewardMultiplier - 1.0, 0) * 0.08),
	}
end

function Generator:Generate(payload)
	local mapId = chooseRandom(self:_mapPool(payload), self._rng) or DEFAULT_MAP_POOL[1] or "HauntedHouse"
	local ghostType = chooseRandom(self:_ghostPool(payload), self._rng) or "UnknownGhost"
	local requestedDifficulty = chooseRandom(self:_difficultyPool(payload), self._rng)
		or (payload and payload.difficulty)
		or DEFAULT_DIFFICULTY_POOL[1]
	local difficulty = normalizeDifficultyName(requestedDifficulty)

	return {
		mapId = mapId,
		ghostType = ghostType,
		difficulty = difficulty,
		objectives = self:_generateObjectives(),
		reward = self:_buildReward(difficulty),
	}
end

return Generator
