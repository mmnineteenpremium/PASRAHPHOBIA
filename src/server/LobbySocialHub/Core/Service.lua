local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._systems = {
        MatchSystem = self._deps.MatchSystem,
        ProfileSystem = self._deps.ProfileSystem,
        EconomySystem = self._deps.EconomySystem,
        PartySystem = self._deps.PartySystem,
    }
    return self
end

function Service:Init()
    self._state:Set("coreStatus", "initialized")
end

function Service:Start()
    self._state:Set("coreStatus", "running")
end

function Service:Stop()
    self._state:Set("coreStatus", "stopped")
end

function Service:GetSystems()
    return self._systems
end

return Service