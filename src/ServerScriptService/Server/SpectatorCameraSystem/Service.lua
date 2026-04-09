local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_BOUNDS = {
    min = Vector3.new(-120, 2, -120),
    max = Vector3.new(120, 80, 120),
}

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

local function clampVector3(position, bounds)
    local minBound = bounds.min
    local maxBound = bounds.max
    return Vector3.new(
        math.clamp(position.X, minBound.X, maxBound.X),
        math.clamp(position.Y, minBound.Y, maxBound.Y),
        math.clamp(position.Z, minBound.Z, maxBound.Z)
    )
end

local function centerFromBounds(bounds)
    return (bounds.min + bounds.max) * 0.5
end

local function vectorToString(value)
    if typeof(value) ~= "Vector3" then
        return nil
    end
    return string.format("%.3f, %.3f, %.3f", value.X, value.Y, value.Z)
end

local function resolveBounds(payload)
    local candidate = payload and (payload.cameraBounds or payload.spectatorBounds or payload.mapBounds)
    if type(candidate) == "table" and typeof(candidate.min) == "Vector3" and typeof(candidate.max) == "Vector3" then
        return candidate
    end
    return DEFAULT_BOUNDS
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    return self
end

function Service:Init()
    self._dependencies = {
        SpectatorModeSystem = Services.Get(self._deps, "SpectatorModeSystem"),
    }
    self._state:Set("activeMatchId", self._state:Get("activeMatchId"))
    self._state:Set("cameraStateBySpectator", self._state:Get("cameraStateBySpectator") or {})
    self._state:Set("cameraBoundsByMatchId", self._state:Get("cameraBoundsByMatchId") or {})
end

function Service:Start()
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_matchId(payload)
    return payload and payload.matchId or self._state:Get("activeMatchId")
end

function Service:_cameraStateMap()
    return self._state:Get("cameraStateBySpectator") or {}
end

function Service:_setCameraStateMap(value)
    self._state:Set("cameraStateBySpectator", value)
end

function Service:_boundsMap()
    return self._state:Get("cameraBoundsByMatchId") or {}
end

function Service:_setBoundsMap(value)
    self._state:Set("cameraBoundsByMatchId", value)
end

function Service:_getBounds(matchId)
    return self:_boundsMap()[matchId] or DEFAULT_BOUNDS
end

function Service:_setBounds(matchId, bounds)
    local mapValue = self:_boundsMap()
    mapValue[matchId] = bounds
    self:_setBoundsMap(mapValue)
end

function Service:_upsertCameraState(userId, build)
    local cameraMap = self:_cameraStateMap()
    cameraMap[userId] = build
    self:_setCameraStateMap(cameraMap)
end

function Service:_removeCameraState(userId)
    local cameraMap = self:_cameraStateMap()
    cameraMap[userId] = nil
    self:_setCameraStateMap(cameraMap)
end

function Service:_stampRuntime(player, payload)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    player:SetAttribute("PasrahSpectatorCameraOwner", "SpectatorCameraSystem")
    player:SetAttribute("PasrahSpectatorCameraMatchId", type(payload.matchId) == "string" and payload.matchId or nil)
    player:SetAttribute("PasrahSpectatorCameraMode", type(payload.mode) == "string" and payload.mode or nil)
    player:SetAttribute("PasrahSpectatorCameraTargetUserId", tonumber(payload.targetUserId))
    player:SetAttribute("PasrahSpectatorCameraPosition", vectorToString(payload.position))
    player:SetAttribute("PasrahSpectatorCameraRotation", vectorToString(payload.rotation))
    player:SetAttribute("PasrahSpectatorCameraBoundsMin", type(payload.bounds) == "table" and vectorToString(payload.bounds.min) or nil)
    player:SetAttribute("PasrahSpectatorCameraBoundsMax", type(payload.bounds) == "table" and vectorToString(payload.bounds.max) or nil)
    player:SetAttribute("PasrahSpectatorCameraCanObserveLivingPlayers", payload.canObserveLivingPlayers == true)
    player:SetAttribute("PasrahSpectatorCameraCanObserveGhost", payload.canObserveGhost == true)
    player:SetAttribute("PasrahSpectatorCameraLimitedAwareness", payload.limitedAwareness == true)
    player:SetAttribute("PasrahSpectatorCameraLastEvent", type(payload.lastEvent) == "string" and payload.lastEvent or nil)
    player:SetAttribute("PasrahSpectatorCameraReason", type(payload.reason) == "string" and payload.reason or nil)
    player:SetAttribute("PasrahSpectatorCameraActive", payload.active == true)
    player:SetAttribute("PasrahSpectatorCameraLastUpdatedAt", os.clock())
end

function Service:_emitCameraUpdated(matchId, userId, player, lastEvent)
    local cameraMap = self:_cameraStateMap()
    local state = cameraMap[userId]
    if not state then
        return
    end
    local runtimePlayer = player
    if typeof(runtimePlayer) ~= "Instance" or not runtimePlayer:IsA("Player") then
        runtimePlayer = Players:GetPlayerByUserId(userId)
    end
    self:_stampRuntime(runtimePlayer, {
        matchId = matchId,
        mode = state.mode,
        targetUserId = state.targetUserId,
        position = state.position,
        rotation = state.rotation,
        canObserveLivingPlayers = state.canObserveLivingPlayers,
        canObserveGhost = state.canObserveGhost,
        limitedAwareness = state.limitedAwareness,
        bounds = state.bounds,
        lastEvent = lastEvent,
        reason = state.reason,
        active = true,
    })
    self:_publish("SpectatorCameraUpdated", {
        matchId = matchId,
        userId = userId,
        player = runtimePlayer,
        cameraState = state,
        source = "SpectatorCameraSystem",
    })
