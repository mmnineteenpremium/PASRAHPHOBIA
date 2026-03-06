local GhostGuess = {}
GhostGuess.__index = GhostGuess

local function normalizeEvidence(evidenceType)
    if type(evidenceType) ~= "string" then
        return nil
    end
    return evidenceType:gsub("%s+", "")
end

local function toSet(list)
    local set = {}
    for _, value in ipairs(list or {}) do
        set[value] = true
    end
    return set
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

function GhostGuess.new(ghostEvidenceMap)
    local self = setmetatable({}, GhostGuess)
    self._ghostEvidenceMap = ghostEvidenceMap or {}
    self._evidenceSetByGhost = {}
    for ghostType, evidenceList in pairs(self._ghostEvidenceMap) do
        local normalized = {}
        for _, evidenceType in ipairs(evidenceList or {}) do
            local token = normalizeEvidence(evidenceType)
            if token then
                table.insert(normalized, token)
            end
        end
        self._evidenceSetByGhost[ghostType] = toSet(normalized)
    end
    return self
end

function GhostGuess:ResolvePossibleGhostTypes(discoveredEvidenceSet)
    local possible = {}
    for ghostType, evidenceSet in pairs(self._evidenceSetByGhost) do
        local matches = true
        for evidenceType in pairs(discoveredEvidenceSet or {}) do
            local token = normalizeEvidence(evidenceType)
            if token and not evidenceSet[token] then
                matches = false
                break
            end
        end
        if matches then
            table.insert(possible, ghostType)
        end
    end
    table.sort(possible)
    return possible
end

function GhostGuess:GetAllGhostTypes()
    local ghostTypes = {}
    for ghostType in pairs(self._evidenceSetByGhost) do
        table.insert(ghostTypes, ghostType)
    end
    table.sort(ghostTypes)
    return ghostTypes
end

function GhostGuess:SubmitGuess(matchState, playerOrUserId, guessedGhostType, now)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false, "invalid_player"
    end
    if type(guessedGhostType) ~= "string" or guessedGhostType == "" then
        return false, "invalid_guess"
    end
    matchState.guessesByUserId[userId] = matchState.guessesByUserId[userId] or {}
    local entry = {
        guessedGhostType = guessedGhostType,
        submittedAt = now or os.clock(),
    }
    table.insert(matchState.guessesByUserId[userId], entry)
    matchState.latestGuessByUserId[userId] = entry
    return true, nil, entry
end

function GhostGuess:ValidateGuess(matchState, playerOrUserId, now)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false, "invalid_player"
    end
    local latest = matchState.latestGuessByUserId[userId]
    if not latest then
        return false, "missing_guess"
    end
    local actual = matchState.ghostType
    local guessed = latest.guessedGhostType
    local correct = type(actual) == "string" and actual == guessed
    local result = {
        userId = userId,
        guessedGhostType = guessed,
        actualGhostType = actual,
        correct = correct,
        validatedAt = now or os.clock(),
    }
    return true, nil, result
end

return GhostGuess
