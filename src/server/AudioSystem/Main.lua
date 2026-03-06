local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local AudioSystem = {}
AudioSystem.__index = AudioSystem

function AudioSystem.new(deps)
	local self = setmetatable({}, AudioSystem)
	self._deps = deps or {}
	self.State = State.new()
	self.Service = Service.new(self.State, self._deps)
	self.Controller = Controller.new(self.State, self.Service, self._deps)
	return self
end

function AudioSystem:Init()
	self.Service:Init()
	self.Controller:Init()
end

function AudioSystem:Start()
	self.Controller:RegisterEventHandlers()
	self.Service:Start()
end

function AudioSystem:Stop()
	self.Controller:UnregisterEventHandlers()
	self.Service:Stop()
end

return AudioSystem
