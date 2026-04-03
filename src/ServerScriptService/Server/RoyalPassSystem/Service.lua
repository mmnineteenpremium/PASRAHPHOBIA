local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local TIER_XP = 200
local MAX_TIER = 50

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
    local fn = target[methodName]
    if type(fn) ~= "function" then
        return nil
    end
    local ok, result = pcall(fn, target, ...)
    if not ok then
        return nil
    end
    return result
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
end

function Service:Init()
    self._state:Set("playerXP", self._state:Get("playerXP") or {})
    self._state:Set("tierProgress", self._state:Get("tierProgress") or {})
    self._state:Set("unlockedTiers", self._state:Get("unlockedTiers") or {})
    self._state:Set("premiumOwners", self._state:Get("premiumOwners") or {})
    self._state:Set("seasonId", self._state:Get("seasonId") or "S1")
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

function Service:_ensurePlayerState(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local playerXP = self._state:Get("playerXP") or {}
    local tierProgress = self._state:Get("tierProgress") or {}
    local unlockedTiers = self._state:Get("unlockedTiers") or {}

    playerXP[userId] = math.max(0, math.floor(tonumber(playerXP[userId]) or 0))
    tierProgress[userId] = math.max(1, math.floor(tonumber(tierProgress[userId]) or 1))
    unlockedTiers[userId] = unlockedTiers[userId] or {}

    self._state:Set("playerXP", playerXP)
    self._state:Set("tierProgress", tierProgress)
    self._state:Set("unlockedTiers", unlockedTiers)
    return userId
end

function Service:_rewardForTier(tier, premium)
    local reward = {
        currency = 100 + (tier * 20),
        xp = 25 + (tier * 5),
    }
    if premium then
        reward.currency += 50
    end
    return reward
end

function Service:GetPlayerSnapshot(player)
    local userId = self:_ensurePlayerState(player)
    if not userId then
        return nil
    end

    local playerXP = self._state:Get("playerXP") or {}
    local tierProgress = self._state:Get("tierProgress") or {}
    local unlockedTiers = self._state:Get("unlockedTiers") or {}
    local premiumOwners = self._state:Get("premiumOwners") or {}

    local totalXP = math.max(0, math.floor(tonumber(playerXP[userId]) or 0))
    local currentTier = math.clamp(math.floor(tonumber(tierProgress[userId]) or 1), 1, MAX_TIER)
    local tierBaseXP = math.max(0, (currentTier - 1) * TIER_XP)
    local currentTierXP = math.clamp(totalXP - tierBaseXP, 0, TIER_XP)
    local remainingXP = currentTier >= MAX_TIER and 0 or math.max(0, TIER_XP - currentTierXP)
    local premiumOwned = premiumOwners[userId] == true

    local unlockedList = {}
    local unlockedByTier = unlockedTiers[userId] or {}
    for tier, isUnlocked in pairs(unlockedByTier) do
        if isUnlocked == true then
            local numericTier = tonumber(tier)
            if numericTier and numericTier >= 1 and numericTier <= MAX_TIER then
                table.insert(unlockedList, math.floor(numericTier))
            end
        end
    end
    table.sort(unlockedList)

    local nextTier = currentTier < MAX_TIER and (currentTier + 1) or nil
    local nextReward = nextTier and self:_rewardForTier(nextTier, premiumOwned) or nil

    return {
        userId = userId,
        seasonId = self._state:Get("seasonId"),
        totalXP = totalXP,
        currentTier = currentTier,
        maxTier = MAX_TIER,
        xpPerTier = TIER_XP,
        currentTierXP = currentTierXP,
        remainingXP = remainingXP,
        progressPercent = TIER_XP > 0 and math.clamp(currentTierXP / TIER_XP, 0, 1) or 0,
        premiumOwned = premiumOwned,
        unlockedTiers = unlockedList,
        unlockedTierCount = #unlockedList,
        nextTier = nextTier,
        nextReward = nextReward,
    }
end

function Service:_grantTierReward(player, tier)
    local userId = self:_ensurePlayerState(player)
    if not userId then
        return
    end

    local premiumOwners = self._state:Get("premiumOwners") or {}
    local reward = self:_rewardForTier(tier, premiumOwners[userId] == true)
    local economy = self._dependencies.EconomySystem

    local granted = false
    granted = safeCall(economy, "GrantCurrency", player, reward.currency, "RoyalPass") == true or granted
    granted = safeCall(economy, "AddCurrency", player, reward.currency, "RoyalPass") == true or granted

    if not granted then
        self:_publish("CurrencyEarned", {
            player = player,
            amount = reward.currency,
            source = "RoyalPass",
        })
    end

    self:_publish("RewardGranted", {
        player = player,
        xp = reward.xp,
        source = "RoyalPass",
    })
end

function Service:SetPremiumOwnership(player, ownsPremium)
    local userId = self:_ensurePlayerState(player)
    if not userId then
        return false, "invalid_player"
    end

    local premiumOwners = self._state:Get("premiumOwners") or {}
    premiumOwners[userId] = ownsPremium == true
    self._state:Set("premiumOwners", premiumOwners)

    self:_publish("RoyalPassPremiumOwnershipChanged", {
        player = player,
        userId = userId,
        ownsPremium = premiumOwners[userId] == true,
        seasonId = self._state:Get("seasonId"),
    })
    return true
end

function Service:AddXP(player, amount, source)
    local userId = self:_ensurePlayerState(player)
    if not userId then
        return false, "invalid_player"
    end

    local xpAmount = math.max(0, math.floor(tonumber(amount) or 0))
    if xpAmount <= 0 then
        return true
    end

    local playerXP = self._state:Get("playerXP") or {}
    local tierProgress = self._state:Get("tierProgress") or {}
    local unlockedTiers = self._state:Get("unlockedTiers") or {}

    playerXP[userId] = (playerXP[userId] or 0) + xpAmount
    local targetTier = math.clamp(math.floor(playerXP[userId] / TIER_XP) + 1, 1, MAX_TIER)
    local currentTier = tierProgress[userId] or 1

    self._state:Set("playerXP", playerXP)

    self:_publish("RoyalPassXPGranted", {
        player = player,
        userId = userId,
        amount = xpAmount,
        totalXP = playerXP[userId],
        source = source,
    })

    while currentTier < targetTier do
        currentTier += 1
        tierProgress[userId] = currentTier
        unlockedTiers[userId][currentTier] = true
        self:_grantTierReward(player, currentTier)

        self:_publish("RoyalPassTierUnlocked", {
            player = player,
            userId = userId,
            tier = currentTier,
            seasonId = self._state:Get("seasonId"),
        })
    end

    self._state:Set("tierProgress", tierProgress)
    self._state:Set("unlockedTiers", unlockedTiers)
    return true
end

function Service:OnMatchEnded(payload)
    if type(payload) ~= "table" then
        return
    end

    local base = 120
    local difficulty = tonumber(payload.difficulty or payload.difficultyMultiplier or 1) or 1
    local bonus = math.max(0, math.floor((difficulty - 1) * 40))
    local total = base + bonus

    if payload.player then
        self:AddXP(payload.player, total, "MatchEnded")
        return
    end

    if type(payload.results) == "table" and type(payload.results.playerResults) == "table" then
        for _, result in ipairs(payload.results.playerResults) do
            local player = result.player or result.userId
            if player then
                local resultBonus = result.didWin == true and 40 or 0
                self:AddXP(player, total + resultBonus, "MatchEnded")
            end
        end
    elseif type(payload.players) == "table" then
        for _, player in ipairs(payload.players) do
            self:AddXP(player, total, "MatchEnded")
        end
    end
end

function Service:OnMissionCompleted(payload)
    if type(payload) ~= "table" or not payload.player then
        return
    end
    self:AddXP(payload.player, tonumber(payload.royalPassXP) or 100, "MissionCompleted")
end

function Service:OnXPGranted(payload)
    if type(payload) ~= "table" or not payload.player then
        return
    end
    local bonus = math.max(0, math.floor((tonumber(payload.amount) or 0) * 0.2))
    self:AddXP(payload.player, bonus, "XPGranted")
end

return Service
