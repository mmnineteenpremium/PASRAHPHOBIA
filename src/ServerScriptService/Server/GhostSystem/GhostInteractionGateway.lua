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


local DEFAULT_BOUNDS = {
    min = Vector3.new(-5000, -5000, -5000),
    max = Vector3.new(5000, 5000, 5000),
}

local function resolveMatchSystem(deps)
    local match = Services.Get(deps, "MatchSystem")
    if type(match) ~= "table" then
        return nil
    end
    return match
end

local function resolveSpectatorSystem(deps)
    local spectator = Services.Get(deps, "SpectatorSystem")
    if type(spectator) ~= "table" then
        return nil
    end
    if type(spectator.IsSpectator) == "function" then
        return spectator
    end
    if type(spectator.Service) == "table" and type(spectator.Service.IsSpectator) == "function" then
        return spectator.Service
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


function GhostInteractionGateway:_resolveMatchForPlayer(player)
    local state = self._matchSystem and self._matchSystem.State
    local matches = state and state:Get("matches")
    if type(matches) ~= "table" then
        return nil, nil
    end

    for matchId, match in pairs(matches) do
        for _, entry in ipairs((match and match.players) or {}) do
            if entry == player then
                return matchId, match
            end
            if type(entry) == "number" and player and entry == player.UserId then
                return matchId, match
            end
            if typeof(entry) == "Instance" and entry:IsA("Player") and player and entry.UserId == player.UserId then
                return matchId, match
            end
        end
    end

    return nil, nil
end

function GhostInteractionGateway:_resolveBounds(match)
    local reference = match and match.mapReference
    if type(reference) == "table" then
        local bounds = reference.bounds or reference.Bounds
        if bounds and bounds.min and bounds.max then
            return bounds
        end
    elseif typeof(reference) == "Instance" then
        local minAttr = reference:GetAttribute("BoundsMin")
        local maxAttr = reference:GetAttribute("BoundsMax")
        if typeof(minAttr) == "Vector3" and typeof(maxAttr) == "Vector3" then
            return { min = minAttr, max = maxAttr }
        end
    end
    return DEFAULT_BOUNDS
end

function GhostInteractionGateway:_isWithinBounds(position, bounds)
    if typeof(position) ~= "Vector3" then
        return false
    end
    local minBound = bounds.min
    local maxBound = bounds.max
    return position.X >= minBound.X and position.X <= maxBound.X
        and position.Y >= minBound.Y and position.Y <= maxBound.Y
        and position.Z >= minBound.Z and position.Z <= maxBound.Z
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
    if not (folder and folder:IsA("Folder")) then
        warn(string.format(
            "[GhostInteractionGateway] Missing canonical folder ReplicatedStorage.%s",
            REMOTE_FUNCTIONS_FOLDER_NAME
        ))
        return nil
    end

    local remote = folder:FindFirstChild(REQUEST_REMOTE_NAME)
    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    warn(string.format(
        "[GhostInteractionGateway] Missing canonical remote ReplicatedStorage.%s.%s",
        REMOTE_FUNCTIONS_FOLDER_NAME,
        REQUEST_REMOTE_NAME
    ))
    return nil
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
