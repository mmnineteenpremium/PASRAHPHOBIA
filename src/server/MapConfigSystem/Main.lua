local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local MapConfigSystem = {}
MapConfigSystem.__index = MapConfigSystem

function MapConfigSystem.new(deps)
    local self = setmetatable({}, MapConfigSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function MapConfigSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function MapConfigSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function MapConfigSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function MapConfigSystem:GetMapConfigs()
    return self.Service:GetMapConfigs()
end

function MapConfigSystem:GetMapConfig(mapId)
    return self.Service:GetMapConfig(mapId)
end

return MapConfigSystem
