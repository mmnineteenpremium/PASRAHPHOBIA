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
local MAX_WALLET_BALANCE = 9999999
local DEFAULT_STARTING_MM = 1200
local DEFAULT_STARTING_PP = 12
local DEFAULT_STARTING_ROBUX = 0
local MATCH_MM_BASE = 180
local MATCH_MM_PERFORMANCE_MULTIPLIER = 4
local MATCH_SURVIVE_BONUS_MM = 40
local MATCH_EXTRACT_BONUS_MM = 30
local MATCH_PP_BASE = 1
local MATCH_PP_THRESHOLD_A = 70
local MATCH_PP_THRESHOLD_B = 90
local MATCH_PP_EXTRACT_BONUS = 1
local MATCH_PP_MAX = 4
local MM_UNCAPPED_REASONS = {
    ShopPurchaseRefund = true,
    GiftPurchaseRefund = true,
    MarketplacePurchase = true,
    CurrencyPackPurchase = true,
}

local CHECKIN_REWARDS = {
    [1] = { currency = "MM", amount = 1000 },
    [2] = { currency = "MM", amount = 1000 },
    [3] = { currency = "MM", amount = 1000 },
    [4] = { assetRarityRoll = { { rarity = "R1", weight = 65 }, { rarity = "R2", weight = 22 }, { rarity = "R3", weight = 10 }, { rarity = "R4", weight = 3 } } },
    [5] = { currency = "MM", amount = 1500 },
    [6] = { currency = "MM", amount = 1500 },
    [7] = { assetRarityRoll = { { rarity = "R1", weight = 35 }, { rarity = "R2", weight = 25 }, { rarity = "R3", weight = 20 }, { rarity = "R4", weight = 15 }, { rarity = "R5", weight = 5 } } },
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
    self._maxWalletBalance = tonumber(self._deps.MaxWalletBalance) or MAX_WALLET_BALANCE
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
    self._state:Set("matchRewardGrantedByKey", {})
    if self._integrations then
        self._integrations:Init()
    end
    if self._royalPassDriver then
        self._royalPassDriver:Init()
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

function Service:_matchRewardGrants()
    return self._state:Get("matchRewardGrantedByKey") or {}
end

function Service:_setMatchRewardGrants(matchRewardGrantedByKey)
    self._state:Set("matchRewardGrantedByKey", matchRewardGrantedByKey)
end

function Service:_markMatchRewardGranted(matchId, userId)
    if type(matchId) ~= "string" or matchId == "" or type(userId) ~= "number" then
        return false
    end
    local key = string.format("%s:%d", matchId, userId)
    local grants = self:_matchRewardGrants()
    if grants[key] == true then
        return true
    end
    grants[key] = true
    self:_setMatchRewardGrants(grants)
    return false
end

function Service:_ensureWallet(userId)
    local wallets = self:_wallets()
    if not wallets[userId] then
        wallets[userId] = {
            MM = DEFAULT_STARTING_MM,
            PP = DEFAULT_STARTING_PP,
            Robux = DEFAULT_STARTING_ROBUX,
        }
        self:_setWallets(wallets)
    end
    wallets[userId].MM = math.max(0, math.floor(tonumber(wallets[userId].MM) or DEFAULT_STARTING_MM))
    wallets[userId].PP = math.max(0, math.floor(tonumber(wallets[userId].PP) or DEFAULT_STARTING_PP))
    wallets[userId].Robux = math.max(0, math.floor(tonumber(wallets[userId].Robux) or DEFAULT_STARTING_ROBUX))
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


function Service:_applyWalletCap(userId, currency, amount)
    if amount <= 0 then
        return 0
    end
    local wallet = self:_ensureWallet(userId)
    local current = wallet[currency] or 0
    local cap = self._maxWalletBalance or MAX_WALLET_BALANCE
    local remaining = math.max(cap - current, 0)
    return math.min(amount, remaining)
end
function Service:_capForUser(userId)
    local cap = BASE_DAILY_MM_CAP
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

    if currency == "RBX" then
        currency = "Robux"
    end

    if currency == "XP" then
        self:_publish("XPGranted", {
            player = player,
            userId = userId,
            amount = amount,
            source = reason or "manual_add",
        })
        return true, nil, amount
    end

    if currency ~= "MM" and currency ~= "PP" and currency ~= "Robux" then
        return false, "unsupported_currency"
    end

    if currency == "MM" then
        if MM_UNCAPPED_REASONS[reason or ""] == true then
            local capped = self:_applyWalletCap(userId, "MM", amount)
            if capped <= 0 then
                return true, nil, 0
            end
            local wallet = self:_ensureWallet(userId)
            wallet.MM += capped
            self:_publish("CurrencyChanged", {
                player = player,
                userId = userId,
                currency = "MM",
                delta = capped,
                balance = wallet.MM,
                reason = reason,
            })
            return true, nil, capped
        end
        local granted = self:_addMMWithCap(player, amount, reason or "manual_add")
        return granted > 0, nil, granted
    end
    if currency == "Robux" then
        local capped = self:_applyWalletCap(userId, "Robux", amount)
        if capped <= 0 then
            return true, nil, 0
        end
        local wallet = self:_ensureWallet(userId)
        wallet.Robux = (wallet.Robux or 0) + capped
        self:_publish("CurrencyChanged", {
            player = player,
            userId = userId,
            currency = "Robux",
            delta = capped,
            balance = wallet.Robux,
            reason = reason or "manual_add",
        })
        return true, nil, capped
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

function Service:GrantMissionReward(userIdOrPlayer, missionReward)
    local userId = toUserId(userIdOrPlayer)
    if not userId or type(missionReward) ~= "table" then
        return false, "invalid_payload"
    end

    local mmAmount = math.max(0, math.floor(tonumber(missionReward.mm) or 0))
    if mmAmount <= 0 then
        return true, nil, 0
    end

    local ok, _, granted = self:AddCurrency(userId, "MM", mmAmount, missionReward.source or "DailyMission")
    if ok and (granted or 0) > 0 then
        self:_publish("CurrencyEarned", {
            userId = userId,
            amount = granted,
            currency = "MM",
            source = missionReward.source or "DailyMission",
        })
    end

    return ok, nil, granted
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

function Service:GetPassOwnership(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end
    return cloneTable(self:_ensurePass(userId))
end

function Service:HasPass(player, passKey)
    if type(passKey) ~= "string" or passKey == "" then
        return false
    end
    local passes = self:GetPassOwnership(player)
    return passes[passKey] == true
end

function Service:GrantMissionCompleted(player)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local awarded = self:_addMMWithCap(player, MISSION_REWARD, "daily_mission")

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

    local awarded = self:_addMMWithCap(player, ALL_MISSION_BONUS, "daily_mission_all")
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

function Service:GrantMatchReward(payload)
    local rewardPayload = type(payload) == "table" and payload or {}
    local entry = type(rewardPayload.entry) == "table" and rewardPayload.entry or rewardPayload
    local playerOrUserId = entry.player or entry.userId or rewardPayload.player or rewardPayload.userId
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false, "invalid_player"
    end

    local matchId = type(rewardPayload.matchId) == "string" and rewardPayload.matchId
        or (type(entry.matchId) == "string" and entry.matchId or nil)
    if self:_markMatchRewardGranted(matchId, userId) then
        return false, "already_rewarded"
    end

    local performance = math.clamp(
        math.floor(tonumber(entry.performancePercent or entry.performance or rewardPayload.performancePercent or 60) or 60),
        0,
        100
    )
    local survived = (entry.survived ~= false) and (rewardPayload.survived ~= false)
    local extracted = entry.extracted == true or rewardPayload.extracted == true

    local mmAmount = MATCH_MM_BASE + (performance * MATCH_MM_PERFORMANCE_MULTIPLIER)
    if survived then
        mmAmount += MATCH_SURVIVE_BONUS_MM
    end
    if extracted then
        mmAmount += MATCH_EXTRACT_BONUS_MM
    end
    local mmAwarded = self:_addMMWithCap(playerOrUserId, mmAmount, "match_completion")

    local ppAmount = MATCH_PP_BASE
    if performance >= MATCH_PP_THRESHOLD_A then
        ppAmount += 1
    end
    if performance >= MATCH_PP_THRESHOLD_B then
        ppAmount += 1
    end
    if extracted then
        ppAmount += MATCH_PP_EXTRACT_BONUS
    end
    if not survived then
        ppAmount = math.max(ppAmount - 1, 0)
    end
    ppAmount = math.clamp(ppAmount, 0, MATCH_PP_MAX)

    local ppAwarded = 0
    if ppAmount > 0 then
        local ppOk, _, ppGranted = self:AddCurrency(playerOrUserId, "PP", ppAmount, "match_completion")
        if ppOk == true then
            ppAwarded = math.max(0, math.floor(tonumber(ppGranted) or ppAmount))
        end
    end

    local emitted = {
        player = playerOrUserId,
        userId = userId,
        matchId = matchId,
        currency = "MM",
        amount = mmAwarded,
        ppReward = ppAwarded,
        performancePercent = performance,
        survived = survived,
        extracted = extracted,
        reason = rewardPayload.reason or "MatchCompletion",
        context = "MatchCompletion",
    }
    self:_publish("CurrencyEarned", emitted)
    self:_publish("RewardGranted", emitted)
    self:_publish("PlayerRewardGranted", emitted)
    self:_publish("RewardsGranted", emitted)

    return true, nil, emitted
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

return Service

