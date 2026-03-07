local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local EventMapRotationSystem = {}
EventMapRotationSystem.__index = EventMapRotationSystem

function EventMapRotationSystem.new(deps)
    local self = setmetatable({}, EventMapRotationSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.EventMapRotationState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function EventMapRotationSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function EventMapRotationSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function EventMapRotationSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function EventMapRotationSystem:GetCurrentPool()
    return self.Service:GetCurrentPool()
end

function EventMapRotationSystem:GetRandomMap(excludedMapId)
    return self.Service:GetRandomMap(excludedMapId)
end

function EventMapRotationSystem:IsEventMap(mapId)
    return self.Service:IsEventMap(mapId)
end

return EventMapRotationSystem
