local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    return self
end

function Service:Init()
    self._state:Set("initialized", true)
end

function Service:Start()
    self._state:Set("started", true)
end

function Service:Stop()
    self._state:Set("started", false)
end

return Service
