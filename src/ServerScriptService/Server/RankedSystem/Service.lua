local Service = {}
Service.__index = Service

local Services = require(script.Parent.Parent.Core.Services)

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
    if type(profile.GetPlayerLevel) == "function" then
        return profile
    end
    if type(profile.Service) == "table" and type(profile.Service.GetPlayerLevel) == "function" then
        return profile.Service
    end
    return nil
end

local function resolvePersistenceService(deps)
    local persistence = Services.Get(deps, "DataPersistence")
        or Services.Get(deps, "DataPersistenceService")
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
    self._persistence = resolvePersistenceService(self._deps)
    return self
end

function Service:Init()
    self._state:Set("rankTable", self._state:Get("rankTable") or {})
    self._state:Set("rankByUserId", self._state:Get("rankByUserId") or {})
    self._state:Set("recentRankUpdates", self._state:Get("recentRankUpdates") or {})
end

function Service:Start()
    -- Event-driven ranked progression.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_rankTable()
    return self._state:Get("rankTable") or {}
end

function Service:_ranks()
    return self._state:Get("rankByUserId") or {}
end

function Service:_setRanks(rankByUserId)
    self._state:Set("rankByUserId", rankByUserId)
end

function Service:_recordUpdate(userId, payload)
    local recent = self._state:Get("recentRankUpdates") or {}
    recent[userId] = recent[userId] or {}
    table.insert(recent[userId], payload)
    self._state:Set("recentRankUpdates", recent)
end

function Service:_tierIndexByName(tierName)
    for i, entry in ipairs(self:_rankTable()) do
        if entry.tier == tierName then
            return i
        end
    end
    return 1
end

