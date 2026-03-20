local Service = {}
Service.__index = Service
local Services = require(script.Parent.Parent.Parent.Core.Services)

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._systems = {
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        PartySystem = Services.Get(self._deps, "PartySystem"),
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
