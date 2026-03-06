local MatchRewardModule = require(script.Parent.Rewards.MatchCompletion.Main)
local DailyMissionModule = require(script.Parent.Rewards.DailyMissions.Main)
local DailyCheckInModule = require(script.Parent.Rewards.DailyCheckIn.Main)
local RoyalPassModule = require(script.Parent.Rewards.RoyalPass.Main)
local IntegrationModule = require(script.Parent.Integrations.Main)
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local BASE_DAILY_MM_CAP = 10000
local LIFETIME_CAP_MULTIPLIER = 2
local MISSION_REWARD = 1000
local ALL_MISSION_BONUS = 2000

local CHECKIN_REWARDS = {
    [1] = { currency = "MM", amount = 1000 },
    [2] = { currency = "MM", amount = 1000 },
    [3] = { currency = "MM", amount = 1000 },
    [4] = { assetRarityRoll = { { rarity = "R1", weight = 80 }, { rarity = "R2", weight = 20 } } },
    [5] = { currency = "MM", amount = 1500 },
    [6] = { currency = "MM", amount = 1500 },
    [7] = { assetRarityRoll = { { rarity = "R1", weight = 60 }, { rarity = "R2", weight = 30 }, { rarity = "R3", weight = 10 } } },
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

local function cloneTable(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._rng = self._deps.Random or Random.new()
    self._integrations = IntegrationModule.new({
        EventBus = self._eventBus,
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        ContractSystem = Services.Get(self._deps, "ContractSystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        LobbySocialHub = Services.Get(self._deps, "LobbySocialHub"),
        IntegrationState = self._deps.IntegrationState,
    })
    self._royalPassDriver = RoyalPassModule.new({
        EventBus = self._eventBus,
        RoyalPassState = self._deps.RoyalPassState,
    })
    self._matchRewardDriver = MatchRewardModule.new({
        EventBus = self._eventBus,
        CurrencyService = self,
        MatchRewardState = self._deps.MatchRewardState,
        Random = self._deps.Random,
    })
    self._dailyMissionsDriver = DailyMissionModule.new({
        EventBus = self._eventBus,
        CurrencyService = self,
        DailyMissionState = self._deps.DailyMissionState,
    })
    self._dailyCheckInDriver = DailyCheckInModule.new({
        EventBus = self._eventBus,
        CurrencyService = self,
        DailyCheckInState = self._deps.DailyCheckInState,
    })
    return self
end

function Service:Init()
    self._state:Set("walletByUserId", {})
    self._state:Set("dailyByUserId", {})
    self._state:Set("passByUserId", {})
    if self._integrations then
        self._integrations:Init()
    end
    if self._royalPassDriver then
        self._royalPassDriver:Init()
    end
    if self._matchRewardDriver then
        self._matchRewardDriver:Init()
    end
    if self._dailyMissionsDriver then
        self._dailyMissionsDriver:Init()
    end
    if self._dailyCheckInDriver then
        self._dailyCheckInDriver:Init()
    end
end

function Service:Start()
    if self._integrations then
        self._integrations:Start()
    end
    if self._royalPassDriver then
        self._royalPassDriver:Start()
    end
    if self._matchRewardDriver then
        self._matchRewardDriver:Start()
    end
    if self._dailyMissionsDriver then
        self._dailyMissionsDriver:Start()
    end
    if self._dailyCheckInDriver then
        self._dailyCheckInDriver:Start()
    end
end

function Service:Stop()
    if self._dailyCheckInDriver then
        self._dailyCheckInDriver:Stop()
    end
    if self._dailyMissionsDriver then
        self._dailyMissionsDriver:Stop()
    end
    if self._matchRewardDriver then
        self._matchRewardDriver:Stop()
    end
    if self._royalPassDriver then
        self._royalPassDriver:Stop()
    end
    if self._integrations then
        self._integrations:Stop()
    end
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_wallets()
    return self._state:Get("walletByUserId") or {}
end

function Service:_setWallets(wallets)
    self._state:Set("walletByUserId", wallets)
end

function Service:_daily()
    return self._state:Get("dailyByUserId") or {}
end

function Service:_setDaily(dailyByUserId)
    self._state:Set("dailyByUserId", dailyByUserId)
end

function Service:_passes()
    return self._state:Get("passByUserId") or {}
end

function Service:_setPasses(passByUserId)
    self._state:Set("passByUserId", passByUserId)
end

function Service:_ensureWallet(userId)
    local wallets = self:_wallets()
    if not wallets[userId] then
        wallets[userId] = {
            MM = 0,
            PP = 0,
        }
        self:_setWallets(wallets)
    end
    return wallets[userId]
end

function Service:_ensureDaily(userId)
    local dailyByUserId = self:_daily()
    if not dailyByUserId[userId] then
        dailyByUserId[userId] = {
            mmEarned = 0,
            missionCompletedCount = 0,
            allMissionsClaimed = false,
            checkInDay = 0,
        }
        self:_setDaily(dailyByUserId)
    end
    return dailyByUserId[userId]
end

function Service:_ensurePass(userId)
    local passByUserId = self:_passes()
    if not passByUserId[userId] then
        passByUserId[userId] = {
            RoyalPass_Dukun = false,
            RoyalPass_Detective = false,
            LifetimePass = false,
        }
        self:_setPasses(passByUserId)
    end
    return passByUserId[userId]
end

function Service:_capForUser(userId)
    local passes = self:_ensurePass(userId)
    local cap = BASE_DAILY_MM_CAP
    if passes.LifetimePass then
        cap *= LIFETIME_CAP_MULTIPLIER
    end
    return cap
end

function Service:_addMMWithCap(player, amount, reason)
    local userId = toUserId(player)
    if not userId then
        return 0
    end

    local daily = self:_ensureDaily(userId)
    local cap = self:_capForUser(userId)
    local remaining = math.max(cap - daily.mmEarned, 0)
    local allowed = math.min(math.max(math.floor(amount), 0), remaining)
    if allowed <= 0 then
        return 0
    end

    local wallet = self:_ensureWallet(userId)
    wallet.MM += allowed
    daily.mmEarned += allowed

    self:_publish("CurrencyChanged", {
        player = player,
        userId = userId,
        currency = "MM",
        delta = allowed,
        balance = wallet.MM,
        reason = reason or "reward",
    })

    return allowed
end

function Service:GetBalance(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end
    return cloneTable(self:_ensureWallet(userId))
end

function Service:AddCurrency(player, currencyOrAmount, amountOrReason, reasonOrNil)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local currency = "MM"
    local amount = 0
    local reason = nil
    if type(currencyOrAmount) == "string" then
        currency = currencyOrAmount
        amount = amountOrReason or 0
        reason = reasonOrNil
    else
        amount = currencyOrAmount or 0
        reason = amountOrReason
    end

    amount = math.floor(amount)
    if amount <= 0 then
        return false, "invalid_amount"
    end

    if currency == "MM" then
        local granted = self:_addMMWithCap(player, amount, reason or "manual_add")
        return granted > 0, nil, granted
    end

    local wallet = self:_ensureWallet(userId)
    wallet[currency] = (wallet[currency] or 0) + amount
    self:_publish("CurrencyChanged", {
        player = player,
        userId = userId,
        currency = currency,
        delta = amount,
        balance = wallet[currency],
        reason = reason or "manual_add",
    })
    return true, nil, amount
end

function Service:SpendCurrency(player, currencyOrAmount, amountOrReason, reasonOrNil)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local currency = "MM"
    local amount = 0
    local reason = nil
    if type(currencyOrAmount) == "string" then
        currency = currencyOrAmount
        amount = amountOrReason or 0
        reason = reasonOrNil
    else
        amount = currencyOrAmount or 0
        reason = amountOrReason
    end

    amount = math.floor(amount)
    if amount <= 0 then
        return false, "invalid_amount"
    end

    local wallet = self:_ensureWallet(userId)
    local current = wallet[currency] or 0
    if current < amount then
        return false, "insufficient_funds"
    end

    wallet[currency] = current - amount
    self:_publish("CurrencyChanged", {
        player = player,
        userId = userId,
        currency = currency,
        delta = -amount,
        balance = wallet[currency],
        reason = reason or "spend",
    })
    return true
end

function Service:CalculateMatchReward(matchData)
    local performancePercent = matchData and (matchData.performancePercent or matchData.performance or 0) or 0
    performancePercent = math.clamp(performancePercent, 0, 100)
    local mmReward = math.floor(performancePercent * 10)
    return {
        currency = "MM",
        amount = mmReward,
        outcome = performancePercent > 50 and "win" or "lose",
    }
end

function Service:_publishMatchRewardEvents(payload)
    if not payload then
        return
    end
    self:_publish("CurrencyEarned", payload)
    self:_publish("RewardGranted", payload)
end

function Service:_grantMatchRewardEntry(entry, payloadContext)
    if not entry then
        return 0
    end
    local reward = self:CalculateMatchReward({
        performancePercent = entry.performancePercent,
    })
    local awarded = self:_addMMWithCap(entry.player or entry.userId, reward.amount, payloadContext and payloadContext.reason or "match_reward")
    if awarded > 0 then
        local rewardPayload = {
            player = entry.player,
            userId = entry.userId,
            matchId = payloadContext and payloadContext.matchId,
            currency = reward.currency,
            amount = awarded,
            performancePercent = entry.performancePercent,
            outcome = reward.outcome,
            reason = payloadContext and payloadContext.reason or "MatchEnded",
        }
        self:_publishMatchRewardEvents(rewardPayload)
        self:_publish("PlayerRewardGranted", rewardPayload)
        self:_publish("RewardsGranted", rewardPayload)
        return awarded, rewardPayload
    end
    return 0, nil
end

function Service:GrantMatchReward(entryPayload)
    local entry = entryPayload and (entryPayload.entry or entryPayload)
    return self:_grantMatchRewardEntry(entry, entryPayload)
end

function Service:SetPassOwnership(player, passState)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    local pass = self:_ensurePass(userId)
    for key, value in pairs(passState or {}) do
        pass[key] = value == true
    end
    return true
end

function Service:GrantMissionCompleted(player)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local passes = self:_ensurePass(userId)
    local multiplier = passes.LifetimePass and 2 or 1
    local awarded = self:_addMMWithCap(player, MISSION_REWARD * multiplier, "daily_mission")

    local daily = self:_ensureDaily(userId)
    daily.missionCompletedCount += 1

    if awarded > 0 then
        local rewardPayload = {
            player = player,
            userId = userId,
            currency = "MM",
            amount = awarded,
            reason = "MissionCompleted",
            context = "Mission",
        }
        self:_publish("CurrencyEarned", rewardPayload)
        self:_publish("RewardGranted", rewardPayload)
        self:_publish("PlayerRewardGranted", rewardPayload)
        self:_publish("RewardsGranted", rewardPayload)
    end

    return true, nil, awarded
end

function Service:GrantAllMissionsCompleted(player)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local daily = self:_ensureDaily(userId)
    if daily.allMissionsClaimed then
        return false, "already_claimed"
    end

    local passes = self:_ensurePass(userId)
    local multiplier = passes.LifetimePass and 2 or 1
    local awarded = self:_addMMWithCap(player, ALL_MISSION_BONUS * multiplier, "daily_mission_all")
    daily.allMissionsClaimed = true

    if awarded > 0 then
        local rewardPayload = {
            player = player,
            userId = userId,
            currency = "MM",
            amount = awarded,
            reason = "AllMissionCompleted",
            context = "Mission",
        }
        self:_publish("CurrencyEarned", rewardPayload)
        self:_publish("RewardGranted", rewardPayload)
        self:_publish("PlayerRewardGranted", rewardPayload)
        self:_publish("RewardsGranted", rewardPayload)
    end
    return true, nil, awarded
end

function Service:_rollRarity(weighted)
    local totalWeight = 0
    for _, entry in ipairs(weighted or {}) do
        totalWeight += entry.weight
    end
    if totalWeight <= 0 then
        return nil
    end

    local roll = self._rng:NextNumber(0, totalWeight)
    local cursor = 0
    for _, entry in ipairs(weighted) do
        cursor += entry.weight
        if roll <= cursor then
            return entry.rarity
        end
    end
    return weighted[#weighted] and weighted[#weighted].rarity or nil
end

function Service:ClaimDailyCheckIn(player)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local daily = self:_ensureDaily(userId)
    local day = (daily.checkInDay % 7) + 1
    daily.checkInDay = day

    local reward = CHECKIN_REWARDS[day]
    if not reward then
        return false, "missing_reward"
    end

    if reward.currency == "MM" then
        local awarded = self:_addMMWithCap(player, reward.amount, "daily_checkin")
        local rewardPayload = {
            player = player,
            userId = userId,
            currency = "MM",
            amount = awarded,
            reason = "DailyCheckIn",
            day = day,
            context = "DailyCheckIn",
        }
        self:_publish("CurrencyEarned", rewardPayload)
        self:_publish("RewardGranted", rewardPayload)
        self:_publish("PlayerRewardGranted", rewardPayload)
        self:_publish("RewardsGranted", rewardPayload)
        self:_publish("DailyRewardClaimed", {
            player = player,
            userId = userId,
            currency = "MM",
            amount = awarded,
            day = day,
        })
        return true, nil, {
            day = day,
            currency = "MM",
            amount = awarded,
        }
    end

    local rarity = self:_rollRarity(reward.assetRarityRoll)
    local assetId = string.format("DailyCheckIn_%s_Day%d", rarity or "R1", day)
    local rewardPayload = {
        player = player,
        userId = userId,
        rewardType = "Asset",
        assetType = "Cosmetic",
        assetId = assetId,
        rarity = rarity,
        reason = "DailyCheckIn",
        day = day,
    }
    self:_publish("RewardGranted", rewardPayload)
    self:_publish("PlayerRewardGranted", rewardPayload)
    self:_publish("RewardsGranted", rewardPayload)
    self:_publish("DailyRewardClaimed", {
        player = player,
        userId = userId,
        assetId = assetId,
        rarity = rarity,
        day = day,
    })

    return true, nil, {
        day = day,
        rewardType = "Asset",
        assetId = assetId,
        rarity = rarity,
    }
end

function Service:_collectMatchPlayerResults(payload)
    local collected = {}
    local results = payload and payload.results or {}

    for _, entry in ipairs(results.playerResults or {}) do
        local player = entry.player
        local userId = entry.userId or (player and player.UserId)
        if player or userId then
            table.insert(collected, {
                player = player,
                userId = userId,
                performancePercent = entry.performancePercent or entry.performance or 0,
            })
        end
    end

    for userId, entry in pairs(results.byUserId or {}) do
        if type(entry) == "table" then
            table.insert(collected, {
                player = entry.player,
                userId = tonumber(userId) or userId,
                performancePercent = entry.performancePercent or entry.performance or 0,
            })
        end
    end

    return collected
end

function Service:GrantMatchRewardsFromMatch(payload)
    local entries = self:_collectMatchPlayerResults(payload)
    local granted = {}

    for _, entry in ipairs(entries) do
        local _, rewardPayload = self:_grantMatchRewardEntry(entry, {
            matchId = payload and payload.matchId,
            reason = "MatchEnded",
        })
        table.insert(granted, rewardPayload)
    end

    return granted
end

return Service

