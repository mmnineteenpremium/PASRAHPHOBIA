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
    self._state:Set("friendLists", self._state:Get("friendLists") or {})
    self._state:Set("pendingRequests", self._state:Get("pendingRequests") or {})
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

function Service:_ensureUserState(userId)
    local friendLists = self._state:Get("friendLists") or {}
    local pendingRequests = self._state:Get("pendingRequests") or {}

    friendLists[userId] = friendLists[userId] or {}
    pendingRequests[userId] = pendingRequests[userId] or {}

    self._state:Set("friendLists", friendLists)
    self._state:Set("pendingRequests", pendingRequests)
end

function Service:_saveFriendData(userId)
    local persistence = self._dependencies.DataPersistenceService
    local friendLists = self._state:Get("friendLists") or {}
    if type(persistence) ~= "table" then
        return
    end

    local payload = {
        friends = friendLists[userId] or {},
    }

    safeCall(persistence, "SaveProfile", userId, payload)
    if type(persistence.Service) == "table" then
        safeCall(persistence.Service, "SaveProfile", userId, payload)
    end
end

function Service:SendFriendRequest(fromPlayer, toPlayer)
    local fromId = toUserId(fromPlayer)
    local toId = toUserId(toPlayer)
    if not fromId or not toId then
        return false, "invalid_player"
    end
    if fromId == toId then
        return false, "cannot_friend_self"
    end

    self:_ensureUserState(fromId)
    self:_ensureUserState(toId)

    local friendLists = self._state:Get("friendLists") or {}
    if friendLists[fromId][toId] == true then
        return false, "already_friends"
    end

    local pendingRequests = self._state:Get("pendingRequests") or {}
    pendingRequests[toId][fromId] = {
        fromUserId = fromId,
        at = os.time(),
    }
    self._state:Set("pendingRequests", pendingRequests)

    self:_publish("FriendRequestSent", {
        fromUserId = fromId,
        toUserId = toId,
    })

    self:_publish("NotificationSent", {
        toUserId = toId,
        type = "FriendRequest",
        message = "Friend request received",
        payload = { fromUserId = fromId },
    })

    return true
end

function Service:AcceptFriendRequest(player, fromUserId)
    local toId = toUserId(player)
    local fromId = toUserId(fromUserId)
    if not toId or not fromId then
        return false, "invalid_player"
    end

    self:_ensureUserState(fromId)
    self:_ensureUserState(toId)

    local pendingRequests = self._state:Get("pendingRequests") or {}
    if not (pendingRequests[toId] and pendingRequests[toId][fromId]) then
        return false, "request_not_found"
    end

    pendingRequests[toId][fromId] = nil
    self._state:Set("pendingRequests", pendingRequests)

    local friendLists = self._state:Get("friendLists") or {}
    friendLists[toId][fromId] = true
    friendLists[fromId][toId] = true
    self._state:Set("friendLists", friendLists)

    self:_saveFriendData(toId)
    self:_saveFriendData(fromId)

    self:_publish("FriendRequestAccepted", {
        fromUserId = fromId,
        toUserId = toId,
    })

    return true
end

function Service:DeclineFriendRequest(player, fromUserId)
    local toId = toUserId(player)
    local fromId = toUserId(fromUserId)
    if not toId or not fromId then
        return false, "invalid_player"
    end

    local pendingRequests = self._state:Get("pendingRequests") or {}
    if pendingRequests[toId] then
        pendingRequests[toId][fromId] = nil
    end
    self._state:Set("pendingRequests", pendingRequests)

    self:_publish("FriendRequestDeclined", {
        fromUserId = fromId,
        toUserId = toId,
    })

    return true
end

function Service:GetFriendList(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end

    self:_ensureUserState(userId)
    local friendLists = self._state:Get("friendLists") or {}
    local out = {}
    for friendId in pairs(friendLists[userId]) do
        table.insert(out, friendId)
    end
    return out
end

return Service