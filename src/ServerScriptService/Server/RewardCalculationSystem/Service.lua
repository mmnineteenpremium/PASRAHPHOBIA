local Players = game:GetService("Players")
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DIFFICULTY_MULTIPLIER = {
    Easy = 1.0,
    Normal = 1.2,
    Hard = 1.45,
    Nightmare = 1.8,
    Mudah = 1.0,
    Lumayan = 1.2,
    Angker = 1.45,
    ["Uji Nyali"] = 1.7,
}

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

local function toNumberUserId(raw)
    if type(raw) == "number" then
        return raw
    end
    if type(raw) == "string" then
        return tonumber(raw)
    end
    return nil
end

local function resolveDifficultyMultiplier(payload)
    local difficulty = payload and payload.difficulty
    local profileMode = payload and payload.difficultyProfile and payload.difficultyProfile.DifficultyMode
    if type(profileMode) == "string" and DIFFICULTY_MULTIPLIER[profileMode] then
        return DIFFICULTY_MULTIPLIER[profileMode]
    end
    if type(difficulty) == "number" then
        return math.max(0.5, difficulty)
    end
    if type(difficulty) == "string" then
        return DIFFICULTY_MULTIPLIER[difficulty] or 1.2
    end
    if payload and type(payload.difficultyMultiplier) == "number" then
        return math.max(0.5, payload.difficultyMultiplier)
    end
    return 1.2
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    return self
end

function Service:Init()
    self._dependencies = {
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        ProgressionSystem = Services.Get(self._deps, "ProgressionSystem"),
        RoyalPassSystem = Services.Get(self._deps, "RoyalPassSystem"),
    }
    self._state:Set("rewardHistory", self._state:Get("rewardHistory") or {})
    self._state:Set("activeMatchId", self._state:Get("activeMatchId"))
    self._state:Set("distributedByMatchId", self._state:Get("distributedByMatchId") or {})
    self._state:Set("pendingMatchEndByMatchId", self._state:Get("pendingMatchEndByMatchId") or {})
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

function Service:_isDistributed(matchId)
    local distributed = self._state:Get("distributedByMatchId") or {}
    return distributed[matchId] == true
end

function Service:_markDistributed(matchId)
    local distributed = self._state:Get("distributedByMatchId") or {}
    distributed[matchId] = true
    self._state:Set("distributedByMatchId", distributed)
end

function Service:_recordHistory(matchId, summary)
    local history = self._state:Get("rewardHistory") or {}
    table.insert(history, {
        matchId = matchId,
        distributedAt = os.clock(),
        rewards = summary,
    })
    self._state:Set("rewardHistory", history)
end

function Service:_collectOutcomes(payload)
    local result = {}

    local function upsert(userId, entry)
        if type(userId) ~= "number" then
            return
        end
        local existing = result[userId] or {
            userId = userId,
            player = Players:GetPlayerByUserId(userId),
            survived = true,
            extracted = false,
            evidenceCount = 0,
        }
        if type(entry) == "table" then
            if entry.player then
                existing.player = entry.player
            end
            if entry.survived ~= nil then
                existing.survived = entry.survived == true
            end
            if entry.died == true then
                existing.survived = false
            end
            if entry.extracted ~= nil then
                existing.extracted = entry.extracted == true
            end
            if type(entry.evidenceCount) == "number" then
                existing.evidenceCount = entry.evidenceCount
            end
        end
        result[userId] = existing
    end

    local sources = {
        payload and payload.playerOutcome,
        payload and payload.results and payload.results.playerOutcome,
    }
    for _, source in ipairs(sources) do
        if type(source) == "table" then
            for key, value in pairs(source) do
                local userId = toNumberUserId(key) or toUserId(value and (value.player or value.userId))
                upsert(userId, value)
            end
        end
    end

    local players = payload and (payload.players or (payload.results and payload.results.players))
    if type(players) == "table" then
        for _, player in ipairs(players) do
            upsert(toUserId(player), { player = player, survived = true })
        end
    end

    return result
end

function Service:_calculateReward(payload, entry)
    local multiplier = resolveDifficultyMultiplier(payload)
    local teamSuccess = (payload and payload.teamSuccess == true)
        or (payload and payload.contractSuccess == true)
        or (payload and payload.extractionCompleted == true)
    local correctGuess = (payload and payload.correctGuess == true) or (payload and payload.ghostIdentified == true)
    local evidenceCollected = math.max(0, tonumber(payload and payload.evidenceCollected) or 0)

    local currency = 120
    local xp = 90

    if teamSuccess then
        currency += 55
        xp += 35
    end
    if correctGuess then
        currency += 75
        xp += 55
    end

    currency += math.min(6, evidenceCollected) * 12
    xp += math.min(6, evidenceCollected) * 8

    if entry.survived then
        currency += 60
        xp += 40
    else
        currency = math.floor(currency * 0.7)
        xp = math.floor(xp * 0.8)
    end

    if entry.extracted then
        currency += 35
        xp += 20
    end

    currency = math.max(0, math.floor(currency * multiplier))
    xp = math.max(1, math.floor(xp * multiplier))
    local royalPassXP = math.max(15, math.floor(xp * 0.45))
    local dailyProgress = (teamSuccess and 2 or 1) + (entry.survived and 1 or 0)

    return {
        currency = "MM",
        amount = currency,
        xp = xp,
        royalPassXP = royalPassXP,
        dailyProgress = dailyProgress,
    }
