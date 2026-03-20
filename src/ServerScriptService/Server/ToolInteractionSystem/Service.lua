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

local function toUserId(player)
    if type(player) == "number" then
        return player
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
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
        MapInteractionSystem = Services.Get(self._deps, "MapInteractionSystem"),
        InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
    }
    self._state:Set("activeInteractions", {})
    self._state:Set("activeMatchId", nil)
end

function Service:Start()
    -- Event-driven system.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:OnMatchStarted(payload)
    if type(payload) ~= "table" then
        return
    end
    self._state:Set("activeMatchId", payload.matchId)
    self._state:Set("activeInteractions", {})
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if activeMatchId ~= nil and matchId ~= nil and activeMatchId ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("activeInteractions", {})
end

function Service:HandleToolActivation(payload)
    if type(payload) ~= "table" then
        return false, "invalid_payload"
    end

    local player = payload.player
    local userId = toUserId(player or payload.userId)
    if not userId then
        return false, "invalid_player"
    end

    local toolType = payload.toolType
    if type(toolType) ~= "string" or toolType == "" then
        return false, "invalid_tool_type"
    end

    local interactions = self._state:Get("activeInteractions") or {}
    interactions[userId] = {
        userId = userId,
        player = player,
        toolType = toolType,
        activatedAt = os.clock(),
        matchId = payload.matchId or self._state:Get("activeMatchId"),
        position = payload.position,
    }
    self._state:Set("activeInteractions", interactions)

    self:_publish("ToolActivated", {
        player = player,
        userId = userId,
        toolType = toolType,
        matchId = payload.matchId or self._state:Get("activeMatchId"),
        position = payload.position,
        metadata = payload.metadata,
        activatedAt = interactions[userId].activatedAt,
    })

    return true
end

return Service
