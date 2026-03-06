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
    -- hooking in addition to calling service directly
end

return Controller
