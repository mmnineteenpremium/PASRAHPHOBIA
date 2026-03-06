local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = deps and deps.EventBus
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
    self._eventBus = resolveEventBus(self._deps)
    self._subscriptions = {}
    return self
end

function Controller:Init()
    -- Event wiring only.
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
    self:_subscribe("GhostSpawned", function(payload)
        self:OnGhostSpawned(payload)
    end)
    self:_subscribe("EvidenceCollected", function(payload)
        self:OnEvidenceCollected(payload)
    end)
    self:_subscribe("GhostGuessSubmitted", function(payload)
        self:OnGhostGuessSubmitted(payload)
    end)
    self:_subscribe("InvestigationGhostGuessSubmitted", function(payload)
        self:OnGhostGuessSubmitted(payload)
    end)
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus then
        return
    end
    for _, sub in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(sub.eventName, sub.callback)
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
    self._service:EndMatch(matchId, payload)
end

function Controller:OnGhostSpawned(payload)
    local matchId = payload and payload.matchId
    local ghostType = payload and payload.ghostType
    if not matchId or not ghostType then
        return
    end
    self._service:SetGhostType(matchId, ghostType, payload and payload.now)
end

function Controller:OnEvidenceCollected(payload)
    local player = payload and payload.player
    local matchId = payload and payload.matchId
    local evidenceType = payload and payload.evidenceType
    if not player or not matchId or not evidenceType then
        return
    end
    self._service:RecordEvidenceDiscovered(player, matchId, evidenceType, payload)
end

function Controller:OnGhostGuessSubmitted(payload)
    if payload and payload.source == "InvestigationSystem" then
        return
    end
    local player = payload and payload.player
    local matchId = payload and payload.matchId
    local guessedGhostType = payload and (payload.guessedGhostType or payload.ghostType)
    if not player or not matchId or not guessedGhostType then
        return
    end
    self._service:SubmitGhostGuess(player, matchId, guessedGhostType, payload)
end

return Controller
