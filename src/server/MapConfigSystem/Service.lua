local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEPENDENCY_NAMES = {
    "MatchSystem",
    "GhostSystem",
    "MapInteractionSystem",
    "MapEventSystem",
    "ContractObjectiveSystem",
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

local function filterCandidates(rooms, candidates)
    local allowed = {}
    for _, room in ipairs(rooms) do
        allowed[room] = true
    end
    local out = {}
    for _, candidate in ipairs(candidates) do
        if allowed[candidate] then
            table.insert(out, candidate)
        end
    end
    return out
end

local function normalizeMapDefinition(raw, fallbackKey)
    local rooms = normalizeStringList(raw.rooms or raw.roomList or {})
    local spawnPoints = normalizeStringList(raw.spawnPoints)
    local evidencePoints = normalizeStringList(raw.evidenceSpawnPoints)
    local interactionObjects = normalizeStringList(raw.interactionObjects)
    local ghostCandidatesRaw = normalizeStringList(raw.ghostRoomCandidates or {})
    local ghostCandidates = filterCandidates(rooms, ghostCandidatesRaw)

    if #rooms == 0 then
        return nil, "map_missing_rooms"
    end
    if #spawnPoints == 0 then
        return nil, "map_missing_spawn_points"
    end
    if #ghostCandidatesRaw > 0 and #ghostCandidates == 0 then
        return nil, "ghost_candidates_not_in_rooms"
    end

    return {
        mapName = type(raw.mapName) == "string" and raw.mapName or fallbackKey,
        mapCategory = type(raw.mapCategory) == "string" and raw.mapCategory or "Investigation",
        mapSize = type(raw.mapSize) == "string" and raw.mapSize or "Medium",
        spawnPoints = spawnPoints,
        rooms = rooms,
        ghostRoomCandidates = ghostCandidates,
        evidenceSpawnPoints = evidencePoints,
        interactionObjects = interactionObjects,
    }
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
        warn(string.format("[MapConfigSystem] Failed loading map configs: %s", tostring(err)))
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

function Service:_buildMapDatabase()
    local moduleScript = resolveGameDataModule("MapConfig")
    local mapTable = safeRequire(moduleScript)
    if type(mapTable) ~= "table" then
        return false, "invalid_map_config_module"
    end

    local out = {}
    for mapKey, rawDefinition in pairs(mapTable) do
        if type(rawDefinition) == "table" then
            local normalized, err = normalizeMapDefinition(rawDefinition, mapKey)
            if not normalized then
                return false, string.format("%s:%s", err, mapKey)
            end
            out[mapKey] = normalized
        end
    end

    return true, out
end

function Service:LoadMaps()
    return self:_buildMapDatabase()
end

function Service:Reload()
    local ok, loadResult = self:LoadMaps()
    if not ok then
        return false, loadResult
    end

    local version = (self._state:Get("version") or 0) + 1
    self._state:Set("mapConfigs", deepCopy(loadResult))
    self._state:Set("loaded", true)
    self._state:Set("version", version)

    self:_publish("MapConfigLoaded", {
        version = version,
        mapCount = self:GetMapCount(),
    })

    return true, self._state:Get("mapConfigs")
end

function Service:GetMapConfigs()
    return deepCopy(self._state:Get("mapConfigs") or {})
end

function Service:GetMapConfig(mapId)
    local configs = self._state:Get("mapConfigs") or {}
    local mapConfig = configs[mapId]
    if type(mapConfig) ~= "table" then
        return nil
    end
    return deepCopy(mapConfig)
end

function Service:GetMapIds()
    local ids = {}
    for mapId in pairs(self._state:Get("mapConfigs") or {}) do
        table.insert(ids, mapId)
    end
    table.sort(ids)
    return ids
end

function Service:GetMapCount()
    local count = 0
    for _ in pairs(self._state:Get("mapConfigs") or {}) do
        count += 1
    end
    return count
end

return Service
