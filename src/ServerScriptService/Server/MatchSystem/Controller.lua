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
    self._handlersRegistered = false
    return self
end

function Controller:Init()
    -- Prepare controller-level wiring here.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end
    if self._handlersRegistered then
        return
    end

    self:_subscribe("ContractSelected", function(payload)
        self:OnContractSelected(payload)
    end)
    self:_subscribe("PlayerQueued", function(payload)
        self:OnPlayerQueued(payload)
    end)
    self:_subscribe("MatchmakingStarted", function(payload)
        self:OnMatchmakingStarted(payload)
    end)
    self:_subscribe("AllEvidenceDiscovered", function(payload)
        self:OnAllEvidenceDiscovered(payload)
    end)
    self:_subscribe("MatchPhaseTransitionRequested", function(payload)
        self:OnMatchPhaseTransitionRequested(payload)
    end)
    self:_subscribe("GhostGuessValidated", function(payload)
        self:OnGhostGuessValidated(payload)
    end)
    self:_subscribe("PlayerDied", function(payload)
        self:OnPlayerDied(payload)
    end)
    self:_subscribe("PlayerExtracted", function(payload)
        self:OnPlayerExtracted(payload)
    end)
    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus then
        return
    end
    if not self._handlersRegistered then
        return
    end

    for _, subscription in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
    end
    table.clear(self._subscriptions)
    self._handlersRegistered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Controller:OnContractSelected(payload)
    local partyId = payload and payload.partyId
    local contractId = payload and payload.contractId
    if not partyId or not contractId then
        return
    end

    self._service:SetContractForParty(partyId, contractId)
end

function Controller:OnPlayerQueued(payload)
    local match = self._service:TryCreateMatchFromQueue(payload)
    if not match then
        return
    end
    task.spawn(function()
        self._service:StartMatch(match.matchId)
    end)
end

function Controller:OnMatchmakingStarted(payload)
    local leader = payload and payload.leader
    if not leader then
        return
    end

    local partyPlayers = payload.players or {}
    local partyMembers = {}
    for _, player in ipairs(partyPlayers) do
        if player ~= leader then
            table.insert(partyMembers, player)
        end
    end

    self._service:JoinQueue(leader, {
        partyId = payload.partyId,
        queueType = payload.queueType
            or (((payload.mode or payload.gameMode) == "Ranked") and "ranked" or "classic"),
        partyMembers = partyMembers,
        mapId = payload.mapId,
        mode = payload.mode or payload.gameMode,
        gameMode = payload.gameMode or payload.mode,
        difficulty = payload.difficulty,
        averageRankScore = payload.averageRankScore,
        playerRankScores = payload.playerRankScores,
        rankedDifficulty = payload.rankedDifficulty,
    })
end

function Controller:OnMatchStarted(payload)
    -- Match phase transitions are orchestrated through GamePhaseSystem requests.
end

function Controller:OnHuntStarted(payload)
    -- Match phase transitions are orchestrated through GamePhaseSystem requests.
end

function Controller:OnAllEvidenceDiscovered(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:EndMatch(matchId, {
        reason = "all_evidence_discovered",
    })
end

function Controller:OnHuntEnded(payload)
    -- Match phase transitions are orchestrated through GamePhaseSystem requests.
end

function Controller:OnMatchPhaseTransitionRequested(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    if payload.endMatch == true then
        self._service:EndMatch(matchId, {
            reason = payload.reason or "phase_flow_completed",
            extractionCompleted = payload.extractionCompleted,
            ghostIdentified = payload.ghostIdentified,
            results = payload.results,
        })
        return
    end

    local nextPhase = payload.nextPhase or payload.phase
    if not nextPhase then
        return
    end

    self._service:AdvanceMatchPhase(matchId, nextPhase)
end

function Controller:OnGhostGuessValidated(payload)
    local matchId = payload and payload.matchId
    if not matchId or payload.correct ~= true or payload.source == "MatchSystem" then
        return
    end
    self:_publish("GhostIdentified", {
        matchId = matchId,
        player = payload.player,
        userId = payload.userId,
        ghostType = payload.actualGhostType,
        guessedGhostType = payload.guessedGhostType,
        source = payload.source or "InvestigationSystem",
        now = payload.validatedAt or payload.now,
    })
end

function Controller:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:EndMatch(matchId, payload.results)
end

function Controller:OnPlayerDied(payload)
    local matchId = payload and payload.matchId
    local userId = payload and (payload.userId or (payload.player and payload.player.UserId))
    if not matchId or not userId then
        return
    end
    self._service:MarkPlayerDeath(matchId, userId, payload.reason, payload)
end

function Controller:OnPlayerExtracted(payload)
    local matchId = payload and payload.matchId
    local userId = payload and (payload.userId or (payload.player and payload.player.UserId))
    if not matchId or not userId then
        return
    end
    self._service:MarkPlayerExtracted(matchId, userId, payload)
end

return Controller


