local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local EventBus = {}
EventBus.__index = EventBus

function EventBus.new(deps)
    local self = setmetatable({}, EventBus)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function EventBus:Init()
    self.Service:Init()
    self.Controller:Init()
end

function EventBus:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function EventBus:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return EventBus
