local Players = game:GetService("Players")
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local MAX_LEVEL = 100

local ROMAN_BY_DIVISION = {
    [1] = "I",
    [2] = "II",
    [3] = "III",
    [4] = "IV",
    [5] = "V",
}

local DIVISION_BY_ROMAN = {
    I = 1,
    II = 2,
    III = 3,
    IV = 4,
    V = 5,
}

local DEFAULT_PROGRESSION = {
    level = 1,
    exp = 0,
}

local DEFAULT_STATISTICS = {
    totalGames = 0,
    totalWins = 0,
    soloGames = 0,
    soloWins = 0,
    teamGames = 0,
    teamWins = 0,
    soloWinrate = 0,
    teamWinrate = 0,
    favoriteTool = nil,
    seasonTitles = {},
}

local DEFAULT_PROFILE = {
    galleryItems = {},
    flexBorder = nil,
    bio = "",
    winrateVisible = true,
}

local DEFAULT_RANK = {
    playerRank = "Bayi III",
    tier = "Bayi",
    division = 3,
    stars = 0,
    victories = 0,
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

local function resolvePlayer(playerOrUserId)
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId
    end

    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local ok, player = pcall(function()
        return Players:GetPlayerByUserId(userId)
    end)
    if ok then
        return player
    end
    return nil
end

local function cloneValue(value)
    if type(value) ~= "table" then
        return value
    end

    local out = {}
    for key, nested in pairs(value) do
        out[key] = cloneValue(nested)
    end
    return out
end

local function cloneArray(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = cloneValue(value)
    end
    return result
end

local function safeCall(target, methodName, ...)
    if type(target) ~= "table" then
        return nil
    end

    local method = target[methodName]
    if type(method) ~= "function" then
        return nil
    end

    local ok, result = pcall(method, target, ...)
    if not ok then
        return nil
    end
    return result
end

local function toInteger(value, defaultValue, minValue, maxValue)
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

local function calculateWinrate(wins, games)
    wins = math.max(0, toInteger(wins, 0))
    games = math.max(0, toInteger(games, 0))
    if games <= 0 then
        return 0
    end
    return math.floor((wins / games) * 100)
end

local function limitGalleryItems(source)
    local items = {}
    for _, itemId in ipairs(source or {}) do
        table.insert(items, itemId)
        if #items >= 3 then
            break
        end
    end
    return items
end

local function formatLegacyRankName(rank)
    if type(rank) ~= "table" then
        return DEFAULT_RANK.playerRank
    end

    local tier = tostring(rank.tier or DEFAULT_RANK.tier)
    if tier == "Sang Ahli" then
        return tier
    end
    local division = toInteger(rank.division, DEFAULT_RANK.division, 0)
    if division <= 0 then
        return tier
    end

    return string.format("%s %s", tier, ROMAN_BY_DIVISION[division] or tostring(division))
end

local function parseLegacyRankName(rankName)
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

    local tier, divisionToken = trimmed:match("^(.-)%s+([IVX]+)$")
    if tier and DIVISION_BY_ROMAN[divisionToken] then
        return tier, DIVISION_BY_ROMAN[divisionToken], nil
    end

    tier, divisionToken = trimmed:match("^(.-)%s+(%d+)$")
    if tier and divisionToken then
        return tier, tonumber(divisionToken), nil
    end

    return trimmed, 0, nil
end

local function defaultProfile(userId)
    return {
        userId = userId,
        progression = cloneValue(DEFAULT_PROGRESSION),
        statistics = cloneValue(DEFAULT_STATISTICS),
        profile = cloneValue(DEFAULT_PROFILE),
        rank = cloneValue(DEFAULT_RANK),
    }
end

local function stampProfileRuntime(target, payload)
    if typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end

    target:SetAttribute("PasrahProfileOwner", "ProfileSystem")
    target:SetAttribute("PasrahProfileLevel", math.max(1, math.floor(tonumber(payload.level) or 1)))
    target:SetAttribute("PasrahProfileXP", math.max(0, math.floor(tonumber(payload.xp) or 0)))
    target:SetAttribute("PasrahProfileRank", tostring(payload.rank or DEFAULT_RANK.playerRank))
    target:SetAttribute("PasrahProfileTotalMatches", math.max(0, math.floor(tonumber(payload.totalMatches) or 0)))
    target:SetAttribute("PasrahProfileTotalWins", math.max(0, math.floor(tonumber(payload.totalWins) or 0)))
    target:SetAttribute("PasrahProfileWinRate", math.max(0, math.floor(tonumber(payload.winRate) or 0)))
    target:SetAttribute("PasrahProfileFavoriteTool", payload.favoriteTool ~= nil and tostring(payload.favoriteTool) or nil)
    target:SetAttribute("PasrahProfileGalleryCount", math.max(0, math.floor(tonumber(payload.galleryCount) or 0)))
    target:SetAttribute("PasrahProfileBio", tostring(payload.bio or ""))
    target:SetAttribute("PasrahProfileFlexBorder", payload.flexBorder ~= nil and tostring(payload.flexBorder) or nil)
    target:SetAttribute("PasrahProfileWinrateVisible", payload.winrateVisible ~= false)
    target:SetAttribute("PasrahProfileSeasonTitleCount", math.max(0, math.floor(tonumber(payload.seasonTitleCount) or 0)))
    target:SetAttribute("PasrahProfileLastEvent", type(payload.lastEvent) == "string" and payload.lastEvent or nil)
    target:SetAttribute("PasrahProfileLastSource", type(payload.lastSource) == "string" and payload.lastSource or nil)
    target:SetAttribute("PasrahProfileUpdatedAt", os.clock())
end

local function normalizeProgression(rawProfile, rawRank)
    local progression = type(rawProfile.progression) == "table" and rawProfile.progression or {}
    local level = progression.level
    if level == nil then
        level = rawProfile.playerLevel
    end
    if level == nil and type(rawRank) == "table" then
        level = rawRank.playerLevel
    end

    local exp = progression.exp
    if exp == nil then
        exp = rawProfile.playerXP
    end
    if exp == nil then
        exp = rawProfile.exp
    end
    if exp == nil then
        exp = rawProfile.xp
    end

    return {
        level = toInteger(level, DEFAULT_PROGRESSION.level, 1, MAX_LEVEL),
        exp = toInteger(exp, DEFAULT_PROGRESSION.exp, 0),
    }
end

local function normalizeStatistics(rawProfile)
    local statistics = type(rawProfile.statistics) == "table" and rawProfile.statistics or {}

    local soloGames = toInteger(statistics.soloGames, DEFAULT_STATISTICS.soloGames, 0)
    local soloWins = toInteger(statistics.soloWins, DEFAULT_STATISTICS.soloWins, 0, soloGames)
    local teamGames = toInteger(statistics.teamGames, DEFAULT_STATISTICS.teamGames, 0)
    local teamWins = toInteger(statistics.teamWins, DEFAULT_STATISTICS.teamWins, 0, teamGames)
    local totalGames = toInteger(statistics.totalGames or statistics.totalMatches, soloGames + teamGames, 0)
    totalGames = math.max(totalGames, soloGames + teamGames)
    local totalWins = toInteger(statistics.totalWins, soloWins + teamWins, 0, totalGames)
    totalWins = math.max(totalWins, soloWins + teamWins)
    totalWins = math.min(totalWins, totalGames)

    return {
        totalGames = totalGames,
        totalWins = totalWins,
        soloGames = soloGames,
        soloWins = soloWins,
        teamGames = teamGames,
        teamWins = teamWins,
        soloWinrate = calculateWinrate(soloWins, soloGames),
        teamWinrate = calculateWinrate(teamWins, teamGames),
        favoriteTool = statistics.favoriteTool,
        seasonTitles = cloneArray(statistics.seasonTitles),
    }
end

local function normalizeProfileDetails(rawProfile)
    local details = cloneValue(type(rawProfile.profile) == "table" and rawProfile.profile or {})
    details.galleryItems = limitGalleryItems(details.galleryItems)
    details.flexBorder = details.flexBorder
    details.bio = tostring(details.bio or "")
    details.winrateVisible = details.winrateVisible ~= false
    return details
end

local function normalizeRank(rawProfile, rawRank)
    local nestedRank = type(rawProfile.rank) == "table" and rawProfile.rank or {}
    local rankData = cloneValue(type(rawRank) == "table" and rawRank or {})
    for key, value in pairs(nestedRank) do
        if rankData[key] == nil then
            rankData[key] = cloneValue(value)
        end
    end

    local fallbackRankString = rankData.playerRank or rawProfile.playerRank
    if fallbackRankString == nil and type(rawProfile.profile) == "table" then
        fallbackRankString = rawProfile.profile.rank
    end

    local parsedTier, parsedDivision, parsedVictories = parseLegacyRankName(fallbackRankString)
    local tier = tostring(rankData.tier or parsedTier or DEFAULT_RANK.tier)
    local division = toInteger(rankData.division, parsedDivision or DEFAULT_RANK.division, 0)
    local rank = {
        tier = tier,
        division = division,
        stars = toInteger(rankData.stars, DEFAULT_RANK.stars, 0),
        victories = toInteger(rankData.victories, parsedVictories or DEFAULT_RANK.victories, 0),
    }
    rank.playerRank = formatLegacyRankName(rank)
    return rank
end

local function normalizeRuntimeProfile(userId, source)
    local rawSource = type(source) == "table" and source or {}
    local rawProfile = rawSource
    local rawRank = type(rawSource.rank) == "table" and rawSource.rank or {}

    if rawSource.progression ~= nil or rawSource.statistics ~= nil or rawSource.userId ~= nil then
        rawProfile = rawSource
    elseif type(rawSource.profile) == "table" or type(rawSource.rank) == "table" then
        rawProfile = type(rawSource.profile) == "table" and rawSource.profile or {}
    end

    local profile = defaultProfile(userId)
    profile.progression = normalizeProgression(rawProfile, rawRank)
    profile.statistics = normalizeStatistics(rawProfile)
    profile.profile = normalizeProfileDetails(rawProfile)
    profile.rank = normalizeRank(rawProfile, rawRank)
    return profile
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._persistence = nil
    return self
end

function Service:Init()
    self._state:Set("profileByUserId", self._state:Get("profileByUserId") or {})
    self._state:Set("loadedProfileByUserId", self._state:Get("loadedProfileByUserId") or {})
end

function Service:Start()
    -- Event-driven service.
end

function Service:Stop()
    self._state:Clear()
    self._persistence = nil
end

function Service:_buildRuntimeSnapshot(playerOrUserId)
    local profile = self:_ensureProfile(playerOrUserId)
    if type(profile) ~= "table" then
        return nil
    end

    local totalMatches = math.max(0, math.floor(tonumber(profile.statistics.totalGames) or 0))
    local totalWins = math.max(0, math.floor(tonumber(profile.statistics.totalWins) or 0))
    return {
        userId = profile.userId,
        level = math.max(1, math.floor(tonumber(profile.progression.level) or 1)),
        xp = math.max(0, math.floor(tonumber(profile.progression.exp) or 0)),
        rank = tostring(profile.rank.playerRank or DEFAULT_RANK.playerRank),
        totalMatches = totalMatches,
        totalWins = math.max(0, math.min(totalWins, totalMatches)),
        winRate = calculateWinrate(totalWins, totalMatches),
        favoriteTool = profile.statistics.favoriteTool,
        galleryCount = #(profile.profile.galleryItems or {}),
        bio = tostring(profile.profile.bio or ""),
        flexBorder = profile.profile.flexBorder,
        winrateVisible = profile.profile.winrateVisible ~= false,
        seasonTitleCount = #(profile.statistics.seasonTitles or {}),
    }
end

function Service:_stampRuntimeState(playerOrUserId, payload)
    local player = resolvePlayer(playerOrUserId)
    if not player then
        return
    end

    local snapshot = self:_buildRuntimeSnapshot(player)
    if type(snapshot) ~= "table" then
        return
    end

    local lastSource = type(payload) == "table" and payload.lastSource or nil
    if lastSource == nil then
        lastSource = player:GetAttribute("PasrahProfileLastSource")
    end

    stampProfileRuntime(player, {
        level = snapshot.level,
        xp = snapshot.xp,
        rank = snapshot.rank,
        totalMatches = snapshot.totalMatches,
        totalWins = snapshot.totalWins,
        winRate = snapshot.winRate,
        favoriteTool = snapshot.favoriteTool,
        galleryCount = snapshot.galleryCount,
        bio = snapshot.bio,
        flexBorder = snapshot.flexBorder,
        winrateVisible = snapshot.winrateVisible,
        seasonTitleCount = snapshot.seasonTitleCount,
        lastEvent = type(payload) == "table" and payload.lastEvent or nil,
        lastSource = lastSource,
    })
end

function Service:_profiles()
    return self._state:Get("profileByUserId") or {}
end

function Service:_setProfiles(profileByUserId)
    self._state:Set("profileByUserId", profileByUserId)
end

function Service:_loadedProfiles()
    return self._state:Get("loadedProfileByUserId") or {}
end

function Service:_setLoadedProfiles(loadedProfileByUserId)
    self._state:Set("loadedProfileByUserId", loadedProfileByUserId)
end

function Service:_resolvePersistence()
    if self._persistence then
        return self._persistence
    end

    local persistence = Services.Get(self._deps, "DataPersistenceService")
    if type(persistence) ~= "table" then
        return nil
    end

    if type(persistence.LoadProfile) == "function" and type(persistence.SaveProfile) == "function" then
        self._persistence = persistence
        return self._persistence
    end

    local service = persistence.Service
    if type(service) == "table" and type(service.LoadProfile) == "function" and type(service.SaveProfile) == "function" then
        self._persistence = service
        return self._persistence
    end

    return nil
end

function Service:_storeProfile(userId, profile)
    local profileByUserId = self:_profiles()
    profileByUserId[userId] = normalizeRuntimeProfile(userId, profile)
    self:_setProfiles(profileByUserId)
    return profileByUserId[userId]
end

function Service:_loadProfileFromPersistence(userId)
    local persistence = self:_resolvePersistence()
    if not persistence then
        return nil
    end

    local data = safeCall(persistence, "LoadProfile", userId)
    if type(data) ~= "table" then
        return nil
    end

    return normalizeRuntimeProfile(userId, data)
end

function Service:_syncStatistics(profile)
    if type(profile) ~= "table" or type(profile.statistics) ~= "table" then
        return
    end

    local stats = profile.statistics
    stats.soloGames = toInteger(stats.soloGames, 0, 0)
    stats.soloWins = toInteger(stats.soloWins, 0, 0, stats.soloGames)
    stats.teamGames = toInteger(stats.teamGames, 0, 0)
    stats.teamWins = toInteger(stats.teamWins, 0, 0, stats.teamGames)
    stats.totalGames = math.max(toInteger(stats.totalGames or stats.totalMatches, 0, 0), stats.soloGames + stats.teamGames)
    stats.totalWins = math.max(toInteger(stats.totalWins, 0, 0), stats.soloWins + stats.teamWins)
    stats.totalWins = math.min(stats.totalWins, stats.totalGames)
    stats.soloWinrate = calculateWinrate(stats.soloWins, stats.soloGames)
    stats.teamWinrate = calculateWinrate(stats.teamWins, stats.teamGames)
    stats.seasonTitles = cloneArray(stats.seasonTitles)
end

function Service:_syncRank(profile)
    if type(profile) ~= "table" then
        return
    end

    local progression = profile.progression or {}
    progression.level = toInteger(progression.level, DEFAULT_PROGRESSION.level, 1, MAX_LEVEL)
    progression.exp = toInteger(progression.exp, DEFAULT_PROGRESSION.exp, 0)
    profile.progression = progression

    local details = profile.profile or {}
    details.galleryItems = limitGalleryItems(details.galleryItems)
    details.bio = tostring(details.bio or "")
    details.winrateVisible = details.winrateVisible ~= false
    profile.profile = details

    local rank = profile.rank or {}
    local fallbackTier, fallbackDivision, fallbackVictories = parseLegacyRankName(rank.playerRank)
    rank.tier = tostring(rank.tier or fallbackTier or DEFAULT_RANK.tier)
    rank.division = toInteger(rank.division, fallbackDivision or DEFAULT_RANK.division, 0)
    rank.stars = toInteger(rank.stars, DEFAULT_RANK.stars, 0)
    rank.victories = toInteger(rank.victories, fallbackVictories or DEFAULT_RANK.victories, 0)
    rank.playerRank = formatLegacyRankName(rank)
    profile.rank = rank

    self:_syncStatistics(profile)
end

function Service:_persistencePayload(profile)
    return {
        profile = {
            progression = {
                level = profile.progression.level,
                exp = profile.progression.exp,
            },
            playerLevel = profile.progression.level,
            playerXP = profile.progression.exp,
            statistics = {
                totalGames = profile.statistics.totalGames,
                totalMatches = profile.statistics.totalGames,
                totalWins = profile.statistics.totalWins,
                soloGames = profile.statistics.soloGames,
                soloWins = profile.statistics.soloWins,
                teamGames = profile.statistics.teamGames,
                teamWins = profile.statistics.teamWins,
                soloWinrate = profile.statistics.soloWinrate,
                teamWinrate = profile.statistics.teamWinrate,
                favoriteTool = profile.statistics.favoriteTool,
                seasonTitles = cloneArray(profile.statistics.seasonTitles),
            },
            profile = {
                galleryItems = cloneArray(profile.profile.galleryItems),
                flexBorder = profile.profile.flexBorder,
                bio = profile.profile.bio,
                winrateVisible = profile.profile.winrateVisible,
            },
        },
        rank = {
            playerRank = profile.rank.playerRank,
            tier = profile.rank.tier,
            division = profile.rank.division,
            stars = profile.rank.stars,
            victories = profile.rank.victories,
        },
    }
end

function Service:_persistProfile(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false
    end

    local persistence = self:_resolvePersistence()
    if not persistence then
        return false
    end

    local profile = self:_profiles()[userId]
    if type(profile) ~= "table" then
        return false
    end

    self:_syncRank(profile)
    return safeCall(persistence, "SaveProfile", userId, self:_persistencePayload(profile)) == true
end

function Service:_ensureProfile(playerOrUserId, options)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local profileByUserId = self:_profiles()
    local loadedProfileByUserId = self:_loadedProfiles()
    local forceReload = type(options) == "table" and options.forceReload == true

    local profile = profileByUserId[userId]
    if profile == nil then
        profile = defaultProfile(userId)
        profileByUserId[userId] = profile
        self:_setProfiles(profileByUserId)
    else
        profileByUserId[userId] = normalizeRuntimeProfile(userId, profile)
        profile = profileByUserId[userId]
        self:_setProfiles(profileByUserId)
    end

    if forceReload or not loadedProfileByUserId[userId] then
        local persistedProfile = self:_loadProfileFromPersistence(userId)
        if persistedProfile then
            profileByUserId[userId] = persistedProfile
            profile = persistedProfile
            self:_setProfiles(profileByUserId)
        end
        loadedProfileByUserId[userId] = true
        self:_setLoadedProfiles(loadedProfileByUserId)
    end

    return profile
end

function Service:LoadProfile(playerOrUserId, forceReload)
    local profile = self:_ensureProfile(playerOrUserId, {
        forceReload = forceReload == true,
    })
    if not profile then
        return nil
    end
    self:_stampRuntimeState(playerOrUserId, {
        lastEvent = "ProfileLoaded",
        lastSource = forceReload == true and "load_profile_forced" or "load_profile",
    })
    return self:GetPlayerProfile(playerOrUserId)
end

function Service:SaveProfile(playerOrUserId)
    local ok = self:_persistProfile(playerOrUserId)
    if ok then
        self:_stampRuntimeState(playerOrUserId, {
            lastEvent = "ProfileSaved",
            lastSource = "save_profile",
        })
    end
    return ok
end

function Service:GetPlayerProfile(playerOrUserId)
    local profile = self:_ensureProfile(playerOrUserId)
    if not profile then
        return nil
    end

    local totalMatches = profile.statistics.totalGames
    local totalWins = profile.statistics.totalWins
    local winRate = calculateWinrate(totalWins, totalMatches)

    local snapshot = {
        userId = profile.userId,
        playerXP = profile.progression.exp,
        playerLevel = profile.progression.level,
        totalMatches = totalMatches,
        totalWins = totalWins,
        winRate = winRate,
        progression = {
            level = profile.progression.level,
            exp = profile.progression.exp,
        },
        statistics = {
            totalGames = totalMatches,
            totalMatches = totalMatches,
            totalWins = totalWins,
            soloGames = profile.statistics.soloGames,
            soloWins = profile.statistics.soloWins,
            teamGames = profile.statistics.teamGames,
            teamWins = profile.statistics.teamWins,
            soloWinrate = profile.statistics.soloWinrate,
            teamWinrate = profile.statistics.teamWinrate,
            favoriteTool = profile.statistics.favoriteTool,
            seasonTitles = cloneArray(profile.statistics.seasonTitles),
        },
        profile = {
            galleryItems = cloneArray(profile.profile.galleryItems),
            flexBorder = profile.profile.flexBorder,
            bio = profile.profile.bio,
            winrateVisible = profile.profile.winrateVisible,
            rank = profile.rank.playerRank,
        },
        rank = {
            playerRank = profile.rank.playerRank,
            tier = profile.rank.tier,
            division = profile.rank.division,
            stars = profile.rank.stars,
            victories = profile.rank.victories,
        },
    }
    self:_stampRuntimeState(playerOrUserId, {
        lastEvent = "ProfileSnapshotBuilt",
    })
    return snapshot
end

function Service:UpdateProfile(playerOrUserId, changes)
    local profile = self:_ensureProfile(playerOrUserId)
    if not profile then
        return false, "invalid_player"
    end

    local profileChanges = changes and changes.profile or {}
    if profileChanges.bio ~= nil then
        profile.profile.bio = tostring(profileChanges.bio)
    end
    if profileChanges.flexBorder ~= nil then
        profile.profile.flexBorder = profileChanges.flexBorder
    end
    if profileChanges.winrateVisible ~= nil then
        profile.profile.winrateVisible = profileChanges.winrateVisible == true
    end
    if type(profileChanges.galleryItems) == "table" then
        profile.profile.galleryItems = limitGalleryItems(profileChanges.galleryItems)
    end

    local progressionChanges = cloneValue(changes and changes.progression or {})
    if changes and changes.playerXP ~= nil and progressionChanges.exp == nil then
        progressionChanges.exp = changes.playerXP
    end
    if changes and changes.playerLevel ~= nil and progressionChanges.level == nil then
        progressionChanges.level = changes.playerLevel
    end
    if progressionChanges.exp ~= nil then
        profile.progression.exp = toInteger(progressionChanges.exp, profile.progression.exp, 0)
    end
    if progressionChanges.level ~= nil then
        profile.progression.level = toInteger(progressionChanges.level, profile.progression.level, 1, MAX_LEVEL)
    end

    local statisticsChanges = changes and changes.statistics or {}
    if statisticsChanges.totalMatches ~= nil and statisticsChanges.totalGames == nil then
        statisticsChanges.totalGames = statisticsChanges.totalMatches
    end
    if statisticsChanges.totalGames ~= nil then
        profile.statistics.totalGames = toInteger(statisticsChanges.totalGames, profile.statistics.totalGames, 0)
    end
    if statisticsChanges.totalWins ~= nil then
        profile.statistics.totalWins = toInteger(statisticsChanges.totalWins, profile.statistics.totalWins, 0)
    end
    if statisticsChanges.soloGames ~= nil then
        profile.statistics.soloGames = toInteger(statisticsChanges.soloGames, profile.statistics.soloGames, 0)
    end
    if statisticsChanges.soloWins ~= nil then
        profile.statistics.soloWins = toInteger(statisticsChanges.soloWins, profile.statistics.soloWins, 0)
    end
    if statisticsChanges.teamGames ~= nil then
        profile.statistics.teamGames = toInteger(statisticsChanges.teamGames, profile.statistics.teamGames, 0)
    end
    if statisticsChanges.teamWins ~= nil then
        profile.statistics.teamWins = toInteger(statisticsChanges.teamWins, profile.statistics.teamWins, 0)
    end
    if statisticsChanges.favoriteTool ~= nil then
        profile.statistics.favoriteTool = statisticsChanges.favoriteTool
    end
    if type(statisticsChanges.seasonTitles) == "table" then
        profile.statistics.seasonTitles = cloneArray(statisticsChanges.seasonTitles)
    end

    local rankChanges = changes and changes.rank
    if type(rankChanges) == "string" then
        rankChanges = { playerRank = rankChanges }
    end
    if type(rankChanges) == "table" then
        if rankChanges.playerRank ~= nil then
            profile.rank.playerRank = tostring(rankChanges.playerRank)
        end
        if rankChanges.tier ~= nil then
            profile.rank.tier = tostring(rankChanges.tier)
        end
        if rankChanges.division ~= nil then
            profile.rank.division = toInteger(rankChanges.division, profile.rank.division, 0)
        end
        if rankChanges.stars ~= nil then
            profile.rank.stars = toInteger(rankChanges.stars, profile.rank.stars, 0)
        end
        if rankChanges.victories ~= nil then
            profile.rank.victories = toInteger(rankChanges.victories, profile.rank.victories, 0)
        end
    end

    self:_syncRank(profile)
    self:_persistProfile(playerOrUserId)
    self:_stampRuntimeState(playerOrUserId, {
        lastEvent = "ProfileUpdated",
        lastSource = "update_profile",
    })
    return true, nil, self:GetPlayerProfile(playerOrUserId)
end

function Service:GetPlayerLevel(playerOrUserId)
    local profile = self:_ensureProfile(playerOrUserId)
    if not profile then
        return nil
    end
    return profile.progression.level
end

function Service:_expToNextLevel(level)
    return 100 + ((level - 1) * 20)
end

function Service:AddExperience(playerOrUserId, amount)
    local profile = self:_ensureProfile(playerOrUserId)
    if not profile then
        return false, "invalid_player"
    end

    local exp = math.max(math.floor(amount or 0), 0)
    if exp <= 0 then
        return true, nil, profile.progression.level
    end

    profile.progression.exp += exp
    while profile.progression.level < MAX_LEVEL do
        local required = self:_expToNextLevel(profile.progression.level)
        if profile.progression.exp < required then
            break
        end
        profile.progression.exp -= required
        profile.progression.level += 1
    end

    if profile.progression.level >= MAX_LEVEL then
        profile.progression.level = MAX_LEVEL
        profile.progression.exp = 0
    end

    self:_persistProfile(playerOrUserId)
    return true, nil, profile.progression.level
end

function Service:OnPlayerEnteredLobby(player)
    self:LoadProfile(player)
end

function Service:OnPlayerAdded(player)
    self:LoadProfile(player)
end

function Service:OnPlayerRemoving(player)
    self:SaveProfile(player)
end

function Service:OnPlayerRewardGranted(payload)
    local player = payload and (payload.player or payload.userId)
    local amount = payload and payload.amount or 0
    local currency = payload and payload.currency
    if currency ~= "MM" then
        return
    end

    local exp = math.max(math.floor(amount / 10), 1)
    self:AddExperience(player, exp)
end

function Service:OnRankUpdated(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    local profile = self:_ensureProfile(playerOrUserId)
    if not profile then
        return
    end

    local rankChanged = false
    local rankName = payload and (payload.playerRank or payload.rank)
    if rankName ~= nil then
        profile.rank.playerRank = tostring(rankName)
        rankChanged = true
    end
    if payload and payload.tier ~= nil then
        profile.rank.tier = tostring(payload.tier)
        rankChanged = true
    end
    if payload and payload.division ~= nil then
        profile.rank.division = toInteger(payload.division, profile.rank.division, 0)
        rankChanged = true
    end
    if payload and payload.stars ~= nil then
        profile.rank.stars = toInteger(payload.stars, profile.rank.stars, 0)
        rankChanged = true
    end
    if payload and payload.victories ~= nil then
        profile.rank.victories = toInteger(payload.victories, profile.rank.victories, 0)
        rankChanged = true
    end

    if rankChanged then
        self:_syncRank(profile)
    end

    local tier = payload and payload.tier
    if tier ~= nil then
        local title = tostring(tier)
        local alreadyTracked = false
        for _, existing in ipairs(profile.statistics.seasonTitles) do
            if existing == title then
                alreadyTracked = true
                break
            end
        end
        if not alreadyTracked then
            table.insert(profile.statistics.seasonTitles, title)
        end
    end

    self:_persistProfile(playerOrUserId)
    self:_stampRuntimeState(playerOrUserId, {
        lastEvent = "ProfileRankUpdated",
        lastSource = "rank_updated",
    })
end

function Service:OnMatchEnded(payload)
    local results = payload and payload.results or {}
    local changedPlayers = {}

    for _, entry in ipairs(results.playerResults or {}) do
        local playerOrUserId = entry.player or entry.userId
        local userId = toUserId(playerOrUserId)
        local profile = self:_ensureProfile(playerOrUserId)
        if profile and userId then
            profile.statistics.totalGames += 1
            local isSolo = entry.isSolo == true
            local didWin = entry.didWin == true or (entry.performancePercent or 0) > 50

            if isSolo then
                profile.statistics.soloGames += 1
                if didWin then
                    profile.statistics.soloWins += 1
                end
            else
                profile.statistics.teamGames += 1
                if didWin then
                    profile.statistics.teamWins += 1
                end
            end

            if didWin then
                profile.statistics.totalWins += 1
            end

            if entry.favoriteTool then
                profile.statistics.favoriteTool = entry.favoriteTool
            end

            self:_syncStatistics(profile)
            changedPlayers[userId] = true
        end
    end

    for userId in pairs(changedPlayers) do
        self:_persistProfile(userId)
        self:_stampRuntimeState(userId, {
            lastEvent = "ProfileMatchStatsApplied",
            lastSource = "match_ended",
        })
    end
end

return Service
