local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for key, nested in pairs(value) do
        out[key] = deepCopy(nested)
    end
    return out
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

local function safeCall(target, methodName, ...)
    if type(target) ~= "table" then
        return nil
    end
    local method = target[methodName]
    if type(method) ~= "function" then
        return nil
    end
    local ok, a, b = pcall(method, target, ...)
    if not ok then
        return nil
    end
    return a, b
end

local function normalizeThresholds(raw)
    local out = {}
    for _, entry in ipairs(raw or {}) do
        if type(entry) == "table" and type(entry.score) == "number" then
            table.insert(out, deepCopy(entry))
        end
    end
    table.sort(out, function(a, b)
        return a.score < b.score
    end)
    return out
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        InventorySystem = Services.Get(self._deps, "InventorySystem"),
        ContentUpdatePipelineSystem = Services.Get(self._deps, "ContentUpdatePipelineSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService") or Services.Get(self._deps, "DataPersistence"),
    }

    self:_loadConfig()
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

function Service:_loadConfig()
    local section = nil
    local content = self._dependencies.ContentUpdatePipelineSystem
    if type(content) == "table" and type(content.GetSection) == "function" then
        section = content:GetSection("Reputation")
    elseif type(content) == "table" and type(content.Service) == "table" and type(content.Service.GetSection) == "function" then
        section = content.Service:GetSection("Reputation")
    end

    section = section or {}

    self._state:Set("defaultScore", math.floor(tonumber(section.DefaultScore) or 100))
    self._state:Set("minScore", math.floor(tonumber(section.MinScore) or 0))
    self._state:Set("maxScore", math.floor(tonumber(section.MaxScore) or 500))
    self._state:Set("positive", deepCopy(section.Positive or self._state:Get("positive") or {}))
    self._state:Set("negative", deepCopy(section.Negative or self._state:Get("negative") or {}))
    self._state:Set("badgeThresholds", normalizeThresholds(section.BadgeThresholds))
    self._state:Set("cosmeticThresholds", normalizeThresholds(section.CosmeticThresholds))
end

function Service:_persistKey()
    return "reputation"
end

function Service:_loadPersistence(userId)
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) ~= "table" then
        return nil
    end

    local profileData = safeCall(persistence, "LoadProfile", userId)
    if type(profileData) ~= "table" then
        profileData = safeCall(persistence, "LoadPlayerData", userId)
    end

    if type(profileData) ~= "table" then
        return nil
    end

    local liveOps = profileData.liveOps or profileData.profile and profileData.profile.liveOps
    if type(liveOps) ~= "table" then
        return nil
    end

    local reputation = liveOps[self:_persistKey()]
    if type(reputation) ~= "table" then
        return nil
    end

    return reputation
end

function Service:_savePersistence(userId)
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) ~= "table" then
        return
    end

    local payload = {
        score = (self._state:Get("scoreByUserId") or {})[userId],
        badges = deepCopy((self._state:Get("unlockedBadgesByUserId") or {})[userId] or {}),
        cosmetics = deepCopy((self._state:Get("unlockedCosmeticsByUserId") or {})[userId] or {}),
    }

    local loaded = safeCall(persistence, "LoadProfile", userId)
    local profile = {}
    if type(loaded) == "table" then
        profile = loaded.profile or loaded
    end

    profile.liveOps = profile.liveOps or {}
    profile.liveOps[self:_persistKey()] = payload

    safeCall(persistence, "SaveProfile", userId, {
        profile = profile,
        rank = type(loaded) == "table" and loaded.rank or nil,
    })
end

