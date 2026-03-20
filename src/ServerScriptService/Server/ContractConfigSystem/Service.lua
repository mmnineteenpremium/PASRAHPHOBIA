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
        warn(string.format("[ContractConfigSystem] Failed loading contract configs: %s", tostring(err)))
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

function Service:Reload()
    local moduleScript = resolveGameDataModule("ContractConfig")
    local contractData = safeRequire(moduleScript)
    if type(contractData) ~= "table" then
        return false, "invalid_contract_config"
    end

    local version = (self._state:Get("version") or 0) + 1
    self._state:Set("contractConfigs", deepCopy(contractData))
    self._state:Set("loaded", true)
    self._state:Set("version", version)

    self:_publish("ContractConfigLoaded", {
        version = version,
        contractCount = self:GetContractCount(),
    })

    return true, self._state:Get("contractConfigs")
end

function Service:GetContractConfigs()
    return deepCopy(self._state:Get("contractConfigs") or {})
end

function Service:GetContractConfig(contractId)
    local contractConfig = (self._state:Get("contractConfigs") or {})[contractId]
    if type(contractConfig) ~= "table" then
        return nil
    end
    return deepCopy(contractConfig)
end

function Service:GetContractIds()
    local ids = {}
    for contractId in pairs(self._state:Get("contractConfigs") or {}) do
        table.insert(ids, contractId)
    end
    table.sort(ids)
    return ids
end

function Service:GetContractCount()
    local count = 0
    for _ in pairs(self._state:Get("contractConfigs") or {}) do
        count += 1
    end
    return count
end

return Service
