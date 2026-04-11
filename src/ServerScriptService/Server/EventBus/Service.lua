local CoreEventBus = require(script.Parent.Parent.Core.EventBus)

local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._bus = CoreEventBus
    return self
end

function Service:Init()
    self._state:Set("coreBacked", true)
    self._bus:Reset()
end

function Service:Start()
    -- EventBus is ready once initialized.
end

function Service:Stop()
    self._state:Clear()
    self._bus:Reset()
end

function Service:Publish(eventName, payload)
    return self._bus:Publish(eventName, payload)
end

function Service:Subscribe(eventName, callback, tag)
    return self._bus:Subscribe(eventName, callback, tag)
end

function Service:SubscribeOnce(eventName, callback, tag)
    return self._bus:SubscribeOnce(eventName, callback, tag)
end

function Service:Unsubscribe(eventName, listenerIdOrCallback)
    return self._bus:Unsubscribe(eventName, listenerIdOrCallback)
end

function Service:GetListenerReport()
    return self._bus:GetListenerReport()
end

function Service:GetRecentLog(count)
    return self._bus:GetRecentLog(count)
end

function Service:SetDebugMode(enabled)
    self._bus:SetDebugMode(enabled)
end

return Service
