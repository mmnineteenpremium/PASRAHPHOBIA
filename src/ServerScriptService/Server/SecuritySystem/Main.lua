local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local SecuritySystem = {}
SecuritySystem.__index = SecuritySystem

function SecuritySystem.new(deps)
    local self = setmetatable({}, SecuritySystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.SecurityState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SecuritySystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function SecuritySystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function SecuritySystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function SecuritySystem:ValidateRemoteRequest(player, remoteName, payload, context)
    return self.Service:ValidateRemoteRequest(player, remoteName, payload, context)
end

function SecuritySystem:ValidateCurrencyRequest(player, payload)
    return self.Service:ValidateCurrencyRequest(player, payload)
end

function SecuritySystem:ValidateInventoryRequest(player, payload)
    return self.Service:ValidateInventoryRequest(player, payload)
end

function SecuritySystem:ValidateMatchRequest(player, payload)
    return self.Service:ValidateMatchRequest(player, payload)
end

return SecuritySystem
