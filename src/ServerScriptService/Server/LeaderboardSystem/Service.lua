local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DIVISION_ROMAN = {
    [1] = "I",
    [2] = "II",
    [3] = "III",
    [4] = "IV",
    [5] = "V",
}

local ROMAN_DIVISION = {
    I = 1,
    II = 2,
    III = 3,
    IV = 4,
    V = 5,
}

local DEFAULT_RANK = {
    playerRank = "Bayi III",
    tier = "Bayi",
    division = 3,
    stars = 0,
    victories = 0,
}

local CANONICAL_RANK_TABLE = {
    { tier = "Bayi", divisions = 3, starsPerDivision = 3 },
    { tier = "Balita", divisions = 3, starsPerDivision = 3 },
    { tier = "Anak-Anak", divisions = 3, starsPerDivision = 3 },
    { tier = "Remaja", divisions = 4, starsPerDivision = 4 },
    { tier = "Dewasa", divisions = 5, starsPerDivision = 5 },
    { tier = "Profesional", divisions = 5, starsPerDivision = 5 },
    { tier = "Detektive", divisions = 5, starsPerDivision = 5 },
    { tier = "Sang Ahli", divisions = 1, starsPerDivision = 0 },
}

local TOP_TIER = "Sang Ahli"
local RANK_META = {}
local TOP_TIER_BASE_SCORE = 0

do
    local accumulated = 0
    for index, entry in ipairs(CANONICAL_RANK_TABLE) do
        RANK_META[entry.tier] = {
            index = index,
            divisions = entry.divisions,
            starsPerDivision = entry.starsPerDivision,
            baseScore = accumulated,
        }
        accumulated += (entry.divisions or 0) * (entry.starsPerDivision or 0)
    end
    TOP_TIER_BASE_SCORE = accumulated + 1
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

local function resolveProfileSystem(deps)
    local profileSystem = Services.Get(deps, "ProfileSystem")
    if type(profileSystem) ~= "table" then
        return nil
    end
    if type(profileSystem.GetPlayerProfile) == "function" then
        return profileSystem
    end
    if type(profileSystem.Service) == "table" and type(profileSystem.Service.GetPlayerProfile) == "function" then
        return profileSystem.Service
    end
    return nil
end

local function resolveRankedSystem(deps)
    local rankedSystem = Services.Get(deps, "RankedSystem")
    if type(rankedSystem) ~= "table" then
        return nil
    end
    if type(rankedSystem.GetPlayerRank) == "function" then
        return rankedSystem
    end
    if type(rankedSystem.Service) == "table" and type(rankedSystem.Service.GetPlayerRank) == "function" then
        return rankedSystem.Service
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

local function clampInteger(value, defaultValue, minValue, maxValue)
    local number = tonumber(value)
    if number == nil then
        number = defaultValue
    end

    number = math.floor(number or 0)
    if minValue ~= nil then
        number = math.max(minValue, number)
    end
    if maxValue ~= nil then
        number = math.min(maxValue, number)
    end
    return number
end

local function parseRankName(rankName)
    if type(rankName) ~= "string" then
        return nil, nil, nil
    end

    local trimmed = rankName:match("^%s*(.-)%s*$")
    if trimmed == nil or trimmed == "" then
        return nil, nil, nil
    end

    local tier, victoryToken = trimmed:match("^(Sang Ahli)%s+[xX](%d+)$")
    if tier and victoryToken then
        return tier, 0, tonumber(victoryToken)
    end

    tier, victoryToken = trimmed:match("^(Sang Ahli)%s*%((%d+)%)$")
    if tier and victoryToken then
        return tier, 0, tonumber(victoryToken)
    end

    local divisionToken = nil
    tier, divisionToken = trimmed:match("^(.-)%s+([IVX]+)$")
    if tier and ROMAN_DIVISION[divisionToken] then
        return tier, ROMAN_DIVISION[divisionToken], nil
    end

    tier, divisionToken = trimmed:match("^(.-)%s+(%d+)$")
    if tier and divisionToken then
        return tier, tonumber(divisionToken), nil
    end

    return trimmed, 0, nil
end

local function formatRankName(rank)
    if type(rank) ~= "table" then
        return DEFAULT_RANK.playerRank
    end

    local tier = tostring(rank.tier or DEFAULT_RANK.tier)
    if tier == TOP_TIER then
        return TOP_TIER
    end

    local division = clampInteger(rank.division, DEFAULT_RANK.division, 0)
    if division <= 0 then
        return tier
    end

    return string.format("%s %s", tier, DIVISION_ROMAN[division] or tostring(division))
end

local function formatLeaderboardLabel(rank)
    if type(rank) ~= "table" then
        return string.format("%s x0", TOP_TIER)
    end

    if tostring(rank.tier or "") == TOP_TIER then
        return string.format("%s x%d", TOP_TIER, clampInteger(rank.victories, 0, 0))
    end

    return formatRankName(rank)