end

function Service:_grantToPlayer(matchId, payload, entry, reward)
    local playerOrUserId = entry.player or entry.userId
    local userId = entry.userId
    local economy = self._dependencies.EconomySystem
    local progression = self._dependencies.ProgressionSystem
    local royalPass = self._dependencies.RoyalPassSystem

    if type(economy) == "table" then
        if type(economy.AddCurrency) == "function" then
            economy:AddCurrency(playerOrUserId, reward.currency, reward.amount, "endgame_match_reward")
        elseif type(economy.Service) == "table" and type(economy.Service.AddCurrency) == "function" then
            economy.Service:AddCurrency(playerOrUserId, reward.currency, reward.amount, "endgame_match_reward")
        end
    end

    if type(progression) == "table" then
        if type(progression.GrantXP) == "function" then
            progression:GrantXP(playerOrUserId, reward.xp)
        elseif type(progression.Service) == "table" and type(progression.Service.GrantXP) == "function" then
            progression.Service:GrantXP(playerOrUserId, reward.xp)
        end
    end

    if type(royalPass) == "table" then
        if type(royalPass.AddXP) == "function" then
            royalPass:AddXP(playerOrUserId, reward.royalPassXP, "EndgameReward")
        elseif type(royalPass.Service) == "table" and type(royalPass.Service.AddXP) == "function" then
            royalPass.Service:AddXP(playerOrUserId, reward.royalPassXP, "EndgameReward")
        end
    end

    local rewardPayload = {
        matchId = matchId,
        player = entry.player,
        userId = userId,
        currency = reward.currency,
        amount = reward.amount,
        xp = reward.xp,
        royalPassXP = reward.royalPassXP,
        dailyProgress = reward.dailyProgress,
        reason = "endgame_match_reward",
        sourceSystem = "RewardCalculationSystem",
    }

    self:_publish("RewardGranted", rewardPayload)
    self:_publish("RewardsGranted", rewardPayload)
    self:_publish("PlayerRewardGranted", rewardPayload)
    self:_publish("XPGranted", {
        player = entry.player,
        userId = userId,
        amount = reward.xp,
        reason = "endgame_match_reward",
        matchId = matchId,
        sourceSystem = "RewardCalculationSystem",
    })
    self:_publish("DailyRewardTriggerRequested", {
        player = entry.player,
        userId = userId,
        matchId = matchId,
        progress = reward.dailyProgress,
        sourceSystem = "RewardCalculationSystem",
    })

    return rewardPayload
end

function Service:_distribute(matchPayload)
    local matchId = matchPayload and matchPayload.matchId
    if type(matchId) ~= "string" or self:_isDistributed(matchId) then
        return
    end

    local outcomeByUserId = self:_collectOutcomes(matchPayload)
    local rewardSummary = {}
    for userId, entry in pairs(outcomeByUserId) do
        local reward = self:_calculateReward(matchPayload, entry)
        rewardSummary[userId] = self:_grantToPlayer(matchId, matchPayload, entry, reward)
    end

    self:_markDistributed(matchId)
    self:_recordHistory(matchId, rewardSummary)

    self:_publish("EndgameRewardDistributionCompleted", {
        matchId = matchId,
        rewardCount = (function()
            local count = 0
            for _ in pairs(rewardSummary) do
                count += 1
            end
            return count
        end)(),
        sourceSystem = "RewardCalculationSystem",
    })
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        self._state:Set("activeMatchId", payload and payload.matchId)
        return
    end

    if eventName == "MatchCompleted" then
        local matchId = payload and payload.matchId
        if type(matchId) == "string" then
            local pending = self._state:Get("pendingMatchEndByMatchId") or {}
            pending[matchId] = nil
            self._state:Set("pendingMatchEndByMatchId", pending)
        end
        self:_distribute(payload)
        return
    end

    if eventName == "MatchEnded" then
        local matchId = payload and payload.matchId
        if type(matchId) ~= "string" or self:_isDistributed(matchId) then
            return
        end

        local pending = self._state:Get("pendingMatchEndByMatchId") or {}
        pending[matchId] = payload
        self._state:Set("pendingMatchEndByMatchId", pending)

        task.delay(0.35, function()
            if self:_isDistributed(matchId) then
                return
            end
            local stillPending = self._state:Get("pendingMatchEndByMatchId") or {}
            local pendingPayload = stillPending[matchId]
            if pendingPayload then
                stillPending[matchId] = nil
                self._state:Set("pendingMatchEndByMatchId", stillPending)
                self:_distribute(pendingPayload)
            end
        end)
    end
end

return Service



