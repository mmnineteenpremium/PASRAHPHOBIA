local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEPENDENCY_NAMES = {
    "MatchSystem",
    "GhostSystem",
    "InvestigationSystem",
    "EconomySystem",
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

local function normalizeGhostDefinition(raw, fallbackName)
    local definition = {}
    definition.ghostName = type(raw.ghostName) == "string" and raw.ghostName or fallbackName
    definition.evidenceTypes = normalizeStringList(raw.evidenceTypes)
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
    return self:_loadGhostModules()
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
