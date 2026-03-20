local Controller = {}
Controller.__index = Controller

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    return self
end

function Controller:Init()
    -- Interaction trigger wiring is intentionally deferred.
end

function Controller:Handle(interactionName, payload)
    if not self._service:IsSupported(interactionName) then
        return false, "unsupported_interaction"
    end

    return true, {
        interaction = interactionName,
        payload = payload,
    }
end

return Controller