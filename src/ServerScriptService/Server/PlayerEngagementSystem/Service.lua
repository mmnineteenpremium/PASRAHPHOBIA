local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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

local function resolveGameDataModule(moduleName)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
    if not shared then
        return nil
    end
    local gameData = shared:FindFirstChild("GameData")
    if not gameData then
        return nil
    end
    return gameData:FindFirstChild(moduleName)
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

local function safeCall(target, methodName, ...)
    if type(target) ~= "table" then
        return nil
    end
    local fn = target[methodName]
    if type(fn) ~= "function" then
        return nil
    end
    local ok, a = pcall(fn, target, ...)
    if not ok then
        return nil
    end
    return a
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
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
    }
    self:ReloadConfig()
end

function Service:Start()
end

function Service:Stop()
    self._state:Clear()
end

function Service:ReloadConfig()
    local cfg = safeRequire(resolveGameDataModule("GlobalOperationsConfig")) or {}
    self._state:Set("config", cfg)

    local seasons = cfg.Seasons or {}
    local nowUnix = os.time()
    local lengthDays = math.max(7, math.floor(tonumber(seasons.SeasonLengthDays) or 90))
    self._state:Set("season", {
        seasonId = tostring(seasons.CurrentSeasonId or "S1"),
        seasonStart = nowUnix,
        seasonEnd = nowUnix + (lengthDays * 86400),
    })
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_grantReturningRewards(userId)
    local cfg = self._state:Get("config") or {}
    local engage = cfg.Engagement or {}
    local reward = engage.ReturningPlayerReward or {}

    local currency = math.max(0, math.floor(tonumber(reward.currency) or 0))
    local xp = math.max(0, math.floor(tonumber(reward.xp) or 0))

    if currency > 0 then
        safeCall(self._dependencies.EconomySystem, "AddCurrency", userId, "MM", currency, "ReturningPlayer")
    end

    self:_publish("ReturningPlayerRewardGranted", {
        userId = userId,
        currency = currency,
        xp = xp,
    })
end

function Service:OnPlayerAdded(payload)
    local userId = toUserId(payload and (payload.player or payload.userId) or payload)
    if not userId then
        return
    end

    local lastSeen = self._state:Get("lastSeenByUserId") or {}
    local nowUnix = os.time()

    local cfg = self._state:Get("config") or {}
    local days = ((cfg.Engagement or {}).ReturningPlayerDays) or 7

    if type(lastSeen[userId]) == "number" and (nowUnix - lastSeen[userId]) >= (days * 86400) then
        self:_grantReturningRewards(userId)
    end

    lastSeen[userId] = nowUnix
    self._state:Set("lastSeenByUserId", lastSeen)
end

function Service:_addSeasonPassXp(userId, amount, reason)
    local map = self._state:Get("seasonPassXpByUserId") or {}
    map[userId] = (map[userId] or 0) + amount
    self._state:Set("seasonPassXpByUserId", map)

    self:_publish("SeasonPassProgressUpdated", {
        userId = userId,
        xp = map[userId],
        delta = amount,
        reason = reason,
        season = self._state:Get("season"),
    })
end

function Service:_updateAchievement(userId, achievementId, delta)
    local all = self._state:Get("achievementsByUserId") or {}
    all[userId] = all[userId] or {}

    local value = (all[userId][achievementId] or 0) + (delta or 1)
    all[userId][achievementId] = value
    self._state:Set("achievementsByUserId", all)

    self:_publish("AchievementProgressUpdated", {
        userId = userId,
        achievementId = achievementId,
        value = value,
    })

    if achievementId == "InvestigationsCompleted" and value == 100 then
        self:_publish("AchievementUnlocked", {
            userId = userId,
            achievementId = "Investigations100",
        })
    end
    if achievementId == "GhostIdentifications" and value == 50 then
        self:_publish("AchievementUnlocked", {
            userId = userId,
            achievementId = "GhostIdentifications50",
        })
    end
end

function Service:OnMatchEnded(payload)
    local cfg = self._state:Get("config") or {}
    local seasonCfg = cfg.Seasons or {}
    local passXpPerMatch = math.max(0, math.floor(tonumber(seasonCfg.PassXpPerMatch) or 120))

    local outcome = payload and payload.results and payload.results.playerOutcome or {}
    for key, entry in pairs(outcome) do
        local userId = tonumber(key) or entry.userId
        if userId then
            self:_addSeasonPassXp(userId, passXpPerMatch, "match_completed")
            self:_updateAchievement(userId, "InvestigationsCompleted", 1)

            if entry.ghostIdentified == true then
                self:_updateAchievement(userId, "GhostIdentifications", 1)
            end
        end
    end
end

function Service:OnGhostIdentified(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end

    local cfg = self._state:Get("config") or {}
    local seasonCfg = cfg.Seasons or {}
    local xp = math.max(0, math.floor(tonumber(seasonCfg.PassXpPerObjective) or 45))
    self:_addSeasonPassXp(userId, xp, "ghost_identified")
    self:_updateAchievement(userId, "GhostIdentifications", 1)
end

function Service:OnContentRegistered(payload)
    local notices = self._state:Get("contentNoticesByUserId") or {}
    local timestamp = os.time()

    for userId in pairs(self._state:Get("lastSeenByUserId") or {}) do
        notices[userId] = notices[userId] or {}
        table.insert(notices[userId], {
            contentCategory = payload.category,
            contentId = payload.id,
            discoveredAt = timestamp,
        })
    end

    self._state:Set("contentNoticesByUserId", notices)
    self:_publish("ContentDiscoveryNoticeCreated", {
        category = payload.category,
        id = payload.id,
        at = timestamp,
    })
end

function Service:OnProfileShowcaseRequested(payload)
    local userId = toUserId(payload and (payload.userId or payload.player))
    if not userId then
        return
    end

    local showcase = {
        seasonPassXp = (self._state:Get("seasonPassXpByUserId") or {})[userId] or 0,
        achievements = (self._state:Get("achievementsByUserId") or {})[userId] or {},
        season = self._state:Get("season"),
    }

    local cache = self._state:Get("profileShowcaseByUserId") or {}
    cache[userId] = showcase
    self._state:Set("profileShowcaseByUserId", cache)

    self:_publish("PlayerProfileShowcaseResolved", {
        userId = userId,
        showcase = showcase,
    })
end

return Service
