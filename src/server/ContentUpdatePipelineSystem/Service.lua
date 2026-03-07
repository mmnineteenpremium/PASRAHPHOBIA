local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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
    local gameData = shared:FindFirstChild("GameData")
    if not gameData then
        return nil
    end
    return gameData:FindFirstChild(moduleName)
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
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self:ReloadCatalog()
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

function Service:ReloadCatalog()
    local moduleScript = resolveGameDataModule("LiveOpsContent")
    local catalog = safeRequire(moduleScript)
    if type(catalog) ~= "table" then
        return false, "invalid_live_ops_catalog"
    end

    local version = (self._state:Get("version") or 0) + 1
    self._state:Set("catalog", deepCopy(catalog))
    self._state:Set("version", version)
    self._state:Set("loaded", true)
    self._state:Set("lastLoadedAt", os.time())

    local payload = {
        version = version,
        loadedAt = self._state:Get("lastLoadedAt"),
        sections = {
            "DailyContracts",
            "WeeklyChallenges",
            "SeasonalEvents",
            "DynamicInvestigationEvents",
            "SocialEmotes",
            "Reputation",
            "ContentPools",
        },
    }

    self:_publish("ContentCatalogLoaded", payload)
    self:_publish("ContentCatalogUpdated", payload)

    return true, self:GetCatalog()
end

function Service:GetCatalog()
    return deepCopy(self._state:Get("catalog") or {})
end

function Service:GetSection(sectionName)
    local catalog = self._state:Get("catalog") or {}
    local section = catalog[sectionName]
    if type(section) ~= "table" then
        return nil
    end
    return deepCopy(section)
end

function Service:GetMapPool(poolName)
    local contentPools = self:GetSection("ContentPools") or {}
    local mapPools = contentPools.MapPools or {}
    local key = poolName or "Core"
    local pool = mapPools[key]
    if type(pool) ~= "table" then
        return {}
    end
    local out = {}
    for _, mapId in ipairs(pool) do
        if type(mapId) == "string" and mapId ~= "" then
            table.insert(out, mapId)
        end
    end
    return out
end

function Service:IsLoaded()
    return self._state:Get("loaded") == true
end

return Service
