local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local TOOL_SIGNAL_THRESHOLDS = {
    JejakEnergi = 0.5,
    KotakArwah = 0.45,
    SuhuMembeku = 0.6,
    BukuTerkutuk = 0.55,
    BolaArwah = 0.7,
    GerakanGaib = 0.5,
}

local TOOL_EVIDENCE_MAP = {
    JejakEnergi = "MEDOK",
    KotakArwah = "Suara",
    SuhuMembeku = "Suhu",
    BukuTerkutuk = "BukuTerkutuk",
    BolaArwah = "To'un",
    GerakanGaib = "Pengganggu",
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
        EvidenceSystem = Services.Get(self._deps, "EvidenceSystem"),
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
        MapInteractionSystem = Services.Get(self._deps, "MapInteractionSystem"),
    }
    self._state:Set("activeTools", {})
    self._state:Set("toolSignals", {})
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
    self._state:Set("activeTools", {})
    self._state:Set("toolSignals", {})
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if activeMatchId ~= nil and matchId ~= nil and activeMatchId ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("activeTools", {})
    self._state:Set("toolSignals", {})
end

function Service:TrackActivatedTool(payload)
    if type(payload) ~= "table" then
        return
    end

    local player = payload.player
    local userId = toUserId(player or payload.userId)
    local toolType = payload.toolType
    if not userId or type(toolType) ~= "string" or toolType == "" then
        return
    end

    local activeTools = self._state:Get("activeTools") or {}
    activeTools[userId] = activeTools[userId] or {}
    activeTools[userId][toolType] = {
        userId = userId,
        player = player,
        toolType = toolType,
        activatedAt = payload.activatedAt or os.clock(),
        matchId = payload.matchId or self._state:Get("activeMatchId"),
    }
    self._state:Set("activeTools", activeTools)
end

function Service:ValidateAndDetectEvidence(payload)
    if type(payload) ~= "table" then
        return false, "invalid_payload"
    end

    local player = payload.player
    local userId = toUserId(player or payload.userId)
    local toolType = payload.toolType
    if not userId then
        return false, "invalid_player"
    end
    if type(toolType) ~= "string" or toolType == "" then
        return false, "invalid_tool_type"
    end

    local strength = math.clamp(tonumber(payload.signalStrength) or 0, 0, 1)
    local threshold = TOOL_SIGNAL_THRESHOLDS[toolType] or 0.5
    local valid = strength >= threshold

    local toolSignals = self._state:Get("toolSignals") or {}
    toolSignals[userId] = toolSignals[userId] or {}
    toolSignals[userId][toolType] = {
        signalStrength = strength,
        signalType = payload.signalType,
        confidence = payload.confidence,
        matchId = payload.matchId or self._state:Get("activeMatchId"),
        timestamp = payload.timestamp or os.clock(),
    }
    self._state:Set("toolSignals", toolSignals)

    if not valid then
        return false, "signal_below_threshold"
    end

    local evidenceType = payload.evidenceType or TOOL_EVIDENCE_MAP[toolType]
    if type(evidenceType) ~= "string" or evidenceType == "" then
        return false, "unknown_evidence_type"
    end

    self:_publish("EvidenceDetected", {
        player = player,
        userId = userId,
        matchId = payload.matchId or self._state:Get("activeMatchId"),
        toolType = toolType,
        evidenceType = evidenceType,
        signalStrength = strength,
        signalType = payload.signalType,
        confidence = payload.confidence,
        metadata = payload.metadata,
        detectedAt = os.clock(),
    })

    return true
end

return Service
