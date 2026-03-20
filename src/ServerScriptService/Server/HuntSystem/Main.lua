local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local HuntSystem = {}
HuntSystem.__index = HuntSystem

function HuntSystem.new(deps)
    local self = setmetatable({}, HuntSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function HuntSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function HuntSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function HuntSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return HuntSystem