end

local function normalizeRankState(rawRank, fallback)
    local fallbackRank = type(fallback) == "table" and fallback or DEFAULT_RANK
    local normalized = {
        playerRank = tostring(fallbackRank.playerRank or DEFAULT_RANK.playerRank),
        tier = tostring(fallbackRank.tier or DEFAULT_RANK.tier),
        division = clampInteger(fallbackRank.division, DEFAULT_RANK.division, 0),
        stars = clampInteger(fallbackRank.stars, DEFAULT_RANK.stars, 0),
        victories = clampInteger(fallbackRank.victories, DEFAULT_RANK.victories, 0),
    }

    if type(rawRank) == "string" then
        rawRank = {
            playerRank = rawRank,
        }
    end

    if type(rawRank) ~= "table" then
        normalized.playerRank = formatRankName(normalized)
        return normalized
    end

    local parsedTier, parsedDivision, parsedVictories = parseRankName(rawRank.playerRank or rawRank.rank)
    normalized.tier = tostring(rawRank.tier or parsedTier or normalized.tier)

    local meta = RANK_META[normalized.tier] or RANK_META[DEFAULT_RANK.tier]
    local maxDivision = math.max(meta.divisions or DEFAULT_RANK.division, 0)

    if normalized.tier == TOP_TIER then
        normalized.division = 0
        normalized.stars = 0
        normalized.victories = clampInteger(rawRank.victories, parsedVictories or normalized.victories, 0)
    else
        local defaultDivision = normalized.division
        if defaultDivision <= 0 then
            defaultDivision = maxDivision
        end
        normalized.division = clampInteger(rawRank.division, parsedDivision or defaultDivision, 1, math.max(maxDivision, 1))
        normalized.stars = clampInteger(rawRank.stars, normalized.stars, 0, math.max(meta.starsPerDivision or 0, 0))
        normalized.victories = clampInteger(rawRank.victories, normalized.victories, 0)
    end

    normalized.playerRank = formatRankName(normalized)
    return normalized
end

local function computeScore(rank)
    local normalized = normalizeRankState(rank)
    local meta = RANK_META[normalized.tier] or RANK_META[DEFAULT_RANK.tier]

    if normalized.tier == TOP_TIER then
        return TOP_TIER_BASE_SCORE + normalized.victories
    end

    local maxDivision = math.max(meta.divisions or 1, 1)
    local starsPerDivision = math.max(meta.starsPerDivision or 0, 0)
    local division = clampInteger(normalized.division, maxDivision, 1, maxDivision)
    local stars = clampInteger(normalized.stars, 0, 0, starsPerDivision)
    local withinTier = ((maxDivision - division) * starsPerDivision) + stars
    return (meta.baseScore or 0) + withinTier
end

local function extractStatValue(profile, keys, defaultValue)
    if type(profile) ~= "table" then
        return defaultValue
    end

    for _, key in ipairs(keys) do
        if profile[key] ~= nil then
            return profile[key]
        end
    end

    local stats = type(profile.statistics) == "table" and profile.statistics or nil
    if stats then
        for _, key in ipairs(keys) do
            if stats[key] ~= nil then
                return stats[key]
            end
        end
    end

    return defaultValue
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._profileSystem = nil
    self._rankedSystem = nil
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._profileSystem = resolveProfileSystem(self._deps)
    self._rankedSystem = resolveRankedSystem(self._deps)
end

function Service:Init()
    self._state:Set("rankings", self._state:Get("rankings") or {})
    self._state:Set("cachedLeaderboard", self._state:Get("cachedLeaderboard") or {})
    self._state:Set("lastUpdate", self._state:Get("lastUpdate") or 0)
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

function Service:_profileSnapshot(playerOrUserId)
    return safeCall(self._profileSystem, "GetPlayerProfile", playerOrUserId)
end

function Service:_rankSnapshot(playerOrUserId)
    return safeCall(self._rankedSystem, "GetPlayerRank", playerOrUserId)
end

function Service:_buildEntry(playerOrUserId, rankOverride)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local rankings = self._state:Get("rankings") or {}
    local existing = rankings[userId] or {}
    local profile = self:_profileSnapshot(playerOrUserId)
    local rankSeed = rankOverride
    if rankSeed == nil then
        rankSeed = self:_rankSnapshot(playerOrUserId)
    end
    if rankSeed == nil and type(profile) == "table" then
        rankSeed = profile.rank or profile.rankTier or profile.playerRank
    end

    local rank = normalizeRankState(rankSeed, existing)
    local level = clampInteger(
        extractStatValue(profile, { "playerLevel", "level" }, existing.level or 1),
        existing.level or 1,
        1
    )
    local totalMatches = clampInteger(
        extractStatValue(profile, { "totalMatches", "totalGames" }, existing.totalMatches or 0),
        existing.totalMatches or 0,
        0
    )
    local totalWins = clampInteger(
        extractStatValue(profile, { "totalWins" }, existing.totalWins or 0),
        existing.totalWins or 0,
        0,
        totalMatches
    )
    totalWins = math.min(totalWins, totalMatches)

    return {
        userId = userId,
        level = level,
        rank = rank.playerRank,
        playerRank = rank.playerRank,
        tier = rank.tier,
        division = rank.division,
        stars = rank.stars,
        victories = rank.victories,
        leaderboardLabel = formatLeaderboardLabel(rank),
        totalMatches = totalMatches,
        totalWins = totalWins,
        score = computeScore(rank),
        updatedAt = os.time(),
    }
