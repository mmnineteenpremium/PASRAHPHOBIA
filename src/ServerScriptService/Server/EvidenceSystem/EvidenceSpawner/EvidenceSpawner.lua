local CoreEvidenceSpawner = require(script.Parent.Parent.Modules.EvidenceSpawner)

local EvidenceSpawner = {}
EvidenceSpawner.__index = EvidenceSpawner

function EvidenceSpawner.new(deps)
    local self = setmetatable({}, EvidenceSpawner)
    self._core = CoreEvidenceSpawner.new(deps)
    return self
end

function EvidenceSpawner:TrySpawn(session, context)
    return self._core:TrySpawn(session, context)
end

return EvidenceSpawner
