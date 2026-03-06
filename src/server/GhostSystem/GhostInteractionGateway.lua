local Services = require(script.Parent.Parent.Core.Services)

local GhostInteractionGateway = {}
GhostInteractionGateway.__index = GhostInteractionGateway

local REMOTE_FUNCTIONS_FOLDER_NAME = "RemoteFunctions"
local REQUEST_REMOTE_NAME = "GhostInteractionRequest"
local REQUEST_COOLDOWN_SECONDS = 0.75
local MAX_PLAYER_TARGET_DISTANCE = 35

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

local function resolveSanityService(deps)
    local sanity = Services.Get(deps, "SanitySystem")
    if type(sanity) ~= "table" then
        return nil
    end
    if type(sanity.DrainSanity) == "function" then
        return sanity
    end
    if type(sanity.Service) == "table" and type(sanity.Service.DrainSanity) == "function" then
        return sanity.Service
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

function GhostInteractionGateway.new(ghostService, deps)
    local self = setmetatable({}, GhostInteractionGateway)
    self._ghostService = ghostService
    self._deps = deps or {}
    self._security = resolveSecurityService(self._deps)
    self._sanity = resolveSanityService(self._deps)
    self._eventBus = resolveEventBus(self._deps)
    self._remote = nil
    self._lastRequestAtByUserId = {}
    return self
end

function GhostInteractionGateway:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function GhostInteractionGateway:_resolveRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok or typeof(replicatedStorage) ~= "Instance" then
        return nil
    end

    local folder = replicatedStorage:FindFirstChild(REMOTE_FUNCTIONS_FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = REMOTE_FUNCTIONS_FOLDER_NAME
        folder.Parent = replicatedStorage
    end

    local remote = folder:FindFirstChild(REQUEST_REMOTE_NAME)
    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    local created = Instance.new("RemoteFunction")
    created.Name = REQUEST_REMOTE_NAME
    created.Parent = folder
    return created
end

function GhostInteractionGateway:Start()
    self._remote = self:_resolveRemote()
    if not self._remote then
        return
    end
    self._remote.OnServerInvoke = function(player, request)
        return self:HandleRequest(player, request)
    end
end

function GhostInteractionGateway:Stop()
    if self._remote then
        self._remote.OnServerInvoke = nil
    end
    table.clear(self._lastRequestAtByUserId)
end

function GhostInteractionGateway:_validateRemote(player, request)
    if type(request) ~= "table" then
        return false, "invalid_request"
    end

    if self._security then
        local ok, reason = self._security:ValidateRemoteRequest(player, REQUEST_REMOTE_NAME, request, {
            system = "GhostSystem",
        })
        if not ok then
            return false, reason or "blocked_by_security"
        end
        local matchOk, matchErr = self._security:ValidateMatchRequest(player, {
            action = "GhostInteractionRequest",
            targetPosition = request.targetPosition,
        })
        if not matchOk then
            return false, matchErr or "invalid_match_request"
        end
    end

    local userId = player and player.UserId
    if not userId then
        return false, "invalid_player"
    end
    local now = os.clock()
    local last = self._lastRequestAtByUserId[userId] or 0
    if (now - last) < REQUEST_COOLDOWN_SECONDS then
        return false, "request_cooldown"
    end
    self._lastRequestAtByUserId[userId] = now
    return true
end

function GhostInteractionGateway:_validateProximity(player, request, ghostState)
    local character = player and player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local targetPosition = request and request.targetPosition
    if hrp and typeof(targetPosition) == "Vector3" then
        local distance = (targetPosition - hrp.Position).Magnitude
        if distance > MAX_PLAYER_TARGET_DISTANCE then
            return false, "target_too_far"
        end
    end

    local targetRoomId = request and (request.roomId or request.targetRoomId)
    local ghostRoomId = ghostState and (ghostState.currentRoomId or ghostState.favoriteRoomId)
    if ghostRoomId and targetRoomId and tostring(ghostRoomId) ~= tostring(targetRoomId) then
        return false, "ghost_not_in_range"
    end
    return true
end

function GhostInteractionGateway:HandleRequest(player, request)
    local ok, reason = self:_validateRemote(player, request)
    if not ok then
        return {
            success = false,
            reason = reason,
        }
    end

    local matchId = request and request.matchId
    if not matchId then
        return {
            success = false,
            reason = "missing_match_id",
        }
    end

    local ghostState = self._ghostService:GetGhostState(matchId)
    if not ghostState then
        return {
            success = false,
            reason = "ghost_not_found",
        }
    end

    local nearOk, nearReason = self:_validateProximity(player, request, ghostState)
    if not nearOk then
        return {
            success = false,
            reason = nearReason,
        }
    end

    local action = request.action or "Interact"
    if action == "ProvokeGhost" then
        self._ghostService:ApplyDirectorEvent(matchId, "TensionHigh", {
            source = "GhostInteractionRequest",
            roomId = request.roomId,
            now = request.now or os.clock(),
        })
        if self._sanity then
            self._sanity:DrainSanity(player, 1.5, matchId, "ghost_interaction_request")
        end
    end

    self:_publish("GhostInteractionRequested", {
        player = player,
        matchId = matchId,
        action = action,
        roomId = request.roomId,
    })

    return {
        success = true,
        reason = "accepted",
        matchId = matchId,
        ghostState = {
            state = ghostState.state,
            roomId = ghostState.currentRoomId or ghostState.favoriteRoomId,
            huntActive = ghostState.huntActive == true,
        },
    }
end

return GhostInteractionGateway
