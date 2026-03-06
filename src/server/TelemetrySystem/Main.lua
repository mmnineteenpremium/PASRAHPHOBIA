local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local TelemetrySystem = {}
TelemetrySystem.__index = TelemetrySystem

function TelemetrySystem.new(deps)
	local self = setmetatable({}, TelemetrySystem)
	self._deps = deps or {}
	self.State = State.new()
	self.Service = Service.new(self.State, self._deps)
	self.Controller = Controller.new(self.State, self.Service, self._deps)
	return self
end

function TelemetrySystem:Init()
	self.Service:Init()
	self.Controller:Init()
end

function TelemetrySystem:Start()
	self.Controller:RegisterEventHandlers()
	self.Service:Start()
end

function TelemetrySystem:Stop()
	self.Controller:UnregisterEventHandlers()
	self.Service:Stop()
end

function TelemetrySystem:RecordEvent(eventName, payload)
	return self.Service:RecordEvent(eventName, payload)
end

return TelemetrySystem
