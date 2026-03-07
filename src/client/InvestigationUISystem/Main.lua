local InvestigationUISystem = {}
InvestigationUISystem.__index = InvestigationUISystem

function InvestigationUISystem:Init(context)
    self._context = context
    self._remotes = context.Remotes or {}
    self._connections = {}
    self._uiState = {
        uiEvidenceState = {},
        ghostPredictionState = {},
        journalState = {},
        isVisible = false,
    }
end

function InvestigationUISystem:Start()
    local evidenceRemote = self._remotes.EvidenceEvent
    if evidenceRemote and evidenceRemote.OnClientEvent then
        table.insert(self._connections, evidenceRemote.OnClientEvent:Connect(function(payload)
            self:_onEvidenceEvent(payload)
        end))
    end
end

function InvestigationUISystem:Stop()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function InvestigationUISystem:_onEvidenceEvent(payload)
    if type(payload) ~= "table" then
        return
    end
    local eventName = payload.eventName
    if type(eventName) ~= "string" then
        return
    end

    if eventName == "UIEvidenceUpdated" then
        self._uiState.uiEvidenceState = payload
        self._uiState.isVisible = true
    elseif eventName == "UIGhostPredictionUpdated" then
        self._uiState.ghostPredictionState = payload
        self._uiState.isVisible = true
    elseif eventName == "JournalUpdated" then
        self._uiState.journalState = payload
        self._uiState.isVisible = true
    end
end

function InvestigationUISystem:GetUIEvidenceState()
    return self._uiState.uiEvidenceState
end

function InvestigationUISystem:GetGhostPredictionState()
    return self._uiState.ghostPredictionState
end

function InvestigationUISystem:GetJournalState()
    return self._uiState.journalState
end

return setmetatable({}, InvestigationUISystem)
