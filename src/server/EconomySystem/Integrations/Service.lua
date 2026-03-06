local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    return self
end

function Service:Init()
    self._state:Set("status", "initialized")
end

function Service:Start()
    self._state:Set("status", "running")
end

function Service:Stop()
    self._state:Set("status", "stopped")
end

function Service:GetSystems()
    return {
        match = self._state:Get("MatchSystem"),
        contract = self._state:Get("ContractSystem"),
        profile = self._state:Get("ProfileSystem"),
        lobby = self._state:Get("LobbySocialHub"),
    }
end

return Service
