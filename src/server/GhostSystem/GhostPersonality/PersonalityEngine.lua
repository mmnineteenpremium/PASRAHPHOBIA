local PersonalityTypes = require(script.Parent.PersonalityTypes)
local PersonalityTraits = require(script.Parent.PersonalityTraits)

local PersonalityEngine = {}
PersonalityEngine.__index = PersonalityEngine

local BASE_PROFILE = {
    type = "Default",
    traits = {},
    huntFrequency = 1.0,
    interactionRate = 1.0,
    favoriteRoomBias = 1.0,
    evidenceSpawnProbability = 1.0,
    manifestChanceScale = 1.0,
    roamBias = 1.0,
    aggressionGainScale = 1.0,
    retreatDurationScale = 1.0,
    deceptionChance = 0.08,
    deceptionCooldown = 12,
    fakeEvidenceChance = 0.0,
    huntStrategyWeights = {
        nearest_player = 1.0,
        lowest_sanity_player = 1.0,
        isolated_player = 1.0,
        random_target = 1.0,
    },
    roomStrategyWeights = {
        stay = 1.0,
        roam = 1.0,
        change_favorite = 1.0,
    },
    investigationReactionWeights = {
        hide_evidence = 1.0,
        fake_evidence = 1.0,
        move_room = 1.0,
        increase_aggression = 1.0,
    },
    deceptionWeights = {
        fake_evidence = 1.0,
        fake_ghost_sound = 1.0,
        fake_footsteps = 1.0,
        fake_manifestation = 1.0,
    },
    evidenceBias = {},
}

local MULTIPLIER_KEYS = {
    huntFrequency = true,
    interactionRate = true,
    favoriteRoomBias = true,
    evidenceSpawnProbability = true,
    manifestChanceScale = true,
    roamBias = true,
    aggressionGainScale = true,
    retreatDurationScale = true,
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = deepCopy(v)
    end
    return out
end

local function mergeInto(target, patch)
    for key, value in pairs(patch or {}) do
        if key == "traits" then
            -- handled separately
        elseif type(value) == "table" and type(target[key]) == "table" then
            for nestedKey, nestedValue in pairs(value) do
                target[key][nestedKey] = nestedValue
            end
        elseif MULTIPLIER_KEYS[key] then
            target[key] = (target[key] or 1.0) * value
        else
            target[key] = value
        end
    end
end

local function mergeWeights(target, patch)
    for key, value in pairs(patch or {}) do
        target[key] = (target[key] or 1.0) * value
    end
end

local function mergeTrait(profile, traitName, traitData)
    if not traitData then
        return
    end
    table.insert(profile.traits, traitName)

    for key, value in pairs(traitData) do
        if key == "huntStrategyWeights" then
            mergeWeights(profile.huntStrategyWeights, value)
        elseif key == "roomStrategyWeights" then
            mergeWeights(profile.roomStrategyWeights, value)
        elseif key == "investigationReactionWeights" then
            mergeWeights(profile.investigationReactionWeights, value)
        elseif key == "deceptionWeights" then
            mergeWeights(profile.deceptionWeights, value)
        elseif key == "evidenceBias" then
            mergeWeights(profile.evidenceBias, value)
        elseif MULTIPLIER_KEYS[key] then
            profile[key] = (profile[key] or 1.0) * value
        elseif key == "deceptionChance" then
            profile[key] = math.max(profile[key] or 0, value)
        elseif key == "deceptionCooldown" then
            profile[key] = math.min(profile[key] or value, value)
        elseif key == "fakeEvidenceChance" then
            profile[key] = math.max(profile[key] or 0, value)
        else
            profile[key] = value
        end
    end
end

local function pickWeighted(list, rng)
    local total = 0
    for _, entry in ipairs(list) do
        total += math.max(0, entry.weight or 0)
    end
    if total <= 0 then
        return list[1]
    end

    local roll = rng:NextNumber() * total
    local cursor = 0
    for _, entry in ipairs(list) do
        cursor += math.max(0, entry.weight or 0)
        if roll <= cursor then
            return entry
        end
    end
    return list[#list]
end

function PersonalityEngine.new(config, rng)
    local self = setmetatable({}, PersonalityEngine)
    self._config = config or {}
    self._rng = rng or Random.new()
    self._types = self._config.PersonalityTypes or PersonalityTypes
    self._traits = self._config.PersonalityTraits or PersonalityTraits
    return self
end

function PersonalityEngine:_composeFromTraits(personalityType, traits)
    local profile = deepCopy(BASE_PROFILE)
    profile.type = personalityType or "Default"
    profile.traits = {}
    for _, traitName in ipairs(traits or {}) do
        mergeTrait(profile, traitName, self._traits[traitName])
    end
    return profile
end

function PersonalityEngine:_randomType()
    local picked = pickWeighted(self._types, self._rng)
    return picked and picked.name or "Default", picked and picked.baseTraits or {}
end

function PersonalityEngine:_traitsForType(typeName)
    for _, entry in ipairs(self._types or {}) do
        if entry.name == typeName then
            return deepCopy(entry.baseTraits or {})
        end
    end
    return {}
end

function PersonalityEngine:Resolve(ghostType, payload)
    local explicit = payload and payload.personality
    if type(explicit) == "table" then
        local profile = deepCopy(BASE_PROFILE)
        mergeInto(profile, explicit)
        profile.type = explicit.type or "Custom"
        profile.traits = explicit.traits or {}
        return profile
    end

    local typeName = payload and payload.personalityType
    local selectedTraits = nil

    if type(typeName) ~= "string" and type(ghostType) == "table" then
        typeName = ghostType.personalityType or ghostType.personality
    end
    if type(ghostType) == "table" and type(ghostType.personalityTraits) == "table" then
        selectedTraits = deepCopy(ghostType.personalityTraits)
    end

    if type(typeName) ~= "string" then
        typeName, selectedTraits = self:_randomType()
    elseif type(selectedTraits) ~= "table" then
        selectedTraits = self:_traitsForType(typeName)
    end
    selectedTraits = selectedTraits or {}
    -- Add one extra random trait to create mixed personalities.
    if #selectedTraits < 3 then
        local traitNames = {}
        for traitName in pairs(self._traits) do
            table.insert(traitNames, traitName)
        end
        if #traitNames > 0 then
            local extra = traitNames[self._rng:NextInteger(1, #traitNames)]
            local exists = false
            for _, trait in ipairs(selectedTraits) do
                if trait == extra then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(selectedTraits, extra)
            end
        end
    end

    if type(payload) == "table" and type(payload.personalityTraits) == "table" then
        selectedTraits = deepCopy(payload.personalityTraits)
    end

    local hasTrickster = false
    for _, trait in ipairs(selectedTraits) do
        if trait == "Trickster" then
            hasTrickster = true
            break
        end
    end

    local profile = self:_composeFromTraits(typeName, selectedTraits)
    if type(ghostType) == "table" and type(ghostType.personalityOverrides) == "table" then
        mergeInto(profile, ghostType.personalityOverrides)
    end

    -- Ensure trickster profile has fake evidence behavior.
    if hasTrickster or typeName == "Trickster" then
        profile.fakeEvidenceChance = math.max(profile.fakeEvidenceChance or 0, 0.35)
    end

    return profile
end

return PersonalityEngine
