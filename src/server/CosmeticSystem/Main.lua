local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local CosmeticSystem = {}
CosmeticSystem.__index = CosmeticSystem

function CosmeticSystem.new(deps)
    local self = setmetatable({}, CosmeticSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function CosmeticSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function CosmeticSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function CosmeticSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return CosmeticSystem
