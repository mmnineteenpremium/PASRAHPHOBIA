local Service = {}
Service.__index = Service
local Services = require(script.Parent.Parent.Parent.Core.Services)

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = Services.Get(self._deps, "EventBus")
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

function Service:ClaimDailyCheckIn(player)
    if not self._deps.CurrencyService then
        return false, "missing_currency_service"
    end
    return self._deps.CurrencyService:ClaimDailyCheckIn(player)
end

return Service
