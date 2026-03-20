local CoreEvidenceValidator = require(script.Parent.Parent.Modules.EvidenceValidator)

local EvidenceValidator = {}
EvidenceValidator.__index = EvidenceValidator

function EvidenceValidator.new(deps)
    local self = setmetatable({}, EvidenceValidator)
    self._core = CoreEvidenceValidator.new(deps)
    return self
end

function EvidenceValidator:Validate(session, payload, context)
    return self._core:Validate(session, payload, context)
end

return EvidenceValidator
