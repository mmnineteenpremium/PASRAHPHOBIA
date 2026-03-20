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
    self._state:Set("pendingNotifications", self._state:Get("pendingNotifications") or {})
    self._state:Set("notificationHistory", self._state:Get("notificationHistory") or {})
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

function Service:SendNotification(toPlayerOrUserId, notificationType, message, payload)
    local userId = toUserId(toPlayerOrUserId)
    if not userId then
        return false, "invalid_target"
    end

    local entry = {
        id = string.format("n_%d_%d", userId, os.clock() * 1000),
        type = tostring(notificationType or "General"),
        message = tostring(message or ""),
        payload = payload or {},
        at = os.time(),
    }

    local pending = self._state:Get("pendingNotifications") or {}
    local history = self._state:Get("notificationHistory") or {}

    pending[userId] = pending[userId] or {}
    history[userId] = history[userId] or {}

    table.insert(pending[userId], entry)
    table.insert(history[userId], entry)

    self._state:Set("pendingNotifications", pending)
    self._state:Set("notificationHistory", history)

    self:_publish("NotificationSent", {
        toUserId = userId,
        notification = entry,
    })

    return true
end

function Service:GetPendingNotifications(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return {}
    end
    local pending = self._state:Get("pendingNotifications") or {}
    return pending[userId] or {}
end

function Service:ConsumeNotifications(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return {}
    end
    local pending = self._state:Get("pendingNotifications") or {}
    local data = pending[userId] or {}
    pending[userId] = {}
    self._state:Set("pendingNotifications", pending)
    return data
end

function Service:OnFriendRequestSent(payload)
    if type(payload) == "table" and payload.toUserId then
        self:SendNotification(payload.toUserId, "FriendRequest", "Friend request received", payload)
    end
end

function Service:OnPartyInviteSent(payload)
    if type(payload) == "table" and payload.toUserId then
        self:SendNotification(payload.toUserId, "PartyInvite", "Party invite received", payload)
    end
end

function Service:OnPlayerProfileViewed(payload)
    if type(payload) == "table" and payload.targetUserId then
        self:SendNotification(payload.targetUserId, "ProfileViewed", "Your profile was viewed", payload)
    end
end

function Service:OnPlayerJoinedLobby(payload)
    local player = payload and payload.player or payload
    local userId = toUserId(player)
    if userId then
        self:SendNotification(userId, "Lobby", "Player joined lobby", { userId = userId })
    end
end

return Service