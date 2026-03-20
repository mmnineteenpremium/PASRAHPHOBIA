local Generator = {}
Generator.__index = Generator

local DEFAULT_MAP_POOL = {
    "AbandonedPalace",
    "HospitalWing",
    "OldDormitory",
    "ForgottenTemple",
}

local DEFAULT_GHOST_POOL = {
    "Pocong",
    "Kuntilanak",
    "Tuyul",
    "Genderuwo",
    "Wewe Gombel",
}

local DEFAULT_DIFFICULTY_POOL = { "Easy", "Normal", "Hard" }
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
    local reward = {
        currency = "MM",
        amount = 600,
        experience = 80,
        rankProgress = 0,
        cosmeticDropChance = 0.05,
    }

    if difficulty == "Easy" then
        reward.amount = 450
        reward.experience = 60
        reward.cosmeticDropChance = 0.03
    elseif difficulty == "Hard" then
        reward.amount = 900
        reward.experience = 130
        reward.rankProgress = 1
        reward.cosmeticDropChance = 0.1
    end

    return reward
end

function Generator:Generate(payload)
    local mapId = chooseRandom(self:_mapPool(payload), self._rng) or "AbandonedPalace"
    local ghostType = chooseRandom(self:_ghostPool(payload), self._rng) or "UnknownGhost"
    local difficulty = chooseRandom(self:_difficultyPool(payload), self._rng) or "Normal"

    return {
        mapId = mapId,
        ghostType = ghostType,
        difficulty = difficulty,
        objectives = self:_generateObjectives(),
        reward = self:_buildReward(difficulty),
    }
end

return Generator
