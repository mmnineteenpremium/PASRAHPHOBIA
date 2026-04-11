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

function EventBus:Publish(eventName, payload)
    return self.Service:Publish(eventName, payload)
end

function EventBus:Subscribe(eventName, callback, tag)
    return self.Service:Subscribe(eventName, callback, tag)
end

function EventBus:SubscribeOnce(eventName, callback, tag)
    return self.Service:SubscribeOnce(eventName, callback, tag)
end

function EventBus:Unsubscribe(eventName, listenerIdOrCallback)
    return self.Service:Unsubscribe(eventName, listenerIdOrCallback)
end

function EventBus:GetListenerReport()
    return self.Service:GetListenerReport()
end

function EventBus:GetRecentLog(count)
    return self.Service:GetRecentLog(count)
end

function EventBus:SetDebugMode(enabled)
    self.Service:SetDebugMode(enabled)
end

function EventBus:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function EventBus:Shutdown()
    self:Stop()
end

return EventBus
