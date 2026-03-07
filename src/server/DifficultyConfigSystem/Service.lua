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

local function resolveDifficultyModesFolder()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local configFolder = replicatedStorage:FindFirstChild("Config")
    if not configFolder then
        return nil
    end
    return configFolder:FindFirstChild("DifficultyModes")
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

local function getStringValue(parent, childName)
    local child = parent and parent:FindFirstChild(childName)
    if child and child:IsA("StringValue") then
        return child.Value
    end
    return nil
end

local function getNumberValue(parent, childName)
    local child = parent and parent:FindFirstChild(childName)
    if child and (child:IsA("IntValue") or child:IsA("NumberValue")) then
        return tonumber(child.Value)
    end
    return nil
end

local function normalizeName(name)
    if type(name) ~= "string" then
        return nil
    end
    return name:gsub("[%s_%-]+", ""):lower()
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
        warn(string.format("[DifficultyConfigSystem] Failed loading difficulty configs: %s", tostring(err)))
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
    local folder = resolveDifficultyModesFolder()
    if not folder then
        return false, "missing_difficulty_modes_folder"
    end

    local configs = {}
    local lookup = {}

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Folder") then
            local modeName = child.Name
            local evidenceRequired = getNumberValue(child, "EvidenceRequired")
            local ghostAggression = getStringValue(child, "GhostAggression") or "Normal"
            local huntFrequency = getStringValue(child, "HuntFrequency") or "Normal"

            if type(evidenceRequired) ~= "number" then
                return false, "missing_evidence_required:" .. modeName
            end

            configs[modeName] = {
                EvidenceRequired = evidenceRequired,
                GhostAggression = ghostAggression,
                HuntFrequency = huntFrequency,
            }
            lookup[normalizeName(modeName)] = modeName
        end
    end

    if next(configs) == nil then
        return false, "empty_difficulty_modes"
    end

    return true, {
        configs = configs,
        lookup = lookup,
        source = "ReplicatedStorage.Config.DifficultyModes",
    }
end

function Service:_loadFromLegacyModule()
    local moduleScript = resolveGameDataModule("DifficultyConfig")
    local difficultyData = safeRequire(moduleScript)
    if type(difficultyData) ~= "table" then
        return false, "invalid_difficulty_config"
    end

    local lookup = {}
    for modeName in pairs(difficultyData) do
        lookup[normalizeName(modeName)] = modeName
    end

    return true, {
        configs = difficultyData,
        lookup = lookup,
        source = "Shared.GameData.DifficultyConfig",
    }
end

function Service:Reload()
    local loaded, result = self:_loadFromReplicatedConfig()
    if not loaded then
        loaded, result = self:_loadFromLegacyModule()
    end
    if not loaded then
        return false, result
    end

    local version = (self._state:Get("version") or 0) + 1
    self._state:Set("difficultyConfigs", deepCopy(result.configs or {}))
    self._state:Set("difficultyLookup", deepCopy(result.lookup or {}))
    self._state:Set("source", result.source)
    self._state:Set("loaded", true)
    self._state:Set("version", version)

    self:_publish("DifficultyConfigLoaded", {
        version = version,
        difficultyCount = self:GetDifficultyCount(),
        source = result.source,
    })

    return true, self._state:Get("difficultyConfigs")
end

function Service:GetDifficultyConfigs()
    return deepCopy(self._state:Get("difficultyConfigs") or {})
end

function Service:GetDifficultyConfig(difficultyName)
    if type(difficultyName) ~= "string" then
        return nil
    end

    local configs = self._state:Get("difficultyConfigs") or {}
    if type(configs[difficultyName]) == "table" then
        return deepCopy(configs[difficultyName])
    end

    local lookup = self._state:Get("difficultyLookup") or {}
    local canonicalName = lookup[normalizeName(difficultyName)]
    if canonicalName and type(configs[canonicalName]) == "table" then
        return deepCopy(configs[canonicalName])
    end

    return nil
end

function Service:GetDifficultyNames()
    local names = {}
    for difficultyName in pairs(self._state:Get("difficultyConfigs") or {}) do
        table.insert(names, difficultyName)
    end
    table.sort(names)
    return names
end

function Service:GetDifficultyCount()
    local count = 0
    for _ in pairs(self._state:Get("difficultyConfigs") or {}) do
        count += 1
    end
    return count
end

return Service
