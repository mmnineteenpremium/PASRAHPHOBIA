local GhostPredictionSystem = {}
GhostPredictionSystem.__index = GhostPredictionSystem

function GhostPredictionSystem:Init(context)
    self._context = context
    self._remotes = context.Remotes or {}
    self._connections = {}
    self._state = {
        ghostPredictionState = {},
        candidates = {},
        lastUpdatedAt = 0,
    }
end

function GhostPredictionSystem:Start()
    local evidenceRemote = self._remotes.EvidenceEvent
    if evidenceRemote and evidenceRemote.OnClientEvent then
        table.insert(self._connections, evidenceRemote.OnClientEvent:Connect(function(payload)
            self:_onEvidenceEvent(payload)
        end))
    end
end

function GhostPredictionSystem:Stop()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function GhostPredictionSystem:_onEvidenceEvent(payload)
    if type(payload) ~= "table" or payload.eventName ~= "UIGhostPredictionUpdated" then
        return
    end

    self._state.ghostPredictionState = payload
    self._state.lastUpdatedAt = os.clock()
    self._state.candidates = payload.candidates or payload.possibleGhosts or {}
end

function GhostPredictionSystem:GetCandidates()
    return self._state.candidates
end

function GhostPredictionSystem:GetState()
    return self._state
end

return setmetatable({}, GhostPredictionSystem)
