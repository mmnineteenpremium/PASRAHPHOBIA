local InvestigationState = require(script.Parent.InvestigationState.InvestigationState)
local EvidenceTracker = require(script.Parent.EvidenceTracker.EvidenceTracker)
local GhostGuess = require(script.Parent.GhostGuess.GhostGuess)

local Service = {}
Service.__index = Service

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function getByPath(root, path)
    local node = root
    for _, segment in ipairs(path) do
        if typeof(node) ~= "Instance" then
            return nil
        end
        node = node:FindFirstChild(segment)
        if not node then
            return nil
        end
    end
    return node
end

local function resolveGhostEvidenceMap(deps)
    if type(deps) == "table" and type(deps.GhostEvidenceMap) == "table" then
        return deps.GhostEvidenceMap
    end
    if type(deps) == "table" and type(deps.SharedDataTypes) == "table" and type(deps.SharedDataTypes.GhostEvidenceMap) == "table" then
        return deps.SharedDataTypes.GhostEvidenceMap
    end

    local cursor = script
    while cursor do
        local shared = cursor:FindFirstChild("shared") or cursor:FindFirstChild("Shared")
        if shared then
            local mapPaths = {
                { "DataTypes", "Ghosts", "GhostEvidenceMap", "ModuleScript" },
                { "DataTypes", "Evidence", "EvidenceGhostMap", "ModuleScript" },
            }
            for _, path in ipairs(mapPaths) do
                local moduleScript = getByPath(shared, path)
                local map = safeRequire(moduleScript)
                if type(map) == "table" then
                    return map
                end
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        local shared = replicatedStorage:FindFirstChild("shared") or replicatedStorage:FindFirstChild("Shared")
        if shared then
            local mapPaths = {
                { "DataTypes", "Ghosts", "GhostEvidenceMap", "ModuleScript" },
                { "DataTypes", "Evidence", "EvidenceGhostMap", "ModuleScript" },
            }
            for _, path in ipairs(mapPaths) do
                local moduleScript = getByPath(shared, path)
                local map = safeRequire(moduleScript)
                if type(map) == "table" then
                    return map
                end
            end
        end
    end

    return {}
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
    self._stateDriver = InvestigationState.new()
    self._evidenceTracker = EvidenceTracker.new()
    self._ghostGuess = GhostGuess.new(resolveGhostEvidenceMap(self._deps))
    return self
end

function Service:Init()
    self._state:Set("matches", {})
end

function Service:Start()
    -- Event-driven investigation updates.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_matches()
    return self._state:Get("matches") or {}
end

function Service:_setMatches(matches)
    self._state:Set("matches", matches)
end

function Service:_ensureMatch(matchId, now)
    local matches = self:_matches()
    local wasMissing = matches[matchId] == nil
    local state = self._stateDriver:EnsureMatch(matches, matchId, now)
    if wasMissing then
        state.possibleGhostTypes = self._ghostGuess:GetAllGhostTypes()
    end
    self:_setMatches(matches)
    return state
end

function Service:StartMatch(matchId, payload)
    if not matchId then
        return nil, "invalid_match"
    end
    return self:_ensureMatch(matchId, payload and payload.now)
end

function Service:EndMatch(matchId, payload)
    local matches = self:_matches()
    local matchState = matches[matchId]
    if not matchState then
        return nil
    end

    local validations = {}
    for userId in pairs(matchState.latestGuessByUserId or {}) do
        local ok, _, result = self._ghostGuess:ValidateGuess(matchState, userId, payload and payload.now)
        if ok and result then
            table.insert(validations, result)
        end
    end

    local matchResult = {
        source = "InvestigationSystem",
        matchId = matchId,
        actualGhostType = matchState.ghostType,
        discoveredEvidence = self._evidenceTracker:GetEvidenceList(matchState),
        possibleGhostTypes = matchState.possibleGhostTypes,
        guessValidations = validations,
        at = payload and payload.now or os.clock(),
    }
    self:_publish("InvestigationMatchResultPublished", matchResult)
    self:_publish("MatchResultPublished", matchResult)

    matches[matchId] = nil
    self:_setMatches(matches)
    return matchResult
end

function Service:SetGhostType(matchId, ghostType, now)
    local matchState = self:_ensureMatch(matchId, now)
    matchState.ghostType = ghostType
end

function Service:RecordEvidenceDiscovered(player, matchId, evidenceType, payload)
    if not matchId or type(evidenceType) ~= "string" then
        return false, "invalid_evidence"
    end
    local matchState = self:_ensureMatch(matchId, payload and payload.now)
    local isNew = self._evidenceTracker:Record(matchState, player, evidenceType, payload and payload.now)
    local possible = self._ghostGuess:ResolvePossibleGhostTypes(matchState.discoveredEvidence)
    matchState.possibleGhostTypes = possible

    local userId = toUserId(player)
    self:_publish("EvidenceDiscovered", {
        source = "InvestigationSystem",
        player = player,
        userId = userId,
        matchId = matchId,
        evidenceType = evidenceType,
        isNew = isNew,
        discoveredEvidence = self._evidenceTracker:GetEvidenceList(matchState),
        possibleGhostTypes = possible,
        discoverers = self._evidenceTracker:GetDiscoverers(matchState, evidenceType),
        now = payload and payload.now,
    })
    self:_publish("InvestigationProgressUpdated", {
        source = "InvestigationSystem",
        matchId = matchId,
        player = player,
        userId = userId,
        discoveredEvidence = self._evidenceTracker:GetEvidenceList(matchState),
        possibleGhostTypes = possible,
        evidenceCount = #self._evidenceTracker:GetEvidenceList(matchState),
        now = payload and payload.now,
    })

    return true, nil, {
        isNew = isNew,
        possibleGhostTypes = possible,
    }
end

function Service:SubmitGhostGuess(player, matchId, guessedGhostType, payload)
    if not matchId then
        return false, "invalid_match"
    end
    local matchState = self:_ensureMatch(matchId, payload and payload.now)
    local ok, err, guessEntry = self._ghostGuess:SubmitGuess(matchState, player, guessedGhostType, payload and payload.now)
    if not ok then
        return false, err
    end

    local userId = toUserId(player)
    self:_publish("GhostGuessSubmitted", {
        source = "InvestigationSystem",
        player = player,
        userId = userId,
        matchId = matchId,
        guessedGhostType = guessedGhostType,
        submittedAt = guessEntry and guessEntry.submittedAt,
    })

    local validOk, validErr, validation = self._ghostGuess:ValidateGuess(matchState, player, payload and payload.now)
    if validOk then
        self:_publish("GhostGuessValidated", {
            source = "InvestigationSystem",
            player = player,
            userId = userId,
            matchId = matchId,
            guessedGhostType = validation.guessedGhostType,
            actualGhostType = validation.actualGhostType,
            correct = validation.correct,
            validatedAt = validation.validatedAt,
        })
    end

    self:_publish("InvestigationProgressUpdated", {
        source = "InvestigationSystem",
        matchId = matchId,
        player = player,
        userId = userId,
        guessedGhostType = guessedGhostType,
        ghostGuessCorrect = validOk and validation and validation.correct or false,
        possibleGhostTypes = matchState.possibleGhostTypes,
        now = payload and payload.now,
    })

    return true, validErr, validation
end

return Service
