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

local function appendUnique(target, seen, mapId)
    if type(mapId) ~= "string" or mapId == "" then
        return
    end
    if seen[mapId] then
        return
    end
    seen[mapId] = true
    table.insert(target, mapId)
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._mapConfigSystem = nil
    self._seasonalEventSystem = nil
    self._contentSystem = nil
    self._rng = self._deps.Random or Random.new()
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._mapConfigSystem = Services.Get(self._deps, "MapConfigSystem")
    self._seasonalEventSystem = Services.Get(self._deps, "SeasonalEventSystem")
    self._contentSystem = Services.Get(self._deps, "ContentUpdatePipelineSystem")
    self:RefreshPool()
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

function Service:_resolveCorePool()
    local pool = {}
    local seen = {}

    local mapIds = nil
    if type(self._mapConfigSystem) == "table" then
        if type(self._mapConfigSystem.GetMapIds) == "function" then
            mapIds = self._mapConfigSystem:GetMapIds()
        elseif type(self._mapConfigSystem.Service) == "table" and type(self._mapConfigSystem.Service.GetMapIds) == "function" then
            mapIds = self._mapConfigSystem.Service:GetMapIds()
        end
    end

    for _, mapId in ipairs(mapIds or {}) do
        if mapId ~= "LobbySocialHub" then
            appendUnique(pool, seen, mapId)
        end
    end

    if #pool == 0 and type(self._contentSystem) == "table" then
        local fromContent = nil
        if type(self._contentSystem.GetMapPool) == "function" then
            fromContent = self._contentSystem:GetMapPool("Core")
        elseif type(self._contentSystem.Service) == "table" and type(self._contentSystem.Service.GetMapPool) == "function" then
            fromContent = self._contentSystem.Service:GetMapPool("Core")
        end
        for _, mapId in ipairs(fromContent or {}) do
            appendUnique(pool, seen, mapId)
        end
    end

    if #pool == 0 then
        appendUnique(pool, seen, "AbandonedPalace")
    end

    return pool
end

function Service:_resolveEventPool()
    local pool = {}
    local seen = {}

    local seasonal = self._seasonalEventSystem
    local eventMaps = nil
    if type(seasonal) == "table" then
        if type(seasonal.GetEventMapPool) == "function" then
            eventMaps = seasonal:GetEventMapPool()
        elseif type(seasonal.Service) == "table" and type(seasonal.Service.GetEventMapPool) == "function" then
            eventMaps = seasonal.Service:GetEventMapPool()
        end
    end

    for _, mapId in ipairs(eventMaps or {}) do
        appendUnique(pool, seen, mapId)
    end

    return pool
end

function Service:RefreshPool()
    local corePool = self:_resolveCorePool()
    local eventPool = self:_resolveEventPool()

    local merged = {}
    local seen = {}
    for _, mapId in ipairs(corePool) do
        appendUnique(merged, seen, mapId)
    end
    for _, mapId in ipairs(eventPool) do
        appendUnique(merged, seen, mapId)
    end

    self._state:Set("coreMapPool", corePool)
    self._state:Set("eventMapPool", eventPool)
    self._state:Set("currentMapPool", merged)
    self._state:Set("lastRotationAt", os.time())

    local payload = {
        coreMapPool = deepCopy(corePool),
        eventMapPool = deepCopy(eventPool),
        currentMapPool = deepCopy(merged),
        refreshedAt = self._state:Get("lastRotationAt"),
    }

    self:_publish("MapRotationUpdated", payload)
    self:_publish("EventMapPoolUpdated", payload)

    return payload
end

function Service:GetCurrentPool()
    return deepCopy(self._state:Get("currentMapPool") or {})
end

function Service:GetRandomMap(excludedMapId)
    local pool = self:GetCurrentPool()
    if #pool == 0 then
        return nil
    end

    if type(excludedMapId) == "string" and excludedMapId ~= "" and #pool > 1 then
        local filtered = {}
        for _, mapId in ipairs(pool) do
            if mapId ~= excludedMapId then
                table.insert(filtered, mapId)
            end
        end
        if #filtered > 0 then
            pool = filtered
        end
    end

    local index = self._rng:NextInteger(1, #pool)
    return pool[index]
end

function Service:IsEventMap(mapId)
    if type(mapId) ~= "string" then
        return false
    end
    for _, eventMapId in ipairs(self._state:Get("eventMapPool") or {}) do
        if eventMapId == mapId then
            return true
        end
    end
    return false
end

function Service:OnSeasonalEventChanged()
    self:RefreshPool()
end

function Service:OnMapConfigLoaded()
    self:RefreshPool()
end

function Service:OnContentCatalogUpdated()
    self:RefreshPool()
end

return Service
