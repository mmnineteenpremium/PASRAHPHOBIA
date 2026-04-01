local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local REQUIRED_GHOST_TYPE_COUNT = 12

local DEPENDENCY_NAMES = {
    "MatchSystem",
    "GhostSystem",
    "InvestigationSystem",
    "EconomySystem",
}

local AGGRESSION_RANGES = {
    low = { min = 30, max = 60, interaction = 0.38, roaming = 0.52 },
    normal = { min = 45, max = 75, interaction = 0.5, roaming = 0.4 },
    high = { min = 60, max = 95, interaction = 0.62, roaming = 0.3 },
    extreme = { min = 75, max = 100, interaction = 0.7, roaming = 0.22 },
}

local EVIDENCE_ALIASES = {
    medok = "MEDOK",
    jejakenergi = "MEDOK",
    suhu = "Suhu",
    suhumembeku = "Suhu",
    bukuterkutuk = "BukuTerkutuk",
    toun = "To'un",
    ["to'un"] = "To'un",
    bolaarwah = "To'un",
    suara = "Suara",
    kotakarwah = "Suara",
    pengganggu = "Pengganggu",
    gerakangaib = "Pengganggu",
    motionsensor = "Pengganggu",
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

local function clamp01(value)
    local numeric = tonumber(value) or 0
    if numeric < 0 then
        return 0
    end
    if numeric > 1 then
        return 1
    end
    return numeric
end

local function normalizeStringList(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    for _, entry in ipairs(source) do
        if type(entry) == "string" and entry ~= "" then
            table.insert(out, entry)
        end
    end
    return out
end

local function normalizeEvidenceType(value)
    if type(value) ~= "string" then
        return nil
    end
    local token = value:gsub("[%s_%-]+", ""):gsub("[^%w]", ""):lower()
    return EVIDENCE_ALIASES[token] or value
end

local function normalizeEvidenceList(source)
    local out = {}
    local seen = {}
    if type(source) ~= "table" then
        return out
    end
    for _, entry in ipairs(source) do
        local normalized = normalizeEvidenceType(entry)
        if type(normalized) == "string" and normalized ~= "" and not seen[normalized] then
            seen[normalized] = true
            table.insert(out, normalized)
        end
    end
    return out
end

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
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

local function resolveGhostTypesConfigFolder()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local configFolder = replicatedStorage:FindFirstChild("Config")
    if not configFolder then
        return nil
    end
    return configFolder:FindFirstChild("GhostTypes")
end

local function resolveGhostsFolder()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
    if not shared then
        return nil
    end
    local gameDataFolder = shared:FindFirstChild("GameData")
    if not gameDataFolder then
        return nil
    end
    return gameDataFolder:FindFirstChild("Ghosts")
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

local function buildEvidenceSignature(evidenceList)
    local normalized = {}
    for _, entry in ipairs(evidenceList) do
        if type(entry) == "string" and entry ~= "" then
            table.insert(normalized, entry)
        end
    end
    table.sort(normalized)
    return table.concat(normalized, "|")
end

local function getStringValue(parent, childName)
    local child = parent and parent:FindFirstChild(childName)
    if child and child:IsA("StringValue") then
        return child.Value
    end
    return nil
end

local function getNumberValue(parent, childName)
    local child = parent and parent:FindFirstChild(childName)
    if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then
        return tonumber(child.Value)
    end
    return nil
end

local function parseEvidenceValues(folder)
    if not folder or not folder:IsA("Folder") then
        return {}
    end

    local evidence = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("StringValue") then
            table.insert(evidence, child.Value)
        end
    end
    table.sort(evidence)
    return normalizeEvidenceList(evidence)
end

local function normalizeAggressionLevel(level)
    if type(level) ~= "string" then
        return "Normal", AGGRESSION_RANGES.normal
    end

    local lowered = level:lower()
    local profile = AGGRESSION_RANGES[lowered]
    if not profile then
        return "Normal", AGGRESSION_RANGES.normal
    end

    if lowered == "low" then
        return "Low", profile
    end
    if lowered == "high" then
        return "High", profile
    end
    if lowered == "extreme" then
        return "Extreme", profile
    end

    return "Normal", profile
end

local function normalizeGhostDefinition(raw, fallbackName)
    local definition = {}
    definition.ghostName = type(raw.ghostName) == "string" and raw.ghostName or fallbackName
    definition.evidenceTypes = normalizeEvidenceList(raw.evidenceTypes)
    definition.behaviorTraits = normalizeStringList(raw.behaviorTraits)

    local aggression = raw.aggressionRange
    local minRange, maxRange = 0, 100
    if type(aggression) == "table" then
        minRange = tonumber(aggression.min) or minRange
        maxRange = tonumber(aggression.max) or maxRange
    end

    definition.aggressionRange = {
        min = math.max(0, math.min(100, minRange)),
        max = math.max(0, math.min(100, maxRange)),
    }
    definition.huntBehavior = type(raw.huntBehavior) == "string" and raw.huntBehavior or "Unknown"
    definition.manifestBehavior = type(raw.manifestBehavior) == "string" and raw.manifestBehavior or "Unknown"
    definition.speedModifier = tonumber(raw.speedModifier) or 1
    definition.aggressionLevel = type(raw.aggressionLevel) == "string" and raw.aggressionLevel or "Normal"
    definition.interactionFrequency = clamp01(raw.interactionFrequency)
    definition.roamingBehavior = clamp01(raw.roamingBehavior)
    return definition
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    for _, dependencyName in ipairs(DEPENDENCY_NAMES) do
        self._dependencies[dependencyName] = Services.Get(self._deps, dependencyName)
    end
    local ok, err = self:Reload()
    if not ok then
        warn(string.format("[GhostDatabaseSystem] Failed loading database: %s", tostring(err)))
    end
end

function Service:Start()
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_loadGhostConfigFolder()
    local folder = resolveGhostTypesConfigFolder()
    if not folder then
        return false, "missing_ghost_config_folder"
    end

    local ghostDatabase = {}
    local seenSignatures = {}
    local ghostCount = 0

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Folder") then
            local ghostKey = child.Name
            local ghostName = getStringValue(child, "GhostName") or ghostKey
            local evidenceFolder = child:FindFirstChild("EvidenceTypes") or child:FindFirstChild("EvidenceList")
            local evidenceTypes = parseEvidenceValues(evidenceFolder)

            if #evidenceTypes == 0 then
                return false, "ghost_missing_evidence:" .. ghostKey
            end

            local signature = buildEvidenceSignature(evidenceTypes)
            if seenSignatures[signature] then
                return false, "duplicate_evidence:" .. ghostKey
            end
            seenSignatures[signature] = true

            local aggressionLevel, aggressionProfile = normalizeAggressionLevel(getStringValue(child, "AggressionLevel"))

            ghostDatabase[ghostKey] = {
                ghostName = ghostName,
                evidenceTypes = evidenceTypes,
                behaviorTraits = {},
                aggressionRange = {
                    min = aggressionProfile.min,
                    max = aggressionProfile.max,
                },
                huntBehavior = getStringValue(child, "HuntBehavior") or "Unknown",
                manifestBehavior = getStringValue(child, "ManifestBehavior") or "Unknown",
                speedModifier = getNumberValue(child, "SpeedModifier") or 1,
                aggressionLevel = aggressionLevel,
                interactionFrequency = aggressionProfile.interaction,
                roamingBehavior = aggressionProfile.roaming,
            }

            ghostCount += 1
        end
    end

    if ghostCount ~= REQUIRED_GHOST_TYPE_COUNT then
        return false, string.format("invalid_ghost_type_count:%d", ghostCount)
    end

    return true, ghostDatabase
end

function Service:_loadGhostModules()
    local folder = resolveGhostsFolder()
    if not folder then
        return false, "missing_ghost_folder"
    end

    local ghostDatabase = {}
    local seenSignatures = {}

    for _, moduleScript in ipairs(folder:GetChildren()) do
        if moduleScript:IsA("ModuleScript") then
            local rawDefinition = safeRequire(moduleScript)
            if type(rawDefinition) == "table" then
                local ghostKey = moduleScript.Name
                local normalized = normalizeGhostDefinition(rawDefinition, ghostKey)
                local signature = buildEvidenceSignature(normalized.evidenceTypes)
                if signature == "" then
                    return false, "ghost_missing_evidence:" .. ghostKey
                end
                if seenSignatures[signature] then
                    return false, "duplicate_evidence:" .. ghostKey
                end
                seenSignatures[signature] = true
                ghostDatabase[ghostKey] = normalized
            end
        end
    end

    return true, ghostDatabase
end

function Service:LoadGhosts()
    local loadedFromModules, moduleResult = self:_loadGhostModules()
    if loadedFromModules then
        return true, moduleResult
    end
    local configFolder = resolveGhostTypesConfigFolder()
    if configFolder then
        return self:_loadGhostConfigFolder()
    end
    return loadedFromModules, moduleResult
end

function Service:Reload()
    local ok, ghostDataOrErr = self:LoadGhosts()
    if not ok then
        return false, ghostDataOrErr
    end

    local version = (self._state:Get("version") or 0) + 1
    self._state:Set("ghostDatabase", deepCopy(ghostDataOrErr))
    self._state:Set("loaded", true)
    self._state:Set("version", version)

    self:_publish("GhostDatabaseLoaded", {
        version = version,
        ghostCount = self:GetGhostCount(),
    })

    return true, self._state:Get("ghostDatabase")
end

function Service:GetGhostDatabase()
    return deepCopy(self._state:Get("ghostDatabase") or {})
end

function Service:GetGhostDefinition(ghostId)
    local database = self._state:Get("ghostDatabase") or {}
    local definition = database[ghostId]
    if type(definition) ~= "table" then
        return nil
    end
    return deepCopy(definition)
end

function Service:GetGhostIds()
    local ids = {}
    for ghostId in pairs(self._state:Get("ghostDatabase") or {}) do
        table.insert(ids, ghostId)
    end
    table.sort(ids)
    return ids
end

function Service:GetGhostCount()
    local count = 0
    for _ in pairs(self._state:Get("ghostDatabase") or {}) do
        count += 1
    end
    return count
end

return Service
