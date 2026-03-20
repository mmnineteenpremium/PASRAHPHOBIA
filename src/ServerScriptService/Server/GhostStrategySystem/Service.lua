local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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
    if #history > 250 then
        table.remove(history, 1)
    end
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
    self._state:Set("activeStrategies", self._state:Get("activeStrategies") or {})
    self._state:Set("strategyHistory", self._state:Get("strategyHistory") or {})
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

function Service:_definitions()
    return self._state:Get("strategyDefinitions") or {}
end

function Service:_pickRandomStrategy()
    local names = {}
    for name in pairs(self:_definitions()) do
        table.insert(names, name)
    end
    if #names == 0 then
        return nil
    end
    return names[self._rng:NextInteger(1, #names)]
end

function Service:GetStrategy(ghostId)
    local active = self._state:Get("activeStrategies") or {}
    return active[ghostId]
end

function Service:SelectStrategy(ghostId, context)
    if type(ghostId) ~= "string" or ghostId == "" then
        return nil, "invalid_ghost_id"
    end

    context = context or {}
    local averageSanity = clamp(tonumber(context.averageSanity) or 100, 0, 100)
    local aggression = clamp(tonumber(context.aggression) or 0, 0, 100)
    local paranormalRate = clamp(tonumber(context.paranormalRate) or 0, 0, 100)

    local selected = nil
    if aggression >= 75 and averageSanity <= 45 then
        selected = "Ambush"
    elseif aggression >= 60 then
        selected = "TerritoryDefense"
    elseif paranormalRate >= 55 then
        selected = "ChaosInteraction"
    else
        selected = "Stalk"
    end

    local definitions = self:_definitions()
    if definitions[selected] == nil then
        selected = self:_pickRandomStrategy()
    end
    if selected == nil then
        return nil, "no_strategy_definition"
    end

    local active = self._state:Get("activeStrategies") or {}
    local previous = active[ghostId]
    active[ghostId] = selected
    self._state:Set("activeStrategies", active)

    local history = self._state:Get("strategyHistory") or {}
    appendHistory(history, {
        at = os.time(),
        matchId = self._state:Get("activeMatchId"),
        ghostId = ghostId,
        previous = previous,
        strategy = selected,
    })
    self._state:Set("strategyHistory", history)

    local payload = {
        matchId = self._state:Get("activeMatchId"),
        ghostId = ghostId,
        strategy = selected,
        context = context,
        modifiers = definitions[selected],
    }
    self:_publish("GhostStrategySelected", payload)
    if previous and previous ~= selected then
        self:_publish("GhostStrategyChanged", payload)
    end
    return selected
end

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._state:ResetForMatch(matchId)
end

function Service:OnGhostSpawned(payload)
    if type(payload) ~= "table" then
        return
    end
    local ghostId = payload.ghostId or payload.id
    if type(ghostId) ~= "string" then
        return
    end
    self:SelectStrategy(ghostId, payload)
end

function Service:OnHuntTriggered(payload)
    if type(payload) ~= "table" then
        return
    end
    local ghostId = payload.ghostId
    if type(ghostId) ~= "string" then
        return
    end
    self:SelectStrategy(ghostId, {
        averageSanity = payload.averageSanity,
        aggression = (payload.aggression or 0) + 10,
        paranormalRate = payload.paranormalRate,
    })
end

function Service:OnParanormalEvent(payload)
    if type(payload) ~= "table" then
        return
    end
    local ghostId = payload.ghostId
    if type(ghostId) ~= "string" then
        return
    end
    self:SelectStrategy(ghostId, {
        averageSanity = payload.averageSanity,
        aggression = payload.aggression,
        paranormalRate = payload.intensity and (payload.intensity * 100) or 0,
    })
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatch = self._state:Get("activeMatchId")
    if activeMatch and matchId and activeMatch ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("activeStrategies", {})
end

return Service
