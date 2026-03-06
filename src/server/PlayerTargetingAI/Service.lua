local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local TARGET_MODES = {
    "ClosestPlayer",
    "LowestSanity",
    "MostAggressivePlayer",
    "RandomTarget",
}

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

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function appendHistory(history, entry)
    table.insert(history, entry)
    if #history > 300 then
        table.remove(history, 1)
    end
end

local function getPlayerId(value)
    if type(value) == "number" then
        return value
    end
    if typeof(value) == "Instance" and value:IsA("Player") then
        return value.UserId
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    self._rng = self._deps.Random or Random.new()
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        AggressionSystem = Services.Get(self._deps, "AggressionSystem"),
        SanitySystem = Services.Get(self._deps, "SanitySystem"),
        HorrorDirector = Services.Get(self._deps, "HorrorDirector"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
end

function Service:Init()
    self._state:Set("currentTargets", self._state:Get("currentTargets") or {})
    self._state:Set("targetHistory", self._state:Get("targetHistory") or {})
    self._state:Set("playerMetrics", self._state:Get("playerMetrics") or {})
end

function Service:Start()
    -- Event-driven system.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_ensurePlayerMetrics(matchId)
    local metrics = self._state:Get("playerMetrics") or {}
    if metrics[matchId] == nil then
        metrics[matchId] = {}
    end
    self._state:Set("playerMetrics", metrics)
    return metrics[matchId], metrics
end

function Service:UpdatePlayerMetrics(payload)
    if type(payload) ~= "table" then
        return
    end
    local matchId = payload.matchId or self._state:Get("activeMatchId")
    if type(matchId) ~= "string" or matchId == "" then
        return
    end
    local playerId = getPlayerId(payload.player) or getPlayerId(payload.userId) or getPlayerId(payload.playerId)
    if not playerId then
        return
    end

    local perMatchMetrics = self:_ensurePlayerMetrics(matchId)
    local existing = perMatchMetrics[playerId] or {
        sanity = 100,
        noise = 0,
        distanceToGhostRoom = 999,
        interactions = 0,
    }

    if payload.sanity ~= nil then
        existing.sanity = clamp(tonumber(payload.sanity) or existing.sanity, 0, 100)
    end
    if payload.noiseLevel ~= nil or payload.noise ~= nil then
        existing.noise = clamp(tonumber(payload.noiseLevel or payload.noise) or existing.noise, 0, 100)
    end
    if payload.distanceToGhostRoom ~= nil or payload.distance ~= nil then
        existing.distanceToGhostRoom = math.max(0, tonumber(payload.distanceToGhostRoom or payload.distance) or existing.distanceToGhostRoom)
    end
    if payload.interactions ~= nil then
        existing.interactions = math.max(0, tonumber(payload.interactions) or existing.interactions)
    end

    perMatchMetrics[playerId] = existing
end

function Service:_scoreForMode(mode, metric)
    if mode == "LowestSanity" then
        return 100 - (metric.sanity or 100)
    end
    if mode == "MostAggressivePlayer" then
        return (metric.noise or 0) + ((metric.interactions or 0) * 5)
    end
    if mode == "ClosestPlayer" then
        return 100 - clamp(metric.distanceToGhostRoom or 999, 0, 100)
    end
    return self._rng:NextNumber(0, 100)
end

function Service:SelectTarget(matchId, ghostId, mode, candidatePlayerIds)
    if type(matchId) ~= "string" or matchId == "" then
        return nil, "invalid_match_id"
    end

    local selectedMode = mode
    if type(selectedMode) ~= "string" or self._state:Get("targetingModes")[selectedMode] ~= true then
        selectedMode = TARGET_MODES[self._rng:NextInteger(1, #TARGET_MODES)]
    end

    local metrics = self._state:Get("playerMetrics") or {}
    local perMatchMetrics = metrics[matchId] or {}

    local candidates = candidatePlayerIds or {}
    if #candidates == 0 then
        for playerId in pairs(perMatchMetrics) do
            table.insert(candidates, playerId)
        end
    end
    if #candidates == 0 then
        return nil, "no_candidates"
    end

    local bestPlayerId = nil
    local bestScore = -math.huge
    for _, playerId in ipairs(candidates) do
        local metric = perMatchMetrics[playerId] or {
            sanity = 100,
            noise = 0,
            distanceToGhostRoom = 999,
            interactions = 0,
        }
        local score = self:_scoreForMode(selectedMode, metric)
        if score > bestScore then
            bestScore = score
            bestPlayerId = playerId
        end
    end
    if bestPlayerId == nil then
        return nil, "no_target_selected"
    end

    local currentTargets = self._state:Get("currentTargets") or {}
    local key = ghostId or "default"
    local previousTarget = currentTargets[key]
    currentTargets[key] = bestPlayerId
    self._state:Set("currentTargets", currentTargets)

    local payload = {
        matchId = matchId,
        ghostId = ghostId,
        playerId = bestPlayerId,
        previousTarget = previousTarget,
        mode = selectedMode,
        score = bestScore,
    }

    local history = self._state:Get("targetHistory") or {}
    appendHistory(history, {
        at = os.time(),
        matchId = matchId,
        ghostId = ghostId,
        target = bestPlayerId,
        previousTarget = previousTarget,
        mode = selectedMode,
    })
    self._state:Set("targetHistory", history)

    self:_publish("GhostTargetSelected", payload)
    if previousTarget and previousTarget ~= bestPlayerId then
        self:_publish("GhostTargetChanged", payload)
    end
    return bestPlayerId
end

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._state:ResetForMatch(matchId)
end

function Service:OnHuntTriggered(payload)
    if type(payload) ~= "table" then
        return
    end
    local matchId = payload.matchId or self._state:Get("activeMatchId")
    if type(matchId) ~= "string" then
        return
    end

    local candidatePlayerIds = {}
    if type(payload.players) == "table" then
        for _, player in ipairs(payload.players) do
            local playerId = getPlayerId(player)
            if playerId then
                table.insert(candidatePlayerIds, playerId)
            end
        end
    end

    self:SelectTarget(matchId, payload.ghostId, payload.targetMode, candidatePlayerIds)
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatch = self._state:Get("activeMatchId")
    if activeMatch and matchId and activeMatch ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("currentTargets", {})
    self._state:Set("playerMetrics", {})
end

return Service
