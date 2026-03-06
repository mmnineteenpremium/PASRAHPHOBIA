local Service = {}
Service.__index = Service

local MAX_LEVEL = 100

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

local function defaultProfile(userId)
    return {
        userId = userId,
        progression = {
            level = 1,
            exp = 0,
        },
        statistics = {
            totalGames = 0,
            soloGames = 0,
            soloWins = 0,
            teamGames = 0,
            teamWins = 0,
            soloWinrate = 0,
            teamWinrate = 0,
            favoriteTool = nil,
            seasonTitles = {},
        },
        profile = {
            galleryItems = {},
            flexBorder = nil,
            bio = "",
            winrateVisible = true,
        },
    }
end

local function cloneArray(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    return self
end

function Service:Init()
    self._state:Set("profileByUserId", {})
end

function Service:Start()
    -- Start runtime tasks or loops here.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_profiles()
    return self._state:Get("profileByUserId") or {}
end

function Service:_setProfiles(profileByUserId)
    self._state:Set("profileByUserId", profileByUserId)
end

function Service:_ensureProfile(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end
    local profileByUserId = self:_profiles()
    if not profileByUserId[userId] then
        profileByUserId[userId] = defaultProfile(userId)
        self:_setProfiles(profileByUserId)
    end
    return profileByUserId[userId]
end

function Service:GetPlayerProfile(player)
    local profile = self:_ensureProfile(player)
    if not profile then
        return nil
    end

    return {
        userId = profile.userId,
        progression = {
            level = profile.progression.level,
            exp = profile.progression.exp,
        },
        statistics = {
            totalGames = profile.statistics.totalGames,
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
    }
end

function Service:UpdateProfile(player, changes)
    local profile = self:_ensureProfile(player)
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
        local limited = {}
        for _, itemId in ipairs(profileChanges.galleryItems) do
            table.insert(limited, itemId)
            if #limited >= 3 then
                break
            end
        end
        profile.profile.galleryItems = limited
    end

    return true, nil, self:GetPlayerProfile(player)
end

function Service:GetPlayerLevel(player)
    local profile = self:_ensureProfile(player)
    if not profile then
        return nil
    end
    return profile.progression.level
end

function Service:_expToNextLevel(level)
    return 100 + ((level - 1) * 20)
end

function Service:AddExperience(player, amount)
    local profile = self:_ensureProfile(player)
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

    return true, nil, profile.progression.level
end

function Service:OnPlayerEnteredLobby(player)
    self:_ensureProfile(player)
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
    local player = payload and (payload.player or payload.userId)
    local profile = self:_ensureProfile(player)
    if not profile then
        return
    end

    local tier = payload and payload.tier
    if not tier then
        return
    end

    local title = tostring(tier)
    for _, existing in ipairs(profile.statistics.seasonTitles) do
        if existing == title then
            return
        end
    end
    table.insert(profile.statistics.seasonTitles, title)
end

function Service:OnMatchEnded(payload)
    local results = payload and payload.results or {}

    for _, entry in ipairs(results.playerResults or {}) do
        local player = entry.player
        local profile = self:_ensureProfile(player or entry.userId)
        if profile then
            profile.statistics.totalGames += 1
            local isSolo = entry.isSolo == true
            local didWin = entry.didWin == true or (entry.performancePercent or 0) > 50

            if isSolo then
                profile.statistics.soloGames += 1
                if didWin then
                    profile.statistics.soloWins += 1
                end
                if profile.statistics.soloGames > 0 then
                    profile.statistics.soloWinrate = math.floor((profile.statistics.soloWins / profile.statistics.soloGames) * 100)
                end
            else
                profile.statistics.teamGames += 1
                if didWin then
                    profile.statistics.teamWins += 1
                end
                if profile.statistics.teamGames > 0 then
                    profile.statistics.teamWinrate = math.floor((profile.statistics.teamWins / profile.statistics.teamGames) * 100)
                end
            end

            if entry.favoriteTool then
                profile.statistics.favoriteTool = entry.favoriteTool
            end
        end
    end
end

return Service

