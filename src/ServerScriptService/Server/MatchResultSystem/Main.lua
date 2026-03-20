local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local MatchResultSystem = {}
MatchResultSystem.__index = MatchResultSystem

function MatchResultSystem.new(deps)
    local self = setmetatable({}, MatchResultSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function MatchResultSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function MatchResultSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function MatchResultSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return MatchResultSystem
