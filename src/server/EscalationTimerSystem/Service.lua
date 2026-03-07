local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local LOOP_INTERVAL_SECONDS = 1

local DEFAULT_STAGES = {
    { stageName = "Calm", durationSeconds = 90, aggressionBoost = 0, tensionDelta = 0, forceHunt = false },
    { stageName = "Tension", durationSeconds = 120, aggressionBoost = 6, tensionDelta = 2, forceHunt = false },
    { stageName = "Aggressive", durationSeconds = 120, aggressionBoost = 12, tensionDelta = 4, forceHunt = false },
    { stageName = "Hunting", durationSeconds = 999, aggressionBoost = 18, tensionDelta = 6, forceHunt = true },
}

local STAGE_ORDER = {
    Calm = 1,
    Tension = 2,
    Aggressive = 3,
    Hunting = 4,
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

local function resolveEscalationFolder()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local configFolder = replicatedStorage:FindFirstChild("Config")
    if not configFolder then
        return nil
    end
    return configFolder:FindFirstChild("Escalation")
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

local function getBoolValue(parent, childName)
    local child = parent and parent:FindFirstChild(childName)
    if child and child:IsA("BoolValue") then
        return child.Value == true
    end
    return false
end

local function sortStages(stages)
    table.sort(stages, function(a, b)
        local aOrder = STAGE_ORDER[a.stageName] or 99
        local bOrder = STAGE_ORDER[b.stageName] or 99
        if aOrder == bOrder then
            return tostring(a.stageName) < tostring(b.stageName)
        end
        return aOrder < bOrder
    end)
    return stages
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
    self:ReloadConfig()
end

function Service:Start()
    -- Loop starts when MatchStarted arrives.
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

function Service:ReloadConfig()
    local folder = resolveEscalationFolder()
    local stages = {}

    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Folder") then
                local stageName = getStringValue(child, "StageName") or child.Name
                table.insert(stages, {
                    stageName = stageName,
                    durationSeconds = getNumberValue(child, "DurationSeconds") or 60,
                    aggressionBoost = getNumberValue(child, "AggressionBoost") or 0,
                    tensionDelta = getNumberValue(child, "TensionDelta") or 0,
                    forceHunt = getBoolValue(child, "ForceHunt"),
                })
            end
        end
    end

    if #stages == 0 then
        stages = deepCopy(DEFAULT_STAGES)
    end

    self._state:Set("stages", sortStages(stages))
    self:_publish("EscalationConfigLoaded", {
        stageCount = #stages,
    })

    return deepCopy(stages)
end

function Service:_emitStageChange(previousStage, nextStage, now)
    local matchId = self._state:Get("activeMatchId")
    if not matchId or type(nextStage) ~= "table" then
        return
    end

    local currentNow = now or os.clock()
    local elapsedSeconds = math.max(0, currentNow - (self._state:Get("matchStartedAt") or currentNow))
    local payload = {
        matchId = matchId,
        previousStage = previousStage,
        currentStage = nextStage.stageName,
        stageIndex = self._state:Get("currentStageIndex"),
        elapsedSeconds = elapsedSeconds,
        stageDuration = nextStage.durationSeconds,
        aggressionBoost = nextStage.aggressionBoost,
        tensionDelta = nextStage.tensionDelta,
        forceHunt = nextStage.forceHunt,
        now = currentNow,
    }

    self:_publish("EscalationStageChanged", payload)

    if (nextStage.tensionDelta or 0) > 0 then
        self:_publish("TensionIncreased", {
            matchId = matchId,
            delta = nextStage.tensionDelta,
            source = "EscalationTimerSystem",
            stage = nextStage.stageName,
            now = currentNow,
        })
    end

    if (nextStage.aggressionBoost or 0) > 0 then
        self:_publish("TensionHigh", {
            matchId = matchId,
            aggressionBoost = nextStage.aggressionBoost,
            duration = math.max(8, math.floor((nextStage.durationSeconds or 0) * 0.35)),
            source = "EscalationTimerSystem",
            stage = nextStage.stageName,
            now = currentNow,
        })
    end

    if nextStage.forceHunt == true then
        self:_publish("ForceHunt", {
            matchId = matchId,
            source = "EscalationTimerSystem",
            stage = nextStage.stageName,
            now = currentNow,
        })
    end
end

function Service:_setStage(stageIndex, now)
    local stages = self._state:Get("stages") or {}
    local nextStage = stages[stageIndex]
    if not nextStage then
        return false
    end

    local previousStage = self._state:Get("currentStageName")
    local currentNow = now or os.clock()

    self._state:Set("currentStageIndex", stageIndex)
    self._state:Set("currentStageName", nextStage.stageName)
    self._state:Set("nextStageAt", currentNow + (nextStage.durationSeconds or 0))
    self:_emitStageChange(previousStage, nextStage, currentNow)
    return true
end

function Service:_advanceStage(now)
    local nextIndex = (self._state:Get("currentStageIndex") or 0) + 1
    return self:_setStage(nextIndex, now)
end

function Service:_tick()
    if not self._state:Get("running") then
        return
    end

    local now = os.clock()
    local stages = self._state:Get("stages") or {}
    local stageIndex = self._state:Get("currentStageIndex") or 0
    local currentStage = stages[stageIndex]
    if not currentStage then
        return
    end

    local nextStageAt = self._state:Get("nextStageAt") or math.huge
    if now < nextStageAt then
        return
    end

    local advanced = self:_advanceStage(now)
    if not advanced then
        self._state:Set("nextStageAt", now + (currentStage.durationSeconds or 60))
    end
end

function Service:_startLoop()
    if self._state:Get("running") == true then
        return
    end

    self._state:Set("running", true)
    local loopToken = (self._state:Get("loopToken") or 0) + 1
    self._state:Set("loopToken", loopToken)

    task.spawn(function()
        while self._state:Get("running") == true and self._state:Get("loopToken") == loopToken do
            self:_tick()
            task.wait(LOOP_INTERVAL_SECONDS)
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

    self:_stopLoop()

    local now = payload and payload.now or os.clock()
    self._state:Set("activeMatchId", matchId)
    self._state:Set("matchStartedAt", now)
    self._state:Set("currentStageIndex", 0)
    self._state:Set("currentStageName", nil)
    self._state:Set("nextStageAt", now)

    if not self:_setStage(1, now) then
        return
    end

    self:_startLoop()
end

function Service:OnMatchEnded(payload)
    local activeMatchId = self._state:Get("activeMatchId")
    local matchId = payload and payload.matchId or activeMatchId
    if not matchId or (activeMatchId and matchId ~= activeMatchId) then
        return
    end

    self:_stopLoop()
    self._state:Set("activeMatchId", nil)
    self._state:Set("currentStageIndex", 0)
    self._state:Set("currentStageName", nil)
    self._state:Set("matchStartedAt", 0)
    self._state:Set("nextStageAt", 0)
end

return Service
