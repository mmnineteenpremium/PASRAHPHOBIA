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
    self._eventBus = resolveEventBus(self._deps)
    self._subscriptions = {}
    self._handlersRegistered = false
    return self
end

function Controller:Init()
    -- Event subscriptions only.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._handlersRegistered then
        return
    end

    self:_subscribe("ContractBoardRequested", function(payload)
        self:OnContractBoardRequested(payload)
    end)
    self:_subscribe("ContractSelectionRequested", function(payload)
        self:OnContractSelectionRequested(payload)
    end)
    self:_subscribe("MatchCreated", function(payload)
        self:OnMatchCreated(payload)
    end)
    self:_subscribe("MatchStarted", function(payload)
        self:OnMatchStarted(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
    end)
    self:_subscribe("GhostSpawned", function(payload)
        self:OnGhostSpawned(payload)
    end)
    self:_subscribe("GhostRoamed", function(payload)
        self:OnGhostRoamed(payload)
    end)
    self:_subscribe("EvidenceDetected", function(payload)
        self:OnEvidenceDetected(payload)
    end)
    self:_subscribe("EvidenceCollected", function(payload)
        self:OnEvidenceCollected(payload)
    end)
    self:_subscribe("GhostIdentified", function(payload)
        self:OnGhostIdentified(payload)
    end)
    self:_subscribe("HuntStarted", function(payload)
        self:OnHuntStarted(payload)
    end)
    self:_subscribe("HuntEnded", function(payload)
        self:OnHuntEnded(payload)
    end)
    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus or not self._handlersRegistered then
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

function Controller:OnContractBoardRequested(payload)
    local lobbyId = payload and payload.lobbyId
    local count = payload and payload.count
    self._service:GenerateBoard(lobbyId, count, payload)
end

function Controller:OnContractSelectionRequested(payload)
    local partyId = payload and payload.partyId
    local contractId = payload and payload.contractId
    if not partyId or not contractId then
        return
    end
    self._service:SelectContract(partyId, contractId, payload and payload.player)
end

function Controller:OnMatchCreated(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:BindMatchFromParties(matchId, payload.partyIds)
end

function Controller:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:StartMatchSession(matchId, payload)
end

function Controller:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:EndMatchSession(matchId, payload)
end

function Controller:OnGhostSpawned(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:SetGhostRoom(matchId, payload.favoriteRoomId)
end

function Controller:OnGhostRoamed(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:SetGhostRoom(matchId, payload.room)
end

function Controller:OnEvidenceDetected(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessSignal(matchId, "evidence_detected", payload)
    if payload and payload.toolType then
        self._service:ProcessSignal(matchId, "tool_used", payload)
    end
end

function Controller:OnEvidenceCollected(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:ProcessSignal(matchId, "evidence_detected", payload)
    if payload and payload.toolType then
        self._service:ProcessSignal(matchId, "tool_used", payload)
    end

    if payload and (payload.nearGhostRoom == true or payload.toolNearGhostRoom == true) then
        self._service:ProcessSignal(matchId, "ghost_room_found", payload)
    end
end

function Controller:OnGhostIdentified(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:ProcessSignal(matchId, "ghost_identified", {
        identified = true,
        now = payload.now,
    })
end

function Controller:OnHuntStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:ProcessSignal(matchId, "hunt_started", payload)
end

function Controller:OnHuntEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:ProcessSignal(matchId, "hunt_ended", payload)
end

return Controller
