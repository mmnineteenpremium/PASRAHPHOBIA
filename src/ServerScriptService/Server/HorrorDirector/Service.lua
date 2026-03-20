local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local LOOP_INTERVAL = 2
local MIN_TENSION = 0
local MAX_TENSION = 100

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
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

local function safeCall(target, methodName, ...)
    if type(target) ~= "table" then
        return nil
    end
    local method = target[methodName]
    if type(method) ~= "function" then
        return nil
    end
    local ok, result = pcall(method, target, ...)
    if not ok then
        return nil
    end
    return result
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        AggressionSystem = Services.Get(self._deps, "AggressionSystem"),
        SanitySystem = Services.Get(self._deps, "SanitySystem"),
        EvidenceSystem = Services.Get(self._deps, "EvidenceSystem"),
        MapEventSystem = Services.Get(self._deps, "MapEventSystem"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
end

function Service:Init()
    self._state:Set("currentTension", 0)
    self._state:Set("lastEventTime", os.clock())
    self._state:Set("eventCooldown", 6)
    self._state:Set("directorMode", "CALM")
    self._state:Set("activeMatchId", nil)
    self._state:Set("running", false)
end

function Service:Start()
    -- Loop starts when a match starts.
end

function Service:Stop()
    self:_stopLoop()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_setTension(value, reason)
    local previous = self._state:Get("currentTension") or 0
    local tension = clamp(value, MIN_TENSION, MAX_TENSION)
    self._state:Set("currentTension", tension)

    if tension >= 90 and previous < 90 then
        self:_publish("TensionSpike", {
            matchId = self._state:Get("activeMatchId"),
            previousTension = previous,
            currentTension = tension,
            reason = reason or "threshold_crossed",
        })
    end
end

function Service:UpdateTension(delta, reason)
    local current = self._state:Get("currentTension") or 0
    self:_setTension(current + (tonumber(delta) or 0), reason)
    return self._state:Get("currentTension")
end

function Service:EvaluateDirectorState()
    local tension = self._state:Get("currentTension") or 0
    local mode = "CALM"
    if tension >= 60 then
        mode = "INTENSE"
    elseif tension >= 30 then
        mode = "BUILDING"
    end
    self._state:Set("directorMode", mode)
    return mode
end

function Service:_canTriggerEvent(nowTime)
    local lastEventTime = self._state:Get("lastEventTime") or 0
    local cooldown = self._state:Get("eventCooldown") or 6
    return (nowTime - lastEventTime) >= cooldown
end

function Service:_getMatchPhase(matchId)
    local matchSystem = self._dependencies.MatchSystem
    return safeCall(matchSystem, "GetCurrentPhase", matchId)
end

function Service:_getAverageSanity(matchId)
    local sanitySystem = self._dependencies.SanitySystem
    return safeCall(sanitySystem, "GetAverageTeamSanity", matchId)
end

function Service:_getAggression(matchId)
    local aggressionSystem = self._dependencies.AggressionSystem
    local info = safeCall(aggressionSystem, "GetAggressionLevel", matchId)
    if type(info) == "table" then
        return tonumber(info.aggression) or 0
    end
    return tonumber(info) or 0
end

function Service:TriggerEvent()
    local matchId = self._state:Get("activeMatchId")
    if not matchId then
        return nil
    end

    local nowTime = os.clock()
    if not self:_canTriggerEvent(nowTime) then
        return nil
    end

    local tension = self._state:Get("currentTension") or 0
    local mode = self._state:Get("directorMode") or "CALM"
    local eventType
    local channelEvent

    if tension < 30 then
        eventType = "AudioDisturbance"
        channelEvent = "AmbientDisturbance"
    elseif tension < 60 then
        local pool = { "DoorSlam", "ObjectMovement", "LightFlicker" }
        eventType = pool[(math.floor(nowTime) % #pool) + 1]
        channelEvent = "ParanormalEvent"
    elseif tension < 90 then
        eventType = "GhostManifestation"
        channelEvent = "ParanormalEvent"
    else
        eventType = "HuntPressure"
        channelEvent = "TensionSpike"
    end

    self._state:Set("lastEventTime", nowTime)

    self:_publish(channelEvent, {
        matchId = matchId,
        eventType = eventType,
        tension = tension,
        mode = mode,
    })

    self:_publish("DirectorEvent", {
        matchId = matchId,
        eventType = eventType,
        tension = tension,
        mode = mode,
    })

    local mapEventSystem = self._dependencies.MapEventSystem
    safeCall(mapEventSystem, "TriggerEvent", matchId, eventType)

    if tension >= 90 then
        local aggressionSystem = self._dependencies.AggressionSystem
        safeCall(aggressionSystem, "IncreaseAggression", matchId, 2, "horror_director_critical_tension")
        safeCall(aggressionSystem, "CheckHuntTrigger", matchId, { source = "HorrorDirector", tension = tension })
    end

    return eventType
end

function Service:_directorStep()
    local matchId = self._state:Get("activeMatchId")
    if not matchId then
        return
    end

    local phase = self:_getMatchPhase(matchId)
    if phase and phase ~= "Investigation" and phase ~= "Hunt" and phase ~= "InvestigationPhase" and phase ~= "HuntPhase" then
        self:UpdateTension(-1, "inactive_phase")
        self:EvaluateDirectorState()
        return
    end

    local sanity = self:_getAverageSanity(matchId)
    if type(sanity) == "number" then
        if sanity <= 40 then
            self:UpdateTension(3, "critical_team_sanity")
        elseif sanity <= 60 then
            self:UpdateTension(2, "low_team_sanity")
        elseif sanity <= 80 then
            self:UpdateTension(1, "mild_sanity_drop")
        end
    end

    local aggression = self:_getAggression(matchId)
    if aggression >= 75 then
        self:UpdateTension(3, "high_ghost_aggression")
    elseif aggression >= 50 then
        self:UpdateTension(2, "elevated_ghost_aggression")
    end

    local nowTime = os.clock()
    local lastEventTime = self._state:Get("lastEventTime") or nowTime
    if nowTime - lastEventTime >= 10 then
        self:UpdateTension(-1, "quiet_period")
    end

    self:EvaluateDirectorState()
    self:TriggerEvent()
end

function Service:_startLoop()
    if self._state:Get("running") == true then
        return
    end

    self._state:Set("running", true)
    local loopToken = (self._state:Get("loopToken") or 0) + 1
    self._state:Set("loopToken", loopToken)

    task.spawn(function()
        while self._state:Get("running") and self._state:Get("loopToken") == loopToken do
            self:_directorStep()
            task.wait(LOOP_INTERVAL)
        end
    end)
end

function Service:_stopLoop()
    self._state:Set("running", false)
    self._state:Set("loopToken", (self._state:Get("loopToken") or 0) + 1)
end

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._state:ResetForMatch(matchId)
    self:_startLoop()
end

function Service:OnMatchEnded(payload)
    local activeMatchId = self._state:Get("activeMatchId")
    local matchId = payload and payload.matchId or activeMatchId
    if not matchId or (activeMatchId and matchId ~= activeMatchId) then
        return
    end

    self._state:Set("lastMatchResults", payload and payload.results)
    self:_stopLoop()
    self._state:Set("activeMatchId", nil)
end

function Service:OnEvidenceCollected(payload)
    if self._state:Get("activeMatchId") == nil then
        return
    end
    self:UpdateTension(5, "evidence_collected")
    self:EvaluateDirectorState()
end

function Service:OnPlayerSanityChanged(payload)
    if self._state:Get("activeMatchId") == nil then
        return
    end
    local sanity = payload and payload.newSanity
    if type(sanity) == "number" then
        if sanity <= 30 then
            self:UpdateTension(6, "very_low_sanity")
        elseif sanity <= 50 then
            self:UpdateTension(4, "low_sanity")
        elseif sanity <= 70 then
            self:UpdateTension(2, "sanity_drop")
        end
    end
    self:EvaluateDirectorState()
end

function Service:OnGhostInteraction(payload)
    if self._state:Get("activeMatchId") == nil then
        return
    end
    self:UpdateTension(4, "ghost_interaction")
    self:EvaluateDirectorState()
end

function Service:OnHuntTriggered(payload)
    if self._state:Get("activeMatchId") == nil then
        return
    end
    self:UpdateTension(8, "hunt_triggered")
    self:EvaluateDirectorState()
    self:_publish("TensionSpike", {
        matchId = payload and payload.matchId or self._state:Get("activeMatchId"),
        currentTension = self._state:Get("currentTension"),
        reason = "hunt_triggered",
    })
end

return Service

