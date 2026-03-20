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
    -- placeholders for RoyalPass hooks
end

return Controller
