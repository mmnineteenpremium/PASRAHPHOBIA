local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local MapInteractionSystem = {}
MapInteractionSystem.__index = MapInteractionSystem

function MapInteractionSystem.new(deps)
	local self = setmetatable({}, MapInteractionSystem)
	self._deps = deps or {}
	self.State = State.new()
	self.Service = Service.new(self.State, self._deps)
	self.Controller = Controller.new(self.State, self.Service, self._deps)
	return self
end

function MapInteractionSystem:Init()
	self.Service:Init()
	self.Controller:Init()
end

function MapInteractionSystem:Start()
	self.Controller:RegisterEventHandlers()
	self.Service:Start()
end

function MapInteractionSystem:Stop()
	self.Controller:UnregisterEventHandlers()
	self.Service:Stop()
end

function MapInteractionSystem:OpenDoor(matchId, doorId, payload)
	return self.Service:OpenDoor(matchId, doorId, payload)
end

function MapInteractionSystem:SlamDoor(matchId, doorId, payload)
	return self.Service:SlamDoor(matchId, doorId, payload)
end

function MapInteractionSystem:SetDoorLock(matchId, doorId, isLocked, payload)
	return self.Service:SetDoorLock(matchId, doorId, isLocked, payload)
end

function MapInteractionSystem:FlickerLights(matchId, roomId, payload)
	return self.Service:FlickerLights(matchId, roomId, payload)
end

function MapInteractionSystem:MoveObject(matchId, objectId, mode, payload)
	return self.Service:MoveObject(matchId, objectId, mode, payload)
end

function MapInteractionSystem:DisturbElectronics(matchId, targetId, mode, payload)
	return self.Service:DisturbElectronics(matchId, targetId, mode, payload)
end

return MapInteractionSystem
