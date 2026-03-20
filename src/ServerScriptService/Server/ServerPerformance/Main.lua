local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ServerPerformance = {}
ServerPerformance.__index = ServerPerformance

function ServerPerformance.new(deps)
	local self = setmetatable({}, ServerPerformance)
	self._deps = deps or {}
	self.State = State.new()
	self.Service = Service.new(self.State, self._deps)
	self.Controller = Controller.new(self.State, self.Service, self._deps)
	return self
end

function ServerPerformance:Init()
	self.Service:Init()
	self.Controller:Init()
end

function ServerPerformance:Start()
	self.Controller:RegisterEventHandlers()
	self.Service:Start()
end

function ServerPerformance:Stop()
	self.Controller:UnregisterEventHandlers()
	self.Service:Stop()
end

function ServerPerformance:GetMetrics()
	return self.Service:GetMetrics()
end

return ServerPerformance
