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
        PlayerProfileSystem = Services.Get(self._deps, "PlayerProfileSystem"),
    }
end

function Service:Init()
    self._state:Set("inspectRequests", self._state:Get("inspectRequests") or {})
    self._state:Set("lastInspections", self._state:Get("lastInspections") or {})
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

function Service:RequestInspect(requestingPlayer, targetPlayer)
    local requesterId = toUserId(requestingPlayer)
    local targetId = toUserId(targetPlayer)
    if not requesterId or not targetId then
        return false, "invalid_player"
    end

    local inspectRequests = self._state:Get("inspectRequests") or {}
    inspectRequests[requesterId] = {
        targetUserId = targetId,
        at = os.time(),
    }
    self._state:Set("inspectRequests", inspectRequests)

    local profileSystem = self._dependencies.PlayerProfileSystem
    local profile = safeCall(profileSystem, "GetPublicProfile", targetPlayer, requestingPlayer)
    if profile == nil and type(profileSystem) == "table" and type(profileSystem.Service) == "table" then
        profile = safeCall(profileSystem.Service, "GetPublicProfile", targetPlayer, requestingPlayer)
    end

    local payload = {
        requestingUserId = requesterId,
        targetUserId = targetId,
        profile = profile,
        cosmetics = profile and profile.equippedCosmetics or {},
        statistics = {
            totalMatches = profile and profile.totalMatches or 0,
            winRate = profile and profile.winRate or 0,
            rankTier = profile and profile.rankTier or "Bayi III",
            playerLevel = profile and profile.playerLevel or 1,
        },
        flexGallery = profile and profile.flexGallery or {},
    }

    local lastInspections = self._state:Get("lastInspections") or {}
    lastInspections[requesterId] = payload
    self._state:Set("lastInspections", lastInspections)

    self:_publish("PlayerInspectDataSent", payload)
    return true
end

function Service:OnPlayerInspectRequested(payload)
    if type(payload) ~= "table" then
        return
    end
    self:RequestInspect(payload.requestingPlayer, payload.targetPlayer)
end

return Service