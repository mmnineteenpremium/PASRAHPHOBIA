local Service = {}
Service.__index = Service

local RankTiersResolver = require(script.Parent.Parent.Core.RankTiersResolver)

local STARS_PER_FINITE_TIER = 4

local function resolveEventBus(deps)
    local eventBus = deps.EventBus
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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._rankTiers = RankTiersResolver.Resolve(self._deps)
    self._tierNames = {}
    self._tierIndexByName = {}
    self._tierLevelByName = {}
    for index, entry in ipairs(self._rankTiers) do
        self._tierNames[index] = entry.name
        self._tierIndexByName[entry.name] = index
        self._tierLevelByName[entry.name] = entry.level or index
    end
    self._topTierName = self._tierNames[#self._tierNames] or "Rookie"
    self._lastFiniteTierIndex = math.max(#self._tierNames - 1, 1)
    return self
end

function Service:Init()
    self._state:Set("rankByUserId", {})
end

function Service:Start()
    -- Start runtime tasks or loops here.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_ranks()
    return self._state:Get("rankByUserId") or {}
end

function Service:_setRanks(rankByUserId)
    self._state:Set("rankByUserId", rankByUserId)
end

function Service:_ensureRank(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end
    local ranks = self:_ranks()
    if not ranks[userId] then
        ranks[userId] = {
            tier = self._tierNames[1] or "Rookie",
            stars = 0,
            topTierCount = 0,
            ahliCount = 0,
        }
        self:_setRanks(ranks)
    end
    return ranks[userId]
end

function Service:_getTopTierCount(rank)
    local legacy = rank and rank.ahliCount or 0
    local current = rank and rank.topTierCount or 0
    return math.max(legacy, current)
end

function Service:_setTopTierCount(rank, value)
    local normalized = math.max(math.floor(tonumber(value) or 0), 0)
    rank.topTierCount = normalized
    -- Backward compatibility for existing readers.
    rank.ahliCount = normalized
end

function Service:_tierIndex(tier)
    return self._tierIndexByName[tier] or 1
end

function Service:_serializeRank(player, rank)
    local topTierCount = self:_getTopTierCount(rank)
    return {
        player = player,
        userId = toUserId(player),
        tier = rank.tier,
        tierLevel = self._tierLevelByName[rank.tier] or 1,
        stars = rank.stars,
        topTierCount = topTierCount,
        ahliCount = topTierCount,
    }
end

function Service:_emitRankUpdated(player, rank, reason)
    local payload = self:_serializeRank(player, rank)
    payload.reason = reason
    self:_publish("RankUpdated", payload)
end

function Service:GetPlayerRank(player)
    local rank = self:_ensureRank(player)
    if not rank then
        return nil
    end
    local topTierCount = self:_getTopTierCount(rank)
    return {
        tier = rank.tier,
        tierLevel = self._tierLevelByName[rank.tier] or 1,
        stars = rank.stars,
        topTierCount = topTierCount,
        ahliCount = topTierCount,
    }
end

function Service:AddStar(player)
    local rank = self:_ensureRank(player)
    if not rank then
        return nil, "invalid_player"
    end

    if rank.tier == self._topTierName then
        self:_setTopTierCount(rank, self:_getTopTierCount(rank) + 1)
        self:_emitRankUpdated(player, rank, "win")
        return self:GetPlayerRank(player)
    end

    local tierIndex = self:_tierIndex(rank.tier)
    local stars = rank.stars or 0
    stars += 1

    if stars > STARS_PER_FINITE_TIER then
        if tierIndex < self._lastFiniteTierIndex then
            rank.tier = self._tierNames[tierIndex + 1] or self._topTierName
            rank.stars = 1
        else
            rank.tier = self._topTierName
            rank.stars = 0
            self:_setTopTierCount(rank, 1)
        end
    else
        rank.stars = stars
    end

    self:_emitRankUpdated(player, rank, "win")
    return self:GetPlayerRank(player)
end

function Service:RemoveStar(player)
    local rank = self:_ensureRank(player)
    if not rank then
        return nil, "invalid_player"
    end

    if rank.tier == self._topTierName then
        local current = self:_getTopTierCount(rank)
        if current > 0 then
            self:_setTopTierCount(rank, current - 1)
        else
            rank.tier = self._tierNames[self._lastFiniteTierIndex] or self._topTierName
            rank.stars = STARS_PER_FINITE_TIER
            self:_setTopTierCount(rank, 0)
        end
        self:_emitRankUpdated(player, rank, "lose")
        return self:GetPlayerRank(player)
    end

    local tierIndex = self:_tierIndex(rank.tier)
    local stars = rank.stars or 0
    if stars > 0 then
        rank.stars = stars - 1
    elseif tierIndex > 1 then
        rank.tier = self._tierNames[tierIndex - 1] or self._tierNames[1] or self._topTierName
        rank.stars = STARS_PER_FINITE_TIER
    else
        rank.stars = 0
    end

    self:_emitRankUpdated(player, rank, "lose")
    return self:GetPlayerRank(player)
end

function Service:CalculateRankDifficulty(player)
    local rank = self:_ensureRank(player)
    if not rank then
        return nil
    end

    local base = self._tierLevelByName[rank.tier] or 1
    if rank.tier == self._topTierName then
        return base + self:_getTopTierCount(rank)
    end
    return base
end

function Service:_collectMatchOutcomes(payload)
    local outcomes = {}
    local results = payload and payload.results or {}

    for _, entry in ipairs(results.playerResults or {}) do
        if entry.player then
            outcomes[entry.player] = entry.didWin == true or (entry.performancePercent or 0) > 50
        end
    end

    for userId, didWin in pairs(results.outcomeByUserId or {}) do
        outcomes[tonumber(userId) or userId] = didWin == true
    end

    return outcomes
end

function Service:ApplyMatchResults(payload)
    local outcomes = self:_collectMatchOutcomes(payload)
    local updated = {}

    for playerOrUserId, didWin in pairs(outcomes) do
        local rank = nil
        if didWin then
            rank = self:AddStar(playerOrUserId)
        else
            rank = self:RemoveStar(playerOrUserId)
        end

        if rank then
            table.insert(updated, {
                player = playerOrUserId,
                rank = rank,
            })
        end
    end

    return updated
end

return Service