end

function Service:_onSpectatorModeStarted(payload)
    local matchId = self:_matchId(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if type(matchId) ~= "string" or not userId then
        return
    end

    local bounds = resolveBounds(payload)
    self:_setBounds(matchId, bounds)

    self:_upsertCameraState(userId, {
        mode = "FreeCamera",
        position = centerFromBounds(bounds),
        rotation = Vector3.new(0, 0, 0),
        targetUserId = payload and payload.targetUserId,
        canObserveLivingPlayers = true,
        canObserveGhost = true,
        limitedAwareness = true,
        bounds = bounds,
        reason = payload and payload.reason,
    })
    self:_emitCameraUpdated(matchId, userId, payload and payload.player, "SpectatorModeStarted")
end

function Service:_onCameraInput(payload)
    local matchId = self:_matchId(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if type(matchId) ~= "string" or not userId then
        return
    end

    local cameraMap = self:_cameraStateMap()
    local state = cameraMap[userId]
    if not state then
        return
    end

    local moveVector = payload and payload.moveVector
    local deltaTime = tonumber(payload and payload.deltaTime) or 0.05
    local speed = tonumber(payload and payload.speed) or 28
    local newPosition = state.position
    if typeof(moveVector) == "Vector3" then
        newPosition = state.position + (moveVector * speed * deltaTime)
    end

    local bounds = state.bounds or self:_getBounds(matchId)
    state.position = clampVector3(newPosition, bounds)
    state.rotation = payload and payload.rotation or state.rotation
    cameraMap[userId] = state
    self:_setCameraStateMap(cameraMap)
    self:_emitCameraUpdated(matchId, userId, payload and payload.player, "SpectatorCameraInput")
end

function Service:_onTargetChanged(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end
    local cameraMap = self:_cameraStateMap()
    local state = cameraMap[userId]
    if not state then
        return
    end
    state.targetUserId = payload and payload.targetUserId
    cameraMap[userId] = state
    self:_setCameraStateMap(cameraMap)
    self:_emitCameraUpdated(self:_matchId(payload), userId, payload and payload.player, "SpectatorTargetChanged")
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        self._state:Set("activeMatchId", matchId)
        self:_setBounds(matchId, resolveBounds(payload))
        for _, player in ipairs(type(payload.players) == "table" and payload.players or {}) do
            self:_stampRuntime(player, {
                matchId = matchId,
                mode = nil,
                bounds = self:_getBounds(matchId),
                lastEvent = "MatchStarted",
                reason = "match_started",
                active = false,
            })
        end
        return
    end

    if eventName == "MatchEnded" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        local cameraMap = self:_cameraStateMap()
        for userId, state in pairs(cameraMap) do
            local player = Players:GetPlayerByUserId(userId)
            self:_stampRuntime(player, {
                matchId = matchId,
                mode = nil,
                targetUserId = nil,
                position = state.position,
                rotation = state.rotation,
                canObserveLivingPlayers = state.canObserveLivingPlayers,
                canObserveGhost = state.canObserveGhost,
                limitedAwareness = state.limitedAwareness,
                bounds = state.bounds,
                lastEvent = "MatchEnded",
                reason = "match_ended",
                active = false,
            })
        end
        self._state:Set("cameraStateBySpectator", {})
        local boundsByMatch = self:_boundsMap()
        boundsByMatch[matchId] = nil
        self:_setBoundsMap(boundsByMatch)
        if self._state:Get("activeMatchId") == matchId then
            self._state:Set("activeMatchId", nil)
        end
        return
    end

    if eventName == "SpectatorModeStarted" then
        self:_onSpectatorModeStarted(payload)
        return
    end

    if eventName == "SpectatorModeEnded" or eventName == "PlayerDisconnected" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local cameraMap = self:_cameraStateMap()
            local state = cameraMap[userId]
            self:_stampRuntime(payload and payload.player or Players:GetPlayerByUserId(userId), {
                matchId = self:_matchId(payload),
                mode = nil,
                targetUserId = nil,
                position = state and state.position or nil,
                rotation = state and state.rotation or nil,
                canObserveLivingPlayers = state and state.canObserveLivingPlayers or false,
                canObserveGhost = state and state.canObserveGhost or false,
                limitedAwareness = state and state.limitedAwareness or false,
                bounds = state and state.bounds or self:_getBounds(self:_matchId(payload)),
                lastEvent = eventName,
                reason = payload and payload.reason or (eventName == "PlayerDisconnected" and "disconnected" or "spectator_ended"),
                active = false,
            })
            self:_removeCameraState(userId)
        end
        return
    end

    if eventName == "SpectatorTargetChanged" then
        self:_onTargetChanged(payload)
        return
    end

    if eventName == "SpectatorCameraInput" then
        self:_onCameraInput(payload)
    end
end

return Service
