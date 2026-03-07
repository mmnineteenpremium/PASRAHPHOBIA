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
    local gameData = shared:FindFirstChild("GameData")
    if not gameData then
        return nil
    end
    return gameData:FindFirstChild(moduleName)
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._contentSystem = nil
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._contentSystem = Services.Get(self._deps, "ContentUpdatePipelineSystem")
    self:RefreshActiveEvent()
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

function Service:_seasonalConfig()
    local seasonal = nil
    if self._contentSystem and type(self._contentSystem.GetSection) == "function" then
        seasonal = self._contentSystem:GetSection("SeasonalEvents")
    elseif type(self._contentSystem) == "table" and type(self._contentSystem.Service) == "table" then
        if type(self._contentSystem.Service.GetSection) == "function" then
            seasonal = self._contentSystem.Service:GetSection("SeasonalEvents")
        end
    end

    if type(seasonal) == "table" then
        return seasonal
    end

    local moduleScript = resolveGameDataModule("LiveOpsContent")
    local liveOps = safeRequire(moduleScript)
    if type(liveOps) == "table" and type(liveOps.SeasonalEvents) == "table" then
        return deepCopy(liveOps.SeasonalEvents)
    end

    return {
        Enabled = false,
        Events = {},
    }
end

function Service:_isEventEnabled(eventId, eventData)
    if type(eventData) ~= "table" then
        return false
    end

    local overrides = self._state:Get("eventOverrides") or {}
    local override = overrides[eventId]
    if type(override) == "boolean" then
        return override
    end

    return eventData.enabled ~= false
end

function Service:_selectEvent(nowUnix)
    local seasonal = self:_seasonalConfig()
    if seasonal.Enabled == false then
        return nil, nil
    end

    local events = seasonal.Events or {}
    local forceId = seasonal.ForceActiveEventId
    if type(forceId) == "string" and forceId ~= "" and type(events[forceId]) == "table" then
        local forced = events[forceId]
        if self:_isEventEnabled(forceId, forced) then
            return forceId, deepCopy(forced)
        end
    end

    local nowValue = tonumber(nowUnix) or os.time()
    local activeId = nil
    local activeEvent = nil

    for eventId, eventData in pairs(events) do
        if self:_isEventEnabled(eventId, eventData) then
            local startUnix = tonumber(eventData.startUnix) or -math.huge
            local endUnix = tonumber(eventData.endUnix) or math.huge
            if nowValue >= startUnix and nowValue <= endUnix then
                if activeId == nil or tostring(eventId) < tostring(activeId) then
                    activeId = eventId
                    activeEvent = deepCopy(eventData)
                end
            end
        end
    end

    return activeId, activeEvent
end

function Service:RefreshActiveEvent(nowUnix)
    local currentId = self._state:Get("activeEventId")
    local nextId, nextEvent = self:_selectEvent(nowUnix)

    self._state:Set("activeEventId", nextId)
    self._state:Set("activeEvent", nextEvent)
    self._state:Set("lastRefreshAt", os.time())

    if currentId ~= nextId then
        self._state:AppendHistory({
            previousEventId = currentId,
            nextEventId = nextId,
            at = os.time(),
        })

        if currentId ~= nil then
            self:_publish("SeasonalEventDeactivated", {
                eventId = currentId,
                at = os.time(),
            })
        end

        if nextId ~= nil then
            self:_publish("SeasonalEventActivated", {
                eventId = nextId,
                eventData = deepCopy(nextEvent),
                at = os.time(),
            })
        end

        self:_publish("SeasonalEventChanged", {
            previousEventId = currentId,
            eventId = nextId,
            eventData = deepCopy(nextEvent),
            at = os.time(),
        })
    end

    self:_publish("SeasonalEventStatusUpdated", {
        eventId = nextId,
        eventData = deepCopy(nextEvent),
        refreshedAt = self._state:Get("lastRefreshAt"),
    })

    return nextId, deepCopy(nextEvent)
end

function Service:GetActiveEvent()
    local eventId = self._state:Get("activeEventId")
    local eventData = self._state:Get("activeEvent")
    if eventId == nil or type(eventData) ~= "table" then
        return nil
    end
    return {
        eventId = eventId,
        eventData = deepCopy(eventData),
    }
end

function Service:GetEventMapPool()
    local active = self:GetActiveEvent()
    if not active then
        return {}
    end

    local mapRotation = active.eventData.mapRotation or {}
    if mapRotation.enabled == false then
        return {}
    end

    local out = {}
    for _, mapId in ipairs(mapRotation.eventMaps or active.eventData.limitedMaps or {}) do
        if type(mapId) == "string" and mapId ~= "" then
            table.insert(out, mapId)
        end
    end
    return out
end

function Service:OnContentCatalogUpdated()
    self:RefreshActiveEvent()
end

function Service:OnSeasonalEventToggleRequested(payload)
    local eventId = payload and payload.eventId
    if type(eventId) ~= "string" or eventId == "" then
        return false, "invalid_event_id"
    end

    local overrides = self._state:Get("eventOverrides") or {}
    overrides[eventId] = payload.enabled == true
    self._state:Set("eventOverrides", overrides)

    self:RefreshActiveEvent(payload.nowUnix)
    return true
end

return Service
