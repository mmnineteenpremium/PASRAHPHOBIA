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

local function toUserId(player)
    if type(player) == "number" then
        return player
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function addUnique(list, value)
    if not contains(list, value) then
        table.insert(list, value)
    end
end

local function copyList(list)
    local out = {}
    for _, item in ipairs(list or {}) do
        table.insert(out, item)
    end
    return out
end

local function inferGhostDatabase(deps)
    local investigationSystem = Services.Get(deps, "InvestigationSystem")
    if type(investigationSystem) == "table" and type(investigationSystem.State) == "table" then
        if type(investigationSystem.State.Get) == "function" then
            local map = investigationSystem.State:Get("ghostDatabase")
            if type(map) == "table" and next(map) ~= nil then
                return map
            end
        end
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._evidenceRemote = nil
    self._dependencies = {}
    return self
end

function Service:Init()
    self._dependencies = {
        EvidenceSystem = Services.Get(self._deps, "EvidenceSystem"),
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
    }

    local inferred = inferGhostDatabase(self._deps)
    if type(inferred) == "table" and next(inferred) ~= nil then
        self._state:Set("ghostEvidenceMap", inferred)
    end

    self._state:Set("playerJournalData", {})
    self._state:Set("ghostCandidatesByPlayer", {})
    self._state:Set("activeMatchId", nil)
    self._evidenceRemote = self:_resolveEvidenceRemote()
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

function Service:_resolveEvidenceRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end
    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    local remote = remoteFolder and remoteFolder:FindFirstChild("EvidenceEvent")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

function Service:_emitUIEvent(eventName, payload)
    self:_publish(eventName, payload)
    if not self._evidenceRemote then
        return
    end
    local message = {
        eventName = eventName,
    }
    for key, value in pairs(payload or {}) do
        message[key] = value
    end
    if payload and payload.player and typeof(payload.player) == "Instance" and payload.player:IsA("Player") then
        self._evidenceRemote:FireClient(payload.player, message)
        return
    end
    self._evidenceRemote:FireAllClients(message)
end

function Service:_getOrCreatePlayerJournal(userId)
    local journals = self._state:Get("playerJournalData") or {}
    journals[userId] = journals[userId] or {
        discoveredEvidence = {},
        ghostCandidates = {},
        lastUpdatedAt = 0,
    }
    self._state:Set("playerJournalData", journals)
    return journals[userId]
end

function Service:_computeCandidates(discoveredEvidence)
    local evidenceList = discoveredEvidence or {}
    local ghostEvidenceMap = self._state:Get("ghostEvidenceMap") or {}
    local candidates = {}

    for ghostType, requiredEvidence in pairs(ghostEvidenceMap) do
        local matches = true
        for _, evidenceType in ipairs(evidenceList) do
            if not contains(requiredEvidence, evidenceType) then
                matches = false
                break
            end
        end
        if matches then
            table.insert(candidates, ghostType)
        end
    end

    table.sort(candidates)
    return candidates
end

function Service:_publishCandidateUpdates(userId, player, matchId, discoveredEvidence, candidates)
    self:_emitUIEvent("UIGhostPredictionUpdated", {
        userId = userId,
        player = player,
        matchId = matchId or self._state:Get("activeMatchId"),
        discoveredEvidence = copyList(discoveredEvidence),
        candidates = copyList(candidates),
    })
end

function Service:OnMatchStarted(payload)
    if type(payload) ~= "table" then
        return
    end
    self._state:Set("activeMatchId", payload.matchId)
    self._state:Set("playerJournalData", {})
    self._state:Set("ghostCandidatesByPlayer", {})
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if activeMatchId ~= nil and matchId ~= nil and activeMatchId ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("playerJournalData", {})
    self._state:Set("ghostCandidatesByPlayer", {})
end

function Service:OnEvidenceLogged(payload)
    if type(payload) ~= "table" then
        return
    end

    local userId = toUserId(payload.player or payload.userId)
    local evidenceType = payload.evidenceType
    if not userId or type(evidenceType) ~= "string" or evidenceType == "" then
        return
    end

    local journal = self:_getOrCreatePlayerJournal(userId)
    addUnique(journal.discoveredEvidence, evidenceType)
    journal.lastUpdatedAt = os.clock()

    local candidates = self:_computeCandidates(journal.discoveredEvidence)
    journal.ghostCandidates = candidates

    local candidateState = self._state:Get("ghostCandidatesByPlayer") or {}
    candidateState[userId] = copyList(candidates)
    self._state:Set("ghostCandidatesByPlayer", candidateState)

    self:_publishCandidateUpdates(
        userId,
        payload.player,
        payload.matchId,
        journal.discoveredEvidence,
        candidates
    )
end

function Service:OnJournalUpdated(payload)
    if type(payload) ~= "table" or type(payload.journalData) ~= "table" then
        return
    end
    local userId = toUserId(payload.player or payload.userId)
    if not userId then
        return
    end

    local discoveredEvidence = payload.journalData.discoveredEvidence or {}
    local candidates = self:_computeCandidates(discoveredEvidence)

    local journal = self:_getOrCreatePlayerJournal(userId)
    journal.discoveredEvidence = copyList(discoveredEvidence)
    journal.ghostCandidates = copyList(candidates)
    journal.lastUpdatedAt = os.clock()

    local candidateState = self._state:Get("ghostCandidatesByPlayer") or {}
    candidateState[userId] = copyList(candidates)
    self._state:Set("ghostCandidatesByPlayer", candidateState)

    self:_publishCandidateUpdates(
        userId,
        payload.player,
        payload.matchId,
        discoveredEvidence,
        candidates
    )
end

return Service
