local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local PROMOTION_STARS = 3

local RANK_LEVEL_REQUIREMENTS = {
    { base = "Bayi", minLevel = 1, minIndex = 1 },
    { base = "Balita", minLevel = 5, minIndex = 4 },
    { base = "Anak-Anak", minLevel = 12, minIndex = 7 },
    { base = "Remaja", minLevel = 20, minIndex = 10 },
    { base = "Dewasa", minLevel = 30, minIndex = 13 },
    { base = "Profesional", minLevel = 40, minIndex = 16 },
    { base = "Detektive", minLevel = 50, minIndex = 19 },
    { base = "Sang Ahli", minLevel = 60, minIndex = 22 },
}

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

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
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
        ProgressionSystem = Services.Get(self._deps, "ProgressionSystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
end

function Service:Init()
    self._state:Set("playerRank", self._state:Get("playerRank") or {})
    self._state:Set("playerStars", self._state:Get("playerStars") or {})
    self._state:Set("rankTable", self._state:Get("rankTable") or {})
end

function Service:Start()
    -- Event-driven rank progression service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_getRankIndex(rankName)
    local rankTable = self._state:Get("rankTable") or {}
    for index, name in ipairs(rankTable) do
        if name == rankName then
            return index
        end
    end
    return 1
end

function Service:_getRankNameByIndex(index)
    local rankTable = self._state:Get("rankTable") or {}
    if #rankTable == 0 then
        return "Bayi III"
    end
    local clamped = math.clamp(index or 1, 1, #rankTable)
    return rankTable[clamped]
end

function Service:_isFinalRank(index)
    local rankTable = self._state:Get("rankTable") or {}
    return index >= #rankTable
end

function Service:_resolveLevel(player, levelHint)
    local level = tonumber(levelHint)
    if level then
        return math.max(1, math.floor(level))
    end

    local progression = self._dependencies.ProgressionSystem
    level = safeCall(progression, "GetPlayerLevel", player)
    if level == nil and type(progression) == "table" and type(progression.Service) == "table" then
        level = safeCall(progression.Service, "GetPlayerLevel", player)
    end

    if level == nil then
        local profile = self._dependencies.ProfileSystem
        level = safeCall(profile, "GetPlayerLevel", player)
        if level == nil and type(profile) == "table" and type(profile.Service) == "table" then
            level = safeCall(profile.Service, "GetPlayerLevel", player)
        end
    end

    return math.max(1, math.floor(tonumber(level) or 1))
end

function Service:_minimumRankIndexForLevel(level)
    local minimumIndex = 1
    for _, requirement in ipairs(RANK_LEVEL_REQUIREMENTS) do
        if level >= requirement.minLevel then
            minimumIndex = requirement.minIndex
        else
            break
        end
    end
    return minimumIndex
end

function Service:_syncProfileRank(player, rankName, stars)
    local profileSystem = self._dependencies.ProfileSystem
    if type(profileSystem) ~= "table" then
        return
    end

    if type(profileSystem.SetPlayerRank) == "function" then
        safeCall(profileSystem, "SetPlayerRank", player, rankName, stars)
        return
    end

    if type(profileSystem.Service) == "table" and type(profileSystem.Service.SetPlayerRank) == "function" then
        safeCall(profileSystem.Service, "SetPlayerRank", player, rankName, stars)
        return
    end

    if type(profileSystem.UpdateProfile) == "function" then
        safeCall(profileSystem, "UpdateProfile", player, {
            rank = rankName,
            stars = stars,
        })
    elseif type(profileSystem.Service) == "table" and type(profileSystem.Service.UpdateProfile) == "function" then
        safeCall(profileSystem.Service, "UpdateProfile", player, {
            rank = rankName,
            stars = stars,
        })
    end
end

function Service:_ensurePlayerData(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local playerRank = self._state:Get("playerRank") or {}
    local playerStars = self._state:Get("playerStars") or {}

    if playerRank[userId] == nil then
        local level = self:_resolveLevel(player)
        local baseIndex = self:_minimumRankIndexForLevel(level)
        playerRank[userId] = self:_getRankNameByIndex(baseIndex)
    end

    if playerStars[userId] == nil then
        playerStars[userId] = 0
    end

    self._state:Set("playerRank", playerRank)
    self._state:Set("playerStars", playerStars)
    return userId
end

function Service:GetPlayerRank(player)
    local userId = self:_ensurePlayerData(player)
    if not userId then
        return nil
    end

    local playerRank = self._state:Get("playerRank") or {}
    return playerRank[userId]
end

function Service:CheckPromotion(player)
    local userId = self:_ensurePlayerData(player)
    if not userId then
        return false, "invalid_player"
    end

    local playerRank = self._state:Get("playerRank") or {}
    local playerStars = self._state:Get("playerStars") or {}

    local rankIndex = self:_getRankIndex(playerRank[userId])
    local stars = playerStars[userId] or 0
    local promoted = false

    while stars >= PROMOTION_STARS and not self:_isFinalRank(rankIndex) do
        local previousRank = self:_getRankNameByIndex(rankIndex)
        rankIndex += 1
        stars -= PROMOTION_STARS
        promoted = true

        self:_publish("RankPromotion", {
            player = player,
            userId = userId,
            fromRank = previousRank,
            toRank = self:_getRankNameByIndex(rankIndex),
            stars = stars,
        })
    end

    playerRank[userId] = self:_getRankNameByIndex(rankIndex)
    playerStars[userId] = math.max(0, stars)
    self._state:Set("playerRank", playerRank)
    self._state:Set("playerStars", playerStars)

    return promoted
end

function Service:CheckDemotion(player)
    local userId = self:_ensurePlayerData(player)
    if not userId then
        return false, "invalid_player"
    end

    local playerRank = self._state:Get("playerRank") or {}
    local playerStars = self._state:Get("playerStars") or {}

    local rankIndex = self:_getRankIndex(playerRank[userId])
    local stars = playerStars[userId] or 0
    local demoted = false

    while stars < 0 and rankIndex > 1 do
        local previousRank = self:_getRankNameByIndex(rankIndex)
        rankIndex -= 1
        stars += PROMOTION_STARS
        demoted = true

        self:_publish("RankDemotion", {
            player = player,
            userId = userId,
            fromRank = previousRank,
            toRank = self:_getRankNameByIndex(rankIndex),
            stars = stars,
        })
    end

    if rankIndex == 1 and stars < 0 then
        stars = 0
    end

    playerRank[userId] = self:_getRankNameByIndex(rankIndex)
    playerStars[userId] = stars
    self._state:Set("playerRank", playerRank)
    self._state:Set("playerStars", playerStars)

    return demoted
end

function Service:UpdateStars(player, stars)
    local userId = self:_ensurePlayerData(player)
    if not userId then
        return false, "invalid_player"
    end

    local playerRank = self._state:Get("playerRank") or {}
    local playerStars = self._state:Get("playerStars") or {}

    local delta = math.floor(tonumber(stars) or 0)
    if delta == 0 then
        return true
    end

    local previousRank = playerRank[userId]
    local previousStars = playerStars[userId] or 0

    playerStars[userId] = previousStars + delta
    self._state:Set("playerStars", playerStars)

    local promoted = self:CheckPromotion(player)
    local demoted = self:CheckDemotion(player)

    playerRank = self._state:Get("playerRank") or {}
    playerStars = self._state:Get("playerStars") or {}

    local currentRank = playerRank[userId]
    local currentStars = playerStars[userId] or 0
    self:_syncProfileRank(player, currentRank, currentStars)

    self:_publish("RankUpdated", {
        player = player,
        userId = userId,
        rank = currentRank,
        stars = currentStars,
        starDelta = delta,
        previousRank = previousRank,
        previousStars = previousStars,
        promoted = promoted == true,
        demoted = demoted == true,
    })

    return true
end

function Service:CalculateRank(player, levelHint)
    local userId = self:_ensurePlayerData(player)
    if not userId then
        return false, "invalid_player"
    end

    local level = self:_resolveLevel(player, levelHint)
    local minIndex = self:_minimumRankIndexForLevel(level)

    local playerRank = self._state:Get("playerRank") or {}
    local playerStars = self._state:Get("playerStars") or {}
    local currentIndex = self:_getRankIndex(playerRank[userId])

    if currentIndex < minIndex then
        local previousRank = playerRank[userId]
        playerRank[userId] = self:_getRankNameByIndex(minIndex)
        playerStars[userId] = 0
        self._state:Set("playerRank", playerRank)
        self._state:Set("playerStars", playerStars)

        self:_publish("RankPromotion", {
            player = player,
            userId = userId,
            fromRank = previousRank,
            toRank = playerRank[userId],
            stars = 0,
            reason = "level_requirement",
        })

        self:_publish("RankUpdated", {
            player = player,
            userId = userId,
            rank = playerRank[userId],
            stars = 0,
            previousRank = previousRank,
            previousStars = 0,
            promoted = true,
            demoted = false,
            reason = "level_requirement",
        })

        self:_syncProfileRank(player, playerRank[userId], 0)
    end

    return true, nil, {
        rank = playerRank[userId],
        stars = playerStars[userId] or 0,
        level = level,
    }
end

function Service:_calculateMatchStarDelta(matchData)
    if type(matchData) ~= "table" then
        return 0
    end

    local delta = 0

    if matchData.correctGhostIdentification == true or matchData.ghostIdentifiedCorrectly == true then
        delta += 1
    end
    if matchData.contractCompleted == true or matchData.didWin == true then
        delta += 1
    end

    local difficulty = tonumber(matchData.difficulty or matchData.difficultyMultiplier or 1) or 1
    if difficulty >= 3 and (matchData.contractCompleted == true or matchData.didWin == true) then
        delta += 1
    end

    if matchData.incorrectGhostIdentification == true or matchData.ghostIdentifiedCorrectly == false then
        delta -= 1
    end
    if matchData.contractFailed == true or (matchData.contractCompleted == false and matchData.didWin == false) then
        delta -= 1
    end

    return delta
end

function Service:OnMatchEnded(payload)
    if type(payload) ~= "table" then
        return
    end

    if payload.player then
        self:UpdateStars(payload.player, self:_calculateMatchStarDelta(payload))
        return
    end

    if type(payload.results) == "table" and type(payload.results.playerResults) == "table" then
        for _, result in ipairs(payload.results.playerResults) do
            local player = result.player or result.userId
            if player then
                self:UpdateStars(player, self:_calculateMatchStarDelta(result))
            end
        end
        return
    end

    if type(payload.players) == "table" then
        local delta = self:_calculateMatchStarDelta(payload)
        for _, player in ipairs(payload.players) do
            self:UpdateStars(player, delta)
        end
    end
end

function Service:OnPlayerLevelUp(payload)
    if type(payload) ~= "table" then
        return
    end

    local player = payload.player or payload.userId
    if not player then
        return
    end

    local level = payload.newLevel or payload.level
    self:CalculateRank(player, level)
end

return Service
