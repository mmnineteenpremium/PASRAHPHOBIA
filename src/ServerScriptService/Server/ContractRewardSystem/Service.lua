local Service = {}
Service.__index = Service

local Services = require(script.Parent.Parent.Core.Services)

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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._economy = Services.Get(self._deps, "EconomySystem")
    self._inventory = Services.Get(self._deps, "InventorySystem")
    self._profile = Services.Get(self._deps, "ProfileSystem")
    return self
end

function Service:Init()
    self._state:Set("activeContracts", self._state:Get("activeContracts") or {})
    self._state:Set("rewardHistory", self._state:Get("rewardHistory") or {})
    self._state:Set("lastMatchResults", self._state:Get("lastMatchResults"))
end

function Service:Start()
    -- Event-driven service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_recordReward(userId, rewardPayload)
    local rewardHistory = self._state:Get("rewardHistory") or {}
    rewardHistory[userId] = rewardHistory[userId] or {}
    table.insert(rewardHistory[userId], rewardPayload)
    self._state:Set("rewardHistory", rewardHistory)
end

function Service:CalculateReward(playerOrUserId, matchData)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local difficulty = matchData and (matchData.difficulty or matchData.contractDifficulty or "Lumayan") or "Lumayan"
    local multipliers = self._state:Get("difficultyMultipliers") or {}
    local difficultyMultiplier = multipliers[difficulty] or 1.0
    local performance = math.clamp(math.floor(matchData and (matchData.performancePercent or matchData.performance) or 0), 0, 100)
    local base = self._state:Get("baseContractReward") or 250
    local performanceScale = self._state:Get("performanceScale") or 2
    local surviveBonus = (matchData and matchData.survived == true) and (self._state:Get("surviveBonus") or 0) or 0
    local objectiveBonus = math.max(math.floor(matchData and matchData.optionalObjectiveBonus or 0), 0)
    local contractBonus = (matchData and matchData.contractCompleted == true) and (self._state:Get("contractBonus") or 0) or 0
    local teamSurvivalBonus = (matchData and matchData.teamSurvived == true) and math.floor((self._state:Get("surviveBonus") or 0) * 0.5) or 0

    local total = math.floor((base + (performance * performanceScale) + surviveBonus + objectiveBonus + contractBonus + teamSurvivalBonus) * difficultyMultiplier)
    local currencyAmount = math.max(total, 0)
    local xpAmount = math.max(math.floor(currencyAmount / 10), 1)

    return {
        player = type(playerOrUserId) == "number" and nil or playerOrUserId,
        userId = userId,
        currency = "MM",
        currencyAmount = currencyAmount,
        xpAmount = xpAmount,
        contractBonusAmount = contractBonus + objectiveBonus,
        difficulty = difficulty,
        performancePercent = performance,
    }
end

function Service:ProcessMatchResults(payload)
    self._state:Set("lastMatchResults", payload)
    local results = payload and payload.results or {}
    for _, entry in ipairs(results.playerResults or {}) do
        local playerOrUserId = entry.player or entry.userId
        local reward = self:CalculateReward(playerOrUserId, {
            difficulty = payload and (payload.difficulty or payload.contractDifficulty),
            performancePercent = entry.performancePercent or entry.performance or 0,
            survived = entry.survived == true,
            teamSurvived = entry.teamSurvived == true or (results and results.teamSurvived == true),
            optionalObjectiveBonus = entry.optionalObjectiveBonus or 0,
            contractCompleted = entry.contractCompleted == true or (payload and payload.contractCompleted == true),
        })
        if reward then
            local rewardPayload = {
                sourceSystem = "ContractRewardSystem",
                player = reward.player,
                userId = reward.userId,
                currency = reward.currency,
                amount = reward.currencyAmount,
                xpAmount = reward.xpAmount,
                contractBonusAmount = reward.contractBonusAmount,
                difficulty = reward.difficulty,
                performancePercent = reward.performancePercent,
                reason = "contract_match_reward",
                matchId = payload and payload.matchId,
                integrations = {
                    economy = self._economy ~= nil,
                    inventory = self._inventory ~= nil,
                    profile = self._profile ~= nil,
                },
            }
            self:_recordReward(reward.userId, rewardPayload)
            self:_publish("RewardGranted", rewardPayload)
        end
    end
end

function Service:HandleMatchEnded(payload)
    self:ProcessMatchResults(payload)
end

return Service
