local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEPENDENCY_NAMES = {
    "MatchSystem",
    "GhostSystem",
    "InvestigationSystem",
    "EconomySystem",
    "GhostDatabaseSystem",
}

local EVIDENCE_ALIASES = {
    medok = "MEDOK",
    jejakenergi = "MEDOK",
    suhu = "Suhu",
    suhumembeku = "Suhu",
    bukuterkutuk = "BukuTerkutuk",
    toun = "To'un",
    bolaarwah = "To'un",
    ["to'un"] = "To'un",
    suara = "Suara",
    kotakarwah = "Suara",
    pengganggu = "Pengganggu",
    gerakangaib = "Pengganggu",
    motionsensor = "Pengganggu",
}

local DISPLAY_NAMES = {
    MEDOK = "MEDOK",
    Suhu = "Suhu",
    BukuTerkutuk = "Buku Terkutuk",
    ["To'un"] = "To'un",
    Suara = "Suara",
    Pengganggu = "Pengganggu",
}

local SUPPORTED_EVIDENCE = {
    MEDOK = true,
    Suhu = true,
    BukuTerkutuk = true,
    ["To'un"] = true,
    Suara = true,
    Pengganggu = true,
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

local function resolveGameDataModule(moduleName)
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

local function resolveEvidenceCombinationFolder()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local configFolder = replicatedStorage:FindFirstChild("Config")
    if not configFolder then
        return nil
    end
    return configFolder:FindFirstChild("EvidenceCombinations")
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

local function normalizeEvidenceType(value)
    if type(value) ~= "string" then
        return nil
    end
    local token = value:gsub("[%s_%-]+", ""):gsub("[^%w]", ""):lower()
    local canonical = EVIDENCE_ALIASES[token] or value
    if not SUPPORTED_EVIDENCE[canonical] then
        return nil
    end
    return canonical
end

local function normalizeEvidenceList(list)
    local out = {}
    local seen = {}
    for _, evidenceType in ipairs(list or {}) do
        local canonical = normalizeEvidenceType(evidenceType)
        if canonical and not seen[canonical] then
            seen[canonical] = true
            table.insert(out, canonical)
        end
    end
    table.sort(out)
    return out
end

local function getStringValue(parent, childName)
    local node = parent and parent:FindFirstChild(childName)
    if node and node:IsA("StringValue") then
        return node.Value
    end
    return nil
end

local function parseEvidenceValues(folder)
    if not folder or not folder:IsA("Folder") then
        return {}
    end
    local list = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("StringValue") then
            table.insert(list, child.Value)
        end
    end
    return normalizeEvidenceList(list)
end

local function buildDefaultEvidenceDefinitions()
    local definitions = {}
    for evidenceType in pairs(SUPPORTED_EVIDENCE) do
        definitions[evidenceType] = {
            evidenceName = DISPLAY_NAMES[evidenceType] or evidenceType,
            evidenceType = evidenceType,
            description = string.format("Evidence marker for %s.", DISPLAY_NAMES[evidenceType] or evidenceType),
        }
    end
    return definitions
end

local function normalizeGhostKey(ghostName)
    if type(ghostName) ~= "string" then
        return nil
    end
    return ghostName:gsub("[%s_%-]+", ""):lower()
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
        warn(string.format("[EvidenceConfigSystem] Failed loading evidence configs: %s", tostring(err)))
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

function Service:_loadFromReplicatedConfig()
    local folder = resolveEvidenceCombinationFolder()
    if not folder then
        return false, "missing_evidence_combinations_folder"
    end

    local combinations = {}
    local keyLookup = {}

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Folder") then
            local ghostName = getStringValue(child, "GhostName") or child.Name
            local evidenceFolder = child:FindFirstChild("EvidenceTypes") or child:FindFirstChild("EvidenceList")
            local evidenceList = parseEvidenceValues(evidenceFolder)
            if #evidenceList == 0 then
                return false, "ghost_missing_evidence_combination:" .. child.Name
            end

            combinations[ghostName] = evidenceList
            local normalizedKey = normalizeGhostKey(ghostName)
            if normalizedKey then
                keyLookup[normalizedKey] = ghostName
            end
        end
    end

    if next(combinations) == nil then
        return false, "empty_evidence_combinations"
    end

    return true, {
        evidenceDefinitions = buildDefaultEvidenceDefinitions(),
        evidenceCombinations = combinations,
        evidenceCombinationLookup = keyLookup,
        source = "ReplicatedStorage.Config.EvidenceCombinations",
    }
end

function Service:_loadFromLegacyModule()
    local moduleScript = resolveGameDataModule("EvidenceConfig")
    local evidenceData = safeRequire(moduleScript)
    if type(evidenceData) ~= "table" then
        return false, "invalid_evidence_config"
    end

    local ghostDatabaseSystem = self._dependencies.GhostDatabaseSystem
    local combinations = {}
    local keyLookup = {}
    if type(ghostDatabaseSystem) == "table" and type(ghostDatabaseSystem.GetGhostDatabase) == "function" then
        local ghostDatabase = ghostDatabaseSystem:GetGhostDatabase() or {}
        for ghostKey, definition in pairs(ghostDatabase) do
            if type(definition) == "table" then
                local ghostName = definition.ghostName or ghostKey
                local evidenceList = normalizeEvidenceList(definition.evidenceTypes or {})
                if #evidenceList > 0 then
                    combinations[ghostName] = evidenceList
                    local normalizedKey = normalizeGhostKey(ghostName)
                    if normalizedKey then
                        keyLookup[normalizedKey] = ghostName
                    end
                end
            end
        end
    end

    return true, {
        evidenceDefinitions = evidenceData,
        evidenceCombinations = combinations,
        evidenceCombinationLookup = keyLookup,
        source = "Shared.GameData.EvidenceConfig",
    }
end

function Service:Reload()
    local loaded, result = self:_loadFromLegacyModule()
    if not loaded then
        loaded, result = self:_loadFromReplicatedConfig()
    end
    if not loaded then
        return false, result
    end

    local version = (self._state:Get("version") or 0) + 1
    self._state:Set("evidenceDefinitions", deepCopy(result.evidenceDefinitions or {}))
    self._state:Set("evidenceCombinations", deepCopy(result.evidenceCombinations or {}))
    self._state:Set("evidenceCombinationLookup", deepCopy(result.evidenceCombinationLookup or {}))
    self._state:Set("source", result.source or "unknown")
    self._state:Set("loaded", true)
    self._state:Set("version", version)

    self:_publish("EvidenceConfigLoaded", {
        version = version,
        evidenceCount = self:GetEvidenceCount(),
        combinationGhostCount = self:GetEvidenceCombinationCount(),
        source = self._state:Get("source"),
    })

    return true, self._state:Get("evidenceDefinitions")
end

function Service:GetEvidenceDefinitions()
    return deepCopy(self._state:Get("evidenceDefinitions") or {})
end

function Service:GetEvidenceDefinition(evidenceId)
    local definition = (self._state:Get("evidenceDefinitions") or {})[evidenceId]
    if type(definition) ~= "table" then
        return nil
    end
    return deepCopy(definition)
end

function Service:GetEvidenceIds()
    local ids = {}
    for evidenceId in pairs(self._state:Get("evidenceDefinitions") or {}) do
        table.insert(ids, evidenceId)
    end
    table.sort(ids)
    return ids
end

function Service:GetEvidenceCount()
    local count = 0
    for _ in pairs(self._state:Get("evidenceDefinitions") or {}) do
        count += 1
    end
    return count
end

function Service:GetEvidenceCombinations()
    return deepCopy(self._state:Get("evidenceCombinations") or {})
end

function Service:GetEvidenceCombinationForGhost(ghostType)
    if type(ghostType) ~= "string" then
        return nil
    end

    local combinations = self._state:Get("evidenceCombinations") or {}
    if type(combinations[ghostType]) == "table" then
        return deepCopy(combinations[ghostType])
    end

    local lookup = self._state:Get("evidenceCombinationLookup") or {}
    local normalized = normalizeGhostKey(ghostType)
    local resolvedGhostName = normalized and lookup[normalized] or nil
    if resolvedGhostName and type(combinations[resolvedGhostName]) == "table" then
        return deepCopy(combinations[resolvedGhostName])
    end

    return nil
end

function Service:GetEvidenceCombinationCount()
    local count = 0
    for _ in pairs(self._state:Get("evidenceCombinations") or {}) do
        count += 1
    end
    return count
end

return Service
