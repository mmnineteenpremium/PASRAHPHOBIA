local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local COSMETIC_REMOTE_NAME = "CosmeticEvent"
local COSMETIC_REQUEST_COOLDOWN_SECONDS = 0.25

local VALID_ACTIONS = {
    EquipCosmetic = true,
    UnequipCosmetic = true,
    Equip = true,
    Unequip = true,
}

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Subscribe) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then
        return eventBus.Service
    end
    return nil
end

local function resolveSecurityService(deps)
    local security = Services.Get(deps, "SecuritySystem")
    if type(security) ~= "table" then
        return nil
    end
    if type(security.ValidateRemoteRequest) == "function" then
        return security
    end
    if type(security.Service) == "table" and type(security.Service.ValidateRemoteRequest) == "function" then
        return security.Service
    end
    return nil
end

local function toUserId(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
end

local function resolveCosmeticRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end

    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end

    local remote = remoteFolder:FindFirstChild(COSMETIC_REMOTE_NAME)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = nil
    self._security = nil
    self._subscriptions = {}
    self._registered = false
    self._cosmeticRemote = nil
    self._remoteConnection = nil
    self._lastRequestAtByUserId = {}
    return self
end

function Controller:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._security = resolveSecurityService(self._deps)
    self._cosmeticRemote = resolveCosmeticRemote()
end

function Controller:Init()
    -- Event subscriptions happen in Start.
end

function Controller:Start()
    self:RegisterEventHandlers()
    self:_connectCosmeticRemote()
end

function Controller:Stop()
    self:_disconnectCosmeticRemote()
    self:UnregisterEventHandlers()
    table.clear(self._lastRequestAtByUserId)
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._registered then
        return
    end

    self:_subscribe("EquipCosmeticRequest", function(payload)
        if payload and payload.player and payload.cosmeticId then
            if payload.source == "CosmeticEvent" then
                return
            end
            self._service:EquipCosmetic(payload.player, payload.cosmeticId)
        end
    end)

    self:_subscribe("UnequipCosmeticRequest", function(payload)
        if payload and payload.player and payload.cosmeticSlot then
            if payload.source == "CosmeticEvent" then
                return
            end
            self._service:UnequipCosmetic(payload.player, payload.cosmeticSlot)
        end
    end)

    self:_subscribe("PlayerEnteredLobby", function(payload)
        if payload and payload.player then
            self._service:ApplyCosmetic(payload.player)
        end
    end)

    self:_subscribe("PlayerJoinedLobby", function(payload)
        if payload and payload.player then
            self._service:ApplyCosmetic(payload.player)
        end
    end)

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus or not self._registered then
        return
    end

    for _, subscription in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
    end
    table.clear(self._subscriptions)
    self._registered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Controller:_connectCosmeticRemote()
    if self._remoteConnection then
        return
    end
    if not self._cosmeticRemote then
        self._cosmeticRemote = resolveCosmeticRemote()
    end
    if not self._cosmeticRemote then
        return
    end

    self._remoteConnection = self._cosmeticRemote.OnServerEvent:Connect(function(player, request)
        self:OnCosmeticRemoteRequest(player, request)
    end)
end

function Controller:_disconnectCosmeticRemote()
    if self._remoteConnection then
        self._remoteConnection:Disconnect()
        self._remoteConnection = nil
    end
end

function Controller:_send(player, payload)
    if self._cosmeticRemote and player then
        self._cosmeticRemote:FireClient(player, payload)
    end
end

function Controller:_validateRemoteRequest(player, request)
    if type(request) ~= "table" then
        return false, "invalid_request"
    end

    self:_publish("RemoteEventReceived", {
        player = player,
        remoteName = COSMETIC_REMOTE_NAME,
        payload = request,
        context = {
            system = "CosmeticSystem",
        },
    })

    if not self._security then
        return true
    end

    local ok, reason = self._security:ValidateRemoteRequest(player, COSMETIC_REMOTE_NAME, request, {
        system = "CosmeticSystem",
    })
    if not ok then
        return false, reason or "blocked_by_security"
    end
    return true
end

function Controller:_validateCooldown(player)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local now = os.clock()
    local last = self._lastRequestAtByUserId[userId] or 0
    if (now - last) < COSMETIC_REQUEST_COOLDOWN_SECONDS then
        return false, "cosmetic_cooldown"
    end
    self._lastRequestAtByUserId[userId] = now
    return true
end

function Controller:OnCosmeticRemoteRequest(player, request)
    local requestId = type(request) == "table" and request.requestId or nil
    local validRequest, requestErr = self:_validateRemoteRequest(player, request)
    if not validRequest then
        self:_send(player, {
            eventName = "CosmeticRequestProcessed",
            requestId = requestId,
            success = false,
            reason = requestErr,
        })
        return
    end

    local action = request.action
    if type(action) ~= "string" or not VALID_ACTIONS[action] then
        self:_send(player, {
            eventName = "CosmeticRequestProcessed",
            requestId = requestId,
            success = false,
            reason = "unsupported_action",
        })
        return
    end

    local cooldownOk, cooldownErr = self:_validateCooldown(player)
    if not cooldownOk then
        self:_send(player, {
            eventName = "CosmeticRequestProcessed",
            requestId = requestId,
            success = false,
            reason = cooldownErr,
        })
        return
    end

    local ok, reason, slot, cosmeticId
    if action == "EquipCosmetic" or action == "Equip" then
        cosmeticId = request.cosmeticId or (type(request.payload) == "table" and request.payload.cosmeticId) or request.itemId
        if type(cosmeticId) ~= "string" or cosmeticId == "" then
            ok, reason = false, "invalid_cosmetic"
        else
            self:_publish("EquipCosmeticRequest", {
                player = player,
                cosmeticId = cosmeticId,
                requestId = requestId,
                source = "CosmeticEvent",
            })
            ok, reason, slot = self._service:EquipCosmetic(player, cosmeticId)
        end
    else
        slot = request.cosmeticSlot or request.slot or (type(request.payload) == "table" and (request.payload.cosmeticSlot or request.payload.slot))
        if type(slot) ~= "string" or slot == "" then
            ok, reason = false, "invalid_slot"
        else
            self:_publish("UnequipCosmeticRequest", {
                player = player,
                cosmeticSlot = slot,
                slot = slot,
                requestId = requestId,
                source = "CosmeticEvent",
            })
            ok, reason = self._service:UnequipCosmetic(player, slot)
        end
    end

    self:_send(player, {
        eventName = "CosmeticRequestProcessed",
        requestId = requestId,
        action = action,
        success = ok == true,
        reason = reason,
        cosmeticId = cosmeticId,
        slot = slot,
    })
end

return Controller
