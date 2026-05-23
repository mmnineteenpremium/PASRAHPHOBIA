local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function resolveMatchRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end
    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    local remote = remoteFolder and remoteFolder:FindFirstChild("MatchEvent")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
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

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    self._matchRemote = nil
    return self
end

local function stampMatchResultRuntime(target, payload)
    if typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end
    target:SetAttribute("PasrahMatchResultOwner", "MatchResultSystem")
    target:SetAttribute("PasrahMatchResultMatchId", type(payload.matchId) == "string" and payload.matchId or nil)
    target:SetAttribute("PasrahMatchResultGhostType", type(payload.ghostType) == "string" and payload.ghostType or nil)
    target:SetAttribute("PasrahMatchResultGuessedGhostType", type(payload.guessedGhostType) == "string" and payload.guessedGhostType or nil)
    target:SetAttribute("PasrahMatchResultGuessedEvidence", type(payload.guessedEvidenceText) == "string" and payload.guessedEvidenceText or nil)
    target:SetAttribute("PasrahMatchResultExpectedEvidence", type(payload.expectedEvidenceText) == "string" and payload.expectedEvidenceText or nil)
    target:SetAttribute("PasrahMatchResultCorrectGuess", payload.correctGuess == true)
    target:SetAttribute("PasrahMatchResultGhostIdentified", payload.ghostIdentified == true)
    target:SetAttribute("PasrahMatchResultEvidenceCollected", tonumber(payload.evidenceCollected) or 0)
    target:SetAttribute("PasrahMatchResultPlayersSurvived", tonumber(payload.playersSurvived) or 0)
    target:SetAttribute("PasrahMatchResultPlayersDead", tonumber(payload.playersDead) or 0)
    target:SetAttribute("PasrahMatchResultPlayersExtracted", tonumber(payload.playersExtracted) or 0)
    target:SetAttribute("PasrahMatchResultContractSuccess", payload.contractSuccess == true)
    target:SetAttribute("PasrahMatchResultTeamSuccess", payload.teamSuccess == true)
    target:SetAttribute("PasrahMatchResultExtractionCompleted", payload.extractionCompleted == true)
    target:SetAttribute("PasrahMatchResultDuration", tonumber(payload.matchDuration) or 0)
    target:SetAttribute("PasrahMatchResultLastEvent", type(payload.lastEvent) == "string" and payload.lastEvent or nil)
    target:SetAttribute("PasrahMatchResultLastUpdatedAt", tonumber(payload.updatedAt) or os.clock())
end

local function listToText(list)
    if type(list) ~= "table" or #list == 0 then
        return nil
    end
    local out = {}
    for _, value in ipairs(list) do
        if type(value) == "string" and value ~= "" then
            table.insert(out, value)
        end
    end
    if #out == 0 then
        return nil
    end
    return table.concat(out, " | ")
end

