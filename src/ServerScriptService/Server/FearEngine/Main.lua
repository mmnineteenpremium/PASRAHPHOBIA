local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local FearEngine = {}
FearEngine.__index = FearEngine

function FearEngine.new(deps)
	local self = setmetatable({}, FearEngine)
	self._deps = deps or {}
	self.State = State.new()
	self.Service = Service.new(self.State, self._deps)
	self.Controller = Controller.new(self.State, self.Service, self._deps)
	return self
end

function FearEngine:Init()
	self.Service:Init()
	self.Controller:Init()
end

function FearEngine:Start()
	self.Controller:RegisterEventHandlers()
	self.Service:Start()
end

function FearEngine:Stop()
	self.Controller:UnregisterEventHandlers()
	self.Service:Stop()
end

function FearEngine:GetFearLevel(matchId)
	return self.Service:GetFearLevel(matchId)
end

return FearEngine
