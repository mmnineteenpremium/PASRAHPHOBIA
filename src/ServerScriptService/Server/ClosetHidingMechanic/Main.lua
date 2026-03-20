local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ClosetHidingMechanic = {}
ClosetHidingMechanic.__index = ClosetHidingMechanic

function ClosetHidingMechanic.new(deps)
    local self = setmetatable({}, ClosetHidingMechanic)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ClosetHidingMechanic:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ClosetHidingMechanic:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ClosetHidingMechanic:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return ClosetHidingMechanic