function Service:Init()
    self._dependencies = {
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
    self._state:Set("activeMatchId", self._state:Get("activeMatchId"))
    self._state:Set("playerOutcome", self._state:Get("playerOutcome") or {})
    self._state:Set("teamEvidenceCount", self._state:Get("teamEvidenceCount") or 0)
    self._state:Set("ghostType", self._state:Get("ghostType"))
    self._state:Set("ghostIdentified", self._state:Get("ghostIdentified") or false)
    self._state:Set("correctGuess", self._state:Get("correctGuess") or false)
    self._state:Set("contractSuccess", self._state:Get("contractSuccess") or false)
end

function Service:Start()
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_fireMatchEventToPlayers(players, payload)
    if type(payload) ~= "table" then
        return
    end

    local remote = self._matchRemote
    if not remote then
        remote = resolveMatchRemote()
        self._matchRemote = remote
    end
    if not remote then
        return
    end

    local sentByUserId = {}
    for _, player in ipairs(players or {}) do
        if typeof(player) == "Instance" and player:IsA("Player") and not sentByUserId[player.UserId] then
            sentByUserId[player.UserId] = true
            remote:FireClient(player, payload)
        end
    end
end

function Service:_collectPlayers(payload, result)
    local players = {}
    local addedByUserId = {}

    local function addPlayer(player)
        if typeof(player) ~= "Instance" or not player:IsA("Player") or addedByUserId[player.UserId] then
            return
        end
        addedByUserId[player.UserId] = true
        table.insert(players, player)
    end

    for _, player in ipairs((payload and payload.players) or {}) do
        addPlayer(player)
    end

    for _, entry in pairs((result and result.playerOutcome) or {}) do
        addPlayer(entry and entry.player)
    end

    return players
end

function Service:_matchId(payload)
    return payload and payload.matchId or self._state:Get("activeMatchId")
end

function Service:_getOutcome()
    return self._state:Get("playerOutcome") or {}
end

function Service:_setOutcome(outcome)
    self._state:Set("playerOutcome", outcome)
end

function Service:_registerPlayers(players)
    local outcome = self:_getOutcome()
    for _, player in ipairs(players or {}) do
        local userId = toUserId(player)
        if userId and outcome[userId] == nil then
            outcome[userId] = {
                survived = true,
                extracted = false,
                evidenceCount = 0,
                player = player,
            }
        end
        if typeof(player) == "Instance" and player:IsA("Player") then
            stampMatchResultRuntime(player, {
                matchId = self._state:Get("activeMatchId"),
                ghostType = self._state:Get("ghostType"),
                correctGuess = self._state:Get("correctGuess"),
                ghostIdentified = self._state:Get("ghostIdentified"),
                evidenceCollected = self._state:Get("teamEvidenceCount") or 0,
                playersSurvived = 0,
                playersDead = 0,
                playersExtracted = 0,
                contractSuccess = self._state:Get("contractSuccess"),
                teamSuccess = false,
                extractionCompleted = false,
                matchDuration = 0,
                lastEvent = "MatchStarted",
                updatedAt = os.clock(),
            })
        end
    end
    self:_setOutcome(outcome)
end

function Service:_markPlayerState(payload, update)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end

    local outcome = self:_getOutcome()
    outcome[userId] = outcome[userId] or {
        survived = true,
        extracted = false,
        evidenceCount = 0,
        player = payload and payload.player,
    }
    for key, value in pairs(update) do
        outcome[userId][key] = value
    end
    if payload and payload.player then
        outcome[userId].player = payload.player
    end
    self:_setOutcome(outcome)
end

function Service:_countSummary(outcome)
    local survived = 0
    local dead = 0
    local extracted = 0
    local totalEvidence = 0

    for _, entry in pairs(outcome or {}) do
        if entry.survived ~= false then
            survived += 1
        else
            dead += 1
        end
        if entry.extracted == true then
            extracted += 1
        end
        totalEvidence += tonumber(entry.evidenceCount) or 0
    end

    return survived, dead, extracted, totalEvidence
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        self._state:Set("activeMatchId", matchId)
        self._state:Set("playerOutcome", {})
        self._state:Set("teamEvidenceCount", 0)
        self._state:Set("ghostType", nil)
        self._state:Set("ghostIdentified", false)
        self._state:Set("correctGuess", false)
        self._state:Set("contractSuccess", false)
        self._state:Set("guessedGhostType", nil)
        self._state:Set("guessedEvidence", nil)
        self._state:Set("expectedEvidence", nil)
        self._state:Set("matchStartedAt", os.clock())
        self:_registerPlayers(payload and payload.players or {})
        return
    end

    if eventName == "MatchEnded" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end

        local outcome = self:_getOutcome()
        local survived, dead, extracted, evidenceTotal = self:_countSummary(outcome)
        local results = payload and payload.results or {}
        local matchDuration = tonumber(results.matchDuration)
            or math.max(0, math.floor(os.clock() - (self._state:Get("matchStartedAt") or os.clock())))

        local result = {
            matchId = matchId,
            ghostType = results.ghostType or self._state:Get("ghostType") or "Unknown",
            correctGuess = (results.correctGuess == true) or (self._state:Get("correctGuess") == true),
            ghostIdentified = (results.ghostIdentified == true) or (self._state:Get("ghostIdentified") == true),
            evidenceCollected = tonumber(results.evidenceCollected) or self._state:Get("teamEvidenceCount") or evidenceTotal,
            playerOutcome = results.playerOutcome or outcome,
            playersSurvived = tonumber(results.playersSurvived) or survived,
            playersDead = tonumber(results.playersDead) or dead,
            playersExtracted = tonumber(results.playersExtracted) or extracted,
            contractSuccess = (results.contractSuccess == true) or (self._state:Get("contractSuccess") == true),
            teamSuccess = (results.teamSuccess == true)
                or (results.contractSuccess == true)
                or (self._state:Get("contractSuccess") == true)
                or (results.extractionCompleted == true),
            extractionCompleted = results.extractionCompleted == true or extracted > 0,
            matchDuration = matchDuration,
            guessedGhostType = results.guessedGhostType or self._state:Get("guessedGhostType"),
            guessedEvidence = results.guessedEvidence or self._state:Get("guessedEvidence"),
            expectedEvidence = results.expectedEvidence or self._state:Get("expectedEvidence"),
        }
        result.guessedEvidenceText = listToText(result.guessedEvidence)
        result.expectedEvidenceText = listToText(result.expectedEvidence)

        self._state:Set("lastResult", result)
        for _, player in ipairs(self:_collectPlayers(payload, result)) do
            if typeof(player) == "Instance" and player:IsA("Player") then
                stampMatchResultRuntime(player, {
                    matchId = result.matchId,
                    ghostType = result.ghostType,
                    guessedGhostType = result.guessedGhostType,
                    guessedEvidenceText = result.guessedEvidenceText,
                    expectedEvidenceText = result.expectedEvidenceText,
                    correctGuess = result.correctGuess,
                    ghostIdentified = result.ghostIdentified,
                    evidenceCollected = result.evidenceCollected,
                    playersSurvived = result.playersSurvived,
                    playersDead = result.playersDead,
                    playersExtracted = result.playersExtracted,
                    contractSuccess = result.contractSuccess,
                    teamSuccess = result.teamSuccess,
                    extractionCompleted = result.extractionCompleted,
                    matchDuration = result.matchDuration,
                    lastEvent = "MatchEnded",
                    updatedAt = os.clock(),
                })
            end
        end
        self:_publish("MatchCompleted", result)
        self:_fireMatchEventToPlayers(self:_collectPlayers(payload, result), {
            eventName = "MatchCompleted",
            matchId = result.matchId,
            ghostType = result.ghostType,
            guessedGhostType = result.guessedGhostType,
            guessedEvidence = result.guessedEvidence,
            expectedEvidence = result.expectedEvidence,
            correctGuess = result.correctGuess,
            ghostIdentified = result.ghostIdentified,
            evidenceCollected = result.evidenceCollected,
            playersSurvived = result.playersSurvived,
            playersDead = result.playersDead,
            playersExtracted = result.playersExtracted,
            contractSuccess = result.contractSuccess,
            teamSuccess = result.teamSuccess,
            extractionCompleted = result.extractionCompleted,
            matchDuration = result.matchDuration,
            playerOutcome = result.playerOutcome,
        })
        return
    end

    if eventName == "PlayerDied" then
        self:_markPlayerState(payload, {
            survived = false,
            extracted = false,
            deathReason = payload and payload.reason or "unknown",
        })
        return
    end

    if eventName == "PlayerExtracted" then
        self:_markPlayerState(payload, {
            extracted = true,
        })
        return
    end

    if eventName == "EvidenceCollected" then
        self._state:Set("teamEvidenceCount", (self._state:Get("teamEvidenceCount") or 0) + 1)
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local outcome = self:_getOutcome()
            outcome[userId] = outcome[userId] or {
                survived = true,
                extracted = false,
                evidenceCount = 0,
                player = payload and payload.player,
            }
            outcome[userId].evidenceCount = (outcome[userId].evidenceCount or 0) + 1
            self:_setOutcome(outcome)
        end
        return
    end

    if eventName == "GhostGuessValidated" then
        if payload and type(payload.guessedGhostType) == "string" and payload.guessedGhostType ~= "" then
            self._state:Set("guessedGhostType", payload.guessedGhostType)
        end
        if payload and type(payload.guessedEvidence) == "table" then
            self._state:Set("guessedEvidence", payload.guessedEvidence)
        end
        if payload and type(payload.expectedEvidence) == "table" then
            self._state:Set("expectedEvidence", payload.expectedEvidence)
        end
        if payload and payload.correct == true then
            self._state:Set("correctGuess", true)
            self._state:Set("ghostIdentified", true)
            self._state:Set("ghostType", payload.actualGhostType or payload.ghostType)
        end
        return
    end

    if eventName == "GhostIdentified" then
        self._state:Set("ghostIdentified", true)
        self._state:Set("ghostType", payload and payload.ghostType or self._state:Get("ghostType"))
        return
    end

    if eventName == "ContractCompletionEvaluated" then
        self._state:Set("contractSuccess", payload and payload.contractSuccess == true)
    end
end

return Service