end

function Service:_updateEntry(playerOrUserId, rankOverride)
    local entry = self:_buildEntry(playerOrUserId, rankOverride)
    if not entry then
        return nil
    end

    local rankings = self._state:Get("rankings") or {}
    rankings[entry.userId] = entry
    self._state:Set("rankings", rankings)
    return entry.userId
end

function Service:UpdatePlayerRanking(playerOrUserId, patch)
    local userId = self:_updateEntry(playerOrUserId, patch)
    if not userId then
        return false, "invalid_player"
    end

    self:RefreshLeaderboard()
    return true
end

function Service:RefreshLeaderboard()
    local rankings = self._state:Get("rankings") or {}
    local rows = {}
    for _, entry in pairs(rankings) do
        table.insert(rows, {
            userId = entry.userId,
            level = entry.level,
            rank = entry.rank,
            playerRank = entry.playerRank,
            tier = entry.tier,
            division = entry.division,
            stars = entry.stars,
            victories = entry.victories,
            leaderboardLabel = entry.leaderboardLabel,
            totalMatches = entry.totalMatches,
            totalWins = entry.totalWins,
            score = entry.score,
            updatedAt = entry.updatedAt,
        })
    end

    table.sort(rows, function(a, b)
        if a.score == b.score then
            if a.totalWins == b.totalWins then
                if a.totalMatches == b.totalMatches then
                    return a.userId < b.userId
                end
                return a.totalMatches > b.totalMatches
            end
            return a.totalWins > b.totalWins
        end
        return a.score > b.score
    end)

    self._state:Set("cachedLeaderboard", rows)
    self._state:Set("lastUpdate", os.time())

    self:_publish("LeaderboardUpdated", {
        seasonId = self._state:Get("seasonId"),
        top = self:GetTopPlayers(20),
        updatedAt = self._state:Get("lastUpdate"),
    })
end

function Service:GetTopPlayers(limit)
    local cached = self._state:Get("cachedLeaderboard") or {}
    local maxCount = math.max(1, math.floor(tonumber(limit) or 20))
    local out = {}
    for i = 1, math.min(#cached, maxCount) do
        out[i] = cached[i]
    end
    return out
end

function Service:GetFriendsLeaderboard(friendUserIds)
    local friendSet = {}
    for _, userId in ipairs(friendUserIds or {}) do
        friendSet[tonumber(userId)] = true
    end

    local cached = self._state:Get("cachedLeaderboard") or {}
    local out = {}
    for _, entry in ipairs(cached) do
        if friendSet[entry.userId] then
            table.insert(out, entry)
        end
    end
    return out
end

function Service:ResetSeason(newSeasonId)
    self._state:Set("rankings", {})
    self._state:Set("cachedLeaderboard", {})
    self._state:Set("seasonId", tostring(newSeasonId or "S1"))
    self._state:Set("lastUpdate", os.time())
    self:_publish("LeaderboardUpdated", {
        seasonId = self._state:Get("seasonId"),
        top = {},
        updatedAt = self._state:Get("lastUpdate"),
    })
end

function Service:OnPlayerJoinedLobby(payload)
    local player = payload and payload.player or payload
    if player then
        self:_updateEntry(player)
        self:RefreshLeaderboard()
    end
end

function Service:OnPlayerLevelUp(payload)
    if type(payload) ~= "table" then
        return
    end
    local player = payload.player or payload.userId
    if player then
        self:_updateEntry(player)
        self:RefreshLeaderboard()
    end
end

function Service:OnRankUpdated(payload)
    if type(payload) ~= "table" then
        return
    end
    local player = payload.player or payload.userId
    if player then
        self:UpdatePlayerRanking(player, payload)
    end
end

function Service:OnMatchEnded(payload)
    if type(payload) ~= "table" then
        return
    end

    local changed = false
    if type(payload.results) == "table" and type(payload.results.playerResults) == "table" then
        for _, result in ipairs(payload.results.playerResults) do
            local player = result.player or result.userId
            if player and self:_updateEntry(player) then
                changed = true
            end
        end
    elseif payload.player and self:_updateEntry(payload.player) then
        changed = true
    end

    if changed then
        self:RefreshLeaderboard()
    end
end

return Service
