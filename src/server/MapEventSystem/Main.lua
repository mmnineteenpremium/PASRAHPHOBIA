local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local MapEventSystem = {}
MapEventSystem.__index = MapEventSystem

function MapEventSystem.new(deps)
	local self = setmetatable({}, MapEventSystem)
	self._deps = deps or {}
	self.State = State.new()
	self.Service = Service.new(self.State, self._deps)
	self.Controller = Controller.new(self.State, self.Service, self._deps)
	return self
end

function MapEventSystem:Init()
	self.Service:Init()
	self.Controller:Init()
end

function MapEventSystem:Start()
	self.Controller:RegisterEventHandlers()
	self.Service:Start()
end

function MapEventSystem:Stop()
	self.Controller:UnregisterEventHandlers()
	self.Service:Stop()
end

function MapEventSystem:TriggerEvent(matchId, eventType, payload)
	return self.Service:TriggerEvent(matchId, eventType, payload)
end

function MapEventSystem:GetActiveEvents(matchId)
	return self.Service:GetActiveEvents(matchId)
end

function MapEventSystem:EndEvent(matchId, eventTypeOrId)
	return self.Service:EndEvent(matchId, eventTypeOrId)
end

return MapEventSystem