function Service:_ensurePlayer(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local playersByUserId = self._state:Get("playersByUserId") or {}
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        playersByUserId[userId] = playerOrUserId
        self._state:Set("playersByUserId", playersByUserId)
    end

    local scores = self._state:Get("scoreByUserId") or {}
    local badges = self._state:Get("unlockedBadgesByUserId") or {}
    local cosmetics = self._state:Get("unlockedCosmeticsByUserId") or {}

    if scores[userId] == nil then
        local persisted = self:_loadPersistence(userId)
        if type(persisted) == "table" then
            scores[userId] = math.floor(tonumber(persisted.score) or self._state:Get("defaultScore") or 100)
            badges[userId] = deepCopy(persisted.badges or {})
            cosmetics[userId] = deepCopy(persisted.cosmetics or {})
        else
            scores[userId] = self._state:Get("defaultScore") or 100
            badges[userId] = {}
            cosmetics[userId] = {}
        end

        self._state:Set("scoreByUserId", scores)
        self._state:Set("unlockedBadgesByUserId", badges)
        self._state:Set("unlockedCosmeticsByUserId", cosmetics)
    end

    return userId
end

function Service:_resolvePlayer(userId)
    local playersByUserId = self._state:Get("playersByUserId") or {}
    return playersByUserId[userId] or userId
end

function Service:_unlockBadgeIfNeeded(userId, score)
    local thresholds = self._state:Get("badgeThresholds") or {}
    local unlocked = self._state:Get("unlockedBadgesByUserId") or {}
    unlocked[userId] = unlocked[userId] or {}

    for _, threshold in ipairs(thresholds) do
        local badgeId = threshold.badgeId
        if type(badgeId) == "string" and badgeId ~= "" and score >= threshold.score and unlocked[userId][badgeId] ~= true then
            unlocked[userId][badgeId] = true
            self:_publish("ReputationBadgeUnlocked", {
                player = typeof(self:_resolvePlayer(userId)) == "Instance" and self:_resolvePlayer(userId) or nil,
                userId = userId,
                badgeId = badgeId,
                score = score,
            })
        end
    end

    self._state:Set("unlockedBadgesByUserId", unlocked)
end

function Service:_unlockCosmeticIfNeeded(userId, score)
    local thresholds = self._state:Get("cosmeticThresholds") or {}
    local unlocked = self._state:Get("unlockedCosmeticsByUserId") or {}
    unlocked[userId] = unlocked[userId] or {}

    local inventory = self._dependencies.InventorySystem
    local playerRef = self:_resolvePlayer(userId)

    for _, threshold in ipairs(thresholds) do
        local cosmeticId = threshold.cosmeticId
        if type(cosmeticId) == "string" and cosmeticId ~= "" and score >= threshold.score and unlocked[userId][cosmeticId] ~= true then
            unlocked[userId][cosmeticId] = true

            safeCall(inventory, "AddCosmeticOwnership", playerRef, cosmeticId)
            if type(inventory) == "table" and type(inventory.Service) == "table" then
                safeCall(inventory.Service, "AddCosmeticOwnership", playerRef, cosmeticId)
            end

            self:_publish("ReputationCosmeticUnlocked", {
                player = typeof(playerRef) == "Instance" and playerRef or nil,
                userId = userId,
                cosmeticId = cosmeticId,
                score = score,
            })
        end
    end

    self._state:Set("unlockedCosmeticsByUserId", unlocked)
end

function Service:_applyDelta(userId, delta, reason, context)
    self:_ensurePlayer(userId)

    local scores = self._state:Get("scoreByUserId") or {}
    local minScore = self._state:Get("minScore") or 0
    local maxScore = self._state:Get("maxScore") or 500

    local previous = scores[userId] or (self._state:Get("defaultScore") or 100)
    local nextScore = math.clamp(previous + delta, minScore, maxScore)
    scores[userId] = nextScore
    self._state:Set("scoreByUserId", scores)

    self:_unlockBadgeIfNeeded(userId, nextScore)
    self:_unlockCosmeticIfNeeded(userId, nextScore)

    self:_publish("PlayerReputationChanged", {
        player = typeof(self:_resolvePlayer(userId)) == "Instance" and self:_resolvePlayer(userId) or nil,
        userId = userId,
        delta = delta,
        previous = previous,
        score = nextScore,
        reason = reason,
        context = context,
    })

    self:_savePersistence(userId)
end

function Service:GetReputation(playerOrUserId)
    local userId = self:_ensurePlayer(playerOrUserId)
    if not userId then
        return nil
    end
    local scores = self._state:Get("scoreByUserId") or {}
    return scores[userId]
end

function Service:OnPlayerAdded(player)
    self:_ensurePlayer(player)
end

function Service:OnPlayerRemoving(player)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local playersInMatch = self._state:Get("playersInMatch") or {}
    local matchId = playersInMatch[userId]
    if matchId then
        local penalties = self._state:Get("negative") or {}
        local penalty = penalties.LeaveMatchEarly or -15
        self:_applyDelta(userId, penalty, "LeaveMatchEarly", {
            matchId = matchId,
            source = "PlayerReputationSystem",
        })
        playersInMatch[userId] = nil
        self._state:Set("playersInMatch", playersInMatch)
    end

    self:_savePersistence(userId)

    local playersByUserId = self._state:Get("playersByUserId") or {}
    playersByUserId[userId] = nil
    self._state:Set("playersByUserId", playersByUserId)
end

function Service:OnMatchStarted(payload)
    local playersInMatch = self._state:Get("playersInMatch") or {}
    for _, player in ipairs(payload and payload.players or {}) do
        local userId = self:_ensurePlayer(player)
        if userId then
            playersInMatch[userId] = payload.matchId
        end
    end
    self._state:Set("playersInMatch", playersInMatch)
end

function Service:OnMatchEnded(payload)
    local positive = self._state:Get("positive") or {}
    local playersInMatch = self._state:Get("playersInMatch") or {}

    local processed = {}
    for _, player in ipairs(payload and payload.players or {}) do
        local userId = self:_ensurePlayer(player)
        if userId then
            processed[userId] = true
            playersInMatch[userId] = nil
            self:_applyDelta(userId, positive.CompleteInvestigation or 12, "CompleteInvestigation", {
                matchId = payload and payload.matchId,
            })
        end
    end

    local playerOutcome = payload and payload.results and payload.results.playerOutcome or {}
    for key, outcome in pairs(playerOutcome) do
        local userId = tonumber(key) or outcome and outcome.userId
        if userId then
            self:_ensurePlayer(userId)
            playersInMatch[userId] = nil
            if not processed[userId] then
                self:_applyDelta(userId, positive.CompleteInvestigation or 12, "CompleteInvestigation", {
                    matchId = payload and payload.matchId,
                })
                processed[userId] = true
            end
            if type(outcome) == "table" and outcome.extracted == true then
                self:_applyDelta(userId, positive.SurviveAndExtract or 6, "SurviveAndExtract", {
                    matchId = payload and payload.matchId,
                })
            end
        end
    end

    self._state:Set("playersInMatch", playersInMatch)
end

function Service:OnGhostIdentified(payload)
    local userId = payload and (payload.userId or toUserId(payload.player))
    if not userId then
        return
    end

    local positive = self._state:Get("positive") or {}
    self:_applyDelta(userId, positive.CorrectGhostIdentification or 8, "CorrectGhostIdentification", {
        matchId = payload.matchId,
    })
end

function Service:OnTeammateHelped(payload)
    local userId = payload and (payload.userId or toUserId(payload.player))
    if not userId then
        return
    end

    local positive = self._state:Get("positive") or {}
    self:_applyDelta(userId, positive.HelpTeammate or 4, "HelpTeammate", payload)
end

function Service:OnGriefingReported(payload)
    local userId = payload and (payload.reportedUserId or payload.userId)
    if not userId then
        return
    end

    local negative = self._state:Get("negative") or {}
    self:_applyDelta(userId, negative.Griefing or -25, "Griefing", payload)
end

function Service:OnTeamSabotage(payload)
    local userId = payload and (payload.userId or payload.reportedUserId)
    if not userId then
        return
    end

    local negative = self._state:Get("negative") or {}
    self:_applyDelta(userId, negative.TeamSabotage or -30, "TeamSabotage", payload)
end

function Service:OnContentCatalogUpdated()
    self:_loadConfig()
end

return Service
