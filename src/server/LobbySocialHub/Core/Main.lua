local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local Core = {}
Core.__index = Core

function Core.new(deps)
    local self = setmetatable({}, Core)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function Core:Init()
    self.Service:Init()
    self.Controller:Init()
end

function Core:Start()
    self.Service:Start()
    self.Controller:Start()
end

function Core:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return Core