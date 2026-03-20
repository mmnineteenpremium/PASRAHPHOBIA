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
    self._state:Set("controllerInitialized", true)
end

function Controller:RegisterEventHandlers()
    self._state:Set("handlersRegistered", true)
end

function Controller:UnregisterEventHandlers()
    self._state:Set("handlersRegistered", false)
end

return Controller
