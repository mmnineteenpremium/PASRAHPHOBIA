local RankTiersResolver = require(script.Parent.Parent.Core.RankTiersResolver)
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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
    if type(profile.GetPlayerLevel) == "function" then
        return profile
    end
    if type(profile.Service) == "table" and type(profile.Service.GetPlayerLevel) == "function" then
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

local function resolveRankPoints(sourceEvent, context)
    if sourceEvent == "MatchEnded" then
        if context and context.survived == true then
            return 20
        end
        return 12
    end
    if sourceEvent == "MissionCompleted" then
        return 15
    end
    if sourceEvent == "ContractCompleted" then
        return 25
    end
    return 0
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._profile = resolveProfileService(self._deps)
    self._rankTiers = RankTiersResolver.Resolve(self._deps)
    self._tierByName = {}
    for _, tier in ipairs(self._rankTiers) do
        self._tierByName[tier.name] = tier
    end
    return self
end

function Service:Init()
    self._state:Set("rankByUserId", self._state:Get("rankByUserId") or {})
end

function Service:Start()
    -- Event-driven rank tracking.
    self:_ensureProfile()
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_ensureProfile()
    if self._profile then
        return
    end
    self._profile = resolveProfileService(self._deps)
end

function Service:_ranks()
    return self._state:Get("rankByUserId") or {}
end

function Service:_setRanks(rankByUserId)
    self._state:Set("rankByUserId", rankByUserId)
end

function Service:_getTierForLevel(level)
    local selected = self._rankTiers[1]
    local target = math.max(math.floor(level or 1), 1)
    for _, tier in ipairs(self._rankTiers) do
        if target >= (tier.level or 1) then
            selected = tier
        else
            break
        end
    end
    return selected
end

function Service:_ensureRank(userId)
    local ranks = self:_ranks()
    if not ranks[userId] then
        local initialTier = self._rankTiers[1] or { level = 1, name = "Rookie", xpRequired = 0 }
        ranks[userId] = {
            userId = userId,
            level = initialTier.level or 1,
            tier = initialTier.name,
            tierLevel = initialTier.level or 1,
            tierXpRequired = initialTier.xpRequired or 0,
        }
        self:_setRanks(ranks)
    end
    return ranks[userId]
end

function Service:GetPlayerRank(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end
    local rank = self:_ensureRank(userId)
    return {
        userId = rank.userId,
        level = rank.level,
        tier = rank.tier,
        tierLevel = rank.tierLevel,
        tierXpRequired = rank.tierXpRequired,
    }
end

function Service:SyncRank(playerOrUserId, level, sourceEvent, context)
    self:_ensureProfile()
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false, "invalid_player"
    end

    local resolvedLevel = level
    if not resolvedLevel and self._profile then
        resolvedLevel = self._profile:GetPlayerLevel(playerOrUserId)
    end
    resolvedLevel = math.max(math.floor(resolvedLevel or 1), 1)

    local rank = self:_ensureRank(userId)
    local previousTier = rank.tier
    local previousTierLevel = rank.tierLevel
    local tier = self:_getTierForLevel(resolvedLevel)
    rank.level = resolvedLevel
    rank.tier = tier and tier.name or rank.tier
    rank.tierLevel = tier and (tier.level or rank.tierLevel) or rank.tierLevel
    rank.tierXpRequired = tier and (tier.xpRequired or rank.tierXpRequired) or rank.tierXpRequired

    local rankPayload = {
        player = type(playerOrUserId) == "number" and nil or playerOrUserId,
        userId = userId,
        level = rank.level,
        tier = rank.tier,
        tierLevel = rank.tierLevel,
        tierXpRequired = rank.tierXpRequired,
        didRankUp = previousTier ~= rank.tier,
        didPromote = rank.tierLevel > (previousTierLevel or rank.tierLevel),
        didDemote = rank.tierLevel < (previousTierLevel or rank.tierLevel),
        sourceEvent = sourceEvent,
        context = context,
    }
    self:_publish("RankUpdated", rankPayload)
    self:_publish("PlayerRankUpdated", rankPayload)

    if rankPayload.didPromote then
        self:_publish("RankPromotion", rankPayload)
    elseif rankPayload.didDemote then
        self:_publish("RankDemotion", rankPayload)
    end

    local rankPoints = resolveRankPoints(sourceEvent, context)
    if rankPoints > 0 then
        self:_publish("RankPointsEarned", {
            player = type(playerOrUserId) == "number" and nil or playerOrUserId,
            userId = userId,
            amount = rankPoints,
            sourceEvent = sourceEvent,
            context = context,
        })
    end

    return true, nil, self:GetPlayerRank(userId)
end

function Service:OnExperienceGranted(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    local level = payload and (payload.levelAfter or payload.level)
    self:SyncRank(playerOrUserId, level, "ExperienceGranted", payload)
end

function Service:OnXPGranted(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    local level = payload and (payload.levelAfter or payload.level)
    self:SyncRank(playerOrUserId, level, "XPGranted", payload)
end

function Service:OnLevelUp(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    local level = payload and (payload.levelAfter or payload.level)
    self:SyncRank(playerOrUserId, level, "LevelUp", payload)
end

function Service:OnRankUp(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    if not playerOrUserId then
        return
    end

    local level = payload and (payload.levelAfter or payload.level)
    if not level then
        local tierName = payload and payload.tier
        local tier = tierName and self._tierByName[tierName]
        level = tier and tier.level or nil
    end
    self:SyncRank(playerOrUserId, level, "RankUp", payload)
end

return Service
