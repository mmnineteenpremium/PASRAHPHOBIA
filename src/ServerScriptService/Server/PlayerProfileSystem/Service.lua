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
    local winRate = 0
    local flexGallery = {}
    local equippedCosmetics = {}

    if type(profile) == "table" then
        level = tonumber(profile.playerLevel or (profile.progression and profile.progression.level)) or level
        rank = tostring(profile.rank or (profile.profile and profile.profile.rank) or rank)
        local stats = profile.statistics or {}
        totalMatches = tonumber(stats.totalMatches) or totalMatches
        local solo = tonumber(stats.soloGames) or 0
        local team = tonumber(stats.teamGames) or 0
        local totalGames = solo + team
        local soloWins = tonumber(stats.soloWins) or 0
        local teamWins = tonumber(stats.teamWins) or 0
        local totalWins = soloWins + teamWins
        if totalGames > 0 then
            winRate = math.floor((totalWins / totalGames) * 100)
        end
        flexGallery = profile.profile and profile.profile.galleryItems or {}
    end

    local invProfile = safeCall(inventorySystem, "GetPlayerInventory", playerRef or userId)
    if invProfile == nil and type(inventorySystem) == "table" and type(inventorySystem.Service) == "table" then
        invProfile = safeCall(inventorySystem.Service, "GetPlayerInventory", playerRef or userId)
    end
    if type(invProfile) == "table" then
        equippedCosmetics = invProfile.equipmentSlots or invProfile.equippedCosmetics or equippedCosmetics
    end

    return {
        userId = userId,
        playerLevel = math.max(1, math.floor(level)),
        rankTier = rank,
        totalMatches = math.max(0, math.floor(totalMatches)),
        winRate = math.max(0, math.floor(winRate)),
        flexGallery = flexGallery,
        equippedCosmetics = equippedCosmetics,
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