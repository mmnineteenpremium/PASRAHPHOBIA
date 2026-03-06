local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local RANK_INDEX = {
    ["Bayi III"] = 1,
    ["Bayi II"] = 2,
    ["Bayi I"] = 3,
    ["Balita III"] = 4,
    ["Balita II"] = 5,
    ["Balita I"] = 6,
    ["Anak-Anak III"] = 7,
    ["Anak-Anak II"] = 8,
    ["Anak-Anak I"] = 9,
    ["Remaja III"] = 10,
    ["Remaja II"] = 11,
    ["Remaja I"] = 12,
    ["Dewasa III"] = 13,
    ["Dewasa II"] = 14,
    ["Dewasa I"] = 15,
    ["Profesional III"] = 16,
    ["Profesional II"] = 17,
    ["Profesional I"] = 18,
    ["Detektive III"] = 19,
    ["Detektive II"] = 20,
    ["Detektive I"] = 21,
    ["Sang Ahli"] = 22,
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

local function computeScore(level, rank, contracts)
    return ((tonumber(level) or 1) * 10000) + ((RANK_INDEX[rank] or 1) * 100) + (tonumber(contracts) or 0)
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

function Service:_ensureEntry(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local rankings = self._state:Get("rankings") or {}
    rankings[userId] = rankings[userId] or {
        userId = userId,
        level = 1,
        rank = "Bayi III",
        contractsCompleted = 0,
        score = 0,
        updatedAt = os.time(),
    }
    rankings[userId].score = computeScore(rankings[userId].level, rankings[userId].rank, rankings[userId].contractsCompleted)
    rankings[userId].updatedAt = os.time()

    self._state:Set("rankings", rankings)
    return userId
end

function Service:UpdatePlayerRanking(player, patch)
    local userId = self:_ensureEntry(player)
    if not userId then
        return false, "invalid_player"
    end

    local rankings = self._state:Get("rankings") or {}
    local entry = rankings[userId]

    if type(patch) == "table" then
        if patch.level ~= nil then
            entry.level = math.max(1, math.floor(tonumber(patch.level) or entry.level))
        end
        if patch.rank ~= nil then
            entry.rank = tostring(patch.rank)
        end
        if patch.contractsCompletedDelta ~= nil then
            entry.contractsCompleted = math.max(0, (entry.contractsCompleted or 0) + math.floor(tonumber(patch.contractsCompletedDelta) or 0))
        end
        if patch.contractsCompleted ~= nil then
            entry.contractsCompleted = math.max(0, math.floor(tonumber(patch.contractsCompleted) or entry.contractsCompleted))
        end
    end

    entry.score = computeScore(entry.level, entry.rank, entry.contractsCompleted)
    entry.updatedAt = os.time()

    rankings[userId] = entry
    self._state:Set("rankings", rankings)
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
            contractsCompleted = entry.contractsCompleted,
            score = entry.score,
            updatedAt = entry.updatedAt,
        })
    end

    table.sort(rows, function(a, b)
        if a.score == b.score then
            return a.userId < b.userId
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
        self:_ensureEntry(player)
        self:RefreshLeaderboard()
    end
end

function Service:OnPlayerLevelUp(payload)
    if type(payload) ~= "table" then
        return
    end
    local player = payload.player or payload.userId
    if player then
        self:UpdatePlayerRanking(player, {
            level = payload.newLevel or payload.level,
        })
    end
end

function Service:OnRankUpdated(payload)
    if type(payload) ~= "table" then
        return
    end
    local player = payload.player or payload.userId
    if player then
        self:UpdatePlayerRanking(player, {
            rank = payload.rank,
        })
    end
end

function Service:OnMatchEnded(payload)
    if type(payload) ~= "table" then
        return
    end

    if type(payload.results) == "table" and type(payload.results.playerResults) == "table" then
        for _, result in ipairs(payload.results.playerResults) do
            local player = result.player or result.userId
            if player then
                local delta = (result.contractCompleted == true or result.didWin == true) and 1 or 0
                self:UpdatePlayerRanking(player, {
                    contractsCompletedDelta = delta,
                })
            end
        end
        return
    end

    if payload.player then
        local delta = (payload.contractCompleted == true or payload.didWin == true) and 1 or 0
        self:UpdatePlayerRanking(payload.player, {
            contractsCompletedDelta = delta,
        })
    end
end

return Service