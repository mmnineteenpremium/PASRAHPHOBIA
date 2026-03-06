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
    -- Building-specific triggers can be connected here.
end

function Controller:OnPlayerInteracted(player)
    return self._service:MarkPlayerActive(player)
end

return Controller