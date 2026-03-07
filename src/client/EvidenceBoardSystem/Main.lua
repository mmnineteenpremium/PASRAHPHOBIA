local EvidenceBoardSystem = {}
EvidenceBoardSystem.__index = EvidenceBoardSystem

function EvidenceBoardSystem:Init(context)
    self._context = context
    self._remotes = context.Remotes or {}
    self._connections = {}
    self._state = {
        uiEvidenceState = {},
        evidenceBoard = {},
        lastUpdatedAt = 0,
    }
end

function EvidenceBoardSystem:Start()
    local evidenceRemote = self._remotes.EvidenceEvent
    if evidenceRemote and evidenceRemote.OnClientEvent then
        table.insert(self._connections, evidenceRemote.OnClientEvent:Connect(function(payload)
            self:_onEvidenceEvent(payload)
        end))
    end
end

function EvidenceBoardSystem:Stop()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function EvidenceBoardSystem:_onEvidenceEvent(payload)
    if type(payload) ~= "table" or payload.eventName ~= "UIEvidenceUpdated" then
        return
    end

    self._state.uiEvidenceState = payload
    self._state.lastUpdatedAt = os.clock()

    local board = {}
    for _, evidenceType in ipairs(payload.discoveredEvidence or {}) do
        board[evidenceType] = true
    end
    for _, evidenceType in ipairs(payload.confirmedEvidence or {}) do
        board[evidenceType] = true
    end
    self._state.evidenceBoard = board
end

function EvidenceBoardSystem:GetEvidenceBoard()
    return self._state.evidenceBoard
end

function EvidenceBoardSystem:GetState()
    return self._state
end

return setmetatable({}, EvidenceBoardSystem)
