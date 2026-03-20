local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local REWARD_BY_STREAK = {
    [1] = { currency = 100, xp = 30 },
    [2] = { currency = 150, xp = 40 },
    [3] = { currency = 200, xp = 50 },
    [4] = { currency = 250, xp = 60 },
    [5] = { currency = 300, xp = 70 },
    [6] = { currency = 350, xp = 80 },
    [7] = { currency = 500, xp = 100, cosmetic = "DailyStreakBadge" },
}

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

local function dayKeyFromTimestamp(ts)
    if type(ts) ~= "number" then
        return nil
    end
    return os.date("!%Y-%m-%d", ts)
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
    self._state:Set("lastLoginDate", self._state:Get("lastLoginDate") or {})
    self._state:Set("streakCount", self._state:Get("streakCount") or {})
    self._state:Set("lastClaim", self._state:Get("lastClaim") or {})
    self._state:Set("claimHistory", self._state:Get("claimHistory") or {})
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

function Service:_todayKey()
    return os.date("!%Y-%m-%d")
end

function Service:_ensurePlayerState(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local lastLoginDate = self._state:Get("lastLoginDate") or {}
    local streakCount = self._state:Get("streakCount") or {}
    local lastClaim = self._state:Get("lastClaim") or {}
    local claimHistory = self._state:Get("claimHistory") or {}

    streakCount[userId] = tonumber(streakCount[userId]) or 0
    claimHistory[userId] = claimHistory[userId] or {}

    self._state:Set("lastLoginDate", lastLoginDate)
    self._state:Set("streakCount", streakCount)
    self._state:Set("lastClaim", lastClaim)
    self._state:Set("claimHistory", claimHistory)

    return userId
end

function Service:_computeReward(streak)
    local normalized = math.clamp(math.floor(tonumber(streak) or 1), 1, 7)
    return REWARD_BY_STREAK[normalized] or REWARD_BY_STREAK[1]
end

function Service:_grantReward(player, reward)
    local economySystem = self._dependencies.EconomySystem
    local currency = math.max(0, math.floor(tonumber(reward.currency) or 0))
    local xp = math.max(0, math.floor(tonumber(reward.xp) or 0))

    if currency > 0 then
        local granted = false
        granted = safeCall(economySystem, "GrantCurrency", player, currency, "DailyCheckin") == true or granted
        granted = safeCall(economySystem, "AddCurrency", player, currency, "DailyCheckin") == true or granted
        if not granted then
            self:_publish("CurrencyEarned", {
                player = player,
                amount = currency,
                source = "DailyCheckin",
            })
        end
    end

    if xp > 0 then
        self:_publish("RewardGranted", {
            player = player,
            xp = xp,
            source = "DailyCheckin",
        })
    end

    if reward.cosmetic then
        self:_publish("RewardGranted", {
            player = player,
            cosmeticId = reward.cosmetic,
            source = "DailyCheckin",
        })
    end
end

function Service:OnPlayerJoinedLobby(payload)
    local player = payload and payload.player or payload
    local userId = self:_ensurePlayerState(player)
    if not userId then
        return
    end

    local today = self:_todayKey()
    local lastLoginDate = self._state:Get("lastLoginDate") or {}
    local streakCount = self._state:Get("streakCount") or {}

    local previousDate = lastLoginDate[userId]
    if previousDate ~= today then
        if previousDate then
            local yesterday = dayKeyFromTimestamp(os.time() - 86400)
            if previousDate == yesterday then
                streakCount[userId] = math.min((streakCount[userId] or 0) + 1, 7)
            else
                streakCount[userId] = 1
            end
        else
            streakCount[userId] = 1
        end
        lastLoginDate[userId] = today
    elseif (streakCount[userId] or 0) <= 0 then
        streakCount[userId] = 1
    end

    self._state:Set("lastLoginDate", lastLoginDate)
    self._state:Set("streakCount", streakCount)

    local reward = self:_computeReward(streakCount[userId])
    self:_publish("DailyRewardAvailable", {
        player = player,
        userId = userId,
        date = today,
        streak = streakCount[userId],
        reward = reward,
    })
end

function Service:ClaimDailyReward(player)
    local userId = self:_ensurePlayerState(player)
    if not userId then
        return false, "invalid_player"
    end

    local today = self:_todayKey()
    local lastClaim = self._state:Get("lastClaim") or {}
    if lastClaim[userId] == today then
        return false, "already_claimed"
    end

    local streakCount = self._state:Get("streakCount") or {}
    if (streakCount[userId] or 0) <= 0 then
        streakCount[userId] = 1
        self._state:Set("streakCount", streakCount)
    end

    local reward = self:_computeReward(streakCount[userId])
    self:_grantReward(player, reward)

    lastClaim[userId] = today
    self._state:Set("lastClaim", lastClaim)

    local claimHistory = self._state:Get("claimHistory") or {}
    claimHistory[userId] = claimHistory[userId] or {}
    table.insert(claimHistory[userId], {
        date = today,
        streak = streakCount[userId],
        reward = reward,
    })
    self._state:Set("claimHistory", claimHistory)

    self:_publish("DailyRewardClaimed", {
        player = player,
        userId = userId,
        date = today,
        streak = streakCount[userId],
        reward = reward,
    })

    return true
end

function Service:OnDailyRewardClaimRequest(payload)
    local player = payload and payload.player or payload
    if player then
        self:ClaimDailyReward(player)
    end
end

return Service