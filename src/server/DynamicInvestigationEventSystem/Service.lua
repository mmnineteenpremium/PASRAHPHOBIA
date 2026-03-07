local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_EVENT_TYPES = {
    {
        id = "cold_spot",
        title = "Sudden Cold Spot",
        mapEventType = "TemperatureDrop",
        escalationWeight = { Calm = 1.0, Tension = 1.2, Aggressive = 1.35, Hunting = 1.5 },
    },
    {
        id = "emf_spike",
        title = "Unusual EMF Spike",
        mapEventType = "LightFlicker",
        escalationWeight = { Calm = 0.9, Tension = 1.1, Aggressive = 1.3, Hunting = 1.45 },
    },
    {
        id = "object_chain",
        title = "Object Chain Reaction",
        mapEventType = "ObjectThrow",
        escalationWeight = { Calm = 0.8, Tension = 1.2, Aggressive = 1.4, Hunting = 1.6 },
    },
    {
        id = "room_lockdown",
        title = "Room Lockdown",
        mapEventType = "DoorSlam",
        escalationWeight = { Calm = 0.7, Tension = 1.15, Aggressive = 1.45, Hunting = 1.75 },
    },
}

local STAGE_INTERVAL_MULTIPLIER = {
    Calm = 1.0,
    Tension = 0.85,
    Aggressive = 0.72,
    Hunting = 0.58,
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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._rng = self._deps.Random or Random.new()
    self._dependencies = {}
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        MapEventSystem = Services.Get(self._deps, "MapEventSystem"),
        ContentUpdatePipelineSystem = Services.Get(self._deps, "ContentUpdatePipelineSystem"),
    }
    self:_loadConfig()
end

function Service:Start()
end

function Service:Stop()
    self:_stopLoop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_loadConfig()
    local section = nil
    local content = self._dependencies.ContentUpdatePipelineSystem
    if type(content) == "table" and type(content.GetSection) == "function" then
        section = content:GetSection("DynamicInvestigationEvents")
    elseif type(content) == "table" and type(content.Service) == "table" and type(content.Service.GetSection) == "function" then
        section = content.Service:GetSection("DynamicInvestigationEvents")
    end

    section = section or {}

    self._state:Set("enabled", section.Enabled ~= false)
    self._state:Set("baseIntervalSeconds", math.max(8, math.floor(tonumber(section.BaseIntervalSeconds) or 36)))
    self._state:Set("minIntervalSeconds", math.max(5, math.floor(tonumber(section.MinIntervalSeconds) or 12)))

    local types = section.EventTypes
    if type(types) ~= "table" or #types == 0 then
        types = DEFAULT_EVENT_TYPES
    end
    self._state:Set("eventTypes", deepCopy(types))
end

function Service:_stageMultiplier(stageName)
    return STAGE_INTERVAL_MULTIPLIER[stageName] or 1.0
end

function Service:_nextIntervalSeconds()
    local base = self._state:Get("baseIntervalSeconds") or 36
    local minimum = self._state:Get("minIntervalSeconds") or 12
    local stage = self._state:Get("currentStage") or "Calm"

    local stageAdjusted = math.max(minimum, math.floor(base * self:_stageMultiplier(stage)))
    local jitter = self._rng:NextInteger(-3, 4)
    return math.max(minimum, stageAdjusted + jitter)
end