function Service:_ensureRank(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local rankByUserId = self:_ranks()
    if not rankByUserId[userId] then
        local first = self:_rankTable()[1] or { tier = "Bayi", divisions = 3 }
        rankByUserId[userId] = {
            tier = first.tier,
            division = math.max(first.divisions or 3, 1),
            stars = 0,
            victories = 0,
        }
        self:_setRanks(rankByUserId)
    end
    return rankByUserId[userId]
end

function Service:_serialize(playerOrUserId, rank)
    local userId = toUserId(playerOrUserId)
    return {
        player = type(playerOrUserId) == "number" and nil or playerOrUserId,
        userId = userId,
        tier = rank.tier,
        division = rank.division,
        stars = rank.stars,
        victories = rank.victories,
    }
end

function Service:_starsPerDivision(tierName)
    local index = self:_tierIndexByName(tierName)
    local entry = self:_rankTable()[index]
    return entry and entry.starsPerDivision or 3
end

function Service:_isTopTier(tierName)
    local rankTable = self:_rankTable()
    local last = rankTable[#rankTable]
    return last and last.tier == tierName
end

function Service:_promote(rank)
    local rankTable = self:_rankTable()
    local tierIndex = self:_tierIndexByName(rank.tier)
    local tierEntry = rankTable[tierIndex]
    if not tierEntry then
        return
    end

    if tierIndex == #rankTable then
        return
    end

    if rank.division > 1 then
        rank.division -= 1
        rank.stars = 0
        return
    end

    local nextTier = rankTable[tierIndex + 1]
    rank.tier = nextTier.tier
    if nextTier.divisions and nextTier.divisions > 0 then
        rank.division = nextTier.divisions
        rank.stars = 0
    else
        rank.division = 0
        rank.stars = 0
    end
end

function Service:_demote(rank)
    local rankTable = self:_rankTable()
    local tierIndex = self:_tierIndexByName(rank.tier)
    local tierEntry = rankTable[tierIndex]
    if not tierEntry then
        return
    end

    if tierIndex == #rankTable then
        if rank.victories > 0 then
            rank.victories -= 1
            return
        end
        local previousTier = rankTable[tierIndex - 1]
        if previousTier then
            rank.tier = previousTier.tier
            rank.division = 1
            rank.stars = math.max((previousTier.starsPerDivision or 3) - 1, 0)
            rank.victories = 0
        end
        return
    end

    if rank.stars > 0 then
        rank.stars -= 1
        return
    end

    local maxDivision = tierEntry.divisions or 0
    if maxDivision > 0 and rank.division < maxDivision then
        rank.division += 1
        rank.stars = math.max((tierEntry.starsPerDivision or 3) - 1, 0)
        return
    end

    if tierIndex > 1 then
        local previousTier = rankTable[tierIndex - 1]
        rank.tier = previousTier.tier
        rank.division = 1
        rank.stars = math.max((previousTier.starsPerDivision or 3) - 1, 0)
    end
end

function Service:_syncProfile(playerOrUserId, rank)
    if not self._persistence then
        return
    end
    local userId = toUserId(playerOrUserId)
    if not userId then
        return
    end
    self._persistence:SaveProfile(userId, {
        playerRank = rank.tier,
        division = rank.division,
        stars = rank.stars,
        victories = rank.victories,
    })
end

function Service:GetPlayerRank(playerOrUserId)
    local rank = self:_ensureRank(playerOrUserId)
    if not rank then
        return nil
    end
    local payload = self:_serialize(playerOrUserId, rank)
    payload.rank = payload.tier
    return payload
end

function Service:AddStar(playerOrUserId)
    local rank = self:_ensureRank(playerOrUserId)
    if not rank then
        return nil, "invalid_player"
    end

    if self:_isTopTier(rank.tier) then
        rank.victories += 1
        local payload = self:_serialize(playerOrUserId, rank)
        payload.reason = "win"
        payload.newStarCount = payload.stars
        self:_publish("RankStarAdded", payload)
        self:_publish("RankUpdated", payload)
        self:_recordUpdate(payload.userId, payload)
        self:_syncProfile(playerOrUserId, rank)
        return self:GetPlayerRank(playerOrUserId)
    end

    rank.stars += 1
    local required = self:_starsPerDivision(rank.tier)
    if rank.stars >= required then
        local beforeTier = rank.tier
        local beforeDivision = rank.division
        self:_promote(rank)
        self:_publish("RankTierChanged", {
            player = type(playerOrUserId) == "number" and nil or playerOrUserId,
            userId = toUserId(playerOrUserId),
            fromTier = beforeTier,
            fromDivision = beforeDivision,
            toTier = rank.tier,
            toDivision = rank.division,
            newTier = rank.tier,
            reason = "promotion",
        })
    end

    local payload = self:_serialize(playerOrUserId, rank)
    payload.reason = "win"
    payload.newStarCount = payload.stars
    self:_publish("RankStarAdded", payload)
    self:_publish("RankUpdated", payload)
    self:_recordUpdate(payload.userId, payload)
    self:_syncProfile(playerOrUserId, rank)
    return self:GetPlayerRank(playerOrUserId)
end

function Service:RemoveStar(playerOrUserId)
    local rank = self:_ensureRank(playerOrUserId)
    if not rank then
        return nil, "invalid_player"
    end

    local beforeTier = rank.tier
    local beforeDivision = rank.division
    self:_demote(rank)
    if beforeTier ~= rank.tier or beforeDivision ~= rank.division then
        self:_publish("RankTierChanged", {
            player = type(playerOrUserId) == "number" and nil or playerOrUserId,
            userId = toUserId(playerOrUserId),
            fromTier = beforeTier,
            fromDivision = beforeDivision,
            toTier = rank.tier,
            toDivision = rank.division,
            newTier = rank.tier,
            reason = "demotion",
        })
    end

    local payload = self:_serialize(playerOrUserId, rank)
    payload.reason = "loss"
    payload.newStarCount = payload.stars
    self:_publish("RankStarRemoved", payload)
    self:_publish("RankUpdated", payload)
    self:_recordUpdate(payload.userId, payload)
    self:_syncProfile(playerOrUserId, rank)
    return self:GetPlayerRank(playerOrUserId)
end

function Service:CalculateRankDifficulty(playerOrUserId)
    local rank = self:_ensureRank(playerOrUserId)
    if not rank then
        return nil
    end
    local tierIndex = self:_tierIndexByName(rank.tier)
    if self:_isTopTier(rank.tier) then
        return tierIndex + rank.victories
    end
    return tierIndex + math.max((3 - (rank.division or 1)), 0)
end

function Service:_collectMatchOutcomes(payload)
    local out = {}
    local results = payload and payload.results or {}
    for _, entry in ipairs(results.playerResults or {}) do
        local playerOrUserId = entry.player or entry.userId
        if playerOrUserId then
            local didWin = entry.didWin == true or (entry.performancePercent or 0) > 50
            out[playerOrUserId] = didWin
        end
    end
    return out
end

function Service:ApplyMatchResults(payload)
    local updated = {}
    for playerOrUserId, didWin in pairs(self:_collectMatchOutcomes(payload)) do
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
