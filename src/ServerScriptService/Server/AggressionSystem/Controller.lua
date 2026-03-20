local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Subscribe) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then
        return eventBus.Service
    end
    return nil
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._subscriptions = {}
    self._eventBus = resolveEventBus(self._deps)
    return self
end

function Controller:Init()
    -- Prepare controller-level wiring here.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    self:_subscribe("MatchStarted", function(payload)
        self:OnMatchStarted(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
    end)
    self:_subscribe("TeamSanityLow", function(payload)
        self:OnTeamSanityLow(payload)
    end)
    self:_subscribe("SanityCritical", function(payload)
        self:OnSanityCritical(payload)
    end)
    self:_subscribe("GhostInteraction", function(payload)
        self:OnGhostInteraction(payload)
    end)
    self:_subscribe("GhostRoamed", function(payload)
        self:OnGhostRoamed(payload)
    end)
    self:_subscribe("EvidenceValidated", function(payload)
        self:OnEvidenceValidated(payload)
    end)
    self:_subscribe("PhaseStarted", function(payload)
        self:OnPhaseStarted(payload)
    end)
    self:_subscribe("SpectatorHint", function(payload)
        self:OnSpectatorHint(payload)
    end)
    self:_subscribe("TensionIncreased", function(payload)
        self:OnTensionIncreased(payload)
    end)
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus then
        return
    end
    for _, subscription in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
    end
    table.clear(self._subscriptions)
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:StartMatch(matchId, payload)
end

function Controller:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:EndMatch(matchId)
end
function Controller:OnTeamSanityLow(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:IncreaseAggression(matchId, 3.0, "low_team_sanity", payload)
    self._service:CheckHuntTrigger(matchId, {
        averageSanity = payload.averageSanity,
    })
end

function Controller:OnSanityCritical(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:IncreaseAggression(matchId, 2.5, "critical_sanity", payload)
    self._service:CheckHuntTrigger(matchId, payload)
end
function Controller:OnGhostInteraction(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:IncreaseAggression(matchId, 1.5, "ghost_interaction_frequency", payload)
end
function Controller:OnPhaseStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    local phaseName = payload.phaseName
    if phaseName == "Investigation" or phaseName == "InvestigationPhase" then
        self._service:RecordInvestigationTime(matchId, payload.dt or 5)
        local silenceSeconds = payload.silenceSeconds
            or (payload.snapshot and payload.snapshot.silenceSeconds)
            or 0
        self._service:RecordLongSilence(matchId, silenceSeconds)
    end
end

function Controller:OnGhostRoamed(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:IncreaseAggression(matchId, 0.8, "player_proximity_to_ghost", payload)
end

function Controller:OnEvidenceValidated(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    if payload.validated == false then
        self._service:IncreaseAggression(matchId, 1.25, "failed_evidence_attempt", payload)
    end
end

function Controller:OnSpectatorHint(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:IncreaseAggression(matchId, 0.9, "spectator_hint", payload)
end

function Controller:OnTensionIncreased(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    local delta = payload.delta or 0
    self._service:IncreaseAggression(matchId, math.max(0, delta) * 0.35, "horror_director_tension", payload)
end
return Controller

