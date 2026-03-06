local Service = {}
Service.__index = Service

local Services = require(script.Parent.Parent.Core.Services)

local MAX_LEVEL = 100
local BASE_XP_TABLE = {
    [1] = 0,
    [2] = 100,
    [3] = 250,
    [4] = 500,
    [5] = 900,
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

local function resolveProfileService(deps)
    local profile = Services.Get(deps, "ProfileSystem")
    if type(profile) ~= "table" then
        return nil
    end
    if type(profile.GetPlayerProfile) == "function" and type(profile.GetPlayerLevel) == "function" then
        return profile
    end
    if type(profile.Service) == "table"
        and type(profile.Service.GetPlayerProfile) == "function"
        and type(profile.Service.GetPlayerLevel) == "function" then
        return profile.Service
    end
    return nil
end

local function resolvePersistenceService(deps)
    local persistence = Services.Get(deps, "DataPersistenceService")
    if type(persistence) ~= "table" then
        return nil
    end
    if type(persistence.SaveProfile) == "function" then
        return persistence
    end
    if type(persistence.Service) == "table" and type(persistence.Service.SaveProfile) == "function" then
        return persistence.Service
    end
    return nil
end

local function buildXpTable(maxLevel)
    local xpTable = {}
    for level = 1, maxLevel do
        if BASE_XP_TABLE[level] then
            xpTable[level] = BASE_XP_TABLE[level]
        else
            local previous = xpTable[level - 1] or 0
            local growth = math.floor((level - 1) * (level - 1) * 12 + 100)
            xpTable[level] = previous + growth
        end
    end
    return xpTable
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._profile = resolveProfileService(self._deps)
    self._persistence = resolvePersistenceService(self._deps)
    return self
end

function Service:Init()
    self._state:Set("xpTable", self._state:Get("xpTable") or buildXpTable(MAX_LEVEL))
    self._state:Set("recentLevelUps", self._state:Get("recentLevelUps") or {})
    self._state:Set("playerProgress", self._state:Get("playerProgress") or {})
end

function Service:Start()
    -- Event-driven progression service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_progressByUserId()
    return self._state:Get("playerProgress") or {}
end

function Service:_setProgressByUserId(progressByUserId)
    self._state:Set("playerProgress", progressByUserId)
end

function Service:_resolveInitialProgress(playerOrUserId, userId)
    local level = 1
    local totalXP = 0
    if self._profile then
        if type(self._profile.GetPlayerLevel) == "function" then
            level = self._profile:GetPlayerLevel(playerOrUserId) or level
        end
        if type(self._profile.GetPlayerProfile) == "function" then
            local profile = self._profile:GetPlayerProfile(playerOrUserId)
            local progression = profile and profile.progression or {}
            local xpInLevel = progression.exp or 0
            local levelStartXP = (self._state:Get("xpTable") or {})[level] or 0
            totalXP = math.max(levelStartXP + xpInLevel, 0)
        end
    end
    return {
        userId = userId,
        level = math.max(math.floor(level), 1),
        totalXP = math.max(math.floor(totalXP), 0),
    }
end

function Service:_ensureProgress(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end
    local progressByUserId = self:_progressByUserId()
    if not progressByUserId[userId] then
        progressByUserId[userId] = self:_resolveInitialProgress(playerOrUserId, userId)
        self:_setProgressByUserId(progressByUserId)
    end
    return progressByUserId[userId]
end

function Service:_recordLevelUp(userId, fromLevel, toLevel, payload)
    local recent = self._state:Get("recentLevelUps") or {}
    recent[userId] = recent[userId] or {}
    table.insert(recent[userId], {
        fromLevel = fromLevel,
        toLevel = toLevel,
        at = os.time(),
        payload = payload,
    })
    self._state:Set("recentLevelUps", recent)
end

function Service:_syncProgressSnapshot(userId, level, totalXP)
    if not self._persistence or type(self._persistence.SaveProfile) ~= "function" then
        return
    end
    self._persistence:SaveProfile(userId, {
        playerLevel = level,
        playerXP = totalXP,
    })
end

function Service:GetLevel(playerOrUserId)
    local progress = self:_ensureProgress(playerOrUserId)
    return progress and progress.level or nil
end

function Service:AddXP(playerOrUserId, amount)
    local progress = self:_ensureProgress(playerOrUserId)
    if not progress then
        return false, "invalid_player"
    end
    local xpToAdd = math.max(math.floor(amount or 0), 0)
    if xpToAdd <= 0 then
        return true, nil, progress.totalXP
    end
    progress.totalXP += xpToAdd
    return true, nil, progress.totalXP
end

function Service:CheckLevelUp(playerOrUserId)
    local progress = self:_ensureProgress(playerOrUserId)
    if not progress then
        return false, "invalid_player"
    end

    local xpTable = self._state:Get("xpTable") or {}
    local previousLevel = progress.level
    local nextLevel = previousLevel + 1

    while nextLevel <= MAX_LEVEL do
        local nextThreshold = xpTable[nextLevel]
        if type(nextThreshold) ~= "number" or progress.totalXP < nextThreshold then
            break
        end
        progress.level = nextLevel
        nextLevel += 1
    end

    if progress.level > previousLevel then
        local userId = progress.userId
        local payload = {
            player = type(playerOrUserId) == "number" and nil or playerOrUserId,
            userId = userId,
            levelBefore = previousLevel,
            levelAfter = progress.level,
            totalXP = progress.totalXP,
        }
        self:_recordLevelUp(userId, previousLevel, progress.level, payload)
        self:_publish("LevelUp", payload)
        self:_syncProgressSnapshot(userId, progress.level, progress.totalXP)
    end

    return true, nil, progress.level
end

function Service:GrantXP(playerOrUserId, amount, context)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false, "invalid_player"
    end

    local xpAmount = math.max(math.floor(amount or 0), 0)
    if xpAmount <= 0 then
        return true
    end

    local levelBefore = self:GetLevel(playerOrUserId) or 1
    local ok, addErr, totalXP = self:AddXP(playerOrUserId, xpAmount)
    if not ok then
        return false, addErr
    end
    local levelOk, levelErr, levelAfter = self:CheckLevelUp(playerOrUserId)
    if not levelOk then
        return false, levelErr
    end

    self:_publish("XPGranted", {
        player = type(playerOrUserId) == "number" and nil or playerOrUserId,
        userId = userId,
        amount = xpAmount,
        totalXP = totalXP,
        levelBefore = levelBefore,
        levelAfter = levelAfter or levelBefore,
        context = context,
    })

    return true, nil, levelAfter
end

return Service
