local Service = {}
Service.__index = Service

local RankTiersResolver = require(script.Parent.Parent.Core.RankTiersResolver)

local function resolveEventBus(deps)
    local eventBus = deps and deps.EventBus
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
    local profile = deps and deps.ProfileSystem
    if type(profile) ~= "table" then
        return nil
    end
    if type(profile.AddExperience) == "function" and type(profile.GetPlayerLevel) == "function" then
        return profile
    end
    if type(profile.Service) == "table"
        and type(profile.Service.AddExperience) == "function"
        and type(profile.Service.GetPlayerLevel) == "function" then
        return profile.Service
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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._profile = resolveProfileService(self._deps)
    self._rankTiers = RankTiersResolver.Resolve(self._deps)
    return self
end

function Service:Init()
    self._state:Set("expByUserId", self._state:Get("expByUserId") or {})
    self._state:Set("levelByUserId", self._state:Get("levelByUserId") or {})
end

function Service:Start()
    -- Event-driven service only.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_setProgressSnapshot(playerOrUserId, expGranted, levelAfter)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return
    end
    local expByUserId = self._state:Get("expByUserId") or {}
    expByUserId[userId] = (expByUserId[userId] or 0) + expGranted
    self._state:Set("expByUserId", expByUserId)

    local levelByUserId = self._state:Get("levelByUserId") or {}
    levelByUserId[userId] = levelAfter
    self._state:Set("levelByUserId", levelByUserId)
end

function Service:_getTierForLevel(level)
    local selected = self._rankTiers[1]
    local targetLevel = math.max(math.floor(level or 1), 1)
    for _, tier in ipairs(self._rankTiers) do
        if targetLevel >= (tier.level or 1) then
            selected = tier
        else
            break
        end
    end
    return selected
end

function Service:GrantExperience(playerOrUserId, amount, reason, context)
    if not self._profile then
        return false, "missing_profile"
    end

    local userId = toUserId(playerOrUserId)
    if not userId then
        return false, "invalid_player"
    end

    local exp = math.max(math.floor(amount or 0), 0)
    if exp <= 0 then
        return true
    end

    local levelBefore = self._profile:GetPlayerLevel(playerOrUserId) or 1
    local ok, err, levelAfter = self._profile:AddExperience(playerOrUserId, exp)
    if not ok then
        return false, err or "failed_to_add_experience"
    end

    self:_setProgressSnapshot(playerOrUserId, exp, levelAfter)
    local tierBefore = self:_getTierForLevel(levelBefore)
    local tierAfter = self:_getTierForLevel(levelAfter)

    self:_publish("ExperienceGranted", {
        player = type(playerOrUserId) == "number" and nil or playerOrUserId,
        userId = userId,
        amount = exp,
        levelBefore = levelBefore,
        levelAfter = levelAfter,
        tierBefore = tierBefore and tierBefore.name or nil,
        tierAfter = tierAfter and tierAfter.name or nil,
        tierLevelBefore = tierBefore and tierBefore.level or nil,
        tierLevelAfter = tierAfter and tierAfter.level or nil,
        tierXpRequiredBefore = tierBefore and tierBefore.xpRequired or nil,
        tierXpRequiredAfter = tierAfter and tierAfter.xpRequired or nil,
        reason = reason or "progression",
        context = context,
    })

    if levelAfter > levelBefore then
        self:_publish("LevelUp", {
            player = type(playerOrUserId) == "number" and nil or playerOrUserId,
            userId = userId,
            levelBefore = levelBefore,
            levelAfter = levelAfter,
            tierBefore = tierBefore and tierBefore.name or nil,
            tierAfter = tierAfter and tierAfter.name or nil,
            tierLevelBefore = tierBefore and tierBefore.level or nil,
            tierLevelAfter = tierAfter and tierAfter.level or nil,
            tierXpRequiredBefore = tierBefore and tierBefore.xpRequired or nil,
            tierXpRequiredAfter = tierAfter and tierAfter.xpRequired or nil,
            reason = reason or "progression",
            context = context,
        })
    end

    return true, nil, levelAfter
end

function Service:OnPlayerRewardGranted(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    local currency = payload and payload.currency
    local amount = payload and payload.amount or 0
    if currency ~= "MM" then
        return
    end

    local exp = math.max(math.floor(amount / 10), 1)
    self:GrantExperience(playerOrUserId, exp, "player_reward", payload)
end

return Service