function Service:_weightedPick(stageName)
    local candidates = self._state:Get("eventTypes") or {}
    local total = 0

    for _, eventType in ipairs(candidates) do
        local weights = eventType.escalationWeight or {}
        local weight = tonumber(weights[stageName]) or tonumber(weights.Default) or 1
        if weight > 0 then
            total += weight
        end
    end

    if total <= 0 then
        return candidates[1]
    end

    local roll = self._rng:NextNumber() * total
    local cursor = 0

    for _, eventType in ipairs(candidates) do
        local weights = eventType.escalationWeight or {}
        local weight = tonumber(weights[stageName]) or tonumber(weights.Default) or 1
        if weight > 0 then
            cursor += weight
            if roll <= cursor then
                return eventType
            end
        end
    end

    return candidates[#candidates]
end

function Service:_scheduleNext(nowClock)
    local nowValue = nowClock or os.clock()
    self._state:Set("nextEventAt", nowValue + self:_nextIntervalSeconds())
end

function Service:_triggerOne(nowClock)
    if self._state:Get("enabled") == false then
        return
    end

    local matchId = self._state:Get("activeMatchId")
    if type(matchId) ~= "string" then
        return
    end

    local stage = self._state:Get("currentStage") or "Calm"
    local picked = self:_weightedPick(stage)
    if type(picked) ~= "table" then
        return
    end

    local nowValue = nowClock or os.clock()
    local intensity = 0.55 + (self._rng:NextNumber() * 0.35)

    local payload = {
        matchId = matchId,
        eventId = picked.id,
        title = picked.title,
        eventType = picked.mapEventType,
        stage = stage,
        intensity = intensity,
        source = "DynamicInvestigationEventSystem",
        now = nowValue,
    }

    local mapEventSystem = self._dependencies.MapEventSystem
    if type(mapEventSystem) == "table" then
        if type(mapEventSystem.TriggerEvent) == "function" then
            mapEventSystem:TriggerEvent({
                matchId = matchId,
                eventType = picked.mapEventType,
                intensity = intensity,
                source = "DynamicInvestigationEventSystem",
                now = nowValue,
            })
        elseif type(mapEventSystem.Service) == "table" and type(mapEventSystem.Service.TriggerEvent) == "function" then
            mapEventSystem.Service:TriggerEvent({
                matchId = matchId,
                eventType = picked.mapEventType,
                intensity = intensity,
                source = "DynamicInvestigationEventSystem",
                now = nowValue,
            })
        end
    end

    if picked.id == "room_lockdown" then
        self:_publish("RoomLockdownTriggered", payload)
    end

    self._state:AppendEvent(payload)
    self:_publish("DynamicInvestigationEventTriggered", payload)
    self:_publish("InvestigationUnpredictabilityIncreased", {
        matchId = matchId,
        stage = stage,
        eventId = picked.id,
        now = nowValue,
    })
end

function Service:_tick()
    if self._state:Get("running") ~= true then
        return
    end

    local matchId = self._state:Get("activeMatchId")
    if type(matchId) ~= "string" then
        return
    end

    local nowValue = os.clock()
    local nextEventAt = self._state:Get("nextEventAt") or 0
    if nowValue >= nextEventAt then
        self:_triggerOne(nowValue)
        self:_scheduleNext(nowValue)
    end
end

function Service:_startLoop()
    if self._state:Get("running") == true then
        return
    end

    self._state:Set("running", true)
    local token = (self._state:Get("loopToken") or 0) + 1
    self._state:Set("loopToken", token)

    task.spawn(function()
        while self._state:Get("running") == true and self._state:Get("loopToken") == token do
            self:_tick()
            task.wait(1)
        end
    end)
end

function Service:_stopLoop()
    self._state:Set("running", false)
    self._state:Set("loopToken", (self._state:Get("loopToken") or 0) + 1)
end

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if type(matchId) ~= "string" then
        return
    end

    self:_stopLoop()
    self._state:ResetForMatch(matchId)
    self:_scheduleNext(os.clock())
    self:_startLoop()
end

function Service:OnEscalationStageChanged(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if type(matchId) ~= "string" or matchId ~= activeMatchId then
        return
    end

    local stageName = payload.currentStage or payload.stage or "Calm"
    self._state:Set("currentStage", tostring(stageName))

    local soon = os.clock() + math.max(4, math.floor(self:_nextIntervalSeconds() * 0.35))
    if soon < (self._state:Get("nextEventAt") or math.huge) then
        self._state:Set("nextEventAt", soon)
    end
end

function Service:OnMatchEnded(payload)
    local activeMatchId = self._state:Get("activeMatchId")
    local matchId = payload and payload.matchId
    if type(activeMatchId) ~= "string" then
        return
    end
    if type(matchId) == "string" and matchId ~= activeMatchId then
        return
    end

    self:_stopLoop()
    self._state:Set("activeMatchId", nil)
    self._state:Set("nextEventAt", 0)
end

function Service:OnContentCatalogUpdated()
    self:_loadConfig()
end

return Service
