local Players = game:GetService("Players")
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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

local function cloneArray(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function toInteger(value, defaultValue, minValue)
    local number = tonumber(value)
    if number == nil then
        number = defaultValue
    end

    number = math.floor(number or 0)
    if minValue ~= nil then
        number = math.max(minValue, number)
    end
    return number
end

local function calculateWinRate(totalWins, totalMatches)
    totalWins = math.max(0, toInteger(totalWins, 0))
    totalMatches = math.max(0, toInteger(totalMatches, 0))
    if totalMatches <= 0 then
        return 0
    end
    return math.floor((totalWins / totalMatches) * 100)
end

local function countEntries(source)
    if type(source) ~= "table" then
        return 0
    end
    local total = 0
    for _ in pairs(source) do
        total += 1
    end
    return total
end

local function stampPlayerProfileRuntime(target, payload)
    if typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end

    target:SetAttribute("PasrahPlayerProfileOwner", "PlayerProfileSystem")
    target:SetAttribute("PasrahPlayerProfileTargetUserId", math.max(0, math.floor(tonumber(payload.targetUserId) or 0)))
    target:SetAttribute("PasrahPlayerProfileLevel", math.max(1, math.floor(tonumber(payload.level) or 1)))
    target:SetAttribute("PasrahPlayerProfileRank", tostring(payload.rank or "Bayi III"))
    target:SetAttribute("PasrahPlayerProfileTotalMatches", math.max(0, math.floor(tonumber(payload.totalMatches) or 0)))
    target:SetAttribute("PasrahPlayerProfileTotalWins", math.max(0, math.floor(tonumber(payload.totalWins) or 0)))
    target:SetAttribute("PasrahPlayerProfileWinRate", math.max(0, math.floor(tonumber(payload.winRate) or 0)))
    target:SetAttribute("PasrahPlayerProfileGalleryCount", math.max(0, math.floor(tonumber(payload.galleryCount) or 0)))
    target:SetAttribute("PasrahPlayerProfileEquippedCosmeticCount", math.max(0, math.floor(tonumber(payload.equippedCount) or 0)))
    target:SetAttribute("PasrahPlayerProfileViewCount", math.max(0, math.floor(tonumber(payload.viewCount) or 0)))
    target:SetAttribute("PasrahPlayerProfileLastEvent", type(payload.lastEvent) == "string" and payload.lastEvent or nil)
    target:SetAttribute("PasrahPlayerProfileUpdatedAt", os.clock())
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
        LobbySocialHub = Services.Get(self._deps, "LobbySocialHub"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        InventorySystem = Services.Get(self._deps, "InventorySystem"),
        CosmeticSystem = Services.Get(self._deps, "CosmeticSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
    }
end

function Service:Init()
    self._state:Set("cachedProfiles", self._state:Get("cachedProfiles") or {})
    self._state:Set("profileViews", self._state:Get("profileViews") or {})
end

function Service:Start()
    -- Event-driven service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_buildRuntimeSnapshot(targetPlayerOrUserId, viewerPlayerOrUserId)
    local targetUserId = toUserId(targetPlayerOrUserId)
    if not targetUserId then
        return nil
    end

    local cachedProfiles = self._state:Get("cachedProfiles") or {}
    local profile = cachedProfiles[targetUserId]
    if type(profile) ~= "table" then
        profile = self:RefreshProfile(targetPlayerOrUserId)
    end
    if type(profile) ~= "table" then
        return nil
    end

    local viewCount = 0
    local viewerId = toUserId(viewerPlayerOrUserId)
    if viewerId then
        local profileViews = self._state:Get("profileViews") or {}
        viewCount = #(profileViews[viewerId] or {})
    end

    return {
        targetUserId = targetUserId,
        level = math.max(1, math.floor(tonumber(profile.playerLevel) or 1)),
        rank = tostring(profile.rankTier or "Bayi III"),
        totalMatches = math.max(0, math.floor(tonumber(profile.totalMatches) or 0)),
        totalWins = math.max(0, math.floor(tonumber(profile.totalWins) or 0)),
        winRate = math.max(0, math.floor(tonumber(profile.winRate) or 0)),
        galleryCount = #(profile.flexGallery or {}),
        equippedCount = countEntries(profile.equippedCosmetics),
        viewCount = viewCount,
    }
end

function Service:_stampRuntimeState(viewerPlayerOrUserId, targetPlayerOrUserId, payload)
    local viewer = resolvePlayer(viewerPlayerOrUserId)
    if not viewer then
        return
    end

    local snapshot = self:_buildRuntimeSnapshot(targetPlayerOrUserId, viewer)
    if type(snapshot) ~= "table" then
        return
    end

    stampPlayerProfileRuntime(viewer, {
        targetUserId = snapshot.targetUserId,
        level = snapshot.level,
        rank = snapshot.rank,
        totalMatches = snapshot.totalMatches,
        totalWins = snapshot.totalWins,
        winRate = snapshot.winRate,
        galleryCount = snapshot.galleryCount,
        equippedCount = snapshot.equippedCount,
        viewCount = snapshot.viewCount,
        lastEvent = type(payload) == "table" and payload.lastEvent or nil,
    })
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_buildProfile(userId, playerRef)
    local profileSystem = self._dependencies.ProfileSystem
    local inventorySystem = self._dependencies.InventorySystem

    local profile = safeCall(profileSystem, "GetPlayerProfile", playerRef or userId)
    if profile == nil and type(profileSystem) == "table" and type(profileSystem.Service) == "table" then
        profile = safeCall(profileSystem.Service, "GetPlayerProfile", playerRef or userId)
    end

    local level = 1
    local rank = "Bayi III"
    local totalMatches = 0
    local totalWins = 0
    local winRate = 0
    local flexGallery = {}
    local equippedCosmetics = {}

    if type(profile) == "table" then
        level = tonumber(profile.playerLevel or (profile.progression and profile.progression.level)) or level
        local rankData = type(profile.rank) == "table" and profile.rank or {}
        rank = tostring(rankData.playerRank or profile.rankTier or (profile.profile and profile.profile.rank) or rank)
        local stats = profile.statistics or {}
        local solo = toInteger(stats.soloGames, 0, 0)
        local team = toInteger(stats.teamGames, 0, 0)
        totalMatches = toInteger(
            profile.totalMatches
            or stats.totalMatches
            or stats.totalGames,
            solo + team,
            0
        )
        totalMatches = math.max(totalMatches, solo + team)

        local soloWins = toInteger(stats.soloWins, 0, 0)
        local teamWins = toInteger(stats.teamWins, 0, 0)
        totalWins = toInteger(profile.totalWins or stats.totalWins, soloWins + teamWins, 0)
        totalWins = math.max(totalWins, soloWins + teamWins)
        totalWins = math.min(totalWins, totalMatches)
        winRate = toInteger(profile.winRate, calculateWinRate(totalWins, totalMatches), 0)
        flexGallery = cloneArray(profile.profile and profile.profile.galleryItems or profile.flexGallery or {})
    end

    local invProfile = safeCall(inventorySystem, "GetPlayerInventory", playerRef or userId)
    if invProfile == nil and type(inventorySystem) == "table" and type(inventorySystem.Service) == "table" then
        invProfile = safeCall(inventorySystem.Service, "GetPlayerInventory", playerRef or userId)
    end
    if type(invProfile) == "table" then
        equippedCosmetics = invProfile.equipmentSlots or invProfile.equippedCosmetics or equippedCosmetics
    end
    if next(equippedCosmetics) == nil then
        local equipmentSlots = safeCall(inventorySystem, "GetEquipmentSlots", playerRef or userId)
        if equipmentSlots == nil and type(inventorySystem) == "table" and type(inventorySystem.Service) == "table" then
            equipmentSlots = safeCall(inventorySystem.Service, "GetEquipmentSlots", playerRef or userId)
        end
        if type(equipmentSlots) == "table" then
            equippedCosmetics = equipmentSlots
        end
    end

    return {
        userId = userId,
        playerLevel = math.max(1, math.floor(level)),
        rankTier = rank,
        totalMatches = math.max(0, math.floor(totalMatches)),
        totalWins = math.max(0, math.floor(totalWins)),
        winRate = math.max(0, math.floor(winRate)),
        flexGallery = flexGallery,
        equippedCosmetics = equippedCosmetics,
        rank = type(profile) == "table" and profile.rank or nil,
        statistics = type(profile) == "table" and profile.statistics or nil,
        updatedAt = os.time(),
    }
end

function Service:RefreshProfile(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local cachedProfiles = self._state:Get("cachedProfiles") or {}
    cachedProfiles[userId] = self:_buildProfile(userId, playerOrUserId)
    self._state:Set("cachedProfiles", cachedProfiles)
    self:_stampRuntimeState(playerOrUserId, playerOrUserId, {
        lastEvent = "PlayerProfileRefreshed",
    })
    return cachedProfiles[userId]
end

function Service:GetPublicProfile(targetPlayerOrUserId, viewerPlayerOrUserId)
    local targetUserId = toUserId(targetPlayerOrUserId)
    if not targetUserId then
        return nil
    end

    local cachedProfiles = self._state:Get("cachedProfiles") or {}
    local profile = cachedProfiles[targetUserId]
    if profile == nil then
        profile = self:RefreshProfile(targetPlayerOrUserId)
    end

    if profile and viewerPlayerOrUserId then
        local viewerId = toUserId(viewerPlayerOrUserId)
        if viewerId then
            local profileViews = self._state:Get("profileViews") or {}
            profileViews[viewerId] = profileViews[viewerId] or {}
            table.insert(profileViews[viewerId], {
                targetUserId = targetUserId,
                at = os.time(),
            })
            self._state:Set("profileViews", profileViews)

            self:_publish("PlayerProfileViewed", {
                viewerUserId = viewerId,
                targetUserId = targetUserId,
            })
        end
    end

    local runtimeViewer = viewerPlayerOrUserId or targetPlayerOrUserId
    self:_stampRuntimeState(runtimeViewer, targetPlayerOrUserId, {
        lastEvent = "PlayerProfileViewed",
    })

    return profile
end

function Service:OnPlayerJoinedLobby(payload)
    local player = payload and payload.player or payload
    if player then
        self:RefreshProfile(player)
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
                self:RefreshProfile(player)
            end
        end
    elseif payload.player then
        self:RefreshProfile(payload.player)
    end
end

return Service
