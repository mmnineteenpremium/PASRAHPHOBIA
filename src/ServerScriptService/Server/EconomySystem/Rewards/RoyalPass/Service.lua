local Service = {}
Service.__index = Service
local Services = require(script.Parent.Parent.Parent.Parent.Core.Services)

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

function Service:ApplyPassBonuses(player, reward)
    local multiplier = 1
    local eventBus = Services.Get(self._deps, "EventBus")
    if eventBus and reward then
        eventBus:Publish("RewardGranted", { player = player, amount = reward.amount * multiplier, context = "RoyalPass" })
    end
end

return Service
