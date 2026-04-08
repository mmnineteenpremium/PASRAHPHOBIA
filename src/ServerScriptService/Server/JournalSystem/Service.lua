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

local function pushUnique(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return
        end
    end
    table.insert(list, value)
end

local function copyList(list)
    local out = {}
    for _, item in ipairs(list or {}) do
        table.insert(out, item)
    end
    return out
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
    self._state:Set("playerJournalData", {})
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

function Service:_resolvePlayer(userId)
    if type(userId) ~= "number" then
        return nil
    end

    local ok, players = pcall(function()
        return game:GetService("Players")
    end)
    if not ok or type(players) ~= "userdata" then
        return nil
    end

    local player = players:GetPlayerByUserId(userId)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player
    end
    return nil
end

function Service:_emitUIEvent(eventName, payload)
    self:_publish(eventName, payload)
    self:_sendRemoteEvent(eventName, payload)
end

function Service:_sendRemoteEvent(eventName, payload)
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

function Service:_getOrCreateJournal(userId)
    local playerJournalData = self._state:Get("playerJournalData") or {}
    playerJournalData[userId] = playerJournalData[userId] or {
        discoveredEvidence = {},
        confirmedEvidence = {},
        ghostCandidates = {},
        timeline = {},
        lastUpdatedAt = 0,
    }
    self._state:Set("playerJournalData", playerJournalData)
    return playerJournalData[userId]
end

function Service:_snapshot(userId)
    local journal = self:_getOrCreateJournal(userId)
    return {
        userId = userId,
        matchId = self._state:Get("activeMatchId"),
        discoveredEvidence = copyList(journal.discoveredEvidence),
        confirmedEvidence = copyList(journal.confirmedEvidence),
        ghostCandidates = copyList(journal.ghostCandidates),
        lastUpdatedAt = journal.lastUpdatedAt,
    }
end

function Service:_stampJournalRuntime(player, userId, matchId, journalData, eventName)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        player = self:_resolvePlayer(userId)
    end
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    local snapshot = type(journalData) == "table" and journalData or self:_snapshot(userId)
    local discovered = type(snapshot.discoveredEvidence) == "table" and snapshot.discoveredEvidence or {}
    local confirmed = type(snapshot.confirmedEvidence) == "table" and snapshot.confirmedEvidence or {}
    local candidates = type(snapshot.ghostCandidates) == "table" and snapshot.ghostCandidates or {}

    player:SetAttribute("PasrahJournalOwner", "JournalSystem")
    player:SetAttribute("PasrahJournalMatchId", type(matchId) == "string" and matchId or nil)
    player:SetAttribute("PasrahJournalLastEvent", type(eventName) == "string" and eventName or nil)
    player:SetAttribute("PasrahJournalDiscoveredCount", #discovered)
    player:SetAttribute("PasrahJournalConfirmedCount", #confirmed)
    player:SetAttribute("PasrahJournalCandidateCount", #candidates)
    player:SetAttribute("PasrahJournalDiscoveredList", #discovered > 0 and table.concat(discovered, " | ") or nil)
    player:SetAttribute("PasrahJournalConfirmedList", #confirmed > 0 and table.concat(confirmed, " | ") or nil)
    player:SetAttribute("PasrahJournalCandidateList", #candidates > 0 and table.concat(candidates, " | ") or nil)
    player:SetAttribute("PasrahJournalLastUpdatedAt", tonumber(snapshot.lastUpdatedAt) or nil)
end

function Service:_publishJournalUpdated(userId, player, matchId)
    local journalPayload = {
        player = player or self:_resolvePlayer(userId),
        userId = userId,
        matchId = matchId or self._state:Get("activeMatchId"),
        journalData = self:_snapshot(userId),
    }
    self:_publish("JournalUpdated", {
        userId = userId,
        matchId = journalPayload.matchId,
        journalData = journalPayload.journalData,
    })
    self:_stampJournalRuntime(journalPayload.player, userId, journalPayload.matchId, journalPayload.journalData, "JournalUpdated")
    self:_sendRemoteEvent("JournalUpdated", journalPayload)
end

function Service:_emitEvidenceSnapshot(player, userId, matchId)
    self:_emitUIEvent("UIEvidenceUpdated", {
        player = player,
        userId = userId,
        matchId = matchId or self._state:Get("activeMatchId"),
        discoveredEvidence = copyList(self:_getOrCreateJournal(userId).discoveredEvidence),
        confirmedEvidence = copyList(self:_getOrCreateJournal(userId).confirmedEvidence),
    })
end

function Service:OnMatchStarted(payload)
    if type(payload) ~= "table" then
        return
    end
    self._state:Set("activeMatchId", payload.matchId)
    self._state:Set("playerJournalData", {})
    local players = type(payload.players) == "table" and payload.players or {}
    for _, player in ipairs(players) do
        local userId = toUserId(player)
        if userId then
            self:_stampJournalRuntime(player, userId, payload.matchId, {
                discoveredEvidence = {},
                confirmedEvidence = {},
                ghostCandidates = {},
                lastUpdatedAt = 0,
            }, "MatchStarted")
        end
    end
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if activeMatchId ~= nil and matchId ~= nil and activeMatchId ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("playerJournalData", {})
    local player = payload and payload.player or nil
    local userId = toUserId(player or (payload and payload.userId))
    if userId then
        self:_stampJournalRuntime(player, userId, nil, {
            discoveredEvidence = {},
            confirmedEvidence = {},
            ghostCandidates = {},
            lastUpdatedAt = 0,
        }, "MatchEnded")
    end
end

function Service:OnEvidenceDetected(payload)
    if type(payload) ~= "table" then
        return
    end

    local userId = toUserId(payload.player or payload.userId)
    local evidenceType = payload.evidenceType
    if not userId or type(evidenceType) ~= "string" or evidenceType == "" then
        return
    end

    local journal = self:_getOrCreateJournal(userId)
    pushUnique(journal.discoveredEvidence, evidenceType)
    table.insert(journal.timeline, {
        type = "EvidenceDetected",
        evidenceType = evidenceType,
        toolType = payload.toolType,
        at = os.clock(),
    })
    journal.lastUpdatedAt = os.clock()

    self:_publish("EvidenceLogged", {
        player = payload.player,
        userId = userId,
        matchId = payload.matchId or self._state:Get("activeMatchId"),
        evidenceType = evidenceType,
        toolType = payload.toolType,
        confirmed = false,
        discoveredEvidence = copyList(journal.discoveredEvidence),
        confirmedEvidence = copyList(journal.confirmedEvidence),
    })
    self:_publishJournalUpdated(userId, payload.player, payload.matchId)
    self:_emitEvidenceSnapshot(payload.player, userId, payload.matchId)
end

function Service:OnEvidenceValidated(payload)
    if type(payload) ~= "table" or payload.validated ~= true then
        return
    end

    local userId = toUserId(payload.player or payload.userId)
    local evidenceType = payload.evidenceType
    if not userId or type(evidenceType) ~= "string" or evidenceType == "" then
        return
    end

    local journal = self:_getOrCreateJournal(userId)
    pushUnique(journal.discoveredEvidence, evidenceType)
    pushUnique(journal.confirmedEvidence, evidenceType)
    table.insert(journal.timeline, {
        type = "EvidenceValidated",
        evidenceType = evidenceType,
        validated = true,
        at = os.clock(),
    })
    journal.lastUpdatedAt = os.clock()

    self:_publishJournalUpdated(userId, payload.player, payload.matchId)
    self:_emitEvidenceSnapshot(payload.player, userId, payload.matchId)
end

function Service:OnEvidenceCollected(payload)
    if type(payload) ~= "table" then
        return
    end

    local userId = toUserId(payload.player or payload.userId)
    local evidenceType = payload.evidenceType
    if not userId or type(evidenceType) ~= "string" or evidenceType == "" then
        return
    end

    local journal = self:_getOrCreateJournal(userId)
    pushUnique(journal.discoveredEvidence, evidenceType)
    pushUnique(journal.confirmedEvidence, evidenceType)
    table.insert(journal.timeline, {
        type = "EvidenceCollected",
        evidenceType = evidenceType,
        toolType = payload.toolType,
        at = os.clock(),
    })
    journal.lastUpdatedAt = os.clock()

    self:_publishJournalUpdated(userId, payload.player, payload.matchId)
    self:_emitEvidenceSnapshot(payload.player, userId, payload.matchId)
end

function Service:OnGhostCandidatesUpdated(payload)
    if type(payload) ~= "table" then
        return
    end

    local candidates = payload.candidates or payload.possibleGhosts
    if type(candidates) ~= "table" then
        return
    end

    local userId = toUserId(payload.player or payload.userId)
    if userId then
        local journal = self:_getOrCreateJournal(userId)
        journal.ghostCandidates = copyList(candidates)
        journal.lastUpdatedAt = os.clock()
        self:_publishJournalUpdated(userId, payload.player, payload.matchId)
        return
    end

    local journals = self._state:Get("playerJournalData") or {}
    for journalUserId, journal in pairs(journals) do
        journal.ghostCandidates = copyList(candidates)
        journal.lastUpdatedAt = os.clock()
        self:_publishJournalUpdated(journalUserId)
    end
end

return Service
