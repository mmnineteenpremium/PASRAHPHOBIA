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

local function normalizeStrength(raw)
    local number = tonumber(raw)
    if number == nil then
        return 0
    end
    return math.clamp(number, 0, 1)
end

local function buildSignalType(payload, strength)
    if payload and type(payload.signalType) == "string" and payload.signalType ~= "" then
        return payload.signalType
    end
    if strength >= 0.8 then
        return "StrongParanormalSignal"
    end
    if strength >= 0.5 then
        return "WeakParanormalSignal"
    end
    return "AmbientNoise"
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
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        EvidenceSystem = Services.Get(self._deps, "EvidenceSystem"),
    }
    self._state:Set("processedSignals", {})
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
    self._state:Set("processedSignals", {})
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if activeMatchId ~= nil and matchId ~= nil and activeMatchId ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("processedSignals", {})
end

function Service:ProcessToolSignal(payload)
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

    local strength = normalizeStrength(payload.signalStrength or payload.signal or payload.reading)
    local processedSignal = {
        player = player,
        userId = userId,
        toolType = toolType,
        signalStrength = strength,
        signalType = buildSignalType(payload, strength),
        confidence = math.clamp(strength * 1.15, 0, 1),
        matchId = payload.matchId or self._state:Get("activeMatchId"),
        metadata = payload.metadata,
        timestamp = os.clock(),
    }

    local processedSignals = self._state:Get("processedSignals") or {}
    processedSignals[userId] = processedSignals[userId] or {}
    processedSignals[userId][toolType] = processedSignal
    self._state:Set("processedSignals", processedSignals)

    self:_publish("ToolSignalReceived", processedSignal)
    return true, processedSignal
end

return Service
