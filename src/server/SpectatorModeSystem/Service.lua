local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_BOUNDS = {
    min = Vector3.new(-120, 1, -120),
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

local function resolveBounds(payload)
    local candidate = payload and (payload.spectatorBounds or payload.cameraBounds or payload.mapBounds)
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
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
    self._state:Set("activeMatchId", self._state:Get("activeMatchId"))
    self._state:Set("spectators", self._state:Get("spectators") or {})
    self._state:Set("spectatorMetaByMatchId", self._state:Get("spectatorMetaByMatchId") or {})
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

function Service:_spectatorMap()
    return self._state:Get("spectators") or {}
end

function Service:_setSpectatorMap(mapValue)
    self._state:Set("spectators", mapValue)
end

function Service:_metaMap()
    return self._state:Get("spectatorMetaByMatchId") or {}
end

function Service:_setMetaMap(mapValue)
    self._state:Set("spectatorMetaByMatchId", mapValue)
end

function Service:_boundsMap()
    return self._state:Get("cameraBoundsByMatchId") or {}
end

function Service:_setBoundsMap(mapValue)
    self._state:Set("cameraBoundsByMatchId", mapValue)
end

function Service:_setBounds(matchId, bounds)
    local boundsByMatch = self:_boundsMap()
    boundsByMatch[matchId] = bounds
    self:_setBoundsMap(boundsByMatch)
end

function Service:_getBounds(matchId)
    return self:_boundsMap()[matchId] or DEFAULT_BOUNDS
end

function Service:_registerSpectator(matchId, userId, player, reason)
    local spectators = self:_spectatorMap()
    spectators[matchId] = spectators[matchId] or {}
    spectators[matchId][userId] = true
    self:_setSpectatorMap(spectators)

    local metadata = self:_metaMap()
    metadata[matchId] = metadata[matchId] or {}
    metadata[matchId][userId] = {
        reason = reason or "death",
        enteredAt = os.clock(),
    }
    self:_setMetaMap(metadata)

    local bounds = self:_getBounds(matchId)
    self:_publish("SpectatorModeStarted", {
        matchId = matchId,
        userId = userId,
        player = player,
        mode = "FreeCamera",
        cameraBounds = bounds,
        limitedAwareness = true,
        source = "SpectatorModeSystem",
    })
    self:_publish("PlayerEnteredSpectator", {
        matchId = matchId,
        userId = userId,
        player = player,
        source = "SpectatorModeSystem",
    })
end

function Service:_removeSpectator(matchId, userId, player, reason)
    local spectators = self:_spectatorMap()
    if type(spectators[matchId]) == "table" then
        spectators[matchId][userId] = nil
    end
    self:_setSpectatorMap(spectators)

    local metadata = self:_metaMap()
    if type(metadata[matchId]) == "table" then
        metadata[matchId][userId] = nil
    end
    self:_setMetaMap(metadata)

    self:_publish("SpectatorModeEnded", {
        matchId = matchId,
        userId = userId,
        player = player,
        reason = reason or "exit",
        source = "SpectatorModeSystem",
    })
end

function Service:_clearMatch(matchId)
    local spectators = self:_spectatorMap()
    local matchSpectators = spectators[matchId] or {}
    spectators[matchId] = nil
    self:_setSpectatorMap(spectators)

    local metadata = self:_metaMap()
    metadata[matchId] = nil
    self:_setMetaMap(metadata)

    local bounds = self:_boundsMap()
    bounds[matchId] = nil
    self:_setBoundsMap(bounds)

    for userId in pairs(matchSpectators) do
        self:_publish("SpectatorModeEnded", {
            matchId = matchId,
            userId = userId,
            reason = "match_ended",
            source = "SpectatorModeSystem",
        })
    end
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        self._state:Set("activeMatchId", matchId)
        self:_setBounds(matchId, resolveBounds(payload))
        local spectators = self:_spectatorMap()
        spectators[matchId] = {}
        self:_setSpectatorMap(spectators)
        return
    end

    if eventName == "MatchEnded" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        self:_clearMatch(matchId)
        if self._state:Get("activeMatchId") == matchId then
            self._state:Set("activeMatchId", nil)
        end
        return
    end

    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    if eventName == "PlayerDied" or eventName == "PlayerKilled" or eventName == "SpectatorTransitionRequested" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if not userId then
            return
        end
        self:_registerSpectator(matchId, userId, payload and payload.player, payload and payload.reason)
        return
    end

    if eventName == "PlayerDisconnected" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if not userId then
            return
        end
        self:_removeSpectator(matchId, userId, payload and payload.player, "disconnected")
    end
end

return Service
