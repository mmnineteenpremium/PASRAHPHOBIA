local EvidenceSync = {}
EvidenceSync.__index = EvidenceSync

local function resolveEventBus(deps)
    local eventBus = deps and deps.EventBus
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

function EvidenceSync.new(deps)
    local self = setmetatable({}, EvidenceSync)
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    return self
end

function EvidenceSync:PushUpdate(matchId, updateType, payload)
    if not self._eventBus then
        return
    end

    self._eventBus:Publish("EvidenceSyncUpdated", {
        matchId = matchId,
        updateType = updateType,
        payload = payload,
    })
end

return EvidenceSync
